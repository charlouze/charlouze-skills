#!/usr/bin/env bats
# Tests du script de finalisation. Chaque test monte un dépôt git local et son
# remote nu dans son dossier temporaire : ni GitHub, ni modèle, ni remote réel.
#
#   bats skills/finalize-stack/scripts/finalize-stack.bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/finalize-stack.sh"
  ROOT="$BATS_TEST_TMPDIR"

  # Isole les tests du dépôt et de la configuration git du poste : aucune
  # variable ne doit les renvoyer vers un vrai dépôt, ni ses hooks ou sa
  # signature s'appliquer.
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
    GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL="$ROOT/gitconfig"
  git config --file "$GIT_CONFIG_GLOBAL" init.defaultBranch main
  git config --file "$GIT_CONFIG_GLOBAL" user.name "Test"
  git config --file "$GIT_CONFIG_GLOBAL" user.email "test@example.invalid"
  git config --file "$GIT_CONFIG_GLOBAL" core.autocrlf false
  git config --file "$GIT_CONFIG_GLOBAL" advice.detachedHead false

  # Un dépôt de travail cloné d'un remote nu, avec un premier commit sur main.
  git init --quiet --bare "$ROOT/remote.git"
  git clone --quiet "$ROOT/remote.git" "$ROOT/work" 2>/dev/null
  cd "$ROOT/work"
  commit base.txt "line 1" "Set the base"
  publish
}

assert_eq() { # attendu obtenu message
  if [ "$1" != "$2" ]; then
    echo "$3: expected \"$1\", got \"$2\""
    return 1
  fi
}

commit() { # fichier contenu message [corps]
  printf '%s\n' "$2" >"$1"
  git add "$1"
  git commit --quiet -m "$3" ${4:+-m "$4"}
}

fixup() { commit "$1" "$2" "fixup! $3"; }     # fichier contenu sujet-visé
amend() { commit "$1" "$2" "amend! $3" "$4"; } # fichier contenu sujet-visé nouveau-message
publish() { git push --quiet origin "$(git branch --show-current)"; }

# Une couche : une branche posée sur la branche courante, un commit, poussée.
layer() { # branche fichier contenu message
  git switch --quiet -c "$1"
  commit "$2" "$3" "$4"
  publish
}

remote_sha() { git --git-dir=../remote.git rev-parse "refs/heads/$1"; }
remote_subjects() { git --git-dir=../remote.git log --reverse --format=%s "$1..$2"; }
remote_merges() { git --git-dir=../remote.git rev-list --merges "$1..$2" | wc -l | tr -d ' '; }
remote_file() { git --git-dir=../remote.git show "$1:$2"; }
# Les têtes des branches sur le remote, pour vérifier que rien n'a été poussé.
remote_heads() { git --git-dir=../remote.git for-each-ref --format='%(refname) %(objectname)' refs/heads; }
last_line() { tail -n 1 <<<"$output"; }

# Lance le script par `run` : sa sortie va dans $output, son code dans $status.
# Il ne tourne que si `origin` est le remote nu du test.
finalize() {
  case "$(git remote get-url origin)" in
    */remote.git) ;;
    *)
      echo "origin is not the test's bare remote" >&2
      return 1
      ;;
  esac
  run bash "$SCRIPT" "$@"
}

@test "a stack whose diffs stay the same is pushed, its fixups folded and its merges dropped" {
  layer layer-a a.txt "a1" "Add a"
  layer layer-b b.txt "b1" "Add b"
  # Correction en revue dans la couche a, propagée dans b par un merge.
  git switch --quiet layer-a
  fixup a.txt "a2" "Add a"
  publish
  git switch --quiet layer-b
  git merge --quiet --no-edit layer-a
  publish

  finalize main layer-a layer-b

  assert_eq 0 "$status" "exit code"
  assert_eq "pushed" "$(last_line)" "last line"
  assert_eq "Add a" "$(remote_subjects main layer-a)" "commits of layer a"
  assert_eq "a2" "$(remote_file layer-a a.txt)" "fixup folded into a"
  assert_eq "Add b" "$(remote_subjects layer-a layer-b)" "commits of layer b"
  assert_eq 0 "$(remote_merges main layer-b)" "merges left"
}

@test "a trunk that moved on is absorbed by the rebase" {
  layer layer-a a.txt "a1" "Add a"
  layer layer-b b.txt "b1" "Add b"
  git switch --quiet main
  commit other.txt "x" "Move main on"
  publish

  finalize main layer-a layer-b

  assert_eq 0 "$status" "exit code"
  assert_eq "$(remote_sha main)" "$(git --git-dir=../remote.git merge-base main layer-a)" "layer a on main"
  assert_eq "Add a" "$(remote_subjects main layer-a)" "commits of layer a"
  assert_eq "Add b" "$(remote_subjects layer-a layer-b)" "commits of layer b"
  assert_eq "x" "$(remote_file layer-b other.txt)" "main's progress in the top"
}

@test "a merge of the trunk that resolves a conflict is replayed" {
  layer layer-a base.txt "line 1 as a says" "Change the base"
  git switch --quiet main
  commit base.txt "line 1 as main says" "Change the base on main"
  publish
  # Le tronc entre en conflit : il est fusionné dans la couche du bas, et la
  # résolution revue avec le reste.
  git switch --quiet layer-a
  git merge --quiet main >/dev/null 2>&1 || true
  commit base.txt "line 1 as a and main say" "Merge branch 'main' into layer-a"
  publish

  finalize main layer-a

  assert_eq 0 "$status" "exit code"
  assert_eq "pushed" "$(last_line)" "last line"
  assert_eq "Change the base" "$(remote_subjects main layer-a)" "commits of layer a"
  assert_eq "line 1 as a and main say" "$(remote_file layer-a base.txt)" "resolution kept"
  assert_eq "$(remote_sha main)" "$(git --git-dir=../remote.git merge-base main layer-a)" "layer a on main"
}

@test "a conflict of an upper layer resolved by propagating the trunk is replayed" {
  layer layer-a a.txt "a1" "Add a"
  layer layer-b base.txt "line 1 as b says" "Change the base"
  git switch --quiet main
  commit base.txt "line 1 as main says" "Change the base on main"
  publish
  # Le tronc entre par la couche du bas, puis monte d'un merge ; le conflit se
  # résout dans la couche où il naît.
  git switch --quiet layer-a
  git merge --quiet --no-edit main >/dev/null
  publish
  git switch --quiet layer-b
  git merge --quiet layer-a >/dev/null 2>&1 || true
  commit base.txt "line 1 as b and main say" "Merge branch 'layer-a' into layer-b"
  publish

  finalize main layer-a layer-b

  assert_eq 0 "$status" "exit code"
  assert_eq "pushed" "$(last_line)" "last line"
  assert_eq "Change the base" "$(remote_subjects layer-a layer-b)" "commits of layer b"
  assert_eq "line 1 as b and main say" "$(remote_file layer-b base.txt)" "resolution kept"
  assert_eq 0 "$(remote_merges main layer-b)" "merges left"
}

@test "a diff that changes in one layer aborts everything, pushing nothing" {
  # Une sortie en couleur ne doit pas aveugler la comparaison des diffs.
  git config color.ui always
  layer layer-a a.txt "a1" "Add a"
  layer layer-b b.txt "b1" "Add b"
  layer layer-c c.txt "c1" "Add c"
  git switch --quiet layer-a
  fixup a.txt "a2" "Add a"
  publish
  # Le merge de propagation de b porte un changement à lui, que sa
  # suppression ferait perdre.
  git switch --quiet layer-b
  git merge --quiet --no-ff --no-commit layer-a >/dev/null 2>&1
  commit lost.txt "l" "Merge branch 'layer-a' into layer-b"
  publish
  local heads
  heads=$(remote_heads)

  finalize main layer-a layer-b layer-c

  assert_eq 1 "$status" "exit code"
  assert_eq "aborted: layer-b: diff changed" "$(last_line)" "last line"
  assert_eq "$heads" "$(remote_heads)" "remote branches"
}

@test "a rebase conflict aborts everything, pushing nothing" {
  layer layer-a a.txt "a1" "Add a"
  layer layer-b base.txt "line 1 as b says" "Change the base"
  git switch --quiet main
  commit base.txt "line 1 as main says" "Change the base on main"
  publish
  git switch --quiet layer-b
  local heads
  heads=$(remote_heads)

  finalize main layer-a layer-b

  assert_eq 1 "$status" "exit code"
  assert_eq "aborted: layer-b: rebase conflict (base.txt)" "$(last_line)" "last line"
  assert_eq "$heads" "$(remote_heads)" "remote branches"
  assert_eq "layer-b" "$(git branch --show-current)" "current branch"
  assert_eq 1 "$(git worktree list | wc -l | tr -d ' ')" "temporary worktree removed"
}

@test "a stack of one layer is finalized" {
  git switch --quiet -c layer-a
  commit a.txt "a1" "Add a"
  commit c.txt "c1" "Add c"
  publish
  fixup a.txt "a2" "Add a"
  amend c.txt "c2" "Add c" "Add c, corrected"
  publish

  finalize main layer-a

  assert_eq 0 "$status" "exit code"
  assert_eq "pushed" "$(last_line)" "last line"
  assert_eq "Add a
Add c, corrected" "$(remote_subjects main layer-a)" "commits of the layer"
  assert_eq "a2" "$(remote_file layer-a a.txt)" "fixup folded"
  assert_eq "c2" "$(remote_file layer-a c.txt)" "amend folded"
}

@test "a commit that its corrections empty is dropped" {
  git switch --quiet -c layer-a
  commit a.txt "a1" "Add a"
  commit b.txt "b1" "Add b"
  commit c.txt "c1" "Add c"
  publish
  # La revue rejette b : sa correction le défait, et b disparaît.
  git rm --quiet b.txt
  git commit --quiet -m "fixup! Add b"
  publish

  finalize main layer-a

  assert_eq 0 "$status" "exit code"
  assert_eq "pushed" "$(last_line)" "last line"
  assert_eq "Add a
Add c" "$(remote_subjects main layer-a)" "commits of the layer"
}

@test "a correction aimed at another layer aborts" {
  layer layer-a a.txt "a1" "Add a"
  layer layer-b b.txt "b1" "Add b"
  fixup a.txt "a2" "Add a"
  publish
  local heads
  heads=$(remote_heads)

  finalize main layer-a layer-b

  assert_eq 1 "$status" "exit code"
  assert_eq 'aborted: layer-b: correction outside its layer: "fixup! Add a"' "$(last_line)" "last line"
  assert_eq "$heads" "$(remote_heads)" "remote branches"
}

@test "a refused push aborts" {
  layer layer-a a.txt "a1" "Add a"
  fixup a.txt "a2" "Add a"
  publish
  printf '#!/bin/sh\nexit 1\n' >../remote.git/hooks/pre-receive
  chmod +x ../remote.git/hooks/pre-receive
  local heads
  heads=$(remote_heads)

  finalize main layer-a

  assert_eq 1 "$status" "exit code"
  assert_eq "aborted: stack: push refused" "$(last_line)" "last line"
  assert_eq "$heads" "$(remote_heads)" "remote branches"
}

@test "a layer missing from the remote aborts" {
  layer layer-a a.txt "a1" "Add a"
  local heads
  heads=$(remote_heads)

  finalize main layer-a unknown-layer

  assert_eq 1 "$status" "exit code"
  assert_eq "aborted: stack: remote unreadable" "$(last_line)" "last line"
  assert_eq "$heads" "$(remote_heads)" "remote branches"
}

@test "no layer is a usage error" {
  finalize main

  assert_eq 2 "$status" "exit code"
}

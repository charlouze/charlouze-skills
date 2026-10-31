#!/usr/bin/env bash
# Tests du script de finalisation. Chaque test monte un dépôt git local et son
# remote nu dans un dossier temporaire : ni GitHub, ni modèle, ni remote réel.
#
#   bash skills/finalize-stack/scripts/finalize-stack.test.sh

set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/finalize-stack.sh"
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT

# Isole les tests du dépôt et de la configuration git du poste : aucune
# variable ne doit les renvoyer vers un vrai dépôt, ni ses hooks ou sa signature
# s'appliquer.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
  GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="$ROOT/gitconfig"
git config --file "$GIT_CONFIG_GLOBAL" init.defaultBranch main
git config --file "$GIT_CONFIG_GLOBAL" user.name "Test"
git config --file "$GIT_CONFIG_GLOBAL" user.email "test@example.invalid"
git config --file "$GIT_CONFIG_GLOBAL" core.autocrlf false
git config --file "$GIT_CONFIG_GLOBAL" advice.detachedHead false

failures=0
current=""

fail() {
  echo "  ÉCHEC ($current) : $*"
  failures=$((failures + 1))
}

assert_eq() { # attendu obtenu message
  [ "$1" = "$2" ] || fail "$3 : attendu « $1 », obtenu « $2 »"
}

# Un dépôt de travail cloné d'un remote nu, avec un premier commit sur main.
sandbox() {
  local dir="$ROOT/$1"
  git init --quiet --bare "$dir/remote.git"
  git clone --quiet "$dir/remote.git" "$dir/work" 2>/dev/null
  cd "$dir/work"
  commit base.txt "ligne 1" "Pose la base"
  publish
}

commit() { # fichier contenu message [corps]
  printf '%s\n' "$2" > "$1"
  git add "$1"
  git commit --quiet -m "$3" ${4:+-m "$4"}
}

fixup() { commit "$1" "$2" "fixup! $3"; } # fichier contenu sujet-visé
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
last_line() { tail -n 1 <<<"$out"; }

# Lance le script ; sa sortie va dans $out, son code dans $status. Il ne tourne
# que si `origin` est le remote nu du test.
finalize() {
  case "$(git remote get-url origin)" in
    */remote.git) ;;
    *) echo "origin n'est pas le remote nu du test" >&2; exit 1 ;;
  esac
  status=0
  out="$(bash "$SCRIPT" "$@" 2>&1)" || status=$?
}

test_pile_identique_poussee() {
  sandbox identique
  layer couche-a a.txt "a1" "Ajoute a"
  layer couche-b b.txt "b1" "Ajoute b"
  # Correction en revue dans la couche a, propagée dans b par un merge.
  git switch --quiet couche-a
  fixup a.txt "a2" "Ajoute a"
  publish
  git switch --quiet couche-b
  git merge --quiet --no-edit couche-a
  publish

  finalize main couche-a couche-b

  assert_eq 0 "$status" "code de sortie"
  assert_eq "poussé" "$(last_line)" "dernière ligne"
  assert_eq "Ajoute a" "$(remote_subjects main couche-a)" "commits de la couche a"
  assert_eq "a2" "$(remote_file couche-a a.txt)" "correction fondue dans a"
  assert_eq "Ajoute b" "$(remote_subjects couche-a couche-b)" "commits de la couche b"
  assert_eq 0 "$(remote_merges main couche-b)" "merges restants"
}

test_main_avance_absorbe() {
  sandbox main-avance
  layer couche-a a.txt "a1" "Ajoute a"
  layer couche-b b.txt "b1" "Ajoute b"
  git switch --quiet main
  commit autre.txt "x" "Avance main"
  publish

  finalize main couche-a couche-b

  assert_eq 0 "$status" "code de sortie"
  assert_eq "$(remote_sha main)" "$(git --git-dir=../remote.git merge-base main couche-a)" "couche a posée sur main"
  assert_eq "Ajoute a" "$(remote_subjects main couche-a)" "commits de la couche a"
  assert_eq "Ajoute b" "$(remote_subjects couche-a couche-b)" "commits de la couche b"
  assert_eq "x" "$(remote_file couche-b autre.txt)" "avance de main dans le sommet"
}

test_merge_du_tronc_resolu_rejoue() {
  sandbox merge-du-tronc
  layer couche-a base.txt "ligne 1 selon a" "Modifie la base"
  git switch --quiet main
  commit base.txt "ligne 1 selon main" "Modifie la base sur main"
  publish
  # Le tronc entre en conflit : il est fusionné dans la couche du bas, et la
  # résolution revue avec le reste.
  git switch --quiet couche-a
  git merge --quiet main >/dev/null 2>&1 || true
  commit base.txt "ligne 1 selon a et main" "Merge branch 'main' into couche-a"
  publish

  finalize main couche-a

  assert_eq 0 "$status" "code de sortie"
  assert_eq "poussé" "$(last_line)" "dernière ligne"
  assert_eq "Modifie la base" "$(remote_subjects main couche-a)" "commits de la couche a"
  assert_eq "ligne 1 selon a et main" "$(remote_file couche-a base.txt)" "résolution gardée"
  assert_eq "$(remote_sha main)" "$(git --git-dir=../remote.git merge-base main couche-a)" "couche a posée sur main"
}

test_conflit_du_haut_resolu_par_propagation() {
  sandbox propagation-du-tronc
  layer couche-a a.txt "a1" "Ajoute a"
  layer couche-b base.txt "ligne 1 selon b" "Modifie la base"
  git switch --quiet main
  commit base.txt "ligne 1 selon main" "Modifie la base sur main"
  publish
  # Le tronc entre par la couche du bas, puis monte d'un merge ; le conflit se
  # résout dans la couche où il naît.
  git switch --quiet couche-a
  git merge --quiet --no-edit main >/dev/null
  publish
  git switch --quiet couche-b
  git merge --quiet couche-a >/dev/null 2>&1 || true
  commit base.txt "ligne 1 selon b et main" "Merge branch 'couche-a' into couche-b"
  publish

  finalize main couche-a couche-b

  assert_eq 0 "$status" "code de sortie"
  assert_eq "poussé" "$(last_line)" "dernière ligne"
  assert_eq "Modifie la base" "$(remote_subjects couche-a couche-b)" "commits de la couche b"
  assert_eq "ligne 1 selon b et main" "$(remote_file couche-b base.txt)" "résolution gardée"
  assert_eq 0 "$(remote_merges main couche-b)" "merges restants"
}

test_ecart_de_diff_abandonne_sans_push() {
  sandbox ecart
  # Une sortie en couleur ne doit pas aveugler la comparaison des diffs.
  git config color.ui always
  layer couche-a a.txt "a1" "Ajoute a"
  layer couche-b b.txt "b1" "Ajoute b"
  layer couche-c c.txt "c1" "Ajoute c"
  git switch --quiet couche-a
  fixup a.txt "a2" "Ajoute a"
  publish
  # Le merge de propagation de b porte un changement à lui, que sa
  # suppression ferait perdre.
  git switch --quiet couche-b
  git merge --quiet --no-ff --no-commit couche-a >/dev/null 2>&1
  commit perdu.txt "p" "Merge branch 'couche-a' into couche-b"
  publish
  local heads
  heads=$(remote_heads)

  finalize main couche-a couche-b couche-c

  assert_eq 1 "$status" "code de sortie"
  assert_eq "abandonné : couche-b : diff changé" "$(last_line)" "dernière ligne"
  assert_eq "$heads" "$(remote_heads)" "branches du remote"
}

test_conflit_au_rebase_abandonne_sans_push() {
  sandbox conflit
  layer couche-a a.txt "a1" "Ajoute a"
  layer couche-b base.txt "ligne 1 selon b" "Modifie la base"
  git switch --quiet main
  commit base.txt "ligne 1 selon main" "Modifie la base sur main"
  publish
  git switch --quiet couche-b
  local heads
  heads=$(remote_heads)

  finalize main couche-a couche-b

  assert_eq 1 "$status" "code de sortie"
  assert_eq "abandonné : couche-b : conflit au rebase (base.txt)" "$(last_line)" "dernière ligne"
  assert_eq "$heads" "$(remote_heads)" "branches du remote"
  assert_eq "couche-b" "$(git branch --show-current)" "branche courante"
  assert_eq 1 "$(git worktree list | wc -l | tr -d ' ')" "worktree temporaire retiré"
}

test_pile_d_une_couche_finalisee() {
  sandbox une-couche
  git switch --quiet -c couche-a
  commit a.txt "a1" "Ajoute a"
  commit c.txt "c1" "Ajoute c"
  publish
  fixup a.txt "a2" "Ajoute a"
  amend c.txt "c2" "Ajoute c" "Ajoute c, corrigé"
  publish

  finalize main couche-a

  assert_eq 0 "$status" "code de sortie"
  assert_eq "poussé" "$(last_line)" "dernière ligne"
  assert_eq "Ajoute a
Ajoute c, corrigé" "$(remote_subjects main couche-a)" "commits de la couche"
  assert_eq "a2" "$(remote_file couche-a a.txt)" "fixup fondu"
  assert_eq "c2" "$(remote_file couche-a c.txt)" "amend fondu"
}

test_correction_hors_de_sa_couche_abandonne() {
  sandbox hors-couche
  layer couche-a a.txt "a1" "Ajoute a"
  layer couche-b b.txt "b1" "Ajoute b"
  fixup a.txt "a2" "Ajoute a"
  publish
  local heads
  heads=$(remote_heads)

  finalize main couche-a couche-b

  assert_eq 1 "$status" "code de sortie"
  assert_eq "abandonné : couche-b : correction hors de sa couche : « fixup! Ajoute a »" "$(last_line)" "dernière ligne"
  assert_eq "$heads" "$(remote_heads)" "branches du remote"
}

test_push_refuse_abandonne() {
  sandbox push-refuse
  layer couche-a a.txt "a1" "Ajoute a"
  fixup a.txt "a2" "Ajoute a"
  publish
  printf '#!/bin/sh\nexit 1\n' > ../remote.git/hooks/pre-receive
  chmod +x ../remote.git/hooks/pre-receive
  local heads
  heads=$(remote_heads)

  finalize main couche-a

  assert_eq 1 "$status" "code de sortie"
  assert_eq "abandonné : pile : push refusé" "$(last_line)" "dernière ligne"
  assert_eq "$heads" "$(remote_heads)" "branches du remote"
}

test_couche_absente_du_remote_abandonne() {
  sandbox absente
  layer couche-a a.txt "a1" "Ajoute a"
  local heads
  heads=$(remote_heads)

  finalize main couche-a couche-inconnue

  assert_eq 1 "$status" "code de sortie"
  assert_eq "abandonné : pile : lecture du remote impossible" "$(last_line)" "dernière ligne"
  assert_eq "$heads" "$(remote_heads)" "branches du remote"
}

test_usage_sans_couche() {
  sandbox usage

  finalize main

  assert_eq 2 "$status" "code de sortie"
}

# Chaque test tourne dans un sous-shell, où `set -e` arrête le test à la
# première commande en échec : son `cd` et ses variables restent à lui.
failed=0
for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
  current="$t"
  echo "$t"
  set +e
  ( set -e; "$t"; exit "$failures" )
  code=$?
  set -e
  if [ "$code" -ne 0 ]; then
    echo "  en échec (code $code)"
    failed=$((failed + 1))
  fi
done

if [ "$failed" -ne 0 ]; then
  echo "$failed test(s) en échec"
  exit 1
fi
echo "tous les tests passent"

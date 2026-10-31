#!/usr/bin/env bash
# Finalise une pile approuvée : fond les corrections (`fixup!`, `amend!`) dans
# leur couche, supprime les merges de la pile, rebase la pile sur le tronc
# courant, et ne force-pousse que si le diff de chaque couche est resté le même.
#
#   finalize-stack.sh <tronc> <branche du bas> … <branche du sommet>
#
# Sortie : une ligne par couche réécrite, puis une dernière ligne, l'une de :
#   poussé
#   abandonné : <couche> : conflit au rebase (<fichiers>)
#   abandonné : <couche> : diff changé
#   abandonné : <couche> : correction hors de sa couche : « <sujet> »
#   abandonné : pile : push refusé
#   abandonné : <couche ou pile> : <autre raison>, une panne de la pile ou du poste
# Code : 0 poussé, 1 abandonné, 2 usage. Un abandon ne pousse rien.
#
# Le script ne lit pas GitHub : que chaque couche passée soit approuvée, c'est
# à l'appelant de le vérifier (la skill finalize-stack le fait).
#
# La pile est lue sur le remote `origin`, et réécrite dans un worktree
# temporaire : ni les branches locales ni l'arbre de travail ne bougent. Les
# résolutions de conflit que portent les merges de la pile (un merge du tronc
# dans la couche du bas, par exemple) sont rejouées par rerere ; elles restent
# dans le cache rerere du dépôt (`.git/rr-cache`), où une résolution plus
# ancienne peut aussi servir : la comparaison des diffs en reste juge. Rien n'est
# poussé avant que toutes les couches soient vérifiées, puis tout l'est d'un
# coup (`--atomic`), chaque branche sous condition de n'avoir pas bougé depuis
# la lecture (`--force-with-lease`).
#
# Demande bash et git 2.41 ou plus récent.

set -euo pipefail

remote=origin

if [ $# -lt 2 ]; then
  echo "usage : finalize-stack.sh <tronc> <branche du bas> … <branche du sommet>" >&2
  exit 2
fi
trunk=$1
shift
layers=("$@")

workdir=""
verdict=""

# À la sortie, le worktree temporaire disparaît. Une sortie sans verdict, sur
# une commande en échec que `set -e` arrête, finit par la même dernière ligne
# qu'un abandon, et avant le push.
on_exit() {
  local code=$?
  if [ -n "$workdir" ]; then
    git worktree remove --force "$workdir" >/dev/null 2>&1 || true
    rm -rf "$workdir"
  fi
  if [ -z "$verdict" ]; then
    echo "abandonné : pile : erreur inattendue (code $code)"
    exit 1
  fi
}
trap on_exit EXIT
trap 'exit 1' INT TERM

abandon() { # couche raison
  verdict=abandonné
  echo "abandonné : $1 : $2"
  exit 1
}

# git dans le worktree temporaire, rerere actif et sans éditeur.
in_worktree() {
  GIT_EDITOR=true GIT_SEQUENCE_EDITOR=true \
    git -C "$workdir" -c rerere.enabled=true -c rerere.autoUpdate=true "$@"
}

# Diff d'une couche tel qu'une PR le montre (depuis la base de fusion), réduit à
# son patch-id : les numéros de ligne n'y comptent pas, les espaces si. Un `main`
# qui avance ailleurs dans un fichier de la couche ne change donc pas le diff.
layer_diff_id() { # base tête
  local fork diff id
  fork=$(git merge-base "$1" "$2") || return 1
  # Appelée à gauche d'un `||`, où `set -e` ne joue pas : chaque échec y est
  # rendu à la main.
  diff=$(git diff --no-color --no-relative --no-ext-diff --no-textconv --no-renames \
    --binary --full-index "$fork" "$2") || return 1
  id=$(git patch-id --verbatim <<<"$diff" | cut -d' ' -f1) || return 1
  # Un diff non vide sans patch-id n'a pas été lu : rien ne doit passer pour égal.
  if [ -n "$diff" ] && [ -z "$id" ]; then
    return 1
  fi
  echo "${id:-vide}"
}

# Apprend à rerere les résolutions de conflit des merges de la couche, comme le
# fait `contrib/rerere-train.sh` de git.
learn_resolutions() { # base tête
  local merge
  for merge in $(git rev-list --merges "$1..$2"); do
    in_worktree checkout --quiet --detach "$merge^1"
    if ! in_worktree merge --quiet --no-edit --no-ff "$merge^2" >/dev/null 2>&1; then
      in_worktree rerere
      in_worktree checkout --quiet "$merge" -- .
      in_worktree rerere
    fi
    in_worktree reset --quiet --hard
  done
}

# Pose les commits de la couche, sans ses merges et autosquashés, sur la couche
# du dessous réécrite. Un conflit que rerere résout est poursuivi ; un autre
# arrête tout.
rebase_layer() { # couche base-avant base-après tête
  local out unmerged steps
  out=$(in_worktree rebase --quiet --interactive --autosquash --no-rebase-merges --no-update-refs \
    --onto "$3" "$2" "$4" 2>&1) && return 0
  steps=$(git rev-list --count "$2..$4")
  while [ "$steps" -gt 0 ]; do
    unmerged=$(in_worktree diff --name-only --diff-filter=U | paste -sd ' ' -)
    if [ -n "$unmerged" ]; then
      in_worktree rebase --abort >/dev/null 2>&1 || true
      abandon "$1" "conflit au rebase ($unmerged)"
    fi
    out=$(in_worktree rebase --continue 2>&1) && return 0
    steps=$((steps - 1))
  done
  in_worktree rebase --abort >/dev/null 2>&1 || true
  abandon "$1" "rebase en échec : $(head -n 1 <<<"$out")"
}

# Lecture de la pile sur le remote.
refspecs=("+refs/heads/$trunk:refs/remotes/$remote/$trunk")
for layer in "${layers[@]}"; do
  refspecs+=("+refs/heads/$layer:refs/remotes/$remote/$layer")
done
git fetch --quiet "$remote" "${refspecs[@]}" || abandon "pile" "lecture du remote impossible"

trunk_head=$(git rev-parse --verify "refs/remotes/$remote/$trunk^{commit}")
old_heads=()
for layer in "${layers[@]}"; do
  old_heads+=("$(git rev-parse --verify "refs/remotes/$remote/$layer^{commit}")")
done

workdir=$(mktemp -d)
git worktree add --quiet --detach "$workdir" "$trunk_head"

# Réécriture couche par couche, du bas vers le haut.
new_heads=()
for i in "${!layers[@]}"; do
  layer=${layers[$i]}
  old_head=${old_heads[$i]}
  if [ "$i" -eq 0 ]; then
    old_base=$trunk_head
    new_base=$trunk_head
  else
    old_base=${old_heads[$((i - 1))]}
    new_base=${new_heads[$((i - 1))]}
  fi

  before=$(layer_diff_id "$old_base" "$old_head") || abandon "$layer" "diff illisible"
  learn_resolutions "$old_base" "$old_head"
  rebase_layer "$layer" "$old_base" "$new_base" "$old_head"
  new_head=$(in_worktree rev-parse HEAD)
  new_heads+=("$new_head")

  subjects=$(git log --format=%s "$new_base..$new_head")
  leftover=$(grep -E '^(fixup|amend|squash)! ' <<<"$subjects" | head -n 1 || true)
  if [ -n "$leftover" ]; then
    abandon "$layer" "correction hors de sa couche : « $leftover »"
  fi

  after=$(layer_diff_id "$new_base" "$new_head") || abandon "$layer" "diff réécrit illisible"
  if [ "$before" != "$after" ]; then
    abandon "$layer" "diff changé"
  fi
  count=$(git rev-list --count "$new_base..$new_head")
  echo "$layer : diff identique, $count commit(s)"
done

# Toutes les couches sont vérifiées : tout part d'un coup, ou rien.
push_args=(--atomic --quiet)
push_refs=()
for i in "${!layers[@]}"; do
  push_args+=("--force-with-lease=refs/heads/${layers[$i]}:${old_heads[$i]}")
  push_refs+=("${new_heads[$i]}:refs/heads/${layers[$i]}")
done
git push "${push_args[@]}" "$remote" "${push_refs[@]}" || abandon "pile" "push refusé"
verdict=poussé
echo "poussé"

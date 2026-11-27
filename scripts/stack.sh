#!/usr/bin/env bash
# Lit une pile sur GitHub : sa forme, l'approbation de chacune de ses couches et
# celles qui sont sautées. Il est le seul à les lire, pour les skills qui
# l'appellent, la reprise (`rework-stack`, par `rework-stack.sh pending`), la
# revue guidée (`guided-review`, par `guided-review.sh notes`) et la
# finalisation (`finalize-stack`) : le parcours de la pile, la règle
# d'approbation et celle des couches sautées ne vivent qu'ici. Il ne lit aucun
# échange (fils, revues, commentaires).
#
#   stack.sh <PR>
#
# Il lit la pile depuis n'importe laquelle de ses PR : vers le bas par les bases
# jusqu'au tronc, vers le haut par les PR ouvertes basées sur chaque tête. Il
# rend un document JSON :
#   {"trunk": "<branche>", "layers": [<couche>, … du bas vers le haut]}
# Une couche donne {number, title, head, base, draft, approval}, où `approval`
# est, pour la couche seule, quels que soient les drafts sous elle :
#   approved           `reviewDecision` à APPROVED ou, quand il est vide, une
#                      approbation sans demande de changement dans `latestReviews`
#   changes requested  `reviewDecision` à CHANGES_REQUESTED ou, quand il est
#                      vide, une demande de changement dans `latestReviews`
#   none               sinon : revue requise, ou personne n'a relu
# puis, pour une couche sautée, celle qu'une passe de revue n'a pas à revoir,
# `skipped`, la raison pour laquelle elle l'est, absent pour une couche à revoir :
#   draft              une couche draft
#   above draft        toute couche au-dessus d'une couche draft
#   approved           une couche approuvée
# Un lecteur qui juge chaque couche par `draft` et `approval`, comme la
# finalisation, l'ignore.
#
# Code : 0 fait, 1 échec de `gh`, 2 usage, 3 pile qui fourche (deux PR ouvertes
# sur une même base, nommées sur la sortie d'erreur). En échec, rien n'est écrit
# sur la sortie.
#
# Le script n'a pas d'identité à lui : ses `gh` agissent sous celle de
# l'environnement qui le lance. Lancé par un wrapper d'identité, ils prennent
# son jeton ; sinon, celui de l'humain.
#
# Demande bash 4.4 ou plus récent, gh et jq.

set -euo pipefail
# Une commande en échec arrête aussi le script depuis une substitution `$(…)`.
shopt -s inherit_errexit

# Tout arrêt que le script ne décide pas lui-même, sur une commande en échec
# (`gh` le plus souvent), sort avec le code 1, quel que soit celui de la commande.
decided=""
trap 'code=$?; if [ "$code" -ne 0 ] && [ -z "$decided" ]; then exit 1; fi' EXIT

leave() { # code message
  decided=yes
  echo "$2" >&2
  exit "$1"
}

usage() {
  leave 2 "usage: stack.sh <PR>"
}

# jq natif sous Windows écrit ses fins de ligne en CRLF.
j() { jq "$@" | tr -d '\r'; }

j -n 1 >/dev/null 2>&1 || leave 1 "stack.sh: jq not found"

pr_view() { # numéro champs
  gh pr view "$1" --json "$2"
}

open_on() { # --base|--head branche
  gh pr list "$1" "$2" --state open --json number | j -r '.[].number'
}

# Descend par les bases jusqu'au tronc : la PR du bas dans `bottom`, le tronc
# dans `trunk`.
walk_down() { # PR
  local info below
  bottom=$1
  while :; do
    info=$(pr_view "$bottom" baseRefName)
    trunk=$(j -r .baseRefName <<<"$info")
    below=$(open_on --head "$trunk")
    below=${below%%$'\n'*}
    [ -n "$below" ] || break
    bottom=$below
  done
}

# Monte par les PR ouvertes basées sur chaque tête : les PR du bas vers le haut
# dans `layers`. Deux PR sur une même base arrêtent tout, avec le code 3.
walk_up() { # PR-du-bas
  local number=$1 info head above
  layers=()
  while :; do
    layers+=("$number")
    info=$(pr_view "$number" headRefName)
    head=$(j -r .headRefName <<<"$info")
    above=$(open_on --base "$head")
    [ -n "$above" ] || break
    if [ "$(wc -l <<<"$above")" -gt 1 ]; then
      leave 3 "stack forks on $head: $(sed 's/^/#/' <<<"$above" | paste -sd ' ' -)"
    fi
    number=$above
  done
}

layer() { # numéro
  pr_view "$1" number,title,headRefName,baseRefName,isDraft,reviewDecision,latestReviews | j -c '
    def approval:
      if .reviewDecision == "APPROVED" then "approved"
      elif .reviewDecision == "CHANGES_REQUESTED" then "changes requested"
      elif (.reviewDecision // "") != "" then "none"
      else [.latestReviews[].state] as $states
        | if $states | index("CHANGES_REQUESTED") then "changes requested"
          elif $states | index("APPROVED") then "approved"
          else "none" end
      end;
    {number, title, head: .headRefName, base: .baseRefName, draft: .isDraft, approval: approval}'
}

stack() { # PR
  local trunk bottom layers number all=""
  walk_down "$1"
  walk_up "$bottom"
  for number in "${layers[@]}"; do
    all+="$(layer "$number")"$'\n'
  done
  # Du bas vers le haut : au-dessus d'une couche draft, tout est sauté.
  j -s --arg trunk "$trunk" '
    def with_skipped($above_draft):
      (if .draft then "draft" elif $above_draft then "above draft"
       elif .approval == "approved" then "approved" else null end) as $skipped
      | if $skipped then . + {skipped: $skipped} else . end;
    . as $layers
    | {trunk: $trunk,
       layers: [range(length) as $i | $layers[$i] | with_skipped(any($layers[:$i][]; .draft))]}' <<<"$all"
}

[ $# -eq 1 ] && [[ "$1" =~ ^[0-9]+$ ]] || usage
stack "$1"

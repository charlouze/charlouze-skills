#!/usr/bin/env bash
# Vérifie les liens de fermeture d'une pile finalisée : chaque couche ferme le
# ticket que nomme son corps, et la PR du sommet ferme la spec de changement
# quand la pile en couvre tous les tickets.
#
#   closing-links.sh <bottom PR> … <top PR>
#
# Sortie : une ligne par PR, une ligne pour la spec de changement, puis une
# dernière ligne, l'une de :
#   linked
#   unlinked: #<PR> …
# Code : 0 tout est lié, 1 sinon, 2 usage.
#
# Un `Closes #<ticket>` écrit avant `gh stack link` n'a pas été lu par GitHub :
# le script retire la ligne du corps, puis la remet, et GitHub la lit alors.
# Une PR dont le corps ne nomme aucun ticket est dite `no ticket` : c'est à
# l'appelant de demander lequel elle ferme.
#
# Le script n'a pas d'identité à lui : ses `git` et `gh` agissent sous celle de
# l'environnement qui le lance. Lancé par un wrapper d'identité, ils prennent
# son jeton et son auteur ; sinon, ceux de l'humain.
#
# Demande bash et gh.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: closing-links.sh <bottom PR> … <top PR>" >&2
  exit 2
fi
prs=("$@")
top=${prs[-1]}

keyword='(close[sd]?|fix(e[sd])?|resolve[sd]?) #[0-9]+'

body() { gh pr view "$1" --json body --jq .body; }
links() { gh pr view "$1" --json closingIssuesReferences --jq '.closingIssuesReferences[].number'; }
named() { grep -ioE "\b$keyword" <<<"$1" | grep -oE '[0-9]+' | sort -nu || true; }
set_body() { gh pr edit "$1" --body-file - >/dev/null <<<"$2"; }

unlinked=()
tickets=()
for pr in "${prs[@]}"; do
  text=$(body "$pr")
  wanted=$(named "$text")
  if [ -z "$wanted" ]; then
    echo "#$pr: no ticket"
    unlinked+=("#$pr")
    continue
  fi
  missing=$(comm -23 <(echo "$wanted") <(links "$pr" | sort -nu))
  if [ -n "$missing" ]; then
    # GitHub ne lit un mot-clé qu'à l'écriture du corps : on l'écrit à nouveau.
    set_body "$pr" "$(grep -viE "^\s*$keyword\s*$" <<<"$text" || true)"
    set_body "$pr" "$text"
    missing=$(comm -23 <(echo "$wanted") <(links "$pr" | sort -nu))
  fi
  if [ -n "$missing" ]; then
    echo "#$pr: unlinked from $(sed 's/^/#/' <<<"$missing" | paste -sd ' ' -)"
    unlinked+=("#$pr")
  else
    echo "#$pr: closes $(sed 's/^/#/' <<<"$wanted" | paste -sd ' ' -)"
    tickets+=($wanted)
  fi
done

# La spec de changement : le parent commun des tickets de la pile.
parents=$(for ticket in "${tickets[@]}"; do
  gh api graphql -F number="$ticket" -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) { issue(number: $number) { parent { number } } }
    }' -F owner='{owner}' -F repo='{repo}' --jq '.data.repository.issue.parent.number // empty'
done | sort -nu)

if [ -z "$parents" ]; then
  echo "change spec: none"
elif [ "$(wc -l <<<"$parents")" -gt 1 ]; then
  echo "change spec: several, $(sed 's/^/#/' <<<"$parents" | paste -sd ' ' -)"
else
  spec=$parents
  waiting=$(gh api --paginate "repos/{owner}/{repo}/issues/$spec/sub_issues" \
    --jq '.[] | select(.state == "open") | .number' | sort -nu \
    | comm -23 - <(printf '%s\n' "${tickets[@]}" | sort -nu))
  if [ -n "$waiting" ]; then
    echo "change spec #$spec: waits for $(sed 's/^/#/' <<<"$waiting" | paste -sd ' ' -)"
  else
    if ! links "$top" | grep -qx "$spec"; then
      set_body "$top" "$(body "$top")

Closes #$spec"
    fi
    if links "$top" | grep -qx "$spec"; then
      echo "change spec #$spec: closed by #$top"
    else
      echo "change spec #$spec: unlinked from #$top"
      unlinked+=("#$top")
    fi
  fi
fi

if [ ${#unlinked[@]} -gt 0 ]; then
  echo "unlinked: ${unlinked[*]}"
  exit 1
fi
echo "linked"

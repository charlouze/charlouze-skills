#!/usr/bin/env bats
# Tests du script qui vérifie les liens de fermeture d'une pile finalisée.
# Chaque test prépare dans son dossier temporaire un monde JSON que sert un `gh`
# simulé, placé en tête du PATH : ni GitHub, ni réseau, ni modèle.
#
#   bats skills/finalize-stack/scripts/closing-links.bats

bats_require_minimum_version 1.5.0

source "$BATS_TEST_DIRNAME/../../../scripts/fake-gh/helpers.bash"

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/closing-links.sh"
  fake_gh_setup
}

# Un ticket, ouvert par défaut, sous une spec de changement s'il en a une.
issue() { # numéro [parent] [état]
  world '.issues += [{number: $n, parent: $parent, state: $state}]' \
    --argjson n "$1" --argjson parent "${2:-null}" --arg state "${3:-open}"
}

# Une PR, son corps et les tickets que GitHub y a lus, qui peuvent être périmés.
pr() { # numéro corps liens
  world '.prs += [{number: $n, body: $body, closingIssuesReferences: ($links | map({number: .}))}]' \
    --argjson n "$1" --arg body "$2" --argjson links "$3"
}

body_of() { j -r --argjson n "$1" '.prs[] | select(.number == $n) | .body' "$FAKE_GH_WORLD"; }
links_of() { j -c --argjson n "$1" '[.prs[] | select(.number == $n) | .closingIssuesReferences[].number]' "$FAKE_GH_WORLD"; }

# Lance le script par `run` : sa sortie va dans $output, son code dans $status.
links() { run bash "$SCRIPT" "$@"; }

@test "without a PR, the script prints its usage and exits 2" {
  links
  assert_eq 2 "$status" "status"
  assert_eq "usage: closing-links.sh <bottom PR> … <top PR>" "$output" "output"
}

@test "a stack whose layers and top already close their tickets and change spec is linked, bodies untouched" {
  issue 10
  issue 11 10
  issue 12 10
  pr 1 $'Adds a\n\nCloses #11' '[11]'
  pr 2 $'Adds b\n\nCloses #12\n\nCloses #10' '[12, 10]'

  links 1 2
  assert_eq 0 "$status" "status"
  assert_eq $'#1: closes #11\n#2: closes #10 #12\nchange spec #10: closed by #2\nlinked' "$output" "output"
  assert_eq $'Adds b\n\nCloses #12\n\nCloses #10' "$(body_of 2)" "top body"
}

@test "a PR whose body names no ticket is unlinked" {
  issue 11
  pr 1 $'Adds a\n\nCloses #11' '[11]'
  pr 2 'Adds b' '[]'

  links 1 2
  assert_eq 1 "$status" "status"
  assert_eq $'#1: closes #11\n#2: no ticket\nchange spec: none\nunlinked: #2' "$output" "output"
}

@test "a Closes line GitHub has not read is rewritten, and GitHub then reads it" {
  issue 11
  pr 1 $'Adds a\n\nCloses #11' '[]'

  links 1
  assert_eq 0 "$status" "status"
  assert_eq $'#1: closes #11\nchange spec: none\nlinked' "$output" "output"
  assert_eq '[11]' "$(links_of 1)" "links"
  assert_eq $'Adds a\n\nCloses #11' "$(body_of 1)" "body"
}

@test "a Closes line GitHub still refuses after the rewrite is unlinked" {
  issue 11
  pr 1 $'Adds a\n\nCloses #11' '[11]'
  pr 2 $'Adds b\n\nCloses #99' '[]'

  links 1 2
  assert_eq 1 "$status" "status"
  assert_eq $'#1: closes #11\n#2: unlinked from #99\nchange spec: none\nunlinked: #2' "$output" "output"
}

@test "tickets without a parent give no change spec" {
  issue 11
  issue 12
  pr 1 'Closes #11' '[11]'
  pr 2 'Closes #12' '[12]'

  links 1 2
  assert_eq 0 "$status" "status"
  assert_eq "change spec: none" "$(sed -n 3p <<<"$output")" "change spec line"
}

@test "tickets under different parents give several change specs, and close none" {
  issue 11 10
  issue 21 20
  pr 1 'Closes #11' '[11]'
  pr 2 'Closes #21' '[21]'

  links 1 2
  assert_eq 0 "$status" "status"
  assert_eq "change spec: several, #10 #20" "$(sed -n 3p <<<"$output")" "change spec line"
  assert_eq 'Closes #21' "$(body_of 2)" "top body"
}

@test "a change spec with open sub-issues outside the stack waits for them, and the top does not close it" {
  issue 11 10
  issue 12 10
  issue 13 10
  issue 14 10 closed
  pr 1 'Closes #11' '[11]'
  pr 2 'Closes #12' '[12]'

  links 1 2
  assert_eq 0 "$status" "status"
  assert_eq "change spec #10: waits for #13" "$(sed -n 3p <<<"$output")" "change spec line"
  assert_eq '[12]' "$(links_of 2)" "top links"
}

@test "a change spec whose sub-issues the stack all covers is closed by the top, its body gaining Closes" {
  issue 11 10
  issue 12 10
  issue 13 10 closed
  issue 10
  pr 1 'Closes #11' '[11]'
  pr 2 $'Adds b\n\nCloses #12' '[12]'

  links 1 2
  assert_eq 0 "$status" "status"
  assert_eq $'#1: closes #11\n#2: closes #12\nchange spec #10: closed by #2\nlinked' "$output" "output"
  assert_eq $'Adds b\n\nCloses #12\n\nCloses #10' "$(body_of 2)" "top body"
  assert_eq '[10,12]' "$(links_of 2)" "top links"
}

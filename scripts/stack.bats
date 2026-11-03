#!/usr/bin/env bats
# Tests du script qui lit la pile. Chaque test prépare dans son dossier
# temporaire un monde JSON que sert un `gh` simulé, placé en tête du PATH : ni
# GitHub, ni réseau, ni modèle.
#
#   bats scripts/stack.bats

bats_require_minimum_version 1.5.0

source "$BATS_TEST_DIRNAME/fake-gh/helpers.bash"

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/stack.sh"
  fake_gh_setup
}

# Une PR ouverte, sans revue ni échange, titrée d'après sa tête.
pr() { # numéro tête base
  world '.prs += [{
    number: $n, id: ("PR_" + ($n | tostring)), state: "OPEN", isDraft: false,
    title: ("Title of " + $head), author: {login: "app/charlouze-dev-agent"},
    headRefName: $head, baseRefName: $base, reviewDecision: "", latestReviews: [],
    threads: [], reviews: [], comments: []
  }]' --argjson n "$1" --arg head "$2" --arg base "$3"
}

# Lance le script par `run` : sa sortie va dans $output, son code dans $status.
stack() { run bash "$SCRIPT" "$@"; }

out() { j -c "$@" <<<"$output"; }

@test "stack reads the stack bottom to top from any of its PRs, with each layer's title, head and base" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-b
  pr 9 other main

  for start in 1 2 3; do
    stack "$start"
    assert_eq 0 "$status" "status from #$start"
    assert_eq '"main"' "$(out .trunk)" "trunk from #$start"
    assert_eq '[1,2,3]' "$(out '[.layers[].number]')" "layers from #$start"
  done
  assert_eq '[["Title of layer-a","layer-a","main"],["Title of layer-b","layer-b","layer-a"],["Title of layer-c","layer-c","layer-b"]]' \
    "$(out '[.layers[] | [.title, .head, .base]]')" "titles, heads and bases"
}

@test "each layer gives its approval, by its review decision or, when empty, by its latest reviews" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-b
  pr 4 layer-d layer-c
  pr 5 layer-e layer-d
  pr 6 layer-f layer-e
  pr 7 layer-g layer-f
  set_pr 1 '.reviewDecision = "APPROVED"'
  set_pr 2 '.reviewDecision = "CHANGES_REQUESTED"'
  set_pr 3 '.reviewDecision = "REVIEW_REQUIRED"'
  latest_review 4 alice APPROVED
  latest_review 5 alice APPROVED
  latest_review 5 bob CHANGES_REQUESTED
  latest_review 6 alice COMMENTED
  # Une décision de revue l'emporte sur les dernières revues.
  set_pr 7 '.reviewDecision = "REVIEW_REQUIRED"'
  latest_review 7 alice APPROVED

  stack 1
  assert_eq 0 "$status" "status"
  assert_eq '["approved","changes requested","none","approved","changes requested","none","none"]' \
    "$(out '[.layers[].approval]')" "approvals"
}

@test "each layer says whether it is a draft, and keeps its own approval, above a draft too" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-b
  set_pr 2 '.isDraft = true | .reviewDecision = "APPROVED"'
  set_pr 3 '.reviewDecision = "APPROVED"'

  stack 1
  assert_eq 0 "$status" "status"
  assert_eq '[[false,"none"],[true,"approved"],[false,"approved"]]' \
    "$(out '[.layers[] | [.draft, .approval]]')" "drafts and approvals"
}

@test "a stack that forks fails with code 3, naming both PRs, with nothing on its output" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-a

  run --separate-stderr bash "$SCRIPT" 2
  assert_eq 3 "$status" "status"
  assert_eq "" "$output" "output"
  [[ "$stderr" == *"#2"*"#3"* ]] || { echo "both PRs not named: $stderr"; return 1; }
}

@test "stack reads no exchange: no thread, review body or PR comment" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  # Chaque lecture d'échanges échoue tour à tour : par GraphQL (fils, revues,
  # commentaires), ou par les champs `reviews` et `comments` de `gh pr view`.
  # `latestReviews`, qui porte l'approbation, n'en est pas un.
  for reading in graphql reviews comments; do
    export FAKE_GH_FAIL=$reading
    stack 1
    assert_eq 0 "$status" "status with $reading failing"
    assert_eq '[1,2]' "$(out '[.layers[].number]')" "layers with $reading failing"
  done
}

@test "a failure of gh fails with code 1, whatever gh's own code, and gives no partial stack" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-b
  export FAKE_GH_FAIL="view 3 --json number" FAKE_GH_FAIL_CODE=4

  run --separate-stderr bash "$SCRIPT" 1
  assert_eq 1 "$status" "status"
  assert_eq "" "$output" "output"
}

@test "a wrong usage fails with code 2" {
  for args in "" "abc" "1 2"; do
    # shellcheck disable=SC2086
    stack $args
    assert_eq 2 "$status" "status for \"$args\""
  done
}

#!/usr/bin/env bats
# Tests du script de la reprise. Chaque test prépare dans son dossier temporaire
# un monde JSON que sert un `gh` simulé, placé en tête du PATH, qui garde ce
# qu'on lui poste : ni GitHub, ni réseau, ni modèle.
#
#   bats skills/rework-stack/scripts/rework-stack.bats

source "$BATS_TEST_DIRNAME/../../../scripts/fake-gh/helpers.bash"

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/rework-stack.sh"
  fake_gh_setup
}

# Une PR ouverte par l'agent, sans revue ni échange. `gh pr view` donne le
# login d'une app préfixé de `app/`.
pr() { # numéro tête base
  world '.prs += [{
    number: $n, id: ("PR_" + ($n | tostring)), state: "OPEN", isDraft: false,
    author: {login: "app/charlouze-dev-agent"},
    headRefName: $head, baseRefName: $base, reviewDecision: "", latestReviews: [],
    threads: [], reviews: [], comments: []
  }]' --argjson n "$1" --arg head "$2" --arg base "$3"
}

# Un fil de revue sur a.txt, ligne 7 ; ses messages sont donnés « auteur:corps ».
thread() { # numéro id résolu message…
  local n=$1 id=$2 resolved=$3 message i=0
  shift 3
  world '(.prs[] | select(.number == $n) | .threads) += [{id: $id, isResolved: $resolved, path: "a.txt", line: 7, originalLine: 7, comments: []}]' \
    --argjson n "$n" --arg id "$id" --argjson resolved "$resolved"
  for message in "$@"; do
    i=$((i + 1))
    world '(.prs[].threads[] | select(.id == $id) | .comments) += [{author: {login: $who}, body: $body, url: ("https://github.com/o/r/pull/" + $n + "#discussion_" + $id + "_" + $i), createdAt: ("2026-01-01T00:00:0" + $i + "Z")}]' \
      --arg n "$n" --arg id "$id" --arg i "$i" --arg who "${message%%:*}" --arg body "${message#*:}"
  done
}

review() { # numéro id auteur corps date [état]
  world '(.prs[] | select(.number == $n) | .reviews) += [{id: $id, author: {login: $who}, body: $body, state: $state, url: ("https://github.com/o/r/pull/" + ($n | tostring) + "#" + $id), submittedAt: $at}]' \
    --argjson n "$1" --arg id "$2" --arg who "$3" --arg body "$4" --arg at "$5" --arg state "${6:-COMMENTED}"
}

comment() { # numéro id auteur corps date
  world '(.prs[] | select(.number == $n) | .comments) += [{id: $id, author: {login: $who}, body: $body, url: ("https://github.com/o/r/pull/" + ($n | tostring) + "#" + $id), createdAt: $at}]' \
    --argjson n "$1" --arg id "$2" --arg who "$3" --arg body "$4" --arg at "$5"
}

# Lance le script par `run` : sa sortie va dans $output, son code dans $status.
rework() { run bash "$SCRIPT" "$@"; }

# Lit la sortie JSON de `pending`.
out() { j -c "$@" <<<"$output"; }

# Les identifiants des éléments en attente, une couche par ligne.
pending_ids() { out -r '.layers[] | [.number, (.pending // [] | map(.id) | join(" "))] | join(": ")'; }

posted() { j -c "$@" "$FAKE_GH_LOG"; }

@test "pending reads the stack bottom to top from any of its PRs" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-b
  pr 9 other main

  for start in 1 2 3; do
    rework pending "$start"
    assert_eq 0 "$status" "status from #$start"
    assert_eq '"main"' "$(out .trunk)" "trunk from #$start"
    assert_eq '[1,2,3]' "$(out '[.layers[].number]')" "layers from #$start"
  done
  assert_eq '[["layer-a","main"],["layer-b","layer-a"],["layer-c","layer-b"]]' \
    "$(out '[.layers[] | [.head, .base]]')" "heads and bases"
}

@test "a single PR is a stack of one layer" {
  pr 4 alone main

  rework pending 4
  assert_eq 0 "$status" "status"
  assert_eq '{"trunk":"main","layers":[4]}' "$(out -c '{trunk, layers: [.layers[].number]}')" "stack"
}

@test "a stack that forks fails with code 3, naming both PRs" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-a

  rework pending 2
  assert_eq 3 "$status" "status"
  [[ "$output" == *"#2"*"#3"* ]] || { echo "both PRs not named: $output"; return 1; }
}

@test "an unresolved thread whose last message comes from a human is pending, with all its messages" {
  pr 1 layer-a main
  thread 1 T1 false "alice:Rename this" "charlouze-dev-agent:🤖 Done" "alice:Not quite"

  rework pending 1
  assert_eq 0 "$status" "status"
  assert_eq '[{"kind":"thread","id":"T1","url":"https://github.com/o/r/pull/1#discussion_T1_1","path":"a.txt","line":7,"messages":[{"author":"alice","body":"Rename this"},{"author":"charlouze-dev-agent","body":"🤖 Done"},{"author":"alice","body":"Not quite"}]}]' \
    "$(out '.layers[0].pending')" "pending"
}

@test "a thread whose last message starts with the mark is not pending, whoever posted it, nor a resolved thread" {
  pr 1 layer-a main
  thread 1 T1 false "alice:Rename this" "charlouze-dev-agent:🤖 Done"
  thread 1 T2 false "alice:Rename that" "alice:🤖 Done"
  thread 1 T3 true "alice:And this"
  thread 1 T4 false "alice:Why?"
  # Le login de l'agent ne compte pas : seule la marque fait son message.
  thread 1 T5 false "alice:Rename those" "charlouze-dev-agent:Done"
  thread 1 T6 false "alice:Rename these" "alice:Done 🤖"

  rework pending 1
  assert_eq 0 "$status" "status"
  assert_eq "1: T4 T5 T6" "$(pending_ids)" "pending"
}

@test "a review body or a PR comment is pending until a PR comment of the agent's answers it, by its link" {
  pr 1 layer-a main
  review 1 R1 alice "Overall, split this" 2026-01-01T00:00:01Z
  comment 1 C1 bob "And the README?" 2026-01-01T00:00:02Z
  comment 1 C10 bob "And the docs?" 2026-01-01T00:00:03Z
  comment 1 A1 charlouze-dev-agent $'🤖 https://github.com/o/r/pull/1#R1\n\n> Overall, split this\n\nSplit.' 2026-01-01T00:00:04Z
  # Une réponse à C10 ne répond pas à C1, dont le lien commence le sien.
  comment 1 A2 charlouze-dev-agent $'🤖 https://github.com/o/r/pull/1#C10\n\n> And the docs?\n\nUpdated.' 2026-01-01T00:00:05Z
  # Un commentaire de l'agent qui ne répond à aucun élément ne répond à rien.
  comment 1 A3 charlouze-dev-agent "🤖 Corrected for #3 by abc123." 2026-01-01T00:00:06Z
  review 1 R2 alice "One more thing" 2026-01-01T00:00:07Z CHANGES_REQUESTED
  # Un lien sans la marque n'est pas une réponse de l'agent.
  comment 1 C2 bob $'https://github.com/o/r/pull/1#R2\n\nSame here' 2026-01-01T00:00:08Z
  review 1 R3 alice "" 2026-01-01T00:00:09Z
  review 1 R4 alice "  " 2026-01-01T00:00:10Z APPROVED
  # Une revue en cours, que seul son auteur voit, n'a pas été postée.
  review 1 R6 alice "Not submitted yet" 2026-01-01T00:00:11Z PENDING

  rework pending 1
  assert_eq 0 "$status" "status"
  assert_eq "1: R2 C1 C2" "$(pending_ids)" "pending"
  assert_eq '[{"kind":"review","id":"R2","url":"https://github.com/o/r/pull/1#R2","messages":[{"author":"alice","body":"One more thing"}]},{"kind":"comment","id":"C1","url":"https://github.com/o/r/pull/1#C1","messages":[{"author":"bob","body":"And the README?"}]}]' \
    "$(out '.layers[0].pending[0:2]')" "elements"
}

@test "a review body or a PR comment that starts with the mark is the agent's, whoever posted it" {
  pr 1 layer-a main
  comment 1 C1 alice "🤖 Done" 2026-01-01T00:00:01Z
  review 1 R1 charlouze-dev-agent "🤖 Points of attention" 2026-01-01T00:00:02Z
  review 1 R2 charlouze-dev-agent "Points of attention" 2026-01-01T00:00:03Z
  comment 1 C2 bob "Thanks 🤖" 2026-01-01T00:00:04Z

  rework pending 1
  assert_eq 0 "$status" "status"
  assert_eq "1: R2 C2" "$(pending_ids)" "pending"
}

@test "an approved layer is skipped, by its review decision or, when empty, by its latest reviews" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-b
  pr 4 layer-d layer-c
  set_pr 1 '.reviewDecision = "APPROVED"'
  latest_review 2 alice APPROVED
  latest_review 3 alice APPROVED
  latest_review 3 bob CHANGES_REQUESTED
  set_pr 4 '.reviewDecision = "REVIEW_REQUIRED"'
  latest_review 4 alice APPROVED
  for n in 1 2 3 4; do comment "$n" "C$n" carol "Look" 2026-01-01T00:00:01Z; done

  rework pending 1
  assert_eq 0 "$status" "status"
  assert_eq '[[1,"approved",null],[2,"approved",null],[3,null,["C3"]],[4,null,["C4"]]]' \
    "$(out '[.layers[] | [.number, .skipped, (.pending // null | if . then map(.id) else . end)]]')" "layers"
}

@test "a draft layer and every layer above it are skipped" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-b
  set_pr 2 '.isDraft = true'
  set_pr 3 '.reviewDecision = "APPROVED"'
  for n in 1 2 3; do comment "$n" "C$n" carol "Look" 2026-01-01T00:00:01Z; done

  rework pending 1
  assert_eq 0 "$status" "status"
  assert_eq '[[1,null],[2,"draft"],[3,"above draft"]]' "$(out '[.layers[] | [.number, .skipped]]')" "layers"
  assert_eq '["C1"]' "$(out '.layers[0].pending | map(.id)')" "pending"
}

@test "each layer gives its past reviewers, the PR's author left out, whatever the form of their login" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  set_pr 1 '.reviewDecision = "CHANGES_REQUESTED"'
  latest_review 1 alice CHANGES_REQUESTED
  latest_review 1 bob COMMENTED
  latest_review 1 charlouze-dev-agent COMMENTED
  latest_review 1 'charlouze-dev-agent[bot]' COMMENTED
  set_pr 2 '.author = {login: "alice"}'
  latest_review 2 alice COMMENTED
  latest_review 2 charlouze-dev-agent COMMENTED

  rework pending 1
  assert_eq 0 "$status" "status"
  assert_eq '[["alice","bob"],["charlouze-dev-agent"]]' "$(out '[.layers[].reviewers]')" "reviewers"
}

@test "everything is read across pages: threads, their messages, review bodies and PR comments" {
  export FAKE_GH_PAGE_SIZE=2
  pr 1 layer-a main
  thread 1 T1 false "alice:One"
  thread 1 T2 false "alice:Two"
  thread 1 T3 false "alice:Three" "bob:Indeed" "alice:Four"
  # Le dernier message, sur la seconde page du fil, vient de l'agent.
  thread 1 T4 false "alice:Five" "bob:Indeed" "charlouze-dev-agent:🤖 Done"
  review 1 R1 alice "First" 2026-01-01T00:00:01Z
  review 1 R2 alice "Second" 2026-01-01T00:00:02Z
  review 1 R3 alice "Third" 2026-01-01T00:00:03Z
  comment 1 C1 bob "First" 2026-01-01T00:00:01Z
  comment 1 C2 bob "Second" 2026-01-01T00:00:02Z
  comment 1 C3 bob "Third" 2026-01-01T00:00:03Z

  rework pending 1
  assert_eq 0 "$status" "status"
  assert_eq "1: T1 T2 T3 R1 R2 R3 C1 C2 C3" "$(pending_ids)" "pending"
  assert_eq '["Three","Indeed","Four"]' "$(out '.layers[0].pending[2].messages | map(.body)')" "messages of T3"
}

@test "an outdated thread gives its original line" {
  pr 1 layer-a main
  thread 1 T1 false "alice:Rename this"
  world '(.prs[].threads[] | select(.id == "T1")) |= (.line = null | .originalLine = 4)'

  rework pending 1
  assert_eq 0 "$status" "status"
  assert_eq '["a.txt",4]' "$(out '.layers[0].pending[0] | [.path, .line]')" "path and line"
}

@test "reply answers a thread in the thread, starting with the mark" {
  pr 1 layer-a main
  thread 1 T1 false "alice:Rename this"

  rework reply T1 "Renamed, in a fixup! of abc123."
  assert_eq 0 "$status" "status"
  assert_eq '[{"on":"thread","id":"T1","body":"🤖 Renamed, in a fixup! of abc123."}]' "$(posted -s .)" "posted"
}

@test "reply answers a review body or a PR comment by a PR comment that quotes it, starting with the mark" {
  pr 1 layer-a main
  review 1 R1 alice $'Split this.\nAnd test it.' 2026-01-01T00:00:01Z
  comment 1 C1 bob "And the README?" 2026-01-01T00:00:02Z

  rework reply R1 "Split, in two commits."
  assert_eq 0 "$status" "status of the review's reply"
  rework reply C1 "Updated."
  assert_eq 0 "$status" "status of the comment's reply"

  assert_eq "$(printf '%s\n' \
    '{"on":"pr","id":"PR_1","body":"🤖 https://github.com/o/r/pull/1#R1\n\n> Split this.\n> And test it.\n\nSplit, in two commits."}' \
    '{"on":"pr","id":"PR_1","body":"🤖 https://github.com/o/r/pull/1#C1\n\n> And the README?\n\nUpdated."}')" \
    "$(posted .)" "posted"
}

@test "an element answered by reply is no longer pending, under any identity, and the others still are" {
  for user in charlouze-dev-agent alice; do
    echo '{"prs": []}' >"$FAKE_GH_WORLD"
    : >"$FAKE_GH_LOG"
    export FAKE_GH_USER=$user
    pr 1 layer-a main
    thread 1 T1 false "alice:Rename this"
    review 1 R1 alice "Split this" 2026-01-01T00:00:01Z
    comment 1 C1 alice "And the README?" 2026-01-01T00:00:02Z
    comment 1 C2 alice "And the docs?" 2026-01-01T00:00:03Z

    # Une reprise arrêtée après deux réponses : les autres restent en attente.
    rework reply T1 "Renamed."
    assert_eq 0 "$status" "status of the thread's reply as $user"
    rework reply C1 "Updated."
    assert_eq 0 "$status" "status of the comment's reply as $user"

    rework pending 1
    assert_eq 0 "$status" "status of pending as $user"
    assert_eq "1: R1 C2" "$(pending_ids)" "pending as $user"
  done
}

@test "reply takes a body that starts with dashes" {
  pr 1 layer-a main
  thread 1 T1 false "alice:Rename this"

  rework reply T1 "--- a rule, then text"
  assert_eq 0 "$status" "status of a body that starts with dashes"
  rework reply T1 "--login"
  assert_eq 0 "$status" "status of a body that looks like an option"
  assert_eq '["🤖 --- a rule, then text","🤖 --login"]' "$(posted -s 'map(.body)')" "posted"
}

@test "reply to an id that is no element fails with code 2, posting nothing" {
  pr 1 layer-a main

  rework reply PR_1 "Renamed."
  assert_eq 2 "$status" "status"
  assert_eq "" "$(posted .)" "posted"
}

@test "comment posts a PR comment of the agent's, marked, which answers nothing" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  comment 2 C1 alice "And the README?" 2026-01-01T00:00:01Z

  rework comment 2 "Corrected for #3 by abc123."
  assert_eq 0 "$status" "status"
  assert_eq "https://github.com/o/r/posted/1" "$output" "link of the comment"
  assert_eq '[{"on":"pr","id":"PR_2","body":"🤖 Corrected for #3 by abc123."}]' "$(posted -s .)" "posted"

  rework pending 2
  assert_eq 0 "$status" "status of pending"
  assert_eq "C1" "$(out -r '.layers[] | select(.number == 2) | .pending | map(.id) | join(" ")')" "pending on #2"
}

@test "a failure of gh fails with code 1, whatever gh's own code, and gives no partial stack" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  thread 1 T1 false "alice:Rename this"

  export FAKE_GH_FAIL="number=2" FAKE_GH_FAIL_CODE=4
  rework pending 1
  assert_eq 1 "$status" "status of pending"
  [[ "$output" == *"simulated failure"* ]] || { echo "not a failure of gh: $output"; return 1; }
  [[ "$output" != *trunk* ]] || { echo "partial stack given: $output"; return 1; }

  export FAKE_GH_FAIL=ReplyInThread FAKE_GH_FAIL_CODE=2
  rework reply T1 "Renamed."
  assert_eq 1 "$status" "status of reply"
  [[ "$output" == *"simulated failure"* ]] || { echo "not a failure of gh: $output"; return 1; }

  export FAKE_GH_FAIL=CommentOnPr FAKE_GH_FAIL_CODE=2
  rework comment 1 "Corrected."
  assert_eq 1 "$status" "status of comment"
  [[ "$output" == *"simulated failure"* ]] || { echo "not a failure of gh: $output"; return 1; }
  assert_eq "" "$(posted .)" "posted"
}

@test "a wrong usage fails with code 2" {
  pr 1 layer-a main
  for usage in "" "merge 1" "pending" "pending one" "pending 1 2" "pending --login 1" "pending --verbose 1" \
    "reply T1" "reply T1 ''" "reply T1 body extra" \
    "comment 1" "comment one body" "comment 1 ''" "comment 1 body extra"; do
    eval "rework $usage"
    assert_eq 2 "$status" "status of \"$usage\""
  done
  assert_eq "" "$(posted .)" "posted"
}

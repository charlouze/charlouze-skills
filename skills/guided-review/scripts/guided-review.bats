#!/usr/bin/env bats
# Tests du script de la revue guidée. Chaque test prépare dans son dossier
# temporaire un monde JSON que sert un `gh` simulé, placé en tête du PATH, qui
# garde ce qu'on lui poste : ni GitHub, ni réseau, ni modèle.
#
#   bats skills/guided-review/scripts/guided-review.bats

source "$BATS_TEST_DIRNAME/../../../scripts/fake-gh/helpers.bash"

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/guided-review.sh"
  fake_gh_setup
}

# Une PR ouverte par l'agent, sans revue ni échange. `gh pr view` donne le
# login d'une app préfixé de `app/`.
pr() { # numéro tête base
  world '.prs += [{
    number: $n, id: ("PR_" + ($n | tostring)), state: "OPEN", isDraft: false,
    title: ("Title of " + $head), author: {login: "app/charlouze-dev-agent"},
    headRefName: $head, baseRefName: $base, reviewDecision: "", latestReviews: [],
    body: "", threads: [], reviews: [], comments: []
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

# Lance le script par `run` : sa sortie va dans $output, son code dans $status.
guided() { run bash "$SCRIPT" "$@"; }

out() { j -c "$@" <<<"$output"; }

posted() { j -c "$@" "$FAKE_GH_LOG"; }

# Les identifiants des fils à juger, une couche par ligne.
note_ids() { out -r '.layers[] | [.number, (.notes // [] | map(.id) | join(" "))] | join(": ")'; }

@test "notes reads the stack bottom to top from any of its PRs, with its skipped layers" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-b
  pr 4 layer-d layer-c
  set_pr 2 '.reviewDecision = "APPROVED"'
  set_pr 3 '.isDraft = true'

  for start in 1 2 4; do
    guided notes "$start"
    assert_eq 0 "$status" "status from #$start"
    assert_eq '"main"' "$(out .trunk)" "trunk from #$start"
    assert_eq '[[1,null],[2,"approved"],[3,"draft"],[4,"above draft"]]' \
      "$(out '[.layers[] | [.number, .skipped]]')" "layers from #$start"
  done
  assert_eq '{"number":1,"title":"Title of layer-a","head":"layer-a","base":"main","author":"app/charlouze-dev-agent","source":"threads","notes":[]}' \
    "$(out '.layers[0]')" "layer to review"
  assert_eq '{"number":2,"title":"Title of layer-b","head":"layer-b","base":"layer-a","author":"app/charlouze-dev-agent","skipped":"approved"}' \
    "$(out '.layers[1]')" "skipped layer"
}

@test "a stack that forks fails with code 3, naming both PRs" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  pr 3 layer-c layer-a

  guided notes 2
  assert_eq 3 "$status" "status"
  [[ "$output" == *"#2"*"#3"* ]] || { echo "both PRs not named: $output"; return 1; }
}

@test "gh never sees GH_TOKEN nor GITHUB_TOKEN, even set at launch" {
  pr 1 layer-a main
  thread 1 T1 false "charlouze-dev-agent:🤖 1/1 A point"
  echo '{"event": "COMMENT", "body": "Seen.", "resolve": ["T1"]}' >"$BATS_TEST_TMPDIR/submission.json"

  GH_TOKEN=agent-token GITHUB_TOKEN=agent-token guided notes 1
  assert_eq 0 "$status" "status of notes"
  GH_TOKEN=agent-token GITHUB_TOKEN=agent-token guided submit 1 "$BATS_TEST_TMPDIR/submission.json"
  assert_eq 0 "$status" "status of submit"
  assert_eq "" "$(cat "$FAKE_GH_TOKENS")" "tokens seen by gh"
}

@test "an identity that is not a user fails with code 4, posting nothing" {
  pr 1 layer-a main
  thread 1 T1 false "charlouze-dev-agent:🤖 1/1 A point"
  echo '{"event": "COMMENT", "body": "Seen.", "resolve": ["T1"]}' >"$BATS_TEST_TMPDIR/submission.json"

  export FAKE_GH_USER_TYPE=Bot
  guided notes 1
  assert_eq 4 "$status" "status of notes as an app"
  [[ "$output" != *trunk* ]] || { echo "stack given: $output"; return 1; }
  guided submit 1 "$BATS_TEST_TMPDIR/submission.json"
  assert_eq 4 "$status" "status of submit as an app"

  unset FAKE_GH_USER_TYPE
  export FAKE_GH_FAIL="api user"
  guided notes 1
  assert_eq 4 "$status" "status of notes when api user is refused"
  guided submit 1 "$BATS_TEST_TMPDIR/submission.json"
  assert_eq 4 "$status" "status of submit when api user is refused"
  assert_eq "" "$(posted .)" "posted"
}

@test "the threads to judge are the unresolved threads whose last message starts with the mark" {
  pr 1 layer-a main
  thread 1 T1 false "charlouze-dev-agent:🤖 1/2 Fragile parsing"
  thread 1 T2 false "alice:Rename this" "charlouze-dev-agent:🤖 Renamed."
  # Un fil où l'humain a répondu en dernier attend la reprise, pas la revue guidée.
  thread 1 T3 false "charlouze-dev-agent:🤖 2/2 Odd name" "alice:Rename it"
  thread 1 T4 true "charlouze-dev-agent:🤖 3/3 Resolved already"
  thread 1 T5 false "alice:Why?"
  # Seule la marque compte, sous quelque identité que le message soit posté.
  thread 1 T6 false "alice:🤖 Point posted under the human's name"

  guided notes 1
  assert_eq 0 "$status" "status"
  assert_eq "1: T1 T6 T2" "$(note_ids)" "threads to judge"
  assert_eq '{"kind":"note","id":"T1","url":"https://github.com/o/r/pull/1#discussion_T1_1","path":"a.txt","line":7,"rank":1,"messages":[{"author":"charlouze-dev-agent","body":"🤖 1/2 Fragile parsing"}]}' \
    "$(out '.layers[0].notes[0]')" "a point of attention"
  assert_eq '{"kind":"note","id":"T6","url":"https://github.com/o/r/pull/1#discussion_T6_1","path":"a.txt","line":7,"messages":[{"author":"alice","body":"🤖 Point posted under the human'"'"'s name"}]}' \
    "$(out '.layers[0].notes[1]')" "a point of attention without its rank"
  assert_eq '{"kind":"answer","id":"T2","url":"https://github.com/o/r/pull/1#discussion_T2_1","path":"a.txt","line":7,"messages":[{"author":"alice","body":"Rename this"},{"author":"charlouze-dev-agent","body":"🤖 Renamed."}]}' \
    "$(out '.layers[0].notes[2]')" "an answer of a rework"
}

@test "the points of attention come by rank, those without one after, then the answers" {
  pr 1 layer-a main
  thread 1 T1 false "alice:Rename this" "charlouze-dev-agent:🤖 Renamed."
  thread 1 T2 false "charlouze-dev-agent:🤖 3/12 Third"
  thread 1 T3 false "charlouze-dev-agent:🤖 Unranked"
  thread 1 T4 false "charlouze-dev-agent:🤖 12/12 Twelfth"
  thread 1 T5 false "charlouze-dev-agent:🤖 1/12 First"

  guided notes 1
  assert_eq 0 "$status" "status"
  assert_eq "1: T5 T2 T4 T3 T1" "$(note_ids)" "order"
}

@test "a layer opened by the human holds its points of attention in its body, and gives only the answers" {
  pr 1 layer-a main
  set_pr 1 '.author = {login: "alice"}'
  thread 1 T1 false "charlouze-dev-agent:🤖 1/1 A point"
  thread 1 T2 false "alice:Rename this" "alice:🤖 Renamed."

  guided notes 1
  assert_eq 0 "$status" "status"
  assert_eq '"body"' "$(out '.layers[0].source')" "source"
  assert_eq "1: T2" "$(note_ids)" "threads to judge"
}

@test "an outdated thread gives its original line" {
  pr 1 layer-a main
  thread 1 T1 false "charlouze-dev-agent:🤖 1/1 A point"
  world '(.prs[].threads[] | select(.id == "T1")) |= (.line = null | .originalLine = 4)'

  guided notes 1
  assert_eq 0 "$status" "status"
  assert_eq '["a.txt",4]' "$(out '.layers[0].notes[0] | [.path, .line]')" "path and line"
}

@test "the threads and their messages are read across pages" {
  export FAKE_GH_PAGE_SIZE=2
  pr 1 layer-a main
  thread 1 T1 false "charlouze-dev-agent:🤖 1/3 One"
  thread 1 T2 false "charlouze-dev-agent:🤖 2/3 Two"
  # Le dernier message, sur la seconde page du fil, porte la marque.
  thread 1 T3 false "alice:Rename" "bob:Indeed" "charlouze-dev-agent:🤖 Renamed."
  # Le dernier message, sur la seconde page du fil, vient de l'humain.
  thread 1 T4 false "charlouze-dev-agent:🤖 3/3 Three" "charlouze-dev-agent:🤖 More" "alice:No"

  guided notes 1
  assert_eq 0 "$status" "status"
  assert_eq "1: T1 T2 T3" "$(note_ids)" "threads to judge"
  assert_eq '["Rename","Indeed","🤖 Renamed."]' "$(out '.layers[0].notes[2].messages | map(.body)')" "messages of T3"
}

# Le fichier de soumission d'une couche, donné en JSON.
submission() { # json
  echo "$1" >"$BATS_TEST_TMPDIR/submission.json"
}

submit() { guided submit "$1" "$BATS_TEST_TMPDIR/submission.json"; }

@test "submit creates the review, replies in its threads within it, then submits it with its event" {
  pr 1 layer-a main
  thread 1 T1 false "charlouze-dev-agent:🤖 1/2 Fragile parsing"
  thread 1 T2 false "alice:Rename this" "charlouze-dev-agent:🤖 Renamed."
  submission '{"event": "REQUEST_CHANGES", "body": "Two things to change.",
    "replies": [{"thread": "T1", "body": "Parse it with jq."}, {"thread": "T2", "body": "Not quite, rename it again."}]}'

  submit 1
  assert_eq 0 "$status" "status"
  assert_eq '{"review":"https://github.com/o/r/posted/1","event":"REQUEST_CHANGES","failed":[]}' "$(out .)" "output"
  assert_eq "$(printf '%s\n' \
    '{"on":"review","action":"create","pr":"PR_1","review":"PRR_posted_1"}' \
    '{"on":"thread","id":"T1","review":"PRR_posted_1","body":"Parse it with jq."}' \
    '{"on":"thread","id":"T2","review":"PRR_posted_1","body":"Not quite, rename it again."}' \
    '{"on":"review","action":"submit","review":"PRR_posted_1","event":"REQUEST_CHANGES","body":"Two things to change."}')" \
    "$(posted .)" "posted"
}

@test "submit resolves the threads accepted, after the review" {
  pr 1 layer-a main
  thread 1 T1 false "charlouze-dev-agent:🤖 1/2 Fragile parsing"
  thread 1 T2 false "charlouze-dev-agent:🤖 2/2 Odd name"
  submission '{"event": "COMMENT", "body": "Both fine.", "resolve": ["T1", "T2"]}'

  submit 1
  assert_eq 0 "$status" "status"
  assert_eq '["submit","T1","T2"]' "$(posted -s 'map(.action // .id) | .[1:]')" "posted"
  assert_eq '[true,true]' "$(j -c '[.prs[0].threads[].isResolved]' "$FAKE_GH_WORLD")" "resolved"
}

@test "submit checks the boxes named, rulings and checks alike, and changes nothing else of the body" {
  pr 1 layer-a main
  world '.prs[0].body = $body' --arg body $'Intro.\n\n## À trancher\n\n- [ ] Keep the cache\n- [ ] Keep the cache longer\n- [x] Already settled\n\n## Vérifications manuelles\n\n- [ ] Run the wizard\r\n- [ ] Open the page\n'
  submission '{"event": "COMMENT", "body": "Checked.", "checks": ["Keep the cache", "Run the wizard"]}'

  submit 1
  assert_eq 0 "$status" "status"
  # Hors d'une substitution `$(…)`, où le bash de Git pour Windows perd les CR.
  local expected=$'Intro.\n\n## À trancher\n\n- [x] Keep the cache\n- [ ] Keep the cache longer\n- [x] Already settled\n\n## Vérifications manuelles\n\n- [x] Run the wizard\r\n- [ ] Open the page\n'
  assert_eq "$(j -n --arg body "$expected" '$body')" "$(j '.prs[0].body' "$FAKE_GH_WORLD")" "body"
}

@test "submit falls back to COMMENT when the human is the PR's author" {
  for event in APPROVE REQUEST_CHANGES; do
    echo '{"prs": []}' >"$FAKE_GH_WORLD"
    : >"$FAKE_GH_LOG"
    pr 1 layer-a main
    set_pr 1 '.author = {login: "human"}'
    thread 1 T1 false "human:Rename this" "human:🤖 Renamed."
    submission '{"event": "'"$event"'", "body": "Seen."}'

    submit 1
    assert_eq 0 "$status" "status of $event"
    assert_eq '"COMMENT"' "$(out .event)" "event of $event"
    assert_eq '"COMMENT"' "$(posted -s '.[-1].event')" "event submitted for $event"
  done
}

@test "the human who is the PR's author may reply in threads with a COMMENT" {
  pr 1 layer-a main
  set_pr 1 '.author = {login: "human"}'
  thread 1 T1 false "human:Rename this" "human:🤖 Renamed."
  submission '{"event": "COMMENT", "body": "One thing.", "replies": [{"thread": "T1", "body": "Rename it again."}]}'

  submit 1
  assert_eq 0 "$status" "status"
  assert_eq '"Rename it again."' "$(posted -s '.[1].body')" "reply"
}

@test "submit refuses with code 5, posting nothing, each submission the spec forbids" {
  pr 1 layer-a main
  pr 2 layer-b layer-a
  world '.prs[0].body = "- [ ] Keep the cache\n- [x] Already settled"'
  thread 1 T1 false "charlouze-dev-agent:🤖 1/1 A point"
  thread 1 T2 false "alice:Why?"
  thread 1 T3 true "charlouze-dev-agent:🤖 2/2 Resolved"
  thread 2 T4 false "charlouze-dev-agent:🤖 1/1 Another layer's"
  local reply='"replies": [{"thread": "T1", "body": "Change it."}]'

  for refused in \
    '{"event": "COMMENT", "body": "🤖 Seen."}' \
    '{"event": "REQUEST_CHANGES", "body": "Seen.", "replies": [{"thread": "T1", "body": "🤖 Change it."}]}' \
    '{"event": "APPROVE", "body": "Fine.", '"$reply"'}' \
    '{"event": "COMMENT", "body": "Seen.", '"$reply"'}' \
    '{"event": "REQUEST_CHANGES", "body": "Seen.", "replies": [{"thread": "T2", "body": "Change it."}]}' \
    '{"event": "COMMENT", "body": "Seen.", "resolve": ["T3"]}' \
    '{"event": "COMMENT", "body": "Seen.", "resolve": ["T4"]}' \
    '{"event": "COMMENT", "body": "Seen.", "checks": ["Already settled"]}' \
    '{"event": "COMMENT", "body": "Seen.", "checks": ["Keep the"]}' \
    '{"event": "DISMISS", "body": "Seen."}' \
    'not json'; do
    submission "$refused"
    submit 1
    assert_eq 5 "$status" "status of $refused"
    [ -n "$output" ] || { echo "no reason given for $refused"; return 1; }
  done
  assert_eq "" "$(posted .)" "posted"
}

@test "an error before the submission deletes the pending review: nothing is half posted" {
  pr 1 layer-a main
  thread 1 T1 false "charlouze-dev-agent:🤖 1/2 Fragile parsing"
  thread 1 T2 false "charlouze-dev-agent:🤖 2/2 Odd name"
  submission '{"event": "REQUEST_CHANGES", "body": "Change both.",
    "replies": [{"thread": "T1", "body": "Parse it with jq."}, {"thread": "T2", "body": "Rename it."}]}'

  for failing in ReplyInReview SubmitReview; do
    export FAKE_GH_FAIL=$failing
    submit 1
    assert_eq 1 "$status" "status when $failing fails"
    assert_eq '[]' "$(j -c '.prs[0].reviews' "$FAKE_GH_WORLD")" "reviews left when $failing fails"
    assert_eq '[1,1]' "$(j -c '[.prs[0].threads[].comments | length]' "$FAKE_GH_WORLD")" "replies left when $failing fails"
  done
}

@test "a failure after the submission is reported, and the rest still done" {
  pr 1 layer-a main
  world '.prs[0].body = "- [ ] Keep the cache"'
  thread 1 T1 false "charlouze-dev-agent:🤖 1/2 Fragile parsing"
  thread 1 T2 false "charlouze-dev-agent:🤖 2/2 Odd name"
  submission '{"event": "COMMENT", "body": "Fine.", "resolve": ["T1", "T2"], "checks": ["Keep the cache"]}'

  export FAKE_GH_FAIL="thread=T1"
  submit 1
  assert_eq 1 "$status" "status"
  # La sortie d'erreur du `gh` simulé précède le document.
  assert_eq '{"review":"https://github.com/o/r/posted/1","event":"COMMENT","failed":["resolve T1"]}' \
    "$(j -c . <<<"${lines[-1]}")" "output"
  assert_eq '[false,true]' "$(j -c '[.prs[0].threads[].isResolved]' "$FAKE_GH_WORLD")" "resolved"
  assert_eq '"- [x] Keep the cache"' "$(j '.prs[0].body' "$FAKE_GH_WORLD")" "body"
}

@test "a wrong usage fails with code 2" {
  pr 1 layer-a main
  for usage in "" "merge 1" "notes" "notes one" "notes 1 2" "submit 1" "submit one file" \
    "submit 1 $BATS_TEST_TMPDIR/missing.json" "submit 1 file extra"; do
    eval "guided $usage"
    assert_eq 2 "$status" "status of \"$usage\""
  done
  assert_eq "" "$(posted .)" "posted"
}

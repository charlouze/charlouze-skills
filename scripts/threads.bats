#!/usr/bin/env bats
# Tests de la bibliothèque des échanges d'une PR, chargée par `source` après la
# définition de `j`, comme le font ses deux scripts. Chaque test prépare dans son
# dossier temporaire un monde JSON que sert un `gh` simulé, placé en tête du
# PATH : ni GitHub, ni réseau, ni modèle.
#
#   bats scripts/threads.bats

bats_require_minimum_version 1.5.0

source "$BATS_TEST_DIRNAME/fake-gh/helpers.bash"

setup() {
  fake_gh_setup
  source "$BATS_TEST_DIRNAME/threads.sh"
  world '.prs += [{number: 1, id: "PR_1", threads: [], reviews: [], comments: []}]'
}

# Un fil de revue de la PR 1, avec ses messages, chacun donné par son auteur et
# son corps. Les messages passent par un fichier : jq natif sous Windows perd les
# guillemets d'un JSON passé en argument.
thread() { # identifiant auteur corps…
  local id=$1 comments="$BATS_TEST_TMPDIR/comments.json"
  shift
  j -nc '[$ARGS.positional | range(0; length; 2) as $i | .[$i:$i + 2] | {author: {login: .[0]}, body: .[1],
    url: ("https://github.com/o/r/" + .[1]), createdAt: "2026-01-01T00:00:00Z"}]' --args "$@" >"$comments"
  world '(.prs[0].threads) += [{id: $id, isResolved: false, path: "a.sh", line: 3, originalLine: 3,
    comments: $comments[0]}]' --arg id "$id" --slurpfile comments "$comments"
}

@test "a message starting with the mark is the agent's; one without it, or with no body, is not" {
  run j -c --arg mark "$mark" "$jq_by_agent"' map(by_agent)' <<<"[
    {\"body\": \"$mark 1/2 a point\"}, {\"body\": \"thanks $mark\"}, {\"body\": null}, {}
  ]"
  assert_eq 0 "$status" "status"
  assert_eq '[true,false,false,false]' "$output" "by_agent"
}

@test "pr_connection gives every node of a connection, all its pages read" {
  export FAKE_GH_PAGE_SIZE=2
  world '(.prs[0].comments) = [range(5) | {id: ("IC_" + tostring), body: ("c" + tostring)}]'

  run pr_connection 1 LayerComments comments 'id body'
  assert_eq 0 "$status" "status"
  assert_eq 'IC_0 IC_1 IC_2 IC_3 IC_4' "$(j -r .id <<<"$output" | tr '\n' ' ' | sed 's/ $//')" "nodes"
}

@test "threads gives each thread of a PR, one per line, with its fields and its messages" {
  thread T1 alice one app/agent "$mark two"
  thread T2 bob three

  run threads 1
  assert_eq 0 "$status" "status"
  assert_eq '{"id":"T1","isResolved":false,"path":"a.sh","line":3,"originalLine":3,"comments":{"totalCount":2,"nodes":[{"author":{"login":"alice"},"body":"one","url":"https://github.com/o/r/one","createdAt":"2026-01-01T00:00:00Z"},{"author":{"login":"app/agent"},"body":"'"$mark"' two","url":"https://github.com/o/r/'"$mark"' two","createdAt":"2026-01-01T00:00:00Z"}]}}' \
    "$(head -n 1 <<<"$output")" "first thread"
  assert_eq '["T2",["three"]]' "$(sed -n 2p <<<"$output" | j -c '[.id, [.comments.nodes[].body]]')" "second thread"
  assert_eq 2 "$(wc -l <<<"$output" | tr -d ' ')" "one line per thread"
}

@test "threads gives all the messages of a thread longer than a page, and the threads in their order" {
  export FAKE_GH_PAGE_SIZE=2
  thread T1 alice m1 bob m2 alice m3 bob m4 alice m5
  thread T2 bob short
  thread T3 alice x1 bob x2 alice x3

  run threads 1
  assert_eq 0 "$status" "status"
  assert_eq '[["T1",5,["m1","m2","m3","m4","m5"]],["T2",1,["short"]],["T3",3,["x1","x2","x3"]]]' \
    "$(j -sc 'map([.id, .comments.totalCount, [.comments.nodes[].body]])' <<<"$output")" "threads"
}

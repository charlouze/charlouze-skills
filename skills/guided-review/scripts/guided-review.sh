#!/usr/bin/env bash
# Le script de la revue guidée : il lit les fils à juger d'une pile, et y poste
# les verdicts de l'humain. Il est le seul à lire les points d'attention de la
# revue guidée et le seul à poster ses verdicts. La pile elle-même, sa forme et
# les couches sautées, il la lit par `scripts/stack.sh`, à la racine du plugin.
#
#   guided-review.sh notes <PR>
#   guided-review.sh submit <PR> <fichier>
#
# Il agit toujours sous l'identité de l'humain : il retire `GH_TOKEN` et
# `GITHUB_TOKEN` de son environnement avant tout `gh`, si bien que `gh` retombe
# sur le compte que l'humain y a enregistré, qu'un wrapper d'identité le lance ou
# non. Il refuse d'agir quand cette identité n'est pas un utilisateur : une app,
# ou `gh api user` refusé.
#
# Un point d'attention est reconnu à la marque de l'agent, `🤖` au début d'un
# message, sous quelque identité qu'il soit posté, comme `rework-stack.sh`
# reconnaît un message de l'agent : la marque et la lecture des fils, ces deux
# scripts les tiennent de `scripts/threads.sh`, à la racine du plugin. Ce que
# celui-ci poste, sous le nom de l'humain, ne la porte jamais.
#
# `notes` lit la pile depuis n'importe laquelle de ses PR, comme `stack.sh`, puis
# les fils de ses couches, pagination comprise, et rend un document JSON :
#   {"trunk": "<branche>", "layers": [<couche>, … du bas vers le haut]}
# Une couche donne {number, title, head, base, author}, puis soit `skipped`, la
# raison pour laquelle elle est sautée, telle que `stack.sh` la donne (`draft`,
# `above draft`, `approved`), soit `source` et `notes`. `source` dit où vivent
# ses points d'attention :
#   threads  l'auteur de la PR n'est pas un utilisateur (l'agent a son identité) :
#            ils vivent dans des fils de revue
#   body     sinon : ils vivent dans le corps de la PR, que le script ne lit pas
# `notes` donne ses fils à juger, les fils non résolus dont le dernier message
# porte la marque, chacun {kind, id, url, path, line, [rank,] messages: [{author,
# body}, …]}, de l'un de ces genres :
#   note     un point d'attention : son premier message porte aussi la marque ;
#            `rank` est le n de son `🤖 n/m`, absent quand il manque
#   answer   un fil ouvert par l'humain auquel une reprise a répondu
# les `note` par rang, celles sans rang ensuite, puis les `answer` ; seulement
# les `answer` quand `source` est `body`.
#
# `submit` soumet la revue d'une couche, d'après un fichier JSON :
#   {"event": "COMMENT" | "REQUEST_CHANGES" | "APPROVE", "body": "…",
#    "replies": [{"thread": "<id>", "body": "…"}],
#    "resolve": ["<id de fil>"],
#    "checks": ["<texte exact d'une case du corps de la PR>"]}
# Il refuse, sans rien poster : un texte (`body` ou réponse) qui commence par la
# marque ; `APPROVE` avec des réponses ; `COMMENT` avec des réponses, sauf quand
# l'humain est l'auteur de la PR ; un fil (réponse ou `resolve`) qui n'est pas un
# fil à juger de cette PR ; une case dont la ligne non cochée `- [ ] <texte>` est
# introuvable dans le corps de la PR. Il rabat `APPROVE` et `REQUEST_CHANGES` sur
# `COMMENT` quand l'humain est l'auteur de la PR, ce que GitHub refuse sinon.
# Puis il crée la revue en attente, y pose les réponses dans leurs fils, la
# soumet, résout les fils de `resolve`, et coche les cases de `checks` dans le
# corps de la PR, sans rien y changer d'autre. Une erreur avant la soumission
# supprime la revue en attente : rien n'est à moitié posté. Après la soumission,
# il va jusqu'au bout. Il écrit un document JSON :
#   {"review": "<lien>", "event": "<événement soumis>", "failed": ["resolve <id>" | "checks", …]}
#
# Code : 0 fait, 1 échec de `gh` (pour `submit`, après la soumission : ce qui a
# échoué est dans `failed`), 2 usage, 3 pile qui fourche (deux PR ouvertes sur
# une même base, nommées sur la sortie d'erreur), 4 identité qui n'est pas un
# utilisateur, 5 soumission refusée (la raison sur la sortie d'erreur). En échec,
# `notes` n'écrit rien sur sa sortie.
#
# Demande bash 4.4 ou plus récent, gh et jq.

set -euo pipefail
# Une commande en échec arrête aussi le script depuis une substitution `$(…)`.
shopt -s inherit_errexit

# L'identité de l'humain : le compte enregistré de `gh`, jamais un jeton reçu.
unset GH_TOKEN GITHUB_TOKEN

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
  leave 2 "usage: guided-review.sh notes <PR>
       guided-review.sh submit <PR> <file>"
}

# jq natif sous Windows écrit ses fins de ligne en CRLF.
j() { jq "$@" | tr -d '\r'; }

j -n 1 >/dev/null 2>&1 || leave 1 "guided-review.sh: jq not found"

# Les scripts partagés, à la racine du plugin : celui qui lit la pile, avec la
# reprise et la finalisation ; la marque et la lecture des fils, avec la reprise.
shared="$(dirname "${BASH_SOURCE[0]}")/../../../scripts"
stack_script="$shared/stack.sh"
# shellcheck source=../../../scripts/threads.sh
source "$shared/threads.sh"

# Le login de l'humain, dans `human`. Toute autre identité arrête tout, code 4.
identify() {
  local user
  user=$(gh api user 2>/dev/null) || leave 4 "guided-review.sh: gh api user refused: log in with gh auth login"
  [ "$(j -r .type <<<"$user")" = User ] || leave 4 "guided-review.sh: $(j -r .login <<<"$user") is not a user"
  human=$(j -r .login <<<"$user")
}

# La pile, lue par `stack.sh`, dans `stack_json`. Une pile qui fourche garde son
# code 3, et `stack.sh` en a déjà nommé les PR sur la sortie d'erreur ; tout
# autre échec sort avec le code 1.
read_stack() { # PR
  local code=0
  stack_json=$(bash "$stack_script" "$1") || code=$?
  case $code in
    0) ;;
    3) decided=yes && exit 3 ;;
    *) exit 1 ;;
  esac
}

# Les fils à juger d'une PR, en JSON, dans l'ordre où les présenter.
to_judge() { # numéro source
  threads "$1" | j -sc --arg mark "$mark" --arg source "$2" "$jq_by_agent"'
    def rank: .body | capture("^" + $mark + " (?<n>[0-9]+)/[0-9]+") | .n | tonumber;
    [.[] | select((.isResolved | not) and (.comments.nodes | last | by_agent)) | .comments.nodes as $messages
      | {kind: (if $messages[0] | by_agent then "note" else "answer" end),
         id, url: $messages[0].url, path, line: (.line // .originalLine)}
      + ([$messages[0] | select(by_agent) | rank] | if length > 0 then {rank: .[0]} else {} end)
      + {messages: [$messages[] | {author: (.author.login // "ghost"), body}]}]
    | [.[] | select(.kind == "note" and $source == "threads")] as $notes
    | ($notes | map(select(.rank)) | sort_by(.rank)) + ($notes | map(select(.rank | not)))
      + map(select(.kind == "answer"))'
}

# L'auteur d'une PR et la source de ses points d'attention, en JSON.
# `gh pr view` préfixe de `app/` le login d'une app.
pr_author() { # numéro
  gh pr view "$1" --json author | j -c '.author
    | {author: (.login // "ghost"),
       source: (if (.is_bot // false) or (.login // "" | startswith("app/")) then "threads" else "body" end)}'
}

# Une couche : ce qui la décrit, puis la raison pour laquelle elle est sautée,
# ou sa source et ses fils à juger.
layer() { # couche-lue-par-stack.sh
  local number info
  number=$(j -r .number <<<"$1")
  info=$(pr_author "$number")
  if [ -n "$(j -r '.skipped // ""' <<<"$1")" ]; then
    j -c --argjson info "$info" '{number, title, head, base, author: $info.author, skipped}' <<<"$1"
  else
    j -c --argjson info "$info" --argjson notes "$(to_judge "$number" "$(j -r .source <<<"$info")")" \
      '{number, title, head, base, author: $info.author, source: $info.source, notes: $notes}' <<<"$1"
  fi
}

notes() { # PR
  local human stack_json stack_layer all=""
  identify
  read_stack "$1"
  # Rien n'est écrit avant que toutes les couches soient lues.
  while IFS= read -r stack_layer; do
    all+="$(layer "$stack_layer")"$'\n'
  done < <(j -c '.layers[]' <<<"$stack_json")
  j -s --arg trunk "$(j -r .trunk <<<"$stack_json")" '{trunk: $trunk, layers: .}' <<<"$all"
}

# Coche dans un corps de PR, en JSON, la première ligne non cochée de chaque
# texte, sans toucher au reste, fins de ligne CRLF comprises.
jq_check='
  def check($text):
    (split("\n")) as $lines
    | ([$lines | to_entries[] | select(.value | rtrimstr("\r") == "- [ ] " + $text) | .key] | first) as $at
    | if $at == null then . else $lines | .[$at] |= sub("^- \\[ \\]"; "- [x]") | join("\n") end;
  reduce $checks[] as $text (.; check($text))'

# La raison de refuser une soumission, vide pour une soumission acceptée.
refusal() { # soumission corps-de-la-PR fils-à-juger auteur-humain
  j -r --arg mark "$mark" --argjson body "$2" --argjson judged "$3" --argjson human_author "$4" '
    def text: . // "" | tostring;
    (.replies // []) as $replies
    | ($judged | map(.id)) as $ids
    | ($body // "" | split("\n") | map(rtrimstr("\r"))) as $lines
    | [ if (.event | IN("COMMENT", "REQUEST_CHANGES", "APPROVE") | not) then "unknown event: \(.event)" else empty end,
        if (.body | text | startswith($mark)) then "the body starts with the agent'"'"'s mark" else empty end,
        ($replies[] | select(.body | text | startswith($mark)) | "the reply in \(.thread) starts with the agent'"'"'s mark"),
        if .event == "APPROVE" and ($replies | length) > 0 then "APPROVE with replies" else empty end,
        if .event == "COMMENT" and ($replies | length) > 0 and ($human_author | not) then "COMMENT with replies" else empty end,
        (($replies | map(.thread)) + (.resolve // []) | .[] | select(IN($ids[]) | not) | "not a thread to judge of this PR: \(.)"),
        ((.checks // [])[] | select(("- [ ] " + .) | IN($lines[]) | not) | "no unchecked box: \(.)")
      ] | first // ""' <<<"$1"
}

# Un appel GraphQL ; sa réponse sur la sortie.
graphql() { # requête variables…
  local query=$1
  shift
  gh api graphql "$@" -f query="$query"
}

# Supprime la revue en attente puis arrête tout, code 1 : rien n'est à moitié posté.
abandon() { # revue
  graphql 'mutation DeleteReview($review: ID!) {
    deletePullRequestReview(input: {pullRequestReviewId: $review}) { clientMutationId }
  }' -f review="$1" >/dev/null || true
  exit 1
}

# Crée la revue en attente, y pose les réponses dans leurs fils et la soumet ;
# le lien de la revue sur la sortie. Une erreur l'abandonne.
post_review() { # identifiant-de-la-PR soumission événement
  local review reply response
  review=$(graphql 'mutation CreateReview($pr: ID!) {
    addPullRequestReview(input: {pullRequestId: $pr}) { pullRequestReview { id } }
  }' -f pr="$1" | j -r .data.addPullRequestReview.pullRequestReview.id)
  while IFS= read -r reply; do
    graphql 'mutation ReplyInReview($review: ID!, $thread: ID!, $body: String!) {
      addPullRequestReviewThreadReply(input: {pullRequestReviewId: $review, pullRequestReviewThreadId: $thread, body: $body}) {
        comment { url }
      }
    }' -f review="$review" -f thread="$(j -r .thread <<<"$reply")" -f body="$(j -r .body <<<"$reply")" >/dev/null \
      || abandon "$review"
  done < <(j -c '.replies // [] | .[]' <<<"$2")
  response=$(graphql 'mutation SubmitReview($review: ID!, $event: PullRequestReviewEvent!, $body: String) {
    submitPullRequestReview(input: {pullRequestReviewId: $review, event: $event, body: $body}) {
      pullRequestReview { url }
    }
  }' -f review="$review" -f event="$3" -f body="$(j -r '.body // ""' <<<"$2")") \
    || abandon "$review"
  j -r .data.submitPullRequestReview.pullRequestReview.url <<<"$response"
}

# Après la soumission : résout les fils et coche les cases, en tentant tout ;
# ce qui échoue s'ajoute à `failed`.
finish_review() { # PR soumission
  local thread checked
  while IFS= read -r thread; do
    graphql 'mutation ResolveThread($thread: ID!) {
      resolveReviewThread(input: {threadId: $thread}) { thread { isResolved } }
    }' -f thread="$thread" >/dev/null || failed+=("resolve $thread")
  done < <(j -r '.resolve // [] | .[]' <<<"$2")
  [ "$(j '.checks // [] | length' <<<"$2")" -gt 0 ] || return 0
  # Le corps relu juste avant d'être réécrit. `-b` garde ses fins de ligne sous
  # Windows, et le point final ses sauts de ligne finaux.
  {
    checked=$(gh pr view "$1" --json body | jq -jb --argjson checks "$(j -c .checks <<<"$2")" \
      "(.body // \"\") | $jq_check | . + \".\"") && gh pr edit "$1" --body "${checked%.}" >/dev/null
  } || failed+=(checks)
}

submit() { # PR fichier
  local human submission info author pr human_author reason event url failed=()
  identify
  submission=$(j -c . "$2" 2>/dev/null) && [ "$(j -r type <<<"$submission")" = object ] \
    || leave 5 "the submission is not a JSON object"
  info=$(pr_author "$1")
  author=$(j -r '.author | sub("^app/"; "") | sub("\\[bot\\]$"; "") | ascii_downcase' <<<"$info")
  pr=$(gh pr view "$1" --json body,id)
  human_author=false
  [ "$author" = "$(j -nr --arg h "$human" '$h | ascii_downcase')" ] && human_author=true
  reason=$(refusal "$submission" "$(j -c .body <<<"$pr")" "$(to_judge "$1" "$(j -r .source <<<"$info")")" "$human_author")
  [ -z "$reason" ] || leave 5 "submission refused: $reason"

  event=$(j -r .event <<<"$submission")
  [ "$human_author" = false ] || event=COMMENT
  url=$(post_review "$(j -r .id <<<"$pr")" "$submission" "$event")
  finish_review "$1" "$submission"

  j -nc --arg review "$url" --arg event "$event" '{review: $review, event: $event, failed: $ARGS.positional}' \
    --args ${failed[@]+"${failed[@]}"}
  [ ${#failed[@]} -eq 0 ] || { decided=yes && exit 1; }
}

[ $# -ge 1 ] || usage
command=$1
shift
case $command in
  notes)
    [ $# -eq 1 ] && [[ "$1" =~ ^[0-9]+$ ]] || usage
    notes "$1"
    ;;
  submit)
    [ $# -eq 2 ] && [[ "$1" =~ ^[0-9]+$ ]] && [ -f "$2" ] || usage
    submit "$1" "$2"
    ;;
  *) usage ;;
esac

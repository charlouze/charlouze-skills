#!/usr/bin/env bash
# Le script de la reprise : il lit les éléments en attente d'une pile, et y
# répond. Il est le seul à lire les échanges d'une pile sur GitHub, et le seul à
# y poster ce qu'une reprise lit ensuite comme un message de l'agent (réponses et
# renvois) : la marque de l'agent et la règle de ce qui est en attente ne vivent
# qu'ici. La pile elle-même, sa forme et l'approbation de ses couches, il la lit
# par `scripts/stack.sh`, à la racine du plugin.
#
#   rework-stack.sh pending <PR>
#   rework-stack.sh reply <element> <body>
#   rework-stack.sh comment <PR> <body>
#
# Un message de l'agent est un message dont le corps commence par `🤖`, sous
# quelque identité qu'il soit posté : le script ne lit aucun auteur pour le
# reconnaître. Tout ce que l'agent poste sur une pile porte donc cette marque,
# ses réponses comme ses points d'attention ; ce que le script poste la porte
# déjà.
#
# `pending` lit la pile depuis n'importe laquelle de ses PR, comme `stack.sh`, puis
# les échanges de ses couches. Il lit tout, pagination comprise, et rend un
# document JSON :
#   {"trunk": "<branche>", "layers": [<couche>, … du bas vers le haut]}
# Une couche donne {number, head, base, reviewers}, ses relecteurs passés hors
# l'auteur de la PR, puis soit `skipped`, la raison pour laquelle elle est
# ignorée :
#   draft        une couche draft
#   above draft  toute couche au-dessus d'une couche draft
#   approved     une couche approuvée, selon la règle de `stack.sh`
# soit `pending`, ses éléments en attente, chacun
#   {kind, id, url, [path, line,] messages: [{author, body}, …]}
# de l'un de ces genres :
#   thread   un fil de revue non résolu dont le dernier message ne vient pas de
#            l'agent ; seul il donne `path` et `line`
#   review   un corps de revue non vide qui ne vient pas de l'agent
#   comment  un commentaire de PR qui ne vient pas de l'agent
# Un corps de revue ou un commentaire de PR n'est plus en attente dès qu'un
# commentaire de PR de l'agent, sur la même PR, lui répond : sa première ligne
# est `🤖 <lien de l'élément>`, la forme que lui donne `reply`. Les autres
# commentaires de l'agent, comme ceux de `comment`, ne répondent à rien.
#
# `reply` répond à un élément par son `id` : dans le fil pour un fil ; pour un
# corps de revue ou un commentaire, par un commentaire de PR qui le cite (son
# lien, puis son corps). Il fait commencer la réponse par `🤖`, et écrit le lien
# de la réponse postée. Le corps est pris tel quel, même quand il commence par
# des tirets.
#
# `comment` poste sur une PR un commentaire de l'agent qui ne répond à aucun
# élément en particulier, comme un renvoi vers un élément posé ailleurs. Il le
# fait commencer par `🤖`, et écrit le lien du commentaire posté.
#
# Code : 0 fait, 1 échec de `gh`, 2 usage, 3 pile qui fourche (deux PR ouvertes
# sur une même base, nommées sur la sortie d'erreur). En échec, `pending`
# n'écrit rien sur sa sortie.
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
  leave 2 "usage: rework-stack.sh pending <PR>
       rework-stack.sh reply <element> <body>
       rework-stack.sh comment <PR> <body>"
}

# jq natif sous Windows écrit ses fins de ligne en CRLF.
j() { jq "$@" | tr -d '\r'; }

j -n 1 >/dev/null 2>&1 || leave 1 "rework-stack.sh: jq not found"

# La marque de l'agent, au début de chacun de ses messages.
mark='🤖'

# Le message de l'agent, en jq.
jq_by_agent='def by_agent: (.body // "") | startswith($mark);'

pr_view() { # numéro champs
  gh pr view "$1" --json "$2"
}

# Le script qui lit la pile, partagé avec la finalisation.
stack_script="$(dirname "${BASH_SOURCE[0]}")/../../../scripts/stack.sh"

# Les nœuds d'une connexion d'une PR (fils, revues, commentaires), tous lus.
pr_connection() { # numéro opération connexion champs
  gh api graphql --paginate -F owner='{owner}' -F repo='{repo}' -F number="$1" -f query="
    query $2(\$owner: String!, \$repo: String!, \$number: Int!, \$endCursor: String) {
      repository(owner: \$owner, name: \$repo) {
        pullRequest(number: \$number) {
          $3(first: 100, after: \$endCursor) {
            pageInfo { hasNextPage endCursor }
            nodes { $4 }
          }
        }
      }
    }" | j -c --arg connection "$3" '.data.repository.pullRequest[$connection].nodes[]'
}

# Les fils de revue d'une PR, chacun avec tous ses messages.
threads() { # numéro
  local thread longer
  pr_connection "$1" LayerThreads reviewThreads '
    id isResolved path line originalLine
    comments(first: 100) { totalCount nodes { author { login } body url createdAt } }' \
    | while IFS= read -r thread; do
      # Un fil plus long qu'une page : ses messages sont relus, tous.
      longer=$(j '.comments.totalCount > (.comments.nodes | length)' <<<"$thread")
      if [ "$longer" = true ]; then
        thread=$({ echo "$thread" && thread_comments "$(j -r .id <<<"$thread")"; } \
          | j -sc '.[0].comments.nodes = .[1:] | .[0]')
      fi
      echo "$thread"
    done
}

thread_comments() { # identifiant
  gh api graphql --paginate -f id="$1" -f query='
    query ThreadComments($id: ID!, $endCursor: String) {
      node(id: $id) {
        ... on PullRequestReviewThread {
          comments(first: 100, after: $endCursor) {
            pageInfo { hasNextPage endCursor }
            nodes { author { login } body url createdAt }
          }
        }
      }
    }' | j -c '.data.node.comments.nodes[]'
}

# La raison pour laquelle une couche est ignorée, ou rien.
skip_reason() { # couche-lue-par-stack.sh au-dessus-d'un-draft(yes|no)
  j -r --arg above "$2" '
    if .draft then "draft" elif $above == "yes" then "above draft"
    elif .approval == "approved" then "approved" else "" end' <<<"$1"
}

# Les relecteurs passés d'une PR, hors son auteur, en JSON.
reviewers() { # numéro
  # `gh pr view` préfixe de `app/` le login d'une app, sans son suffixe `[bot]`.
  pr_view "$1" author,latestReviews | j -c '
    def plain: sub("^app/"; "") | sub("\\[bot\\]$"; "");
    (.author.login // "" | plain) as $author
    | [.latestReviews[].author.login // empty | select(plain != $author)] | unique'
}

# Les éléments en attente d'une PR, d'après tous ses échanges.
pending_elements() { # numéro
  {
    threads "$1" | j -c '{thread: .}'
    pr_connection "$1" LayerReviews reviews 'id author { login } body state url submittedAt' | j -c '{review: .}'
    pr_connection "$1" LayerComments comments 'id author { login } body url createdAt' | j -c '{comment: .}'
  } | j -sc --arg mark "$mark" "$jq_by_agent"'
    def messages: [.[] | {author: (.author.login // "ghost"), body}];
    [.[].thread // empty] as $threads
    | [.[].review // empty] as $reviews
    | [.[].comment // empty] as $comments
    # Les liens des éléments auxquels un commentaire de PR de l’agent répond.
    | [$comments[] | select(by_agent) | .body | split("\n")[0] | ltrimstr($mark + " ")] as $answered
    | def answered: .url | IN($answered[]);
    [
        $threads[] | select((.isResolved | not) and (.comments.nodes | last | by_agent | not)) | {
          kind: "thread", id, url: .comments.nodes[0].url, path, line: (.line // .originalLine),
          messages: (.comments.nodes | messages)
        }
      ] + [
        $reviews[] | select(.state != "PENDING" and (.body // "" | test("\\S")) and (by_agent | not)
          and (answered | not))
        | {kind: "review", id, url, messages: ([.] | messages)}
      ] + [
        $comments[] | select((by_agent | not) and (answered | not))
        | {kind: "comment", id, url, messages: ([.] | messages)}
      ]'
}

# Une couche : ce qui la décrit, puis la raison pour laquelle elle est ignorée,
# ou ses éléments en attente.
layer() { # couche-lue-par-stack.sh au-dessus-d'un-draft(yes|no)
  local number skipped info elements
  number=$(j -r .number <<<"$1")
  skipped=$(skip_reason "$1" "$2")
  info=$(j -c --argjson reviewers "$(reviewers "$number")" \
    '{number, head, base, reviewers: $reviewers}' <<<"$1")
  if [ -n "$skipped" ]; then
    j -c --arg skipped "$skipped" '. + {skipped: $skipped}' <<<"$info"
  else
    elements=$(pending_elements "$number")
    j -sc '.[0] + {pending: .[1]}' <<<"$info"$'\n'"$elements"
  fi
}

# La pile, lue par `stack.sh`, dans `stack_json`. Une pile qui fourche garde son
# code 3, et `stack.sh` en a déjà nommé les PR sur la sortie d'erreur ; tout
# autre échec, de `gh` le plus souvent, sort avec le code 1 (l'usage, `pending`
# l'a déjà vérifié).
read_stack() { # PR
  local code=0
  stack_json=$(bash "$stack_script" "$1") || code=$?
  case $code in
    0) ;;
    3) decided=yes && exit 3 ;;
    *) exit 1 ;;
  esac
}

pending() { # PR
  local stack_json stack_layer above_draft=no out all=""
  read_stack "$1"
  # Du bas vers le haut : au-dessus d'une couche draft, tout est ignoré. Rien
  # n'est écrit avant que toutes les couches soient lues.
  while IFS= read -r stack_layer; do
    out=$(layer "$stack_layer" "$above_draft")
    if [ "$(j -r .skipped <<<"$out")" = draft ]; then
      above_draft=yes
    fi
    all+="$out"$'\n'
  done < <(j -c '.layers[]' <<<"$stack_json")
  j -s --arg trunk "$(j -r .trunk <<<"$stack_json")" '{trunk: $trunk, layers: .}' <<<"$all"
}

# La marque fait reconnaître une réponse comme celle de l'agent.
marked() { # corps
  printf '%s %s\n' "$mark" "$1"
}

reply_in_thread() { # fil corps
  local body
  body=$(marked "$2")
  gh api graphql -f thread="$1" -f body="$body" -f query='
    mutation ReplyInThread($thread: ID!, $body: String!) {
      addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $thread, body: $body}) {
        comment { url }
      }
    }' | j -r .data.addPullRequestReviewThreadReply.comment.url
}

# Un commentaire de PR qui cite l'élément : son lien, puis son corps. La
# première ligne, `🤖 <lien>`, est celle que lit `pending`.
reply_on_pr() { # élément-lu corps
  local subject url quote
  subject=$(j -r '.pullRequest.id // ""' <<<"$1")
  [ -n "$subject" ] || leave 2 "not an element of a PR"
  url=$(j -r .url <<<"$1")
  quote=$(j -r .body <<<"$1" | sed 's/^/> /; s/^> $/>/')
  post_on_pr "$subject" "$url

$quote

$2"
}

# Un commentaire de PR de l'agent, marqué.
post_on_pr() { # identifiant-de-la-PR corps
  local body
  body=$(marked "$2")
  gh api graphql -f subject="$1" -f body="$body" -f query='
    mutation CommentOnPr($subject: ID!, $body: String!) {
      addComment(input: {subjectId: $subject, body: $body}) { commentEdge { node { url } } }
    }' | j -r .data.addComment.commentEdge.node.url
}

comment() { # PR corps
  local info
  info=$(pr_view "$1" id)
  post_on_pr "$(j -r .id <<<"$info")" "$2"
}

reply() { # élément corps
  local node kind
  node=$(gh api graphql -f id="$1" -f query='
    query Element($id: ID!) {
      node(id: $id) {
        __typename
        ... on PullRequestReview { body url pullRequest { id } }
        ... on IssueComment { body url pullRequest { id } }
      }
    }' | j -c .data.node)
  kind=$(j -r .__typename <<<"$node")
  case $kind in
    PullRequestReviewThread) reply_in_thread "$1" "$2" ;;
    PullRequestReview | IssueComment) reply_on_pr "$node" "$2" ;;
    *) leave 2 "not an element: $1 ($kind)" ;;
  esac
}

[ $# -ge 1 ] || usage
command=$1
shift
case $command in
  pending)
    [ $# -eq 1 ] && [[ "$1" =~ ^[0-9]+$ ]] || usage
    pending "$1"
    ;;
  reply)
    [ $# -eq 2 ] && [ -n "$1" ] && [ -n "$2" ] || usage
    reply "$1" "$2"
    ;;
  comment)
    [ $# -eq 2 ] && [[ "$1" =~ ^[0-9]+$ ]] && [ -n "$2" ] || usage
    comment "$1" "$2"
    ;;
  *) usage ;;
esac

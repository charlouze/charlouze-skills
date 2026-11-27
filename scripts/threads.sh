# La marque de l'agent et la lecture paginée des échanges d'une PR, ses fils de
# revue en tête, communes aux deux scripts qui lisent les échanges d'une pile :
# `rework-stack.sh`, le script de la reprise, et `guided-review.sh`, le script de
# la revue guidée, qui le chargent par `source`. La marque et la lecture paginée des échanges ne vivent
# qu'ici. `thread_comments` y reste interne : `threads` l'appelle.
#
# Il donne :
#   mark         la marque de l'agent, `🤖`, au début de chacun de ses messages
#   jq_by_agent  la définition jq de `by_agent`, vrai d'un message de l'agent :
#                à placer en tête d'un filtre qui reçoit `--arg mark "$mark"`
#   threads <numéro>
#                les fils de revue d'une PR, un objet JSON par ligne, chacun
#                {id, isResolved, path, line, originalLine, comments: {totalCount,
#                nodes: [{author: {login}, body, url, createdAt}, …]}}, tous ses
#                messages compris, pagination comprise
#   pr_connection <numéro> <opération> <connexion> <champs>
#                les nœuds d'une connexion d'une PR (`reviewThreads`, `reviews`,
#                `comments`…), un objet JSON par ligne, toutes les pages lues ;
#                `opération` nomme la requête, que le `gh` simulé des tests
#                reconnaît
#
# Il attend du script qui le charge la fonction `j`, jq sans CRLF, et `gh`, sous
# l'identité que ce script a choisie.

# La marque de l'agent, au début de chacun de ses messages.
mark='🤖'

# Le message de l'agent, en jq.
jq_by_agent='def by_agent: (.body // "") | startswith($mark);'

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

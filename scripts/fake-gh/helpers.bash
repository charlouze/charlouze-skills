# Les aides communes des tests qui préparent un monde JSON pour le `gh` simulé :
# `scripts/stack.bats` et `skills/rework-stack/scripts/rework-stack.bats`, qui les
# chargent par `source`.

# Place le `gh` simulé en tête du PATH, avec un monde vide et rien de posté.
fake_gh_setup() {
  export FAKE_GH_WORLD="$BATS_TEST_TMPDIR/world.json"
  export FAKE_GH_LOG="$BATS_TEST_TMPDIR/posted.jsonl"
  # Le dossier du gh simulé, sous la forme que lit le PATH : sous Windows, le
  # dossier du test peut s'écrire `C:/…`, dont le `:` couperait le PATH.
  local fake
  fake=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  export PATH="$fake:$PATH"
  # Aucun test ne doit atteindre le vrai gh, ni GitHub.
  if [ "$(command -v gh)" != "$fake/gh" ]; then
    echo "the fake gh is not first on PATH" >&2
    return 1
  fi
  unset FAKE_GH_USER FAKE_GH_PAGE_SIZE FAKE_GH_FAIL FAKE_GH_FAIL_CODE
  echo '{"prs": []}' >"$FAKE_GH_WORLD"
  : >"$FAKE_GH_LOG"
}

# jq natif sous Windows écrit ses fins de ligne en CRLF.
j() { jq "$@" | tr -d '\r'; }

assert_eq() { # attendu obtenu message
  if [ "$1" != "$2" ]; then
    echo "$3: expected \"$1\", got \"$2\""
    return 1
  fi
}

world() { # filtre jq, arguments jq…
  local filter=$1 next
  shift
  next=$(j "$@" "$filter" "$FAKE_GH_WORLD")
  printf '%s\n' "$next" >"$FAKE_GH_WORLD"
}

set_pr() { world "(.prs[] | select(.number == $1)) |= ($2)"; } # numéro mise-à-jour

# La dernière revue d'un relecteur sur une PR.
latest_review() { # numéro auteur état
  world '(.prs[] | select(.number == $n) | .latestReviews) += [{author: {login: $who}, state: $state}]' \
    --argjson n "$1" --arg who "$2" --arg state "$3"
}

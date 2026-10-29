# Lit la sortie de `claude plugin validate . --json` et rend la liste des
# avertissements qui doivent faire échouer la CI.
#
# `--strict` n'est pas utilisable : le plugin ne porte volontairement pas de
# `version` (Claude Code prend le SHA du commit), et ce manque est toujours
# signalé. Deux avertissements sont donc tolérés, tous les autres échouent :
# - l'absence de `version`, dans le manifeste comme dans la marketplace ;
# - le `CLAUDE.md` à la racine, qui sert aux sessions de ce dépôt et non au
#   plugin.
[ (.manifest // {} | .warnings // [] | .[]),
  (.contents[]? | .warnings // [] | .[]) ]
| map(select(
    ((.path // "") | test("(^|→ )version$"))
    or ((.path // "") == "root" and ((.message // "") | test("CLAUDE.md")))
    | not))

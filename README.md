# charlouze-skills

Plugin de skills d'ingénierie pour Claude Code, qui se pose par-dessus [`mattpocock-skills`](https://github.com/mattpocock/skills) pour des projets produit et jeu vidéo. Il complète le flux de Matt sans le remplacer (voir [l'ADR 0004](docs/adr/0004-completer-matt-par-consignes.md)). Le dépôt est à la fois le plugin et sa marketplace.

## Installation

```
claude plugin marketplace add charlouze/charlouze-skills
claude plugin install charlouze-skills@charlouze-skills
```

L'installation tire aussi `mattpocock-skills@claude-plugins-official`, dont le plugin dépend. Il faut pour cela que la marketplace `claude-plugins-official` soit connue de Claude Code (`claude plugin marketplace add anthropics/claude-plugins-official` sinon).

Pour préparer un projet, lancer `/setup-matt-pocock-skills`, puis `/setup-charlouze-skills`. La seconde écrit le bloc `## charlouze-skills` du `CLAUDE.md` et la déclaration des grilles, `docs/agents/grids.md`, et déclare la marketplace et les deux plugins dans `.claude/settings.json`, après avoir montré chaque changement. Elle se relance sans risque, ne commite rien, et finit par la liste de ce qui reste à faire.

Elle complète aussi les fichiers de Matt, pour que `domain-modeling` et `triage` suivent les règles du plugin : des sections balisées `<!-- charlouze-skills -->` dans `docs/agents/domain.md` (le format du glossaire et la carte des contextes) et dans `docs/agents/triage-labels.md` (les dérives), et la disposition multi-contexte dans `domain.md` et dans la ligne `### Domain docs` du `CLAUDE.md`. Une relance de `/setup-matt-pocock-skills` défait ces ajouts ; relancer `/setup-charlouze-skills` ensuite les refait.

`grid-review` juge par les grilles du projet, un sous-agent par grille, l'objet de l'un des trois points d'accroche : un brouillon de spec de changement, entier (spec) ou par ses `Implementation Decisions`, où vit sa conception (conception), ou un diff (revue). En revue, son rapport forme un axe Grilles à côté des axes Standards et Spec de `code-review` (voir [l'ADR 0001](docs/adr/0001-grilles-axe-de-revue-separe.md)). Aucune skill ne l'appelle encore aux points d'accroche spec et conception. Elle lit `docs/agents/grids.md`, ou à défaut la déclaration par défaut, [`skills/grid-review/default-grids.md`](skills/grid-review/default-grids.md). La mise en place écrit cette déclaration en clair dans `docs/agents/grids.md`, quand le fichier manque, et deux lignes dans le bloc `## charlouze-skills` : `Grids`, qui pointe vers le fichier, et `Code review`, qui joint `grid-review` à toute revue `code-review`, qu'elle soit lancée par l'humain, par `/implement` ou par `/implement-spec`. Les grilles par défaut sont des skills de wondelai (`domain-driven-design`, `clean-architecture`, `software-design-philosophy`, `clean-code`), dont le plugin ne dépend pas : une grille absente est signalée dans le rapport, sans rien bloquer.

Le plugin ne porte pas de version : Claude Code prend le SHA du commit, et chaque fusion sur `main` en devient une.

## Développer le plugin

Les sessions ordinaires de ce dépôt utilisent le plugin de `main`, que déclare `.claude/settings.json`. Pour essayer une skill sans la publier, lancer Claude Code sur le worktree où elle se développe :

```
claude --plugin-dir <chemin du worktree>
```

Pour cette session, la copie du worktree remplace le plugin installé, et le plugin de Matt reste chargé depuis son installation. Après une modification d'une skill ou du manifeste, `/reload-plugins` la prend en compte sans relancer la session.

Une skill se déclare dans `.claude-plugin/plugin.json`, sous `skills`, une ligne par skill (`"./skills/<nom>"`). Les dépendances du plugin, elles, sont déclarées dans l'entrée de `.claude-plugin/marketplace.json` : déclarées dans `plugin.json`, elles empêcheraient `--plugin-dir` de charger le plugin seul.

## Validation

La CI lance `claude plugin validate .` sur chaque pull request. Elle échoue sur une erreur du manifeste, de la marketplace ou du frontmatter d'une skill, et sur tout avertissement autre que l'absence de `version` et le `CLAUDE.md` à la racine (filtre : `.github/untolerated-warnings.jq`). Pour vérifier en local :

```
claude plugin validate .
claude plugin validate . --json | jq -f .github/untolerated-warnings.jq
```

La seconde commande doit afficher `[]`.

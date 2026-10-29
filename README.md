# charlouze-skills

Plugin de skills d'ingénierie pour Claude Code, qui se pose par-dessus [`mattpocock-skills`](https://github.com/mattpocock/skills) pour des projets produit et jeu vidéo. Il complète le flux de Matt sans le remplacer (voir [l'ADR 0004](docs/adr/0004-completer-matt-par-consignes.md)). Le dépôt est à la fois le plugin et sa marketplace.

## Installation

```
claude plugin marketplace add charlouze/charlouze-skills
claude plugin install charlouze-skills@charlouze-skills
```

L'installation tire aussi `mattpocock-skills@claude-plugins-official`, dont le plugin dépend. Il faut pour cela que la marketplace `claude-plugins-official` soit connue de Claude Code (`claude plugin marketplace add anthropics/claude-plugins-official` sinon).

Le plugin ne porte pas de version : Claude Code prend le SHA du commit, et chaque fusion sur `main` en devient une.

## Développer le plugin

Les sessions ordinaires de ce dépôt utilisent le plugin de `main`, que déclare `.claude/settings.json`. Pour essayer une skill sans la publier, lancer Claude Code sur le worktree où elle se développe :

```
claude --plugin-dir <chemin du worktree>
```

Pour cette session, la copie du worktree remplace le plugin installé, et le plugin de Matt reste chargé depuis son installation. Après une modification d'une skill ou du manifeste, `/reload-plugins` la prend en compte sans relancer la session.

Une skill se déclare dans `.claude-plugin/plugin.json`, sous `skills`, une ligne par skill (`"./skills/<nom>"`). Les dépendances du plugin, elles, sont déclarées dans l'entrée de `.claude-plugin/marketplace.json` : déclarées dans `plugin.json`, elles empêcheraient `--plugin-dir` et `claude plugin eval` de charger le plugin seul.

## Validation

La CI lance `claude plugin validate .` sur chaque pull request. Elle échoue sur une erreur du manifeste, de la marketplace ou du frontmatter d'une skill, et sur tout avertissement autre que l'absence de `version` et le `CLAUDE.md` à la racine (filtre : `.github/untolerated-warnings.jq`). Pour vérifier en local :

```
claude plugin validate .
claude plugin validate . --json | jq -f .github/untolerated-warnings.jq
```

La seconde commande doit afficher `[]`.

# Contribuer à charlouze-skills

## Développer le plugin

Les sessions ordinaires de ce dépôt utilisent le plugin de `main`, que déclare `.claude/settings.json`. Pour essayer une skill sans la publier, lancer Claude Code sur le worktree où elle se développe :

```
claude --plugin-dir <chemin du worktree>
```

Pour cette session, la copie du worktree remplace le plugin installé, et le plugin de Matt, `mattpocock-skills`, reste chargé depuis son installation. Après une modification d'une skill ou du manifeste, `/reload-plugins` la prend en compte sans relancer la session.

Une skill se déclare dans `.claude-plugin/plugin.json`, sous `skills`, une ligne par skill (`"./skills/<nom>"`). Les dépendances du plugin, elles, sont déclarées dans l'entrée de `.claude-plugin/marketplace.json` : déclarées dans `plugin.json`, elles empêcheraient `--plugin-dir` de charger le plugin seul.

Un script qu'une seule skill appelle vit dans son dossier, sous `scripts/`. Un script que plusieurs skills appellent vit dans `scripts/` à la racine du plugin. Chaque skill l'atteint par `<this skill's directory>/../../scripts/<script>` : le plugin s'installe en entier, et ce dossier, qu'aucune ligne de `plugin.json` ne déclare, n'est pas pris pour une skill.

## Validation

La CI lance `claude plugin validate .` sur chaque pull request. Elle échoue sur une erreur du manifeste, de la marketplace ou du frontmatter d'une skill, et sur tout avertissement autre que l'absence de `version` et le `CLAUDE.md` à la racine (filtre : `.github/untolerated-warnings.jq`). Pour vérifier en local :

```
claude plugin validate .
claude plugin validate . --json | jq -f .github/untolerated-warnings.jq
```

La seconde commande doit afficher `[]`.

Les scripts ont leurs propres tests, ordinaires, sans modèle ni GitHub, écrits pour [bats](https://bats-core.readthedocs.io/) :

- ceux du script de finalisation, `skills/finalize-stack/scripts/finalize-stack.sh`, montent chacun un dépôt git local et son remote nu dans leur dossier temporaire, isolé de la configuration git du poste ;
- ceux du script qui lit la pile, `scripts/stack.sh`, et ceux du script de la reprise, `skills/rework-stack/scripts/rework-stack.sh`, préparent chacun un monde JSON que sert un `gh` simulé, `scripts/fake-gh/gh`, placé en tête du `PATH` : il garde ce qu'on lui poste, et aucun test n'atteint le vrai `gh`. Leurs aides communes vivent à côté de lui, dans `scripts/fake-gh/helpers.bash`.

Le `package.json` de la racine fixe la version de bats ; il ne sert qu'au développement. Les tests demandent Node, et ce que demandent les scripts : `bash` (Git Bash sous Windows) ; `git` 2.41 ou plus récent pour la finalisation ; `jq` pour la lecture de la pile et la reprise. La CI ne les lance pas :

```
npm install
npm test
```

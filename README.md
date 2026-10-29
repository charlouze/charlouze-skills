# charlouze-skills

Plugin de skills d'ingénierie pour Claude Code, qui se pose par-dessus [`mattpocock-skills`](https://github.com/mattpocock/skills) pour des projets produit et jeu vidéo. Il complète le flux de Matt sans le remplacer (voir [l'ADR 0004](docs/adr/0004-completer-matt-par-consignes.md)). Le dépôt est à la fois le plugin et sa marketplace.

## Installation

```
claude plugin marketplace add charlouze/charlouze-skills
claude plugin install charlouze-skills@charlouze-skills
```

L'installation tire aussi `mattpocock-skills@claude-plugins-official`, dont le plugin dépend. Il faut pour cela que la marketplace `claude-plugins-official` soit connue de Claude Code (`claude plugin marketplace add anthropics/claude-plugins-official` sinon).

Pour préparer un projet, lancer `/setup-matt-pocock-skills`, puis `/setup-charlouze-skills`. La seconde écrit le bloc `## charlouze-skills` du `CLAUDE.md` et déclare la marketplace et les deux plugins dans `.claude/settings.json`, après avoir montré chaque changement. Elle se relance sans risque, ne commite rien, et finit par la liste de ce qui reste à faire.

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

## Banc d'évaluation

Les skills se testent par ce qu'elles laissent derrière elles. Chaque cas de `evals/` lance une session sur un dépôt fixture, que construit son `fixture.sh`, puis juge les fichiers que la session y a laissés, jamais la formulation de la skill. Les suites tournent en local, dans une session du compte de l'humain, et jamais en CI ([ADR 0005](docs/adr/0005-evaluations-en-local-jamais-en-ci.md), qui note aussi le coût mesuré d'une passe).

Pour lancer les cas d'une skill, depuis la racine du dépôt :

```
claude plugin eval . --tag <skill> --ablation none --model opus \
  --scaffold --allow-tools Write Edit --trust-plugin --no-publish --max-cost-usd 3
```

- `--ablation none` : pas de bras sans le plugin, qui doublerait le coût.
- `--scaffold` lance le `fixture.sh` de chaque cas, et `--allow-tools Write Edit` laisse la session écrire dans le dépôt fixture.
- `--no-publish` garde le rapport en local : sans lui, il est publié sur claude.ai.
- `--max-cost-usd` arrête la passe au-delà d'un plafond, estimé au prix catalogue.
- `--runs 1` suffit pour mettre au point un grader ; la mesure se fait au nombre de runs du cas.
- `--keep-temp` garde le dépôt fixture de chaque run, pour lire ce que la session a écrit (sous `home/cwd/`). Le CLI déconseille d'y lancer `git`.

Le rapport et le JSON (`--json <fichier>`) vont dans `evals/results/`, ignoré par git. La commande sort en 0 quand tous les cas passent.

Sur Windows, depuis PowerShell, `bash` désigne celui de WSL, et les `fixture.sh` échouent. Mettre celui de Git en tête du `PATH` avant de lancer la passe :

```
$env:PATH = "<dossier de Git>\bin;$env:PATH"
```

Une session d'évaluation qui reçoit un shell (`Bash`, `PowerShell`) est refusée sur Windows natif, faute de bac à sable : un cas qui en a besoin tourne sous WSL2 ou Linux.

Claude Code refuse toute écriture sous `.claude/` à une session sans humain, quels que soient les outils accordés : après un run, `.claude/settings.json` n'a jamais changé. Un cas juge donc une écriture des réglages sur l'appel `Write` ou `Edit` que la session tente, par un grader `tool_used` dont `input_match` porte le chemin et les valeurs. Dans une vraie session, l'humain approuve cette écriture.

« Rien d'écrit » se juge en deux graders : `file_exists` sur `'**'` avec `exists: false` (aucun fichier créé ; ce grader ne voit que les fichiers créés), et une regex qui reprend le fichier existant octet pour octet, de `^` à `$`.

Sans réponse dans le prompt, une session montre les changements, pose sa question et s'arrête là : elle n'écrit rien, mais n'atteint pas le rapport final. Un cas qui juge le rapport donne donc ses réponses dans le prompt.

Un cas est un dossier `evals/<skill>/<cas>/` : `prompt.md` (le prompt, et en frontmatter les runs, le modèle et les outils), `case.yaml` (qui nomme le `fixture.sh`), `fixtures/` et un grader par fichier dans `graders/`. Le prompt ne nomme pas une skill que lance le modèle : c'est à lui de la choisir. Une skill que lance l'humain (`disable-model-invocation: true`) a pour prompt sa commande, `/charlouze-skills:<nom>`, suivie de ce que l'humain répondrait à ses questions, tel qu'il le taperait avec la commande : la session ne peut pas lui répondre. Ces réponses passent par le prompt, et non par `append_system_prompt`, parce qu'un humain ne parle jamais par le prompt système : le cas jugerait un chemin que la skill ne rencontre pas. Une réponse qui ne vaut qu'une fois la proposition montrée, comme le oui à une consigne contraire, ne se donne pas d'avance : le cas juge alors que la proposition reste sans effet. Ce que plusieurs cas d'une skill partagent vit dans `evals/<skill>/_fixtures/`, un dossier sans `prompt.md` que le banc ne prend pas pour un cas, et que chaque `fixture.sh` lit par un chemin relatif.

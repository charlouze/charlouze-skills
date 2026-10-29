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

Un cas est un dossier `evals/<skill>/<cas>/` : `prompt.md` (le prompt, et en frontmatter les runs, le modèle et les outils), `case.yaml` (qui nomme le `fixture.sh`), `fixtures/` et un grader par fichier dans `graders/`. Le prompt ne nomme pas la skill : c'est au modèle de la choisir.

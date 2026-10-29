# charlouze-skills

Plugin de skills d'ingénierie pour Claude Code, qui se pose par-dessus [`mattpocock-skills`](https://github.com/mattpocock/skills) pour des projets produit et jeu vidéo. Il complète le flux de Matt sans le remplacer (voir [l'ADR 0004](docs/adr/0004-completer-matt-par-consignes.md)). Le dépôt est à la fois le plugin et sa marketplace.

## Installation

```
claude plugin marketplace add charlouze/charlouze-skills
claude plugin install charlouze-skills@charlouze-skills
```

L'installation tire aussi `mattpocock-skills@claude-plugins-official`, dont le plugin dépend. Il faut pour cela que la marketplace `claude-plugins-official` soit connue de Claude Code (`claude plugin marketplace add anthropics/claude-plugins-official` sinon).

Pour préparer un projet, lancer `/setup-matt-pocock-skills`, puis `/setup-charlouze-skills`. La seconde écrit le bloc `## charlouze-skills` du `CLAUDE.md` et déclare la marketplace et les deux plugins dans `.claude/settings.json`, après avoir montré chaque changement. Elle se relance sans risque, ne commite rien, et finit par la liste de ce qui reste à faire.

Elle complète aussi les fichiers de Matt, pour que `domain-modeling` et `triage` suivent les règles du plugin : des sections balisées `<!-- charlouze-skills -->` dans `docs/agents/domain.md` (le format du glossaire et la carte des contextes) et dans `docs/agents/triage-labels.md` (les dérives), et la disposition multi-contexte dans `domain.md` et dans la ligne `### Domain docs` du `CLAUDE.md`. Une relance de `/setup-matt-pocock-skills` défait ces ajouts ; relancer `/setup-charlouze-skills` ensuite les refait.

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

Les skills se testent par ce qu'elles laissent derrière elles. Chaque cas de `evals/` lance une session sur un dépôt fixture, que construit son `fixture.sh`, puis juge les fichiers que la session y a laissés, jamais la formulation de la skill. Les suites tournent en local, dans une session du compte de l'humain, et jamais en CI ([ADR 0005](docs/adr/0005-evaluations-en-local-jamais-en-ci.md)). Le coût de chaque passe mesurée est noté en fin de section.

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

Ces regex ne s'écrivent pas à la main. Pour `setup-charlouze-skills`, elles se dérivent des fixtures, tout comme les fichiers de Matt complétés de `evals/_fixtures/charlouze-setup/`, qui appliquent `matt-files.md` aux modèles de Matt. Après un changement de `matt-files.md` ou d'une fixture, une commande régénère le tout :

```
mise exec python -- python evals/setup-charlouze-skills/_tools/regenerate.py
```

Elle ne réécrit que la ligne `pattern:` de chaque grader, et `--check` vérifie sans rien écrire. Dans un pattern, trois tirets de suite fermeraient le frontmatter du grader : ils s'écrivent `-{3}`.

Sans réponse dans le prompt, une session montre les changements, pose sa question et s'arrête là : elle n'écrit rien, mais n'atteint pas le rapport final. Un cas qui juge le rapport donne donc ses réponses dans le prompt.

Un cas est un dossier `evals/<skill>/<cas>/` : `prompt.md` (le prompt, et en frontmatter les runs, le modèle et les outils), `case.yaml` (qui nomme le `fixture.sh`), `fixtures/` et un grader par fichier dans `graders/`. Le prompt ne nomme pas une skill que lance le modèle : c'est à lui de la choisir. Une skill que lance l'humain (`disable-model-invocation: true`) a pour prompt sa commande, `/charlouze-skills:<nom>`, suivie de ce que l'humain répondrait à ses questions, tel qu'il le taperait avec la commande : la session ne peut pas lui répondre. Ces réponses passent par le prompt, et non par `append_system_prompt`, parce qu'un humain ne parle jamais par le prompt système : le cas jugerait un chemin que la skill ne rencontre pas. Une réponse qui ne vaut qu'une fois la proposition montrée, comme le oui à une consigne contraire, ne se donne pas d'avance : le cas juge alors que la proposition reste sans effet. Ce que les cas partagent vit dans `evals/_fixtures/`, un dossier sans `prompt.md` que le banc ne prend pas pour un cas : `lib.sh`, que chaque `fixture.sh` source par un chemin relatif pour bâtir son dépôt couche par couche (`init_repo`, `add_matt_setup`, `commit_fixture`…), et les dépôts types que ces fonctions copient.

### Coût mesuré

Chaque passe mesurée s'ajoute ici, avec sa date, la version de Claude Code et le modèle. Les montants sont le `costUsd` du rapport, une estimation au prix catalogue de l'API, pas la part de l'abonnement consommée (voir l'ADR 0005).

- 2026-10-29, Claude Code 2.1.312, modèle `claude-opus-5-5`, juge `haiku` : le cas `writing-functional-specs-from-a-brief` à 3 runs a coûté 0,48 $ (0,15 à 0,17 $ par run, dont moins de 0,001 $ de juge) et duré 116 s (34 à 47 s par run, 7 à 9 tours). Mettre au point les graders a demandé trois runs de plus, pour 0,45 $.
- Le même jour, dans les mêmes conditions : les cinq cas de `setup-charlouze-skills` à 3 runs (15 runs, `-j 3`) ont coûté 1,97 $ (0,10 à 0,17 $ par run) et duré 97 s (11 à 30 s par run, 7 à 10 tours). La mise au point a coûté 1,13 $ (un run par cas, plusieurs passes).
- Le même jour, après l'ajout des fichiers de Matt à la mise en place : les six cas de `setup-charlouze-skills` à 3 runs (18 runs, `-j 3`) ont coûté 3,77 $ (0,11 à 0,30 $ par run) et duré 186 s (14 à 56 s par run, 5 à 16 tours). Les cas qui écrivent dans `docs/agents/` coûtent le plus, autour de 0,30 $ par run. La mise au point a coûté 1,11 $ (un run rouge, puis un run par cas).
- Le même jour : les deux cas des consignes contraires et des flux concurrents à 3 runs ont coûté 0,59 $ (`setup-contrary-instructions`) et 0,72 $ (`setup-competing-plugins`), soit 0,18 à 0,24 $ par run, 35 à 55 s et 12 à 14 tours. Une passe des sept cas de `setup-charlouze-skills` à un run a coûté 1,17 $ (51 s) ; après l'ajout des fichiers de Matt, celle des huit cas, 1,92 $ (97 s), où les deux nouveaux cas coûtent 0,26 et 0,29 $. La mise au point a coûté 2,01 $ (quatre runs, puis une première passe de mesure qui a fait préciser le rapport), et vérifier un échec isolé de `setup-with-matt-setup` (un run sur six, cause non retrouvée faute de trace gardée) 1,07 $ de plus.

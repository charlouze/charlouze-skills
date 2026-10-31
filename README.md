# charlouze-skills

Plugin de skills d'ingénierie pour Claude Code, qui se pose par-dessus [`mattpocock-skills`](https://github.com/mattpocock/skills) pour des projets produit et jeu vidéo. Il complète le flux de Matt sans le remplacer (voir [l'ADR 0004](docs/adr/0004-completer-matt-par-consignes.md)). Le dépôt est à la fois le plugin et sa marketplace.

## Installation

```
claude plugin marketplace add charlouze/charlouze-skills
claude plugin install charlouze-skills@charlouze-skills
```

L'installation tire aussi `mattpocock-skills@claude-plugins-official`, dont le plugin dépend. Il faut pour cela que la marketplace `claude-plugins-official` soit connue de Claude Code (`claude plugin marketplace add anthropics/claude-plugins-official` sinon).

Pour préparer un projet, lancer `/setup-matt-pocock-skills`, puis `/setup-charlouze-skills`. La seconde écrit le bloc `## charlouze-skills` du `CLAUDE.md` (avec la consigne de découpage de `/to-tickets` et la consigne d'empilement de `/implement-spec`), la déclaration des grilles, `docs/agents/grids.md`, la consigne de la spec de changement, `docs/agents/change-spec.md`, et la politique d'historique git, `docs/agents/git-history.md`, et déclare la marketplace et les deux plugins dans `.claude/settings.json`, après avoir montré chaque changement. Elle se relance sans risque, ne commite rien, et finit par la liste de ce qui reste à faire.

Elle complète aussi les fichiers de Matt, pour que `domain-modeling` et `triage` suivent les règles du plugin : des sections balisées `<!-- charlouze-skills -->` dans `docs/agents/domain.md` (le format du glossaire et la carte des contextes) et dans `docs/agents/triage-labels.md` (les dérives), et la disposition multi-contexte dans `domain.md` et dans la ligne `### Domain docs` du `CLAUDE.md`. Une relance de `/setup-matt-pocock-skills` défait ces ajouts ; relancer `/setup-charlouze-skills` ensuite les refait.

`grid-review` juge par les grilles du projet, un sous-agent par grille, l'objet de l'un des trois points d'accroche : un brouillon de spec de changement, entier (spec) ou par ses `Implementation Decisions`, où vit sa conception (conception), ou un diff (revue). En revue, son rapport forme un axe Grilles à côté des axes Standards et Spec de `code-review` (voir [l'ADR 0001](docs/adr/0001-grilles-axe-de-revue-separe.md)). La consigne de la spec de changement l'appelle aux points d'accroche spec et conception. Elle lit `docs/agents/grids.md`, ou à défaut la déclaration par défaut, [`skills/grid-review/default-grids.md`](skills/grid-review/default-grids.md). La mise en place écrit cette déclaration en clair dans `docs/agents/grids.md`, quand le fichier manque, et deux lignes dans le bloc `## charlouze-skills` : `Grids`, qui pointe vers le fichier, et `Code review`, qui joint `grid-review` à toute revue `code-review`, qu'elle soit lancée par l'humain, par `/implement` ou par `/implement-spec`. Les grilles par défaut sont des skills de wondelai (`domain-driven-design`, `clean-architecture`, `software-design-philosophy`, `clean-code`), dont le plugin ne dépend pas : une grille absente est signalée dans le rapport, sans rien bloquer.

`/to-spec` est complétée par `docs/agents/change-spec.md`, que la mise en place écrit quand il manque, avec la ligne `Change spec` du bloc qui le fait suivre. La spec de changement y gagne trois sections : `Contexts`, les contextes qu'elle touche, avec leur frontière et leur état ; `Spec delta`, son écart en blocs ; `Risks`, ses risques. Un flag n'y entre que par exception, quand les user stories ne se livrent pas en tickets qui tiennent seuls : l'agent le propose, les `Implementation Decisions` le déclarent (nom, défaut, parties gardées, levée), un bloc ajoute sa phrase de garde à la spec fonctionnelle et un autre l'en retire, et les `Testing Decisions` couvrent ses deux valeurs. Elle passe par les grilles des points d'accroche spec et conception, et n'est publiée qu'après la relecture par l'humain de tous ses blocs et de ses flags.

`/to-tickets` est complétée par la consigne de découpage, que la mise en place écrit en une section du bloc `## charlouze-skills`, « Slicing with `to-tickets` ». Le modèle d'issue de Matt ne change pas : chaque ticket nomme dans *What to build* les blocs qu'il transcrit, chaque bloc va dans un seul ticket, et le découpage présenté montre les blocs de chaque ticket. Chaque ticket, fusionné seul après ses bloqueurs, ne laisse aucun utilisateur devant un comportement à moitié livré, et chaque user story est livrée par au moins un ticket ; quand il y faudrait un flag que la spec de changement ne déclare pas, l'agent s'arrête sans rien publier, et la spec de changement est à reprendre. Dans un contexte sans spec fonctionnelle, le ticket qui en ouvre la spec passe en premier, et bloque les autres tickets de ce contexte. Pour un flag déclaré, le premier ticket gardé transcrit le bloc qui ajoute la phrase de garde, et bloque les autres tickets gardés ; le ticket de levée retire le flag du code, transcrit le bloc qui retire la phrase de garde, et est bloqué par tous les tickets gardés. S'il survit à la spec de changement, le ticket de levée porte sa condition de levée et reste ouvert. La publication crée le label `context:<contexte>` de chaque contexte touché, s'il manque, et ouvre une issue d'adoption pour chaque contexte existant non adopté. Une section du bloc est, comme une ligne, à l'humain une fois écrite : la mise en place ajoute celle qui manque et garde celle qui est là, listée sous **Kept** quand elle diffère.

La politique d'historique git (voir [l'ADR 0002](docs/adr/0002-merge-commit-apres-finalisation.md)) vit dans `docs/agents/git-history.md`, que la mise en place écrit quand il manque, avec la ligne `Git history` du bloc, qui la résume et y renvoie. Avant le premier push d'une branche, l'agent range ses commits librement ; après, il ne réécrit rien tant que toute la pile n'est pas approuvée : ni `rebase`, ni `commit --amend`, ni `push --force`. Une correction de ce qu'un commit de la pile fait déjà devient un `fixup!` ou un `amend!` qui vise un commit de sa propre couche, une modification nouvelle un commit normal, et l'agent dit lequel il a choisi. Les corrections montent la pile par `git merge`, seulement dans une couche qui pousse de toute façon, et `main` n'y entre qu'en cas de conflit. Une fois toute la pile approuvée, la finalisation fond les corrections sans changer le diff d'aucune couche, puis l'humain fusionne la pile en merge commit. Une PR seule suit la même règle, comme une pile d'une couche.

La mise en place propose aussi les réglages GitHub qui tiennent cette politique : le merge commit pour seule méthode de fusion, titré par la PR (`merge_commit_title=PR_TITLE`) et sans corps (`merge_commit_message=BLANK`), pour que `main` en `--first-parent` montre une ligne par pile ; et le rejet des approbations périmées sur la branche par défaut, par un ruleset qui y exige alors une PR, sans approbation requise. Elle lit les réglages par `gh`, ne repropose pas ceux qui sont en place, et applique les autres par `gh` après un oui donné à ces réglages seuls. Ce qu'elle ne peut pas appliquer, faute de droits, ou ce que l'humain refuse, finit en commandes sous **Left to you**.

`/implement-spec` est complétée par la consigne d'empilement, que la mise en place écrit en une section du bloc `## charlouze-skills`, « Stacked delivery with `implement-spec` » (voir les ADR [0003](docs/adr/0003-enchainement-parallele-empile-un-a-un.md) et [0004](docs/adr/0004-completer-matt-par-consignes.md)). Elle remplace la branche d'intégration de la skill par une seule pile native par spec de changement, une couche par ticket, liée à son ticket ; le graphe de tickets, la frontière, les implémenteurs en parallèle dans leur worktree et `tdd` restent ceux de Matt. Les tickets se développent en parallèle, chaque couche passe sa revue avant d'être poussée, et les couches s'empilent une à une, dans l'ordre d'arrivée. Un ticket seul donne une PR ordinaire. L'enchaînement finit par un commentaire de rapport sur la spec de changement, avec la pile et ses couches. La mise en place vérifie que l'extension `gh stack` est installée, et sinon en donne la commande d'installation sous **Left to you**, sans s'arrêter : le reste du plugin s'en passe.

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

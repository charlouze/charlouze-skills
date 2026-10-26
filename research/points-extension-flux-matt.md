# Points d'extension du flux de Matt (mattpocock-skills 1.3.1)

Recherche pour le ticket « Où brancher ses réglages dans le flux de Matt sans réécrire ses skills ? » (#3, carte #1).

**Source primaire** : les fichiers du plugin installé, `~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/1.3.1/`, abrégé `M/` ci-dessous. Les `SKILL.md` sont sous `M/skills/engineering/` et `M/skills/productivity/` (abrégés `eng/` et `prod/`). La documentation utilisateur de chaque skill est sous `M/docs/engineering/` (abrégé `doc/`). Chaque affirmation cite `fichier:ligne`.

Convention : **[Fait]** = lu tel quel dans la source citée. **[Inférence]** = déduit des faits, non vérifié par une exécution.

## 1. Le mécanisme de configuration : une indirection par `CLAUDE.md`

- **[Fait]** Aucun `SKILL.md` du flux ne nomme `docs/agents/*.md`. Seul `setup-matt-pocock-skills` les cite (grep sur `eng/` et `prod/`). Les skills disent « The issue tracker […] should have been provided to you » (`eng/to-spec/SKILL.md:9`, `eng/to-tickets/SKILL.md:11`, `eng/code-review/SKILL.md:13`, `eng/implement-spec/SKILL.md:9`) ou « the tracker doc » (`eng/code-review/SKILL.md:29`).
- **[Fait]** Le chemin est résolu par le bloc `## Agent skills` que setup écrit dans `CLAUDE.md` ou `AGENTS.md` (`eng/setup-matt-pocock-skills/SKILL.md:84-100`). Ce bloc pointe vers les fichiers de configuration, où qu'ils soient. Le CHANGELOG le confirme : les skills « never name a path — they resolve the tracker through the `### Issue tracker` block […], which points at the tracker doc wherever it lives » (`M/CHANGELOG.md:277`).
- **[Fait]** Setup écrit trois fichiers : `issue-tracker.md`, `domain.md` et `triage-labels.md` (ce dernier seulement si `triage` est installé) (`eng/setup-matt-pocock-skills/SKILL.md:65-68`, `:102`, `:106-114`). On peut les éditer à la main ensuite (`:118`, `doc/setup-matt-pocock-skills.md:82`).
- **[Fait]** Setup ne configure que trois choses : le tracker, les labels et la disposition des docs de domaine. Pour les préférences, la doc de Matt est explicite : « skills stay opinionated and take no per-user config. Preferences belong in your `CLAUDE.md` as plain instructions, which every skill already reads » (`doc/setup-matt-pocock-skills.md:72-74`). Le CHANGELOG cite un exemple : passer de `grilling` à une question à la fois se fait par « a line in your global `CLAUDE.md` » (`M/CHANGELOG.md:190`).
- **[Fait]** Il n'existe pas de mode au niveau utilisateur : chaque dépôt porte son propre `docs/agents/` (`doc/setup-matt-pocock-skills.md:26`, `:76-78`).
- **[Fait]** Quand on relance setup, il met à jour le bloc `## Agent skills` sur place sans toucher au reste du fichier (`eng/setup-matt-pocock-skills/SKILL.md:82`). Il réécrit en revanche les fichiers `docs/agents/*` à partir de ses modèles, après avoir montré un brouillon (`:63-70`, `:106`).
  - **[Inférence]** Des ajouts faits dans les fichiers de Matt (`docs/agents/domain.md`…) risquent d'être écrasés par une nouvelle exécution de setup. Des ajouts placés dans des fichiers à nous et dans une section `CLAUDE.md` séparée ne le sont pas.
- **[Fait]** Les dépendances entre skills sont classées en deux catégories (`M/.agents/adr/0001-explicit-setup-pointer-only-for-hard-dependencies.md:5-8`) :
  - **dures** (`to-tickets`, `to-spec`, `triage`) : sans configuration, ces skills échouent ;
  - **souples** (`tdd`, `diagnose`, `improve-codebase-architecture`) : elles mentionnent « the project's domain glossary » et « ADRs in the area you're touching » en prose vague, et fonctionnent sans.

**Conséquence** : les seuls points d'extension sont du texte que l'agent a dans son contexte ou qu'il atteint par un pointeur. Il y en a trois :

1. `CLAUDE.md`, toujours chargé ;
2. les docs atteintes par un pointeur du bloc `## Agent skills` (`docs/agents/*.md`) ;
3. les fichiers conventionnels que certaines skills cherchent d'elles-mêmes : `GLOSSARY.md`, `GLOSSARY-MAP.md`, `docs/adr/`, `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `.out-of-scope/`, et les specs sous `docs/`, `specs/` ou `.scratch/`.

Aucune skill ne lit de fichier de configuration structuré. Les modèles de spec et de ticket sont écrits en dur dans les `SKILL.md`.

## 2. Invocation et graphe d'appels

- **[Fait]** Une skill marquée `disable-model-invocation: true` (**user-invoked**) ne peut être lancée que par un humain qui tape son nom. Aucune autre skill ne peut l'appeler (`M/.agents/invocation.md:5`, `:8`, `:22`).
- **[Fait]** Les skills user-invoked du flux sont `to-spec`, `to-tickets`, `implement`, `implement-spec`, `grill-with-docs`, `setup-matt-pocock-skills`, `wayfinder`, `triage`, `retro`, `improve-codebase-architecture` et `ask-matt` (frontmatter, ligne 4 de chaque `SKILL.md`).
- **[Fait]** Les skills model-invoked (sans ce drapeau) sont `tdd`, `code-review`, `domain-modeling`, `grilling`, `codebase-design`, `research`, `prototype`, `diagnosing-bugs`, `pr` et `writing-for-agents`.
- **[Fait]** Une skill en appelle une autre par la formule « Call the Skill tool with "<nom>" », avec le nom nu (`M/.agents/invocation.md:16`).

Graphe d'appels (formules « Skill tool » relevées par grep dans `eng/` et `prod/`) :

| Appelant (invocation) | Appelle | Source |
|---|---|---|
| `implement` (user) | `tdd`, `code-review` | `eng/implement/SKILL.md:11`, `:15` |
| `implement-spec` (user) | `tdd` (dans chaque sous-agent implémenteur), `code-review` | `eng/implement-spec/SKILL.md:29`, `:36` |
| `grill-with-docs` (user) | `grilling`, `domain-modeling` | `eng/grill-with-docs/SKILL.md:7` |
| `tdd` (model) | `codebase-design` | `eng/tdd/SKILL.md:26` (renvoie aussi à `code-review` en prose, `:38`) |
| `wayfinder` (user) | `grilling`, `domain-modeling`, `research`, `prototype`, plus les skills nommées dans les Notes de la carte | `eng/wayfinder/SKILL.md:77-79`, `:111`, `:115`, `:124` |
| `triage` (user) | `grilling`, `domain-modeling` | `eng/triage/SKILL.md:76` |
| `improve-codebase-architecture` (user) | `codebase-design`, `grilling`, `domain-modeling` | `eng/improve-codebase-architecture/SKILL.md:13`, `:64`, `:66`, `:71` |
| `retro` (user) | `writing-for-agents` | `eng/retro/SKILL.md:11` |
| `grill-me` (user) | `grilling` | `prod/grill-me/SKILL.md:7` |
| `to-spec`, `to-tickets`, `code-review`, `domain-modeling`, `setup-matt-pocock-skills` | aucune | — |

- **[Fait]** `to-spec`, `to-tickets` et `implement-spec` disent de demander à l'utilisateur de lancer `/setup-matt-pocock-skills`. Ce n'est pas un appel.
- **[Inférence]** Remplacer `tdd` ou `code-review` oblige à remplacer aussi `implement` et `implement-spec`, qui les appellent par leur nom nu. Remplacer `implement` ou `implement-spec` n'oblige à rien d'autre : aucune skill ne peut les appeler.
- **[Inférence]** Une skill à nous peut appeler `tdd`, `code-review`, `domain-modeling`, `grilling` et `codebase-design`. Elle ne peut pas appeler `implement`, `implement-spec`, `to-spec` ni `to-tickets`. Pour réutiliser ces quatre-là, il faut que l'humain les tape, ou qu'on les copie dans nos propres skills.
- **[Fait]** Un nom de skill peut être en collision avec un autre. Claude Code fournit son propre `/code-review`. Avec une installation par le marketplace, chaque skill de Matt prend le préfixe `mattpocock-skills:`, et la doc ajoute « the built-in becomes hard to reach at the unqualified name ». La parade signalée par les utilisateurs est de forker la skill sous un nouveau nom (`doc/code-review.md:50-57`).
  - **[Inférence, non vérifiée]** On ne sait pas vers quelle skill Claude Code résout un appel nu (« Call the Skill tool with "code-review" ») lancé depuis `implement`. C'est le cas quand plusieurs plugins, ou le harnais, exposent le même nom. Une session de ce dépôt liste justement à la fois `code-review` (intégré au harnais) et `mattpocock-skills:code-review`. Donner à une de nos skills le même nom qu'une skill de Matt n'est donc pas un mécanisme de remplacement fiable.

## 3. Ce que lit chaque skill et ce qu'on peut régler

| Skill | Fichiers lus | Skills appelées | Réglable sans modifier la skill |
|---|---|---|---|
| `setup-matt-pocock-skills` | `git remote`, `CLAUDE.md`/`AGENTS.md`, `GLOSSARY.md`, `GLOSSARY-MAP.md`, `docs/adr/`, `src/*/docs/adr/`, `docs/agents/`, `.scratch/`, signaux de monorepo (`eng/setup-matt-pocock-skills/SKILL.md:21-30`) | — | Le choix de tracker, dont un tracker « Other » décrit en prose (`:47`, `:114`) ; les noms des labels ; mono- ou multi-contexte (`:59-61`). Rien d'autre (`doc/setup-matt-pocock-skills.md:72-74`). |
| `to-spec` | Tracker et labels « provided » (`eng/to-spec/SKILL.md:9`) ; vocabulaire du glossaire et ADR de la zone touchée (`:13`) | — | La destination (tracker) et le label `ready-for-agent` (`:19`). Le modèle de spec est écrit en dur (`:21-75`), avec la règle « Do NOT include specific file paths or code snippets » (`:55`). On ne peut **qu'ajouter** des consignes via `CLAUDE.md`. |
| `to-tickets` | Tracker et labels (`eng/to-tickets/SKILL.md:11`) ; la référence passée en argument (`:17`) ; glossaire et ADR (`:21`) | — | La forme de publication selon le tracker : fichiers locaux ou issues avec dépendances natives et sous-issues (`:60-63`). Les modèles de ticket sont écrits en dur (`:69-103`) et interdisent chemins et extraits de code (`:105`). |
| `implement` | Ticket récupéré dans le tracker (`eng/implement/SKILL.md:9`) | `tdd`, `code-review` | Rien de déclaré. La doc dit qu'il n'existe « no configuration flag and no PR mode » : on passe la consigne dans l'invocation ou on édite une copie locale (`doc/implement.md:61`). Commite sur la branche courante (`eng/implement/SKILL.md:17`). |
| `implement-spec` | Tracker (`eng/implement-spec/SKILL.md:9`) ; spec et tickets ; notes d'exploration hors dépôt (`:23`) | `tdd`, `code-review` | Une PR brouillon seulement si le tracker ferme le travail par des PR ou si l'utilisateur la demande (`:25`). Le reste est fixe : une seule **integration branch**, un worktree par ticket fusionné par un sous-agent de fusion (`:11`, `:27-32`), et une revue unique en fin de parcours (`:36`). |
| `tdd` | `GLOSSARY.md` s'il existe, ADR de la zone (`eng/tdd/SKILL.md:10`) ; `tests.md` et `mocking.md` dans le dossier de la skill (`:16`) | `codebase-design` | Les seams sont « pre-agreed » et confirmées avec l'utilisateur (`:22`). Les préférences passent par `CLAUDE.md` ; la doc donne l'exemple des tests navigateur (`doc/tdd.md:63`). |
| `code-review` | Diff et commits (`eng/code-review/SKILL.md:21`) ; la spec, dans cet ordre : références d'issues dans les commits, chemin passé en argument, fichier sous `docs/`, `specs/` ou `.scratch/` qui correspond à la branche, puis l'utilisateur (`:27-32`) ; **tous les fichiers du dépôt qui documentent comment écrire le code**, `CODING_STANDARDS.md` et `CONTRIBUTING.md` obligatoirement (`:36`) | Aucune nommément ; lance deux sous-agents (`:58-72`) | Les règles de l'axe Standards (voir §4) et l'emplacement de la spec. |
| `grill-with-docs` | Rien par elle-même | `grilling`, `domain-modeling` | Ce que lisent les deux skills appelées. |
| `grilling` | L'environnement, via des sous-agents (`prod/grilling/SKILL.md:28`) | — | Le rythme et le format, via le `CLAUDE.md` global (`M/CHANGELOG.md:190`). |
| `domain-modeling` | `GLOSSARY.md`, ou `GLOSSARY-MAP.md` puis un `GLOSSARY.md` par contexte, `docs/adr/` (`eng/domain-modeling/SKILL.md:12-40`) ; le code (`:56-58`) ; `GLOSSARY-FORMAT.md` et `ADR-FORMAT.md` du dossier de la skill (`:62`, `:74`) | — | Le choix mono/multi-contexte, par la présence de `GLOSSARY-MAP.md` (`eng/domain-modeling/GLOSSARY-FORMAT.md:54-60`). Le format d'ADR est fixe. La doc propose comme parade de « override the ADR conventions in your repo's own agent docs » ou de copier la skill (`doc/domain-modeling.md:66-67`). Les consignes de domaine supplémentaires vont dans `docs/agents/domain.md`, « which the skills already read » (`doc/domain-modeling.md:50`). |

Autres fichiers lus en dehors des skills cibles :

- `triage` lit `.out-of-scope/*.md` (`eng/triage/SKILL.md:70`) ;
- `wayfinder` lit la section « Wayfinding operations » du document de tracker et les **Notes** de la carte, qui listent les « skills every session should consult » (`eng/wayfinder/SKILL.md:25`, `:38`, `:124`) ;
- `domain.md` (le modèle de setup) demande de lire glossaire et ADR « before exploring » et de signaler tout conflit avec un ADR (`eng/setup-matt-pocock-skills/domain.md:5-11`, `:47-51`).

## 4. L'axe Standards de `/code-review`

- **[Fait]** L'orchestrateur cherche dans le dépôt « every file that documents how code should be written ». `CODING_STANDARDS.md` et `CONTRIBUTING.md` doivent figurer dans la liste quand ils existent (`eng/code-review/SKILL.md:36`).
- **[Fait]** Il ajoute toujours la **smell baseline** : douze odeurs de code de Fowler. Le dépôt a priorité sur elle (« The repo overrides »). Chaque odeur trouvée reste une question de jugement (`:38-56`).
- **[Fait]** Le sous-agent Standards reçoit la commande de diff, la **liste des fichiers** de standards et la baseline recopiée en entier, « the sub-agent has no other access to it ». Il doit citer pour chaque infraction « the standard (file + the rule) », en moins de 400 mots (`:62-66`).
- **[Fait]** L'orchestrateur ne fusionne ni ne reclasse les deux rapports (`:76-80`). La doc confirme que la documentation du dépôt est la source primaire et que « the repo always overrides » (`doc/code-review.md:44`).
- **[Fait]** `retro` est la skill qui alimente `CODING_STANDARDS.md`. Ce fichier est « read during review, not implementation » et il est réservé aux questions de jugement. Les règles mécaniques doivent devenir des contrôles automatiques (`eng/retro/SKILL.md:19`, `:35`, `:42` ; `doc/code-review.md:96`).
- **[Fait]** Les sous-agents de `code-review` peuvent invoquer des skills. Un bogue ouvert le montre : ils relancent `/code-review` récursivement, et une exécution est montée à plus de 50 agents (`doc/code-review.md:59-61`).

**Peut-il pointer vers des skills externes ?**

- **[Inférence]** Pas directement : la recherche porte sur des fichiers **du dépôt**, et les skills wondelai vivent hors du dépôt, dans `~/.claude/skills/`.
- **[Inférence]** Indirectement, probablement oui. Un `CODING_STANDARDS.md` du dépôt est transmis d'office au sous-agent. Il peut contenir une consigne du type « charge les skills `clean-code`, `clean-architecture`, `domain-driven-design` et `software-design-philosophy`, et note le diff selon leur grille 0-10 ».
  - Le sous-agent peut invoquer des skills (fait ci-dessus), et ces quatre skills sont model-invoked : leur frontmatter n'a pas `disable-model-invocation`, et chacune contient une grille « Goal: 10/10 » (`~/.claude/skills/*/SKILL.md:20`).
  - Trois limites s'appliquent : le plafond de 400 mots, le format de citation « file + rule », et le fait que le rapport Standards reste un seul bloc que l'orchestrateur ne retravaille pas.
  - De plus, `~/.claude/skills/` n'existe que sur le poste de l'utilisateur. Un agent dans le cloud ou une autre machine ne verrait pas ces skills. Copier les grilles dans le dépôt lèverait cette dépendance.
- **[Inférence]** On peut aussi faire tourner les grilles dans une étape à nous, séparée, qui appelle `code-review` puis applique les grilles. `code-review` est model-invoked, donc une skill à nous peut l'appeler. Mais `implement` et `implement-spec` appellent `code-review` directement : une étape séparée suppose de remplacer ces deux appelants.

## 5. Ce que ça implique, par objectif

**Spec fonctionnelle vivante par contexte (bounded context DDD)**

- **[Fait]** Le flux connaît la notion de contexte au niveau du glossaire : `GLOSSARY-MAP.md`, un `GLOSSARY.md` et un `docs/adr/` par contexte (`eng/domain-modeling/SKILL.md:24-38`, `eng/setup-matt-pocock-skills/domain.md:26-39`).
- **[Fait]** Le glossaire est « a glossary and nothing else » (`eng/domain-modeling/SKILL.md:64`). `to-spec` publie une spec **ponctuelle** dans le tracker (`eng/to-spec/SKILL.md:19`). Aucune skill ne tient de spec vivante dans le dépôt. La doc reconnaît que les réponses de `grill-with-docs` partent « Into the conversation only » (`doc/grill-with-docs.md:55`).
- **[Inférence]** La **lecture** d'une spec vivante peut passer par un point d'extension existant : une consigne de lecture ajoutée aux règles de consommation (`domain.md` ou un fichier à nous pointé par `CLAUDE.md`). La troisième piste de recherche de spec de `code-review` (« a spec file under `docs/`, `specs/` », `eng/code-review/SKILL.md:31`) ne trouve qu'un fichier qui correspond à la branche, pas une spec par contexte.
- **[Inférence]** **Écrire** et tenir cette spec à jour demande une skill nouvelle ou modifiée : aucune étape du flux ne l'écrit.

**Tickets plus riches (delta de spec fonctionnelle et spec technique complète)**

- **[Fait]** Les modèles de `to-spec` et `to-tickets` sont écrits dans les `SKILL.md` (`eng/to-spec/SKILL.md:21-75`, `eng/to-tickets/SKILL.md:69-103`). Ils interdisent chemins et extraits de code (`eng/to-spec/SKILL.md:55`, `eng/to-tickets/SKILL.md:105`).
- **[Inférence]** Un `CLAUDE.md` peut **ajouter** des sections, sur le modèle « Preferences belong in your `CLAUDE.md` ». Il ne contredira pas de façon fiable une consigne explicite de la skill. Des tickets nettement plus riches, en particulier techniques, demandent une skill modifiée ou remplaçante.
- **[Inférence]** `to-tickets` est user-invoked : le remplacer ne force aucun autre remplacement.

**Grilles de qualité wondelai dans le flux**

- **[Inférence]** Ce point est atteignable par un point d'extension existant : un `CODING_STANDARDS.md` qui renvoie aux skills (§4). C'est à confirmer par un essai, car l'invocation par le sous-agent n'est pas garantie et les limites de format s'appliquent.
- **[Inférence]** Placer les grilles **pendant** l'implémentation va à l'encontre de la position de Matt : les standards s'appliquent en revue (`eng/retro/SKILL.md:35`). Ce n'est pas impossible : `CLAUDE.md` est lu partout.
- **[Inférence]** Pour un rapport de notes distinct du rapport Standards, il faut une skill à nous et le remplacement des appelants `implement` et `implement-spec`.

**Enchaînement AFK de tickets en PR empilées (stacked PRs)**

- **[Fait]** `implement` commite sur la branche courante, sans mode PR (`eng/implement/SKILL.md:17`, `doc/implement.md:61`).
- **[Fait]** `implement-spec` fait converger tous les tickets sur **une** integration branch par des fusions, avec au plus une PR brouillon pour l'ensemble (`eng/implement-spec/SKILL.md:11`, `:25`, `:27-32`).
- **[Fait]** `to-tickets` n'a pas de dispatch automatique (`doc/to-tickets.md:80`).
- **[Inférence]** Aucun point d'extension ne produit une PR par ticket, chacune basée sur la branche du ticket bloquant. Il faut un orchestrateur à nous qui remplace `implement-spec`. Cet orchestrateur peut toujours appeler `tdd` et `code-review`, qui sont model-invoked.

**Politique d'historique git (pas de réécriture avant approbation de la revue)**

- **[Fait]** Les skills du flux ne demandent aucun rebase ni force-push. `implement-spec` fusionne : « merges the integration branch tip into its own branch », puis passe par un sous-agent de fusion (`eng/implement-spec/SKILL.md:30-32`). Son seul « reset » concerne un worktree neuf mal basé (`:28`).
- **[Fait]** La doc de `code-review` conseille « Commit first, then review, then amend or add a fixup » (`doc/code-review.md:81`). L'option `amend` réécrit l'historique.
- **[Inférence]** Ce point est atteignable par `CLAUDE.md` : une consigne de dépôt ou globale, que « every skill already reads ». Rien dans les `SKILL.md` ne la contredit. Les garde-fous mécaniques (hooks) relèvent du harnais, pas du flux de Matt.

**`setup-matt-pocock-skills` lui-même**

- **[Fait]** Setup ne gère que le tracker, les labels et la disposition des docs de domaine. Il n'a pas de mode global (`doc/setup-matt-pocock-skills.md:72-78`).
- **[Inférence]** Nos réglages ne passeront pas par lui. Il faut une étape d'installation à nous qui écrit sa propre section `CLAUDE.md` et ses propres fichiers. Garder ces fichiers hors des `docs/agents/*` de Matt évite qu'une nouvelle exécution de setup les écrase.

## 6. Questions ouvertes relevées

1. Vers quelle skill un appel nu (« Skill tool with "code-review" » ou « "tdd" ») se résout-il quand Matt, le harnais et notre plugin exposent le même nom ? (§2 ; seule la doc de Matt l'évoque, pour `code-review`.)
2. Le sous-agent Standards de `code-review` invoque-t-il réellement une skill externe qu'un `CODING_STANDARDS.md` lui nomme ? Ses notes 0-10 survivent-elles au plafond de 400 mots ? (À prototyper.)
3. Les sous-agents de `implement-spec` et de `code-review` reçoivent-ils le `CLAUDE.md` du dépôt ? Les consignes de préférence en dépendent ; la doc de Matt l'affirme pour « every skill » sans préciser le cas des sous-agents.

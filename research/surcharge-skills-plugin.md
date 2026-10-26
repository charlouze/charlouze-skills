# Peut-on surcharger les skills d'un plugin Claude Code ?

Recherche pour le ticket [#2](https://github.com/charlouze/charlouze-skills/issues/2) (carte [#1](https://github.com/charlouze/charlouze-skills/issues/1)). État au 2026-10-26, Claude Code 2.1.310 en local, documentation consultée le même jour.

## Réponse courte

- **Non, un plugin ne peut ni remplacer ni masquer une skill d'un autre plugin.** Chaque skill de plugin vit sous son espace de noms `plugin:skill` ; deux plugins qui livrent une skill du même nom chargent **toutes les deux** les skills. Le seul « remplacement » que prévoit Claude Code se fait au niveau du **plugin entier**, et seulement pour un plugin chargé avec `--plugin-dir` qui porte le même nom de manifeste.
- **Le nom court (sans préfixe) est le seul point de friction**, et il ne sert pas à surcharger : quand plusieurs plugins livrent `grilling`, l'outil Skill refuse le nom court et demande le nom complet, et le modèle choisit lui-même (expérience E3).
- **Une skill personnelle ou de projet portant le même nom court, elle, intercepte les appels par nom court**, y compris ceux que les skills de Matt font entre elles (`Call the Skill tool with "grilling"`). C'est le seul vrai levier de surcharge, et il n'est pas accessible depuis un plugin.
- **Une skill peut en invoquer une autre**, d'un autre plugin ou de `~/.claude/skills`, du moment qu'elle est chargée dans la session et invocable par le modèle.
- **Un plugin peut dépendre d'un autre plugin** (`dependencies` dans `plugin.json`), y compris d'une autre marketplace avec une liste d'autorisation. **Il ne peut pas dépendre d'une skill utilisateur** : aucun mécanisme pour ça.
- **Dogfooding** : `claude --plugin-dir <racine du plugin>` charge le plugin depuis le dépôt, en place, pour une session, et `/reload-plugins` prend les modifications en compte. Autre voie : une marketplace locale.
- **Couper une seule skill de Matt** : `skillOverrides` ne s'applique pas aux skills de plugin. Une règle de permission `deny` sur `Skill(mattpocock-skills:<skill>)` empêche le modèle de l'invoquer, mais elle reste listée et l'utilisateur peut toujours la taper. Sinon, il faut désactiver le plugin entier.

## Méthode

- Documentation officielle de Claude Code, lue en Markdown brut (`https://code.claude.com/docs/en/<page>.md`) : [Skills][skills], [Plugin manifest reference][manifest], [Plugin dependencies][deps], [Plugin loading reference][loading], [Create a plugin][create], [Install and manage plugins][install], [Settings reference][settings].
- [CHANGELOG de Claude Code][changelog] pour dater les comportements.
- Fichiers locaux : le plugin de Matt installé (`~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/1.3.1/`), son entrée dans la marketplace officielle (`~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json`), les skills de wondelai (`~/.claude/skills/`).
- **Expériences** (E1 à E7) avec Claude Code 2.1.310 sous Windows, en mode non interactif (`claude -p`), avec deux plugins jetables chargés par `--plugin-dir` (`zz-test` et `aa-test`, chacun avec une skill `grilling` qui répond un mot témoin) et le plugin de Matt activé au niveau du projet. Les sorties `--output-format stream-json` montrent l'appel exact à l'outil Skill et sa réponse. Ces expériences montrent ce que fait cette version ; quand la doc ne décrit pas le comportement, elles ne garantissent pas qu'il restera stable.

Dans la suite, **[doc]** marque un fait tiré de la documentation, **[exp]** un fait observé en expérience, **[local]** un fait lu dans les fichiers installés, et **[inférence]** une déduction qui n'a pas été vérifiée directement.

## 1. Résolution des noms

### Espace de noms des skills de plugin

- [doc] Une skill de plugin s'appelle `/plugin-name:skill-name`. Le champ `name` du frontmatter remplace seulement le dernier segment ; le préfixe du plugin reste en place ([Skills, How a skill gets its command name][skills-name]).
- [doc] Le préfixe est le `name` du **manifeste** (`plugin.json`), pas le nom de l'entrée de marketplace : « The `name` in the manifest: what the plugin's components are namespaced under » ([Loading, Entry name and manifest name][loading-names]).
- [doc] Le nom court marche aussi : « The bare `/fancy` also invokes the skill unless another command already uses that name » ([Skills][skills-name]). Le changelog 2.1.265 l'élargit à la saisie en milieu de prompt : « a plugin skill is now found by its bare name » ([changelog][changelog]).
- [local] Matt s'appuie explicitement sur ce mécanisme pour les collisions de nom : « The Claude Code plugin exposes every skill under its plugin name, so you can always reach ours explicitly: `/mattpocock-skills:research` » (`.out-of-scope/harness-name-collisions.md`).

### Collisions entre emplacements

[doc] Tableau « Resolve skills that share a name » ([Skills][skills-collide]) :

| Même nom dans | Ce qui s'exécute |
| :- | :- |
| Deux emplacements parmi entreprise, personnel, projet | Entreprise > personnel > projet |
| L'un de ceux-là et une skill intégrée (*bundled*) | La skill de l'utilisateur remplace la commande intégrée, mais pas ses alias |
| Une skill de plugin et une skill à l'un des emplacements ci-dessus | **Les deux se chargent**, car les skills de plugin ont leur espace de noms `/plugin-name:skill-name` |

La doc ne dit rien d'une collision de **nom court** entre deux plugins. Les expériences ont comblé ce manque :

- **E1** [exp] : `zz-test` (`--plugin-dir`) et Matt (marketplace, projet) livrent tous deux `grilling`. Taper `/grilling` lance celle de `zz-test` ; `/mattpocock-skills:grilling` reste joignable.
- **E1c** [exp] : `zz-test` et `aa-test` sont chargés tous deux avec `--plugin-dir`. Taper `/grilling` lance la skill du plugin passé **en premier** sur la ligne de commande, quel que soit l'ordre alphabétique. Le nom court tapé par l'utilisateur va donc au premier plugin chargé. [inférence] Entre deux plugins de marketplace, l'ordre de chargement n'est pas documenté.
- **E3** [exp] : quand le **modèle** appelle l'outil Skill avec `"grilling"`, l'appel échoue : `Unknown skill: grilling. Several skills match that name: zz-test:grilling, mattpocock-skills:grilling — invoke one by its full name.` Le modèle a ensuite rappelé l'outil avec `mattpocock-skills:grilling`, de lui-même. Le changelog 2.1.269 documente le cas voisin, celui d'un nom court qui ne désigne qu'une seule skill de plugin ([changelog][changelog]).
- **E4** [exp] : avec une skill **de projet** `.claude/skills/grilling/` et le plugin de Matt, `/grilling` **et** l'appel modèle `Skill("grilling")` lancent tous deux la skill de projet, sans ambiguïté signalée.

### Un plugin ne peut pas prendre l'espace de noms d'un autre

- [doc] Le préfixe ne peut contenir ni `:` ni `@` dans le `name` du manifeste ([Manifest, name][manifest-name]). Si le `name` d'une skill commence déjà par le préfixe **de son propre plugin**, Claude Code ne le double pas (2.1.246 et suivantes, [Skills][skills-name]).
- **E6** [exp] : une skill de `zz-test` déclarée avec `name: mattpocock-skills:tdd` passe `claude plugin validate`, mais elle ne s'enregistre pas sous ce nom. `/mattpocock-skills:tdd` lance toujours la skill de Matt, et la skill de test reste joignable sous `/zz-test:hijack`, son nom de dossier.

### Le seul remplacement prévu : le plugin entier, par `--plugin-dir`

[doc] Quand des plugins activés d'origines différentes partagent un **nom de manifeste**, un plugin `--plugin-dir`, `--plugin-url` ou `CLAUDE_CODE_PLUGIN_DIRS` « replaces a same-named installed marketplace plugin », silencieusement : `claude plugin list` montre encore la version de marketplace comme activée ([Loading, Name conflicts][loading-conflicts]). Entre deux plugins de **marketplace** qui portent le même nom de manifeste, les deux apparaissent activés, mais les hooks de l'un d'eux sont ignorés. [inférence] La doc ne dit pas ce que deviennent les skills dans ce cas.

Conséquence [inférence] : une copie modifiée de Matt, nommée `mattpocock-skills` dans son manifeste, peut remplacer celle de la marketplace, mais seulement en session (`--plugin-dir`). C'est une bifurcation complète du plugin de Matt, pas une surcharge skill par skill.

## 2. Invoquer une skill depuis une autre

- [doc] « By default, Claude can invoke any skill that doesn't have `disable-model-invocation: true` set » ([Skills, Restrict Claude's skill access][skills-restrict]). L'outil Skill voit toutes les skills chargées dans la session : plugins, personnelles, projet. Les sous-agents les découvrent aussi depuis la 2.1.133 ([changelog][changelog]).
- [local] C'est la convention de Matt : une dépendance entre skills s'écrit comme une instruction explicite, `Call the Skill tool with "grilling"`, **avec le nom court** (`.agents/invocation.md`). Une skill appelable seulement par l'utilisateur (`disable-model-invocation: true`) ne peut être appelée par aucune autre.
- [local] Les skills de Matt s'appellent effectivement entre elles par nom court : `grilling`, `domain-modeling`, `tdd`, `code-review`, `codebase-design`, `research`, `prototype`, `writing-for-agents` (recherche de `Skill tool` dans `skills/engineering` et `skills/productivity`).
- [exp] Invoquer une skill d'un autre plugin par son nom complet fonctionne : `Skill("mattpocock-skills:grilling")` → `Launching skill: mattpocock-skills:grilling` (E3).
- **Skills utilisateur (wondelai)** : [local] `~/.claude/skills/domain-driven-design/` et les autres sont de simples skills personnelles, sans `.claude-plugin/`. [doc] Elles se chargent dans tous les projets de la machine, mais pas dans Cowork ni dans les sessions cloud ([Skills, Choose where skills load][skills-where]). [inférence] Une skill de plugin peut donc écrire `Call the Skill tool with "domain-driven-design"`, et l'appel aboutit quand la skill est installée. Sans elle, l'outil répond « Unknown skill » et rien ne permet de déclarer qu'elle est requise.

[exp + inférence] **Effet de bord à connaître** : les appels internes de Matt utilisent des noms courts. Si notre plugin livre une skill du même nom (`grilling`, `tdd`…), ces appels deviennent ambigus (E3) et le modèle choisit lui-même la cible, rien ne garantit que ce sera la nôtre. Si c'est une skill **de projet ou personnelle** qui porte ce nom, elle capte ces appels de façon déterministe (E4). Les noms courts `code-review` et `research` existent aussi parmi les skills intégrées de cette session ; Matt considère ce cas comme hors de son périmètre (`.out-of-scope/harness-name-collisions.md`).

## 3. Dépendances

- [doc] `plugin.json` accepte `dependencies` : un tableau de `"name"`, de `"name@marketplace"` ou de `{ "name", "marketplace", "version" }` ([Manifest, dependencies][manifest-deps]). À l'installation, Claude Code installe et active les dépendances au même scope. Il refuse de désactiver un plugin dont un autre plugin activé dépend ([Install, Plugins with dependencies][install-deps], changelog 2.1.143).
- [doc] **Dépendance vers une autre marketplace** : par défaut, Claude Code ne l'installe pas, sauf si l'utilisateur l'a déjà installée et activée au même scope. Pour l'autoriser, il faut ajouter la marketplace cible à `allowCrossMarketplaceDependenciesOn` dans le `marketplace.json` **racine**, celui qui héberge notre plugin. Quand la dépendance est déclarée dans `plugin.json` et que la marketplace n'est pas autorisée, l'installation se termine sans elle et notre plugin ne se charge pas ([Dependencies, Depend on a plugin from another marketplace][deps-cross]).
- [local] Matt est publié dans `claude-plugins-official`, avec une source `url` qui pointe sur `https://github.com/mattpocock/skills.git` à un sha épinglé (entrée de marketplace locale). La dépendance s'écrirait donc `"mattpocock-skills@claude-plugins-official"`, et notre marketplace ajouterait `"allowCrossMarketplaceDependenciesOn": ["claude-plugins-official"]`.
- [doc] Une contrainte de version se résout sur les tags git `<plugin-name>--v<version>` du dépôt du plugin. Pour un plugin qui a son propre dépôt, l'installation échoue si aucun tag ne satisfait la contrainte ([Dependencies, Release / How a constraint resolves][deps-tags]). [local] Le dépôt de Matt est tagué `v1.3.1`, pas `mattpocock-skills--v1.3.1` (`git ls-remote --tags`). [inférence] Une contrainte de version sur Matt échouerait donc aujourd'hui, et seule une dépendance sans version est utilisable.
- [doc] **Aucun mécanisme pour dépendre d'une skill qui n'est pas dans un plugin** : `dependencies` ne vise que des plugins ([Dependencies][deps]). Le champ de frontmatter `compatibility` n'est qu'une chaîne libre de 500 caractères au plus ([Skills, Frontmatter reference][skills-frontmatter]). [inférence] Pour les skills de wondelai, il ne reste que la documentation et la vérification à l'exécution, sauf à les republier sous forme de plugin, ce qui suppose de les copier (licence MIT).
- [doc] Pour tester un plugin avec sa dépendance en local : `claude --plugin-dir ./dep --plugin-dir ./mon-plugin`. La copie locale satisfait la dépendance, et une entrée qui nomme une marketplace correspond aussi à la copie locale (2.1.242 et suivantes) ([Dependencies, Test a plugin and its dependency locally][deps-local]).

## 4. Désactiver une skill

| Mécanisme | Skills personnelles / projet | Skills de plugin |
| :- | :- | :- |
| `skillOverrides` (`on`, `name-only`, `user-invocable-only`, `off`) dans les settings, ou menu `/skills` | Oui | **Non** : « Plugin skills are not affected by `skillOverrides`. Manage those through `/plugin` instead. » ([Skills][skills-overrides], [Settings][settings-overrides]). Confirmé par E7 [exp] : avec `"mattpocock-skills:tdd": "off"` et `"tdd": "off"`, la skill se lance quand même |
| Frontmatter `disable-model-invocation` | Oui (on édite le fichier) | Seulement en modifiant le plugin, donc en le bifurquant |
| Permission `deny` : `Skill(<nom>)` | Oui | **Partiellement** (E5) [exp] : `deny: ["Skill(mattpocock-skills:tdd)"]` bloque l'appel du modèle (`Skill execution blocked by permission rules`), mais l'utilisateur peut encore taper `/mattpocock-skills:tdd`, et la skill reste listée dans l'événement `init` |
| Désactiver ou désinstaller | Supprimer le dossier | Le **plugin entier** seulement, via `/plugin` ou `claude plugin disable` ([Skills, Remove a skill][skills-remove]) |

[doc] Pour les règles `deny`, la forme `Skill(skill:<nom>)` couvre la skill sous tous ses noms, alias compris ([Permissions][permissions], [Skills][skills-restrict]). [inférence] On ne sait pas si une skill de plugin bloquée par `deny` garde sa description dans la liste que voit le modèle : elle continuerait alors à consommer du contexte.

**Réponse à « l'utilisateur peut-il couper une skill de Matt et garder le reste ? »** Pas proprement. Il peut empêcher le modèle de l'invoquer avec une règle `deny`, ou la court-circuiter par nom court avec une skill personnelle ou de projet du même nom (E4). Mais rien ne la retire de `/` ni de `/mattpocock-skills:<skill>`, à moins de désactiver tout le plugin.

## 5. Installer le plugin depuis ce dépôt pour le tester (dogfooding)

1. **`--plugin-dir`, pour une session** [doc] : `claude --plugin-dir <racine du plugin>`. Le plugin se charge en place, sans copie ni écriture dans les settings ; `/reload-plugins` applique les modifications ([Create, Develop without a marketplace][create-dev]). Points d'attention :
   - [doc] `--plugin-dir` attend la **racine du plugin**, le dossier qui contient `.claude-plugin/plugin.json`. Pointé sur une racine de marketplace, il ne lit pas `marketplace.json`, et les plugins qui se trouvent sous `plugins/` ne se chargent pas, sans erreur ([Create, Test and debug][create-debug]). Un dossier qui contient plusieurs plugins est accepté depuis la 2.1.265.
   - [doc] Si une version installée depuis une marketplace porte le même nom de manifeste, la copie `--plugin-dir` la remplace pour la session ([Loading, Name conflicts][loading-conflicts]). C'est pratique pour tester la version de développement par-dessus la version publiée.
   - [doc] `CLAUDE_CODE_PLUGIN_DIRS` fait la même chose sans le drapeau (2.1.280 et suivantes), mais pas depuis les settings de projet ou locaux.
   - [exp] Vérifié dans ce dépôt : avec `--plugin-dir`, le plugin de test se charge à côté de Matt, activé au niveau du projet par `.claude/settings.json`.
2. **Marketplace locale** [doc] : `claude plugin marketplace add ./` (un dossier qui contient `.claude-plugin/marketplace.json`), puis `claude plugin install <plugin>@<marketplace> --scope local`. Les plugins référencés par chemin relatif dans une marketplace ajoutée depuis un chemin local se chargent **en place** : les modifications s'appliquent au prochain démarrage ou à `/reload-plugins`, sans changer de version ([Loading, In-place and copied plugins][loading-inplace]). Cette voie teste aussi le `marketplace.json` et les dépendances réelles. Une source `directory` dans `extraKnownMarketplaces` exige un chemin **absolu** ([Settings][settings]), ce qui la rend peu portable dans un `.claude/settings.json` commité.
3. **Plugin de dossier de skills** [doc] : un dossier `.claude/skills/<nom>/` qui contient `.claude-plugin/plugin.json` se charge au démarrage sous l'identifiant `<nom>@skills-dir`, après le dialogue de confiance de l'espace de travail. Seulement depuis le répertoire de travail principal, et dans l'app desktop, depuis le checkout principal plutôt que le worktree ([Loading, Plugins shared through a repository][loading-repo]). [inférence] Cette voie impose de placer le plugin sous `.claude/skills/`, ce qui cadre mal avec un dépôt qui le publie.

## Ce que ça implique pour la surcouche

Les faits ci-dessus dessinent quatre options. Le choix revient à un ticket ultérieur.

| Option | Ce que ça donne | Coûts et risques |
| :- | :- | :- |
| **A. Ajouter sous d'autres noms** (`charlouze-skills:<x>`), Matt intact à côté | Seule voie que Claude Code prévoit. Nos skills peuvent appeler celles de Matt par nom complet (`mattpocock-skills:grilling`) et celles de wondelai par nom court | Les skills de Matt restent toutes visibles et invocables, et leurs enchaînements internes par nom court continuent de viser les skills de Matt, pas les nôtres. Deux skills proches se disputent le déclenchement automatique, et on paie le contexte des deux |
| **B. Reprendre les mêmes noms courts** dans notre plugin | Rien n'est remplacé. `/grilling` tapé va au premier plugin chargé (E1/E1c), et `Skill("grilling")` devient ambigu, le modèle choisit (E3) | Comportement non déterministe, et cela casse les enchaînements internes de Matt. À éviter |
| **C. Surcharger par des skills personnelles ou de projet** (même nom court que la skill de Matt) | Seul mécanisme qui intercepte de façon déterministe les appels de Matt par nom court (E4) | Ne passe pas par un plugin : il faut copier des fichiers dans `~/.claude/skills` ou `.claude/skills`, donc installer hors du système de plugins. Absent de Cowork et du cloud pour les skills personnelles. `/mattpocock-skills:<x>` reste joignable |
| **D. Bifurquer Matt** (copie modifiée) | Contrôle total ; une copie qui garde le nom de manifeste `mattpocock-skills` remplace l'originale, mais seulement en `--plugin-dir` | Toutes les mises à jour de Matt sont à fusionner nous-mêmes. Hors session, deux plugins de marketplace qui portent le même nom de manifeste ne se remplacent pas proprement |

Faits transverses :

- La dépendance `mattpocock-skills@claude-plugins-official` est déclarable, sans contrainte de version tant que Matt ne publie pas de tags `mattpocock-skills--v*`. Il faut aussi `allowCrossMarketplaceDependenciesOn` dans notre marketplace.
- Aucune dépendance déclarable vers les skills de wondelai : ce prérequis se documente et se vérifie à l'exécution.
- L'utilisateur ne peut pas couper finement une skill de Matt. Le mieux disponible est une règle `deny` sur l'invocation par le modèle.

## Questions ouvertes (non vérifiées)

- L'ordre de chargement, et donc le propriétaire du nom court tapé par l'utilisateur, entre deux plugins installés depuis des **marketplaces**. Seul le cas `--plugin-dir` a été testé.
- Une skill de plugin bloquée par `deny` garde-t-elle sa description dans la liste de skills que voit le modèle ?
- Ce que deviennent les **skills** quand deux plugins de marketplace portent le même nom de manifeste. La doc ne parle que des hooks.

[skills]: https://code.claude.com/docs/en/skills
[skills-name]: https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name
[skills-collide]: https://code.claude.com/docs/en/skills#resolve-skills-that-share-a-name
[skills-where]: https://code.claude.com/docs/en/skills#choose-where-skills-load
[skills-restrict]: https://code.claude.com/docs/en/skills#restrict-claude%E2%80%99s-skill-access
[skills-overrides]: https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings
[skills-remove]: https://code.claude.com/docs/en/skills#remove-a-skill
[skills-frontmatter]: https://code.claude.com/docs/en/skills#frontmatter-reference
[manifest]: https://code.claude.com/docs/en/plugins/manifest-reference
[manifest-name]: https://code.claude.com/docs/en/plugins/manifest-reference#name
[manifest-deps]: https://code.claude.com/docs/en/plugins/manifest-reference#dependencies
[deps]: https://code.claude.com/docs/en/plugins/dependencies
[deps-cross]: https://code.claude.com/docs/en/plugins/dependencies#depend-on-a-plugin-from-another-marketplace
[deps-tags]: https://code.claude.com/docs/en/plugins/dependencies#how-a-constraint-resolves-against-tags
[deps-local]: https://code.claude.com/docs/en/plugins/dependencies#test-a-plugin-and-its-dependency-locally
[loading]: https://code.claude.com/docs/en/plugins/loading
[loading-names]: https://code.claude.com/docs/en/plugins/loading#entry-name-and-manifest-name
[loading-conflicts]: https://code.claude.com/docs/en/plugins/loading#name-conflicts
[loading-inplace]: https://code.claude.com/docs/en/plugins/loading#in-place-and-copied-plugins
[loading-repo]: https://code.claude.com/docs/en/plugins/loading#plugins-shared-through-a-repository
[create]: https://code.claude.com/docs/en/plugins/create
[create-dev]: https://code.claude.com/docs/en/plugins/create#develop-without-a-marketplace
[create-debug]: https://code.claude.com/docs/en/plugins/create#test-and-debug
[install]: https://code.claude.com/docs/en/plugins/install
[install-deps]: https://code.claude.com/docs/en/plugins/install#plugins-with-dependencies
[settings]: https://code.claude.com/docs/en/settings-reference
[settings-overrides]: https://code.claude.com/docs/en/settings-reference#skilloverrides
[permissions]: https://code.claude.com/docs/en/permissions
[changelog]: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md

# PR empilées sur GitHub : offre native, outils, fusion d'une pile

Recherche pour le ticket #4 de la carte #1. État au 26 octobre 2026.

Question : que propose GitHub pour empiler des PR, comment chaque option met à jour les PR du dessus quand celle du dessous change, comment se fusionne une pile, et ce que ça implique pour une revue qui ne veut pas voir l'historique réécrit avant validation.

Convention : **[F]** marque un fait lu dans une source primaire citée, **[I]** une inférence de ma part, **[?]** un point que je n'ai pas pu vérifier.

## Résumé

- GitHub propose désormais des **PR empilées natives** (*stacked pull requests*) : aperçu public le 30 juillet 2026, disponibilité générale le 6 octobre 2026 sur tous les plans de github.com [F, S1, S2]. Aucune activation n'est nécessaire [F, S6].
- Le modèle natif est **fondé sur le rebase** : une pile doit avoir un « historique linéaire » pour être fusionnée, la mise à jour passe par un rebase en cascade (local ou côté serveur) puis un force-push, et après la fusion du bas de la pile, GitHub **rebase automatiquement** les branches restantes [F, S3, S4, S5].
- Il n'existe **aucun mode « merge »** (fusionner le parent dans l'enfant au lieu de rebaser) : c'est une demande ouverte, sans réponse des mainteneurs (gh-stack #354, #445, #553) [F, S14, S15, S16].
- En compensation, GitHub **conserve les approbations** quand un rebase de pile ne change pas le diff, même si la règle « dismiss stale approvals » est active [F, S2, S5].
- Une pile se fusionne **du bas vers le haut, de façon atomique** : fusionner une PR fusionne aussi toutes celles du dessous ; les trois méthodes (merge, squash, rebase) et la merge queue sont prises en charge [F, S4, S5].
- L'outil officiel `gh stack` (extension `github/gh-stack`, licence MIT) est **pilotable sans interaction** par un agent, avec des drapeaux dédiés et des codes de sortie documentés ; GitHub fournit même une skill d'agent [F, S7, S9].
- Parmi les outils tiers, seul **git-town** synchronise par **merge** par défaut (pas de réécriture) ; Graphite, spr, gh-stack, git-branchless rebasent et force-poussent ; ghstack ne force-pousse jamais les branches de PR mais impose ses propres branches synthétiques et un atterrissage hors du bouton de fusion [F, S18–S25].

## 1. Le support natif de GitHub

### Chronologie

| Date | Événement | Source |
|---|---|---|
| 19 mai 2020 | Quand la branche d'une PR fusionnée est supprimée, les PR qui la ciblaient sont **reciblées** sur la base de la PR fusionnée au lieu d'être fermées. Seul support « pile » de GitHub avant 2026. | S13 |
| 30 juillet 2026 | PR empilées en aperçu public ; extension `gh-stack` ; merge queue « progressivement dans les semaines qui suivent ». | S1 |
| 6 octobre 2026 | Disponibilité générale sur tous les plans github.com ; GitHub Enterprise Server « dans une prochaine version ». | S2 |

### Le modèle

- Une pile est une chaîne d'au moins deux PR **dans le même dépôt** : la PR du bas cible le *trunk* (souvent `main`, mais n'importe quelle branche), chaque PR suivante cible la branche de la PR du dessous [F, S3]. Pas de pile entre forks, pas de branches en arbre : une seule chaîne linéaire [F, S3, S6]. Jusqu'à 100 PR par pile [F, S8].
- On crée une pile en CLI (`gh stack`), sur le site (option **Create stack** à la création d'une PR dont la base est la branche d'une autre PR, ou bannière qui propose de transformer des PR déjà chaînées en pile), via l'API REST (endpoints Stacks : lister, créer, étendre, dissoudre) ; GraphQL est en lecture seule [F, S3, S10, S11].
- Les règles (revues requises, checks requis, CODEOWNERS, code scanning) de **la base de la pile** s'appliquent à **chaque** PR, même au milieu de la pile ; un workflow Actions déclenché sur `pull_request` vers `main` tourne pour chaque PR de la pile [F, S5]. Les métadonnées `github.event.pull_request.stack.{number,size,position,base.ref,base.sha}` permettent de limiter les jobs coûteux [F, S12].

### Comment les PR du dessus suivent un changement du dessous

- **Rebase, toujours.** La doc officielle de gestion d'une pile : corriger dans la branche qui possède le changement, puis `gh stack rebase --upstack`, puis `gh stack push`, qui pousse avec `--force-with-lease` [F, S4]. La doc de revue décrit la même boucle pour traiter un retour de revue [F, S17].
- **Historique linéaire obligatoire pour fusionner.** « A fully linear history between every branch in the stack is a strict requirement for merging. » Une pile perd sa linéarité quand on pousse sur une branche basse ou quand le trunk avance [F, S5].
- **Bouton « Rebase stack »** dans la boîte de fusion : rebase en cascade côté serveur, puis **force-push** de chaque branche [F, S4]. Depuis la GA, les commits produits sont signés et l'auteur d'origine est conservé [F, S2] (la page « Managing » dit encore qu'ils ne sont pas signés : contradiction dans la doc, la page de référence et le changelog GA disent « signés ») [F, S2, S4, S5].
- **Rebase automatique après fusion.** Quand la PR du bas est fusionnée, « the remaining branches are automatically rebased so the next pull request targets the default base branch » [F, S3]. Pour une fusion squash, CLI et serveur utilisent `git rebase --onto` pour rejouer seulement les commits propres à la branche [F, S8].
- **Approbations conservées.** « Rebasing a stack doesn't count as a new, reviewable commit if the diff does not change. Approvals are retained in this situation, even when the Dismiss stale pull request approvals when new commits are pushed rule is enabled. » [F, S5]
- **Qu'est-ce que « linéaire » exactement ?** Côté CLI, deux définitions coexistent dans le code de gh-stack : l'affichage (`view`) ne vérifie que « la pointe du parent est un ancêtre de l'enfant », alors que `modify` exige en plus **aucun commit de merge** entre parent et enfant [F, S19]. Ce que le **serveur** exige pour autoriser la fusion n'est pas documenté au-delà de « fully linear history » [?]. Autrement dit : on ne sait pas si une branche enfant mise à jour par `git merge parent` (le parent devient ancêtre, mais avec un commit de merge) est acceptée à la fusion. **À tester sur un dépôt jetable.**

### Comment se fusionne une pile

- Toujours **du bas vers le haut**. Fusionner une PR fusionne aussi toutes les PR non fusionnées du dessous, en une opération ; on ne peut pas fusionner une PR du milieu seule [F, S4, S5].
- Conditions : la PR et **toutes celles du dessous** sont approuvées et ont leurs checks au vert ; la pile est linéaire [F, S4, S5].
- Méthodes [F, S5] :
  - **merge commit** : un commit de merge par PR (le changelog GA le confirme ; la FAQ du dépôt gh-stack parle encore d'« un commit de merge pour tout le groupe ») [F, S2, S8] ;
  - **squash** : un commit par PR, donc `n` commits pour `n` PR ;
  - **rebase** : les commits de chaque PR rejoués sur la base.
- Fusion directe : **atomique**, tout ou rien [F, S8, S11]. Les PR du dessus restent ouvertes et sont **reciblées** sur la base de la pile, puis rebasées [F, S3, S4]. Si la branche de base de la pile est supprimée, la pile est reciblée au lieu d'être fermée [F, S2].
- **Merge queue** : la pile entre dans la file dans l'ordre ; si une PR est éjectée, toutes celles du dessus le sont aussi ; un groupe de fusion peut dépasser sa taille maximale de 50 % pour garder la pile ensemble [F, S4, S5]. Via la file, les PR sont évaluées une à une et peuvent atterrir dans des groupes successifs [F, S7, S8].
- **API** : seule l'API de fusion **asynchrone** sait fusionner une pile ; les endpoints de fusion synchrones historiques (et donc `gh pr merge`) ne le peuvent pas [F, S6, S9, S11]. Les règles sont évaluées au moment de la fusion effective, et l'échec remonte au polling [F, S11].
- **Auto-merge** : le changelog GA annonce un déploiement « dans les semaines qui viennent », la page « Merging stacked pull requests » dit encore « not supported » [F, S2, S4]. À considérer comme indisponible tant qu'on ne l'a pas constaté [I].
- **Contournement des règles** : seul un utilisateur autorisé à contourner, et seulement pour la PR la plus basse ; pas pour la pile entière, et pas depuis `gh stack merge` [F, S2, S5, S7].

### Ce que voit le relecteur (UX de revue d'une couche)

- Chaque PR n'affiche que **le diff de sa couche**, c'est-à-dire contre la branche du dessous [F, S1, S3]. Ce n'est pas nouveau : c'est l'effet normal d'une PR dont la base est la branche parente [I].
- Une **carte de la pile** dans l'en-tête persistant et la boîte de fusion montre chaque PR, son statut, et permet de naviguer ; raccourcis Shift+J / Shift+K ; la pile apparaît dans la liste des PR ; la timeline montre l'entrée et la sortie d'une PR dans une pile [F, S2, S3].
- Les approbations survivent à un rebase qui ne change pas le diff [F, S5]. En revanche, **rien dans la doc ne dit que « changes since your last review » survit à un rebase** : un utilisateur rapporte que cette vue échoue après le rebase automatique, parce que le commit relu n'existe plus dans la branche [F (témoignage), S16]. Le seul outil natif après un force-push reste le lien « force-pushed » de la timeline, qui ouvre une comparaison à deux points entre l'ancienne et la nouvelle tête [F, S26]. Après un rebase sur un parent modifié, cette comparaison mélange les changements du parent et ceux de la couche [I].

### L'extension `gh stack` (outil officiel)

- Dépôt `github/gh-stack`, licence MIT, dernière version v0.2.1 du 9 octobre 2026 [F, S27]. Prérequis selon les pages : `gh` ≥ 2.90 et Git ≥ 2.20 (quickstart), Git ≥ 2.36 (référence et skill) [F, S7, S9, S10]. Sur ce poste : `gh` 2.102.0 et `gh-stack` v0.1.1 déjà installé, donc à mettre à jour [F, constat local].
- Commandes : `init`, `add`, `view`, `checkout`, `modify`, `unstack`, `submit`, `sync`, `rebase`, `push`, `link`, `merge`, navigation (`up`, `down`, `top`, `bottom`, `trunk`) [F, S7].
- **Usage par un agent** : la skill officielle (`gh skill install github/gh-stack`) donne la table des formes non interactives : `view --json`, `submit --auto`, `merge <cible> --yes`, `init <branche>...`, `add <branche>`, `checkout <cible>` ; `modify` et `switch` n'ont **aucun** chemin non interactif [F, S9]. Codes de sortie documentés (3 = conflit de rebase, 8 = pile verrouillée…) [F, S7]. `sync` est « sûr en automatisation » sauf en cas de divergence entre pile locale et distante : il s'arrête alors en sortant avec 0 sans rien pousser [F, S7, S9].
- `submit --auto` crée les PR en **brouillon**, sauf avec `--open` [F, S7].
- `gh stack link` crée ou étend une pile sur GitHub **sans suivi local** à partir de branches gérées par un autre outil (jj, Sapling, git-town) : il pousse les branches, crée les PR manquantes avec la bonne base, et lie le tout [F, S7, S18]. C'est la porte d'entrée pour piloter les branches à la main (par exemple avec des merges) tout en profitant de l'UI native [I].
- Signaux de maturité : plusieurs bugs ouverts touchent exactement notre usage, par exemple `sync` qui sort avec 0 alors que son push a échoué (#472), ou `merge` qui rebase silencieusement et fait tomber les approbations d'une PR dépendante (#446) [F, S28, S29]. Ce sont des rapports d'utilisateurs, non confirmés par les mainteneurs [I].

## 2. Les outils tiers

| Outil | Mise à jour des enfants | Fusion d'une pile | Pilotage non interactif | Coût / compte | Compatible « pas de réécriture avant validation » |
|---|---|---|---|---|---|
| **GitHub natif + `gh stack`** | Rebase en cascade + force-push (`--force-with-lease`) ; rebase serveur auto après fusion du bas [S3, S4] | Bas → haut, atomique, merge/squash/rebase, merge queue [S5] | Oui, drapeaux dédiés et codes de sortie ; `modify` interactif seulement [S7, S9] | Gratuit, tous plans github.com ; GHES plus tard [S2] | **Non par défaut.** Merge-mode demandé, pas fourni [S14–S16]. Approbations conservées si diff inchangé [S5] |
| **Graphite (`gt`)** | `gt restack` rebase ; `gt submit` force-pousse (`--force-with-lease` par défaut) [S20] | `gt merge` fusionne de trunk à la branche courante « via Graphite » ; merge queue sur plans payants [S20, S21] | Oui, drapeau global `--no-interactive` [S20] | CLI dans le plan gratuit Hobby ; Team 40 $/utilisateur/mois ; compte Graphite via l'app GitHub [S21, S22] | **Non.** Aucune option merge [S20] |
| **spr (ejoffe)** | Un commit = une PR ; on amende, `git spr update` rebase [S23] | `spr merge` combine les commits jusqu'à la PR choisie en **une seule PR**, la fusionne et ferme les intermédiaires [S23] | Oui (CLI) [S23] | MIT, pas de service tiers [S23] ; dernière version avril 2026 [S27] | **Non.** Le modèle repose sur l'amendement des commits |
| **git-town** | `sync-feature-strategy` = **`merge` par défaut** (parent fusionné dans l'enfant, pas de force-push) ; `rebase` et `compress` en option [S24] | `git town ship` branche la plus ancienne d'abord ; stratégies `api` (bouton de fusion, défaut), `always-merge`, `fast-forward`, `squash-merge` [S25, S30] | Oui, `--non-interactive`, `--dry-run` [S31] | MIT, gratuit, v24.1.0 de septembre 2026 [S27] | **Oui** pour la synchro. Risque de « conflits fantômes » après une fusion squash, partiellement résolus automatiquement [S25] |
| **git-branchless** | `git submit` force-pousse les branches existantes [S32] | Pas de création de PR GitHub documentée (seul Phabricator l'est) [S32] | CLI | Apache-2.0 [S27] | **Non** |
| **Sapling (`sl pr`)** | PR « chevauchantes » : chaque PR contient aussi tous les commits du dessous [S33] | Non documenté | CLI | GPL-2.0 [S27] | **Non pertinent** : la doc recommande ReviewStack plutôt que l'UI GitHub [S33, S34] |
| **ghstack** | Branches synthétiques `gh/<user>/N/{base,head,orig}` ; `base` et `head` ne sont **jamais force-poussées**, les rebases ajoutent des commits de merge [S35] | `ghstack land` uniquement, **pas le bouton de fusion** [S35] | CLI | MIT, jeton PAT [S35] | **Oui côté PR**, mais modèle étranger à l'UI native (branches synthétiques, atterrissage hors GitHub) [I] |

Interopérabilité avec la pile native : GitHub documente explicitement jj, Sapling et git-town comme gestionnaires locaux, couplés à `gh stack link` [F, S18]. Je n'ai trouvé aucune source primaire sur la cohabitation de Graphite avec les piles natives [?].

## 3. Pistes compatibles avec « pas de réécriture avant validation »

Ces pistes sont des **inférences** construites à partir des faits ci-dessus ; aucune n'a été testée.

1. **Fusionner le parent dans l'enfant** (`git merge parent` sur l'enfant, push normal), puis lier la pile avec `gh stack link`. Pas de force-push pendant la revue ; le relecteur garde « changes since your last review ». Inconnue bloquante : le serveur accepte-t-il ces commits de merge comme « historique linéaire » au moment de la fusion [?] ? Si non, il faudra un `Rebase stack` juste avant la fusion, donc **après** l'approbation, ce qui garde les approbations si le diff de chaque couche est inchangé [F, S5].
2. **Corrections en `fixup!`** sur la couche concernée, puis propagation par merge (piste 1). À la validation : soit fusion **squash**, qui absorbe les fixups sans réécrire la branche (un commit par PR [F, S5]) ; soit `git rebase --autosquash` puis `gh stack rebase` / push, après approbation, avec approbations conservées si le diff ne change pas [F, S5].
3. **Fusionner toute la pile d'un coup, par le haut**, une fois toutes les couches approuvées : l'opération est atomique [F, S11], donc aucune PR non approuvée ne subit le rebase automatique qui suit la fusion du bas [I]. Fusionner la pile morceau par morceau, au contraire, déclenche ce rebase sur des PR peut-être pas encore approuvées [F, S3 ; I].
4. **git-town en local** (synchro par merge, `--non-interactive`) + `gh stack link` pour l'UI native. Même inconnue que la piste 1 sur la linéarité, et le risque de conflits fantômes après squash [F, S25]. Le contournement décrit dans gh-stack #354 : après une fusion squash, fusionner `main` dans l'**ancien parent**, puis ce parent dans l'enfant, plutôt que `main` directement dans l'enfant [F (témoignage), S14].

## Ce que ça implique

### Pour l'objectif 1 : l'agent enchaîne seul des tickets en PR empilées

- **Faits favorables.** La pile native existe, est gratuite, n'a rien à activer, et vise explicitement les agents : « An agent completes one task, then starts the next task that builds on it. That sequence maps directly onto a stack » [S3]. L'outil officiel a une skill d'agent et un contrat non interactif documenté [S9]. Les checks et règles de `main` tournent sur chaque couche [S5].
- **Compromis.** Un ticket = une couche = une PR colle au modèle, à condition que les tickets forment une **chaîne linéaire** : pas d'arbre, pas de fork [S6]. Deux tickets indépendants ne devraient pas être empilés (chacun sur `main`) [I, conseil aussi donné par git-town S25].
- **Points à surveiller.** `gh stack` est jeune (v0.2.x) et a des bugs ouverts sur `sync` et `merge` [S28, S29]. `submit --auto` crée des brouillons [S7]. L'auto-merge n'est pas encore là de façon sûre [S2, S4]. Comme les PR sont ouvertes sous l'identité de l'app, l'utilisateur peut les approuver lui-même [I].
- **Traitement des retours après la série.** La doc native prescrit : corriger dans la couche qui possède le changement, puis propager vers le haut [S17]. C'est aussi ce que la skill officielle impose [S9]. Le volet « sous-agents qui reprennent les commentaires » reste à concevoir (déjà noté dans la carte).

### Pour l'objectif 2 : pas de réécriture d'historique avant approbation

- **Conflit frontal avec le chemin officiel.** Le natif et tous les outils majeurs (gh-stack, Graphite, spr, git-branchless) propagent par **rebase + force-push** [S4, S20, S23, S32]. Le rebase automatique après fusion du bas touche les PR du dessus même non approuvées [S3]. Le « merge-mode » est une demande ouverte sans réponse [S14–S16].
- **Ce que GitHub donne en échange.** Les approbations survivent à un rebase sans changement de diff [S5]. Ça règle « l'approbation tombe », pas « le relecteur perd le fil de ce qu'il a déjà vu » [S16].
- **Marges de manœuvre.** Propager par merge pendant la revue (pistes 1, 2, 4), fusionner la pile entière par le haut une fois tout approuvé (piste 3), et réserver la réécriture (autosquash, rebase de pile) à l'après-approbation. Tout repose sur **une inconnue à lever par un prototype** : le serveur accepte-t-il, au moment de la fusion, une pile dont les enfants contiennent des merges du parent ?
- **Alternative radicale.** Ne pas utiliser la pile native : PR chaînées classiques (base = branche parente), mises à jour par merge, reciblage automatique à la suppression de la branche fusionnée [S13]. On perd la carte de pile, la fusion atomique, la merge queue de pile et l'évaluation des règles de `main` sur chaque couche [I, d'après S3–S5].

## Sources

Sources primaires : changelog et docs GitHub, dépôts et docs officiels des outils. Les issues GitHub de gh-stack sont des témoignages d'utilisateurs, sans réponse des mainteneurs au 26 octobre 2026.

- S1 — GitHub Changelog, « Stacked pull requests are now in public preview », 30/07/2026 : https://github.blog/changelog/2026-07-30-stacked-pull-requests-are-now-in-public-preview/
- S2 — GitHub Changelog, « Stacked pull requests generally available », 06/10/2026 : https://github.blog/changelog/2026-10-06-stacked-pull-requests-generally-available/
- S3 — GitHub Docs, About stacked pull requests : https://docs.github.com/en/pull-requests/get-started/about-stacked-prs
- S4 — GitHub Docs, Managing stacked pull requests : https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/managing-stacked-pull-requests ; Merging stacked pull requests : https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/merging-stacked-pull-requests
- S5 — GitHub Docs, Stacked pull requests (référence) : https://docs.github.com/en/pull-requests/reference/stacked-pull-requests
- S6 — GitHub Docs, Roll out stacked pull requests to your organization : https://docs.github.com/en/pull-requests/tutorials/roll-out-stacked-prs
- S7 — GitHub Docs, Stacked pull requests CLI commands : https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands
- S8 — FAQ du dépôt gh-stack : https://github.com/github/gh-stack/blob/main/docs/src/content/docs/faq.md
- S9 — Skill d'agent officielle : https://github.com/github/gh-stack/blob/main/skills/gh-stack/SKILL.md
- S10 — GitHub Docs, Quickstart : https://docs.github.com/en/pull-requests/get-started/stacked-prs-quickstart ; Creating stacked pull requests : https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/creating-stacked-pull-requests
- S11 — GitHub Docs, Stacked pull requests APIs and webhooks : https://docs.github.com/en/pull-requests/reference/stacked-pull-requests-apis-and-webhooks
- S12 — GitHub Docs, Optimizing CI for stacked pull requests : https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/optimizing-ci-for-stacked-pull-requests
- S13 — GitHub Changelog, « Pull request retargeting », 19/05/2020 : https://github.blog/changelog/2020-05-19-pull-request-retargeting
- S14 — gh-stack #354, « `gh stack sync` always rebases, which breaks PR review history » : https://github.com/github/gh-stack/issues/354
- S15 — gh-stack #445, « support merge-based stack synchronization without force-pushing » : https://github.com/github/gh-stack/issues/445
- S16 — gh-stack #553, « Stacked PRs need to support non-linear history ("merge-mode") » : https://github.com/github/gh-stack/issues/553
- S17 — GitHub Docs, Reviewing stacked pull requests : https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/reviewing-stacked-pull-requests
- S18 — GitHub Docs, Use other tools with stacked pull requests : https://docs.github.com/en/pull-requests/reference/use-other-tools-with-stacked-pull-requests
- S19 — Code gh-stack, `CheckStackLinearity` : https://github.com/github/gh-stack/blob/main/internal/modify/preconditions.go ; vérification d'affichage : https://github.com/github/gh-stack/blob/main/cmd/view.go
- S20 — Graphite, Command reference : https://graphite.com/docs/command-reference ; Restack branches : https://graphite.com/docs/restack-branches
- S21 — Graphite, Pricing : https://graphite.com/pricing
- S22 — Graphite, Authenticate with the GitHub App : https://graphite.com/docs/authenticate-with-github-app
- S23 — spr : https://github.com/ejoffe/spr
- S24 — git-town, sync-feature-strategy : https://www.git-town.com/preferences/sync-feature-strategy
- S25 — git-town, Stacked changes : https://www.git-town.com/stacked-changes
- S26 — GitHub Changelog, « Force push timeline event », 15/11/2018 : https://github.blog/changelog/2018-11-15-force-push-timeline-event/
- S27 — Métadonnées des dépôts (licence, dernière release) lues via l'API GitHub le 26/10/2026 : github/gh-stack, git-town/git-town, ejoffe/spr, arxanas/git-branchless, facebook/sapling, ezyang/ghstack.
- S28 — gh-stack #472, « sync reports success (exit 0) when its internal push fails » : https://github.com/github/gh-stack/issues/472
- S29 — gh-stack #446, « gh stack merge … silently rebases and dismisses approvals on the dependent PR » : https://github.com/github/gh-stack/issues/446
- S30 — git-town, ship-strategy : https://www.git-town.com/preferences/ship-strategy
- S31 — git-town, sync : https://www.git-town.com/commands/sync
- S32 — git-branchless, `git submit` : https://github.com/arxanas/git-branchless/wiki/Command:-git-submit
- S33 — Sapling, Sapling stack : https://sapling-scm.com/docs/git/sapling-stack
- S34 — Sapling, GitHub : https://sapling-scm.com/docs/git/github
- S35 — ghstack : https://github.com/ezyang/ghstack

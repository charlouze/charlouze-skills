# Les suites d'évaluation des skills tournent en local, dans une session du compte de l'humain, jamais en CI

Une suite de `claude plugin eval` lance de vraies sessions de Claude Code sur des dépôts fixture, et juge ce que la skill y laisse. Elle tourne sur le poste de l'humain, avec l'authentification de son abonnement ; la CI ne lance que `claude plugin validate`. La CI n'a pas d'accès à une IA : lui en donner un demandait une clé d'API, donc des tokens payés en plus de l'abonnement. Retomber sur des essais manuels évitait tout coût, mais laissait chaque skill sans test rejouable ; la mesure ci-dessous montre que le banc coûte assez peu pour servir aux specs de changement suivantes.

## Consequences

- La CI garde la forme du plugin (manifeste, marketplace, frontmatter des skills), jamais le comportement d'une skill : celui-ci se vérifie en lançant sa suite en local, avec les commandes du README.
- Une passe compte dans les limites d'usage de l'abonnement. Le `costUsd` du rapport est une estimation au prix catalogue de l'API, pas une facture ; la CLI n'expose pas la part de l'abonnement consommée, et c'est cette estimation qui sert de mesure.
- Première mesure, le 2026-10-29, Claude Code 2.1.312, modèle `claude-opus-5-5`, juge `haiku` : le cas `wfs-from-a-brief` à 3 runs a coûté 0,48 $ (0,15 à 0,17 $ par run, dont moins de 0,001 $ de juge) et duré 116 s (34 à 47 s par run, 7 à 9 tours). Mettre au point les graders a demandé trois runs de plus, pour 0,45 $.
- Sur Windows natif, une session d'évaluation à qui l'on accorde un shell est refusée, faute de bac à sable. Les cas s'en passent (Read, Write, Edit suffisent ici) ; une skill qui ne peut s'en passer fait tourner sa suite sous WSL2 ou Linux.

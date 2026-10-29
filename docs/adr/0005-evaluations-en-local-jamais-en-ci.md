# Les suites d'évaluation des skills tournent en local, dans une session du compte de l'humain, jamais en CI

Une suite de `claude plugin eval` lance de vraies sessions de Claude Code sur des dépôts fixture, et juge ce que la skill y laisse. Elle tourne sur le poste de l'humain, avec l'authentification de son abonnement ; la CI ne lance que `claude plugin validate`. La CI n'a pas d'accès à une IA : lui en donner un demandait une clé d'API, donc des tokens payés en plus de l'abonnement. Retomber sur des essais manuels évitait tout coût, mais laissait chaque skill sans test rejouable ; la mesure ci-dessous montre que le banc coûte assez peu pour servir aux specs de changement suivantes.

## Consequences

- La CI garde la forme du plugin (manifeste, marketplace, frontmatter des skills), jamais le comportement d'une skill : celui-ci se vérifie en lançant sa suite en local, avec les commandes du README.
- Une passe compte dans les limites d'usage de l'abonnement. Avec le modèle `claude-opus-5-5`, au prix catalogue de l'API : un run de `writing-functional-specs` coûte de 0,15 à 0,17 $, un run de `setup-charlouze-skills` de 0,10 à 0,40 $, et la suite de la mise en place, à un run par cas, autour de 2 $. Le journal daté des mesures est dans la section « Banc d'évaluation » du README.
- **Point ouvert : la part de l'abonnement qu'une passe consomme n'a pas été mesurée.** La CLI ne donne que `costUsd`, une estimation au prix catalogue, pas une facture. Pour la connaître, relever `/usage` dans une session interactive avant et après une passe.
- Sur Windows natif, une session d'évaluation à qui l'on accorde un shell est refusée, faute de bac à sable. Les cas s'en passent (Read, Write, Edit suffisent ici) ; une skill qui ne peut s'en passer fait tourner sa suite sous WSL2 ou Linux. `setup-charlouze-skills` lit donc ses remotes dans `.git/config`, et ne peut pas vérifier `gh` pendant une évaluation : son rapport le dit.

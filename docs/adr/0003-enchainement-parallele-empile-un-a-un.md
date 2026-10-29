# Un enchaînement développe ses tickets en parallèle, mais les empile un à un dans une seule pile

Un enchaînement livre les tickets d'une spec de changement en une seule pile, une couche par ticket, plutôt que sur la branche d'intégration de `/implement-spec`. Un ticket démarre dès que ses bloqueurs sont poussés, dans son propre worktree, en parallèle des autres. Une fois relu et corrigé, il rebase sur le sommet de la pile, puis il est poussé : les tickets s'empilent un à un, dans l'ordre d'arrivée. Le rebase est permis parce que l'historique ne se fige qu'au premier push (ADR 0002). La branche d'intégration de Matt, avec sa revue finale unique et ses corrections regroupées, produisait l'historique que l'ADR 0002 refuse. La séquence stricte tenait la pile, mais perdait le parallélisme.

## Consequences

- L'ordre de la pile est l'ordre d'arrivée des tickets. Il reste topologique, puisqu'un ticket ne démarre qu'une fois ses bloqueurs poussés.
- Un conflit au rebase oblige à relancer la vérification et la revue de la couche. Sans conflit, seule la vérification est relancée.
- Le nombre d'implémenteurs en même temps n'est pas réglé : c'est la frontière du graphe de tickets.
- Un projet déclare dans `docs/agents/run.md` les zones réservées au dépôt principal (la partie Unity d'un projet, par exemple). Un ticket qui touche une zone réservée s'exécute seul dans le dépôt principal.
- Le travail partiel d'un ticket arrêté arrive toujours en dernier : il attend que les tickets en cours soient poussés, puis devient une couche draft au sommet. Ses descendants n'étant pas lancés, rien ne s'empile au-dessus.
- Un ticket seul donne une PR ordinaire : la pile ne se crée qu'à la deuxième couche.

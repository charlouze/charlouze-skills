# Les grilles forment un axe de revue à part, déclaré hors de `CODING_STANDARDS.md`

Les grilles d'un projet (par défaut les quatre skills de wondelai, telles quelles) se déclarent dans `docs/agents/grids.md` et passent en revue dans un axe à nous, un sous-agent par grille, à côté des axes Standards et Spec de `/code-review`. Nommer les grilles dans `CODING_STANDARDS.md`, le point d'extension que prévoit Matt, était la voie évidente ; un essai l'a écartée : le sous-agent Standards appelle bien les grilles, mais dépasse sa limite de 400 mots dès deux grilles, classe chaque ligne en échec en violation dure (alors qu'une remarque de grille se corrige ou se justifie, sans seuil), et double les odeurs de Fowler qu'il applique déjà.

## Consequences

- `CODING_STANDARDS.md` ne nomme aucune grille, sinon l'axe Standards les appliquerait une seconde fois.
- Brancher l'axe Grilles oblige à compléter ou remplacer `/code-review`, donc ses appelants `implement` et `implement-spec`.

# Une pile fusionne en merge commit après finalisation, plutôt qu'en squash

L'historique de `main` raconte le changement, pas le développement : une PR garde autant de commits qu'elle fait de modifications distinctes, et aucun commit n'y corrige un commit de la même PR. Pendant la revue, rien n'est réécrit (corrections en `fixup!` ou `amend!`, propagation par merge) pour que le relecteur ne revoie que les commits ajoutés ; une fois toute la pile approuvée, la finalisation fond ces corrections et force-pousse chaque couche à diff identique, puis la pile fusionne en merge commit. Le squash évitait toute réécriture, mais réduisait chaque PR à un seul commit ; le rebase continu, natif des piles GitHub, réécrivait pendant la revue.

## Consequences

- Force-pousser après approbation est voulu : GitHub garde les approbations quand le diff ne change pas, et la finalisation abandonne sans rien pousser au moindre écart de diff ou conflit.
- `main` en `--first-parent` montre une ligne par pile, titrée par la PR du sommet, que la finalisation renomme pour résumer la pile.

# Le plugin complète les skills de Matt par des consignes, même contre l'une de leurs étapes

Une skill de Matt est complétée par des consignes que pointe le `CLAUDE.md` du projet (des fichiers de `docs/agents/`, ou une section du bloc), le mécanisme de préférences qu'il prévoit. Une consigne peut même contredire une étape de la skill. Celle qui fait empiler `/implement-spec`, au lieu de converger sur sa branche d'intégration, a été suivie à l'essai ([charlouze/gh-stack-merge-lab#33](https://github.com/charlouze/gh-stack-merge-lab/issues/33)). Celle qui fait nommer à chaque ticket de `/to-tickets` les blocs qu'il transcrit, et ouvrir l'issue d'adoption d'un contexte, sans rien contredire, l'a été aussi ([charlouze/gh-stack-merge-lab#42](https://github.com/charlouze/gh-stack-merge-lab/issues/42)). Ainsi `/to-spec` gagne l'écart en blocs et `Risks`, et `/to-tickets` garde son modèle d'issue. `/implement-spec` garde son graphe de tickets, ses implémenteurs en parallèle et `tdd`, alors que la consigne remplace cinq de ses neuf étapes. Une skill ne serait remplacée par une copie à nous que si un essai montrait que la consigne n'est pas suivie. Copier les skills donnait la maîtrise complète, mais coupait le plugin des évolutions de Matt et doublait le contexte de chaque skill. C'était la voie retenue avant les essais, sur l'idée, jamais vérifiée, qu'un `CLAUDE.md` contraire n'est pas suivi.

## Consequences

- **Complétées** :
  - `to-spec` par `docs/agents/change-spec.md` ;
  - `to-tickets` par la consigne de découpage du bloc `CLAUDE.md` ;
  - `implement-spec` par la consigne d'empilement du bloc `CLAUDE.md` (ADR 0003) ;
  - `code-review` par `grid-review`, que la même ligne de `CLAUDE.md` joint à toute revue (ADR 0001), si bien que `/implement` et `/implement-spec` reçoivent l'axe Grilles sans être remplacées ;
  - `domain-modeling` par `docs/agents/domain.md` ;
  - `triage` par `docs/agents/triage-labels.md` ;
  - `pr` par ce que la consigne d'empilement demande au corps de chaque PR.
- **Ajoutées** : `grid-review` (les trois points d'accroche), `finalize-stack` et `writing-functional-specs`. Aucune ne reprend un nom court de Matt : entre deux plugins, ce nom va au premier activé.
- Le ticket reste celui de Matt. La conception vit dans la spec de changement, que `/implement-spec` donne à chaque implémenteur. Un ticket plus riche obligerait à remplacer `/to-tickets`.
- Une consigne qui contredit une skill de Matt se vérifie par un spike, à refaire quand Matt fait évoluer la skill : une nouvelle version peut la défaire sans prévenir (ADR 0006).
- Les fichiers de `docs/agents/` que le plugin lit portent des noms anglais fixes : `grids.md`, `run.md`, `git-history.md`, `change-spec.md`.

> **PROTOTYPE, à jeter.** Ticket complet rédigé pour la tranche 2 du lot 04 de
> charlouze-game, pour répondre à « À quoi ressemble un ticket complet ? ».
> Hypothèses : le projet a migré vers le modèle de charlouze-skills (spec dans
> `docs/contexts/expedition/SPEC.md`, glossaire au format de Matt à côté). Le
> parent tient lieu de spec de changement : c'est le README du lot 04, privé de
> sa section `L'arme`, que ce ticket porte désormais seul.

# L'arme suit les coups de mêlée

## Parent

Sensation de la mêlée (spec de changement).

## What to build

Chaque combattant qui a un pouvoir de mêlée, le personnage du joueur comme le
soldat, porte une arme faite de formes simples, que voient tous les joueurs.
L'arme est au repos quand aucun coup n'occupe le combattant. Pendant
l'armement, elle se porte vers le bord de l'arc de frappe d'où part le
balayage ; pendant l'exécution, elle suit le balayage.

Le coin qui glissait au sol pendant l'exécution disparaît : l'arme montre
désormais le sens de chaque coup.

## Spec delta

Les blocs se transcrivent mot pour mot dans la PR de ce ticket, avec le code, et
dans l'ordre de leurs numéros.

### D6 — `docs/contexts/expedition/SPEC.md`, `Combat > Melee`

```diff
 L'ouverture de l'arc de frappe, la portée, le sens du balayage et les dégâts
 sont propres au coup.
+
+Un combattant qui a un pouvoir de mêlée porte une arme, que voient tous les
+joueurs. Quand aucun coup ne l'occupe, il tient son arme au repos.
+
+Pendant l'armement d'un coup, le combattant amène son arme au bord de l'arc de
+frappe d'où part le balayage, qu'elle atteint à la fin de l'armement. Pendant
+l'exécution, l'arme suit le balayage.
```

### D7 — `docs/contexts/expedition/GLOSSARY.md`, `Language`

```diff
 **Délai d'enchaînement** (*Chain window*) :
 Le temps pendant lequel un pouvoir de mêlée enchaîne encore s'il s'arme, après
 la fin de son coup précédent et de sa recharge.
 _Code_ : `ChainWindow`
+
+**Arme** (*Weapon*) :
+Ce que porte un combattant qui a un pouvoir de mêlée, et qui suit ses coups.
+_Code_ : `Weapon`
```

## Technical design

### Le mécanisme

Le noyau expose l'angle du balayage à une avancée donnée :
`Geometry.SweepAngle(MeleeStrike strike, float progress)`, relatif à
l'orientation du combattant, l'avancée allant de 0 à 1 sur l'exécution, la
gauche négative. `Geometry.Portion` l'emploie. `StrikeView.SweepAngle`
disparaît, et son test passe au noyau.

`RoccaVentura.Interface` porte `WeaponPose`, une fonction pure qui donne l'angle
de l'arme, relatif à l'orientation du combattant :

- au repos : l'angle de repos ;
- pendant l'armement : de l'angle où l'arme se trouvait au début de l'armement
  jusqu'au bord de départ de l'arc de frappe, linéairement sur la durée de
  l'armement ;
- pendant l'exécution : `Geometry.SweepAngle`.

L'armement part de l'angle courant de l'arme, et non de l'angle de repos : le
coup enchaîné part de là où le précédent l'a laissée. Pour le coup d'essai, qui
balaie de droite à gauche puis de gauche à droite, le second coup s'arme donc
sans retour au repos.

`WeaponView`, dans `RoccaVentura.Presentation`, est un `ICombatantPresenter`
posé sur l'arme, qui applique l'angle de `WeaponPose` à chaque image :

- pour le personnage du joueur local, à partir de sa prédiction
  (`ActiveAbility`, sa phase et ses ticks) ; il ignore alors les événements
  relayés de ce personnage ;
- pour tout autre combattant, à partir des événements relayés
  `WindUpStarted`, `ExecutionStarted`, `AbilityLost` et `CombatantDowned`,
  chronométrés à leur réception comme le fait `StrikeView`.

Un coup perdu ramène l'arme au repos, sans transition. L'angle de repos se
règle sur `WeaponView`, à l'œil.

L'arme est un objet fait de cubes, sans volume de collision, enfant de la forme
(le `_graphic` de `CombatantView`) dans `Player.prefab` et `Trooper.prefab`. Les
commandes de prefabs du paquet Pipeline n'ajoutent pas d'enfant sous la forme :
une commande `[CliCommand]` de `RoccaVentura.Game.Editor`, à côté de
`PrefabBuildCommand`, ajoute l'arme et son `WeaponView`.

`StrikeView` perd le coin du balayage et ses maillages. Il garde l'arc de
frappe pendant l'armement d'un soldat, et le cache aussi sur `AbilityLost`.

### Produit

Les tranches 3 et 4 du lot s'appuient sur ces éléments ; s'en écarter oblige à
mettre à jour leurs tickets.

- L'arme est enfant de la forme dans les deux prefabs : le recul de la
  tranche 3 l'emportera avec la forme.
- `WeaponView` est seul à poser l'angle de l'arme : l'arrêt au premier impact de
  la tranche 4 s'y greffera.
- `Geometry.SweepAngle(MeleeStrike, float)`.

### Consommé

De « La suite de coups » : `ExpeditionEvent.Strike`, `EventKind.AbilityLost`,
`ActiveAbility.Strike`, `MeleeAbility.Strike(int)`.

### Contraintes

Le noyau compte le temps en ticks, à 30 ticks par seconde.

ADR concernés : `aucune-allocation-par-tick-ni-par-image`,
`trois-couches-et-noyau-pur`, `les-regles-se-testent-hors-de-unity`,
`contenu-en-scriptableobjects-et-prefabs`.

## Verification

### Cas à surveiller en revue

- Un coup enchaîné s'arme depuis l'angle où le précédent a laissé l'arme, sans
  repasser par le repos.
- Un coup perdu à un étourdissement ou à une mise à terre ramène l'arme au
  repos, chez le joueur local comme chez les autres.
- L'arme du personnage local suit sa prédiction : l'arrivée de l'événement
  relayé ne la fait pas sauter.
- L'arc de frappe d'un soldat s'affiche toujours pendant son armement, et
  disparaît quand il perd son coup.
- L'arme n'a pas de volume de collision : ce que touche un coup reste décidé par
  le noyau seul.

### Tests

- `Geometry.SweepAngle` et `WeaponPose` se testent par `dotnet test`, en
  particulier les deux sens, les bornes 0 et 1, et un armement qui part d'un
  angle autre que le repos.
- `WeaponView` a son test d'allocation.
- Un test en mode jeu vérifie que l'arme d'un soldat suit les événements de son
  coup, puis revient au repos quand il le perd.

### Commandes

```bash
mise run test:core      # noyau et interface, hors de Unity
mise run compile
mise run test           # les deux suites
mise run test:headless  # le serveur sans affichage charge l'arène avec les armes
```

### Vérifications manuelles, à rapporter dans la PR

- En jouant dans l'éditeur, l'arme du personnage s'arme puis balaie de droite à
  gauche ; si le joueur frappe de nouveau dans la demi-seconde, elle balaie de
  gauche à droite.
- L'arme d'un soldat s'arme et balaie avec son arc.
- Dans Multiplayer Play Mode, l'arme du personnage d'un autre joueur suit ses
  coups.

## Acceptance criteria

- [ ] D6 et D7 sont transcrits mot pour mot dans la PR.
- [ ] Chaque règle de D6 a un test qui la vérifie.
- [ ] Le coin du balayage n'existe plus.
- [ ] `mise run test` et `mise run test:headless` passent.
- [ ] Les vérifications manuelles sont rapportées dans la PR.

## Out of scope

- Le vacillement, le recul et l'impact, y compris l'arrêt de l'arme au premier
  impact : tranches 3 et 4.
- Un modèle ou une animation achetés.

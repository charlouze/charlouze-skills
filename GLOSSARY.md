# charlouze-skills

Plugin de skills d'ingénierie qui se pose par-dessus celui de Matt Pocock, pour des projets produit et jeu vidéo.

## Language

**Contexte** (*Context*) :
Une partie du domaine métier d'un projet, avec son propre langage, son glossaire et sa spec fonctionnelle. C'est le *bounded context* du DDD.
_Avoid_ : module (réservé au code : une unité derrière une interface)

**Spec fonctionnelle** (*Functional spec*) :
Le document vivant d'un contexte, qui énonce au présent les règles que tient son comportement sur `main`. Ce qui n'est pas livré n'y figure pas.
_Avoid_ : spec (seul), spec vivante, PRD

**Spec de changement** (*Change spec*) :
La description d'un changement à venir, telle que la produit `/to-spec`, parente de ses tickets. Elle cesse de servir une fois le changement livré.
_Avoid_ : spec (seul), PRD, lot

**Ticket** (*Ticket*) :
Une tranche d'une spec de changement, assez complète pour guider seul un implémenteur : son écart, sa conception technique et sa vérification.
_Avoid_ : story, US

**Écart** (*Delta*) :
Ce qu'un ticket change à la spec fonctionnelle et au glossaire d'un contexte, sous forme de blocs.
_Avoid_ : delta de spec

**Bloc** (*Block*) :
Le texte exact d'un changement à un paragraphe d'une spec fonctionnelle ou d'un glossaire, à recopier mot pour mot.

**Dérive** (*Drift*) :
Un code de `main` qui contredit la spec fonctionnelle de `main`, ou un comportement de `main` qu'aucune spec fonctionnelle ne décrit.

**Violation** (*Violation*) :
Une dérive où le code contredit la spec fonctionnelle.

**Lacune** (*Gap*) :
Ce qu'aucune spec fonctionnelle ne décrit : un comportement du code, ou une intention, voulue ou encore à décider.
_Avoid_ : écart, trou

**Grille** (*Grid*) :
Une skill d'évaluation qu'un projet déclare à un ou plusieurs points d'accroche, sur une zone de code. Chacune de ses remarques est corrigée ou justifiée ; sa note, si elle en donne une, ne fait qu'informer.
_Avoid_ : standard, checklist

**Point d'accroche** (*Hook point*) :
Une étape du flux où un projet branche ses grilles : la spec, la conception ou la revue.
_Avoid_ : hook (seul), étape

**Pile** (*Stack*) :
Une suite de PR posées chacune sur la précédente, revues une à une et fusionnées ensemble.
_Avoid_ : chaîne, série

**Couche** (*Layer*) :
Une PR d'une pile.

**Finalisation** (*Finalization*) :
La passe qui, une fois toute la pile approuvée, fond chaque correction dans le commit qu'elle vise, sans changer le diff d'aucune couche.
_Avoid_ : nettoyage, squash

**Enchaînement** (*Run*) :
La passe où l'agent livre seul un ou plusieurs tickets d'une spec de changement en une pile, une couche par ticket.
_Avoid_ : série, lot, boucle

**Arbitrage** (*Ruling*) :
Une décision que l'agent prend sans l'humain, consignée pour lui dans la PR avec sa raison et ce qu'elle coûte si elle est fausse.
_Avoid_ : ruling, choix d'implémentation

**Adoption** (*Adoption*) :
La passe qui décrit dans sa spec fonctionnelle tout ce que fait déjà un contexte, depuis ses documents ou l'humain.
_Avoid_ : migration, rétro-spec

**Mise en place** (*Setup*) :
La passe qui prépare un dépôt pour le plugin : ses consignes, ses déclarations et ses réglages. Elle ne crée aucun contexte.
_Avoid_ : onboarding, installation

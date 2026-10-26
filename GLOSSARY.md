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

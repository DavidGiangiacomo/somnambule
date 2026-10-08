# Le Somnambule — Game Design Document

Oct 8, 2026 · @David

## Pitch et intention

Le Somnambule est un runner idle mobile où l'on gagne davantage en touchant le moins possible l'écran. Un dormeur marche à travers ses rêves : chaque seconde sans toucher l'enfonce dans le sommeil et multiplie ses gains.

**Expérience visée** : la tension douce du « ne pas toucher ». Le joueur regarde, anticipe, et n'intervient qu'au dernier moment. Les rêves deviennent plus étranges à chaque nuit, et c'est cette étrangeté qu'on vient chercher.

**Format** : mobile, portrait, jouable à une main. Sessions de 30 secondes à 5 minutes, plusieurs fois par jour, avec une vraie progression nocturne quand le téléphone dort.

**Cible** : joueurs d'incrémentaux mobiles (Idle Slayer, Tap Ninja, Egg, Inc.) qui aiment optimiser, et joueurs plus contemplatifs attirés par l'ambiance.

**Différence avec Idle Slayer** : là-bas, jouer activement rapporte toujours plus. Ici, chaque action a un coût ; la compétence consiste à savoir quand ne rien faire.

## Piliers de design

Cinq principes tranchent les décisions ; une idée qui en contredit un est écartée.

1. **Ne rien faire est un choix.** L'inaction est une action récompensée, jamais un temps mort.
2. **Chaque toucher se paie.** Pas de spam : un tap doit toujours être une décision.
3. **L'étrangeté est la récompense.** Chaque palier franchi montre quelque chose de neuf, pas seulement un chiffre plus grand.
4. **La vraie nuit compte.** Le moment où le joueur dort est le moment fort du jeu, pas une pause.
5. **Lisible d'un regard.** Profondeur, danger et gains se lisent en une seconde, sans texte.

## Mécanique centrale : la profondeur

La profondeur de sommeil (P, de 0 à 100) monte toute seule tant qu'on ne touche pas l'écran, et multiplie tous les gains. Toucher fait remonter le dormeur vers l'éveil.

### Le dormeur

Il avance seul, de gauche à droite, à vitesse constante. Le seul geste est un **tap = enjamber** : il passe par-dessus l'obstacle suivant.

### Coût d'un toucher

- **Enjambée parfaite** (tap dans la fenêtre juste avant l'obstacle) : P perd 3 %.
- **Enjambée maladroite** (trop tôt ou trop tard) : P perd 15 %.
- **Trébuchement** (obstacle non évité) : P perd 50 % et les fragments ramassés depuis 5 secondes s'envolent.

Le joueur expert ne touche presque jamais, mais toujours au bon moment.

### Les paliers de sommeil

| Palier | Profondeur | Multiplicateur | Ce qui change à l'écran |
| --- | --- | --- | --- |
| Assoupi | 0–19 | ×1 à ×1,9 | Décor réaliste, couleurs normales |
| Sommeil léger | 20–39 | ×1,9 à ×3,5 | Les objets se déforment légèrement |
| Paradoxal | 40–59 | ×3,5 à ×5,6 | Les règles du rêve s'activent (voir Les rêves) |
| Profond | 60–79 | ×5,6 à ×8,1 | Portes de sommeil ouvertes, palette indigo |
| Abysse | 80–100 | ×8,1 à ×11 | Cauchemars possibles, sons étouffés |

### Les portes de sommeil

Certaines portes ne s'ouvrent qu'au-delà d'une profondeur donnée. Les franchir mène à des passages riches en fragments et en souvenirs. Pour les atteindre, il faut avoir tenu longtemps sans toucher.

### Le rêve lucide

Les éclats de lucidité remplissent une jauge. Pleine, elle déclenche sur demande 15 secondes de rêve lucide : les taps ne coûtent rien, un double tap fait voler, et les fragments valent ×5. À la fin, P retombe au palier Assoupi.

C'est l'équivalent du mode Rage d'Idle Slayer, avec un prix : un rêve lucide lancé en Abysse sacrifie un gros multiplicateur.

## Boucles de jeu

Tout le jeu tient en trois boucles imbriquées, et la décision « toucher ou attendre » est au centre de la plus courte.

**Trois boucles imbriquées : la seconde, la session, la nuit** (↺ : la boucle recommence)

**Moment-à-moment · quelques secondes**

Le dormeur avance seul → Un obstacle approche → **Toucher ou attendre ?** → P monte ou retombe ↺

↓ *les fragments financent la session*

**Session · 2 à 5 minutes**

Fragments ramassés → Moutons et améliorations → Viser le palier suivant → Porte de sommeil ou rêve lucide ↺

↓ *la nuit grossit jusqu'au Réveil*

**Long terme · une nuit par Réveil**

Fin de nuit, réveil-matin → Réveil : réminiscences → Constellation et souvenirs → Nuit suivante, nouveau rêve ↺

Chaque boucle nourrit la suivante : les secondes bien jouées remplissent la session, et les sessions font grossir la nuit jusqu'au Réveil.

## Ressources et économie

Quatre ressources suffisent : une monnaie, une jauge, une collection et une méta-monnaie.

| Ressource | Rôle | Sources | Puits |
| --- | --- | --- | --- |
| Fragments oniriques | Monnaie principale | Ramassés en marchant, produits par le troupeau, gains hors-ligne | Moutons, améliorations du dormeur |
| Éclats de lucidité | Jauge du rêve lucide | Rares sur le parcours, plus fréquents en Paradoxal et au-delà | Déclencher un rêve lucide |
| Souvenirs | Collection unique, fil narratif | Un par rêve et par palier atteint, derrière les portes de sommeil | Aucun : ils restent, chacun donne un petit bonus permanent |
| Réminiscences | Méta-monnaie de prestige | Gagnées au Réveil, selon les fragments de la nuit | Arbre de la Constellation |

Les fragments sont remis à zéro à chaque Réveil ; souvenirs et réminiscences sont permanents.

## Améliorations et générateurs

Les générateurs sont les moutons qu'on compte pour s'endormir ; les améliorations équipent le dormeur.

### Le troupeau (production passive)

Chaque mouton produit des fragments en continu, multipliés par la profondeur actuelle. Les valeurs sont un point de départ pour le simulateur.

| Mouton | Coût de base (fragments) | Production de base (fragments/s) | Particularité |
| --- | --- | --- | --- |
| Mouton | 15 | 0,1 | — |
| Bélier | 100 | 1 | Ses cornes cassent un obstacle par minute |
| Mouton à plumes | 1 100 | 8 | Ramasse les fragments hors de portée |
| Nuage-mouton | 12 000 | 47 | Production ×2 en Paradoxal et au-delà |
| Troupeau céleste | 130 000 | 260 | Remplit lentement la jauge de lucidité |
| Berger de la Lune | 1 400 000 | 1 400 | +1 % de production par mouton possédé |

Tous les 25 exemplaires d'un même mouton, sa production double (palier façon Cookie Clicker).

### Le dormeur (améliorations à niveaux)

| Amélioration | Effet par niveau |
| --- | --- |
| Oreiller | Vitesse de descente dans le sommeil +10 % |
| Couette | Perte au trébuchement −5 points (plancher : 20 %) |
| Veilleuse | Fenêtre d'enjambée parfaite +20 ms |
| Bouillotte | Profondeur maximale +5 (au-delà de 100, nouveaux paliers) |
| Attrape-rêves | Rayon de ramassage des fragments +10 % |
| Tisane | Durée du rêve lucide +1 s |

La Bouillotte est l'amélioration-clé du milieu de partie : elle ouvre des paliers au-delà de l'Abysse.

## Prestige : le Réveil

Le Réveil remet fragments, moutons et améliorations à zéro, et convertit la nuit écoulée en réminiscences permanentes. Chaque Réveil ouvre la nuit suivante.

### Déclenchement

Le joueur choisit quand se réveiller. Un réveil-matin apparaît dans le décor dès que le Réveil rapporterait au moins 1 réminiscence, puis sonne plus fort quand le gain double depuis la dernière nuit.

### Ce que rapportent les réminiscences

- **Non dépensées** : +2 % de production globale chacune, comme les âmes d'Idle Slayer.
- **Dépensées** dans la Constellation du dormeur, un arbre en trois branches.

| Branche | Thème | Exemples de nœuds |
| --- | --- | --- |
| Abysses | Jouer la profondeur | Commencer chaque nuit en Sommeil léger ; trébuchement −10 % ; nouveaux paliers après l'Abysse |
| Lucidité | Jouer l'actif | Jauge pleine au départ ; double tap en dehors du rêve lucide ; fragments ×2 pendant 30 s après un rêve lucide |
| Troupeau | Jouer l'idle | Moutons achetés automatiquement ; plafond hors-ligne +2 h ; production ×3 quand l'app est fermée |

### Les nuits d'insomnie (défis)

À partir de la nuit 10, des nuits à contrainte se débloquent : pas de moutons, profondeur plafonnée à 50, un seul tap par minute, etc. Les réussir donne des bonus permanents uniques. C'est l'équivalent des challenges d'Antimatter Dimensions.

### Deuxième couche : les cycles lunaires

Après 28 nuits, une Pleine Lune propose un prestige plus profond, qui réinitialise aussi l'arbre. Elle rapporte des Phases, qui débloquent de nouveaux rêves et changent les règles de base. À n'introduire qu'après validation de la première couche.

## Les rêves

Chaque rêve est un biome avec sa propre règle, activée à partir du palier Paradoxal. Un nouveau rêve se débloque tous les 3 à 5 Réveils.

| Rêve | Déblocage | Règle propre (à partir de Paradoxal) |
| --- | --- | --- |
| La maison d'enfance | Départ | Aucune ; les couloirs s'allongent avec la profondeur |
| L'examen oublié | Nuit 3 | Des copies volent ; une enjambée parfaite au-dessus d'une copie vaut une « bonne réponse », ×3 fragments |
| La chute | Nuit 6 | Le dormeur tombe au lieu de marcher ; le tap le freine au lieu de le faire enjamber |
| La ville aux escaliers | Nuit 10 | Les escaliers pivotent ; les portes de sommeil y sont deux fois plus nombreuses |
| L'océan de lait | Nuit 15 | Impossible d'enjamber : il faut plonger (tap long), la profondeur devient littérale |
| Les dents | Nuit 21 | Rêve d'angoisse : cauchemars dès le palier Profond, récompenses doublées |

### Les cauchemars

En Abysse, chaque minute comporte un risque de cauchemar. Une silhouette surgit et poursuit le dormeur pendant 20 secondes, avec des obstacles plus denses.

- **Survivre** : un souvenir rare et ×10 fragments pendant une minute.
- **Échouer** : réveil en sursaut, P tombe à 0.

C'est le risque qui donne du goût à la profondeur.

### Le fil narratif

Les souvenirs racontent, par fragments, qui est le dormeur et pourquoi il marche la nuit. La réponse ne se complète qu'au dernier rêve. La collection de souvenirs sert de journal consultable entre deux nuits.

## Progression hors-ligne et notifications

Quand l'application est fermée, le dormeur continue de dormir à la profondeur qu'il avait au moment où le joueur a quitté. Quitter en Abysse rapporte donc beaucoup plus que quitter Assoupi.

- **Gains** : production du troupeau × multiplicateur de la profondeur au départ. Pas de fragments ramassés, pas de souvenirs.
- **Plafond** : 8 heures, une nuit. Extensible à 12 heures par la branche Troupeau.
- **Bonus nuit complète** : +25 % si l'absence dure entre 6 et 10 heures, pour récompenser le joueur qui dort vraiment.
- **Retour** : un écran « Pendant que tu dormais » résume la nuit, avec une courte phrase de rêve générée à partir du rêve en cours.
- **Notifications** : au plus une par jour, désactivables, au ton calme (« Le troupeau t'attend »). Jamais de relance culpabilisante.
- **Anti-triche** : comparer l'horloge du téléphone à la dernière heure enregistrée ; un saut en arrière annule le gain hors-ligne de la session.

## Direction artistique et sonore

La profondeur doit se voir et s'entendre sans aucun chiffre : c'est la règle qui guide tout le rendu.

### Image

- **Style** : aplats de couleurs et silhouettes, formes simples. Réaliste pour un développeur solo, et lisible sur petit écran.
- **Écran portrait** : la bande de rêve occupe les 60 % du haut, le troupeau et les achats le bas.
- **Profondeur visible** : la palette glisse du bleu nuit vers l'indigo puis le violet profond ; les bords de l'écran s'assombrissent et le décor se déforme légèrement.
- **Dormeur** : silhouette en pyjama, bras tendus, yeux fermés. Il trébuche de façon comique, jamais violente.
- **Moutons** : visibles en petit au bas de l'écran, ils sautent une barrière en boucle. Plus il y en a, plus la file est longue.

### Son

- Un bourdon ambiant qui se densifie et s'assourdit avec la profondeur.
- Le tap fait un bruit de drap froissé ; le trébuchement, un petit sursaut de respiration.
- Le cauchemar coupe la musique et ne garde que des battements de cœur.
- Retours haptiques légers sur l'enjambée parfaite, désactivables.

## Formules et équilibrage

Ces formules sont des points de départ, à régler dans un simulateur d'économie avant tout prototype jouable.

### Descente dans le sommeil

La profondeur monte vite au début, puis ralentit à l'approche du maximum. v est la vitesse de base (2 points par seconde), améliorée par l'Oreiller.

```latex
\frac{dP}{dt} = v \left(1 - \frac{P}{P_{max}}\right)
```

### Multiplicateur de profondeur

Il donne les valeurs du tableau des paliers : ×1,9 à 20, ×5,6 à 60, ×11 à 100.

```latex
M(P) = 1 + 0{,}32 \left(\frac{P}{10}\right)^{1{,}5}
```

### Coût des moutons

Coût du n-ième exemplaire, avec r entre 1,07 et 1,15 selon le mouton (les plus chers croissent le plus lentement).

```latex
C_n = C_0 \cdot r^{\,n}
```

### Réminiscences au Réveil

F est le total de fragments gagnés pendant la nuit.

```latex
R = \left\lfloor \sqrt{F / 10^{6}} \right\rfloor
```

### Rythme visé

| Moment | Durée cible |
| --- | --- |
| Atteindre le palier Profond la première fois | 3 à 5 min |
| Premier Réveil possible | 15 à 20 min |
| Nuits suivantes, jusqu'à la nuit 10 | 10 à 15 min chacune |
| Nouveau rêve | Tous les 3 à 5 Réveils |
| Première Pleine Lune | 2 à 3 semaines de jeu régulier |

Le point à surveiller : le joueur qui ne touche jamais doit progresser, mais nettement moins vite qu'un joueur qui touche juste.

## Monétisation mobile éthique

Recommandation : gratuit avec un achat unique « Veilleur », sans monnaie premium. Le jeu repose sur le calme ; une pub forcée casserait le pilier « la vraie nuit compte ».

- **Achat unique Veilleur** (3 à 5 €) : supprime toutes les pubs et double le bonus nuit complète.
- **Pubs récompensées, toujours optionnelles** : doubler un gain hors-ligne, ou relancer un cauchemar raté. Au plus 3 par jour.
- **Cosmétiques** : pyjamas, oreillers, races de moutons. Aucun effet sur la progression.
- **Interdits** : monnaie premium, accélérateurs de prestige payants, offres à durée limitée agressives.

Alternative : jeu payant 3 € sans aucune pub, plus simple à développer et cohérent avec l'ambiance.

## Périmètre MVP et feuille de route Godot

Le MVP doit prouver une seule chose : que « ne pas toucher » est amusant pendant 20 minutes.

### Contenu du MVP

- [ ] Un rêve (la maison d'enfance), sans règle propre
- [ ] Profondeur, enjambée parfaite / maladroite / trébuchement, 5 paliers
- [ ] 4 moutons et 3 améliorations (Oreiller, Couette, Veilleuse)
- [ ] Le Réveil avec 6 nœuds d'arbre (2 par branche)
- [ ] Gains hors-ligne et sauvegarde
- [ ] Pas de rêve lucide, pas de cauchemar, pas de monétisation

### Architecture Godot 4

- **Langage** : GDScript est le choix sûr pour l'export mobile. C# serait plus proche de Java ; vérifier l'état de son export Android/iOS avant de s'y engager.
- **Scènes** : `Runner` (dormeur + obstacles + défilement avec `Parallax2D`), `Flock` (moutons), `Shop` (UI), `WakeScreen` (Réveil).
- **État global** : un autoload `GameState` qui tient ressources, niveaux et profondeur, et émet des signaux vers l'UI.
- **Grands nombres** : un `float` (double) suffit jusqu'à 1e308 ; prévoir une classe mantisse/exposant seulement si l'économie la dépasse.
- **Hors-ligne** : enregistrer `Time.get_unix_time_from_system()` et la profondeur à la mise en pause (`NOTIFICATION_APPLICATION_PAUSED`), calculer l'écart au retour.
- **Sauvegarde** : JSON via `FileAccess` dans `user://`, avec un numéro de version pour les migrations.

### Étapes

1. **Simulateur d'économie** (script ou tableur) : valider les formules et le rythme visé avant d'écrire le jeu.
2. **Prototype gris** : rectangles, profondeur, enjambée. Tester seul la sensation du « ne pas toucher ».
3. **MVP complet** : contenu ci-dessus, faire jouer 3 à 5 personnes.
4. **Tranche verticale** : rêve lucide, cauchemars, 2 rêves, direction artistique définitive sur un rêve.
5. **Contenu et polish** : les 6 rêves, insomnies, sons, notifications.
6. **Publication** : test fermé Google Play, puis sortie.

## Risques et questions ouvertes

### Risques

| Risque | Pourquoi c'est un problème | Parade |
| --- | --- | --- |
| « Ne pas toucher » devient ennuyeux | Le joueur regarde sans rien faire et décroche | Obstacles assez fréquents, portes de sommeil, cauchemars ; à valider dès le prototype gris |
| Latence tactile sur mobile | Une fenêtre parfaite trop étroite paraît injuste | Fenêtre de départ généreuse (150 ms) et retour visuel immédiat |
| Profondeur peu lisible | Le joueur ne sent pas ce qu'il risque | Palette, flou et son liés à P ; jauge discrète en bord d'écran |
| Le joueur idle pur stagne | Le jeu n'est pas un idle s'il exige l'actif | Branche Troupeau et gains hors-ligne suffisants pour progresser sans jouer |
| Ressemblance avec Idle Slayer | Le jeu paraît dérivé | Mécanique inversée mise en avant dès la fiche du store |

### Questions ouvertes

- Portrait ou paysage ? Le portrait favorise la main unique, le paysage le défilement.
- Ton : mélancolique, humoristique, ou les deux selon les rêves ?
- Qui est le dormeur ? Le fil narratif mérite d'être écrit avant les souvenirs.
- Gratuit avec achat Veilleur, ou payant ?

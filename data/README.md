# balance.json

Source unique des valeurs d'équilibrage du Somnambule. Le simulateur
(`simulateur/`) et le jeu Godot lisent ce même fichier : un réglage validé au
simulateur arrive tel quel dans le jeu.

Le format JSON n'accepte pas les commentaires, d'où cette page. Les valeurs
reprennent le GDD (`docs/gdd.md`), sauf celles que le GDD ne donne pas,
signalées ci-dessous comme **inventées**, et celles que le calage de
l'issue #3 a modifiées, signalées comme **calées**. Le détail de chaque
changement est dans l'issue #3.

Après une modification, vérifiez les cibles du GDD avec
`simulateur/verifier_rythme.py` et `simulateur/comparer_profils.py`.

Conventions :

- les pourcentages sont écrits en points : `3` veut dire 3 % ;
- les durées sont en secondes (`_s`) ou en millisecondes (`_ms`) ;
- `id` est l'identifiant utilisé par le code (sans accent ni espace), `nom`
  est le texte affiché au joueur.

## profondeur

| Champ | Sens | Simulateur |
|---|---|---|
| `max` | Pmax, profondeur maximale | oui |
| `vitesse_descente` | v dans dP/dt = v·(1 − P/Pmax), en points de P par seconde. **Calée** à 1,5 (GDD : 2) pour atteindre Profond en 3 à 5 min | oui |
| `paliers` | Assoupi → Abysse. `seuil` : P à partir de laquelle on entre dans le palier. Rangés du moins au plus profond | oui |

## multiplicateur

M(P) = 1 + `coefficient` · (P / `echelle`)^`exposant`, soit
1 + 0,32·(P/10)^1,5 dans le GDD. Il multiplie tous les gains de fragments.
Utilisé par le simulateur.

Le tableau des paliers du GDD annonce ×5,6 à P = 60 et ×8,1 à P = 80, alors que
la formule donne 5,7 et 8,2 (les autres valeurs concordent). Le simulateur suit
la formule.

## enjambee

| Champ | Sens | Simulateur |
|---|---|---|
| `fenetre_parfaite_ms` | durée de la fenêtre d'enjambée parfaite avant l'obstacle | non (le simulateur tire l'issue au hasard selon le profil de joueur) |
| `cout_profondeur_pourcent` | part de P perdue selon l'issue de l'enjambée | oui |
| `trebuchement_perte_fragments_s` | un trébuchement fait perdre les fragments ramassés sur le parcours pendant ces dernières secondes | oui |

## defilement

`vitesse_px_s` : vitesse à laquelle le décor défile sous le dormeur, en pixels
par seconde, dans l'écran de référence large de 1080 pixels. Elle fixe le
temps pendant lequel on voit venir un obstacle. Valeur **inventée**, reprise
de la maquette de l'issue #6. Le simulateur ne l'utilise pas : il compte les
obstacles en secondes, pas en pixels.

## obstacles

Temps entre deux obstacles, tiré au hasard entre `intervalle_min_s` et
`intervalle_max_s`. Utilisé par le simulateur, qui avance seconde par seconde :
garder `intervalle_min_s` ≥ 1. Le GDD demande seulement des « obstacles
assez fréquents » : 5 à 10 s est un choix de design fait pendant le calage
(#3), qui garde le rapport de vitesse attentif / idle pur de l'issue #2 proche
de sa cible.

## fragments

Fragments flottant sur le parcours : `apparitions_par_seconde` fragments par
seconde en moyenne, chacun valant `valeur_base` × M(P). Utilisé par le
simulateur. Valeurs **inventées**.

## moutons

| Champ | Sens | Simulateur |
|---|---|---|
| `doublement_tous_les` | la production d'un type de mouton double tous les N exemplaires | oui |
| `liste[].cout_initial` | C0, prix du premier exemplaire | oui |
| `liste[].raison_cout` | r : le n-ième exemplaire coûte C0·r^n | oui |
| `liste[].production_par_seconde` | fragments par seconde d'un exemplaire, avant M(P) | oui |

Les productions viennent du tableau du troupeau du GDD. Les coûts de base
sont **calés** au double de ceux du GDD (30 / 200 / 2 200 / 24 000 au lieu de
15 / 100 / 1 100 / 12 000) pour que le premier Réveil arrive en 15 à 20 min.
Pour `raison_cout`, le GDD dit seulement « entre 1,07 et 1,15 selon le mouton, les
plus chers croissent le plus lentement » : les valeurs 1,15 / 1,13 / 1,11 /
1,09 sont **inventées**, en gardant 1,08 et 1,07 pour le Troupeau céleste et
le Berger de la Lune (issue #31).

Les particularités (le Bélier casse un obstacle par minute, le Mouton à
plumes ramasse les fragments hors de portée, le Nuage-mouton produit ×2 en
Paradoxal) ne sont pas encore décrites ici : elles arriveront avec l'issue #16.

## ameliorations

Oreiller, Couette et Veilleuse (issue #17). Même logique de prix que les
moutons (`cout_initial`, `raison_cout`). `effet` dit ce que l'amélioration
modifie, `valeur_par_niveau` de combien par niveau :

- `vitesse_descente_pourcent` : +10 % de vitesse de descente par niveau ;
- `perte_trebuchement_points` : −5 points de perte de P au trébuchement par
  niveau, sans descendre sous `plancher` (20 %) ;
- `fenetre_parfaite_ms` : +20 ms de fenêtre parfaite par niveau.

Les effets viennent du GDD ; les prix sont **inventés**. **Le simulateur ne
les utilise pas encore.**

## reminiscences

| Champ | Sens | Simulateur |
|---|---|---|
| `diviseur_fragments` | R = ⌊√(F / `diviseur_fragments`)⌋, où F est le total des fragments gagnés pendant la nuit | oui |
| `bonus_production_pourcent` | bonus de production globale par réminiscence gardée (non dépensée) | oui |

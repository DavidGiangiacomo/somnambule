# balance.json

Source unique des valeurs d'équilibrage de Somnambule. Le simulateur
(`simulateur/`) et le jeu Godot lisent ce même fichier : un réglage validé au
simulateur arrive tel quel dans le jeu.

Le format JSON n'accepte pas les commentaires, d'où cette page. Toutes les
valeurs sont **provisoires** jusqu'au calage de l'issue #3.

Conventions :

- les pourcentages sont écrits en points : `3` veut dire 3 % ;
- les durées sont en secondes (`_s`) ou en millisecondes (`_ms`) ;
- `id` est l'identifiant utilisé par le code (sans accent ni espace), `nom`
  est le texte affiché au joueur.

## profondeur

| Champ | Sens | Simulateur |
|---|---|---|
| `max` | Pmax, profondeur maximale | oui |
| `vitesse_descente` | v dans dP/dt = v·(1 − P/Pmax), en points de P par seconde | oui |
| `paliers` | Assoupi → Abysse. `seuil` : P à partir de laquelle on entre dans le palier. Rangés du moins au plus profond | oui |

## multiplicateur

M(P) = 1 + `coefficient` · (P / `echelle`)^`exposant`, soit
1 + 0,32·(P/10)^1,5 dans le GDD. Il multiplie tous les gains de fragments.
Utilisé par le simulateur.

## enjambee

| Champ | Sens | Simulateur |
|---|---|---|
| `fenetre_parfaite_ms` | durée de la fenêtre d'enjambée parfaite avant l'obstacle | non (le simulateur tire l'issue au hasard selon le profil de joueur) |
| `cout_profondeur_pourcent` | part de P perdue selon l'issue de l'enjambée | oui |
| `trebuchement_perte_fragments_s` | un trébuchement fait perdre les fragments ramassés sur le parcours pendant ces dernières secondes | oui |

## obstacles

Temps entre deux obstacles, tiré au hasard entre `intervalle_min_s` et
`intervalle_max_s`. Utilisé par le simulateur, qui avance seconde par seconde :
garder `intervalle_min_s` ≥ 1.

## fragments

Fragments flottant sur le parcours : `apparitions_par_seconde` fragments par
seconde en moyenne, chacun valant `valeur_base` × M(P). Utilisé par le
simulateur.

## moutons

| Champ | Sens | Simulateur |
|---|---|---|
| `doublement_tous_les` | la production d'un type de mouton double tous les N exemplaires | oui |
| `liste[].cout_initial` | C0, prix du premier exemplaire | oui |
| `liste[].raison_cout` | r : le n-ième exemplaire coûte C0·r^n | oui |
| `liste[].production_par_seconde` | fragments par seconde d'un exemplaire, avant M(P) | oui |

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

Les effets viennent du GDD ; les prix sont inventés. **Le simulateur ne les
utilise pas encore.**

## reminiscences

R = ⌊√(F / `diviseur_fragments`)⌋, où F est le total des fragments gagnés
pendant la nuit. Utilisé par le simulateur.

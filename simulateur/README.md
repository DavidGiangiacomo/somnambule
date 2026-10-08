# Simulateur d'économie

Simule une nuit du Somnambule seconde par seconde, sans graphisme, pour
vérifier que les formules du GDD (`docs/gdd.md`) donnent un rythme agréable
avant d'écrire du code Godot (issue #1). Les valeurs viennent de
`data/balance.json` (issue #4). Un second script compare les trois profils de
joueur de l'issue #2.

## Lancer

Il faut Python 3.8 ou plus récent, sans aucune bibliothèque à installer.
Depuis la racine du dépôt :

```sh
python3 simulateur/simulateur.py
```

Sous Windows, remplacez `python3` par `py`.

Le script affiche un résumé (premier passage par chaque palier, premier Réveil
possible, troupeau en fin de nuit) et écrit le détail dans
`simulateur/sorties/nuit_<profil>.csv`. Ce dossier n'est pas versionné.

Options :

| Option | Effet | Défaut |
|---|---|---|
| `--profil idle` | profil de joueur : `attentif`, `moyen` ou `idle` | `moyen` |
| `--duree 60` | durée de la nuit en minutes | 30 |
| `--graine 7` | graine du hasard : même graine = même nuit | 42 |
| `--obstacles 2 5` | intervalle entre obstacles (min et max, en secondes), à la place de celui de `balance.json` | celui de `balance.json` |
| `--balance chemin.json` | utiliser un autre fichier de valeurs | `data/balance.json` |
| `--sortie chemin.csv` | écrire le CSV ailleurs | `simulateur/sorties/nuit_<profil>.csv` |

Pour tester un réglage, modifiez `data/balance.json` puis relancez avec la
même graine : seule la valeur modifiée change le résultat.

## Lire le CSV

Le fichier s'ouvre directement dans Excel ou LibreOffice réglés en français
(séparateur `;`, virgule décimale). Une ligne par seconde :

| Colonne | Contenu |
|---|---|
| `seconde`, `minute` | temps écoulé |
| `profondeur`, `palier`, `multiplicateur` | P, son palier et M(P) |
| `obstacle` | issue de l'enjambée s'il y avait un obstacle à cette seconde |
| `gain` | fragments gagnés pendant cette seconde |
| `fragments` | fragments en poche après les achats |
| `fragments_total` | fragments gagnés depuis le début de la nuit |
| une colonne par mouton | nombre possédé |
| `reminiscences` | R qu'un Réveil rapporterait maintenant |

Pour la courbe des fragments, tracez `fragments_total` en fonction de
`minute`, de préférence avec une échelle logarithmique.

## Comparer les profils de joueur

```sh
python3 simulateur/comparer_profils.py
python3 simulateur/comparer_profils.py --obstacles 5 10
```

Simule plusieurs nuits par profil (5 par défaut, option `--graines`), affiche
la profondeur moyenne et le premier Réveil de chacun, puis vérifie les deux
critères de l'issue #2 :

- **rapport de vitesse attentif / idle pur entre 2 et 4.** La vitesse se
  mesure au temps qu'il faut pour atteindre le premier Réveil : un rapport de
  3 veut dire que l'idle pur met 3 fois plus longtemps que l'attentif ;
- **premier Réveil de l'idle pur en moins d'une heure**, sur toutes les nuits.

Les options `--duree` (120 min par défaut), `--obstacles` et `--balance`
fonctionnent comme pour `simulateur.py`.

## Organisation du code

- `formules.py` : les formules du GDD, une fonction par formule, sans rien
  d'autre. C'est la partie à recopier en GDScript.
- `simulateur.py` : les profils de joueur, la boucle de la nuit découpée en
  cinq étapes (descente, récolte, obstacle, achats, enregistrement), puis
  l'écriture du CSV et du résumé.
- `comparer_profils.py` : réutilise `simulateur.py` pour comparer les profils.
- `.gdignore` : fichier vide qui demande à Godot d'ignorer ce dossier. Sans
  lui, Godot essaierait d'importer les CSV comme des fichiers de traduction.

## Hypothèses

Ce que le GDD ne précise pas et que le simulateur a dû trancher :

- **Profils de joueur** (`PROFILS` dans `simulateur.py`), repris de
  l'issue #2 :

  | Profil | Parfaites | Maladroites | Trébuchements |
  |---|---|---|---|
  | attentif | 90 % | 8 % | 2 % |
  | moyen | 50 % | 40 % | 10 % |
  | idle pur | 0 % | 0 % | 100 % |

  L'issue ne fixe que les 90 % de parfaites de l'attentif : ses 10 % restants
  sont répartis comme ceux du profil moyen, 4 maladroites pour 1 trébuchement.
- **Achats.** Tous les profils, idle pur compris, achètent des moutons : « ne
  jamais toucher » vaut pour les obstacles, pas pour la boutique. Le joueur
  simulé achète le mouton qui sera remboursé le plus vite, en comptant le
  temps d'économiser pour lui. Il sait donc attendre un Bélier plutôt que
  d'acheter un Mouton devenu trop cher.
- **Trébuchement.** Le GDD fait perdre « les fragments ramassés depuis
  5 secondes » : seuls ceux du parcours sont perdus, pas la production des
  moutons. Ils sont aussi retirés du total F qui sert à calculer R.
- **Coût des moutons.** Dans C_n = C0·r^n, n est le nombre d'exemplaires déjà
  possédés : le premier coûte donc le « coût de base » du GDD.
- **Valeurs absentes du GDD.** Fréquence des obstacles, fragments du parcours,
  raison r de chaque mouton et prix des améliorations sont inventés (détail
  dans `data/README.md`).

## Pas encore simulé

Améliorations du dormeur (#17), particularités des moutons (#16), rêve
lucide, portes, cauchemars, Réveil et nuits suivantes. Ces éléments viendront
avec leurs issues, au fil de l'équilibrage (#3, #31, #38).

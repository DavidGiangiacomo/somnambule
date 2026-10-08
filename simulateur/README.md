# Simulateur d'économie

Simule une nuit de Somnambule seconde par seconde, sans graphisme, pour
vérifier que les formules du GDD donnent un rythme agréable avant d'écrire du
code Godot (issue #1). Les valeurs viennent de `data/balance.json` (issue #4).

## Lancer

Il faut Python 3.8 ou plus récent, sans aucune bibliothèque à installer.
Depuis la racine du dépôt :

```sh
python3 simulateur/simulateur.py
```

Sous Windows, remplacez `python3` par `py`.

Le script affiche un résumé (premier passage par chaque palier, premier Réveil
possible, troupeau en fin de nuit) et écrit le détail dans
`simulateur/sorties/nuit.csv`. Ce dossier n'est pas versionné.

Options :

| Option | Effet | Défaut |
|---|---|---|
| `--duree 60` | durée de la nuit en minutes | 30 |
| `--graine 7` | graine du hasard : même graine = même nuit | 42 |
| `--balance chemin.json` | utiliser un autre fichier de valeurs | `data/balance.json` |
| `--sortie chemin.csv` | écrire le CSV ailleurs | `simulateur/sorties/nuit.csv` |

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

## Organisation du code

- `formules.py` : les formules du GDD, une fonction par formule, sans rien
  d'autre. C'est la partie à recopier en GDScript.
- `simulateur.py` : la boucle de la nuit, découpée en cinq étapes (descente,
  récolte, obstacle, achats, enregistrement), puis l'écriture du CSV et du
  résumé.
- `.gdignore` : fichier vide qui demande à Godot d'ignorer ce dossier. Sans
  lui, Godot essaierait d'importer les CSV comme des fichiers de traduction.

## Hypothèses

Ce que le GDD ne précise pas et que le simulateur a dû trancher :

- **Joueur simulé.** Il enjambe chaque obstacle avec le profil « moyen » de
  l'issue #2 : 50 % parfaites, 40 % maladroites, 10 % de trébuchements. Les
  profils « attentif » et « idle pur » restent à ajouter avec cette issue
  (`PROFIL_MOYEN` dans `simulateur.py`).
- **Achats.** Il achète le mouton qui sera remboursé le plus vite, en
  comptant le temps d'économiser pour lui. Il sait donc attendre un Bélier
  plutôt que d'acheter un Mouton devenu trop cher.
- **Trébuchement.** Seuls les fragments ramassés sur le parcours pendant les
  5 dernières secondes sont perdus, pas la production des moutons. Ils sont
  aussi retirés du total qui sert à calculer R.
- **Réminiscences.** R se calcule sur le total des fragments gagnés pendant
  la nuit, pas sur ce qui reste en poche.
- **Paliers.** Les seuils 0 / 20 / 40 / 60 / 80 répartissent les cinq paliers
  régulièrement entre 0 et Pmax.

## Pas encore simulé

Améliorations du dormeur (#17), particularités des moutons (#16), rêve
lucide, portes, cauchemars, Réveil et nuits suivantes. Ces éléments viendront
avec leurs issues, au fil de l'équilibrage (#3, #31, #38).

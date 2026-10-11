# somnambule
Jeu mobile incrémental en Godot 4 : voir le game design document
(`docs/gdd.md`).

## Arborescence

| Dossier | Contenu |
|---|---|
| `scenes/` | scènes Godot (`.tscn`) |
| `scripts/` | scripts GDScript |
| `assets/` | images, sons, polices |
| `shaders/` | shaders (effets visuels calculés par la carte graphique) |
| `data/` | `balance.json`, valeurs d'équilibrage lues par le jeu et le simulateur |
| `tests/` | tests des scripts (voir plus bas) |
| `addons/gut/` | GUT, le framework de test (code tiers, licence MIT) |
| `simulateur/` | simulateur d'économie en Python (ignoré par Godot) |
| `docs/` | game design document (ignoré par Godot) |
| `build/` | exports Android, non versionnés |

## Lancer le jeu

Ouvrir `project.godot` avec Godot 4.7, puis F5. La fenêtre de bureau fait
450×800 ; le jeu est dessiné en 1080×1920 (portrait) et s'adapte à la largeur
de l'écran.

## Tests

Les tests utilisent [GUT](https://gut.readthedocs.io/en/v9.7.1/) 9.7.1, copié
dans `addons/gut/`. Chaque fichier `tests/test_*.gd` hérite de `GutTest` ;
chaque fonction dont le nom commence par `test_` est un test.

Dans l'éditeur : l'onglet GUT, en bas de la fenêtre, puis « Run All ».

En ligne de commande, depuis la racine du dépôt :

```sh
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

La commande se termine avec le code 1 si un test échoue. Les réglages
(dossier des tests, niveau de détail) sont dans `.gutconfig.json`. Pour ne
lancer qu'un fichier, ajouter `-gselect=test_nombres`.

Les tests travaillent sur un GameState neuf et un fichier de sauvegarde à
part : ils ne touchent jamais à la vraie partie. Ni `tests/` ni `addons/gut/`
ne sont exportés dans l'APK.

## Exporter sur Android

Il faut les modèles d'export Godot 4.7.2, le SDK Android et un JDK, réglés
dans Éditeur → Paramètres de l'éditeur → Export → Android. Brancher le
téléphone en USB (débogage USB activé) puis utiliser le bouton de déploiement
en haut à droite de l'éditeur, ou Projet → Exporter → Android, qui écrit
`build/somnambule.apk`.

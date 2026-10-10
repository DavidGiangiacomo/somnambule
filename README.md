# somnambule
Jeu mobile incrémental en Godot 4 : voir le game design document
(`docs/gdd.md`).

## Arborescence

| Dossier | Contenu |
|---|---|
| `scenes/` | scènes Godot (`.tscn`) |
| `scripts/` | scripts GDScript |
| `assets/` | images, sons, polices |
| `data/` | `balance.json`, valeurs d'équilibrage lues par le jeu et le simulateur |
| `simulateur/` | simulateur d'économie en Python (ignoré par Godot) |
| `docs/` | game design document (ignoré par Godot) |
| `build/` | exports Android, non versionnés |

## Lancer le jeu

Ouvrir `project.godot` avec Godot 4.7, puis F5. La fenêtre de bureau fait
450×800 ; le jeu est dessiné en 1080×1920 (portrait) et s'adapte à la largeur
de l'écran.

## Exporter sur Android

Il faut les modèles d'export Godot 4.7.2, le SDK Android et un JDK, réglés
dans Éditeur → Paramètres de l'éditeur → Export → Android. Brancher le
téléphone en USB (débogage USB activé) puis utiliser le bouton de déploiement
en haut à droite de l'éditeur, ou Projet → Exporter → Android, qui écrit
`build/somnambule.apk`.

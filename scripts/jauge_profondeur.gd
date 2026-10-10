extends Node2D
## Jauge de profondeur, discrète, sur le bord droit de la bande de rêve.
## Elle se remplit vers le bas ; les traits marquent les paliers de sommeil.

const TAILLE := Vector2(10, 840)
const COULEUR_FOND := Color(1, 1, 1, 0.12)
const COULEUR_NIVEAU := Color(0.8, 0.75, 1, 0.6)
const COULEUR_PALIER := Color(1, 1, 1, 0.35)

## Profondeur ramenée entre 0 (éveillé) et 1 (profondeur maximale).
var valeur := 0.0:
	set(nouvelle):
		valeur = nouvelle
		queue_redraw()

var _paliers: Array[float] = []  # seuils des paliers, entre 0 et 1


func _ready() -> void:
	var profondeur: Dictionary = Balance.donnees()["profondeur"]
	for palier in profondeur["paliers"]:
		if palier["seuil"] > 0:
			_paliers.append(palier["seuil"] / profondeur["max"])


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, TAILLE), COULEUR_FOND)
	draw_rect(Rect2(0, 0, TAILLE.x, TAILLE.y * valeur), COULEUR_NIVEAU)
	for seuil in _paliers:
		draw_rect(Rect2(-6, TAILLE.y * seuil - 1, TAILLE.x + 12, 2), COULEUR_PALIER)

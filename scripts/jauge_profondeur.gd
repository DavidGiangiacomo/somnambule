extends Node2D
## Jauge de profondeur, discrète, sur le bord droit de la bande de rêve.
## Elle se remplit vers le bas ; les traits marquent les paliers de sommeil.
## Elle ne fait qu'afficher ce que GameState annonce.

const TAILLE := Vector2(10, 840)
const COULEUR_FOND := Color(1, 1, 1, 0.12)
const COULEUR_NIVEAU := Color(0.8, 0.75, 1, 0.6)
const COULEUR_PALIER := Color(1, 1, 1, 0.35)

var _valeur := 0.0  # profondeur ramenée entre 0 (éveillé) et 1 (maximum)
var _paliers: Array[float] = []  # seuils des paliers, entre 0 et 1


func _ready() -> void:
	var profondeur: Dictionary = Balance.donnees()["profondeur"]
	for palier in profondeur["paliers"]:
		if palier["seuil"] > 0:
			_paliers.append(palier["seuil"] / profondeur["max"])

	GameState.profondeur_changee.connect(_sur_profondeur_changee)
	_sur_profondeur_changee(GameState.profondeur)


func _sur_profondeur_changee(profondeur: float) -> void:
	_valeur = profondeur / GameState.profondeur_max
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, TAILLE), COULEUR_FOND)
	draw_rect(Rect2(0, 0, TAILLE.x, TAILLE.y * _valeur), COULEUR_NIVEAU)
	for seuil in _paliers:
		draw_rect(Rect2(-6, TAILLE.y * seuil - 1, TAILLE.x + 12, 2), COULEUR_PALIER)

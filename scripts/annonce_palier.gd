extends Label
## Affiche brièvement le nom du palier de sommeil quand le dormeur en change,
## puis s'efface. Il ne fait qu'afficher ce que GameState annonce.

const DUREE_APPARITION_S := 0.3
const DUREE_MAINTIEN_S := 1.2
const DUREE_DISPARITION_S := 0.8

var _animation: Tween


func _ready() -> void:
	modulate.a = 0.0
	GameState.palier_change.connect(_sur_palier_change)


func _sur_palier_change(palier: Dictionary) -> void:
	text = palier["nom"]
	# Si une annonce est encore à l'écran, la nouvelle la remplace.
	if _animation != null:
		_animation.kill()
	_animation = create_tween()
	_animation.tween_property(self, "modulate:a", 1.0, DUREE_APPARITION_S)
	_animation.tween_interval(DUREE_MAINTIEN_S)
	_animation.tween_property(self, "modulate:a", 0.0, DUREE_DISPARITION_S)

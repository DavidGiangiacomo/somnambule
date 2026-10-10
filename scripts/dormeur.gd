extends Area2D
## Le dormeur. Pour l'instant il ne sait que détecter les obstacles : il rougit
## un instant quand l'un d'eux le touche. L'enjambée arrive avec l'issue #9.

const COULEUR := Color(0.9, 0.9, 1.0)
const COULEUR_TOUCHE := Color(0.95, 0.3, 0.3)

@onready var corps: Polygon2D = $Corps


func _ready() -> void:
	area_entered.connect(_sur_obstacle)


func _sur_obstacle(_obstacle: Area2D) -> void:
	corps.color = COULEUR_TOUCHE
	create_tween().tween_property(corps, "color", COULEUR, 0.4)

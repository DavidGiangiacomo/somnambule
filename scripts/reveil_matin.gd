extends Button
## Le réveil-matin du décor. Il apparaît dès que le Réveil rapporterait au
## moins une réminiscence, et s'agite plus fort quand le gain a doublé depuis
## la nuit précédente. Le toucher ouvre l'écran de Réveil.
##
## Il ne décide de rien : GameState dit s'il faut le montrer et s'il insiste.

const COULEUR := Color(0.95, 0.8, 0.35)
const COULEUR_FORTE := Color(1.0, 0.9, 0.55)
const COULEUR_AIGUILLES := Color(0.2, 0.18, 0.3)
const RAYON := 46.0
# Balancement : angle maximal, en radians, et nombre d'allers-retours par seconde.
const AGITATION := {"angle": 0.08, "frequence": 2.0}
const AGITATION_FORTE := {"angle": 0.3, "frequence": 5.0}

var _temps := 0.0
var _fort := false


func _ready() -> void:
	pivot_offset = Vector2(size.x / 2.0, RAYON + 20.0)
	pressed.connect(_sur_appui)
	GameState.reminiscences_possibles_changees.connect(_sur_reminiscences_possibles_changees)
	_sur_reminiscences_possibles_changees(GameState.reminiscences_possibles)


func _process(delta: float) -> void:
	_temps += delta
	var agitation: Dictionary = AGITATION_FORTE if _fort else AGITATION
	rotation = sin(_temps * TAU * agitation["frequence"]) * agitation["angle"]


func _sur_reminiscences_possibles_changees(_reminiscences: int) -> void:
	visible = GameState.peut_se_reveiller()
	set_process(visible)
	_fort = GameState.le_reveil_sonne_fort()
	queue_redraw()


func _sur_appui() -> void:
	# L'écran de Réveil vit dans la scène principale : on l'appelle par son groupe.
	get_tree().call_group("ecran_reveil", "ouvrir")


func _draw() -> void:
	var couleur := COULEUR_FORTE if _fort else COULEUR
	var centre := Vector2(size.x / 2.0, RAYON + 20.0)
	# Les deux cloches, les pieds, puis le cadran.
	draw_circle(centre + Vector2(-32, -40), 16.0, couleur)
	draw_circle(centre + Vector2(32, -40), 16.0, couleur)
	draw_line(centre + Vector2(-24, 34), centre + Vector2(-36, 52), couleur, 8.0)
	draw_line(centre + Vector2(24, 34), centre + Vector2(36, 52), couleur, 8.0)
	draw_circle(centre, RAYON, couleur)
	draw_circle(centre, RAYON - 8.0, Color(1, 1, 1, 0.85))
	draw_line(centre, centre + Vector2(0, -26), COULEUR_AIGUILLES, 6.0)
	draw_line(centre, centre + Vector2(18, 8), COULEUR_AIGUILLES, 6.0)

	# Ce que le Réveil rapporterait.
	draw_string(
		ThemeDB.fallback_font, Vector2(0, size.y - 8.0),
		"+%d" % GameState.reminiscences_possibles,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 40, couleur
	)

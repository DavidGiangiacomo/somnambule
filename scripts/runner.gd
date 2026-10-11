extends Node2D
## La bande de rêve : le dormeur reste fixe à l'écran, le décor défile.
##
## Chaque plan du décor est un Parallax2D. Son scroll_scale, réglé dans
## l'éditeur, dit à quelle fraction de la vitesse il défile : 1 pour le sol,
## moins pour les plans lointains.
##
## Le Runner ne tient aucun compte : il signale à GameState ce qui arrive au
## dormeur (enjambée, trébuchement, fragment ramassé) et montre ce que
## GameState décide (décor qui fonce, obstacle cassé par le troupeau).

# Teinte du décor : couleurs normales à P = 0, violet profond à P maximale.
const TEINTE_EVEIL := Color(1, 1, 1)
const TEINTE_ABYSSE := Color(0.3, 0.22, 0.55)
# Le troupeau casse l'obstacle quand il arrive à cette distance du dormeur.
const DISTANCE_CASSE := 300.0
# Les fragments hors de portée sont estompés tant que personne ne les ramasse.
const OPACITE_HORS_DE_PORTEE := 0.4

var vitesse: float  # pixels par seconde

@onready var decor: Node2D = $Decor
@onready var dormeur: Area2D = $Dormeur
@onready var obstacles: Generateur = $Obstacles
@onready var generateur_fragments: Generateur = $Fragments
@onready var fragments_hauts: Generateur = $FragmentsHauts
@onready var eclat: Polygon2D = $Eclat


func _ready() -> void:
	vitesse = Balance.donnees()["defilement"]["vitesse_px_s"]
	for enfant in decor.get_children():
		if enfant is Parallax2D:
			enfant.autoscroll.x = -vitesse * enfant.scroll_scale.x

	dormeur.enjambee.connect(GameState.enjamber)
	dormeur.trebuchement.connect(GameState.trebucher)
	$Dormeur/Ramassage.area_entered.connect(_sur_fragment)
	$Dormeur/RamassageHaut.area_entered.connect(_sur_fragment_haut)

	GameState.profondeur_changee.connect(_sur_profondeur_changee)
	_sur_profondeur_changee(GameState.profondeur)
	GameState.troupeau_change.connect(_sur_troupeau_change)
	_sur_troupeau_change("", 0)
	GameState.amelioration_changee.connect(_sur_amelioration_changee)
	_sur_amelioration_changee("", 0)


func _process(_delta: float) -> void:
	# Le troupeau casse l'obstacle qui approche, sauf si le joueur s'est déjà
	# engagé à l'enjamber.
	if GameState.peut_casser_obstacle() and dormeur.etat == dormeur.Etat.MARCHE:
		var obstacle := obstacles.prochain(dormeur.position.x)
		if obstacle != null and obstacle.position.x - dormeur.position.x < DISTANCE_CASSE:
			_casser(obstacle)


func _unhandled_input(event: InputEvent) -> void:
	# Toucher n'importe où : le dormeur enjambe le prochain obstacle. Un
	# obstacle qui vient de le toucher compte encore, le temps de la tolérance.
	if event is InputEventScreenTouch and event.pressed:
		var x_min: float = dormeur.position.x - dormeur.tolerance_retard_s * vitesse
		dormeur.toucher(obstacles.prochain(x_min))


func _sur_fragment(fragment: Area2D) -> void:
	generateur_fragments.retirer(fragment)
	GameState.ramasser_fragment()


## Un fragment hors de portée passe au-dessus du dormeur : il n'est ramassé
## que si un mouton du troupeau s'en charge.
func _sur_fragment_haut(fragment: Area2D) -> void:
	if GameState.ramasse_hors_de_portee():
		fragments_hauts.retirer(fragment)
		GameState.ramasser_fragment()


func _casser(obstacle: Area2D) -> void:
	# L'éclat part du centre de l'obstacle, grossit et s'efface.
	eclat.position = obstacles.position + obstacle.position + Vector2(40, -40)
	eclat.scale = Vector2.ONE
	eclat.modulate.a = 1.0
	eclat.visible = true
	var animation := create_tween().set_parallel()
	animation.tween_property(eclat, "scale", Vector2(2.5, 2.5), 0.35)
	animation.tween_property(eclat, "modulate:a", 0.0, 0.35)

	obstacles.retirer(obstacle)
	GameState.casser_obstacle()


func _sur_profondeur_changee(profondeur: float) -> void:
	decor.modulate = TEINTE_EVEIL.lerp(TEINTE_ABYSSE, profondeur / GameState.profondeur_max)


func _sur_troupeau_change(_id: String, _nombre: int) -> void:
	fragments_hauts.modulate.a = 1.0 if GameState.ramasse_hors_de_portee() else OPACITE_HORS_DE_PORTEE


func _sur_amelioration_changee(_id: String, _niveau: int) -> void:
	dormeur.fenetre_parfaite_s = GameState.fenetre_parfaite_ms() / 1000.0

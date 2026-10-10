extends Node2D
## La bande de rêve : le dormeur reste fixe à l'écran, le décor défile.
##
## Chaque plan du décor est un Parallax2D. Son scroll_scale, réglé dans
## l'éditeur, dit à quelle fraction de la vitesse il défile : 1 pour le sol,
## moins pour les plans lointains.
##
## Le Runner ne tient aucun compte : il signale à GameState ce qui arrive au
## dormeur (enjambée, trébuchement, fragment ramassé) et fonce le décor quand
## GameState annonce que la profondeur a changé.

# Teinte du décor : couleurs normales à P = 0, violet profond à P maximale.
const TEINTE_EVEIL := Color(1, 1, 1)
const TEINTE_ABYSSE := Color(0.3, 0.22, 0.55)

var vitesse: float  # pixels par seconde

@onready var decor: Node2D = $Decor
@onready var dormeur: Area2D = $Dormeur
@onready var obstacles: Generateur = $Obstacles
@onready var generateur_fragments: Generateur = $Fragments


func _ready() -> void:
	vitesse = Balance.donnees()["defilement"]["vitesse_px_s"]
	for enfant in decor.get_children():
		if enfant is Parallax2D:
			enfant.autoscroll.x = -vitesse * enfant.scroll_scale.x

	dormeur.enjambee.connect(GameState.enjamber)
	dormeur.trebuchement.connect(GameState.trebucher)
	$Dormeur/Ramassage.area_entered.connect(_sur_fragment)

	GameState.profondeur_changee.connect(_sur_profondeur_changee)
	_sur_profondeur_changee(GameState.profondeur)


func _unhandled_input(event: InputEvent) -> void:
	# Toucher n'importe où : le dormeur enjambe le prochain obstacle. Un
	# obstacle qui vient de le toucher compte encore, le temps de la tolérance.
	if event is InputEventScreenTouch and event.pressed:
		var x_min: float = dormeur.position.x - dormeur.tolerance_retard_s * vitesse
		dormeur.toucher(obstacles.prochain(x_min))


func _sur_fragment(fragment: Area2D) -> void:
	generateur_fragments.retirer(fragment)
	GameState.ramasser_fragment()


func _sur_profondeur_changee(profondeur: float) -> void:
	decor.modulate = TEINTE_EVEIL.lerp(TEINTE_ABYSSE, profondeur / GameState.profondeur_max)

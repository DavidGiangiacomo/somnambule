extends Node2D
## La bande de rêve : le dormeur reste fixe à l'écran, le décor défile.
##
## Chaque plan est un Parallax2D. Son scroll_scale, réglé dans l'éditeur, dit à
## quelle fraction de la vitesse il défile : 1 pour le sol, moins pour les
## plans lointains.

var vitesse: float  # pixels par seconde

@onready var dormeur: Area2D = $Dormeur
@onready var obstacles: Node2D = $Obstacles


func _ready() -> void:
	vitesse = Balance.donnees()["defilement"]["vitesse_px_s"]
	for enfant in get_children():
		if enfant is Parallax2D:
			enfant.autoscroll.x = -vitesse * enfant.scroll_scale.x


func _unhandled_input(event: InputEvent) -> void:
	# Toucher n'importe où : le dormeur enjambe le prochain obstacle. Un
	# obstacle qui vient de le toucher compte encore, le temps de la tolérance.
	if event is InputEventScreenTouch and event.pressed:
		var x_min: float = dormeur.position.x - dormeur.tolerance_retard_s * vitesse
		dormeur.toucher(obstacles.prochain(x_min))

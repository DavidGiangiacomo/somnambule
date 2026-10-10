extends Node2D
## La bande de rêve : le dormeur reste fixe à l'écran, le décor défile.
##
## Chaque plan est un Parallax2D. Son scroll_scale, réglé dans l'éditeur, dit à
## quelle fraction de la vitesse il défile : 1 pour le sol, moins pour les
## plans lointains.

var vitesse: float  # pixels par seconde


func _ready() -> void:
	vitesse = Balance.donnees()["defilement"]["vitesse_px_s"]
	for enfant in get_children():
		if enfant is Parallax2D:
			enfant.autoscroll.x = -vitesse * enfant.scroll_scale.x

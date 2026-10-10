extends Node2D
## La bande de rêve : le dormeur reste fixe à l'écran, le décor défile.
##
## Chaque plan du décor est un Parallax2D. Son scroll_scale, réglé dans
## l'éditeur, dit à quelle fraction de la vitesse il défile : 1 pour le sol,
## moins pour les plans lointains.
##
## La profondeur de sommeil P monte toute seule tant qu'on ne touche pas
## l'écran. Chaque enjambée et chaque trébuchement en fait perdre une part.

# Teinte du décor : couleurs normales à P = 0, violet profond à P maximale.
const TEINTE_EVEIL := Color(1, 1, 1)
const TEINTE_ABYSSE := Color(0.3, 0.22, 0.55)

var vitesse: float  # pixels par seconde
var profondeur := 0.0  # P, entre 0 et profondeur_max
var profondeur_max: float
var couts_pourcent: Dictionary  # part de P perdue selon l'issue de l'enjambée

@onready var decor: Node2D = $Decor
@onready var dormeur: Area2D = $Dormeur
@onready var obstacles: Node2D = $Obstacles
@onready var jauge: Node2D = $Jauge


func _ready() -> void:
	var balance := Balance.donnees()
	vitesse = balance["defilement"]["vitesse_px_s"]
	profondeur_max = balance["profondeur"]["max"]
	couts_pourcent = balance["enjambee"]["cout_profondeur_pourcent"]

	for enfant in decor.get_children():
		if enfant is Parallax2D:
			enfant.autoscroll.x = -vitesse * enfant.scroll_scale.x

	dormeur.enjambee.connect(_sur_enjambee)
	dormeur.trebuchement.connect(_sur_trebuchement)


func _process(delta: float) -> void:
	profondeur += Formules.variation_profondeur(profondeur, delta)
	_montrer_profondeur()


func _unhandled_input(event: InputEvent) -> void:
	# Toucher n'importe où : le dormeur enjambe le prochain obstacle. Un
	# obstacle qui vient de le toucher compte encore, le temps de la tolérance.
	if event is InputEventScreenTouch and event.pressed:
		var x_min: float = dormeur.position.x - dormeur.tolerance_retard_s * vitesse
		dormeur.toucher(obstacles.prochain(x_min))


func _sur_enjambee(parfaite: bool) -> void:
	_faire_payer("parfaite" if parfaite else "maladroite")


func _sur_trebuchement() -> void:
	_faire_payer("trebuchement")


## Retire à P la part prévue pour cette issue : 3 veut dire 3 % de P.
func _faire_payer(issue: String) -> void:
	profondeur -= profondeur * couts_pourcent[issue] / 100.0
	_montrer_profondeur()


func _montrer_profondeur() -> void:
	var part := profondeur / profondeur_max
	jauge.valeur = part
	decor.modulate = TEINTE_EVEIL.lerp(TEINTE_ABYSSE, part)

extends Node2D
## La bande de rêve : le dormeur reste fixe à l'écran, le décor défile.
##
## Chaque plan du décor est un Parallax2D. Son scroll_scale, réglé dans
## l'éditeur, dit à quelle fraction de la vitesse il défile : 1 pour le sol,
## moins pour les plans lointains.
##
## La profondeur de sommeil P monte toute seule tant qu'on ne touche pas
## l'écran. Chaque enjambée et chaque trébuchement en fait perdre une part.
##
## Les fragments ramassés en marchant valent d'autant plus que P est haute.
## Un trébuchement fait perdre ceux des dernières secondes.

# Teinte du décor : couleurs normales à P = 0, violet profond à P maximale.
const TEINTE_EVEIL := Color(1, 1, 1)
const TEINTE_ABYSSE := Color(0.3, 0.22, 0.55)
const COULEUR_PERTE := Color(0.6, 0.5, 0.85)  # comme le dormeur qui trébuche

var vitesse: float  # pixels par seconde
var profondeur := 0.0  # P, entre 0 et profondeur_max
var profondeur_max: float
var couts_pourcent: Dictionary  # part de P perdue selon l'issue de l'enjambée
var fragments := 0.0
var valeur_fragment: float  # avant le multiplicateur M(P)
var duree_perte_s: float  # un trébuchement fait perdre les fragments de cette durée

var _temps := 0.0  # secondes écoulées depuis le début de la nuit
var _ramassages_recents: Array[Dictionary] = []  # { "temps": ..., "gain": ... }

@onready var decor: Node2D = $Decor
@onready var dormeur: Area2D = $Dormeur
@onready var obstacles: Generateur = $Obstacles
@onready var generateur_fragments: Generateur = $Fragments
@onready var compteur: Label = $Compteur
@onready var jauge: Node2D = $Jauge


func _ready() -> void:
	var balance := Balance.donnees()
	vitesse = balance["defilement"]["vitesse_px_s"]
	profondeur_max = balance["profondeur"]["max"]
	couts_pourcent = balance["enjambee"]["cout_profondeur_pourcent"]
	duree_perte_s = balance["enjambee"]["trebuchement_perte_fragments_s"]
	valeur_fragment = balance["fragments"]["valeur_base"]

	for enfant in decor.get_children():
		if enfant is Parallax2D:
			enfant.autoscroll.x = -vitesse * enfant.scroll_scale.x

	dormeur.enjambee.connect(_sur_enjambee)
	dormeur.trebuchement.connect(_sur_trebuchement)
	$Dormeur/Ramassage.area_entered.connect(_sur_fragment)


func _process(delta: float) -> void:
	_temps += delta
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
	_perdre_fragments_recents()


func _sur_fragment(fragment: Area2D) -> void:
	var gain := valeur_fragment * Formules.multiplicateur(profondeur)
	fragments += gain
	_oublier_ramassages_anciens()
	_ramassages_recents.append({"temps": _temps, "gain": gain})
	generateur_fragments.retirer(fragment)
	_montrer_fragments()


## Les fragments ramassés depuis `duree_perte_s` secondes s'envolent.
func _perdre_fragments_recents() -> void:
	_oublier_ramassages_anciens()
	for ramassage in _ramassages_recents:
		fragments -= ramassage["gain"]
	_ramassages_recents.clear()
	_montrer_fragments()
	compteur.modulate = COULEUR_PERTE
	create_tween().tween_property(compteur, "modulate", Color.WHITE, 0.8)


func _oublier_ramassages_anciens() -> void:
	var limite := _temps - duree_perte_s
	while not _ramassages_recents.is_empty() and _ramassages_recents[0]["temps"] < limite:
		_ramassages_recents.pop_front()


func _montrer_fragments() -> void:
	compteur.text = "%d" % floori(fragments)


## Retire à P la part prévue pour cette issue : 3 veut dire 3 % de P.
func _faire_payer(issue: String) -> void:
	profondeur -= profondeur * couts_pourcent[issue] / 100.0
	_montrer_profondeur()


func _montrer_profondeur() -> void:
	var part := profondeur / profondeur_max
	jauge.valeur = part
	decor.modulate = TEINTE_EVEIL.lerp(TEINTE_ABYSSE, part)

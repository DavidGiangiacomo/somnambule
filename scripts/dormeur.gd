extends Area2D
## Le dormeur. Il avance seul ; le seul geste du joueur est de toucher l'écran
## pour lui faire enjamber le prochain obstacle.
##
## - Toucher dans la fenêtre parfaite, juste avant l'obstacle : enjambée
##   parfaite (saut haut et net, éclat doré).
## - Toucher trop tôt ou un peu trop tard : enjambée maladroite (saut bas, il
##   se balance, teinte orange).
## - Ne pas toucher : trébuchement (il bascule en avant puis se relève).

signal enjambee(parfaite: bool)
signal trebuchement

enum Etat { MARCHE, PRET, SAUT, CHUTE }

const COULEUR := Color(0.9, 0.9, 1.0)
const COULEUR_PARFAITE := Color(1.0, 0.9, 0.4)
const COULEUR_MALADROITE := Color(0.95, 0.6, 0.35)
const COULEUR_CHUTE := Color(0.6, 0.5, 0.85)

const DUREE_SAUT_S := 0.7
const HAUTEUR_PARFAITE := 220.0
const HAUTEUR_MALADROITE := 130.0
# Après un toucher trop tôt, le saut part ce délai avant l'obstacle.
const AVANCE_SAUT_S := 0.1

var etat := Etat.MARCHE
var vitesse: float  # pixels par seconde
var fenetre_parfaite_s: float
var tolerance_retard_s: float

# L'obstacle que le dormeur s'est engagé à enjamber : il ne le fera pas trébucher.
var _obstacle_vise: Area2D = null

@onready var corps: Polygon2D = $Corps


func _ready() -> void:
	var balance := Balance.donnees()
	vitesse = balance["defilement"]["vitesse_px_s"]
	fenetre_parfaite_s = balance["enjambee"]["fenetre_parfaite_ms"] / 1000.0
	tolerance_retard_s = balance["enjambee"]["tolerance_retard_ms"] / 1000.0
	area_entered.connect(_sur_contact)


func _process(_delta: float) -> void:
	if etat == Etat.PRET and _temps_avant(_obstacle_vise) <= AVANCE_SAUT_S:
		_sauter(false)


## Le joueur a touché l'écran. `obstacle` est le prochain obstacle, ou null
## s'il n'y en a aucun à l'écran.
func toucher(obstacle: Area2D) -> void:
	if etat != Etat.MARCHE:
		return

	if obstacle == null:
		# Un pas dans le vide : maladroit, et il ne protège de rien.
		enjambee.emit(false)
		_sauter(false)
		return

	_obstacle_vise = obstacle
	var temps := _temps_avant(obstacle)
	if temps > fenetre_parfaite_s:
		# Trop tôt : il enjambera maladroitement, le moment venu.
		etat = Etat.PRET
		enjambee.emit(false)
		_sursauter()
	else:
		# Dans la fenêtre : parfait. Après le contact : rattrapé de justesse.
		var parfaite := temps >= 0.0
		enjambee.emit(parfaite)
		_sauter(parfaite)


## Secondes avant que l'obstacle n'atteigne le dormeur (négatif s'il le touche déjà).
func _temps_avant(obstacle: Area2D) -> float:
	return (obstacle.global_position.x - global_position.x) / vitesse


func _sur_contact(obstacle: Area2D) -> void:
	# Courte tolérance : un toucher un peu tardif sauve encore le dormeur.
	await get_tree().create_timer(tolerance_retard_s).timeout
	if obstacle != _obstacle_vise and etat != Etat.CHUTE:
		_trebucher()


func _sursauter() -> void:
	corps.color = COULEUR_MALADROITE
	corps.scale.y = 0.85
	create_tween().tween_property(corps, "scale:y", 1.0, 0.15)


func _sauter(parfaite: bool) -> void:
	etat = Etat.SAUT
	corps.color = COULEUR_PARFAITE if parfaite else COULEUR_MALADROITE
	var hauteur := HAUTEUR_PARFAITE if parfaite else HAUTEUR_MALADROITE

	var saut := create_tween()
	saut.tween_property(corps, "position:y", -hauteur, DUREE_SAUT_S / 2) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	saut.tween_property(corps, "position:y", 0.0, DUREE_SAUT_S / 2) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	saut.tween_callback(_reprendre_la_marche)

	if not parfaite:
		# Il se balance : en arrière, en avant, puis se redresse.
		var balancement := create_tween()
		balancement.tween_property(corps, "rotation", -0.3, DUREE_SAUT_S * 0.3)
		balancement.tween_property(corps, "rotation", 0.25, DUREE_SAUT_S * 0.4)
		balancement.tween_property(corps, "rotation", 0.0, DUREE_SAUT_S * 0.3)


func _trebucher() -> void:
	etat = Etat.CHUTE
	trebuchement.emit()
	corps.color = COULEUR_CHUTE

	# Il bascule en avant sur la pointe des pieds, reste un instant, se relève.
	var chute := create_tween()
	chute.tween_property(corps, "rotation", 1.3, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chute.tween_interval(0.35)
	chute.tween_property(corps, "rotation", 0.0, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	chute.tween_callback(_reprendre_la_marche)


func _reprendre_la_marche() -> void:
	etat = Etat.MARCHE
	_obstacle_vise = null
	create_tween().tween_property(corps, "color", COULEUR, 0.2)

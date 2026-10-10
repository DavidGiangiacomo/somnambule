extends Node2D
## Fait apparaître les obstacles à droite de l'écran, à intervalles aléatoires,
## et les recycle une fois sortis à gauche.
##
## Les obstacles viennent d'une réserve créée au démarrage : on ne crée ni ne
## détruit rien pendant le jeu, on déplace seulement ceux qui existent déjà.

const SCENE_OBSTACLE := preload("res://scenes/obstacle.tscn")
const TAILLE_RESERVE := 3
const X_APPARITION := 1080.0  # bord droit de l'écran de référence
const X_SORTIE := -80.0  # l'obstacle, large de 80, a quitté l'écran

var vitesse: float  # pixels par seconde
var intervalle_min_s: float
var intervalle_max_s: float

var _reserve: Array[Area2D] = []
var _actifs: Array[Area2D] = []

@onready var minuteur: Timer = $Minuteur


func _ready() -> void:
	var balance := Balance.donnees()
	vitesse = balance["defilement"]["vitesse_px_s"]
	intervalle_min_s = balance["obstacles"]["intervalle_min_s"]
	intervalle_max_s = balance["obstacles"]["intervalle_max_s"]

	for i in TAILLE_RESERVE:
		_reserve.append(_creer_obstacle())

	minuteur.timeout.connect(_sur_minuteur)
	_relancer_minuteur()


func _process(delta: float) -> void:
	# À l'envers, pour pouvoir retirer un obstacle pendant le parcours.
	for i in range(_actifs.size() - 1, -1, -1):
		var obstacle := _actifs[i]
		obstacle.position.x -= vitesse * delta
		if obstacle.position.x < X_SORTIE:
			_actifs.remove_at(i)
			_ranger(obstacle)
			_reserve.append(obstacle)


## Renvoie l'obstacle le plus proche à droite de x_min, ou null s'il n'y en a pas.
func prochain(x_min: float) -> Area2D:
	var plus_proche: Area2D = null
	for obstacle in _actifs:
		if obstacle.position.x < x_min:
			continue
		if plus_proche == null or obstacle.position.x < plus_proche.position.x:
			plus_proche = obstacle
	return plus_proche


func _sur_minuteur() -> void:
	# Si la réserve est vide (intervalles très courts), on l'agrandit.
	var obstacle: Area2D = _reserve.pop_back() if not _reserve.is_empty() else _creer_obstacle()
	obstacle.position.x = X_APPARITION
	obstacle.visible = true
	obstacle.set_deferred("monitorable", true)
	_actifs.append(obstacle)
	_relancer_minuteur()


func _relancer_minuteur() -> void:
	minuteur.start(randf_range(intervalle_min_s, intervalle_max_s))


func _creer_obstacle() -> Area2D:
	var obstacle: Area2D = SCENE_OBSTACLE.instantiate()
	_ranger(obstacle)
	add_child(obstacle)
	return obstacle


## Cache l'obstacle et le rend indétectable jusqu'à sa prochaine apparition.
func _ranger(obstacle: Area2D) -> void:
	obstacle.visible = false
	obstacle.set_deferred("monitorable", false)

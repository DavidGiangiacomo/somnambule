class_name Generateur
extends Node2D
## Base commune aux obstacles et aux fragments : des objets qui apparaissent à
## droite de l'écran, défilent avec le sol, puis sont recyclés.
##
## Les objets viennent d'une réserve créée au démarrage : on ne crée ni ne
## détruit rien pendant le jeu, on déplace seulement ceux qui existent déjà.

const X_APPARITION := 1080.0  # bord droit de l'écran de référence
const X_SORTIE := -80.0  # l'objet a quitté l'écran par la gauche

## La scène des objets à faire défiler. Sa racine doit être un Area2D.
@export var scene: PackedScene
@export var taille_reserve := 3

var vitesse: float  # pixels par seconde

var _reserve: Array[Area2D] = []
var _actifs: Array[Area2D] = []


func _ready() -> void:
	vitesse = Balance.donnees()["defilement"]["vitesse_px_s"]
	for i in taille_reserve:
		_reserve.append(_creer())


func _process(delta: float) -> void:
	# À l'envers, pour pouvoir retirer un objet pendant le parcours.
	for i in range(_actifs.size() - 1, -1, -1):
		var objet := _actifs[i]
		objet.position.x -= vitesse * delta
		if objet.position.x < X_SORTIE:
			retirer(objet)


## Fait apparaître un objet au bord droit, à la hauteur `y`.
func apparaitre(y := 0.0) -> Area2D:
	# Si la réserve est vide (apparitions très rapprochées), on l'agrandit.
	var objet: Area2D = _reserve.pop_back() if not _reserve.is_empty() else _creer()
	objet.position = Vector2(X_APPARITION, y)
	objet.visible = true
	objet.set_deferred("monitorable", true)
	_actifs.append(objet)
	return objet


## Retire un objet de l'écran et le remet dans la réserve.
func retirer(objet: Area2D) -> void:
	_actifs.erase(objet)
	_ranger(objet)
	_reserve.append(objet)


## Renvoie l'objet le plus proche à droite de x_min, ou null s'il n'y en a pas.
func prochain(x_min: float) -> Area2D:
	var plus_proche: Area2D = null
	for objet in _actifs:
		if objet.position.x < x_min:
			continue
		if plus_proche == null or objet.position.x < plus_proche.position.x:
			plus_proche = objet
	return plus_proche


func _creer() -> Area2D:
	var objet: Area2D = scene.instantiate()
	_ranger(objet)
	add_child(objet)
	return objet


## Cache l'objet et le rend indétectable jusqu'à sa prochaine apparition.
func _ranger(objet: Area2D) -> void:
	objet.visible = false
	objet.set_deferred("monitorable", false)

extends Generateur
## Fait apparaître un obstacle à intervalles aléatoires, entre le minimum et
## le maximum de balance.json.

var intervalle_min_s: float
var intervalle_max_s: float

@onready var minuteur: Timer = $Minuteur


func _ready() -> void:
	super()
	var obstacles: Dictionary = Balance.donnees()["obstacles"]
	intervalle_min_s = obstacles["intervalle_min_s"]
	intervalle_max_s = obstacles["intervalle_max_s"]
	minuteur.timeout.connect(_sur_minuteur)
	_relancer_minuteur()


func _sur_minuteur() -> void:
	apparaitre()
	_relancer_minuteur()


func _relancer_minuteur() -> void:
	minuteur.start(randf_range(intervalle_min_s, intervalle_max_s))

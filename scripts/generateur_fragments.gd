extends Generateur
## Fait flotter des fragments sur le parcours, à un rythme régulier, à une
## hauteur que le dormeur atteint en marchant.

# Hauteur au-dessus du sol : plus haut qu'un obstacle, à portée du dormeur.
const HAUTEUR_MIN := 100.0
const HAUTEUR_MAX := 150.0

@onready var minuteur: Timer = $Minuteur


func _ready() -> void:
	super()
	minuteur.timeout.connect(_sur_minuteur)
	minuteur.start(1.0 / Balance.donnees()["fragments"]["apparitions_par_seconde"])


func _sur_minuteur() -> void:
	apparaitre(-randf_range(HAUTEUR_MIN, HAUTEUR_MAX))

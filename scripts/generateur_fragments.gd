extends Generateur
## Fait flotter des fragments sur le parcours, à un rythme régulier, à une
## hauteur tirée au hasard entre hauteur_min et hauteur_max.
##
## Le Runner en a deux : les fragments à portée du dormeur, qu'il ramasse en
## marchant, et les fragments hors de portée, plus hauts et plus rares.

## Champ de « fragments » dans balance.json qui donne le nombre d'apparitions
## par seconde.
@export var cle_rythme := "apparitions_par_seconde"
## Hauteur au-dessus du sol. Un obstacle fait 80 de haut, le dormeur 160.
@export var hauteur_min := 100.0
@export var hauteur_max := 150.0

@onready var minuteur: Timer = $Minuteur


func _ready() -> void:
	super()
	minuteur.timeout.connect(_sur_minuteur)
	minuteur.start(1.0 / Balance.donnees()["fragments"][cle_rythme])


func _sur_minuteur() -> void:
	apparaitre(-randf_range(hauteur_min, hauteur_max))

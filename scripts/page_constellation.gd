extends MarginContainer
## Page Constellation du panneau. En attendant l'arbre (issue #21), elle
## montre le numéro de la nuit, les réminiscences gardées et le bonus de
## production qu'elles donnent. Elle ne fait qu'afficher ce que GameState sait.

@onready var message: Label = $Message


func _ready() -> void:
	GameState.reminiscences_changees.connect(_sur_reminiscences_changees)
	GameState.nuit_terminee.connect(_sur_nuit_terminee)
	_ecrire()


func _sur_reminiscences_changees(_reminiscences: int) -> void:
	_ecrire()


func _sur_nuit_terminee(_resume: Dictionary) -> void:
	_ecrire()


func _ecrire() -> void:
	if GameState.reminiscences == 0:
		message.text = "Nuit %d\n\nLa Constellation s'ouvrira après le premier Réveil." % GameState.nuit
		return
	var bonus := roundi((GameState.bonus_reminiscences() - 1.0) * 100.0)
	message.text = "Nuit %d\n\nRéminiscences : %d\nProduction : +%d %%" % [
		GameState.nuit, GameState.reminiscences, bonus
	]

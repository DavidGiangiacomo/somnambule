extends Label
## Images par seconde et nombre de nœuds : un outil de développement. Un
## nombre de nœuds qui grimpe trahit des objets jamais libérés.
##
## Il n'apparaît que dans l'éditeur et dans les exports qui portent la marque
## « compteur » (le préréglage « Android (développement) »). Les joueurs et
## les testeurs ne le voient pas.

const MARQUE := "compteur"


func _ready() -> void:
	visible = OS.has_feature("editor") or OS.has_feature(MARQUE)
	set_process(visible)


func _process(_delta: float) -> void:
	text = "%d i/s · %d nœuds" % [
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	]

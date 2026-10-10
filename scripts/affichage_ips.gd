extends Label
## Images par seconde et nombre de nœuds, affichés seulement dans les builds de
## débogage. Un nombre de nœuds qui grimpe trahit des objets jamais libérés.


func _ready() -> void:
	visible = OS.is_debug_build()
	set_process(visible)


func _process(_delta: float) -> void:
	text = "%d i/s · %d nœuds" % [
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	]

extends Label
## Images par seconde, affichées seulement dans les builds de débogage.


func _ready() -> void:
	visible = OS.is_debug_build()
	set_process(visible)


func _process(_delta: float) -> void:
	text = "%d i/s" % Engine.get_frames_per_second()

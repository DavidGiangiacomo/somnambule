extends Label
## Compteur de fragments. Il ne fait qu'afficher ce que GameState annonce.

const COULEUR_PERTE := Color(0.6, 0.5, 0.85)  # comme le dormeur qui trébuche


func _ready() -> void:
	GameState.fragments_changes.connect(_sur_fragments_changes)
	GameState.fragments_perdus.connect(_sur_fragments_perdus)
	_sur_fragments_changes(GameState.fragments)


func _sur_fragments_changes(fragments: float) -> void:
	text = "%d" % floori(fragments)


func _sur_fragments_perdus(_montant: float) -> void:
	modulate = COULEUR_PERTE
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.8)

extends HBoxContainer
## Barre d'onglets en bas de l'écran, à portée de pouce : un grand bouton par
## page du TabContainer voisin, dont les propres onglets sont masqués.

const TAILLE_POLICE := 40

## Le TabContainer dont cette barre choisit la page.
@export var pages: TabContainer


func _ready() -> void:
	# Un groupe : un seul bouton enfoncé à la fois.
	var groupe := ButtonGroup.new()
	for i in pages.get_tab_count():
		var bouton := Button.new()
		bouton.text = pages.get_tab_title(i)
		bouton.toggle_mode = true
		bouton.button_group = groupe
		bouton.button_pressed = i == pages.current_tab
		bouton.focus_mode = Control.FOCUS_NONE
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.add_theme_font_size_override("font_size", TAILLE_POLICE)
		bouton.pressed.connect(_montrer_page.bind(i))
		add_child(bouton)


func _montrer_page(numero: int) -> void:
	pages.current_tab = numero

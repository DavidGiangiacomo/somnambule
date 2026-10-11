extends MarginContainer
## Panneau du troupeau : les gains par seconde et un bouton d'achat par
## mouton. Il ne fait qu'afficher : c'est GameState qui tient les comptes et
## décide si un achat est possible.

# Hauteur sur un écran 16:9, le plus court prévu. Sur un écran plus haut, les
# boutons se partagent la place libre.
const HAUTEUR_MIN_BOUTON := 90.0
const TAILLE_POLICE := 40

var _fiches: Array  # les moutons tels que décrits dans balance.json
var _boutons: Dictionary = {}  # identifiant du mouton → son bouton

@onready var gains: Label = $Colonne/Ligne/Gains
@onready var achat_automatique: CheckButton = $Colonne/Ligne/AchatAutomatique
@onready var liste: VBoxContainer = $Colonne/Boutons


func _ready() -> void:
	_fiches = Balance.donnees()["moutons"]["liste"]
	for fiche in _fiches:
		var bouton := Button.new()
		bouton.custom_minimum_size.y = HAUTEUR_MIN_BOUTON
		bouton.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bouton.focus_mode = Control.FOCUS_NONE
		bouton.add_theme_font_size_override("font_size", TAILLE_POLICE)
		bouton.pressed.connect(GameState.acheter_mouton.bind(fiche["id"]))
		liste.add_child(bouton)
		_boutons[fiche["id"]] = bouton

	GameState.fragments_changes.connect(_sur_fragments_changes)
	GameState.profondeur_changee.connect(_sur_profondeur_changee)
	GameState.troupeau_change.connect(_sur_troupeau_change)
	GameState.constellation_changee.connect(_sur_constellation_changee)
	GameState.achat_automatique_change.connect(_sur_achat_automatique_change)
	achat_automatique.toggled.connect(_sur_interrupteur_bascule)
	_montrer_achat_automatique()

	_ecrire_boutons()
	_griser_boutons()
	_ecrire_gains()


func _sur_fragments_changes(_fragments: float) -> void:
	_griser_boutons()


func _sur_profondeur_changee(_profondeur: float) -> void:
	_ecrire_gains()


func _sur_troupeau_change(_id: String, _nombre: int) -> void:
	_ecrire_boutons()
	_griser_boutons()
	_ecrire_gains()


func _ecrire_boutons() -> void:
	for fiche in _fiches:
		var id: String = fiche["id"]
		# Le prix est arrondi vers le haut : afficher 34 pour un prix de 34,5
		# ferait croire qu'on peut acheter avec 34 fragments.
		_boutons[id].text = "%s ×%d  ·  %s" % [
			fiche["nom"], GameState.moutons[id], Nombres.court(ceilf(GameState.cout_mouton(id)))
		]


## Un bouton est grisé tant que le mouton est trop cher.
func _griser_boutons() -> void:
	for id: String in _boutons:
		_boutons[id].disabled = not GameState.peut_acheter_mouton(id)


func _ecrire_gains() -> void:
	gains.text = "Troupeau : +%s par seconde" % Nombres.debit(GameState.gains_par_seconde())


func _sur_constellation_changee(_id: String) -> void:
	_montrer_achat_automatique()


func _sur_achat_automatique_change(_actif: bool) -> void:
	_montrer_achat_automatique()


func _sur_interrupteur_bascule(actif: bool) -> void:
	GameState.achat_automatique = actif


## L'interrupteur n'apparaît qu'une fois l'achat automatique acquis dans la
## Constellation.
func _montrer_achat_automatique() -> void:
	achat_automatique.visible = GameState.a_l_achat_automatique()
	achat_automatique.set_pressed_no_signal(GameState.achat_automatique)

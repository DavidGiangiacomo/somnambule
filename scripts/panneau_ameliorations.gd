extends MarginContainer
## Panneau du dormeur : un bouton par amélioration, avec son niveau, son prix
## et son effet actuel. Il ne fait qu'afficher : c'est GameState qui tient les
## comptes et décide si un achat est possible.

const HAUTEUR_BOUTON := 130.0
const TAILLE_POLICE := 36

var _fiches: Array  # les améliorations telles que décrites dans balance.json
var _boutons: Dictionary = {}  # identifiant de l'amélioration → son bouton

@onready var liste: VBoxContainer = $Boutons


func _ready() -> void:
	_fiches = Balance.donnees()["ameliorations"]
	for fiche in _fiches:
		var bouton := Button.new()
		bouton.custom_minimum_size.y = HAUTEUR_BOUTON
		bouton.focus_mode = Control.FOCUS_NONE
		bouton.add_theme_font_size_override("font_size", TAILLE_POLICE)
		bouton.pressed.connect(GameState.acheter_amelioration.bind(fiche["id"]))
		liste.add_child(bouton)
		_boutons[fiche["id"]] = bouton

	GameState.fragments_changes.connect(_sur_fragments_changes)
	GameState.amelioration_changee.connect(_sur_amelioration_changee)

	_ecrire_boutons()
	_griser_boutons()


func _sur_fragments_changes(_fragments: float) -> void:
	_griser_boutons()


func _sur_amelioration_changee(_id: String, _niveau: int) -> void:
	_ecrire_boutons()
	_griser_boutons()


## Première ligne : nom, niveau et prix. Seconde ligne : l'effet obtenu.
func _ecrire_boutons() -> void:
	for fiche in _fiches:
		var id: String = fiche["id"]
		var prix := "maximum"
		if not GameState.amelioration_au_maximum(id):
			# Arrondi vers le haut, comme pour les moutons.
			prix = Nombres.court(ceilf(GameState.cout_amelioration(id)))
		_boutons[id].text = "%s niv. %d  ·  %s\n%s" % [
			fiche["nom"], GameState.ameliorations[id], prix, _decrire_effet(fiche["effet"])
		]


## Un bouton est grisé tant que le niveau suivant est trop cher, ou inutile.
func _griser_boutons() -> void:
	for id: String in _boutons:
		_boutons[id].disabled = not GameState.peut_acheter_amelioration(id)


## Ce que l'effet vaut en ce moment, en clair.
func _decrire_effet(effet: String) -> String:
	match effet:
		"vitesse_descente_pourcent":
			return "Descente dans le sommeil : +%d %%" % GameState.bonus_descente_pourcent()
		"perte_trebuchement_points":
			return "Trébucher fait perdre %d %% de profondeur" % GameState.cout_trebuchement_pourcent()
		"fenetre_parfaite_ms":
			return "Fenêtre parfaite : %d ms" % GameState.fenetre_parfaite_ms()
	return ""

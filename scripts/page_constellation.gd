extends MarginContainer
## Page Constellation du panneau : l'arbre où se dépensent les réminiscences.
## Une colonne par branche ; dans chaque colonne, les nœuds de haut en bas,
## chacun débloquant le suivant.
##
## Elle ne fait qu'afficher : GameState dit ce qui est acquis, ce qui est
## accessible, et fait l'achat.

const TAILLE_POLICE_BRANCHE := 36
const TAILLE_POLICE_NOEUD := 28
const HAUTEUR_MIN_NOEUD := 200.0
const COULEUR_ACQUIS := Color(0.95, 0.8, 0.35)  # le doré du Réveil

var _boutons: Dictionary = {}  # identifiant du nœud → son bouton

@onready var entete: Label = $Colonne/Entete
@onready var branches: HBoxContainer = $Colonne/Branches


func _ready() -> void:
	var noeuds: Array = GameState.noeuds_de_la_constellation()
	for branche in Balance.donnees()["constellation"]["branches"]:
		var colonne := VBoxContainer.new()
		colonne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		colonne.mouse_filter = Control.MOUSE_FILTER_IGNORE
		colonne.add_theme_constant_override("separation", 12)
		branches.add_child(colonne)

		var titre := Label.new()
		titre.text = branche["nom"]
		titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		titre.add_theme_font_size_override("font_size", TAILLE_POLICE_BRANCHE)
		colonne.add_child(titre)

		for noeud in noeuds:
			if noeud["branche"] == branche["id"]:
				colonne.add_child(_creer_bouton(noeud))

	GameState.reminiscences_changees.connect(_sur_reminiscences_changees)
	GameState.constellation_changee.connect(_sur_constellation_changee)
	GameState.nuit_terminee.connect(_sur_nuit_terminee)
	_tout_ecrire()


func _creer_bouton(noeud: Dictionary) -> Button:
	var bouton := Button.new()
	bouton.custom_minimum_size.y = HAUTEUR_MIN_NOEUD
	bouton.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bouton.focus_mode = Control.FOCUS_NONE
	# Le texte passe à la ligne dans la largeur de la colonne.
	bouton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bouton.add_theme_font_size_override("font_size", TAILLE_POLICE_NOEUD)
	# Un nœud acquis reste lisible, en doré, même si son bouton est inactif.
	bouton.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	bouton.pressed.connect(GameState.acheter_noeud.bind(noeud["id"]))
	_boutons[noeud["id"]] = bouton
	return bouton


func _sur_reminiscences_changees(_reminiscences: int) -> void:
	_tout_ecrire()


func _sur_constellation_changee(_id: String) -> void:
	_tout_ecrire()


func _sur_nuit_terminee(_resume: Dictionary) -> void:
	_tout_ecrire()


func _tout_ecrire() -> void:
	var bonus := roundi((GameState.bonus_reminiscences() - 1.0) * 100.0)
	entete.text = "Nuit %d  ·  Réminiscences : %d  ·  Production +%d %%" % [
		GameState.nuit, GameState.reminiscences, bonus
	]

	for noeud in GameState.noeuds_de_la_constellation():
		var id: String = noeud["id"]
		var bouton: Button = _boutons[id]
		var acquis: bool = GameState.constellation[id]
		bouton.text = "%s\n%s\n%s" % [noeud["nom"], noeud["description"], _ecrire_etat(noeud, acquis)]
		bouton.disabled = not GameState.peut_acheter_noeud(id)
		bouton.add_theme_color_override(
			"font_disabled_color", COULEUR_ACQUIS if acquis else Color(1, 1, 1, 0.4)
		)


## Dernière ligne du bouton : acquis, verrouillé, ou le prix.
func _ecrire_etat(noeud: Dictionary, acquis: bool) -> String:
	if acquis:
		return "Acquis"
	if not GameState.noeud_accessible(noeud["id"]):
		return "Verrouillé"
	var cout := int(noeud["cout"])
	return "%d réminiscence%s" % [cout, "s" if cout > 1 else ""]

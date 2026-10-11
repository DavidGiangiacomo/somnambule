extends GutTest
## Tests du panneau du bas : ses onglets et le contenu de ses pages.
##
## Le panneau lit l'autoload GameState, mais ces tests ne font que regarder :
## ils n'achètent rien et ne modifient pas la partie.

const SCENE_PANNEAU := preload("res://scenes/panneau.tscn")

var _panneau: Control
var _pages: TabContainer
var _onglets: Array[Node]


func before_each() -> void:
	_panneau = SCENE_PANNEAU.instantiate()
	add_child_autofree(_panneau)
	_pages = _panneau.get_node("Pages")
	_onglets = _panneau.get_node("Onglets").get_children()


func _textes_des_onglets() -> Array[String]:
	var textes: Array[String] = []
	for onglet: Button in _onglets:
		textes.append(onglet.text)
	return textes


func test_les_trois_onglets_sont_la_dans_l_ordre() -> void:
	assert_eq(_textes_des_onglets(), ["Troupeau", "Dormeur", "Constellation"] as Array[String])


func test_le_troupeau_est_affiche_au_depart() -> void:
	assert_eq(_pages.get_tab_title(_pages.current_tab), "Troupeau")
	assert_true(_onglets[0].button_pressed)


func test_toucher_un_onglet_montre_sa_page() -> void:
	_onglets[1].pressed.emit()
	assert_eq(_pages.get_tab_title(_pages.current_tab), "Dormeur")
	assert_true(_pages.get_node("Dormeur").visible)
	assert_false(_pages.get_node("Troupeau").visible)


func test_un_seul_onglet_est_enfonce_a_la_fois() -> void:
	_onglets[2].button_pressed = true
	var enfonces := 0
	for onglet: Button in _onglets:
		if onglet.button_pressed:
			enfonces += 1
	assert_eq(enfonces, 1)


func test_les_onglets_d_origine_du_conteneur_sont_masques() -> void:
	assert_false(_pages.tabs_visible)


func test_chaque_onglet_est_assez_haut_pour_le_pouce() -> void:
	# 48 dp, le minimum conseillé pour une cible tactile, font environ 120
	# pixels dans l'écran de référence large de 1080.
	await wait_process_frames(2)  # le temps que les conteneurs placent tout
	for onglet: Button in _onglets:
		assert_gte(onglet.size.y, 120.0, onglet.text)


func test_la_page_troupeau_a_un_bouton_par_mouton() -> void:
	var boutons := _pages.get_node("Troupeau/Colonne/Boutons").get_children()
	assert_eq(boutons.size(), Balance.donnees()["moutons"]["liste"].size())


func test_la_page_dormeur_a_un_bouton_par_amelioration() -> void:
	var boutons := _pages.get_node("Dormeur/Boutons").get_children()
	assert_eq(boutons.size(), Balance.donnees()["ameliorations"].size())


func test_les_boutons_d_achat_affichent_le_nom_du_mouton() -> void:
	var fiches: Array = Balance.donnees()["moutons"]["liste"]
	var boutons := _pages.get_node("Troupeau/Colonne/Boutons").get_children()
	for i in fiches.size():
		assert_string_contains(boutons[i].text, fiches[i]["nom"])

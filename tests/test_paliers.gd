extends GutTest
## Tests des paliers de sommeil : quel palier pour quelle profondeur, et
## l'annonce des changements. Les seuils viennent de balance.json.

const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")
const SCRIPT_ANNONCE := preload("res://scripts/annonce_palier.gd")

var _etat: Node
var _paliers: Array


func before_all() -> void:
	_paliers = Balance.donnees()["profondeur"]["paliers"]


func before_each() -> void:
	_etat = SCRIPT_GAME_STATE.new()
	add_child_autofree(_etat)
	_etat.set_process(false)


# --- Formules.palier ---


func test_a_profondeur_nulle_on_est_dans_le_premier_palier() -> void:
	assert_eq(Formules.palier(0.0)["id"], _paliers[0]["id"])


func test_on_entre_dans_un_palier_pile_a_son_seuil() -> void:
	for palier in _paliers:
		assert_eq(Formules.palier(palier["seuil"])["id"], palier["id"], palier["nom"])


func test_juste_sous_un_seuil_on_est_encore_dans_le_palier_precedent() -> void:
	for i in range(1, _paliers.size()):
		var juste_avant: float = _paliers[i]["seuil"] - 0.01
		assert_eq(Formules.palier(juste_avant)["id"], _paliers[i - 1]["id"], _paliers[i]["nom"])


func test_a_profondeur_maximale_on_est_dans_le_dernier_palier() -> void:
	var p_max: float = Balance.donnees()["profondeur"]["max"]
	assert_eq(Formules.palier(p_max)["id"], _paliers[-1]["id"])


# --- GameState ---


func test_la_partie_commence_dans_le_premier_palier() -> void:
	assert_eq(_etat.palier["id"], _paliers[0]["id"])


func test_franchir_un_seuil_annonce_le_nouveau_palier() -> void:
	watch_signals(_etat)
	_etat.profondeur = _paliers[1]["seuil"] + 1.0
	assert_signal_emitted_with_parameters(_etat, "palier_change", [_paliers[1]])
	assert_eq(_etat.palier["id"], _paliers[1]["id"])


func test_rester_dans_le_meme_palier_n_annonce_rien() -> void:
	_etat.profondeur = _paliers[1]["seuil"] + 1.0
	watch_signals(_etat)
	_etat.profondeur = _paliers[1]["seuil"] + 2.0
	_etat.profondeur = _paliers[1]["seuil"] + 3.0
	assert_signal_not_emitted(_etat, "palier_change")


func test_remonter_vers_l_eveil_annonce_aussi_le_palier() -> void:
	_etat.profondeur = _paliers[2]["seuil"] + 1.0
	watch_signals(_etat)
	_etat.profondeur = _paliers[1]["seuil"] + 1.0
	assert_signal_emitted_with_parameters(_etat, "palier_change", [_paliers[1]])


func test_un_trebuchement_peut_faire_changer_de_palier() -> void:
	_etat.profondeur = _paliers[1]["seuil"] + 1.0
	watch_signals(_etat)
	_etat.trebucher()
	assert_signal_emitted(_etat, "palier_change")
	assert_eq(_etat.palier["id"], Formules.palier(_etat.profondeur)["id"])


func test_sauter_plusieurs_paliers_n_annonce_que_celui_d_arrivee() -> void:
	watch_signals(_etat)
	_etat.profondeur = _paliers[-1]["seuil"] + 1.0
	assert_signal_emit_count(_etat, "palier_change", 1)
	assert_eq(_etat.palier["id"], _paliers[-1]["id"])


func test_la_partie_rechargee_retrouve_son_palier() -> void:
	_etat.depuis_sauvegarde({"profondeur": _paliers[3]["seuil"] + 1.0})
	assert_eq(_etat.palier["id"], _paliers[3]["id"])


# --- L'annonce à l'écran ---
# Elle écoute l'autoload GameState : on émet son signal à la main, sans
# toucher à la partie.


func _nouvelle_annonce() -> Label:
	var annonce := Label.new()
	annonce.set_script(SCRIPT_ANNONCE)
	add_child_autofree(annonce)
	return annonce


func test_l_annonce_est_invisible_tant_qu_on_ne_change_pas_de_palier() -> void:
	assert_eq(_nouvelle_annonce().modulate.a, 0.0)


func test_l_annonce_affiche_le_nom_du_nouveau_palier() -> void:
	var annonce := _nouvelle_annonce()
	GameState.palier_change.emit(_paliers[2])
	assert_eq(annonce.text, _paliers[2]["nom"])


func test_l_annonce_apparait_puis_s_efface() -> void:
	var annonce := _nouvelle_annonce()
	GameState.palier_change.emit(_paliers[2])

	await wait_seconds(SCRIPT_ANNONCE.DUREE_APPARITION_S + 0.2)
	assert_almost_eq(annonce.modulate.a, 1.0, 0.01, "visible après l'apparition")

	await wait_seconds(SCRIPT_ANNONCE.DUREE_MAINTIEN_S + SCRIPT_ANNONCE.DUREE_DISPARITION_S + 0.2)
	assert_almost_eq(annonce.modulate.a, 0.0, 0.01, "effacée à la fin")


func test_une_nouvelle_annonce_remplace_celle_en_cours() -> void:
	var annonce := _nouvelle_annonce()
	GameState.palier_change.emit(_paliers[1])
	await wait_seconds(0.2)
	GameState.palier_change.emit(_paliers[2])
	assert_eq(annonce.text, _paliers[2]["nom"])

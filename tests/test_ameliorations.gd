extends GutTest
## Tests des améliorations du dormeur : achat par niveaux et effets.
## Chaque test travaille sur un GameState neuf, pas sur la vraie partie.
##
## Les améliorations sont repérées par leur effet (« celle qui accélère la
## descente »), pas par leur nom ; les valeurs viennent de balance.json.

const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")

var _etat: Node
var _fiches: Array
var _couts: Dictionary


func before_all() -> void:
	_fiches = Balance.donnees()["ameliorations"]
	_couts = Balance.donnees()["enjambee"]["cout_profondeur_pourcent"]


func before_each() -> void:
	_etat = SCRIPT_GAME_STATE.new()
	add_child_autofree(_etat)
	_etat.set_process(false)


## Renvoie la fiche de l'amélioration qui agit sur cet effet.
func _fiche_pour(effet: String) -> Dictionary:
	for fiche in _fiches:
		if fiche["effet"] == effet:
			return fiche
	fail_test("Aucune amélioration n'a l'effet « %s » dans balance.json" % effet)
	return {}


# --- Achat ---


func test_toutes_les_ameliorations_commencent_au_niveau_zero() -> void:
	for fiche in _fiches:
		assert_eq(_etat.ameliorations[fiche["id"]], 0, fiche["id"])


func test_sans_fragments_on_ne_peut_rien_ameliorer() -> void:
	for fiche in _fiches:
		assert_false(_etat.peut_acheter_amelioration(fiche["id"]), fiche["id"])
	assert_false(_etat.acheter_amelioration(_fiches[0]["id"]))
	assert_eq(_etat.ameliorations[_fiches[0]["id"]], 0)


func test_un_achat_retire_le_prix_et_monte_d_un_niveau() -> void:
	var id: String = _fiches[0]["id"]
	_etat.fragments = _etat.cout_amelioration(id) + 5.0

	assert_true(_etat.acheter_amelioration(id))

	assert_almost_eq(_etat.fragments, 5.0, 1e-9)
	assert_eq(_etat.ameliorations[id], 1)


func test_chaque_niveau_coute_plus_cher_que_le_precedent() -> void:
	var fiche: Dictionary = _fiches[0]
	var id: String = fiche["id"]
	assert_almost_eq(_etat.cout_amelioration(id), fiche["cout_initial"], 1e-9)
	_etat.fragments = 1e9
	_etat.acheter_amelioration(id)
	assert_almost_eq(
		_etat.cout_amelioration(id), fiche["cout_initial"] * fiche["raison_cout"], 1e-6
	)


func test_un_achat_est_annonce_par_signal() -> void:
	var id: String = _fiches[0]["id"]
	_etat.fragments = 1e9
	watch_signals(_etat)
	_etat.acheter_amelioration(id)
	assert_signal_emitted_with_parameters(_etat, "amelioration_changee", [id, 1])
	assert_signal_emitted_with_parameters(_etat, "achat_effectue", [id])


func test_un_achat_refuse_n_annonce_rien() -> void:
	watch_signals(_etat)
	_etat.acheter_amelioration(_fiches[0]["id"])
	assert_signal_not_emitted(_etat, "amelioration_changee")
	assert_signal_not_emitted(_etat, "achat_effectue")


# --- Descente plus rapide ---


func test_sans_amelioration_la_descente_n_est_pas_acceleree() -> void:
	assert_eq(_etat.bonus_descente_pourcent(), 0.0)


func test_chaque_niveau_accelere_la_descente() -> void:
	var fiche := _fiche_pour("vitesse_descente_pourcent")
	_etat.ameliorations[fiche["id"]] = 3
	assert_almost_eq(_etat.bonus_descente_pourcent(), 3 * fiche["valeur_par_niveau"], 1e-9)


func test_la_profondeur_monte_plus_vite_avec_l_amelioration() -> void:
	var fiche := _fiche_pour("vitesse_descente_pourcent")
	_etat.ameliorations[fiche["id"]] = 2
	_etat._process(1.0)
	var acceleration: float = 1.0 + 2 * fiche["valeur_par_niveau"] / 100.0
	assert_almost_eq(
		_etat.profondeur, Formules.variation_profondeur(0.0, 1.0) * acceleration, 1e-9
	)


func test_meme_acceleree_la_profondeur_ne_depasse_pas_le_maximum() -> void:
	_etat.ameliorations[_fiche_pour("vitesse_descente_pourcent")["id"]] = 20
	for seconde in 3600:
		_etat._process(1.0)
	assert_lte(_etat.profondeur, _etat.profondeur_max)


# --- Trébuchement moins coûteux ---


func test_sans_amelioration_le_trebuchement_coute_son_prix_de_base() -> void:
	assert_eq(_etat.cout_trebuchement_pourcent(), float(_couts["trebuchement"]))


func test_chaque_niveau_adoucit_le_trebuchement() -> void:
	var fiche := _fiche_pour("perte_trebuchement_points")
	_etat.ameliorations[fiche["id"]] = 2
	var attendu: float = _couts["trebuchement"] + 2 * fiche["valeur_par_niveau"]
	assert_almost_eq(_etat.cout_trebuchement_pourcent(), attendu, 1e-9)
	assert_lt(attendu, float(_couts["trebuchement"]), "la valeur par niveau doit être négative")


func test_le_trebuchement_adouci_fait_perdre_moins_de_profondeur() -> void:
	var fiche := _fiche_pour("perte_trebuchement_points")
	_etat.ameliorations[fiche["id"]] = 2
	_etat.profondeur = 50.0
	_etat.trebucher()
	var cout: float = _couts["trebuchement"] + 2 * fiche["valeur_par_niveau"]
	assert_almost_eq(_etat.profondeur, 50.0 * (1.0 - cout / 100.0), 1e-9)


func test_le_trebuchement_ne_descend_jamais_sous_le_plancher() -> void:
	var fiche := _fiche_pour("perte_trebuchement_points")
	_etat.ameliorations[fiche["id"]] = 100
	assert_eq(_etat.cout_trebuchement_pourcent(), float(fiche["plancher"]))


func test_l_amelioration_ne_touche_pas_au_cout_des_enjambees() -> void:
	_etat.ameliorations[_fiche_pour("perte_trebuchement_points")["id"]] = 3
	_etat.profondeur = 50.0
	_etat.enjamber(false)
	assert_almost_eq(_etat.profondeur, 50.0 * (1.0 - _couts["maladroite"] / 100.0), 1e-9)


func test_au_plancher_l_amelioration_ne_se_vend_plus() -> void:
	var fiche := _fiche_pour("perte_trebuchement_points")
	var id: String = fiche["id"]
	_etat.fragments = 1e12

	var achats := 0
	while _etat.acheter_amelioration(id) and achats < 1000:
		achats += 1

	assert_true(_etat.amelioration_au_maximum(id))
	assert_eq(_etat.cout_trebuchement_pourcent(), float(fiche["plancher"]))
	var niveaux_utiles := ceili(
		(_couts["trebuchement"] - fiche["plancher"]) / absf(fiche["valeur_par_niveau"])
	)
	assert_eq(achats, niveaux_utiles, "on n'achète que les niveaux qui servent")


func test_les_autres_ameliorations_n_ont_pas_de_maximum() -> void:
	var id: String = _fiche_pour("vitesse_descente_pourcent")["id"]
	_etat.ameliorations[id] = 500
	assert_false(_etat.amelioration_au_maximum(id))


# --- Fenêtre parfaite plus large ---


func test_sans_amelioration_la_fenetre_parfaite_est_celle_de_base() -> void:
	var base: float = Balance.donnees()["enjambee"]["fenetre_parfaite_ms"]
	assert_eq(_etat.fenetre_parfaite_ms(), base)


func test_chaque_niveau_elargit_la_fenetre_parfaite() -> void:
	var fiche := _fiche_pour("fenetre_parfaite_ms")
	var base: float = Balance.donnees()["enjambee"]["fenetre_parfaite_ms"]
	_etat.ameliorations[fiche["id"]] = 2
	assert_almost_eq(_etat.fenetre_parfaite_ms(), base + 2 * fiche["valeur_par_niveau"], 1e-9)


# --- Sauvegarde ---


func test_les_niveaux_sont_sauvegardes_et_retrouves() -> void:
	var id: String = _fiches[0]["id"]
	_etat.ameliorations[id] = 4
	var sauvegarde: Dictionary = _etat.vers_sauvegarde()

	var partie_relancee: Node = SCRIPT_GAME_STATE.new()
	add_child_autofree(partie_relancee)
	# Comme après un passage par le fichier JSON, les entiers reviennent à virgule.
	partie_relancee.depuis_sauvegarde(JSON.parse_string(JSON.stringify(sauvegarde)))

	assert_eq(partie_relancee.ameliorations[id], 4)
	assert_typeof(partie_relancee.ameliorations[id], TYPE_INT)


func test_une_ancienne_sauvegarde_sans_ameliorations_repart_du_niveau_zero() -> void:
	_etat.depuis_sauvegarde({"fragments": 10.0})
	for fiche in _fiches:
		assert_eq(_etat.ameliorations[fiche["id"]], 0, fiche["id"])

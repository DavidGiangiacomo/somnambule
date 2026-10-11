extends GutTest
## Tests de la Constellation : l'achat des nœuds avec des réminiscences et
## l'effet de chacun. Chaque test travaille sur un GameState neuf.
##
## Les nœuds sont repérés par leur effet (« celui qui fait commencer la nuit
## plus profond »), pas par leur nom ; les valeurs viennent de balance.json.

const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")

var _etat: Node
var _noeuds: Array
var _couts: Dictionary


func before_all() -> void:
	_noeuds = Balance.donnees()["constellation"]["noeuds"]
	_couts = Balance.donnees()["enjambee"]["cout_profondeur_pourcent"]


func before_each() -> void:
	_etat = SCRIPT_GAME_STATE.new()
	add_child_autofree(_etat)
	_etat.set_process(false)


## Renvoie le nœud qui porte cet effet dans balance.json.
func _noeud_pour(effet: String) -> Dictionary:
	for noeud in _noeuds:
		if noeud["effet"] == effet:
			return noeud
	fail_test("Aucun nœud n'a l'effet « %s » dans balance.json" % effet)
	return {}


## Donne le nœud au joueur sans passer par l'achat, avec ceux qu'il requiert.
func _acquerir(effet: String) -> Dictionary:
	var noeud := _noeud_pour(effet)
	_etat.constellation[noeud["id"]] = true
	return noeud


func _premier_noeud_d_une_branche() -> Dictionary:
	for noeud in _noeuds:
		if not noeud.has("requiert"):
			return noeud
	return {}


func _noeud_avec_prerequis() -> Dictionary:
	for noeud in _noeuds:
		if noeud.has("requiert"):
			return noeud
	return {}


# --- Les données ---


func test_chaque_branche_a_ses_noeuds() -> void:
	for branche in Balance.donnees()["constellation"]["branches"]:
		var nombre := 0
		for noeud in _noeuds:
			if noeud["branche"] == branche["id"]:
				nombre += 1
		assert_gt(nombre, 0, branche["nom"])


func test_chaque_noeud_a_un_prix_et_des_textes() -> void:
	var identifiants := {}
	for noeud in _noeuds:
		assert_gt(noeud["cout"], 0.0, noeud["id"])
		assert_ne(noeud["nom"], "", noeud["id"])
		assert_ne(noeud["description"], "", noeud["id"])
		assert_does_not_have(identifiants, noeud["id"], "identifiant en double")
		identifiants[noeud["id"]] = true


func test_un_prerequis_designe_un_noeud_de_la_meme_branche() -> void:
	var branches := {}
	for noeud in _noeuds:
		branches[noeud["id"]] = noeud["branche"]
	for noeud in _noeuds:
		if noeud.has("requiert"):
			assert_has(branches, noeud["requiert"], noeud["id"])
			assert_eq(branches[noeud["requiert"]], noeud["branche"], noeud["id"])


# --- Achat ---


func test_aucun_noeud_n_est_acquis_au_depart() -> void:
	for noeud in _noeuds:
		assert_false(_etat.constellation[noeud["id"]], noeud["id"])


func test_sans_reminiscence_on_ne_peut_rien_acheter() -> void:
	for noeud in _noeuds:
		assert_false(_etat.peut_acheter_noeud(noeud["id"]), noeud["id"])
	assert_false(_etat.acheter_noeud(_premier_noeud_d_une_branche()["id"]))


func test_un_achat_depense_les_reminiscences_et_donne_le_noeud() -> void:
	var noeud := _premier_noeud_d_une_branche()
	_etat.reminiscences = int(noeud["cout"]) + 2

	assert_true(_etat.acheter_noeud(noeud["id"]))

	assert_eq(_etat.reminiscences, 2)
	assert_true(_etat.constellation[noeud["id"]])


func test_un_noeud_ne_s_achete_qu_une_fois() -> void:
	var noeud := _premier_noeud_d_une_branche()
	_etat.reminiscences = 100
	_etat.acheter_noeud(noeud["id"])
	var restantes: int = _etat.reminiscences

	assert_false(_etat.acheter_noeud(noeud["id"]))
	assert_eq(_etat.reminiscences, restantes)


func test_le_second_noeud_d_une_branche_demande_le_premier() -> void:
	var noeud := _noeud_avec_prerequis()
	_etat.reminiscences = 100

	assert_false(_etat.noeud_accessible(noeud["id"]))
	assert_false(_etat.acheter_noeud(noeud["id"]), "verrouillé tant que le premier manque")

	_etat.acheter_noeud(noeud["requiert"])
	assert_true(_etat.noeud_accessible(noeud["id"]))
	assert_true(_etat.acheter_noeud(noeud["id"]))


func test_un_achat_est_annonce_par_signal() -> void:
	var noeud := _premier_noeud_d_une_branche()
	_etat.reminiscences = 100
	watch_signals(_etat)
	_etat.acheter_noeud(noeud["id"])
	assert_signal_emitted_with_parameters(_etat, "constellation_changee", [noeud["id"]])
	assert_signal_emitted(_etat, "reminiscences_changees")


func test_depenser_des_reminiscences_reduit_le_bonus_de_production() -> void:
	var noeud := _premier_noeud_d_une_branche()
	_etat.reminiscences = int(noeud["cout"]) + 1
	var bonus_avant: float = _etat.bonus_reminiscences()
	_etat.acheter_noeud(noeud["id"])
	assert_lt(_etat.bonus_reminiscences(), bonus_avant)
	assert_almost_eq(_etat.bonus_reminiscences(), Formules.bonus_reminiscences(1), 1e-9)


func test_les_noeuds_survivent_au_reveil() -> void:
	var noeud := _premier_noeud_d_une_branche()
	_etat.reminiscences = 100
	_etat.acheter_noeud(noeud["id"])
	_etat.fragments_de_la_nuit = Balance.donnees()["reminiscences"]["diviseur_fragments"]

	_etat.se_reveiller()

	assert_true(_etat.constellation[noeud["id"]])


# --- Abysses ---


func test_sans_noeud_la_nuit_commence_eveille() -> void:
	assert_eq(_etat.profondeur_de_depart(), 0.0)


func test_la_nuit_suivante_commence_au_palier_promis() -> void:
	var noeud := _acquerir("depart_palier")
	var seuil := 0.0
	for palier in Balance.donnees()["profondeur"]["paliers"]:
		if palier["id"] == noeud["valeur"]:
			seuil = palier["seuil"]
	_etat.fragments_de_la_nuit = Balance.donnees()["reminiscences"]["diviseur_fragments"]

	_etat.se_reveiller()

	assert_gt(seuil, 0.0)
	assert_eq(_etat.profondeur, seuil)
	assert_eq(_etat.palier["id"], noeud["valeur"])


func test_le_noeud_adoucit_le_trebuchement() -> void:
	var noeud := _acquerir("perte_trebuchement_points")
	assert_almost_eq(
		_etat.cout_trebuchement_pourcent(), _couts["trebuchement"] + noeud["valeur"], 1e-9
	)
	assert_lt(noeud["valeur"], 0.0, "la valeur doit être négative")


func test_le_noeud_et_l_amelioration_s_additionnent_jusqu_au_plancher() -> void:
	var noeud := _acquerir("perte_trebuchement_points")
	var couette: Dictionary
	for fiche in Balance.donnees()["ameliorations"]:
		if fiche["effet"] == "perte_trebuchement_points":
			couette = fiche

	_etat.ameliorations[couette["id"]] = 1
	var attendu: float = _couts["trebuchement"] + noeud["valeur"] + couette["valeur_par_niveau"]
	assert_almost_eq(_etat.cout_trebuchement_pourcent(), maxf(attendu, couette["plancher"]), 1e-9)

	_etat.ameliorations[couette["id"]] = 50
	assert_eq(_etat.cout_trebuchement_pourcent(), float(couette["plancher"]))


# --- Lucidité ---


func test_le_noeud_elargit_la_fenetre_parfaite() -> void:
	var base: float = _etat.fenetre_parfaite_ms()
	var noeud := _acquerir("fenetre_parfaite_ms")
	assert_almost_eq(_etat.fenetre_parfaite_ms(), base + noeud["valeur"], 1e-9)


func test_sans_noeud_aucune_enjambee_n_est_gratuite() -> void:
	assert_false(_etat.enjambee_gratuite_prete())
	_etat.profondeur = 50.0
	_etat.enjamber(true)
	assert_lt(_etat.profondeur, 50.0)


func test_la_premiere_enjambee_parfaite_est_gratuite() -> void:
	_acquerir("parfaite_gratuite_toutes_les_s")
	_etat.profondeur = 50.0
	assert_true(_etat.enjambee_gratuite_prete())
	_etat.enjamber(true)
	assert_eq(_etat.profondeur, 50.0)


func test_la_suivante_est_payante_jusqu_a_la_fin_du_delai() -> void:
	var delai: float = _acquerir("parfaite_gratuite_toutes_les_s")["valeur"]
	_etat.profondeur = 50.0
	_etat.enjamber(true)

	assert_false(_etat.enjambee_gratuite_prete())
	_etat.enjamber(true)
	assert_almost_eq(_etat.profondeur, 50.0 * (1.0 - _couts["parfaite"] / 100.0), 1e-9)

	_etat._recharge_gratuite_s = 0.0  # comme si le délai était écoulé
	assert_true(_etat.enjambee_gratuite_prete())
	assert_gt(delai, 0.0)


func test_le_delai_de_la_gratuite_s_ecoule_avec_le_temps() -> void:
	var delai: float = _acquerir("parfaite_gratuite_toutes_les_s")["valeur"]
	_etat.enjamber(true)
	_etat._process(delai - 1.0)
	assert_false(_etat.enjambee_gratuite_prete(), "une seconde avant la fin")
	_etat._process(1.5)
	assert_true(_etat.enjambee_gratuite_prete(), "une fois le délai écoulé")


func test_une_enjambee_maladroite_ne_consomme_pas_la_gratuite() -> void:
	_acquerir("parfaite_gratuite_toutes_les_s")
	_etat.profondeur = 50.0
	_etat.enjamber(false)
	assert_lt(_etat.profondeur, 50.0, "la maladroite reste payante")
	assert_true(_etat.enjambee_gratuite_prete())


# --- Troupeau ---


func test_sans_noeud_rien_ne_s_achete_tout_seul() -> void:
	_etat.fragments = 1e6
	_etat._process(5.0)
	for id: String in _etat.moutons:
		assert_eq(_etat.moutons[id], 0, id)


func test_avec_le_noeud_les_moutons_s_achetent_tout_seuls() -> void:
	_acquerir("achat_automatique")
	var moins_cher: Dictionary = Balance.donnees()["moutons"]["liste"][0]
	_etat.fragments = moins_cher["cout_initial"] + 1.0

	_etat._process(1.0)

	assert_eq(_etat.moutons[moins_cher["id"]], 1)


func test_l_achat_automatique_prend_le_mouton_le_plus_cher_possible() -> void:
	_acquerir("achat_automatique")
	var liste: Array = Balance.donnees()["moutons"]["liste"]
	_etat.fragments = liste[1]["cout_initial"] + 1.0  # de quoi payer le deuxième mouton

	_etat._process(1.0)

	assert_eq(_etat.moutons[liste[1]["id"]], 1)
	assert_eq(_etat.moutons[liste[0]["id"]], 0)


func test_le_joueur_peut_couper_l_achat_automatique() -> void:
	_acquerir("achat_automatique")
	_etat.achat_automatique = false
	_etat.fragments = 1e6

	_etat._process(5.0)

	for id: String in _etat.moutons:
		assert_eq(_etat.moutons[id], 0, id)


func test_le_noeud_allonge_le_plafond_hors_ligne() -> void:
	assert_eq(_etat.bonus_plafond_hors_ligne_s(), 0.0)
	var noeud := _acquerir("plafond_hors_ligne_h")
	assert_almost_eq(_etat.bonus_plafond_hors_ligne_s(), noeud["valeur"] * 3600.0, 1e-9)


# --- Sauvegarde ---


func test_la_constellation_est_sauvegardee_et_retrouvee() -> void:
	var noeud := _premier_noeud_d_une_branche()
	_etat.reminiscences = 100
	_etat.acheter_noeud(noeud["id"])
	_etat.achat_automatique = false
	var sauvegarde: Dictionary = JSON.parse_string(JSON.stringify(_etat.vers_sauvegarde()))

	var partie_relancee: Node = SCRIPT_GAME_STATE.new()
	add_child_autofree(partie_relancee)
	partie_relancee.set_process(false)
	partie_relancee.depuis_sauvegarde(sauvegarde)

	assert_true(partie_relancee.constellation[noeud["id"]])
	assert_false(partie_relancee.achat_automatique)
	for autre in _noeuds:
		if autre["id"] != noeud["id"]:
			assert_false(partie_relancee.constellation[autre["id"]], autre["id"])


func test_une_sauvegarde_sans_constellation_repart_sans_noeud() -> void:
	_etat.depuis_sauvegarde({"fragments": 10.0})
	for noeud in _noeuds:
		assert_false(_etat.constellation[noeud["id"]], noeud["id"])
	assert_true(_etat.achat_automatique)

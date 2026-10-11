extends GutTest
## Garde-fous sur data/balance.json : le jeu lit ces valeurs sans les
## vérifier, une faute de frappe dans le fichier doit donc se voir ici.

var _balance: Dictionary


func before_all() -> void:
	_balance = Balance.donnees()


func test_le_fichier_se_charge() -> void:
	assert_false(_balance.is_empty())


func test_le_fichier_n_est_lu_qu_une_fois() -> void:
	assert_same(Balance.donnees(), Balance.donnees())


func test_les_valeurs_lues_par_le_jeu_existent() -> void:
	assert_gt(_balance["defilement"]["vitesse_px_s"], 0.0)
	assert_gt(_balance["profondeur"]["max"], 0.0)
	assert_gt(_balance["profondeur"]["vitesse_descente"], 0.0)
	assert_gt(_balance["enjambee"]["fenetre_parfaite_ms"], 0.0)
	assert_gte(_balance["enjambee"]["tolerance_retard_ms"], 0.0)
	assert_gt(_balance["enjambee"]["trebuchement_perte_fragments_s"], 0.0)
	assert_gt(_balance["fragments"]["apparitions_par_seconde"], 0.0)
	assert_gt(_balance["fragments"]["valeur_base"], 0.0)


func test_les_obstacles_ont_un_intervalle_coherent() -> void:
	var obstacles: Dictionary = _balance["obstacles"]
	assert_gt(obstacles["intervalle_min_s"], 0.0)
	assert_gte(obstacles["intervalle_max_s"], obstacles["intervalle_min_s"])


func test_une_enjambee_parfaite_coute_moins_qu_une_maladroite() -> void:
	var couts: Dictionary = _balance["enjambee"]["cout_profondeur_pourcent"]
	assert_lt(couts["parfaite"], couts["maladroite"])
	assert_lt(couts["maladroite"], couts["trebuchement"])
	assert_lte(couts["trebuchement"], 100.0)


func test_les_paliers_sont_ranges_du_moins_au_plus_profond() -> void:
	var paliers: Array = _balance["profondeur"]["paliers"]
	assert_eq(paliers[0]["seuil"], 0.0, "le premier palier commence à 0")
	for i in range(1, paliers.size()):
		assert_gt(paliers[i]["seuil"], paliers[i - 1]["seuil"])
	assert_lt(paliers[-1]["seuil"], _balance["profondeur"]["max"])


func test_les_fragments_hors_de_portee_ont_un_rythme() -> void:
	assert_gt(_balance["fragments"]["hors_de_portee_par_seconde"], 0.0)


func test_chaque_mouton_a_un_prix_et_une_production() -> void:
	var identifiants := {}
	for fiche in _balance["moutons"]["liste"]:
		assert_gt(fiche["cout_initial"], 0.0, fiche["id"])
		assert_gt(fiche["raison_cout"], 1.0, fiche["id"])
		assert_gt(fiche["production_par_seconde"], 0.0, fiche["id"])
		assert_does_not_have(identifiants, fiche["id"], "identifiant en double")
		identifiants[fiche["id"]] = true
	assert_gt(_balance["moutons"]["doublement_tous_les"], 0.0)


func test_les_moutons_sont_ranges_du_moins_cher_au_plus_cher() -> void:
	var liste: Array = _balance["moutons"]["liste"]
	for i in range(1, liste.size()):
		assert_gt(liste[i]["cout_initial"], liste[i - 1]["cout_initial"])


func test_un_bonus_de_palier_designe_un_palier_qui_existe() -> void:
	var paliers := {}
	for palier in _balance["profondeur"]["paliers"]:
		paliers[palier["id"]] = true
	for fiche in _balance["moutons"]["liste"]:
		if fiche.has("bonus_palier"):
			assert_has(paliers, fiche["bonus_palier"], fiche["id"])
			assert_gt(fiche["bonus_multiplicateur"], 1.0, fiche["id"])

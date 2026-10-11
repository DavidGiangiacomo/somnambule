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

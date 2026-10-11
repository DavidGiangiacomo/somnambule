extends GutTest
## Tests du troupeau : achat, production et particularités des moutons.
## Chaque test travaille sur un GameState neuf, pas sur la vraie partie.
##
## Les prix et productions attendus sont recalculés depuis balance.json. Les
## particularités sont repérées par leur champ (« le mouton qui casse les
## obstacles »), pas par un nom de mouton.

const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")

var _etat: Node
var _fiches: Array
var _doublement: int
var _premier: Dictionary  # le mouton le moins cher


func before_all() -> void:
	_fiches = Balance.donnees()["moutons"]["liste"]
	_doublement = Balance.donnees()["moutons"]["doublement_tous_les"]
	_premier = _fiches[0]


func before_each() -> void:
	_etat = SCRIPT_GAME_STATE.new()
	add_child_autofree(_etat)
	_etat.set_process(false)


## Renvoie la fiche du mouton qui porte ce champ dans balance.json.
func _fiche_avec(champ: String) -> Dictionary:
	for fiche in _fiches:
		if fiche.has(champ):
			return fiche
	fail_test("Aucun mouton n'a le champ « %s » dans balance.json" % champ)
	return {}


# --- Formules ---


func test_le_premier_mouton_coute_son_prix_de_base() -> void:
	assert_almost_eq(Formules.cout_mouton(_premier, 0), _premier["cout_initial"], 1e-9)


func test_chaque_mouton_coute_plus_cher_que_le_precedent() -> void:
	var attendu: float = _premier["cout_initial"] * pow(_premier["raison_cout"], 10)
	assert_almost_eq(Formules.cout_mouton(_premier, 10), attendu, 1e-6)
	assert_gt(Formules.cout_mouton(_premier, 11), Formules.cout_mouton(_premier, 10))


## Mêmes chiffres que simulateur/formules.py avec les valeurs calées de #3 :
## 30 × 1,15^10 et 0,1 × 50 × 2².
func test_les_formules_donnent_les_chiffres_du_simulateur() -> void:
	var mouton := {"cout_initial": 30.0, "raison_cout": 1.15, "production_par_seconde": 0.1}
	assert_almost_eq(Formules.cout_mouton(mouton, 10), 121.36673, 1e-4)
	assert_almost_eq(Formules.production_moutons(mouton, 50, 25), 20.0, 1e-9)


func test_la_production_est_proportionnelle_au_nombre_de_moutons() -> void:
	var unitaire: float = _premier["production_par_seconde"]
	assert_eq(Formules.production_moutons(_premier, 0, _doublement), 0.0)
	assert_almost_eq(Formules.production_moutons(_premier, 1, _doublement), unitaire, 1e-9)
	assert_almost_eq(Formules.production_moutons(_premier, 10, _doublement), unitaire * 10, 1e-9)


func test_la_production_double_a_chaque_palier_d_exemplaires() -> void:
	var unitaire: float = _premier["production_par_seconde"]
	var n := _doublement
	assert_almost_eq(Formules.production_moutons(_premier, n - 1, n), unitaire * (n - 1), 1e-9)
	assert_almost_eq(Formules.production_moutons(_premier, n, n), unitaire * n * 2, 1e-9)
	assert_almost_eq(Formules.production_moutons(_premier, 2 * n, n), unitaire * 2 * n * 4, 1e-9)


# --- Achat ---


func test_sans_fragments_on_ne_peut_rien_acheter() -> void:
	for fiche in _fiches:
		assert_false(_etat.peut_acheter_mouton(fiche["id"]))
	assert_false(_etat.acheter_mouton(_premier["id"]))
	assert_eq(_etat.moutons[_premier["id"]], 0)


func test_un_achat_retire_le_prix_et_ajoute_un_mouton() -> void:
	var prix: float = _etat.cout_mouton(_premier["id"])
	_etat.fragments = prix + 5.0

	assert_true(_etat.acheter_mouton(_premier["id"]))

	assert_almost_eq(_etat.fragments, 5.0, 1e-9)
	assert_eq(_etat.moutons[_premier["id"]], 1)


func test_on_peut_acheter_avec_exactement_le_prix() -> void:
	_etat.fragments = _etat.cout_mouton(_premier["id"])
	assert_true(_etat.acheter_mouton(_premier["id"]))
	assert_almost_eq(_etat.fragments, 0.0, 1e-9)


func test_il_manque_un_rien_et_l_achat_est_refuse() -> void:
	_etat.fragments = _etat.cout_mouton(_premier["id"]) - 0.01
	assert_false(_etat.acheter_mouton(_premier["id"]))
	assert_eq(_etat.moutons[_premier["id"]], 0)


func test_le_prix_monte_apres_chaque_achat() -> void:
	var id: String = _premier["id"]
	var premier_prix: float = _etat.cout_mouton(id)
	_etat.fragments = 1e9
	_etat.acheter_mouton(id)
	assert_almost_eq(_etat.cout_mouton(id), premier_prix * _premier["raison_cout"], 1e-6)


func test_un_achat_est_annonce_par_signal() -> void:
	var id: String = _premier["id"]
	_etat.fragments = 1e9
	watch_signals(_etat)
	_etat.acheter_mouton(id)
	assert_signal_emitted_with_parameters(_etat, "troupeau_change", [id, 1])
	assert_signal_emitted_with_parameters(_etat, "achat_effectue", [id])


func test_un_achat_refuse_n_annonce_rien() -> void:
	watch_signals(_etat)
	_etat.acheter_mouton(_premier["id"])
	assert_signal_not_emitted(_etat, "achat_effectue")
	assert_signal_not_emitted(_etat, "troupeau_change")


# --- Production ---


func test_sans_mouton_le_troupeau_ne_rapporte_rien() -> void:
	assert_eq(_etat.production_troupeau(), 0.0)
	assert_eq(_etat.gains_par_seconde(), 0.0)
	_etat._process(10.0)
	assert_eq(_etat.fragments, 0.0)


func test_le_troupeau_additionne_la_production_de_chaque_type() -> void:
	_etat.moutons[_fiches[0]["id"]] = 4
	_etat.moutons[_fiches[1]["id"]] = 2
	var attendu: float = (
		_fiches[0]["production_par_seconde"] * 4 + _fiches[1]["production_par_seconde"] * 2
	)
	assert_almost_eq(_etat.production_troupeau(), attendu, 1e-9)


func test_les_gains_sont_multiplies_par_la_profondeur() -> void:
	_etat.moutons[_premier["id"]] = 10
	var a_la_surface: float = _etat.gains_par_seconde()
	_etat.profondeur = 30.0
	assert_almost_eq(
		_etat.gains_par_seconde(), a_la_surface * Formules.multiplicateur(30.0), 1e-9
	)


func test_le_troupeau_produit_en_continu() -> void:
	_etat.moutons[_premier["id"]] = 10
	var gains: float = _etat.gains_par_seconde()  # à profondeur nulle
	_etat._process(0.001)  # un pas assez court pour que P ne bouge presque pas
	assert_almost_eq(_etat.fragments, gains * 0.001, gains * 0.001 * 0.01)


func test_un_trebuchement_ne_reprend_pas_la_production_du_troupeau() -> void:
	_etat.fragments = 50.0  # produits par le troupeau, pas ramassés
	_etat.trebucher()
	assert_almost_eq(_etat.fragments, 50.0, 1e-9)


func test_un_trebuchement_ne_rend_jamais_le_compteur_negatif() -> void:
	_etat.ramasser_fragment()
	_etat.fragments = 0.0  # tout a été dépensé entre-temps
	_etat.trebucher()
	assert_eq(_etat.fragments, 0.0)


# --- Particularités ---


func test_le_mouton_a_bonus_produit_plus_a_partir_de_son_palier() -> void:
	var fiche := _fiche_avec("bonus_palier")
	var seuil := 0.0
	for palier in Balance.donnees()["profondeur"]["paliers"]:
		if palier["id"] == fiche["bonus_palier"]:
			seuil = palier["seuil"]
	_etat.moutons[fiche["id"]] = 1

	_etat.profondeur = seuil - 1.0
	var avant: float = _etat.production_troupeau()
	_etat.profondeur = seuil
	var apres: float = _etat.production_troupeau()

	assert_almost_eq(avant, fiche["production_par_seconde"], 1e-9)
	assert_almost_eq(apres, avant * fiche["bonus_multiplicateur"], 1e-9)


func test_sans_le_bon_mouton_aucun_obstacle_n_est_casse() -> void:
	_etat.moutons[_premier["id"]] = 10
	assert_false(_etat.peut_casser_obstacle())


func test_le_mouton_casseur_est_pret_des_l_achat() -> void:
	_etat.moutons[_fiche_avec("casse_obstacle_toutes_les_s")["id"]] = 1
	assert_true(_etat.peut_casser_obstacle())


func test_apres_un_obstacle_casse_il_faut_attendre() -> void:
	var fiche := _fiche_avec("casse_obstacle_toutes_les_s")
	var delai: float = fiche["casse_obstacle_toutes_les_s"]
	_etat.moutons[fiche["id"]] = 1

	_etat.casser_obstacle()
	assert_false(_etat.peut_casser_obstacle(), "juste après")
	_etat._process(delai - 1.0)
	assert_false(_etat.peut_casser_obstacle(), "une seconde avant la fin du délai")
	_etat._process(1.5)
	assert_true(_etat.peut_casser_obstacle(), "une fois le délai écoulé")


func test_plusieurs_moutons_casseurs_ne_cassent_pas_plus_souvent() -> void:
	var fiche := _fiche_avec("casse_obstacle_toutes_les_s")
	_etat.moutons[fiche["id"]] = 10
	_etat.casser_obstacle()
	_etat._process(fiche["casse_obstacle_toutes_les_s"] / 2.0)
	assert_false(_etat.peut_casser_obstacle())


func test_les_fragments_hors_de_portee_demandent_le_bon_mouton() -> void:
	assert_false(_etat.ramasse_hors_de_portee())
	_etat.moutons[_premier["id"]] = 10
	assert_false(_etat.ramasse_hors_de_portee())
	_etat.moutons[_fiche_avec("ramasse_hors_de_portee")["id"]] = 1
	assert_true(_etat.ramasse_hors_de_portee())

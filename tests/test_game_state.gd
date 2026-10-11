extends GutTest
## Tests des règles du jeu tenues par GameState. Chaque test travaille sur un
## exemplaire neuf, pas sur l'autoload : la vraie partie n'est jamais touchée.

const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")

var _etat: Node
var _couts: Dictionary


func before_all() -> void:
	_couts = Balance.donnees()["enjambee"]["cout_profondeur_pourcent"]


func before_each() -> void:
	_etat = SCRIPT_GAME_STATE.new()
	add_child_autofree(_etat)
	# La profondeur ne monte que quand le test le demande.
	_etat.set_process(false)


# --- Profondeur ---


func test_la_profondeur_monte_toute_seule() -> void:
	_etat._process(1.0)
	assert_almost_eq(_etat.profondeur, Formules.variation_profondeur(0.0, 1.0), 1e-9)


func test_la_profondeur_ne_depasse_jamais_le_maximum() -> void:
	for seconde in 3600:
		_etat._process(1.0)
	assert_lte(_etat.profondeur, _etat.profondeur_max)
	assert_almost_eq(_etat.profondeur, _etat.profondeur_max, 0.01)


func test_une_enjambee_parfaite_coute_peu_de_profondeur() -> void:
	_etat.profondeur = 50.0
	_etat.enjamber(true)
	assert_almost_eq(_etat.profondeur, 50.0 * (1.0 - _couts["parfaite"] / 100.0), 1e-9)


func test_une_enjambee_maladroite_coute_davantage() -> void:
	_etat.profondeur = 50.0
	_etat.enjamber(false)
	assert_almost_eq(_etat.profondeur, 50.0 * (1.0 - _couts["maladroite"] / 100.0), 1e-9)


func test_un_trebuchement_coute_le_plus_cher() -> void:
	_etat.profondeur = 50.0
	_etat.trebucher()
	assert_almost_eq(_etat.profondeur, 50.0 * (1.0 - _couts["trebuchement"] / 100.0), 1e-9)


func test_le_cout_est_une_part_de_la_profondeur_pas_un_montant_fixe() -> void:
	_etat.profondeur = 0.0
	_etat.trebucher()
	assert_eq(_etat.profondeur, 0.0)


# --- Fragments ---


func test_un_fragment_vaut_sa_valeur_de_base_a_profondeur_nulle() -> void:
	_etat.ramasser_fragment()
	assert_almost_eq(_etat.fragments, Balance.donnees()["fragments"]["valeur_base"], 1e-9)


func test_un_fragment_vaut_plus_en_profondeur() -> void:
	_etat.profondeur = 60.0
	_etat.ramasser_fragment()
	var base: float = Balance.donnees()["fragments"]["valeur_base"]
	assert_almost_eq(_etat.fragments, base * Formules.multiplicateur(60.0), 1e-9)
	assert_gt(_etat.fragments, base * 3.0)


func test_un_trebuchement_fait_perdre_les_fragments_recents() -> void:
	_etat.ramasser_fragment()
	_etat.ramasser_fragment()
	_etat.trebucher()
	assert_almost_eq(_etat.fragments, 0.0, 1e-9)


func test_un_trebuchement_epargne_les_fragments_anciens() -> void:
	var duree_perte: float = Balance.donnees()["enjambee"]["trebuchement_perte_fragments_s"]
	_etat.ramasser_fragment()
	var anciens: float = _etat.fragments
	_etat._process(duree_perte + 1.0)  # le temps passe
	_etat.ramasser_fragment()

	_etat.trebucher()

	assert_almost_eq(_etat.fragments, anciens, 1e-9)


func test_deux_trebuchements_de_suite_ne_font_pas_perdre_deux_fois() -> void:
	_etat.fragments = 100.0
	_etat.ramasser_fragment()
	_etat.trebucher()
	_etat.trebucher()
	assert_almost_eq(_etat.fragments, 100.0, 1e-9)


# --- Signaux ---


func test_les_changements_sont_annonces_par_signal() -> void:
	watch_signals(_etat)
	_etat.ramasser_fragment()
	_etat.enjamber(true)
	assert_signal_emitted_with_parameters(_etat, "fragments_changes", [_etat.fragments])
	assert_signal_emitted_with_parameters(_etat, "profondeur_changee", [_etat.profondeur])


func test_un_trebuchement_annonce_le_montant_perdu() -> void:
	_etat.ramasser_fragment()
	var gain: float = _etat.fragments
	watch_signals(_etat)
	_etat.trebucher()
	assert_signal_emitted_with_parameters(_etat, "fragments_perdus", [gain])


# --- Sauvegarde ---


func test_la_sauvegarde_contient_fragments_profondeur_et_troupeau() -> void:
	_etat.fragments = 123.5
	_etat.profondeur = 42.0
	_etat.moutons["mouton"] = 3
	var donnees: Dictionary = _etat.vers_sauvegarde()
	assert_eq(donnees["fragments"], 123.5)
	assert_eq(donnees["profondeur"], 42.0)
	assert_eq(donnees["moutons"]["mouton"], 3)


func test_on_retrouve_la_partie_sauvegardee() -> void:
	_etat.depuis_sauvegarde({"fragments": 123.5, "profondeur": 42.0, "moutons": {"mouton": 3}})
	assert_eq(_etat.fragments, 123.5)
	assert_eq(_etat.profondeur, 42.0)
	assert_eq(_etat.moutons["mouton"], 3)


## Le JSON rend les entiers sous forme de nombres à virgule.
func test_le_troupeau_sauvegarde_redevient_un_nombre_entier() -> void:
	_etat.depuis_sauvegarde({"moutons": {"mouton": 3.0}})
	assert_typeof(_etat.moutons["mouton"], TYPE_INT)


func test_le_chargement_annonce_le_troupeau_par_signal() -> void:
	watch_signals(_etat)
	_etat.depuis_sauvegarde({"moutons": {"mouton": 3}})
	assert_signal_emitted_with_parameters(_etat, "troupeau_change", ["mouton", 3], 0)


func test_un_champ_absent_de_la_sauvegarde_repart_de_zero() -> void:
	_etat.depuis_sauvegarde({})
	assert_eq(_etat.fragments, 0.0)
	assert_eq(_etat.profondeur, 0.0)
	for id: String in _etat.moutons:
		assert_eq(_etat.moutons[id], 0)


func test_un_mouton_inconnu_dans_la_sauvegarde_est_ignore() -> void:
	_etat.depuis_sauvegarde({"moutons": {"licorne": 5}})
	assert_does_not_have(_etat.moutons, "licorne")


func test_une_profondeur_sauvegardee_hors_bornes_est_ramenee_dans_les_bornes() -> void:
	_etat.depuis_sauvegarde({"profondeur": 9999.0})
	assert_eq(_etat.profondeur, _etat.profondeur_max)
	_etat.depuis_sauvegarde({"profondeur": -5.0})
	assert_eq(_etat.profondeur, 0.0)

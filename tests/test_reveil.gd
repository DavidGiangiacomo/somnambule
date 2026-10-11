extends GutTest
## Tests du Réveil : les réminiscences gagnées, ce qui repart de zéro, ce qui
## reste, et le bonus de production des nuits suivantes.
## Chaque test travaille sur un GameState neuf, pas sur la vraie partie.

const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")
const SCRIPT_SAUVEGARDE := preload("res://scripts/sauvegarde.gd")
const SCRIPT_ECRAN := preload("res://scripts/ecran_reveil.gd")

var _etat: Node
var _diviseur: float  # fragments de la nuit qu'il faut pour 1 réminiscence
var _bonus_pourcent: float


func before_all() -> void:
	_diviseur = Balance.donnees()["reminiscences"]["diviseur_fragments"]
	_bonus_pourcent = Balance.donnees()["reminiscences"]["bonus_production_pourcent"]


func before_each() -> void:
	_etat = SCRIPT_GAME_STATE.new()
	add_child_autofree(_etat)
	_etat.set_process(false)


## Met la partie dans l'état d'une nuit bien avancée, qui vaut `reminiscences`.
func _avancer_la_nuit(reminiscences: int) -> void:
	_etat.fragments_de_la_nuit = _diviseur * reminiscences * reminiscences
	_etat.fragments = 5000.0
	_etat.profondeur = 70.0
	_etat.moutons[_etat.moutons.keys()[0]] = 12
	_etat.ameliorations[_etat.ameliorations.keys()[0]] = 3
	_etat._temps = 600.0  # dix minutes de nuit


# --- Formules ---


func test_il_faut_le_diviseur_entier_pour_une_reminiscence() -> void:
	assert_eq(Formules.reminiscences(0.0), 0)
	assert_eq(Formules.reminiscences(_diviseur * 0.99), 0)
	assert_eq(Formules.reminiscences(_diviseur), 1)


func test_chaque_reminiscence_coute_de_plus_en_plus_cher() -> void:
	assert_eq(Formules.reminiscences(_diviseur * 3.99), 1)
	assert_eq(Formules.reminiscences(_diviseur * 4.0), 2)
	assert_eq(Formules.reminiscences(_diviseur * 9.0), 3)
	assert_eq(Formules.reminiscences(_diviseur * 100.0), 10)


func test_un_total_negatif_ne_donne_aucune_reminiscence() -> void:
	assert_eq(Formules.reminiscences(-50.0), 0)


func test_le_bonus_grandit_avec_les_reminiscences_gardees() -> void:
	assert_almost_eq(Formules.bonus_reminiscences(0), 1.0, 1e-9)
	assert_almost_eq(Formules.bonus_reminiscences(1), 1.0 + _bonus_pourcent / 100.0, 1e-9)
	assert_almost_eq(Formules.bonus_reminiscences(5), 1.0 + 5 * _bonus_pourcent / 100.0, 1e-9)


# --- Le total de la nuit ---


func test_les_fragments_ramasses_comptent_dans_la_nuit() -> void:
	_etat.ramasser_fragment()
	assert_almost_eq(_etat.fragments_de_la_nuit, _etat.fragments, 1e-9)
	assert_gt(_etat.fragments_de_la_nuit, 0.0)


func test_la_production_du_troupeau_compte_dans_la_nuit() -> void:
	_etat.moutons[_etat.moutons.keys()[0]] = 10
	_etat._process(1.0)
	assert_gt(_etat.fragments_de_la_nuit, 0.0)
	assert_almost_eq(_etat.fragments_de_la_nuit, _etat.fragments, 1e-9)


func test_depenser_ne_diminue_pas_le_total_de_la_nuit() -> void:
	var id: String = _etat.moutons.keys()[0]
	_etat.fragments = 1000.0
	_etat.fragments_de_la_nuit = 1000.0
	_etat.acheter_mouton(id)
	assert_lt(_etat.fragments, 1000.0)
	assert_eq(_etat.fragments_de_la_nuit, 1000.0)


## Comme dans le simulateur : ce qu'un trébuchement fait perdre ne compte plus.
func test_un_trebuchement_retire_aussi_du_total_de_la_nuit() -> void:
	_etat.ramasser_fragment()
	_etat.trebucher()
	assert_almost_eq(_etat.fragments_de_la_nuit, 0.0, 1e-9)


func test_franchir_le_seuil_annonce_la_reminiscence_possible() -> void:
	watch_signals(_etat)
	_etat.fragments_de_la_nuit = _diviseur * 0.5
	assert_signal_not_emitted(_etat, "reminiscences_possibles_changees")
	_etat.fragments_de_la_nuit = _diviseur
	assert_signal_emitted_with_parameters(_etat, "reminiscences_possibles_changees", [1])
	assert_eq(_etat.reminiscences_possibles, 1)


# --- Se réveiller ---


func test_on_ne_peut_pas_se_reveiller_sans_reminiscence_a_gagner() -> void:
	_etat.fragments_de_la_nuit = _diviseur * 0.9
	_etat.fragments = 500.0
	assert_false(_etat.peut_se_reveiller())
	assert_false(_etat.se_reveiller())
	assert_eq(_etat.fragments, 500.0, "rien n'est remis à zéro")
	assert_eq(_etat.nuit, 1)


func test_le_reveil_donne_les_reminiscences_de_la_nuit() -> void:
	_avancer_la_nuit(3)
	assert_true(_etat.se_reveiller())
	assert_eq(_etat.reminiscences, 3)
	assert_eq(_etat.reminiscences_derniere_nuit, 3)


func test_les_reminiscences_s_ajoutent_d_une_nuit_a_l_autre() -> void:
	_avancer_la_nuit(2)
	_etat.se_reveiller()
	_avancer_la_nuit(1)
	_etat.se_reveiller()
	assert_eq(_etat.reminiscences, 3)
	assert_eq(_etat.reminiscences_derniere_nuit, 1)
	assert_eq(_etat.nuit, 3)


func test_le_reveil_remet_la_nuit_a_zero() -> void:
	_avancer_la_nuit(1)
	_etat.se_reveiller()

	assert_eq(_etat.fragments, 0.0)
	assert_eq(_etat.fragments_de_la_nuit, 0.0)
	assert_eq(_etat.profondeur, 0.0)
	assert_eq(_etat.profondeur_record, 0.0)
	assert_eq(_etat.reminiscences_possibles, 0)
	for id: String in _etat.moutons:
		assert_eq(_etat.moutons[id], 0, id)
	for id: String in _etat.ameliorations:
		assert_eq(_etat.ameliorations[id], 0, id)


func test_apres_le_reveil_les_prix_reviennent_au_depart() -> void:
	var id: String = _etat.moutons.keys()[0]
	var prix_de_depart: float = _etat.cout_mouton(id)
	_avancer_la_nuit(1)
	_etat.se_reveiller()
	assert_almost_eq(_etat.cout_mouton(id), prix_de_depart, 1e-9)


func test_le_reveil_annonce_tout_ce_qui_change() -> void:
	_avancer_la_nuit(2)
	var premier_mouton: String = _etat.moutons.keys()[0]
	var premiere_amelioration: String = _etat.ameliorations.keys()[0]
	watch_signals(_etat)

	_etat.se_reveiller()

	assert_signal_emitted(_etat, "nuit_terminee")
	assert_signal_emitted_with_parameters(_etat, "reminiscences_changees", [2])
	assert_signal_emitted_with_parameters(_etat, "troupeau_change", [premier_mouton, 0], 0)
	assert_signal_emitted_with_parameters(
		_etat, "amelioration_changee", [premiere_amelioration, 0], 0
	)
	assert_signal_emitted_with_parameters(_etat, "fragments_changes", [0.0])


func test_le_resume_decrit_la_nuit_qui_s_acheve() -> void:
	_avancer_la_nuit(2)
	var resume: Dictionary = _etat.resume_de_la_nuit()
	assert_eq(resume["nuit"], 1)
	assert_eq(resume["reminiscences"], 2)
	assert_almost_eq(resume["duree_s"], 600.0, 0.001)
	assert_gte(resume["fragments"], _diviseur * 4.0)
	assert_eq(resume["palier"]["id"], Formules.palier(_etat.profondeur_record)["id"])


func test_le_palier_du_resume_est_le_plus_profond_atteint_pas_l_actuel() -> void:
	_etat.profondeur = 85.0
	_etat.profondeur = 10.0  # un trébuchement l'a fait remonter
	assert_eq(_etat.resume_de_la_nuit()["palier"]["id"], Formules.palier(85.0)["id"])


# --- Le bonus des nuits suivantes ---


func test_la_premiere_nuit_n_a_aucun_bonus() -> void:
	assert_almost_eq(_etat.bonus_reminiscences(), 1.0, 1e-9)


func test_les_fragments_ramasses_valent_plus_apres_un_reveil() -> void:
	_etat.ramasser_fragment()
	var gain_premiere_nuit: float = _etat.fragments
	_avancer_la_nuit(3)
	_etat.se_reveiller()

	_etat.ramasser_fragment()

	assert_almost_eq(
		_etat.fragments, gain_premiere_nuit * (1.0 + 3 * _bonus_pourcent / 100.0), 1e-9
	)


func test_le_troupeau_produit_plus_apres_un_reveil() -> void:
	var id: String = _etat.moutons.keys()[0]
	_etat.moutons[id] = 10
	var gains_premiere_nuit: float = _etat.gains_par_seconde()
	_avancer_la_nuit(2)
	_etat.se_reveiller()

	_etat.moutons[id] = 10

	assert_almost_eq(
		_etat.gains_par_seconde(),
		gains_premiere_nuit * (1.0 + 2 * _bonus_pourcent / 100.0),
		1e-9
	)


# --- Le réveil-matin ---


func test_la_premiere_nuit_le_reveil_insiste_a_partir_de_deux_reminiscences() -> void:
	_etat.fragments_de_la_nuit = _diviseur
	assert_true(_etat.peut_se_reveiller())
	assert_false(_etat.le_reveil_sonne_fort())
	_etat.fragments_de_la_nuit = _diviseur * 4.0
	assert_true(_etat.le_reveil_sonne_fort())


func test_ensuite_il_insiste_quand_le_gain_double_depuis_la_derniere_nuit() -> void:
	_avancer_la_nuit(3)
	_etat.se_reveiller()

	_etat.fragments_de_la_nuit = _diviseur * 5.0 * 5.0
	assert_false(_etat.le_reveil_sonne_fort(), "5 réminiscences après une nuit à 3")
	_etat.fragments_de_la_nuit = _diviseur * 6.0 * 6.0
	assert_true(_etat.le_reveil_sonne_fort(), "6 réminiscences après une nuit à 3")


# --- Sauvegarde ---


func test_la_progression_entre_les_nuits_est_sauvegardee() -> void:
	_avancer_la_nuit(2)
	_etat.se_reveiller()
	_etat.fragments_de_la_nuit = 1234.0
	_etat._temps = 42.0
	var sauvegarde: Dictionary = JSON.parse_string(JSON.stringify(_etat.vers_sauvegarde()))

	var partie_relancee: Node = SCRIPT_GAME_STATE.new()
	add_child_autofree(partie_relancee)
	partie_relancee.set_process(false)
	partie_relancee.depuis_sauvegarde(sauvegarde)

	assert_eq(partie_relancee.nuit, 2)
	assert_eq(partie_relancee.reminiscences, 2)
	assert_eq(partie_relancee.reminiscences_derniere_nuit, 2)
	assert_almost_eq(partie_relancee.fragments_de_la_nuit, _etat.fragments_de_la_nuit, 1e-6)
	assert_almost_eq(partie_relancee.resume_de_la_nuit()["duree_s"], 42.0, 1e-6)
	assert_typeof(partie_relancee.reminiscences, TYPE_INT)


func test_une_sauvegarde_d_avant_le_reveil_est_migree() -> void:
	var sauvegarde: Node = SCRIPT_SAUVEGARDE.new()
	sauvegarde.chemin = "user://sauvegarde_de_test_inexistante.json"
	sauvegarde.etat = _etat
	add_child_autofree(sauvegarde)

	var ancienne := {"save_version": 1, "fragments": 750.0, "profondeur": 30.0}
	var migree: Dictionary = sauvegarde._migrer(ancienne)

	assert_eq(migree["save_version"], 2)
	assert_eq(migree["fragments_de_la_nuit"], 750.0, "on repart de ce que le joueur a en poche")
	_etat.depuis_sauvegarde(migree)
	assert_eq(_etat.nuit, 1)
	assert_eq(_etat.reminiscences, 0)


# --- Le texte de l'écran de Réveil ---


func test_l_ecran_annonce_les_reminiscences_et_le_bonus_a_venir() -> void:
	_avancer_la_nuit(2)
	var texte: String = SCRIPT_ECRAN.texte_du_resume(_etat.resume_de_la_nuit(), 1)
	assert_string_contains(texte, "Nuit 1")
	assert_string_contains(texte, "Durée : 10 min 00 s")
	assert_string_contains(texte, "Réminiscences gagnées : +2")
	# 1 déjà gardée + 2 gagnées
	assert_string_contains(texte, "+%d %%" % roundi(3 * _bonus_pourcent))


# --- Nombres.duree ---


func test_les_durees_s_ecrivent_en_clair() -> void:
	assert_eq(Nombres.duree(0.0), "0 s")
	assert_eq(Nombres.duree(45.9), "45 s")
	assert_eq(Nombres.duree(60.0), "1 min 00 s")
	assert_eq(Nombres.duree(965.0), "16 min 05 s")
	assert_eq(Nombres.duree(3720.0), "1 h 02 min")

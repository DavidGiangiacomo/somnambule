extends GutTest
## Tests des gains hors-ligne : ce que rapporte une absence, son plafond, le
## bonus de nuit complète et la garde contre une horloge qui recule.
## Chaque test travaille sur un GameState neuf et un fichier à part.

const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")
const SCRIPT_SAUVEGARDE := preload("res://scripts/sauvegarde.gd")
const SCRIPT_ECRAN := preload("res://scripts/ecran_absence.gd")
const CHEMIN := "user://sauvegarde_de_test_hors_ligne.json"
const HEURE := 3600.0

var _etat: Node
var _regles: Dictionary
var _heure_simulee := 1_000_000.0


func before_all() -> void:
	_regles = Balance.donnees()["hors_ligne"]


func before_each() -> void:
	_effacer_fichiers()
	_heure_simulee = 1_000_000.0
	_etat = _nouvel_etat()


func after_all() -> void:
	_effacer_fichiers()


func _effacer_fichiers() -> void:
	for chemin: String in [CHEMIN, CHEMIN + ".tmp"]:
		if FileAccess.file_exists(chemin):
			DirAccess.remove_absolute(chemin)


func _nouvel_etat() -> Node:
	var etat: Node = SCRIPT_GAME_STATE.new()
	add_child_autofree(etat)
	etat.set_process(false)
	return etat


## Donne un troupeau à l'état, pour qu'une absence rapporte quelque chose.
func _donner_un_troupeau(etat: Node = _etat) -> void:
	etat.moutons[etat.moutons.keys()[0]] = 10
	etat.moutons[etat.moutons.keys()[1]] = 5


func _lire_l_heure() -> float:
	return _heure_simulee


## Crée une sauvegarde branchée sur `etat`, dont l'horloge est celle du test.
func _nouvelle_sauvegarde(etat: Node) -> Node:
	var sauvegarde: Node = SCRIPT_SAUVEGARDE.new()
	sauvegarde.chemin = CHEMIN
	sauvegarde.etat = etat
	sauvegarde.horloge = _lire_l_heure
	add_child_autofree(sauvegarde)
	return sauvegarde


# --- Ce que rapporte une absence ---


func test_une_absence_rapporte_la_production_du_troupeau() -> void:
	_donner_un_troupeau()
	var par_seconde: float = _etat.gains_par_seconde()

	var resume: Dictionary = _etat.appliquer_absence(HEURE)

	assert_almost_eq(_etat.fragments, par_seconde * HEURE, 1e-6)
	assert_almost_eq(resume["gain"], par_seconde * HEURE, 1e-6)
	assert_eq(resume["duree_s"], HEURE)


func test_sans_troupeau_une_absence_ne_rapporte_rien() -> void:
	assert_eq(_etat.appliquer_absence(HEURE), {})
	assert_eq(_etat.fragments, 0.0)


func test_une_absence_trop_courte_ne_rapporte_rien() -> void:
	_donner_un_troupeau()
	assert_eq(_etat.appliquer_absence(_regles["absence_min_s"] - 1.0), {})
	assert_eq(_etat.fragments, 0.0)


## Critère de l'issue #22.
func test_quitter_en_abysse_rapporte_bien_plus_que_quitter_assoupi() -> void:
	_donner_un_troupeau()
	_etat.profondeur = 5.0
	var gain_assoupi: float = _etat.appliquer_absence(HEURE)["gain"]

	var autre := _nouvel_etat()
	_donner_un_troupeau(autre)
	autre.profondeur = 90.0
	var gain_abysse: float = autre.appliquer_absence(HEURE)["gain"]

	assert_gt(gain_abysse, gain_assoupi * 5.0)
	assert_almost_eq(
		gain_abysse / gain_assoupi,
		Formules.multiplicateur(90.0) / Formules.multiplicateur(5.0),
		1e-6
	)


func test_la_profondeur_ne_bouge_pas_pendant_l_absence() -> void:
	_donner_un_troupeau()
	_etat.profondeur = 70.0
	_etat.appliquer_absence(3.0 * HEURE)
	assert_eq(_etat.profondeur, 70.0)


func test_les_gains_hors_ligne_comptent_pour_le_reveil() -> void:
	_donner_un_troupeau()
	_etat.appliquer_absence(HEURE)
	assert_almost_eq(_etat.fragments_de_la_nuit, _etat.fragments, 1e-6)
	assert_gt(_etat.fragments_de_la_nuit, 0.0)


func test_les_reminiscences_augmentent_aussi_les_gains_hors_ligne() -> void:
	_donner_un_troupeau()
	var sans_bonus: float = _etat.gains_par_seconde() * HEURE
	_etat.reminiscences = 3
	var resume: Dictionary = _etat.appliquer_absence(HEURE)
	assert_almost_eq(resume["gain"], sans_bonus * Formules.bonus_reminiscences(3), 1e-6)


func test_le_retour_est_annonce_par_signal_et_garde_pour_l_ecran() -> void:
	_donner_un_troupeau()
	watch_signals(_etat)
	var resume: Dictionary = _etat.appliquer_absence(HEURE)
	assert_signal_emitted(_etat, "retour_d_absence")
	assert_eq(_etat.absence_a_montrer, resume)


# --- Plafond ---


func test_le_plafond_est_celui_de_balance_json() -> void:
	assert_almost_eq(_etat.plafond_hors_ligne_s(), _regles["plafond_h"] * HEURE, 1e-9)


func test_au_dela_du_plafond_l_absence_ne_rapporte_plus() -> void:
	_donner_un_troupeau()
	var par_seconde: float = _etat.gains_par_seconde()
	var plafond: float = _etat.plafond_hors_ligne_s()
	# Bien au-delà du plafond et de la fenêtre de nuit complète.
	var resume: Dictionary = _etat.appliquer_absence(plafond + 20.0 * HEURE)

	assert_almost_eq(resume["gain"], par_seconde * plafond, 1e-6)
	assert_true(resume["plafond_atteint"])
	assert_eq(resume["duree_comptee_s"], plafond)


func test_sous_le_plafond_il_n_est_pas_signale() -> void:
	_donner_un_troupeau()
	assert_false(_etat.appliquer_absence(HEURE)["plafond_atteint"])


func test_la_constellation_allonge_le_plafond() -> void:
	var plafond_de_base: float = _etat.plafond_hors_ligne_s()
	for noeud in Balance.donnees()["constellation"]["noeuds"]:
		if noeud["effet"] == "plafond_hors_ligne_h":
			_etat.constellation[noeud["id"]] = true
			assert_almost_eq(
				_etat.plafond_hors_ligne_s(), plafond_de_base + noeud["valeur"] * HEURE, 1e-9
			)
			return
	fail_test("Aucun nœud n'allonge le plafond hors-ligne")


# --- Nuit complète ---


func test_une_nuit_complete_donne_son_bonus() -> void:
	_donner_un_troupeau()
	var par_seconde: float = _etat.gains_par_seconde()
	var nuit: Dictionary = _regles["nuit_complete"]
	var duree: float = (nuit["min_h"] + 0.5) * HEURE

	var resume: Dictionary = _etat.appliquer_absence(duree)

	var comptee: float = minf(duree, _etat.plafond_hors_ligne_s())
	assert_true(resume["nuit_complete"])
	assert_almost_eq(
		resume["gain"], par_seconde * comptee * (1.0 + nuit["bonus_pourcent"] / 100.0), 1e-6
	)


func test_une_absence_plus_courte_qu_une_nuit_n_a_pas_le_bonus() -> void:
	_donner_un_troupeau()
	var duree: float = (_regles["nuit_complete"]["min_h"] - 1.0) * HEURE
	assert_false(_etat.appliquer_absence(duree)["nuit_complete"])


func test_une_absence_trop_longue_n_a_pas_le_bonus() -> void:
	_donner_un_troupeau()
	var duree: float = (_regles["nuit_complete"]["max_h"] + 1.0) * HEURE
	assert_false(_etat.appliquer_absence(duree)["nuit_complete"])


# --- Avec la sauvegarde et l'horloge ---


func test_au_lancement_le_temps_ecoule_depuis_la_sauvegarde_rapporte() -> void:
	_donner_un_troupeau()
	_etat.profondeur = 50.0
	var par_seconde: float = _etat.gains_par_seconde()
	_nouvelle_sauvegarde(_etat).sauvegarder()

	_heure_simulee += 2.0 * HEURE
	var partie_relancee := _nouvel_etat()
	_nouvelle_sauvegarde(partie_relancee)

	assert_almost_eq(partie_relancee.fragments, par_seconde * 2.0 * HEURE, 1e-3)
	assert_false(partie_relancee.absence_a_montrer.is_empty())


func test_relancer_tout_de_suite_ne_rapporte_rien() -> void:
	_donner_un_troupeau()
	_nouvelle_sauvegarde(_etat).sauvegarder()

	_heure_simulee += 5.0
	var partie_relancee := _nouvel_etat()
	_nouvelle_sauvegarde(partie_relancee)

	assert_eq(partie_relancee.fragments, 0.0)
	assert_true(partie_relancee.absence_a_montrer.is_empty())


## Anti-triche : reculer l'horloge du téléphone ne rapporte rien.
func test_une_horloge_qui_recule_ne_rapporte_rien() -> void:
	_donner_un_troupeau()
	_nouvelle_sauvegarde(_etat).sauvegarder()

	_heure_simulee -= 5.0 * HEURE
	var partie_relancee := _nouvel_etat()
	_nouvelle_sauvegarde(partie_relancee)

	assert_eq(partie_relancee.fragments, 0.0)
	assert_true(partie_relancee.absence_a_montrer.is_empty())


func test_revenir_de_l_arriere_plan_rapporte_aussi() -> void:
	_donner_un_troupeau()
	var par_seconde: float = _etat.gains_par_seconde()
	var sauvegarde := _nouvelle_sauvegarde(_etat)

	sauvegarde.notification(NOTIFICATION_APPLICATION_PAUSED)
	_heure_simulee += HEURE
	sauvegarde.notification(NOTIFICATION_APPLICATION_RESUMED)

	assert_almost_eq(_etat.fragments, par_seconde * HEURE, 1e-3)


func test_une_absence_n_est_comptee_qu_une_fois() -> void:
	_donner_un_troupeau()
	var sauvegarde := _nouvelle_sauvegarde(_etat)
	sauvegarde.notification(NOTIFICATION_APPLICATION_PAUSED)
	_heure_simulee += HEURE
	sauvegarde.notification(NOTIFICATION_APPLICATION_RESUMED)
	var apres_le_retour: float = _etat.fragments

	sauvegarde.notification(NOTIFICATION_APPLICATION_RESUMED)

	assert_eq(_etat.fragments, apres_le_retour)


func test_une_premiere_partie_sans_sauvegarde_ne_compte_aucune_absence() -> void:
	_donner_un_troupeau()
	_nouvelle_sauvegarde(_etat)
	assert_eq(_etat.fragments, 0.0)


# --- Le texte de l'écran ---


func test_l_ecran_dit_la_duree_le_palier_et_le_gain() -> void:
	_donner_un_troupeau()
	_etat.profondeur = 90.0
	var texte: String = SCRIPT_ECRAN.texte_du_resume(_etat.appliquer_absence(2.0 * HEURE))
	assert_string_contains(texte, "Tu es parti 2 h 00 min.")
	assert_string_contains(texte, _etat.palier["nom"])
	assert_string_contains(texte, "Fragments gagnés")
	assert_false(texte.contains("Nuit complète"))
	assert_false(texte.contains("Plafond"))


func test_l_ecran_signale_la_nuit_complete_et_le_plafond() -> void:
	_donner_un_troupeau()
	var nuit: Dictionary = _regles["nuit_complete"]
	# Une nuit complète qui dépasse le plafond de base.
	var duree: float = maxf(nuit["min_h"], _regles["plafond_h"] + 1.0) * HEURE
	if duree > nuit["max_h"] * HEURE:
		pass_test("Avec ces réglages, une nuit complète ne dépasse jamais le plafond")
		return
	var texte: String = SCRIPT_ECRAN.texte_du_resume(_etat.appliquer_absence(duree))
	assert_string_contains(texte, "Nuit complète")
	assert_string_contains(texte, "ont compté")

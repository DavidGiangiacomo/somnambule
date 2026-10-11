extends GutTest
## Tests de Generateur : la réserve d'objets partagée par les obstacles et les
## fragments. Rien ne doit être créé ni détruit en cours de jeu.

const SCENE_OBSTACLE := preload("res://scenes/obstacle.tscn")
const TAILLE_RESERVE := 3

var _generateur: Generateur


func before_each() -> void:
	_generateur = Generateur.new()
	_generateur.scene = SCENE_OBSTACLE
	_generateur.taille_reserve = TAILLE_RESERVE
	add_child_autofree(_generateur)


func test_la_reserve_est_creee_au_demarrage() -> void:
	assert_eq(_generateur.get_child_count(), TAILLE_RESERVE)


func test_les_objets_en_reserve_sont_caches() -> void:
	for objet in _generateur.get_children():
		assert_false(objet.visible)


func test_un_objet_apparait_au_bord_droit_a_la_hauteur_demandee() -> void:
	var objet := _generateur.apparaitre(-120.0)
	assert_true(objet.visible)
	assert_eq(objet.position, Vector2(Generateur.X_APPARITION, -120.0))


func test_faire_apparaitre_ne_cree_rien_tant_que_la_reserve_suffit() -> void:
	for i in TAILLE_RESERVE:
		_generateur.apparaitre()
	assert_eq(_generateur.get_child_count(), TAILLE_RESERVE)


func test_la_reserve_s_agrandit_si_elle_est_vide() -> void:
	for i in TAILLE_RESERVE + 1:
		_generateur.apparaitre()
	assert_eq(_generateur.get_child_count(), TAILLE_RESERVE + 1)


func test_les_objets_avancent_vers_la_gauche_a_la_vitesse_du_sol() -> void:
	var objet := _generateur.apparaitre()
	_generateur._process(0.5)
	assert_almost_eq(objet.position.x, Generateur.X_APPARITION - 0.5 * _generateur.vitesse, 0.001)


func test_un_objet_sorti_a_gauche_est_range() -> void:
	var objet := _generateur.apparaitre()
	objet.position.x = Generateur.X_SORTIE + 1.0
	_generateur._process(1.0)
	assert_false(objet.visible)


func test_un_objet_range_est_reutilise() -> void:
	var premier := _generateur.apparaitre()
	_generateur.retirer(premier)
	var suivant := _generateur.apparaitre()
	assert_same(suivant, premier)
	assert_eq(_generateur.get_child_count(), TAILLE_RESERVE)


func test_des_centaines_d_apparitions_ne_creent_aucun_objet() -> void:
	for i in 500:
		var objet := _generateur.apparaitre()
		_generateur.retirer(objet)
	assert_eq(_generateur.get_child_count(), TAILLE_RESERVE)


func test_prochain_renvoie_null_sans_objet_a_l_ecran() -> void:
	assert_null(_generateur.prochain(0.0))


func test_prochain_renvoie_l_objet_le_plus_proche_devant() -> void:
	var loin := _generateur.apparaitre()
	loin.position.x = 800.0
	var proche := _generateur.apparaitre()
	proche.position.x = 400.0
	assert_same(_generateur.prochain(200.0), proche)


func test_prochain_ignore_les_objets_deja_passes() -> void:
	var passe := _generateur.apparaitre()
	passe.position.x = 100.0
	var devant := _generateur.apparaitre()
	devant.position.x = 600.0
	assert_same(_generateur.prochain(200.0), devant)


func test_prochain_ignore_les_objets_ranges() -> void:
	var objet := _generateur.apparaitre()
	_generateur.retirer(objet)
	assert_null(_generateur.prochain(0.0))

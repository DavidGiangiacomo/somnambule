extends GutTest
## Tests des formules du GDD. Les valeurs attendues sont recalculées à partir
## de balance.json : régler l'équilibrage ne casse pas ces tests.

var _profondeur: Dictionary
var _multiplicateur: Dictionary


func before_all() -> void:
	_profondeur = Balance.donnees()["profondeur"]
	_multiplicateur = Balance.donnees()["multiplicateur"]


func test_a_profondeur_nulle_on_descend_a_pleine_vitesse() -> void:
	var v: float = _profondeur["vitesse_descente"]
	assert_almost_eq(Formules.variation_profondeur(0.0, 1.0), v, 1e-9)
	assert_almost_eq(Formules.variation_profondeur(0.0, 0.5), v * 0.5, 1e-9)


func test_a_mi_profondeur_on_descend_deux_fois_moins_vite() -> void:
	var v: float = _profondeur["vitesse_descente"]
	var mi_profondeur: float = _profondeur["max"] / 2.0
	assert_almost_eq(Formules.variation_profondeur(mi_profondeur, 1.0), v / 2.0, 1e-9)


func test_a_profondeur_maximale_on_ne_descend_plus() -> void:
	assert_almost_eq(Formules.variation_profondeur(_profondeur["max"], 1.0), 0.0, 1e-9)


## Critère de l'issue #10 : même courbe que le simulateur, qui avance par pas
## d'une seconde. La courbe exacte est Pmax · (1 − e^(−v·t / Pmax)).
func test_la_descente_suit_la_courbe_du_gdd() -> void:
	var v: float = _profondeur["vitesse_descente"]
	var p_max: float = _profondeur["max"]
	var p := 0.0
	for image in 60 * 120:  # deux minutes à 60 images par seconde
		p += Formules.variation_profondeur(p, 1.0 / 60.0)
	var attendu := p_max * (1.0 - exp(-v * 120.0 / p_max))
	assert_almost_eq(p, attendu, attendu * 0.01)


func test_multiplicateur_vaut_un_a_profondeur_nulle() -> void:
	assert_almost_eq(Formules.multiplicateur(0.0), 1.0, 1e-9)


func test_multiplicateur_suit_la_formule_du_gdd() -> void:
	var m := _multiplicateur
	var attendu: float = 1.0 + m["coefficient"] * pow(40.0 / m["echelle"], m["exposant"])
	assert_almost_eq(Formules.multiplicateur(40.0), attendu, 1e-9)


func test_multiplicateur_grandit_avec_la_profondeur() -> void:
	var precedent := Formules.multiplicateur(0.0)
	for p in [20.0, 40.0, 60.0, 80.0, 100.0]:
		var actuel := Formules.multiplicateur(p)
		assert_gt(actuel, precedent, "M(%d) doit dépasser le palier précédent" % p)
		precedent = actuel

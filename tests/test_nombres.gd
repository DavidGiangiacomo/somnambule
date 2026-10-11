extends GutTest
## Tests de Nombres.court() : l'écriture courte des grands nombres.

const E := Nombres.ESPACE


func test_sous_mille_on_garde_l_entier() -> void:
	assert_eq(Nombres.court(0.0), "0")
	assert_eq(Nombres.court(42.0), "42")
	assert_eq(Nombres.court(999.0), "999")


func test_on_arrondit_toujours_vers_le_bas() -> void:
	assert_eq(Nombres.court(7.9), "7")
	assert_eq(Nombres.court(999.99), "999")
	assert_eq(Nombres.court(1299.0), "1,2" + E + "k")
	assert_eq(Nombres.court(999999.0), "999" + E + "k")


func test_milliers() -> void:
	assert_eq(Nombres.court(1000.0), "1,0" + E + "k")
	assert_eq(Nombres.court(1234.0), "1,2" + E + "k")
	assert_eq(Nombres.court(12345.0), "12,3" + E + "k")
	assert_eq(Nombres.court(123456.0), "123" + E + "k")


func test_millions() -> void:
	assert_eq(Nombres.court(1e6), "1,0" + E + "M")
	assert_eq(Nombres.court(3.4e6), "3,4" + E + "M")
	assert_eq(Nombres.court(999.9e6), "999" + E + "M")


func test_milliards() -> void:
	assert_eq(Nombres.court(1e9), "1,0" + E + "Md")
	assert_eq(Nombres.court(5.6e9), "5,6" + E + "Md")
	assert_eq(Nombres.court(5.7e9), "5,7" + E + "Md")
	assert_eq(Nombres.court(999.9e9), "999" + E + "Md")


func test_la_decimale_disparait_quand_elle_ne_tient_plus() -> void:
	assert_eq(Nombres.court(12.3e9), "12" + E + "Md")
	assert_eq(Nombres.court(1e100), "1e100")
	assert_eq(Nombres.court(4.6e200), "4e200")


func test_notation_scientifique_au_dela_des_milliards() -> void:
	assert_eq(Nombres.court(1e12), "1,0e12")
	assert_eq(Nombres.court(1.26e15), "1,2e15")
	assert_eq(Nombres.court(9.99e99), "9,9e99")
	assert_eq(Nombres.court(1.7e308), "1e308")


func test_nombres_negatifs_et_infini() -> void:
	assert_eq(Nombres.court(-1234.0), "-1,2" + E + "k")
	assert_eq(Nombres.court(INF), "∞")


## Critère de l'issue #15 : jamais plus de 6 caractères, de 1 à 1e308.
func test_jamais_plus_de_six_caracteres() -> void:
	var trop_longs: Array[String] = []
	for exposant in range(0, 309):
		for mantisse: float in [1.0, 1.05, 2.5, 9.99, 9.999999]:
			var valeur: float = mantisse * pow(10.0, exposant)
			if is_inf(valeur):
				continue
			var texte := Nombres.court(valeur)
			if texte.length() > Nombres.LONGUEUR_MAX:
				trop_longs.append("%s → « %s »" % [valeur, texte])
	assert_eq(trop_longs, [] as Array[String])


func test_un_petit_debit_garde_une_decimale() -> void:
	assert_eq(Nombres.debit(0.0), "0,0")
	assert_eq(Nombres.debit(0.1), "0,1")
	assert_eq(Nombres.debit(0.3), "0,3")
	assert_eq(Nombres.debit(12.34), "12,3")
	assert_eq(Nombres.debit(99.99), "99,9")


func test_un_grand_debit_passe_au_format_court() -> void:
	assert_eq(Nombres.debit(100.0), "100")
	assert_eq(Nombres.debit(1234.0), "1,2" + E + "k")

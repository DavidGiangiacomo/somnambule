class_name Nombres
## Écrit les grands nombres en peu de caractères, pour l'affichage.
##
## Usage : Nombres.court(1234.0) renvoie « 1,2 k ».

const LONGUEUR_MAX := 6
# Espace insécable : le nombre et son suffixe ne sont jamais coupés en fin de ligne.
const ESPACE := " "
# Du plus grand au plus petit. Au-delà du dernier, on passe en notation scientifique.
const SUFFIXES := [[1e9, "Md"], [1e6, "M"], [1e3, "k"]]
const SEUIL_SCIENTIFIQUE := 1e12


## Renvoie `valeur` en 6 caractères au plus : « 999 », « 1,2 k », « 3,4 M »,
## « 5,6 Md », puis « 1,2e15 ». On arrondit toujours vers le bas, pour ne
## jamais afficher plus que ce que le joueur possède.
static func court(valeur: float) -> String:
	if valeur < 0.0:
		return "-" + court(-valeur)
	if is_inf(valeur):
		return "∞"
	if valeur < 1e3:
		return str(floori(valeur))

	if valeur < SEUIL_SCIENTIFIQUE:
		for suffixe in SUFFIXES:
			if valeur >= suffixe[0]:
				return _avec_suite(valeur / suffixe[0], ESPACE + suffixe[1])

	# Notation scientifique : 1 250 000 000 000 000 s'écrit 1,2e15.
	var exposant := floori(log(valeur) / log(10.0))
	var mantisse := valeur / pow(10.0, exposant)
	# Les calculs à virgule peuvent tomber juste à côté : on ramène la
	# mantisse entre 1 et 10.
	if mantisse < 1.0:
		mantisse *= 10.0
		exposant -= 1
	if mantisse * 10.0 + 1e-9 >= 100.0:
		mantisse /= 10.0
		exposant += 1
	return _avec_suite(mantisse, "e%d" % exposant)


## Écrit `mantisse` avec une décimale suivie de `suite`, ou sans décimale si
## le tout dépasse LONGUEUR_MAX : « 12,3 k » mais « 123 k ».
static func _avec_suite(mantisse: float, suite: String) -> String:
	# Le petit ajout compense les erreurs d'arrondi (5,7 calculé comme 5,6999…).
	var dixiemes := floori(mantisse * 10.0 + 1e-9)
	@warning_ignore("integer_division")
	var entier := dixiemes / 10
	var texte := "%d,%d%s" % [entier, dixiemes % 10, suite]
	if texte.length() > LONGUEUR_MAX:
		texte = "%d%s" % [entier, suite]
	return texte

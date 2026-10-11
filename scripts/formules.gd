class_name Formules
## Formules du GDD, traduites de simulateur/formules.py. Le jeu et le
## simulateur doivent donner les mêmes résultats.


## De combien la profondeur P augmente pendant `duree_s` secondes.
## Formule du GDD : dP/dt = v · (1 − P / Pmax)
static func variation_profondeur(p: float, duree_s: float) -> float:
	var profondeur: Dictionary = Balance.donnees()["profondeur"]
	return profondeur["vitesse_descente"] * (1.0 - p / profondeur["max"]) * duree_s


## Palier de sommeil (Assoupi, Paradoxal…) correspondant à la profondeur P,
## tel que décrit dans balance.json : { "id": …, "nom": …, "seuil": … }.
## C'est le dernier palier dont le seuil est atteint.
static func palier(p: float) -> Dictionary:
	var paliers: Array = Balance.donnees()["profondeur"]["paliers"]
	var trouve: Dictionary = paliers[0]
	for candidat in paliers:
		if p >= candidat["seuil"]:
			trouve = candidat
	return trouve


## Multiplicateur de gains M(P) pour une profondeur P.
## Formule du GDD : M(P) = 1 + 0,32 · (P / 10)^1,5
static func multiplicateur(p: float) -> float:
	var m: Dictionary = Balance.donnees()["multiplicateur"]
	return 1.0 + m["coefficient"] * pow(p / m["echelle"], m["exposant"])


## Prix du prochain exemplaire d'un mouton, ou du prochain niveau d'une
## amélioration, quand on en possède déjà `deja_possedes`. `fiche` est sa
## description dans balance.json.
## Formule du GDD : C_n = C0 · r^n
static func cout_achat(fiche: Dictionary, deja_possedes: int) -> float:
	return fiche["cout_initial"] * pow(fiche["raison_cout"], deja_possedes)


## Fragments produits par seconde par `nombre` moutons d'un même type, avant
## M(P). La production du type double tous les `doublement_tous_les` exemplaires.
static func production_moutons(mouton: Dictionary, nombre: int, doublement_tous_les: int) -> float:
	@warning_ignore("integer_division")
	var bonus := pow(2.0, nombre / doublement_tous_les)
	return mouton["production_par_seconde"] * nombre * bonus

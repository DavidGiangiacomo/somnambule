class_name Formules
## Formules du GDD, traduites de simulateur/formules.py. Le jeu et le
## simulateur doivent donner les mêmes résultats.


## De combien la profondeur P augmente pendant `duree_s` secondes.
## Formule du GDD : dP/dt = v · (1 − P / Pmax)
static func variation_profondeur(p: float, duree_s: float) -> float:
	var profondeur: Dictionary = Balance.donnees()["profondeur"]
	return profondeur["vitesse_descente"] * (1.0 - p / profondeur["max"]) * duree_s

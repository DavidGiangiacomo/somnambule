class_name Balance
## Lit data/balance.json, la source unique des valeurs d'équilibrage.
##
## Usage : Balance.donnees()["defilement"]["vitesse_px_s"]

const CHEMIN := "res://data/balance.json"

static var _donnees: Dictionary = {}


## Renvoie le contenu de balance.json. Le fichier n'est lu qu'une fois.
static func donnees() -> Dictionary:
	if _donnees.is_empty():
		var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHEMIN))
		assert(json is Dictionary, "%s est illisible ou mal formé" % CHEMIN)
		_donnees = json
	return _donnees

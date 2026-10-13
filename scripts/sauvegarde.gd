extends Node
## Sauvegarde automatique de la partie, chargée au démarrage sous le nom
## Sauvegarde (autoload, après GameState).
##
## La partie est écrite en JSON dans user://, le dossier que le système
## réserve au jeu : toutes les 30 secondes, quand l'application passe en
## arrière-plan, et quand on ferme la fenêtre sur ordinateur.
##
## Chaque sauvegarde porte son heure. Au lancement, ou au retour de
## l'arrière-plan, le temps écoulé depuis est donné à GameState, qui en tire
## les gains hors-ligne.
##
## Le fichier porte un numéro de version, `save_version`. Quand son format
## changera, _migrer() mettra les anciennes sauvegardes au format du jour.

const VERSION := 2
const INTERVALLE_S := 30.0

## Le fichier de sauvegarde. Les tests en choisissent un autre.
var chemin := "user://sauvegarde.json"
## L'état à sauvegarder. Les tests en fournissent un autre que la vraie partie.
var etat: Node = GameState
## Donne l'heure, en secondes depuis 1970. Les tests la remplacent pour
## simuler une absence sans attendre.
var horloge: Callable = Time.get_unix_time_from_system

var _horodatage := 0.0  # heure de la dernière sauvegarde écrite ou lue (0 : aucune)


func _ready() -> void:
	charger()

	var minuteur := Timer.new()
	minuteur.wait_time = INTERVALLE_S
	minuteur.timeout.connect(sauvegarder)
	add_child(minuteur)
	minuteur.start()


func _notification(what: int) -> void:
	# PAUSED : le joueur quitte l'application sur téléphone.
	# CLOSE_REQUEST : il ferme la fenêtre sur ordinateur.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		sauvegarder()
	# RESUMED : il revient dans l'application restée en arrière-plan.
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_compter_absence()


func sauvegarder() -> void:
	var donnees: Dictionary = etat.vers_sauvegarde()
	donnees["save_version"] = VERSION
	# Heure de la sauvegarde, pour calculer les gains hors-ligne au retour.
	_horodatage = horloge.call()
	donnees["horodatage"] = _horodatage

	# On écrit d'abord à côté, puis on remplace : si l'application est tuée
	# pendant l'écriture, l'ancienne sauvegarde reste intacte.
	var chemin_temporaire := chemin + ".tmp"
	var fichier := FileAccess.open(chemin_temporaire, FileAccess.WRITE)
	if fichier == null:
		push_warning("Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return
	fichier.store_string(JSON.stringify(donnees, "\t"))
	fichier.close()
	DirAccess.rename_absolute(chemin_temporaire, chemin)


func charger() -> void:
	if not FileAccess.file_exists(chemin):
		return  # première partie

	var json := JSON.new()
	var erreur := json.parse(FileAccess.get_file_as_string(chemin))
	if erreur != OK or not json.data is Dictionary:
		push_warning("Sauvegarde illisible : la partie repart de zéro.")
		return
	etat.depuis_sauvegarde(_migrer(json.data))
	_horodatage = json.data.get("horodatage", 0.0)
	_compter_absence()


## Donne à l'état le temps écoulé depuis la dernière sauvegarde. Si l'horloge
## du téléphone a reculé, la durée est négative et ne rapporte rien.
func _compter_absence() -> void:
	if _horodatage <= 0.0:
		return
	var maintenant: float = horloge.call()
	etat.appliquer_absence(maintenant - _horodatage)
	# Cette absence est comptée : la suivante partira de maintenant.
	_horodatage = maintenant


## Met une sauvegarde ancienne au format actuel, une version après l'autre.
func _migrer(donnees: Dictionary) -> Dictionary:
	# Version 2 (le Réveil) : on compte désormais les fragments gagnés pendant
	# la nuit. Une ancienne sauvegarde ne les connaît pas ; on repart de ce
	# que le joueur a en poche, faute de mieux.
	if donnees.get("save_version", 1) < 2:
		donnees["fragments_de_la_nuit"] = donnees.get("fragments", 0.0)
		donnees["save_version"] = 2
	return donnees

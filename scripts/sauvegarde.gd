extends Node
## Sauvegarde automatique de la partie, chargée au démarrage sous le nom
## Sauvegarde (autoload, après GameState).
##
## La partie est écrite en JSON dans user://, le dossier que le système
## réserve au jeu : toutes les 30 secondes, quand l'application passe en
## arrière-plan, et quand on ferme la fenêtre sur ordinateur.
##
## Le fichier porte un numéro de version, `save_version`. Quand son format
## changera, _migrer() mettra les anciennes sauvegardes au format du jour.

const VERSION := 1
const INTERVALLE_S := 30.0

## Le fichier de sauvegarde. Les tests en choisissent un autre.
var chemin := "user://sauvegarde.json"
## L'état à sauvegarder. Les tests en fournissent un autre que la vraie partie.
var etat: Node = GameState


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


func sauvegarder() -> void:
	var donnees: Dictionary = etat.vers_sauvegarde()
	donnees["save_version"] = VERSION
	# Heure de la sauvegarde, pour calculer plus tard les gains hors-ligne.
	donnees["horodatage"] = Time.get_unix_time_from_system()

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


## Met une sauvegarde ancienne au format actuel. Rien à faire tant qu'il
## n'existe qu'une version. Le jour où le format change, on ajoutera ici :
##
##     if donnees["save_version"] < 2:
##         donnees["nouveau_champ"] = valeur_par_defaut
##         donnees["save_version"] = 2
func _migrer(donnees: Dictionary) -> Dictionary:
	return donnees

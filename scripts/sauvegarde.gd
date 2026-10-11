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

const CHEMIN := "user://sauvegarde.json"
const CHEMIN_TEMPORAIRE := "user://sauvegarde.json.tmp"
const VERSION := 1
const INTERVALLE_S := 30.0


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
	var donnees := GameState.vers_sauvegarde()
	donnees["save_version"] = VERSION
	# Heure de la sauvegarde, pour calculer plus tard les gains hors-ligne.
	donnees["horodatage"] = Time.get_unix_time_from_system()

	# On écrit d'abord à côté, puis on remplace : si l'application est tuée
	# pendant l'écriture, l'ancienne sauvegarde reste intacte.
	var fichier := FileAccess.open(CHEMIN_TEMPORAIRE, FileAccess.WRITE)
	if fichier == null:
		push_warning("Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return
	fichier.store_string(JSON.stringify(donnees, "\t"))
	fichier.close()
	DirAccess.rename_absolute(CHEMIN_TEMPORAIRE, CHEMIN)


func charger() -> void:
	if not FileAccess.file_exists(CHEMIN):
		return  # première partie

	var donnees: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHEMIN))
	if not donnees is Dictionary:
		push_warning("Sauvegarde illisible : la partie repart de zéro.")
		return
	GameState.depuis_sauvegarde(_migrer(donnees))


## Met une sauvegarde ancienne au format actuel. Rien à faire tant qu'il
## n'existe qu'une version. Le jour où le format change, on ajoutera ici :
##
##     if donnees["save_version"] < 2:
##         donnees["nouveau_champ"] = valeur_par_defaut
##         donnees["save_version"] = 2
func _migrer(donnees: Dictionary) -> Dictionary:
	return donnees

extends Control
## L'écran « Pendant que tu dormais » : au retour du joueur, il dit combien de
## temps il est parti et ce que le troupeau a produit. Le jeu est en pause
## tant qu'il est ouvert.
##
## Il ne calcule rien : GameState fournit le résumé de l'absence.

@onready var resume: Label = %Resume
@onready var bouton_continuer: Button = %Continuer


func _ready() -> void:
	# Cet écran doit continuer de répondre pendant la pause qu'il déclenche.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	bouton_continuer.pressed.connect(fermer)
	GameState.retour_d_absence.connect(_sur_retour_d_absence)
	# Au lancement, l'absence est comptée avant que cet écran n'existe.
	if not GameState.absence_a_montrer.is_empty():
		ouvrir.call_deferred(GameState.absence_a_montrer)


func _sur_retour_d_absence(resume_absence: Dictionary) -> void:
	ouvrir(resume_absence)


func ouvrir(resume_absence: Dictionary) -> void:
	resume.text = texte_du_resume(resume_absence)
	visible = true
	get_tree().paused = true


func fermer() -> void:
	GameState.absence_a_montrer = {}
	visible = false
	get_tree().paused = false


## Le texte affiché, à partir du résumé fourni par GameState.appliquer_absence().
static func texte_du_resume(resume_absence: Dictionary) -> String:
	var lignes: Array[String] = [
		"Tu es parti %s." % Nombres.duree(resume_absence["duree_s"]),
		"",
		"Le dormeur est resté en %s : le troupeau a produit à ×%s."
		% [resume_absence["palier"]["nom"], Nombres.debit(resume_absence["multiplicateur"])],
		"",
		"Fragments gagnés : %s" % Nombres.court(resume_absence["gain"]),
	]
	if resume_absence["nuit_complete"]:
		lignes.append("Nuit complète : bonus compris.")
	if resume_absence["plafond_atteint"]:
		lignes.append(
			"Plafond atteint : seules %s ont compté." % Nombres.duree(resume_absence["duree_comptee_s"])
		)
	return "\n".join(lignes)

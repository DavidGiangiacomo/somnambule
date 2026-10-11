extends Control
## L'écran de Réveil : il résume la nuit, annonce les réminiscences gagnées et
## laisse le joueur choisir entre se réveiller et dormir encore. Le jeu est
## en pause tant qu'il est ouvert.
##
## Il ne décide de rien : GameState fournit le résumé et fait le Réveil.

@onready var resume: Label = %Resume
@onready var bouton_reveil: Button = %SeReveiller
@onready var bouton_dormir: Button = %DormirEncore


func _ready() -> void:
	# Cet écran doit continuer de répondre pendant la pause qu'il déclenche.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("ecran_reveil")
	visible = false
	bouton_reveil.pressed.connect(_sur_se_reveiller)
	bouton_dormir.pressed.connect(fermer)


## Ouvre l'écran, si la nuit rapporte au moins une réminiscence.
func ouvrir() -> void:
	if not GameState.peut_se_reveiller():
		return
	resume.text = texte_du_resume(GameState.resume_de_la_nuit(), GameState.reminiscences)
	visible = true
	get_tree().paused = true


func fermer() -> void:
	visible = false
	get_tree().paused = false


func _sur_se_reveiller() -> void:
	GameState.se_reveiller()
	fermer()


## Le texte affiché, à partir du résumé de la nuit et des réminiscences déjà
## gardées avant ce Réveil.
static func texte_du_resume(resume_nuit: Dictionary, reminiscences_gardees: int) -> String:
	var gagnees: int = resume_nuit["reminiscences"]
	var bonus := Formules.bonus_reminiscences(reminiscences_gardees + gagnees)
	return "\n".join([
		"Nuit %d" % resume_nuit["nuit"],
		"Durée : %s" % Nombres.duree(resume_nuit["duree_s"]),
		"Fragments gagnés : %s" % Nombres.court(resume_nuit["fragments"]),
		"Sommeil le plus profond : %s" % resume_nuit["palier"]["nom"],
		"",
		"Réminiscences gagnées : +%d" % gagnees,
		"Production des prochaines nuits : +%d %%" % roundi((bonus - 1.0) * 100.0),
		"",
		"Fragments, moutons et améliorations repartent de zéro.",
	])

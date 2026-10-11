extends Control
## Les moutons du troupeau défilent en petit et sautent une barrière, en
## boucle. Plus le troupeau grandit, plus la file s'allonge. Purement
## décoratif : rien ici ne change le jeu.

const MAX_PAR_TYPE := 3  # au-delà, la file ne s'allonge plus
const ECART := 90.0  # distance entre deux moutons
const VITESSE := 120.0  # pixels par seconde
const CORPS := Vector2(44, 28)
const TETE := Vector2(16, 16)
const HAUTEUR_SOL := 20.0  # au-dessus du bas de la zone
const HAUTEUR_BARRIERE := 36.0
const HAUTEUR_SAUT := 56.0
const ELAN := 60.0  # le mouton décolle à cette distance de la barrière

const COULEUR_SOL := Color(1, 1, 1, 0.15)
const COULEUR_BARRIERE := Color(0.6, 0.5, 0.4)
const COULEURS := {
	"mouton": Color(0.95, 0.95, 0.95),
	"belier": Color(0.78, 0.68, 0.58),
	"mouton_a_plumes": Color(0.7, 0.9, 1.0),
	"nuage_mouton": Color(0.85, 0.8, 1.0),
}

var _file: Array[Color] = []  # un mouton par couleur, dans l'ordre de la file
var _avance := 0.0


func _ready() -> void:
	GameState.troupeau_change.connect(_sur_troupeau_change)
	_composer_la_file()


func _process(delta: float) -> void:
	_avance += VITESSE * delta
	queue_redraw()


func _sur_troupeau_change(_id: String, _nombre: int) -> void:
	_composer_la_file()


func _composer_la_file() -> void:
	_file.clear()
	for id: String in GameState.moutons:
		for i in mini(GameState.moutons[id], MAX_PAR_TYPE):
			_file.append(COULEURS.get(id, Color.WHITE))


func _draw() -> void:
	var sol := size.y - HAUTEUR_SOL
	var x_barriere := size.x / 2.0
	draw_rect(Rect2(0, sol, size.x, 3), COULEUR_SOL)
	draw_rect(Rect2(x_barriere - 4, sol - HAUTEUR_BARRIERE, 8, HAUTEUR_BARRIERE), COULEUR_BARRIERE)

	# Les moutons traversent de gauche à droite puis reviennent par la gauche.
	var boucle := maxf(size.x + 2.0 * CORPS.x, _file.size() * ECART)
	for i in _file.size():
		var x := fposmod(_avance - i * ECART, boucle) - CORPS.x
		var centre := x + CORPS.x / 2.0
		# Saut en cloche au-dessus de la barrière.
		var distance := absf(centre - x_barriere)
		var hauteur := 0.0
		if distance < ELAN:
			hauteur = HAUTEUR_SAUT * (1.0 - pow(distance / ELAN, 2.0))
		var bas := sol - hauteur
		draw_rect(Rect2(x, bas - CORPS.y, CORPS.x, CORPS.y), _file[i])
		draw_rect(Rect2(x + CORPS.x - 6, bas - CORPS.y - 8, TETE.x, TETE.y), _file[i].darkened(0.25))

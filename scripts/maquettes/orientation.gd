extends Node2D
## Maquette jetable pour l'issue #6 : portrait ou paysage ?
##
## Tout est dessiné avec des rectangles dans _draw(). Le bouton du panneau
## bascule entre les deux dispositions. Toucher la bande de rêve fait enjamber
## le dormeur ; les faux boutons d'achat servent à tester la portée du pouce.

const TAILLE_PORTRAIT := Vector2i(1080, 1920)
const TAILLE_PAYSAGE := Vector2i(1920, 1080)

# Portrait : bande de rêve sur les 60 % du haut (GDD), panneau en bas.
# Paysage : bande de rêve sur les 70 % de gauche, panneau à droite.
const PART_BANDE_PORTRAIT := 0.6
const PART_BANDE_PAYSAGE := 0.7

const VITESSE := 400.0  # défilement, en pixels par seconde
const INTERVALLE_MIN_S := 5.0  # comme data/balance.json
const INTERVALLE_MAX_S := 10.0
const DUREE_SAUT_S := 0.45
const HAUTEUR_SAUT := 220.0
const TAILLE_DORMEUR := Vector2(80, 160)
const TAILLE_OBSTACLE := Vector2(80, 80)
const NB_ACHATS := 4

var paysage := false
var defilement := 0.0
var obstacles: Array[float] = []  # distance de chaque obstacle devant le dormeur
var prochain_obstacle_s := 2.0
var temps_saut := -1.0  # négatif : le dormeur est au sol
var enjambees := 0
var trebuchements := 0
var flash_trebuchement := 0.0
var flash_achats: Array[float] = []


func _ready() -> void:
	flash_achats.resize(NB_ACHATS)
	flash_achats.fill(0.0)
	_appliquer_orientation()


func _process(delta: float) -> void:
	defilement += VITESSE * delta
	flash_trebuchement = maxf(0.0, flash_trebuchement - delta)
	for i in NB_ACHATS:
		flash_achats[i] = maxf(0.0, flash_achats[i] - delta)

	if temps_saut >= 0.0:
		temps_saut += delta
		if temps_saut >= DUREE_SAUT_S:
			temps_saut = -1.0

	prochain_obstacle_s -= delta
	if prochain_obstacle_s <= 0.0:
		prochain_obstacle_s = randf_range(INTERVALLE_MIN_S, INTERVALLE_MAX_S)
		var bande := _rect_bande()
		obstacles.append(bande.end.x - _x_dormeur())

	for i in range(obstacles.size() - 1, -1, -1):
		var avant := obstacles[i]
		obstacles[i] -= VITESSE * delta
		# L'obstacle passe sous le dormeur : enjambé s'il est en l'air.
		if avant > 0.0 and obstacles[i] <= 0.0:
			if temps_saut >= 0.0:
				enjambees += 1
			else:
				trebuchements += 1
				flash_trebuchement = 0.3
		if obstacles[i] < -_x_dormeur() - TAILLE_OBSTACLE.x:
			obstacles.remove_at(i)

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Sur téléphone, Godot transforme le toucher en clic de souris.
	if not (event is InputEventMouseButton and event.pressed):
		return
	var pos: Vector2 = event.position
	if _rect_bascule().has_point(pos):
		paysage = not paysage
		_appliquer_orientation()
	elif _rect_bande().has_point(pos):
		if temps_saut < 0.0:
			temps_saut = 0.0
	else:
		for i in NB_ACHATS:
			if _rect_achat(i).has_point(pos):
				flash_achats[i] = 0.2


func _appliquer_orientation() -> void:
	var fenetre := get_window()
	if paysage:
		fenetre.content_scale_size = TAILLE_PAYSAGE
		fenetre.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
	else:
		fenetre.content_scale_size = TAILLE_PORTRAIT
		fenetre.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH

	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(
			DisplayServer.SCREEN_LANDSCAPE if paysage else DisplayServer.SCREEN_PORTRAIT
		)
	else:
		# Sur ordinateur, on retourne la fenêtre pour imiter le téléphone.
		var grand := maxi(fenetre.size.x, fenetre.size.y)
		var petit := mini(fenetre.size.x, fenetre.size.y)
		fenetre.size = Vector2i(grand, petit) if paysage else Vector2i(petit, grand)


func _rect_bande() -> Rect2:
	var ecran := get_viewport_rect().size
	if paysage:
		return Rect2(0, 0, ecran.x * PART_BANDE_PAYSAGE, ecran.y)
	return Rect2(0, 0, ecran.x, ecran.y * PART_BANDE_PORTRAIT)


func _rect_panneau() -> Rect2:
	var ecran := get_viewport_rect().size
	var bande := _rect_bande()
	if paysage:
		return Rect2(bande.end.x, 0, ecran.x - bande.end.x, ecran.y)
	return Rect2(0, bande.end.y, ecran.x, ecran.y - bande.end.y)


func _rect_bascule() -> Rect2:
	var panneau := _rect_panneau()
	return Rect2(panneau.position + Vector2(40, 40), Vector2(panneau.size.x - 80, 120))


func _rect_achat(i: int) -> Rect2:
	var panneau := _rect_panneau()
	var haut := _rect_bascule().end.y + 40
	var hauteur := (panneau.end.y - haut - 40) / NB_ACHATS
	return Rect2(panneau.position.x + 40, haut + i * hauteur, panneau.size.x - 80, hauteur - 20)


func _x_dormeur() -> float:
	return _rect_bande().size.x * 0.2


func _y_sol() -> float:
	return _rect_bande().size.y * 0.75


func _draw() -> void:
	var police := ThemeDB.fallback_font
	var bande := _rect_bande()
	var panneau := _rect_panneau()
	var sol := _y_sol()

	# Bande de rêve
	draw_rect(bande, Color(0.09, 0.1, 0.18))
	draw_rect(Rect2(0, sol, bande.size.x, bande.size.y - sol), Color(0.16, 0.17, 0.28))
	# Repères au sol, pour sentir le défilement
	var x := -fmod(defilement, 200.0)
	while x < bande.size.x:
		draw_rect(Rect2(x, sol, 6, 30), Color(0.3, 0.32, 0.45))
		x += 200.0

	# Obstacles
	for distance in obstacles:
		var x_obstacle := _x_dormeur() + distance
		if x_obstacle < bande.size.x:
			draw_rect(
				Rect2(Vector2(x_obstacle, sol - TAILLE_OBSTACLE.y), TAILLE_OBSTACLE),
				Color(0.85, 0.55, 0.3)
			)

	# Dormeur
	var hauteur := 0.0
	if temps_saut >= 0.0:
		var u := temps_saut / DUREE_SAUT_S
		hauteur = 4.0 * HAUTEUR_SAUT * u * (1.0 - u)
	var couleur_dormeur := Color(0.9, 0.9, 1.0)
	if flash_trebuchement > 0.0:
		couleur_dormeur = Color(0.95, 0.3, 0.3)
	draw_rect(
		Rect2(Vector2(_x_dormeur() - TAILLE_DORMEUR.x, sol - TAILLE_DORMEUR.y - hauteur), TAILLE_DORMEUR),
		couleur_dormeur
	)

	draw_string(
		police, Vector2(40, 90),
		"Enjambées : %d   Trébuchements : %d" % [enjambees, trebuchements],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 48
	)

	# Panneau du troupeau et des achats
	draw_rect(panneau, Color(0.13, 0.13, 0.16))
	var bascule := _rect_bascule()
	draw_rect(bascule, Color(0.3, 0.45, 0.7))
	draw_string(
		police, bascule.position + Vector2(0, 78),
		"Passer en portrait" if paysage else "Passer en paysage",
		HORIZONTAL_ALIGNMENT_CENTER, bascule.size.x, 44
	)
	for i in NB_ACHATS:
		var achat := _rect_achat(i)
		draw_rect(achat, Color(0.55, 0.6, 0.4) if flash_achats[i] > 0.0 else Color(0.25, 0.26, 0.3))
		draw_string(
			police, achat.position + Vector2(0, achat.size.y / 2 + 14),
			"Achat %d" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, achat.size.x, 40
		)

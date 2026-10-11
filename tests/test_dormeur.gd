extends GutTest
## Tests de l'enjambée : selon le moment du toucher, elle est parfaite,
## maladroite, ou le dormeur trébuche.
##
## Le dormeur est construit à la main (un Area2D avec son Corps) et les
## obstacles sont de simples Area2D placés à la distance voulue.

const SCRIPT_DORMEUR := preload("res://scripts/dormeur.gd")
const X_DORMEUR := 216.0

var _dormeur: Area2D


func before_each() -> void:
	_dormeur = Area2D.new()
	var corps := Polygon2D.new()
	corps.name = "Corps"
	_dormeur.add_child(corps)
	_dormeur.set_script(SCRIPT_DORMEUR)
	_dormeur.position.x = X_DORMEUR
	add_child_autofree(_dormeur)
	watch_signals(_dormeur)


## Crée un obstacle qui atteindra le dormeur dans `secondes` secondes
## (négatif : il le touche déjà depuis ce temps-là).
func _obstacle_dans(secondes: float) -> Area2D:
	var obstacle := Area2D.new()
	obstacle.position.x = X_DORMEUR + secondes * _dormeur.vitesse
	add_child_autofree(obstacle)
	return obstacle


func test_toucher_juste_avant_l_obstacle_est_parfait() -> void:
	_dormeur.toucher(_obstacle_dans(_dormeur.fenetre_parfaite_s * 0.5))
	assert_signal_emitted_with_parameters(_dormeur, "enjambee", [true])
	assert_eq(_dormeur.etat, _dormeur.Etat.SAUT)


func test_toucher_au_bord_de_la_fenetre_est_encore_parfait() -> void:
	_dormeur.toucher(_obstacle_dans(_dormeur.fenetre_parfaite_s * 0.99))
	assert_signal_emitted_with_parameters(_dormeur, "enjambee", [true])


func test_toucher_trop_tot_est_maladroit() -> void:
	_dormeur.toucher(_obstacle_dans(_dormeur.fenetre_parfaite_s + 0.5))
	assert_signal_emitted_with_parameters(_dormeur, "enjambee", [false])


func test_apres_un_toucher_trop_tot_le_dormeur_attend_l_obstacle() -> void:
	_dormeur.toucher(_obstacle_dans(1.0))
	assert_eq(_dormeur.etat, _dormeur.Etat.PRET)


func test_le_dormeur_pret_saute_quand_l_obstacle_arrive() -> void:
	var obstacle := _obstacle_dans(1.0)
	_dormeur.toucher(obstacle)
	obstacle.position.x = X_DORMEUR + 0.05 * _dormeur.vitesse  # l'obstacle est là
	_dormeur._process(0.0)
	assert_eq(_dormeur.etat, _dormeur.Etat.SAUT)


func test_toucher_un_peu_trop_tard_est_maladroit() -> void:
	_dormeur.toucher(_obstacle_dans(-_dormeur.tolerance_retard_s * 0.5))
	assert_signal_emitted_with_parameters(_dormeur, "enjambee", [false])
	assert_eq(_dormeur.etat, _dormeur.Etat.SAUT)


func test_toucher_sans_obstacle_est_un_pas_maladroit_dans_le_vide() -> void:
	_dormeur.toucher(null)
	assert_signal_emitted_with_parameters(_dormeur, "enjambee", [false])


func test_un_second_toucher_pendant_le_saut_est_ignore() -> void:
	_dormeur.toucher(_obstacle_dans(0.05))
	_dormeur.toucher(_obstacle_dans(0.05))
	assert_signal_emit_count(_dormeur, "enjambee", 1)


func test_un_second_toucher_apres_un_toucher_trop_tot_est_ignore() -> void:
	var obstacle := _obstacle_dans(1.0)
	_dormeur.toucher(obstacle)
	_dormeur.toucher(obstacle)
	assert_signal_emit_count(_dormeur, "enjambee", 1)


func test_sans_toucher_le_dormeur_trebuche() -> void:
	_dormeur._sur_contact(_obstacle_dans(0.0))
	await wait_seconds(_dormeur.tolerance_retard_s + 0.1)
	assert_signal_emitted(_dormeur, "trebuchement")
	assert_eq(_dormeur.etat, _dormeur.Etat.CHUTE)


func test_un_obstacle_enjambe_ne_fait_pas_trebucher() -> void:
	var obstacle := _obstacle_dans(0.05)
	_dormeur.toucher(obstacle)
	_dormeur._sur_contact(obstacle)
	await wait_seconds(_dormeur.tolerance_retard_s + 0.1)
	assert_signal_not_emitted(_dormeur, "trebuchement")


func test_un_toucher_pendant_la_tolerance_sauve_le_dormeur() -> void:
	var obstacle := _obstacle_dans(-0.01)
	_dormeur._sur_contact(obstacle)  # l'obstacle vient de le toucher…
	_dormeur.toucher(obstacle)  # …et le joueur réagit de justesse
	await wait_seconds(_dormeur.tolerance_retard_s + 0.1)
	assert_signal_not_emitted(_dormeur, "trebuchement")
	assert_signal_emitted_with_parameters(_dormeur, "enjambee", [false])


func test_un_toucher_pendant_la_chute_est_ignore() -> void:
	_dormeur._sur_contact(_obstacle_dans(0.0))
	await wait_seconds(_dormeur.tolerance_retard_s + 0.1)
	_dormeur.toucher(null)
	assert_signal_not_emitted(_dormeur, "enjambee")


func test_le_dormeur_reprend_sa_marche_apres_le_saut() -> void:
	_dormeur.toucher(null)
	await wait_seconds(_dormeur.DUREE_SAUT_S + 0.2)
	assert_eq(_dormeur.etat, _dormeur.Etat.MARCHE)

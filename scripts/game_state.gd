extends Node
## État du jeu, chargé automatiquement au démarrage sous le nom GameState
## (voir Projet → Paramètres du projet → Chargement automatique).
##
## Il tient les ressources et la profondeur, applique les règles du jeu, et
## prévient l'affichage par des signaux. Les scènes ne modifient jamais ces
## valeurs elles-mêmes : elles disent ce qui s'est passé (« le dormeur a
## trébuché ») en appelant les fonctions ci-dessous.

signal fragments_changes(fragments: float)
## Un trébuchement vient de faire s'envoler `montant` fragments.
signal fragments_perdus(montant: float)
signal profondeur_changee(profondeur: float)

var fragments := 0.0:
	set(valeur):
		fragments = valeur
		fragments_changes.emit(fragments)

## Profondeur de sommeil P, entre 0 et profondeur_max. Elle monte toute seule
## tant qu'on ne touche pas l'écran.
var profondeur := 0.0:
	set(valeur):
		profondeur = valeur
		profondeur_changee.emit(profondeur)

var profondeur_max: float

var _couts_pourcent: Dictionary  # part de P perdue selon l'issue de l'enjambée
var _valeur_fragment: float  # avant le multiplicateur M(P)
var _duree_perte_s: float  # un trébuchement fait perdre les fragments de cette durée

var _temps := 0.0  # secondes écoulées depuis le début de la nuit
var _ramassages_recents: Array[Dictionary] = []  # { "temps": ..., "gain": ... }


func _ready() -> void:
	var balance := Balance.donnees()
	profondeur_max = balance["profondeur"]["max"]
	_couts_pourcent = balance["enjambee"]["cout_profondeur_pourcent"]
	_duree_perte_s = balance["enjambee"]["trebuchement_perte_fragments_s"]
	_valeur_fragment = balance["fragments"]["valeur_base"]


func _process(delta: float) -> void:
	_temps += delta
	profondeur += Formules.variation_profondeur(profondeur, delta)


## Le dormeur a enjambé un obstacle (ou fait un pas dans le vide).
func enjamber(parfaite: bool) -> void:
	_faire_payer("parfaite" if parfaite else "maladroite")


## Le dormeur a trébuché : P chute et les fragments ramassés depuis
## quelques secondes s'envolent.
func trebucher() -> void:
	_faire_payer("trebuchement")

	_oublier_ramassages_anciens()
	var perte := 0.0
	for ramassage in _ramassages_recents:
		perte += ramassage["gain"]
	_ramassages_recents.clear()
	fragments -= perte
	fragments_perdus.emit(perte)


## Le dormeur a ramassé un fragment : il vaut d'autant plus que P est haute.
func ramasser_fragment() -> void:
	var gain := _valeur_fragment * Formules.multiplicateur(profondeur)
	_oublier_ramassages_anciens()
	_ramassages_recents.append({"temps": _temps, "gain": gain})
	fragments += gain


## Retire à P la part prévue pour cette issue : 3 veut dire 3 % de P.
func _faire_payer(issue: String) -> void:
	profondeur -= profondeur * _couts_pourcent[issue] / 100.0


func _oublier_ramassages_anciens() -> void:
	var limite := _temps - _duree_perte_s
	while not _ramassages_recents.is_empty() and _ramassages_recents[0]["temps"] < limite:
		_ramassages_recents.pop_front()

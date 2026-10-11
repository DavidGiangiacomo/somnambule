extends Node
## État du jeu, chargé automatiquement au démarrage sous le nom GameState
## (voir Projet → Paramètres du projet → Chargement automatique).
##
## Il tient les ressources, le troupeau, les améliorations du dormeur, la
## profondeur et les réminiscences, applique les règles du jeu, et prévient l'affichage par des signaux. Les scènes ne modifient
## jamais ces valeurs elles-mêmes : elles disent ce qui s'est passé (« le
## dormeur a trébuché », « le joueur veut un mouton ») en appelant les
## fonctions ci-dessous.

signal fragments_changes(fragments: float)
## Un trébuchement vient de faire s'envoler `montant` fragments.
signal fragments_perdus(montant: float)
signal profondeur_changee(profondeur: float)
## Le dormeur vient d'entrer dans un autre palier de sommeil, plus profond ou
## moins profond. `palier` est sa description dans balance.json.
signal palier_change(palier: Dictionary)
## Le nombre de moutons d'un type a changé (achat ou chargement de la partie).
signal troupeau_change(id: String, nombre: int)
## Une amélioration du dormeur a changé de niveau (achat ou chargement).
signal amelioration_changee(id: String, niveau: int)
## Le joueur vient d'acheter un mouton ou un niveau d'amélioration.
signal achat_effectue(id: String)
## Un Réveil rapporterait maintenant ce nombre de réminiscences.
signal reminiscences_possibles_changees(reminiscences: int)
## Le nombre de réminiscences gardées a changé (Réveil ou chargement).
signal reminiscences_changees(reminiscences: int)
## Le dormeur vient de se réveiller : `resume` décrit la nuit qui s'achève
## (voir resume_de_la_nuit), et une nouvelle nuit commence.
signal nuit_terminee(resume: Dictionary)

var fragments := 0.0:
	set(valeur):
		fragments = valeur
		fragments_changes.emit(fragments)

## Profondeur de sommeil P, entre 0 et profondeur_max. Elle monte toute seule
## tant qu'on ne touche pas l'écran.
var profondeur := 0.0:
	set(valeur):
		profondeur = valeur
		profondeur_record = maxf(profondeur_record, profondeur)
		profondeur_changee.emit(profondeur)
		var nouveau_palier := Formules.palier(profondeur)
		if nouveau_palier["id"] != palier.get("id"):
			palier = nouveau_palier
			palier_change.emit(palier)

var profondeur_max: float

## Le palier de sommeil où se trouve le dormeur : { "id": …, "nom": …, "seuil": … }
var palier: Dictionary = {}

## La profondeur la plus grande atteinte pendant la nuit.
var profondeur_record := 0.0

## Total des fragments gagnés pendant la nuit, dépenses non déduites. C'est
## lui qui décide du nombre de réminiscences au Réveil.
var fragments_de_la_nuit := 0.0:
	set(valeur):
		fragments_de_la_nuit = valeur
		var possibles := Formules.reminiscences(fragments_de_la_nuit)
		if possibles != reminiscences_possibles:
			reminiscences_possibles = possibles
			reminiscences_possibles_changees.emit(possibles)

## Ce qu'un Réveil rapporterait maintenant.
var reminiscences_possibles := 0

## Réminiscences gardées, gagnées aux Réveils précédents. Chacune augmente
## toute la production.
var reminiscences := 0:
	set(valeur):
		reminiscences = valeur
		reminiscences_changees.emit(reminiscences)

## Ce qu'a rapporté le Réveil précédent (0 pendant la première nuit).
var reminiscences_derniere_nuit := 0

## Numéro de la nuit en cours : 1 pour la première.
var nuit := 1

## Nombre de moutons possédés, par identifiant : { "mouton": 3, "belier": 0… }
var moutons: Dictionary = {}

## Niveau de chaque amélioration du dormeur : { "oreiller": 2, "couette": 0… }
var ameliorations: Dictionary = {}

var _couts_pourcent: Dictionary  # part de P perdue selon l'issue de l'enjambée
var _valeur_fragment: float  # avant le multiplicateur M(P)
var _duree_perte_s: float  # un trébuchement fait perdre les fragments de cette durée

var _fiches_moutons: Array  # les moutons tels que décrits dans balance.json
var _doublement_tous_les: int
var _seuils_paliers: Dictionary = {}  # identifiant du palier → profondeur d'entrée
var _fiches_ameliorations: Array  # les améliorations décrites dans balance.json
var _fenetre_parfaite_de_base_ms: float

var _temps := 0.0  # secondes écoulées depuis le début de la nuit
var _ramassages_recents: Array[Dictionary] = []  # { "temps": ..., "gain": ... }
var _recharge_casse_s := 0.0  # temps avant de pouvoir casser un nouvel obstacle


func _ready() -> void:
	var balance := Balance.donnees()
	profondeur_max = balance["profondeur"]["max"]
	palier = Formules.palier(profondeur)
	_couts_pourcent = balance["enjambee"]["cout_profondeur_pourcent"]
	_duree_perte_s = balance["enjambee"]["trebuchement_perte_fragments_s"]
	_valeur_fragment = balance["fragments"]["valeur_base"]

	_fiches_moutons = balance["moutons"]["liste"]
	_doublement_tous_les = balance["moutons"]["doublement_tous_les"]
	for fiche in _fiches_moutons:
		moutons[fiche["id"]] = 0
	for palier in balance["profondeur"]["paliers"]:
		_seuils_paliers[palier["id"]] = palier["seuil"]

	_fiches_ameliorations = balance["ameliorations"]
	_fenetre_parfaite_de_base_ms = balance["enjambee"]["fenetre_parfaite_ms"]
	for fiche in _fiches_ameliorations:
		ameliorations[fiche["id"]] = 0


func _process(delta: float) -> void:
	_temps += delta
	_recharge_casse_s = maxf(0.0, _recharge_casse_s - delta)
	var acceleration := 1.0 + bonus_descente_pourcent() / 100.0
	# Bornée : après une très longue image, le calcul pourrait dépasser le maximum.
	profondeur = minf(
		profondeur + Formules.variation_profondeur(profondeur, delta) * acceleration,
		profondeur_max
	)

	var gain := gains_par_seconde() * delta
	if gain > 0.0:
		_gagner(gain)


# --- Le dormeur ---


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
	# S'ils ont déjà été dépensés, on ne peut pas reprendre plus que le reste.
	perte = minf(perte, fragments)
	fragments -= perte
	fragments_de_la_nuit -= perte
	fragments_perdus.emit(perte)


## Le dormeur a ramassé un fragment : il vaut d'autant plus que P est haute.
func ramasser_fragment() -> void:
	var gain := _valeur_fragment * Formules.multiplicateur(profondeur) * bonus_reminiscences()
	_oublier_ramassages_anciens()
	_ramassages_recents.append({"temps": _temps, "gain": gain})
	_gagner(gain)


# --- Le troupeau ---


## Prix du prochain mouton de ce type.
func cout_mouton(id: String) -> float:
	return Formules.cout_achat(_fiche_mouton(id), moutons[id])


func peut_acheter_mouton(id: String) -> bool:
	return fragments >= cout_mouton(id)


## Achète un mouton si le joueur en a les moyens. Renvoie vrai si c'est fait.
func acheter_mouton(id: String) -> bool:
	var cout := cout_mouton(id)
	if fragments < cout:
		return false
	fragments -= cout
	moutons[id] += 1
	troupeau_change.emit(id, moutons[id])
	achat_effectue.emit(id)
	return true


## Fragments produits par seconde par tout le troupeau, avant M(P).
func production_troupeau() -> float:
	var total := 0.0
	for fiche in _fiches_moutons:
		var production := Formules.production_moutons(
			fiche, moutons[fiche["id"]], _doublement_tous_les
		)
		# Certains moutons produisent davantage à partir d'un palier de sommeil.
		if fiche.has("bonus_palier") and profondeur >= _seuils_paliers[fiche["bonus_palier"]]:
			production *= fiche["bonus_multiplicateur"]
		total += production
	return total


## Ce que le troupeau rapporte vraiment chaque seconde, à la profondeur
## actuelle et avec le bonus des réminiscences.
func gains_par_seconde() -> float:
	return production_troupeau() * Formules.multiplicateur(profondeur) * bonus_reminiscences()


## Vrai si un mouton du troupeau peut casser le prochain obstacle.
func peut_casser_obstacle() -> bool:
	return _recharge_casse_s <= 0.0 and _intervalle_casse_s() > 0.0


## Un obstacle vient d'être cassé : il faut attendre avant le suivant.
func casser_obstacle() -> void:
	_recharge_casse_s = _intervalle_casse_s()


## Vrai si un mouton du troupeau ramasse les fragments hors de portée du dormeur.
func ramasse_hors_de_portee() -> bool:
	for fiche in _fiches_moutons:
		if fiche.get("ramasse_hors_de_portee", false) and moutons[fiche["id"]] > 0:
			return true
	return false


# --- Les améliorations du dormeur ---


## Prix du prochain niveau de cette amélioration.
func cout_amelioration(id: String) -> float:
	return Formules.cout_achat(_fiche_amelioration(id), ameliorations[id])


## Vrai si un niveau de plus n'apporterait rien : l'effet a atteint son plancher.
func amelioration_au_maximum(id: String) -> bool:
	var fiche := _fiche_amelioration(id)
	return (
		fiche["effet"] == "perte_trebuchement_points"
		and cout_trebuchement_pourcent() <= fiche.get("plancher", 0.0)
	)


func peut_acheter_amelioration(id: String) -> bool:
	return not amelioration_au_maximum(id) and fragments >= cout_amelioration(id)


## Achète un niveau si le joueur en a les moyens. Renvoie vrai si c'est fait.
func acheter_amelioration(id: String) -> bool:
	if not peut_acheter_amelioration(id):
		return false
	fragments -= cout_amelioration(id)
	ameliorations[id] += 1
	amelioration_changee.emit(id, ameliorations[id])
	achat_effectue.emit(id)
	return true


## De combien la descente dans le sommeil est accélérée : 20 veut dire +20 %.
func bonus_descente_pourcent() -> float:
	return _effet("vitesse_descente_pourcent")


## Part de P perdue à chaque trébuchement, améliorations comprises.
func cout_trebuchement_pourcent() -> float:
	var cout: float = _couts_pourcent["trebuchement"] + _effet("perte_trebuchement_points")
	return maxf(cout, _plancher("perte_trebuchement_points"))


## Durée de la fenêtre d'enjambée parfaite, améliorations comprises.
func fenetre_parfaite_ms() -> float:
	return _fenetre_parfaite_de_base_ms + _effet("fenetre_parfaite_ms")


# --- Le Réveil ---


## Multiplicateur de production dû aux réminiscences gardées (1 = aucun bonus).
func bonus_reminiscences() -> float:
	return Formules.bonus_reminiscences(reminiscences)


func peut_se_reveiller() -> bool:
	return reminiscences_possibles >= 1


## Vrai quand le Réveil rapporterait au moins le double du précédent (ou au
## moins 2 réminiscences pendant la première nuit) : le réveil-matin insiste.
func le_reveil_sonne_fort() -> bool:
	return reminiscences_possibles >= 2 * maxi(1, reminiscences_derniere_nuit)


## Ce qu'il y a à dire de la nuit en cours, pour l'écran de Réveil.
func resume_de_la_nuit() -> Dictionary:
	return {
		"nuit": nuit,
		"duree_s": _temps,
		"fragments": fragments_de_la_nuit,
		"palier": Formules.palier(profondeur_record),
		"reminiscences": reminiscences_possibles,
	}


## Le dormeur se réveille, si la nuit rapporte au moins une réminiscence :
## elles sont gardées pour toujours, tout le reste repart de zéro et la nuit
## suivante commence. Renvoie vrai si c'est fait.
func se_reveiller() -> bool:
	if not peut_se_reveiller():
		return false
	var resume := resume_de_la_nuit()

	reminiscences_derniere_nuit = reminiscences_possibles
	reminiscences += reminiscences_possibles
	nuit += 1

	_temps = 0.0
	_ramassages_recents.clear()
	_recharge_casse_s = 0.0
	for id: String in moutons:
		moutons[id] = 0
		troupeau_change.emit(id, 0)
	for id: String in ameliorations:
		ameliorations[id] = 0
		amelioration_changee.emit(id, 0)
	fragments = 0.0
	fragments_de_la_nuit = 0.0
	profondeur = 0.0
	profondeur_record = 0.0

	nuit_terminee.emit(resume)
	return true


# --- La sauvegarde ---


## Ce qu'il faut écrire dans la sauvegarde pour retrouver la partie.
func vers_sauvegarde() -> Dictionary:
	return {
		"fragments": fragments,
		"profondeur": profondeur,
		"moutons": moutons.duplicate(),
		"ameliorations": ameliorations.duplicate(),
		"fragments_de_la_nuit": fragments_de_la_nuit,
		"duree_nuit_s": _temps,
		"profondeur_record": profondeur_record,
		"nuit": nuit,
		"reminiscences": reminiscences,
		"reminiscences_derniere_nuit": reminiscences_derniere_nuit,
	}


## Reprend la partie décrite par une sauvegarde. Un champ absent garde sa
## valeur de départ.
func depuis_sauvegarde(donnees: Dictionary) -> void:
	fragments = donnees.get("fragments", 0.0)
	profondeur = clampf(donnees.get("profondeur", 0.0), 0.0, profondeur_max)
	profondeur_record = clampf(donnees.get("profondeur_record", profondeur), profondeur, profondeur_max)
	fragments_de_la_nuit = donnees.get("fragments_de_la_nuit", 0.0)
	_temps = donnees.get("duree_nuit_s", 0.0)
	# Le JSON ne connaît que les nombres à virgule : on revient à des entiers.
	nuit = maxi(1, int(donnees.get("nuit", 1)))
	reminiscences = maxi(0, int(donnees.get("reminiscences", 0)))
	reminiscences_derniere_nuit = maxi(0, int(donnees.get("reminiscences_derniere_nuit", 0)))

	var moutons_sauvegardes: Dictionary = donnees.get("moutons", {})
	for id: String in moutons:
		moutons[id] = maxi(0, int(moutons_sauvegardes.get(id, 0)))
		troupeau_change.emit(id, moutons[id])

	var niveaux_sauvegardes: Dictionary = donnees.get("ameliorations", {})
	for id: String in ameliorations:
		ameliorations[id] = maxi(0, int(niveaux_sauvegardes.get(id, 0)))
		amelioration_changee.emit(id, ameliorations[id])


# --- Détails ---


func _fiche_mouton(id: String) -> Dictionary:
	for fiche in _fiches_moutons:
		if fiche["id"] == id:
			return fiche
	assert(false, "Mouton inconnu : %s" % id)
	return {}


func _fiche_amelioration(id: String) -> Dictionary:
	for fiche in _fiches_ameliorations:
		if fiche["id"] == id:
			return fiche
	assert(false, "Amélioration inconnue : %s" % id)
	return {}


## Total apporté par les améliorations qui agissent sur `effet` : leur valeur
## par niveau multipliée par leur niveau.
func _effet(effet: String) -> float:
	var total := 0.0
	for fiche in _fiches_ameliorations:
		if fiche["effet"] == effet:
			total += fiche["valeur_par_niveau"] * ameliorations[fiche["id"]]
	return total


## Valeur sous laquelle `effet` ne peut pas faire descendre ce qu'il modifie.
func _plancher(effet: String) -> float:
	for fiche in _fiches_ameliorations:
		if fiche["effet"] == effet:
			return fiche.get("plancher", 0.0)
	return 0.0


## Ajoute des fragments gagnés : au compteur et au total de la nuit.
func _gagner(montant: float) -> void:
	fragments += montant
	fragments_de_la_nuit += montant


## Délai entre deux obstacles cassés, ou 0 si aucun mouton possédé n'en casse.
func _intervalle_casse_s() -> float:
	for fiche in _fiches_moutons:
		if fiche.has("casse_obstacle_toutes_les_s") and moutons[fiche["id"]] > 0:
			return fiche["casse_obstacle_toutes_les_s"]
	return 0.0


## Retire à P la part prévue pour cette issue : 3 veut dire 3 % de P.
func _faire_payer(issue: String) -> void:
	var cout: float = _couts_pourcent[issue]
	if issue == "trebuchement":
		cout = cout_trebuchement_pourcent()
	profondeur -= profondeur * cout / 100.0


func _oublier_ramassages_anciens() -> void:
	var limite := _temps - _duree_perte_s
	while not _ramassages_recents.is_empty() and _ramassages_recents[0]["temps"] < limite:
		_ramassages_recents.pop_front()

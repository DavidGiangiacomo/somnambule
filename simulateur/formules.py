"""
Formules du GDD du Somnambule (docs/gdd.md).

Chaque fonction de ce fichier traduit UNE formule du document de game design.
Elles sont « pures » : elles reçoivent des nombres, renvoient un résultat et
ne modifient rien d'autre. C'est ce qui les rend faciles à vérifier une par
une, et à recopier plus tard en GDScript dans Godot.

Le paramètre `balance` qu'on retrouve partout est le contenu du fichier
data/balance.json, chargé sous forme de dictionnaire Python (voir
simulateur.py). On lit une valeur avec des crochets, par exemple :
    balance["profondeur"]["max"]   ->   100
"""

# `import` donne accès à un module, c'est-à-dire un fichier de code tout prêt.
# `math` fait partie de Python (rien à installer) : il fournit sqrt, floor...
import math


# `def` définit une fonction : un nom, des paramètres entre parenthèses,
# puis un bloc de code indenté. `return` renvoie le résultat à l'appelant.
def variation_profondeur(p, balance, duree_s):
    """Renvoie de combien la profondeur P augmente pendant `duree_s` secondes.

    Formule du GDD :  dP/dt = v · (1 − P / Pmax)

    Plus le dormeur est déjà profond, plus il s'enfonce lentement : à P = 0,
    il descend à la vitesse v ; à P = Pmax, il ne descend plus du tout.

    On applique la formule par petits pas de temps (« méthode d'Euler ») :
    sur un pas, P augmente de  v · (1 − P / Pmax) × durée du pas.
    Avec v = 2 et Pmax = 100, P bouge d'au plus 2 par seconde, donc un pas
    d'une seconde reste très proche du calcul exact.
    """
    v = balance["profondeur"]["vitesse_descente"]
    p_max = balance["profondeur"]["max"]
    return v * (1 - p / p_max) * duree_s


def multiplicateur(p, balance):
    """Renvoie le multiplicateur de gains M(P) pour une profondeur P.

    Formule du GDD :  M(P) = 1 + 0,32 · (P / 10)^1,5

    Exemples avec les valeurs du GDD : M(0) = 1, M(40) ≈ 3,6, M(100) ≈ 11,1.
    En Python, `**` est l'opérateur « puissance » : 2 ** 3 vaut 8.
    """
    m = balance["multiplicateur"]
    return 1 + m["coefficient"] * (p / m["echelle"]) ** m["exposant"]


def palier(p, balance):
    """Renvoie le palier de sommeil (Assoupi, Paradoxal...) correspondant à P.

    Le résultat est le dictionnaire du palier tel qu'écrit dans balance.json,
    par exemple {"id": "paradoxal", "nom": "Paradoxal", "seuil": 40}.

    Les paliers sont rangés du moins profond au plus profond. On les parcourt
    dans l'ordre et on garde le dernier dont le seuil est atteint.
    """
    paliers = balance["profondeur"]["paliers"]
    palier_trouve = paliers[0]  # [0] = premier élément de la liste
    # `for ... in ...` répète le bloc indenté pour chaque élément de la liste.
    for candidat in paliers:
        if p >= candidat["seuil"]:
            palier_trouve = candidat
    return palier_trouve


def cout_mouton(mouton, deja_possedes):
    """Renvoie le prix du prochain mouton d'un type donné.

    Formule du GDD :  C_n = C0 · r^n

    - `mouton` est la fiche du mouton dans balance.json (coût initial C0,
      raison r...) ;
    - `deja_possedes` est n, le nombre de moutons de ce type déjà achetés.

    Le premier coûte donc C0 (car r^0 = 1), puis chaque achat multiplie le
    prix par r. Avec r = 1,15, chaque mouton coûte 15 % de plus que le
    précédent. Le GDD place r entre 1,07 et 1,15 selon le mouton.
    """
    return mouton["cout_initial"] * mouton["raison_cout"] ** deja_possedes


def production_moutons(mouton, nombre, doublement_tous_les):
    """Renvoie les fragments produits par seconde par `nombre` moutons
    d'un même type, AVANT le multiplicateur de profondeur M(P).

    Règle du GDD : la production de ce type double tous les 25 exemplaires.

    `//` est la division entière (on jette les décimales) : 24 // 25 vaut 0,
    25 // 25 vaut 1, 60 // 25 vaut 2. Le bonus vaut donc 2^0 = 1 jusqu'à
    24 moutons, 2^1 = 2 de 25 à 49, 2^2 = 4 de 50 à 74, etc.
    """
    bonus = 2 ** (nombre // doublement_tous_les)
    return mouton["production_par_seconde"] * nombre * bonus


def reminiscences(fragments_total, balance):
    """Renvoie le nombre de réminiscences R qu'un Réveil rapporterait.

    Formule du GDD :  R = ⌊√(F / 10⁶)⌋

    F est le total des fragments gagnés depuis le début de la nuit (pas ce
    qu'il reste en poche après les achats). ⌊ ⌋ veut dire « arrondi à
    l'entier inférieur » : c'est `math.floor`.

    Il faut donc 1 million de fragments pour R = 1, 4 millions pour R = 2,
    9 millions pour R = 3 : chaque réminiscence coûte de plus en plus cher.
    """
    diviseur = balance["reminiscences"]["diviseur_fragments"]
    return math.floor(math.sqrt(fragments_total / diviseur))


def bonus_reminiscences(reminiscences_gardees, balance):
    """Renvoie le multiplicateur de production dû aux réminiscences gardées.

    Règle du GDD : chaque réminiscence non dépensée donne +2 % de production
    globale. Avec 5 réminiscences gardées : 1 + 5 × 2 / 100 = 1,10, soit +10 %.
    Sans réminiscence (première nuit), le multiplicateur vaut 1 : pas de bonus.
    """
    pourcent = balance["reminiscences"]["bonus_production_pourcent"]
    return 1 + reminiscences_gardees * pourcent / 100

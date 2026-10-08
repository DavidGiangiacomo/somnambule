"""
Simulateur d'économie de Somnambule (issue #1).

Il fait tourner une nuit seconde par seconde, sans aucun graphisme, pour
répondre à la question : « avec les valeurs de data/balance.json, à quel
rythme le joueur progresse-t-il ? »

À chaque seconde simulée, dans cet ordre :
  1. le dormeur s'enfonce : la profondeur P augmente ;
  2. il récolte des fragments (parcours + moutons), multipliés par M(P) ;
  3. si un obstacle arrive, le joueur l'enjambe plus ou moins bien, ce qui
     fait remonter P (et, en cas de trébuchement, perdre des fragments) ;
  4. il achète les moutons qui valent le coup ;
  5. on note l'état de la nuit dans une ligne du fichier CSV.

Utilisation, depuis la racine du dépôt :
    python3 simulateur/simulateur.py
    python3 simulateur/simulateur.py --duree 60 --graine 7

Liste des options : python3 simulateur/simulateur.py --help
"""

# Modules fournis avec Python : rien à installer.
import argparse  # lit les options passées en ligne de commande (--duree...)
import csv  # écrit des fichiers CSV
import json  # lit des fichiers JSON
import random  # tire des nombres au hasard
import time  # mesure le temps de calcul
from dataclasses import dataclass  # décrit l'état d'une nuit (voir plus bas)
from pathlib import Path  # manipule des chemins de fichiers

# Notre propre module : le fichier formules.py, rangé à côté de celui-ci.
# Python le trouve tout seul parce qu'il est dans le même dossier.
import formules


# ---------------------------------------------------------------------------
# Réglages du simulateur
# ---------------------------------------------------------------------------
# Par convention, un nom EN_MAJUSCULES désigne une constante : une valeur
# fixée une fois pour toutes, qu'on ne modifie pas pendant le calcul.

# Durée d'un pas de simulation : on avance d'une seconde à la fois.
PAS_S = 1

# `__file__` est le chemin de ce fichier-ci et `.parent` remonte d'un dossier.
# L'opérateur `/` colle des morceaux de chemin. Ces chemins fonctionnent quel
# que soit le dossier depuis lequel on lance le script.
DOSSIER_SIMULATEUR = Path(__file__).parent
FICHIER_BALANCE = DOSSIER_SIMULATEUR.parent / "data" / "balance.json"
FICHIER_SORTIE = DOSSIER_SIMULATEUR / "sorties" / "nuit.csv"

# Comportement du joueur simulé face aux obstacles : la probabilité de chaque
# issue d'enjambée. Les trois valeurs doivent faire 1 (= 100 %).
# C'est le profil « moyen » de l'issue #2 ; les profils « attentif » et
# « idle pur » viendront avec cette issue.
PROFIL_MOYEN = {
    "nom": "moyen",
    "parfaite": 0.50,
    "maladroite": 0.40,
    "trebuchement": 0.10,
}


# ---------------------------------------------------------------------------
# État d'une nuit
# ---------------------------------------------------------------------------
# Une « dataclass » est une fiche avec des champs nommés. On en crée une au
# début de la nuit, puis chaque étape lit et modifie ses champs :
#     etat.profondeur        -> lit la profondeur actuelle
#     etat.profondeur = 12   -> la remplace par 12
# Ce qui suit les deux-points indique le type de valeur attendu : int (nombre
# entier), float (nombre à virgule), dict (dictionnaire), list (liste).
# C'est une aide à la lecture : Python ne le vérifie pas.


@dataclass
class EtatNuit:
    seconde: int  # temps écoulé depuis le début de la nuit
    profondeur: float  # P, entre 0 et Pmax
    fragments: float  # fragments en poche, que l'on peut dépenser
    fragments_total: float  # fragments gagnés depuis le début de la nuit (sert à calculer R)
    moutons: dict  # nombre possédé par type, ex. {"mouton": 12, "belier": 3}
    gains_parcours_recents: list  # fragments ramassés sur le parcours, une valeur par seconde
    prochain_obstacle: float  # instant (en secondes) où arrive le prochain obstacle


def nouvelle_nuit(balance, hasard):
    """Crée l'état du tout début d'une nuit : rien en poche, aucun mouton."""
    # On part d'un dictionnaire vide {} et on y range 0 pour chaque type de
    # mouton déclaré dans balance.json.
    moutons = {}
    for mouton in balance["moutons"]["liste"]:
        moutons[mouton["id"]] = 0

    return EtatNuit(
        seconde=0,
        profondeur=0.0,
        fragments=0.0,
        fragments_total=0.0,
        moutons=moutons,
        gains_parcours_recents=[],  # [] est une liste vide
        prochain_obstacle=tirer_intervalle_obstacle(balance, hasard),
    )


# ---------------------------------------------------------------------------
# Étape 1 : la descente
# ---------------------------------------------------------------------------


def faire_descendre(etat, balance):
    """Le dormeur s'enfonce dans le sommeil pendant un pas de temps."""
    # `a += b` est un raccourci pour `a = a + b`.
    etat.profondeur += formules.variation_profondeur(etat.profondeur, balance, PAS_S)


# ---------------------------------------------------------------------------
# Étape 2 : la récolte
# ---------------------------------------------------------------------------


def gain_parcours_de_base(balance):
    """Fragments ramassés par seconde sur le parcours, avant M(P)."""
    fragments = balance["fragments"]
    return fragments["apparitions_par_seconde"] * fragments["valeur_base"]


def production_troupeau(etat, balance):
    """Fragments produits par seconde par tout le troupeau, avant M(P)."""
    doublement = balance["moutons"]["doublement_tous_les"]
    total = 0
    for mouton in balance["moutons"]["liste"]:
        nombre = etat.moutons[mouton["id"]]
        total += formules.production_moutons(mouton, nombre, doublement)
    return total


def recolter(etat, balance):
    """Le dormeur ramasse des fragments sur le parcours et le troupeau produit.

    Tout est multiplié par M(P) : plus le dormeur est profond, plus il gagne.
    Renvoie le gain de ce pas de temps, pour l'écrire dans le CSV.
    """
    m = formules.multiplicateur(etat.profondeur, balance)
    gain_parcours = gain_parcours_de_base(balance) * m * PAS_S
    gain_moutons = production_troupeau(etat, balance) * m * PAS_S

    gain = gain_parcours + gain_moutons
    etat.fragments += gain
    etat.fragments_total += gain

    # On mémorise ce qui a été ramassé sur le parcours pendant les dernières
    # secondes, car un trébuchement le fait perdre (étape 3).
    # `.append(x)` ajoute x à la fin d'une liste ; `liste[-n:]` garde ses
    # n derniers éléments et oublie les plus anciens.
    etat.gains_parcours_recents.append(gain_parcours)
    secondes_memorisees = balance["enjambee"]["trebuchement_perte_fragments_s"]
    nombre_de_pas = int(secondes_memorisees / PAS_S)
    etat.gains_parcours_recents = etat.gains_parcours_recents[-nombre_de_pas:]

    return gain


# ---------------------------------------------------------------------------
# Étape 3 : les obstacles
# ---------------------------------------------------------------------------


def tirer_intervalle_obstacle(balance, hasard):
    """Renvoie le temps (en secondes) avant l'obstacle suivant, tiré au hasard
    entre l'intervalle minimum et l'intervalle maximum de balance.json."""
    obstacles = balance["obstacles"]
    return hasard.uniform(obstacles["intervalle_min_s"], obstacles["intervalle_max_s"])


def tirer_issue_enjambee(profil, hasard):
    """Tire au sort l'issue d'une enjambée selon les probabilités du profil.

    `hasard.random()` renvoie un nombre au hasard entre 0 et 1. Avec le
    profil moyen (50 % / 40 % / 10 %), on découpe cet intervalle ainsi :
      - de 0   à 0,5 -> "parfaite"
      - de 0,5 à 0,9 -> "maladroite"
      - de 0,9 à 1   -> "trebuchement"
    """
    tirage = hasard.random()
    if tirage < profil["parfaite"]:
        return "parfaite"
    if tirage < profil["parfaite"] + profil["maladroite"]:
        return "maladroite"
    return "trebuchement"


def passer_obstacle(etat, balance, profil, hasard):
    """Si un obstacle arrive à cet instant, le joueur l'enjambe.

    Renvoie l'issue ("parfaite", "maladroite" ou "trebuchement"), ou une
    chaîne vide "" s'il n'y a pas d'obstacle à cet instant.
    """
    if etat.seconde < etat.prochain_obstacle:
        return ""  # l'obstacle n'est pas encore là

    issue = tirer_issue_enjambee(profil, hasard)

    # Enjamber fait remonter le dormeur : cela coûte un pourcentage de P.
    # balance.json donne des pourcentages (3 pour 3 %), d'où la division par 100.
    cout = balance["enjambee"]["cout_profondeur_pourcent"][issue] / 100
    etat.profondeur -= etat.profondeur * cout

    # Un trébuchement fait en plus perdre les fragments ramassés sur le
    # parcours pendant les dernières secondes (pas la production des moutons).
    if issue == "trebuchement":
        perte = sum(etat.gains_parcours_recents)  # sum() additionne une liste
        perte = min(perte, etat.fragments)  # on ne peut pas perdre plus qu'on n'a
        etat.fragments -= perte
        etat.fragments_total -= perte
        etat.gains_parcours_recents = []

    # On programme l'obstacle suivant.
    etat.prochain_obstacle += tirer_intervalle_obstacle(balance, hasard)
    return issue


# ---------------------------------------------------------------------------
# Étape 4 : les achats
# ---------------------------------------------------------------------------


def delai_rentabilisation(mouton, etat, balance):
    """Renvoie dans combien de secondes l'achat de ce mouton serait remboursé.

    C'est la somme de deux durées :
      - le temps d'économiser son prix (0 si on a déjà de quoi le payer) ;
      - le temps qu'il faut à sa production pour rembourser ce prix.
    Plus le délai est court, meilleur est l'achat.

    On compare la production de ce type de mouton avant et après l'achat :
    cela compte aussi le doublement au 25e exemplaire, qui rend cet achat-là
    particulièrement intéressant.
    """
    doublement = balance["moutons"]["doublement_tous_les"]
    m = formules.multiplicateur(etat.profondeur, balance)
    n = etat.moutons[mouton["id"]]

    prix = formules.cout_mouton(mouton, n)
    avant = formules.production_moutons(mouton, n, doublement)
    apres = formules.production_moutons(mouton, n + 1, doublement)
    gain_en_plus = (apres - avant) * m

    revenu = (gain_parcours_de_base(balance) + production_troupeau(etat, balance)) * m
    attente = max(0, prix - etat.fragments) / revenu  # max(0, x) : jamais négatif
    remboursement = prix / gain_en_plus
    return attente + remboursement


def meilleur_achat(etat, balance):
    """Renvoie le mouton dont l'achat serait remboursé le plus vite."""
    # min() cherche le plus petit élément d'une liste. `key=` lui dit quoi
    # comparer : ici, pour chaque mouton, son délai de rentabilisation.
    # `lambda mouton: ...` est une petite fonction sans nom écrite sur place.
    return min(
        balance["moutons"]["liste"],
        key=lambda mouton: delai_rentabilisation(mouton, etat, balance),
    )


def acheter_moutons(etat, balance):
    """Le joueur achète des moutons tant que c'est intéressant.

    Stratégie : on repère l'achat remboursé le plus vite. Si on peut se le
    payer, on l'achète et on recommence ; sinon, on économise pour lui.
    Ainsi le joueur simulé sait attendre un Bélier plutôt que d'acheter un
    énième Mouton devenu trop cher.
    """
    # `while True` répète le bloc indéfiniment ; `break` permet d'en sortir.
    while True:
        mouton = meilleur_achat(etat, balance)
        prix = formules.cout_mouton(mouton, etat.moutons[mouton["id"]])
        if prix > etat.fragments:
            break  # trop cher pour l'instant : on économise
        etat.fragments -= prix
        etat.moutons[mouton["id"]] += 1


# ---------------------------------------------------------------------------
# La nuit complète
# ---------------------------------------------------------------------------


def verifier_profil(profil):
    """Arrête le programme avec un message clair si les probabilités du profil
    ne font pas 100 %."""
    total = profil["parfaite"] + profil["maladroite"] + profil["trebuchement"]
    # Les nombres à virgule ne sont pas exacts en informatique (0.1 + 0.2 ne
    # vaut pas tout à fait 0.3), d'où une petite tolérance plutôt que `== 1`.
    if abs(total - 1) > 1e-9:
        # `raise` arrête le programme en signalant une erreur.
        raise ValueError(f"Les probabilités du profil {profil['nom']} font {total}, pas 1.")


def ligne_csv(etat, balance, gain, obstacle):
    """Résume l'état de la nuit à cet instant : une ligne du futur CSV.

    La ligne est un dictionnaire {nom de colonne: valeur}.
    """
    ligne = {
        "seconde": etat.seconde,
        "minute": etat.seconde / 60,
        "profondeur": etat.profondeur,
        "palier": formules.palier(etat.profondeur, balance)["nom"],
        "multiplicateur": formules.multiplicateur(etat.profondeur, balance),
        "obstacle": obstacle,
        "gain": gain,
        "fragments": etat.fragments,
        "fragments_total": etat.fragments_total,
    }
    # Une colonne par type de mouton : si on en ajoute un dans balance.json,
    # il apparaît tout seul dans le CSV.
    for mouton in balance["moutons"]["liste"]:
        ligne[mouton["nom"]] = etat.moutons[mouton["id"]]
    ligne["reminiscences"] = formules.reminiscences(etat.fragments_total, balance)
    return ligne


def simuler_nuit(balance, profil, duree_s, graine):
    """Simule une nuit complète et renvoie la liste des lignes du CSV."""
    verifier_profil(profil)

    # Générateur de hasard initialisé avec une « graine » : la même graine
    # donne toujours la même suite de tirages, donc exactement la même nuit.
    # On peut ainsi comparer deux réglages de balance.json à hasard égal.
    hasard = random.Random(graine)

    etat = nouvelle_nuit(balance, hasard)
    lignes = [ligne_csv(etat, balance, gain=0.0, obstacle="")]

    while etat.seconde < duree_s:
        etat.seconde += PAS_S
        faire_descendre(etat, balance)  # 1. descente
        gain = recolter(etat, balance)  # 2. récolte
        obstacle = passer_obstacle(etat, balance, profil, hasard)  # 3. obstacle
        acheter_moutons(etat, balance)  # 4. achats
        lignes.append(ligne_csv(etat, balance, gain, obstacle))  # 5. on note

    return lignes


# ---------------------------------------------------------------------------
# Sorties : fichier CSV et résumé à l'écran
# ---------------------------------------------------------------------------


def valeur_csv(valeur):
    """Écrit les nombres à virgule au format français : 3.14159 -> "3,14"."""
    # isinstance(x, float) vaut True si x est un nombre à virgule.
    if isinstance(valeur, float):
        # Une « f-string » (f"...") remplace ce qui est entre accolades par
        # sa valeur ; `:.2f` demande 2 chiffres après la virgule.
        return f"{valeur:.2f}".replace(".", ",")
    return valeur


def ecrire_csv(lignes, chemin):
    """Écrit les lignes dans un fichier CSV prêt pour un tableur en français.

    - séparateur « ; » et virgule décimale : c'est ce qu'attendent Excel et
      LibreOffice réglés en français ;
    - encodage « utf-8-sig » : de l'UTF-8 précédé d'une marque qui permet à
      Excel d'afficher correctement les accents (« Sommeil léger »).
    """
    chemin.parent.mkdir(parents=True, exist_ok=True)  # crée le dossier s'il manque
    colonnes = list(lignes[0].keys())

    # `with open(...) as fichier:` ouvre le fichier et le referme tout seul
    # à la fin du bloc, même en cas d'erreur.
    with open(chemin, "w", newline="", encoding="utf-8-sig") as fichier:
        ecrivain = csv.writer(fichier, delimiter=";")
        ecrivain.writerow(colonnes)  # première ligne : les titres
        for ligne in lignes:
            # Construit la liste des valeurs de la ligne, dans l'ordre des
            # colonnes, chacune passée au format français.
            ecrivain.writerow([valeur_csv(ligne[colonne]) for colonne in colonnes])


def premiere_seconde(lignes, colonne, seuil):
    """Renvoie la première seconde où `colonne` atteint `seuil`,
    ou None (« rien ») si cela n'arrive jamais pendant la nuit."""
    for ligne in lignes:
        if ligne[colonne] >= seuil:
            return ligne["seconde"]
    return None


def en_minutes(secondes):
    """Met une durée en forme : 1052 -> "17 min 32 s", None -> "jamais"."""
    if secondes is None:
        return "jamais"
    # `//` est la division entière et `%` le reste : 1052 s = 17 × 60 + 32.
    # `:02d` écrit l'entier sur 2 chiffres (5 -> "05").
    return f"{secondes // 60} min {secondes % 60:02d} s"


def grand_nombre(x):
    """Met un grand nombre en forme : 1234567.8 -> "1 234 568"."""
    # `:,.0f` arrondit à l'unité et sépare les milliers par des virgules,
    # qu'on remplace ensuite par des espaces.
    return f"{x:,.0f}".replace(",", " ")


def afficher_resume(lignes, balance, profil, graine, duree_calcul_s, chemin_csv):
    """Affiche à l'écran les chiffres clés de la nuit simulée."""
    fin = lignes[-1]  # [-1] = dernier élément de la liste
    # sum(... for ligne in lignes) additionne la profondeur de chaque ligne ;
    # len() donne le nombre de lignes.
    profondeur_moyenne = sum(ligne["profondeur"] for ligne in lignes) / len(lignes)
    palier_moyen = formules.palier(profondeur_moyenne, balance)["nom"]

    print(f"Nuit de {en_minutes(fin['seconde'])}, profil {profil['nom']}, graine {graine}")
    print(f"Calcul : {duree_calcul_s:.3f} s".replace(".", ","))
    print()
    print("Premier passage par chaque palier :")
    for palier in balance["profondeur"]["paliers"]:
        seconde = premiere_seconde(lignes, "profondeur", palier["seuil"])
        # `:<15` aligne le nom à gauche sur 15 caractères, pour faire une colonne.
        print(f"  {palier['nom']:<15} {en_minutes(seconde)}")
    print(f"Profondeur moyenne : {profondeur_moyenne:.1f} ({palier_moyen})".replace(".", ","))
    print()
    print(f"Premier Réveil possible (R ≥ 1) : {en_minutes(premiere_seconde(lignes, 'reminiscences', 1))}")
    print(f"Fragments gagnés dans la nuit : {grand_nombre(fin['fragments_total'])}")
    print(f"Réminiscences en fin de nuit : {fin['reminiscences']}")
    print("Troupeau en fin de nuit :")
    for mouton in balance["moutons"]["liste"]:
        print(f"  {mouton['nom']:<15} {fin[mouton['nom']]}")
    print()
    print(f"CSV écrit dans {chemin_csv}")


# ---------------------------------------------------------------------------
# Point d'entrée
# ---------------------------------------------------------------------------


def lire_arguments():
    """Lit les options de la ligne de commande (toutes facultatives)."""
    parseur = argparse.ArgumentParser(description="Simule une nuit de Somnambule et écrit un CSV.")
    parseur.add_argument("--duree", type=float, default=30, help="durée de la nuit en minutes (défaut : 30)")
    parseur.add_argument("--graine", type=int, default=42, help="graine du hasard (défaut : 42)")
    parseur.add_argument("--balance", type=Path, default=FICHIER_BALANCE, help="fichier de valeurs à utiliser")
    parseur.add_argument("--sortie", type=Path, default=FICHIER_SORTIE, help="fichier CSV à écrire")
    return parseur.parse_args()


def main():
    arguments = lire_arguments()

    # json.load transforme le texte de balance.json en dictionnaires et
    # listes Python, que les fonctions lisent ensuite avec des crochets.
    with open(arguments.balance, encoding="utf-8") as fichier:
        balance = json.load(fichier)

    # time.perf_counter() donne l'heure précise : la différence entre deux
    # appels mesure le temps de calcul (l'issue #1 demande moins d'1 s).
    debut = time.perf_counter()
    lignes = simuler_nuit(balance, PROFIL_MOYEN, arguments.duree * 60, arguments.graine)
    duree_calcul_s = time.perf_counter() - debut

    ecrire_csv(lignes, arguments.sortie)
    afficher_resume(lignes, balance, PROFIL_MOYEN, arguments.graine, duree_calcul_s, arguments.sortie)


# Ce bloc ne s'exécute que si l'on lance ce fichier directement
# (python3 simulateur/simulateur.py), pas si un autre fichier l'importe.
if __name__ == "__main__":
    main()

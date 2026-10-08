"""
Vérifie le rythme visé par le GDD pour le profil moyen (issue #3).

Trois cibles, tirées du tableau « Rythme visé » du GDD :
  - atteindre le palier Profond la première fois en 3 à 5 min ;
  - premier Réveil possible en 15 à 20 min ;
  - nuits suivantes de 10 à 15 min chacune, jusqu'à la nuit 10.

Chaque mesure est la moyenne de plusieurs séries de nuits, une par graine
de hasard. Après un changement de data/balance.json, lancez aussi
comparer_profils.py : le calage ne doit pas casser les critères de l'issue #2.

Utilisation, depuis la racine du dépôt :
    python3 simulateur/verifier_rythme.py
    python3 simulateur/verifier_rythme.py --graines 10
"""

import argparse
from pathlib import Path

import simulateur

# Cibles du GDD, en secondes. Chaque cible est un couple (minimum, maximum).
CIBLE_PROFOND = (3 * 60, 5 * 60)
CIBLE_PREMIER_REVEIL = (15 * 60, 20 * 60)
CIBLE_NUITS_SUIVANTES = (10 * 60, 15 * 60)
NOMBRE_NUITS = 10

# Les cibles du GDD portent sur le profil moyen.
PROFIL = simulateur.PROFILS["moyen"]


def moyenne(valeurs):
    """Moyenne d'une liste de nombres."""
    return sum(valeurs) / len(valeurs)


def dans_cible(valeur, cible):
    """True si la valeur est entre le minimum et le maximum de la cible."""
    minimum, maximum = cible
    return minimum <= valeur <= maximum


def afficher_mesure(titre, valeurs, cible):
    """Affiche une mesure (moyenne, plage) et dit si elle tient sa cible.

    Renvoie True si la moyenne est dans la cible.
    """
    if None in valeurs:
        print(f"{titre} : jamais atteint sur au moins une nuit -> NON respecté")
        return False

    # round() arrondit à l'entier le plus proche : en_minutes attend un entier.
    texte = simulateur.en_minutes(round(moyenne(valeurs)))
    plage = f"{simulateur.en_minutes(min(valeurs))} à {simulateur.en_minutes(max(valeurs))}"
    texte_cible = f"{cible[0] // 60} à {cible[1] // 60} min"
    respecte = dans_cible(moyenne(valeurs), cible)
    if respecte:
        verdict = "respecté"
    else:
        verdict = "NON respecté"
    print(f"{titre} : {texte} ({plage}), cible {texte_cible} -> {verdict}")
    return respecte


def lire_arguments():
    """Lit les options de la ligne de commande (toutes facultatives)."""
    parseur = argparse.ArgumentParser(description="Vérifie le rythme visé par le GDD (issue #3).")
    parseur.add_argument("--graines", type=int, default=5, help="nombre de séries de nuits simulées (défaut : 5)")
    parseur.add_argument(
        "--duree", type=float, default=60, help="durée maximale d'une nuit en minutes (défaut : 60)"
    )
    parseur.add_argument(
        "--obstacles",
        type=float,
        nargs=2,
        metavar=("MIN", "MAX"),
        help="intervalle entre obstacles en secondes, à la place de celui de balance.json",
    )
    parseur.add_argument(
        "--balance", type=Path, default=simulateur.FICHIER_BALANCE, help="fichier de valeurs à utiliser"
    )
    return parseur.parse_args()


def main():
    arguments = lire_arguments()
    balance = simulateur.charger_balance(arguments.balance)
    simulateur.appliquer_intervalle_obstacles(balance, arguments.obstacles)
    graines = range(1, arguments.graines + 1)
    duree_s = arguments.duree * 60

    print(f"Profil moyen, {arguments.graines} séries de nuits, obstacles {simulateur.decrire_obstacles(balance)}")
    print()

    # Première nuit, simulée en entier pour repérer le premier passage en Profond.
    seuil_profond = balance["profondeur"]["paliers"][3]["seuil"]  # [3] : 4e palier, Profond
    profonds = []
    for graine in graines:
        lignes = simulateur.simuler_nuit(balance, PROFIL, duree_s, graine)
        profonds.append(simulateur.premiere_seconde(lignes, "profondeur", seuil_profond))

    # Séries de nuits : chaque élément de `series` est la liste des durées
    # des nuits d'une graine, par exemple [980, 955, 930, ...].
    series = []
    for graine in graines:
        series.append(simulateur.simuler_nuits(balance, PROFIL, NOMBRE_NUITS, graine, duree_s))

    # On regroupe par numéro de nuit : `par_nuit[0]` contient la durée de la
    # première nuit de chaque série, `par_nuit[1]` celle de la deuxième, etc.
    # Une série interrompue (nuit sans Réveil) compte comme None.
    par_nuit = []
    for numero in range(NOMBRE_NUITS):
        durees = []
        for serie in series:
            if numero < len(serie):
                durees.append(serie[numero])
            else:
                durees.append(None)
        par_nuit.append(durees)

    resultats = [
        afficher_mesure("Premier passage en Profond", profonds, CIBLE_PROFOND),
        afficher_mesure("Premier Réveil possible   ", par_nuit[0], CIBLE_PREMIER_REVEIL),
    ]

    print()
    print("Nuits suivantes : Réveil dès que possible, réminiscences gardées")
    # par_nuit[1:] : toutes les nuits sauf la première. enumerate(..., start=2)
    # numérote les éléments à partir de 2 : nuit 2, nuit 3, etc.
    for numero, durees in enumerate(par_nuit[1:], start=2):
        resultats.append(afficher_mesure(f"  nuit {numero:>2}", durees, CIBLE_NUITS_SUIVANTES))

    print()
    # sum() sur des True / False compte les True.
    print(f"{sum(resultats)} cibles respectées sur {len(resultats)}")


if __name__ == "__main__":
    main()

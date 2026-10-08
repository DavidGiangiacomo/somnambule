"""
Compare les trois profils de joueur (issue #2).

Pour chaque profil (attentif, moyen, idle pur), on simule plusieurs nuits,
chacune avec une graine de hasard différente, et on mesure quand le premier
Réveil devient possible. On vérifie ensuite les deux critères de l'issue #2 :
  - le joueur attentif progresse 2 à 4 fois plus vite que l'idle pur ;
  - l'idle pur atteint quand même un premier Réveil en moins d'une heure.

Utilisation, depuis la racine du dépôt :
    python3 simulateur/comparer_profils.py
    python3 simulateur/comparer_profils.py --obstacles 2 5 --graines 10
"""

import argparse
from pathlib import Path

import formules

# Notre fichier simulateur.py : on réutilise ses fonctions en les préfixant
# par `simulateur.`, par exemple simulateur.simuler_nuit(...).
import simulateur

# Critères de l'issue #2.
RAPPORT_MIN = 2
RAPPORT_MAX = 4
REVEIL_IDLE_MAX_S = 60 * 60  # une heure


def moyenne(valeurs):
    """Moyenne d'une liste de nombres."""
    return sum(valeurs) / len(valeurs)


def mesurer_profil(balance, profil, graines, duree_s):
    """Simule une nuit par graine pour un profil.

    Renvoie deux valeurs :
      - la liste des secondes du premier Réveil, une par graine (None pour une
        nuit où le Réveil n'est jamais devenu possible) ;
      - la profondeur moyenne, toutes nuits confondues.
    """
    reveils = []
    profondeurs = []
    for graine in graines:
        lignes = simulateur.simuler_nuit(balance, profil, duree_s, graine)
        reveils.append(simulateur.premiere_seconde(lignes, "reminiscences", 1))
        profondeurs.append(simulateur.profondeur_moyenne(lignes))
    # `return a, b` renvoie deux valeurs d'un coup ; l'appelant les récupère
    # avec `x, y = mesurer_profil(...)`.
    return reveils, moyenne(profondeurs)


def decrire_reveils(reveils):
    """Résume les premiers Réveils d'un profil : "6 min 18 s (5 min 50 s à 7 min 02 s)"."""
    if None in reveils:
        return "jamais sur au moins une nuit"
    # round() arrondit à l'entier le plus proche : en_minutes attend un entier.
    texte = simulateur.en_minutes(round(moyenne(reveils)))
    return f"{texte} ({simulateur.en_minutes(min(reveils))} à {simulateur.en_minutes(max(reveils))})"


def verdict(respecte):
    """Transforme True / False en texte lisible."""
    if respecte:
        return "respecté"
    return "NON respecté"


def afficher_criteres(resultats):
    """Vérifie et affiche les deux critères de l'issue #2."""
    reveils_attentif = resultats["attentif"][0]  # [0] : la liste des Réveils
    reveils_idle = resultats["idle"][0]

    # Critère 1. « Deux fois plus vite » veut dire « en deux fois moins de
    # temps » : le rapport de vitesse est donc le temps de l'idle pur divisé
    # par celui de l'attentif, pour atteindre le même objectif (le premier
    # Réveil).
    if None in reveils_attentif or None in reveils_idle:
        print("Rapport de vitesse attentif / idle pur : incalculable, un Réveil n'est jamais arrivé.")
        print("  Allongez la nuit avec --duree.")
    else:
        rapport = moyenne(reveils_idle) / moyenne(reveils_attentif)
        respecte = RAPPORT_MIN <= rapport <= RAPPORT_MAX
        texte = f"{rapport:.1f}".replace(".", ",")
        print(f"Rapport de vitesse attentif / idle pur : {texte} (cible : {RAPPORT_MIN} à {RAPPORT_MAX})")
        print(f"  -> {verdict(respecte)}")

    # Critère 2. Toutes les nuits de l'idle pur doivent atteindre le Réveil
    # en moins d'une heure, pas seulement la moyenne.
    # all(...) vaut True si la condition est vraie pour chaque élément.
    respecte = all(r is not None and r < REVEIL_IDLE_MAX_S for r in reveils_idle)
    print("Idle pur : premier Réveil en moins d'une heure sur toutes les nuits")
    print(f"  -> {verdict(respecte)}")


def lire_arguments():
    """Lit les options de la ligne de commande (toutes facultatives)."""
    parseur = argparse.ArgumentParser(description="Compare les trois profils de joueur (issue #2).")
    parseur.add_argument("--graines", type=int, default=5, help="nombre de nuits simulées par profil (défaut : 5)")
    parseur.add_argument(
        "--duree", type=float, default=120, help="durée maximale d'une nuit en minutes (défaut : 120)"
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

    # range(1, n + 1) donne les entiers de 1 à n : les graines 1, 2, ..., n.
    graines = range(1, arguments.graines + 1)
    duree_s = arguments.duree * 60

    print(f"{arguments.graines} nuits par profil, obstacles {simulateur.decrire_obstacles(balance)}")
    print()
    print(f"{'Profil':<10} {'Profondeur moyenne':<25} Premier Réveil (moyenne, min à max)")

    # On range les résultats de chaque profil dans un dictionnaire
    # {"attentif": (reveils, profondeur), ...} pour vérifier les critères ensuite.
    resultats = {}
    # .items() parcourt un dictionnaire en donnant à la fois la clé et la valeur.
    for cle, profil in simulateur.PROFILS.items():
        reveils, profondeur = mesurer_profil(balance, profil, graines, duree_s)
        resultats[cle] = (reveils, profondeur)

        palier = formules.palier(profondeur, balance)["nom"]
        texte_profondeur = f"{profondeur:.1f} ({palier})".replace(".", ",")
        print(f"{profil['nom']:<10} {texte_profondeur:<25} {decrire_reveils(reveils)}")

    print()
    afficher_criteres(resultats)


if __name__ == "__main__":
    main()

shader_type canvas_item;
// Fait onduler le décor quand le sommeil s'approfondit : le pied de chaque
// forme reste posé au sol, son sommet se balance de gauche à droite.

// Balancement, en pixels, d'un point situé `hauteur_de_reference` au-dessus
// du sol. À 0, le décor est immobile.
uniform float amplitude = 0.0;
uniform float y_sol = 864.0;
uniform float hauteur_de_reference = 400.0;
uniform float vitesse = 1.2;

void vertex() {
	float hauteur = max(y_sol - VERTEX.y, 0.0) / hauteur_de_reference;
	// VERTEX.x décale le rythme d'une forme à l'autre : elles ne bougent pas
	// toutes ensemble.
	VERTEX.x += sin(TIME * vitesse + VERTEX.x * 0.01) * amplitude * hauteur;
}

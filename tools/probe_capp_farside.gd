extends Node
## PROFILUL VAII PE EXTERIOR, si unde ar trebui sa stea peretele de dincolo.
##
## Runda 10, verdictul amandurora criticilor: ochiul merge de la marginea
## drumului pana la cer fara sa treaca peste NICIO suprafata verticala pe
## jumatatea dreapta. Lead-ul a masurat cauza in captura: caderea EXISTA, dar
## malul de dincolo urca inapoi la aceeasi inaltime pe ecran, deci se citeste un
## singur plan continuu, si baloanele stau LA SI PESTE linia orizontului.
##
## Sonda asta masoara trei lucruri pe care se poate dimensiona un perete:
##   1. profilul terenului pe rulaj lateral spre exterior, 0..250 m;
##   2. UNGHIUL fiecarui punct fata de ochiul soferului (negativ = sub orizont);
##   3. plafonul de cadru la distanta aia (conul camerei: 10 + 0.093*d peste ochi),
##      ca sa se stie cat de inalt poate fi peretele fara sa iasa din cadru.
##
## Regula de citire: un perete TAIE ORIZONTUL doar daca unghiul coamei lui e
## POZITIV. Orice masa cu unghi negativ e o dunga la baza cerului, oricat de mare.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const EYE_M: float = 6.0  # inaltimea camerei de urmarire peste asfalt
const FRACS: Array[float] = [0.20, 0.24, 0.28, 0.32]

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== PROFIL EXTERIOR (dreapta), ochi la %.1f m peste asfalt ===" % EYE_M)
	for f in FRACS:
		_profile(f)
	get_tree().quit(0)


func _profile(frac: float) -> void:
	var route := _track.route_at(0)
	var n := route.count()
	var idx := clampi(int(round(frac * float(n))), 0, n - 1)
	var c := _track.point_at(idx)
	var side := route.side_at(idx)
	var sampler := _track._sampler as TrackSideSampler
	var eye_y := c.y + EYE_M
	print("  --- frac %.2f: ax la (%.0f,%.1f,%.0f) ---" % [frac, c.x, c.y, c.z])
	var best_ang := -1e9
	var best_d := 0.0
	for d in [10.0, 20.0, 30.0, 40.0, 60.0, 80.0, 100.0, 130.0, 160.0, 200.0, 250.0]:
		var p: Vector3 = c + side * d
		var y: float = sampler.ground_y(p.x, p.z)
		var ang := rad_to_deg(atan2(y - eye_y, d))
		# plafonul cadrului: cat de sus peste ochi mai incape la distanta d
		var ceil_y: float = eye_y + 10.0 + 0.093 * d
		if ang > best_ang:
			best_ang = ang
			best_d = d
		print("    %6.0f m: teren y=%7.2f (dy=%+7.2f)  unghi %+6.1f gr   plafon cadru y=%7.2f (mai incap %+6.2f m)"
			% [d, y, y - c.y, ang, ceil_y, ceil_y - y])
	print("    cel mai inalt: %+.1f gr la %.0f m  -> %s"
		% [best_ang, best_d, "TAIE ORIZONTUL" if best_ang > 0.0 else "SUB ORIZONT (dunga la baza cerului)"])

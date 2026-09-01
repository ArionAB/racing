extends Node
## Panta MEDIE a spiralei din stanca goala (Cappadocia, POI G).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHelixGrade.tscn ##       -- --track=6 --center=-302.02,6
##
## ATENTIE: `--center` NU e optional pe Track13, desi sonda porneste si fara el.
## Fara centru cauta elicea intr-un inel in jurul originii, nu gaseste nimic,
## tipareste "nu am gasit elicea (0 puncte in inel)" si IESE CU 0 — adica trece
## tacut fara sa masoare. Centrul e pozitia nodului `StancaGoalaInterior` din
## Track13.tscn (azi -302.02, 6). Daca stanca se muta, se muta si aici.
## Cifra corecta, verificata: PANTA MEDIE 9.52 % (bara 13.00), arc 375.6 m.
##
## De ce exista, separat de ProbeLayout: ProbeLayout tipareste panta MAXIMA
## intre doua puncte coapte vecine, care pe o elice e zgomot de esantionare
## (un pas de 3 m prinde si o cocoasa de racord). Bara ceruta de dezvoltator
## e alta: MEDIA pe toata spirala sub 13%. Media se citeste pe lungimea de
## ARC — 2*PI*r*ture — nu pe coarda, si de aceea capcana traseului era ca
## elicei i se dadeau 280 m de tur (13.6%) in loc de cei 352 m ai arcului.
##
## Portiunea de elice se afla singura: punctele coapte care stau in cilindrul
## stancii (raza +- o marja) SI urca monoton.

## Cat de aproape de raza nominala trebuie sa fie un punct ca sa fie "pe elice".
const RADIUS_TOL: float = 4.0


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	var cx := 0.0
	var cz := 0.0
	var rad := 28.0
	var has_center := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--center="):
			var p := arg.trim_prefix("--center=").split(",")
			if p.size() >= 2:
				cx = float(p[0])
				cz = float(p[1])
				has_center = true
		elif arg.begins_with("--radius="):
			rad = float(arg.trim_prefix("--radius="))
	if idx < 0:
		push_error("ProbeHelix: index de pista invalid")
		get_tree().quit(1)
		return

	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var r := track.routes[0]
	var n := r.baked.size()
	if not has_center:
		cx = 0.0
		cz = 0.0
		push_warning("ProbeHelix: fara --center, se presupune originea")

	# --- felia de elice: puncte in inelul cilindrului, in ordine ------------
	var on: Array[int] = []
	for i in n:
		var p := r.baked[i]
		var d := Vector2(p.x - cx, p.z - cz).length()
		if absf(d - rad) <= RADIUS_TOL:
			on.append(i)
	if on.size() < 8:
		print("ProbeHelix: nu am gasit elicea (%d puncte in inel, centru %.1f,%.1f raza %.1f)"
			% [on.size(), cx, cz, rad])
		get_tree().quit(1)
		return

	# cea mai lunga insiruire continua de indici (elicea e un tronson)
	var best_a := 0
	var best_b := 0
	var a := 0
	for k in range(1, on.size()):
		if on[k] != on[k - 1] + 1:
			if on[k - 1] - on[a] > best_b - best_a:
				best_a = a
				best_b = k - 1
			a = k
	if on[on.size() - 1] - on[a] > best_b - best_a:
		best_a = a
		best_b = on.size() - 1
	var i0 := on[best_a]
	var i1 := on[best_b]

	# --- masuratorile ------------------------------------------------------
	var arc := 0.0
	var max_s := 0.0
	var max_at := 0.0
	for i in range(i0, i1):
		var d := r.baked[i].distance_to(r.baked[i + 1])
		arc += d
		if d > 0.01:
			var s := absf(r.baked[i + 1].y - r.baked[i].y) / d
			if s > max_s:
				max_s = s
				max_at = r.frac_at(i)
	var dy := r.baked[i1].y - r.baked[i0].y
	var avg := 0.0 if arc < 0.01 else absf(dy) / arc

	print("")
	print("=== %s — spirala din stanca goala ===" % track.track_name)
	print("  centru (%.1f, %.1f)  raza nominala %.1f m" % [cx, cz, rad])
	print("  frac %.3f -> %.3f   (%d puncte coapte)"
		% [r.frac_at(i0), r.frac_at(i1), i1 - i0 + 1])
	print("  cota      %.2f m -> %.2f m   (urcare %.2f m)"
		% [r.baked[i0].y, r.baked[i1].y, dy])
	print("  lungime de ARC          %8.1f m" % arc)
	print("  PANTA MEDIE             %8.2f %%   (bara: 13.00)" % (avg * 100.0))
	print("  panta maxima pe pas     %8.2f %% la frac %.3f" % [max_s * 100.0, max_at])
	var turns := arc / (TAU * rad)
	print("  ture                    %8.2f      pas vertical %.2f m/tura"
		% [turns, dy / maxf(turns, 0.01)])
	print("")
	var ok := avg * 100.0 <= 13.0
	print("VERDICT: %s" % ("OK" if ok else "PROBLEMA (panta medie peste 13%)"))
	get_tree().quit(0 if ok else 1)

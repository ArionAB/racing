extends Node
## Cat de departe e APA de sosea, masurat in metri, pe ambele laturi.
##
## Sonda s-a nascut dintr-o neintelegere scumpa: brief-ul Stromboli cere la POI
## B "marea pe langa drum, fara parapet, intri in mare -> repunere", iar o
## captura statica parea sa confirme. Masurat, apa era la 78-98 m de asfalt —
## nu puteai fizic sa cazi in ea. O captura arata ce cauti tu; cifra asta arata
## ce e acolo.
##
##   godot --headless --path . res://tools/ProbeShore.tscn -- --track=4
##   ... --track=8 --fracs=0.05,0.09,0.20
##
## `--track=` ia pozitia din GameState.TRACK_SCENES (Stromboli 4, Okinawa 1),
## dar accepta si numarul scenei (--track=11). Parametrizata ca sa poata masura
## SI pistele pe care nu le schimbam: o reparatie pe Stromboli nu e dovedita
## pana nu arati ca Okinawa a ramas pe aceleasi cifre.

## Cat de sus fata de nivelul marii mai numaram "apa". Panta de tarm intra lin,
## deci un prag exact pe linia apei ar rata primul metru de plaja uda.
const WATER_EPS: float = 0.3
## Pana unde cautam lateral. Peste atat raspunsul e "nu e apa pe langa drum",
## si nu conteaza daca sunt 260 sau 400 m.
const MAX_DIST: int = 260


func _ready() -> void:
	var index := 4
	var fracs: Array[float] = [0.05, 0.07, 0.09, 0.11]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--fracs="):
			fracs.clear()
			for piece in arg.trim_prefix("--fracs=").split(",", false):
				fracs.append(clampf(float(piece), 0.0, 1.0))
	var resolved := GameState.resolve_track_index(index)
	if resolved < 0:
		push_error("probe_shore: --track=%d nu e nici pozitie in lista (0..%d), nici numar de pista din lista."
			% [index, GameState.TRACK_SCENES.size() - 1])
		get_tree().quit(1)
		return
	if fracs.is_empty():
		push_error("probe_shore: --fracs= nu a dat nicio fractie valida")
		get_tree().quit(1)
		return

	var t := (load(GameState.TRACK_SCENES[resolved]) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame

	var sp: TrackSideSampler = t._sampler
	var sea: float = sp.mean_road_y() + t.sea_level_offset
	print("SHORE: %s — nivelul marii y = %.2f"
		% [GameState.track_label(resolved), sea])
	var n := t.baked.size()
	for f in fracs:
		var i := int(f * float(n)) % n
		var p: Vector3 = t.baked[i]
		var j := (i + 4) % n
		var dir: Vector3 = t.baked[j] - p
		dir.y = 0.0
		dir = dir.normalized()
		var out := ""
		for sgn in [1.0, -1.0]:
			var side := Vector3(dir.z * sgn, 0.0, -dir.x * sgn)
			var found := -1.0
			for d in range(3, MAX_DIST):
				var q: Vector3 = p + side * float(d)
				if sp.ground_y(q.x, q.z) <= sea + WATER_EPS:
					found = float(d)
					break
			out += "  %s=%s" % ["dr" if sgn > 0 else "st",
				("%.0f m" % found) if found > 0 else (">%d" % (MAX_DIST - 2))]
		print("SHORE: frac %.2f  y=%.2f %s" % [f, p.y, out])
	get_tree().quit()

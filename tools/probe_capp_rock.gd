extends Node
## Profilul stancii goale: e plina pe dinafara si goala pe dinauntru?
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappRock.tscn -- --track=6
##
## Taie campul de teren pe raze care pleaca din axa elicei si tipareste cota la
## fiecare 4 m. Doua intrebari, amandoua obligatorii:
##   - INAUNTRU (r < raza elicei) terenul sta la podea, ca spirala sa incapa;
##   - AFARA (r > raza stancii) masivul se ridica la ~70 m latime de baza, ca
##     stanca sa citeasca plin din vale.
## Fara a doua, "am reparat ingroparea" ar putea sa insemne "am sters muntele".

const AXIS := Vector2(-302.02, 6.00)
## Raza pana la care terenul TREBUIE sa ramana jos (elicea + carosabil).
const INNER_R: float = 34.0
## Cat de sus trebuie sa urce creasta masivului fata de podeaua hornului.
const MIN_WALL_RISE: float = 20.0


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var s: TrackSideSampler = track.get("_sampler")

	print("")
	print("=== Stanca goala — profil radial din axa elicei (%.1f, %.1f) ==="
		% [AXIS.x, AXIS.y])
	var header := "  r(m) "
	for deg in range(0, 360, 45):
		header += "  %4d" % deg
	print(header)
	var inner_max := -INF
	var crest: Array[float] = []
	for d in range(0, 8):
		crest.append(-INF)
	var r := 0.0
	while r <= 120.0:
		var line := "  %4.0f " % r
		var k := 0
		for deg in range(0, 360, 45):
			var a := deg_to_rad(float(deg))
			var y := s.ground_y(AXIS.x + r * cos(a), AXIS.y + r * sin(a))
			line += " %5.1f" % y
			if r <= INNER_R:
				inner_max = maxf(inner_max, y)
			crest[k] = maxf(crest[k], y)
			k += 1
		print(line)
		r += 8.0

	var floor_y := 11.0
	var rise := -INF
	for c in crest:
		rise = maxf(rise, c - floor_y)
	print("")
	print("  interiorul (r <= %.0f m): cel mai inalt teren %.2f m" % [INNER_R, inner_max])
	print("  creasta masivului: cea mai mare urcare fata de podea %+.2f m" % rise)
	var ok_in := inner_max <= 12.0
	var ok_out := rise >= MIN_WALL_RISE
	print("")
	print("  gol pe dinauntru : %s" % ("OK" if ok_in else "PROBLEMA"))
	print("  plin pe dinafara : %s" % ("OK" if ok_out else "PROBLEMA (masivul a disparut)"))
	print("VERDICT: %s" % ("OK" if ok_in and ok_out else "PROBLEMA"))
	get_tree().quit(0 if ok_in and ok_out else 1)

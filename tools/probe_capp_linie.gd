extends Node
## Linia crestei exterioare, punct cu punct, pe POI B.
##
## Da coordonatele LUMII pentru un sir de module asezate paralel cu banda, pe
## umarul exterior, la o distanta ceruta. Pentru fiecare: pozitia, cota
## terenului, cota drumului, si cat de inalt poate fi modulul ca varful lui sa
## ramana in cadru (plafonul 2.6 + 10 + 0.093*d fata de camera).
##
## Exista fiindca "pune un perete la 40 m in dreapta" nu e o instructiune pana
## nu stii ce cota are terenul acolo: pe POI B dreapta cade la -22 m, deci un
## perete de 12 m asezat pe teren are varful tot SUB sosea si nu taie nimic.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappLinie.tscn -- --track=6 --dist=38

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	var dist := 38.0
	var f0 := 0.075
	var f1 := 0.185
	var step := 0.005
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--dist="):
			dist = float(arg.trim_prefix("--dist="))
		elif arg.begins_with("--from="):
			f0 = float(arg.trim_prefix("--from="))
		elif arg.begins_with("--to="):
			f1 = float(arg.trim_prefix("--to="))
		elif arg.begins_with("--step="):
			step = float(arg.trim_prefix("--step="))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sampler: TrackSideSampler = track._sampler
	var n := track.baked.size()
	print("")
	print("=== linia crestei la %.0f m in DREAPTA benzii ===" % dist)
	print("  frac      x        z     teren   drum   dh(teren-drum)  h_max_in_cadru")
	var f := f0
	while f <= f1 + 0.0001:
		var i := int(f * float(n)) % n
		var p := track.baked[i]
		var s := track._side_at(i)
		var q := p + s * dist
		var g := sampler.ground_y(q.x, q.z)
		# Cat de inalt poate fi modulul de la BAZA lui (pe teren) ca varful sa
		# ramana sub plafonul cadrului.
		var ceiling := p.y + 2.6 + 10.0 + 0.093 * dist
		print("  %.3f  %7.1f  %7.1f  %7.2f  %6.2f   %+7.2f      %6.2f" % [
			f, q.x, q.z, g, p.y, g - p.y, ceiling - g])
		f += step
	print("")
	get_tree().quit(0)

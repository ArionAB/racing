extends Node
## Unde poate sta o CREASTA care taie orizontul, pe POI B (fracii 0.10-0.16).
##
## De ce exista. Runda 10: amandoi criticii cer o suprafata verticala pe umarul
## exterior, destul de inalta cat sa acopere linia orizontului. Ca s-o asezi
## trebuie sa stii trei lucruri pe care nicio sonda de pana acum nu le da
## impreuna:
##   (a) cota terenului LATERAL pana la 70 m (probe_capp_b se opreste la 16),
##       fiindca baza crestei sta pe teren, nu la cota drumului;
##   (b) IN CE PARTE e valea — creasta se pune pe umarul exterior, iar "dreapta"
##       depinde de sensul benzii, nu de axa lumii;
##   (c) plafonul de cadru: camera vede pana la 10 + 0.093*d deasupra ei, deci o
##       creasta la 40 m poate urca ~14 m peste drum inainte sa iasa din poza.
##       Peste plafon creasta exista si NU se vede — exact felul de efect care
##       trece o sonda si lipseste din cadru.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappCreasta.tscn -- --track=6

const DIST: Array[float] = [15.0, 25.0, 35.0, 45.0, 60.0, 80.0]


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sampler: TrackSideSampler = track._sampler
	var n := track.baked.size()
	print("")
	print("=== profil lateral larg, POI B ===")
	print("  (dreapta = +side; cotele sunt ABSOLUTE, y_drum e cota benzii)")
	print("")
	var f := 0.080
	while f <= 0.185:
		var i := int(f * float(n)) % n
		var p := track.baked[i]
		var s := track._side_at(i)
		print("  frac %.3f  i=%4d  drum=(%.1f, %.2f, %.1f)  side=(%.2f, %.2f)  w=%.1f" % [
			f, i, p.x, p.y, p.z, s.x, s.z, track.width_at_index(i)])
		var ls := "     stanga :"
		var rs := "     dreapta:"
		for d: float in DIST:
			var gl := sampler.ground_y(p.x - s.x * d, p.z - s.z * d)
			var gr := sampler.ground_y(p.x + s.x * d, p.z + s.z * d)
			ls += "  %3.0fm %+7.2f" % [d, gl - p.y]
			rs += "  %3.0fm %+7.2f" % [d, gr - p.y]
		print(ls)
		print(rs)
		# Plafonul de cadru: cat de sus poate urca ceva la distanta d si sa
		# ramana in poza. Camera sta ~2.6 m peste banda.
		var pl := "     plafon :"
		for d: float in DIST:
			pl += "  %3.0fm %+7.2f" % [d, 2.6 + 10.0 + 0.093 * d]
		print(pl)
		f += 0.010
	print("")
	get_tree().quit(0)

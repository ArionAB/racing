extends Node
## De ce fata taieturii ajunge la -13,5 m de marginea asfaltului cand
## `cut_offset_m` e 7,6 si semi-latimea 6,0 (deci ar trebui -1,6 m).
##
## Reface, pas cu pas, aritmetica din `_cut_column` pe cateva coloane reale si
## tipareste FIECARE termen: offset, batter, tread, tuck, facet. Termenul care
## domina e raspunsul. Memoria `justificarea-din-comentariu-se-verifica`:
## comentariul spune "peretele sta LANGA banda", masuratoarea spune altceva.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var fal := _track.get_node_or_null("Faleze")
	for nod in fal.get_children():
		var cf := nod as CliffFace
		if cf == null or not cf.cut_wall: continue
		print("=== ", nod.name, " offset=%.2f batter=%.2f tread=%.2f bands=%d tuck=%.1f facet=%.2f cols=%d taper=%.2f" % [cf.cut_offset_m, cf.cut_batter_m, cf.cut_tread_m, cf.cut_bands, cf.cut_tuck_m, cf.cut_facet_m, cf.cut_facet_cols, cf.cut_taper_frac])
		var span_f: float = cf.frac_end - cf.frac_start
		for u: float in [0.1, 0.3, 0.5, 0.7, 0.9]:
			var f: float = cf.frac_start + span_f * u
			var edge: float = minf(f - cf.frac_start, cf.frac_end - f)
			var taper: float = smoothstep(0.0, 1.0, clampf(edge / maxf(cf.cut_taper_frac * span_f, 1e-5), 0.0, 1.0))
			var tuck: float = (1.0 - taper) * cf.cut_tuck_m
			# la COAMA (r=0, t=0): back = batter, tread = cut_tread_m*bands
			var back_crown: float = cf.cut_batter_m
			var tread_crown: float = cf.cut_tread_m * float(cf.cut_bands)
			# la TALPA (r=bands, t=1): back = 0, tread = 0
			var facet_max: float = cf.cut_facet_m
			var tot_crown: float = cf.cut_offset_m + back_crown + tread_crown + tuck
			var tot_foot: float = cf.cut_offset_m + 0.0 + 0.0 + tuck
			print("  u=%.1f frac=%.3f taper=%.2f tuck=%5.2f | de la AX: coama %.2f  talpa %.2f  (+facet <=%.2f)" % [u, f, taper, tuck, tot_crown, tot_foot, facet_max])
	print("")
	print("NOTA: cifrele de mai sus sunt de la AX. Semi-latimea pe interval e 6,00-6,50,")
	print("deci de la MARGINE se scade aia. Daca suma nu ajunge la 13,5, termenul lipsa")
	print("nu e in aritmetica asta.")
	get_tree().quit(0)

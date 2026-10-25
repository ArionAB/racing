extends Node
## Harta curbei COAPTE a pistei Carrara pentru generatorul de scena:
##   (x, z, fractie pe INDEX, fractie pe LUNGIME) pentru fiecare punct copt.
##
##   godot --headless --path . res://tools/ProbeCarraraFracmap.tscn
##
## De ce: motorul foloseste doua fractii (memoria `fractia-pe-index-vs-pe-lungime`) — idx = i/n
## (latimi, praf, ud) si len = _dists[i]/total (rape, parapete, zone de sol) — si ele diverg pe
## curba coapta (punctele se indesesc in viraje). `tools/gen_carrara_route.py` citeste fisierul
## si scrie fiecare interval in fractia pe care o asteapta consumatorul lui. Doua treceri:
## generator (aproximativ) -> aceasta sonda -> generator (exact). Punctele de control nu se
## schimba intre treceri, deci harta ramane valabila cat timp traseul nu se muta.
## (tools/data are .gdignore: .tsv nu e importat ca resursa.)

func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track23.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var dd: PackedFloat32Array = track.get("_dists")
	var f := FileAccess.open("res://tools/data/carrara_fracmap.tsv", FileAccess.WRITE)
	for i in n:
		var p: Vector3 = r.baked[i]
		f.store_line("%.3f %.3f %.6f %.6f" % [p.x, p.z, float(i) / float(n), dd[i] / dd[n]])
	f.close()
	print("carrara_fracmap: %d puncte coapte, lungime %.1f m" % [n, r.length()])
	get_tree().quit()

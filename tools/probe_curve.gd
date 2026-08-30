extends Node
## Cat de mult COTESTE cornisa, si incotro.
##
## Contextul: fata falezei e vazuta la 83 de grade fata de normala (pe muchie)
## din camera de joc. Asta e o proprietate a unei cornise DREPTE — mergi
## paralel cu peretele, deci nu ai cum sa-l vezi in plin. Referinta arata altfel
## fiindca drumul COTESTE: vezi peretele portiunii DE DINAINTE.
##
## Deci intrebarea nu mai e „ce culoare are peretele", ci „exista un viraj care
## sa-l intoarca spre camera?". Aici se masoara curbura pe sectorul de cornisa.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	var route := t.route_at(0)
	var pts := route.baked
	var n := pts.size()
	print("=== curbura pe cornisa (0.185..0.38), semn + = coteste spre DREAPTA ===")
	var f := 0.185
	while f <= 0.381:
		var i := int(f * float(n)) % n
		var a: Vector3 = pts[route.wrap_index(i - 10)]
		var b: Vector3 = pts[i]
		var c: Vector3 = pts[route.wrap_index(i + 10)]
		var d1 := (b - a); d1.y = 0.0; d1 = d1.normalized()
		var d2 := (c - b); d2.y = 0.0; d2 = d2.normalized()
		var cross := d1.x * d2.z - d1.z * d2.x
		var ang := rad_to_deg(asin(clampf(-cross, -1.0, 1.0)))
		var lbl := "drept"
		if ang > 3.0:
			lbl = "DREAPTA (spre vale)"
		elif ang < -3.0:
			lbl = "stanga (spre deal)"
		print("  frac %.3f  cota %6.2f   viraj %+6.1f gr / 20 pasi   %s" % [f, b.y, ang, lbl])
		f += 0.0125
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

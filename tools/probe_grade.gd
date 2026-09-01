extends Node
## Panta pe curba COAPTA, nu pe punctele de control.
##
## De ce exista: pe serpentina noua, aritmetica pe punctele de control dadea
## 21.6% si ProbeLayout masura 23.9%. Diferenta nu e o eroare de rotunjire, e
## Catmull-Rom: intre doua puncte de control curba trage mai sus/mai jos decat
## coarda, deci panta LOCALA de pe coapta poate depasi panta medie a segmentului.
## Ca sa nu mai reglez in orb, tiparesc chiar sirul pe care il citeste garda.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var curve: Curve3D = (t.get_node("Path") as Path3D).curve
	var total := curve.get_baked_length()
	var pts := curve.get_baked_points()
	var n := pts.size()
	print("baked puncte %d, lungime %.1f" % [n, total])
	var worst := 0.0
	var worst_f := 0.0
	for i in n - 1:
		var d := pts[i].distance_to(pts[i + 1])
		if d < 0.01:
			continue
		var s: float = absf(pts[i + 1].y - pts[i].y) / d
		var f := float(i) / float(n)
		if s > worst:
			worst = s
			worst_f = f
		if f > 0.20 and f < 0.30 and s > 0.19:
			print("  frac %.4f  y %6.2f  panta %5.1f%%" % [f, pts[i].y, s * 100.0])
	print("MAX %.1f%% la frac %.4f" % [worst * 100.0, worst_f])
	get_tree().quit()

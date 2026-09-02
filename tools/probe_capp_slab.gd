extends Node
## CE e lespedea care pluteste in cadrul de la fractia 0.235.
##
## Doua incercari au fost cheltuite pe presupuneri (politele falezei), si
## capturile au iesit IDENTICE pixel cu pixel dupa ce cifrele politelor chiar se
## imbunatatisera de 3.8 ori. Adica obiectul din poza nu era cel reparat —
## capcana scrisa deja in `_quad`: „nu se vede" arata la fel ca „nu s-a
## construit".
##
## Deci nu se mai ghiceste: se trag raze prin cadru din ochiul real si se
## tipareste CINE e lovit, cu nod si cota. Raspunsul vine din scena, nu din cap.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const FRAC: float = 0.235
const EYE_M: float = 1.5

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var route := _track.route_at(0)
	var n := route.count()
	var idx := clampi(int(round(FRAC * float(n))), 0, n - 1)
	var c := _track.point_at(idx)
	var fwd := (_track.point_at((idx + 6) % n) - c).normalized()
	var eye := c + Vector3.UP * EYE_M
	print("=== CE E IN CADRU la frac %.3f (ochi %.1f m) ===" % [FRAC, EYE_M])
	# Nodurile VIZUALE nu au coliziune (falezele sunt doar mesh), deci razele
	# n-ar gasi nimic. Se cauta direct in arbore: orice MeshInstance3D al carui
	# AABB in lume e in fata ochiului si peste linia lui.
	var hits: Array = []
	_scan(_track, eye, fwd, hits)
	hits.sort_custom(func(a, b): return a["d"] < b["d"])
	for h in hits.slice(0, 26):
		print("  %6.1f m  y=%6.1f..%6.1f  %s"
			% [h["d"], h["lo"], h["hi"], h["path"]])
	get_tree().quit(0)


func _scan(node: Node, eye: Vector3, fwd: Vector3, out: Array) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null and mi.visible:
		var ab := mi.global_transform * mi.mesh.get_aabb()
		var ctr := ab.position + ab.size * 0.5
		var to := ctr - eye
		var d := to.length()
		# in fata, in con de ~40 de grade, si aproape
		if d < 140.0 and to.normalized().dot(fwd) > 0.30:
			out.append({
				"d": d, "lo": ab.position.y, "hi": ab.position.y + ab.size.y,
				"path": str(_track.get_path_to(mi)),
			})
	for ch in node.get_children():
		_scan(ch, eye, fwd, out)

extends Node
## ACELASI frac, DOUA pozitii diferite — care e cea fotografiata?
##
## Sondele folosesc route.count() cu round(), Snapshot foloseste route.baked cu
## int(). Daca cele doua liste au lungimi diferite, "fractia 0.32" din sonda si
## "fractia 0.32" din captura sunt doua locuri de pe pista, si noua runde de
## masuratori s-au comparat cu capturi facute in alta parte.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const FRACS: Array[float] = [0.20, 0.28, 0.32]

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var route := _track.route_at(0)
	var n_count := route.count()
	var n_baked := route.baked.size()
	print("=== count()=%d   baked.size()=%d ===" % [n_count, n_baked])
	for f in FRACS:
		var i_probe := clampi(int(round(f * float(n_count))), 0, n_count - 1)
		var i_snap := int(f * float(n_baked)) % n_baked
		var p_probe := _track.point_at(i_probe)
		var p_snap: Vector3 = route.baked[i_snap]
		print("  frac %.2f: sonda idx %d (%.0f,%.1f,%.0f) | snapshot idx %d (%.0f,%.1f,%.0f) | distanta %.1f m"
			% [f, i_probe, p_probe.x, p_probe.y, p_probe.z,
			i_snap, p_snap.x, p_snap.y, p_snap.z, p_probe.distance_to(p_snap)])
	get_tree().quit(0)

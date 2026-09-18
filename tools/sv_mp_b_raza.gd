extends Node
## Ce vede soferul lateral, prin RAZE ORIZONTALE — nu prin AABB (un AABB peste
## 50 m de curba proiectat pe o singura normala e fara sens) si nu prin campul
## de inaltime (memoria terrain-mesh-y-extrapoleaza).
##
## Din punctul de ochi (ax + 1,6 m, inaltimea capotei) trage o raza pe normala
## laterala in fiecare parte si raporteaza: la ce DISTANTA de marginea asfaltului
## intalneste ceva, si CE corp e. Asta e cifra din verdict: "stanca sta la 20+ m
## in stanga, separata de asfalt" vs "peretele porneste chiar din marginea
## drumului (zero umar)".
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var n := _track.baked.size()
	print("=== POI B — raze orizontale din ochiul soferului (ax +1,6 m) ===")
	print("distanta e de la MARGINEA asfaltului, nu de la ax. '--' = nimic pe 60 m.")
	print("")
	print("frac   semi | STANGA dist / corp                | DREAPTA dist / corp")
	for f in range(40, 212, 6):
		var frac := float(f) / 1000.0
		var idx := int(round(frac * float(n))) % n
		var bp: Vector3 = _track.baked[idx]
		var dir: Vector3 = (_track.baked[(idx + 1) % n] - bp); dir.y = 0.0
		if dir.length() < 0.001: continue
		var lat := dir.normalized().cross(Vector3.UP).normalized()
		var w := _track.width_at_index(idx)
		var eye := bp + Vector3(0, 1.6, 0)
		var st := _ray(eye, -lat, w)
		var dr := _ray(eye, lat, w)
		print("%.3f %5.2f | %-34s | %s" % [frac, w, st, dr])
	# A doua trecere: si la +6 m (inaltimea camerei de urmarire), ca sa se vada
	# daca peretele are INALTIME peste linia ochiului sau doar prispa.
	print("")
	print("=== aceleasi raze, dar de la +6,0 m (camera de urmarire) ===")
	print("frac   semi | STANGA                            | DREAPTA")
	for f in range(40, 212, 6):
		var frac := float(f) / 1000.0
		var idx := int(round(frac * float(n))) % n
		var bp: Vector3 = _track.baked[idx]
		var dir: Vector3 = (_track.baked[(idx + 1) % n] - bp); dir.y = 0.0
		if dir.length() < 0.001: continue
		var lat := dir.normalized().cross(Vector3.UP).normalized()
		var w := _track.width_at_index(idx)
		var eye := bp + Vector3(0, 6.0, 0)
		print("%.3f %5.2f | %-34s | %s" % [frac, w, _ray(eye, -lat, w), _ray(eye, lat, w)])
	get_tree().quit(0)

func _ray(from: Vector3, d: Vector3, w: float) -> String:
	var sp := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + d * 60.0)
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	if r.is_empty(): return "  --"
	var hit: Vector3 = r["position"]
	var col: Object = r["collider"]
	var nm := "?" if col == null else str((col as Node).name)
	return "%5.2f m  %s" % [from.distance_to(hit) - w, nm]

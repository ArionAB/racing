extends Node
## Sub ce UNGHI vede camera fata falezei.
##
## O panza poate fi in cadru, neascunsa, si tot invizibila: daca normala ei e
## aproape perpendiculara pe privire, suprafata proiectata tinde la zero — o
## „ata", exact cum arata capturile. Aici se masoara unghiul dintre directia de
## privire si normala fetei, mediat pe panza.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var mis: Array[Node] = []
	_walk(t, mis)
	var route := t.route_at(0)
	var pts := route.baked
	var n := pts.size()
	for f: float in [0.22, 0.28, 0.34]:
		var idx := int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		var eye := focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		var buckets := {"fata (<50 gr)": 0, "oblic (50-75)": 0, "muchie (>75)": 0}
		var cnt := 0
		var sum := 0.0
		for m in mis:
			var mi := m as MeshInstance3D
			var arr := mi.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var step := maxi(int(verts.size() / 600), 1)
			var k := 0
			while k < verts.size():
				var w: Vector3 = mi.global_transform * verts[k]
				var nn: Vector3 = (mi.global_transform.basis * norms[k]).normalized()
				k += step
				if eye.distance_to(w) > 160.0:
					continue
				var view := (w - eye).normalized()
				var ang := rad_to_deg(acos(clampf(absf(view.dot(nn)), 0.0, 1.0)))
				# ang = unghiul intre privire si NORMALA; 0 = fata in plin.
				cnt += 1
				sum += ang
				if ang < 50.0:
					buckets["fata (<50 gr)"] += 1
				elif ang < 75.0:
					buckets["oblic (50-75)"] += 1
				else:
					buckets["muchie (>75)"] += 1
		print("\n=== frac %.2f — unghiul de vedere al fetei (%d esantioane) ===" % [f, cnt])
		if cnt > 0:
			print("   mediu: %.1f grade fata de normala (0 = in plin, 90 = pe muchie)" % (sum / float(cnt)))
			for kk in buckets.keys():
				print("   %-16s %4d  (%.0f%%)" % [kk, buckets[kk], 100.0 * float(buckets[kk]) / float(cnt)])
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _walk(n: Node, out: Array[Node]) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("Faleza"):
			out.append(c)
		_walk(c, out)

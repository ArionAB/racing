extends Node
## Sonda crr-f: unde cad crestele de fundal (ApuanRidge_*) pe Track23 si ce vede din
## ele CAMERA DE JOC (memoria `reperul-se-vede-pe-patru-axe`): distanta, azimutul fata
## de privire, verticala fata de marginea de sus a cadrului, ocluzia prin teren
## (raycast fizic din ochi pana la fiecare vertex esantionat).
##
## Camera: parametrii lui `chase_camera.gd` (10 m sus, 12,5 m in spate, fov vertical
## 68, priveste spre 5 m in fata la +0,4 m; memoria `verifica-cu-parametrii-lui`),
## raport 16:9. Fractia -> index ca in snapshot.gd (int(frac * baked.size())).
##   godot --headless --path . res://tools/ProbeCarraraHorizon.tscn [-- --fracs=0.02,0.62]
## Iese cu 1 daca vreo fractie din lista de contract (A 0.02, E 0.62, F 0.70,
## G 0.80, G 0.88) nu vede nicio creasta (>= MIN_VIS vertecsi in cadru, neocluzati),
## daca nu sunt exact 3 creste sau daca vreun mesh de fundal arunca umbra. Pe starea
## dinaintea legarii (`horizon_model` gol) pica: 0 creste, 5 fractii goale.

const TRACK := "res://scenes/tracks/Track23.tscn"
const CONTRACT := [0.02, 0.62, 0.70, 0.80, 0.88]
const MIN_VIS := 25
const FOV_V := 68.0
const ASPECT := 16.0 / 9.0

var _track: Node3D
var _frames := 0
var _fracs: Array = []


func _ready() -> void:
	_fracs = CONTRACT.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fracs="):
			_fracs.clear()
			for f in a.trim_prefix("--fracs=").split(","):
				_fracs.append(float(f))
	_track = (load(TRACK) as PackedScene).instantiate() as Node3D
	add_child(_track)


func _physics_process(_d: float) -> void:
	_frames += 1
	if _frames < 6:
		return
	set_physics_process(false)
	_measure()


func _ridges() -> Array:
	var out := []
	for n in _track.find_children("ApuanRidge_*", "", true, false):
		if n is Node3D:
			out.append(n)
	return out


func _verts(ridge: Node3D, step: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var meshes := ridge.find_children("*", "MeshInstance3D", true, false)
	if ridge is MeshInstance3D:
		meshes.append(ridge)
	for m in meshes:
		var mi := m as MeshInstance3D
		var xf := mi.global_transform
		for s in mi.mesh.get_surface_count():
			var vs: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for i in range(0, vs.size(), step):
				out.append(xf * vs[i])
	return out


func _measure() -> void:
	var baked: PackedVector3Array = _track.get("baked")
	var space := get_viewport().world_3d.direct_space_state
	var ridges := _ridges()
	print("== crestele de fundal pe Track23: %d ==" % ridges.size())
	var samples := {}
	for r in ridges:
		var vs := _verts(r, 23)
		samples[r] = vs
		var lo := Vector3(INF, INF, INF)
		var hi := -lo
		var road := INF
		for w in vs:
			lo = lo.min(w)
			hi = hi.max(w)
			for i in range(0, baked.size(), 4):
				var dx := baked[i].x - w.x
				var dz := baked[i].z - w.z
				road = minf(road, dx * dx + dz * dz)
		var g: Vector3 = r.global_position
		print("  %-13s pivot (%6.1f, %5.1f, %6.1f) scara %.2f yaw %5.0f  cota %5.1f..%5.1f  la %5.1f m de sosea" % [
			r.name, g.x, g.y, g.z, r.global_transform.basis.get_scale().x,
			rad_to_deg(r.global_transform.basis.get_euler().y), lo.y, hi.y, sqrt(road)])
	# Fundalul NU arunca umbra (memoria caster-departat-fura-umbra): o creasta de
	# 200 m in cascada intinde harta de umbre si fura precizia din prim-plan.
	var casters := 0
	for r in ridges:
		var ms: Array = r.find_children("*", "MeshInstance3D", true, false)
		if r is MeshInstance3D:
			ms.append(r)
		for m in ms:
			if (m as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				casters += 1
	print("  mesh-uri de fundal care arunca umbra: %d (cerut 0)" % casters)
	var tv := tan(deg_to_rad(FOV_V * 0.5))
	var th := tv * ASPECT
	var fail := 0
	for f in _fracs:
		var n := baked.size()
		var idx := int(float(f) * float(n)) % n
		var p := baked[idx]
		var fwd := baked[(idx + 4) % n] - p
		fwd.y = 0.0
		fwd = fwd.normalized()
		var eye := p - fwd * 12.5 + Vector3.UP * 10.0
		var target := p + fwd * 5.0 + Vector3.UP * 0.4
		var basis := Basis.looking_at(target - eye, Vector3.UP)
		var line := "frac %.2f  ochi (%5.0f,%4.0f,%5.0f) priveste %4.0f grade:" % [
			f, eye.x, eye.y, eye.z, rad_to_deg(atan2(fwd.z, fwd.x))]
		var best := 0
		for r in ridges:
			var vis := 0
			var inframe := 0
			var dists := []
			var top := -INF
			for w in samples[r]:
				var d: Vector3 = w - eye
				var z := -basis.z.dot(d)
				if z <= 1.0:
					continue
				var x := basis.x.dot(d) / z
				var y := basis.y.dot(d) / z
				if absf(x) > th or absf(y) > tv:
					continue
				inframe += 1
				var q := PhysicsRayQueryParameters3D.create(eye, w)
				var hit := space.intersect_ray(q)
				if not hit.is_empty() and eye.distance_to(hit["position"]) < d.length() - 4.0:
					continue
				vis += 1
				dists.append(d.length())
				top = maxf(top, y / tv)
			best = maxi(best, vis)
			if vis > 0:
				dists.sort()
				line += "  %s %d/%d vizibile, %0.f-%0.f m, varful la %.2f din cadru" % [
					String(r.name).trim_prefix("ApuanRidge_"), vis, inframe,
					dists[0], dists[dists.size() / 2], top]
			elif inframe > 0:
				line += "  %s 0/%d (ocluzat)" % [String(r.name).trim_prefix("ApuanRidge_"), inframe]
		if CONTRACT.has(f) and best < MIN_VIS:
			fail += 1
			line += "  <- NICIO CREASTA"
		print(line)
	var ok := fail == 0 and ridges.size() == 3 and casters == 0
	print("probe_carrara_horizon: %s" % ("OK" if ok else "PICA (%d fractii fara creasta, %d creste, %d umbre)" % [fail, ridges.size(), casters]))
	get_tree().quit(0 if ok else 1)

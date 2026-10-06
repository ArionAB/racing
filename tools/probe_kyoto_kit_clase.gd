extends SceneTree
## Inventarul kitului Kyoto pentru valul de materiale (docs/track_briefs/
## kyoto_materiale.md). Tiparul: probe_capp_kit_slots.gd, plus doua coloane:
##
## - INTERVALUL DE Y pe slot: o piesa cu doua sloturi pe intervale separate se
##   poate rupe curat (corp + `_Accente`); pe intervale suprapuse, nu.
## - CLASA de azi din `WorldProp.CLASSES_BY_MODEL`, ca sa se vada ce a ramas
##   pe atlas curat.
##
##   godot --headless --path . -s tools/probe_kyoto_kit_clase.gd

const ROOT := "res://assets/models/kyoto"
const DIRS := ["animals", "buildings", "plants", "props", "rocks", "structures",
	"trees", "vehicles"]

func _init() -> void:
	var rows := []
	for d in DIRS:
		var da := DirAccess.open("%s/%s" % [ROOT, d])
		if da == null:
			continue
		for f in da.get_files():
			if f.ends_with(".glb"):
				rows.append_array(_survey("%s/%s/%s" % [ROOT, d, f]))
	print("%-24s %-22s %7s %5s %5s %-6s %-22s %s" % [
		"fisier", "nod", "arie_m2", "dom%", "lat", "uv", "clasa", "sloturi (pct y0-y1)"])
	for r in rows:
		print("%-24s %-22s %7.1f %4.0f%% %5.2f %-6s %-22s %s" % [
			r["file"], r["node"], r["area"], r["dom"] * 100.0, r["w"],
			r["uv"], r["cls"], r["slots"]])
	quit()

func _survey(path: String) -> Array:
	var stem := path.get_file().get_basename()
	var sc := load(path) as PackedScene
	if sc == null:
		return []
	var inst := sc.instantiate()
	var mapping: Dictionary = WorldProp.CLASSES_BY_MODEL.get(stem, {})
	var out := []
	for mi in _meshes(inst):
		var mesh: Mesh = mi.mesh
		var xf: Transform3D = _xf_to_root(mi, inst)
		var hist := {}
		var ylo := {}
		var yhi := {}
		var total := 0.0
		var us := {}
		var vs := {}
		var aabb := AABB()
		var first := true
		for si in mesh.get_surface_count():
			var arr: Array = mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			if uv.size() == 0:
				continue
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var n: int = idx.size() if idx.size() > 0 else v.size()
			var i := 0
			while i + 2 < n:
				var ia: int = idx[i] if idx.size() > 0 else i
				var ib: int = idx[i + 1] if idx.size() > 0 else i + 1
				var ic: int = idx[i + 2] if idx.size() > 0 else i + 2
				var pa: Vector3 = xf * v[ia]
				var pb: Vector3 = xf * v[ib]
				var pc: Vector3 = xf * v[ic]
				var ar: float = 0.5 * (pb - pa).cross(pc - pa).length()
				var slot: int = clampi(int(
					((uv[ia].x + uv[ib].x + uv[ic].x) / 3.0) * 32.0), 0, 31)
				hist[slot] = float(hist.get(slot, 0.0)) + ar
				var y0: float = minf(pa.y, minf(pb.y, pc.y))
				var y1: float = maxf(pa.y, maxf(pb.y, pc.y))
				ylo[slot] = minf(float(ylo.get(slot, INF)), y0)
				yhi[slot] = maxf(float(yhi.get(slot, -INF)), y1)
				total += ar
				for p in [pa, pb, pc]:
					if first:
						aabb = AABB(p, Vector3.ZERO)
						first = false
					else:
						aabb = aabb.expand(p)
				i += 3
			for k in uv.size():
				us[snappedf(uv[k].x, 0.0005)] = true
				vs[snappedf(uv[k].y, 0.0005)] = true
		if total <= 0.0:
			continue
		var keys: Array = hist.keys()
		keys.sort_custom(func(x, y): return hist[x] > hist[y])
		var parts := PackedStringArray()
		for k in keys:
			var pct: float = 100.0 * float(hist[k]) / total
			if pct >= 2.0:
				parts.append("%d:%.0f%%(%.2f-%.2f)" % [k, pct, ylo[k], yhi[k]])
		var s := aabb.size
		var w: float = minf(s.x, minf(s.y, s.z))
		out.append({
			"file": stem, "node": String(mi.name), "area": total,
			"dom": float(hist[keys[0]]) / total, "w": w,
			"uv": "REAL" if us.size() > 4 and vs.size() > 4 else "colaps",
			"cls": String(mapping.get(String(mi.name), "-")),
			"slots": " ".join(parts),
		})
	inst.free()
	return out

func _xf_to_root(n: Node3D, root: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var c: Node = n
	while c != null and c != root:
		if c is Node3D:
			t = (c as Node3D).transform * t
		c = c.get_parent()
	return t

func _meshes(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		o.append(n)
	for c in n.get_children():
		o.append_array(_meshes(c))
	return o

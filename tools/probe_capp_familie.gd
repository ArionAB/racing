extends SceneTree
## Cat de MONOCROMA e o piesa DUPA remaparea de la incarcare (TUFF_UV_REMAP).
##
## Sondajul pe .glb brut minte pe kitul asta: `_retint_tuff` muta slotul 1 pe
## CONCRETE si 2 pe MARBLE_GREY inainte ca vreun material sa fie pus, deci
## "32% pe slotul 2 (#915D27, saturatie 0.73)" e in joc "32% pe #B8B4AC
## (saturatie 0.08)". Diferenta decide daca o clasa STERGE un accent pictat
## (caz in care piesa ramane pe atlas) sau doar inlocuieste variatie de valoare
## intr-o singura familie de culoare (caz in care textura n-are ce pierde).
##
## Criteriul raportat: ecartul de NUANTA si de SATURATIE peste sloturile care
## tin >=2% din arie. Familie unica = tot ce e sub ~0.10 saturatie si sub ~0.08
## nuanta; orice peste inseamna accent pictat.

const DIRS := ["buildings", "plants", "props", "rocks", "structures"]

func _init() -> void:
	var remap := WorldProp.TUFF_UV_REMAP
	var tuff := WorldProp.TUFF_UV_MODELS
	var rows := []
	for d in DIRS:
		var da := DirAccess.open("res://assets/models/cappadocia/%s" % d)
		if da == null:
			continue
		for f in da.get_files():
			if not f.ends_with(".glb"):
				continue
			var stem := f.get_basename()
			var use := remap if tuff.has(stem) else {}
			if stem == "church_arch":
				use = use.duplicate()
				use.merge(WorldProp.ARCH_UV_REMAP)
			rows.append_array(_survey(
				"res://assets/models/cappadocia/%s/%s" % [d, f], use, tuff.has(stem)))
	rows.sort_custom(func(a, b): return a["area"] > b["area"])
	print("%-24s %8s %5s %6s %6s %6s  %s" % [
		"fisier", "arie", "lat_m", "d_sat", "d_hue", "dom%", "sloturi(dupa remap)"])
	for r in rows:
		print("%-24s %8.1f %5.2f %6.3f %6.3f %5.0f%%  %s" % [
			r["file"], r["area"], r["w"], r["dsat"], r["dhue"],
			r["dom"] * 100.0, r["slots"]])
	quit()

func _survey(path: String, remap: Dictionary, is_tuff: bool) -> Array:
	var sc := load(path) as PackedScene
	if sc == null:
		return []
	var inst := sc.instantiate()
	var hist := {}
	var total := 0.0
	var aabb := AABB()
	var first := true
	for mi in _meshes(inst):
		var mesh: Mesh = mi.mesh
		var b: AABB = mesh.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
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
				var ar: float = 0.5 * (v[ib] - v[ia]).cross(v[ic] - v[ia]).length()
				var slot: int = clampi(int(
					((uv[ia].x + uv[ib].x + uv[ic].x) / 3.0) * 32.0), 0, 31)
				if remap.has(slot):
					slot = int(remap[slot])
				hist[slot] = float(hist.get(slot, 0.0)) + ar
				total += ar
				i += 3
	inst.free()
	if total <= 0.0:
		return []
	var keys: Array = hist.keys()
	keys.sort_custom(func(x, y): return hist[x] > hist[y])
	var parts := PackedStringArray()
	var sats := []
	var hues := []
	for k in keys:
		var pct: float = 100.0 * float(hist[k]) / total
		if pct < 2.0:
			continue
		var col := Palette.color(int(k))
		parts.append("%d(%s s%.2f):%.0f%%" % [k, Palette.HEX[k], col.s, pct])
		sats.append(col.s)
		hues.append(col.h)
	var dsat := 0.0
	var dhue := 0.0
	for a in sats:
		for b2 in sats:
			dsat = maxf(dsat, absf(a - b2))
	for a in hues:
		for b2 in hues:
			# nuanta e circulara
			var d: float = absf(a - b2)
			dhue = maxf(dhue, minf(d, 1.0 - d))
	return [{
		"file": path.get_file().get_basename() + ("*" if is_tuff else ""),
		"area": total, "w": maxf(aabb.size.x, aabb.size.z),
		"dsat": dsat, "dhue": dhue,
		"dom": float(hist[keys[0]]) / total, "slots": " ".join(parts),
	}]

func _meshes(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		o.append(n)
	for c in n.get_children():
		o.append_array(_meshes(c))
	return o

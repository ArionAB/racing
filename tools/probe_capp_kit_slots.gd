extends SceneTree
## Inventarul kitului Cappadocia pentru decizia de CLASA de textura.
##
## Doua cifre decid, si sunt exact cele doua din STROMBOLI_CLASSES:
##
## 1. ARIA pe slotul dominant. O clasa triplanara STERGE culorile din sloturi
##    (regula #313), deci primesc textura doar piesele MONOCROME — alea n-au ce
##    pierde. Piesele care matura 2-4 sloturi isi tin accentul pictat acolo.
## 2. UV-urile: colapsate sau reale. Se testeaza numarul de valori DISTINCTE,
##    nu intervalul (memoria `uv-colapsat-nu-e-un-interval`) — un kit cu UV-uri
##    pe centrele sloturilor are u_max-u_min mare si totusi zero textura.
##
## Se raporteaza si latimea gabaritului: sub ~0.5 m granulatia se pierde in
## mipmap si textura iese plata oricat de corecta ar fi maparea (style_bible §4,
## lectia `Bollard`/`Jib` din CHONGQING_CLASSES).

const DIRS := ["buildings", "plants", "props", "rocks", "structures"]

func _init() -> void:
	var rows := []
	for d in DIRS:
		var da := DirAccess.open("res://assets/models/cappadocia/%s" % d)
		if da == null:
			continue
		for f in da.get_files():
			if not f.ends_with(".glb"):
				continue
			rows.append_array(_survey("res://assets/models/cappadocia/%s/%s" % [d, f]))
	rows.sort_custom(func(a, b): return a["area"] > b["area"])
	print("%-26s %-26s %7s %6s  %-5s %s" % [
		"fisier", "nod", "arie_m2", "dom%", "uv", "sloturi"])
	for r in rows:
		print("%-26s %-26s %7.1f %5.0f%%  %-5s %s" % [
			r["file"], r["node"], r["area"], r["dom"] * 100.0,
			r["uv"], r["slots"]])
	quit()

func _survey(path: String) -> Array:
	var stem := path.get_file().get_basename()
	var sc := load(path) as PackedScene
	if sc == null:
		return []
	var inst := sc.instantiate()
	var out := []
	for mi in _meshes(inst):
		var mesh: Mesh = mi.mesh
		var hist := {}
		var total := 0.0
		var us := {}
		var vs := {}
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
				hist[slot] = float(hist.get(slot, 0.0)) + ar
				total += ar
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
				parts.append("%d:%.0f%%" % [k, pct])
		# UV-uri REALE inseamna valori distincte SI de u, SI de v: un kit pe
		# centrele sloturilor are multi u si un singur v (v == 0.5).
		var real: bool = us.size() > 4 and vs.size() > 4
		out.append({
			"file": stem, "node": mi.name, "area": total,
			"dom": float(hist[keys[0]]) / total,
			"uv": "REAL" if real else "colaps",
			"slots": " ".join(parts),
		})
	inst.free()
	return out

func _meshes(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		o.append(n)
	for c in n.get_children():
		o.append_array(_meshes(c))
	return o

extends SceneTree
## Masoara kitul Chongqing inainte de a-i da clase de material: pentru fiecare
## NOD cu mesh din cele 49 de GLB-uri, cat din ARIA de triunghi sta pe fiecare
## slot de paleta, si daca UV-urile sunt colapsate.
##
## Cele doua cifre decid impreuna, si numai impreuna:
##
## 1. UV-uri COLAPSATE (u_min == u_max) inseamna ca `class_material` ar citi un
##    singur texel — deci clasa TREBUIE sa fie triplanara. Lectia e masurata pe
##    kitul Stromboli (vezi STROMBOLI_CLASSES) si pe atlas (style_bible §4).
## 2. O clasa triplanara STERGE culorile din sloturi. Deci primesc clasa doar
##    piesele in care UN SINGUR slot duce grosul ariei — pe restul, textura ar
##    costa exact accentul pentru care exista piesa.
##
## Pragul de 85% nu e ales din burta: pe Stromboli casele au intrat pe clasa la
## 90-94% slot dominant, iar cele respinse stateau pe 2-4 sloturi comparabile.
##
##   godot --headless --path . --script res://tools/probe_cq_slots.gd
##   godot --headless --path . --script res://tools/probe_cq_slots.gd -- --glb=hongya_dong

## Sub cat la suta din arie pe slotul dominant piesa NU primeste clasa
## triplanara, fiindca ar sterge culori pictate care conteaza.
const DOMINANT_MIN: float = 85.0

## Latimea unui slot in atlas (32 de sloturi pe 512 px).
const SLOTS: int = 32


func _init() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--glb="):
			only = a.substr(6)

	var files := _kit_files()
	var rows: Array = []
	for f in files:
		if only != "" and not f.contains(only):
			continue
		rows.append_array(_measure_glb(f))

	rows.sort_custom(func(a, b): return a["dominant_pct"] > b["dominant_pct"])

	print("=== KIT CHONGQING: arie per slot, per nod ===")
	print("%-34s %-26s %7s %6s %12s  %s" % [
		"nod", "fisier", "slot%", "slot", "uv(u/v)", "verdict"])
	var eligible: Array = []
	for r in rows:
		var uv: String = "COLAPS" if r["uv_collapsed"] else "reale"
		uv += " %d/%d" % [r["n_u"], r["n_v"]]
		var verdict := "-"
		if r["dominant_pct"] >= DOMINANT_MIN:
			verdict = "CANDIDAT (slot %d)" % r["dominant_slot"]
			eligible.append(r)
		else:
			verdict = "ramane pe atlas (%s)" % r["mix"]
		print("%-34s %-26s %6.1f%% %6d %12s  %s" % [
			r["node"], r["file"], r["dominant_pct"], r["dominant_slot"],
			uv, verdict])

	print("")
	print("=== CANDIDATI (%d din %d noduri) ===" % [eligible.size(), rows.size()])
	var by_slot: Dictionary = {}
	for r in eligible:
		var s: int = r["dominant_slot"]
		if not by_slot.has(s):
			by_slot[s] = []
		by_slot[s].append(r["node"])
	for s in by_slot.keys():
		print("slot %2d : %s" % [s, ", ".join(by_slot[s])])
	quit(0)


func _kit_files() -> Array:
	var out: Array = []
	for sub in ["buildings", "props", "structures", "vehicles"]:
		var dir: String = "res://assets/models/chongqing/" + str(sub)
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for f in d.get_files():
			if f.ends_with(".glb"):
				out.append(dir + "/" + f)
	out.sort()
	return out


func _measure_glb(path: String) -> Array:
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("nu se incarca: " + path)
		return []
	var root := packed.instantiate()
	var rows: Array = []
	_walk(root, path.get_file().get_basename(), rows)
	root.free()
	return rows


func _walk(n: Node, file: String, rows: Array) -> void:
	if n is MeshInstance3D and n.mesh != null:
		var r := _measure_mesh(n as MeshInstance3D)
		if not r.is_empty():
			r["node"] = n.name
			r["file"] = file
			rows.append(r)
	for c in n.get_children():
		_walk(c, file, rows)


## Aria de triunghi per slot. Slotul se citeste din U-ul vertexului: atlasul are
## 32 de sloturi pe latime, deci slot = floor(u * 32). Aria se ia in spatiul
## MESH-ului si se imparte pe cele trei varfuri doar daca sunt in acelasi slot;
## altfel triunghiul se atribuie slotului majoritar dintre varfuri (UV-urile
## kitului sunt colapsate pe punct, deci in practica toate trei coincid).
func _measure_mesh(mi: MeshInstance3D) -> Dictionary:
	var mesh := mi.mesh
	var area_per_slot: Dictionary = {}
	var total := 0.0
	var u_min := INF
	var u_max := -INF
	var distinct_u: Dictionary = {}
	var distinct_v: Dictionary = {}

	for si in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(si)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs = arrays[Mesh.ARRAY_TEX_UV]
		if uvs == null or uvs.size() == 0:
			continue
		var idx = arrays[Mesh.ARRAY_INDEX]
		var tri_count := 0
		if idx != null and idx.size() > 0:
			tri_count = idx.size() / 3
		else:
			tri_count = verts.size() / 3
		# Numarul de valori DISTINCTE de u, nu intervalul. Intervalul masoara
		# distanta dintre sloturi diferite din atlas, ceea ce nu spune nimic:
		# o piesa cu 9 sloturi are span 0.84 si totusi fiecare patch e un
		# PUNCT. Colapsat = fiecare slot are o singura coordonata, deci
		# derivata e zero si `class_material` ar citi un singur texel.
		for u in uvs:
			u_min = min(u_min, u.x)
			u_max = max(u_max, u.x)
			distinct_u["%.4f" % u.x] = true
			distinct_v["%.4f" % u.y] = true
		for t in range(tri_count):
			var i0: int
			var i1: int
			var i2: int
			if idx != null and idx.size() > 0:
				i0 = idx[t * 3]
				i1 = idx[t * 3 + 1]
				i2 = idx[t * 3 + 2]
			else:
				i0 = t * 3
				i1 = t * 3 + 1
				i2 = t * 3 + 2
			var a := verts[i1] - verts[i0]
			var b := verts[i2] - verts[i0]
			var area := a.cross(b).length() * 0.5
			if area <= 0.0:
				continue
			var s0 := _slot_of(uvs[i0].x)
			var s1 := _slot_of(uvs[i1].x)
			var s2 := _slot_of(uvs[i2].x)
			var s := s0
			if s1 == s2:
				s = s1
			area_per_slot[s] = float(area_per_slot.get(s, 0.0)) + area
			total += area

	if total <= 0.0 or area_per_slot.is_empty():
		return {}

	var best_slot := -1
	var best := 0.0
	var parts: Array = []
	for s in area_per_slot.keys():
		var pct: float = float(area_per_slot[s]) / total * 100.0
		if pct >= 1.0:
			parts.append("%d:%.0f%%" % [s, pct])
		if area_per_slot[s] > best:
			best = area_per_slot[s]
			best_slot = s
	parts.sort()
	return {
		"dominant_slot": best_slot,
		"dominant_pct": best / total * 100.0,
		# Colapsat inseamna: cel mult o valoare de v (patch-ul n-are inaltime)
		# SAU cel mult cate o valoare de u per slot maturat.
		"uv_collapsed": distinct_v.size() <= 1 or distinct_u.size() <= area_per_slot.size(),
		"n_u": distinct_u.size(),
		"n_v": distinct_v.size(),
		"mix": " ".join(parts),
	}


func _slot_of(u: float) -> int:
	return clampi(int(floor(u * SLOTS)), 0, SLOTS - 1)

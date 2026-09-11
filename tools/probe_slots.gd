extends SceneTree

## SLOTURILE DE ATLAS PE CARE STA O FAMILIE DE PIESE.
##
## Exista fiindca "frunzisul e prea verde" nu se poate repara pana nu stii DIN
## CE e facut verdele. Pe POI D (Serengeti) intrebarea a rasturnat trei ipoteze:
## criticul rundei 5 a spus ca padurea e scatterata din kitul Stromboli — nu e,
## `probe_decor` si Track14.tscn nu contin niciun `stromboli/`. Cauza reala, pe
## care numai UV-urile o arata, e ca TOATE coroanele zonei (206 smochini, 64 de
## acacii-febra, 98 de tufe, 19 euforbii) stau pe aceeasi pereche de sloturi:
## 12 (CACTUS_GREEN #5B7C34, nuanta 87) si 21 (TROPICAL_GREEN #3F7A3C, nuanta
## 117 — VERDE PUR). De aia toata adancimea citeste un singur smarald.
##
## Se ruleaza ca script, nu ca scena:
##   godot --headless --path <worktree> --script res://tools/probe_slots.gd \
##       -- --dir=serengeti/plants
##
## Raporteaza, per fisier si per nod de mesh, procentul de vertecsi pe fiecare
## slot SI intervalul lui de y — inaltimea separa trunchiul de coroana, si fara
## ea nu se poate spune daca o clasa pusa pe nod ar vopsi si scoarta (chiar asta
## se intampla aici: fiecare copac e UN nod, cu trunchiul de la y=0 si coroana
## de la y~7 in sus, deci o clasa pe tot nodul face trunchiul verde).
func _init() -> void:
	var dir := "serengeti/plants"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dir="):
			dir = a.trim_prefix("--dir=")
	var base := "res://assets/models/%s" % dir
	var da := DirAccess.open(base)
	if da == null:
		push_error("probe_slots: nu pot deschide %s" % base)
		quit(1)
		return
	var names: Array[String] = []
	for f in da.get_files():
		if f.ends_with(".glb"):
			names.append(f.get_basename())
	names.sort()
	print("=== SLOTURI DE ATLAS · %s ===" % dir)
	for stem in names:
		var sc := load("%s/%s.glb" % [base, stem]) as PackedScene
		if sc == null:
			continue
		var root := sc.instantiate()
		print("--- %s" % stem)
		_report(root)
		root.free()
	quit()


func _report(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null:
		for si in range(mi.mesh.get_surface_count()):
			var arr: Array = mi.mesh.surface_get_arrays(si)
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var vt: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if uv.is_empty():
				continue
			# slot -> [y_min, y_max, numar]
			var per: Dictionary = {}
			for i in range(uv.size()):
				var sl := clampi(int(uv[i].x * float(Palette.SLOTS)), 0,
					Palette.SLOTS - 1)
				var e: Array = per.get(sl, [INF, -INF, 0])
				e[0] = minf(float(e[0]), vt[i].y)
				e[1] = maxf(float(e[1]), vt[i].y)
				e[2] = int(e[2]) + 1
				per[sl] = e
			var keys: Array = per.keys()
			keys.sort()
			for k in keys:
				var e: Array = per[k]
				var c := Palette.color(int(k))
				print("   %-22s slot %2d #%02X%02X%02X  %4.1f%% verts  y %6.2f..%6.2f" % [
					mi.name, int(k),
					int(c.r * 255.0), int(c.g * 255.0), int(c.b * 255.0),
					100.0 * float(e[2]) / float(uv.size()),
					float(e[0]), float(e[1])])
	for c in n.get_children():
		_report(c)

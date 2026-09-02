extends Node
## Ce SLOT din atlas atinge fiecare piesa a piatei, cu ARIA pe care o acopera.
##
## Culoarea nu se citeste din numele fisierului (lectia `slot-ales-dupa-nume`),
## si nici din numarul de vertecsi: aria spune CAT, hexul spune CE
## (`aria-slotului-spune-cat-nu-ce`). Slotul se afla din UV: indexul e
## floor(uv.x * 32), fiindca `Palette.uv()` pune centrul slotului la
## (slot + 0.5) / 32.
##
##   godot --headless --path . res://tools/ProbeCappSlot.tscn

const MODELS: Array[String] = [
	"buildings/cave_house_a", "buildings/cave_house_b", "buildings/cave_house_c",
	"buildings/farmhouse", "buildings/dovecote",
	"rocks/chimney_a", "rocks/chimney_triple",
	"rocks/cracked_chimney_b", "rocks/cracked_chimney_c",
	"structures/church_arch", "structures/cave_entrance",
	"plants/vine_row", "props/torch", "props/carpet_terrace",
]


func _ready() -> void:
	await get_tree().process_frame
	print("")
	print("=== sloturi atinse, pe ARIE (POI A) ===")
	for m in MODELS:
		var ps := load("res://assets/models/cappadocia/%s.glb" % m) as PackedScene
		if ps == null:
			continue
		var inst := ps.instantiate()
		get_tree().root.add_child(inst)
		var area := {}
		_collect(inst, area)
		var total := 0.0
		for k in area:
			total += float(area[k])
		var keys: Array = area.keys()
		keys.sort_custom(func(a, b): return float(area[a]) > float(area[b]))
		var parts: Array[String] = []
		for k in keys:
			var pct := 100.0 * float(area[k]) / maxf(total, 0.0001)
			if pct < 1.0:
				continue
			parts.append("%d(%s) %.0f%%" % [k, Palette.HEX[int(k)], pct])
		print("  %-28s %s" % [m, ", ".join(parts)])
		inst.queue_free()
	get_tree().quit(0)


## Aria triunghiului, atribuita slotului dat de UV-ul primului lui vertex.
func _collect(node: Node, acc: Dictionary) -> void:
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			for si in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(si)
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				if uv.size() == 0:
					continue
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				var count := idx.size() if idx.size() > 0 else verts.size()
				var t := 0
				while t + 2 < count:
					var i0 := idx[t] if idx.size() > 0 else t
					var i1 := idx[t + 1] if idx.size() > 0 else t + 1
					var i2 := idx[t + 2] if idx.size() > 0 else t + 2
					var a := (verts[i1] - verts[i0]).cross(verts[i2] - verts[i0]).length() * 0.5
					var slot := int(clampf(uv[i0].x, 0.0, 0.9999) * float(Palette.SLOTS))
					acc[slot] = float(acc.get(slot, 0.0)) + a
					t += 3
	for c in node.get_children():
		_collect(c, acc)

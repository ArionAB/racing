extends Node
## Silueta conurilor: cat de mult se ingusteaza corpul de la baza spre varf, si
## ce fractie din inaltime ocupa palaria inchisa. Referinta v3 are conuri care
## se subtiaza continuu, cu varf mic; daca ale noastre sunt cilindri cu palarie
## mare, nicio asezare nu le salveaza — e o problema de MESH, si trebuie sa se
## vada intr-o cifra, nu doar in poza.
##   godot --headless --path . res://tools/ProbeCappTaper.tscn

const MODELS: Array[String] = [
	"rocks/chimney_a", "rocks/chimney_b", "rocks/chimney_c", "rocks/chimney_d",
	"rocks/chimney_mushroom", "rocks/chimney_triple",
]


func _ready() -> void:
	await get_tree().process_frame
	print("")
	print("=== silueta conurilor: raza pe felii de inaltime ===")
	print("  model                     h      r@10%  r@35%  r@60%  r@85%  | conicitate | palarie")
	for m in MODELS:
		var ps := load("res://assets/models/cappadocia/%s.glb" % m) as PackedScene
		if ps == null:
			continue
		var inst := ps.instantiate()
		get_tree().root.add_child(inst)
		var pts: Array[Vector3] = []
		var dark: Array[float] = []
		_gather(inst, pts, dark)
		if pts.is_empty():
			inst.queue_free()
			continue
		var lo := INF
		var hi := -INF
		for p in pts:
			lo = minf(lo, p.y)
			hi = maxf(hi, p.y)
		var h := hi - lo
		# O SINGURA trecere prin vertecsi, cu felii pe indice: varianta cu
		# patru cautari peste tot vectorul rula minute intregi pe mesh-urile
		# mari si sonda a fost oprita de timeout.
		var r: Array[float] = [0.0, 0.0, 0.0, 0.0]
		var centers: Array[float] = [0.10, 0.35, 0.60, 0.85]
		for p in pts:
			var t := (p.y - lo) / maxf(h, 0.001)
			for b in 4:
				if absf(t - centers[b]) < 0.06:
					r[b] = maxf(r[b], Vector2(p.x, p.z).length())
		# Palaria: de la ce cota in sus stau vertecsii de slot inchis.
		var cap_lo := hi
		for i in dark.size():
			cap_lo = minf(cap_lo, dark[i])
		var cap_frac := (hi - cap_lo) / maxf(h, 0.001) if dark.size() > 0 else 0.0
		print("  %-24s %5.2f  %5.2f  %5.2f  %5.2f  %5.2f  |   %4.2f     | %4.0f%%" % [
			m, h, r[0], r[1], r[2], r[3],
			r[3] / maxf(r[0], 0.001), 100.0 * cap_frac])
		inst.queue_free()
	print("")
	print("  conicitate = raza la 85%% / raza la 10%%. 1.00 = cilindru, 0.2 = con ascutit.")
	get_tree().quit(0)


## Vertecsii, plus cotele celor care stau pe sloturile inchise (palaria).
func _gather(node: Node, pts: Array[Vector3], dark: Array[float]) -> void:
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			for si in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(si)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				for i in v.size():
					pts.append(v[i])
					if uv.size() > i:
						var slot := int(clampf(uv[i].x, 0.0, 0.9999) * 32.0)
						# 20 = VOLCANIC_BLACK, 4 = ROCK_DARK: palaria de bazalt.
						if slot == 20 or slot == 4:
							dark.append(v[i].y)
	for c in node.get_children():
		_gather(c, pts, dark)

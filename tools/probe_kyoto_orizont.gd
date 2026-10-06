extends Node
## Unde cad siluetele de orizont ale Kyoto (int-a): pentru fiecare nod din
## `kyoto_horizon.glb` asezat de `Track._build_horizon`, tipareste distanta pana
## la CEL MAI APROPIAT punct de sosea si pana la centroid, inaltimea varfului
## peste sosea si unghiul vertical sub care il vede camera de joc (10 m sus).
##
##   godot --headless --path . res://tools/ProbeKyotoOrizont.tscn
const NAMES := ["Higashiyama_A", "Higashiyama_B", "Arashiyama_A", "FarRoofs_A"]

func _ready() -> void:
	var track := (load("res://scenes/tracks/Track18.tscn") as PackedScene).instantiate() as Track
	add_child(track)
	for i in 6:
		await get_tree().process_frame
	var c := Vector3.ZERO
	for p in track.baked:
		c += p
	c /= float(track.baked.size())
	var rmax := 0.0
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for p in track.baked:
		rmax = maxf(rmax, Vector2(p.x - c.x, p.z - c.z).length())
		mn = mn.min(Vector2(p.x, p.z))
		mx = mx.max(Vector2(p.x, p.z))
	print("centroid (%.0f, %.0f) · %d puncte baked · raza max %.0f m · x[%.0f..%.0f] z[%.0f..%.0f]"
		% [c.x, c.z, track.baked.size(), rmax, mn.x, mx.x, mn.y, mx.y])
	var n := 0
	for ch in track.get_children():
		var m3 := ch as Node3D
		if m3 == null:
			continue
		var nm := ""
		for k in NAMES:
			if m3.find_child(k, false, false) != null:
				nm = k
		if nm.is_empty():
			continue
		n += 1
		var nearest := 1e12
		var ny := 0.0
		for i in range(0, track.baked.size(), 2):
			var d := Vector2(track.baked[i].x - m3.position.x, track.baked[i].z - m3.position.z).length()
			if d < nearest:
				nearest = d
				ny = track.baked[i].y
		var aabb := Track.model_aabb(m3)
		var top := m3.position.y + aabb.end.y - 0.0
		var dc := Vector2(m3.position.x - c.x, m3.position.z - c.z).length()
		var rise := top - (ny + 10.0)
		print("%-16s s=%.2f  d_sosea=%5.0f  d_centroid=%5.0f  latime=%4.0f  inaltime=%3.0f  varf peste camera=%+5.1f m (%.1f grade)"
			% [nm, m3.scale.x, nearest, dc, aabb.size.x, aabb.size.y, rise,
			rad_to_deg(atan2(rise, nearest))])
	print("%d siluete" % n)
	get_tree().quit(0)

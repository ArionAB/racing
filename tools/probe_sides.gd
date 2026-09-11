extends Node
## Masoara SIMETRIA padurii POI D: pentru fiecare copac din ZoneD, partea
## benzii (dot cu side), distanta laterala si inaltimea coroanei. Raport pe
## felia deasa 0.214-0.334, plus histograma de inaltimi.
const TRACK := "res://scenes/tracks/Track14.tscn"

func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var zone := t.get_node("DecorManual/ZoneD_PadureaDeCeata")
	var n := t.baked.size()
	var buckets := {}
	var hs: Array[float] = []
	var lat_bins := [0, 0, 0, 0, 0, 0, 0]
	var near_h: Array[float] = []
	for ch in zone.get_children():
		var nm := str(ch.name)
		if nm.begins_with("ceata"):
			continue
		var pos: Vector3 = (ch as Node3D).global_position
		# cel mai apropiat index
		var best := -1
		var bd := INF
		for i in n:
			var d: float = t.baked[i].distance_squared_to(pos)
			if d < bd:
				bd = d
				best = i
		var f := float(best) / float(n)
		if f < 0.214 or f > 0.334:
			continue
		var p: Vector3 = t.baked[best]
		var s := t._side_at(best)
		var lat := (pos - p).dot(s)
		var key := nm.rstrip("0123456789")
		if not buckets.has(key):
			buckets[key] = [0, 0, 0.0, 0.0]
		var b: Array = buckets[key]
		if lat < 0.0:
			b[0] += 1
			b[2] += absf(lat)
		else:
			b[1] += 1
			b[3] += absf(lat)
		var aabb: AABB = _aabb(ch)
		hs.append(aabb.size.y)
		var al := absf(lat)
		lat_bins[clampi(int(al / 5.0), 0, 6)] += 1
		if al <= 12.0:
			near_h.append(aabb.size.y)
	print("clasa            stanga dreapta  lat_med_S lat_med_D")
	var ts := 0
	var td := 0
	for k in buckets:
		var b: Array = buckets[k]
		ts += b[0]
		td += b[1]
		print("%-16s %5d %7d  %8.1f %9.1f" % [k, b[0], b[1],
			b[2] / maxf(1.0, float(b[0])), b[3] / maxf(1.0, float(b[1]))])
	print("TOTAL            %5d %7d   raport %.2f" % [ts, td, float(td) / maxf(1.0, float(ts))])
	hs.sort()
	var bins := [0, 0, 0, 0, 0, 0]
	for h in hs:
		var idx := clampi(int(h / 4.0), 0, 5)
		bins[idx] += 1
	print("lateral de la ax (m) 0-5:%d 5-10:%d 10-15:%d 15-20:%d 20-25:%d 25-30:%d 30+:%d" % lat_bins)
	var nb := [0, 0, 0, 0, 0, 0]
	for h in near_h:
		nb[clampi(int(h / 4.0), 0, 5)] += 1
	print("piese la <=12 m de ax: %d — inaltimi 0-4:%d 4-8:%d 8-12:%d 12-16:%d 16-20:%d 20+:%d" % ([near_h.size()] + nb))
	print("inaltimi (m) 0-4:%d 4-8:%d 8-12:%d 12-16:%d 16-20:%d 20+:%d" % bins)
	get_tree().quit(0)

func _aabb(node: Node) -> AABB:
	var out := AABB()
	var got := false
	for m in _meshes(node):
		var a: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		if not got:
			out = a
			got = true
		else:
			out = out.merge(a)
	return out

func _meshes(node: Node) -> Array:
	var r: Array = []
	if node is MeshInstance3D and (node as MeshInstance3D).visible:
		r.append(node)
	for c in node.get_children():
		r += _meshes(c)
	return r

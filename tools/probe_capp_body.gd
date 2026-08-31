extends Node
## Reface CHIAR calculul din `_far_column` pentru pintenii de taietura, si
## tipareste talpa fata de terenul de sub ea.
##
## Masuratoarea dinainte (cel mai de jos vertex pe celula, raza in jos) e
## inselatoare: panzele de faleza N-AU COLIZIUNE, deci raza trece prin toate
## celelalte panze si loveste terenul de dedesubt. Ce se cere aici e talpa
## coloanei fata de `surface_y` la CHIAR rulajul ei.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_viewport().world_3d.direct_space_state
	var route := _track.route_at(0)
	var n := route.count()
	# pentru fiecare pinten: rulajul lui, si intervalul de fractii
	var specs := [
		["TaieturaSerpentinei", 0.252, 0.318, 9.0],
		["TaieturaCornisei", 0.322, 0.372, 9.0],
		["MalulOpusAlVaiiRosii", 0.170, 0.420, 78.0],
	]
	for sp in specs:
		var nm: String = sp[0]
		var f0: float = sp[1]
		var f1: float = sp[2]
		var off: float = sp[3]
		var worst := -1e9
		var wf := 0.0
		for k in 40:
			var f := f0 + (f1 - f0) * (float(k) / 39.0)
			var idx := int(round(f * float(n))) % n
			var c := _track.point_at(idx)
			var sd: Vector3 = route.side_at(idx)
			sd.y = 0.0
			sd = sd.normalized()
			var b := c + sd * off
			var q := PhysicsRayQueryParameters3D.create(
				b + Vector3(0, 320, 0), b + Vector3(0, -320, 0))
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				continue
			var gy := float(hit["position"].y)
			# cat de jos e terenul de sub baza fata de cota drumului de acolo
			var dd := c.y - gy
			if dd > worst:
				worst = dd
				wf = f
		print("%-24s  la rulajul %.0f m terenul e cu %.1f m sub sosea (frac %.3f)"
			% [nm, off, worst, wf])
	get_tree().quit(0)

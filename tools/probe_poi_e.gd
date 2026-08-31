extends Node3D
## Sonda de teren pentru POI E (via + balonul aterizat), fractiile 0.50-0.68.
##
## Raspunde la intrebarile de care depinde asezarea, si pe care ochiul nu le
## poate da: unde e axul benzii in lume, incotro merge, ce latime are, cat de
## sus e terenul la 15/30/60 m lateral, si care e plafonul de inaltime al
## camerei la distanta aia (10 + 0.093*d).

const FRACS := [0.50, 0.53, 0.56, 0.58, 0.60, 0.62, 0.64, 0.66, 0.68]
const SIDES := [12.0, 20.0, 35.0, 55.0, 80.0]


func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var baked: PackedVector3Array = track.route_at(0).baked
	var n: int = baked.size()
	print("puncte coapte: %d" % n)
	for f: float in FRACS:
		var i: int = int(round(f * float(n))) % n
		var p: Vector3 = baked[i]
		var nx: Vector3 = baked[(i + 4) % n]
		var fwd := (nx - p)
		fwd.y = 0.0
		fwd = fwd.normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		var w := track.width_at(f)
		print("\nfrac %.2f  pos=(%.1f, %.2f, %.1f)  fwd=(%.2f,%.2f)  half_w=%.1f"
			% [f, p.x, p.y, p.z, fwd.x, fwd.z, w])
		for s: float in SIDES:
			var l: Vector3 = p + right * -s
			var r: Vector3 = p + right * s
			var ly := track._terrain_mesh_y(l.x, l.z)
			var ry := track._terrain_mesh_y(r.x, r.z)
			var cap: float = 10.0 + 0.093 * s
			print("   ±%4.0f m  stanga y=%7.2f (dy %+6.2f)  dreapta y=%7.2f (dy %+6.2f)  plafon camera %.1f m"
				% [s, ly, ly - p.y, ry, ry - p.y, cap])
	get_tree().quit()

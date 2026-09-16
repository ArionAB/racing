extends SceneTree
## TEMPORAR: captura A/B a zidariei incase, de la distanta de sofer.
## Motiv: la frac 0.00 pe Track15 nu exista inca NICIUN zid (decorul vine cu
## POI-urile), deci captura din masina nu poate spune daca rosturile se citesc.
## Aici piesele se asaza pe tema pistei, la 4 m de ochi si la 1.2 m inaltime —
## exact geometria trecerii pe langa un zid.
##   --clasa=0  zidaria pe ATLAS (cum era)   --clasa=1  cu `inca_stone`
const OUT := "res://snapshots/mp_zid_%s.png"
var _f := 0
var _on := true

func _process(_d: float) -> bool:
	if _f == 0:
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--clasa="):
				_on = int(a.trim_prefix("--clasa=")) != 0
		_build()
	_f += 1
	if _f < 8:
		return false
	var img := root.get_texture().get_image()
	var path := OUT % ("clasa" if _on else "atlas")
	img.save_png(path)
	print("SNAPSHOT: ", path)
	quit()
	return true

func _build() -> void:
	root.world_3d.environment = _env()
	var holder: Node3D = WorldProp.new() if _on else Node3D.new()
	var pieces := ["structures/inca_wall_a", "structures/inca_wall_b",
		"structures/inca_stair_b", "buildings/inca_house_a"]
	var x := -7.0
	for p in pieces:
		var scn: PackedScene = load("res://assets/models/machupicchu/%s.glb" % p)
		var inst: Node3D = scn.instantiate()
		inst.position = Vector3(x, 0.0, 0.0)
		x += 7.0
		holder.add_child(inst)
	root.add_child(holder)
	# Varianta "inainte": piesele nu trec prin WorldProp, deci raman exact cum
	# vin din .glb — pe atlasul pictat, fara nicio clasa si fara ruptura.
	if not _on:
		_strip(holder)
	var cam := Camera3D.new()
	# Ochiul soferului: 1.2 m inaltime, 9 m in fata zidului, privind orizontal.
	cam.position = Vector3(0.0, 1.2, 9.0)
	cam.fov = 68.0
	root.add_child(cam)
	cam.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, 135.0, 0.0)
	sun.light_energy = 1.1
	root.add_child(sun)

## Pune inapoi atlasul peste ce a aplicat clasa (varianta „inainte").
func _strip(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = Palette.world_material()
	for c in n.get_children():
		_strip(c)

func _env() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.72, 0.82)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.70, 0.75, 0.82)
	e.ambient_light_energy = 0.55
	return e

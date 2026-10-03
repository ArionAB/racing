extends Node
## Sonda de coliziune pentru kitul Kyoto (int-a): pentru fiecare GLB din
## assets/models/kyoto/ il pune sub un WorldProp (ca DecorManual) si raporteaza
## modul, numarul de forme si caseta corpului fizic rezultat.
##
##   godot --headless --path . res://tools/ProbeKyotoColiziune.tscn
## (scena, nu --script: WorldProp are nevoie de autoload-uri)
##
## Verifica doua lucruri pe care tabelul PROP_COLLISION nu le spune singur:
## (1) casele machiya au hull NUMAI pe miezul de lemn (caseta corpului sub 5,3 m
## adancime, nu 7,2 m cat streasina), (2) cilindrul `trunk` are raza din
## TRUNK_RADIUS, nu din latimea coroanei.

func _ready() -> void:
	var root := "res://assets/models/kyoto"
	var files: Array[String] = []
	for sub in DirAccess.get_directories_at(root):
		for f in DirAccess.get_files_at("%s/%s" % [root, sub]):
			if f.ends_with(".glb"):
				files.append("%s/%s/%s" % [root, sub, f])
	files.sort()
	var holder_script: Script = load("res://scenes/props/world_prop.gd")
	print("%-26s %-6s %6s  %s" % ["model", "mod", "forme", "caseta corp (x,y,z) m"])
	for path in files:
		var stem := path.get_file().get_basename()
		var holder := Node3D.new()
		holder.name = "H_" + stem
		var inst := (load(path) as PackedScene).instantiate() as Node3D
		holder.add_child(inst)
		holder.set_script(holder_script)
		root_add(holder)
		var body: StaticBody3D = null
		# _ready ruleaza la add_child; corpul e FRATE al modelului, adica copil
		# al holder-ului.
		for c in holder.get_children():
			if c is StaticBody3D:
				body = c
		if body == null:
			print("%-26s %-6s %6d" % [stem, "none", 0])
		else:
			var mn := Vector3(1e9, 1e9, 1e9)
			var mx := Vector3(-1e9, -1e9, -1e9)
			var n := 0
			var mode := String(body.get_meta("mod_coliziune", "?"))
			var cyl := ""
			for cs in body.get_children():
				var shp := cs as CollisionShape3D
				if shp == null:
					continue
				n += 1
				if shp.shape is CylinderShape3D:
					var cy := shp.shape as CylinderShape3D
					cyl = " cilindru r=%.2f h=%.1f" % [cy.radius, cy.height]
					mn = mn.min(shp.position - Vector3(cy.radius, cy.height * 0.5, cy.radius))
					mx = mx.max(shp.position + Vector3(cy.radius, cy.height * 0.5, cy.radius))
				else:
					var pts: PackedVector3Array
					if shp.shape is ConvexPolygonShape3D:
						pts = (shp.shape as ConvexPolygonShape3D).points
					elif shp.shape is ConcavePolygonShape3D:
						pts = (shp.shape as ConcavePolygonShape3D).get_faces()
					for p in pts:
						mn = mn.min(p)
						mx = mx.max(p)
			var sz := mx - mn
			print("%-26s %-6s %6d  %.1f x %.1f x %.1f  z[%.1f..%.1f]%s"
				% [stem, mode, n, sz.x, sz.y, sz.z, mn.z, mx.z, cyl])
		holder.queue_free()
	get_tree().quit(0)


func root_add(n: Node) -> void:
	add_child(n)

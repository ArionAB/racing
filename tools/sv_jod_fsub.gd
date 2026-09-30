extends Node
## Sonda pentru „orasul sub tine" (Track17, POI F): drumul pe 0.40-0.75,
## grila de teren randat in jurul stancii fortului si casele OrasFill.
##   godot --headless --path . res://tools/SvJodFsub.tscn

const SCENE := "res://scenes/tracks/Track17.tscn"
var tr: Track

func _ready() -> void:
	tr = (load(SCENE) as PackedScene).instantiate() as Track
	add_child(tr)
	for k in 4:
		await get_tree().process_frame
	var b := tr.baked
	var n := b.size()
	print("\n--- drum ---")
	var f := 0.40
	while f <= 0.76:
		var i := int(f * n)
		print("  %.3f  (%.1f, %+.1f, %.1f)" % [f, b[i].x, b[i].y, b[i].z])
		f += 0.01
	print("\n--- grila teren (mesh) x 40..260 step 15, z -270..30; dNN = distanta la drum <40 ---")
	var hdr := "   z|x "
	for x in range(40, 261, 15):
		hdr += "%5d" % x
	print(hdr)
	for z in range(-270, 31, 15):
		var row := "%6d " % z
		for x in range(40, 261, 15):
			var y: float = tr.call("_terrain_mesh_y", float(x), float(z))
			var dmin := INF
			for p in b:
				dmin = minf(dmin, Vector2(p.x - x, p.z - z).length())
			row += ("  R%2.0f" % y) if dmin <= 8.0 else (("%5.0f" % y) if dmin >= 40.0 else ("  ~%2.0f" % y))
		print(row)
	for k in 30:
		await get_tree().physics_frame
	var cf := tr.get_node_or_null("OrasFill")
	if cf:
		print("\n--- OrasFill stats: ", cf.get("stats"))
	get_tree().quit(0)

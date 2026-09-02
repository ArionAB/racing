extends Node
## Ce SLOTURI de paleta ating chiar piesele salii subterane.
##
## Exista fiindca runda 3 a discutat culoarea peretilor din amintire ("brun cald",
## "portocaliu saturat") in loc s-o citeasca. Slotul e o coordonata U in atlas:
## se citeste din mesh, nu din numele piesei (memoria `aria-slotului-spune-cat-nu-ce`).
const PIESE := [
	"structures/hall_alcove", "structures/hall_column",
	"structures/hall_ceiling_module", "structures/hall_arch",
	"structures/church_arch", "structures/cave_entrance",
	"structures/vent_shaft", "props/torch",
]


func _ready() -> void:
	var atlas := Image.load_from_file("res://assets/textures/palette_atlas.png")
	for p in PIESE:
		var path := "res://assets/models/cappadocia/%s.glb" % p
		var ps := load(path) as PackedScene
		if ps == null:
			print("%-34s LIPSA" % p)
			continue
		var root := ps.instantiate()
		var hist := {}
		_walk(root, hist)
		root.free()
		var keys := hist.keys()
		keys.sort()
		var parts := PackedStringArray()
		for k: int in keys:
			var x := int((float(k) + 0.5) / 32.0 * float(atlas.get_width()))
			var c := atlas.get_pixel(x, atlas.get_height() / 2)
			parts.append("%d(%s):%d" % [k, c.to_html(false), hist[k]])
		print("%-34s %s" % [p, " ".join(parts)])
	get_tree().quit()


func _walk(n: Node, hist: Dictionary) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null:
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			for v in uv:
				var slot := clampi(int(v.x * 32.0), 0, 31)
				hist[slot] = int(hist.get(slot, 0)) + 1
	for c in n.get_children():
		_walk(c, hist)

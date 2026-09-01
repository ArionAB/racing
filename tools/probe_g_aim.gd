extends Node
## Unde se uita camera la 0.80/0.86/0.92, si pe ce azimuturi ale inelului cade
## privirea — ca ferestrele sa fie puse UNDE SE UITA OMUL, nu unde e comod.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeGAim.tscn
##
## Lectia `masoara-inainte-nu-langa`, aplicata la inel: o firida pusa pe un
## azimut "dinspre vale" poate fi in spatele camerei tot urcusul.

const AXIS := Vector2(-302.02, 6.00)

func _ready() -> void:
	var track: Node = (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var path := track.get_node_or_null("Path") as Path3D
	var curve: Curve3D = path.curve
	var L := curve.get_baked_length()
	print("
=== POI G — pe ce azimuturi ale inelului cade privirea ===")
	for frac: float in [0.80, 0.84, 0.86, 0.88, 0.92, 0.96]:
		var pos := curve.sample_baked(frac * L)
		var ahead := curve.sample_baked(fmod(frac * L + 10.0, L))
		var fwd := (ahead - pos).normalized()
		var eye := pos + Vector3.UP * 10.0 - fwd * 12.5
		# azimutul masinii pe inel
		var dm := Vector2(pos.x - AXIS.x, pos.z - AXIS.y)
		var az_masina := rad_to_deg(atan2(dm.y, dm.x))
		# unde intalneste privirea inelul: proiecteaza inainte 40 m
		var target := pos + fwd * 40.0
		var dt := Vector2(target.x - AXIS.x, target.z - AXIS.y)
		var az_privire := rad_to_deg(atan2(dt.y, dt.x))
		print("  frac %.2f: masina y=%5.1f az=%7.1f  |  privirea cade pe az %7.1f"
			% [frac, pos.y, az_masina, az_privire])
	print("
=== firidele existente ===")
	var fer: Node = track.get_node_or_null("DecorManual/G) Stanca goala/Ferestre")
	for f in fer.get_children():
		var o := (f as Node3D).global_transform.origin
		var d := Vector2(o.x - AXIS.x, o.z - AXIS.y)
		print("  %-8s az %7.1f  y %5.1f" % [String(f.name),
			rad_to_deg(atan2(d.y, d.x)), o.y])
	get_tree().quit()

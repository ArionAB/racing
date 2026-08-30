extends Node
## DIRECTIA benzii pe portiunea cornisei, ca sa stiu cat coteste drumul.
##
## Criticul: „aceeasi faleza se vede de doua ori" — asta cere ca drumul sa
## SCHIMBE directia destul cat peretele sa treaca prin fata privirii. Un drum
## care merge drept tine peretele mereu pe muchie, oricat de bine ar fi taiat.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var prev := -999.0
	for k in 26:
		var f: float = 0.20 + 0.008 * float(k)
		var i := int(f * float(n)) % n
		var j := (i + 6) % n
		var d := s.baked_point(j) - s.baked_point(i)
		var head := rad_to_deg(atan2(d.z, d.x))
		var delta := 0.0
		if prev > -900.0:
			delta = wrapf(head - prev, -180.0, 180.0)
		prev = head
		print("frac %.3f  directie %+7.1f  delta %+6.1f" % [f, head, delta])
	get_tree().quit()

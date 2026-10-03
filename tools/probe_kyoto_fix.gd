extends Node
## Sonda de GEOMETRIE Kyoto (kogarashi + trenul G2). Ruleaza ca SCENA, headless:
##   godot --headless --path . res://tools/ProbeKyotoFix.tscn
## Optional: PTS="x,z;x,z" (puncte de lume) pentru a le raporta ca distanta pe ruta.
##
## Raporteaza, in METRI pe curba coapta reala (route.dists), nu din fractii
## rotunjite: lungimea totala, capatul podului Tsutenkyo, kogarashi (distanta
## dupa pod, pana la intrarea in arcul E / tunelul de torii) si unghiul dintre
## axa lunga a figurii Lissajous si tangenta soselei (tinta: 90 grade).

const TRACK := "res://scenes/tracks/Track18.tscn"


func _d_of(route: TrackRoute, p: Vector3) -> float:
	return route.dists[route.closest_index_global(p)]


func _ready() -> void:
	var track: Track = (load(TRACK) as PackedScene).instantiate()
	add_child(track)
	for _i in 6:
		await get_tree().process_frame
	var route := track.route_at(0)
	var total: float = route.dists[route.baked.size()]
	print("lungime curba coapta: %.1f m" % total)
	var tsu := track.get_node("Poduri/Tsutenkyo")
	var d_end: float = float(tsu.get("frac_to")) * total
	var d_start: float = float(tsu.get("frac_from")) * total
	print("pod Tsutenkyo: %.1f - %.1f m (frac %.3f-%.3f, %.1f m lung)" % [
		d_start, d_end, float(tsu.get("frac_from")), float(tsu.get("frac_to")), d_end - d_start])
	var kog := track.get_node_or_null("Hazarduri/Kogarashi") as Node3D
	if kog != null:
		var i := route.closest_index_global(kog.global_position)
		var d: float = route.dists[i]
		var tan3: Vector3 = (route.baked[mini(i + 2, route.baked.size() - 1)] - route.baked[maxi(i - 2, 0)])
		var tan2 := Vector2(tan3.x, tan3.z).normalized()
		var yaw := deg_to_rad(float(kog.get("path_yaw_deg")))
		# X local rotit cu yaw in jurul lui Y (conventia Godot): (cos, -sin) in (x, z).
		var ax := Vector2(cos(yaw), -sin(yaw))
		var ang := rad_to_deg(acos(clampf(absf(ax.dot(tan2)), 0.0, 1.0)))
		var lat: float = Vector2(kog.global_position.x - route.baked[i].x, kog.global_position.z - route.baked[i].z).length()
		print("kogarashi: d=%.1f m (frac %.4f) = %.1f m dupa capatul podului; abatere laterala fata de axa %.1f m; unghi axa-Lissajous/tangenta = %.1f grade (tinta 90)" % [
			d, d / total, d - d_end, lat, ang])
		print("  pana la intrarea in arcul E (0.4833): %.1f m" % (0.4833 * total - d))
	var pts := OS.get_environment("PTS")
	if not pts.is_empty():
		for pr in pts.split(";"):
			var xz := pr.split(",")
			var dd := _d_of(route, Vector3(float(xz[0]), 12.0, float(xz[1])))
			print("punct (%s): d=%.1f m (frac %.4f) = %.1f m dupa capatul podului" % [pr, dd, dd / total, dd - d_end])
	get_tree().quit()

extends Node
## Care semn de azimut pune soarele in EST (identitatea de zori, brief §4).
##
## Baleiajul din probe_capp_azimut e simetric: |cross| nu are semn, deci y si
## y+180 dau acelasi scor de "taie banda". Numai unul din ele are soarele peste
## vale, la rasarit. Aici se rezolva semnul, o data, si se scrie de unde vine
## soarele in coordonate de lume.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappEst.tscn -- --track=6


func _ready() -> void:
	await get_tree().process_frame
	print("")
	print("=== de unde vine soarele, pe candidati ===")
	print("  conventie: +X = est, -Z = nord (Godot)")
	for ydeg in [-30, 5, 25, 185, 205, -155, -175]:
		var basis := Basis.from_euler(Vector3(deg_to_rad(-13.0), deg_to_rad(float(ydeg)), 0.0))
		var d := -basis.z  # incotro bat fotonii = incotro se intinde umbra
		var sh := Vector2(d.x, d.z).normalized()
		# soarele e in directia OPUSA fotonilor
		var sun_dir := -sh
		var compass := ""
		if sun_dir.x > 0.35: compass += "EST "
		if sun_dir.x < -0.35: compass += "VEST "
		if sun_dir.y < -0.35: compass += "nord"
		if sun_dir.y > 0.35: compass += "sud"
		print("  y=%4d  umbra->(%+.2f,%+.2f)  soare dinspre (%+.2f,%+.2f)  %s" % [
			ydeg, sh.x, sh.y, sun_dir.x, sun_dir.y, compass])
	get_tree().quit(0)

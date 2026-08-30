extends Node
## Pe ce parte a benzii trebuie sa stea hornul ca UMBRA LUI SA TAIE DRUMUL.
##
## Nu se mai deriva din euler (prima incercare a iesit pe dos, si captura de la
## 0.14 arata umbrele plecand de langa drum in loc sa-l traverseze). Se citeste
## direct din nodul de lumina construit de pista si se proiecteaza pe teren.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappShadow.tscn -- --track=6


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sun: DirectionalLight3D = null
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is DirectionalLight3D:
			sun = n as DirectionalLight3D
	if sun == null:
		print("VERDICT: nu exista DirectionalLight3D")
		get_tree().quit(1)
		return

	# Fotonii merg pe -Z al bazei luminii; umbra se intinde pe acelasi sens.
	var dir := -sun.global_transform.basis.z
	var shadow := Vector2(dir.x, dir.z).normalized()
	print("")
	print("=== soarele si umbrele pe POI B ===")
	print("  rotatie lumina  %s" % str(sun.global_rotation_degrees))
	print("  directia fotonilor  (%.3f, %.3f, %.3f)" % [dir.x, dir.y, dir.z])
	print("  umbra pe XZ         (%.3f, %.3f)" % [shadow.x, shadow.y])
	print("  elevatie            %.1f grade" % rad_to_deg(asin(-dir.y)))
	print("")
	print("  frac   side(+) . umbra   hornul care TAIE drumul sta pe partea")
	var n := track.baked.size()
	var f := 0.045
	while f <= 0.176:
		var i := int(f * float(n)) % n
		var s := track._side_at(i)
		var d := Vector2(s.x, s.z).normalized().dot(shadow)
		# Un horn pe partea S arunca umbra catre `shadow`. Umbra ajunge pe
		# sosea daca pleaca DINSPRE acea parte spre ax, adica daca S puncteaza
		# INVERS fata de umbra: dot(S, umbra) < 0.
		print("  %.3f   %+6.3f            %s" % [f, d, "MINUS" if d > 0.0 else "PLUS"])
		f += 0.010
	# VERIFICARE DIRECTA, nu deductie: se ia un punct la 10 m pe fiecare parte,
	# se proiecteaza umbra unui horn de 14 m de acolo si se masoara cat de
	# aproape trece de axul benzii. Semnul lui `_side_at` a mai pacalit o data
	# runda asta, deci raspunsul se MASOARA.
	print("")
	print("  proiectie reala a varfului unui horn de 14 m asezat la 10 m lateral:")
	print("  frac   partea   dist. umbrei fata de ax (m)   taie banda de 6.5?")
	var lung := 14.0 / tan(deg_to_rad(13.0))
	f = 0.045
	while f <= 0.176:
		var i := int(f * float(n)) % n
		var p := track.baked[i]
		var s := track._side_at(i)
		for sgn: float in [-1.0, 1.0]:
			var base := p + s * sgn * 10.0
			var tip := base + Vector3(shadow.x, 0.0, shadow.y) * lung
			# distanta de la varful umbrei la axul benzii, pe lateral
			var rel := tip - p
			var lat := absf(rel.x * s.x + rel.z * s.z)
			var side_of := (rel.x * s.x + rel.z * s.z)
			print("  %.3f   %s     %6.1f (semn %+.1f)          %s" % [
				f, "MINUS" if sgn < 0.0 else "PLUS ", lat, side_of,
				"DA" if side_of * sgn < 0.0 else "nu"])
		f += 0.030
	print("")
	get_tree().quit(0)

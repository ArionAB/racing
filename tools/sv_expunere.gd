extends Node
## Cat de tare arde lumina suprafetele, fata de culoarea lor de sursa?
##
## Constatarea POI F: carosabilul si frunzisul urca AMANDOUA cu ~0,15 in
## valoare fata de tinta lor de atlas. Daca amandoua urca la fel, cauza e
## expunerea/lumina, nu alegerea de piesa. Sonda masoara pe captura reala.
const TRACK := "res://scenes/tracks/Track15.tscn"

func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8:
		await get_tree().process_frame
	var env := _find_env(t)
	var sun := _find_sun(t)
	print("=== lumina pe Machu Picchu ===")
	if sun != null:
		print("sun_energy: %.3f   culoare: %s" % [sun.light_energy, sun.light_color])
	if env != null and env.environment != null:
		var e := env.environment
		print("ambient_energy: %.3f" % e.ambient_light_energy)
		print("exposure: %.3f" % e.tonemap_exposure)
		print("tonemap mode: %d" % e.tonemap_mode)
		print("raport soare/ambient: %.2f" % (sun.light_energy / maxf(e.ambient_light_energy, 0.001)))
	get_tree().quit(0)

func _find_env(n: Node) -> WorldEnvironment:
	if n is WorldEnvironment:
		return n as WorldEnvironment
	for c in n.get_children():
		var r := _find_env(c)
		if r != null:
			return r
	return null

func _find_sun(n: Node) -> DirectionalLight3D:
	if n is DirectionalLight3D:
		return n as DirectionalLight3D
	for c in n.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null

extends Node
## Masoara canionul rosu (POI D) in jurul hornului: cota terenului pe un profil
## transversal, ca hornul cazut sa se sprijine pe pamant, nu pe aer.

const SITE := Vector3(143.54, 25.98, -176.09)
const DIRX := -0.9646
const DIRZ := -0.2639

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sx := DIRZ
	var sz := -DIRX
	print("--- profil transversal la frac 0.460 (lateral: - stanga, + dreapta) ---")
	for k in range(-9, 10):
		var lat := float(k) * 2.0
		var x := SITE.x + sx * lat
		var z := SITE.z + sz * lat
		print("  lat %+6.1f m -> (%8.2f, %8.2f)  teren y = %7.2f" % [
			lat, x, z, track._sampler.ground_y(x, z)])

	print("--- profil LONGITUDINAL pe axa drumului (de la frac 0.460) ---")
	for k in range(-6, 13):
		var d := float(k) * 4.0
		var x := SITE.x + DIRX * d
		var z := SITE.z + DIRZ * d
		print("  long %+6.1f m -> (%8.2f, %8.2f)  teren y = %7.2f" % [
			d, x, z, track._sampler.ground_y(x, z)])
	get_tree().quit(0)

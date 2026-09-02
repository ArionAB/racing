extends Node3D
## Cotele pentru masele prabusite de la baza hornurilor din bazinul drept.
##
## Defectul 3 al rundei 2 cere ca piatra sa intalneasca solul printr-un gradient
## de moloz. DOUA incercari au picat inainte de asta, si amandoua pe acelasi
## motiv — PIESA, nu asezarea:
##   1. `cracked_chimney_c` (72 buc): 67% din arie pe slotul 2 (SAND_SHADOW,
##      maro ars). Pe un platou de tuf crem a iesit un camp de CARAMIZI ruginii
##      — o a treia nuanta care nu era nici in horn, nici in sol.
##   2. hornuri intregi micsorate la 0.13-0.42 (81 buc): fiecare si-a pastrat
##      calota inchisa si silueta de clepsidra, deci la 1,5-4 m inaltime au
##      citit SCAUNELE cu capac negru, nu bolovani.
## Lectia e cea deja platita pe POI D: mai mult dintr-un lucru uniform face masa
## mai uniforma, nu mai bogata. Deci acum: PUTINE si MARI, din piesa care chiar
## e o masa prabusita (`cracked_chimney_b`, 20,9 x 6,5 m), asezate culcat la
## poalele hornurilor mari.
const FEET := [
	[-53.437, -197.136], [-150.827, -240.713], [-167.760, -241.912],
	[-158.122, -212.475], [-205.349, -242.302], [-277.907, -256.135],
]

func _ready() -> void:
	var track := get_parent().get_node_or_null("Track13")
	await get_tree().process_frame
	var sampler = track.get("_sampler")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260901
	var k := 0
	for f in FEET:
		for i in range(2):
			var a: float = rng.randf() * TAU
			var d: float = rng.randf_range(9.0, 17.0)
			var x: float = float(f[0]) + cos(a) * d
			var z: float = float(f[1]) + sin(a) * d
			var y: float = sampler.ground_y(x, z)
			var sc: float = rng.randf_range(0.55, 0.95)
			k += 1
			# infundata pe ~40% din inaltimea ei: o masa prabusita sta IN
			# pamant, nu pe el.
			print("T%02d (%.3f, %.3f, %.3f) scale %.3f yaw %.1f" % [
				k, x, y - 6.54 * sc * 0.40, z, sc, rng.randf() * 360.0])
	get_tree().quit()

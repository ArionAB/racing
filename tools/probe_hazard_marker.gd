extends Node
## Sonda gimmickurilor plasate vizual ([HazardMarker] sub o pista).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHazardMarker.tscn
##
## Ca SCENA, nu cu --script: pista se construieste in _ready si are nevoie de
## autoload-uri (AudioManager). Cu `--script`, `car.gd` si hazardele nici nu
## compileaza. Acelasi motiv ca la probe_peaks.gd / probe_layout.gd.
##
## Construieste ACEEASI pista de doua ori — o data goala, o data cu cate un
## HazardMarker din fiecare tip — si compara ce obstacole exista in scena.
## Acelasi nume de pista = aceeasi lume, deci orice diferenta vine din noduri.
##
## Doua verdicte, si al doilea e cel care conteaza:
##   1. obstacolul EXISTA: apare un nod de clasa asteptata pentru fiecare tip;
##   2. fractia URMEAZA nodul: doua noduri in locuri diferite dau fractii
##      diferite, iar fractia derivata cade langa cea plantata. Fara asta,
##      un obstacol ar aparea mereu in acelasi loc si (1) ar trece la fel.

## Ce clasa de nod trebuie sa apara pentru fiecare tip plantat.
## Doar tipurile ieftine de construit — trenul si tromba isi aduc estacada,
## respectiv o coloana de apa, si nu adauga nimic la ce se verifica aici.
## Valoarea e o LISTA de clase acceptate, nu una singura: `_build_hazard` are un
## lant de rezerve documentat (model de tema -> excavator -> cutie placeholder),
## deci pe o pista fara `hazard_model` bariera mobila iese legitim ca
## ExcavatorHazard. Sonda verifica REGIA — ca nodul ajunge la constructorul lui
## si acesta produce ceva — nu ce alege tema.
var expect := {
	HazardMarker.Kind.SLIDING: ["SlidingHazard", "ExcavatorHazard"],
	HazardMarker.Kind.ROCKFALL: ["RockfallHazard"],
	HazardMarker.Kind.CAROUSEL: ["CarouselHazard"],
	HazardMarker.Kind.DEFLECTOR: ["DeflectorHazard"],
}

## Unde se planteaza fiecare, ca fractie din tur.
const FRACS: Array[float] = [0.15, 0.35, 0.55, 0.75]
## Cat de departe are voie sa cada fractia derivata de cea plantata.
## Nodul se aseaza pe un punct baked, deci fractia derivata cade pe cel mai
## apropiat esantion, nu exact pe valoarea ceruta.
const FRAC_TOLERANCE: float = 0.02


func _ready() -> void:
	await get_tree().process_frame

	var plain := await _census(false)
	var planted := await _census(true)

	print("")
	print("=== Sonda HazardMarker ===")
	print("fara noduri: ", _brief(plain["census"]))
	print("cu noduri:   ", _brief(planted["census"]))

	var failed := false

	print("\nobstacole construite:")
	for kind in expect:
		var wants: Array = expect[kind]
		var got := 0
		var via := ""
		for want in wants:
			var d: int = int(planted["census"].get(want, 0)) \
					- int(plain["census"].get(want, 0))
			if d > got:
				got = d
				via = String(want)
		var good := got >= 1
		if not good:
			failed = true
		print("  %-10s -> %-16s delta=%+d  %s" % [
			HazardMarker.Kind.keys()[kind],
			via if good else String(wants[0]), got,
			"OK" if good else "PROBLEMA"])

	print("\nfractia derivata din pozitia nodului:")
	var derived: Array = planted["fracs"]
	if derived.size() != FRACS.size():
		print("  PROBLEMA: %d noduri colectate, asteptate %d"
				% [derived.size(), FRACS.size()])
		failed = true
	for i in mini(derived.size(), FRACS.size()):
		var want_f: float = FRACS[i]
		var got_f := float(derived[i])
		var delta: float = absf(got_f - want_f)
		var good := delta < FRAC_TOLERANCE
		if not good:
			failed = true
		print("  plantat %.2f -> derivat %.3f (delta %.3f) %s"
				% [want_f, got_f, delta, "OK" if good else "PROBLEMA"])

	print("")
	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


## Construieste pista (cu sau fara noduri) si intoarce censusul + fractiile.
func _census(with_markers: bool) -> Dictionary:
	var track := TrackFromPath.new()
	track.custom_name = "SondaHazard" # acelasi nume = aceeasi lume in ambele rulari

	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var fracs: Array[float] = []
	if with_markers:
		# Grupul intra in arbore doar pe ramura cu noduri — altfel ar ramane
		# orfan si l-ar strange colectorul chiar sub mana noastra.
		#
		# Are transformare proprie DINADINS: colectorul e recursiv si trece prin
		# `to_local`. Daca ar lipsi, fractiile derivate ar fi gresite exact cu
		# offsetul asta, si sonda ar trebui s-o vada.
		var group := Node3D.new()
		group.name = "Hazards"
		group.position = Vector3(12.0, 3.0, -7.0)
		track.add_child(group)

		# Pozitiile se pot alege abia acum: `baked` exista dupa prima constructie.
		var baked: Array = track.baked
		var kinds: Array = expect.keys()
		for i in kinds.size():
			var idx := int(float(baked.size()) * FRACS[i]) % baked.size()
			var marker := HazardMarker.new()
			marker.kind = kinds[i]
			marker.position = Vector3(baked[idx]) - group.position
			group.add_child(marker)
		track.rebuild()
		await get_tree().process_frame
		for hz in track._node_hazards():
			fracs.append(float(hz["frac"]))

	var out := {"census": _walk_census(track), "fracs": fracs}
	track.queue_free()
	await get_tree().process_frame
	return out


func _walk_census(from: Node) -> Dictionary:
	var out := {}
	_walk(from, out)
	return out


func _walk(n: Node, out: Dictionary) -> void:
	var s: Script = n.get_script()
	if s != null:
		var g: String = s.get_global_name()
		if not g.is_empty():
			out[g] = int(out.get(g, 0)) + 1
	for c in n.get_children():
		_walk(c, out)


## Doar clasele de hazard, ca raportul sa nu fie un perete de decor.
func _brief(census: Dictionary) -> String:
	var parts: Array[String] = []
	for k in census:
		var nm := String(k)
		if nm.ends_with("Hazard") or nm == "HazardMarker":
			parts.append("%s=%d" % [nm, census[k]])
	parts.sort()
	return ", ".join(parts) if parts.size() > 0 else "(niciun hazard)"

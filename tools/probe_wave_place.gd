extends Node
## Sonda plasarii valului fara cod (#247).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWavePlace.tscn
##
## `WaveSurge` era deja generic — mergea pe orice pista cu mare — dar singurul
## mod de a pune un val era sa scrii cod. Sonda verifica cele trei lucruri pe
## care le cere issue-ul:
##
##   1. `custom_wave_fracs` chiar construieste valuri, la fractiile cerute.
##   2. DEFAZAREA se pastreaza: doua valuri pe aceeasi pista nu bat la unison.
##      Daca ar porni simultan, ar arata a mecanism, nu a mare.
##   3. REFUZ CURAT fara mare: pe o tema fara apa nu se construieste nimic (si
##      nici nu crapa). Un val plutind peste desert, la o cota luata din senin,
##      ar fi absurd vizual dar tacut in cod.
##
## Plus: kind-ul WAVE din [HazardMarker] ajunge la acelasi constructor.

const FRACS: Array[float] = [0.30, 0.70]


func _ready() -> void:
	await get_tree().process_frame

	print("")
	print("=== Sonda val plasabil ===")
	var failed := false

	# --- 1 + 2: pe o tema CU mare
	var sea := await _count("island", FRACS, false)
	var built: int = sea["waves"]
	var ok_count := built == FRACS.size()
	if not ok_count:
		failed = true
	print("\ntema cu mare (island):")
	print("  valuri construite -> %d (cerute %d)  %s"
			% [built, FRACS.size(), "OK" if ok_count else "PROBLEMA"])

	var phases: Array = sea["phases"]
	var distinct := phases.size() >= 2 \
		and absf(float(phases[0]) - float(phases[1])) > 0.05
	if not distinct:
		failed = true
	print("  defazaje          -> %s  %s"
			% [_fmt(phases),
			"OK (nu bat la unison)" if distinct else "PROBLEMA"])

	# --- 3: pe o tema FARA mare
	var desert := await _count("desert", FRACS, false)
	var none: int = desert["waves"]
	var refused := none == 0
	if not refused:
		failed = true
	print("\ntema fara mare (desert):")
	print("  valuri construite -> %d  %s"
			% [none, "OK (refuz curat, cu avertisment)" if refused
			else "PROBLEMA (val plutind peste desert)"])

	# --- kind-ul din marker
	var marked := await _count("island", [], true)
	var via_marker: int = marked["waves"]
	var marker_ok := via_marker == 1
	if not marker_ok:
		failed = true
	print("\nprin HazardMarker (kind = WAVE):")
	print("  valuri construite -> %d  %s"
			% [via_marker, "OK" if marker_ok else "PROBLEMA"])

	print("")
	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


## Construieste o pista cu tema ceruta si numara valurile.
func _count(theme: String, fracs: Array, with_marker: bool) -> Dictionary:
	var t := TrackFromPath.new()
	# Acelasi nume = aceeasi lume, ca diferentele sa vina din ce testam.
	t.custom_name = "SondaVal"
	t.custom_theme = theme
	var typed: Array[float] = []
	for f in fracs:
		typed.append(float(f))
	t.custom_wave_fracs = typed
	get_tree().root.add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame

	if with_marker:
		var m := HazardMarker.new()
		m.kind = HazardMarker.Kind.WAVE
		var n: int = t.baked.size()
		m.position = Vector3(t.baked[int(float(n) * 0.5) % n])
		t.add_child(m)
		t.rebuild()
		await get_tree().process_frame

	var found: Array[Node] = []
	_walk(t, found)
	var phases: Array[float] = []
	for w: WaveSurge in found:
		phases.append(w.phase)
	var out := {"waves": found.size(), "phases": phases}
	t.queue_free()
	await get_tree().process_frame
	return out


func _walk(n: Node, out: Array[Node]) -> void:
	if n is WaveSurge:
		out.append(n)
	for c in n.get_children():
		_walk(c, out)


func _fmt(values: Array) -> String:
	var parts: Array[String] = []
	for v in values:
		parts.append("%.3f" % float(v))
	return "[" + ", ".join(parts) + "]"

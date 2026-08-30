extends Node
## SE PLIAZA taietura pe cotitura?
##
## Capturile arata la mijlocul cadrului cochilii suprapuse in loc de perete.
## Ipoteza: pe INTERIORUL virajului coloanele vecine se incaleca — fiecare sta
## la `off` metri pe normala ei, si cand raza interioara scade sub `off`
## normalele converg dincolo de centru, deci punctele vin unul peste altul.
##
## PRIMA VERSIUNE A ACESTEI SONDE A MINTIT: esantiona pe fractii mai dese decat
## pasul benzii, deci doua esantioane cadeau pe ACELASI punct baked si avansul
## iesea 0.000 peste tot — "pliere" pe toata lungimea, inclusiv pe drept. Se
## merge acum pe INDICE de punct baked, cum construieste si peretele.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var off := 8.2
	var i0 := int(0.20 * float(n))
	var i1 := int(0.40 * float(n))
	var folds := 0
	var worst := 1e9
	var worst_f := 0.0
	for i in range(i0, i1):
		var p := s.baked_point(i % n)
		var q := s.baked_point((i + 1) % n)
		var fa := p + s.side_at(i % n) * -1.0 * off
		var fb := q + s.side_at((i + 1) % n) * -1.0 * off
		var fwd := (q - p)
		if fwd.length() < 1e-5:
			continue
		var along := (fb - fa).dot(fwd.normalized())
		if along < worst:
			worst = along
			worst_f = float(i) / float(n)
		if along <= 0.0:
			folds += 1
	print("rulaj perete %.1f m · interval frac 0.20-0.40" % off)
	print("pasi cu talpa care merge INAPOI (pliere): %d" % folds)
	print("cel mai mic avans pe pas: %+.3f m la frac %.4f" % [worst, worst_f])
	print("VERDICT: %s" % ("SE PLIAZA" if folds > 0 else "nu se pliaza"))
	get_tree().quit()

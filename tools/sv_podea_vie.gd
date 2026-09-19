extends Node
## Ajung piesele de podea in LUME, sau raman doar in .tscn?
##
## Capturile ies identice la BIT cu cele fara podea, desi .tscn are 5633 de
## instante cu pozitii reale. Doua ipoteze, si sonda le separa:
##   (a) nodurile nu se construiesc  -> multimesh e null / instance_count 0
##   (b) se construiesc dar nu se vad -> instance_count corect, deci e
##       incadrare sau culling, nu mecanism
##
## `FlockProp._build()` ruleaza prin `call_deferred`, deci se asteapta cadre
## inainte de a numara (memoria decorul-amanat-nu-e-in-captura).
const TRACK := "res://scenes/tracks/Track15.tscn"

func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate()
	get_tree().root.add_child(t)
	# Generos: _build e deferred, iar samplerul pistei se face tot in _ready.
	for i in 12:
		await get_tree().process_frame
	var zona := t.get_node_or_null("DecorManual/ZonePodeaVale")
	if zona == null:
		print("EROARE: nu exista nodul ZonePodeaVale")
		get_tree().quit(1)
		return
	var noduri := 0
	var cu_mm := 0
	var instante := 0
	var vizibile := 0
	var nenule := 0
	var y_min := INF
	var y_max := -INF
	for c in zona.get_children():
		noduri += 1
		var mmi := c as MultiMeshInstance3D
		if mmi == null:
			continue
		if mmi.visible and mmi.is_visible_in_tree():
			vizibile += 1
		if mmi.multimesh == null:
			continue
		cu_mm += 1
		instante += mmi.multimesh.instance_count
		for i in mmi.multimesh.instance_count:
			var o := mmi.multimesh.get_instance_transform(i).origin
			# x/z se citesc ca martor: daca TOATE cele trei componente ies 0,
			# instanta nu e citita (memoria multimesh-masuratoare-moarta), nu
			# e asezata la zero.
			if absf(o.x) > 0.001 or absf(o.z) > 0.001:
				nenule += 1
			y_min = minf(y_min, o.y)
			y_max = maxf(y_max, o.y)
	print("noduri in zona:      %d" % noduri)
	print("vizibile in arbore:  %d" % vizibile)
	print("cu multimesh CONSTRUIT: %d" % cu_mm)
	print("instante in lume:    %d" % instante)
	if instante > 0:
		print("cote: %.1f .. %.1f" % [y_min, y_max])
		print("instante cu x/z nenul: %d din %d" % [nenule, instante])
	else:
		print("ZERO instante -> _build nu a rulat sau a iesit devreme")
	get_tree().quit(0)

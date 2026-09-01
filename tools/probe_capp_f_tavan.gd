extends SceneTree
## Cat spatiu liber e deasupra carosabilului pe POI F (subteranul), din 0.005 in
## 0.005 de fractie.
##
## [b]De ce nu ajunge `ProbeBuried`.[/b] Garda aia intreaba doar `TerrainBody` —
## adica relieful. Dar caverna de aici NU e sapata in teren: campul de inaltime e
## o functie de (x,z) si peste un punct nu poate avea si podea, si tavan, deci
## sala e facuta din lespezi de decor (`hall_ceiling_module`). Consecinta e ca
## `ProbeBuried` raporteaza `tavane: 0` pe pista asta si trece VERDE chiar daca o
## lespede ar sta pe sosea. Sonda de fata se uita la ce e chiar deasupra masinii,
## indiferent din ce nod vine.
##
## [b]Ce a prins.[/b] Doua lespezi de tavan care intrau in carosabilul de
## intoarcere al elicei (POI G trece PE DEASUPRA salii 2): 4.41 m degajare la
## frac 0.845, sub minimul de 4.5 m. Defectul exista de dinaintea rundei de arta
## si nicio garda nu-l vedea.
##
## Ramane 3.88 m la frac 0.785 — acolo e chiar pasajul elicei peste ea insasi
## (`custom_overpass_ranges`, brief §2 POI G), verificat identic pe HEAD.
func _init() -> void:
	var ps := load("res://scenes/tracks/Track13.tscn") as PackedScene
	var tr := ps.instantiate()
	get_root().add_child(tr)
	await process_frame
	await process_frame
	var route = tr.route_at(0)
	var pts = route.baked
	var n = pts.size()
	var space: PhysicsDirectSpaceState3D = tr.get_world_3d().direct_space_state
	print("frac  y_road  tavan_m  ce")
	var f := 0.64
	while f <= 0.86:
		var idx: int = int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.UP * 60.0)
		var hit: Dictionary = space.intersect_ray(q)
		if hit.is_empty():
			print("%.3f  %6.2f   ---     CER (fara tavan)" % [f, p.y])
		else:
			var h: float = (hit.position.y - p.y)
			print("%.3f  %6.2f  %5.2f    %s" % [f, p.y, h, hit.collider.name])
		f += 0.005
	quit()

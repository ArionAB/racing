extends Node
## Sonda covorului de frunze (LeafCarpet) si a frunzelor care cad (LeafFall), Kyoto.
##
## Ruleaza CU FEREASTRA (viewport-urile nu deseneaza headless; aici chiar
## continutul foii de uzura e ce se verifica — o sonda care doar numara instante
## trece si cand pe ecran nu e nimic, memoria `efecte-invizibile-nu-se-numara`).
##
##   godot --path . res://tools/ProbeLeafCarpet.tscn
##
## Verifica:
##   1. panoul exista pe ambele zone, cu UN SINGUR material si triunghiuri > 0;
##   2. UN SINGUR material la frunzele care cad, plafon de count <= 64;
##   3. textura frunzei care cade are muchie continua (salt maxim de alfa
##      intre pixeli vecini < 0.12);
##   4. `Track.stamp_wear_sinks` ajunge la covor (roata pe zona -> stampile), iar
##      in afara zonelor nu se stampileaza nimic;
##   5. stampila chiar SCRIE in foaie: alfa citit inapoi pe linia stampilata,
##      0 pe un punct de control nestampilat;
##   6. panoul nu intra in fizica: nicio coliziune sub nodul covorului.

const TRACK := "res://scenes/tracks/Track18.tscn"
var _fails := 0


func _check(what: String, ok: bool, detail: String = "") -> void:
	print("  %s  %s%s" % ["OK  " if ok else "PICA", what,
		"" if detail.is_empty() else "  (" + detail + ")"])
	if not ok:
		_fails += 1


func _ready() -> void:
	print("=== ProbeLeafCarpet: Track18 (Kyoto) ===")
	var track: Track = (load(TRACK) as PackedScene).instantiate()
	add_child(track)
	for _i in 6:
		await get_tree().process_frame
	var carpet := track.get_node_or_null("CovorFrunze") as LeafCarpet
	_check("CovorFrunze exista si s-a construit", carpet != null and carpet.built)
	if carpet == null or not carpet.built:
		_finish()
		return
	var panels := carpet.find_children("Panou*", "MeshInstance3D", false, false)
	_check("un panou per zona", panels.size() == carpet.zones.size(),
		"%d panouri, %d zone" % [panels.size(), carpet.zones.size()])
	var mats := {}
	for p in panels:
		mats[(p as MeshInstance3D).mesh.surface_get_material(0)] = true
	_check("UN SINGUR material pe tot covorul", mats.size() == 1, "%d" % mats.size())
	_check("triunghiuri > 0", carpet.triangle_count > 0, "%d tri" % carpet.triangle_count)
	print("  info: zone_spans=%s lane_len=%.0f lane_span=%.1f" % [
		carpet.zone_spans, carpet.lane_len, carpet.lane_span])

	var fall := track.get_node_or_null("FrunzeCazatoare") as LeafFall
	_check("FrunzeCazatoare exista", fall != null)
	if fall != null:
		_check("plafon de particule", fall.amount <= LeafFall.MAX_LEAVES,
			"amount=%d plafon=%d" % [fall.amount, LeafFall.MAX_LEAVES])
		_check("UN material la frunzele care cad",
			fall.material_override == LeafFall.leaf_material())
	var step := LeafFall.edge_max_step()
	_check("muchia frunzei care cade: fara trepte", step < 0.12,
		"salt maxim de alfa %.3f" % step)

	# 4/5. Stampile prin lantul real al pistei.
	var route := track.route_at(0)
	var d0 := carpet.zone_spans[0].x
	var mid := d0 + (carpet.zone_spans[0].y - d0) * 0.5
	var i := 0
	while i < route.baked.size() - 1 and route.dists[i] < mid:
		i += 1
	var side: Vector3 = track._side_at(i)
	var before := carpet.stamps_received
	var wheel: Vector3 = route.baked[i] + side * 1.5
	for _k in 6:
		track.stamp_wear_sinks(i, wheel)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	_check("roata pe zona ajunge la covor", carpet.stamps_received - before == 6,
		"%d stampile" % (carpet.stamps_received - before))
	# afara zonelor (start, linia de sosire)
	var out_idx := 20
	var before2 := carpet.stamps_received
	track.stamp_wear_sinks(out_idx, route.baked[out_idx])
	_check("in afara zonelor nu se stampileaza", carpet.stamps_received == before2)
	# Citirea foii (cu fereastra).
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var wear := carpet.get_node("FoaieUzura") as RoadWear
	var img := wear.get_texture().get_image()
	var s := carpet.zone_spans[0]
	var px := int((1.5 / carpet.lane_span + 0.5) * float(RoadWear.MASK_W))
	var py := int((s.z + (route.dists[i] - s.x)) / carpet.lane_len * float(RoadWear.MASK_H))
	var hit := img.get_pixel(clampi(px, 0, RoadWear.MASK_W - 1), clampi(py, 0, RoadWear.MASK_H - 1)).a
	var ctl := img.get_pixel(clampi(px, 0, RoadWear.MASK_W - 1),
		clampi(py + 400, 0, RoadWear.MASK_H - 1)).a
	var opp := img.get_pixel(clampi(RoadWear.MASK_W - px, 0, RoadWear.MASK_W - 1),
		clampi(py, 0, RoadWear.MASK_H - 1)).a
	_check("foaia are alfa pe linia stampilata", hit > 0.5, "alfa %.2f" % hit)
	_check("punct de control (alt loc) curat", ctl < 0.02, "alfa %.3f" % ctl)
	_check("punct de control (alta parte) curat", opp < 0.02, "alfa %.3f" % opp)
	var colliders := carpet.find_children("*", "CollisionObject3D", true, false)
	_check("panoul nu are coliziune", colliders.is_empty())
	_finish()


func _finish() -> void:
	print("VERDICT: %s" % ("OK" if _fails == 0 else "PROBLEMA (%d)" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)

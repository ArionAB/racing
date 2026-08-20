extends Node
## Sonda CAMPULUI DE PLACI CRAPATE (IceFieldHazard, Baikal).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeIceField.tscn [-- --track=3]
##
## Ce verifica:
##   1. SE CONSTRUIESTE: pista are campul, cu placi statice destule, exact
##      atatea placi vii cate s-au cerut, apa si zona de incarcare.
##   2. SEMNUL INCLINARII: o masina parcata langa marginea unei placi vii o
##      inclina spre EA — unghi peste prag si, geometric, coltul incarcat mai
##      jos decat cel opus. Semnele se verifica pe geometrie, nu se ghicesc
##      (lectia din IceSlabHazard, pastrata).
##   3. O SEDERE SCURTA (0.5 s, cat o traversare lenta) NU o rupe — dar
##      stricaciunea se ACUMULEAZA: zabovita in continuare, placa se rupe
##      si masina e repusa. Pragul e cumulativ (BREAK_TIME), nu instantaneu.
##   4. DOUA MASINI pe o placa proaspata o rup RAPID (sub o secunda) ->
##      BROKEN, placa se scufunda si AMBELE sunt repuse; placa revine SOLID.
##   5. SE TRAVERSEAZA: o masina lansata la 30 m/s intra pe rampa campului si
##      iese pe partea cealalta cu viteza — campul ridicat nu e un perete.

func _ready() -> void:
	await get_tree().process_frame
	var idx := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = int(arg.trim_prefix("--track="))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var failed := false
	print("\n=== ProbeIceField — %s ===" % track.track_name)

	var fields: Array[IceFieldHazard] = []
	for child in track.get_children():
		if child is IceFieldHazard:
			fields.append(child)
	if fields.is_empty():
		print("1. constructie: NICIUN camp  PROBLEMA")
		get_tree().quit(1)
		return
	var field := fields[0]
	var plates := field.get_node("Plates") as StaticBody3D
	var static_count := 0
	for c in plates.get_children():
		if c is CollisionShape3D:
			static_count += 1
	var live := field.live_plates()
	var ok1 := static_count > 40 and live.size() == 8 \
		and field.get_node_or_null("Water") != null \
		and field.get_node_or_null("Load") != null
	failed = failed or not ok1
	print("1. constructie: %d placi statice, %d vii, apa+zona  %s (lungime camp %.0f m)" % [
		static_count, live.size(), "OK" if ok1 else "PROBLEMA",
		field.field_length()])

	var car_scene: PackedScene = load("res://scenes/cars/Car.tscn")
	var car: Car = car_scene.instantiate()
	track.add_child(car)
	car.track = track
	await get_tree().process_frame

	# 2. parcata excentric pe prima placa vie: se inclina SPRE masina
	var plate: Dictionary = live[0]
	var body := plate["body"] as AnimatableBody3D
	var origin: Vector3 = (plate["rest"] as Transform3D).origin
	var side: Vector3 = plate["v"]
	var offset: Vector3 = side * 1.8
	car.global_transform = Transform3D(Basis.IDENTITY,
		origin + offset + Vector3.UP * 0.7)
	car.freeze = true
	# 0.5 s, nu 1.5: cu stricaciunea cumulativa, o sedere lunga ar rupe placa
	# inainte sa apucam sa citim unghiul (100 kg rup la ~0.75 s de stat).
	for k in 30:
		await get_tree().physics_frame
	var tilt := field.plate_tilt_deg(0)
	var loaded_y := (body.transform.basis * offset).y
	var opposite_y := (body.transform.basis * -offset).y
	var ok2 := tilt > 1.2 and loaded_y < opposite_y - 0.05
	failed = failed or not ok2
	print("2. incarcata excentric: unghi %.1f grade, colt incarcat dy %.2f, opus dy %.2f  %s" % [
		tilt, loaded_y, opposite_y, "OK" if ok2 else "PROBLEMA"])

	# 3. sederea scurta n-a rupt-o (o traversare nu rupe placa din prima)...
	var ok3: bool = int(plate["state"]) == IceFieldHazard.PlateState.SOLID
	failed = failed or not ok3
	print("3. dupa 0.5 s: stare %s, asezare %.2f m  %s" % [
		"SOLID" if ok3 else "BROKEN", field.plate_sink(0),
		"OK" if ok3 else "PROBLEMA"])

	# ...dar stricaciunea se acumuleaza: zabovita, placa cedeaza si repune.
	var broke_at := -1.0
	for k in 120:
		await get_tree().physics_frame
		if int(plate["state"]) == IceFieldHazard.PlateState.BROKEN:
			broke_at = 0.5 + float(k) / 60.0
			break
	var moved0 := false
	for k in 90:
		await get_tree().physics_frame
		moved0 = moved0 or car.global_position.distance_to(origin) > 25.0
	var ok3b := broke_at > 0.0 and moved0
	failed = failed or not ok3b
	print("   zabovita: rupta la %.2f s de stat, repusa=%s  %s" % [
		broke_at, moved0, "OK" if ok3b else "PROBLEMA"])

	# 4. doua masini pe o placa PROASPATA: se rupe rapid, scufunda, le repune
	var plate2: Dictionary = live[1]
	var origin2: Vector3 = (plate2["rest"] as Transform3D).origin
	var offset2: Vector3 = (plate2["v"] as Vector3) * 1.8
	var car2: Car = car_scene.instantiate()
	track.add_child(car2)
	car2.track = track
	await get_tree().process_frame
	# repunerea din 3b poate lasa masina dezghetata — o inghetam la loc
	car.freeze = true
	car.global_transform = Transform3D(Basis.IDENTITY,
		origin2 + offset2 + Vector3.UP * 0.7)
	car2.freeze = true
	car2.global_transform = Transform3D(Basis.IDENTITY,
		origin2 - offset2 + Vector3.UP * 0.7)
	var max_sink := 0.0
	var broke := false
	var t_break := -1.0
	for k in int(3.0 * 60.0):
		await get_tree().physics_frame
		max_sink = maxf(max_sink, field.plate_sink(1))
		if not broke and int(plate2["state"]) == IceFieldHazard.PlateState.BROKEN:
			broke = true
			t_break = float(k) / 60.0
	var moved1 := car.global_position.distance_to(origin2) > 25.0
	var moved2 := car2.global_position.distance_to(origin2) > 25.0
	var ok4 := broke and t_break < 1.0 and max_sink > 0.22 \
		and moved1 and moved2
	failed = failed or not ok4
	print("4. doua masini: rupta=%s la %.2f s, scufundare max %.2f m, repuse=%s/%s  %s" % [
		broke, t_break, max_sink, moved1, moved2, "OK" if ok4 else "PROBLEMA"])

	# ...si revine la loc dupa ce s-a descarcat
	for k in int(3.5 * 60.0):
		await get_tree().physics_frame
	var ok4b: bool = int(plate2["state"]) == IceFieldHazard.PlateState.SOLID \
		and field.plate_sink(1) < 0.05
	failed = failed or not ok4b
	print("   revine: stare SOLID=%s, scufundare %.2f m  %s" % [
		int(plate2["state"]) == IceFieldHazard.PlateState.SOLID,
		field.plate_sink(1), "OK" if ok4b else "PROBLEMA"])

	# 5. traversare la 30 m/s: rampa te urca, nu te opreste
	car2.queue_free()
	var entry := field._map(0.0, 0.0)
	var exit := field._map(field.field_length(), 0.0)
	var toward := (field._map(6.0, 0.0) - entry).normalized()
	car.freeze = false
	car.global_transform = Transform3D(
		Basis.looking_at(toward, Vector3.UP), entry - toward * 25.0
			+ Vector3.UP * 0.5)
	car.velocity = toward * 30.0
	car.angular_velocity = Vector3.ZERO
	car.race_active = true
	var ctrl := _FollowSpine.new()
	ctrl.field = field
	ctrl.car = car
	car.controller = ctrl
	var min_speed := INF
	var max_s := 0.0
	for k in int(8.0 * 60.0):
		await get_tree().physics_frame
		min_speed = minf(min_speed, car.velocity.length())
		max_s = maxf(max_s, field._to_st(car.global_position).x)
		if car.global_position.distance_to(exit) < 12.0:
			break
	# „a trecut" = ori a ajuns aproape de punctul de iesire, ori abscisa ei a
	# strabatut campul (bucla se opreste cu 12 m inainte de iesire, deci
	# abscisa maxima consemnata e legitim sub lungimea campului; drumul si
	# curbeaza pe cei ~150 m, asa ca nici distanta pura nu ajunge singura).
	var passed := car.global_position.distance_to(exit) < 14.0 \
		or max_s > field.field_length() - 6.0
	var ok5 := passed and min_speed > 12.0
	failed = failed or not ok5
	print("5. traversare: s maxim %.0f/%.0f m, viteza minima %.1f m/s  %s (final la %.0f m de iesire)" % [
		max_s, field.field_length(), min_speed,
		"OK" if ok5 else "PROBLEMA",
		car.global_position.distance_to(exit)])

	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


## Tine axa campului cu un volan minimal: tinteste punctul de pe axa cu 14 m
## in fata. Fara el, drumul curbeaza pe cei ~150 m si masina lansata drept
## iese lateral din culoar desi campul n-a incetinit-o — testul ar pica din
## vina sondei, nu a hazardului.
class _FollowSpine extends CarController:
	var field: IceFieldHazard
	func get_steer() -> float:
		if field == null or car == null:
			return 0.0
		var s := field._to_st(car.global_position).x
		var target := field._map(minf(s + 14.0, field.field_length()), 0.0)
		var fwd := -car.global_transform.basis.z
		fwd.y = 0.0
		var to := target - car.global_position
		to.y = 0.0
		if to.length() < 0.5 or fwd.length() < 0.01:
			return 0.0
		return clampf(fwd.normalized().signed_angle_to(to.normalized(),
			Vector3.UP) * 2.2, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0

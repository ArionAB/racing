@tool # vizibil (si animat) si in preview-ul din editor
class_name CarouselHazard
extends Node3D
## Caruselul: o morisca uriasa plantata in mijlocul soselei, cu vane care
## MATURA toata latimea drumului. Gimmick de TIMING — nu exista linie sigura,
## doar fereastra dintre doua vane. O vezi de la 100m, deci e cinstit:
## incetinesti si o lasi sa treaca, sau intri tare si speri.
##
## Vanele sunt un AnimatableBody3D (corp mutat din cod, cu viteza calculata
## corect de fizica) — te blocheaza onest. Peste asta, un Area3D adauga un
## ghiont pe TANGENTA rotatiei, ca maturatul sa se simta ca o maturare, nu ca
## un stalp. Butucul din centru ramane solid: e si el obstacol, dar vizibil.

## Cat de departe ajunge varful vanei de la butuc (tinut sub half_width ca
## sa nu intre in pereti).
var arm_reach: float = 6.8
var arm_count: int = 2
## Secunde pentru o rotatie completa. Cu 2 vane, o fereastra la fiecare
## jumatate de perioada — destul de lent ca sa fie citibil de departe.
var period: float = 4.2
## m/s adaugati pe tangenta masinii maturate.
var sweep_push: float = 6.5
var vane_colors: Array[Color] = [Color(0.9, 0.22, 0.18), Color(0.98, 0.82, 0.15)]

## Turnul de langa drum, ca morisca sa apartina unei gospodarii (#245).
##
## Gol = butucul procedural de dinainte (talpa + stalp). Cu model, mecanica NU
## se schimba deloc: bratele maturau si maturau la fel, doar ca acum au un motiv
## sa existe acolo.
##
## De ce turn LANGA drum si nu chiar moara peste sosea: paletele lui
## `windmill.glb` au raza 1.3 m si stau la 9.66 m inaltime (masurat) — sunt o
## cladire, nu un obstacol. Mecanica cere 6.8 m de bataie la nivelul masinii.
## Scalata cat sa matura drumul, moara ar fi avut turnul de 50 m; coborata la
## sol, ar fi fost o moara ingropata. Asa ca moara ramane moara, iar peste drum
## trece ARIPA ei lunga — piesa care oricum se invarte.
## Numele piesei de palete din GLB-ul morii — se arunca (vezi `_build_tower`).
const BLADES_NODE := "Blades"

## Cat de sus ramane varful aripii cand e in punctul cel mai de jos.
##
## Aripa COBOARA PANA JOS (0.35 m): trebuie sa te loveasca daca esti sub ea,
## altfel gimmickul n-are dinti. Ce face hazardul jucabil nu e inaltimea, ci
## faptul ca matura DOAR O JUMATATE de drum — vezi `STRADDLE_LANE_FRAC`.
const STRADDLE_BLADE_CLEAR: float = 0.35

## Cat din latimea drumului matura aripile, ca fractie din semilatime.
##
## Regula bolovanului: ocupa O BANDA, nu tot drumul, ca sa ramana mereu o linie
## curata — atunci hazardul e o alegere, nu o franare.
##
## Prima incercare avea moara centrata pe axa, cu aripi cat toata semilatimea:
## aripa traversa fiecare banda, iar AI-ul, care nu stie s-o pandeasca,
## incetinea si se aglomera. probe_race pe Dunele, felia 0.90-0.95: 14.2 m/s
## inainte -> 6.4 m/s, 61% timp „lent", 35 de izbituri in pereti si pana la
## 1420 de atingeri pe o singura masina intr-o cursa de 120 s.
##
## Cu butucul mutat pe o margine, aripa matura de la marginea aia pana in axa.
## Jumatatea cealalta ramane libera tot timpul: ocolesti, ca la bolovan.
const STRADDLE_LANE_FRAC: float = 1.0

## Ce pati daca te prinde aripa care coboara. Mai bland decat bolovanul (3 s /
## 0.70): acolo iti cade o stanca in cap, aici te-a mangaiat o scandura. Destul
## cat sa te coste depasirea, prea putin cat sa-ti strice turul.
const STRADDLE_CRUSH_SECONDS: float = 1.4
const STRADDLE_CRUSH_FACTOR: float = 0.72
const STRADDLE_KEEP_SPEED: float = 0.62

var tower_scene: PackedScene
var tower_node: String = ""
var tower_scale: float = 1.0
var tower_class: String = ""
## Clase pe PIESE numite, pentru cladirile care nu sunt dintr-un material unic.
## Are prioritate fata de `tower_class` — vezi `_build_tower`.
var tower_classes: Dictionary = {}
## Cat de lateral sta turnul fata de axa drumului. Se pune de pista: turnul NU
## are voie sa stea pe carosabil, doar bratele trec peste el.
var tower_offset: float = 0.0
## Bratele arata ca aripi de moara (lati, cu zabrele), nu ca vane de carusel.
var mill_blades: bool = false

## Moara CALARE pe drum: picioarele de o parte si de alta a soselei, butucul
## deasupra axei, iar aripile mature carosabilul rotindu-se in plan VERTICAL.
##
## Asta rezolva problema pe care o avea varianta cu turnul lateral: acolo
## bratele se roteau in jurul axei drumului, iar moara statea alaturi — doua
## obiecte fara legatura vizibila (snapshots/dunele_joc.png). Calare, butucul e
## chiar deasupra ta si aripa care coboara vine DIN moara.
##
## Ritmul se schimba si el, in bine: nu mai e „treci prin fereastra dintre doua
## vane care matura orizontal", ci „treci inainte sa coboare aripa" — o
## fereastra pe care o vezi venind de departe, ca la bariera de tren.
var straddle: bool = false
## Pe ce margine sta butucul morii calare: +1 dreapta, -1 stanga sensului de
## mers. Aripa matura de la marginea aia pana in axa; cealalta jumatate de drum
## ramane libera.
var straddle_side: float = 1.0
## Semilatimea soselei aici. O pune pista — de ea depinde si cat matura aripa,
## si unde cad picioarele.
var road_half: float = 7.0

## Unde a fost asezat turnul pe lateral (calare). Butucul cade fix pe el.
var _straddle_x: float = 0.0
var _rotor: AnimatableBody3D
var _area: Area3D
var _angle: float = 0.0
## Cat mai are fiecare masina pana poate fi maturata iar (altfel primeste
## ghiontul de 60 de ori pe secunda cat sta lipita de vana).
var _cooldown: Dictionary = {}

## Inaltimea butucului la moara calare. Se DERIVA din raza aripii, ca varful ei
## sa ajunga la `STRADDLE_BLADE_CLEAR` de asfalt — vezi `_build_rotor`.
##
## Cu o inaltime fixa si o raza care depinde de latimea drumului, pe o pista
## mai lata aripa ar fi intrat in sosea, iar pe una ingusta ar fi ramas
## suspendata degeaba.
func _straddle_hub_y() -> float:
	return maxf(absf(_straddle_x), 1.0) + STRADDLE_BLADE_CLEAR


func _ready() -> void:
	add_to_group("hazards")
	_build_hub()
	_build_rotor()

## Butucul: talpa lata in nisip + stalpul pe care se invarte morisca.
##
## Cu `tower_scene`, in locul stalpului procedural vine cladirea morii, asezata
## LANGA drum. Coliziunea ii ramane a ei, la fel de solida — un turn prin care
## treci ar fi mai rau decat un stalp.
func _build_hub() -> void:
	if tower_scene != null and _build_tower():
		return
	var hub := StaticBody3D.new()
	add_child(hub)
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.55
	base_mesh.bottom_radius = 1.0
	base_mesh.height = 0.5
	base.mesh = base_mesh
	base.position = Vector3.UP * 0.25
	base.material_override = _flat(Color(0.35, 0.36, 0.42))
	hub.add_child(base)
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.22
	post_mesh.bottom_radius = 0.28
	post_mesh.height = 2.2
	post.mesh = post_mesh
	post.position = Vector3.UP * 1.35
	post.material_override = _flat(Color(0.82, 0.84, 0.88))
	hub.add_child(post)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.75
	cyl.height = 2.4
	shape.shape = cyl
	shape.position = Vector3.UP * 1.2
	hub.add_child(shape)

## O instanta a cladirii morii, cu piesele nedorite scoase si materialul pus.
## `null` daca modelul n-a putut fi folosit.
func _instance_tower() -> Node3D:
	var root := tower_scene.instantiate() as Node3D
	if root == null:
		return null
	if not tower_node.is_empty():
		var kept: Node3D = null
		for child in root.get_children():
			if child.name == tower_node:
				kept = child as Node3D
			else:
				root.remove_child(child) # vezi nota de mai jos despre queue_free
				child.queue_free()
		if kept == null:
			root.queue_free()
			return null
	else:
		# Paletele proprii ale cladirii se ARUNCA: ele stau sus, la 9.66 m, si
		# s-ar invarti separat de bratele care matura drumul. Doua seturi de
		# palete pe aceeasi moara, rotindu-se independent, e chiar genul de
		# lucru pe care nimeni nu-l observa in cod si toata lumea il vede pe
		# ecran.
		for child in root.get_children():
			if String(child.name).begins_with(BLADES_NODE):
				# `remove_child` INAINTE de `queue_free`: eliberarea e amanata la
				# sfarsitul cadrului, deci pana atunci paletele ar fi ramas in
				# arbore — se randau si se numarau, chiar daca „au fost sterse".
				root.remove_child(child)
				child.queue_free()
	root.scale = Vector3.ONE * tower_scale
	if not tower_classes.is_empty():
		# Maparea PE PIESE NUMITE e cazul normal pentru o cladire: moara are
		# lemn, metal si un accent pe atlas, deci o singura clasa „pe tot
		# subarborele" lasa piesele nepotrivite fara material valid — adica
		# MAGENTA in joc. Exact asta s-a intamplat la prima incercare (vezi
		# snapshots/dunele_joc.png): turnul iesea roz aprins.
		#
		# Maparea e aceeasi cu a morii decorative din `_LANDMARKS`, ca sa nu
		# existe doua adevaruri despre cum arata acelasi model.
		Palette.apply_class_materials(root, tower_classes)
	elif tower_class.is_empty():
		Palette.apply_world_material(root)
	elif Palette.CLASS_TRIPLANAR_SCALE.has(tower_class):
		Palette.apply_object_triplanar_class(root, tower_class, tower_scale)
	else:
		Palette.apply_class_materials(root, {"": tower_class})
	return root


## Cladirea morii, langa drum (sau calare pe el). Intoarce `false` daca modelul
## n-a putut fi folosit — si atunci se cade pe butucul procedural.
func _build_tower() -> bool:
	var root := _instance_tower()
	if root == null:
		return false

	# Cat de departe de axa sta CENTRUL turnului, la moara calare: marginea
	# drumului plus propria raza, ca zidul lui sa nu muste din asfalt.
	#
	# Coliziunea e un cilindru in jurul centrului, iar moara are acoperisul lat
	# (2.35 m pe Z), deci raza iese ~2 m. Fara impingerea asta, probe_race pe
	# Dunele arata felia 0.90-0.95 cazuta la 4.8 m/s cu 71% timp „lent" si toate
	# cele 6 masini raportand blocaj la frac 0.941, atingand `StaticBody3D`:
	# moara nu era un obstacol de ferit, era un zid.
	if straddle:
		var probe := Track.model_aabb(root)
		var probe_r := maxf(maxf(probe.size.x, probe.size.z) * 0.5, 0.6)
		_straddle_x = straddle_side * (road_half * STRADDLE_LANE_FRAC + probe_r)

	var body := StaticBody3D.new()
	add_child(body)
	# Turnul sta LATERAL, dincolo de bataia bratelor: pe axa drumului ar fi fost
	# un zid in mijlocul soselei, iar caruselul trebuie sa lase o fereastra.
	#
	# CALARE, insa, cele doua picioare trebuie sa fie SIMETRICE fata de axa
	# drumului (+offset si −offset), fiindca butucul sta pe axa si aripile se
	# invart in jurul ei. Cu corpul asezat la +offset si geamanul la −2×offset
	# (cum era la inceput), toata constructia iesea decalata cu o semilatime:
	# picioarele cadeau in afara cadrului, iar aripa nu mai era centrata pe drum.
	#
	# Moara care matura JUMATATE de drum sta pe marginea aia, cu butucul
	# deasupra ei: aripa intra peste asfalt pana in ax si se retrage. Nu mai e
	# nevoie de al doilea picior si de grinda peste sosea — aia era structura
	# de cand aripile se roteau in jurul AXEI, adica pe cand maturau tot drumul
	# si blocau si banda libera.
	body.position = Vector3(_straddle_x if straddle else tower_offset, 0.0, 0.0)
	body.add_child(root)
	var aabb := Track.model_aabb(root)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = maxf(maxf(aabb.size.x, aabb.size.z) * 0.5, 0.6)
	cyl.height = maxf(aabb.size.y, 1.0)
	shape.shape = cyl
	shape.position = Vector3.UP * cyl.height * 0.5
	body.add_child(shape)
	return true



## Rotorul: vanele care matura, plus zona de ghiont care le insoteste.
func _build_rotor() -> void:
	_rotor = AnimatableBody3D.new()
	_rotor.sync_to_physics = true
	add_child(_rotor)
	_area = Area3D.new()
	_rotor.add_child(_area)
	# Vana e joasa si lata: prinde caroseria (colizerul masinii sta la 0.1..1.1).
	var vane_h := 0.95
	var vane_t := 0.32
	if straddle:
		# CALARE: butucul e sus, deasupra drumului, iar aripile se rotesc in
		# plan VERTICAL (in jurul axei drumului), maturand carosabilul de sus in
		# jos. Raza se alege ca varful aripii sa ajunga aproape de asfalt fara
		# sa-l grebleze — altfel aripa fie taie drumul, fie se opreste la doi
		# metri deasupra si nu te atinge niciodata.
		# Butucul sta DEASUPRA UNEI MARGINI, nu a axei: de acolo aripa matura
		# spre mijloc si se opreste in ax, lasand banda cealalta libera.
		# `straddle_side` spune care margine (+1 dreapta, -1 stanga).
		# Raza = cat are de maturat pe orizontala (o semilatime), nu cat e de
		# sus butucul: aripa trebuie sa ajunga fix in axa drumului cand e
		# orizontala, si sa nu treaca dincolo de ea.
		# Raza se masoara de la BUTUC pana in axa drumului. Butucul sta pe turn
		# (`_straddle_x`), care e cu propria raza mai in afara decat marginea —
		# deci aripa are de acoperit distanta aia in plus, altfel se opreste
		# inainte de mijlocul drumului.
		arm_reach = maxf(absf(_straddle_x), 1.0)
		# Inaltimea butucului se DERIVA din raza, nu se alege: aripa in jos
		# trebuie sa ajunga la `STRADDLE_BLADE_CLEAR` de asfalt. Cu o inaltime
		# fixa si o raza care depinde de latimea drumului, pe o pista mai lata
		# aripa ar fi intrat in sosea, iar pe una ingusta ar fi ramas suspendata.
		# Butucul FIX peste turn: la 2 m distanta, aripile pareau ca se invart
		# in aer, langa moara, nu ca ies din ea.
		_rotor.position = Vector3(_straddle_x, _straddle_hub_y(), 0.0)
		# DOUA aripi, nu patru. O moara adevarata are patru, si asta a fost
		# prima incercare — dar cu patru brate exista mereu unul jos, deci
		# drumul statea blocat 66% din rotatie (masurat). Cu doua, ferestrele
		# sunt largi si pericolul se pandeste.
		#
		# Vizual nu se pierde nimic: aripile trec razant pe deasupra masinii, iar
		# ce se vede din chase cam e aripa care COBOARA spre tine, nu numarul
		# lor.
		arm_count = 2
	for k in arm_count:
		var angle := TAU * float(k) / float(arm_count)
		# Directia bratului: in planul XZ la carusel (matura orizontal), in
		# planul XY la moara calare (matura vertical, peste drum).
		var dir := Vector3(cos(angle), 0.0, -sin(angle))
		if straddle:
			dir = Vector3(0.0, cos(angle), -sin(angle))
		var center := dir * arm_reach * 0.5
		if not straddle:
			center += Vector3.UP * (vane_h * 0.5 + 0.12)
		var basis := Basis.looking_at(dir,
			Vector3.RIGHT if straddle else Vector3.UP)
		if mill_blades:
			_add_mill_blade(basis, center, vane_h, vane_t, arm_reach)
		else:
			var mesh_inst := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(vane_t, vane_h, arm_reach)
			mesh_inst.mesh = box
			mesh_inst.transform = Transform3D(basis, center)
			mesh_inst.material_override = _flat(
				vane_colors[k % vane_colors.size()])
			_rotor.add_child(mesh_inst)
		# Coliziunea urmeaza PANZA la carusel, dar la moara calare ramane
		# SUBTIRE — si asta e o corectie platita cu masuratori.
		#
		# Panza e lata (1.56 m la o aripa de 6 m), iar cutia e centrata pe brat:
		# o cutie „cat panza" coboara deci cu jumatate din latime SUB varful
		# aripii, adica la 0.42 m in loc de 1.20. Rezultatul era ca aripa lovea
		# masina cu mult inainte sa para ca o atinge — 876 de lovituri
		# raportate de probe_race pe o singura masina, cu felia cazuta la
		# 5.3 m/s.
		#
		# Grosimea de lovire ramane cat lonjeronul: panza e o suprafata, nu un
		# corp, si oricum ce conteaza pentru jucator e varful care coboara.
		var hit_h := vane_h * 0.42 if straddle else vane_h
		var col_shape := CollisionShape3D.new()
		var col_box := BoxShape3D.new()
		col_box.size = Vector3(vane_t, hit_h, arm_reach)
		col_shape.shape = col_box
		col_shape.transform = Transform3D(basis, center)
		_rotor.add_child(col_shape)
		# Zona de ghiont: un pic mai grasa decat vana, ca sa prinda contactul.
		var area_shape := CollisionShape3D.new()
		var area_box := BoxShape3D.new()
		area_box.size = Vector3(vane_t + 1.1, hit_h + 0.4, arm_reach)
		area_shape.shape = area_box
		area_shape.transform = Transform3D(basis, center)
		_area.add_child(area_shape)

## O aripa de moara: lonjeronul de lemn plus panza intinsa pe el.
##
## Aceeasi amprenta ca vana de carusel (coliziunea nici nu se atinge — se
## construieste separat, din aceleasi cote), doar ca se citeste ca aripa: lemn,
## nu plastic colorat, si o panza mai lata decat grinda.
func _add_mill_blade(basis: Basis, center: Vector3, vane_h: float,
		vane_t: float, reach: float) -> void:
	var spar := MeshInstance3D.new()
	var spar_box := BoxMesh.new()
	spar_box.size = Vector3(vane_t, vane_h * 0.42, reach)
	spar.mesh = spar_box
	spar.transform = Transform3D(basis, center)
	spar.material_override = _flat(Color(0.42, 0.30, 0.19)) # lemn
	_rotor.add_child(spar)
	# Panza: mai lata si mai subtire decat lonjeronul, impinsa spre VARFUL
	# aripii — langa butuc o aripa de moara e goala, panza incepe mai incolo.
	#
	# `Basis.looking_at(dir)` pune -Z pe directia bratului, deci "spre varf"
	# inseamna -Z local, adica `-basis.z` in lume.
	var cloth := MeshInstance3D.new()
	var cloth_box := BoxMesh.new()
	# Latimea panzei se ia din LUNGIMEA aripii, nu din inaltimea vanei de
	# carusel: pe o aripa de aproape 7 m, o panza de 0.95 m se citea ca o bara
	# de metal, nu ca o moara. Un sfert din lungime e proportia unei aripi
	# adevarate (masurat pe morile din referinte).
	var cloth_w := maxf(vane_h, reach * 0.26) if straddle else vane_h
	cloth_box.size = Vector3(vane_t * 0.35, cloth_w, reach * 0.62)
	cloth.mesh = cloth_box
	var outward := -basis.z.normalized()
	cloth.transform = Transform3D(basis, center + outward * reach * 0.16)
	cloth.material_override = _flat(Color(0.88, 0.85, 0.76)) # panza patata
	_rotor.add_child(cloth)


func _physics_process(delta: float) -> void:
	_angle = fposmod(_angle + TAU * delta / period, TAU)
	if straddle:
		# Calare, aripile se invart in jurul axei DRUMULUI (Z local, fiindca
		# nodul e orientat cu -Z pe sensul cursei), deci matura carosabilul de
		# sus in jos ca o moara adevarata vazuta din lateral.
		_rotor.rotation.z = _angle
	else:
		_rotor.rotation.y = _angle
	if Engine.is_editor_hint():
		return
	_sweep_cars(delta)

func _sweep_cars(delta: float) -> void:
	for key: Variant in _cooldown.keys():
		_cooldown[key] = maxf(float(_cooldown[key]) - delta, 0.0)
	for body in _area.get_overlapping_bodies():
		var car := body as Car
		if car == null or float(_cooldown.get(car, 0.0)) > 0.0:
			continue
		_cooldown[car] = 0.35
		if straddle:
			# Calare, aripa vine DE SUS: te turteste in asfalt si te franeaza,
			# nu te matura lateral. Un ghiont pe tangenta ar fi insemnat aici o
			# forta in jos sau in sus, dupa partea in care te prinde — adica
			# uneori te-ar fi ARUNCAT in aer, ceea ce nu seamana deloc cu o
			# aripa de moara care coboara peste tine.
			#
			# Refoloseste `crush`, ca bolovanul: pedeapsa e timp pierdut, si e
			# citita la fel peste tot in joc.
			car.crush(STRADDLE_CRUSH_SECONDS, STRADDLE_CRUSH_FACTOR,
				Vector3(1.35, 0.42, 1.3), STRADDLE_KEEP_SPEED)
			car.velocity.y = minf(car.velocity.y, -3.0)
			continue
		var radial := car.global_position - global_position
		radial.y = 0.0
		if radial.length() < 0.3:
			continue
		# Tangenta in sensul rotatiei: pentru rotatie pozitiva pe Y, un punct
		# la raza r se deplaseaza spre UP x r.
		var tangent := Vector3.UP.cross(radial.normalized()).normalized()
		car.apply_sweep(tangent * sweep_push + Vector3.UP * 1.2)

func _flat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat

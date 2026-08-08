class_name TrackScenography
extends RefCounted
## Decorul ASEZAT DUPA REFERINTA, nu imprastiat statistic.
##
## [TrackDecor] raspunde la intrebarea "cu ce umplem marginea drumului ca sa nu
## fie goala" — trei benzi, ponderi, zaruri. Modulul asta raspunde la alta
## intrebare: "ce anume e AICI, in poza?". Pe Okinawa v2 referinta
## (assets/okinawa_v2/okinawa_v2.png) nu arata "vegetatie tropicala pe margine",
## arata un dig cu tetrapozi pe dreapta de start, un port cu barci sabani in
## golf, un sat de case cu olane pe urcarea dinspre vest, ziduri gusuku pe
## creasta si un lan de trestie pe coborarea de est. Ordinea aia e continut, nu
## statistica, si nu poate iesi dintr-un zar.
##
## De ce un modul si nu inca o ramura in TrackDecor: benzile de acolo au un
## contract simplu (slot -> prop) pe care nu vrei sa-l rupi cu exceptii per
## sector. Aici contractul e altul — o LISTA DE SCENE, fiecare cu intervalul ei
## de tur, latura, distanta si specii — iar pista o declara ca date
## ([code]Track._scenography()[/code]), nu ca cod.
##
## Cele patru feluri de asezare, si de ce exact astea:
##
## [b]revetment[/b] — repetare pe LINIA TARMULUI, gasita in motor prin marsaluit
## in afara pana cand terenul intra sub nivelul marii. Tetrapozii din referinta
## nu stau la o distanta fixa de asfalt, stau acolo unde apa atinge uscatul; pe
## un dig care se ingusteaza, o distanta fixa i-ar fi lasat ori in mijlocul
## nisipului, ori pluitind peste apa.
##
## [b]edge[/b] — repetare la distanta fixa de marginea asfaltului, aliniata cu
## drumul: parapetul de pe laguna, zidurile gusuku, gardurile de curte. Astea
## chiar sunt paralele cu soseaua in referinta.
##
## [b]grove[/b] — banda cu specii ponderate, ca la TrackDecor, dar limitata la un
## interval de tur si la o latura. Asa se face diferenta dintre palmierii desi de
## pe coasta de est si curtile rare din sat, fara ca una din ele sa strice
## media celeilalte.
##
## [b]spot[/b] — un singur obiect, la fractie+latura sau la coordonate de lume.
## Coordonatele de lume exista pentru ce a fost MASURAT in referinta: pozitiile
## caselor din sat vin din masca de acoperisuri portocalii a hartii de tur,
## trecuta prin transformarea harta->lume (vezi track07.gd).
##
## Tot ce aseaza modulul e copil al unui singur nod "Scenography", deci dispare
## si se reface la fiecare [code]rebuild()[/code], ca orice decor procedural.
## Decorul pus de mana in editor (docs/decor_manual.md) e alt subarbore si nu e
## atins.

## Ce NU se gaseste nici in [TrackDecor.ISLAND_CLASSES], nici in tabelul de
## landmark-uri. Deocamdata un singur rand: bolovanii de tarm, care pe insula
## trebuie sa arate a bazalt de recif, nu a gresie de canion.
const EXTRA_CLASSES := {
	"Cluster_": Palette.TRI_PREFIX + "coral_rock",
}

static var _classes_cache: Dictionary = {}


## Maparea nume-de-parte -> clasa de material, ADUNATA din sursele existente.
##
## Nu e o lista noua scrisa de mana, si asta conteaza: un GLB venit din kit are
## UV-uri reale (unwrap peste tot atlasul), deci pus pe materialul comun al lumii
## iese in dungi — inclusiv benzi magenta din sloturile de rezerva. Aceeasi casa
## trebuie sa arate la fel si asezata ca landmark, si asezata de scenografie,
## deci sursa e tot `Track._LANDMARKS`, citita, nu copiata.
static func classes() -> Dictionary:
	if _classes_cache.is_empty():
		_classes_cache = TrackDecor.ISLAND_CLASSES.duplicate()
		for id: int in Track._LANDMARKS:
			var info: Dictionary = Track._LANDMARKS[id]
			if info.has("classes"):
				_classes_cache.merge(info["classes"])
		_classes_cache.merge(EXTRA_CLASSES)
	return _classes_cache


## Cat de departe de marginea asfaltului cauta `revetment` linia tarmului.
## Peste atat, tarmul nu mai e al drumului — e alta parte a insulei.
const SHORE_SEARCH_MAX: float = 70.0
## Pasul de cautare grosier, urmat de doua injumatatiri. 2 m + 2 pasi de
## bisectie da o precizie de 0.5 m pe linia apei, cu 1/3 din apelurile de
## `ground_y` fata de o cautare liniara de 0.5 m.
const SHORE_SEARCH_STEP: float = 2.0
## Cat de sus fata de nivelul marii se considera ca inca esti pe uscat. Terenul
## are unda proprie; fara o marja, cautarea se opreste in prima adancitura.
const SHORE_WATER_MARGIN: float = 0.15


## Construieste toata scenografia unei piste. Intoarce nodul radacina, chiar si
## gol (apelantul il adauga oricum, ca sa aiba ce sterge la rebuild).
static func build(sampler: TrackSideSampler, specs: Array[Dictionary],
		seed_value: int, sea_y: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Scenography"
	if specs.is_empty() or sampler == null:
		return root
	var path := _Path.new(sampler)
	if path.total <= 0.0:
		return root
	# Un singur RNG pentru toata scenografia, dar cu samanta pistei: acelasi
	# checkout da aceeasi insula, doua piste diferite nu-si copiaza tufele.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x5CE0_6DAF
	for spec in specs:
		var kind := String(spec.get("kind", ""))
		match kind:
			"revetment":
				_build_revetment(root, path, sampler, spec, rng, sea_y)
			"edge":
				_build_edge(root, path, sampler, spec, rng, sea_y)
			"grove":
				_build_grove(root, path, sampler, spec, rng, sea_y)
			"spot":
				_build_spot(root, path, sampler, spec, rng, sea_y)
			_:
				push_warning("TrackScenography: fel necunoscut '%s'" % kind)
	_report(root)
	return root


## O linie in consola cu ce a iesit, scena cu scena.
##
## Nu e decor de log: scenografia se regleaza in triunghiuri (un panou de zid
## gusuku costa cat 3 palmieri, o casa cat 7 tetrapozi), iar `probe_decor` da
## doar totalul pe pista. Fara defalcarea asta, singurul mod de a afla ce s-a
## scumpit era sa comentezi randuri din `_scenography()` una cate una.
static func _report(root: Node3D) -> void:
	var total_tris := 0
	var total_pieces := 0
	var parts: PackedStringArray = []
	for group in root.get_children():
		var tris := _count_tris(group)
		var pieces := group.get_child_count()
		total_tris += tris
		total_pieces += pieces
		parts.append("%s %d/%dk" % [group.name, pieces, tris / 1000])
	if total_pieces == 0:
		return
	print("scenografie: %d piese, %d tri — %s"
		% [total_pieces, total_tris, ", ".join(parts)])


static func _count_tris(node: Node) -> int:
	var tris := 0
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			if arr.is_empty():
				continue
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if idx.size() > 0:
				tris += idx.size() / 3
			else:
				tris += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	for c in node.get_children():
		tris += _count_tris(c)
	return tris


# --------------------------------------------------------------- feluri

## Digul: siruri de piese pe linia apei.
##
## Pentru fiecare statie de pe interval se cauta INTAI tarmul, apoi randurile se
## numara de acolo spre larg. `row_gap` negativ trage randurile spre uscat.
static func _build_revetment(root: Node3D, path: _Path,
		sampler: TrackSideSampler, spec: Dictionary, rng: RandomNumberGenerator,
		sea_y: float) -> void:
	var side := float(spec.get("side", -1.0))
	var rows := int(spec.get("rows", 2))
	var spacing := float(spec.get("spacing", 5.0))
	var row_gap := float(spec.get("row_gap", 4.0))
	var jitter := float(spec.get("jitter", 0.8))
	var first := float(spec.get("first_row", -1.5))
	var d0 := path.total * float(spec.get("from", 0.0))
	var d1 := path.total * float(spec.get("to", 1.0))
	if d1 <= d0:
		d1 += path.total
	# Cat de departe de sosea mai are sens sirul. Un dig e o LUCRARE care apara
	# drumul: acolo unde tarmul s-a departat de asfalt cu 60 m, tetrapozii n-ar
	# mai apara nimic si ar citi ca gunoi de beton pe o plaja. Peste prag,
	# scenografia lasa tarmul in seama pietrelor (alt spec, alt fel de piesa).
	var max_shore := float(spec.get("max_shore", SHORE_SEARCH_MAX))
	var holder := _group(root, spec, "revetment")
	var d := d0
	var row_shift := 0.0
	while d < d1:
		var st := path.at(d)
		var out: Vector3 = st["right"] * side
		var base: Vector3 = st["pos"]
		var shore := _shoreline(sampler, base, out, sampler.half_width() + 1.0,
			sea_y)
		if shore > max_shore:
			shore = -1.0
		if shore > 0.0:
			for r in rows:
				# Randurile se decaleaza intre ele cu jumatate de pas, ca sirul
				# sa nu citeasca drept grila. Tetrapozii chiar se pun asa: piesa
				# din randul doi sta in golul dintre doua din primul.
				var along_off := row_shift + float(r % 2) * spacing * 0.5
				var off := shore + first + float(r) * row_gap \
					+ rng.randf_range(-jitter, jitter)
				var st2 := path.at(d + along_off)
				var pos: Vector3 = st2["pos"] + (st2["right"] * side) * off
				pos.y = sampler.ground_y(pos.x, pos.z)
				# Piesele care ar iesi complet din apa in larg nu se pun: pe
				# portiunile unde marea mananca digul, randul doi cade in gol.
				if pos.y < sea_y - float(spec.get("max_depth", 3.0)):
					continue
				_place(holder, spec, pos, rng, st2["along"], side)
		d += spacing
		row_shift = -row_shift


## Sir aliniat cu soseaua, la distanta fixa de marginea asfaltului.
##
## `off` se masoara de la MARGINEA asfaltului, nu de la axa — la fel ca in
## TrackSideSampler, ca sa nu depinda de latimea pistei.
static func _build_edge(root: Node3D, path: _Path, sampler: TrackSideSampler,
		spec: Dictionary, rng: RandomNumberGenerator, sea_y: float) -> void:
	var side := float(spec.get("side", 1.0))
	var off := float(spec.get("off", 3.0)) + sampler.half_width()
	var spacing := float(spec.get("spacing", 4.0))
	var jitter := float(spec.get("jitter", 0.0))
	var d0 := path.total * float(spec.get("from", 0.0))
	var d1 := path.total * float(spec.get("to", 1.0))
	if d1 <= d0:
		d1 += path.total
	var drop := float(spec.get("min_ground", -1e9))
	var holder := _group(root, spec, "edge")
	# Pasul se numara pe LINIA PIESELOR, nu pe axa soselei.
	#
	# Prima versiune avansa cu `spacing` pe traseu, si de aici ieseau rosturi:
	# un sir asezat la 13 m in exteriorul unui viraj e mai LUNG decat portiunea
	# de sosea care il genereaza (masurat pe terasele de la creasta: pasi reali
	# intre 5.3 si 10.2 m pentru un pas cerut de 8.1). Un zid de cetate cu goluri
	# de 2 m nu mai e zid, e un sir de panouri.
	var probe := maxf(0.35, spacing * 0.05)
	var d := d0
	var last := Vector3.INF
	while d < d1:
		var st := path.at(d)
		var out: Vector3 = st["right"] * side
		var pos: Vector3 = st["pos"] + out * (off + rng.randf_range(-jitter,
			jitter))
		pos.y = sampler.ground_y(pos.x, pos.z)
		var far_enough := last == Vector3.INF \
			or Vector2(pos.x - last.x, pos.z - last.z).length() >= spacing
		# Un zid care intra in apa nu e zid, e naufragiu. Pragul e in metri
		# fata de nivelul marii, deci se poate cere si "doar pe uscat bun".
		if far_enough and pos.y >= sea_y + drop:
			_place(holder, spec, pos, rng, st["along"], side)
			_skirt(holder, spec, pos, rng, st["along"], side, sampler, sea_y)
			last = pos
		d += probe


## Banda de vegetatie/pietre, cu specii ponderate.
##
## Fata de benzile din TrackDecor: aici intervalul de tur si latura sunt
## explicite, iar densitatea e data in metri de-a lungul drumului, nu in numar
## total de piese. Asa un lan ramane lan si dupa ce se muta un punct de control.
static func _build_grove(root: Node3D, path: _Path, sampler: TrackSideSampler,
		spec: Dictionary, rng: RandomNumberGenerator, sea_y: float) -> void:
	var side := float(spec.get("side", 1.0))
	var both := bool(spec.get("both_sides", false))
	var spacing := float(spec.get("spacing", 8.0))
	var band: Array = spec.get("off", [8.0, 30.0])
	var off_min := float(band[0]) + sampler.half_width()
	var off_max := float(band[1]) + sampler.half_width()
	var d0 := path.total * float(spec.get("from", 0.0))
	var d1 := path.total * float(spec.get("to", 1.0))
	if d1 <= d0:
		d1 += path.total
	var above := float(spec.get("above_sea", 0.4))
	var clear := float(spec.get("clear", 3.0))
	var species: Array = spec.get("species", [])
	if species.is_empty():
		return
	var holder := _group(root, spec, "grove")
	var sides: Array[float] = [side]
	if both:
		sides.append(-side)
	var d := d0
	while d < d1:
		for s in sides:
			var st := path.at(d + rng.randf_range(-spacing * 0.4,
				spacing * 0.4))
			var out: Vector3 = st["right"] * s
			var pos: Vector3 = st["pos"] + out * rng.randf_range(off_min,
				off_max)
			pos.y = sampler.ground_y(pos.x, pos.z)
			# Doua motive de refuz, ambele vizibile din masina: piesa in apa si
			# piesa peste alta banda de asfalt (bucla se apropie de ea insasi la
			# 51 m, iar scurtatura trece la 30 m de sosea pe coborarea de est).
			#
			# Pragul e "cati metri liberi dupa marginea asfaltului", NU offsetul
			# benzii. Cu offsetul, un lan cerut la 8-20 m de margine era refuzat
			# in bloc oriunde scurtatura trecea la mai putin de 15 m: din 32 de
			# smocuri ramaneau 9, si lanul din referinta iesea o pajiste rara.
			if pos.y < sea_y + above:
				continue
			if sampler.clearance_at(pos) < sampler.half_width() + clear:
				continue
			var pick: Dictionary = _weighted(species, rng)
			_place(holder, pick, pos, rng, st["along"], s)
			_skirt(holder, spec, pos, rng, st["along"], s, sampler, sea_y)
		d += spacing


## Un singur obiect. Ori la (frac, side, off), ori la coordonate de lume.
static func _build_spot(root: Node3D, path: _Path, sampler: TrackSideSampler,
		spec: Dictionary, rng: RandomNumberGenerator, sea_y: float) -> void:
	var pos: Vector3
	var along := Vector3.FORWARD
	var side := float(spec.get("side", 1.0))
	if spec.has("world"):
		var w: Vector2 = spec["world"]
		pos = Vector3(w.x, 0.0, w.y)
		# Orientarea vine tot de la sosea: casele din referinta se uita spre
		# drum, oricat de departe ar fi de el.
		var st := path.nearest(pos)
		along = st["along"]
		side = signf((pos - (st["pos"] as Vector3)).dot(st["right"] as Vector3))
		if is_zero_approx(side):
			side = 1.0
	else:
		var st := path.at(path.total * float(spec.get("frac", 0.0)))
		var out: Vector3 = st["right"] * side
		pos = (st["pos"] as Vector3) + out * (sampler.half_width()
			+ float(spec.get("off", 10.0)))
		along = st["along"]
	if bool(spec.get("on_water", false)):
		pos.y = sea_y
	else:
		pos = _snap_to_land(sampler, path, pos, sea_y,
			float(spec.get("above_sea", 0.3)))
		if is_inf(pos.y):
			push_warning("TrackScenography: '%s' cade in apa, sarit"
				% String(spec.get("label", "spot")))
			return
	_place(_group(root, spec, "spot"), spec, pos, rng, along, side)


## Trage un obiect spre sosea pana iese din apa.
##
## Exista fiindca pozitiile masurate din referinta si terenul din motor NU sunt
## acelasi lucru: conturul lagunei e simplificat la 16 laturi, deci o casa citita
## la 61 m de axa in harta poate cadea cu 14 m in apa in joc. Varianta "muta
## numarul din fisier pana arata bine" ar fi legat scenografia de forma de azi a
## terenului; asa, cifra ramane cea masurata si obiectul se aseaza singur pe
## primul metru de uscat.
static func _snap_to_land(sampler: TrackSideSampler, path: _Path, pos: Vector3,
		sea_y: float, above: float) -> Vector3:
	var out := pos
	out.y = sampler.ground_y(out.x, out.z)
	if out.y >= sea_y + above:
		return out
	var road: Vector3 = path.nearest(pos)["pos"]
	var dir := Vector3(road.x - pos.x, 0.0, road.z - pos.z)
	var span := dir.length()
	if span < 1.0:
		out.y = INF
		return out
	dir /= span
	var moved := 2.0
	while moved < span - sampler.half_width():
		var q := pos + dir * moved
		q.y = sampler.ground_y(q.x, q.z)
		if q.y >= sea_y + above:
			return q
		moved += 2.0
	out.y = INF
	return out


# --------------------------------------------------------------- asezare

## Instantiaza si aseaza o piesa. Punctul UNIC prin care trec toate felurile:
## alegerea variantei, materialele de clasa, coliziunea si orientarea.
##
## `along` e sensul drumului la statia respectiva, `side` latura. Rotatia
## implicita alinieaza axa X a modelului cu drumul (asa sunt exportate zidurile
## si parapetele: lungimea pe X), iar `face_road` intoarce piesa cu fata spre
## sosea (case, statui).
## "Fusta" unei piese: sateliti marunti pe o raza in jurul ei (#209).
##
## In referinta nimic nu sta singur pe gazon: pietrele au smocuri la baza,
## tufele au fire rasarite in jur. Cheia "skirt" pe un spec de `edge`/`grove`
## descrie satelitii o singura data si fiecare piesa plasata si-i primeste:
##   "skirt": {"path": ..., "picks": [...], "count": [2, 4], "radius": 1.6,
##             "scale": [0.7, 1.2], "sink": 0.1}
## Raza e de la MARGINEA piesei spre afara (0.35..1.0 din valoare), ca
## satelitii sa nu rasara din piesa. Aceleasi refuzuri ca la grove: apa si
## alta banda de asfalt. E acelasi tipar ca _place_satellites din TrackDecor,
## dar declarativ — nu cod nou per compozitie.
static func _skirt(parent: Node3D, spec: Dictionary, pos: Vector3,
		rng: RandomNumberGenerator, along: Vector3, side: float,
		sampler: TrackSideSampler, sea_y: float) -> void:
	var skirt: Dictionary = spec.get("skirt", {})
	if skirt.is_empty():
		return
	var cnt: Array = skirt.get("count", [2, 3])
	var radius := float(skirt.get("radius", 1.5))
	var above := float(spec.get("above_sea", 0.4))
	for _j in rng.randi_range(int(cnt[0]), int(cnt[1])):
		var ang := rng.randf_range(0.0, TAU)
		var rr := radius * (0.35 + rng.randf() * 0.65)
		var p2 := pos + Vector3(cos(ang) * rr, 0.0, sin(ang) * rr)
		p2.y = sampler.ground_y(p2.x, p2.z)
		if p2.y < sea_y + above:
			continue
		if sampler.clearance_at(p2) < sampler.half_width() + 1.2:
			continue
		_place(parent, skirt, p2, rng, along, side)


static func _place(parent: Node3D, spec: Dictionary, pos: Vector3,
		rng: RandomNumberGenerator, along: Vector3, side: float) -> void:
	var node := _instance(spec, rng)
	if node == null:
		return
	var holder: Node3D = node
	var scale := 1.0
	var sr: Array = spec.get("scale", [1.0, 1.0])
	scale = rng.randf_range(float(sr[0]), float(sr[1]))
	var collide := float(spec.get("collide", 0.0))
	if collide > 0.0:
		# Raza se da NESCALATA: forma e copil al lui `holder`, iar scara lui o
		# inmulteste oricum. Inmultita si aici, un palmier la 1.2 ar fi primit un
		# cilindru de 1.44 ori raza ceruta.
		holder = _with_collision(node, collide, spec)
	else:
		holder = Node3D.new()
		holder.add_child(node)
	parent.add_child(holder)
	holder.scale = Vector3.ONE * scale
	holder.position = pos - Vector3.UP * float(spec.get("sink", 0.08))

	# Conventiile de axe, scrise o data ca sa nu se mai ghiceasca:
	#   - rotatia cu unghiul t in jurul lui Y duce axa X a modelului in
	#     (cos t, 0, -sin t) si axa -Z in (-sin t, 0, -cos t);
	#   - piesele LUNGI din kit (zid, parapet, barca) au lungimea pe X, deci
	#     "along" trebuie sa alinieze X-ul, nu Z-ul;
	#   - "fata" unui model e -Z, ca la `look_at`, deci si ca la landmark-uri.
	# Prima versiune folosea atan2(along.x, along.z) pentru amandoua, adica
	# alinia +Z: zidul de cetate iesea PERPENDICULAR pe drum (un sir de panouri
	# ca niste garduri de fotbal), iar casele stateau cu spatele la sosea.
	var yaw := 0.0
	match String(spec.get("face", "along")):
		"along":
			yaw = atan2(-along.z, along.x)
		"road":
			var to_road := -along.cross(Vector3.UP) * side
			yaw = atan2(-to_road.x, -to_road.z)
		"world":
			# Orientare LITERALA, pentru piesele promovate din decorul manual:
			# yaw-ul (si eventual inclinarea, prin "rot") vin exact din spec,
			# fara nicio deriva din drum si fara zar. O piesa asezata cu mouse-ul
			# si promovata in scenografie trebuie sa ramana EXACT cum a lasat-o
			# mana — altfel promovarea n-ar fi conservare, ci re-generare.
			pass
		_:
			yaw = rng.randf_range(0.0, TAU)
	yaw += deg_to_rad(float(spec.get("yaw", 0.0)))
	yaw += deg_to_rad(rng.randf_range(-float(spec.get("yaw_jitter", 0.0)),
		float(spec.get("yaw_jitter", 0.0))))
	holder.rotation.y = yaw
	if spec.has("rot"):
		var r: Array = spec["rot"]
		holder.rotation.x = deg_to_rad(float(r[0]))
		holder.rotation.z = deg_to_rad(float(r[1]))
	var tilt := float(spec.get("tilt", 0.0))
	if tilt > 0.0:
		# Inclinare mica pe doua axe: tetrapozii aruncati de macara nu stau
		# drept, si un sir de piese perfect verticale se citeste imediat ca
		# geometrie generata.
		holder.rotation.x = rng.randf_range(-tilt, tilt)
		holder.rotation.z = rng.randf_range(-tilt, tilt)
	Palette.apply_class_materials(holder, classes())


## Modelul cerut de spec: fie o varianta numita din GLB (`picks`), fie fisierul
## intreg. Intoarce null daca lipseste — o pista trebuie sa ramana jucabila pe
## un checkout fara assets.
static func _instance(spec: Dictionary, rng: RandomNumberGenerator) -> Node3D:
	var path := String(spec.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var picks: Array = spec.get("picks", [])
	if picks.is_empty():
		return (load(path) as PackedScene).instantiate() as Node3D
	var name := String(picks[rng.randi_range(0, picks.size() - 1)])
	return TrackDecor.pick_from_glb(path, name)


## Cilindru de coliziune in jurul piesei. Doar pentru ce trebuie sa opreasca
## masina; decorul marunt ramane fara, ca sa nu te agati de o tufa.
static func _with_collision(node: Node3D, radius: float,
		spec: Dictionary) -> Node3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var aabb := Track.model_aabb(node)
	if String(spec.get("collide_shape", "cyl")) == "box":
		var box := BoxShape3D.new()
		box.size = aabb.size
		shape.shape = box
		shape.position = aabb.position + aabb.size * 0.5
	else:
		var cyl := CylinderShape3D.new()
		cyl.radius = radius
		cyl.height = maxf(aabb.size.y, 1.0)
		shape.shape = cyl
		shape.position = Vector3.UP * (aabb.position.y + cyl.height * 0.5)
	body.add_child(shape)
	body.add_child(node)
	return body


## Nodul-container al unei scene, numit dupa eticheta din spec. Exista ca sa se
## poata citi arborele de scene: "Zid gusuku" langa "Sat", nu 400 de copii intr-o
## singura lista.
static func _group(root: Node3D, spec: Dictionary, fallback: String) -> Node3D:
	var label := String(spec.get("label", fallback))
	var found := root.get_node_or_null(NodePath(label))
	if found != null:
		return found as Node3D
	var g := Node3D.new()
	g.name = label
	root.add_child(g)
	return g


static func _weighted(entries: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for e: Dictionary in entries:
		total += float(e.get("weight", 1.0))
	var roll := rng.randf() * total
	var acc := 0.0
	for e: Dictionary in entries:
		acc += float(e.get("weight", 1.0))
		if roll <= acc:
			return e
	return entries[entries.size() - 1]


## Distanta de la axa soselei pana la linia apei, pe directia `out`.
##
## Intoarce -1 daca nu gaseste apa in SHORE_SEARCH_MAX metri — pe portiunile
## unde insula e lata, digul pur si simplu nu are ce sa apere.
static func _shoreline(sampler: TrackSideSampler, base: Vector3, out: Vector3,
		start: float, sea_y: float) -> float:
	var limit := sea_y + SHORE_WATER_MARGIN
	var prev := start
	var d := start
	while d <= SHORE_SEARCH_MAX:
		var p := base + out * d
		if sampler.ground_y(p.x, p.z) <= limit:
			# Bisectie intre ultimul punct uscat si primul ud.
			var lo := prev
			var hi := d
			for _i in 2:
				var mid := (lo + hi) * 0.5
				var q := base + out * mid
				if sampler.ground_y(q.x, q.z) <= limit:
					hi = mid
				else:
					lo = mid
			return (lo + hi) * 0.5
		prev = d
		d += SHORE_SEARCH_STEP
	return -1.0


# --------------------------------------------------------------- traseu

## Traseul copt, cu lungimi de arc — ca sa se poata cere o statie "la 5 m dupa
## cealalta" fara sa depinzi de cat de des cad punctele coapte in viraje.
class _Path:
	extends RefCounted

	var pts: PackedVector3Array
	var cum: PackedFloat32Array
	var total: float = 0.0

	func _init(sampler: TrackSideSampler) -> void:
		var n := sampler.point_count()
		pts.resize(n)
		cum.resize(n + 1)
		for i in n:
			pts[i] = sampler.baked_point(i)
		cum[0] = 0.0
		for i in n:
			cum[i + 1] = cum[i] + pts[i].distance_to(pts[(i + 1) % n])
		total = cum[n]

	## Statia de la distanta `d` pe traseu (se poate cere si peste o tura).
	func at(d: float) -> Dictionary:
		var n := pts.size()
		if n == 0:
			return {"pos": Vector3.ZERO, "along": Vector3.FORWARD,
				"right": Vector3.RIGHT, "frac": 0.0}
		var dd := fposmod(d, total)
		var i := _index(dd)
		var seg := cum[i + 1] - cum[i]
		var t := 0.0 if seg <= 0.0 else (dd - cum[i]) / seg
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var along := (b - a).normalized()
		return {
			"pos": a.lerp(b, t),
			"along": along,
			"right": along.cross(Vector3.UP).normalized(),
			"frac": dd / total,
		}

	## Cea mai apropiata statie de un punct din lume.
	func nearest(w: Vector3) -> Dictionary:
		var n := pts.size()
		var best := 0
		var best_d := INF
		for i in n:
			var dx := pts[i].x - w.x
			var dz := pts[i].z - w.z
			var d2 := dx * dx + dz * dz
			if d2 < best_d:
				best_d = d2
				best = i
		return at(cum[best])

	func _index(d: float) -> int:
		var lo := 0
		var hi := cum.size() - 2
		while lo < hi:
			var mid := (lo + hi + 1) / 2
			if cum[mid] <= d:
				lo = mid
			else:
				hi = mid - 1
		return lo

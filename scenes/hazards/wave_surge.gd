@tool # vizibil si in preview-ul din editor
class_name WaveSurge
extends WaterHazard
## Valul care spala soseaua: marea trece PESTE drum la intervale regulate.
##
## Gimmick-ul sectorului: nu e un obstacol care te opreste — treci prin el — e un
## CEAS. Apa taie grip-ul cat timp valul e pe asfalt, si nimic intre treceri.
## Asta e diferenta fata de conducta sparta care tinea locul pana acum: teava uda
## drumul la nesfarsit, deci nu era o decizie, era o taxa. Cu val, sectorul are
## un raspuns corect (treci inainte sau dupa) si unul gresit.
##
## Fata de `WaterHose` schimba doar sursa: petecul ud, balta si taierea de grip
## sunt ale lui `WaterHazard` si sunt LITERAL acelasi cod. Ce e aici e miscarea —
## si fiindca apa e copil al nodului, ea calatoreste cu creasta pe gratis.
##
## De ce nu `SlidingHazard`: alea matura lateral si te IMPING. Valul trece peste
## sosea pe toata latimea, nu are coliziune si nu are pozitie de repaus pe
## margine — sunt doua obiecte diferite care se misca amandoua lateral, si a
## forta unul in altul ar fi insemnat trei steaguri noi in SlidingHazard.
##
## TELEGRAFIEREA (style_bible §7, regula "obstacolul se anunta"): valul intra in
## cadru din larg, cu spuma inainte, si abia dupa aia ajunge pe asfalt. Timpul
## dintre momentul in care se vede si momentul in care ajunge e `LEAD_TIME`, si
## e ce transforma hazardul dintr-o pedeapsa intr-o decizie.

## Cat dureaza o traversare completa, dus-intors. Perioada e lunga DELIBERAT:
## la 4-5 s valul ar fi fost un stroboscop, iar sectorul un slalom. La 9 s, un
## tur normal prinde una sau doua treceri, deci fiecare conteaza.
const PERIOD: float = 9.0
## Cat din perioada valul e efectiv pe drum (restul e in larg, invizibil).
const ON_ROAD_FRAC: float = 0.42
## Cu cat timp inainte de a atinge asfaltul devine vizibil valul.
const LEAD_TIME: float = 1.6
## Cati metri dincolo de marginea drumului mai e vazut valul dupa ce l-a trecut.
const EXIT_MARGIN: float = 8.0

## Latimea maturata, in metri de o parte si de alta a axei drumului.
var sweep: float = 22.0
## Lungimea CERUTA a crestei, masurata de-a lungul soselei. Se rotunjeste la un
## numar intreg de segmente de model (vezi `_build_source`), iar valoarea rotita
## e si lungimea peliculei de apa: un val care se vede lung de 30 m si uda 12 ar
## minti despre unde te prinde.
##
## De ce atat de lunga fata de drum (30 m pe o sosea de 14): un val cat un sfert
## din latimea drumului citea, din masina, ca un obiect care pluteste pe asfalt —
## prima captura arata o pana alba, nu marea. Un val care spala un dig acopera o
## PORTIUNE de drum, si tocmai asta e decizia: intri in ea sau astepti.
var crest_length: float = 30.0
## Cat de adanca e pelicula de apa pe directia de mers a valului. Mai lata decat
## modelul crestei (2.6 m): apa nu se opreste la creasta, se intinde in urma ei.
var film_depth: float = 6.0
## Defazaj 0..1, ca doua valuri de pe aceeasi pista sa nu bata la unison.
var phase: float = 0.0
## Directia in care merge valul (versor orizontal, perpendicular pe sosea),
## in spatiul PARINTELUI. Se pune inainte de add_child.
var travel_dir: Vector3 = Vector3.RIGHT
## Cat de sus fata de sosea sta creasta cand trece.
var ride_height: float = -0.35
## Cota marii, in spatiul parintelui. Fara ea valul traverseaza orizontal la
## cota soselei, deci in larg pluteste in aer — pe un dig inalt de 1.6 m se vede.
## `INF` = pista n-a spus, deci nu coboara.
var water_y: float = INF

## Punctul pe care a fost asezat valul, in spatiul PARINTELUI.
##
## Nu e un detaliu de stil: `_advance` scrie `position` in fiecare cadru, deci
## fara ancora ARUNCA pozitia primita de la pista (`_build_wave_surge`) si matura
## in jurul originii pistei, nu in jurul sectorului. Exact bug-ul pe care il
## descria `typhoon_hazard.gd` cand si-a luat ancora proprie — pe Track05 nu s-a
## vazut fiindca sectorul cu val e langa origine.
var _anchor: Vector3 = Vector3.ZERO

var _time: float = 0.0
var _model: Node3D
## Toate piesele de spuma din creasta, ca pulsul sa bata pe toata lungimea ei si
## nu doar pe primul segment.
var _foams: Array[Node3D] = []
## Modelul unui segment de creasta si lungimea lui reala, masurata din GLB.
var _model_scene: PackedScene
var _segment_span: float = 0.0
var _segment_depth: float = 2.6
var _segments: int = 1

const MODEL_PATH := "res://assets/models/wave_surge.glb"


func _ready() -> void:
	_anchor = position
	# Fata spre directia de mers, o singura data: creasta merge in linie dreapta,
	# deci basis-ul nu are ce sa se schimbe de la un cadru la altul. `Basis`, nu
	# `look_at`: `travel_dir` e in spatiul parintelui, care e si spatiul in care
	# se citeste basis-ul local — `look_at` ar fi cerut coordonate globale.
	if travel_dir.length_squared() > 0.001:
		basis = Basis.looking_at(travel_dir, Vector3.UP)
	# INAINTE de super(): baza construieste pelicula de apa din `crest_length`,
	# iar aici se afla cat de lunga iese ea de fapt.
	_snap_crest_to_model()
	super()


## Rotunjeste lungimea crestei la un numar intreg de segmente de model.
##
## De ce segmente si nu o singura piesa intinsa: `wave_surge.glb` e o bucata de
## val de 6 m, iar pista cere 30. Intinsa de cinci ori, spuma ei se latea odata
## cu ea si se vedea ca o pata; repetata, fiecare bucata isi pastreaza scara la
## care a fost desenata. Costul e cinci mesh-uri de 500 de triunghiuri in loc de
## unul — nimic fata de bugetul pistei — si zero materiale in plus, fiindca toate
## primesc materialul lumii.
func _snap_crest_to_model() -> void:
	if not ResourceLoader.exists(MODEL_PATH):
		return
	_model_scene = load(MODEL_PATH) as PackedScene
	var probe := _model_scene.instantiate() as Node3D
	var span := _model_span(probe)
	probe.free()
	_segment_span = span.x
	_segment_depth = span.z
	if _segment_span <= 0.01:
		_model_scene = null
		return
	_segments = maxi(1, int(round(crest_length / _segment_span)))
	crest_length = float(_segments) * _segment_span


## Petecul ud tine cat creasta: lung cat ea de-a lungul soselei (X local, fiindca
## nodul e intors cu -Z pe directia de mers), si ingust pe directia de mers.
func _wet_patch_size() -> Vector3:
	return Vector3(crest_length, 3.0, film_depth)


## Creasta e ingropata cu `ride_height` sub asfalt; pelicula de apa nu are voie
## sa mearga cu ea, altfel iese sub drum si nu se mai vede.
func _wet_patch_offset() -> float:
	return 0.06 - ride_height


func _build_source() -> void:
	if _model_scene == null:
		# Fara GLB, o prisma turcoaz. Mecanica trebuie sa poata fi jucata si
		# reglata inainte sa existe modelul — acelasi contract ca la tromba.
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(crest_length, 1.8, 2.6)
		mi.mesh = box
		mi.position = Vector3.UP * 0.9
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Palette.color(Palette.REEF_SHALLOW)
		mat.roughness = 0.35
		mi.material_override = mat
		_model = mi
		add_child(_model)
		return
	# Creasta: `_segments` bucati asezate cap la cap pe X (adica de-a lungul
	# soselei — nodul e intors cu -Z pe directia de mers), centrate pe hazard.
	_model = Node3D.new()
	_model.name = "Crest"
	# Spuma sta pe MUCHIA DIN FATA a peliculei, nu pe mijlocul ei: valul impinge
	# apa inaintea lui, deci foaia ramane in urma crestei. Fata = -Z local.
	_model.position.z = -0.5 * (film_depth - _segment_depth)
	add_child(_model)
	var start := -0.5 * (crest_length - _segment_span)
	for i in _segments:
		var seg := _model_scene.instantiate() as Node3D
		seg.position.x = start + float(i) * _segment_span
		# Aceeasi bucata de sase metri repetata de cinci ori se citeste ca
		# sablon, nu ca val — se vedea in captura, un sirag de piese identice.
		# Variatia e derivata din indice (deci stabila intre rulari, ca tot
		# decorul procedural din proiect), mica, si pe axele pe care un val chiar
		# variaza: cat de mult a inaintat bucata si cat de sus a crescut.
		seg.position.z = (-0.35 if i % 2 == 0 else 0.4)
		seg.rotation.y = deg_to_rad(-4.0 if i % 3 == 0 else 3.0)
		seg.scale = Vector3(1.0, 0.86 + 0.09 * float(i % 3), 1.0)
		_model.add_child(seg)
		# Nodul `Wave_Foam` se cauta dupa NUME, ca `Blades` la moara. Daca
		# lipseste, valul merge fara pulsul de spuma in loc sa crape.
		for child in seg.get_children():
			if child.name == "Wave_Foam":
				_foams.append(child as Node3D)
	Palette.apply_world_material(_model)


func _advance(delta: float) -> bool:
	_time += delta
	var t := fposmod(_time / PERIOD + phase, 1.0)
	# Valul e pe drum doar in prima parte a ciclului; in rest asteapta in larg.
	# Se ascunde in loc sa fie mutat departe: un mesh de 500 de triunghiuri
	# randat degeaba la 60 fps, de doua ori pe pista, nu e gratis pe mobil.
	var span := ON_ROAD_FRAC + LEAD_TIME / PERIOD
	if t >= span:
		if _model != null:
			_model.visible = false
		return false
	# Traversare liniara: valul nu accelereaza, si asta e intentionat — un val
	# cu viteza constanta se poate ANTICIPA, iar anticiparea e tot gimmick-ul.
	var offset := lerpf(-sweep, sweep, t / span)
	# Se vede din larg pana dincolo de drum, si NU mai departe. Capatul dinspre
	# venire e telegrafierea (valul sparge in tetrapozi inainte sa urce pe dig,
	# vezi capturile din #106); capatul celalalt nu spune nimic — acolo creasta
	# doar plutea pe laguna si citea ca niste aschii pe apa.
	var visible_now := offset < road_width * 0.5 + EXIT_MARGIN
	if _model != null:
		_model.visible = visible_now
	if not visible_now:
		return false
	# Cat de mult e creasta peste asfalt, 0..1. Serveste la doua lucruri, si
	# de-aia e o rampa si nu un da/nu: coboara valul spre mare cat e in larg, si
	# umfla spuma cand ajunge pe drum.
	var half := road_width * 0.5
	var on_road := clampf(1.0 - (absf(offset) - half) / 6.0, 0.0, 1.0)
	var p := _anchor + travel_dir * offset
	p.y = _anchor.y + ride_height
	if is_finite(water_y):
		p.y = lerpf(water_y, p.y, on_road)
		# Dupa ce a trecut drumul, valul se SCUFUNDA in loc sa dispara dintr-un
		# cadru in altul. Asimetria fata de venire e chiar fizica sectorului: un
		# val sparge cand urca pe dig si se scurge dupa ce l-a trecut. Doi metri
		# ajung — creasta are 1.8.
		var past := maxf(0.0, offset - (half + 2.0))
		p.y -= minf(past * 0.35, 2.2)
	position = p
	# Pulsul de spuma: creste cat valul e pe asfalt. Nu e decor — e semnalul
	# vizual care spune "ACUM", si de-aia e pe o piesa separata din GLB.
	if not _foams.is_empty():
		var pulse := 1.0 + (0.22 * sin(_time * 6.5) + 0.35 * on_road)
		for foam in _foams:
			foam.scale = Vector3(1.0, pulse, 1.0)
	# Apa taie grip-ul doar cat creasta chiar atinge asfaltul. Marja de 1 m peste
	# jumatatea de latime tine cont de faptul ca petecul are si el grosime: fara
	# ea, valul ar uda ultimul metru de drum din varful zonei, adica inainte sa
	# se vada peste el.
	return absf(offset) <= half + 1.0


## Cotele modelului, in unitati locale. AABB-ul se aduna din mesh-uri: radacina
## unui GLB e un Node3D gol, deci n-are AABB propriu.
func _model_span(root: Node) -> Vector3:
	var span := Vector3.ZERO
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			span = span.max(mi.mesh.get_aabb().size * mi.scale)
	return span

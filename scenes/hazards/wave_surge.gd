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
## ## CE SE SIMTE, si de ce nu era destul grip-ul taiat
##
## Prima versiune doar taia aderenta laterala. Din masina nu se simtea NIMIC, si
## motivul e geometric: digul e o dreapta de 200 m, iar pe o dreapta nu ceri
## aderenta laterala — deci n-ai ce pierde. Un hazard care se manifesta numai
## daca virezi e, pe sectorul asta, decor.
##
## Acum valul face ce face un metru cub de apa care te loveste din lateral:
##   - te IMPINGE in directia lui de mers (`Car.apply_sweep`),
##   - te FRANEAZA, ca orice masina bagata in apa mare,
##   - taie grip-ul (mai departe, pentru cine chiar vira),
##   - si zguduie ecranul prin semnalul `Car.splashed`.
## Primele doua se simt mergand drept, care e singurul fel in care treci pe acolo.
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

## Imbrancitura, in m/s adaugati LATERAL o singura data cand creasta trece peste
## masina. Nu e o acceleratie: apa te loveste o data, nu te impinge continuu.
##
## Cifra se MASOARA cu `tools/ProbeWave.tscn` (o masina lansata trece prin sector
## de doua ori, o data cu valul peste ea si o data fara, si se citeste diferenta)
## dar se ALEGE din scaun. Istoricul, fiindca s-a jucat de doua ori:
##
##   impuls  apa    drag   rezultat masurat
##   ------  -----  -----  --------------------------------------------------
##    9.0    6 m    0.40   masinile terminau la 9.5 m una de alta (distanta
##                         bruta, inainte sa desfac lateralul de longitudinal)
##    5.0    6 m    0.40   2.6 m lateral, 3.4 m/s — masurabil, dar verdictul
##                         din joc a fost „prea mic"
##    9.0    9 m    1.40   4.1 m lateral, 5.8 m in urma, 7.1 m/s  <- acum
##
## Detaliul contraintuitiv din tabel: la 11.0 (incercat si el) masina pierdea mai
## PUTINA viteza decat la 9.0 — 4.8 m/s fata de 7.1 — fiindca o imbrancitura mai
## tare o scoate mai repede din apa, deci drag-ul are mai putin timp sa lucreze.
## Impulsul si franarea nu se aduna, se concureaza.
##
## De ce sonda si scaunul nu cad de acord: sonda trece cu o masina LANSATA de la
## 26 m/s care incetineste singura, jucatorul intra cu piciorul in podea la 30+.
## Acelasi impuls lateral da un unghi mai mic si o corectie mai usoara cu cat
## mergi mai repede — deci cifra care „se simte" in sonda e sub cea care se simte
## in cursa. Sonda ramane pentru REGRESII (plafonul „nu te matura de pe dig"),
## nu ca arbitru de feel.
const PUSH_IMPULSE: float = 9.0
## Cat din viteza pierzi pe secunda de stat in apa (fractiune). Apa mare franeaza;
## fara asta, valul era o pata de vopsea peste care treceai fara sa clipesti.
##
## Se citeste IMPREUNA cu `film_depth`: la 28 m/s traversezi 9 m de apa in 0.32 s,
## deci vechiul 0.40/s lua 13% din viteza — sub pragul la care simti ceva. La 1.4
## ies ~37%, adica intri in apa si te trezesti franat.
const DRAG_PER_SEC: float = 1.40
## Cat de mult zguduie ecranul intrarea in val.
##
## Shake-ul camerei e `trauma^2 * 0.35 m`, deci creste PATRATIC si valorile mici
## practic nu exista: la 0.30 (prima versiune) ieseau 3 cm de offset stinsi in
## 0.17 s. Semnalul chiar se emitea — sonda l-a si numarat, o stropire per
## trecere — dar pe ecran nu se vedea nimic, si exact asta s-a raportat din joc.
## La 0.75 ies 20 cm, mai mult decat o izbitura in perete (0.5 -> 9 cm), si e
## corect asa: acolo atingi un zid cu o aripa, aici te ia un val cu totul.
const SPLASH_TRAUMA: float = 0.75
## Zguduitura de fond cat timp esti IN apa, adaugata la fiecare `SPLASH_EVERY`
## secunde. Fara ea valul dadea o singura palma, iar trauma (care se stinge cu
## 1.8 pe secunda) se termina inainte sa fi iesit din apa.
const SPLASH_RUMBLE: float = 0.22
const SPLASH_EVERY: float = 0.12

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
## modelul crestei (4.5 m): apa nu se opreste la creasta, se intinde in urma ei.
##
## E si CAT TIMP stai in apa, deci un reglaj de gameplay, nu doar de decor: la
## 28 m/s, 9 m inseamna 0.32 s de franare si de grip taiat. La 6 m (versiunea
## dinainte de playtest) erau 0.21 s — prea putin cat sa se simta ceva.
var film_depth: float = 9.0
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
## Suportul care poarta leganarea, ca sa n-o dea si peliculei de apa de dedesubt.
var _model: Node3D
## Piesele animate separat din GLB, cautate dupa nume (contractul din
## `tools/blender/build_wave_surge.py`). Lipsa oricareia nu e fatala.
var _foam: Node3D
var _spray_piece: Node3D
var _spray: CPUParticles3D
var _audio: AudioStreamPlayer3D
## Cat de departe de creasta era fiecare masina in cadrul trecut, ca sa stim cand
## INTRA sub ea — imbrancitura si stropul se dau la intrare, nu continuu.
##
## Cheia e `get_instance_id()`, nu masina: un dictionar cu obiecte drept chei le
## tine in viata si crapa la prima masina eliberata („previously freed instance",
## bug pe care `typhoon_hazard.gd` inca il scoate in sonde).
var _crest_dist: Dictionary = {}
## Cronometrul zguduiturii de fond. Unul singur pentru tot valul, nu unul per
## masina: shake-ul e al CAMEREI, iar camera urmareste o singura masina.
var _rumble: float = 0.0

const MODEL_PATH := "res://assets/models/wave_surge.glb"


func _ready() -> void:
	_anchor = position
	# Fata spre directia de mers, o singura data: creasta merge in linie dreapta,
	# deci basis-ul nu are ce sa se schimbe de la un cadru la altul. `Basis`, nu
	# `look_at`: `travel_dir` e in spatiul parintelui, care e si spatiul in care
	# se citeste basis-ul local — `look_at` ar fi cerut coordonate globale.
	if travel_dir.length_squared() > 0.001:
		basis = Basis.looking_at(travel_dir, Vector3.UP)
	super()
	if not Engine.is_editor_hint():
		_start_wash()


## Petecul ud tine cat creasta: lung cat ea de-a lungul soselei (X local, fiindca
## nodul e intors cu -Z pe directia de mers), si ingust pe directia de mers.
func _wet_patch_size() -> Vector3:
	return Vector3(crest_length, 3.0, film_depth)


## Creasta e ingropata cu `ride_height` sub asfalt; pelicula de apa nu are voie
## sa mearga cu ea, altfel iese sub drum si nu se mai vede.
func _wet_patch_offset() -> float:
	return 0.06 - ride_height


func _build_source() -> void:
	# Suportul poarta leganarea si inaintarea peliculei; piesele din GLB stau sub
	# el. Fara suport, orice rotatie a valului ar fi invartit si apa de pe drum.
	_model = Node3D.new()
	_model.name = "Crest"
	# Creasta sta pe MUCHIA DIN FATA a peliculei, nu pe mijlocul ei: valul impinge
	# apa inaintea lui, deci foaia ramane in urma lui. Fata = -Z local.
	_model.position.z = -0.28 * film_depth
	add_child(_model)
	_build_crest()
	_build_spray()
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	# Raza mare, ca la tromba: vuietul e jumatate din telegrafiere. Il auzi
	# crescand inainte sa te uiti dupa el.
	_audio.max_distance = 180.0
	_audio.unit_size = 20.0
	add_child(_audio)


## Creasta: O SINGURA piesa, scalata pe lungime la cat cere pista.
##
## Pana la #106 erau cinci copii de 6 m puse cap la cap, si din masina se vedea
## exact ce erau — cinci valuri identice cu cusaturi intre ele. Un val e o LINIE
## CONTINUA: orice ritm in ea se citeste instantaneu ca sablon. Acum GLB-ul e
## construit intreg la 30 m, cu varfuri inegale si o portiune deja sparta
## (`tools/blender/build_wave_surge.py`), iar aici se intinde doar cat trebuie.
func _build_crest() -> void:
	if not ResourceLoader.exists(MODEL_PATH):
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
		_model.add_child(mi)
		return
	var crest := (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	_model.add_child(crest)
	# Scalare doar pe X, si e intentionat neuniforma: o foaie de apa intinsa pe
	# lungimea ei nu se vede alungita, dar un val inaltat proportional fiindca
	# pista voia o creasta mai lunga ar iesi un zid de 6 m.
	var span := _model_span(crest)
	if span.x > 0.01:
		crest.scale.x = crest_length / span.x
	# Piesele animate se cauta dupa NUME, ca `Blades` la moara. Daca lipsesc,
	# valul merge fara animatia lor in loc sa crape.
	for child in crest.get_children():
		if child.name == "Wave_Foam":
			_foam = child as Node3D
		elif child.name == "Wave_Spray":
			_spray_piece = child as Node3D
	Palette.apply_world_material(crest)


## Stropii: particule, nu geometrie.
##
## Silueta singura nu vinde apa — tornada a invatat asta inaintea valului, si tot
## ea a dat reteta (`typhoon_hazard.gd`): trei sisteme mici bat un model mare.
## Emitatorul e o CUTIE cat toata creasta, deci stropii sar de pe toata lungimea
## ei, nu dintr-un punct.
func _build_spray() -> void:
	_spray = CPUParticles3D.new()
	_spray.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_spray.emission_box_extents = Vector3(crest_length * 0.5, 0.2, 0.4)
	_spray.position = Vector3(0.0, 1.4, -0.4)
	_spray.direction = Vector3(0, 1, -0.55)
	_spray.spread = 26.0
	_spray.initial_velocity_min = 2.5
	_spray.initial_velocity_max = 6.5
	_spray.gravity = Vector3(0, -9.0, 0)
	# Plafon de particule, regula din CLAUDE.md. 90 pe 30 m de creasta inseamna
	# trei stropi pe metru — destul cat sa citeasca, destul de putin cat sa nu
	# conteze pe mobil.
	_spray.amount = 90
	_spray.lifetime = 0.9
	_spray.emitting = false
	var drop := BoxMesh.new()
	drop.size = Vector3(0.16, 0.16, 0.16)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.vertex_color_use_as_albedo = true
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = drop_mat
	_spray.mesh = drop
	_spray.color = Palette.color(Palette.FOAM_WHITE)
	_model.add_child(_spray)


func _start_wash() -> void:
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager == null or _audio == null:
		return
	var stream: AudioStream = manager.call("stream", &"wave_wash")
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()


func _advance(delta: float) -> bool:
	_time += delta
	var t := fposmod(_time / PERIOD + phase, 1.0)
	# Valul e pe drum doar in prima parte a ciclului; in rest asteapta in larg.
	# Se ascunde in loc sa fie mutat departe: 2800 de triunghiuri plus 90 de
	# particule randate degeaba la 60 fps nu sunt gratis pe mobil.
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
	_animate(on_road)
	# Apa taie grip-ul doar cat creasta chiar atinge asfaltul. Marja de 1 m peste
	# jumatatea de latime tine cont de faptul ca petecul are si el grosime: fara
	# ea, valul ar uda ultimul metru de drum din varful zonei, adica inainte sa
	# se vada peste el.
	return absf(offset) <= half + 1.0


## Ce misca in val, in afara de deplasarea lui.
##
## Un obiect care se translateaza rigid citeste ca decupaj tras pe sfoara —
## aceeasi lectie pe care tornada o rezolva cu rotatia si braiele elicoidale.
## Valul n-are cum sa se roteasca (o suprafata de apa care se invarte e absurda),
## deci miscarea lui e alta: se LEAGANA pe directia de mers, spuma pulseaza,
## stropii sar, si toate trei se sting cand valul iese de pe drum.
func _animate(on_road: float) -> void:
	if _model != null:
		# Leganare in jurul axei crestei (X local): buza se apleaca inainte si se
		# ridica, adica exact miscarea unui val care se rastoarna. Amplitudine
		# mica — la mai mult de ~4° apa incepe sa arate ca o barca.
		_model.rotation.x = deg_to_rad(3.2 * sin(_time * 2.1))
	# Pulsul de spuma: creste cat valul e pe asfalt. Nu e decor — e semnalul
	# vizual care spune "ACUM", si de-aia e pe o piesa separata din GLB.
	if _foam != null:
		var pulse := 1.0 + (0.14 * sin(_time * 6.5) + 0.22 * on_road)
		_foam.scale = Vector3(1.0, pulse, 1.0)
	if _spray_piece != null:
		# Stropii de geometrie sar defazat fata de spuma: doua piese care pulseaza
		# la unison se citesc ca o singura piesa care pulseaza.
		_spray_piece.position.y = 0.18 * sin(_time * 3.7 + 1.1)
		_spray_piece.scale = Vector3.ONE * (1.0 + 0.18 * sin(_time * 5.3))
	if _spray != null:
		# Particulele pornesc doar cat valul e efectiv peste ceva: in larg n-are
		# de ce sa stropeasca, si sunt 90 de particule care nu se randeaza degeaba.
		_spray.emitting = on_road > 0.05
	if _audio != null:
		# Vuietul creste cand valul urca pe drum si scade cand se scurge. -30 dB
		# la capat inseamna practic tacere, dar fara opriri si porniri de stream.
		_audio.volume_db = lerpf(-30.0, -4.0, on_road)


## Ce pateste masina prinsa de val.
##
## Ordinea conteaza: intai imbrancitura (o singura data, la INTRARE), apoi
## franarea si grip-ul taiat (continue, cat stai in apa). Daca imbrancitura ar fi
## continua, valul ar impinge masina in fata lui ca un buldozer si ai iesi de pe
## dig — apa te LOVESTE o data si dupa aia doar te tine.
func _touch_car(car: Car, delta: float) -> void:
	super(car, delta)
	# Distanta de la masina la linia crestei, pe directia de mers a valului.
	var to_car := car.global_position - global_position
	var d := absf(to_car.dot(travel_dir))
	var key := car.get_instance_id()
	var was: float = _crest_dist.get(key, 1e9)
	_crest_dist[key] = d
	# Franare: apa mare ia din viteza cat timp esti in ea. Proportional cu delta,
	# deci nu depinde de rata de cadre.
	var keep := 1.0 - clampf(DRAG_PER_SEC * delta, 0.0, 0.5)
	car.velocity.x *= keep
	car.velocity.z *= keep
	# Zguduitura de fond, cat esti in apa. Se da la intervale, nu in fiecare cadru:
	# la 60 fps, `add_trauma` de 60 de ori pe secunda satureaza plafonul de 1.0 din
	# doua cadre si ecranul intra in convulsii. La 0.22 pe 0.12 s, trauma se tine
	# in jur de 0.3-0.4 cat timp esti udat — un tremur, nu o palma.
	_rumble += delta
	if _rumble >= SPLASH_EVERY:
		_rumble = 0.0
		car.splash(SPLASH_RUMBLE)
	# Imbrancitura + palma: doar cand creasta chiar trece peste masina, adica in
	# cadrul in care distanta scade sub un metru. `was` porneste de la infinit,
	# deci prima intrare se prinde si ea.
	if d > 1.0 or was <= 1.0:
		return
	car.apply_sweep(travel_dir * PUSH_IMPULSE)
	car.splash(SPLASH_TRAUMA)


## Cotele modelului, in unitati locale. AABB-ul se aduna din mesh-uri: radacina
## unui GLB e un Node3D gol, deci n-are AABB propriu.
func _model_span(root: Node) -> Vector3:
	var span := Vector3.ZERO
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			span = span.max(mi.mesh.get_aabb().size * mi.scale)
	return span

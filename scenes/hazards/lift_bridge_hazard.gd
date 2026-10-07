@tool
class_name LiftBridgeHazard
extends Node3D
## Podul cu travee ridicatoare peste un canal navigabil: la interval fix se
## ridica si lasa o gaura in pista. Cine intra prea incet cade in apa.
##
## Gimmick-ul e de DECIZIE, ca la tren, dar cu o intoarcere: acolo intrebarea e
## "franez sau fortez", aici e "am destula viteza". Traversa nu te loveste — pur
## si simplu nu mai e acolo, iar rampele de la cele doua buze transforma golul
## intr-o saritura pe care o faci sau n-o faci. Turbo-ul (model Ignition, resursa
## pe care o arzi cand vrei) isi capata aici cea mai clara intrebuintare de pe
## pista: il tii pentru pod sau il arzi mai devreme.
##
## [b]De ce se ridica pe verticala si nu se deschide in doua (bascula)[/b].
## Bascula e podul care arata bine si nu se poate sari: brațele ridicate stau fix
## pe buzele golului, adica exact pe linia de decolare si pe cea de aterizare —
## un zid, nu o saritura. Ca sa treaca vaporul cu catargele de 10 m, ele trebuie
## sa urce la ~70°, iar la 70° o masina intra in ele. Travee care urca DREPT intre
## doi piloni rezolva amandoua cerintele deodata: golul ramane curat de la apa
## pana la cer, masina zboara pe sub travee, catargele trec prin acelasi gol.
##
## [b]Cifrele saritei[/b] (gravitatie 28 m/s², rampa 1.6 m pe 5.0 m = 17.7°):
## decolezi de la +1.6 m si trebuie sa atingi buza cealalta tot la +1.6 m. Pentru
## un gol de 12 m iese pragul la ~24 m/s, adica 71% din viteza de varf de baza
## (34 m/s). Deci: cine merge tare trece fara sa se gandeasca, cine a ridicat
## piciorul sau a fost imbrancit inainte de pod inoata. Exact pedeapsa care
## trebuie — nu pentru viteza, ci pentru ezitare.
##
## Vaporul NU e decor de fundal: el e cronometrul. Il vezi venind pe canal cu
## secunde inainte si stii, fara sa te uiti la lumini, daca prinzi traveea jos.
##
## [b]Reuse cu parametri — barnele Podului Incas (Machu Picchu, brief §2 POI H)[/b].
## Pe cornisa, golul de 4 m e acoperit de barne care sunt SCOASE 6 s din 28:
## acelasi mecanism, cu traveea care COBOARA sub cornisa (`descend`) in loc
## sa urce intre turnuri, fara turnuri, fara corabii (`build_towers`,
## `build_ships`), cu ritmul din exporturi (`period`, `open_hold`,
## `lift_time`). Declarat DIRECT in scena pistei (nu printr-un canal): nod cu
## scriptul asta, `transform` cu -Z local pe sensul de mers si originea pe
## punctul copt din mijlocul golului, `near_lip`/`far_lip` LOCAL pe punctele
## copte vecine, `gap` = distanta dintre ele, `standalone_hole = true` — asa
## isi cere singur gaura din carosabil prin `road_hole_span()`
## (Track._resolve_span_holes, contractul pasajului rotativ si al podului de
## franghie). Pe cornisa nu e apa sub gol: terenul ramane la ~0.3 m sub
## asfalt, deci plasa de cadere isi ia plafonul din `fall_top_drop` (0.15),
## ca o masina oprita in gol sa fie repusa, nu blocata intre rampe.

# ------------------------------------------------------------------ ciclul
## Cat dureaza un ciclu complet (implicitul; vezi `period`).
const PERIOD: float = 10.0
## Cat sta traveea sus, complet deschisa.
const OPEN_HOLD: float = 3.0
## Cat dureaza ridicarea (si coborarea).
const LIFT_TIME: float = 0.9
## Cu cate secunde inainte de ridicare incep sa clipeasca luminile.
const WARN: float = 2.0
## Cat de sus urca traveea peste cota drumului.
##
## Nu e o cifra de stil: sub ea trebuie sa treaca catargele. Vaporul are 11.5 m
## la scara de joc si pluteste cu SHIP_DRAFT sub linia apei, deci varful lui
## ajunge la ~9.8 m peste apa. Cu soseaua la ~8.5 m peste apa, asta inseamna
## catarge care depasesc asfaltul — de-aia podul TREBUIE sa se deschida, si de
## aia degajarea se masoara, nu se ghiceste (vezi tools/probe_bridge.gd).
const LIFT_HEIGHT: float = 5.0

# ------------------------------------------------------------------- rampa
const RAMP_PATH := "res://assets/models/structures/bridge_ramp.glb"
const RAMP_NODE := "Bridge_Ramp"
## Lungimea si inaltimea rampei, IDENTICE cu cele din tools/blender/
## build_lift_bridge.py. Se rescriu aici fiindca din ele iese si cutia de
## coliziune (neteda, vezi _build_ramp) si pozitia traveei.
const RAMP_RUN: float = 5.0
const RAMP_RISE: float = 1.6

## Cat de tare arunca buza, ca fractie din viteza orizontala.
##
## Panta rampei NU arunca masina, si asta nu e o presupunere — e scris in
## [FlyoffKicker]: `Car` e un CharacterBody3D, `move_and_slide` o face sa
## ALUNECE pe suprafata, iar `floor_snap_length` o tine lipita si peste creasta.
## Masurat cu probe_bridge_drive: intrata cu 36 m/s, masina parasea varful cu
## velocity.y ~ 0, cadea 1.3 m pe cei 11 m de gol si se infigea in buza cealalta.
## Rampa ramane — ea e ce VEZI si ce face buza solida — dar aruncarea o face
## acelasi Area3D ca la crestele de fly-off.
##
## Factorul e DERIVAT din gol, nu ales: bataia unei arunc<ri e 2*f*v²/g, deci ca
## sa treci exact `gap` la viteza-prag v_p trebuie f = gap*g / (2*v_p²). Cu 11 m,
## g = 28 si v_p = 24 m/s (71% din viteza de varf de baza) iese 0.27. Sub prag
## cazi in apa, peste el treci — si cu cat intri mai tare, cu atat aterizezi mai
## departe, adica exact decizia pe care o vrem la turbo.
const LAUNCH_FACTOR: float = 0.27
## Plafon, ca un tur cu turbo sa nu devina zbor de planor.
const LAUNCH_MAX: float = 12.0

# ------------------------------------------------------------------ vapor
const SHIP_PATH := "res://assets/models/vehicles/tall_ship.glb"
const SHIP_NODE := "Tall_Ship"
## Vaporul e mai mare decat il da kitul: 13.1 m e o barca de pescuit langa un
## canal de 52 m. La 1.15 iese o corabie de 15 m, adica de trei ori lungimea
## unei masini — se citeste ca vapor si nu concureaza cu podul ca silueta.
const SHIP_SCALE: float = 1.15
## Cat din coca sta sub linia apei. Originea modelului e la CHILA (finish() cu
## origin="base"), deci scufundarea e o decizie de scena, nu una de asset.
const SHIP_DRAFT: float = 1.7
## Cat de repede merge, si cat de departe se duce inainte sa reintre in ciclu.
const SHIP_SPEED: float = 9.0
## Doua corabii pe o bucla de doua ori mai lunga decat a podului.
##
## Nu din generozitate: la o bucla de 10 s corabia ar fi trebuit sa reintre la
## 45 m de pod, adica in plin camp vizual, si SALTUL ei de la un capat la altul
## s-ar fi vazut de pe sosea. La 20 s reintrarea se muta la 90 m. Cu doua
## corabii defazate cu jumatate de perioada, prin gol trece una la FIECARE
## deschidere — deci si promisiunea se tine, si nu se vede trucul.
const SHIP_COUNT: int = 2
const SHIP_PERIOD: float = PERIOD * float(SHIP_COUNT)
## Decalajul care aduce o corabie in dreptul golului la mijlocul rastimpului in
## care traveea sta sus. Derivat, nu ales — vezi _ship_offset().
const SHIP_LEAD: float = SHIP_PERIOD * 0.5 - LIFT_TIME - OPEN_HOLD * 0.5

# ------------------------------------------------------------- structura
## Inaltimea pilonilor peste asfalt. Traveea urca LIFT_HEIGHT, deci turnul
## trebuie sa fie mai inalt decat atat plus grinda de sus.
const TOWER_HEIGHT: float = 8.4
const TOWER_LEG: float = 0.9
## Cat in afara marginii asfaltului stau picioarele turnului.
const TOWER_CLEAR: float = 1.1
## Grosimea traveei mobile si a grinzilor podului fix.
const SPAN_THICK: float = 0.55
## Pe cati metri se retrage talpa la capetele traveei si la varful rampei, ca
## fata dinspre gol sa fie PANTA si nu perete. Vezi _build_span pentru ce a
## costat lipsa ei.
const SPAN_END_SLOPE: float = 1.1
## Cat de des se pune un pilon sub tabliera fixa de peste apa.
const PIER_STEP: float = 11.0
## Sub atat de multa cadere, nu se mai construieste pilon: drumul sta pe mal.
const PIER_MIN_DROP: float = 2.0
const PIER_WIDTH: float = 2.2
# Parapetul NU se construieste aici. Peretele de margine al pistei
# (`Track._build_walls`) merge deja pe curba soselei si e exact inaltimea
# potrivita; peste apa se emite doar in alta culoare. Prima versiune il facea
# aici, din stalpi insirati pe axa LOCALA a podului — si asta e o axa DREAPTA,
# in timp ce soseaua se curbeaza: la 35 m de pod balustrada iesise deja de langa
# drum si plutea singura peste mare.

## Cat de departe inapoi e repusa masina care a cazut in canal.
##
## Mult mai mult decat implicitul de 14 m si decat cei 20 ai trenului: repunerea
## trebuie sa lase loc de ELAN. Repus la 15 m de buza, n-ai cum sa ajungi la cei
## ~24 m/s de care ai nevoie, deci ai cadea din nou — si bucla aia ar tine o
## masina in apa toata cursa.
const FALL_BACKOFF: float = 70.0

# --------------------------------------------------------------- parametri
## Latimea soselei acolo (jumatate).
@export var road_half_width: float = 7.0
## Cati metri de asfalt lipsesc. Vine masurat de la Track, nu cerut: capetele
## golului cad pe puncte coapte (vezi Track._resolve_channels).
@export var gap: float = 12.0
## Cotele celor doua buze, in spatiul LOCAL al nodului. Podul nu presupune ca
## soseaua e orizontala acolo — pe Okinawa are ~1.7% panta, adica 20 cm pe gol.
@export var near_lip: Vector3 = Vector3.ZERO
@export var far_lip: Vector3 = Vector3.ZERO

@export_group("Ciclu")
## Durata ciclului (s), cat sta traveea deschisa (s), cat dureaza miscarea (s).
## Implicitele sunt ale podului de pe Okinawa; barnele din Machu Picchu:
## 28 / 6 / 0.9.
@export_range(4.0, 120.0, 0.5) var period: float = PERIOD
@export_range(0.5, 60.0, 0.5) var open_hold: float = OPEN_HOLD
@export_range(0.2, 5.0, 0.1) var lift_time: float = LIFT_TIME
## SENSUL: traveea urca intre turnuri (implicit) sau COBOARA sub drum
## (barnele scoase de sub cornisa). Cursa e aceeasi (LIFT_HEIGHT).
@export var descend: bool = false
## Podul NU se ridica niciodata si NU arunca — un podet fix de scanduri
## (Chasm, Fiordland brief §2 randul D): tabliera, pilonii, rampele si
## plasa de cadere raman identice cu podul mobil, dar ciclul e mort si
## trambulina de la buza nu se construieste. Reuse cu parametru, ca la
## barnele Podului Incas (`descend`) — nu e o clasa noua.
@export var static_deck: bool = false
## Clasa triplanara pentru tabliera (`Palette.triplanar_class_material`), in
## loc de culoarea plata WOOD_WEATHERED din `_deck_material()`. Gol (implicit)
## = comportamentul vechi, bit-identic — pod-ul mobil de pe Okinawa si
## barnele Machu Picchu nu seteaza asta, deci raman neatinse. Setat de
## `TrackChannel.deck_material_class` (Chasm, Fiordland) prin
## `Track._build_lift_bridge`.
@export var deck_material_class: String = ""

@export_group("Structura")
## Turnurile cu grinda si lampile; corabiile de pe canal. Se sting pe un gol
## fara canal (cornisa): acolo nu are ce sa ridice si nu are pe ce sa pluteasca.
@export var build_towers: bool = true
@export var build_ships: bool = true
## Vaporul care traverseaza canalul. GOL (implicit) = corabia cu panze din
## kit (`SHIP_PATH` / `SHIP_NODE` / `SHIP_SCALE` / `SHIP_DRAFT`, prova pe +Z),
## bit-identic pe Track08 si Track15. Pe Okinawa (Track20, brief §3) vine un
## feribot: `ship_model` e calea GLB, `ship_node` numele nodului-radacina de
## extras. Celelalte trei se citesc doar cand `ship_model` e setat, fiindca un
## alt model are alta scara, alta origine si alta prova:
##  - `ship_scale`: scara pe holder;
##  - `ship_draft`: cat din coca sta sub origine (0 = originea e la linia de
##    plutire, cum cere `--origin=waterline`; tall_ship are originea la CHILA);
##  - `ship_bow_neg_z`: prova pe -Z (conventia proiectului), nu pe +Z.
@export_file("*.glb") var ship_model: String = ""
@export var ship_node: String = ""
@export var ship_scale: float = 1.0
@export var ship_draft: float = 0.0
@export var ship_bow_neg_z: bool = true
## Declarat direct in scena, nu printr-un canal: isi cere singur gaura din
## carosabil (`road_hole_span()` = `gap`). FALS cand podul e construit de
## Track dintr-un TrackChannel — acolo canalul a taiat deja asfaltul, si o a
## doua gaura pe acelasi loc ar putea cadea cu un pas mai lunga.
@export var standalone_hole: bool = false
## Plafonul plasei de cadere, sub cota buzei celei mai joase (m). 2.0 peste
## apa; pe cornisa, unde terenul e la 0.3 m sub asfalt, 0.15.
@export_range(0.05, 5.0, 0.05) var fall_top_drop: float = 2.0
## Cati metri inapoi e repusa masina cazuta. Vezi FALL_BACKOFF.
@export_range(5.0, 120.0, 1.0) var fall_backoff: float = FALL_BACKOFF
## Cota apei, local. Din ea ies pescajul corabiilor si podeaua zonei de cadere.
@export var water_y: float = -8.5
## Cat de departe se intinde apa canalului in fiecare parte. Corabiile nu ies
## din ea.
@export var channel_reach: float = 200.0
## Pilonii de sub tabliera fixa: (x, y, z) LOCAL plus cat de jos e fundul sub
## acel punct, ca `w`.
##
## Pozitiile vin gata calculate de la Track, pe PUNCTELE COAPTE ale soselei, si
## nu se deduc aici dintr-un pas pe axa locala. Axa locala e dreapta, soseaua nu:
## la 35 m de gol curba se departeaza de ea destul cat un pilon sa iasa de sub
## drum. Aceeasi separare ca la `TrainHazard.ground_drop` — cotele terenului stau
## in samplerul pistei, la care hazardul n-are acces.
@export var piers: Array[Vector4] = []

var _span: AnimatableBody3D
var _span_rest: float = 0.0
var _ships: Array[Node3D] = []
var _ship_hits: Array[Area3D] = []
var _lamps: Array[MeshInstance3D] = []
var _audio: AudioStreamPlayer3D
var _time: float = 0.0
var _last_bell: int = -1
var _cooldown: Dictionary = {}

## Materiale STATICE, partajate cu restul structurilor procedurale. Doua
## materiale pentru tot podul, si amandoua sunt sloturi din paleta deja
## folosite: garda de pe Okinawa numara materialele, nu obiectele.
static var _struct_mat: StandardMaterial3D
static var _deck_mat: StandardMaterial3D
static var _lamp_mat: StandardMaterial3D


func _ready() -> void:
	if build_towers:
		_build_towers()
	_build_piers()
	_build_ramps()
	if not static_deck:
		_build_kicker()
	_build_span()
	if build_ships:
		_build_ships()
	_build_fall_zone()
	_audio = AudioStreamPlayer3D.new()
	_audio.bus = &"SFX"
	_audio.max_distance = 160.0
	add_child(_audio)
	_apply_cycle(0.0)


## Structura si tabliera: doua sloturi de paleta, niciunul nou.
static func _structure_material() -> StandardMaterial3D:
	if _struct_mat == null:
		_struct_mat = StandardMaterial3D.new()
		_struct_mat.albedo_color = Palette.color(Palette.CONCRETE)
		_struct_mat.roughness = 0.92
	return _struct_mat


## Instanta, NU static: `deck_material_class` e per-hazard (Chasm cere lemn
## texturat, podul mobil de pe Okinawa si barnele Machu Picchu raman pe
## culoarea plata), deci materialul nu poate fi memoizat o singura data pe
## toata clasa, cum erau `_struct_mat`/`_lamp_mat` (identice peste tot).
## `Palette.triplanar_class_material(cls)` e ea insasi memoizata GLOBAL pe
## numele clasei — zero materiale noi la garda cata vreme clasa e deja
## folosita in alta parte a pistei (aici, `wood`, cache cu `driftwood`).
func _deck_material() -> StandardMaterial3D:
	if deck_material_class != "":
		return Palette.triplanar_class_material(deck_material_class)
	if _deck_mat == null:
		_deck_mat = StandardMaterial3D.new()
		_deck_mat.albedo_color = Palette.color(Palette.WOOD_WEATHERED)
		_deck_mat.roughness = 0.9
	return _deck_mat


# ------------------------------------------------------------------ turnuri

## Cei patru piloni, cate doi pe fiecare buza, cu grinda peste drum.
##
## Sunt si structura, si SEMNAL: podul trebuie sa se vada de la 200 m, altfel
## decizia "ard turbo-ul acum sau nu" se ia cu o secunda inainte, adica prea
## tarziu ca sa fie o decizie.
func _build_towers() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x_off := road_half_width + TOWER_CLEAR
	for lip: Vector3 in [near_lip, far_lip]:
		for side: float in [-1.0, 1.0]:
			var foot := lip + Vector3(0.0, -1.2, 0.0)
			foot.x += side * x_off
			_box(st, foot + Vector3(0.0, (TOWER_HEIGHT + 1.2) * 0.5, 0.0),
				Vector3(TOWER_LEG, TOWER_HEIGHT + 1.2, TOWER_LEG))
		# Grinda de sus, peste toata latimea drumului. Sub ea trece traveea
		# ridicata, deci sta la TOWER_HEIGHT si nu mai jos.
		_box(st, lip + Vector3(0.0, TOWER_HEIGHT - 0.35, 0.0),
			Vector3(x_off * 2.0 + TOWER_LEG, 0.7, TOWER_LEG * 1.1))
		# Contrafisele de colt: fara ele doi stalpi si o grinda citesc ca o poarta
		# de fotbal, nu ca un turn care ridica o tabliera.
		for side: float in [-1.0, 1.0]:
			_beam(st,
				lip + Vector3(side * (x_off - 1.9), TOWER_HEIGHT - 0.7, 0.0),
				lip + Vector3(side * x_off, TOWER_HEIGHT - 2.6, 0.0), 0.4)
	_emit(st, _structure_material(), "Towers")


# -------------------------------------------------------------------- piloni

## Pilonii care tin tabliera fixa deasupra apei.
##
## Fara ei soseaua de peste canal e o panglica de 3 m grosime care pluteste —
## exact bug-ul pe care l-a avut calea ferata peste rapa de pe Dunele, si care
## se vede cel mai bine tocmai cand ratezi saritura si cazi pe langa pod.
func _build_piers() -> void:
	if piers.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Grinda longitudinala de sub tabliera NU e aici, desi ar fi fost locul
	# evident. Am incercat: o cutie de la o buza la mal. Iese gresit din acelasi
	# motiv ca balustrada — o cutie e dreapta, soseaua nu. Betonul de sub drum
	# vine din `Track._build_road`, care merge pe curba prin constructie.
	for pier in piers:
		var drop := pier.w
		if drop < PIER_MIN_DROP:
			continue
		var top := pier.y - 1.5
		var bottom := pier.y - drop - 1.0
		var at := Vector3(pier.x, 0.0, pier.z)
		_box(st, at + Vector3(0.0, (top + bottom) * 0.5, 0.0),
			Vector3(PIER_WIDTH * 2.6, top - bottom, PIER_WIDTH))
		# Talpa lata: un pilon care intra in apa cu aceeasi sectiune arata infipt
		# cu forta, unul cu radier arata construit.
		_box(st, at + Vector3(0.0, bottom + 0.6, 0.0),
			Vector3(PIER_WIDTH * 3.2, 1.2, PIER_WIDTH * 1.7))
	_emit(st, _structure_material(), "Piers")


# -------------------------------------------------------------------- rampe

## Cele doua rampe de la buzele golului, plus cutiile lor de coliziune.
##
## Modelul e o cala de scanduri (Kenney, prin tools/blender/build_lift_bridge.py)
## si ARE ROSTURI intre grinzi. Vizual e chiar ce trebuie — se vede apa printre
## ele — dar ca suprafata de rulare ar fi un gratar: rotile ar cadea intre
## scanduri la 100 km/h. De aia coliziunea e o PANA neteda separata, iar mesh-ul
## nu are colizor deloc. Aceeasi despartire ca la orice rampa de joc: ce vezi si
## ce atingi n-au de ce sa fie acelasi triunghi.
func _build_ramps() -> void:
	var scene: PackedScene = null
	if ResourceLoader.exists(RAMP_PATH):
		scene = load(RAMP_PATH) as PackedScene
	for k in 2:
		var lip := near_lip if k == 0 else far_lip
		# Panta urca SPRE gol. Rampa e modelata cu varful spre -Z local (sensul
		# de mers), deci cea de la buza dinspre plecare sta asa cum vine, iar cea
		# de la aterizare se intoarce.
		var yaw := 0.0 if k == 0 else PI
		var sign_z := 1.0 if k == 0 else -1.0
		if scene != null:
			var model := _extract(scene, RAMP_NODE)
			if model != null:
				var holder := Node3D.new()
				holder.add_child(model)
				holder.rotation.y = yaw
				# Originea modelului e la baza, in mijlocul lungimii lui, iar
				# varful cade la +RAMP_RUN/2 pe axa lui. Buza trebuie sa fie
				# exact la varf, deci centrul se retrage cu jumatate de rampa.
				holder.position = lip + Vector3(0.0, 0.02,
					sign_z * RAMP_RUN * 0.5)
				add_child(holder)
				Palette.apply_world_material(model)
		# Pana de coliziune: un prisma triunghiular peste toata latimea.
		#
		# NUMELE conteaza pentru tools/probe_lane_clear.gd: o pana pe care
		# se CALCA (suprafata de rulare pana la gol) trebuie sa fie in lista
		# DRIVABLE, altfel garda o citeste ca zid. Fara nume explicit
		# ("Ramp", deja in lista — acelasi nume cu FlyoffKicker.gd), un
		# StaticBody3D.new() ramane "@StaticBody3D@N" si NU se scuza —
		# defect gasit pe Okinawa (Track08, absorbit tacut in linia de baza
		# 18 in loc de reparat) si pe podetul Chasm (unde static_deck tine
		# rampa permanent activa, deci orice sonda statica o prinde).
		#
		# Nume UNIC per capat, nu "Ramp" de doua ori. Masurat direct (Godot
		# 4.7): daca al doilea `body.name = "Ramp"` ruleaza cand fratele cu
		# acelasi nume exista deja, Godot NU uniformizeaza tacut in "Ramp2"
		# atunci cand numele e atribuit INAINTE de add_child() — revine la
		# formatul automat "@StaticBody3D@N", nenumit. Setat DUPA add_child()
		# Godot chiar da "Ramp"/"Ramp2", dar "Ramp2" nu mai e in DRIVABLE
		# (potrivire EXACTA, nu prefix) — deci nume explicite, ambele in
		# probe_lane_clear.gd.
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var wedge := ConvexPolygonShape3D.new()
		var hw := road_half_width
		var z_foot := sign_z * RAMP_RUN
		var pts := PackedVector3Array()
		for sx: float in [-hw, hw]:
			pts.append(Vector3(sx, -0.4, z_foot))
			pts.append(Vector3(sx, 0.0, z_foot))
			# Talpa se retrage de la buza, din acelasi motiv ca la travee:
			# altfel varful rampei e un perete de 2 m intors spre gol.
			pts.append(Vector3(sx, -0.4, sign_z * SPAN_END_SLOPE))
			pts.append(Vector3(sx, RAMP_RISE, 0.0))
		wedge.points = pts
		shape.shape = wedge
		body.add_child(shape)
		add_child(body)
		body.name = "RampNear" if k == 0 else "RampFar"
		body.position = lip


## Buza care arunca, exact pe varful rampei dinspre plecare.
##
## Se declanseaza si cu podul INCHIS, si asta e voit: masina rapida sare oricum
## peste tabliera si aterizeaza dincolo de ea, deci podul nu-i schimba cursa. Ce
## se schimba intre deschis si inchis e ce gaseste sub ea cine NU are viteza —
## scanduri sau apa. Aia e toata mecanica.
func _build_kicker() -> void:
	var kicker := FlyoffKicker.new()
	kicker.name = "LaunchLip"
	kicker.launch_factor = LAUNCH_FACTOR
	kicker.launch_max = LAUNCH_MAX
	# Sub viteza asta nu te arunca nimic: te tarasti pe rampa si, daca podul e
	# sus, cazi de pe buza. O aruncare mica ar fi si mai rea decat niciuna —
	# te-ar scoate din contactul cu solul fix cand ai nevoie de el.
	kicker.min_speed = 10.0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(road_half_width * 2.0, 2.6, 2.4)
	shape.shape = box
	kicker.add_child(shape)
	add_child(kicker)
	# Cu 1.2 m inaintea buzei: volumul trebuie sa fie strabatut INAINTE de
	# desprindere, nu dupa. Inaltimea e cea a varfului rampei plus jumatate de
	# cutie, ca masina sa intre in el cu tot cu roti.
	kicker.position = near_lip + Vector3(0.0, RAMP_RISE + 0.9, 1.2)


# ------------------------------------------------------------------- travee

## Traveea mobila: tabliera de scanduri care umple golul cand e jos.
##
## `AnimatableBody3D` cu `sync_to_physics`, ca la tren: masina care sta pe ea in
## clipa ridicarii e purtata in sus, nu strapunsa. Se ridica rar cu cineva
## deasupra, dar cand se intampla e cel mai bun cadru de pe pista.
func _build_span() -> void:
	_span = AnimatableBody3D.new()
	_span.name = "LiftSpan"
	_span.sync_to_physics = true
	add_child(_span)

	var hw := road_half_width
	# Tabliera nu e o CUTIE, e o pana intre cele doua buze — geometria ei se
	# scrie din cotele lor, nu dintr-o marime si o pozitie.
	#
	# Cutia a costat o cursa intreaga. Doua greseli se aduna in ea, si ambele
	# ridica marginea traveei DEASUPRA rampei care ar trebui sa duca in ea:
	#   - o cutie e orizontala, iar buzele nu sunt: soseaua are ~1.7% panta pe
	#     pod, deci intre ele sunt 19 cm. Asezata la media lor, traveea iese cu
	#     ~10 cm peste rampa dinspre plecare.
	#   - ii adaugasem 30 cm in fiecare capat ca sa acopere o fanta de sub un
	#     metru. Dar acolo rampa inca urca, deci cei 30 cm de tabliera stau peste
	#     ea, iar capatul lor e o fata VERTICALA de o jumatate de metru fix pe
	#     linia de rulare.
	# Rezultatul masurat (tools/probe_bridge_drive.gd): masina urca rampa, se
	# infige in muchia traveei la 14 m/s si se opreste. Plutonul de AI se aduna
	# acolo si cursa se termina la fractia 0.31 — cu podul INCHIS, adica exact
	# unde ar fi trebuit sa nu se intample nimic.
	#
	# Acum cele patru colturi de sus cad exact pe varfurile rampelor si nu mai
	# exista nicio muchie de care sa te agati.
	# Colturile se iau DIN BUZE, nu din `gap` si o simetrie presupusa.
	#
	# `gap` e lungimea coardei, dar originea podului (`baked[ci]`) nu cade la
	# mijlocul ei: pe Okinawa buzele ies la z = +5.20 si z = -5.78, adica
	# decalate cu 29 cm. Construita simetric, tabliera intra cu atat peste rampa
	# de la plecare — si acolo rampa inca urca, deci capatul ei ramane o fata
	# VERTICALA in mijlocul liniei de rulare. Masurat cu probe_bridge_drive:
	# normala de contact (-0.07, 0.00, 1.00), oprire de la 11 m/s la zero, cu
	# podul INCHIS. La celalalt capat lipsea exact aceeasi bucata.
	var near_top := near_lip + Vector3.UP * RAMP_RISE
	var far_top := far_lip + Vector3.UP * RAMP_RISE
	var lat := Vector3.RIGHT * hw
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [
		near_top - lat, near_top + lat, far_top + lat, far_top - lat,
	]
	var deep := Vector3.DOWN * SPAN_THICK
	for k in 4:
		var a: Vector3 = corners[k]
		var b: Vector3 = corners[(k + 1) % 4]
		st.add_vertex(a); st.add_vertex(b); st.add_vertex(a + deep)
		st.add_vertex(b); st.add_vertex(b + deep); st.add_vertex(a + deep)
	st.add_vertex(corners[0]); st.add_vertex(corners[2]); st.add_vertex(corners[1])
	st.add_vertex(corners[0]); st.add_vertex(corners[3]); st.add_vertex(corners[2])
	st.add_vertex(corners[0] + deep); st.add_vertex(corners[1] + deep)
	st.add_vertex(corners[2] + deep)
	st.add_vertex(corners[0] + deep); st.add_vertex(corners[2] + deep)
	st.add_vertex(corners[3] + deep)
	# Grinzile laterale: dau traveei o silueta cand e sus, altfel de pe sosea se
	# vede o scandura plutind. In afara latimii de rulare, ca sa nu devina ele
	# muchia de care ne-am ferit mai sus.
	var mid := (near_top + far_top) * 0.5
	for s: float in [-1.0, 1.0]:
		_box(st, mid + Vector3(s * (hw + 0.25), 0.35, 0.0),
			Vector3(0.5, 1.2, gap))
	var inst := MeshInstance3D.new()
	st.generate_normals()
	inst.mesh = st.commit()
	inst.material_override = _deck_material()
	_span.add_child(inst)

	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	var pts := PackedVector3Array()
	for c: Vector3 in corners:
		pts.append(c)
		# Fata de la capat se INCLINA, nu cade drept. Cu ea verticala, tabliera
		# are la fiecare capat un perete de o jumatate de metru — iar masina nu e
		# o sfera: colizorul ei ramane DREPT cand urca rampa, deci coltul lui din
		# fata calatoreste sub linia asfaltului si se infige exact in peretele
		# ala. Masurat cu tools/probe_bridge_drive.gd: oprire de la 11 m/s la
		# zero, fix la buza podului INCHIS, cu tot plutonul de AI adunat acolo.
		pts.append(c + deep - Vector3(0.0, 0.0, signf(c.z) * SPAN_END_SLOPE))
	hull.points = pts
	shape.shape = hull
	_span.add_child(shape)

	_span_rest = 0.0
	_span.position = Vector3.ZERO

	# Lampile de avertizare, pe grinzile de sus ale turnurilor.
	for lip: Vector3 in [near_lip, far_lip]:
		for side: float in [-1.0, 1.0]:
			var lamp := MeshInstance3D.new()
			var bulb := SphereMesh.new()
			bulb.radius = 0.38
			bulb.height = 0.76
			# Rezolutia implicita a unei sfere Godot e 64x32 = 4224 de triunghiuri
			# (vezi CLAUDE.md). Patru becuri asa ar fi costat cat un palmier.
			bulb.radial_segments = 8
			bulb.rings = 4
			lamp.mesh = bulb
			lamp.position = lip + Vector3(
				side * (road_half_width + TOWER_CLEAR - 0.7),
				TOWER_HEIGHT - 1.2, 0.0)
			if _lamp_mat == null:
				_lamp_mat = StandardMaterial3D.new()
				_lamp_mat.albedo_color = Color(0.85, 0.15, 0.1)
				# UNSHADED: un bec trebuie sa se vada aprins si din umbra.
				_lamp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			# Instanta proprie de material per lampa nu ne trebuie — clipesc
			# toate la unison — deci ramane unul singur, partajat.
			lamp.material_override = _lamp_mat
			add_child(lamp)
			_lamps.append(lamp)


# ------------------------------------------------------------------ corabii

func _build_ships() -> void:
	var path := SHIP_PATH if ship_model.is_empty() else ship_model
	var node_name := SHIP_NODE if ship_model.is_empty() else ship_node
	if not ResourceLoader.exists(path):
		return
	var scene := load(path) as PackedScene
	for i in SHIP_COUNT:
		var model := _extract(scene, node_name)
		if model == null:
			return
		var holder := Node3D.new()
		holder.name = "Ship%d" % i
		holder.add_child(model)
		holder.scale = Vector3.ONE * _ship_scale()
		# Canalul merge pe +X local, iar corabia are prova spre +Z, NU spre -Z
		# cum cere conventia proiectului: masurat pe GLB (sonda temporara
		# probe_ship_bow), capatul +Z e ingust si jos (bompresul, 0.4 m latime),
		# capatul -Z e lat si inalt (castelul pupei, 4.4 m / 9.2 m). Prima
		# versiune presupunea -Z si rotea cu -90°: corabiile navigau cu pupa
		# inainte. +90° pe Y aduce prova pe +X, in sensul de mers.
		model.rotation.y = PI * 0.5
		if not ship_model.is_empty() and ship_bow_neg_z:
			model.rotation.y = -PI * 0.5   # prova pe -Z: -90 o aduce pe +X
		add_child(holder)
		Palette.apply_world_material(model)
		_ships.append(holder)

		# Contactul cu coca = repunere, nu coliziune solida. Un corp solid ar
		# putea prinde o masina pe punte si ar scoate-o din lume cu vaporul cu
		# tot — zona de repunere din canal e SUB nivelul apei si n-ar mai
		# prinde-o niciodata.
		var hit := Area3D.new()
		var hs := CollisionShape3D.new()
		var hb := BoxShape3D.new()
		hb.size = Vector3(15.1, 6.0, 5.6) * _ship_scale()
		hs.shape = hb
		hs.position = Vector3(0.0, 2.0 * _ship_scale(), 0.0)
		hit.add_child(hs)
		holder.add_child(hit)
		_ship_hits.append(hit)


## Scara si pescajul EFECTIV al vaporului: constantele corabiei din kit cand
## `ship_model` e gol (comportamentul vechi), exporturile cand e setat.
func _ship_scale() -> float:
	return SHIP_SCALE if ship_model.is_empty() else ship_scale


func _ship_draft() -> float:
	if ship_model.is_empty():
		return SHIP_DRAFT * SHIP_SCALE
	return ship_draft * ship_scale


## Unde e corabia `i` pe canal, in metri fata de gol.
##
## SHIP_LEAD nu e reglat din ochi: se cere ca la mijlocul rastimpului in care
## traveea sta sus (LIFT_TIME + OPEN_HOLD/2) corabia sa fie exact in gol, adica
## faza ei sa fie la jumatatea buclei. De acolo iese formula, si de aceea
## ramane corecta daca se schimba OPEN_HOLD sau LIFT_TIME.
func _ship_offset(i: int) -> float:
	var phase := fposmod(_time + _ship_lead() + float(i) * period, _ship_period())
	return SHIP_SPEED * (phase - _ship_period() * 0.5)


## Bucla corabiilor si decalajul ei, din ritmul CURENT (vezi SHIP_PERIOD /
## SHIP_LEAD pentru derivare).
func _ship_period() -> float:
	return period * float(SHIP_COUNT)


func _ship_lead() -> float:
	return _ship_period() * 0.5 - lift_time - open_hold * 0.5


# ------------------------------------------------------------ plasa de cadere

## Cine a ratat saritura e repus, cu spatiu de elan.
##
## Zona sta PESTE cea globala de mare (Track._build_sea_respawn, al carei plafon
## e la nivelul apei minus 1.2 m): cine cade in canal trebuie sa primeasca
## repunerea CU ELAN de aici, nu pe cea de 16 m de acolo, care l-ar aseza inapoi
## pe buza podului fara viteza cu care sa-l treaca.
func _build_fall_zone() -> void:
	var zone := RespawnZone.new()
	zone.name = "BridgeFall"
	zone.backoff_m = fall_backoff
	add_child(zone)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var top := minf(near_lip.y, far_lip.y) - fall_top_drop
	var bottom := water_y - 4.0
	box.size = Vector3(road_half_width * 4.0, maxf(top - bottom, 2.0),
		gap + RAMP_RUN * 2.0)
	shape.shape = box
	shape.position = Vector3(0.0, (top + bottom) * 0.5, 0.0)
	zone.add_child(shape)


# ------------------------------------------------------------------- ciclul

func _physics_process(delta: float) -> void:
	if static_deck:
		return # tabliera ramane la _span_rest, fixata o data in _ready
	_time = fposmod(_time + delta, _ship_period())
	_apply_cycle(fposmod(_time, period))
	if Engine.is_editor_hint():
		return
	_tick_cooldowns(delta)
	_hit_ships()


## Cat e ridicata traveea, in 0..1, la momentul `t` din ciclu.
func _open_amount(t: float) -> float:
	if t < lift_time:
		return smoothstep(0.0, 1.0, t / lift_time)
	if t < lift_time + open_hold:
		return 1.0
	var falling := t - lift_time - open_hold
	if falling < lift_time:
		return smoothstep(0.0, 1.0, 1.0 - falling / lift_time)
	return 0.0


func _apply_cycle(t: float) -> void:
	var k := _open_amount(t)
	if _span != null:
		_span.position.y = _span_rest + (-LIFT_HEIGHT if descend else LIFT_HEIGHT) * k
	# Luminile: clipesc in avertizare (inainte de ridicare) si stau APRINSE cat
	# timp e gol. Doua stari diferite pentru doua informatii diferite — "vine" si
	# "acum" — fiindca la 100 km/h nu ai timp sa numeri clipiri.
	var warning := t > period - WARN
	var on := k > 0.02 or (warning and fmod(t, 0.45) < 0.24)
	for lamp in _lamps:
		lamp.visible = on
	for i in _ships.size():
		var s := _ship_offset(i)
		_ships[i].position = Vector3(s, water_y - _ship_draft(), 0.0)
		# Dincolo de apa canalului corabia n-are ce cauta: acolo terenul urca
		# inapoi la cota insulei si ar naviga prin nisip.
		_ships[i].visible = absf(s) < channel_reach
	if Engine.is_editor_hint():
		return
	_tick_audio(t, warning)


func _tick_audio(t: float, warning: bool) -> void:
	if warning:
		var bell := int((t - (period - WARN)) / 0.45)
		if bell != _last_bell:
			_last_bell = bell
			_play(&"crossing_bell")
	else:
		_last_bell = -1


## Sunetul, cerut prin ARBORE si nu prin identificatorul de autoload.
##
## `AudioManager.stream(...)` ar fi fost mai scurt si e ce fac train_hazard si
## rockfall_hazard — dar in modul `--script` autoload-urile nu exista, deci
## identificatorul nu se rezolva si SCRIPTUL NU COMPILEAZA. Pana acum n-a
## deranjat pe nimeni fiindca pistele cu tren nu se sondau asa; podul insa e pe
## Okinawa manual, adica exact pista pe care ruleaza probe_shore, probe_decor si
## probe_layout — toate cu `--script`. Cu clasa necompilata, `LiftBridgeHazard.new()`
## intoarce eroare si pista se construieste fara pod, in tacere.
func _play(sfx: StringName) -> void:
	var manager := get_node_or_null(^"/root/AudioManager")
	if manager == null:
		return
	var stream: AudioStream = manager.call("stream", sfx)
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()


func _tick_cooldowns(delta: float) -> void:
	# Netipat: `for car: Car in` ar ATRIBUI si cheile-masini deja eliberate
	# in variabila tipata, si chiar atribuirea da "previously freed instance"
	# (vezi nota din TyphoonHazard._steer_lofted).
	for key in _cooldown.keys():
		if not is_instance_valid(key):
			_cooldown.erase(key)
			continue
		var left: float = float(_cooldown[key]) - delta
		if left <= 0.0:
			_cooldown.erase(key)
		else:
			_cooldown[key] = left


func _hit_ships() -> void:
	for hit in _ship_hits:
		for body in hit.get_overlapping_bodies():
			var car := body as Car
			if car == null or _cooldown.has(car):
				continue
			_cooldown[car] = 2.0
			car.respawn(fall_backoff)


# ---------------------------------------------------------- pentru Track

## Contractul gaurii de carosabil (Track._resolve_span_holes), doar cand podul
## e declarat direct in scena (`standalone_hole`).
func road_hole_span() -> float:
	return gap if standalone_hole else 0.0


func wall_clear_span() -> float:
	return 0.0


# -------------------------------------------------------------------- unelte

## Instantiaza GLB-ul si pastreaza un singur nod, anuland offsetul lui din
## fisier. Acelasi tipar ca `TrainHazard._extract` — copiat si acolo, si aici,
## fiindca varianta din Track e metoda de instanta a pistei.
func _extract(scene: PackedScene, node_name: String) -> Node3D:
	var container := scene.instantiate() as Node3D
	var kept: Node3D = null
	for child in container.get_children():
		if String(child.name) == node_name:
			kept = child as Node3D
		else:
			container.remove_child(child)
			child.queue_free()
	if kept == null:
		container.queue_free()
		return null
	container.position = -kept.position
	return container


func _emit(st: SurfaceTool, mat: StandardMaterial3D, node_name: String) -> void:
	st.generate_normals()
	var mesh := st.commit()
	# BUG GASIT pe podetul Chasm: cand niciun pilon nu trece de PIER_MIN_DROP
	# (aici, ambele capete au drop 0.24/0.30 m — malul e aproape la cota
	# drumului langa buze, exact cum trebuie), `st.commit()` intoarce un mesh
	# FARA SUPRAFETE. `create_trimesh_shape()` pe un mesh gol nu arunca eroare
	# — produce un shape degenerat care se comporta ca un punct la ORIGINEA
	# LOCALA a nodului, adica exact centrul podului, PE AXA soselei. Sonda
	# `probe_lane_clear.gd` il gaseste ca "@StaticBody3D@N" la lat=0.000,
	# citit ca zid in mijlocul benzii. Fara garda asta, orice pod cu toate
	# capetele sub PIER_MIN_DROP (parauri inguste ca albia unui torent, nu
	# doar podetul Chasm) ar fi lasat o coliziune fluture in banda.
	if mesh.get_surface_count() == 0:
		return
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.material_override = mat
	add_child(inst)
	# Structura e solida: pilonii si turnurile opresc masina, ca orice perete.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	add_child(body)


## O cutie in SurfaceTool. Doua triunghiuri per fata, fara indexare.
func _box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var c := [
		center + Vector3(-h.x, -h.y, -h.z), center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, h.z), center + Vector3(-h.x, -h.y, h.z),
		center + Vector3(-h.x, h.y, -h.z), center + Vector3(h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, h.z), center + Vector3(-h.x, h.y, h.z),
	]
	const FACES := [
		[4, 5, 6, 7], [1, 0, 3, 2], [0, 1, 5, 4],
		[2, 3, 7, 6], [3, 0, 4, 7], [1, 2, 6, 5],
	]
	for f: Array in FACES:
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[1]]); st.add_vertex(c[f[2]])
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[2]]); st.add_vertex(c[f[3]])


## Grinda inclinata intre doua puncte. Acelasi cod ca `TrainHazard._beam`: o
## cutie aliniata pe axe n-ar putea desena o contrafisa.
func _beam(st: SurfaceTool, from: Vector3, to: Vector3, thick: float) -> void:
	var axis := to - from
	var len_sq := axis.length_squared()
	if len_sq < 1e-6:
		return
	var dir := axis / sqrt(len_sq)
	var ref := Vector3.RIGHT if absf(dir.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var u := dir.cross(ref).normalized() * (thick * 0.5)
	var v := dir.cross(u).normalized() * (thick * 0.5)
	var c := [
		from - u - v, from + u - v, from + u + v, from - u + v,
		to - u - v, to + u - v, to + u + v, to - u + v,
	]
	const FACES := [
		[4, 5, 6, 7], [1, 0, 3, 2], [0, 1, 5, 4],
		[2, 3, 7, 6], [3, 0, 4, 7], [1, 2, 6, 5],
	]
	for f: Array in FACES:
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[1]]); st.add_vertex(c[f[2]])
		st.add_vertex(c[f[0]]); st.add_vertex(c[f[2]]); st.add_vertex(c[f[3]])

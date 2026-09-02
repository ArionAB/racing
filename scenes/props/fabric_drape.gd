@tool
class_name FabricDrape
extends Node3D
## Panza dezumflata a balonului, ca SUPRAFATA CURBA — nu ca placa.
##
## [b]De ce exista.[/b] Criticul orb al rundei 2 a contrazis concluzia mea din
## runda 1 si a avut dreptate mai ieftin. Scrisesem ca panza nu poate citi panza
## fara sa reautoram assetul cu slack; raspunsul: nu-i trebuie slack, ii trebuie
## CURBURA. Trei-patru semi-cilindri asezati de-a curmezisul drumului dau
## terminatorul lumina-sus / umbra-dedesubt care face tesatura sa citeasca
## tesatura, cu zero autorat nou.
##
## [b]Cifra care spune de ce placa nu putea functiona.[/b] Masurat pe
## `balloon_landed.glb` cu tools/probe_bandmod.gd: 73% din normalele ei arata IN
## SUS. Aia nu e o tesatura, e o PODEA — si o podea nu are cum sa arunce un
## terminator, oricat de bine ai aseza-o. Cu 20,7 x 0,50 x 8,0 m e, geometric, un
## linoleu pictat, si exact asa a citit-o criticul. A doua cuta pe care o
## adaugasem in runda 1 n-a ajutat din acelasi motiv: doua lucruri plate
## suprapuse sunt tot plate.
##
## Semi-cilindrul real da 47% normale-sus / 53% flanc (masurat mai jos, prin
## `report()`). Diferenta fata de 73% e ce se vede.
##
## [b]De ce profilul e CERC, nu val.[/b] Prima incercare a folosit un profil
## abs(sin) — mai moale, mai "natural" pe hartie. A iesit 100% normale-sus, adica
## MAI RAU decat GLB-ul: o umflatura lina n-are flanc. Profilul trebuie sa aiba
## raza egala cu jumatatea pasului, altfel nu e cilindru si nu e terminator.
##
## [b]De ce mesh scris de mana, si nu un CylinderMesh.[/b] Un CylinderMesh brut
## are u 0..1, adica matura toate cele 32 de sloturi ale atlasului, inclusiv
## rezerva magenta de la 24 in sus (masurat: "u maturat = 32.0 sloturi").
## Contractul atlasului cere UV COLAPSAT pe centrul slotului — vezi nota lunga
## din world_prop.gd despre tetrapozii in dungi curcubeu. Cu UV-ul fixat aici,
## panza foloseste materialul comun al lumii: ZERO materiale in plus.
##
## Nodul se aseaza cu +Z in lungul valurilor si +X de-a curmezisul lor; panza se
## roteste din transformul nodului, ca sa cada de-a curmezisul soselei.

## Latimea panzei, de-a curmezisul valurilor (metri).
@export var width_m: float = 9.0:
	set(v):
		width_m = maxf(v, 0.5)
		_rebuild()

## Pasul unui semi-cilindru (metri). Raza cupolei e jumatate din el, deci pasul
## controleaza si cat de INALTA e panza — nu e un parametru de densitate.
@export var pitch_m: float = 4.0:
	set(v):
		pitch_m = maxf(v, 0.5)
		_rebuild()

## Cati semi-cilindri. Trei sau patru, cat cerea criticul: mai multi ar face din
## panza un acoperis ondulat de tabla, adica alt obiect.
@export var arches: int = 3:
	set(v):
		arches = clampi(v, 1, 8)
		_rebuild()

## Cat de mult se lasa cupolele spre capetele panzei (0 = toate la fel de
## inalte, 1 = ultimele complet culcate). Fara asta panza s-ar termina taiata in
## aer, adica exact defectul 3 al rundei 2 (obiect infipt intr-un plan).
@export_range(0.0, 1.0) var taper: float = 0.35:
	set(v):
		taper = clampf(v, 0.0, 1.0)
		_rebuild()

## Slotul de paleta pentru culoarea panzei. Implicit CAR_YELLOW, culoarea pe
## care o avea deja fasia galbena a GLB-ului.
@export var slot: int = 16:
	set(v):
		slot = clampi(v, 0, Palette.SLOTS - 1)
		_rebuild()

## Cat de sus ramane panza in valea dintre doua cupole (metri). Zero = atinge
## pamantul la fiecare vale, adica exact ce facea versiunea care citea "benzi
## de culoare pe pamant" in loc de invelis.
@export var floor_m: float = 0.45:
	set(v):
		floor_m = maxf(v, 0.0)
		_rebuild()

## Cat de fin pe latime / pe arc. 8 x 6 da 288 de triunghiuri pe panza — un
## SphereMesh implicit are 4224, deci trei panze costa cat un sfert de sfera.
@export var seg_width: int = 8:
	set(v):
		seg_width = clampi(v, 2, 24)
		_rebuild()

@export var seg_arch: int = 6:
	set(v):
		seg_arch = clampi(v, 2, 16)
		_rebuild()

## Cat de departe se cauta solul pe verticala, la asezarea fiecarui varf.
const GROUND_SEARCH_M: float = 40.0

var _mi: MeshInstance3D


func _ready() -> void:
	_rebuild()
	# A DOUA constructie, dupa ce lumea exista.
	#
	# `_ground_local` are nevoie de teren in spatiul fizic, iar la `_ready`-ul
	# nodului pista inca se construieste (terenul se coase in `Track.rebuild`,
	# care ruleaza pe radacina). Prima trecere iese deci cu solul la 0 —
	# comportamentul vechi, panza in plan. Un cadru mai tarziu terenul e acolo
	# si foaia se aseaza pe el.
	#
	# In editor (@tool) nu se asteapta: acolo `_rebuild` se cheama oricum la
	# fiecare modificare de parametru.
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		await get_tree().process_frame
		_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mi == null:
		_mi = MeshInstance3D.new()
		_mi.name = "Drape"
		# fara owner: nu intra in .tscn, ca la corpurile din world_prop
		add_child(_mi)
	_mi.mesh = _build()
	# DUBLA FATA, si nu din gust: panza e o suprafata DESCHISA, de grosime
	# zero — semi-cilindri cusuti pe Z, fara fund si fara spate. Cu materialul
	# obisnuit al lumii (StandardMaterial3D, deci CULL_BACK implicit) fetele
	# vazute din spate nu se deseneaza deloc, si atunci prin panza se vede
	# soseaua. Exact asta a raportat dezvoltatorul la primul tur condus
	# ("balonul cazut e TRANSPARENT", cadrul de la 55 s): din masina, care vine
	# din spatele cupolelor, jumatate din foaie pur si simplu lipseste.
	#
	# Nota de la `apply_foliage_material` spune acelasi lucru de mai demult:
	# "foile de 0 grosime dispar pe jumatate cu CULL_BACK". Panza e o foaie.
	#
	# ZERO materiale in plus: `foliage_material()` e un singleton duplicat FARA
	# subresurse din `world_material()`, deci textura, masca si detaliul raman
	# aceleasi obiecte pe GPU, si materialul e deja numarat de probe_decor.
	_mi.material_override = Palette.foliage_material()


## Mesh-ul: `arches` semicercuri inlantuite pe Z, latite pe X.
func _build() -> ArrayMesh:
	var r: float = pitch_m * 0.5
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var total: int = arches * seg_arch
	var uv_c: Vector2 = Palette.uv(slot)
	var span: float = float(arches) * pitch_m
	var w: int = seg_width + 1
	for j in range(total + 1):
		var ai: int = mini(j / seg_arch, arches - 1)
		var k: int = j - ai * seg_arch
		var th: float = PI * float(k) / float(seg_arch)
		var z: float = float(ai) * pitch_m + r - r * cos(th)
		# Cupola PLUS o talpa: intre doua cupole panza nu atinge pamantul, se
		# aseaza pe restul de aer al ei. Fara talpa, profilul revine la zero la
		# fiecare vale si printre foi se vedea PAMANT — pe capturile r2f/r2g
		# cele trei panze citeau benzi de culoare separate, nu un invelis
		# prabusit. O panza de balon dezumflat ramane un morman continuu; doar
		# creasta urca si coboara.
		var y: float = floor_m + (r - floor_m) * sin(th)
		var ny: float = sin(th)
		var nz: float = -cos(th)
		var tz: float = z / span
		# capetele panzei se lasa pe teren
		var fall: float = 1.0 - taper * pow(2.0 * absf(tz - 0.5), 3.0)
		for i in range(seg_width + 1):
			var tu: float = float(i) / float(seg_width)
			var x: float = (tu - 0.5) * width_m
			# Marginile laterale coboara, dar DOAR pe ultima cincime: panza
			# trebuie sa ramana o PANZA pe toata latimea.
			#
			# Aici a fost greseala care a costat doua capturi. Prima versiune
			# avea `lat = sin(PI*tu)^0.45`, adica o cadere care incepe din
			# mijloc si strange foaia spre zero la ambele capete. Inmultita cu
			# `fall` (care face acelasi lucru pe cealalta axa), panza ramanea un
			# SIRET: pe captura r2e/r2f cele trei foi citeau panglici aruncate
			# pe pamant, nu tesatura — exact "litter"-ul de care avertizase
			# criticul. O foaie de balon dezumflat e lata; se lasa la margine,
			# nu se ascute.
			var edge: float = clampf(minf(tu, 1.0 - tu) / 0.20, 0.0, 1.0)
			var lat: float = smoothstep(0.0, 1.0, edge)
			var lz: float = z - span * 0.5
			# COTA TERENULUI SUB FIECARE VARF, nu cota nodului.
			#
			# Pana aici panza era construita intr-un plan local orizontal: toti
			# vertecsii porneau de la y = 0 al nodului, si numai profilul de
			# cupola ii ridica. Pe teren plat asta merge; pe coasta pe care sta
			# de fapt POI E, nu. Masurat cu ProbeCappPanzaTalpa: 71-74% din
			# vertecsi stateau la peste 30 cm deasupra solului, in medie 0.95 m
			# si pana la 2.35 m — adica exact "panglici colorate care plutesc",
			# cu pamant si umbre vizibile pe sub foaie. O panza prabusita nu
			# pluteste; ea IA FORMA a ce e sub ea.
			#
			# Deci cota locala a solului intra ca baza, si profilul de cupola se
			# adauga peste ea. Terenul se citeste o singura data pe varf, la
			# construire (panza nu se misca), deci nu costa nimic pe cadru.
			var base: float = _ground_local(x, lz)
			verts.append(Vector3(x, base + y * fall * lat, lz))
			var nx: float = 0.0
			if edge > 0.0 and edge < 1.0:
				# derivata lui smoothstep(edge) dupa x, cu semnul marginii
				var dl: float = 6.0 * edge * (1.0 - edge) / (0.20 * width_m)
				nx = -(y * fall * dl * (1.0 if tu < 0.5 else -1.0))
			norms.append(Vector3(nx, ny, nz).normalized())
			uvs.append(uv_c)
	for j in range(total):
		for i in range(seg_width):
			var a: int = j * w + i
			var b: int = j * w + i + 1
			var c: int = (j + 1) * w + i
			var d: int = (j + 1) * w + i + 1
			idx.append_array([a, c, b, b, c, d])
			# SI FATA DE DEDESUBT. Panza e o suprafata deschisa de grosime
			# zero: cu winding-ul intr-un singur sens, tot ce se vede din spate
			# sau de dedesubt pur si simplu nu se deseneaza, si prin foaie se
			# vede soseaua — "balonul cazut e TRANSPARENT" din raportul de la
			# volan (cadrul de la 55 s).
			#
			# Se face in GEOMETRIE, nu prin `cull_mode`, dintr-un motiv masurat:
			# materialul pus aici e rescris mai tarziu (WorldProp reaplica
			# materialul lumii pe subarbore), deci un CULL_DISABLED pus pe
			# material nu supravietuieste pana la randare — sonda l-a gasit
			# inapoi pe CULL_BACK. Triunghiurile intoarse nu pot fi rescrise de
			# nimeni.
			#
			# Costul: 288 -> 576 de triunghiuri pe panza, adica trei panze
			# ajung cat un sfert de SphereMesh implicit. Zero materiale.
			idx.append_array([a, b, c, b, d, c])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


## Cota terenului sub un punct din spatiul LOCAL al panzei, intoarsa tot in
## spatiul local (adica: cu cat trebuie coborat/urcat varful fata de planul
## nodului ca sa stea pe pamant).
##
## Se foloseste raycast pe lumea fizica: panza se construieste dupa ce terenul
## si prop-urile exista, si asa foaia se aseaza si peste un bolovan, nu doar
## peste campul de inaltimi. Daca raza nu gaseste nimic (panza construita
## inainte de teren, sau in editor), se intoarce 0 — comportamentul dinainte.
func _ground_local(lx: float, lz: float) -> float:
	if not is_inside_tree():
		return 0.0
	var world := get_world_3d()
	if world == null:
		return 0.0
	var space := world.direct_space_state
	if space == null:
		return 0.0
	var w: Vector3 = global_transform * Vector3(lx, 0.0, lz)
	var q := PhysicsRayQueryParameters3D.create(
		w + Vector3.UP * GROUND_SEARCH_M, w + Vector3.DOWN * GROUND_SEARCH_M)
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return 0.0
	var gy: float = float(hit["position"].y)
	# inapoi in local: doar diferenta pe verticala conteaza, nodul nu e rotit
	# pe alta axa decat Y (vezi antetul).
	return clampf(gy - global_position.y, -GROUND_SEARCH_M, GROUND_SEARCH_M)


## Ce trebuie sa poata verifica o sonda: cat din panza e fata de sus si cat e
## flanc. Placa GLB e la 73% sus; un semi-cilindru real trebuie sa fie sub 60%.
func report() -> Dictionary:
	var m := _build()
	var arr: Array = m.surface_get_arrays(0)
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var up: int = 0
	for n in norms:
		if n.y > 0.6:
			up += 1
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var hi: float = -1e9
	for v in verts:
		hi = maxf(hi, v.y)
	return {
		"verts": norms.size(),
		"tris": (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3,
		"up_pct": 100.0 * float(up) / float(norms.size()),
		"height_m": hi,
	}

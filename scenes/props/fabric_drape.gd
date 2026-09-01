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

var _mi: MeshInstance3D


func _ready() -> void:
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
	_mi.material_override = Palette.world_material()


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
			verts.append(Vector3(x, y * fall * lat, z - span * 0.5))
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
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


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

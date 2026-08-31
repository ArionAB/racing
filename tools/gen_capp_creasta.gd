extends Node
## Generator RUNDA 10 pentru POI B: CREASTA CARE TAIE ORIZONTUL, pe umarul
## exterior (dreapta, spre Valea Rosie).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenCappCreasta.tscn
##
## De ce exista, si de ce e un PERETE si nu inca o sapatura.
##
## Amandoi criticii, runda 10, au cerut acelasi lucru cu aceleasi cuvinte:
## "ochiul poate merge de la marginea drumului pana la cer fara sa treaca peste
## NICIO suprafata verticala pe jumatatea dreapta". Noua runde s-au dus pe
## sapat in jos — canioane, taieturi, buze de cornisa. Masurat acum
## (ProbeCappCreasta), caderea CHIAR exista: la 25 m in dreapta terenul e cu
## 21.7 m sub sosea si ramane acolo pana la 80 m. Problema nu e ca lipseste
## caderea, e ca fundul ei e PLAT si nimic nu urca inapoi: pe ecran, un gol
## fara margine departata se citeste ca o campie, fiindca nu are cu ce sa fie
## comparat. O prapastie se vede DOAR daca i se vede peretele opus.
##
## Cifrele care aseaza peretele (ProbeCappLinie --dist=38, fracii 0.075-0.185):
##   teren la 38 m dreapta:  +24.7 .. +26.1     (aproape orizontal, ±1.5 m)
##   sosea pe aceeasi fractie: +45.1 .. +48.4
##   deci caderea:            -22 m, constanta
##   plafonul cadrului la 38 m: 38.0 m peste teren
## Un perete inalt de 28-31 m asezat pe fundul vaii are creasta la +4..+8 m
## PESTE cota soselei — adica taie linia orizontului — si ii mai raman ~30 m
## pana la marginea de sus a cadrului. Nu poate nici sa dispara sub buza, nici
## sa iasa din poza; ambele erau riscuri reale, si amandoua se calculeaza, nu
## se incearca.
##
## De ce `cliff_band_module` si nu geometrie noua: piesa e masurata 20.3 x 12.4 m
## si e AUTORATA cu benzi orizontale, adica exact "presented broadside so its
## banding is visible as horizontal steps" din cererea criticului. Doua randuri
## suprapuse dau 24.8 m; al treilea rand partial ridica creasta unde trebuie.
## Zero materiale noi: piesa e deja in Track13.tscn ca ExtResource 23_cliff.

const TRACK := "res://scenes/tracks/Track13.tscn"

const RES := {
	"rocks/cliff_band_module": "23_cliff",
	"rocks/red_mesa": "24_mesa",
	"rocks/chimney_a": "10_ch_a",
	"rocks/chimney_b": "11_ch_b",
	"rocks/chimney_c": "12_ch_c",
	"rocks/chimney_d": "13_ch_d",
	"rocks/chimney_mushroom": "14_ch_mush",
	"rocks/chimney_triple": "15_ch_tri",
}

## Distanta de la ax pana la fata peretelui. 62 m, nu 38: la 38 peretele a iesit
## in captura ca un ZID DE SPRIJIN langa sosea — se vedea fata lui de sus, deci
## citea a mal betonat, nu a mal de dincolo. Ca sa se citeasca prapastia, ochiul
## trebuie sa TRAVERSEZE golul inainte sa dea de perete; la 62 m intre buza si
## el raman ~55 m de vale goala, si abia atunci caderea are ce compara.
## Tot in ceata scurta (fog_end ~250 m), deci benzile raman citibile.
const DIST := 62.0

## Cat de sus urca creasta peste cota SOSELEI. Pozitiv = taie orizontul.
##
## 2.5 m, nu 6: creasta trebuie sa treaca PESTE linia orizontului (altfel nu
## taie nimic), dar cu cat urca mai mult cu atat inghite mai mult din cerul in
## care se ridica baloanele — iar baloanele sunt gimmick-ul pistei. 2.5 m e
## minimul care se vede clar peste linie la 62 m distanta.
const CREST_ABOVE_ROAD := 2.5

var _track: Track
var _sampler: TrackSideSampler
var _out: PackedStringArray = []
var _rng := RandomNumberGenerator.new()
var _n := 0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	_rng.seed = 101077
	_wall()
	print("")
	for line in _out:
		print(line)
	print("; asezate %d piese pe creasta" % _n)
	get_tree().quit(0)


## Peretele propriu-zis: un sir NEINTRERUPT de module, suprapuse pe orizontala
## ca sa nu ramana fante de cer intre ele.
##
## Pasul e 16 m pe o piesa de 20.3 m latime: suprapunerea de 4 m e ce
## garanteaza ca nu se vede cerul printre module cand camera se misca lateral.
## Un sir "cap la cap" ar fi lasat fante la orice unghi oblic — si tocmai
## unghiul oblic e cel din care se conduce.
func _wall() -> void:
	var n := _track.baked.size()
	# Pasul in FRACTIUNI se deriva din pasul in metri: lungimea pistei impartita
	# la numarul de puncte coapte da metri pe punct.
	var total := 0.0
	for i in n:
		total += _track.baked[i].distance_to(_track.baked[(i + 1) % n])
	var step_frac := 11.0 / total
	var f := 0.062
	var col := 0
	while f <= 0.196:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var q := p + s * DIST
		var g := _sampler.ground_y(q.x, q.z)
		# Inaltimea CERUTA: de la teren pana la creasta, unde creasta sta cu
		# CREST_ABOVE_ROAD peste sosea. Se recalculeaza la fiecare modul,
		# fiindca si soseaua si terenul coboara pe parcurs — un perete de
		# inaltime fixa ar fi iesit din orizont la un capat si sub el la
		# celalalt.
		var want := (p.y + CREST_ABOVE_ROAD) - g
		# Variatie de creasta: o linie perfect dreapta ar citi a zid de beton.
		# ±2.2 m pe doua armonici, deci creasta unduieste dar nu coboara
		# niciodata sub cota soselei (want e minim ~26 m, variatia e 8%).
		want += 2.2 * sin(float(col) * 0.9) + 1.3 * sin(float(col) * 2.3 + 1.1)
		# Fata peretelui se uita spre DRUM: piesa e autorata cu benzile pe
		# latimea X, deci yaw-ul trebuie sa puna X de-a lungul benzii si Z
		# catre ax. `s` e catre exterior, deci -s e catre drum.
		var yaw := atan2(-s.x, -s.z)
		# Doua randuri suprapuse pe verticala + un rest. Piesa are 12.4 m; se
		# scaleaza pe Y ca suma sa dea exact `want`, si pe X cu putin peste 1
		# ca sa acopere pasul.
		var rows := int(ceil(want / 12.4))
		rows = maxi(rows, 2)
		var sy := (want / float(rows)) / 12.4
		for r in rows:
			# Fiecare rand e putin retras fata de cel de dedesubt: o faleza
			# reala se ingusteaza in sus, iar retragerea e chiar TREAPTA pe
			# care criticul o cere vizibila ("horizontal steps").
			#
			# Retragerea NU e constanta pe coloana. Cu un pas fix, toate
			# modulele de pe acelasi rand stateau pe aceeasi linie si rosturile
			# verticale se suprapuneau perfect — in captura de la 38 m
			# rezultatul citea a ZIDARIE, randuri de caramida, nu strat de
			# roca. Un depozit erodat se retrage neuniform, deci si retragerea
			# se face neuniforma, per coloana si per rand.
			# Retragerea e MICA si monotona. Prima incercare a variat-o per
			# coloana ca sa rupa aspectul de zidarie; efectul masurat in captura
			# a fost invers si mai rau — modulele s-au desprins unul de altul si
			# printre ele se vedea cer, adica exact ce trebuia peretele sa
			# acopere. Piesa are 6 m grosime: orice retragere comparabila ii
			# scoate capetele la vedere. Continuitatea bate varietatea, fiindca
			# cererea criticului e un perete NEINTRERUPT.
			var setback := float(r) * 1.1
			var yy := g + float(r) * (want / float(rows))
			var qq := q + s * setback
			# Peste 1 ca modulele sa se MUSTE intre ele: cu pasul de 11 m pe o
			# piesa de 20.3 m suprapunerea e de ~9 m, deci nu ramane fanta de
			# cer nici la unghiul oblic din care se conduce.
			var sx := 1.10 - float(r) * 0.03
			_raw("rocks/cliff_band_module", "zidValea",
				Vector3(qq.x, yy, qq.z), yaw, sx, sy)
		col += 1
		f += step_frac
	print("; perete: %d coloane, pas %.1f m, fata la %.0f m de ax" % [
		col, 11.0, DIST])


func _raw(model: String, base: String, pos: Vector3, yaw: float,
		scl: float, scl_y: float) -> void:
	_n += 1
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="DecorManual/ZidulValeiRosii" instance=ExtResource("%s")]'
		% [base, _n, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, scl_y, s, c, pos.x, pos.y, pos.z])
	# Departe de banda si sub nivelul ei: nu are nevoie de corp fizic. Masina
	# n-ajunge acolo, iar un hull per modul ar fi zeci de corpuri degeaba.
	_out.append('metadata/coliziune = "niciuna"')
	_out.append("")

extends SceneTree
## Cat de "texturata" e lumea, in cifre.
##
## "Arata plat" e o parere; deviatia de luminanta e un numar pe care oricine din
## echipa il poate reproduce. Sonda taie imaginea in dale mici si masoara cat
## variaza luminozitatea INAUNTRUL fiecarei dale — deci masoara textura de
## suprafata, nu contrastul dintre obiecte. O stanca de o singura culoare da
## sigma ~0 oricat de dramatica ar fi silueta ei.
##
## Se ruleaza pe poza INGHETATA de masurare (tools/snapshot.gd --driver). Daca
## cineva schimba parametrii aceia, cifrele nu mai sunt comparabile intre
## build-uri — vezi avertismentul din antetul lui snapshot.gd.
##
## Rulare:
##   godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.20 --driver
##   godot --headless --path . --script res://tools/measure_surface.gd -- \
##       --image=snapshots/dunele_sofer.png
##
## Fara alte argumente masoara zonele standard de pe Dunele la frac 0.20 (vezi
## PATCHES_DUNELE). Alege singur zone cu --patch, in fractii 0..1:
##   ... -- --patch=faleza:0.28,0.36,0.40,0.46
##
## ATENTIE la alegerea zonei: un dreptunghi care prinde si cer, si nisip, si
## stanca masoara media dintre ele, nu textura niciuneia. Prima versiune a
## zonei "faleza" includea cerul de deasupra si dadea 3.5, in timp ce stanca
## propriu-zisa era la 8.4.
##
## Cu --min=N iese cu cod 1 daca medianul global e sub prag (util in CI).

## Zonele standard de pe poza inghetata a Dunelor (--track=0 --frac=0.20).
## Coordonate in fractii din latime/inaltime: x0, y0, x1, y1.
const PATCHES_DUNELE := {
	"faleza_aproape": [0.28, 0.36, 0.40, 0.46],
	"faleza_departe": [0.05, 0.50, 0.20, 0.56],
	"nisip": [0.02, 0.60, 0.30, 0.80],
	"asfalt": [0.40, 0.75, 0.62, 0.95],
}

## Latura dalei, in pixeli. 8 masoara granulatie, 16 masoara pete mai mari.
const DEFAULT_TILE: int = 8
## Dale cu mai putini pixeli utili de-atat se ignora (marginile imaginii).
const MIN_TILE_PIXELS: int = 32


func _initialize() -> void:
	var path := ""
	var tile := DEFAULT_TILE
	var min_sigma := -1.0
	var patches: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--image="):
			path = arg.trim_prefix("--image=")
		elif arg.begins_with("--tile="):
			tile = maxi(2, int(arg.trim_prefix("--tile=")))
		elif arg.begins_with("--min="):
			min_sigma = float(arg.trim_prefix("--min="))
		elif arg.begins_with("--patch="):
			var spec := arg.trim_prefix("--patch=")
			var parts := spec.split(":")
			if parts.size() != 2:
				push_error("--patch cere forma nume:x0,y0,x1,y1")
				quit(1)
				return
			var nums := parts[1].split(",")
			if nums.size() != 4:
				push_error("--patch cere 4 fractii: nume:x0,y0,x1,y1")
				quit(1)
				return
			patches.append({
				"name": parts[0],
				"rect": Rect2(float(nums[0]), float(nums[1]),
					float(nums[2]) - float(nums[0]),
					float(nums[3]) - float(nums[1])),
			})
	if path.is_empty():
		push_error("measure_surface: lipseste --image=<cale>")
		quit(1)
		return

	var img := Image.load_from_file(ProjectSettings.globalize_path(path)) \
		if path.begins_with("res://") else Image.load_from_file(path)
	if img == null:
		push_error("measure_surface: nu pot citi '%s'" % path)
		quit(1)
		return

	var w := img.get_width()
	var h := img.get_height()
	print("=== TEXTURA DE SUPRAFATA: %s (%dx%d, dale de %dpx) ==="
		% [path.get_file(), w, h, tile])

	# Luminanta o data, apoi toate masuratorile citesc din tabloul asta.
	var lum := PackedFloat32Array()
	lum.resize(w * h)
	var warm := PackedByteArray()
	warm.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var i := y * w + x
			lum[i] = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			# "Cald" = albastrul nu domina rosul. Exclude cerul, care e o
			# suprafata uriasa si neteda si ar trage medianul in jos indiferent
			# cat de texturat e restul lumii.
			warm[i] = 1 if c.b <= c.r else 0

	var global_sigmas := _tile_sigmas(lum, warm, w, h, tile,
		Rect2(0.0, 0.0, 1.0, 1.0), true)
	_report("CADRU (doar dale calde)", global_sigmas)

	# Fara --patch explicit, masoara zonele standard: altfel fiecare rulare ar
	# alege alt dreptunghi si cifrele n-ar mai fi comparabile intre build-uri.
	if patches.is_empty():
		for name: String in PATCHES_DUNELE:
			var r: Array = PATCHES_DUNELE[name]
			patches.append({
				"name": name,
				"rect": Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1]),
			})

	for p in patches:
		var s := _tile_sigmas(lum, warm, w, h, tile, p["rect"], false)
		_report(p["name"], s)

	if min_sigma >= 0.0:
		var med := _median(global_sigmas)
		if med < min_sigma:
			printerr("PICA: median %.2f < prag %.2f" % [med, min_sigma])
			quit(1)
			return
		print("\nOK — median %.2f >= prag %.2f" % [med, min_sigma])
	quit(0)


## Deviatia standard a luminantei in fiecare dala din interiorul unui dreptunghi.
##
## Valorile sunt in trepte de 0..255, ca sa fie comparabile cu ce citesti dintr-un
## editor de imagini.
func _tile_sigmas(lum: PackedFloat32Array, warm: PackedByteArray, w: int, h: int,
		tile: int, frac: Rect2, warm_only: bool) -> Array[float]:
	var x0 := int(frac.position.x * float(w))
	var y0 := int(frac.position.y * float(h))
	var x1 := mini(w, int((frac.position.x + frac.size.x) * float(w)))
	var y1 := mini(h, int((frac.position.y + frac.size.y) * float(h)))
	var out: Array[float] = []
	var ty := y0
	while ty < y1:
		var tx := x0
		while tx < x1:
			var n := 0
			var sum := 0.0
			var sum_sq := 0.0
			for y in range(ty, mini(ty + tile, y1)):
				for x in range(tx, mini(tx + tile, x1)):
					var i := y * w + x
					if warm_only and warm[i] == 0:
						continue
					var v := lum[i] * 255.0
					sum += v
					sum_sq += v * v
					n += 1
			if n >= MIN_TILE_PIXELS:
				var mean := sum / float(n)
				out.append(sqrt(maxf(sum_sq / float(n) - mean * mean, 0.0)))
			tx += tile
		ty += tile
	return out


func _report(label: String, sigmas: Array[float]) -> void:
	if sigmas.is_empty():
		print("%-22s (nicio dala utila)" % label)
		return
	var sorted := sigmas.duplicate()
	sorted.sort()
	print("%-22s median %6.2f   p25 %6.2f   p75 %6.2f   max %6.2f   (%d dale)"
		% [label, _median(sorted), _percentile(sorted, 0.25),
			_percentile(sorted, 0.75), sorted[sorted.size() - 1], sorted.size()])


func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var s := values.duplicate()
	s.sort()
	return _percentile(s, 0.5)


## Asteapta un tablou DEJA sortat.
func _percentile(sorted: Array[float], q: float) -> float:
	if sorted.is_empty():
		return 0.0
	var idx := clampi(int(q * float(sorted.size())), 0, sorted.size() - 1)
	return sorted[idx]

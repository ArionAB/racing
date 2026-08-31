extends Node
## UNDE in cadru cade un obiect asezat la X metri lateral si Y metri in fata?
##
## De ce exista, si ce a raspuns. Lead-ul cere "conuri, moloz si vegetatie LANGA
## banda, in treimea de jos". Sonda spune ca instructiunea NU se poate executa
## asa cum e scrisa, si e o constrangere de geometrie, nu de efort:
##
##   treimea de jos incepe la y=480
##   obiect la marginea carosabilului (6.5 m), la 8 m in fata -> baza la y=419
##   acelasi obiect la 14 m in fata                            -> baza la y=389
##   la 32 m                                                   -> baza la y=353
##
## Adica cel mai jos punct din cadru pe care il poate atinge ceva asezat pe sol
## LANGA sosea e y=419, cu 61 px DEASUPRA treimii de jos — si aia doar daca sta
## lipit de carosabil si la doar 8 m in fata. Nu conteaza cat de lateral e
## (coloana "lateral" nu misca deloc y-ul bazei: terenul e plat, iar y depinde
## doar de distanta si de inaltimea ochiului).
##
## Concluzia: treimea de jos a cadrului de la --driver E carosabilul de sub
## botul masinii, la 7-9 m. Nu se umple cu decor de margine, indiferent cat pui.
## Se umple doar cu ceva PE sosea (nu se face: e banda de curse) sau schimband
## cadrul. De-aia livrarea rundei asta e la fractia care compune mai bine, iar
## decorul nou se aduce cat se poate de jos si de aproape — imping continutul de
## la y~480 la y~420, ceea ce chiar se vede.
const MD := 7.5
const MH := 3.2
const MF := 68.0
const MLA := 14.0
const MLH := 1.2
const W := 1280
const H := 720

func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 5:
		await get_tree().process_frame
	var cam := Camera3D.new()
	cam.fov = MF
	cam.near = 0.05
	cam.far = 400.0
	add_child(cam)
	get_viewport().size = Vector2i(W, H)
	await get_tree().process_frame
	var r = t.routes[0]
	var pts: PackedVector3Array = r.baked
	var n: int = pts.size()
	var i := int(0.05 * float(n)) % n
	var p: Vector3 = pts[i]
	var a: Vector3 = pts[r.wrap_index(i + 12)]
	var dir: Vector3 = (a - p).normalized()
	var right := dir.cross(Vector3.UP).normalized()
	cam.global_position = p - dir * MD + Vector3.UP * MH
	cam.look_at(p + dir * MLA + Vector3.UP * MLH, Vector3.UP)
	await get_tree().process_frame
	print("treimea de jos incepe la y=%d" % int(H * 2.0 / 3.0))
	print("lateral  inainte  inaltime -> y_baza  y_varf")
	for off in [6.5, 8.0, 10.0, 13.0]:
		for ahead in [8.0, 14.0, 22.0, 32.0]:
			for hh in [2.0, 4.0]:
				var b: Vector3 = p + right * off + dir * ahead
				var sb := cam.unproject_position(b)
				var sv := cam.unproject_position(b + Vector3.UP * hh)
				print("  %4.1f m  %4.1f m   %3.1f m  ->  %4d    %4d" % [
					off, ahead, hh, int(sb.y), int(sv.y)])
	get_tree().quit()

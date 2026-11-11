class_name QuickRaceTracks
extends RefCounted
## Pistele pe care le vede jucatorul in QUICK RACE, in ordinea cartonaselor
## (issue #680, nov 2026).
##
## De ce o lista separata de `GameState.TRACK_SCENES`: TRACK_SCENES e si
## registrul uneltelor. Zeci de sonde si `verify_local.sh` o indexeaza cu
## literal (`--track=0` pe Dunele, `--track=16` pe Angkor, `TRACK_SCENES[14]`),
## iar `resolve_track_index` da castig indexului. Daca am fi scris Monument
## Valley si Okinawa peste indicii 0-1 si le-am fi scos de la 12-13, lista s-ar
## fi tasat si Ha Long / Carrara / Angkor ar fi coborat cu doua pozitii — orice
## comanda veche ar fi masurat TACUT alta pista (`--track=16` ar fi ajuns pe
## Fiordland, prin ramura "numar de scena"). Asa, registrul ramane neatins si
## jucatorul primeste lista asta.
##
## Ordinea: pe cupe. Intai pistele cupelor din `GameState.WORLD_CUPS`, cupa cu
## cupa, in ordinea curselor; apoi pistele care nu sunt (inca) in nicio cupa,
## in ordinea din registru. Cu 4 cupe x 4 la lansare, grila iese exact cupa
## dupa cupa, fara nicio editare aici.
##
## Ce NU apare: pistele cu `TrackInfo.test_bench` (Dunele, Okinawa manual) —
## raman in repo si in registru ca bancuri de test. O pista noua (San
## Francisco) apare singura, la coada, cand intra in TRACK_SCENES.


## Indicii din `GameState.TRACK_SCENES`, in ordinea cartonaselor.
static func indices() -> Array[int]:
	var out: Array[int] = []
	for res in GameState.WORLD_CUPS:
		var cup := res as WorldCup
		for race in cup.tracks.size():
			var index := cup.track_index(race)
			if is_playable(index) and not out.has(index):
				out.append(index)
	for index in GameState.TRACK_SCENES.size():
		if is_playable(index) and not out.has(index):
			out.append(index)
	return out


## True daca pista poate ajunge in fata jucatorului (exista si nu e banc de test).
static func is_playable(index: int) -> bool:
	if index < 0 or index >= GameState.TRACK_SCENES.size():
		return false
	return not TrackInfo.for_track(index).test_bench

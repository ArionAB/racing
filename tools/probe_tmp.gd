extends RefCounted
## Folderul temporar al unei sonde, PROPRIU procesului (#722).
##
## `user://` e acelasi folder pe disc pentru TOATE worktree-urile proiectului
## (acelasi nume de proiect), deci un nume fix — `user://probe_tmp/tutorial/` —
## e comun si tuturor rularilor paralele. Pe 11 nov 2026 doua `verify_local.sh`
## au rulat ProbeTutorial la o secunda distanta: una a sters fisierul celeilalte,
## iar a doua a picat 3 din 50 de verificari. Reprodus pe 15 nov: doua rulari
## pornite odata pica in 9 din 20 (ProbeTutorial), 20 din 20 (ProbeSaveMigration).
##
## Folosire (preload, nu class_name: merge si fara reimport, cu --no-import):
##   const ProbeTmp := preload("res://tools/probe_tmp.gd")
##   var dir := ProbeTmp.make("tutorial")   # user://probe_tmp/tutorial_<pid>/, gol
##   ...
##   ProbeTmp.remove(dir)                    # la final, si pe OK si pe PICA
## Pune `remove` si in `_exit_tree` al sondei: prinde si iesirile timpurii.
##
## O rulare omorata (timeout-ul din verify_local.sh) nu mai apuca sa stearga:
## folderul ei ramane, iar urmatorul `make` al ORICAREI sonde il sterge cand
## e mai vechi de `STALE_S`. Nu strica nimic nici pana atunci — un PID nou nu
## da peste el, iar un PID refolosit il gaseste golit de `make`.
## De ce dupa varsta si nu dupa PID: `OS.is_process_running` pe Windows stie
## doar de procesele pornite de procesul curent — pentru o sonda vie din alt
## worktree raspunde `false` (masurat 15 nov 2026), deci ar sterge folderul
## unei rulari in curs, adica exact bug-ul de aici.

const ROOT := "user://probe_tmp/"
## Marcatorul scris de `make`; varsta lui = varsta folderului.
const STAMP := ".probe_tmp_stamp"
## Peste orice sonda care foloseste folderul (verify_local.sh omoara un pas la
## 900 s); sub asta un folder strain nu se atinge.
const STALE_S := 6 * 3600


## Creeaza (gol) si intoarce `user://probe_tmp/<name>_<pid>/`.
static func make(name: String) -> String:
	sweep_stale()
	var dir := "%s%s_%d/" % [ROOT, name, OS.get_process_id()]
	# PID refolosit de la o rulare moarta: resturile ei nu intra in rularea asta.
	remove(dir)
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir + STAMP, FileAccess.WRITE)
	if f != null:
		f.store_string(str(OS.get_process_id()))
		f.close()
	return dir


## Sterge recursiv un folder facut de `make`. Refuza orice cale din afara
## `ROOT`: o greseala aici nu are voie sa ajunga la save-ul real din `user://`.
static func remove(dir: String) -> void:
	if not dir.begins_with(ROOT) or ".." in dir \
			or dir.trim_suffix("/") == ROOT.trim_suffix("/"):
		push_error("ProbeTmp.remove: refuz %s (nu e sub %s)" % [dir, ROOT])
		return
	if not dir.ends_with("/"):
		dir += "/"
	if not DirAccess.dir_exists_absolute(dir):
		return
	for sub in DirAccess.get_directories_at(dir):
		remove(dir + sub + "/")
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + f)
	DirAccess.remove_absolute(dir)


## Sterge folderele facute de `make` (cu marcator) mai vechi de `STALE_S`.
## Folderele fara marcator — sondele de dinainte de #722, cu nume fix, din
## worktree-uri vechi — raman neatinse: pot fi ale unei rulari in curs.
static func sweep_stale() -> void:
	if not DirAccess.dir_exists_absolute(ROOT):
		return
	var now := int(Time.get_unix_time_from_system())
	for sub in DirAccess.get_directories_at(ROOT):
		var stamp := ROOT + sub + "/" + STAMP
		if not FileAccess.file_exists(stamp):
			continue
		if now - int(FileAccess.get_modified_time(stamp)) > STALE_S:
			remove(ROOT + sub + "/")

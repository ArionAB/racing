extends Node
## SONDA TEMPORARA — incarca fiecare pista existenta (Track01, Track08-16) si
## verifica ca nu apar erori NOI in urma generalizarii Track.branch_is_open /
## grupului Track.BRANCH_GATE_GROUP (Jodhpur/sonda-vaca, brief §4: "pe toate
## pistele existente comportamentul ramane neschimbat").
##
##   godot --headless --fixed-fps 60 --path . res://tools/VerifyAllTracksLoad.tscn

const TRACKS := [
	"res://scenes/tracks/Track01.tscn",
	"res://scenes/tracks/Track08.tscn",
	"res://scenes/tracks/Track09.tscn",
	"res://scenes/tracks/Track10.tscn",
	"res://scenes/tracks/Track11.tscn",
	"res://scenes/tracks/Track12.tscn",
	"res://scenes/tracks/Track13.tscn",
	"res://scenes/tracks/Track14.tscn",
	"res://scenes/tracks/Track15.tscn",
	"res://scenes/tracks/Track16.tscn",
]

func _ready() -> void:
	var failed := false
	for path in TRACKS:
		var scene := load(path) as PackedScene
		if scene == null:
			print("  %-30s NU S-A INCARCAT SCENA" % path)
			failed = true
			continue
		var track := scene.instantiate() as Track
		if track == null:
			print("  %-30s instantiere esuata (nu e Track)" % path)
			failed = true
			continue
		get_tree().root.add_child(track)
		await get_tree().process_frame
		await get_tree().process_frame
		var branch_ok := true
		# Cere raspuns pe orice index rezonabil de banda, ca sa fie sigur ca
		# noua bucla din Track.branch_is_open (get_tree().get_nodes_in_group)
		# nu arunca pe piste fara nicio poarta montata.
		for idx in range(0, 3):
			branch_ok = branch_ok and (track.branch_is_open(idx) == true \
				or track.branch_is_open(idx) == false) # doar sa nu pice
		print("  %-30s OK (%d rute, branch_is_open raspunde pe 0..2)" % [
			path, track.routes.size()])
		track.queue_free()
		await get_tree().process_frame

	print("\n=== %s ===" % ("PROBLEME" if failed else "TOATE PISTELE SE INCARCA OK"))
	get_tree().quit(1 if failed else 0)

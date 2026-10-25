class_name CareerWorld
extends Resource
## O lume din cariera: un grup de piste pe raft. Gruparea e DATE — a muta o
## pista intre lumi sau a schimba pragul de deblocare = editezi un .tres, zero
## cod. Progresul NU sta aici: cheile din `career.cfg` sunt pe pista, deci o
## regrupare nu pierde nicio medalie.

@export var id: StringName = &""
## Placeholder pana la decizia de nume (brief, sectiunea 12).
@export var display_name: String = ""
## Id-uri de pista (`TrackInfo.id`), in ordinea de pe raft.
@export var tracks: Array[StringName] = []
## Lumea de inceput: mereu deschisa, indiferent de stampile.
@export var free: bool = false
## Pragul de puncte cumulate (toate lumile) la care cutia se deschide; 0 pe
## lumea free. Punctele: brief §3 (loc 3/2/1 + bonus provocare 1).
@export var points_to_unlock: int = 0
## Rivalul lumii si pista lui (pasul 3+). Goale in pasul 1, dar schema e
## completa ca sa nu rescriem resursele mai tarziu.
@export var rival: StringName = &""
@export var rival_track: StringName = &""

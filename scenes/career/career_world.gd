class_name CareerWorld
extends Resource
## O lume din carieră: un grup de piste pe raft. Gruparea e DATE — a muta o
## pistă între lumi sau a schimba pragul de deblocare = editezi un .tres, zero
## cod. Progresul NU stă aici: cheile din `career.cfg` sunt pe pistă, deci o
## regrupare nu pierde nicio medalie.

@export var id: StringName = &""
## Placeholder până la decizia de nume (brief §12).
@export var display_name: String = ""
## Id-uri de pistă (`TrackInfo.id`), în ordinea de pe raft.
@export var tracks: Array[StringName] = []
## Lumea de început: mereu deschisă, indiferent de ștampile.
@export var free: bool = false
@export var stamps_to_unlock: int = 0
## Rivalul lumii și pista lui (pasul 3+). Goale în pasul 1, dar schema e
## completă ca să nu rescriem resursele mai târziu.
@export var rival: StringName = &""
@export var rival_track: StringName = &""

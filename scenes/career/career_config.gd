class_name CareerConfig
extends Resource
## Rafturile carierei, in ordinea afisarii. Un singur fisier de date
## (`data/career_config.tres`) descrie toata structura.

@export var worlds: Array[CareerWorld] = []
## Provocarea gimmick-ului per pista (maxim una pe pista; vezi `Career.validate`).
## O pista fara intrare aici nu are provocare, iar foaia ei arata „SOON".
@export var challenges: Array[CareerChallenge] = []

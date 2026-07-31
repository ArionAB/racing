class_name TrackDecorSpec
extends RefCounted
## UN loc de asezat ceva langa drum, cu tot ce trebuie stiut despre el.
##
## Produs de [TrackSideSampler], consumat de [TrackCliffs] si [TrackDecor].
## Rostul lui e sa mute deciziile de siguranta (unde NU se pune nimic inalt,
## unde trebuie lasat gol pentru franare) intr-un singur loc: samplerul le
## calculeaza o data, consumatorii doar citesc steagurile. Altfel fiecare
## generator si-ar reface propria matematica de curbura si ar diverge.

## Punctul pe sol unde se aseaza obiectul.
var position: Vector3
## Versor orizontal dinspre drum spre exterior (perpendicular pe traseu).
var normal_out: Vector3
## Versor orizontal in sensul cursei.
var along: Vector3
## Indexul punctului copt al pistei cel mai apropiat.
var index: int
## Pozitia pe traseu, 0..1.
var frac: float
## Pe ce parte a drumului: -1 sau +1.
var side_sign: float
## Distanta fata de MARGINEA soselei (nu fata de axa).
var offset: float
## Slotul e in afara buclei de puncte de control (exteriorul circuitului).
var is_exterior: bool
## Soseaua e inaltata aici (y > 1.0) — pe interior asta cere perete.
var is_elevated: bool
## Curbura mare: nimic inalt, ca sa ramana lizibil apexul (style_bible §7).
var is_apex: bool
## Zona de franare inaintea unui viraj: se lasa liber (style_bible §7).
var is_braking: bool

"""avalanche_boulders.glb — bolovanii de zapada din care se face avalansa.

INLOCUIESTE masa unica din `avalanche.glb`, si motivul e o observatie de
gameplay, nu de estetica: un corp rigid de 7 m ARATA ca un corp rigid oricat de
bine il texturezi. O avalansa e material in miscare — bucati de marimi diferite
care se rostogolesc fiecare in ritmul ei. Referinta (Ignition) chiar asta
arata: mai multi bolovani care se dau peste cap, fiecare cu norul lui.

Fisierul vechi ramane pe disc si NU se suprascrie (regula "asset nou = fisier
nou" din contractul de assets): `avalanche.glb` e inca incarcat de o versiune
anterioara a hazardului, iar un GLB rescris sub picioarele Godot ar porni tacut
fallback-ul procedural.

CE CONTINE: patru FORME distincte de bolovan, ca noduri numite:
  Boulder_A .. Boulder_D

Patru, nu opt-zece: hazardul instantiaza 9 bucati din astea patru forme, cu
scari si rotatii diferite. La rostogolire nimeni nu recunoaste ca doi bolovani
impart silueta — ii deosebesc marimea, viteza si faza rotatiei. Patru forme x
un GLB de 20 KB e mult mai ieftin decat noua mesh-uri unice, si arata la fel.

TOATE PE SLOTUL FOAM_WHITE, cu UV pe centrul slotului: culoarea vine din
`Palette` la instantiere, iar detaliul din clasa triplanara `snow`
(`assets/textures/classes/snow.png`, in-dala 39.9). Un bolovan nu-si aduce
niciodata textura proprie.

ORIGINEA E IN CENTRU pe fiecare forma, ca la `boulder_roller.glb` si din
acelasi motiv: rostogolirea se face in jurul centrului. Cu originea la baza,
rotatia ar fi in jurul unui punct de pe sol si bolovanul ar sari.
Din cauza asta `verify_glb.py` raporteaza "baza nu e la Y=0" — asteptat, exact
ca la bolovanul din canion.

Buget: vezi TRI_BUDGET. Formele sunt mici pe ecran (0.8-2.6 m in joc), deci
rezolutia lor e mai mica decat a masei pe care o inlocuiesc.
"""

import math

# Diametrul la care se construieste fiecare forma. E doar unitatea de lucru:
# hazardul le scaleaza pe fiecare la marimea ei (vezi AvalancheHazard.BOULDERS),
# si `Track.model_aabb` masoara ce a iesit.
UNIT = 2.0

# Rezolutia unui bolovan. Mult sub cei 14x8 ai masei unice, si e o consecinta
# directa a schimbarii: masa acoperea jumatate de ecran, un bolovan de 1-2.6 m
# nu. La 9x5 fatetele cad sub un grad de arc de la distanta de franare.
#
# `boulder()` cu segments impar: cu numar par ies doua fatete perfect opuse si
# piesa citeste ca o moneda cand se roteste (nota din build_boulder_roller.py).
SEGMENTS = 9
RINGS = 5

## Plafon de alarma pentru TOT fisierul (patru forme). Larg, ca la masa: prinde
## clasa de accident (o primitiva lasata la rezolutia implicita sare cu mii
## dintr-un foc), nu strange munca legitima.
TRI_BUDGET = 2000

# Cele patru forme. (seed, deviatie, turtire pe Z).
#
# Deviatiile URCA de la A la D: A e aproape rotund (bolovanul care se
# rostogoleste curat), D e coltos (bucata proaspat rupta din versant). Amestecul
# lor e ce face gramada sa arate ca material spart, nu ca un set de mingi.
#
# Turtirea difera si ea, tot pentru varietate de silueta — dar ramane peste
# 0.72: sub atat piesa devine o lespede care se rostogoleste vizibil prost
# (se poticneste pe muchia lunga).
#
# Valorile de deviatie sunt PLAFONATE de garda de concavitate, nu alese liber.
# Prima incercare urca liniar 0.14 / 0.20 / 0.26 / 0.32 si a picat pe doua
# forme: B iesea la 0.114 concavitate si C la 0.147, cu pragul la 0.08. Peste
# ~0.20 deviatie, `boulder()` incepe sa produca scobituri reale intre inele —
# adica exact defectul de rostogolire pe care garda il cauta.
#
# Varietatea nu se pierde: ea vine acum din TURTIRE si din seed (silueta), nu
# din adancimea denivelarilor. Masurat dupa corectie, variatia de raza ramane
# 26-38%, deci nicio forma nu citeste ca sfera.
SHAPES = [
    ("Boulder_A", 41, 0.14, 0.92),
    ("Boulder_B", 907, 0.17, 0.84),
    ("Boulder_C", 233, 0.19, 0.78),
    ("Boulder_D", 611, 0.16, 0.88),
]


def max_concavity(obj):
    """Cea mai adanca scobitura, ca fractiune din raza. 0 = strict convex.

    Aceeasi garda ca la `boulder_roller.glb`, si aici redevine o GARDA REALA,
    nu o cifra informativa. Pe masa unica era normal sa fie mare (crevasele
    dintre lobi erau silueta); un bolovan singur insa TREBUIE sa ramana aproape
    convex, altfel se poticneste vizibil la rostogolire — exact defectul pe
    care brieful bolovanului il numea "fara concavitati".
    """
    me = obj.data
    verts = [v.co for v in me.vertices]
    radius = max(v.length for v in verts) or 1.0
    worst = 0.0
    for p in me.polygons:
        c, n = p.center, p.normal
        for v in verts:
            worst = max(worst, (v - c).dot(n))
    return worst / radius


def radius_variation(obj):
    """(min, max, variatie) a razei fata de origine, ca fractiune.

    Bolovanul din canion isi justifica deviatia cu "27% variatie de raza": sub
    atat piesa citeste ca sfera si rostogolirea devine plictisitoare.
    """
    lens = [v.co.length for v in obj.data.vertices]
    lo, hi = min(lens), max(lens)
    return lo, hi, (hi - lo) / hi


clear_built("Boulder_")

built = []
total_tris = 0

for name, seed, deviation, squash in SHAPES:
    b = Builder()
    b.boulder((0.0, 0.0, 0.0), (UNIT, UNIT * 0.96, UNIT * squash), FOAM_WHITE,
              seed=seed, segments=SEGMENTS, rings=RINGS, deviation=deviation)
    obj = b.to_object(name)

    # BEVEL ZERO, ca la bolovanul din canion si din acelasi motiv aritmetic:
    # multiplicatorul masurat al bevel-ului e ~3.7x, iar aici sunt patru piese.
    # Estetic nu pierdem — style_bible §3 accepta stanci fatetate, si zapada
    # inghetata proaspat rupta din versant e chiar cazul fatetat.
    stats = finish(
        obj,
        bevel=0.0,
        # AO SFERIC, obligatoriu pe orice piesa care se roteste: un gradient
        # vertical ar aseza umbra la baza, iar dupa o jumatate de rotatie ar
        # ajunge in varf. Distanta fata de centru e singurul gradient invariant
        # la rotatie (lectia din build_boulder_roller.py).
        #
        # `low` 0.70, mai sus decat cei 0.58 ai bolovanului de roca: zapada e
        # materialul cel mai deschis din paleta si un AO adanc o face sa citeasca
        # gri-murdar. Contrastul vine din textura, nu din ocluzie.
        ao=dict(samples=32, dist=1.4, gradient="spherical",
                low=0.70, high=1.00, power=0.9, floor=0.25),
        origin="center",
        origin_size=(UNIT, UNIT, UNIT * squash),
    )
    lo, hi, var = radius_variation(obj)
    conc = max_concavity(obj)
    total_tris += stats["tris"]
    flag = "  CONCAV!" if conc > 0.08 else ""
    print("%-10s %3d tris | AO %.2f..%.2f | variatie raza %4.1f%% | concavitate %.4f%s"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             var * 100.0, conc, flag))
    obj.location = (0.0, 0.0, 0.0)
    built.append(obj)

print("TOTAL %d tris (buget %d), %d forme" % (total_tris, TRI_BUDGET, len(built)))
if total_tris > TRI_BUDGET:
    print("  PESTE BUGET")

print("GLB:   %s (%d B)" % export_glb(built, "effects/avalanche_boulders.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "avalanche_boulders.blend"))

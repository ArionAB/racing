"""Kitul alpin — NATURA (planşa "Swiss Alps — Alpine Switchback").

  MountainPeak  rocks/mountain_peak.glb      100 x 80 x 80 m  <= 2000 (backdrop)
    + PeakSnow  (acelasi GLB, copil)      calota de zapada, alta clasa
  AlpineShrub   plants/alpine_shrub.glb      1.5 x 1.5 x 1.2  <= 600
  FlowerCluster flowers/flower_cluster.glb   1.5 x 1.5 x 0.6  <= 600
  SnowPatch     scatter/snow_patch.glb       5 x 5 x 0.2      <= 200

Muntele e fundal: sta la sute de metri, dincolo de ceata partiala, deci
silueta si cele trei benzi de culoare (padure - granit - zapada) sunt tot
mesajul. Fara bevel — la scara asta tesitura nu se vede, doar plateste
triunghiuri.

BENZILE, DIN AUGUST 2026, NU MAI SUNT SLOTURI DE ATLAS. Prima versiune le
picta in sloturi (CONCRETE/ASPHALT_EDGE ciclate pe inele, TROPICAL_GREEN la
poale, FOAM_WHITE peste linia zapezii) si tema lasa muntele pe atlas tocmai ca
sa nu i le stearga o textura de roca. Rezultatul, pe captura de sofer: benzi
de culoare UNIFORMA cu granita dura pe fete intregi, granit maro-portocaliu
saturat — muntii de carton, in timp ce stancile de langa drum aveau deja
textura de clasa `alpine_granite`. Doua lumi.

Acum muntele e DOUA obiecte in acelasi GLB, ca sa primeasca doua clase:
  MountainPeak  corpul de roca (copilul de mai jos e atasat de el)
    PeakSnow    fetele de peste linia zapezii, DESPRINSE din acelasi mesh
In joc (Track._build_horizon, `horizon_classes`): MountainPeak -> tri:alpine_granite,
PeakSnow -> tri:snow — aceleasi clase ca stancile si masa de avalansa de langa
drum, deci fundalul si prim-planul sunt din aceeasi piatra. Zapada e obiect
separat fiindca vertex color-ul doar INTUNECA (SurfaceTool taie la [0,1]): nu
poti "albi" granitul din vertecsi, dar poti da alta clasa altui nod.

Padurea de la poale NU e obiect separat: e o TENTA verde in vertex color peste
granit (inmultire, deci merge — spre inchis), cu granita moale si zgomotoasa
pe cota, nu pe fete. La 200-350 m si prin ceata, o banda verde-inchis pe
piatra deschisa citeste "padure sub linia golului", si costa zero noduri.

Linia zapezii are ZGOMOT pe fata (±ZIGZAG m): o cota unica da o dunga trasa cu
rigla, iar zapada reala coboara pe vaiugi si se retrage de pe muchii.
"""

import math

SNOW_ZIGZAG = 7.0

# ============================================================ MountainPeak
# Doua varfuri (principal + umar), ca silueta sa nu fie un con simetric.
# Benzile: sub ~12 m padure, mijloc granit, peste linia zapezii alb. Linia
# de zapada nu e dreapta — urmeaza fetele, pentru ca retag lucreaza pe fete
# intregi si treapta rezultata citeste ca limba de zapada, nu ca greseala.

SNOW_LINE = 38.0
TREE_LINE = 14.0


def build_peak():
    b = Builder()
    # Un singur slot (CONCRETE): sub triplanar UV-ul nu mai inseamna culoare,
    # iar CONCRETE e ancora clasei `alpine_granite` — daca vreodata muntele
    # cade inapoi pe atlas, iese in aceeasi familie, nu portocaliu.
    b.rock((0.0, 0.0, 0.0), (92.0, 74.0, 80.0), CONCRETE, seed=41,
           segments=9, rings=6, taper=0.88, squash=0.94)
    b.rock((30.0, -14.0, 0.0), (48.0, 42.0, 52.0), CONCRETE, seed=57,
           segments=8, rings=5, taper=0.82, squash=0.9)
    b.rock((-32.0, 10.0, 0.0), (34.0, 30.0, 34.0), CONCRETE, seed=69,
           segments=7, rings=4, taper=0.78, squash=0.9)
    return b


def _hash01(x, y, seed=0):
    """Zgomot determinist 0..1 din pozitie — acelasi munte la fiecare build."""
    h = math.sin(x * 12.9898 + y * 78.233 + seed * 37.719) * 43758.5453
    return h - math.floor(h)


def split_snow(obj):
    """Desprinde fetele de peste linia zapezii intr-un obiect copil `PeakSnow`.

    Se face DUPA finish(): AO-ul e copt pe muntele intreg (umbra din vai trece
    prin linia zapezii), iar bevel-ul nu exista aici oricum. Culorile de vertex
    (atributul AO, pe puncte) supravietuiesc stergerii de fete in bmesh.
    """
    me = obj.data
    # Intai TAIEM mesh-ul pe cota zapezii: fetele muntelui au 10-13 m pe
    # verticala, iar o granita pe fete intregi urca si coboara in trepte de
    # un inel — dunga trasa cu rigla, doar mai stramba. Bisectia pune o bucla
    # de vertecsi noi exact pe linie; pe ea se aplica zgomotul (in jos si in
    # sus cu SNOW_ZIGZAG), deci limbile de zapada sunt in GEOMETRIE, si
    # amandoua obiectele (roca/zapada) le impart, fara crapaturi.
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
                           plane_co=(0.0, 0.0, SNOW_LINE), plane_no=(0.0, 0.0, 1.0),
                           dist=1e-4)
    # Apartenenta se decide INAINTE de zgomot, cand fiecare fata e complet
    # sub sau complet peste plan; dupa zimtare, o fata ingusta de langa linie
    # ar putea sa-si mute centrul de partea cealalta si sa apara o pata de
    # granit in zapada.
    tag = bm.faces.layers.int.new("snow")
    for f in bm.faces:
        f[tag] = 1 if f.calc_center_median().z > SNOW_LINE else 0
    for v in bm.verts:
        if abs(v.co.z - SNOW_LINE) < 1e-3:
            v.co.z += (_hash01(v.co.x * 0.13, v.co.y * 0.13, 3) - 0.5) * 2.0 * SNOW_ZIGZAG
    bm.to_mesh(me)
    bm.free()

    bm_rock = bmesh.new()
    bm_rock.from_mesh(me)
    bm_snow = bmesh.new()
    bm_snow.from_mesh(me)
    tr = bm_rock.faces.layers.int["snow"]
    ts = bm_snow.faces.layers.int["snow"]
    bmesh.ops.delete(bm_rock, geom=[f for f in bm_rock.faces if f[tr] == 1],
                     context="FACES")
    bmesh.ops.delete(bm_snow, geom=[f for f in bm_snow.faces if f[ts] == 0],
                     context="FACES")
    bm_rock.to_mesh(me)
    bm_rock.free()
    snow_me = bpy.data.meshes.new(obj.name.replace("MountainPeak", "PeakSnow"))
    bm_snow.to_mesh(snow_me)
    bm_snow.free()
    for m_ in (me, snow_me):   # atributul de lucru nu are ce cauta in GLB
        if "snow" in m_.attributes:
            m_.attributes.remove(m_.attributes["snow"])
    for m in me.materials:
        snow_me.materials.append(m)
    snow = bpy.data.objects.new(snow_me.name, snow_me)
    bpy.context.collection.objects.link(snow)
    snow.parent = obj
    snow.matrix_parent_inverse = snow.matrix_parent_inverse.Identity(4)
    return snow


TREE_BAND = 6.0


def tint_forest(obj):
    """Tenta de padure la poale, in vertex color, peste AO: verde-inchis sub
    TREE_LINE, granit curat peste, cu o banda de tranzitie de ±TREE_BAND m si
    zgomot pe cota ca liziera sa nu fie o linie.

    Intai doua bisectii, la marginile benzii. Fara ele, tenta se interpoleaza
    Gouraud intre inelele muntelui (la 13 m distanta): pe captura, verdele
    urca pana aproape de zapada, iar granitul curat disparea — vazut pe varful
    din inelul apropiat, unde ocupa jumatate de ecran. Cu buclele de vertecsi
    puse exact la marginile benzii, sub e padure, peste e piatra, si tranzitia
    e cat am spus ca e."""
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    for z in (TREE_LINE - TREE_BAND, TREE_LINE + TREE_BAND):
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
                               plane_co=(0.0, 0.0, z), plane_no=(0.0, 0.0, 1.0),
                               dist=1e-4)
    bm.to_mesh(me)
    bm.free()
    ca = me.color_attributes.get("AO")
    if ca is None:
        return
    forest = (0.44, 0.62, 0.34)
    for v in me.vertices:
        jitter = (_hash01(v.co.x * 0.21, v.co.y * 0.21, 5) - 0.5) * 8.0
        t = (v.co.z - (TREE_LINE + jitter) + TREE_BAND) / (2.0 * TREE_BAND)
        t = max(0.0, min(1.0, t))
        t = t * t * (3.0 - 2.0 * t)   # smoothstep
        col = ca.data[v.index].color
        ca.data[v.index].color = (
            col[0] * (forest[0] + (1.0 - forest[0]) * t),
            col[1] * (forest[1] + (1.0 - forest[1]) * t),
            col[2] * (forest[2] + (1.0 - forest[2]) * t),
            1.0)


# ============================================================= AlpineShrub
# Trei mase rotunjite intrepatrunse — jneapanul de altitudine e o perna, nu
# un copac. Gradientul de nuanta (baza umbrita) vine din tint_gradient, DUPA
# finish (bake_ao sterge atributele de culoare — ordinea e o constrangere).

def build_shrub():
    b = Builder()
    b.boulder((0.0, 0.05, 0.5), (1.25, 1.1, 0.95), TROPICAL_GREEN, seed=13,
              segments=7, rings=3, deviation=0.15)
    b.boulder((-0.4, -0.25, 0.38), (0.8, 0.75, 0.7), TROPICAL_GREEN, seed=27,
              segments=6, rings=3, deviation=0.17)
    b.boulder((0.42, -0.3, 0.35), (0.7, 0.65, 0.62), TROPICAL_GREEN, seed=35,
              segments=6, rings=3, deviation=0.17)
    return b


# =========================================================== FlowerCluster
# Smoc de pajiste inflorita: frunze pliate in V radial + cateva flori albe pe
# tulpini — silueta de "floare" vine din capul alb pe bat, nu din petale
# (la 1.5 m diametru, petalele ar fi zgomot de frecventa inalta).

def build_flowers():
    b = Builder()
    for i, (azim, length) in enumerate(((15.0, 0.55), (72.0, 0.48),
                                        (131.0, 0.58), (198.0, 0.5),
                                        (256.0, 0.56), (310.0, 0.46))):
        leaf_vfold(b, (0.0, 0.0, 0.02), azim, length, 0.16, 0.22,
                   CACTUS_GREEN, fold_deg=26.0, stations=4, droop=0.5)
    for (x, y, h, s, seed) in ((0.1, 0.12, 0.5, 0.11, 3),
                               (-0.28, -0.1, 0.42, 0.1, 7),
                               (0.3, -0.24, 0.38, 0.09, 11),
                               (-0.05, 0.32, 0.34, 0.09, 15),
                               (0.42, 0.18, 0.3, 0.08, 19)):
        b.frustum((x, y, h * 0.5), 0.016, 0.01, h, CACTUS_GREEN, segments=4)
        b.boulder((x, y, h + s * 0.4), (s * 1.5, s * 1.5, s), FOAM_WHITE,
                  seed=seed, segments=5, rings=2, deviation=0.1)
    return b


# =============================================================== SnowPatch
# Pata de zapada ramasa in umbra: clatita neregulata, joasa, cu marginea
# tesita de bevel. AO aproape plat — zapada nu are ce sa se auto-umbreasca.

def build_snow_patch():
    b = Builder()
    b.rock((0.0, 0.0, 0.0), (5.0, 4.6, 0.26), FOAM_WHITE, seed=8,
           segments=11, rings=1, taper=0.55, squash=0.9, flat_top=True)
    b.rock((1.4, 1.2, 0.0), (2.2, 1.9, 0.2), FOAM_WHITE, seed=16,
           segments=7, rings=1, taper=0.5, squash=0.9, flat_top=True)
    return b


# ------------------------------------------------------------------ build
ASSETS = [
    ("MountainPeak", build_peak, "rocks/mountain_peak.glb", 2000, 0.0,
     dict(samples=24, dist=30.0, gradient="vertical", low=0.55, high=1.0,
          power=0.8, floor=0.2), 60.0),
    ("AlpineShrub", build_shrub, "plants/alpine_shrub.glb", 600, 0.0,
     dict(samples=20, dist=1.2, gradient="vertical", low=0.5, high=1.0,
          power=0.9, floor=0.2), 60.0),
    ("FlowerCluster", build_flowers, "flowers/flower_cluster.glb", 600, 0.0,
     dict(samples=16, dist=0.7, gradient="vertical", low=0.55, high=1.0,
          power=1.0, floor=0.3), 60.0),
    ("SnowPatch", build_snow_patch, "scatter/snow_patch.glb", 200, 0.05,
     dict(samples=14, dist=0.8, gradient="vertical", low=0.85, high=1.0,
          power=1.0, floor=0.55), 55.0),
]

built = []
for name, make, glb, budget, bevel, ao, smooth in ASSETS:
    clear_built(name)
    b = make()
    obj = b.to_object(name)
    stats = finish(obj, bevel=bevel, bevel_angle=40.0, ao=ao,
                   smooth_angle=smooth)
    if name == "AlpineShrub":
        # baza spre umbra rece, varfurile aproape de culoarea slotului
        tint_gradient(obj, base=(0.55, 0.62, 0.55), tip=(1.05, 1.0, 0.88))
    extra = []
    if name == "MountainPeak":
        clear_built("PeakSnow")
        tint_forest(obj)
        extra.append(split_snow(obj))
    me = obj.data
    dims = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices)
            for i in range(3)]
    print("%-14s %5d tris (buget %d) %s | %.1f x %.1f x %.1f m | AO %.2f..%.2f"
          % (name, stats["tris"], budget,
             "OK" if stats["tris"] <= budget else "DEPASIT",
             dims[0], dims[1], dims[2], stats["ao_min"], stats["ao_max"]))
    print("GLB:   %s (%d B)" % export_glb([obj] + extra, glb))
    built.append(obj)
    built.extend(extra)

print("BLEND: %s (%d B)" % save_blend(built, "alpine_nature.blend"))

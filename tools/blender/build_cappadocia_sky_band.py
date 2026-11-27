"""Banda de orizont a cerului Cappadocia (Track13) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/cappadocia_horizon_band.png`, o felie
equirectangulara de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15),
cu alfa: platourile de tuf vulcanic cu marginea taiata in faleze cu dungi pastel
(crem, roz, ocru) si calota tare, cenusie; vaile dintre ele cu „cosuri de zana”
(hornuri conice cu palarie de bazalt), plopi si vii; Uchisar, cetatea-stanca
gaurita ca un fagure, cu satul pe poale; si departe, spre est, conul vulcanului
Erciyes cu zapada pe varf. Plus planul 0 (`NEAR_GIANTS`): margini de platou MARI si
APROPIATE (0,55-0,85 km), puse de mana pe directiile camerei de joc, care dau
SCARA. Cerul ramane TRANSPARENT: gradientul lui il deseneaza shaderul de cer din
joc (`scenes/tracks/sky_band.gdshader`).

Reteta e cea de pe Monument Valley (`build_monument_sky_band.py`, prima pista de
USCAT). Ce e specific aici:

  * IMBINAREA. Terenul jocului (tuf crem, CORAL_SAND, cu benzile rosii ale vaii
    pe cote) intra in ceata spre fog_end 300 m; dincolo de FAR_PLANE (380 m) e
    banda. Podeaua benzii e acelasi tuf, luminat de ACELASI soare si ambient,
    apoi spalat de un AER RECE (`AIR`, = `fog` al temei) — perspectiva aeriana a
    pistei e rece si palida (memoria ceata-in-familia-solului: patru critici orbi
    au cerut-o), deci si cea a benzii. La marginea de jos podeaua iese #BFA89C
    in textura (mediana randului de jos), si `fog` = `below` din tema = exact
    aceasta culoare: terenul cetos intra in podeaua pictata fara dunga
    (masurat pe captura: acelasi ton deasupra si dedesubtul taieturii).
  * DUNGILE sunt ale jocului: benzi late rosu / crem / roz pe cote (vezi
    `land_material`), ca falezele 3D si benzile `custom_strata_bands` ale
    terenului; NU dungi fine (pe versantii brazdati citeau curbe de nivel).
  * DOUA AERURI. Aproape (0,4-2 km) aerul e cel rece al jocului; departe
    (> 2 km) totul se topeste in HAZE = `sky_horizon` (C08752, portocaliul
    zorilor), ca marginea de sus a benzii sa intre in cerul desenat de joc.
  * Fara baloane in banda: pista are deja baloane 3D (cosurile care urca, cel
    aterizat, `balloon_far` in vale) — doua seturi s-ar contrazice ca scara.
  * Fara Uchisar in spatele stancii goale reale (POI G) si fara Erciyes 3D: cele
    sase copii de Erciyes din `horizon_rings` au fost scoase (fantome in fata
    benzii, si sase vulcani mint despre loc). Muntele e unul, in banda.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste fundul vaii, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din Track13.tscn (`custom_sun_rotation_deg` (-22, 25, 0): busola 155,
    SSE, 22 de grade), `sun_color` (1.0, 0.82, 0.63), energia 1,70; ambientul
    F0C79A la 0,20 (tema "cappadocia");
  * HAZE = `sky_horizon` din tema (C08752); AIR = `fog` din tema;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_cappadocia_sky_band.py [-- --test]
    rmdir D:/GameDev/.render_lock
"""

import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector, noise

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEST = "--test" in ARGS

W, H = (1024, 64) if TEST else (8192, 512)
LAT_MIN, LAT_MAX = -7.5, 15.0            # grade; (LAT_MAX - LAT_MIN) / 360 = H / W
# Ochiul peste fundul vaii. Masurat pe Track13.baked (sonda temporara): de pe
# platou (drumul la 48-50 m, camera la ~60) terenul jocului de la 250-340 m e la
# -35 m fata de camera, adica valea din jur sta la ~25 m absolut. Deci podeaua
# benzii = cota 25 a jocului, si camera benzii la 35 m peste ea: taietura
# terenului la FAR_PLANE (380 m) cade la -5,3 grade, exact unde incepe podeaua
# pictata vazuta de pe platou (de unde se vede cel mai mult din banda).
CAM_Z = 35.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "cappadocia_horizon_band_test.png" if TEST
                   else "cappadocia_horizon_band.png")


def srgb(hexstr, k=1.0):
    """Culoare sRGB hex -> liniar (intrarile de culoare din noduri sunt liniare)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        c = c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        out.append(c * k)
    return (out[0], out[1], out[2], 1.0)


# --- Paleta (sRGB) --------------------------------------------------------------
HAZE = "C08752"          # = sky_horizon din tema: departarea intra in cer
AIR = "B8BDCC"           # = fog din tema (0.72, 0.74, 0.80): aerul rece de aproape
# Podeaua: ALBEDO-ul tufului din joc (CORAL_SAND cu tenta de teren), nu culoarea
# lui pe ecran: lumina o pune soarele de mai jos, acelasi ca in joc.
FLOOR_ALBEDO = "D9C9A8"
FLOOR_DARK = "BFA886"    # praf mai inchis, aratura
FLOOR_LIGHT = "E6DAC0"   # albii palide
FIELD = ["8C8C5A", "7E8452", "9A9361", "6F7A4C"]   # vii si livezi, uscate de vara
POPLAR = "4F6B3C"        # plopii din vai (TROPICAL_GREEN, umbriti)
# Tuful: dungile Vaii Trandafirilor si ale Vaii Rosii, pe aceleasi culori ca
# hornurile si falezele 3D. ALBEDO, nu culoare pe ecran: tuful hornurilor din joc
# iese (202, 166, 133) dupa `_warm_tuff` (world_prop.gd), nu CORAL_SAND pur — cu
# E9DCC0 sub soarele de 1,70 al temei peretii benzii se ardeau spre alb (prima
# captura: platouri ca niste nori, mai deschise decat orice hornul 3D).
TUFF_CREAM = "CAA685"    # = tuful hornurilor din joc
TUFF_WHITE = "D8C2A2"
TUFF_PINK = "C99A88"     # roz prafuit (Gulludere)
TUFF_ROSE = "B57D6B"     # roz-rosu (red_valley_tuff)
TUFF_OCHRE = "C39963"    # ocru
TUFF_RED = "A86839"      # banda rosie a vaii (strata_band_tints[0])
CAPROCK = "8F8276"       # ignimbritul tare de sus, cenusiu-maro
CAPROCK_DARK = "6E6259"
PLATEAU_TOP = "C9B68E"   # stepa uscata de pe platou
BASALT = "5E5862"        # palaria hornurilor (VOLCANIC_BLACK 20)
HOUSE = "EDE3CF"         # casele din Uchisar, tuf + var
HOLE = "3A2E2A"          # gurile din stanca (porumbare, locuinte)
SNOW = "F4F1EC"
VOLCANO = "877C80"       # andezitul lui Erciyes (MARBLE_GREY tras spre violet)
SUN_COLOR = "FFD1A1"     # Color(1.0, 0.82, 0.63)
# Godot inmulteste energia luminii cu pi; Cycles nu. Taria Cycles = pi x energia.
SUN_STRENGTH = math.pi * 1.70
AMBIENT = "F0C79A"
AMBIENT_ENERGY = 0.20
SUN_ROT = (-22.0, 25.0)                   # custom_sun_rotation_deg (x, y) din Track13

# Aerul rece (AIR), de la fog_end-ul jocului incolo:
#   fac = AIR_F0 + (AIR_MAX - AIR_F0) * (1 - exp(-(d - d0) / D)).
# AIR_F0 0,45, nu 0,30: cu 0,30 podeaua (deci si `fog`) iesea (228, 196, 165) pe
# ecran — un piersica in familia tufului, adica exact ceata calda pe care
# criticii orbi o scosesera (memoria ceata-in-familia-solului).
AIR_D0, AIR_D, AIR_F0, AIR_MAX = 300.0, 900.0, 0.45, 0.60
# Departarea (HAZE): de la HAZE_D0 incolo, spre cerul zorilor.
HAZE_D0, HAZE_D, HAZE_MAX = 1500.0, 9000.0, 0.92


# --- Scena ---------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def _math(n, L, op, a=None, b=None, va=None, vb=None):
    m = n.new("ShaderNodeMath")
    m.operation = op
    if a is not None:
        L.new(a, m.inputs[0])
    elif va is not None:
        m.inputs[0].default_value = va
    if b is not None:
        L.new(b, m.inputs[1])
    elif vb is not None:
        m.inputs[1].default_value = vb
    return m.outputs[0]


def haze_wrap(nt, surface_socket, out_node, k=1.0, k_far=1.0):
    """surface -> AIR (rece, aproape) -> HAZE (zorii, departe), dupa distanta.
    `k` < 1 slabeste aerul rece (uriasii apropiati: altfel ies spalati)."""
    n, L = nt.nodes, nt.links
    cam = n.new("ShaderNodeCameraData")
    d = cam.outputs["View Distance"]
    # aerul rece
    x = _math(n, L, "SUBTRACT", d, vb=AIR_D0)
    x = _math(n, L, "MAXIMUM", x, vb=0.0)
    x = _math(n, L, "MULTIPLY", x, vb=-1.0 / AIR_D)
    x = _math(n, L, "EXPONENT", x)
    air = _math(n, L, "SUBTRACT", va=1.0, b=x)
    air = _math(n, L, "MULTIPLY", air, vb=AIR_MAX - AIR_F0)
    air = _math(n, L, "ADD", air, vb=AIR_F0)
    air = _math(n, L, "MULTIPLY", air, vb=k)
    # departarea
    y = _math(n, L, "SUBTRACT", d, vb=HAZE_D0)
    y = _math(n, L, "MAXIMUM", y, vb=0.0)
    y = _math(n, L, "MULTIPLY", y, vb=-1.0 / HAZE_D)
    y = _math(n, L, "EXPONENT", y)
    far = _math(n, L, "SUBTRACT", va=1.0, b=y)
    far = _math(n, L, "MULTIPLY", far, vb=HAZE_MAX * k_far)
    em_air = n.new("ShaderNodeEmission")
    em_air.inputs["Color"].default_value = srgb(AIR)
    em_far = n.new("ShaderNodeEmission")
    em_far.inputs["Color"].default_value = srgb(HAZE)
    m1 = n.new("ShaderNodeMixShader")
    L.new(air, m1.inputs[0])
    L.new(surface_socket, m1.inputs[1])
    L.new(em_air.outputs[0], m1.inputs[2])
    m2 = n.new("ShaderNodeMixShader")
    L.new(far, m2.inputs[0])
    L.new(m1.outputs[0], m2.inputs[1])
    L.new(em_far.outputs[0], m2.inputs[2])
    L.new(m2.outputs[0], out_node.inputs["Surface"])


def new_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    return mat, nt, out


def ramp(n, stops, interp="LINEAR"):
    cr = n.new("ShaderNodeValToRGB")
    cr.color_ramp.interpolation = interp
    els = cr.color_ramp.elements
    els[0].position, els[0].color = stops[0][0], srgb(stops[0][1])
    els[1].position, els[1].color = stops[-1][0], srgb(stops[-1][1])
    for pos, col in stops[1:-1]:
        e = els.new(pos)
        e.color = srgb(col)
    return cr


def mixc(n, L, fac, a, b):
    """amestec RGBA; a/b sunt socket-uri sau culori hex."""
    m = n.new("ShaderNodeMix")
    m.data_type = "RGBA"
    if isinstance(fac, float):
        m.inputs[0].default_value = fac
    else:
        L.new(fac, m.inputs[0])
    for idx, v in ((6, a), (7, b)):
        if isinstance(v, str):
            m.inputs[idx].default_value = srgb(v)
        else:
            L.new(v, m.inputs[idx])
    return m.outputs[2]


def land_material(name="BandTuff", k=1.0, strata_scale=0.025, k_far=1.0):
    """Un singur material pentru tot relieful, cu culoarea de baza in atributul
    `Col` (pe varfuri) si doua mecanisme procedurale aprinse din atribute:

      * `strata` (0..1): dungile pastel ale tufului — benzi ORIZONTALE pe Z de
        lume, distorsionate, ca straturile de cenusa ale vaii; plus santurile
        VERTICALE de siroire (tuful se erodeaza cu apa, in jos — aceeasi regula
        ca `detail_tuff.png` din joc: caneluri, nu linii de nivel);
      * `holes` (0..1): gurile sapate in stanca (Uchisar, porumbarele), un
        Voronoi intunecat pe fete.
    """
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    col = n.new("ShaderNodeAttribute")
    col.attribute_type = "GEOMETRY"
    col.attribute_name = "Col"
    st = n.new("ShaderNodeAttribute")
    st.attribute_type = "GEOMETRY"
    st.attribute_name = "strata"
    ho = n.new("ShaderNodeAttribute")
    ho.attribute_type = "GEOMETRY"
    ho.attribute_name = "holes"
    # dungile
    wave = n.new("ShaderNodeTexWave")
    wave.wave_type = "BANDS"
    wave.bands_direction = "Z"
    wave.inputs["Scale"].default_value = strata_scale
    wave.inputs["Distortion"].default_value = 0.8
    wave.inputs["Detail"].default_value = 1.0
    wave.inputs["Detail Scale"].default_value = 0.5
    L.new(tc.outputs["Object"], wave.inputs["Vector"])
    # ZONE LATE pe cota (roz jos, crem-alb la mijloc, ocru sub calota) si peste
    # ele dungi FINE cu contrast mic. Prima randare avea numai dungi dese si
    # tari: pe versantii brazdati citeau curbe de nivel („topographic map”,
    # exact reprosul criticilor orbi pe hornurile 3D).
    #
    # Benzile late sunt ALE JOCULUI: terenul Track13 are benzi rosii pe cote
    # (`custom_strata_bands` 11-23, 31-44, 52-62 m), iar fundul vaii din banda
    # (z = 0) e cota 25 a jocului, deci 31-44 -> z 6-19 si 52-62 -> z 27-37.
    # Peste ele, aceeasi alternanta crem / rosu-ocru / roz, pe trepte nete
    # (interpolare CONSTANTA, muchia zdrentuita de un zgomot pe z), ca falezele
    # in benzi ale kitului (cliff_band_module) — nu un gradient pastel.
    sz = n.new("ShaderNodeSeparateXYZ")
    L.new(tc.outputs["Object"], sz.inputs[0])
    jit = n.new("ShaderNodeTexNoise")
    jit.inputs["Scale"].default_value = 0.02
    jit.inputs["Detail"].default_value = 3.0
    L.new(tc.outputs["Object"], jit.inputs["Vector"])
    jz = _math(n, L, "SUBTRACT", jit.outputs["Fac"], vb=0.5)
    jz = _math(n, L, "MULTIPLY", jz, vb=7.0)
    zz = _math(n, L, "ADD", sz.outputs[2], jz)
    zn = _math(n, L, "MULTIPLY", zz, vb=1.0 / 120.0)
    zones = ramp(n, [(0.0, TUFF_CREAM), (0.05, TUFF_RED), (0.16, TUFF_CREAM),
                     (0.225, TUFF_ROSE), (0.31, TUFF_WHITE), (0.40, TUFF_OCHRE),
                     (0.47, TUFF_CREAM), (0.55, TUFF_PINK), (0.63, TUFF_WHITE),
                     (0.72, TUFF_RED), (0.78, TUFF_CREAM), (0.86, TUFF_ROSE),
                     (0.92, TUFF_WHITE)], interp="CONSTANT")
    L.new(zn, zones.inputs["Fac"])
    fine = ramp(n, [(0.0, "8A8A8A"), (0.5, "FFFFFF"), (1.0, "B8B8B8")])
    L.new(wave.outputs["Fac"], fine.inputs["Fac"])
    stripes_m = n.new("ShaderNodeMix")
    stripes_m.data_type = "RGBA"
    stripes_m.blend_type = "MULTIPLY"
    stripes_m.inputs[0].default_value = 0.08
    L.new(zones.outputs["Color"], stripes_m.inputs[6])
    L.new(fine.outputs["Color"], stripes_m.inputs[7])
    stripes = stripes_m.outputs[2]
    # o a doua frecventa, ca benzile sa nu fie un tipar periodic
    nz0 = n.new("ShaderNodeTexNoise")
    nz0.inputs["Scale"].default_value = 0.004
    nz0.inputs["Detail"].default_value = 2.0
    L.new(tc.outputs["Object"], nz0.inputs["Vector"])
    vary = n.new("ShaderNodeMapRange")
    vary.inputs["From Min"].default_value = 0.45
    vary.inputs["From Max"].default_value = 0.65
    vary.inputs["To Max"].default_value = 0.2
    L.new(nz0.outputs["Fac"], vary.inputs["Value"])
    tuff = mixc(n, L, vary.outputs["Result"], stripes, TUFF_RED)
    tuff = mixc(n, L, 0.15, tuff, col.outputs["Color"])
    # santurile verticale: zgomot alungit pe Z, inchide culoarea
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.35, 0.35, 0.015)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 3.0
    nz.inputs["Detail"].default_value = 3.0
    L.new(mp.outputs[0], nz.inputs["Vector"])
    gr = n.new("ShaderNodeMapRange")
    gr.inputs["From Min"].default_value = 0.35
    gr.inputs["From Max"].default_value = 0.65
    gr.inputs["To Min"].default_value = 0.82
    gr.inputs["To Max"].default_value = 1.0
    L.new(nz.outputs["Fac"], gr.inputs["Value"])
    groove = n.new("ShaderNodeMix")
    groove.data_type = "RGBA"
    groove.blend_type = "MULTIPLY"
    groove.inputs[0].default_value = 1.0
    L.new(tuff, groove.inputs[6])
    cg = n.new("ShaderNodeCombineColor")
    for i in range(3):
        L.new(gr.outputs["Result"], cg.inputs[i])
    L.new(cg.outputs[0], groove.inputs[7])
    base = mixc(n, L, st.outputs["Fac"], col.outputs["Color"], groove.outputs[2])
    # gurile
    vo = n.new("ShaderNodeTexVoronoi")
    vo.feature = "F1"
    vo.inputs["Scale"].default_value = 0.08
    vo.inputs["Randomness"].default_value = 0.8
    L.new(tc.outputs["Object"], vo.inputs["Vector"])
    hm = n.new("ShaderNodeMapRange")
    hm.inputs["From Min"].default_value = 0.16
    hm.inputs["From Max"].default_value = 0.11
    L.new(vo.outputs["Distance"], hm.inputs["Value"])
    hf = _math(n, L, "MULTIPLY", hm.outputs["Result"], ho.outputs["Fac"])
    base = mixc(n, L, hf, base, HOLE)
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(base, bsdf.inputs["Color"])
    haze_wrap(nt, bsdf.outputs[0], out, k, k_far)
    return mat


def floor_material():
    """Fundul vaii: albedo-ul tufului din joc, luminat de acelasi soare; petice de
    praf mai inchis si albii palide, alungite pe X ca sa citeasca orizontal la
    unghiuri razante."""
    mat, nt, out = new_material("BandFloor")
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0 / 110.0, 1.0 / 110.0, 1.0)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 1.0
    nz.inputs["Detail"].default_value = 5.0
    nz.inputs["Roughness"].default_value = 0.6
    L.new(mp.outputs[0], nz.inputs["Vector"])
    cr = ramp(n, [(0.30, FLOOR_DARK), (0.47, FLOOR_ALBEDO), (0.56, FLOOR_ALBEDO),
                  (0.72, FLOOR_LIGHT)])
    L.new(nz.outputs["Fac"], cr.inputs["Fac"])
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(cr.outputs["Color"], bsdf.inputs["Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


# --- Geometrie -------------------------------------------------------------------

class Mesh:
    """bmesh cu atributele materialului pe varfuri: Col (culoare), strata, holes."""

    def __init__(self):
        self.bm = bmesh.new()
        self.col = self.bm.verts.layers.float_color.new("Col")
        self.st = self.bm.verts.layers.float.new("strata")
        self.ho = self.bm.verts.layers.float.new("holes")

    def v(self, co, col, strata=0.0, holes=0.0):
        vv = self.bm.verts.new(co)
        vv[self.col] = srgb(col) if isinstance(col, str) else col
        vv[self.st] = strata
        vv[self.ho] = holes
        return vv

    def finish(self, name, mat):
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        for poly in me.polygons:
            poly.use_smooth = False
        ob = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(ob)
        ob.data.materials.append(mat)
        print("banda: %s, %d fete" % (name, len(me.polygons)))
        return ob


def smooth01(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def superellipse_r(a, rx, ry, p=4.0):
    c, s = abs(math.cos(a)) / rx, abs(math.sin(a)) / ry
    return (c ** p + s ** p) ** (-1.0 / p)


def plateau(M, cx, cy, h, rx, ry, rng, rot, segs=96, detail=1.0):
    """O margine de platou de tuf, profilul vaii Gulludere / Rose Valley, NU o
    masa de gresie (prima randare, cu perete vertical, citea Monument Valley):

      * jos un taluz concav, lung, care se evazeaza in fundul vaii;
      * peste el un versant de BADLAND care urca tot mai abrupt, brazdat de
        rigole in V (abs de zgomot: muchii ascutite intre ele, ca nervurile de
        pe fata Vaii Trandafirilor), rigolele mai adanci jos, unde curge apa;
      * sus o faleza scurta, aproape verticala, si CALOTA tare de ignimbrit pe
        ultimii ~7% (putin in consola: tuful moale de sub ea se retrage);
      * varf plat de stepa.
    Toate dungile vin din material (`strata`), deci geometria nu adauga volum
    pentru culoare (lectia benzilor de pe uchisar_castle)."""
    seed = rng.random() * 100.0
    lean = h * rng.uniform(0.9, 1.3)           # cat se retrage peretele de la baza la umar
    hc = h * 0.93                              # piciorul calotei
    n_wall = max(10, int(hc / (4.0 / detail)))
    zs = [-4.0] + [hc * (i / n_wall) for i in range(1, n_wall + 1)]
    f_lobe = 1.4
    f_rib = 26.0 * detail
    f_rib2 = 61.0 * detail

    def r_at(a, t):
        """t = 0 la fundul vaii, 1 la piciorul calotei."""
        ca, sa = math.cos(a), math.sin(a)
        base = superellipse_r(a - rot, rx, ry, 4.5)
        lobe = noise.noise(Vector((ca * f_lobe + seed, sa * f_lobe, 0.0)))
        # rigole in V: 1 - |zgomot| are creste ascutite; le adancim spre baza
        g1 = 1.0 - abs(noise.noise(Vector((ca * f_rib, sa * f_rib + seed, t * 0.9))))
        g2 = 1.0 - abs(noise.noise(Vector((ca * f_rib2 + seed, sa * f_rib2, t * 1.6))))
        rib = (0.75 * g1 ** 3 + 0.35 * g2 ** 3) * (0.35 + 0.65 * (1.0 - t))
        # profil: concav jos, abrupt sus (umarul la ~85%)
        prof = lean * (1.0 - smooth01(0.0, 0.86, t)) ** 1.8
        return base * (1.0 + 0.16 * lobe) + prof - rib * 0.11 * lean

    grid = []
    for z in zs:
        t = max(0.0, z) / hc
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            ca, sa = math.cos(a), math.sin(a)
            r = r_at(a, t)
            ring.append(M.v((cx + ca * r, cy + sa * r, z), TUFF_CREAM,
                            strata=smooth01(-2.0, 5.0, z)))
        grid.append(ring)
    # calota: iese putin in consola, cenusie, cu muchie neregulata
    top_drop = rng.uniform(-0.01, 0.02) * h
    for k, z in enumerate((hc + 0.3, h + top_drop)):
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            ca, sa = math.cos(a), math.sin(a)
            rr = r_at(a, 1.0) + 1.5
            zz = z + (0.8 * noise.noise(Vector((ca * 5.0, sa * 5.0, seed))) if k else 0.0)
            c = CAPROCK if (j * 7 + k) % 5 else CAPROCK_DARK
            ring.append(M.v((cx + ca * rr, cy + sa * rr, zz), c))
        grid.append(ring)
    top_ring = []
    for j in range(segs):
        p = grid[-1][j].co
        top_ring.append(M.v((cx + (p.x - cx) * 0.97, cy + (p.y - cy) * 0.97, p.z + 0.4), PLATEAU_TOP))
    grid.append(top_ring)
    top = M.v((cx, cy, sum(v.co.z for v in top_ring) / segs + 1.0), PLATEAU_TOP)
    bm = M.bm
    for i in range(len(grid) - 1):
        for j in range(segs):
            k = (j + 1) % segs
            bm.faces.new((grid[i][j], grid[i][k], grid[i + 1][k], grid[i + 1][j]))
    for j in range(segs):
        bm.faces.new((grid[-1][j], grid[-1][(j + 1) % segs], top))


def chimney(M, x, y, h, rng, z0=0.0, cap=True):
    """Cos de zana: con cu flancuri usor concave pe un taluz, cu palarie de bazalt
    MAI LATA decat gatul (lectia criticului B: palaria trebuie sa iasa in consola)."""
    r0 = h * rng.uniform(0.22, 0.32)
    segs = 10
    rings = 6
    grid = []
    for i in range(rings + 1):
        t = i / rings
        r = r0 * (1.0 - t) ** 1.35 + r0 * 0.12
        z = z0 - 1.0 + (h + 1.0) * t
        ring = []
        for j in range(segs):
            a = j / segs * math.tau + rng.uniform(-0.1, 0.1)
            ring.append(M.v((x + math.cos(a) * r, y + math.sin(a) * r, z), TUFF_CREAM, strata=1.0))
        grid.append(ring)
    bm = M.bm
    for i in range(rings):
        for j in range(segs):
            k = (j + 1) % segs
            bm.faces.new((grid[i][j], grid[i][k], grid[i + 1][k], grid[i + 1][j]))
    tip = M.v((x, y, z0 + h + 0.3), TUFF_CREAM, strata=1.0)
    for j in range(segs):
        bm.faces.new((grid[-1][j], grid[-1][(j + 1) % segs], tip))
    if cap:
        rc = r0 * rng.uniform(0.55, 0.75)
        res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
        zc = z0 + h * 0.96
        for vv in res["verts"]:
            vv.co = Vector((x + vv.co.x * rc, y + vv.co.y * rc, zc + vv.co.z * rc * 0.45))
            vv[M.col] = srgb(BASALT)
            vv[M.st] = 0.0
            vv[M.ho] = 0.0


def poplar(M, x, y, h, rng):
    """Plop: fus verde-inchis, ingust."""
    r = h * 0.14
    segs = 6
    base = [M.v((x + math.cos(j / segs * math.tau) * r * 0.5,
                 y + math.sin(j / segs * math.tau) * r * 0.5, h * 0.12), POPLAR)
            for j in range(segs)]
    mid = [M.v((x + math.cos(j / segs * math.tau) * r,
                y + math.sin(j / segs * math.tau) * r, h * 0.45), POPLAR)
           for j in range(segs)]
    tip = M.v((x, y, h), POPLAR)
    trunk = M.v((x, y, 0.0), "5A4A3A")
    bm = M.bm
    for j in range(segs):
        k = (j + 1) % segs
        bm.faces.new((base[j], base[k], mid[k], mid[j]))
        bm.faces.new((mid[j], mid[k], tip))
        bm.faces.new((trunk, base[k], base[j]))


def field(M, cx, cy, w, d, rot, colhex):
    """Petic de vie/livada: un dreptunghi intins pe podea, putin peste ea."""
    ca, sa = math.cos(rot), math.sin(rot)
    pts = []
    for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        lx, ly = sx * w * 0.5, sy * d * 0.5
        pts.append(M.v((cx + lx * ca - ly * sa, cy + lx * sa + ly * ca, 0.25), colhex))
    M.bm.faces.new(pts)


def polar(az_deg, d):
    a = math.radians(az_deg)
    return math.sin(a) * d, math.cos(a) * d          # busola -> Blender XY


# --- Planurile ------------------------------------------------------------------
#
# NEAR_GIANTS: marginile de platou apropiate, pe directiile camerei de joc
# (masurate pe Track13.baked, vezi tabelul de mai jos). Fiecare:
#   (nume, azimut, distanta, [(dx_tangential, dr_radial, h, rx, ry), ...])
# h = inaltimea fata de fundul vaii (camera benzii la CAM_Z = 30 m).
#
# Directiile camerei (busola de mers, `sus` = cate grade de cer intra in cadru):
#
#   portiunea                         fractii       directia   sus
#   dreapta startului, platou (50 m)  0,96-0,03     105-110    5-7
#   padurea de hornuri                0,04-0,16     70-110     4,5-5
#   coborarea de pe cornisa           0,20-0,25     0-115      sub 0 (nu se vede cer)
#   urcarea spre cornisa (valea dr.)  0,27-0,32     22-58      8-13
#   canionul, dreapta spre N          0,33-0,37     350-12     3
#   canionul + via, spre vest         0,38-0,64     245-295    2-4 (teren inalt in stanga)
#   subteranul + spirala              0,65-0,95     (inauntru: cer doar prin ferestre)
#
# Regulile plasarii (lectiile MV): niciun urias pe axa unei drepte (10-15+ grade
# lateral); nimic in spatele stancii goale reale (POI G, la vest, pe axa
# portiunii 0,38-0,64: uriasii D si E o incadreaza); valea de la est (dreapta
# urcarii spre cornisa) ramane deschisa spre Erciyes. Inaltimea in grade din
# camera benzii: e = atan((h - CAM_Z) / d).
#
# (nume, azimut, distanta, k_voal, [(dx_tangential, dr_radial, h, rx, ry), ...])
# k_voal: cat din aerul rece primesc (0,6 pe cei luminati, altfel ies lavanda; B e in contre-jour: soarele e la 155, deci
# primeste voalul intreg, ca sa nu iasa mai inchis decat stancile 3D cetoase).
NEAR_GIANTS = [
    # A: padurea de hornuri (axa 78) in stanga, la 16 grade; startul o vede la
    # marginea stanga.
    # Un singur bloc lat: o a doua bucata spre azimuturi mici ar fi stat in fata
    # lui Uchisar.
    ("A", 63.0, 700.0, 0.6, [(0.0, 0.0, 98.0, 165.0, 60.0)]),
    # B: startul (axa 105) in dreapta, la 35 de grade, langa Erciyes.
    ("B", 143.0, 800.0, 1.0, [(0.0, 0.0, 84.0, 115.0, 50.0)]),
    # C: canionul spre N (axa 350-12) in stanga; se vede si prin ferestrele spiralei.
    ("C", 333.0, 650.0, 0.6, [(0.0, 0.0, 110.0, 120.0, 55.0),
                               (135.0, 30.0, 86.0, 60.0, 40.0)]),
    # D, E: portiunea spre vest (axa 245-295), de o parte si de alta a stancii goale.
    ("D", 226.0, 720.0, 0.6, [(0.0, 0.0, 100.0, 140.0, 60.0)]),
    ("E", 310.0, 690.0, 0.6, [(0.0, 0.0, 92.0, 100.0, 50.0),
                               (-125.0, 40.0, 72.0, 50.0, 35.0)]),
]

# Uchisar: (azimut, distanta) — la capatul urcarii spre cornisa, unde camera vede
# cel mai mult cer. Erciyes: (azimut, distanta, inaltime, raza) — spre ESE, ca in
# realitate de la Goreme, la 13 grade in dreapta axei startului.
UCHISAR = (45.0, 1800.0)
ERCIYES = (118.0, 30000.0, 2100.0, 9000.0)
ERCIYES_K = 0.62
# Directii in care relieful mediu/departat ramane JOS: piciorul lui Erciyes.
QUIET = [(108.0, 130.0)]


def in_quiet(az):
    a = az % 360.0
    return any(lo <= a <= hi for lo, hi in QUIET)


def build_near(Ms):
    """Planul 0, in doua obiecte dupa voal (Ms[k_voal])."""
    rng = random.Random(1313)
    for name, az, d, kv, parts in NEAR_GIANTS:
        M = Ms[kv]
        a = math.radians(az)
        radial = Vector((math.sin(a), math.cos(a), 0.0))
        tang = Vector((math.cos(a), -math.sin(a), 0.0))
        for dx, dr, h, rx, ry in parts:
            c = radial * (d + dr) + tang * dx
            plateau(M, c.x, c.y, h, rx, ry, rng, -a + rng.uniform(-0.15, 0.15),
                    segs=384, detail=2.0)
            dd = c.length
            print("banda: urias %s az %.1f d %.0f h %.0f -> %.1f grade"
                  % (name, math.degrees(math.atan2(c.x, c.y)) % 360.0, dd, h,
                     math.degrees(math.atan2(h - CAM_Z, dd))))
        # cosuri de zana si plopi la poalele lor, spre camera
        span = max(p[3] for p in parts) * 2.0
        for _ in range(int(30 * len(parts))):
            t = rng.uniform(-1.0, 1.0)
            c = radial * (d - max(p[4] for p in parts) - rng.uniform(70.0, 200.0)) + tang * (t * span)
            if c.length < 430.0:
                continue
            if rng.random() < 0.72:
                chimney(M, c.x, c.y, rng.uniform(10.0, 28.0), rng)
            else:
                poplar(M, c.x, c.y, rng.uniform(10.0, 16.0), rng)


def build_landforms(M):
    """Planurile 1-3: margini de platou medii (1-3 km), lungi (3-8 km) si buza
    platoului departat (8-16 km), aproape continua; vaile intre ele raman
    deschise (fundul vaii pana la orizont)."""
    rng = random.Random(13)
    count = 0

    def place(d_min, d_max, n, make):
        nonlocal count
        placed = tries = 0
        while placed < n and tries < n * 50:
            tries += 1
            az = rng.uniform(0.0, 360.0)
            if in_quiet(az):
                continue
            d = rng.uniform(d_min, d_max)
            x, y = polar(az, d)
            make(x, y, d, az)
            placed += 1
            count += 1

    def mid(x, y, d, az):
        h = rng.uniform(40.0, min(110.0, 30.0 + 0.03 * d))
        r = h * rng.uniform(1.5, 4.0)
        plateau(M, x, y, h, r, r * rng.uniform(0.3, 0.6), rng,
                -math.radians(az) + rng.uniform(-0.4, 0.4), segs=96, detail=1.2)
        for _ in range(rng.randint(2, 6)):        # hornuri in vale, in fata
            a2 = math.radians(az + rng.uniform(-3.0, 3.0))
            dd = d - r - rng.uniform(30.0, 200.0)
            if dd > 500.0:
                chimney(M, math.sin(a2) * dd, math.cos(a2) * dd, rng.uniform(12.0, 26.0), rng)
    place(1000.0, 3000.0, 26, mid)

    def far(x, y, d, az):
        h = rng.uniform(60.0, min(200.0, 0.024 * d))
        r = h * rng.uniform(3.0, 8.0)
        plateau(M, x, y, h, r, r * rng.uniform(0.15, 0.35), rng,
                -math.radians(az) + rng.uniform(-0.2, 0.2), segs=64, detail=0.8)
    place(3000.0, 8000.0, 22, far)

    az = 0.0
    while az < 360.0:
        step = rng.uniform(7.0, 16.0)
        m = az + step * 0.5
        if not in_quiet(m):
            d = rng.uniform(9000.0, 16000.0)
            x, y = polar(m, d)
            half = math.radians(step) * d * 0.6
            h = rng.uniform(120.0, 260.0)
            plateau(M, x, y, h, half, h * rng.uniform(2.0, 4.0), rng,
                    -math.radians(m) + rng.uniform(-0.1, 0.1), segs=48, detail=0.6)
            count += 1
        az += step + (rng.uniform(2.0, 8.0) if rng.random() < 0.4 else 0.0)
    print("banda: %d forme de relief" % count)


def build_valley_life(M):
    """Vii, livezi, plopi si cosuri de zana raspandite pe fundul vaii (0,4-2,5 km)."""
    rng = random.Random(77)
    for _ in range(260):
        az = rng.uniform(0.0, 360.0)
        d = 420.0 + rng.random() ** 1.5 * 2100.0
        x, y = polar(az, d)
        r = rng.random()
        if r < 0.45:
            field(M, x, y, rng.uniform(25.0, 70.0), rng.uniform(12.0, 35.0),
                  rng.uniform(0.0, math.pi), rng.choice(FIELD))
        elif r < 0.75:
            for _ in range(rng.randint(2, 7)):
                poplar(M, x + rng.uniform(-14, 14), y + rng.uniform(-14, 14),
                       rng.uniform(10.0, 17.0), rng)
        else:
            for _ in range(rng.randint(2, 6)):
                chimney(M, x + rng.uniform(-25, 25), y + rng.uniform(-25, 25),
                        rng.uniform(8.0, 20.0), rng)


def build_uchisar(M):
    """Uchisar: cetatea-stanca. O movila de tuf abrupta, neregulata (doua varfuri),
    ciuruita de guri, cu satul de case-cub pe poale si un platou in spate."""
    rng = random.Random(4242)
    az, d = UCHISAR
    cx, cy = polar(az, d)
    h = 130.0

    def ucr(t):
        # trunchi cu pereti aproape verticali si varf rotunjit, pe un taluz lat
        # (prima randare, con drept, citea a cort)
        return 68.0 * max(0.0, 1.0 - t ** 3.2) ** 0.5 + 170.0 * (1.0 - smooth01(0.0, 0.4, t)) ** 2 + 5.0

    segs = 128
    rings = 28
    grid = []
    seed = 3.7
    for i in range(rings + 1):
        t = i / rings
        # profil: poale late, trunchi abrupt, varf rotunjit
        r = ucr(t)
        z = -4.0 + (h + 4.0) * t
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            ca, sa = math.cos(a), math.sin(a)
            nn = noise.noise(Vector((ca * 2.0 + seed, sa * 2.0, t * 2.0)))
            col = noise.noise(Vector((ca * 14.0, sa * 14.0 + seed, t * 2.5)))
            rr = r * (1.0 + 0.22 * nn + 0.07 * col)
            ring.append(M.v((cx + ca * rr, cy + sa * rr, z), TUFF_CREAM,
                            strata=0.55, holes=smooth01(0.15, 0.3, t)))
        grid.append(ring)
    bm = M.bm
    for i in range(rings):
        for j in range(segs):
            k = (j + 1) % segs
            bm.faces.new((grid[i][j], grid[i][k], grid[i + 1][k], grid[i + 1][j]))
    tip = M.v((cx, cy, h + 3.0), TUFF_CREAM, strata=0.55, holes=1.0)
    for j in range(segs):
        bm.faces.new((grid[-1][j], grid[-1][(j + 1) % segs], tip))
    # satul pe poale: cuburi de tuf si var
    for _ in range(220):
        a = rng.uniform(0.0, math.tau)
        t = rng.uniform(0.02, 0.3)
        r = ucr(t) * rng.uniform(1.0, 1.12)
        z = -4.0 + (h + 4.0) * t
        s = rng.uniform(4.0, 8.0)
        bx, by = cx + math.cos(a) * r, cy + math.sin(a) * r
        res = bmesh.ops.create_cube(bm, size=1.0)
        ang = rng.uniform(0.0, math.tau)
        c = srgb(HOUSE) if rng.random() < 0.7 else srgb(TUFF_PINK)
        for vv in res["verts"]:
            lx, ly, lz = vv.co.x * s, vv.co.y * s * rng.uniform(0.8, 1.2), (vv.co.z + 0.5) * s * 0.8
            vv.co = Vector((bx + lx * math.cos(ang) - ly * math.sin(ang),
                            by + lx * math.sin(ang) + ly * math.cos(ang), z - 2.0 + lz))
            vv[M.col] = c
            vv[M.st] = 0.0
            vv[M.ho] = 0.0
    print("banda: Uchisar az %.0f d %.0f -> %.1f grade" % (az, d, math.degrees(math.atan2(h - CAM_Z, d))))


def build_erciyes(M):
    """Erciyes: con de stratovulcan cu flancuri concave, doua umeri, zapada pe
    ultima treime (cu limbi pe vai)."""
    az, d, h, R = ERCIYES
    cx, cy = polar(az, d)
    segs = 192
    rings = 40
    grid = []
    for i in range(rings + 1):
        t = i / rings
        r = R * (1.0 - t) ** 1.8 + 120.0
        z = -10.0 + (h + 10.0) * t
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            ca, sa = math.cos(a), math.sin(a)
            ridge = noise.noise(Vector((ca * 12.0, sa * 12.0, t * 3.0)))
            shoulder = noise.noise(Vector((ca * 1.5 + 9.0, sa * 1.5, t)))
            rr = r * (1.0 + 0.10 * ridge + 0.12 * shoulder)
            snow_line = 0.62 + 0.10 * ridge
            c = SNOW if t > snow_line else VOLCANO
            ring.append(M.v((cx + ca * rr, cy + sa * rr, z), c))
        grid.append(ring)
    bm = M.bm
    for i in range(rings):
        for j in range(segs):
            k = (j + 1) % segs
            bm.faces.new((grid[i][j], grid[i][k], grid[i + 1][k], grid[i + 1][j]))
    tip = M.v((cx, cy, h + 20.0), SNOW)
    for j in range(segs):
        bm.faces.new((grid[-1][j], grid[-1][(j + 1) % segs], tip))
    print("banda: Erciyes az %.0f d %.0f -> %.1f grade" % (az, d, math.degrees(math.atan2(h - CAM_Z, d))))


def build_floor():
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=60000.0)
    me = bpy.data.meshes.new("BandFloor")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("BandFloor", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(floor_material())


def sun_dir_blender():
    """to_sun din tema Godot (Basis.from_euler YXZ, lumina pe -Z), in Blender."""
    rx, ry = math.radians(SUN_ROT[0]), math.radians(SUN_ROT[1])
    x, y, z = 0.0, -math.sin(rx), math.cos(rx)
    gx = x * math.cos(ry) + z * math.sin(ry)
    gz = -x * math.sin(ry) + z * math.cos(ry)
    g = Vector((gx, y, gz))                     # Godot: x est, y sus, z sud
    return Vector((g.x, -g.z, g.y)).normalized()  # Blender: x est, y nord, z sus


def setup_render():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "OPTIX"
        prefs.get_devices()
        for dev in prefs.devices:
            dev.use = True
        sc.cycles.device = "GPU"
    except Exception as e:  # fara GPU merge si pe CPU, doar mai incet
        print("GPU indisponibil: %s" % e)
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 3
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.render.resolution_x = W
    sc.render.resolution_y = H
    sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.image_settings.color_depth = "8"
    sc.render.filepath = OUT

    cd = bpy.data.cameras.new("BandCam")
    cd.type = "PANO"
    cd.panorama_type = "EQUIRECTANGULAR"
    cd.latitude_min = math.radians(LAT_MIN)
    cd.latitude_max = math.radians(LAT_MAX)
    cd.longitude_min = -math.pi
    cd.longitude_max = math.pi
    cd.clip_start = 1.0
    cd.clip_end = 80000.0
    cam = bpy.data.objects.new("BandCam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (0.0, 0.0, CAM_Z)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)   # priveste spre +Y (nord)
    sc.camera = cam

    ld = bpy.data.lights.new("BandSun", "SUN")
    ld.energy = SUN_STRENGTH
    ld.color = srgb(SUN_COLOR)[:3]
    ld.angle = math.radians(0.6)
    sun = bpy.data.objects.new("BandSun", ld)
    bpy.context.collection.objects.link(sun)
    sun.rotation_euler = (-sun_dir_blender()).to_track_quat("-Z", "Y").to_euler()

    world = bpy.data.worlds.new("BandWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = srgb(AMBIENT)
    bg.inputs["Strength"].default_value = AMBIENT_ENERGY
    sc.world = world


def test_markers():
    """Cuburi emisive pe punctele cardinale, la 800 m: rosu E, verde N, albastru V."""
    for name, (x, y), col in (("E", (800, 0), (1, 0, 0, 1)), ("N", (0, 800), (0, 1, 0, 1)),
                              ("V", (-800, 0), (0, 0, 1, 1))):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=60.0)
        me = bpy.data.meshes.new("Mk" + name)
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new("Mk" + name, me)
        bpy.context.collection.objects.link(ob)
        ob.location = (x, y, 40)
        mat, nt, out = new_material("Mk" + name)
        em = nt.nodes.new("ShaderNodeEmission")
        em.inputs["Color"].default_value = col
        nt.links.new(em.outputs[0], out.inputs["Surface"])
        ob.data.materials.append(mat)


reset()
random.seed(13)
setup_render()
build_floor()
M_far = Mesh()
build_landforms(M_far)
build_valley_life(M_far)
build_uchisar(M_far)
M_far.finish("BandLand", land_material())
# Erciyes separat: la 30 km voalul intreg (~0,9) ii stergea zapada. Aerul de
# podis la zori e limpede; muntele trebuie sa ramana munte cu zapada, nu o pata.
M_volc = Mesh()
build_erciyes(M_volc)
M_volc.finish("BandErciyes", land_material("BandVolcano", k_far=ERCIYES_K))
Ms = {kv: Mesh() for kv in sorted({g[3] for g in NEAR_GIANTS})}
build_near(Ms)
for kv, M in Ms.items():
    M.finish("BandNear%03d" % int(kv * 100),
             land_material("BandTuffNear%03d" % int(kv * 100), k=kv, strata_scale=0.03))
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))

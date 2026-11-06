"""Angkor — ELEFANTUL ASIATIC (kit §1.3, `angkor/animals/asian_elephant.glb`).

Pornește de la elefantul din Serengeti, FĂRĂ să-l copieze: sursa
`build_serengeti_animals.py` e citită ca text și tăiată înainte de partea ei
care rulează la import (`results = []`); rămân definițiile — `elephant_mesh()`,
`elephant_rig()`, `elephant_animate()` — executate în aceleași globale. Nimic
din Serengeti nu se scrie: GLB-ul lui rămâne neatins.

Ce se schimbă față de cel african (planșa `asian_elephant.png`):
  * umăr 2,9 m (african 3,4), lungime ~5,6 m cu trompa (african 6,4);
  * urechi MICI și rotunjite (african: uriașe, până la ±2 m);
  * cap bombat, cu DOUĂ boltiri pe frunte;
  * spatele cel mai înalt LA MIJLOC (arcuit), nu la umeri;
  * fără fildeși mari (rămân niște colți scurți din textura sursei) — fără șa, fără călăreț.

ORDINEA CONTEAZĂ. Reforma se face DUPĂ rigging, nu înainte: clasificarea pe
vertex din `elephant_rig` (fereastră pe Y pentru picioare, nu prag pe X —
memoria `elefant-mesh-importat-rig-per-vertex`) e calibrată pe geometria
africană, iar urechile micșorate ar cădea sub pragul `x_ear` și s-ar lipi de
cap. Greutățile rămân deci cele verificate; vertecșii și oasele trec prin ACEEAȘI
funcție `reshape()`, așa că scheletul rămâne în interiorul pielii. Cele 11 oase,
`Walk` (1,5 s) și `Trumpet` sunt cele din Serengeti, cu numele neschimbate
(`StrideDriver` conduce `LegFL/FR/RL/RR` și `Body` după nume).

Licența sursei: pachetul „191 animals pack" n-are fișier de licență (vezi
`transfagarasan_inventory_c.md`); e aceeași sursă deja folosită în Serengeti,
iar forma pleacă de aici dar e remodelată puternic (alte proporții, urechi,
cap). Decizia de provență rămâne a coordonatorului.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_angkor_elephant.py
"""

import bpy
import bmesh
import math
import os
from mathutils import Matrix, Vector

# ---- reutilizarea Serengeti: definițiile, fără partea care rulează ----------
_SER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build_serengeti_animals.py")
_text = open(_SER, encoding="utf-8").read()
_cut = _text.index("\nresults = []")
exec(compile(_text[:_cut], "build_serengeti_animals.py", "exec"), globals())

# ---- cote țintă (kit §1.3) ---------------------------------------------------
SHOULDER_H = 2.90          # contract 2,8-3,0
LENGTH_TOTAL = 5.60        # contract 5,4-5,8, cu trompa
EAR_AREA = 0.42            # urechea africană are ~3x aria celei asiatice dorite
OUT = "angkor/animals/asian_elephant.glb"


def _sm(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


# Parametri de forma, in spatiul african (inainte de scara). Se regleaza prin iteratie.
EAR_ANCHOR = Vector((0.70, 0.85, 4.20))   # radacina urechii pe cap (x pe partea dreapta)
EAR_K = Vector((0.55, 0.80, 0.80))        # factorii de micsorare x, y, z fata de ancora
ARCH_A = 0.64                             # cat se ridica mijlocul spatelui (m, spatiu african)
ARCH_Y, ARCH_W = -0.74, 1.1                # centrul si latimea arcului pe Y
BUMP_X, BUMP_Y, BUMP_H = 0.30, 1.55, 0.28 # cele doua boltiri ale frunții
SC_X = 0.92                               # latimea (SC_Y se deduce din lungimea tinta)
Z_LEG, LEG_SC, HEAD_BOOST = 2.0, 0.62, 0.12  # tronsonul picioarelor, scara lui, spor de cap
RUMP_DROP = 0.55                          # coborarea crupei (m, spatiu african)
TUSK_K = 0.45                             # fildesii scurti: factor fata de radacina


def warp(p, w_ear=0.0, w_head=0.0, tusk=None):
    """Forma asiatica pe un punct din spatiul african (Vector). Fara scara
    finala pe Z (se calibreaza pe cota umarului, vezi `build`)."""
    q = Vector(p)
    sgn = 1.0 if q.x >= 0 else -1.0
    if tusk is not None:                       # fildes: spre radacina lui
        q = tusk + (q - tusk) * TUSK_K
    if w_ear > 0.0:                            # urechea: spre radacina, mai mica
        a = Vector((sgn * EAR_ANCHOR.x, EAR_ANCHOR.y, EAR_ANCHOR.z))
        d = q - a
        q = a + Vector((d.x * EAR_K.x, d.y * EAR_K.y, d.z * EAR_K.z)) * w_ear + d * (1.0 - w_ear)
    # spatele arcuit: mijlocul sus, umarul si crupa coboara
    wy = _sm((1.2 - q.y) / 0.6)
    bump = math.exp(-((q.y - ARCH_Y) / ARCH_W) ** 2)
    q.z += ARCH_A * (bump - 0.50) * _sm((q.z - 2.6) / 1.4) * wy * (1.0 - w_ear)
    # crupa coboara spre coada (la elefantul asiatic coloana scade dupa sold)
    q.z -= RUMP_DROP * _sm((-1.2 - q.y) / 0.9) * _sm((q.z - 2.6) / 1.4)
    if w_head > 0.0:                           # capul bombat cu doua boltiri
        for cx in (-BUMP_X, BUMP_X):
            r2 = ((q.x - cx) / 0.30) ** 2 + ((q.y - BUMP_Y) / 0.85) ** 2
            q.z += BUMP_H * math.exp(-r2) * _sm((q.z - 3.6) / 0.6) * w_head
        q.z += 0.20 * math.exp(-((q.y - BUMP_Y) / 1.0) ** 2) * _sm((q.z - 3.6) / 0.6) * w_head
    return q


def build():
    _wipe()
    arm, ele = build_elephant()                # mesh african + rig + Walk/Trumpet
    me = ele.data
    gname = {vg.index: vg.name for vg in ele.vertex_groups}
    dom = {}
    for v in me.vertices:
        dom[v.index] = gname[max(v.groups, key=lambda x: x.weight).group]

    # fildesii: fetele cu slotul IVORY (ca in rig); radacina = varful cel mai sus
    uvd = me.uv_layers.active.data
    ivory = set()
    for poly in me.polygons:
        if int(round(uvd[poly.loop_indices[0]].uv[0] * SLOTS - 0.5)) == IVORY:
            ivory.update(poly.vertices)
    roots = {}
    for sgn in (-1.0, 1.0):
        side = [me.vertices[i].co for i in ivory if (me.vertices[i].co.x >= 0) == (sgn > 0)]
        roots[sgn] = max(side, key=lambda c: c.z - 0.5 * abs(c.x)).copy()

    new = {}
    ear_move = []
    for v in me.vertices:
        c = v.co
        b = dom[v.index]
        w_ear = 0.0
        if b in ("EarL", "EarR"):
            w_ear = 1.0
        elif b == "Body" and c.y > -0.15 and c.z > 2.8:
            w_ear = _sm((abs(c.x) - 1.0) / 0.25)
        w_head = 1.0 if b == "Head" else 0.0
        if b == "Body" and w_ear >= 0.5:
            # jumatatea din spate a urechii africane e legata de Body (la
            # Serengeti flutura doar o treime din ea); aici toata clapa trece
            # pe osul ei, altfel la Trumpet se rupe in doua
            ear_move.append((v.index, "EarR" if c.x >= 0 else "EarL"))
        tusk = roots[1.0 if c.x >= 0 else -1.0] if v.index in ivory else None
        new[v.index] = warp(c, w_ear, w_head, tusk)

    body_vg = ele.vertex_groups["Body"]
    for i, ear_bone in ear_move:
        body_vg.remove([i])
        ele.vertex_groups[ear_bone].add([i], 1.0, "REPLACE")
    print("  clapa urechii: %d varfuri mutate de pe Body pe Ear" % len(ear_move))

    # scara: PE TRONSOANE pe Z, calibrata pe UMAR (spatele din mijloc iese mai sus, arcuit). Elefantul african din pachet e un butoi inalt
    # (spatele la 4,6 m): o scara uniforma pana la cota asiatica il facea pui
    # (picioare scurte). Picioarele (z < Z_LEG) se scaleaza mai putin, corpul
    # deasupra se turteste mai tare, capul (spre +Y) mai putin decat spatele.
    top = max(new[i].z for i in new if dom[i] == "Body" and abs(new[i].x) < 0.8
              and 0.0 < new[i].y < 0.8)           # umarul: deasupra picioarelor din fata
    leg_h = Z_LEG * LEG_SC
    # lungimea cu trompa; fildesii scurtati nu mai sunt varful, deci se masoara dupa reforma
    sc_y = LENGTH_TOTAL / (max(q.y for q in new.values()) - min(q.y for q in new.values()))
    k_body = (SHOULDER_H - leg_h) / (top - Z_LEG)
    print("  spate (african+arc) %.2f m -> picioare x%.2f, corp x%.3f" % (top, LEG_SC, k_body))

    def scl(q):
        k = k_body * (1.0 + HEAD_BOOST * _sm((q.y - 0.4) / 1.0))
        z = q.z * LEG_SC if q.z < Z_LEG else leg_h + (q.z - Z_LEG) * k
        return Vector((q.x * SC_X, q.y * sc_y, z))

    for v in me.vertices:
        v.co = scl(new[v.index])
    me.update()
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for eb in arm.data.edit_bones:
        ear = 1.0 if eb.name.startswith("Ear") else 0.0
        eb.head = scl(warp(eb.head, ear, 0.0))
        eb.tail = scl(warp(eb.tail, ear, 0.0))
        eb.roll = 0.0
    bpy.ops.object.mode_set(mode="OBJECT")
    for act in bpy.data.actions:               # Body.location (m) scalat pe Z
        fcs = act.fcurves if hasattr(act, "fcurves") else []
        for fc in fcs:
            if fc.data_path.endswith("location") and fc.array_index == 2:
                for kp in fc.keyframe_points:
                    kp.co[1] *= LEG_SC
                    kp.handle_left[1] *= LEG_SC
                    kp.handle_right[1] *= LEG_SC
    bpy.context.view_layer.update()
    return arm, ele


arm, ele = build()
_, sz = export_glb([arm, ele], OUT, animations=True)
print("%s  %d tris  %.1f kB" % (OUT, tri_count(ele), sz / 1024.0))

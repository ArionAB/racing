"""stone_gate_torii.glb — poarta de piatra cu acoperis de olane (4.5 m).

Referinta: assets/okinawa_inspiration/, randul ROADSIDE (STONE_GATE_TORII).
NU e un torii shinto japonez clasic (doua bare rosii): e poarta ryukyuana de
piatra, cu stalpi masivi si un acoperis de olane deasupra lintoului. Diferenta
conteaza — poarta rosie ar muta pista din Okinawa in Kyoto.

Doua piese, doua clase: `stone_wall` pe piatra (UV cubic 1.4 m, cat un bloc de
zidarie) si `roof_tiles` pe acoperis (UV cubic 1.0 m, cat un rand de olane).
Amandoua exista deja pentru casa de sat, deci poarta nu adauga NICIUN material
nou la bugetul pistei — de aia a fost aleasa peste o poarta vopsita.

Buget: hero de marginea drumului -> tinta 1200-2500 tris.
"""

import math

SPAN = 1.42        # jumatatea distantei dintre axele stalpilor
P_W = 0.52         # latura stalpului la baza
BASE_H = 0.34
PILLAR_TOP = 3.28
NUKI_Z = 2.42      # traversa de jos
KASAGI_Z = 3.28    # lintoul de sub acoperis
EAVE_Z = 3.72
RIDGE_Z = 4.24
ROOF_W = 4.60
ROOF_D = 1.62


def stone(b):
    for sx in (-1.0, 1.0):
        x = sx * SPAN
        # Soclu in doua trepte: o singura placa arata a stalp infipt in nisip.
        b.box((x, 0.0, BASE_H * 0.5), (P_W + 0.42, P_W + 0.42, BASE_H),
              CORAL_SAND)
        b.box((x, 0.0, BASE_H + 0.09), (P_W + 0.20, P_W + 0.20, 0.18),
              CORAL_SAND)
        # Stalpul: doua tronsoane usor diferite ca grosime. Conicitatea reala
        # (`frustum`) ar fi rotit sectiunea patrata cu 45°, deci se face din
        # doua cutii — muchia dintre ele intra oricum in bevel.
        b.box((x, 0.0, (BASE_H + 1.85) * 0.5 + 0.18),
              (P_W, P_W, 1.85 - BASE_H + 0.18), CORAL_SAND)
        b.box((x, 0.0, (1.85 + PILLAR_TOP) * 0.5),
              (P_W * 0.93, P_W * 0.93, PILLAR_TOP - 1.85), CORAL_SAND)
    # Traversa (nuki) — trece PRIN stalpi si iese putin in afara, ca la poarta
    # adevarata; capetele care ies sunt ce face poarta sa citeasca drept poarta.
    b.box((0.0, 0.0, NUKI_Z), (SPAN * 2 + P_W + 0.44, 0.34, 0.30), CORAL_SAND)
    # Lintoul (kasagi) pe care sta acoperisul.
    b.box((0.0, 0.0, KASAGI_Z + 0.20), (SPAN * 2 + P_W + 0.90, 0.66, 0.40),
          CORAL_SAND)
    # Placuta cu inscriptie, sub linto, in axul portii.
    b.box((0.0, -0.30, NUKI_Z + 0.42), (0.62, 0.10, 0.44), CONCRETE)


def roof(b):
    """Acoperis in patru ape, ca la casa de sat: fetele se construiesc explicit
    intre streasina si coama, nu din placi rotite.

    Motivul e acelasi si a fost invatat acolo: placile rotite diverg de la panta
    si acoperisul iese un morman plutitor. Cand geometria E panta, nu are cum.
    """
    ridge_len = ROOF_W - ROOF_D * 1.15
    c = {
        "fl": (-ROOF_W / 2, -ROOF_D / 2, EAVE_Z),
        "fr": (ROOF_W / 2, -ROOF_D / 2, EAVE_Z),
        "bl": (-ROOF_W / 2, ROOF_D / 2, EAVE_Z),
        "br": (ROOF_W / 2, ROOF_D / 2, EAVE_Z),
        "rl": (-ridge_len / 2, 0.0, RIDGE_Z),
        "rr": (ridge_len / 2, 0.0, RIDGE_Z),
    }
    v = {k: b.bm.verts.new(p) for k, p in c.items()}
    faces = [
        b.bm.faces.new((v["fl"], v["fr"], v["rr"], v["rl"])),
        b.bm.faces.new((v["br"], v["bl"], v["rl"], v["rr"])),
        b.bm.faces.new((v["bl"], v["fl"], v["rl"])),
        b.bm.faces.new((v["fr"], v["br"], v["rr"])),
    ]
    for f in faces:
        f[b.slot] = TILE_TERRACOTTA
    b._tag(list(v.values()), TILE_TERRACOTTA)
    # Talpa acoperisului, ca sa nu se vada in pod pe dedesubt.
    b.box((0.0, 0.0, EAVE_Z - 0.06), (ROOF_W, ROOF_D, 0.12), TILE_TERRACOTTA)

    # Randurile de olane: bare paralele cu streasina, impinse putin in afara pe
    # panta. Cateva muchii care prind lumina razanta vand "cursuri de tigla" mai
    # bine decat orice textura la 30 m.
    courses = 3
    for k in range(1, courses):
        t = k / courses
        for sy in (-1.0, 1.0):
            x0 = _lerp(-ROOF_W / 2, -ridge_len / 2, t)
            x1 = _lerp(ROOF_W / 2, ridge_len / 2, t)
            y = sy * _lerp(ROOF_D / 2, 0.0, t)
            z = _lerp(EAVE_Z, RIDGE_Z, t)
            b.beam((x0, y + sy * 0.045, z + 0.05),
                   (x1, y + sy * 0.045, z + 0.05),
                   (0.075, 0.06), TILE_TERRACOTTA)
    # Coama alba + muchiile de apa: semnatura acoperisului okinawan.
    b.beam((-ridge_len / 2 - 0.10, 0.0, RIDGE_Z + 0.07),
           (ridge_len / 2 + 0.10, 0.0, RIDGE_Z + 0.07), (0.22, 0.17), CONCRETE)
    for rk, ck in (("rl", "fl"), ("rl", "bl"), ("rr", "fr"), ("rr", "br")):
        b.beam((c[rk][0], c[rk][1], c[rk][2] + 0.05),
               (c[ck][0], c[ck][1], c[ck][2] + 0.05),
               (0.14, 0.12), CONCRETE)


def _lerp(a, b_, t):
    return a + (b_ - a) * t


AO_SPEC = dict(samples=28, dist=2.4, gradient="vertical",
               low=0.48, high=1.0, power=0.8, floor=0.16)

# (nume, functie, bevel, latura cubului de UV)
PARTS = [
    ("Torii_Stone", stone, 0.05, 1.4),
    ("Torii_Roof", roof, 0.04, 1.0),
]

clear_built("Torii_")
built = []
for name, fill, bevel, uv_size in PARTS:
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    min_z = min(v[2] for v in obj.bound_box)
    stats = finish(obj, bevel=bevel, origin="base_axis",
                   ao=dict(AO_SPEC, z_range=(0.0, RIDGE_Z + 0.2)))
    obj.location.z = min_z
    cube_uvs(obj, uv_size)
    built.append((obj, stats))
    print("  %-14s %4d tris  AO %.2f..%.2f  uv cub %.1f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"], uv_size))

objs = [o for o, _s in built]
bpy.context.view_layer.update()
lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
hi = max(max((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
print("stone_gate_torii.glb  TOTAL %d tris  inaltime %.2f m"
      % (sum(s["tris"] for _o, s in built), hi - lo))
print("GLB:  %s (%d B)" % export_glb(objs, "structures/stone_gate_torii.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "stone_gate_torii.blend"))

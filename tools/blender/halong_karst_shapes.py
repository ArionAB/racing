"""Turnurile de carst Ha Long, v2 — generatorul comun (exec, ca okinawa_shapes).

Folosit de `build_halong_karst.py` (turnuri, stive) si `build_halong_grotto.py`
(masivul grotei = acelasi turn, alungit si rotit). Cere in globals: Builder,
Vector, Matrix, bmesh, math, _ok_rand, TROPICAL_GREEN, CACTUS_GREEN, HL_ROCK si,
daca `spec` nu da `prof`, KARST_PROFILE.
"""

# --- v2 (26 nov 2026): turnurile din prim-plan dupa cele din banda de cer -------
#
# Dupa ce a intrat banda de orizont (build_halong_sky_band.py), dezvoltatorul a
# vazut diferenta pe aceeasi captura: turnurile din banda au lobi, caneluri
# verticale, creste zimtate si sunt ACOPERITE de jungla, iar cele de langa drum
# erau prisme fatetate bej, cu cateva tufe-bolovan pe varf — "simple si
# colturoase". V1 avea 13 coloane, `jag` aleator per coloana si umbrire PLATA
# (fiecare fata o placa de lumina); exact aspectul "Minecraft" descris la
# `apply_smooth`.
#
# V2 ia vocabularul benzii, la scara de prim-plan:
#  * aceeasi LEGE DE FORMA (KARST_PROFILE — nisa, consola, perete drept), deci
#    garda de silueta si amprenta pe sol nu se misca;
#  * suprafata din zgomot continuu (`mathutils.noise`), nu aleator per coloana:
#    lobi mari pe unghi, caneluri verticale si cornise orizontale, umbrire
#    NETEDA cu muchii doar peste 62 de grade;
#  * creasta zimtata (varfuri si sei din zgomot), nu un capac plat;
#  * coroane de jungla (icosfere bosselate, doua sloturi de verde) pe tot ce
#    priveste in sus, plus petice agatate pe pereti — densitate pe m^2, ca in
#    banda;
#  * culoarea rocii in VERTEX COLOR peste AO: dungi verticale de scurgere,
#    banda uda la linia apei, muschi pe cornise, umbra sub coronament. Clasa
#    `karst_limestone` inmulteste albedo-ul cu vertex color-ul
#    (`vertex_color_use_as_albedo`), deci toata variatia e fara materiale noi.
from mathutils import noise as _mnoise

HL_VEG_SLOTS = (TROPICAL_GREEN, TROPICAL_GREEN, CACTUS_GREEN)


def _sm(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def _prof_r(prof, zf):
    """Raza (fractie) la fractia de inaltime `zf`, liniar intre nodurile
    profilului."""
    for i in range(len(prof) - 1):
        a, b = prof[i], prof[i + 1]
        if a[0] <= zf <= b[0]:
            t = (zf - a[0]) / max(b[0] - a[0], 1e-9)
            return a[1] + (b[1] - a[1]) * t
    return prof[-1][1]


def _ring_ts(prof, n):
    """Cotele inelelor: TOATE nodurile profilului (nisa si consola trebuie sa
    cada exact pe inel, altfel interpolarea le rotunjeste) plus o grila
    uniforma, fara inele mai apropiate de 0,4/n de un nod."""
    ts = [p[0] for p in prof]
    for i in range(1, n):
        t = i / n
        if all(abs(t - u) > 0.4 / n for u in ts):
            ts.append(t)
    return sorted(ts)


def _lean_at(spec, t):
    lean = spec.get("lean", 0.0)
    if not lean:
        return 0.0
    lf, lt = spec.get("lean_from", 0.25), spec.get("lean_to", 0.95)
    u = max(0.0, min(1.0, (t - lf) / max(lt - lf, 1e-6)))
    return lean * u * u * (3.0 - 2.0 * u)


def _crown(bm, slot_layer, c, n, size, rnd, slot, flat=0.75):
    """O coroana: icosaedru (20 tri) bosselat, turtita pe o directie intre
    normala peretelui si verticala, scufundata partial in roca."""
    up = Vector((0.0, 0.0, 1.0))
    z = (up * 0.55 + n * 0.45).normalized()
    x = z.cross(up if abs(z.z) < 0.95 else Vector((1.0, 0.0, 0.0))).normalized()
    y = z.cross(x)
    yaw = rnd() * math.tau
    x, y = x * math.cos(yaw) + y * math.sin(yaw), y * math.cos(yaw) - x * math.sin(yaw)
    sx = size * (0.9 + 0.25 * rnd())
    sy = size * (0.8 + 0.25 * rnd())
    sz = size * flat
    M = Matrix((
        (x.x * sx, y.x * sy, z.x * sz, c.x),
        (x.y * sx, y.y * sy, z.y * sz, c.y),
        (x.z * sx, y.z * sy, z.z * sz, c.z),
        (0.0, 0.0, 0.0, 1.0)))
    # 20 triunghiuri, fatetat: la umbrire plata o icosfera de 80 citea ca o
    # perla. Masa de jungla vine din SUPRAPUNEREA multor coroane mici.
    res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
    ph = Vector((rnd() * 50.0, rnd() * 50.0, rnd() * 50.0))
    for v in res["verts"]:
        k = 1.0 + 0.28 * _mnoise.noise(v.co * 2.1 + ph)
        v.co = M @ (v.co * k)
    faces = set()
    for v in res["verts"]:
        faces.update(v.link_faces)
    for f in faces:
        f[slot_layer] = slot


def karst_body(spec):
    """Corpul unui turn v2. `spec`:
      seed, h, r_mid, ratio (y/x), seg (coloane), rings (inele pe inaltime),
      lobe / flute / ledge (amplitudinile zgomotului, fractii din raza),
      crest (amplitudinea crestei, fractie din h), twin (saua crestei duble),
      lean / lean_from / lean_to (inclinare pe +X), prof,
      crown (raza medie a coroanei, m), cover (straturi de coroane in masca),
      wall_veg (cat din perete acopera perdelele de jungla, 0..1),
      names (numele celor doua noduri), xform (Matrix 4x4), veg_skip(c, r).
    Returneaza (obiect_roca, obiect_vegetatie, cota_varfului)."""
    sd = spec["seed"]
    H, RM = spec["h"], spec["r_mid"]
    ratio = spec.get("ratio", 0.88)
    prof = spec.get("prof") or KARST_PROFILE
    segs = spec.get("seg", 40)
    lobe_a = spec.get("lobe", 0.14)
    flute_a = spec.get("flute", 0.06)
    ledge_a = spec.get("ledge", 0.035)
    crest = spec.get("crest", 0.10)
    twin = spec.get("twin", 0.0)
    off = Vector((sd * 1.37, sd * 0.71, sd * 2.13))
    rnd = _ok_rand(sd + 101)

    rock = Builder()
    bm, SL = rock.bm, rock.slot
    ts = _ring_ts(prof, spec.get("rings", 34))
    # Zgomotul de LOB e atenuat in banda nisei: nisa e contractul de silueta
    # (garda o masoara ca raport fata de mijloc), iar lobii mari i-ar umple
    # golul dintr-o parte. Canelurile si cornisele raman — sunt textura.
    grid = []
    zl = H / (RM * 2.4)
    for t in ts:
        z = t * H
        rb = _prof_r(prof, t) * RM
        cx = _lean_at(spec, t)
        base_w = 0.35 + 0.65 * _sm(0.10, 0.22, t)
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            ca, sa = math.cos(a), math.sin(a)
            lobe = _mnoise.noise(Vector((ca * 1.25, sa * 1.25, t * zl)) + off)
            flute = _mnoise.noise(Vector((ca * 6.5, sa * 6.5, t * H / 70.0)) + off * 1.7)
            ledge = _mnoise.noise(Vector((ca * 2.2, sa * 2.2, t * H / 5.5)) + off * 0.6)
            k = 1.0 + base_w * lobe_a * lobe + flute_a * flute + ledge_a * ledge
            zz = z
            # Creasta: in sfertul de sus varfurile urca si seile coboara (zgomot
            # pe unghi); `twin` sapa o saua pe axa Y -> creasta dubla.
            if t > 0.80:
                s2 = (t - 0.80) / 0.20
                peak = _mnoise.noise(Vector((ca * 1.5, sa * 1.5, 0.0)) + off * 0.37)
                peak += twin * (abs(ca) - 0.5) * 1.6
                # Seile coboara PUTIN (-0,35), varfurile urca: o saua adanca
                # facea ca o felie orizontala de la 0,8 din inaltime sa taie
                # doar un varf, iar garda de silueta citea "perete de 2,9 m"
                # (karst_tower_b, prima rulare v2).
                peak = max(peak, -0.35)
                zz = z + crest * H * s2 * s2 * peak
                k *= 1.0 + 0.10 * s2 * peak
            ring.append(bm.verts.new((cx + ca * rb * k, sa * rb * k * ratio, zz)))
        grid.append(ring)
    rock_faces = []
    for i in range(len(grid) - 1):
        for j in range(segs):
            jj = (j + 1) % segs
            f = bm.faces.new((grid[i][j], grid[i][jj], grid[i + 1][jj], grid[i + 1][j]))
            f[SL] = HL_ROCK
            rock_faces.append(f)
    # Capacul: un varf central ridicat (cupola joasa), nu un ngon plat.
    top_ring = grid[-1]
    tz = sum(v.co.z for v in top_ring) / segs
    apex = bm.verts.new((_lean_at(spec, 1.0), 0.0, tz + RM * prof[-1][1] * 0.35))
    for j in range(segs):
        f = bm.faces.new((top_ring[j], top_ring[(j + 1) % segs], apex))
        f[SL] = HL_ROCK
        rock_faces.append(f)
    bot = bm.verts.new((0.0, 0.0, 0.0))
    for j in range(segs):
        f = bm.faces.new((grid[0][(j + 1) % segs], grid[0][j], bot))
        f[SL] = HL_ROCK
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    # `xform` (Matrix 4x4, doar rotatie in jurul lui Z + translatie in plan):
    # masivul grotei e un turn ALUNGIT, rotit pe directia tunelului. Se aplica
    # inainte de jungla, ca filtrul `veg_skip` sa lucreze in coordonatele finale.
    xf = spec.get("xform")
    if xf is not None:
        for v in bm.verts:
            v.co = xf @ v.co
    veg_skip = spec.get("veg_skip")

    # Jungla, ca ACOPERIRE, nu ca densitate uniforma. Prima varianta presara
    # coroane pe toata suprafata, cu o pondere: in joc ieseau BULINE verzi pe
    # un perete bej. In banda (si in fotografii) jungla e o MANTIE continua pe
    # creasta si pe cornise, plus PERDELE pe perete, cu roca goala intre ele.
    # Deci: o masca (coronament + perdele), si in masca `cover` straturi de
    # coroane suprapuse; in afara ei, nimic.
    #   coronament = ce priveste in sus (cornise, umeri) + sfertul de sus;
    #   perdele    = zgomot ALUNGIT pe verticala (z de 3 ori mai rar decat xy),
    #                deci petice inalte si inguste, ca vegetatia care curge
    #                pe o faleza de carst.
    veg = Builder()
    vbm, VSL = veg.bm, veg.slot
    cover = spec.get("cover", 2.4)
    cr = spec.get("crown", 3.0)
    wall = spec.get("wall_veg", 0.5)
    top_z = max(v.co.z for v in bm.verts)
    n_crowns = 0
    for f in rock_faces:
        f.normal_update()
        nz = f.normal.z
        cen = f.calc_center_median()
        t = cen.z / H
        if t < 0.18:
            continue
        crest_m = max(_sm(0.22, 0.55, nz) * _sm(0.18, 0.30, t), _sm(0.80, 0.90, t))
        pz = _mnoise.noise(Vector((cen.x / (RM * 0.42), cen.y / (RM * 0.42),
                                   cen.z / (H * 0.40))) + off * 0.5)
        curtain = _sm(0.30 - 0.45 * wall, 0.45 - 0.45 * wall, pz) * _sm(0.28, 0.45, t)
        m = max(crest_m, curtain)
        if m < 0.05:
            continue
        on_crest = crest_m >= curtain
        rmean = cr * (1.05 if on_crest else 0.8)
        expect = f.calc_area() * m * cover / (math.pi * rmean * rmean)
        cnt = int(expect) + (1 if rnd() < expect - int(expect) else 0)
        vs = [v.co for v in f.verts]
        for _ in range(cnt):
            # punct uniform pe quad (biliniar), nu doar pe jumatatea lui
            a, b = rnd(), rnd()
            if len(vs) == 4:
                p = (vs[0] * (1 - a) * (1 - b) + vs[1] * a * (1 - b)
                     + vs[2] * a * b + vs[3] * (1 - a) * b)
            else:
                if a + b > 1.0:
                    a, b = 1.0 - a, 1.0 - b
                p = vs[0] + (vs[1] - vs[0]) * a + (vs[2] - vs[0]) * b
            size = rmean * (0.75 + 0.5 * rnd())
            # pe perete coroanele sunt turtite (agatatoare), pe creasta pernite
            flat = 0.72 if on_crest else 0.5
            c = p + f.normal * size * (0.25 if on_crest else 0.15)
            if veg_skip is not None and veg_skip(c, size):
                continue
            slot = HL_VEG_SLOTS[int(rnd() * len(HL_VEG_SLOTS)) % len(HL_VEG_SLOTS)]
            _crown(vbm, VSL, c, f.normal, size, rnd, slot, flat)
            n_crowns += 1
    spec["_crowns"] = n_crowns
    names = spec.get("names", ("Tower_Rock", "Tower_Scrub"))
    return rock.to_object(names[0]), veg.to_object(names[1]), top_z


# Tenta de pozitie, coapta peste AO (vertex color). Valorile sunt multiplicatori
# pe albedo-ul clasei: <1 intuneca, iar R/B mai mici decat G inverzesc.
MOSS_TINT = (0.62, 0.78, 0.47)
WET_TINT = (0.50, 0.52, 0.50)


def tint_rock(o, H, RM, seed, wet_band=True):
    """Dungi de scurgere, banda uda la linia apei, muschi pe cornise si sub
    coronament — inmultite peste AO-ul copt (canalul R al lui "AO")."""
    me = o.data
    ca = me.color_attributes["AO"]
    off = Vector((seed * 0.91, seed * 1.73, seed * 0.29))
    for v in me.vertices:
        p = v.co
        t = p.z / max(H, 1e-6)
        ao = ca.data[v.index].color[0]
        # dungi de scurgere: zgomot alungit pe verticala
        # Contrast MARE: Godot citeste vertex color-ul ca LINIAR
        # (`vertex_color_is_srgb` e fals), deci 0,5 aici se vede ~0,73 pe
        # ecran. La 0,42 de adancime dungile se pierdeau in soare direct si
        # peretele iesea crem uniform (capturile de la 0,7 si 0,88).
        # Latimea dungii TREBUIE sa fie peste pasul dintre coloane: la RM*0,12
        # (1,9 m pe turnul A) cadeau intre vertecsi (2,3 m la 44 de coloane) si
        # se netezeau in pete. RM*0,30 da ~3 coloane pe dunga la 64 de coloane.
        st = _mnoise.noise(Vector((p.x / (RM * 0.30), p.y / (RM * 0.30),
                                   p.z / (H * 0.55))) + off)
        s = 0.90 - 0.62 * _sm(-0.20, 0.35, st)
        rgb = [s, s, s]
        # banda uda la linia apei (sub consola)
        wet = (1.0 - _sm(0.07, 0.15, t)) if wet_band else 0.0
        rgb = [c * (1.0 - wet + wet * w) for c, w in zip(rgb, WET_TINT)]
        # muschi pe ce priveste in sus (cornise) si sub coronament
        m = 0.85 * _sm(0.25, 0.7, v.normal.z) * _sm(0.12, 0.25, t)
        m = max(m, 0.55 * _sm(0.80, 0.95, t))
        rgb = [c * (1.0 - m + m * w) for c, w in zip(rgb, MOSS_TINT)]
        ca.data[v.index].color = (ao * rgb[0], ao * rgb[1], ao * rgb[2], 1.0)


def tint_veg(o, RM, seed):
    """Petice de verde mai inchis / mai deschis (in banda: o culoare aleatoare
    per coroana). Peste AO, deci doar intuneca."""
    me = o.data
    ca = me.color_attributes["AO"]
    off = Vector((seed * 0.53, seed * 1.11, seed * 0.77))
    for v in me.vertices:
        n = _mnoise.noise(v.co / max(RM * 0.22, 0.5) + off)
        k = 0.74 + 0.26 * (0.5 + 0.5 * n)
        c = ca.data[v.index].color
        ca.data[v.index].color = (c[0] * k, c[1] * k, c[2] * k, 1.0)



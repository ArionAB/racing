"""Transfagarasan -- vehiculele de decor (brief docs/asset_briefs/transfagarasan_kit.md §1.7).

  transfagarasan/vehicles/parked_car_a.glb   hatchback mic generic, CAR_BLUE
  transfagarasan/vehicles/parked_car_b.glb   break / SUV mic generic, CAR_RED, bare + cutie
  transfagarasan/vehicles/motorbike.glb      turism-aventura generica, pe cric, 2 genti

Trenul (`ro_train`) si cabina (`cable_cabin_large`) NU sunt aici: valul 3 (tf-h).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_vehicles.py
Variabila de mediu TF_ONLY=<piesa> reface doar piesa respectiva.

GABARITUL MASINII DE JOC (kit §1.7: "la latimea si lungimea carcasei din
scenes/cars/Car.tscn, masurate, nu presupuse"). Car.tscn nu are forma de
coliziune in text: o face `car.gd` la `_ready` -- `BoxShape3D` de
**2,2 (X) x 1,0 (Y) x 3,8 (Z) m** (car.gd:482), talpa la +0,25. `apply_data`
o redimensioneaza pe fiecare masina la `body_width*0,9 x body_length*0,85`
(car.gd:550); pe masina implicita a jucatorului (Muscle, `selected_car = 0`,
body 2,00 x 4,37) iese 1,80 x 3,71 m, iar modelul ei (`open_roadster.glb`)
masoara 2,10 x 4,37 m (`measure_tf_f.py aabb`). Masinile parcate sunt pe
carcasa din Car.tscn: **a = 2,20 x 3,80 m**, **b = 2,20 x 4,37 m** (+15 %);
tabelul complet e in docs/asset_briefs/transfagarasan_inventory_f.md.

CORECTURA DE COORDONATOR (kit, capul fisierului; brief §8): masinile NU au voie
sa semene cu Dacia. Pe planșă `parked_car_a` e un Logan, `parked_car_b` un
Sandero/Duster: grila cu bara cromata si sigla, farurile in Y si silueta Logan
NU se modeleaza. Aici: grila = o fanta simpla, farurile = dreptunghiuri, placuta
goala, silueta de masinuta de jucarie (scurta, lata, roti mari, cabina mare).

Axe: X latime, Y lungime (fata spre +Y in Blender = -Z in Godot), Z sus.
Originea pe centrul amprentei, la sol. Un nod = un slot (un material pe atlas).
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("TF_ONLY", "")
hull = _hull          # invelitoare convexa (transfagarasan_shapes)
PAINTED_METAL = PAINTED   # 11, numele din kit §0 (dio_lib il cheama PAINTED)

AO_CAR = dict(samples=20, dist=1.1, gradient="vertical", low=0.62, high=1.0,
              power=0.8, floor=0.40, z_range=(0.0, 1.9))
AO_MOTO = dict(samples=20, dist=0.6, gradient="vertical", low=0.66, high=1.0,
               power=0.8, floor=0.42, z_range=(0.0, 1.3))

CAR_W = 2.20          # latimea carcasei din Car.tscn (car.gd:482), la anvelope/oglinzi
CAR_L = 3.80          # lungimea carcasei din Car.tscn (car.gd:482), la bare


# ---------------------------------------------------------------------------
# caroseria din sectiuni (loft pe Y)
# ---------------------------------------------------------------------------

def _lerp_track(track, y):
    """Interpolare liniara pe o lista sortata de (y, valori...)."""
    if y <= track[0][0]:
        return track[0][1:]
    for a, b in zip(track, track[1:]):
        if a[0] <= y <= b[0]:
            t = (y - a[0]) / (b[0] - a[0]) if b[0] > a[0] else 0.0
            return tuple(va + (vb - va) * t for va, vb in zip(a[1:], b[1:]))
    return track[-1][1:]


def _section(w, z0, zb, zr, wg):
    """Sectiunea (x, z) a caroseriei, inel inchis de 18 puncte (aceeasi
    numerotare la orice statie): 0 = mijlocul talpii, 1..9 partea +X de jos
    pana la mijlocul plafonului, 10..17 partea -X inapoi spre talpa.
      1 muchia talpii   2-4 flancul   5 umarul (linia de centura)
      6 baza serei (centura interioara)   7 sus pe lateralul serei
      8 muchia plafonului   9 mijlocul plafonului (usor bombat)
    Unde nu e sera (capota, portbagaj) zr ~ zb si punctele 6-9 dau capota."""
    h = max(0.10, zb - z0)
    wb = w - 0.13
    gh = max(0.02, zr - zb)
    wg = min(wg, wb - 0.12)
    half = [
        (w - 0.16, z0),
        (w - 0.03, z0 + 0.22 * h),
        (w, z0 + 0.55 * h),
        (w - 0.01, zb - 0.30 * min(h, 0.20)),
        (w - 0.07, zb),
        (wb, zb + 0.02),
        (wg + 0.06, zb + 0.02 + 0.80 * max(0.0, gh - 0.02)),
        (wg - 0.08, zr - 0.01 if gh > 0.05 else zb + 0.035),
        (0.0, (zr + 0.015) if gh > 0.05 else zb + 0.05),
    ]
    ring = [(0.0, z0)] + half + [(-x, z) for (x, z) in reversed(half[:-1])]
    return ring


def car_stations(track, wheels, arch_r, n_arch=9):
    """Statiile loft-ului: cheile din `track` + esantioane dese pe arcadele
    rotilor. `track` = [(y, w, z0, zb, zr, wg)], `wheels` = [(y, z_centru)].
    Talpa (z0) urca pe cercul arcadei deasupra fiecarei roti: din lateral se
    citesc arcadele, iar intre roti talpa trece la inaltimea arcadei (tunel
    peste axa, nevazut din camera)."""
    ys = {round(t[0], 4) for t in track}
    for (yw, zc) in wheels:
        for k in range(n_arch):
            a = math.pi * k / (n_arch - 1)
            ys.add(round(yw + arch_r * math.cos(a), 4))
        ys.add(round(yw + arch_r + 0.012, 4))
        ys.add(round(yw - arch_r - 0.012, 4))
    out = []
    for y in sorted(ys):
        w, z0, zb, zr, wg = _lerp_track(track, y)
        for (yw, zc) in wheels:
            d = y - yw
            if abs(d) <= arch_r + 1e-6:
                z0 = max(z0, zc + math.sqrt(max(0.0, arch_r * arch_r - d * d)))
        out.append((y, w, z0, zb, zr, wg))
    return out


def body_loft(b, stations, slot):
    """Construieste caroseria; intoarce grila P[i][j] (statie, punct de inel)."""
    grid = []
    for (y, w, z0, zb, zr, wg) in stations:
        grid.append([Vector((x, y, z)) for (x, z) in _section(w, z0, zb, zr, wg)])
    ring_stack(b, [[tuple(p) for p in r] for r in grid], slot)
    return grid


def _y_to_u(stations, y):
    ys = [s[0] for s in stations]
    for i in range(len(ys) - 1):
        if ys[i] <= y <= ys[i + 1]:
            return i + (y - ys[i]) / (ys[i + 1] - ys[i])
    return 0.0 if y < ys[0] else float(len(ys) - 1)


def _grid_at(P, u, v):
    n = len(P[0])
    i = max(0, min(len(P) - 2, int(math.floor(u))))
    fu = u - i
    j = int(math.floor(v)) % n
    fv = v - math.floor(v)
    j2 = (j + 1) % n
    a = P[i][j].lerp(P[i][j2], fv)
    c = P[i + 1][j].lerp(P[i + 1][j2], fv)
    return a.lerp(c, fu)


def glass_patch(b, P, stations, y0, y1, v0, v1, slot, out=0.014, inn=0.02, nu=None, nv=4):
    """Geam: o placa SUBTIRE (inchisa) urmand suprafata caroseriei pe petecul
    (y0..y1, v0..v1) din grila, iesita `out` m in afara (memoria val 1: un
    strat lipit coplanar fura culoarea, deci 1,4 cm intre ele) si infipta `inn`
    m inauntru. Normala locala se orienteaza dinspre axa masinii."""
    u0, u1 = _y_to_u(stations, y0), _y_to_u(stations, y1)
    if nu is None:
        nu = max(2, int(abs(u1 - u0)) + 2)
    pts_o, pts_i = [], []
    for a in range(nu + 1):
        u = u0 + (u1 - u0) * a / nu
        row_o, row_i = [], []
        for c in range(nv + 1):
            v = v0 + (v1 - v0) * c / nv
            p = _grid_at(P, u, v)
            du = _grid_at(P, min(u + 0.05, len(P) - 1.001), v) - _grid_at(P, max(u - 0.05, 0.0), v)
            dv = _grid_at(P, u, v + 0.05) - _grid_at(P, u, v - 0.05)
            n = du.cross(dv)
            if n.length < 1e-9:
                n = Vector((0, 0, 1))
            n.normalize()
            axis = Vector((0.0, p.y, 0.9))
            if n.dot(p - axis) < 0:
                n = -n
            row_o.append(b.bm.verts.new(p + n * out))
            row_i.append(b.bm.verts.new(p - n * inn))
        pts_o.append(row_o)
        pts_i.append(row_i)
    faces = []
    for a in range(nu):
        for c in range(nv):
            faces.append(b.bm.faces.new((pts_o[a][c], pts_o[a + 1][c], pts_o[a + 1][c + 1], pts_o[a][c + 1])))
            faces.append(b.bm.faces.new((pts_i[a][c + 1], pts_i[a + 1][c + 1], pts_i[a + 1][c], pts_i[a][c])))
    for a in range(nu):
        for c in (0, nv):
            faces.append(b.bm.faces.new((pts_o[a][c], pts_i[a][c], pts_i[a + 1][c], pts_o[a + 1][c])))
    for c in range(nv):
        for a in (0, nu):
            faces.append(b.bm.faces.new((pts_o[a][c], pts_o[a][c + 1], pts_i[a][c + 1], pts_i[a][c])))
    for f in faces:
        f[b.slot] = slot
    return faces


def wheel_set(tyre, hub, wheels, x_out, radius, width, hub_r, seg=14):
    """4 roti: anvelopa (cilindru, rotunjita de bevel) + janta (disc iesit 1 cm
    pe fata exterioara, cu un capac central)."""
    for (yw, zc) in wheels:
        for sx in (-1.0, 1.0):
            xc = sx * (x_out - width * 0.5)
            tyre.cylinder((xc, yw, zc), radius, width, VOLCANIC_BLACK, segments=seg, axis="X")
            hub.cylinder((sx * (x_out - 0.010), yw, zc), hub_r, 0.040, MARBLE_GREY, segments=10, axis="X")
            hub.cylinder((sx * (x_out + 0.008), yw, zc), hub_r * 0.38, 0.030, MARBLE_GREY, segments=8, axis="X")


def rect(b, center, size, slot, rot_z=0.0, rot_x=0.0):
    rot = Matrix.Rotation(math.radians(rot_z), 3, "Z") @ Matrix.Rotation(math.radians(rot_x), 3, "X")
    b.box(center, size, slot, rotation=rot)


# ---------------------------------------------------------------------------
# parked_car_a
# ---------------------------------------------------------------------------

def build_parked_car_a():
    """Masina parcata A (`parked_car_a`): HATCHBACK MIC GENERIC, CAR_BLUE.

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/parked_car_a.png`,
    scrisa INAINTE de geometrie; unde corectura „nu Dacia” contrazice decuparea,
    lista urmeaza corectura si o spune):
      1) caroseria albastra dintr-o bucata: capota scurta, sera mare, plafon
         drept, hayon aproape vertical. DECUPAREA: sedan Logan cu portbagaj si
         capota lunga -> CORECTURA: hatchback de jucarie (fara portbagaj in trepte),
         capota scurta, roti mari, scurt si lat
      2) 4 roti mari, negre, cu jante argintii (decuparea: 4 roti, jante cu spite;
         aici disc + capac, fara spite: la 30 m nu se vad)
      3) 4 arcade de roata decupate in flanc (decuparea: arcade vizibile)
      4) parbriz mare inclinat, luneta, 2 geamuri laterale pe parte cu stalpul B
         si unul mic in spate (decuparea: 3 geamuri laterale pe parte, rame
         negre) -> 3 pe parte (fata, spate, sfert)
      5) 2 oglinzi pe stalpul A, in culoarea caroseriei (decuparea: 2)
      6) faruri: decuparea are farurile Dacia trase in Y -> CORECTURA: 2
         DREPTUNGHIURI albe simple
      7) grila: decuparea are bara cromata cu sigla -> CORECTURA: O FANTA simpla
         neagra, fara sigla
      8) bara fata si bara spate din plastic gri-inchis (decuparea: bare in
         culoarea caroseriei cu plastic jos) -> plastic ASPHALT, ca rol
      9) placuta alba GOALA fata si spate (decuparea: placuta cu caractere ->
         fara text, regula 9)
     10) 2 stopuri rosii verticale in colturile hayonului
     11) bare de plafon: decuparea are 2 bare subtiri -> NU pe A (sunt semnul
         lui B, ca sa difere ca tip); un eleron mic pe muchia hayonului
     12) praguri negre intre arcade

    Cote: 2,20 x 3,80 m (carcasa din Car.tscn, car.gd:482), ~1,64 m inalt,
    roti R 0,40 (masinile garajului au 0,37-0,41). Noduri (un slot fiecare):
    Car_Body CAR_BLUE 15, Car_Glass VOLCANIC_BLACK 20, Car_Tyre VOLCANIC_BLACK 20,
    Car_Trim ASPHALT 5, Car_Hub MARBLE_GREY 29, Car_Lamp FOAM_WHITE 22,
    Car_Tail KERB_RED 7.
    """
    body, glass, tyre, trim, hub, lamp, tail = (Builder() for _ in range(7))
    E = 1.84                       # capetele caroseriei; barele ies pana la +-1,90
    R, ZC = 0.40, 0.40
    wheels = [(-1.22, ZC), (1.22, ZC)]
    #          y      w     z0    zb    zr    wg
    track = [(-E,    0.97, 0.40, 0.98, 1.00, 0.70),
             (-1.80, 1.02, 0.33, 1.04, 1.26, 0.66),
             (-1.66, 1.04, 0.30, 1.06, 1.50, 0.66),
             (-1.40, 1.04, 0.30, 1.07, 1.60, 0.68),
             (-0.10, 1.04, 0.30, 1.07, 1.62, 0.69),
             (0.15,  1.04, 0.30, 1.07, 1.56, 0.71),
             (0.95,  1.04, 0.30, 1.04, 1.07, 0.76),
             (1.55,  1.02, 0.30, 0.98, 1.00, 0.74),
             (1.78,  0.98, 0.33, 0.92, 0.94, 0.70),
             (E,     0.92, 0.40, 0.85, 0.87, 0.65)]
    st = car_stations(track, wheels, arch_r=0.46)
    P = body_loft(body, st, CAR_BLUE)

    # --- geamurile (placi subtiri pe suprafata serei)
    # v pe inel: 6 = centura, 7 = sus pe lateral, 8 = muchia plafonului,
    # 9 = mijloc; partea -X e oglinda: v' = 18 - v
    glass_patch(glass, P, st, 0.24, 0.90, 7.55, 10.45, VOLCANIC_BLACK, nu=6, nv=6)     # parbriz
    glass_patch(glass, P, st, -1.78, -1.44, 7.55, 10.45, VOLCANIC_BLACK, nu=3, nv=6)   # luneta
    for (y0, y1) in ((-0.40, 0.36), (-1.16, -0.52), (-1.52, -1.28)):
        glass_patch(glass, P, st, y0, y1, 6.18, 7.80, VOLCANIC_BLACK, nu=4, nv=2)
        glass_patch(glass, P, st, y0, y1, 18 - 7.80, 18 - 6.18, VOLCANIC_BLACK, nu=4, nv=2)

    # --- oglinzile (culoarea caroseriei) pe stalpul A
    for sx in (-1.0, 1.0):
        body.box((sx * 1.04, 0.86, 1.10), (0.10, 0.05, 0.05), CAR_BLUE)
        body.box((sx * 1.075, 0.84, 1.13), (0.05, 0.12, 0.10), CAR_BLUE)
    # --- eleronul mic pe muchia hayonului
    body.box((0.0, -1.47, 1.615), (1.04, 0.12, 0.03), CAR_BLUE)

    # --- barele, pragurile, fanta grilei (plastic)
    for sy in (-1.0, 1.0):
        trim.box((0.0, sy * 1.86, 0.47), (1.86, 0.07, 0.20), ASPHALT)
        for sx in (-1.0, 1.0):
            rect(trim, (sx * 0.93, sy * 1.80, 0.47), (0.10, 0.20, 0.20), ASPHALT, rot_z=sx * sy * 30.0)
    trim.box((0.0, E + 0.012, 0.635), (0.82, 0.03, 0.08), ASPHALT)         # fanta grilei
    for sx in (-1.0, 1.0):
        trim.box((sx * 1.035, 0.0, 0.345), (0.04, 1.42, 0.07), ASPHALT)       # pragul

    # --- farurile (dreptunghiuri), placutele GOALE, stopurile
    for sx in (-1.0, 1.0):
        lamp.box((sx * 0.60, E + 0.012, 0.745), (0.32, 0.03, 0.11), FOAM_WHITE)
        tail.box((sx * 0.80, -E - 0.012, 0.88), (0.15, 0.03, 0.26), KERB_RED)
    lamp.box((0.0, 1.888, 0.47), (0.40, 0.02, 0.10), FOAM_WHITE)
    lamp.box((0.0, -1.888, 0.47), (0.40, 0.02, 0.10), FOAM_WHITE)

    wheel_set(tyre, hub, wheels, x_out=1.072, radius=R, width=0.30, hub_r=0.25)

    return [body.to_object("Car_Body"), glass.to_object("Car_Glass"),
            tyre.to_object("Car_Tyre"), trim.to_object("Car_Trim"),
            hub.to_object("Car_Hub"), lamp.to_object("Car_Lamp"),
            tail.to_object("Car_Tail")]


# ---------------------------------------------------------------------------
# parked_car_b
# ---------------------------------------------------------------------------

def build_parked_car_b():
    """Masina parcata B (`parked_car_b`): BREAK / SUV MIC GENERIC, CAR_RED,
    cu bare de plafon si o cutie de 1,2 m pe ele.

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/parked_car_b.png`,
    scrisa INAINTE de geometrie; corectura „nu Dacia” bate decuparea):
      1) caroserie rosie inalta, cu plafon lung si drept pana in spate, stalpul D
         aproape vertical (decuparea: SUV compact Duster -> CORECTURA: silueta
         generica de jucarie, mai lunga +15 % si mai inalta decat A)
      2) 4 roti mari negre cu jante argintii (decuparea: 4, jante cu spite)
      3) 4 arcade cu buza de plastic negru (decuparea: arcade cu plastic gri
         inchis, semn de SUV) -> tub ASPHALT pe arcada
      4) garda la sol mare (decuparea: SUV ridicat)
      5) parbriz, luneta, 3 geamuri laterale pe parte (decuparea: 3)
      6) 2 bare de plafon pe toata lungimea (decuparea: 2, negre)
      7) CUTIE de plafon de 1,2 m pe bare (contract; nu e pe decupare)
      8) faruri: decuparea are farurile Duster -> CORECTURA: 2 dreptunghiuri albe
      9) grila: decuparea are grila Dacia cu sigla -> CORECTURA: o fanta simpla
     10) bare fata/spate de plastic gri-inchis, cu scut jos (decuparea: idem)
     11) placute albe GOALE
     12) 2 oglinzi in culoarea caroseriei (decuparea: 2)
     13) stopuri rosii orizontale in colturile spate
     14) placare de plastic pe partea de jos a usilor (decuparea: banda inchisa)

    Cote: 2,20 x 4,37 m (A + 15 %), ~1,90 m la plafon, ~2,22 m cu cutia; roti
    R 0,45. Noduri ca la A (Car_Body pe CAR_RED 14).
    """
    body, glass, tyre, trim, hub, lamp, tail = (Builder() for _ in range(7))
    E = 2.125                      # barele ies pana la +-2,185 (L = 4,37)
    R, ZC = 0.45, 0.45
    wheels = [(-1.42, ZC), (1.45, ZC)]
    track = [(-E,    0.97, 0.47, 1.10, 1.12, 0.70),
             (-2.08, 1.03, 0.40, 1.16, 1.62, 0.74),
             (-2.00, 1.04, 0.38, 1.18, 1.84, 0.74),
             (-1.82, 1.04, 0.38, 1.18, 1.89, 0.75),
             (0.30,  1.04, 0.38, 1.18, 1.91, 0.75),
             (0.55,  1.04, 0.38, 1.18, 1.83, 0.77),
             (1.12,  1.04, 0.38, 1.16, 1.20, 0.78),
             (1.80,  1.03, 0.38, 1.13, 1.15, 0.77),
             (2.05,  0.99, 0.41, 1.07, 1.09, 0.73),
             (E,     0.94, 0.48, 1.00, 1.02, 0.68)]
    st = car_stations(track, wheels, arch_r=0.53)
    P = body_loft(body, st, CAR_RED)

    glass_patch(glass, P, st, 0.60, 1.08, 7.55, 10.45, VOLCANIC_BLACK, nu=5, nv=6)     # parbriz
    glass_patch(glass, P, st, -2.07, -1.98, 7.45, 10.55, VOLCANIC_BLACK, nu=2, nv=6)   # luneta
    for (y0, y1) in ((-0.36, 0.60), (-1.28, -0.48), (-1.94, -1.40)):
        glass_patch(glass, P, st, y0, y1, 6.18, 7.80, VOLCANIC_BLACK, nu=4, nv=2)
        glass_patch(glass, P, st, y0, y1, 18 - 7.80, 18 - 6.18, VOLCANIC_BLACK, nu=4, nv=2)

    for sx in (-1.0, 1.0):
        body.box((sx * 1.04, 0.98, 1.23), (0.10, 0.05, 0.05), CAR_RED)
        body.box((sx * 1.075, 0.96, 1.26), (0.05, 0.12, 0.11), CAR_RED)

    # --- bare de plafon (2) pe picioruse, cutia de 1,2 m pe ele
    for sx in (-1.0, 1.0):
        x = sx * 0.62
        trim.beam((x, -1.78, 1.97), (x, 0.32, 1.97), (0.05, 0.05), ASPHALT)
        for y in (-1.80, -0.74, 0.34):
            trim.box((x, y, 1.935), (0.06, 0.10, 0.07), ASPHALT)
    trim.box((0.0, -0.78, 2.12), (0.86, 1.20, 0.26), ASPHALT)
    trim.box((0.0, -0.78, 2.005), (0.80, 1.10, 0.04), ASPHALT)

    # --- buza de plastic pe arcade (SUV), placarea de jos, barele, fanta
    for (yw, zc) in wheels:
        for sx in (-1.0, 1.0):
            path = []
            for k in range(11):
                a = math.pi * k / 10.0
                path.append((sx * 1.035, yw + 0.56 * math.cos(a), zc + 0.56 * math.sin(a)))
            trim.sweep(path, 0.045, ASPHALT, segments=6, dome_end=False)
    for sx in (-1.0, 1.0):
        trim.box((sx * 1.035, 0.02, 0.50), (0.045, 1.72, 0.16), ASPHALT)
    for sy in (-1.0, 1.0):
        trim.box((0.0, sy * 2.135, 0.55), (1.88, 0.07, 0.24), ASPHALT)
        trim.box((0.0, sy * 2.10, 0.42), (1.20, 0.10, 0.06), ASPHALT)          # scutul
        for sx in (-1.0, 1.0):
            rect(trim, (sx * 0.93, sy * 2.07, 0.55), (0.10, 0.20, 0.24), ASPHALT, rot_z=sx * sy * 30.0)
    trim.box((0.0, E + 0.012, 0.82), (0.86, 0.03, 0.10), ASPHALT)

    for sx in (-1.0, 1.0):
        lamp.box((sx * 0.64, E + 0.012, 0.92), (0.32, 0.03, 0.12), FOAM_WHITE)
        tail.box((sx * 0.78, -E - 0.012, 0.98), (0.30, 0.03, 0.12), KERB_RED)
    lamp.box((0.0, 2.172, 0.55), (0.40, 0.02, 0.10), FOAM_WHITE)
    lamp.box((0.0, -2.172, 0.55), (0.40, 0.02, 0.10), FOAM_WHITE)

    wheel_set(tyre, hub, wheels, x_out=1.072, radius=R, width=0.32, hub_r=0.27)

    return [body.to_object("Car_Body"), glass.to_object("Car_Glass"),
            tyre.to_object("Car_Tyre"), trim.to_object("Car_Trim"),
            hub.to_object("Car_Hub"), lamp.to_object("Car_Lamp"),
            tail.to_object("Car_Tail")]


# ---------------------------------------------------------------------------
# motorbike
# ---------------------------------------------------------------------------

def build_motorbike():
    """Motocicleta (`motorbike`): TURISM-AVENTURA GENERICA, pe cric lateral,
    inclinata ~10 grade spre stanga (-X), cu 2 genti laterale. Fara sigla.

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/motorbike.png`,
    scrisa INAINTE de geometrie; unde contractul cere altceva decat decuparea
    -- turism-aventura cu genti, pe cric -- urmeaza contractul si o spune):
      1) 2 roti, fata putin mai mare (decuparea: 2 roti egale, jante cu spite)
      2) furca telescopica inclinata ~27 grade (decuparea: tuburi aurii) ->
         metal PAINTED_METAL
      3) aripa fata sus + „cioc” sub far (decuparea: aripa joasa de sport ->
         CONTRACT aventura: cioc)
      4) semicarenaj cu far (1 far dreptunghiular) si parbriz INALT
         (decuparea: semicarenaj de sport-turism, parbriz mediu)
      5) ghidon lat cu 2 aparatori de maini si 2 oglinzi pe tije
      6) rezervor mare albastru cu flancuri care coboara pe laterale
         (decuparea: rezervor albastru, flancuri albastre)
      7) sa neagra in doua trepte, pilot + pasager (decuparea: idem)
      8) coada albastra subtire sub sa + stop rosu (decuparea: idem, fara stop vizibil)
      9) motorul (bloc + chiulasa inclinata), scut sub motor (decuparea: motor
         gri inchis vizibil, fara scut -> CONTRACT aventura: scut)
     10) bascula + amortizor spate (decuparea: idem)
     11) toba pe dreapta, ridicata spre spate (decuparea: toba scurta, dreapta)
     12) 2 GENTI laterale cu rama (CONTRACT; pe decupare nu sunt)
     13) cricul lateral pe stanga, motocicleta sprijinita pe el (CONTRACT)
     14) scarite (2)

    Cote: 2,20 m lung, ~1,30 m inalt dupa inclinare. Noduri (un slot fiecare):
    Moto_Body CAR_BLUE 15, Moto_Metal PAINTED_METAL 11, Moto_Dark VOLCANIC_BLACK 20,
    Moto_Lamp FOAM_WHITE 22 (farul), Moto_Tail KERB_RED 7 (stopul).
    """
    bodyb, metal, dark, lamp, tail = (Builder() for _ in range(5))
    YF, ZF, RF = 0.76, 0.37, 0.37      # roata fata
    YR, ZR, RR = -0.72, 0.35, 0.35     # roata spate

    # 1) roti: anvelopa-tor + janta (disc) + butuc
    for (y, z, r, wt) in ((YF, ZF, RF, 0.065), (YR, ZR, RR, 0.08)):
        dark.torus((0.0, y, z), r - wt, wt, VOLCANIC_BLACK, major_seg=16, minor_seg=6, axis="X")
        # janta: inel metalic subtire + 6 spite + butuc; golul dintre spite e
        # un disc negru retras (se vede roata, nu un capac plin)
        metal.torus((0.0, y, z), r - wt - 0.035, 0.022, PAINTED_METAL, major_seg=16, minor_seg=4, axis="X")
        dark.cylinder((0.0, y, z), r - wt - 0.03, 0.02, VOLCANIC_BLACK, segments=12, axis="X")
        for k in range(6):
            a = math.pi * 2.0 * k / 6.0 + 0.3
            ry_, rz_ = math.cos(a) * (r - wt - 0.04), math.sin(a) * (r - wt - 0.04)
            metal.beam((0.0, y, z), (0.0, y + ry_, z + rz_), (0.05, 0.022), PAINTED_METAL)
        metal.cylinder((0.0, y, z), 0.06, 0.14, PAINTED_METAL, segments=8, axis="X")

    # 2) furca: 2 tuburi de la ax la jugul de sus
    head_lo = Vector((0.0, 0.47, 0.98))
    for sx in (-1.0, 1.0):
        metal.beam((sx * 0.075, YF, ZF), (sx * 0.075, head_lo.y, head_lo.z), 0.07, PAINTED_METAL)
    metal.box((0.0, 0.50, 0.93), (0.22, 0.08, 0.05), PAINTED_METAL)                # jugul
    # 3) aripa fata sus + ciocul sub far
    # aripa joasa peste roata (urmeaza anvelopa) + ciocul (pana sub far)
    hull(bodyb, [(-0.08, YF - 0.20, 0.80), (0.08, YF - 0.20, 0.80), (-0.08, YF + 0.22, 0.79),
                 (0.08, YF + 0.22, 0.79), (-0.07, YF - 0.16, 0.76), (0.07, YF - 0.16, 0.76),
                 (-0.07, YF + 0.20, 0.75), (0.07, YF + 0.20, 0.75), (0.0, YF, 0.82)], CAR_BLUE)
    hull(bodyb, [(-0.11, 0.56, 0.98), (0.11, 0.56, 0.98), (-0.09, 0.58, 0.86), (0.09, 0.58, 0.86),
                 (-0.04, 0.84, 0.86), (0.04, 0.84, 0.86), (0.0, 0.82, 0.90)], CAR_BLUE)
    # 4) semicarenajul (cu flancuri) + farul + parbrizul inalt
    hull(bodyb, [(-0.22, 0.42, 0.90), (0.22, 0.42, 0.90), (-0.24, 0.40, 1.08), (0.24, 0.40, 1.08),
                 (-0.15, 0.62, 0.94), (0.15, 0.62, 0.94), (-0.14, 0.60, 1.10), (0.14, 0.60, 1.10),
                 (-0.10, 0.50, 1.18), (0.10, 0.50, 1.18), (0.0, 0.66, 1.02)], CAR_BLUE)
    rect(lamp, (0.0, 0.638, 1.03), (0.20, 0.03, 0.09), FOAM_WHITE, rot_x=-14.0)
    rect(metal, (0.0, 0.48, 1.20), (0.34, 0.012, 0.26), PAINTED_METAL, rot_x=-24.0)   # parbriz
    # 5) ghidon, aparatori, oglinzi
    dark.beam((-0.40, 0.36, 1.12), (0.40, 0.36, 1.12), 0.035, VOLCANIC_BLACK)
    dark.box((0.0, 0.40, 1.05), (0.06, 0.06, 0.14), VOLCANIC_BLACK)
    for sx in (-1.0, 1.0):
        hull(bodyb, [(sx * 0.34, 0.40, 1.08), (sx * 0.44, 0.40, 1.08), (sx * 0.34, 0.44, 1.16),
                     (sx * 0.44, 0.44, 1.16), (sx * 0.39, 0.47, 1.12), (sx * 0.36, 0.38, 1.14)], CAR_BLUE)
        dark.beam((sx * 0.28, 0.37, 1.13), (sx * 0.33, 0.39, 1.24), 0.018, VOLCANIC_BLACK)
        dark.box((sx * 0.35, 0.39, 1.26), (0.12, 0.025, 0.07), VOLCANIC_BLACK)
    # 6) rezervorul cu flancuri
    hull(bodyb, [(-0.20, 0.42, 1.04), (0.20, 0.42, 1.04), (-0.17, 0.02, 0.98), (0.17, 0.02, 0.98),
                 (-0.24, 0.40, 0.78), (0.24, 0.40, 0.78), (-0.20, 0.10, 0.74), (0.20, 0.10, 0.74),
                 (-0.13, 0.30, 1.10), (0.13, 0.30, 1.10), (0.0, 0.06, 1.03)], CAR_BLUE)
    # 7) saua in doua trepte
    hull(dark, [(-0.16, 0.04, 0.92), (0.16, 0.04, 0.92), (-0.15, -0.38, 0.88), (0.15, -0.38, 0.88),
                (-0.13, 0.00, 1.00), (0.13, 0.00, 1.00), (-0.13, -0.36, 0.96), (0.13, -0.36, 0.96)],
         VOLCANIC_BLACK)
    hull(dark, [(-0.14, -0.36, 0.92), (0.14, -0.36, 0.92), (-0.12, -0.72, 0.94), (0.12, -0.72, 0.94),
                (-0.12, -0.38, 1.04), (0.12, -0.38, 1.04), (-0.10, -0.70, 1.02), (0.10, -0.70, 1.02)],
         VOLCANIC_BLACK)
    # 8) coada sub sa + stopul
    hull(bodyb, [(-0.15, -0.30, 0.78), (0.15, -0.30, 0.78), (-0.10, -0.90, 0.86), (0.10, -0.90, 0.86),
                 (-0.13, -0.32, 0.92), (0.13, -0.32, 0.92), (-0.08, -0.92, 0.94), (0.08, -0.92, 0.94)],
         CAR_BLUE)
    tail.box((0.0, -0.93, 0.89), (0.12, 0.03, 0.05), KERB_RED)
    # capacele laterale sub sa: umplu golul dintre rezervor si coada (decuparea:
    # flancul albastru continuu de la rezervor la coada)
    hull(bodyb, [(-0.15, 0.06, 0.66), (0.15, 0.06, 0.66), (-0.14, -0.34, 0.74), (0.14, -0.34, 0.74),
                 (-0.16, 0.06, 0.90), (0.16, 0.06, 0.90), (-0.14, -0.36, 0.88), (0.14, -0.36, 0.88)],
         CAR_BLUE)
    # 9) motorul: bloc, chiulasa inclinata in fata, scutul
    dark.box((0.0, 0.08, 0.50), (0.34, 0.40, 0.30), VOLCANIC_BLACK)                # carterul
    rect(metal, (0.0, 0.24, 0.70), (0.30, 0.18, 0.24), PAINTED_METAL, rot_x=-25.0)   # chiulasa
    dark.box((0.0, -0.12, 0.56), (0.30, 0.12, 0.22), VOLCANIC_BLACK)                # cutia
    hull(metal, [(-0.18, 0.34, 0.40), (0.18, 0.34, 0.40), (-0.18, -0.10, 0.27), (0.18, -0.10, 0.27),
                 (-0.16, 0.38, 0.30), (0.16, 0.38, 0.30), (-0.16, -0.12, 0.33), (0.16, -0.12, 0.33)],
         PAINTED_METAL)
    # cadrul: tub de la jug la pivotul basculei, pe ambele parti
    for sx in (-1.0, 1.0):
        dark.beam((sx * 0.09, 0.46, 0.96), (sx * 0.12, -0.10, 0.80), 0.045, VOLCANIC_BLACK)
        dark.beam((sx * 0.12, -0.10, 0.80), (sx * 0.12, -0.20, 0.48), 0.045, VOLCANIC_BLACK)
    # 10) bascula + amortizorul
    for sx in (-1.0, 1.0):
        metal.beam((sx * 0.10, -0.20, 0.47), (sx * 0.10, YR, ZR), (0.04, 0.07), PAINTED_METAL)
    dark.beam((0.0, -0.22, 0.86), (0.0, -0.42, 0.50), 0.05, VOLCANIC_BLACK)
    # 11) toba pe dreapta, ridicata spre spate (+ colectorul)
    metal.beam((0.10, 0.30, 0.42), (0.18, -0.20, 0.42), 0.05, PAINTED_METAL)
    metal.beam((0.19, -0.26, 0.50), (0.19, -0.62, 0.70), 0.11, PAINTED_METAL)
    # 12) gentile laterale cu rama si capac
    for sx in (-1.0, 1.0):
        metal.box((sx * 0.33, -0.66, 0.68), (0.20, 0.48, 0.36), PAINTED_METAL)
        dark.box((sx * 0.33, -0.66, 0.875), (0.215, 0.50, 0.05), VOLCANIC_BLACK)
        dark.beam((sx * 0.22, -0.38, 0.48), (sx * 0.22, -0.92, 0.48), 0.03, VOLCANIC_BLACK)
        dark.beam((sx * 0.22, -0.40, 0.48), (sx * 0.14, -0.40, 0.86), 0.03, VOLCANIC_BLACK)
    # 14) scaritele
    for sx in (-1.0, 1.0):
        dark.box((sx * 0.18, -0.06, 0.36), (0.12, 0.05, 0.04), VOLCANIC_BLACK)

    objs = [bodyb.to_object("Moto_Body"), metal.to_object("Moto_Metal"),
            dark.to_object("Moto_Dark"), lamp.to_object("Moto_Lamp"),
            tail.to_object("Moto_Tail")]

    # 13) inclinarea pe cric: totul se roteste in jurul liniei de contact a
    # rotilor (axa Y, z = 0) cu ~10 grade spre -X; apoi cricul, din lume.
    lean = Matrix.Rotation(math.radians(-10.0), 4, "Y")
    for o in objs:
        o.data.transform(lean)
        o.data.update()
    pivot = lean @ Vector((-0.14, -0.10, 0.38))
    foot = Vector((pivot.x - 0.30, pivot.y + 0.10, 0.012))
    stand = Builder()
    stand.beam(tuple(pivot), tuple(foot), 0.03, PAINTED_METAL)
    stand.box((foot.x, foot.y, 0.012), (0.07, 0.09, 0.024), PAINTED_METAL)
    so = stand.to_object("Moto_Stand")
    # cricul e metal: intra in nodul Moto_Metal (un slot), nu nod separat
    bpy.ops.object.select_all(action="DESELECT")
    objs[1].select_set(True)
    so.select_set(True)
    bpy.context.view_layer.objects.active = objs[1]
    bpy.ops.object.join()
    return objs


# ---------------------------------------------------------------------------

def _emit(objs, path, ao, bevels=None, smooth=50.0):
    emit_tf(objs, path, ao, keep_xy=True, bevel=0.0, bevels=bevels, smooth_angle=smooth)
    clear_built()


clear_built()
if not ONLY or ONLY == "parked_car_a":
    _emit(build_parked_car_a(), "vehicles/parked_car_a.glb", AO_CAR,
          bevels={"_Trim": 0.02, "_Tyre": 0.05, "_Hub": 0.008, "_Lamp": 0.008, "_Tail": 0.008})
if not ONLY or ONLY == "parked_car_b":
    _emit(build_parked_car_b(), "vehicles/parked_car_b.glb", AO_CAR,
          bevels={"_Trim": 0.02, "_Tyre": 0.05, "_Hub": 0.008, "_Lamp": 0.008, "_Tail": 0.008})
if not ONLY or ONLY == "motorbike":
    _emit(build_motorbike(), "vehicles/motorbike.glb", AO_MOTO,
          bevels={"_Body": 0.0, "_Metal": 0.006, "_Dark": 0.006}, smooth=40.0)
report_tf()

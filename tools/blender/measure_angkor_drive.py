"""Garda templului prin care se trece (Track24, B): `angkor/structures/angkor_wat_drive.glb`
fata de carcasa de coliziune exportata din joc (`tools/data/angkor_temple_shell.json`).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- measure_angkor_drive.py [-- --sabotaj=<nume> | --selftest]

Citeste GLB-ul EXPORTAT (importorul glTF il intoarce in cadrul hartii: X est, Y nord, Z sus) si
refaxe tubul INDEPENDENT de scriptul de build (sectiunile ca `track.gd::_build_tunnel`), apoi
verifica ca peretii refacuti cad pe varfurile carcasei din JSON. Un rand per verificare, apoi
`MASURA TEMPLU: OK` / `PICAT`.

  a  varfuri    turnul central: varful la z 36 +-0,5, la < 1 m de (0, 0); colturile la 30 +-0,5
  b  culoar     NIMIC intre peretii de coliziune, de la asfalt la tavan, pe tot tubul (capac la
                capac): niciun varf si niciun triunghi (raze laterale si verticale la 0,25 m);
                in afara portalurilor, nimic intre aripi pana la 10 m, pe 20 m (plus rama)
  c  perete     raze din axa spre perete la fiecare 1 m, la 0,3 / 1,5 / 3 / 6 m: nicio lovitura
                in fata planului (> 2 cm), iar la 0,3 m (soclul) lovitura OBLIGATORIE la 0..1,8 m
                in spatele lui; la celelalte cote se raporteaza acoperirea (golurile = ferestre)
  d  tavan      raze in sus din axa si de la 2 m de fiecare perete, la fiecare 1 m: lovesc
                geometrie la sau peste tavanul de coliziune (fara cer)
  e  portaluri  golul vizual = rama de coliziune (montantii la 0 .. 0,15 m in spatele ei, buiandrugul
                la 0 .. 0,3 m peste ea, niciodata mai ingust/jos); fatada pe planul capacului +-0,1
  f  amprenta   masivul la +-52 (+-0,15); turnurile de colt la < 1 m de (+-26, +-26)

`--sabotaj=<varfuri|culoar|perete|tavan|portal|amprenta>` strica o copie in memorie astfel incat
EXACT verificarea respectiva sa pice; `--selftest` le ruleaza pe toate si cere ca fiecare sabotaj
sa pice doar garda lui (regula casei: o garda e crezuta abia dupa ce sabotajul ei pica).
"""

import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
GLB = os.path.join(ROOT, "assets", "models", "angkor", "structures", "angkor_wat_drive.glb")
SHELL = os.path.join(ROOT, "tools", "data", "angkor_temple_shell.json")

TOL = 0.02
CHECKS = ["varfuri", "culoar", "perete", "tavan", "portal", "amprenta"]
LETTER = dict(zip(CHECKS, "abcdef"))


# --- tubul, refacut din JSON ------------------------------------------------------------

class Tube:
    def __init__(self, d):
        road, tube = d["road"], d["tube"]
        i0 = [k for k, r in enumerate(road) if abs(r["m"]) < 1e-6][0]
        acc, j = 0.0, i0
        while acc < tube["length"]:
            acc += (Vector(road[j + 1]["p"]) - Vector(road[j]["p"])).length
            j += 1
        iw = j
        P = [Vector(r["p"]) for r in road]
        S = [Vector((r["side"][0], r["side"][1], 0.0)) for r in road]
        te = (P[i0 + 1] - P[i0]).normalized()
        tw = (P[iw] - P[iw - 1]).normalized()
        c, s, w, m = [P[i0] - te * 0.3], [S[i0]], [road[i0]["hw"]], [road[i0]["m"] - 0.3]
        for k in range(i0, iw):
            c.append((P[k] + P[k + 1]) * 0.5)
            s.append(S[k])
            w.append((road[k]["hw"] + road[k + 1]["hw"]) * 0.5)
            m.append((road[k]["m"] + road[k + 1]["m"]) * 0.5)
        c.append(P[iw] + tw * 0.3)
        s.append(S[iw - 1])
        w.append(road[iw]["hw"])
        m.append(road[iw]["m"] + 0.3)
        hw0 = tube["half_width"]
        w = [max(hw0, x) for x in w]
        hmax = max(w)
        self.ceil = [tube["ceiling"] + (tube["hall_ceiling"] - tube["ceiling"]) *
                     min(max((x - hw0) / (hmax - hw0), 0.0), 1.0) for x in w]
        self.c, self.s, self.w, self.m = c, s, w, m
        self.n = len(c)
        self.hw0 = hw0
        self.road = road
        self.cap_out = [(c[0] - c[1]).normalized(), (c[-1] - c[-2]).normalized()]
        for v in self.cap_out:
            v.z = 0.0
            v.normalize()
        self.np_c = np.array([[p.x, p.y] for p in c])
        self.np_s = np.array([[p.x, p.y] for p in s])
        self.np_w = np.array(w)
        self.np_m = np.array(m)

    def seg(self, m):
        k = 0
        while k < self.n - 2 and self.m[k + 1] < m:
            k += 1
        return k, (m - self.m[k]) / (self.m[k + 1] - self.m[k])

    def P(self, m, side, e, h, f=1.0):
        k, t = self.seg(m)
        a = self.c[k] + self.s[k] * (side * f * (self.w[k] + e))
        b = self.c[k + 1] + self.s[k + 1] * (side * f * (self.w[k + 1] + e))
        p = a + (b - a) * t
        return Vector((p.x, p.y, p.z + h))

    def C(self, m):
        k, t = self.seg(m)
        return self.ceil[k] + (self.ceil[k + 1] - self.ceil[k]) * t

    def W(self, m):
        k, t = self.seg(m)
        return self.w[k] + (self.w[k + 1] - self.w[k]) * t

    def locate_np(self, xy):
        """(m, e) pentru N puncte; m = nan dincolo de capace."""
        a = self.np_c[:-1][None, :, :]
        b = self.np_c[1:][None, :, :]
        d = b - a
        p = xy[:, None, :]
        ll = (d ** 2).sum(-1)
        traw = ((p - a) * d).sum(-1) / ll
        t = np.clip(traw, 0.0, 1.0)
        q = a + d * t[..., None]
        d2 = ((p - q) ** 2).sum(-1)
        k = d2.argmin(1)
        idx = np.arange(len(xy))
        tk, trk = t[idx, k], traw[idx, k]
        m = self.np_m[k] + (self.np_m[k + 1] - self.np_m[k]) * tk
        s = self.np_s[k] + (self.np_s[k + 1] - self.np_s[k]) * tk[:, None]
        s /= np.linalg.norm(s, axis=1)[:, None]
        qk = q[idx, k]
        L = ((xy - qk) * s).sum(1)
        w = self.np_w[k] + (self.np_w[k + 1] - self.np_w[k]) * tk
        out = (k == 0) & (trk < 0.0) | (k == self.n - 2) & (trk > 1.0)
        m = np.where(out, np.nan, m)
        return m, np.abs(L) - w, L

    def C_np(self, m):
        return np.interp(m, self.np_m, np.array(self.ceil))


# --- geometria ------------------------------------------------------------------------

def load(path):
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=path)
    bpy.context.view_layer.update()
    nodes = {}
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        me = o.data
        me.calc_loop_triangles()
        mw = o.matrix_world
        vs = np.array([tuple(mw @ v.co) for v in me.vertices])
        tr = np.array([tuple(lt.vertices) for lt in me.loop_triangles], dtype=np.int64)
        name = o.name.split(".")[0]
        nodes[name] = (vs, tr)
    return nodes


def merged(nodes):
    vs, tr, off = [], [], 0
    for name in sorted(nodes):
        v, t = nodes[name]
        vs.append(v)
        tr.append(t + off)
        off += len(v)
    return np.concatenate(vs), np.concatenate(tr)


def bvh_of(V, F):
    return BVHTree.FromPolygons([Vector(p) for p in V], [tuple(int(i) for i in f) for f in F],
                                all_triangles=True)


# --- sabotajele (pe copia din memorie) -----------------------------------------------------

def sabotage(name, nodes, T):
    nodes = {k: (v.copy(), t.copy()) for k, (v, t) in nodes.items()}
    st = "TempleDrive_Stone"
    v, t = nodes[st]
    if name == "varfuri":
        sel = (np.hypot(v[:, 0], v[:, 1]) < 8.0) & (v[:, 2] > 31.0)
        v[sel, 2] += 2.0
    elif name == "culoar":
        # un bolovan de 0,6 m in sala, intre razele garzii de tavan (m intreg, axa, +-(w - 2))
        c = T.P(45.5, 1, 0.0, 2.0, 1.0 / T.W(45.5))
        box = np.array([[c.x + dx, c.y + dy, c.z + dz] for dx in (-0.3, 0.3) for dy in (-0.3, 0.3)
                        for dz in (0.0, 0.6)])
        quads = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
        tris = []
        for (a, b, cc, d) in quads:
            tris += [(a, b, cc), (a, cc, d)]
        n0 = len(v)
        v = np.concatenate([v, box])
        t = np.concatenate([t, np.array(tris) + n0])
    elif name in ("perete", "tavan"):
        cen = v[t].mean(1)
        m, e, L = T.locate_np(cen[:, :2])
        h = cen[:, 2] - 4.0
        if name == "perete":
            kill = (m > 40.0) & (m < 45.0) & (L > 0) & (e > -0.1) & (e < 2.4) & (h < 1.0)
        else:
            kill = (m > 20.0) & (m < 24.0) & (e < 0.5) & (h > T.C_np(np.nan_to_num(m)))
        kill &= ~np.isnan(m)
        t = t[~kill]
        # aceeasi gaura in TOATE nodurile (lichen, dare)
        for k2 in list(nodes):
            if k2 == st:
                continue
            v2, t2 = nodes[k2]
            if len(t2) == 0:
                continue
            c2 = v2[t2].mean(1)
            m2, e2, L2 = T.locate_np(c2[:, :2])
            h2 = c2[:, 2] - 4.0
            if name == "perete":
                k_ = (m2 > 40.0) & (m2 < 45.0) & (L2 > 0) & (e2 > -0.1) & (e2 < 2.4) & (h2 < 1.0)
            else:
                k_ = (m2 > 20.0) & (m2 < 24.0) & (e2 < 0.5) & (h2 > T.C_np(np.nan_to_num(m2)))
            nodes[k2] = (v2, t2[~(k_ & ~np.isnan(m2))])
    elif name == "portal":
        sel = (v[:, 0] > -52.95) & (v[:, 0] < -51.55) & (np.abs(v[:, 1]) > 5.95) & \
              (np.abs(v[:, 1]) < 6.9) & (v[:, 2] < 14.05)
        v[sel, 1] += np.sign(v[sel, 1]) * 0.3
    elif name == "amprenta":
        sel = (v[:, 0] > 18.0) & (v[:, 1] < -18.0) & (v[:, 2] > 12.5)
        v[sel, 0] += 2.0
    nodes[st] = (v, t)
    return nodes


# --- verificarile ---------------------------------------------------------------------------

def check_tips(V, say):
    ok = True
    r = np.hypot(V[:, 0], V[:, 1])
    sel = r < 8.0
    i = np.argmax(np.where(sel, V[:, 2], -1e9))
    p = V[i]
    good = abs(p[2] - 36.0) <= 0.5 and math.hypot(p[0], p[1]) <= 1.0
    say("   turnul central: varf z %.3f (36 +-0,5) la (%.2f, %.2f)" % (p[2], p[0], p[1]))
    ok &= good
    tips = {}
    for sx in (-1, 1):
        for sy in (-1, 1):
            sel = np.hypot(V[:, 0] - sx * 26.0, V[:, 1] - sy * 26.0) < 7.0
            i = np.argmax(np.where(sel, V[:, 2], -1e9))
            p = V[i]
            tips[(sx, sy)] = p
            g = abs(p[2] - 30.0) <= 0.5
            say("   colt (%+d,%+d): varf z %.3f (30 +-0,5)" % (sx * 26, sy * 26, p[2]))
            ok &= g
    return ok, tips


def corridor_vertices(V, T):
    sel = (V[:, 2] > 4.0 + TOL) & (V[:, 2] < 4.0 + 15.0) & (V[:, 0] > -60) & (V[:, 0] < 15) & \
          (V[:, 1] > -15) & (V[:, 1] < 60)
    idx = np.nonzero(sel)[0]
    if len(idx) == 0:
        return []
    m, e, _ = T.locate_np(V[idx, :2])
    h = V[idx, 2] - 4.0
    bad = (~np.isnan(m)) & (m > T.m[0] + TOL) & (m < T.m[-1] - TOL) & (e < -TOL) &           (h < T.C_np(np.nan_to_num(m)) - TOL)
    return idx[bad]


def check_corridor(bvh, V, T, say):
    ok = True
    bad_v = corridor_vertices(V, T)
    say("   varfuri in culoar: %d" % len(bad_v))
    if len(bad_v):
        for i in bad_v[:5]:
            say("      ex. (%.2f, %.2f, %.2f)" % tuple(V[i]))
    ok &= len(bad_v) == 0
    hits = []
    m = T.m[0] + TOL           # capacele insesi: rama sta lipita de ele (contact, nu intrare)
    nr = 0
    while m <= T.m[-1] - TOL + 1e-6:
        C = T.C(m)
        for h in (0.05, 0.3, 0.8, 1.5, 3.0, 4.5, 6.0, 7.5, 9.0, 10.5, 12.0, 13.5, C - 0.05):
            if h > C - TOL:
                continue
            a, b = T.P(m, -1, -TOL, h), T.P(m, 1, -TOL, h)
            d = b - a
            r = bvh.ray_cast(a, d.normalized(), d.length)
            nr += 1
            if r[0] is not None:
                hits.append(("lateral", m, h, tuple(r[0])))
        W = T.W(m)
        L = -W + TOL
        while L <= W - TOL:
            a = T.P(m, 1, 0.0, TOL, L / W) if L >= 0 else T.P(m, -1, 0.0, TOL, -L / W)
            r = bvh.ray_cast(a, Vector((0, 0, 1)), C - 2 * TOL)
            nr += 1
            if r[0] is not None:
                hits.append(("vertical", m, L, tuple(r[0])))
            L += 0.5
        m = min(m + 0.25, T.m[-1] - TOL) if m < T.m[-1] - TOL - 1e-6 else m + 1.0
    say("   raze in tub: %d, lovituri: %d" % (nr, len(hits)))
    for h_ in hits[:5]:
        say("      ex. %s m %.2f %.2f -> (%.2f, %.2f, %.2f)" % (h_[0], h_[1], h_[2], *h_[3]))
    ok &= not hits
    # in afara portalurilor: rama (1,2 m) + 20 m intre aripi, pana la 10 m
    out_hits, out_v = 0, 0
    ex_out = []
    for end in (0, 1):
        c = T.c[0] if end == 0 else T.c[-1]
        s = T.s[0] if end == 0 else T.s[-1]
        o = T.cap_out[end]
        d = 0.0
        while d <= 21.2:
            half = T.hw0 if d < 1.2 else T.hw0 + 3.5 * min(d - 1.2, 14.0) / 14.0
            base = c + o * d
            # cota soselei: punctul copt cel mai apropiat
            rz = min(T.road, key=lambda r: (r["p"][0] - base.x) ** 2 + (r["p"][1] - base.y) ** 2)["p"][2]
            for h in (0.05, 0.3, 1.0, 2.0, 4.0, 6.0, 8.0, 9.95):
                a = Vector((base.x, base.y, rz + h)) - s * (half - TOL)
                b = Vector((base.x, base.y, rz + h)) + s * (half - TOL)
                r = bvh.ray_cast(a, (b - a).normalized(), (b - a).length)
                if r[0] is not None:
                    out_hits += 1
                    ex_out.append(tuple(r[0]))
            L = -half + TOL
            while L <= half - TOL:
                a = Vector((base.x, base.y, rz + TOL)) + s * L
                r = bvh.ray_cast(a, Vector((0, 0, 1)), 10.0 - 2 * TOL)
                if r[0] is not None:
                    out_hits += 1
                    ex_out.append(tuple(r[0]))
                L += 0.5
            d += 0.25
    # varfuri in zona din fata portalurilor
    for end in (0, 1):
        c = T.c[0] if end == 0 else T.c[-1]
        s = T.s[0] if end == 0 else T.s[-1]
        o = T.cap_out[end]
        rel = V - np.array([c.x, c.y, 0.0])
        d = rel[:, 0] * o.x + rel[:, 1] * o.y
        L = rel[:, 0] * s.x + rel[:, 1] * s.y
        half = np.where(d < 1.2, T.hw0, T.hw0 + 3.5 * np.clip(d - 1.2, 0, 14.0) / 14.0)
        # (cota soselei 4,0 la capac, ~3,9 la 21 m: razele de mai sus folosesc cota locala)
        sel = (d > 0.0) & (d < 21.2) & (np.abs(L) < half - TOL) & (V[:, 2] > 4.0 + TOL) & \
              (V[:, 2] < 4.0 + 10.0 - TOL)
        out_v += int(sel.sum())
        ex_out += [tuple(p) for p in V[sel][:3]]
    say("   in afara portalurilor: lovituri %d, varfuri %d" % (out_hits, out_v))
    for p in ex_out[:6]:
        say("      ex. (%.2f, %.2f, %.2f)" % p)
    ok &= out_hits == 0 and out_v == 0
    return ok


def check_walls(bvh, T, say):
    ok = True
    stats = {}
    front = []
    miss03 = []
    m = math.ceil(T.m[0])
    while m <= T.m[-1] + 1e-6:
        for side in (-1, 1):
            for h in (0.3, 1.5, 3.0, 6.0):
                o = T.P(m, side, 0.0, h, 0.0)
                w = T.P(m, side, 0.0, h)
                dv = w - o
                dl = dv.length
                r = bvh.ray_cast(o, dv.normalized(), dl + 1.8 + 3.0)
                st = stats.setdefault(h, [0, 0, 0])
                st[0] += 1
                if r[0] is None:
                    st[2] += 1
                    if h == 0.3:
                        miss03.append((m, side, None))
                    continue
                e = r[3] - dl
                if e < -TOL:
                    front.append((m, side, h, e))
                elif e <= 1.8:
                    st[1] += 1
                else:
                    st[2] += 1
                    if h == 0.3:
                        miss03.append((m, side, e))
        m += 1.0
    for h in sorted(stats):
        n, good, far = stats[h]
        say("   la %.1f m: %d raze, %d pe perete (0..1,8 m in spate), %d goluri/departe" % (h, n, good, far))
    say("   lovituri in fata planului: %d; goluri la 0,3 m: %d" % (len(front), len(miss03)))
    for f_ in front[:4]:
        say("      in fata: m %.1f side %+d h %.1f e %.3f" % f_)
    for f_ in miss03[:4]:
        say("      gol la 0,3: m %.1f side %+d e %s" % (f_[0], f_[1], f_[2]))
    ok &= not front and not miss03
    return ok


def check_ceiling(bvh, T, say):
    bad = []
    m = math.ceil(T.m[0])
    n = 0
    while m <= T.m[-1] + 1e-6:
        C = T.C(m)
        for (side, e, f) in ((0, 0.0, 0.0), (-1, -2.0, 1.0), (1, -2.0, 1.0)):
            o = T.P(m, side, e, 0.5, f)
            r = bvh.ray_cast(o, Vector((0, 0, 1)), 80.0)
            n += 1
            if r[0] is None:
                bad.append((m, side, None))
            elif r[0].z - 4.0 < C - TOL:
                bad.append((m, side, r[0].z - 4.0))
        m += 1.0
    say("   raze in sus: %d, fara acoperis sau sub tavan: %d" % (n, len(bad)))
    for b in bad[:5]:
        say("      m %.1f side %+d -> %s" % (b[0], b[1], "cer" if b[2] is None else "%.2f m" % b[2]))
    return not bad


def frame_of_json(d, T, end):
    """Rama de coliziune: semilatimea interioara si inaltimea golului, din triunghiurile `portal`."""
    c = T.c[0] if end == 0 else T.c[-1]
    s = T.s[0] if end == 0 else T.s[-1]
    o = T.cap_out[end]
    pts = d["portal"]
    lat, top = [], []
    for p in pts:
        rel = Vector(p) - c
        dd = rel.x * o.x + rel.y * o.y
        if -0.05 < dd < 1.25:
            L = abs(rel.x * s.x + rel.y * s.y)
            lat.append(L)
            top.append(p[2] - c.z)
    half = min(lat)
    height = min(z for z, L in zip(top, lat) if L < half + 0.01 and z > 5.0)
    return half, height


def check_portals(bvh, T, d, say):
    ok = True
    for end, name in ((0, "vest"), (1, "nord")):
        c = T.c[0] if end == 0 else T.c[-1]
        s = T.s[0] if end == 0 else T.s[-1]
        o = T.cap_out[end]
        half, height = frame_of_json(d, T, end)
        road_rule = max(T.hw0, T.w[0] if end == 0 else T.w[-1]) + 0.15
        mid = c + o * 0.6
        lat = []
        for h in (0.3, 2.0, 5.0, 8.0, 9.5):
            for sg in (-1, 1):
                a = Vector((mid.x, mid.y, c.z + h))
                r = bvh.ray_cast(a, s * sg, 12.0)
                lat.append(r[3] if r[0] is not None else 99.0)
        hts = []
        for L in (-5.0, -2.5, 0.0, 2.5, 5.0):
            a = Vector((mid.x, mid.y, c.z + 0.3)) + s * L
            r = bvh.ray_cast(a, Vector((0, 0, 1)), 30.0)
            hts.append((r[0].z - c.z) if r[0] is not None else 99.0)
        g_w = all(half - TOL <= x <= half + 0.15 for x in lat)
        g_h = all(height - TOL <= x <= height + 0.3 for x in hts)
        # fatada: raze din afara spre capac, langa rama
        plane = []
        for Lf in (-10.6, -11.2, 10.6, 11.2):
            for h in (2.0, 3.0):
                a = c + o * 6.0 + s * Lf + Vector((0, 0, h))
                r = bvh.ray_cast(a, -o, 12.0)
                plane.append((6.0 - r[3]) if r[0] is not None else 99.0)
        g_p = all(-0.1 <= x <= 0.1 for x in plane)
        say("   %s: rama de coliziune %.2f x %.2f; gol vizual lat %.2f..%.2f (semilatimi), "
            "inalt %.2f..%.2f; fatada %+.3f..%+.3f m de capac" %
            (name, 2 * half, height, min(lat), max(lat), min(hts), max(hts), min(plane), max(plane)))
        if 2 * road_rule > 2 * half + 1e-3:
            say("   NOTA %s: regula din brief (soseaua + 0,3 = %.2f m) cere mai mult decat rama de "
                "coliziune (%.2f m); golul vizual urmeaza rama (altfel ar fi perete invizibil)" %
                (name, 2 * road_rule, 2 * half))
        ok &= g_w and g_h and g_p
    return ok


def check_footprint(V, tips, say):
    low = V[V[:, 2] < 3.05]
    ext = []
    for ax in (0, 1):
        other = 1 - ax
        main = low[np.abs(low[:, other]) > 13.5]
        ext += [main[:, ax].max(), -main[:, ax].min()]
    g = all(abs(x - 52.0) <= 0.15 for x in ext)
    say("   masivul: +x %.2f -x %.2f +y %.2f -y %.2f (52 +-0,15)" % (ext[0], ext[1], ext[2], ext[3]))
    gt = True
    for (sx, sy), p in tips.items():
        dd = math.hypot(p[0] - sx * 26.0, p[1] - sy * 26.0)
        say("   turn (%+d,%+d): varful la %.2f m de axa ceruta" % (sx * 26, sy * 26, dd))
        gt &= dd <= 1.0
    return g and gt


def run(nodes, T, d, verbose=True):
    lines = []
    say = (lambda s: (print(s), lines.append(s))) if verbose else (lambda s: lines.append(s))
    V, F = merged(nodes)
    bvh = bvh_of(V, F)
    res = {}
    say("a. varfuri")
    res["varfuri"], tips = check_tips(V, say)
    say("b. culoar")
    res["culoar"] = check_corridor(bvh, V, T, say)
    say("c. perete")
    res["perete"] = check_walls(bvh, T, say)
    say("d. tavan")
    res["tavan"] = check_ceiling(bvh, T, say)
    say("e. portaluri")
    res["portal"] = check_portals(bvh, T, d, say)
    say("f. amprenta")
    res["amprenta"] = check_footprint(V, tips, say)
    for k in CHECKS:
        say("%s. %-9s %s" % (LETTER[k], k, "OK" if res[k] else "PICAT"))
    return res


def main():
    args = sys.argv[1:]
    sab = None
    selftest = "--selftest" in args
    for a in args:
        if a.startswith("--sabotaj="):
            sab = a.split("=", 1)[1]
    d = json.load(open(SHELL))
    T = Tube(d)
    # garda pe garda: peretii refacuti cad pe varfurile carcasei
    bore = np.array(d["bore"])
    hit = 0
    for k in range(T.n):
        for sg in (-1, 1):
            for z in (T.c[k].z - 0.5, T.c[k].z + T.ceil[k]):
                p = T.c[k] + T.s[k] * (sg * T.w[k])
                hit += int((np.abs(bore - np.array([p.x, p.y, z])).max(1) < 0.02).any())
    print("tub refacut: %d sectiuni, m %.2f .. %.2f; %d/%d varfuri de perete pe carcasa" %
          (T.n, T.m[0], T.m[-1], hit, 4 * T.n))
    if hit != 4 * T.n:
        print("MASURA TEMPLU: PICAT (tubul refacut nu se potriveste cu carcasa)")
        sys.exit(1)
    nodes = load(GLB)
    for name in sorted(nodes):
        print("noduri: %-22s %7d triunghiuri" % (name, len(nodes[name][1])))
    print("noduri: %-22s %7d triunghiuri" % ("TOTAL", sum(len(t) for _, t in nodes.values())))
    if selftest:
        allok = True
        base = run(nodes, T, d, verbose=False)
        print("-- original: %s" % ("trece" if all(base.values()) else "PICA %s" % [k for k in CHECKS if not base[k]]))
        allok &= all(base.values())
        for name in CHECKS:
            r = run(sabotage(name, nodes, T), T, d, verbose=False)
            failed = [k for k in CHECKS if not r[k]]
            good = failed == [name]
            print("-- sabotaj %-9s pica: %-30s %s" % (name, ",".join(failed) or "-", "OK" if good else "!! GRESIT"))
            allok &= good
        print("SELFTEST: %s" % ("OK" if allok else "ESUAT"))
        sys.exit(0 if allok else 1)
    if sab:
        if sab not in CHECKS:
            raise SystemExit("sabotaj necunoscut: %s (%s)" % (sab, ", ".join(CHECKS)))
        print("== SABOTAJ: %s ==" % sab)
        nodes = sabotage(sab, nodes, T)
    res = run(nodes, T, d)
    ok = all(res.values())
    print("MASURA TEMPLU: %s" % ("OK" if ok else "PICAT"))
    sys.exit(0 if ok else 1)


main()

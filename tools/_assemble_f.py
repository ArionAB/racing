"""Insereaza POI F in Track13.tscn: ext_resource-uri, DecorManual, zone, hazard.

Nu e o unealta de rulat des — e pasul care MUTA rezultatul generatorului in
scena editabila. Dupa el, sursa de adevar sunt nodurile din .tscn.
"""
import io
import re
import sys

TSCN = "scenes/tracks/Track13.tscn"
NODES = "tools/_capp_f_nodes.txt"

# (id, uid, cale) — id-urile sunt cele emise de generator.
GLB = [
    ("cave_entrance", "d3t6vagidlwjc", "structures/cave_entrance"),
    ("hall_column", "b2ff4ec61lxki", "structures/hall_column"),
    ("cliff_band_module", "dpe8qhxsugqgd", "rocks/cliff_band_module"),
    ("hall_arch", "bvkr3ftq6ccpk", "structures/hall_arch"),
    ("hall_ceiling_module", "vmn6icumj3ax", "structures/hall_ceiling_module"),
    ("hall_alcove", "8xerxf0wuwc2", "structures/hall_alcove"),
    ("church_arch", "dm6d7l4vhnofl", "structures/church_arch"),
    ("millstone_door", "i4hg6bfwqtkc", "structures/millstone_door"),
    ("millstone_slot", "njat5wghuxbj", "structures/millstone_slot"),
    ("vent_shaft", "dha7jsoirc1vl", "structures/vent_shaft"),
    ("torch", "brbs86tcqqs6e", "props/torch"),
]

LSHAFT_UID = io.open("scenes/props/light_shaft.gd.uid", encoding="utf-8").read().strip()

src = io.open(TSCN, encoding="utf-8").read()
nodes = io.open(NODES, encoding="utf-8").read().rstrip() + "\n"

# --- 1. ext_resource-uri noi, dupa ultimul existent -------------------------
ext_lines = []
for rid, uid, path in GLB:
    ext_lines.append(
        '[ext_resource type="PackedScene" uid="uid://%s" '
        'path="res://assets/models/cappadocia/%s.glb" id="%s"]'
        % (uid, path, rid))
ext_lines.append(
    '[ext_resource type="Script" uid="uid://twspgftscxb4" '
    'path="res://scenes/props/world_prop.gd" id="wprop"]')
ext_lines.append(
    '[ext_resource type="Script" uid="uid://ccxa8xagvu55q" '
    'path="res://scenes/tracks/hazard_marker.gd" id="hzm"]')
ext_lines.append(
    '[ext_resource type="Script" uid="uid://b6qhqlgfsk8ou" '
    'path="res://scenes/hazards/camera_zone.gd" id="camzone"]')
ext_lines.append(
    '[ext_resource type="Script" uid="%s" '
    'path="res://scenes/props/light_shaft.gd" id="lshaft"]' % LSHAFT_UID)

last_ext = list(re.finditer(r"^\[ext_resource .*\]$", src, re.M))[-1]
src = (src[:last_ext.end()] + "\n" + "\n".join(ext_lines)
       + src[last_ext.end():])

# --- 2. load_steps ----------------------------------------------------------
m = re.search(r"load_steps=(\d+)", src)
src = src.replace(m.group(0), "load_steps=%d" % (int(m.group(1)) + len(ext_lines)), 1)

# --- 3. nodurile, la coada --------------------------------------------------
src = src.rstrip() + "\n\n" + io.open("tools/_capp_f_tail.txt", encoding="utf-8").read()
src = src.replace("@@NODES@@", nodes)

io.open(TSCN, "w", encoding="utf-8", newline="\n").write(src)
print("ok: %d ext_resource, %d linii de noduri" % (len(ext_lines), nodes.count("[node")))

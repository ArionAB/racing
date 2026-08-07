# Surse Blender

Fisierele `.blend` din care ies GLB-urile din `assets/models/`. Se comit odata cu
exportul (regula din [ONBOARDING.md](../../ONBOARDING.md)), ca oricine din echipa
sa poata edita ulterior propul.

`.gdignore` opreste Godot din a scana folderul — altfel ar incerca sa importe
`.blend`-urile ca scene si ar cere Blender instalat pe fiecare masina din echipa.

## Sursa reala e scriptul, nu .blend-ul

Assets-urile sunt **generate procedural** de scripturile din
[tools/blender/](../../tools/blender/). `.blend`-ul e un artefact al rularii, util
ca sa deschizi si sa ciupesti ceva de mana; daca vrei sa schimbi forma sau
proportiile, editeaza scriptul si regenereaza — asa raman reproductibile si
verificabile.

```
# in consola Python din Blender (namespace comun, deci merg doua exec separate):
exec(open(r"d:/GameDev/ignition-spike/tools/blender/dio_lib.py").read())
exec(open(r"d:/GameDev/ignition-spike/tools/blender/build_windmill.py").read())
```

Prin **Blender MCP** (`execute_blender_code`) namespace-ul nu e comun, deci cele
doua fisiere trebuie sa imparta explicit acelasi dictionar de globale. Si
`__file__` trebuie pus de mana: `exec(open(...).read())` nu-l defineste, iar
`dio_lib` il foloseste ca sa afle radacina repo-ului.

```python
g = {"__name__": "__main__",
     "__file__": r"d:/GameDev/ignition-spike/tools/blender/dio_lib.py"}
exec(open(r"d:/GameDev/ignition-spike/tools/blender/dio_lib.py").read(), g)
exec(open(r"d:/GameDev/ignition-spike/tools/blender/build_windmill.py").read(), g)
```

Verificarea GLB-ului rezultat, fara Blender si fara Godot:

```
python tools/blender/verify_glb.py assets/models/buildings/windmill.glb 1200
```

## Geometrie din afara: `vendor/`

Un asset poate porni de la un pachet extern in loc de `Builder` — trenul
(`build_train.py`) vine din **Train Pack** de [@Quaternius](https://quaternius.com)
(CC0). Regula de mai sus nu se schimba: **sursa ramane scriptul**, doar ca el
importa un OBJ in loc sa construiasca din primitive, si mai departe face acelasi
lucru cu orice alt asset — mapeaza materialele pachetului pe sloturi de paleta,
colapseaza UV-urile pe centrul slotului si coace AO in vertex colors.

Doua conditii, ca sa nu devina o portita:

1. **Sursa se vendorizeaza in repo** (`assets/blender/vendor/<pachet>/`), cu tot
   cu licenta. Un script care citeste dintr-un folder de pe discul cuiva nu e
   reproductibil, e o amintire.
2. **Nu vine cu texturile lui.** Pachetele externe aduc materiale proprii; daca
   ar intra asa in joc, fiecare ar adauga draw call-uri si si-ar aduce propria
   familie de culori — exact „asset soup"-ul de care paleta ne apara
   (CLAUDE.md, style_bible §4).

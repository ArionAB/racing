import sys,re
scene,zone,frag=sys.argv[1:4]
s=open(scene,encoding='utf-8').read()
f=open(frag,encoding='utf-8').read().strip('\n')+'\n\n'
# scoate blocurile vechi ale zonei
s=re.sub(r'\[node name="[^"]+" parent="DecorManual/%s" instance=ExtResource\("[^"]+"\)\]\n(?:(?!\[node)[^\n]*\n)*'%zone,'',s)
m=re.search(r'\[node name="%s" type="Node3D" parent="DecorManual"\]\n[^\n]*\n\n'%zone,s)
assert m
s=s[:m.end()]+f+s[m.end():]
open(scene,'w',encoding='utf-8',newline='\n').write(s)

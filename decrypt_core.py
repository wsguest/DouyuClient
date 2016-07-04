#-*- coding: utf-8 -*-
# decrypt core swf to normal
f1 = open('corenormal.swf','rb')
content = bytearray(f1.read())
f1.close()
key = 'dkrltl0%4*@jrky#@$'
cl = len(content)
kindex = 0
index = 0
hc = 0
while(index < cl):
    if(kindex >= len(key)):
        kindex = 0
        hc = hc + 1
        if(hc >= 50) : break
    content[index] = (content[index] - ord(key[kindex])) & 0xff
    index = index + 1
    kindex = kindex+1

f1 = open('corenormal_dc.swf','wb')
f1.write(content)
f1.close()

import numpy as np, json
from PIL import Image, ImageDraw, ImageFont
b=np.load('trace2_base.npz'); P=b['P']; N=b['N']; s=b['s']; c=np.load('trace2_curbs.npz')
R=c['R']; Lf=c['Lf']; n=len(P); pxm=198/7.3152
CW=1.2*pxm
walls_px=[[(440,292),(2066,292),(2151,445)],
 [(835,295),(950,500),(1000,600),(1040,645),(1150,690),(1300,730),(1336,780),(1356,870),(1386,990),(1426,1150)],
 [(115,595),(330,565),(560,527)],
 [(745,565),(800,625),(860,700),(900,750),(950,820),(1000,865),(1090,900)],
 [(1210,485),(1276,510),(1426,560),(1491,610),(1556,580),(1696,510),(1836,505),(1976,600),(2096,680),(2326,690),(2501,610)],
 [(1491,610),(1516,690),(1576,800),(1666,930)],
 [(610,1120),(715,1395)],
 [(810,1368),(1891,1370)],
 [(1911,1410),(1966,1345)],
 [(2066,1205),(2071,1390)]]
stripes_px=[[(780,1320),(805,1358)],[(1896,1360),(1921,1325)]]
start_px=(1440,1269)
X0,Y0=P[0]
def w(p): p=np.asarray(p,float); return np.c_[(p[:,0]-X0)/pxm, -(p[:,1]-Y0)/pxm]
xy=w(P)
cRin=c['curbRin']; cLin=c['curbLin']
cLw=np.where(np.isfinite(cLin),c['curbLout']-cLin,0)/pxm; cRw=np.where(np.isfinite(cRin),c['curbRout']-cRin,0)/pxm
M=np.c_[s,xy,Lf/pxm,R/pxm,cLw,cRw]
np.savetxt('raceCourse_trace.csv',M,delimiter=',',fmt=['%.3f']*7,
  header='s_m,x_m,y_m,widthLeft_m,widthRight_m,curbWidthLeft_m,curbWidthRight_m',comments='')
rows=[]
for k,wl in enumerate(walls_px,1):
    for p in w(wl): rows.append((k,'wall',p[0],p[1]))
for k,st in enumerate(stripes_px,1):
    for p in w(st): rows.append((k,'stripe',p[0],p[1]))
with open('raceCourse_features.csv','w') as f:
    f.write('id,type,x_m,y_m\n')
    for r in rows: f.write('%d,%s,%.3f,%.3f\n'%r)
print('loop %.1f m; widths %.2f to %.2f m; %d walls, %d stripes'%(s[-1]+s[1],(R+Lf).min()/pxm,(R+Lf).max()/pxm,len(walls_px),len(stripes_px)))
# overlay
img=Image.open('RaceTrack.jpg').convert('RGB'); d=ImageDraw.Draw(img)
try: font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',30)
except: font=None
eR=P+N*R[:,None]; eL=P-N*Lf[:,None]
d.line([tuple(p) for p in np.r_[P,P[:1]]],fill=(255,255,0),width=4)
d.line([tuple(p) for p in np.r_[eR,eR[:1]]],fill=(0,255,255),width=4)
d.line([tuple(p) for p in np.r_[eL,eL[:1]]],fill=(255,0,255),width=4)
for side,cin in ((1,cRin),(-1,cLin)):
    ok=np.isfinite(cin)
    for i in np.nonzero(ok)[0]:
        a=P[i]+N[i]*side*cin[i]; bb=P[i]+N[i]*side*c['curb%sout'%('R' if side>0 else 'L')][i]
        d.line([tuple(a),tuple(bb)],fill=(255,40,40) if (i//4)%2==0 else (255,255,255),width=4)
for wl in walls_px: d.line(wl,fill=(255,140,0),width=9)
for st in stripes_px: d.line(st,fill=(120,255,120),width=9)
d.line([(start_px[0],1170),(start_px[0],1368)],fill=(0,255,0),width=7)
for k in range(0,int(s[-1])+1,25):
    i=np.argmin(np.abs(s-k)); p=P[i]
    d.ellipse([p[0]-8,p[1]-8,p[0]+8,p[1]+8],fill=(255,255,255),outline=(0,0,0))
    d.text((p[0]+10,p[1]-34),f'{k}',fill=(255,255,255),font=font,stroke_width=3,stroke_fill=(0,0,0))
d.polygon([tuple(P[0]+[0,-16]),tuple(P[0]+[-40,0]),tuple(P[0]+[0,16])],fill=(0,255,0))
img.resize((2000,1125)).save('raceCourse_trace_check2.png')

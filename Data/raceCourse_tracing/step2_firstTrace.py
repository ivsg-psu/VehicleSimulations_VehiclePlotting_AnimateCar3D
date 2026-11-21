import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from scipy.interpolate import splprep, splev
from scipy.signal import medfilt
im=np.asarray(Image.open('RaceTrack.jpg').convert('RGB')).astype(float)
A=np.load('asphalt.npy'); W=np.load('white.npy'); Rd=np.load('red.npy')
mean=im.mean(2); sat=im.max(2)-im.min(2)
light=(mean>160)&(sat<70)
wall=(~A)|Rd|W|(light&ndi.binary_dilation(W,iterations=2))
H,Wd=A.shape
# Waypoints (original pixels), in driving order, starting on the top straight heading east
wp=[(450,187),(800,187),(1200,187),(1600,187),(2000,187),(2150,195),(2280,240),(2350,320),(2365,420),(2340,520),(2270,590),(2160,605),(2050,595),(1950,555),(1870,480),(1790,425),(1700,408),(1600,425),(1500,480),(1420,490),(1340,450),(1250,400),(1150,385),(1085,415),(1062,475),(1085,545),(1160,592),(1260,622),(1350,660),(1405,740),(1450,830),(1500,920),(1560,1010),(1640,1060),(1740,1060),(1800,1020),(1815,945),(1790,860),(1730,790),(1680,720),(1690,655),(1750,615),(1830,615),(1910,650),(1990,710),(2080,760),(2180,775),(2280,760),(2360,800),(2400,880),(2410,1000),(2405,1120),(2380,1220),(2330,1290),(2260,1300),(2200,1260),(2170,1180),(2150,1100),(2110,1040),(2050,1025),(1995,1060),(1970,1130),(1960,1200),(1930,1250),(1860,1265),(1700,1265),(1300,1265),(900,1265),(800,1235),(740,1150),(690,1050),(640,975),(560,935),(510,960),(500,1050),(500,1150),(470,1230),(400,1265),(310,1245),(250,1170),(232,1050),(232,900),(250,800),(310,730),(400,690),(500,665),(600,655),(690,680),(760,760),(810,840),(860,920),(920,1000),(1000,1050),(1100,1060),(1190,1045),(1235,960),(1225,860),(1170,810),(1080,795),(1010,760),(960,700),(910,630),(860,550),(790,470),(700,425),(600,425),(500,435),(420,445),(330,455),(255,420),(200,340),(215,255),(290,205),(370,190)]
wp=np.array(wp,float)
tck,u=splprep([wp[:,0],wp[:,1]],s=len(wp)*30,per=1)
def sample(tck,step=8):
    uu=np.linspace(0,1,20000); x,y=splev(uu,tck); d=np.r_[0,np.cumsum(np.hypot(np.diff(x),np.diff(y)))]
    L=d[-1]; n=int(L/step); ui=np.interp(np.linspace(0,L,n,endpoint=False),d,uu)
    x,y=splev(ui,tck); dx,dy=splev(ui,tck,der=1); t=np.hypot(dx,dy)
    return np.c_[x,y], np.c_[-dy/t, dx/t], L   # normal: image left of travel (y down)
def ray(p,n,skip=14,maxlen=260):
    for k in range(skip,maxlen):
        x=int(round(p[0]+k*n[0])); y=int(round(p[1]+k*n[1]))
        if x<0 or y<0 or x>=Wd or y>=H or wall[y,x]: return k
    return maxlen
P=None
for it in range(4):
    pts,nrm,L=sample(tck)
    a=np.array([ray(p,n) for p,n in zip(pts,nrm)],float)    # one side
    b=np.array([ray(p,-n) for p,n in zip(pts,nrm)],float)   # other side
    # (gaps in dashed dividers let rays leak: clip to a running median)
    def tame(v):
        m=medfilt(v,15); return np.minimum(v,1.25*m)
    a=tame(a); b=tame(b)
    shift=np.clip(medfilt((a-b)/2,21),-25,25)
    ctr=pts+nrm*shift[:,None]
    ctr=ctr[::4]
    tck,u=splprep([ctr[:,0],ctr[:,1]],s=len(ctr)*40,per=1)
    print('iteration',it,'L',sample(tck)[2],'mean |shift|',np.abs(shift).mean())
pts,nrm,L=sample(tck)
a=np.array([ray(p,n) for p,n in zip(pts,nrm)],float); b=np.array([ray(p,-n) for p,n in zip(pts,nrm)],float)
from scipy.signal import savgol_filter
def unleak(v):
    sm=medfilt(v,31)
    for it in range(4):
        vv=np.where(np.abs(v-sm)>14,sm,v)
        sm=savgol_filter(np.r_[vv[-40:],vv,vv[:40]],31,2)[40:-40]
    return sm
a=unleak(a); b=unleak(b)
np.savez('trace.npz',pts=pts,nrm=nrm,a=a,b=b,L=L)
print('loop length px',L,'samples',len(pts),'width px median',np.median(a+b),'min',(a+b).min(),'max',(a+b).max())
# curbs: red within 45 px beyond each edge
tng=np.c_[nrm[:,1],-nrm[:,0]]
def curb(p,n,dist,tv):
    c=0;t=0
    for k in range(int(dist)-3,int(dist)+45,3):
        for j in range(-12,13,4):
            x=int(round(p[0]+k*n[0]+j*tv[0])); y=int(round(p[1]+k*n[1]+j*tv[1]))
            if 0<=x<Wd and 0<=y<H: t+=1; c+=Rd[y,x]
    return c/max(t,1)
ca=np.array([curb(p,n,d,tv) for p,n,d,tv in zip(pts,nrm,a,tng)]); cb=np.array([curb(p,-n,d,tv) for p,n,d,tv in zip(pts,nrm,b,tng)])
np.savez('trace.npz',pts=pts,nrm=nrm,a=a,b=b,L=L,ca=ca,cb=cb)
img=Image.open('RaceTrack.jpg').convert('RGB'); d=ImageDraw.Draw(img)
la=pts+nrm*a[:,None]; lb=pts-nrm*b[:,None]
d.line([tuple(p) for p in np.r_[pts,pts[:1]]],fill=(255,255,0),width=4)
d.line([tuple(p) for p in np.r_[la,la[:1]]],fill=(0,255,255),width=3)
d.line([tuple(p) for p in np.r_[lb,lb[:1]]],fill=(255,0,255),width=3)
for i in range(0,len(pts),6):
    if ca[i]>0.12: d.ellipse([la[i,0]-6,la[i,1]-6,la[i,0]+6,la[i,1]+6],fill=(255,0,0))
    if cb[i]>0.12: d.ellipse([lb[i,0]-6,lb[i,1]-6,lb[i,0]+6,lb[i,1]+6],fill=(255,0,0))
for i in range(0,len(pts),60): d.text(tuple(pts[i]+5),f'{i}',fill=(255,255,255))
d.polygon([tuple(pts[0]+[0,-12]),tuple(pts[0]+[30,0]),tuple(pts[0]+[0,12])],fill=(0,255,0))
img.save('trace_full.png'); img.resize((1288,724)).save('trace_small.png')

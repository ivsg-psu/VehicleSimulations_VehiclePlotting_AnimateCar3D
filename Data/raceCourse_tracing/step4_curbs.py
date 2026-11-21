import numpy as np, warnings; warnings.filterwarnings('ignore')
from scipy.ndimage import maximum_filter1d, binary_closing, binary_opening, label
Rd=np.load('red.npy'); H,Wd=Rd.shape
b=np.load('trace2_base.npz'); P=b['P']; N=b['N']; s=b['s']; R=b['R'].copy(); Lf=b['Lf'].copy()
pxm=198/7.3152; n=len(P); T=np.c_[N[:,1],-N[:,0]]
def redFrac(side,edge):
    out=np.zeros(n); ext=np.zeros(n)
    for i in range(n):
        c=t=0; far=0
        for k in range(-3,60,3):
            for j in (-12,-6,0,6,12):
                q=P[i]+N[i]*side*(edge[i]+k)+T[i]*j; x,y=int(round(q[0])),int(round(q[1]))
                if 0<=x<Wd and 0<=y<H:
                    if k<45: t+=1; c+=Rd[y,x]
                    if Rd[y,x]: far=max(far,k)
        out[i]=c/max(t,1); ext[i]=far
    return out,ext
def runs(flag):
    lab,nr=label(np.r_[flag,flag])   # (wrap)
    res=[]
    for r in range(1,nr+1):
        idx=np.nonzero(lab==r)[0]
        if idx[0]>=n: continue
        if idx[-1]>=n and idx[0]==0: continue
        res.append(idx%n)
    return res
def kasa(xy):
    x,y=xy[:,0],xy[:,1]; M=np.c_[x,y,np.ones_like(x)]; c=np.linalg.lstsq(M,x*x+y*y,rcond=None)[0]
    cx,cy=c[0]/2,c[1]/2; return cx,cy,np.sqrt(c[2]+cx*cx+cy*cy)
def arcT(js,side,edge):
    pts=P[js]+N[js]*side*edge[js][:,None]
    cx,cy,r=kasa(pts); rms=np.sqrt(np.mean((np.hypot(pts[:,0]-cx,pts[:,1]-cy)-r)**2))
    if (rms>0.12*pxm or r>60*pxm) and len(js)>40:
        h=len(js)//2; return np.r_[arcT(js[:h],side,edge),arcT(js[h:],side,edge)]
    if r>60*pxm:   # (nearly straight: a straight fit)
        return edge[js].astype(float)
    tc=[]
    for j in js:
        dp=P[j]-[cx,cy]; v=N[j]*side; B=2*dp@v; C=dp@dp-r*r; D=B*B-4*C
        a=np.nan
        if D>=0:
            ro=[x for x in ((-B-np.sqrt(D))/2,(-B+np.sqrt(D))/2) if x>0]
            if ro: a=min(ro,key=lambda z:abs(z-edge[j]))
        tc.append(a)
    tc=np.array(tc); bad=~np.isfinite(tc)|(np.abs(tc-edge[js])>1.0*pxm)
    tc[bad]=edge[js][bad]; return tc
result={}
report=[]
for side,edge,name in ((1,R,'R'),(-1,Lf,'L')):
    fr,ext=redFrac(side,edge)
    f=maximum_filter1d((fr>0.07).astype(int),5,mode='wrap')>0
    f=binary_closing(f,structure=np.ones(9)); f=binary_opening(f,structure=np.ones(int(3*pxm/(0.25*pxm))))
    cin=np.full(n,np.nan); cout=np.full(n,np.nan)
    for js in runs(f):
        tc=arcT(js,side,edge)
        width=np.clip(np.percentile(ext[js],80),0.6*pxm,1.6*pxm)
        cin[js]=tc; cout[js]=tc+width
        report.append((name,s[js[0]],s[js[-1]],width/pxm))
    result[name]=(cin,cout)
    edge[np.isfinite(cin)]=cin[np.isfinite(cin)]
# curvature of the centerline, for the cap
tg=np.gradient(P,axis=0); hd=np.unwrap(np.arctan2(tg[:,1],tg[:,0])); kap=np.gradient(hd)/(np.hypot(tg[:,0],tg[:,1]))   # 1/px, + turning toward +N (right)
kap=np.convolve(np.r_[kap[-10:],kap,kap[:10]],np.ones(21)/21,'same')[10:-10]
for name,side in (('R',1),('L',-1)):
    cin,cout=result[name]; ok=np.isfinite(cin)
    inside=np.sign(kap)==side
    room=np.where(inside,1/np.maximum(np.abs(kap),1e-6)-cin,np.inf)
    width=np.minimum(1.2*pxm,0.8*room)
    cout[ok]=cin[ok]+np.maximum(width[ok],0.2*pxm)
for r in sorted(report,key=lambda z:z[1]): print('curb %s  s %6.1f - %6.1f m  width %.2f m'%r)
np.savez('trace2_curbs.npz',R=R,Lf=Lf,curbRin=result['R'][0],curbRout=result['R'][1],curbLin=result['L'][0],curbLout=result['L'][1])

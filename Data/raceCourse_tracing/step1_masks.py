# Step 1: color masks from the photo (RaceTrack.jpg in this folder)
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
im=np.asarray(Image.open('RaceTrack.jpg').convert('RGB')).astype(float)
R,G,B=im[...,0],im[...,1],im[...,2]
mx=im.max(2); mn=im.min(2); mean=im.mean(2)
asphalt=(mx-mn<35)&(mean<150)&(R>=G-6)&(R>=B-12)
a=ndi.binary_closing(ndi.binary_opening(asphalt,iterations=2),iterations=4)
lab,n=ndi.label(a); sizes=ndi.sum(a,lab,range(1,n+1))
np.save('asphalt.npy',lab==(np.argmax(sizes)+1))
np.save('white.npy',mn>190)
np.save('red.npy',(R>165)&(R-G>45))

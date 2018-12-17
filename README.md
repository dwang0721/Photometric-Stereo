# Photometric-Stereo
Given 3 images of the same object under different lighting conditions, recover the surface normal at each pixel and the overall shape of the object.
This technique is used in [GelSight touch sensor](http://www.gelsight.com/), but my approach is simpler. 

<p align="middle">
<img src="https://github.com/dwang0721/Photometric-Stereo/blob/master/readmeImage/gelSight.JPG" alt="GelSight" height="300" width="620">

&nbsp; 
### 1. Find Light Direction

Assuming lambert surface with all equal radiance from all angles, the Light direction is calculated by looking for the brightest spot on a sphere, I used Matlab to automatic find this position. 
The coordinate of the brightest spot is *L(x, y, z)*. By dividing the vector by -z, we can get:

<p align="middle">
<a href="https://www.codecogs.com/eqnedit.php?latex=(\frac{x}{-z},&space;\frac{y}{-z},&space;\frac{z}{-z})" target="_blank"><img src="https://latex.codecogs.com/gif.latex?(\frac{x}{-z},&space;\frac{y}{-z},&space;\frac{z}{-z})" title="(\frac{x}{-z}, \frac{y}{-z}, \frac{z}{-z})" /></a>
</p>
<p align="middle">
<a href="https://www.codecogs.com/eqnedit.php?latex=(\frac{x}{-z},&space;\frac{y}{-z},&space;-1)" target="_blank"><img src="https://latex.codecogs.com/gif.latex?(\frac{x}{-z},&space;\frac{y}{-z},&space;-1)" title="(\frac{x}{-z}, \frac{y}{-z}, -1)" /></a>
</p>

Where we define *p*, *q* values of the Light *L* are:
<p align="middle">
<a href="https://www.codecogs.com/eqnedit.php?latex=p=&space;\frac{x}{-z},&space;q=&space;\frac{x}{-z}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?p=&space;\frac{x}{-z},&space;q=&space;\frac{x}{-z}" title="p= \frac{x}{-z}, q= \frac{x}{-z}" /></a>
</p>

&nbsp; 
### 2. Build Intensity Lookup Table
Each Light *L* is represented by *p* and *q*. We know that the cross product of surface normal *n* and light is propotional to the image irradiance *E*:
<p align="middle">
<a href="https://www.codecogs.com/eqnedit.php?latex=n&space;\cdot&space;L_1&space;=&space;E_1" target="_blank"><img src="https://latex.codecogs.com/gif.latex?n&space;\cdot&space;L_1&space;=&space;E_1" title="n \cdot L_1 = E_1" /></a>
</p><p align="middle">
<a href="https://www.codecogs.com/eqnedit.php?latex=n&space;\cdot&space;L_2&space;=&space;E_2" target="_blank"><img src="https://latex.codecogs.com/gif.latex?n&space;\cdot&space;L_2&space;=&space;E_2" title="n \cdot L_2 = E_2" /></a>
</p><p align="middle">
<a href="https://www.codecogs.com/eqnedit.php?latex=n&space;\cdot&space;L_3&space;=&space;E_3" target="_blank"><img src="https://latex.codecogs.com/gif.latex?n&space;\cdot&space;L_3&space;=&space;E_3" title="n \cdot L_3 = E_3" /></a>
</p>
Expand those and We get:
<p align="middle">
<a href="https://www.codecogs.com/eqnedit.php?latex=\frac{E_1}{E_2}&space;=&space;\frac&space;{n&space;\cdot&space;L_1}&space;{n&space;\cdot&space;L_2}&space;=&space;\frac{(pp_1&space;&plus;qq_1&plus;1)\sqrt{{p_2}^2&space;&plus;&space;{q_2}^2&space;&plus;1}}{&space;(pp_2&space;&plus;qq_2&plus;1)\sqrt{{p_1}^2&space;&plus;&space;{q_1}^2&space;&plus;1}&space;}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\frac{E_1}{E_2}&space;=&space;\frac&space;{n&space;\cdot&space;L_1}&space;{n&space;\cdot&space;L_2}&space;=&space;\frac{(pp_1&space;&plus;qq_1&plus;1)\sqrt{{p_2}^2&space;&plus;&space;{q_2}^2&space;&plus;1}}{&space;(pp_2&space;&plus;qq_2&plus;1)\sqrt{{p_1}^2&space;&plus;&space;{q_1}^2&space;&plus;1}&space;}" title="\frac{E_1}{E_2} = \frac {n \cdot L_1} {n \cdot L_2} = \frac{(pp_1 +qq_1+1)\sqrt{{p_2}^2 + {q_2}^2 +1}}{ (pp_2 +qq_2+1)\sqrt{{p_1}^2 + {q_1}^2 +1} }" /></a>
</p><p align="middle">
<a href="https://www.codecogs.com/eqnedit.php?latex=\frac{E_2}{E_3}&space;=&space;\frac&space;{n&space;\cdot&space;L_2}&space;{n&space;\cdot&space;L_3}&space;=&space;\frac{(pp_2&space;&plus;qq_2&plus;1)\sqrt{{p_3}^2&space;&plus;&space;{q_3}^2&space;&plus;1}}{&space;(pp_3&space;&plus;qq_3&plus;1)\sqrt{{p_2}^2&space;&plus;&space;{q_2}^2&space;&plus;1}&space;}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\frac{E_2}{E_3}&space;=&space;\frac&space;{n&space;\cdot&space;L_2}&space;{n&space;\cdot&space;L_3}&space;=&space;\frac{(pp_2&space;&plus;qq_2&plus;1)\sqrt{{p_3}^2&space;&plus;&space;{q_3}^2&space;&plus;1}}{&space;(pp_3&space;&plus;qq_3&plus;1)\sqrt{{p_2}^2&space;&plus;&space;{q_2}^2&space;&plus;1}&space;}" title="\frac{E_2}{E_3} = \frac {n \cdot L_2} {n \cdot L_3} = \frac{(pp_2 +qq_2+1)\sqrt{{p_3}^2 + {q_3}^2 +1}}{ (pp_3 +qq_3+1)\sqrt{{p_2}^2 + {q_2}^2 +1} }" /></a>
</p>

In Matlab, I used **scatterInterpolant** as the data structure to store *E1/E2* and *E2/E3* lookup value. 
*q* and *p* range from *-10* to *10*, with step size *0.1*. 


&nbsp; 
### 3. Build pq Map:
Since we have a Lookup table to find Gradience (p, q) at each pixel, we can easily build a gradience map the same size as the image. Each pixel of the image corresponds to a (p, q) value pair. I call this map pqMap. These pq value pair can also be represented by the surface normal.  

I created a normal drawer function to plot the surface normals from a pqMap. Some render results:

<p align="middle">
<img src="https://github.com/dwang0721/Photometric-Stereo/blob/master/readmeImage/normal%20plot.JPG" alt="normal" height="340" width="400">
<img src="https://github.com/dwang0721/Photometric-Stereo/blob/master/readmeImage/normal%20plot_ellipsoid.JPG" alt="normal" height="340" width="400">

&nbsp; 
### 4. Recover the 3d model by Integration
I integrate surface gradience from 2 directions (LeftTop->Right Bottom, Right Bottom->LeftTop) and averaged them out. Some results are here under:

<p align="middle">
<img src="https://github.com/dwang0721/Photometric-Stereo/blob/master/readmeImage/integration.JPG" alt="integration" height="340" width="400">
<img src="https://github.com/dwang0721/Photometric-Stereo/blob/master/readmeImage/integration_ellipsoid.JPG" alt="integration" height="340" width="400">


&nbsp; 
### 5. Future Work
The sample images are taken by a camera and the surface is not fully lambert refletance, so the mirror reflection (high light) causes the error the calibaration stage. Also if a pixel at the 3 input images are all black, there is no solution to the equation in the Step 2, we get error in some dark areas. Carefully placing light sources and using matte surface materials gives better results. 

% di wang
% learning reference: http://pages.cs.wisc.edu/~csverma/CS766_09/Stereo/stereo.html

clc;
close all;
clear;

% read image from 1-6
images1 = ["cone","hexagon","octogon", "sphere", "sphereR", "torus" ];
images2 = ["cone2-lamp","cone-lamp","cylinder-lamp", "ellipsoid-lamp", "hex1-lamp", "hex2-lamp", "sphere-lamp" ];
dir1 = 'Photostereo_SyntheticImages/';
dir2 = 'Photostereo_RealImages/';

dir = dir2;
images = images2;

% load image for calculation
[img1, img2, img3] = getThereImages(2, images, dir);

% calibration to find light angle 4 or 7
[cali1, cali2, cali3] = getThereImages(7, images, dir);

% get image dimesion
[img_height, img_width, channel] = size(img1);


[p1,q1] = getGradentPQ(cali1);
[p2,q2] = getGradentPQ(cali2);
[p3,q3] = getGradentPQ(cali3);
[a1, b1, c1] = findNormalizedVectorS(p1,q1);
[a2, b2, c2] = findNormalizedVectorS(p2,q2);
[a3, b3, c3] = findNormalizedVectorS(p3,q3);


% create data map
dataxy = [];
datap = [];
dataq = [];
step = 0.1;
range = 10;


% build interploation map ----------------------
disp("interploation map");
for p = -range:step:range
    for q = -range:step:range
        % e12 is y, e23 is x

        [e12, e23] = calculate_E12_E23(p, q, p1, p2, p3, q1, q2, q3);
        
        if (isnan(e12) ||  isnan(e23) || isinf(e12) || isinf(e23))
            break;
        end
                
        dataxy = [dataxy; e23, e12];
        datap = [datap;p];
        dataq = [dataq;q];  
        
    end
end

%         dataxy = [dataxy; 1, 1];
%         datap = [datap;0];
%         dataq = [dataq;0];  

Fp = scatteredInterpolant(dataxy,datap,'natural');
Fq = scatteredInterpolant(dataxy,dataq,'natural');


% build pq map -------------------------------



disp("build pq map");

hsv1 = rgb2hsv(img1);
e1 = hsv1(:,:,3);
hsv2 = rgb2hsv(img2);
e2 = hsv2(:,:,3);
hsv3 = rgb2hsv(img3);
e3 = hsv3(:,:,3);
e1e2 = reshape(e1./e2, [],1);
e2e3 = reshape(e2./e3, [],1);
exy = [e2e3,e1e2];
p = Fp(exy);
q = Fq(exy);


% find background
bg_loc = find((e1+e2+e3)<0.4);
render = zeros(size(e1));
render(bg_loc) = 1;
imshow(render);
p(bg_loc)=0;
q(bg_loc)=0;


pq = [p, q];
pqMap = reshape(pq, img_height,img_width,2);
pqMap(isnan(pqMap))=0;


% debug, print some normals
figure;
imshow(img1);
for y = 1:15:img_height
    for x = 1:15:img_width
        p = pqMap(y, x, 1);
        q = pqMap(y, x, 2);
        [nx,ny,nz] = findNormalizedVectorS(p,q);
        drawNormalVector(x,y,nx,ny,nz,8);
    end
end


% build Z map by integrate pq map ---------------------------

disp("build Z map");

zMap = zeros(img_height,img_width,1);
zMap2 = zeros(img_height,img_width,1);
% zMask= zeros(img_height,img_width,1);

for x = 1:1:img_width
    for y = 1:1:img_height
        if x <=1
            z1 = 0 + pqMap(y,x,1);
        else
            z1 = zMap(y, x-1) + pqMap(y,x,1);
        end
        
        if y <=1
            z2 = 0 + pqMap(y,x,2);
        else
            z2 = zMap(y-1, x) + pqMap(y,x,2);
        end
        
        % average z
        zMap(y, x) = mean([z1, z2]);    

    end
end

for x = img_width:-1:1
    for y = img_height:1:-1
        if x >= img_width
            z1 = 0 + pqMap(y,x,1);
        else
            z1 = zMap2(y, x+1) - pqMap(y,x,1);
        end
        
        if y >=img_height
            z2 = 0 + pqMap(y,x,2);
        else
            z2 = zMap2(y+1, x) - pqMap(y,x,2);
        end
        
        % average z
        zMap2(y, x) = mean([z1, z2]);    
    end
end

zMap3 = (zMap+zMap2)/2;

% ploting the shape--------------------------------

figure;
[X,Y] = meshgrid(1:img_width,1:img_height);
h = surf(X,Y,zMap3), grid on
set(h,'LineStyle','none');
axis([0 img_width 0 img_height -200 200])
xlabel('x'), ylabel('y'), zlabel('z')
legend('integration')
rotate3d on;


function [e12, e23] = calculate_E12_E23(p, q, p1, p2, p3, q1, q2, q3)
    e12 = (p*p1+q*q1+1)*sqrt(p2^2+q2^2+1)/((p*p2+q*q2+1)*sqrt(p1^2+q1^2+1));
    e23 = (p*p2+q*q2+1)*sqrt(p3^2+q3^2+1)/((p*p3+q*q3+1)*sqrt(p2^2+q2^2+1));
end

function drawNormalQuiver(x,y,u,v,scale)
%     figure;
%     imshow(image);
    axis on
    hold on;
    quiver(x,y,u,v,scale)
end

function drawNormalVector(x,y,nx,ny,nz, reverse)
%     figure;
%     imshow(image);
    axis on
    hold on;   
    
    nx = reverse * nx;
    ny = reverse * ny;
    
    depth = 1.1-nz;
    
    line_x = [x x+nx/depth];
    line_y = [y y+ny/depth];
    plot( x, y, 'g*', 'MarkerSize', 3, 'LineWidth', 1);
    line(line_x, line_y);
end

function [rp,rq] = calculateSurfacePQ(x,y, image1, image2, image3, p1, p2, p3, q1, q2, q3)
    
    syms p q    
    
    % image radiance
    e1 = findImageRadianceE (x,y, image1);
    e2 = findImageRadianceE (x,y, image2);
    e3 = findImageRadianceE (x,y, image3);
    
    E_W1 = (e1*sqrt(p1^2+q1^2+1)/(e2*sqrt(p2^2+q2^2+1)));
    E_W2 = (e2*sqrt(p2^2+q2^2+1)/(e3*sqrt(p3^2+q3^2+1)));
    
    equation1 = (p1-E_W1*p2)*p + (q1-E_W1*q2)*q + (1 - E_W1) == 0;
    equation2 = (p2-E_W2*p3)*p + (q2-E_W2*q3)*q + (1 - E_W2) == 0;
    
    eqns = [equation1, equation2];
    S = solve(eqns, [p q]);
    
    % output radiance map
    rp = double(S.p); 
    rq = double(S.q);
end

function e = findImageRadianceE(x,y, image)
    hsv = rgb2hsv(image); 
    e = double(hsv(y,x,3));
end

function [normalx, normaly,normalz] = findNormalizedVectorS(p,q)
    norm = sqrt(p.^2+q.^2+1);
    normalx = -p/norm;
    normaly = -q/norm;
    normalz = 1/norm;
end

function [p,q] = getGradentPQ(image)
    %find sphere center [cx, cy]
    r =151;
    
    [cx, cy] = findImageCenter(image);
    
    r =140;
    cy = 300;

    %find brightest spot [px, py]
    [py,px] = findBrightestSpot(image);

    %find light direction, normal is the same as the light direction:
    x = px-cx;
    y = py-cy;
    z = sqrt(r^2-x^2-y^2);

    % convert to (p, q, -1)
    p = x/-z;
    q = y/-z;
end

function [py, px] = findBrightestSpot(image)
    hsv = rgb2hsv(image);
    v = hsv(:,:,3);
    hilight_loc = v==max(v(:));
    render = zeros(size(v));
    render(hilight_loc) = 1;
    result = bwmorph(render, 'shrink', Inf);
    [py, px]=find(result>0);

    % for display purpos only
    % displayMarker(px, py, image);
end

% use this function to find light direction
function displayMarker(x, y, image)
    figure;
    imshow(image);
    axis on
    hold on;
    plot( x, y, 'r+', 'MarkerSize', 15, 'LineWidth', 2);
end

function [cx, cy] = findImageCenter(image)
image_size = size(image);
cy = image_size(1)/2;
cx = image_size(2)/2;
end

% 3 light direction images
function [img1, img2, img3] = getThereImages(image_index, images, dir)
    img1 = imread(char(strcat( dir, images(image_index), '1.tif')));
    img2 = imread(char(strcat( dir, images(image_index), '2.tif')));
    img3 = imread(char(strcat( dir, images(image_index), '3.tif')));
end


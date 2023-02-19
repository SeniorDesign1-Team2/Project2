
close all
clc
clear
clear('cam')

% find webcam 
cam_list = webcamlist;

cam_name = cam_list{2};

cam = webcam(cam_name);

%%
preview(cam);


%% take picture of image before shapes
closePreview(cam);
%data.orig = snapshot(cam);

%% read in image before shapes
data.orig = imread("Images/NoShapes.jpg");
figure();
imshow(data.orig)
[height,width,depth] = size(data.orig);

%% take picture of camera after shapes are included
%data.cur = snapshot(cam);
data.cur = imread("Images/Basic Shapes.jpg");
figure();
imshow(data.cur)

%% compute difference of two pictures
data.diff = data.orig - data.cur;
figure();
imshow(data.diff)

%% fix image and compute binary
backgroundSub = data.diff;
for i=1:height
    for j=1:width
        if (data.diff(i,j,1) > 20) || ...
           (data.diff(i,j,2) > 20) || ...
           (data.diff(i,j,3) > 20)
            
            %Will Show in Green
            backgroundSub(i,j,:) = [175,200,175];
        end
    end
end

figure();
imshow(backgroundSub);

data.binary = im2bw(backgroundSub);
figure();
imshow(data.binary);

%% Erode Image

SE = strel('disk',8);

data.noise_remove = imerode(data.binary, SE);

figure();
imshow(data.noise_remove);

%%

STATS = regionprops(data.noise_remove, 'all');

figure();
imshow(data.cur);
hold on;

%Ideal Color Combinations
colorsNum = {[255,0,0], [0,255,0], [0,0,255], [255,255,0], [255,0,255], [0,255,255]};
colorsName = ["Red", "Green", "Blue", "Yellow", "Magenta", "Cyan"];

items = size(STATS);
for i = 1:items
    ratio = STATS(i).Area / STATS(i).Perimeter;
    if ratio >= 0.75 && ratio < 2.5
        STATS(i).Shape = "Triangle";
    elseif ratio < 5
        STATS(i).Shape = "Square";
    elseif ratio < 7.5
        STATS(i).Shape = "Circle";
    else
        STATS(i).Shape = "Invalid";
        continue;
    end
   
    %Find RGB Values at each Centroid
    STATS(i).Red = data.cur(round(STATS(i).Centroid(2)), round(STATS(i).Centroid(1)),1);
    STATS(i).Green = data.cur(round(STATS(i).Centroid(2)), round(STATS(i).Centroid(1)),2);
    STATS(i).Blue = data.cur(round(STATS(i).Centroid(2)), round(STATS(i).Centroid(1)),3);
    
    STATS(i).lowestEuclideanDistance = 1000000;
    for j = 1:size(colorsName,2)
        currDistance = round(sqrt((colorsNum{j}(1) - double(STATS(i).Red))^2 + (colorsNum{j}(2) - double(STATS(i).Green))^2 + (colorsNum{j}(3) - double(STATS(i).Blue))^2));
        if currDistance < STATS(i).lowestEuclideanDistance
            STATS(i).colorIndex = j;
            STATS(i).lowestEuclideanDistance = currDistance;
        end
    end

    %Plot Centroid and Shape Label
    plot(STATS(i).Centroid(1),STATS(i).Centroid(2),'kO','MarkerFaceColor', 'k', 'MarkerSize', 3);
    text(STATS(i).Centroid(1) - 10,STATS(i).Centroid(2) + 25, STATS(i).Shape, 'Color', colorsName{STATS(i).colorIndex});

end



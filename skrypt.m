close all

imagefiles = dir('*.jpg');
nfiles = length(imagefiles);
for index=1:nfiles
    currentImage = rgb2gray(imread( imagefiles(index).name));
    [x, y] = size(currentImage);
    %calculate maxiumum size of area
    minimumSize = uint32(x*0.09 * y*0.09);
    MaximumSize = uint32(x*0.25 * y*0.25);
    blurValue = floor(y / 100);
    %display original image
    subplot(1, 3, 3);
    imshow(currentImage)
    title('original image')
    
    %first noise reduce
    reducedNoiseImage = wiener2(currentImage,[blurValue,blurValue]);
    subplot(1, 3, 1);
    imshow(reducedNoiseImage)
    title('first noise reduce')
    waitforbuttonpress
    
    %second noise reduce
    reducedNoiseImage = medfilt2(reducedNoiseImage);
    subplot(1, 3, 1);
    imshow(reducedNoiseImage)
    title('second noise reduce')
    waitforbuttonpress
    
    %binarize
    %binarized = imbinarize(currentImage);
    binarized = currentImage > 100;
    subplot(1, 3, 1);
    imshow(binarized)
    title('binarize')
    waitforbuttonpress
    
    %remove hudge areas bigger than 20000 pixels
    hudge = bwareaopen(binarized, double(MaximumSize));
    binarized = xor(binarized,hudge);
    subplot(1, 3, 1);
    imshow(binarized)
    title(['remove hudge areas bigger than', num2str(MaximumSize),' pixels'])
    waitforbuttonpress
    
    %remove small areas less than 2000 pixels
    binarized = bwareaopen(binarized, double(minimumSize));
    subplot(1, 3, 1);
    imshow(binarized)
    title(['remove small areas less than ', num2str(minimumSize),' pixels'])
    waitforbuttonpress
    
    
    
    Iprops = regionprops(binarized,'BoundingBox','FilledArea','Image','Perimeter','Centroid','PixelList');
    count = numel(Iprops);
    coloredRegions = bwlabel(binarized);
    %removing shapes that proportions are for sure wrong
    for i = 1:count
        width = Iprops(i).BoundingBox(3);
        height = Iprops(i).BoundingBox(4);
        proportions = width / height;
        boundingBox = floor(Iprops(i).BoundingBox);
        plate = imcrop(currentImage,Iprops(i).BoundingBox);
        subplot(1, 3, 2);
        imshow(plate)
        fragment = imcrop(binarized,boundingBox);
        numberOfCells = numel(fragment);
        numberOfZeros = numberOfCells - nnz(fragment);
        coverage = numberOfZeros / numberOfCells;
        
        title('founded area')
        %text(25, 25,...
        %    num2str(proportions), 'Color', 'b','FontSize',15);
        %text(55, 55,...
        %    num2str(coverage), 'Color', 'r','FontSize',15);
        
        if((proportions < 3) || (proportions > 6.6) || (coverage < 0.2))
            startX = uint32(floor(boundingBox(2)));
            if(startX ==0)
                startX = 1;
            end
            lenghtX = uint32(floor(boundingBox(4)));
            startY = uint32(floor(boundingBox(1)));
            if(startY ==0)
                startY = 1;
            end
            lenghtY = uint32(floor(boundingBox(3)));
            endX = startX + lenghtX;
            if endX >x
                endX = x;
            end
            endY = startY + lenghtY;
            if endY >y
                endY = y;
            end
            for x1 =startX:endX
                for y1 = startY:endY
                    if(coloredRegions(x1,y1) == i)
                        binarized(x1,y1) = 0;
                    end
                end
            end
        end
        
        subplot(1, 3, 1);
        imshow(binarized)
        title('removing wrong islands')
        waitforbuttonpress
    end
    
    %convexhull
    binarized = bwconvhull(binarized,'objects');
    subplot(1, 3, 1);
    imshow(binarized)
    title('convex hull')
    waitforbuttonpress
    
    %count the roundes of every area
    Iprops = regionprops(binarized,'BoundingBox','FilledArea','Image','Perimeter','Centroid');
    count = numel(Iprops);
    
    score = zeros(count,1);
    bestproportions = 5.2;
    bestCircularity = 2;
    bestCoverage = 0;
    if(count ~= 0)
        circularities = [Iprops.Perimeter].^2 ./ (4 * pi * [Iprops.FilledArea]);
        area = Iprops.FilledArea;
        boundingBox = Iprops.BoundingBox;
        finalImage = Iprops.Image;
        %find biggest area from binary image
        subplot(1, 3, 3);
        title('original image with roundes')
        for i = 1:count
            boundingBox = Iprops(i).BoundingBox;
            width = Iprops(i).BoundingBox(3);
            height = Iprops(i).BoundingBox(4);
            proportions = width / height;
            proportionsDifference = abs(proportions - bestproportions);
            circularityDiffernece = abs(circularities(i) - bestCircularity);
            fragment = imcrop(binarized,boundingBox);
            numberOfCells = numel(fragment);
            numberOfZeros = numberOfCells - nnz(fragment);
            coverage = numberOfZeros / numberOfCells;
            
            score(i) = coverage + circularityDiffernece + proportionsDifference;
            
            text(Iprops(i).Centroid(1)-500, Iprops(i).Centroid(2),...
                num2str(circularities(i)), 'Color', 'r', 'FontSize',14);
            text(Iprops(i).Centroid(1)-500, Iprops(i).Centroid(2)+50,...
                num2str(proportions), 'Color', 'b', 'FontSize',14);
            text(Iprops(i).Centroid(1)-500, Iprops(i).Centroid(2)+100,...
                num2str(coverage), 'Color', 'g', 'FontSize',14);
            text(Iprops(i).Centroid(1)-500, Iprops(i).Centroid(2)+150,...
                num2str(score(i)), 'Color', 'black', 'FontSize',14);
            
        end
        waitforbuttonpress
        bestIndex = 1;
        minValue = score(1) ;
        for i = 2: numel(score)
            if(score(i) <  minValue)
                bestIndex = i;
                minValue = score(i);
            end
        end
        plate = imcrop(currentImage,Iprops(bestIndex).BoundingBox);
        subplot(1, 3, 1);
        imshow(plate)
        title('founded area')
        waitforbuttonpress
    end
end
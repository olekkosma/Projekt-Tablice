close all
correct = 0;
wrong = 0;
noFind = 0;
number = 0;
timeSum = 0;
imagefiles = dir('*.jpg');
nfiles = length(imagefiles);
for index=1:100
    tic;
    currentImage = rgb2gray(imread( imagefiles(index).name));
    for multiplier = 0:0.4
        number = number + 1;
        plate = 0;
        currentImage = imresize(currentImage,1-multiplier);
        [x, y] = size(currentImage);
        minimumSize = uint32(x*0.05 * y*0.05);
        MaximumSize = uint32(x*0.35 * y*0.35);
        blurValue = floor(y / 100);
        subplot(1, 2, 2);
        imshow(currentImage)
        title('original image')
        reducedNoiseImage = wiener2(currentImage,[blurValue,blurValue]);
        reducedNoiseImage = medfilt2(reducedNoiseImage);
        binarized = imbinarize(currentImage);
        hudge = bwareaopen(binarized, double(MaximumSize));
        binarized = xor(binarized,hudge);
        binarized = bwareaopen(binarized, double(minimumSize));
        
        
        Iprops = regionprops(binarized,'BoundingBox','FilledArea','Image','Perimeter','Centroid','PixelList');
        count = numel(Iprops);
        coloredRegions = bwlabel(binarized);
        for i = 1:count
            width = Iprops(i).BoundingBox(3);
            height = Iprops(i).BoundingBox(4);
            proportions = width / height;
            boundingBox = floor(Iprops(i).BoundingBox);
            
            fragment = imcrop(binarized,boundingBox);
            
            numberOfCells = numel(fragment);
            numberOfZeros = numberOfCells - nnz(fragment);
            coverage = numberOfZeros / numberOfCells;
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
        end
        binarized = bwconvhull(binarized,'objects');
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
                
            end
            bestIndex = 1;
            minValue = score(1) ;
            for i = 2: numel(score)
                if(score(i) <  minValue)
                    bestIndex = i;
                    minValue = score(i);
                end
            end
            plate = imcrop(currentImage,floor(Iprops(bestIndex).BoundingBox));
            
            subplot(1, 2, 2);
            imshow(currentImage);
            hold on;
            plot(Iprops(bestIndex).Centroid(1),Iprops(bestIndex).Centroid(2),'c*')
            hold off;
            rectangle('Position', boundingBox,...
                'EdgeColor','r','LineWidth',2 )
            
        end
        subplot(1, 2, 1);
        imshow(plate)
        title(['founded plate | image nr. ', num2str(number)])
        time =  toc;
        timeSum = timeSum + time;
        w = waitforbuttonpress;
        key = get(gcf,'currentcharacter');
        while (any(~ismember(key,[49,50,51,52]))) || (w ~= 1)
            disp(key)
            w = waitforbuttonpress;
            key = get(gcf,'currentcharacter');
        end
        
        switch key
            case 49
                wrong = wrong + 1;
                disp(['Wrong plate detection ', num2str(wrong)])
            case 50
                correct = correct + 1;
                disp(['Correct plate detection ', num2str(correct)])
            case 51
                noFind = noFind + 1;
                disp(['No plate detected ', num2str(noFind)])
            case 52
                disp(['results: correct', num2str(correct), ' wrong ',num2str(wrong), ' didnt find ',num2str(noFind)])
            otherwise
        end
    end
end
disp(timeSum)
disp(timeSum/index)
disp(['results: correct', num2str(correct), ' wrong ',num2str(wrong), ' didnt find ',num2str(noFind)])


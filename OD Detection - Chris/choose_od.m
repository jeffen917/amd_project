function [ candidate_region, max_od_strength ] = choose_od( od_img, vessels, angles,varargin )
debug = -1;
if length(varargin) == 1
    debug = varargin{1};
elseif isempty(varargin)
    debug = 1;
else
    throw(MException('MATLAB:paramAmbiguous','Incorrect number of input arugments'));
end
    
% Finds optic disk region of interest
addpath('..');

%Get vessels and angles of greatest lineop strength
angles(~vessels) = 0;

[origy, origx] = size(angles);
angle_map = mod(angles,180);
%  maxpad = 100;
%  angles = padarray(angles, [maxpad maxpad], 'symmetric', 'both');
% 
 %adjust "mirroring" so angles translate over
% angles(1:maxpad,maxpad:2*maxpad-1) = 180 - angles(1:maxpad,maxpad:2*maxpad-1);
% angles(2*maxpad:2*maxpad+maxpad-1,maxpad:2*maxpad-1) = 180 - angles(2*maxpad:2*maxpad+maxpad-1,maxpad:2*maxpad-1);
% angles(maxpad:2*maxpad-1,1:maxpad) = 180 - angles(maxpad:2*maxpad-1,1:maxpad);
% angles(maxpad:2*maxpad-1,2*maxpad:2*maxpad+maxpad-1) = 180 - angles(maxpad:2*maxpad-1,2*maxpad:2*maxpad+maxpad-1); 


%Interpolate
% [y, x, angs] = find(angles);
% [xq, yq] = meshgrid(1:size(angles,2), 1:size(angles,1));
% angle_map = griddata(x, y, angs, xq, yq,'cubic');
% angle_map = angle_map(maxpad+1:maxpad+origy,maxpad+1:maxpad+origx);
% if(debug==2)
%     figure(5), imshow(mat2gray(angle_map))
% end

%Run correlation on this mofo
od_img = labelmatrix(bwconncomp(od_img));
od_filter = load('od_masks', 'mask150', 'mask200', 'mask250');

if(debug == 1 || debug == 2)
    disp('Running angle filtering')
end

e = cputime;
scales = [150 200 250];
strength_img = zeros(origy, origx,length(scales));
for k = 1:length(scales)
    full_mask = od_filter.(['mask',num2str(scales(k))]);
    for y = 1:16:768
        tb = y - scales(k)/2;
        bb = y + scales(k)/2-1;
        ymask = full_mask;
        if y <= scales(k)/2
            ymask = full_mask(scales(k)/2+1-(y-1):end,:);
            tb = 1;
        end
        if y > origy - scales(k)/2
            ymask = full_mask(1:scales(k)-(y+scales(k)/2-origy)+1,:);
            bb = origy;
        end
        for x = 1:16:768
            lb = x - scales(k)/2;
            rb = x + scales(k)/2-1;
            mask = ymask;
            if x <= scales(k)/2
                mask = ymask(:,scales(k)/2+1-(x-1):end);
                lb = 1;
            end
            if x > origx - scales(k)/2
                mask = ymask(:,1:scales(k)-(x+scales(k)/2-origx)+1);
                rb = origx;
            end
            %check if in texture of interest
            if od_img(y,x) > 0
                strength_img = corr2(angle_map(tb:bb,lb:rb),mask);
            end
        end
    end
end
t = (cputime-e)/60.0;
if(debug == 1 || debug == 2)
    disp(['Time to run angle filtering (min): ' num2str(t)])
end

%Only keep region containing max correlation
strength_img = max(strength_img,[],3);
max_od_strength = max(strength_img(:));
[max_y, max_x, ~] = find(strength_img==max_od_strength);
if debug == 2
    figure(5), imshow(mat2gray(strength_img))
    hold on
    plot(max_x,max_y,'gx')
    hold off
end
candidate_region = zeros(size(od_img)); 
for y = 1:size(od_img,1)
    for x = 1:size(od_img,2)
        if od_img(y,x) == od_img(max_y,max_x);
            candidate_region(y,x) = 1;
        end
    end
end
candidate_region = logical(candidate_region);

end


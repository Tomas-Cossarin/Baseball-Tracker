%**************************************************************************
% ENGO 559 Project 1 Baseball detection and tracking
% Author: Tomas Cossarin
% January 16, 2024
%
% This script takes in two videos, dclipA and dclipB. A and B correspond to 
% the two cameras used to record these videos. Each video contains a pitch
% from a baseball game. The location of the pitch is determined in each
% frame using a combination of object detection and tracking. Two balls
% appear in each frame, indicated with a 1 or 2.
%
% The detections are returned in two structs, ballA and ballB.
% The struct is contructed as follows
%
%  ballA.x     = column of detected ball
%       .y     = row of detected ball
%       .frame = frame number containing detected ball
%       .image = image # within frame containing detected ball
%                image will be either 1 or 2
%**************************************************************************


function [ballA, ballB] = pitchfx_detect(dclipA, dclipB)    % mina function   
    ballA = detect(dclipA, 1);
    ballB = detect(dclipB, 2);
    
	function ballX = detect(dclip, cam)
        ballX_template = struct('x', NaN, 'y', NaN, 'frame', NaN, 'image', NaN);    % template for the output struct
        ballX = repmat(ballX_template, size(dclip, 3) * 2, 1);                      % create array of structs for each ball
        
        template_filename = strjoin({'ball_template_', int2str(cam), '.csv'}, '');  % load ball template to match with images
        template = load(template_filename);
        offset = round(size(template, 1) / 2);
        prev_dx = nan;
        
        if cam == 1
            top = 150;  left = 100;         % pick starting bounds of where to search in image for given camera
            threshold = 0.007;              % pick threshold for given camera
        else
            top = 150;  left = 420;
            threshold = 0.003;
        end
        window_height = 130;                % size of search area
        window_width = 200;
        
        for frame = 1 : size(dclip, 3)-5
            fprintf('%i ', frame)
            img0 = dclip(:, :, frame);    	% get image
            img_height = size(img0, 1);     % image dimensions
            img_width = size(img0, 2);
            
            bot = top + window_height;    	% calculate window bounds
            right = left + window_width;
            bot = min(bot, img_height);
            right = min(right, img_width);

            bounded_img = apply_bounds(img0, top, bot, left, right);	% mask out unused parts of image
            edged_img = detect_edges(bounded_img);                     	% detect horizontal lines in image
            blurred_img = convolve(edged_img);                        	% blur edges to make balls circular

            match = match_template(blurred_img, template, top, bot, left, right); % template match the balls
            
             if frame > 2                               % requires at least two previous frames
                 [dx, dy] = trajectory(ballX, frame);	% predict location of balls from previous trajectory
                 if ~isnan(dx)                          % if previous images contain balls
                     if ~isnan(prev_dx)
                        dx = round((dx + prev_dx) / 2);	% take average of last 2 dxs
                     end
                     
                     prev1 = ballX(2*(frame-2)+1);      % ball1 from previous frame
                     if ~isnan(prev1.x)
                        match = adjust_match(match, prev1.x+dx, prev1.y+dy, offset); % adjust match based on trajectory of ball1
                     end
                     
                     prev2 = ballX(2*(frame-2)+2);      % repeat with ball2
                     if ~isnan(prev2.x)
                        match = adjust_match(match, prev2.x+dx, prev2.y+dy, offset);
                     end
                 end
                 prev_dx = dx;
             end
            
            logic = match > threshold;          % only keep matches within threshold
            islands = regionprops(logic);       % group adjacent matches
            
            if size(islands, 1) ~= 0            % if contains match(es)
                for island = 1 : size(islands, 1)
                    [ballX, top, left] = locate_balls(ballX, islands, cam, frame, top, left, offset);	% locate balls and add to matrix of structs
                end
                
                window_height = 70;
                window_width = 120;
            end
        end
    end

    function match = adjust_match(match, x, y, offset)  % adjust match based on trajectory of ball
        factor = 3;                                     % multiply matches by factor of 3 near predicted locations from trajectory
        for i = y-4 : min(y+4, size(match, 1))
            for j = x-4 : min(x+4, size(match, 2))
                match(i-offset, j-offset) = match(i-offset, j-offset) * factor;
            end
        end
    end
    
    function [dx, dy] = trajectory(ballX, frame)    % get trajectory of ball from previous two frames
        dx_sum = 0;
        dy_sum = 0;
        count = 0;
        % get change in x and y for each image from previous two frames
        for image = 1 : 2
            prev = ballX(2*(frame-2) + image);      % balls detected in previous frame
            preprev = ballX(2*(frame-3) + image);   % and before previous frame

            if ~isnan(preprev.x) && ~isnan(prev.x)
                dx_sum = dx_sum + prev.x - preprev.x;
                dy_sum = dy_sum + prev.y - preprev.y;
                count = count + 1;
            end
        end
        adj = 1.03;                         % adjustment due to camera angle
        dx = round(adj*dx_sum / count);     % take average dx and dy of both balls in frame
        dy = round(adj*dy_sum / count);
    end


    function [ballX, top, left] = locate_balls(ballX, islands, cam, frame, top, left, offset)
        detections = zeros(size(islands, 1), 4);    % centroids of islands become detected balls
        for detection = 1 : size(islands, 1)
            detections(detection, :) = [frame, detection, round(islands(detection).Centroid(1)), round(islands(detection).Centroid(2))];
        end

        detections = sortrows(detections, 3);       % sort detected balls from left to right
        if cam == 2                                 % right to left if camera B
            detections = flip(detections, 1);
        end
        
        if size(detections, 1) ~= 0                 % slide search window based on new location of balls
            if cam == 1
                top = detections(end, 4) - 15;
                left = detections(end, 3) + 10;
            else
                top = detections(end, 4) - 10;
                left = detections(end, 3) - 110;
            end
            top = max(1, top);
            left = max(1, left);
        end

        for detection = 1 : size(detections, 1)     % add detections to output array of structs
            row = detections(detection, :);
            n = 2*(frame-1) + detection;
            ballX(n).frame = row(1);
            ballX(n).image = row(2);
            ballX(n).x = row(3) + offset - 1;
            ballX(n).y = row(4) + offset - 1;
        end
    end


    function match = match_template(img, template, top, bot, left, right)   % template match balls
        template_size = size(template, 1);
        match = zeros(size(img));
        
        for i = top : bot - template_size                                   % slide through every part of frame
            for j = left : right - template_size
                sample = img(i : i+template_size-1, j : j+template_size-1); % sample of image to check against template
                diff2 = (template - sample).^2;                             % sum of squared differences
                match(i, j) = size(template, 1)^2 / sum(sum(diff2));        % take inverse to bigger number = better match
            end
        end
    end


    function img2 = convolve(img)           % convolution used for blurring
        img2 = zeros(size(img));
        kernel = ones(3) / 7;               % blurring kernel
        
        for i = 1 : size(img, 1)-2          % convolve
            for j = 1 : size(img, 2)-2
                if ~isnan(img(i, j))
                    square = img(i:i+2, j:j+2);
                    product = square * kernel;
                    img2(i, j) = sum(sum(product));
                end
            end
        end
    end

    function edges = detect_edges(img)  % detect horizontal stripes in image
        edges = zeros(size(img));
        summ = 0;
        count = 0;
        
        for i = 1 : size(img, 1) - 1
            for j = 1 : size(img, 2)
                diff = abs( img(i, j) - img(i+1, j) );  % take absolute difference of DN between vertically adjacent pixels
                if ~isnan(diff) && diff > 10
                    edges(i, j) = diff;
                    summ = summ + diff;
                    count = count + 1;
                end
            end
        end
        av = summ / count;              % only keep edges with greater than average differences (remove noise)
        for i = 1 : size(edges, 1)
            for j = 1 : size(edges, 2)
                if edges(i, j) < av
                   edges(i, j) = 0; 
                end
            end
        end
    end

    function img = apply_bounds(img0, top, bot, left, right)    % mask pixels outside search window
        img = NaN(size(img0));                                  % outside window is NaN
        
        for i = top : bot
            for j = left : right
                img(i, j) = img0(i, j);                         % inside is original values
            end
        end
    end

    function create_template(img)   % create ball template used for matching
        figure
        imshow(uint8(img))
        h = impoly;
        mask = createMask(h);
        for i = 1 : size(img, 1)
            for j = 1 : size(img, 2)
                if mask(i, j) == 0
                    img(i, j) = nan;
                end
            end
        end
        csvwrite('ball.csv', img)
    end
end
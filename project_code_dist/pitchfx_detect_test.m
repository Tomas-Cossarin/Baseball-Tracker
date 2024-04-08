function [ballA, ballB] = pitchfx_detect2(dclipA, dclipB)    
    ballA = detect(dclipA, 1);
    ballB = detect(dclipB, 2);
    
	function ballX = detect(dclip, cam)
        ballX_template = struct('x', NaN, 'y', NaN, 'frame', NaN, 'image', NaN);
        ballX = repmat(ballX_template, size(dclip, 3) * 2, 1);
%         size(dclip)
%         ballX
        
        template_filename = strjoin({'ball_template_', int2str(cam), '.csv'}, '');
        template = load(template_filename);
        offset = round(size(template, 1) / 2);
        prev_dx = nan;
        
        if cam == 1                         % pick starting bounds and threshold for given camera
            top = 150;  left = 100;
            threshold = 0.006;
        else
            top = 150;  left = 420;
            threshold = 0.003;
        end
        window_height = 130;
        window_width = 200;
        
        for frame = 1:13%size(dclip, 3)
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
            SE = strel('square', 3);
            edged_img2 = imopen(edged_img, SE);
            blurred_img = convolve(edged_img2);                        	% blur edges to make balls circular
            
%             SE = strel('square', 2);                                    % remove noise
%             blurred_img = imopen(blurred_img, SE);
            
            

            match = match_template(blurred_img, template, top, bot, left, right);	% template match the balls
            
             if frame > 2
                 [dx, dy] = trajectory(ballX, frame);	% predict location of balls from previous trajectory
                 if ~isnan(dx)
                     if ~isnan(prev_dx)
                        dx = round((dx + prev_dx) / 2);	% take average of last 2 dxs
                     end
                     
                     prev1 = ballX(2*(frame-2)+1);      % ball1 from previous frame
                     if ~isnan(prev1.x)                 % adjust match based on trajectory of ball1
                        match = adjust_match(match, prev1.x+dx, prev1.y+dy, offset, cam);
                     end
                     
                     prev2 = ballX(2*(frame-2)+2);      % repeat with ball2
                     if ~isnan(prev2.x)
                        match = adjust_match(match, prev2.x+dx, prev2.y+dy, offset, cam);
                     end
                 end
                 prev_dx = dx;
             end
            
            logic = match > threshold;     	% matches within threshold
            islands = regionprops(logic);	% group adjacent matches
            
            if size(islands, 1) ~= 0      	% if contains possible match(es)
                has_match = 0;
                for island = 1 : size(islands, 1)
                    if cam==2 || islands(island).Area > 3 	% if enough adjacent matches in cam A
                        [ballX, top, left] = locate_balls(ballX, islands, cam, frame, top, left, offset);	% locate balls and add to matrix of structs
                        has_match = 1;
                    end
                end
                if has_match == 1
                    window_height = 70;
                    window_width = 120;
                end
            end
            
            
            
            figure
%             imshow(uint8(bounded_img))
%             figure
%             imshow(uint8(edged_img))
%             figure
            imshow(uint8(edged_img2))
            figure
            imshow(uint8(blurred_img))
%             figure
%             imshow(uint8(1./match))
%             
%             subplot(3,2,1), imshow(uint8(img0))
%             subplot(2,2,2), imshow(uint8(img))
%             subplot(2,2,3), imshow(uint8(1./match))

            
        end
    end

    function match = adjust_match(match, x, y, offset, cam)
        if cam == 1
            factor = 2.5;
        else
            factor = 8;
        end
        for i = y-4 : min(y+4, size(match, 1))
            for j = x-4 : min(x+4, size(match, 2))
                match(i-offset, j-offset) = match(i-offset, j-offset) * factor;
            end
        end
    end
    
    function [dx, dy] = trajectory(ballX, frame)
        dx = 0;
        dy = 0;
        count = 0;
        % get change in x and y for each image from previous two frames
        for image = 1 : 2
            preprev = ballX(2*(frame-3) + image);
            prev = ballX(2*(frame-2) + image);

            if ~isnan(preprev.x) && ~isnan(prev.x)
                dx = dx + prev.x - preprev.x;
                dy = dy + prev.y - preprev.y;
                count = count + 1;
            end
        end
        adj = 1.03;                    % adjustment from camera angle
        dx = round(adj*dx / count);    % take average of images
        dy = round(adj*dy / count);
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
        
        if size(detections, 1) ~= 0                 % slide window
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

        for detection = 1 : size(detections, 1)     % add to matrix of structs
            row = detections(detection, :);
            n = 2*(frame-1) + detection;
            ballX(n).frame = row(1);
            ballX(n).image = row(2);
            ballX(n).x = row(3) + offset;
            ballX(n).y = row(4) + offset;
        end
    end


    function match = match_template(img, template, top, bot, left, right)
        template_size = size(template, 1);
        match = zeros(size(img));
        
        for i = top : bot - template_size
            for j = left : right - template_size
                sample = img(i : i+template_size-1, j : j+template_size-1);
                diff2 = (template - sample).^2;                      % sum of squared differences
                SSD_inv = size(template, 1)^2 / sum(sum(diff2));
                match(i, j) = SSD_inv;
            end
        end
    end


    function img2 = convolve(img)
        img2 = zeros(size(img));
        kernel = ones(3) / 7;
        
        for i = 1 : size(img, 1)-2
            for j = 1 : size(img, 2)-2
                if ~isnan(img(i, j))
                    square = img(i:i+2, j:j+2);
                    product = square * kernel;
                    img2(i, j) = sum(sum(product));
                end
            end
        end
        img2 = abs(img2);
    end

    function edges = detect_edges(img)
        edges = zeros(size(img));
        summ = 0;
        count = 0;
        
        for i = 1 : size(img, 1) - 1
            for j = 1 : size(img, 2)
                diff = abs( img(i, j) - img(i+1, j) );
                if ~isnan(diff) && diff > 10
                    edges(i, j) = diff;
                    summ = summ + diff;
                    count = count + 1;
                end
            end
        end
        av = summ / count;
        for i = 1 : size(edges, 1)
            for j = 1 : size(edges, 2)
                if edges(i, j) < av
                   edges(i, j) = 0; 
                end
            end
        end
    end

    function img = apply_bounds(img0, top, bot, left, right)
        img = NaN(size(img0));
        
        for i = top : bot
            for j = left : right
                img(i, j) = img0(i, j);
            end
        end
    end

        function create_mask(img)
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
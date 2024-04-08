clear all
close all
%**************************************************************************
% ENGO 559 PitchF/X Project
%
% This script reads a PitchF/X .asf video clips from camera A and B and 
% detects a baseball in as many frames as possible. The image coordinates
% of the detected balls are compared with those from the PitchFX system.
% A time stamp is assigned to each ball, and the image coordinates of the 
% ball from the two cameras are used to solve for the coefficients of the 
% equations of motion, assuming constant acceleration. 
% The estimated coefficients are compared with those estimates by the 
% PitchFX system. The time vector and the coefficients are used to calculate 
% real world 3D coordinates of every ball position, which are then plotted,
% along with the PitchFX ball positions.
%
% Note that the original .asf video files are not supported on the Mac,
% so I downloaded "Smart Converter" from the App Store, and converted the
% video file to .mp4.
%
%  This first project requires students to find or 'detect' a baseball in
%  frames of a video clip.  In theory we are looking for a single object 
%  in each frame.  In practice, the frame rate of the video cameras used 
%  in the PitcgFX system gives us two ball images in each frame.
%
%  In this project we know exactly what we are looking for. In other words
%  we have a-priori information.
%
%  The problem in this project is to determine what a baseball looks like 
%  in the image and develop a description of that.  Students should start 
%  by choosing a few pitches and looking carefully at every ball in every 
%  frame and develping a desiption that is general enough to cover every 
%  ball, but narrow enough to isolate the ball and nothing else.  
%  Perhaps you can use one baseball as a template and do template matching.  
%  Perhaps the baseball is very bright compared with all the other pixels, 
%  and you can threshold the image to find bright pixels.
%  It may be helpful to only look for the ball where you know a-priori the
%  ball is going to be.  There is no point looking for the ball in the
%  rafters of the stadium.  This is another form of a-priori information.
%  It involves defining a region-of-interest or ROI.
%
% Sometimes the description of what we are looking for in an image is not
% accurate enough and the cost of mis-identifying an object is fatal.
% Recall cases of the military mis-identifying a passenger jet as a hostile
% aircraft and shooting it down.
%
% This script is a template for the project. Your job is to write the
% function pitchfx_detect(), which takes the the array of frames from the two
% two caneras, returned by pitchfx_read_video(), and returns two struct 
% arrays ballA and ballB.  These have the following structure:
%
%  ballA.x     = column of detected ball
%       .y     = row of detected ball
%       .frame = frame number containing detected ball
%       .image = image # within frame containing detected ball
%                image will be either 1 or 2
%
%  m.j.collins april.2016
%**************************************************************************

%--------------------------------------------------------------------------
% call function to read PitchFX video data
%--------------------------------------------------------------------------
[dclipA,dclipB,pitch_path] = pitchfx_read_video();
%--------------------------------------------------------------------------
% get dimensions of the video data.
%--------------------------------------------------------------------------
[nrA,ncA,nfA] = size(dclipA);
[nrB,ncB,nfB] = size(dclipB);
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%  Start of Detection Phase
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

[ballA, ballB] = pitchfx_detect(dclipA,dclipB);

% Your job is to write the detection function above.
% This function returns two arrays of structs: ballA and ballB
% These two arrays are organized as

% ballA(i).x
% ballA(i).y
% ballA(i).frame
% ballA(i).image
% where i runs from 1 to the number of balls detected in the camera A video

%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%  End of Detection Phase
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%--------------------------------------------------------------------------
% show each image with the positions of all detected  balls plotted on top
%--------------------------------------------------------------------------

for frame = 2:nfA
image(dclipA(:,:,frame))
colormap(gray(256))
title(['Camera A  Frame ' num2str(frame)])
hold on

%plot(x_ROI_A,y_ROI_A,'y*')

for ball = 1:length(ballA)
    if frame == ballA(ball).frame
        plot(ballA(ball).x,ballA(ball).y,'r+')
    end
end

hold off
pause(0.25)
end


for frame = 2:nfB
image(dclipB(:,:,frame))
colormap(gray(256))
title(['Camera B  Frame ' num2str(frame)])
hold on

%plot(x_ROI_B,y_ROI_B,'y*')

for ball = 1:length(ballB)
    if frame == ballB(ball).frame
        plot(ballB(ball).x,ballB(ball).y,'r+')
    end
end

hold off
pause(0.25)
end

close

%--------------------------------------------------------------------------
% compare detected ball positions with those in PitchFX blobs.csv file
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% get the data from the blobs.csv file
%--------------------------------------------------------------------------
blob = pitchfx_get_blobs_csv(pitch_path);

sxA = blob.xA'; syA = blob.yA'; 
sxB = blob.xB'; syB = blob.yB'; 
tA = blob.tA';   tB = blob.tB';

% Use 5 pixels as the distance threshold for a match.
d_threshold = 5;
 
% *** Camera A
fprintf(1,'**** Camera A\n');
% loop through the detected balls and find the pfx ball that is closest to each.
diffsA = NaN(length(ballA), 3);

for ball = 1:length(ballA)
    min_d = 999;
    for pfx_ball = 1:length(sxA)
        dpos = sqrt((ballA(ball).x - sxA(pfx_ball))^2 + (ballA(ball).y - syA(pfx_ball))^2);
        if dpos < min_d && dpos < d_threshold
            min_ball = pfx_ball;
            min_d = dpos;
        end
    end
    % if min_d < 999 the a matching pitchfx ball is found
    % in this case we can use the pitchfx time stamp for this ball
    if min_d < 999
        pfx_match(ball) = min_ball;
        d_match(ball) = min_d;
        
        % set the time of this ball
        ballA(ball).time = tA(min_ball);
        
        dx = sxA(min_ball) - ballA(ball).x;
        dy = syA(min_ball) - ballA(ball).y;
        fprintf(1,'** ball %2d : (%5.1f %5.1f) - PFX ball %2d : (%5.1f,%5.1f)\n',ball,ballA(ball).x,ballA(ball).y,min_ball,sxA(min_ball),syA(min_ball));
        fprintf(1,'**    difference: (%5.3f,%5.3f) time = %f\n',dx,dy,tA(min_ball));
        diffsA(ball, :) = [dx, dy, sqrt(dx^2 + dy^2)];  
    else
    % if min_d is still set to 999, then no matching pitchfx ball was found
    % in this case, set the time stamp to -99, so this ball can be filtered
    % out
        pfx_match(ball) = -99;
        ballA(ball).time = -99;
        fprintf(1,'** ball %2d: (%5.1f %5.1f) - no matching PFX ball\n',ball,ballA(ball).x,ballA(ball).y)
    end
end

clear min_ball

% *** Camera B
fprintf(1,'**** Camera B\n');
% loop through the detected balls and find the pfx ball that is closest to each.
diffsB = NaN(length(ballB), 3);

for ball = 1:length(ballB)
    min_d = 999;
    for pfx_ball = 1:length(sxB)
        dpos = sqrt((ballB(ball).x - sxB(pfx_ball))^2 + (ballB(ball).y - syB(pfx_ball))^2);
        if dpos < min_d && dpos < d_threshold
            min_ball = pfx_ball;
            min_d = dpos;
        end
    end
    if min_d < 999
        pfx_match(ball) = min_ball;
        d_match(ball) = min_d;
        
        % set the time of this ball
        ballB(ball).time = tB(min_ball);
        
        dx = sxB(min_ball) - ballB(ball).x;
        dy = syB(min_ball) - ballB(ball).y;
        fprintf(1,'** ball %2d : (%5.1f %5.1f) - PFX ball %2d : (%5.1f,%5.1f)\n',ball,ballB(ball).x,ballB(ball).y,min_ball,sxB(min_ball),syB(min_ball));
        fprintf(1,'**   difference: (%5.3f,%5.3f), time = %f\n',dx,dy,tB(min_ball));
        diffsB(ball, :) = [dx, dy, sqrt(dx^2 + dy^2)];  
        
    else
        pfx_match(ball) = -99;
        ballB(ball).time = -99;
        fprintf(1,'** ball %2d: (%5.1f %5.1f) - no matching PFX ball\n',ball,ballB(ball).x,ballB(ball).y)
    end
end

%--------------------------------------------------------------------------
% loop through each ball and create a new ball struct array that includes
% detected balls that match a pitchfx ball, i.e. balls that have a valid 
% time stamp.
%--------------------------------------------------------------------------


new_ball = 1;
for ball = 1:length(ballA)
    if ballA(ball).time > 0
        newballA(new_ball).x = ballA(ball).x;
        newballA(new_ball).y = ballA(ball).y;
        newballA(new_ball).frame = ballA(ball).frame;
        newballA(new_ball).image = ballA(ball).image;
        newballA(new_ball).time = ballA(ball).time;
        new_ball = new_ball + 1;
    end
end

new_ball = 1;
for ball = 1:length(ballB)
    if ballB(ball).time > 0
        newballB(new_ball).x = ballB(ball).x;
        newballB(new_ball).y = ballB(ball).y;
        newballB(new_ball).frame = ballB(ball).frame;
        newballB(new_ball).image = ballB(ball).image;
        newballB(new_ball).time = ballB(ball).time;
        new_ball = new_ball + 1;
    end
end
        
%--------------------------------------------------------------------------
% call function to estimate coefficients of the equations of motion
%--------------------------------------------------------------------------
[initPosition,initVelocity,acceleration] = pitchfx_solve_pitch(newballA,newballB,pitch_path);

x0 = initPosition(1); y0 = initPosition(2); z0 = initPosition(3);
vx0 = initVelocity(1); vy0 = initVelocity(2); vz0 = initVelocity(3);
ax = acceleration(1); ay = acceleration(2); az = acceleration(3); 

fprintf(1,'*******  SVD solution *******\n')
fprintf(1,'initial position x0 = %f y0 = %f z0 = %f\n',x0,y0,z0);
fprintf(1,'initial velocity vx0 = %f vy0 = %f vz0 = %f\n',vx0,vy0,vz0);
fprintf(1,'initial acceleration ax = %f ay = %f az = %f\n',ax,ay,az);
fprintf(1,'initial speed = %f\n',sqrt(vx0^2+vy0^2+vz0^2)*0.681818);

%--------------------------------------------------------------------------
% open pitch.info and read the data into a string
%--------------------------------------------------------------------------
pitch = pitchfx_get_pitch_info(pitch_path);

pfx_x0  = pitch.initPosition(1); pfx_y0  = pitch.initPosition(2); pfx_z0  = pitch.initPosition(3);
pfx_vx0 = pitch.initVelocity(1); pfx_vy0 = pitch.initVelocity(2); pfx_vz0 = pitch.initVelocity(3);
pfx_ax  = pitch.acceleration(1); pfx_ay  = pitch.acceleration(2); pfx_az  = pitch.acceleration(3);

fprintf(1,'*******  PitchFX solution *******\n')
fprintf(1,'initial position x0 = %f y0 = %f z0 = %f\n',pfx_x0,pfx_y0,pfx_z0);
fprintf(1,'initial velocity vx0 = %f vy0 = %f vz0 = %f\n',pfx_vx0,pfx_vy0,pfx_vz0);
fprintf(1,'initial acceleration ax = %f ay = %f az = %f\n',pfx_ax,pfx_ay,pfx_az);
fprintf(1,'initial speed = %f\n',pitch.initSpeed);

%--------------------------------------------------------------------------
% Pull the time for each ball out of the ball struct arrays.
% Create an overall time vector, sort it, and subtract the minimum so that
% it starts at t0 = 0.
%--------------------------------------------------------------------------
for ball = 1:length(newballA)
    tA(ball) = newballA(ball).time;
end
for ball = 1:length(newballB)
    tB(ball) = newballB(ball).time;
end
tA = reshape(tA,[length(tA),1]); tB = reshape(tB,[length(tB),1]);
t = [tA; tB];
t = sort(t);
%t = t - min(t);
t = t - pitch.initTime;

% Calculate the 3D coordinates of the ball using our solution
wx = x0 + vx0*t + 0.5*ax*t.^2;
wy = y0 + vy0*t + 0.5*ay*t.^2;
wz = z0 + vz0*t + 0.5*az*t.^2;

% Calculate the 3D coordinates of the ball using the PitchFX solution
pfx_wx = pfx_x0 + pfx_vx0*t + 0.5*pfx_ax*t.^2;
pfx_wy = pfx_y0 + pfx_vy0*t + 0.5*pfx_ay*t.^2;
pfx_wz = pfx_z0 + pfx_vz0*t + 0.5*pfx_az*t.^2;

% plot the 3D ball position
figure
plot3(wx,wy,wz,'k*',pfx_wx,pfx_wy,pfx_wz,'b*')
xlabel('wx (feet)');
ylabel('wy (feet)');
zlabel('wz (feet)');
axis equal
axis([-10 10 0 60 0 6])
grid

diff_w = [pfx_wx - wx, pfx_wy - wy, pfx_wz - wz];
figure
plot3(diff_w(:,1), diff_w(:,2), diff_w(:,3), '*')
xlabel('dx (feet)');
ylabel('dy (feet)');
zlabel('dz (feet)');
axis equal
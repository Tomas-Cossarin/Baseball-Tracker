function[initPosition,initVelocity,acceleration] = pitchfx_solve_pitch(ballA,ballB,pitch_path)
%**************************************************************************
% ENGO 559 PitchF/X Project
%
% This function takes a set of {x,y) coordinates of detected ball positions
% from the two PitchFX cameras, along with a time stamp for each coordinate
% and returns the corresponding coefficients of the equations of motion.
%
% The details of how to do all this are in the patent describing the
% PitchFX baseball pitch tracking system.
%
%  https://www.google.com/patents/US20080219509
%
% input:
% sxA,syA : x (column) and y (row) image coordinates for camera A
% tA      : time stamp for each image coordinate
% sxB,syB : x (column) and y (row) image coordinates for camera B
% tB      : time stamp for each image coordinate
% pitch_path : the complete path containing the PitchFX data for this pitch
%
% output
% initPosition : a vector containg the (x,y,z) coordinate of the first
% location of the ball 
%
%  m.j.collins : april.2016
%
%**************************************************************************

% unpack data from ballA and ballB
for ball = 1:length(ballA)
    sxA(ball) = ballA(ball).x;
    syA(ball) = ballA(ball).y;
    tA(ball) = ballA(ball).time;
end

for ball = 1:length(ballB)
    sxB(ball) = ballB(ball).x;
    syB(ball) = ballB(ball).y;
    tB(ball) = ballB(ball).time;
end

sxA = reshape(sxA,[length(sxA),1]); syA = reshape(syA,[length(syA),1]);
sxB = reshape(sxB,[length(sxB),1]); syB = reshape(syB,[length(syB),1]); 
tA = reshape(tA,[length(tA),1]); tB = reshape(tB,[length(tB),1]);

nobs = 2*length(sxA)+2*length(sxB);
%--------------------------------------------------------------------------
% subtract the overall minimum time from the Camera A and B times, 
% and from the overall time vector, so the initial time is zero
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% get pitch.info data in order to get the initTime parameter
%--------------------------------------------------------------------------
pitch = pitchfx_get_pitch_info(pitch_path);

t = [tA; tB];
min_t = pitch.initTime;

tA = tA - min_t;
tB = tB - min_t;
%---------------------------------------------------------------------------
% call function to open the calibration parameter file for camera A and B 
% and read the contents into a struct
%--------------------------------------------------------------------------
camA = pitchfx_get_calibration(pitch_path,'camA.cam');
camB = pitchfx_get_calibration(pitch_path,'camB.cam');
%--------------------------------------------------------------------------
% normalize the transformation matrix M by m(3,4)
%--------------------------------------------------------------------------
camA.M = camA.M/camA.M(3,4);
camB.M = camB.M/camB.M(3,4);
%--------------------------------------------------------------------------
% remove radial lens distortion from image coordinates of ball
%--------------------------------------------------------------------------
for k = 1:length(sxA)
    [usxA(k), usyA(k)] = UnDistortScreenPoint(sxA(k), syA(k), camA);
    %fprintf(1,'distorted: (%f,%f) undistorted: (%f,%f)\n',sxA(k),syA(k),usxA(k),usyA(k));
end
for k = 1:length(sxB)
    [usxB(k), usyB(k)] = UnDistortScreenPoint(sxB(k), syB(k), camB);
    %fprintf(1,'distorted: (%f,%f) undistorted: (%f,%f)\n',sxA(k),syA(k),usxB(k),usyB(k));
end
%--------------------------------------------------------------------------
% setup U matrix section with camera A observations
%--------------------------------------------------------------------------
U = zeros(nobs,9);
k1 = 1;
for k2 = 1:length(usxA)
    U(k1,1) = (camA.M(1,1) - camA.M(3,1)*usxA(k2));
    U(k1,2) = (camA.M(1,1) - camA.M(3,1)*usxA(k2))*tA(k2);
    U(k1,3) = 0.5*(camA.M(1,1) - camA.M(3,1)*usxA(k2))*tA(k2)^2;
    U(k1,4) = (camA.M(1,2) - camA.M(3,2)*usxA(k2));
    U(k1,5) = (camA.M(1,2) - camA.M(3,2)*usxA(k2))*tA(k2);
    U(k1,6) = 0.5*(camA.M(1,2) - camA.M(3,2)*usxA(k2))*tA(k2)^2;
    U(k1,7) = (camA.M(1,3) - camA.M(3,3)*usxA(k2));
    U(k1,8) = (camA.M(1,3) - camA.M(3,3)*usxA(k2))*tA(k2);
    U(k1,9) = 0.5*(camA.M(1,3) - camA.M(3,3)*usxA(k2))*tA(k2)^2;
        
    U(k1+1,1) = (camA.M(2,1) - camA.M(3,1)*usyA(k2));
    U(k1+1,2) = (camA.M(2,1) - camA.M(3,1)*usyA(k2))*tA(k2);
    U(k1+1,3) = 0.5*(camA.M(2,1) - camA.M(3,1)*usyA(k2))*tA(k2)^2;
    U(k1+1,4) = (camA.M(2,2) - camA.M(3,2)*usyA(k2));
    U(k1+1,5) = (camA.M(2,2) - camA.M(3,2)*usyA(k2))*tA(k2);
    U(k1+1,6) = 0.5*(camA.M(2,2) - camA.M(3,2)*usyA(k2))*tA(k2)^2;
    U(k1+1,7) = (camA.M(2,3) - camA.M(3,3)*usyA(k2));
    U(k1+1,8) = (camA.M(2,3) - camA.M(3,3)*usyA(k2))*tA(k2);
    U(k1+1,9) = 0.5*(camA.M(2,3) - camA.M(3,3)*usyA(k2))*tA(k2)^2;
    
    k1 = k1 + 2;
end
%--------------------------------------------------------------------------
% setup U matrix section with camera B observations
%--------------------------------------------------------------------------
for k2 = 1:length(usxB)
    U(k1,1) = (camB.M(1,1) - camB.M(3,1)*usxB(k2));
    U(k1,2) = (camB.M(1,1) - camB.M(3,1)*usxB(k2))*tB(k2);
    U(k1,3) = 0.5*(camB.M(1,1) - camB.M(3,1)*usxB(k2))*tB(k2)^2;
    U(k1,4) = (camB.M(1,2) - camB.M(3,2)*usxB(k2));
    U(k1,5) = (camB.M(1,2) - camB.M(3,2)*usxB(k2))*tB(k2);
    U(k1,6) = 0.5*(camB.M(1,2) - camB.M(3,2)*usxB(k2))*tB(k2)^2;
    U(k1,7) = (camB.M(1,3) - camB.M(3,3)*usxB(k2));
    U(k1,8) = (camB.M(1,3) - camB.M(3,3)*usxB(k2))*tB(k2);
    U(k1,9) = 0.5*(camB.M(1,3) - camB.M(3,3)*usxB(k2))*tB(k2)^2;
        
    U(k1+1,1) = (camB.M(2,1) - camB.M(3,1)*usyB(k2));
    U(k1+1,2) = (camB.M(2,1) - camB.M(3,1)*usyB(k2))*tB(k2);
    U(k1+1,3) = 0.5*(camB.M(2,1) - camB.M(3,1)*usyB(k2))*tB(k2)^2;
    U(k1+1,4) = (camB.M(2,2) - camB.M(3,2)*usyB(k2));
    U(k1+1,5) = (camB.M(2,2) - camB.M(3,2)*usyB(k2))*tB(k2);
    U(k1+1,6) = 0.5*(camB.M(2,2) - camB.M(3,2)*usyB(k2))*tB(k2)^2;
    U(k1+1,7) = (camB.M(2,3) - camB.M(3,3)*usyB(k2));
    U(k1+1,8) = (camB.M(2,3) - camB.M(3,3)*usyB(k2))*tB(k2);
    U(k1+1,9) = 0.5*(camB.M(2,3) - camB.M(3,3)*usyB(k2))*tB(k2)^2;
    
    k1 = k1 + 2;
end
%--------------------------------------------------------------------------
% make the s vector of observations using the images coordinates from
% camera A, then the coordinates from camera B
%--------------------------------------------------------------------------
s = zeros(nobs,1);
k1 = 1;
for k2 = 1:length(usxA)
    s(k1) = usxA(k2) - camA.M(1,4);
    s(k1+1) = usyA(k2) - camA.M(2,4);
    k1 = k1 + 2;
end
for k2 = 1:length(usxB)
    s(k1) = usxB(k2) - camB.M(1,4);
    s(k1+1) = usyB(k2) - camB.M(2,4);
    k1 = k1 + 2;
end
%--------------------------------------------------------------------------
% find the SVD of U
%--------------------------------------------------------------------------
[Us,Ss,Vs] = svd(U,0);
%--------------------------------------------------------------------------
% Then solve for A
%--------------------------------------------------------------------------
a = Vs*((Us'*s)./diag(Ss));
%--------------------------------------------------------------------------
% unpack the vector of parameters
%--------------------------------------------------------------------------
sf = 3.0;  % a scale factor to convert from yards to feet

initPosition(1) = sf*a(1); % x0
initPosition(2) = sf*a(4); % y0
initPosition(3) = sf*a(7); % z0

initVelocity(1) = sf*a(2); % vx0
initVelocity(2) = sf*a(5); % vy0
initVelocity(3) = sf*a(8); % vz0
 
acceleration(1) = sf*a(3); % ax
acceleration(2) = sf*a(6); % ay
acceleration(3) = sf*a(9); % az

return
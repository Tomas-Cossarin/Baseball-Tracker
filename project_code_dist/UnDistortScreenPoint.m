function [undistorted_x, undistorted_y] = UnDistortScreenPoint(distorted_x, distorted_y, cam)
%--------------------------------------------------------------------------
% The distortion function is not analytically invertible so we use an 
% iterative approach described in page 7 of J. Heikkila. 
% Geometric camera calibration using circular control points. 
% IEEE Transactions on Pattern Analysis and Machine Intelligence, 
% 22(10):1066-1077, 2000

% start out with an undistorted point at the same position at the distorted Point
undistorted_x = distorted_x;
undistorted_y = distorted_y;

lastDistortion_x = 0;
lastDistortion_y = 0;

eps = 1e-3;

for k = 1:200
    [testDistorted_x, testDistorted_y] = DistortScreenPoint(undistorted_x, undistorted_y, cam);
    distortion_x = testDistorted_x - undistorted_x;
    distortion_y = testDistorted_y - undistorted_y;

    undistorted_x = distorted_x - distortion_x;
    undistorted_y = distorted_y - distortion_y;
        
    delta_x = distortion_x - lastDistortion_x; 
    delta_y = distortion_y - lastDistortion_y; 

    if (k > 1 && abs(delta_x) < eps && abs(delta_y) < eps)
        break;
    end
        
    lastDistortion_x = distortion_x;
    lastDistortion_y = distortion_y;
    
end

return;
function [normalizedLens_x, normalizedLens_y] = DoPixelNormalization(screen_x, screen_y, cam)
%--------------------------------------------------------------------------
% Note that we do not verify the that screenPoint is within the activeVideo
% region.  This is essential in the case of barrel distortion, 
% when undistorted points outside of active video are distorted to fall 
% within active video

% Various calculations are based on the activeVideo min and max corners
[activeVideoMinCorner, activeVideoMaxCorner] = GetActiveVideoCorners(cam);

% Put screenPoint in activeVideo coordinates
activeVideo_x = screen_x - activeVideoMinCorner(1);
activeVideo_y = screen_y - activeVideoMinCorner(2);

% active video point as percentage of activeVideoHeight
activeVideoPct_x = activeVideo_x / cam.activeVideoSize(1);
activeVideoPct_y = activeVideo_y / cam.activeVideoSize(2);

% stretching based on any difference between lensImageSize vs activeVideoSize
lensImageSize = GetLensImageSize(cam);

normalizedLens_x = cam.lensImageOffset(1) + (activeVideoPct_x - 0.5) * lensImageSize(1);
normalizedLens_y = cam.lensImageOffset(2) + (activeVideoPct_y - 0.5) * lensImageSize(2);

return
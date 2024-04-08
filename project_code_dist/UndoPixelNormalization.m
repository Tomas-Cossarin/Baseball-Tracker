function [screen_x, screen_y] = UndoPixelNormalization(normalizedLens_x, normalizedLens_y, cam)
%--------------------------------------------------------------------------
% stretching based on any difference between lensImageSize vs activeVideoSize
lensImageSize = GetLensImageSize(cam);
    
activeVideoPct_x = 0.5 + (normalizedLens_x - cam.lensImageOffset(1)) / lensImageSize(1);
activeVideoPct_y = 0.5 + (normalizedLens_y - cam.lensImageOffset(2)) / lensImageSize(2);

% determine location of pixel within active video portion of screen
activeVideo_x = activeVideoPct_x * cam.activeVideoSize(1);
activeVideo_y = activeVideoPct_y * cam.activeVideoSize(2);

% convert active video coordinate to screen coordinate
[activeVideoMinCorner, activeVideoMaxCorner] = GetActiveVideoCorners(cam);
    
screen_x = activeVideo_x + activeVideoMinCorner(1);
screen_y = activeVideo_y + activeVideoMinCorner(2);

return
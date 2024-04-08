function [distortedScreen_x, distortedScreen_y] = DistortScreenPoint(screen_x, screen_y, cam)
%--------------------------------------------------------------------------
% Compute the effect of radial distortion.
% Note that either/both coefficients may be 0, in which case there is no effect
%
% Note that the calculations below are performed in normalized pixel 
% coordinates, a convention that is defined in SampledCamera.
% A normalized pixel position is the location of the pixel on the CCD 
% as a percentage of the radius of the CCD, where the radius of the CCD 
% is measured in units of CCD pixel height.
%
% Attempt to normalize the screenpoint based on the radius of the lens image
% as an offset from center, % of ccd radius

[normPixel_x, normPixel_y] = DoPixelNormalization(screen_x, screen_y, cam);
 
% Determine the radius of the pixel, as a % of ccd radius
pixelOffset_x = normPixel_x - cam.centerOfDistortion(1);
pixelOffset_y = normPixel_y - cam.centerOfDistortion(2);

pixelRadius2 = power(pixelOffset_x,2) + power(pixelOffset_y,2);
 
% Filter out large radius points to avoid "wraparound" distortion
% -- If we have barrel distortion (eg, k1 negative), then points are
% -- moved inwards based on the distortion process.  In the extreme case,
% -- a point that is far outside of the active video (very big radius) could be
% -- distorted inwards so far that it falls into the active image area.  Of course,
% -- this would never happen in real lens - it's just a product of our distortion
% -- function.  To avoid this "wraparound" distortion, we don't bother distorting
% -- points with very large radii
% -- Assuming that -0.25<k1  (there's not a ton of distortion), restricting pixelRadius<2
% -- will be sufficient to filter out these points without affecting the actual image points

if (pixelRadius2 > 4)
    distortedScreen_x = screen_x;
    distortedScreen_y = screen_y;
end

% Determine the radial distortion 
distortionFactor = cam.radialDistortionK1*pixelRadius2 + cam.radialDistortionK2*power(pixelRadius2,2);    

% Determine the new position of the pixel (in units of % of ccd radius)
distortionDistance_x = distortionFactor .* pixelOffset_x;
distortionDistance_y = distortionFactor .* pixelOffset_y;

distortedNormPixel_x = normPixel_x + distortionDistance_x;
distortedNormPixel_y = normPixel_y + distortionDistance_y;

% Convert the distoredPixelPosition back into normal screen coordinates
[distortedScreen_x, distortedScreen_y] = UndoPixelNormalization(distortedNormPixel_x,distortedNormPixel_y,cam);

return
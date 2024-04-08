function [activeVideoMinCorner, activeVideoMaxCorner] = GetActiveVideoCorners(cam)
%--------------------------------------------------------------------------
activeVideoCenter(1) = cam.numPixels(1)/2.0 + cam.activeVideoOffset(1);
activeVideoCenter(2) = cam.numPixels(2)/2.0 + cam.activeVideoOffset(2);
    
activeVideoMinCorner(1) = activeVideoCenter(1) - cam.activeVideoSize(1)/2.0;
activeVideoMinCorner(2) = activeVideoCenter(2) - cam.activeVideoSize(2)/2.0;
    
activeVideoMaxCorner(1) = activeVideoCenter(1) + cam.activeVideoSize(1)/2.0;
activeVideoMaxCorner(2) = activeVideoCenter(2) + cam.activeVideoSize(2)/2.0;
    
% active video can never fall outside of the total numPixels
if activeVideoMinCorner(1) > activeVideoMaxCorner(1)
    activeVideoMinCorner(1) = activeVideoMaxCorner(1);
end
if activeVideoMinCorner(2) > activeVideoMaxCorner(2)
    activeVideoMinCorner(2) = activeVideoMaxCorner(2);
end
    
if activeVideoMinCorner(1) < 0
    activeVideoMinCorner(1) = 0;
end
if activeVideoMinCorner(2) < 0
    activeVideoMinCorner(2) = 0;
end
    
return
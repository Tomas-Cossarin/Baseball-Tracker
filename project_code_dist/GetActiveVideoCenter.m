function activeVideoCenter = GetActiveVideoCenter(cam)
%--------------------------------------------------------------------------
activeVideoCenter(1) = cam.numPixels(1)/2.0 + cam.activeVideoOffset(1);
activeVideoCenter(2) = cam.numPixels(2)/2.0 + cam.activeVideoOffset(2);

return
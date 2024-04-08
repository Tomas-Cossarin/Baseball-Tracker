function lensImageSize = GetLensImageSize(cam)
%--------------------------------------------------------------------------
% lensImageSizeX^2 + lensImageSizeY^2 = (2*lensImageRadius)^2
% (lensImageAspectRatio*lensImageSizeY)^2 + lensImageSizeY^2 = (2*lensImageRadius)^2
% (lensImageAspectRatio^2 + 1) * lensImageSizeY^2 = (2*lensImageRadius)^2
% lensImageSizeY = 2*lensImageRadius / sqrt(lensImageAspectRatio^2 + 1)

lensImageSize(2) = 2.0 * cam.lensImageRadius / sqrt(cam.lensImageAspectRatio^2 + 1.0);
lensImageSize(1) = cam.lensImageAspectRatio * lensImageSize(2);
    
    %=====================================
    %  For SD lensImageAspectRatio = 4/3 tracking cameras this works out to
    %         lensImageSize[1] = 6/5         = 1.2  lensImageRadius
    %         lensImageSize[0] = 24/15 = 8/5 = 1.6  lensImageRadius RPP 5/1/08
    %
    %      HD lensImageAspectRatio = 16/9
    %         lensImageSize[1] =             = 0.9806  lensImageRadius
    %         lensImageSize[0] =             = 1.7432  lensImageRadius RPP 5/1/08
    %=====================================
    
    %check calculation to make sure that size is correct
    %assert(fabs(lensImageSize.length() - 2.0*m_LensImageRadius) < VERY_SMALL);
return
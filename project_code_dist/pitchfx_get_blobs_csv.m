function blob = pitchfx_get_blobs_csv(pitch_path)
%**************************************************************************
% ENGO 559 PitchF/X Project
%
% a function to open blobs.csv and get the (x,y) image coordinates and time
% stamps for camera A and B images.
%
%  m.j.collins april.2016
%
%**************************************************************************

%--------------------------------------------------------------------------
% read the data from the blobs.csv file
%--------------------------------------------------------------------------
blob_data = csvread([pitch_path 'blobs.csv'],1,0);
% get the size of the array
[nr_blob,nc_blob] = size(blob_data);
% the array should have 9 columns, if it doesn't, there is a problem
if nc_blob ~= 9
    fprintf(1,'pitchfx_get_blobs.csv: problem reading blobs.csv file\n');
    fprintf(1,'                       file must have 9 columns\n');
    return;
end
%--------------------------------------------------------------------------
% unpack the (x,y) image coordinates of the ball and the time stamps 
% from the blob array
%--------------------------------------------------------------------------
kA = 1; kB = 1;
for k = 1:nr_blob
    if blob_data(k,3) && blob_data(k,9) == 0 % camera A
        blob.xA(kA) = blob_data(k,6);
        blob.yA(kA) = blob_data(k,7);
        blob.tA(kA) = blob_data(k,5);
        kA = kA + 1;
    elseif blob_data(k,3) && blob_data(k,9) == 1 % camera B
        blob.xB(kB) = blob_data(k,6);
        blob.yB(kB) = blob_data(k,7);
        blob.tB(kB) = blob_data(k,5);
        kB = kB + 1;
    end
end

return
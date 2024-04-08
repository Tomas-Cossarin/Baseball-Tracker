function [dclipA, dclipB, pitch_path] = pitchfx_read_video()
%**************************************************************************
% ENGO 559 PitchF/X Project
%
% A function to read in PitchFX video data from camera A and B, and return
% two real arrays containg all the frames.
%
% The orginal video data are in the form of .asf files.  These cannot be
% read on a Mac. So you will have to convert the .asf files to .mp4.  You
% can do this using a program called "Smart Converter", which is available
% through the App Store.
% The function detects whether it is being run from a Mac.  If it is then 
% it looks for an mp4 file, otherwise it looks for the orginal .asf file.
%
%  m.j.collins april.2016
%
%**************************************************************************

%--------------------------------------------------------------------------
% get video data file names
%--------------------------------------------------------------------------
if ismac
    [clipA_name,pitch_path] = uigetfile('*.mp4','Select Camera A Video file');
    [clipB_name,pitch_path] = uigetfile('*.mp4','Select Camera B Video file',pitch_path);
else
    [clipA_name,pitch_path] = uigetfile('*.asf','Select Camera A Video file');
    [clipB_name,pitch_path] = uigetfile('*.asf','Select Camera B Video file',pitch_path);
end
%--------------------------------------------------------------------------
% read in the clip from camera A
%--------------------------------------------------------------------------
vidObj = VideoReader([pitch_path clipA_name]);

% Determine the height and width of the frames.
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;

% Create a MATLAB® movie structure array, s.
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

% Read one frame at a time using readFrame until the end of the file is 
% reached. Append data from each video frame to the structure array.
k = 1;
while hasFrame(vidObj)
    clipA(:,:,:,k) = readFrame(vidObj);
    k = k+1;
end
[nrA,ncA,nb,nFramesA] = size(clipA);

clear vidObj;

fprintf(1,'clipA: %s has %d frames\n',clipA_name,nFramesA)

%--------------------------------------------------------------------------
% read in the clip from camera B
%--------------------------------------------------------------------------
vidObj = VideoReader([pitch_path clipB_name]);

% Determine the height and width of the frames.
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;

% Create a MATLAB® movie structure array, s.
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

% Read one frame at a time using readFrame until the end of the file is 
% reached. Append data from each video frame to the structure array.
k = 1;
while hasFrame(vidObj)
    clipB(:,:,:,k) = readFrame(vidObj);
    k = k+1;
end
[nrB,ncB,nb,nFramesB] = size(clipB);

fprintf(1,'clipB: %s has %d frames\n',clipB_name,nFramesB)

%--------------------------------------------------------------------------
% All three bands of these grey-scale video frames are the same, 
% so we only need one of them. Cycle through each frame and save band 1
% to a double so we can use it in calculations.
%--------------------------------------------------------------------------
for frame = 1:nFramesA
    dclipA(:,:,frame) = double(clipA(:,:,1,frame));
end

for frame = 1:nFramesB
    dclipB(:,:,frame) = double(clipB(:,:,1,frame));
end


return
function pitch = pitchfx_get_pitch_info(pitch_path)
%**************************************************************************
% ENGO 559 PitchF/X Project
%
% A function to read in PitchFX data from pitch.info.
% These date include the PitchFX solution, along with the initTime, which
% is subtracted from the time vector before calculating the 3D world
% coordinates of the ball.
% Parameters are put in a struct and returned.
%
%  m.j.collins april.2016
%**************************************************************************
%--------------------------------------------------------------------------
% open pitch.info and read the data into a string
%--------------------------------------------------------------------------
fd = fopen([pitch_path 'pitch.info']);
% check to make sure file was opened
if fd < 0
    fprintf(1,'pitchfx_get_pitch_info: problem opening %s\n',file_name);
    fprintf(1,'%s\n',error_message);
    return;
end
% read file contents into a string
pich_string = fscanf(fd,'%c');
% close file
fclose(fd);
%--------------------------------------------------------------------------
% separate the strings and numbers
%--------------------------------------------------------------------------
remain = pich_string;
k = 1;
while length(remain)
    [token, remain] = strtok(remain);
    cam_cell{k} = token;
    k = k + 1;
end
%--------------------------------------------------------------------------
% unpack the PitchFX solution of the parameters
%--------------------------------------------------------------------------
eval(['pitch.initTime = ' cam_cell{42} ';']);
eval(['pitch.initPosition = [' cam_cell{45:47} '];']);
eval(['pitch.initVelocity = [' cam_cell{50:52} '];']);
eval(['pitch.acceleration = [' cam_cell{55:57} '];']);
eval(['pitch.initSpeed = ' cam_cell{60} ';']);
eval(['pitch.finalSpeed = ' cam_cell{63} ';']);

return
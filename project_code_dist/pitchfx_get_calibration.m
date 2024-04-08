function calibration_data = pitchfx_get_calibration(pitch_path,file_name)
%**************************************************************************
% ENGO 559 PitchF/X Project
%
% function that opens the PitchFX calibration file called file_name with
% the path pitch_string, and returns a struct containing the data.
%
% m.j.collins april.2016
%
%**************************************************************************

% open file and deal with the fall out
[fd,error_message] = fopen([pitch_path file_name]);
if fd < 0
    fprintf(1,'pitchfx_get_calibration: problem opening %s\n',file_name);
    fprintf(1,'%s\n',error_message);
    return;
end

% read file contents into string
cal_string = fscanf(fd,'%c');
fclose(fd);
%--------------------------------------------------------------------------
% cam string is one long string of characters with everything we need all
% mashed together.  We have to pull it all apart like a big sticky cinnamon
% bun.
% we are only interested in the numbers, and we know the format of the
% file, so we know the order in which the numbers appear.
%--------------------------------------------------------------------------
remain = cal_string;
k = 1;
while length(remain)
    [token, remain] = strtok(remain);
    cam_cell{k} = token;
    k = k + 1;
end

% unpack the string
eval(['calibration_data.M = [' cam_cell{3} ';' cam_cell{6} ';' cam_cell{9} '];']);
eval(['calibration_data.numPixels = [' cam_cell{12} '];']);
eval(['calibration_data.' cam_cell{13:15} ';']);
eval(['calibration_data.activeVideoOffset = [' cam_cell{18} '];']);
eval(['calibration_data.activeVideoSize = [' cam_cell{21} '];']);
eval(['calibration_data.lensImageOffset = [' cam_cell{24} '];']);
eval(['calibration_data.' cam_cell{25:27} ';']);
eval(['calibration_data.' cam_cell{28:30} ';']);
eval(['calibration_data.centerOfDistortion = [' cam_cell{33} '];']);
eval(['calibration_data.' cam_cell{34:36} ';']);
eval(['calibration_data.' cam_cell{37:39} ';']);
eval(['calibration_data.frontNodalPoint = [' cam_cell{42} '];']);
eval(['calibration_data.lookAtPoint = [' cam_cell{45} '];']);
eval(['calibration_data.upDirection = [' cam_cell{48} '];']);
eval(['calibration_data.fieldOfView = [' cam_cell{51} '];']);

return
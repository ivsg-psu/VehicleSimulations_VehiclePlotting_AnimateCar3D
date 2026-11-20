function liveState = fcn_AnimateCar3D_writeLiveTestFiles(folder, sceneList, motions, sceneTime, options)
% fcn_AnimateCar3D_writeLiveTestFiles

% A test helper that stands in for a live data source (a simulator, or a
% vehicle sending data). Called with a growing scene time, it writes into
% a watched folder only the data that exists up to that time: it creates
% each object's file when its motion starts, appends new rows as time
% goes on, and can delete the file once the motion has ended. It is meant
% only for testing and demonstrating fcn_AnimateCar3D_watchFolder.
%
% Rows are always appended as whole lines, as a live source should. The
% scene list is written once, at the first call (it may list objects that
% have not started yet), with time offsets of 0: the times written are
% scene times.
%
% FORMAT:
%
%       liveState = fcn_AnimateCar3D_writeLiveTestFiles(folder, sceneList, motions, sceneTime,...
%           (LiveState=liveState), (Format=format), (DeleteAfter=seconds),...
%           (WriteSceneList=flag), (TrafficName=name), (FigNum=figNum))
%
% INPUTS:
%
%      folder: the watched folder. It is made if it does not exist. At
%      the first call, the files this helper writes are deleted from it.
%
%      sceneList: from fcn_AnimateCar3D_loadSceneList; gives each
%      object's role, mesh, color, and time offset.
%
%      motions: the full motions (fields Instance, Time, Pose (K x 3 or
%      K x 6), and optionally SteerAngle, WheelSpin, LightStates), one
%      per object in sceneList.
%
%      sceneTime: write everything up to this time (seconds).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      LiveState: the output of the last call; [] (default) for the first.
%
%      Format: 'perObject' (default): one CarMesh3D motion file per
%      object, <instance>.csv. 'traffic': all objects in ONE long-format
%      traffic file (<TrafficName>.csv, with columns id, time, X, Y, yaw,
%      and the size); the watcher names them <TrafficName>_<instance>.
%
%      DeleteAfter: delete an object's file this many seconds after its
%      motion ends ('perObject' only). Default Inf (never).
%
%      WriteSceneList: write sceneList.csv at the first call. Default
%      true.
%
%      TrafficName: the traffic file's name, without .csv. Default
%      'traffic'.
%
%      FigNum: a figure number to plot the rows written so far, from
%      above. Empty (default) for no figure; -1 for fast mode (no input
%      checks).
%
% OUTPUTS:
%
%      liveState: a structure with fields Folder, Format, Instances,
%      LastWritten (the last scene time written for each object; -Inf if
%      none), FileCreated and FileDeleted (logical, per object),
%      RowsWritten (total), and SceneTime (of this call).
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       liveState = [];
%       for t = 0:0.5:10
%           liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, t, ...
%               LiveState=liveState, DeleteAfter=2);
%           ... the watcher and the animation run here ...
%       end
%
%       See the script: script_test_fcn_AnimateCar3D_writeLiveTestFiles.m
%       for a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_writeLiveTestFiles
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_writeLiveTestFiles
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    folder
    sceneList
    motions
    sceneTime
    options.LiveState = []              % from the last call; [] for the first
    options.Format = 'perObject'        % 'perObject' or 'traffic'
    options.DeleteAfter = Inf           % seconds after a motion ends ('perObject')
    options.WriteSceneList = true       % write sceneList.csv at the first call
    options.TrafficName = 'traffic'     % traffic file name, without .csv
    options.FigNum = []                 % figure to plot the rows written; -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
flag_max_speed = 0; % The default. This runs code with all error checking
if isequal(options.FigNum,-1)
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS");
    MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above


        % Check the folder input
        if ~(ischar(folder) || isstring(folder))
            error('folder must be a folder name');
        end

        % Check the sceneList and motions inputs
        if ~(isstruct(sceneList) && all(isfield(sceneList,{'Instance','Role','MeshID','TimeOffset'})))
            error('sceneList must come from fcn_AnimateCar3D_loadSceneList');
        end
        if ~(isstruct(motions) && all(isfield(motions,{'Instance','Time','Pose'})))
            error('motions must be a structure array with fields Instance, Time, and Pose');
        end
        if ~all(ismember({motions.Instance}, {sceneList.Instance}))
            error('Every motion must have a row in sceneList');
        end

        % Check the sceneTime input
        if ~isnumeric(sceneTime) || ~isscalar(sceneTime)
            error('sceneTime must be a number of seconds');
        end

        % Check the options
        if ~any(strcmp(options.Format, {'perObject','traffic'}))
            error('Format must be ''perObject'' or ''traffic''');
        end
        if ~isnumeric(options.DeleteAfter) || ~isscalar(options.DeleteAfter) || options.DeleteAfter<0
            error('DeleteAfter must be a non-negative number of seconds (or Inf)');
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed)
    temp = options.FigNum;
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp;
        flag_do_plots = 1;
    end
end

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


folder = char(folder);
motions = motions(:);
Nmotions = numel(motions);
liveState = options.LiveState;
trafficFile = fullfile(folder, [char(options.TrafficName) '.csv']);
rowIndex = zeros(Nmotions,1);
for ith_motion = 1:Nmotions
    rowIndex(ith_motion) = find(strcmp({sceneList.Instance}, motions(ith_motion).Instance), 1);
end
if strcmp(options.Format,'traffic')
    folderNames = strcat(char(options.TrafficName), '_', {motions.Instance});
else
    folderNames = {motions.Instance};
end

%%%% The first call: a clean folder, and the scene list
if isempty(liveState)
    if ~isfolder(folder)
        mkdir(folder);
    end
    for ith_motion = 1:Nmotions
        oldFile = fullfile(folder, [motions(ith_motion).Instance '.csv']);
        if isfile(oldFile)
            delete(oldFile);
        end
    end
    if isfile(trafficFile)
        delete(trafficFile);
    end
    if options.WriteSceneList
        fcn_INTERNAL_writeSceneList(fullfile(folder,'sceneList.csv'), sceneList(rowIndex), folderNames);
    end
    liveState = struct;
    liveState.Folder = folder;
    liveState.Format = options.Format;
    liveState.Instances = {motions.Instance};
    liveState.LastWritten = -Inf(Nmotions,1);
    liveState.FileCreated = false(Nmotions,1);
    liveState.FileDeleted = false(Nmotions,1);
    liveState.RowsWritten = 0;
    liveState.SceneTime = -Inf;
end

%%%% Append the rows from the last time written up to sceneTime
trafficText = strings(0,1);
for ith_motion = 1:Nmotions
    thisMotion = motions(ith_motion);
    thisRow = sceneList(rowIndex(ith_motion));
    times = thisMotion.Time(:) + thisRow.TimeOffset;
    newRows = find(times > liveState.LastWritten(ith_motion) & times <= sceneTime + 1e-9);
    if ~isempty(newRows) && ~liveState.FileDeleted(ith_motion)
        if strcmp(options.Format,'perObject')
            [headerText, rowText] = fcn_INTERNAL_motionRows(thisMotion, times, newRows);
            objectFile = fullfile(folder, [thisMotion.Instance '.csv']);
            if ~liveState.FileCreated(ith_motion)
                fcn_INTERNAL_append(objectFile, headerText + newline + rowText, 'w');
                liveState.FileCreated(ith_motion) = true;
            else
                fcn_INTERNAL_append(objectFile, rowText, 'a');
            end
        else
            trafficText(end+1,1) = fcn_INTERNAL_trafficRows(thisMotion, thisRow, times, newRows); %#ok<AGROW>
            liveState.FileCreated(ith_motion) = true;
        end
        liveState.LastWritten(ith_motion) = times(newRows(end));
        liveState.RowsWritten = liveState.RowsWritten + numel(newRows);
    end

    % Delete the file once the motion has ended, plus DeleteAfter
    if strcmp(options.Format,'perObject') && liveState.FileCreated(ith_motion) && ~liveState.FileDeleted(ith_motion) ...
            && sceneTime > times(end) + options.DeleteAfter
        delete(fullfile(folder, [thisMotion.Instance '.csv']));
        liveState.FileDeleted(ith_motion) = true;
    end
end
if ~isempty(trafficText)
    if ~isfile(trafficFile)
        fcn_INTERNAL_append(trafficFile, "id,time,X,Y,yaw,length,width,height" + newline + join(trafficText,""), 'w');
    else
        fcn_INTERNAL_append(trafficFile, join(trafficText,""), 'a');
    end
end
liveState.SceneTime = sceneTime;

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots

    figure(figNum);
    clf;
    hold on;
    for ith_motion = 1:Nmotions
        thisMotion = motions(ith_motion);
        times = thisMotion.Time(:) + sceneList(rowIndex(ith_motion)).TimeOffset;
        written = times <= liveState.LastWritten(ith_motion);
        plot(thisMotion.Pose(:,1), thisMotion.Pose(:,2), ':', 'Color', [0.7 0.7 0.7]);
        if any(written)
            if liveState.FileDeleted(ith_motion)
                lineStyle = '--';
            else
                lineStyle = '-';
            end
            plot(thisMotion.Pose(written,1), thisMotion.Pose(written,2), lineStyle, 'LineWidth', 1.5);
        end
    end
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    title(sprintf('Written up to t = %.1f s: %d rows; %d files deleted', sceneTime, ...
        liveState.RowsWritten, sum(liveState.FileDeleted)));
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_append
function fcn_INTERNAL_append(fileName, text, mode)
% Write or append whole lines in one call
fileID = fopen(fileName, mode);
if fileID < 0
    error('Could not open %s', fileName);
end
closeFile = onCleanup(@() fclose(fileID));   % closed even if writing fails
fprintf(fileID, '%s', text);
end % Ends fcn_INTERNAL_append

%% fcn_INTERNAL_motionRows
function [headerText, rowText] = fcn_INTERNAL_motionRows(thisMotion, times, newRows)
% Rows in the CarMesh3D motion format: time, X, Y, yaw, plus Z, roll,
% pitch (6-column poses), the front steer angles, the wheel angles, and
% the brake light, when the motion has them
pose = thisMotion.Pose(newRows,:);
if size(pose,2)==3
    pose = [pose(:,1:2), zeros(numel(newRows),3), pose(:,3)];
end
columnNames = ["time","X","Y","Z","roll","pitch","yaw"];
values = [times(newRows), pose];
if isfield(thisMotion,'SteerAngle') && ~isempty(thisMotion.SteerAngle)
    columnNames = [columnNames, "steer_FL","steer_FR"];
    values = [values, thisMotion.SteerAngle(newRows,:)];
end
if isfield(thisMotion,'WheelSpin') && ~isempty(thisMotion.WheelSpin)
    columnNames = [columnNames, "wheelAngle_FL","wheelAngle_FR","wheelAngle_RL","wheelAngle_RR"];   % WheelSpin is [FL FR RL RR]
    values = [values, thisMotion.WheelSpin(newRows,:)];
end
if isfield(thisMotion,'LightStates') && ~isempty(thisMotion.LightStates)
    lightStates = thisMotion.LightStates(newRows);
    columnNames = [columnNames, "headlights","brakeLight"];
    headlights = double(strcmp({lightStates.Headlights}','low')) + 2*double(strcmp({lightStates.Headlights}','high'));
    values = [values, headlights, double(strcmp({lightStates.Tail}','brake'))];
end
headerText = join(columnNames, ",");
formatText = ['%.4f', repmat(',%.6g', 1, size(values,2)-1), '\n'];
rowText = string(sprintf(formatText, values'));
end % Ends fcn_INTERNAL_motionRows

%% fcn_INTERNAL_trafficRows
function rowText = fcn_INTERNAL_trafficRows(thisMotion, thisRow, times, newRows)
% Rows in the long traffic format: id, time, X, Y, yaw, and the size
% (empty when not given)
pose = thisMotion.Pose(newRows,:);
yaw = pose(:,end);
sizeText = strjoin(fcn_INTERNAL_numberText(thisRow.Size), ',');
lines = compose("%s,%.4f,%.4f,%.4f,%.6f,%s", string(thisMotion.Instance), times(newRows), pose(:,1), pose(:,2), yaw, sizeText);
rowText = join(lines, newline) + newline;
end % Ends fcn_INTERNAL_trafficRows

%% fcn_INTERNAL_numberText
function texts = fcn_INTERNAL_numberText(values)
% Numbers as text, with NaN as empty text
texts = strings(1, numel(values));
for ith_value = 1:numel(values)
    if ~isnan(values(ith_value))
        texts(ith_value) = string(sprintf('%.10g', values(ith_value)));
    end
end
end % Ends fcn_INTERNAL_numberText

%% fcn_INTERNAL_writeSceneList
function fcn_INTERNAL_writeSceneList(fileName, sceneRows, folderNames)
% The scene list as CSV, with the instance names the watcher will use and
% time offsets of 0 (the times written are scene times)
lines = "instance,role,meshID,branchOf,branchID,splitTime,respondsTo,color,alpha,timeOffset,length,width,height";
for ith_row = 1:numel(sceneRows)
    thisRow = sceneRows(ith_row);
    if all(isnan(thisRow.Color))
        colorText = "";
    else
        colorText = strjoin(fcn_INTERNAL_numberText(thisRow.Color), ' ');
    end
    branchOf = string(thisRow.BranchOf);
    respondsTo = string(thisRow.RespondsTo);
    if ~isempty(thisRow.BranchOf) && ~strcmp(folderNames{ith_row}, thisRow.Instance)
        prefix = extractBefore(string(folderNames{ith_row}), string(thisRow.Instance));
        branchOf = prefix + branchOf;
        if strlength(respondsTo)>0
            respondsTo = prefix + respondsTo;
        end
    end
    numberTexts = fcn_INTERNAL_numberText([thisRow.BranchID, thisRow.SplitTime]);
    sizeTexts = fcn_INTERNAL_numberText(thisRow.Size);
    alphaText = fcn_INTERNAL_numberText(thisRow.Alpha);
    lines(end+1,1) = strjoin([string(folderNames{ith_row}), string(thisRow.Role), string(thisRow.MeshID), ...
        branchOf, numberTexts, respondsTo, colorText, alphaText, "0", sizeTexts], ','); %#ok<AGROW>
end
fcn_INTERNAL_append(fileName, join(lines, newline) + newline, 'w');
end % Ends fcn_INTERNAL_writeSceneList

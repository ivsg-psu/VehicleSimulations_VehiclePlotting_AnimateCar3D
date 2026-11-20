function [sceneList, motions] = fcn_AnimateCar3D_loadTrafficFile(source, options)
% fcn_AnimateCar3D_loadTrafficFile

% Reads many traffic vehicles from ONE narrow file, in "long" format:
% one row per vehicle per time step. This suits dense traffic (hundreds
% or thousands of vehicles), where one CarMesh3D motion file per vehicle
% would mean thousands of small files. Vehicles drawn as far-tier boxes
% need only these few columns.
%
% Columns:
%
%   id       the vehicle's name or number (required)
%   time     seconds (required)
%   X, Y     position of the vehicle's origin (the ground below the rear
%            axle), global frame, meters (required)
%   yaw      heading, radians (required)
%   length, width, height   optional size, meters (the first row of each
%            vehicle is used)
%
% Rows may be in any order. Each vehicle's rows are sorted by time.
%
% FORMAT:
%
%       [sceneList, motions] = fcn_AnimateCar3D_loadTrafficFile(source,...
%           (MeshID=meshID), (Role=role), (InstancePrefix=prefix),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      source: a CSV file name, or a table, with the columns above.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      MeshID: the mesh for every vehicle. Default 'sample'.
%
%      Role: the role of every vehicle. Default 'traffic'.
%
%      InstancePrefix: put before each id to make the instance name.
%      Default 'traffic_' (id 12 becomes traffic_12).
%
%      FigNum: a figure number to plot every path from above. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      sceneList: one row per vehicle (as from
%      fcn_AnimateCar3D_loadSceneList).
%
%      motions: one motion per vehicle, with fields Instance, Time
%      (K x 1), and Pose (K x 3 [x y yaw]), for
%      fcn_AnimateCar3D_buildCatalog's Motions input.
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_loadSceneList
%
% EXAMPLES:
%
%       [sceneList, motions] = fcn_AnimateCar3D_loadTrafficFile('traffic.csv', MeshID='2013_Toyota_Prius_Four');
%
%       See the script: script_test_fcn_AnimateCar3D_loadTrafficFile.m for
%       a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadTrafficFile
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadTrafficFile
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    source
    options.MeshID = 'sample'           % the mesh for every vehicle
    options.Role = 'traffic'            % the role of every vehicle
    options.InstancePrefix = 'traffic_' % instance = prefix + id
    options.FigNum = []                 % figure to plot the paths; -1 for fast mode
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


        % Check the source input
        if ischar(source) || isstring(source)
            if ~isfile(source)
                error('Traffic file not found: %s', char(source));
            end
        elseif ~istable(source)
            error('source must be a CSV file name or a table');
        end

        % Check the text options
        if ~(ischar(options.MeshID) || isstring(options.MeshID)) || ~(ischar(options.Role) || isstring(options.Role)) ...
                || ~(ischar(options.InstancePrefix) || isstring(options.InstancePrefix))
            error('MeshID, Role, and InstancePrefix must be text');
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


if ischar(source) || isstring(source)
    rawTable = readtable(char(source), 'Delimiter', ',');
else
    rawTable = source;
end
lowerNames = lower(rawTable.Properties.VariableNames);
requiredColumns = {'id','time','x','y','yaw'};
missingColumns = setdiff(requiredColumns, lowerNames, 'stable');
if ~isempty(missingColumns)
    error('The traffic file is missing column(s): %s', strjoin(missingColumns,', '));
end
column = @(name) rawTable{:, find(strcmp(lowerNames,name),1)};
ids = string(column('id'));
times = double(column('time'));
xyYaw = [double(column('x')), double(column('y')), double(column('yaw'))];
hasSize = all(ismember({'length','width','height'}, lowerNames));
if hasSize
    sizes = [double(column('length')), double(column('width')), double(column('height'))];
end

% Group the rows by vehicle, in order of first appearance
[uniqueIDs, firstRows, groupIndex] = unique(ids, 'stable');
Nvehicles = numel(uniqueIDs);
instanceNames = cellstr(string(options.InstancePrefix) + uniqueIDs);
motions = repmat(struct('Instance','', 'Time',[], 'Pose',[]), Nvehicles, 1);
sceneRows = repmat(struct('instance','', 'role',char(options.Role), 'meshID',char(options.MeshID), ...
    'length',NaN, 'width',NaN, 'height',NaN), Nvehicles, 1);
rowsByVehicle = accumarray(groupIndex, (1:numel(groupIndex))', [Nvehicles 1], @(r) {r});
for ith_vehicle = 1:Nvehicles
    rows = rowsByVehicle{ith_vehicle};
    [vehicleTimes, order] = sort(times(rows));
    rows = rows(order);
    motions(ith_vehicle).Instance = instanceNames{ith_vehicle};
    motions(ith_vehicle).Time = vehicleTimes;
    motions(ith_vehicle).Pose = xyYaw(rows,:);
    sceneRows(ith_vehicle).instance = instanceNames{ith_vehicle};
    if hasSize
        sceneRows(ith_vehicle).length = sizes(firstRows(ith_vehicle),1);
        sceneRows(ith_vehicle).width = sizes(firstRows(ith_vehicle),2);
        sceneRows(ith_vehicle).height = sizes(firstRows(ith_vehicle),3);
    end
end
sceneList = fcn_AnimateCar3D_loadSceneList(sceneRows, FigNum=-1);

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
    for ith_vehicle = 1:numel(motions)
        plot(motions(ith_vehicle).Pose(:,1), motions(ith_vehicle).Pose(:,2), '-');
    end
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    title(sprintf('%d vehicles from the traffic file', numel(motions)));
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

% (none)

function staticScene = fcn_AnimateCar3D_loadStaticScene(source, options)
% fcn_AnimateCar3D_loadStaticScene

% Reads a static scene: objects that never move (buildings, signs,
% cubes, parked vehicles). Like moving objects, they go through the
% object catalog and the selector, so only those in view are drawn.
%
% Columns (CSV header names, or field names of a structure array). Only
% x and y are required.
%
%   instance   a unique name (default static1, static2, ...)
%   meshID     'box' (default), or a vehicle mesh ID for parked vehicles
%   x, y, z    position in the global frame, in meters (z default 0).
%              For a box, (x, y) is the center of its footprint; for a
%              vehicle, its origin (the ground below the rear axle).
%   yaw        heading in radians (default 0)
%   length, width, height   the size, in meters (boxes; default 2 2 2)
%   color      "r g b" from 0 to 1 (default gray)
%
% FORMAT:
%
%       staticScene = fcn_AnimateCar3D_loadStaticScene(source, (FigNum=figNum))
%
% INPUTS:
%
%      source: a CSV file name, a table, or a structure array.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: a figure number to plot the scene from above. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      staticScene: N x 1 structure array with fields Instance, MeshID,
%      Pose (1 x 6 [x y z roll pitch yaw]), Size (1 x 3), and Color
%      (1 x 3).
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       staticScene = fcn_AnimateCar3D_loadStaticScene(fullfile('Data','staticScene_cubeGrid.csv'), FigNum=1);
%
%       See the script: script_test_fcn_AnimateCar3D_loadStaticScene.m for
%       a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadStaticScene
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadStaticScene
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    source
    options.FigNum = []    % figure to plot the scene from above; -1 for fast mode
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
                error('Static scene file not found: %s', char(source));
            end
        elseif ~(istable(source) || isstruct(source))
            error('source must be a CSV file name, a table, or a structure array');
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


% Read the rows into a table
if ischar(source) || isstring(source)
    readOptions = detectImportOptions(char(source), 'Delimiter', ',');
    textColumns = intersect(readOptions.VariableNames, {'instance','meshID','color'});
    readOptions = setvartype(readOptions, textColumns, 'char');
    rawTable = readtable(char(source), readOptions);
elseif istable(source)
    rawTable = source;
else
    rawTable = struct2table(source(:), 'AsArray', true);
end
lowerNames = lower(rawTable.Properties.VariableNames);
if ~all(ismember({'x','y'}, lowerNames))
    error('The static scene needs x and y columns');
end
N = height(rawTable);

% Columns, or defaults
instanceIndex = find(strcmp(lowerNames,'instance'),1);
if isempty(instanceIndex)
    instances = compose('static%d', (1:N)');
else
    instances = cellstr(string(rawTable{:,instanceIndex}));
end
meshIndex = find(strcmp(lowerNames,'meshid'),1);
if isempty(meshIndex)
    meshIDs = repmat({'box'}, N, 1);
else
    meshIDs = cellstr(string(rawTable{:,meshIndex}));
    meshIDs(cellfun(@isempty,meshIDs) | strcmpi(meshIDs,'<missing>')) = {'box'};
end
x = fcn_INTERNAL_number(rawTable, lowerNames, 'x', 0, N);
y = fcn_INTERNAL_number(rawTable, lowerNames, 'y', 0, N);
z = fcn_INTERNAL_number(rawTable, lowerNames, 'z', 0, N);
yaw = fcn_INTERNAL_number(rawTable, lowerNames, 'yaw', 0, N);
sizes = [fcn_INTERNAL_number(rawTable, lowerNames, 'length', 2, N), ...
    fcn_INTERNAL_number(rawTable, lowerNames, 'width', 2, N), ...
    fcn_INTERNAL_number(rawTable, lowerNames, 'height', 2, N)];
colors = repmat([0.6 0.6 0.62], N, 1);
colorIndex = find(strcmp(lowerNames,'color'),1);
if ~isempty(colorIndex)
    colorValues = rawTable{:,colorIndex};
    if isnumeric(colorValues) && size(colorValues,2)==3
        colors = double(colorValues);
    else
        colorValues = cellstr(string(colorValues));
        for ith_row = 1:N
            numbers = sscanf(strrep(colorValues{ith_row},',',' '), '%f')';
            if numel(numbers)==3
                colors(ith_row,:) = numbers;
            end
        end
    end
end
if numel(unique(instances)) ~= N
    error('Static object instance names must be unique');
end

staticScene = repmat(struct('Instance','', 'MeshID','box', 'Pose',zeros(1,6), 'Size',[2 2 2], 'Color',[0.6 0.6 0.62]), N, 1);
for ith_row = 1:N
    staticScene(ith_row).Instance = instances{ith_row};
    staticScene(ith_row).MeshID = meshIDs{ith_row};
    staticScene(ith_row).Pose = [x(ith_row) y(ith_row) z(ith_row) 0 0 yaw(ith_row)];
    staticScene(ith_row).Size = sizes(ith_row,:);
    staticScene(ith_row).Color = colors(ith_row,:);
end

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
    for ith_object = 1:numel(staticScene)
        thisObject = staticScene(ith_object);
        halfL = thisObject.Size(1)/2;
        halfW = thisObject.Size(2)/2;
        corners = [-halfL -halfW; halfL -halfW; halfL halfW; -halfL halfW];
        yawAngle = thisObject.Pose(6);
        rotated = corners*[cos(yawAngle) sin(yawAngle); -sin(yawAngle) cos(yawAngle)];
        fill(thisObject.Pose(1)+rotated(:,1), thisObject.Pose(2)+rotated(:,2), thisObject.Color, 'EdgeColor', [0.3 0.3 0.3]);
    end
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    title(sprintf('Static scene: %d objects', numel(staticScene)));
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

%% fcn_INTERNAL_number
function values = fcn_INTERNAL_number(rawTable, lowerNames, columnName, defaultValue, N)
% A number column as N x 1, or the default
index = find(strcmp(lowerNames, columnName), 1);
if isempty(index)
    values = defaultValue*ones(N,1);
    return;
end
values = rawTable{:,index};
if iscell(values) || isstring(values)
    values = str2double(string(values));
end
values = double(values(:));
values(isnan(values)) = defaultValue;
end % Ends fcn_INTERNAL_number

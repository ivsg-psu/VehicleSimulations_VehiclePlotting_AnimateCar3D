function sceneList = fcn_AnimateCar3D_loadSceneList(source, options)
% fcn_AnimateCar3D_loadSceneList

% Reads a scene list: one row per moving object in a scene, saying what
% it is, which mesh draws it, where its motion comes from, and how it is
% linked to other objects. The scene list is the only file that names
% many objects; each object's motion stays in its own file (or in
% memory), so no single file becomes unwieldy.
%
% Columns (CSV header names, or field names of a structure array). Only
% instance is required; the others take the defaults shown.
%
%   instance     a unique name, e.g. ego, car12, ego_branch3
%   role         ego, traffic (default), confederate, pedestrian, or
%                movingItem
%   meshID       the mesh: a CarMesh3D vehicle ID, 'sample', or 'box'
%                (default 'sample')
%   motionFile   the object's CarMesh3D motion CSV file, relative to the
%                scene list's folder (or absolute); empty if the motion is
%                given in memory to fcn_AnimateCar3D_buildCatalog
%   branchOf     the instance this one branches from (empty if none)
%   branchID     which branch it is (0 if none)
%   splitTime    when it splits from branchOf, in seconds (NaN: the
%                start of its motion)
%   respondsTo   for an ego branch, the confederate branch it answers
%   color        "r g b" from 0 to 1 (empty: the mesh's own colors, or
%                the role's default)
%   alpha        opacity from 0 to 1 (NaN: the role's default)
%   timeOffset   seconds added to the motion's times (default 0)
%   length, width, height   the object's size in meters, for meshes
%                drawn as boxes (NaN: the mesh's size)
%
% FORMAT:
%
%       sceneList = fcn_AnimateCar3D_loadSceneList(source, (FigNum=figNum))
%
% INPUTS:
%
%      source: a CSV file name, a table, or a structure array with the
%      columns above as fields.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: a figure number to show the scene list as a table and its
%      branch links. Empty (default) for no figure; -1 for fast mode (no
%      input checks).
%
% OUTPUTS:
%
%      sceneList: N x 1 structure array with every column as a field
%      (Instance, Role, MeshID, MotionFile, BranchOf, BranchID,
%      SplitTime, RespondsTo, Color (1 x 3, NaN if none), Alpha,
%      TimeOffset, Size (1 x 3)). MotionFile is made absolute.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       sceneList = fcn_AnimateCar3D_loadSceneList(fullfile('Data','sceneList_confederate.csv'));
%
%       See the script: script_test_fcn_AnimateCar3D_loadSceneList.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadSceneList
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadSceneList
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    source
    options.FigNum = []    % figure to show the list; -1 for fast mode
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
                error('Scene list file not found: %s', char(source));
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


% Read the rows into a table, with lower-case column names
baseFolder = pwd;
if ischar(source) || isstring(source)
    readOptions = detectImportOptions(char(source), 'TextType','char', 'Delimiter',',');
    textColumns = intersect(readOptions.VariableNames, {'instance','role','meshID','motionFile','branchOf','respondsTo','color'});
    readOptions = setvartype(readOptions, textColumns, 'char');
    rawTable = readtable(char(source), readOptions);
    baseFolder = fileparts(char(source));
    if isempty(baseFolder)
        baseFolder = pwd;
    elseif ~fcn_INTERNAL_isAbsolute(baseFolder)
        baseFolder = fullfile(pwd, baseFolder);
    end
elseif istable(source)
    rawTable = source;
else
    rawTable = struct2table(source(:), 'AsArray', true);
end
rawNames = rawTable.Properties.VariableNames;
lowerNames = lower(rawNames);
if ~any(strcmp(lowerNames,'instance'))
    error('The scene list has no instance column');
end
N = height(rawTable);

% Each column, or its default
instances  = fcn_INTERNAL_textColumn(rawTable, lowerNames, 'instance', '', N);
roles      = fcn_INTERNAL_textColumn(rawTable, lowerNames, 'role', 'traffic', N);
meshIDs    = fcn_INTERNAL_textColumn(rawTable, lowerNames, 'meshid', 'sample', N);
motionFiles= fcn_INTERNAL_textColumn(rawTable, lowerNames, 'motionfile', '', N);
branchOfs  = fcn_INTERNAL_textColumn(rawTable, lowerNames, 'branchof', '', N);
respondsTo = fcn_INTERNAL_textColumn(rawTable, lowerNames, 'respondsto', '', N);
colorTexts = fcn_INTERNAL_colorColumn(rawTable, lowerNames, N);
branchIDs  = fcn_INTERNAL_numberColumn(rawTable, lowerNames, 'branchid', 0, N);
splitTimes = fcn_INTERNAL_numberColumn(rawTable, lowerNames, 'splittime', NaN, N);
alphas     = fcn_INTERNAL_numberColumn(rawTable, lowerNames, 'alpha', NaN, N);
timeOffsets= fcn_INTERNAL_numberColumn(rawTable, lowerNames, 'timeoffset', 0, N);
lengths    = fcn_INTERNAL_numberColumn(rawTable, lowerNames, 'length', NaN, N);
widths     = fcn_INTERNAL_numberColumn(rawTable, lowerNames, 'width', NaN, N);
heights    = fcn_INTERNAL_numberColumn(rawTable, lowerNames, 'height', NaN, N);

% Checks on the values
validRoles = {'ego','traffic','confederate','pedestrian','movingItem'};
badRoles = setdiff(roles, validRoles);
if ~isempty(badRoles)
    error('Unknown role(s): %s. Use: %s', strjoin(badRoles,', '), strjoin(validRoles,', '));
end
if numel(unique(instances)) ~= N || any(cellfun(@isempty,instances))
    error('Every row needs an instance name, and the names must be unique');
end
unknownParents = setdiff(branchOfs(~cellfun(@isempty,branchOfs)), instances);
if ~isempty(unknownParents)
    error('branchOf names an instance that is not in the scene list: %s', strjoin(unknownParents,', '));
end
unknownAnswers = setdiff(respondsTo(~cellfun(@isempty,respondsTo)), instances);
if ~isempty(unknownAnswers)
    error('respondsTo names an instance that is not in the scene list: %s', strjoin(unknownAnswers,', '));
end

% Build the structure array
sceneList = repmat(struct('Instance','', 'Role','', 'MeshID','', 'MotionFile','', 'BranchOf','', ...
    'BranchID',0, 'SplitTime',NaN, 'RespondsTo','', 'Color',nan(1,3), 'Alpha',NaN, ...
    'TimeOffset',0, 'Size',nan(1,3)), N, 1);
for ith_row = 1:N
    motionFile = motionFiles{ith_row};
    if ~isempty(motionFile) && ~fcn_INTERNAL_isAbsolute(motionFile)
        motionFile = fullfile(baseFolder, motionFile);
    end
    sceneList(ith_row).Instance = instances{ith_row};
    sceneList(ith_row).Role = roles{ith_row};
    sceneList(ith_row).MeshID = meshIDs{ith_row};
    sceneList(ith_row).MotionFile = motionFile;
    sceneList(ith_row).BranchOf = branchOfs{ith_row};
    sceneList(ith_row).BranchID = branchIDs(ith_row);
    sceneList(ith_row).SplitTime = splitTimes(ith_row);
    sceneList(ith_row).RespondsTo = respondsTo{ith_row};
    sceneList(ith_row).Color = colorTexts(ith_row,:);
    sceneList(ith_row).Alpha = alphas(ith_row);
    sceneList(ith_row).TimeOffset = timeOffsets(ith_row);
    sceneList(ith_row).Size = [lengths(ith_row) widths(ith_row) heights(ith_row)];
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
    set(gcf, 'Name', 'Scene list', 'NumberTitle', 'off');
    tableData = [{sceneList.Instance}', {sceneList.Role}', {sceneList.MeshID}', ...
        {sceneList.BranchOf}', num2cell([sceneList.BranchID]'), {sceneList.RespondsTo}', ...
        cellfun(@(f) fcn_INTERNAL_shortName(f), {sceneList.MotionFile}', 'UniformOutput', false)];
    uitable(gcf, 'Data', tableData, 'ColumnName', {'instance','role','meshID','branchOf','branchID','respondsTo','motionFile'}, ...
        'Units','normalized', 'Position',[0.01 0.01 0.98 0.98], 'RowName', []);
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

%% fcn_INTERNAL_textColumn
function values = fcn_INTERNAL_textColumn(rawTable, lowerNames, columnName, defaultValue, N)
% A text column as an N x 1 cell array, or the default
index = find(strcmp(lowerNames, lower(columnName)), 1);
if isempty(index)
    values = repmat({defaultValue}, N, 1);
    return;
end
values = rawTable{:, index};
if isstring(values)
    values = cellstr(values);
elseif ~iscell(values)
    values = cellstr(string(values));
end
values = cellfun(@(v) strtrim(char(string(v))), values, 'UniformOutput', false);
values(strcmpi(values,'NaN') | strcmpi(values,'<missing>')) = {''};
if ~isempty(defaultValue)
    values(cellfun(@isempty,values)) = {defaultValue};
end
values = values(:);
end % Ends fcn_INTERNAL_textColumn

%% fcn_INTERNAL_numberColumn
function values = fcn_INTERNAL_numberColumn(rawTable, lowerNames, columnName, defaultValue, N)
% A number column as N x 1, or the default (empty cells take the default)
index = find(strcmp(lowerNames, lower(columnName)), 1);
if isempty(index)
    values = defaultValue*ones(N,1);
    return;
end
values = rawTable{:, index};
if iscell(values) || isstring(values)
    values = str2double(string(values));
end
values = double(values(:));
values(isnan(values)) = defaultValue;
end % Ends fcn_INTERNAL_numberColumn

%% fcn_INTERNAL_colorColumn
function colors = fcn_INTERNAL_colorColumn(rawTable, lowerNames, N)
% Colors as "r g b" text (or a numeric N x 3 field), as N x 3 (NaN if none)
colors = nan(N,3);
index = find(strcmp(lowerNames,'color'), 1);
if isempty(index)
    return;
end
values = rawTable{:, index};
if isnumeric(values) && size(values,2)==3
    colors = double(values);
    return;
end
if ~iscell(values)
    values = cellstr(string(values));
end
for ith_row = 1:N
    thisValue = values{ith_row};
    if isnumeric(thisValue) && numel(thisValue)==3
        colors(ith_row,:) = thisValue(:)';
    else
        numbers = sscanf(strrep(char(string(thisValue)),',',' '), '%f')';
        if numel(numbers)==3
            colors(ith_row,:) = numbers;
        end
    end
end
end % Ends fcn_INTERNAL_colorColumn

%% fcn_INTERNAL_isAbsolute
function flag = fcn_INTERNAL_isAbsolute(fileName)
% A full path (Windows drive letter, or starting with a slash)?
flag = ~isempty(regexp(fileName, '^([A-Za-z]:[\\/]|[\\/])', 'once'));
end % Ends fcn_INTERNAL_isAbsolute

%% fcn_INTERNAL_shortName
function shortName = fcn_INTERNAL_shortName(fileName)
% A file name without its folder
[~, baseName, extension] = fileparts(fileName);
shortName = [baseName extension];
end % Ends fcn_INTERNAL_shortName

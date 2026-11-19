function checkReport = fcn_AnimateCar3D_checkCarMesh3D(options)
% fcn_AnimateCar3D_checkCarMesh3D
% Checks that the copy of CarMesh3D on the MATLAB path still provides
% everything AnimateCar3D relies on: the "contract" between the two
% libraries. Run it after installing a new CarMesh3D release, or while
% changing a working copy of CarMesh3D, to find any conflict before it
% shows up as a confusing error deep inside an animation.
%
% The contract has six parts (each is a "category" in the report):
%
%   functions       every CarMesh3D function AnimateCar3D calls exists,
%                   exactly once on the path, inside the CarMesh3D copy
%                   being checked
%   inputs          each of those functions still takes the same number
%                   of required inputs, and still has every Name=Value
%                   option AnimateCar3D passes to it
%   motionColumns   fcn_CarMesh3D_saveMotionCSV writes the 30 standard
%                   motion columns, in order, and
%                   fcn_CarMesh3D_loadMotionCSV returns every field
%                   AnimateCar3D reads
%   meshFields      a mesh made by the CarMesh3D workflow, and a finished
%                   mesh from its Data folder, have every field
%                   AnimateCar3D reads
%   plotting        fcn_CarMesh3D_plotVehicle returns the plot handles
%                   AnimateCar3D moves, moves the vehicle when called
%                   again with PlotHandles, and turns a pose into a
%                   transform the way fcn_AnimateCar3D_playScene does for
%                   middle-tier vehicles (done in a hidden figure)
%   vehicleFolders  the Data folder follows the vehicle folder rules:
%                   YEAR_Make_Model_Trimline names, the file names
%                   returned by fcn_CarMesh3D_findVehicleFiles, and the
%                   reference vehicle list
%
% FORMAT:
%
%       checkReport = fcn_AnimateCar3D_checkCarMesh3D(...
%           (CarMesh3DRoot=folder), (Checks=categories),...
%           (Contract=contract), (ThrowError=flag), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs, in any order. Any
%      option not given takes its default.
%
% INPUTS:
%
%      (none required)
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      CarMesh3DRoot: the root folder of the CarMesh3D copy to check (the
%      folder holding its Functions and Data folders). Default: the
%      folder in the environment variable
%      MATLABFLAG_ANIMATECAR3D_CARMESH3D_ROOT (set by
%      script_demo_AnimateCar3D), or else the copy where MATLAB finds
%      fcn_CarMesh3D_plotVehicle.
%
%      Checks: 'all' (default), or a cell array of category names from
%      the list above, e.g. {'functions','inputs'}.
%
%      Contract: the contract to check against, as a structure. Default
%      is the current contract (built inside this function; see
%      fcn_INTERNAL_defaultContract). Mainly for testing: a test can
%      change a copy of the contract to check that a conflict is caught.
%      Get the default with checkReport.Contract.
%
%      ThrowError: true (default) to stop with an error listing every
%      failed check; false to only report them.
%
%      FigNum: a figure number to show the results as a table. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      checkReport: a structure with fields
%           Passed: true if every check passed
%           NumChecks, NumFailed: how many checks ran, and failed
%           Results: a table with one row per check: Category, Item,
%               Passed, Message (why it failed, or empty)
%           CarMesh3DRoot: the CarMesh3D copy that was checked
%           CarMesh3DName: that copy's folder name (for a release, its
%               version, e.g. CarMesh3D_2026_11_19b)
%           Contract: the contract used
%
% DEPENDENCIES:
%
%      The CarMesh3D library (the copy being checked)
%
% EXAMPLES:
%
%       checkReport = fcn_AnimateCar3D_checkCarMesh3D(FigNum=1);
%
%       See the script: script_test_fcn_AnimateCar3D_checkCarMesh3D.m
%       for a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_checkCarMesh3D
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_checkCarMesh3D
%   % * Added the scene player's uses: the LightPatches handle and the
%   %   % pose to transform convention

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_checkCarMesh3D
%   % * Add each new CarMesh3D function, option, or field to the contract
%   %   % (fcn_INTERNAL_defaultContract) as soon as AnimateCar3D starts
%   %   % using it
%   % * Add a version check once CarMesh3D has a version function



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.CarMesh3DRoot = ''   % CarMesh3D folder to check; '' for the one in use
    options.Checks = 'all'       % 'all', or a cell array of categories
    options.Contract = []        % [] for the current contract
    options.ThrowError = true    % stop with an error if any check fails
    options.FigNum = []          % figure for a results table; -1 for fast mode
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
allCategories = {'functions','inputs','motionColumns','meshFields','plotting','vehicleFolders'};

if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the CarMesh3DRoot input
        if ~(ischar(options.CarMesh3DRoot) || isstring(options.CarMesh3DRoot))
            error('CarMesh3DRoot must be a folder name');
        end
        if ~isempty(options.CarMesh3DRoot) && ~isfolder(options.CarMesh3DRoot)
            error('CarMesh3DRoot is not a folder: %s', options.CarMesh3DRoot);
        end

        % Check the Checks input
        if ~(isequal(options.Checks,'all') || iscellstr(options.Checks) || isstring(options.Checks))
            error('Checks must be ''all'' or a cell array of category names');
        end
        if ~isequal(options.Checks,'all')
            unknownChecks = setdiff(cellstr(options.Checks), allCategories);
            if ~isempty(unknownChecks)
                error('Unknown check category: %s. Use: %s', strjoin(unknownChecks,', '), strjoin(allCategories,', '));
            end
        end

        % Check the Contract input
        if ~isempty(options.Contract) && ~isstruct(options.Contract)
            error('Contract must be a structure (see checkReport.Contract for the default)');
        end

        % Check the ThrowError input
        if ~((islogical(options.ThrowError) || isnumeric(options.ThrowError)) && isscalar(options.ThrowError))
            error('ThrowError must be true or false');
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

% Which CarMesh3D copy?
carMesh3DRoot = char(options.CarMesh3DRoot);
if isempty(carMesh3DRoot)
    carMesh3DRoot = getenv('MATLABFLAG_ANIMATECAR3D_CARMESH3D_ROOT');
end
if isempty(carMesh3DRoot)
    plotVehicleFile = which('fcn_CarMesh3D_plotVehicle');
    if isempty(plotVehicleFile)
        error('CarMesh3D is not on the MATLAB path. Run script_demo_AnimateCar3D first.');
    end
    carMesh3DRoot = fileparts(fileparts(plotVehicleFile));
end
[~, carMesh3DName] = fileparts(carMesh3DRoot);

% Which contract?
if isempty(options.Contract)
    contract = fcn_INTERNAL_defaultContract;
else
    contract = options.Contract;
end

% Which categories?
if isequal(options.Checks,'all')
    categoriesToRun = allCategories;
else
    categoriesToRun = cellstr(options.Checks);
end

% Run the checks. Each check adds rows to the results list; each one
% runs inside try/catch, so an error is reported as a failed check
% rather than stopping the others.
results = cell(0,4);
if any(strcmp(categoriesToRun,'functions'))
    results = [results; fcn_INTERNAL_checkFunctions(contract, carMesh3DRoot)];
end
if any(strcmp(categoriesToRun,'inputs'))
    results = [results; fcn_INTERNAL_checkInputs(contract)];
end
if any(strcmp(categoriesToRun,'motionColumns'))
    results = [results; fcn_INTERNAL_checkMotionColumns(contract)];
end
if any(strcmp(categoriesToRun,'meshFields'))
    results = [results; fcn_INTERNAL_checkMeshFields(contract, carMesh3DRoot)];
end
if any(strcmp(categoriesToRun,'plotting'))
    results = [results; fcn_INTERNAL_checkPlotting(contract)];
end
if any(strcmp(categoriesToRun,'vehicleFolders'))
    results = [results; fcn_INTERNAL_checkVehicleFolders(contract, carMesh3DRoot)];
end

% Fill the report
resultsTable = cell2table(results, 'VariableNames', {'Category','Item','Passed','Message'});
resultsTable.Passed = logical(resultsTable.Passed);
checkReport = struct;
checkReport.Passed = all(resultsTable.Passed);
checkReport.NumChecks = height(resultsTable);
checkReport.NumFailed = sum(~resultsTable.Passed);
checkReport.Results = resultsTable;
checkReport.CarMesh3DRoot = carMesh3DRoot;
checkReport.CarMesh3DName = carMesh3DName;
checkReport.Contract = contract;

% Report
if 0==flag_max_speed
    fprintf(1,'CarMesh3D contract check (%s): %d of %d checks passed\n', ...
        carMesh3DName, checkReport.NumChecks-checkReport.NumFailed, checkReport.NumChecks);
end
if ~checkReport.Passed
    failedRows = resultsTable(~resultsTable.Passed,:);
    failureText = strjoin(compose('  [%s] %s: %s', string(failedRows.Category), ...
        string(failedRows.Item), string(failedRows.Message)), newline);
    if options.ThrowError
        error('fcn_AnimateCar3D_checkCarMesh3D:conflict', ...
            'CarMesh3D (%s) does not meet what AnimateCar3D needs. %d check(s) failed:\n%s', ...
            carMesh3DName, checkReport.NumFailed, failureText);
    elseif 0==flag_max_speed
        fprintf(1,'Failed checks:\n%s\n', failureText);
    end
end

%% Plot the results (optional)
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
    figureHandle = figure(figNum);
    clf(figureHandle);
    set(figureHandle, 'Name', sprintf('CarMesh3D contract check: %s', carMesh3DName), 'NumberTitle', 'off');
    statusText = repmat({'pass'}, height(resultsTable), 1);
    statusText(~resultsTable.Passed) = {'FAIL'};
    tableData = [statusText, cellstr(resultsTable.Category), cellstr(resultsTable.Item), cellstr(resultsTable.Message)];
    uitable(figureHandle, 'Data', tableData, ...
        'ColumnName', {'Result','Category','Item','Message'}, ...
        'ColumnWidth', {50, 110, 260, 400}, ...
        'Units', 'normalized', 'Position', [0.01 0.01 0.98 0.90], 'RowName', []);
    uicontrol(figureHandle, 'Style', 'text', 'Units', 'normalized', 'Position', [0.01 0.92 0.98 0.06], ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
        'String', sprintf('%s: %d of %d checks passed', carMesh3DName, ...
        checkReport.NumChecks-checkReport.NumFailed, checkReport.NumChecks));
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

%% fcn_INTERNAL_defaultContract
function contract = fcn_INTERNAL_defaultContract
% Everything AnimateCar3D relies on from CarMesh3D. When AnimateCar3D
% starts using another CarMesh3D function, option, or field, add it here.

% Functions: name, number of required (positional) inputs, and the
% Name=Value options AnimateCar3D uses
functionList = {
    'fcn_CarMesh3D_plotVehicle',            1, {'Pose','PlotHandles','WheelSpin','SteerAngle','WheelLift','BodyRoll','BodyPitch','BodyHeave','LightStates','LightEffects','FigNum'}
    'fcn_CarMesh3D_loadMotionCSV',          1, {'VehicleSpec','SampleTime','ColumnNames','FigNum'}
    'fcn_CarMesh3D_saveMotionCSV',          2, {'BodyRoll','BodyPitch','BodyHeave','WheelLift','Lights','FigNum'}
    'fcn_CarMesh3D_fillTrajectory',         0, {'Path','Waypoints','Speed','Duration','SampleTime','StartPose','VehicleSpec','WheelSlip','FigNum'}
    'fcn_CarMesh3D_calcAckermannSteering',  3, {'AckermannFraction','FigNum'}
    'fcn_CarMesh3D_plotScene',              0, {'GroundExtent','GridSpacing','Cubes','PathXY','TimeOfDay','FigNum'}
    'fcn_CarMesh3D_fillCameraSettings',     0, {'Mode','Position','PositionFrame','Target','TargetFrame','FieldOfView','FigNum'}
    'fcn_CarMesh3D_updateCamera',           2, {'Time','AxesHandle','FigNum'}
    'fcn_CarMesh3D_saveGifFrame',           3, {'DelayTime','FigNum'}
    'fcn_CarMesh3D_findVehicleFiles',       1, {'DataFolder','FigNum'}
    'fcn_CarMesh3D_loadVehicleSpec',        1, {'FigNum'}
    'fcn_CarMesh3D_fillVehicleSpec',        0, {'Preset','OverallLength','OverallWidth','OverallHeight','Wheelbase','FigNum'}
    'fcn_CarMesh3D_fillSampleMesh',         0, {'VehicleSpec','FigNum'}
    'fcn_CarMesh3D_labelParts',             1, {'BodyColor','FigNum'}
    'fcn_CarMesh3D_fitMeshToSpec',          2, {'FigNum'}
    'fcn_CarMesh3D_simplifyMesh',           1, {'TargetFaces','FigNum'}
    };
contract.Functions = cell2struct(functionList, {'Name','NumRequiredInputs','Options'}, 2);

% The 30 standard motion columns, in order (fcn_CarMesh3D_saveMotionCSV)
contract.MotionColumns = {'time','X','Y','Z','roll','pitch','yaw','U','V','W', ...
    'roll_rate','pitch_rate','yaw_rate', ...
    'wheelSpeed_FL','wheelSpeed_RL','wheelSpeed_RR','wheelSpeed_FR', ...
    'wheelLift_FL','wheelLift_RL','wheelLift_RR','wheelLift_FR', ...
    'roadRoll','roadPitch','steer_FL','steer_FR', ...
    'headlights','indicator','brakeLight','reverseLight','runningLights'};

% Fields of the motion returned by fcn_CarMesh3D_loadMotionCSV
contract.MotionFields = {'Time','Pose','BodyRoll','BodyPitch','BodyHeave','Speed', ...
    'SteerAngle','WheelSpin','WheelLift','LightStates'};

% Fields of a finished mesh
contract.MeshFields = {'Vertices','Faces','FaceNormals','FacePartIndex','FaceWheelIndex', ...
    'FaceColors','FaceAlpha','PartNames','LightTypeNames','FaceLightType','VehicleSpec','AxleX'};

% Fields of a vehicle specification
contract.SpecFields = {'Name','OverallLength','OverallWidth','OverallHeight','Wheelbase', ...
    'TrackFront','TireDiameter'};

% Fields of the handles from fcn_CarMesh3D_plotVehicle
contract.PlotHandleFields = {'Axes','Transform','BodyTransform','WheelTransforms','Patches','LightPatches'};

% The pose convention: fcn_AnimateCar3D_playScene moves middle-tier
% vehicles by setting their transform directly, with this formula, so it
% must match fcn_CarMesh3D_plotVehicle's: translate, then yaw, pitch, roll
contract.PoseToMatrix = @(pose) makehgtform('translate',pose(1:3)) * makehgtform('zrotate',pose(6)) * ...
    makehgtform('yrotate',pose(5)) * makehgtform('xrotate',pose(4));

% Vehicle folder rules
contract.VehicleIDPattern = '^\d{4}_[A-Za-z0-9]+_[A-Za-z0-9]+_[A-Za-z0-9]+$';
contract.VehicleFileFields = {'ID','Name','Folder','ParametersFile','ScriptFile','MeshFile', ...
    'HasParameters','HasScript','HasMesh'};
contract.VehicleScriptName = 'script_CarMesh3D_vehicle_%s.m';   % %s is the vehicle ID
contract.VehicleMeshName = 'vehicleMesh_%s.mat';
contract.VehicleMeshVariables = {'vehicleMesh','vehicleSpec'};
contract.ReferenceListFile = 'referenceVehicles.csv';            % in the Data folder
contract.ReferenceListColumns = {'ID','Name','Length_m','Width_m','Height_m','Wheelbase_m','Faces','GIF'};
end % Ends fcn_INTERNAL_defaultContract


%% fcn_INTERNAL_checkFunctions
function results = fcn_INTERNAL_checkFunctions(contract, carMesh3DRoot)
% Each function exists, exactly once on the path, inside the copy checked
results = cell(0,4);
for ith_function = 1:length(contract.Functions)
    functionName = contract.Functions(ith_function).Name;
    foundFiles = which(functionName,'-all');
    if isempty(foundFiles)
        results(end+1,:) = {'functions', functionName, false, 'not found on the MATLAB path'}; %#ok<AGROW>
    elseif length(foundFiles)>1
        results(end+1,:) = {'functions', functionName, false, ...
            sprintf('%d copies on the path (expected 1): %s', length(foundFiles), strjoin(foundFiles,' ; '))}; %#ok<AGROW>
    elseif ~startsWith(foundFiles{1}, carMesh3DRoot, 'IgnoreCase', ispc)
        results(end+1,:) = {'functions', functionName, false, ...
            sprintf('found outside the CarMesh3D copy being checked: %s', foundFiles{1})}; %#ok<AGROW>
    else
        results(end+1,:) = {'functions', functionName, true, ''}; %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_checkFunctions


%% fcn_INTERNAL_checkInputs
function results = fcn_INTERNAL_checkInputs(contract)
% Each function's required inputs and Name=Value options, read from its
% source: the "function" line and the arguments block
results = cell(0,4);
for ith_function = 1:length(contract.Functions)
    functionName = contract.Functions(ith_function).Name;
    try
        [requiredInputs, optionNames] = fcn_INTERNAL_readSignature(which(functionName));
        problems = {};
        if length(requiredInputs) ~= contract.Functions(ith_function).NumRequiredInputs
            problems{end+1} = sprintf('takes %d required inputs (%s); expected %d', ...
                length(requiredInputs), strjoin(requiredInputs,', '), contract.Functions(ith_function).NumRequiredInputs); %#ok<AGROW>
        end
        missingOptions = setdiff(contract.Functions(ith_function).Options, optionNames, 'stable');
        if ~isempty(missingOptions)
            problems{end+1} = sprintf('missing option(s): %s', strjoin(missingOptions,', ')); %#ok<AGROW>
        end
        results(end+1,:) = {'inputs', functionName, isempty(problems), strjoin(problems,'; ')}; %#ok<AGROW>
    catch ME
        results(end+1,:) = {'inputs', functionName, false, ME.message}; %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_checkInputs


%% fcn_INTERNAL_readSignature
function [requiredInputs, optionNames] = fcn_INTERNAL_readSignature(fileName)
% The required input names (from the function line) and the option names
% (options.<Name> lines in the arguments block) of a function file
if isempty(fileName)
    error('file not found');
end
sourceLines = splitlines(fileread(fileName));

% The function line
functionLineIndex = find(startsWith(strtrim(sourceLines),'function '),1);
inputText = regexp(sourceLines{functionLineIndex}, '\((.*)\)', 'tokens', 'once');
if isempty(inputText) || isempty(strtrim(inputText{1}))
    inputNames = {};
else
    inputNames = strtrim(strsplit(inputText{1}, ','));
end
requiredInputs = inputNames(~strcmp(inputNames,'options'));

% The arguments block
argumentsStart = find(strcmp(strtrim(sourceLines),'arguments'),1);
optionNames = {};
if ~isempty(argumentsStart)
    for ith_line = argumentsStart+1:length(sourceLines)
        thisLine = strtrim(sourceLines{ith_line});
        if strcmp(thisLine,'end') || startsWith(thisLine,'end ') || startsWith(thisLine,'end%')
            break;
        end
        optionToken = regexp(thisLine, '^options\.(\w+)', 'tokens', 'once');
        if ~isempty(optionToken)
            optionNames{end+1} = optionToken{1}; %#ok<AGROW>
        end
    end
end
end % Ends fcn_INTERNAL_readSignature


%% fcn_INTERNAL_checkMotionColumns
function results = fcn_INTERNAL_checkMotionColumns(contract)
% Write a short motion with fcn_CarMesh3D_saveMotionCSV, check its header,
% then read it back with fcn_CarMesh3D_loadMotionCSV and check the fields
results = cell(0,4);
csvFile = [tempname '.csv'];
cleanupFile = onCleanup(@() fcn_INTERNAL_deleteIfFile(csvFile));
try
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
    trajectory = fcn_CarMesh3D_fillTrajectory(Path='straight', Speed=5, Duration=1, VehicleSpec=vehicleSpec, FigNum=-1);
    fcn_CarMesh3D_saveMotionCSV(csvFile, trajectory, FigNum=-1);

    % The header row
    fileID = fopen(csvFile,'r');
    headerLine = fgetl(fileID);
    fclose(fileID);
    columnNames = strtrim(strsplit(headerLine, ','));
    expectedColumns = contract.MotionColumns;
    if length(columnNames) < length(expectedColumns)
        results(end+1,:) = {'motionColumns', 'saved column names', false, ...
            sprintf('%d columns written; expected at least %d', length(columnNames), length(expectedColumns))};
    else
        firstColumns = columnNames(1:length(expectedColumns));
        mismatches = find(~strcmp(firstColumns, expectedColumns));
        if isempty(mismatches)
            results(end+1,:) = {'motionColumns', 'saved column names', true, ''};
        else
            results(end+1,:) = {'motionColumns', 'saved column names', false, ...
                sprintf('column %d is "%s"; expected "%s"', mismatches(1), firstColumns{mismatches(1)}, expectedColumns{mismatches(1)})};
        end
    end
catch ME
    results(end+1,:) = {'motionColumns', 'saved column names', false, ME.message};
end

try
    motion = fcn_CarMesh3D_loadMotionCSV(csvFile, VehicleSpec=vehicleSpec, FigNum=-1);
    results(end+1,:) = fcn_INTERNAL_fieldResult('motionColumns', 'fields read back by loadMotionCSV', motion, contract.MotionFields);
catch ME
    results(end+1,:) = {'motionColumns', 'fields read back by loadMotionCSV', false, ME.message};
end
end % Ends fcn_INTERNAL_checkMotionColumns


%% fcn_INTERNAL_checkMeshFields
function results = fcn_INTERNAL_checkMeshFields(contract, carMesh3DRoot)
% A mesh made by the CarMesh3D workflow, and a finished mesh from Data
results = cell(0,4);
try
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
    results(end+1,:) = fcn_INTERNAL_fieldResult('meshFields', 'vehicle specification (fillVehicleSpec)', vehicleSpec, contract.SpecFields);
    vehicleMesh = fcn_INTERNAL_makeSampleMesh(vehicleSpec);
    results(end+1,:) = fcn_INTERNAL_fieldResult('meshFields', 'mesh made by the workflow (sample car)', vehicleMesh, contract.MeshFields);
catch ME
    results(end+1,:) = {'meshFields', 'mesh made by the workflow (sample car)', false, ME.message};
end

% A finished mesh from the Data folder (the first vehicle that has one)
try
    allVehicles = fcn_CarMesh3D_findVehicleFiles('', DataFolder=fullfile(carMesh3DRoot,'Data'), FigNum=-1);
    meshFile = '';
    for ith_vehicle = 1:length(allVehicles)
        vehicleFiles = fcn_CarMesh3D_findVehicleFiles(allVehicles(ith_vehicle).ID, DataFolder=fullfile(carMesh3DRoot,'Data'), FigNum=-1);
        if vehicleFiles.HasMesh
            meshFile = vehicleFiles.MeshFile;
            break;
        end
    end
    if isempty(meshFile)
        results(end+1,:) = {'meshFields', 'finished mesh in Data', false, 'no vehicle in Data has a finished mesh'};
    else
        savedVariables = whos('-file', meshFile);
        missingVariables = setdiff(contract.VehicleMeshVariables, {savedVariables.name}, 'stable');
        if ~isempty(missingVariables)
            results(end+1,:) = {'meshFields', sprintf('finished mesh in Data (%s)', vehicleFiles.ID), false, ...
                sprintf('the file is missing variable(s): %s', strjoin(missingVariables,', '))};
        else
            loaded = load(meshFile, contract.VehicleMeshVariables{:});
            results(end+1,:) = fcn_INTERNAL_fieldResult('meshFields', sprintf('finished mesh in Data (%s)', vehicleFiles.ID), ...
                loaded.vehicleMesh, contract.MeshFields);
        end
    end
catch ME
    results(end+1,:) = {'meshFields', 'finished mesh in Data', false, ME.message};
end
end % Ends fcn_INTERNAL_checkMeshFields


%% fcn_INTERNAL_checkPlotting
function results = fcn_INTERNAL_checkPlotting(contract)
% Plot the sample car in a hidden figure, check the handles, then move it
results = cell(0,4);
figureHandle = figure('Visible','off');
cleanupFigure = onCleanup(@() close(figureHandle));
try
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
    vehicleMesh = fcn_INTERNAL_makeSampleMesh(vehicleSpec);
    plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figureHandle.Number);
    results(end+1,:) = fcn_INTERNAL_fieldResult('plotting', 'handles returned by plotVehicle', plotHandles, contract.PlotHandleFields);

    % Move it the way the scene player will: a new pose and body motion,
    % reusing the handles
    matrixBefore = get(plotHandles.Transform, 'Matrix');
    fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[3 1 0.5], WheelSpin=[1 1 1 1], SteerAngle=[0.1 0.08], ...
        BodyRoll=0.02, BodyPitch=0.01, BodyHeave=0.01, PlotHandles=plotHandles, FigNum=-1);
    matrixAfter = get(plotHandles.Transform, 'Matrix');
    if norm(matrixAfter(1:3,4) - [3;1;0]) < 1e-9 && ~isequal(matrixAfter, matrixBefore)
        results(end+1,:) = {'plotting', 'moving the vehicle with PlotHandles', true, ''};
    else
        results(end+1,:) = {'plotting', 'moving the vehicle with PlotHandles', false, ...
            sprintf('the vehicle transform did not move to Pose [3 1 0.5]: its position is [%s]', num2str(matrixAfter(1:3,4)'))};
    end

    % The pose convention (a full 6-element pose)
    testPose = [3 1 0.2 0.05 0.03 0.5];
    fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=testPose, PlotHandles=plotHandles, FigNum=-1);
    matrixPlotted = get(plotHandles.Transform, 'Matrix');
    matrixExpected = contract.PoseToMatrix(testPose);
    if max(abs(matrixPlotted(:) - matrixExpected(:))) < 1e-9
        results(end+1,:) = {'plotting', 'pose to transform convention', true, ''};
    else
        results(end+1,:) = {'plotting', 'pose to transform convention', false, ...
            'fcn_CarMesh3D_plotVehicle turns a pose into a transform differently from the contract (and from fcn_AnimateCar3D_playScene''s middle tier)'};
    end
catch ME
    results(end+1,:) = {'plotting', 'plotting and moving the sample car', false, ME.message};
end
end % Ends fcn_INTERNAL_checkPlotting


%% fcn_INTERNAL_checkVehicleFolders
function results = fcn_INTERNAL_checkVehicleFolders(contract, carMesh3DRoot)
% The Data folder follows the vehicle folder rules
results = cell(0,4);
dataFolder = fullfile(carMesh3DRoot,'Data');
try
    allVehicles = fcn_CarMesh3D_findVehicleFiles('', DataFolder=dataFolder, FigNum=-1);
    if isempty(allVehicles)
        results(end+1,:) = {'vehicleFolders', 'vehicles in Data', false, 'no vehicle folders found'};
    else
        results(end+1,:) = {'vehicleFolders', 'vehicles in Data', true, ''};
    end
    for ith_vehicle = 1:length(allVehicles)
        vehicleID = allVehicles(ith_vehicle).ID;
        problems = {};
        if isempty(regexp(vehicleID, contract.VehicleIDPattern, 'once'))
            problems{end+1} = 'name does not follow YEAR_Make_Model_Trimline'; %#ok<AGROW>
        end
        vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, DataFolder=dataFolder, FigNum=-1);
        missingFields = setdiff(contract.VehicleFileFields, fieldnames(vehicleFiles), 'stable');
        if ~isempty(missingFields)
            problems{end+1} = sprintf('findVehicleFiles is missing field(s): %s', strjoin(missingFields,', ')); %#ok<AGROW>
        else
            [~, scriptName, scriptExtension] = fileparts(vehicleFiles.ScriptFile);
            if ~strcmp([scriptName scriptExtension], sprintf(contract.VehicleScriptName, vehicleID))
                problems{end+1} = sprintf('vehicle script is named %s; expected %s', [scriptName scriptExtension], sprintf(contract.VehicleScriptName, vehicleID)); %#ok<AGROW>
            end
            [~, meshName, meshExtension] = fileparts(vehicleFiles.MeshFile);
            if ~strcmp([meshName meshExtension], sprintf(contract.VehicleMeshName, vehicleID))
                problems{end+1} = sprintf('mesh file is named %s; expected %s', [meshName meshExtension], sprintf(contract.VehicleMeshName, vehicleID)); %#ok<AGROW>
            end
            if ~vehicleFiles.HasParameters
                problems{end+1} = 'no vehicleParameters file'; %#ok<AGROW>
            end
        end
        results(end+1,:) = {'vehicleFolders', sprintf('vehicle folder %s', vehicleID), isempty(problems), strjoin(problems,'; ')}; %#ok<AGROW>
    end
catch ME
    results(end+1,:) = {'vehicleFolders', 'vehicle folders (findVehicleFiles)', false, ME.message};
end

% The reference vehicle list
referenceFile = fullfile(dataFolder, contract.ReferenceListFile);
try
    if ~isfile(referenceFile)
        results(end+1,:) = {'vehicleFolders', 'reference vehicle list', false, sprintf('%s not found', referenceFile)};
    else
        referenceTable = readtable(referenceFile, 'TextType','string', 'Delimiter', ',');
        missingColumns = setdiff(contract.ReferenceListColumns, referenceTable.Properties.VariableNames, 'stable');
        if isempty(missingColumns)
            results(end+1,:) = {'vehicleFolders', 'reference vehicle list', true, ''};
        else
            results(end+1,:) = {'vehicleFolders', 'reference vehicle list', false, ...
                sprintf('missing column(s): %s', strjoin(missingColumns,', '))};
        end
    end
catch ME
    results(end+1,:) = {'vehicleFolders', 'reference vehicle list', false, ME.message};
end
end % Ends fcn_INTERNAL_checkVehicleFolders


%% fcn_INTERNAL_makeSampleMesh
function vehicleMesh = fcn_INTERNAL_makeSampleMesh(vehicleSpec)
% The CarMesh3D workflow on its built-in sample car
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, FigNum=-1);
end % Ends fcn_INTERNAL_makeSampleMesh


%% fcn_INTERNAL_fieldResult
function resultRow = fcn_INTERNAL_fieldResult(category, itemName, structureToCheck, requiredFields)
% One result row: does the structure have every required field?
missingFields = setdiff(requiredFields, fieldnames(structureToCheck), 'stable');
if isempty(missingFields)
    resultRow = {category, itemName, true, ''};
else
    resultRow = {category, itemName, false, sprintf('missing field(s): %s', strjoin(missingFields,', '))};
end
end % Ends fcn_INTERNAL_fieldResult


%% fcn_INTERNAL_deleteIfFile
function fcn_INTERNAL_deleteIfFile(fileName)
if isfile(fileName)
    delete(fileName);
end
end % Ends fcn_INTERNAL_deleteIfFile

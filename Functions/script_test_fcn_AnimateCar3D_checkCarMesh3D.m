% script_test_fcn_AnimateCar3D_checkCarMesh3D.m
% Tests fcn_AnimateCar3D_checkCarMesh3D
% Checks that the CarMesh3D copy on the path provides everything
% AnimateCar3D relies on (the contract between the two libraries).
%
% Run script_demo_AnimateCar3D first, so that exactly one copy of
% CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_checkCarMesh3D
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_checkCarMesh3D
%   % * (fill in items here)


%% Set up the workspace
close all

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: Check the CarMesh3D copy in use, and show the results
figNum = 10001;
titleString = sprintf('DEMO case: Check the CarMesh3D copy in use, and show the results');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

checkReport = fcn_AnimateCar3D_checkCarMesh3D(FigNum=figNum);

% Check variable types
assert(isstruct(checkReport));
assert(islogical(checkReport.Passed) && isscalar(checkReport.Passed));
assert(istable(checkReport.Results));
assert(all(ismember({'Category','Item','Passed','Message'}, checkReport.Results.Properties.VariableNames)));
assert(isstruct(checkReport.Contract));

% Check variable sizes
assert(checkReport.NumChecks == height(checkReport.Results));
assert(checkReport.NumChecks > 20);

% Check variable values: everything passes, all six categories ran, and
% the copy checked is the one MATLAB uses
assert(checkReport.Passed);
assert(checkReport.NumFailed == 0);
assert(isempty(setxor(unique(cellstr(checkReport.Results.Category)), ...
    {'functions','inputs','motionColumns','meshFields','plotting','vehicleFolders'})));
assert(startsWith(which('fcn_CarMesh3D_plotVehicle'), checkReport.CarMesh3DRoot));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_    ___ __ _ ___  ___  ___
%    | |/ _ \/ __| __|  / __/ _` / __|/ _ \/ __|
%    | |  __/\__ \ |_  | (_| (_| \__ \  __/\__ \
%    |_|\___||___/\__|  \___\__,_|___/\___||___/
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Only some categories
figNum = 20001;
titleString = sprintf('TEST case: Only some categories');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

checkReport = fcn_AnimateCar3D_checkCarMesh3D(Checks={'functions','inputs'});

% Check variable values: only those two categories, one row per function each
assert(checkReport.Passed);
assert(isempty(setxor(unique(cellstr(checkReport.Results.Category)), {'functions','inputs'})));
assert(checkReport.NumChecks == 2*length(checkReport.Contract.Functions));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A conflict is caught (a function and an option that do not exist)
figNum = 20002;
titleString = sprintf('TEST case: A conflict is caught (a function and an option that do not exist)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% Make a contract that CarMesh3D cannot meet
goodReport = fcn_AnimateCar3D_checkCarMesh3D(Checks={'functions'}, FigNum=-1);
badContract = goodReport.Contract;
badContract.Functions(end+1) = struct('Name','fcn_CarMesh3D_doesNotExist', 'NumRequiredInputs',0, 'Options',{{}});
badContract.Functions(1).Options{end+1} = 'NoSuchOption';

% Reported, not thrown, with ThrowError=false
checkReport = fcn_AnimateCar3D_checkCarMesh3D(Checks={'functions','inputs'}, Contract=badContract, ThrowError=false);
assert(~checkReport.Passed);
failedItems = cellstr(checkReport.Results.Item(~checkReport.Results.Passed));
assert(any(strcmp(failedItems, 'fcn_CarMesh3D_doesNotExist')));
assert(any(strcmp(failedItems, badContract.Functions(1).Name)));
failedMessages = strjoin(cellstr(checkReport.Results.Message(~checkReport.Results.Passed)), ' ');
assert(contains(failedMessages, 'not found on the MATLAB path'));
assert(contains(failedMessages, 'NoSuchOption'));

% Thrown as an error by default, with a message naming each failure
flagThrown = false;
try
    fcn_AnimateCar3D_checkCarMesh3D(Checks={'functions','inputs'}, Contract=badContract);
catch ME
    flagThrown = true;
    assert(strcmp(ME.identifier, 'fcn_AnimateCar3D_checkCarMesh3D:conflict'));
    assert(contains(ME.message, 'fcn_CarMesh3D_doesNotExist'));
    assert(contains(ME.message, 'NoSuchOption'));
end
assert(flagThrown);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A changed motion column and mesh field are caught
figNum = 20003;
titleString = sprintf('TEST case: A changed motion column and mesh field are caught');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

badContract = goodReport.Contract;
badContract.MotionColumns{11} = 'rollRate';           % the old spelling of roll_rate
badContract.MeshFields{end+1} = 'FaceTextureCoordinates';
checkReport = fcn_AnimateCar3D_checkCarMesh3D(Checks={'motionColumns','meshFields'}, Contract=badContract, ThrowError=false);
failedMessages = strjoin(cellstr(checkReport.Results.Message(~checkReport.Results.Passed)), ' ');
assert(contains(failedMessages, 'column 11 is "roll_rate"; expected "rollRate"'));
assert(contains(failedMessages, 'FaceTextureCoordinates'));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
checkReport = fcn_AnimateCar3D_checkCarMesh3D(Checks={'functions'}, FigNum=[]);
assert(checkReport.Passed);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
checkReport = fcn_AnimateCar3D_checkCarMesh3D(Checks={'functions'}, FigNum=-1);
assert(checkReport.Passed);

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: An unknown check category
if 1==0
    fcn_AnimateCar3D_checkCarMesh3D(Checks={'paint'});
end

%% FAIL case: A CarMesh3D folder that does not exist
if 1==0
    fcn_AnimateCar3D_checkCarMesh3D(CarMesh3DRoot='C:\noSuchFolder');
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


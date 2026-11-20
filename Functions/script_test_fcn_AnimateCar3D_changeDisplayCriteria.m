% script_test_fcn_AnimateCar3D_changeDisplayCriteria.m
% Tests fcn_AnimateCar3D_changeDisplayCriteria
% Changes some display criteria while an animation runs, from a structure or a text file.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_changeDisplayCriteria
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_changeDisplayCriteria
%   % * (fill in items here)


%% Set up the workspace
close all

criteria = fcn_AnimateCar3D_fillDisplayCriteria(NearDistance=40);

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

%% DEMO case: Change the region to a circle around the ego, from a text file
figNum = 10001;
titleString = sprintf('DEMO case: Change the region to a circle around the ego, from a text file');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

criteriaFile = [tempname '.txt'];
fileID = fopen(criteriaFile, 'w');
fprintf(fileID, '%% Show only what is near the ego\n');
fprintf(fileID, 'Region = circle\n');
fprintf(fileID, 'Radius = 45\n\n');
fprintf(fileID, 'RolesShown = ego, confederate, traffic\n');
fprintf(fileID, 'BoxSize = [120, 40]\n');
fprintf(fileID, 'HideParentAtSplit = false\n');
fprintf(fileID, 'FixedTiers = ego near; confederate middle\n');
fprintf(fileID, 'FarCount = Inf\n');
fclose(fileID);
[newCriteria, changedNames] = fcn_AnimateCar3D_changeDisplayCriteria(criteria, criteriaFile, FigNum=figNum);

% Check variable types
assert(isstruct(newCriteria) && iscell(changedNames));

% Check variable sizes
assert(isequal(size(newCriteria.FixedTiers), [2 2]));

% Check variable values
assert(strcmp(newCriteria.Region,'circle') && newCriteria.Radius==45);
assert(isequal(newCriteria.RolesShown, {'ego','confederate','traffic'}));
assert(isequal(newCriteria.BoxSize, [120 40]) && newCriteria.HideParentAtSplit==false);
assert(isequal(newCriteria.FixedTiers, {'ego','near';'confederate','middle'}));
assert(newCriteria.NearDistance==40);            % kept from before
assert(isequal(sort(changedNames), sort({'Region','Radius','RolesShown','BoxSize','HideParentAtSplit','FixedTiers'})));
delete(criteriaFile);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Changes from a structure; a fixed center from numbers
figNum = 20001;
titleString = sprintf('TEST case: Changes from a structure; a fixed center from numbers');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

newCriteria = fcn_AnimateCar3D_changeDisplayCriteria(criteria, struct('FarDistance',150, 'Center',[10 20]));
assert(newCriteria.FarDistance==150 && isequal(newCriteria.Center,[10 20]) && newCriteria.NearDistance==40);
criteriaFile = [tempname '.txt'];
writelines(["Center = 5, -3"; "Hysteresis = 0.2"], criteriaFile);
newCriteria = fcn_AnimateCar3D_changeDisplayCriteria(criteria, criteriaFile);
assert(isequal(newCriteria.Center,[5 -3]) && newCriteria.Hysteresis==0.2);
delete(criteriaFile);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A bad change with OnError 'warn' keeps the old criteria
figNum = 20002;
titleString = sprintf('TEST case: A bad change with OnError ''warn'' keeps the old criteria');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

criteriaFile = [tempname '.txt'];
writelines(["Radius = 45"; "Regoin = circle"], criteriaFile);     % a typing mistake
warningState = warning('off','AnimateCar3D:criteriaNotChanged');
[sameCriteria, changedNames] = fcn_AnimateCar3D_changeDisplayCriteria(criteria, criteriaFile, OnError='warn');
warning(warningState);
assert(isequal(sameCriteria, criteria) && isempty(changedNames));
writelines("NearDistance = -5", criteriaFile);                    % a bad value
warningState = warning('off','AnimateCar3D:criteriaNotChanged');
sameCriteria = fcn_AnimateCar3D_changeDisplayCriteria(criteria, criteriaFile, OnError='warn');
warning(warningState);
assert(isequal(sameCriteria, criteria));
delete(criteriaFile);

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
newCriteria = fcn_AnimateCar3D_changeDisplayCriteria(criteria, struct('Radius',60), FigNum=[]);
assert(newCriteria.Radius==60);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
newCriteria = fcn_AnimateCar3D_changeDisplayCriteria(criteria, struct('Radius',60), FigNum=-1);
assert(newCriteria.Radius==60);

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: An unknown name
if 1==0
    fcn_AnimateCar3D_changeDisplayCriteria(criteria, struct('Raduis',60));
end

%% FAIL case: A bad value
if 1==0
    fcn_AnimateCar3D_changeDisplayCriteria(criteria, struct('NearDistance',-5));
end

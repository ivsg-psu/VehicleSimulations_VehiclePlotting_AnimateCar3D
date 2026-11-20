% script_test_fcn_AnimateCar3D_fillDisplayCriteria.m
% Tests fcn_AnimateCar3D_fillDisplayCriteria
% Makes the display criteria the selector reads at every step.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillDisplayCriteria
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillDisplayCriteria
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

%% DEMO case: The defaults (the camera's view)
figNum = 10001;
titleString = sprintf('DEMO case: The defaults (the camera''s view)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

criteria = fcn_AnimateCar3D_fillDisplayCriteria(FigNum=figNum);

% Check variable types
assert(isstruct(criteria));

% Check variable values
assert(strcmp(criteria.Region,'cameraView') && strcmp(criteria.Center,'ego'));
assert(criteria.TopScreenSize==105 && criteria.MergeBelowSize==37 && criteria.MinScreenSize==1);
assert(criteria.NearCount==10 && criteria.MiddleCount==40 && isinf(criteria.FarCount));
assert(criteria.MaxDistance==500 && criteria.NominalScale==618 && abs(criteria.Hysteresis-0.1)<1e-12);
assert(~any(isfield(criteria, {'NearDistance','MiddleDistance','FarDistance'})));
assert(isequal(criteria.FixedTiers, {'ego','near'}));
assert(~isfield(criteria,'FigNum'));

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

%% TEST case: A fixed circle, a moving box, and the camera's target
figNum = 20001;
titleString = sprintf('TEST case: A fixed circle, a moving box, and the camera''s target');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Center=[120 0], Radius=60, FigNum=figNum);
assert(isequal(criteria.Center,[120 0]) && criteria.Radius==60);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='box', Center=@(t) [10*t 0 0], BoxAlign='heading');
assert(isa(criteria.Center,'function_handle') && isequal(criteria.Center(2), [20 0 0]));
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Center="camera");
assert(ischar(criteria.Center) && strcmp(criteria.Center,'camera'));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(FigNum=[]);
assert(isstruct(criteria));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(FigNum=-1);
assert(isstruct(criteria));

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

%% FAIL case: Tier sizes out of order
if 1==0
    fcn_AnimateCar3D_fillDisplayCriteria(TopScreenSize=30, MergeBelowSize=37);
end

%% FAIL case: An unknown region
if 1==0
    fcn_AnimateCar3D_fillDisplayCriteria(Region='sphere');
end

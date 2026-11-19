% script_test_fcn_AnimateCar3D_fillBranchMotions.m
% Tests fcn_AnimateCar3D_fillBranchMotions
% Makes a parent motion that splits into decision branches.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillBranchMotions
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillBranchMotions
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

%% DEMO case: Ten branches splitting at 2 s
figNum = 10001;
titleString = sprintf('DEMO case: Ten branches splitting at 2 s');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

branchMotions = fcn_AnimateCar3D_fillBranchMotions(FigNum=figNum);

% Check variable types
assert(isstruct(branchMotions.Parent));
assert(isstruct(branchMotions.Branches));

% Check variable sizes
assert(numel(branchMotions.Branches)==10);
K = numel(branchMotions.Branches(1).Time);
assert(isequal(size(branchMotions.Branches(1).Pose),[K 3]));
assert(isequal(size(branchMotions.Branches(1).WheelSpin),[K 4]));
assert(isequal(size(branchMotions.Branches(1).SteerAngle),[K 2]));

% Check variable values
parent = branchMotions.Parent;
assert(abs(parent.Time(end) - 2) < 1e-9);
assert(abs(parent.Pose(end,1) - 16) < 1e-9);     % 8 m/s for 2 s
for ith_branch = 1:10
    thisBranch = branchMotions.Branches(ith_branch);
    % Each branch starts exactly at the parent's pose and wheel spin
    assert(norm(thisBranch.Pose(1,:) - parent.Pose(end,:)) < 1e-9);
    assert(abs(thisBranch.WheelSpin(1,1) - parent.WheelSpin(end,1)) < 1e-9);
    assert(strcmp(thisBranch.BranchOf,'ego') && thisBranch.BranchID==ith_branch);
    % Speed stays 8 m/s
    stepLengths = vecnorm(diff(thisBranch.Pose(:,1:2)),2,2);
    assert(all(abs(stepLengths/0.05 - 8) < 0.01));
end
% Branch 1 turns hardest left, branch 10 hardest right, and the left
% turn's inside (left) tire steers more than the outside
assert(branchMotions.Branches(1).Pose(end,2) > 0 && branchMotions.Branches(10).Pose(end,2) < 0);
assert(branchMotions.Branches(1).SteerAngle(end,1) > branchMotions.Branches(1).SteerAngle(end,2));
% The final heading change of branch 1: about curvature x distance
% (1/20 x 8 m/s x (4 s - 0.4 s ramp half)) = 1.44 rad
assert(abs(branchMotions.Branches(1).Pose(end,3) - 1.44) < 0.02);

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

%% TEST case: One branch goes straight on
figNum = 20001;
titleString = sprintf('TEST case: One branch goes straight on');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

branchMotions = fcn_AnimateCar3D_fillBranchMotions(NumBranches=1, StartPose=[5 2 pi/2], ParentName='confederate1');
thisBranch = branchMotions.Branches(1);
assert(abs(thisBranch.Pose(end,1) - 5) < 1e-9);
assert(abs(thisBranch.Pose(end,2) - (2 + 8*6)) < 1e-9);
assert(strcmp(thisBranch.Instance,'confederate1_branch1'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
branchMotions = fcn_AnimateCar3D_fillBranchMotions(NumBranches=3, FigNum=[]);
assert(numel(branchMotions.Branches)==3);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
branchMotions = fcn_AnimateCar3D_fillBranchMotions(NumBranches=3, FigNum=-1);
assert(numel(branchMotions.Branches)==3);

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

%% FAIL case: A split after the end
if 1==0
    fcn_AnimateCar3D_fillBranchMotions(SplitTime=10, Duration=6);
end

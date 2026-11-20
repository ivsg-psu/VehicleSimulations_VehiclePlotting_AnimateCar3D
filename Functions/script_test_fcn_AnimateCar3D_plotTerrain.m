% script_test_fcn_AnimateCar3D_plotTerrain.m
% Tests fcn_AnimateCar3D_plotTerrain
% Draws the ground from fcn_AnimateCar3D_fillTerrain: grass and block trees.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_plotTerrain
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_plotTerrain
%   % * (fill in items here)


%% Set up the workspace
close all

mountainRoad = fcn_AnimateCar3D_fillRoad(Preset='curvy', Elevation='mountain', FigNum=-1);
terrain = fcn_AnimateCar3D_fillTerrain(mountainRoad, GridSpacing=10, FigNum=-1);

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

%% DEMO case: The ground and trees
figNum = 10001;
titleString = sprintf('DEMO case: The ground and trees');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

handles = fcn_AnimateCar3D_plotTerrain(terrain, FigNum=figNum);

% Check variable types
assert(isgraphics(handles.Ground, 'patch') && isgraphics(handles.Trees, 'patch') && isgraphics(handles.SeeThrough, 'patch'));

% Check variable sizes
Nfull = (numel(terrain.X)-1)*(numel(terrain.Y)-1);
assert(handles.NumGroundFaces < 0.6*Nfull);   % (coarse far from the road)

% Check variable values: near-side trees see-through
assert(handles.SeeThrough.FaceAlpha==0.3 && handles.NumFaces==size(handles.Ground.Faces,1) + 12*numel(terrain.Trees));
% (the full grid everywhere, either way of asking)
fullHandles = fcn_AnimateCar3D_plotTerrain(terrain, CoarseStep=1, FigNum=figNum + 1);
assert(fullHandles.NumGroundFaces==Nfull);
fullHandles = fcn_AnimateCar3D_plotTerrain(terrain, NearDistance=Inf, FigNum=figNum + 2);
assert(fullHandles.NumGroundFaces==Nfull);
close([figNum + 1, figNum + 2]);

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

%% TEST case: Another grass color; solid near-side trees
figNum = 20001;
titleString = sprintf('TEST case: Another grass color; solid near-side trees');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

handles = fcn_AnimateCar3D_plotTerrain(terrain, GrassColor=[0.3 0.4 0.25], NearSideAlpha=1, FigNum=figNum);
assert(max(handles.Ground.FaceVertexCData(:,1)) <= 0.3*1.03 + 1e-9 && handles.SeeThrough.FaceAlpha==1);
nightHandles = fcn_AnimateCar3D_plotTerrain(terrain, TimeOfDay='night', FigNum=figNum);
assert(max(nightHandles.Ground.FaceVertexCData(:,2)) <= 0.55*0.55*1.03 + 1e-9);

%% Fast Mode Tests

%% Basic fast mode - FAST MODE (the current axes)
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum);
handles = fcn_AnimateCar3D_plotTerrain(terrain, FigNum=-1);
assert(isequal(handles.Axes.Parent.Number, figNum));
close(figNum);

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

%% FAIL case: Not a terrain
if 1==0
    fcn_AnimateCar3D_plotTerrain(struct('X',1));
end

%% FAIL case: A coarse step that is not a whole number
if 1==0
    fcn_AnimateCar3D_plotTerrain(terrain, CoarseStep=2.5);
end

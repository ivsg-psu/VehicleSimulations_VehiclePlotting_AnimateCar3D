% script_test_fcn_AnimateCar3D_plotRoad.m
% Tests fcn_AnimateCar3D_plotRoad
% Draws a road: lane surfaces, road marks, curbs, and road objects.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_plotRoad
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_plotRoad
%   % * (fill in items here)


%% Set up the workspace
close all

twoLaneRoad = fcn_AnimateCar3D_fillRoad(Preset='twoLane', FigNum=-1);

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

%% DEMO case: An urban street: curbs, sidewalks, a crosswalk, trees, and buildings
figNum = 10001;
titleString = sprintf('DEMO case: An urban street: curbs, sidewalks, a crosswalk, trees, and buildings');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

urbanRoad = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet', FigNum=-1);
handles = fcn_AnimateCar3D_plotRoad(urbanRoad, FigNum=figNum);

% Check variable types
assert(isstruct(handles) && isgraphics(handles.Surface, 'patch') && isgraphics(handles.Marks, 'patch') ...
    && isgraphics(handles.Objects, 'patch'));

% Check variable sizes
assert(isscalar(handles.Surface) && isscalar(handles.Marks) && isscalar(handles.Objects));

% Check variable values: curbs reach 0.15 m; buildings stand tall; the
% marks are only white or yellow
assert(abs(max(handles.Surface.Vertices(:,3)) - 0.15) < 1e-9);
assert(max(handles.Objects.Vertices(:,3)) > 6);
markColors = unique(handles.Marks.FaceVertexCData, 'rows');
assert(size(markColors,1)==1 && all(abs(markColors - [0.96 0.76 0.12]) < 1e-9));   % (only the double yellow line)

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

%% TEST case: A two-lane road: one broken yellow center line, two solid white edges
figNum = 20001;
titleString = sprintf('TEST case: A two-lane road: one broken yellow center line, two solid white edges');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

handles = fcn_AnimateCar3D_plotRoad(twoLaneRoad, FigNum=figNum);
markColors = handles.Marks.FaceVertexCData;
isYellow = all(abs(markColors - [0.96 0.76 0.12]) < 1e-9, 2);
% (300 m straight: 25 dashes of 3 m every 12 m; the edges sampled only
% every 50 m: 6 faces each)
assert(sum(isYellow) >= 25 && sum(isYellow) <= 30 && sum(~isYellow)==2*6);
assert(isempty(handles.Objects) && all(abs(handles.Surface.Vertices(:,3)) < 1e-12));
assert(isequal(zlim(handles.Axes), [-0.5 10]));                % (room for a camera above the road)
% The marks sit just above the road
assert(all(abs(handles.Marks.Vertices(:,3) - 0.02) < 1e-12));
% On curves, a wider spacing gives fewer faces
curvyRoad = fcn_AnimateCar3D_fillRoad(Preset='curvy', FigNum=-1);
fine = fcn_AnimateCar3D_plotRoad(curvyRoad, FigNum=figNum);
coarse = fcn_AnimateCar3D_plotRoad(curvyRoad, SampleSpacing=10, FigNum=figNum);
assert(coarse.NumFaces < fine.NumFaces);

%% TEST case: An interstate: the barrier on the median, double width of lanes
figNum = 20002;
titleString = sprintf('TEST case: An interstate: the barrier on the median');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

interstate = fcn_AnimateCar3D_fillRoad(Preset='interstate', Length=200, FigNum=-1);
handles = fcn_AnimateCar3D_plotRoad(interstate, FigNum=figNum);
barrierVertices = handles.Objects.Vertices;
assert(max(abs(barrierVertices(:,2))) <= 0.3 + 1e-9 && abs(max(barrierVertices(:,3)) - 0.81) < 1e-9);
assert(abs(max(abs(handles.Surface.Vertices(:,2))) - 23.2) < 1e-9);   % (median 0.6, shoulder 1.2, 4 lanes, shoulder 3, border 4)

%% TEST case: Intersections: arms, junction, stop lines, arrows; both lane layouts
figNum = 20004;
titleString = sprintf('TEST case: Intersections: arms, junction, stop lines, arrows; both lane layouts');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

network = fcn_AnimateCar3D_fillRoad(Preset='intersection', FigNum=-1);
handles = fcn_AnimateCar3D_plotRoad(network, FigNum=figNum);
surfaceXY = handles.Surface.Vertices(:,1:2);
assert(max(surfaceXY(:,1)) > 80 && min(surfaceXY(:,1)) < -80 && max(surfaceXY(:,2)) > 80 && min(surfaceXY(:,2)) < -80);
% (the junction square: a face with corners at +/-7.2 m)
assert(any(all(abs(abs(surfaceXY) - 7.2) < 1e-9, 2)));
% White marks include the stop lines and arrows near the junction
whiteFaces = all(abs(handles.Objects.FaceVertexCData - [0.96 0.96 0.94]) < 1e-9, 2);
assert(sum(whiteFaces) > 4*(1 + 2*3));
networkB = fcn_AnimateCar3D_fillRoad(Preset='intersection', RightTurnLane=true, FigNum=-1);
handlesB = fcn_AnimateCar3D_plotRoad(networkB, FigNum=figNum);
assert(handlesB.NumFaces > handles.NumFaces);
% The raised corner sidewalks reach the curb height
assert(abs(max(handlesB.Surface.Vertices(:,3)) - 0.15) < 1e-9);

%% TEST case: Pedestrians stand on the sidewalk, at sidewalk height
figNum = 20005;
titleString = sprintf('TEST case: Pedestrians stand on the sidewalk, at sidewalk height');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

urbanRoad = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet', BuildingSides='none', FigNum=-1);
urbanRoad.Objects = urbanRoad.Objects(strcmp({urbanRoad.Objects.Type},'pedestrian'));
handles = fcn_AnimateCar3D_plotRoad(urbanRoad, FigNum=figNum);
assert(abs(min(handles.Objects.Vertices(:,3)) - 0.15) < 1e-9 && max(handles.Objects.Vertices(:,3)) < 0.15 + 1.86);

%% TEST case: A curvy road: marks follow the curves; colors and objects can be changed
figNum = 20003;
titleString = sprintf('TEST case: A curvy road: marks follow the curves; colors can be changed');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

curvyRoad = fcn_AnimateCar3D_fillRoad(Preset='curvy', FigNum=-1);
handles = fcn_AnimateCar3D_plotRoad(curvyRoad, Colors=struct('driving',[0.2 0.2 0.25]), FigNum=figNum);
assert(any(all(abs(handles.Surface.FaceVertexCData - [0.2 0.2 0.25]) < 1e-12, 2)));
% Every edge-line vertex is 3.6 m (+/- half a line) from the reference line
edgeColor = all(abs(handles.Marks.FaceVertexCData - [0.96 0.96 0.94]) < 1e-9, 2);
edgeVertices = unique(handles.Marks.Faces(edgeColor,:));
referencePoints = fcn_AnimateCar3D_getRoadPoints(curvyRoad, (0:0.25:curvyRoad.Length)', FigNum=-1);
edgeXY = handles.Marks.Vertices(edgeVertices,1:2);
distances = min(hypot(edgeXY(:,1) - referencePoints(:,1)', edgeXY(:,2) - referencePoints(:,2)'), [], 2);
assert(all(distances > 3.6 - 0.08 - 0.02 & distances < 3.6 + 0.08 + 0.02));
urbanRoad = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet', FigNum=-1);
handles = fcn_AnimateCar3D_plotRoad(urbanRoad, ShowObjects=false, FigNum=figNum);
assert(isempty(handles.Objects));
% See-through: near-side buildings and trees at 0.3 by default (the
% far-side trees stay solid); all buildings at 0.5
handles = fcn_AnimateCar3D_plotRoad(urbanRoad, FigNum=figNum);
assert(isscalar(handles.SeeThrough) && handles.SeeThrough.FaceAlpha==0.3 && all(handles.SeeThrough.Vertices(:,2) < 0));
trunkColor = all(abs(handles.SeeThrough.FaceVertexCData - [0.40 0.28 0.18]) < 1e-9, 2);
solidTrunks = all(abs(handles.Objects.FaceVertexCData - [0.40 0.28 0.18]) < 1e-9, 2);
solidTrunkVertices = handles.Objects.Faces(solidTrunks,:);
solidTrunkVertices = solidTrunkVertices(~isnan(solidTrunkVertices));
assert(any(trunkColor) && all(handles.Objects.Vertices(solidTrunkVertices(:),2) > 0));   % (solid trees only on the far side)
handles = fcn_AnimateCar3D_plotRoad(urbanRoad, BuildingAlpha=0.5, FigNum=figNum);
assert(numel(handles.SeeThrough)==2 && isequal(sort([handles.SeeThrough.FaceAlpha]), [0.3 0.5]) && max(handles.Objects.Vertices(:,3)) < 5);
handles = fcn_AnimateCar3D_plotRoad(urbanRoad, NearSideAlpha=1, FigNum=figNum);
assert(isempty(handles.SeeThrough));

%% Fast Mode Tests

%% Basic example - NO FIGURE NUMBER (the current axes)
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum);
handles = fcn_AnimateCar3D_plotRoad(twoLaneRoad, FigNum=[]);
assert(isequal(handles.Axes.Parent.Number, figNum));
close(figNum);

%% Basic fast mode - FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum);
handles = fcn_AnimateCar3D_plotRoad(twoLaneRoad, FigNum=-1);
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

%% FAIL case: A color name that does not exist
if 1==0
    fcn_AnimateCar3D_plotRoad(twoLaneRoad, Colors=struct('asphalt',[0 0 0]));
end

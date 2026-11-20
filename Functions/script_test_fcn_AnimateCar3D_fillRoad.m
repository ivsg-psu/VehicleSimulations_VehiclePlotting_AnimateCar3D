% script_test_fcn_AnimateCar3D_fillRoad.m
% Tests fcn_AnimateCar3D_fillRoad
% Fills a road description, laid out as an ASAM OpenDRIVE road, from a preset.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillRoad
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillRoad
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

%% DEMO case: The four presets
figNum = 10001;
titleString = sprintf('DEMO case: The four presets');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

road = fcn_AnimateCar3D_fillRoad(Preset='curvy', FigNum=figNum);

% Check variable types
assert(isstruct(road) && isstruct(road.PlanView) && isstruct(road.LaneSections));

% Check variable sizes
assert(numel(road.PlanView)==9 && numel(road.LaneSections)==1);

% Check variable values: one lane each way, a broken yellow center line,
% the right lanes mirrored on the left
section = road.LaneSections;
assert(isequal([section.Right.ID], [-1 -2 -3]) && isequal([section.Left.ID], [1 2 3]));
assert(strcmp(section.Center.RoadMark.Type,'broken') && strcmp(section.Center.RoadMark.Color,'yellow'));
assert(abs(road.Length - 410) < 1e-9);

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

%% TEST case: The interstate: lanes, marks, and the median barrier
figNum = 20001;
titleString = sprintf('TEST case: The interstate: lanes, marks, and the median barrier');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

road = fcn_AnimateCar3D_fillRoad(Preset='interstate');
rightLanes = road.LaneSections.Right;
assert(isequal({rightLanes.Type}, {'median','shoulder','driving','driving','driving','driving','shoulder','border'}));
assert(isequal(arrayfun(@(lane) lane.RoadMark.Type, rightLanes', 'UniformOutput', false), ...
    {'none','solid','broken','broken','broken','solid','none','none'}));
assert(strcmp(rightLanes(2).RoadMark.Color,'yellow'));
assert(numel(road.Objects)==1 && strcmp(road.Objects.Type,'barrier') && road.Objects.Length==road.Length);
road = fcn_AnimateCar3D_fillRoad(Preset='interstate', LanesEachWay=2, Length=150);
assert(sum(strcmp({road.LaneSections.Right.Type}, 'driving'))==2 && road.Length==150);

%% TEST case: The urban street: curbs, sidewalks, and repeatable objects
figNum = 20002;
titleString = sprintf('TEST case: The urban street: curbs, sidewalks, and repeatable objects');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

road = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet');
rightLanes = road.LaneSections.Right;
assert(isequal({rightLanes.Type}, {'driving','curb','walking','border'}) && rightLanes(2).Height(1)==0.15);
objectTypes = {road.Objects.Type};
assert(sum(strcmp(objectTypes,'crosswalk'))==1 && sum(strcmp(objectTypes,'tree')) > 10 && sum(strcmp(objectTypes,'building')) >= 5);
again = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet');
assert(isequaln(road.Objects, again.Objects));                       % (the same seed, the same buildings)
other = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet', Seed=2);
assert(~isequaln(road.Objects, other.Objects));
% Setback: the nearest building face is BuildingSetback behind the
% sidewalk (3.6 + 0.15 + 2.5 m from the center)
buildings = road.Objects(strcmp({road.Objects.Type},'building'));
assert(abs(min(abs([buildings.T]) - [buildings.Width]/2) - (3.6 + 0.15 + 2.5 + 6)) < 1e-9);
farther = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet', BuildingSetback=12);
buildings = farther.Objects(strcmp({farther.Objects.Type},'building'));
assert(abs(min(abs([buildings.T]) - [buildings.Width]/2) - (3.6 + 0.15 + 2.5 + 12)) < 1e-9);
% Sides: both by default; near-side (right) buildings low: mostly one
% story, a few two; 'left' keeps only the left side's buildings (the same)
allBuildings = road.Objects(strcmp({road.Objects.Type},'building'));
nearHeights = [allBuildings([allBuildings.T] < 0).Height];
assert(any([allBuildings.T] < 0) && any([allBuildings.T] > 0));
assert(all(nearHeights <= 7.5) && mean(nearHeights <= 4.5) > 0.6 && max([allBuildings([allBuildings.T] > 0).Height]) > 10);
leftOnly = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet', BuildingSides='left');
leftBuildings = leftOnly.Objects(strcmp({leftOnly.Objects.Type},'building'));
assert(all([leftBuildings.T] > 0) && isequaln(rmfield(leftBuildings,'ID'), rmfield(allBuildings([allBuildings.T] > 0),'ID')));
noBuildings = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet', BuildingSides='none');
assert(~any(strcmp({noBuildings.Objects.Type},'building')));

%% TEST case: The neighborhood: crosswalks every block, houses, parks
figNum = 20004;
titleString = sprintf('TEST case: The neighborhood: crosswalks every block, houses, parks');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

road = fcn_AnimateCar3D_fillRoad(Preset='neighborhood', BuildingSides='both');
assert(road.Length==1200 && strcmp(road.LaneSections.Center.RoadMark.Type,'none'));
crosswalks = road.Objects(strcmp({road.Objects.Type},'crosswalk'));
assert(isequal([crosswalks.S], [400 800]));
houses = road.Objects(strcmp({road.Objects.Type},'building'));
assert(numel(houses) > 60 && all([houses.Height] <= 8) && all(strcmp({houses.Name},'house')));
% (parks: some stretches without houses, but with trees off the street)
trees = road.Objects(strcmp({road.Objects.Type},'tree'));
assert(any(abs([trees.T]) > 3.6 + 0.15 + 3 + 6));
road = fcn_AnimateCar3D_fillRoad(Preset='neighborhood', BlockLength=200, Length=1000);
crosswalks = road.Objects(strcmp({road.Objects.Type},'crosswalk'));
assert(isequal([crosswalks.S], [200 400 600 800]));
houses = road.Objects(strcmp({road.Objects.Type},'building'));
assert(all([houses.T] > 0));                                           % (the default: left side only)

%% TEST case: Pedestrians stand on the sidewalks of the urban street and neighborhood
figNum = 20005;
titleString = sprintf('TEST case: Pedestrians stand on the sidewalks of the urban street and neighborhood');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

for presetName = {'urbanStreet','neighborhood'}
    road = fcn_AnimateCar3D_fillRoad(Preset=presetName{1});
    people = road.Objects(strcmp({road.Objects.Type},'pedestrian'));
    sidewalks = road.LaneSections.Right(strcmp({road.LaneSections.Right.Type},'walking'));
    [~, innerT] = fcn_AnimateCar3D_getRoadPoints(road, [people.S]', LaneID=sidewalks.ID, LaneEdge='inner');
    [~, outerT] = fcn_AnimateCar3D_getRoadPoints(road, [people.S]', LaneID=sidewalks.ID, LaneEdge='outer');
    assert(numel(people) >= 4 && any([people.T] > 0) && any([people.T] < 0));
    assert(all(abs([people.T]') >= abs(innerT) & abs([people.T]') <= abs(outerT)));    % (on the sidewalk)
end
% (pedestrians do not change the buildings)
assert(isequaln(road.Objects(strcmp({road.Objects.Type},'building')), ...
    fcn_INTERNAL_buildingsOnly(fcn_AnimateCar3D_fillRoad(Preset='neighborhood'))));

%% TEST case: The intersection: four arms, a junction, two lane layouts
figNum = 20006;
titleString = sprintf('TEST case: The intersection: four arms, a junction, two lane layouts');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

network = fcn_AnimateCar3D_fillRoad(Preset='intersection', FigNum=figNum);
assert(numel(network.Roads)==4 && isscalar(network.Junctions));
arm = network.Roads(1);
assert(sum(strcmp({arm.LaneSections.Left.Type},'driving'))==2 && sum(strcmp({arm.LaneSections.Right.Type},'driving'))==2);
assert(isequal(sort({arm.Objects(strcmp({arm.Objects.Type},'arrow')).Name}), {'left','straightRight'}));
% Each arm starts at the junction's edge (7.2 m out), pointing away
for ith_arm = 1:4
    startPoint = fcn_AnimateCar3D_getRoadPoints(network.Roads(ith_arm), 0);
    heading = (ith_arm-1)*pi/2;
    assert(max(abs(startPoint - [7.2*cos(heading) 7.2*sin(heading) heading])) < 1e-9);
end
assert(numel(network.Junctions.Surfaces)==1);                    % (a square; the corners need no filling)
network = fcn_AnimateCar3D_fillRoad(Preset='intersection', RightTurnLane=true);
arm = network.Roads(1);
assert(sum(strcmp({arm.LaneSections.Left.Type},'driving'))==3);
assert(isequal(sort({arm.Objects(strcmp({arm.Objects.Type},'arrow')).Name}), {'left','right','straight'}));
assert(numel(network.Junctions.Surfaces)==1 + 4*2 && numel(network.Junctions.CurbFaces)==4);
% The through lane coming in lines up with the far arm's first lane going out
[~, tIn] = fcn_AnimateCar3D_getRoadPoints(network.Roads(1), 10, LaneID=2);
[~, tOut] = fcn_AnimateCar3D_getRoadPoints(network.Roads(3), 10, LaneID=-2);
assert(abs(tIn + tOut) < 1e-9 && abs(tIn - 5.4) < 1e-9);

%% TEST case: Seed: the same Seed gives the same scene, whatever MATLAB's rng
figNum = 20007;
titleString = sprintf('TEST case: Seed: the same Seed gives the same scene, whatever MATLAB''s rng');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

for presetName = {'urbanStreet','neighborhood','intersection'}
    rng(1);
    first = fcn_AnimateCar3D_fillRoad(Preset=presetName{1}, Seed=7);
    rng(99);
    randomBefore = rand;
    rng(99);
    second = fcn_AnimateCar3D_fillRoad(Preset=presetName{1}, Seed=7);
    assert(isequaln(first, second) && rand==randomBefore);           % (repeatable; rng untouched)
    other = fcn_AnimateCar3D_fillRoad(Preset=presetName{1}, Seed=8);
    assert(~isequaln(first, other));
end

%% TEST case: Options: center mark, lane width, start pose
figNum = 20003;
titleString = sprintf('TEST case: Options: center mark, lane width, start pose');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

road = fcn_AnimateCar3D_fillRoad(CenterMark='solid solid', LaneWidth=3.3, Start=[100 50 pi/2]);
assert(strcmp(road.LaneSections.Center.RoadMark.Type,'solid solid') && road.LaneSections.Right(1).Width(1)==3.3);
endPoint = fcn_AnimateCar3D_getRoadPoints(road, road.Length);
assert(max(abs(endPoint - [100 350 pi/2])) < 1e-9);

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
road = fcn_AnimateCar3D_fillRoad(Preset='twoLane', FigNum=[]);
assert(road.Length==300);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
road = fcn_AnimateCar3D_fillRoad(Preset='twoLane', FigNum=-1);
assert(road.Length==300);

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

%% FAIL case: A preset that does not exist
if 1==0
    fcn_AnimateCar3D_fillRoad(Preset='racetrack');
end

%% FAIL case: A seed that is not a whole number
if 1==0
    fcn_AnimateCar3D_fillRoad(Preset='urbanStreet', Seed=1.5);
end

%% FAIL case: A center mark that does not exist
if 1==0
    fcn_AnimateCar3D_fillRoad(CenterMark='dotted');
end

%% Functions follow
%% fcn_INTERNAL_buildingsOnly
function buildings = fcn_INTERNAL_buildingsOnly(road)
% A road's buildings
buildings = road.Objects(strcmp({road.Objects.Type},'building'));
end % Ends fcn_INTERNAL_buildingsOnly

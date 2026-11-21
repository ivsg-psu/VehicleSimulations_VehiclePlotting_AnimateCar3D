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

%% TEST case: Junction connections: turning paths meet the lanes, headings match
figNum = 20008;
titleString = sprintf('TEST case: Junction connections: turning paths meet the lanes, headings match');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

for flagRightTurn = [false true]
    network = fcn_AnimateCar3D_fillRoad(Preset='intersection', RightTurnLane=flagRightTurn);
    connections = network.Junctions.Connections;
    assert(numel(connections)==4*3 && sum(strcmp({connections.Turn},'left'))==4 && sum(strcmp({connections.Turn},'right'))==4);
    for ith_connection = 1:numel(connections)
        thisConnection = connections(ith_connection);
        pathEnds = fcn_AnimateCar3D_getRoadPoints(thisConnection.Path, [0; thisConnection.Path.Length]);
        inRoad = network.Roads(strcmp({network.Roads.ID}, thisConnection.IncomingRoad));
        outRoad = network.Roads(strcmp({network.Roads.ID}, thisConnection.OutgoingRoad));
        laneIn = fcn_AnimateCar3D_getRoadPoints(inRoad, 0, LaneID=thisConnection.IncomingLane);
        laneOut = fcn_AnimateCar3D_getRoadPoints(outRoad, 0, LaneID=thisConnection.OutgoingLane);
        assert(norm(pathEnds(1,1:2) - laneIn(1:2)) < 1e-3 && norm(pathEnds(2,1:2) - laneOut(1:2)) < 1e-3);
        headingError = @(a, b) abs(atan2(sin(a - b), cos(a - b)));
        assert(headingError(pathEnds(1,3), laneIn(3) + pi) < 1e-6 && headingError(pathEnds(2,3), laneOut(3)) < 1e-6);
    end
end
assert(strcmp(network.EgoStart.Road,'3') && network.EgoStart.LaneID==2 && network.EgoStart.Direction==-1);
road = fcn_AnimateCar3D_fillRoad(Preset='interstate');
assert(road.EgoStart.LaneID==-3 && road.EgoStart.S==0);
[~, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset='twoLane');
assert(iscell(centerlineOptions) && numel(centerlineOptions)==2);

%% TEST case: The urban grid: cross streets, a junction at each, connections that meet the lanes
figNum = 20030;
titleString = sprintf('TEST case: The urban grid: cross streets, a junction at each, connections that meet the lanes');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

network = fcn_AnimateCar3D_fillRoad(Preset='urbanGrid', FigNum=figNum);
assert(numel(network.Junctions)==3 && numel(network.Roads)==4 + 2*3);
assert(abs(network.Roads(2).Length - (100 - 4*3.6)) < 1e-9);
assert(strcmp(network.Roads(2).Predecessor.ElementID,'1') && strcmp(network.Roads(2).Successor.ElementID,'2'));
assert(isempty(network.Roads(1).Predecessor.ElementID) && strcmp(network.Roads(1).Successor.ElementID,'1'));
% (the lane line before each junction is solid; broken mid-block)
link = network.Roads(2);
assert(strcmp(link.LaneSections(1).Left(1).RoadMark.Type,'solid') && strcmp(link.LaneSections(2).Left(1).RoadMark.Type,'broken') ...
    && strcmp(link.LaneSections(end).Right(1).RoadMark.Type,'solid'));
headingError = @(a, b) abs(atan2(sin(a - b), cos(a - b)));
for ith_junction = 1:3
    connections = network.Junctions(ith_junction).Connections;
    assert(numel(connections)==4*3 && sum(strcmp({connections.Turn},'left'))==4 && sum(strcmp({connections.Turn},'straight'))==4);
    for ith_connection = 1:numel(connections)
        thisConnection = connections(ith_connection);
        pathEnds = fcn_AnimateCar3D_getRoadPoints(thisConnection.Path, [0; thisConnection.Path.Length]);
        inRoad = network.Roads(strcmp({network.Roads.ID}, thisConnection.IncomingRoad));
        outRoad = network.Roads(strcmp({network.Roads.ID}, thisConnection.OutgoingRoad));
        inS = inRoad.Length*(thisConnection.IncomingLane < 0);       % (coming in: left lanes at s = 0, right lanes at the end)
        outS = outRoad.Length*(thisConnection.OutgoingLane > 0);
        laneIn = fcn_AnimateCar3D_getRoadPoints(inRoad, inS, LaneID=thisConnection.IncomingLane);
        laneOut = fcn_AnimateCar3D_getRoadPoints(outRoad, outS, LaneID=thisConnection.OutgoingLane);
        assert(norm(pathEnds(1,1:2) - laneIn(1:2)) < 1e-3 && norm(pathEnds(2,1:2) - laneOut(1:2)) < 1e-3);
        assert(headingError(pathEnds(1,3), laneIn(3) + pi*(thisConnection.IncomingLane > 0)) < 1e-6);
        assert(headingError(pathEnds(2,3), laneOut(3) + pi*(thisConnection.OutgoingLane > 0)) < 1e-6);
    end
end
% (buildings: behind the sidewalks; tall to the north, low to the south)
mainObjects = [network.Roads(1:4).Objects];
buildings = mainObjects(strcmp({mainObjects.Type},'building'));
assert(all(abs([buildings.T]) > 2*3.6 + 0.15 + 2.5) && min([buildings([buildings.T] > 0).Height]) >= 6 && max([buildings([buildings.T] < 0).Height]) <= 7.5);
% (no building reaches into a cross street: each lies outside every
% cross street's band, out to its grass)
crossBand = 2*3.6 + 0.15 + 2.5 + 1.5;
for ith_road = 1:4
    thisRoad = network.Roads(ith_road);
    roadBuildings = thisRoad.Objects(strcmp({thisRoad.Objects.Type},'building'));
    for thisBuilding = roadBuildings
        buildingCenter = fcn_AnimateCar3D_getRoadPoints(thisRoad, thisBuilding.S, T=thisBuilding.T);
        for ith_junction = 1:3
            alongDistance = abs(buildingCenter(1) - network.Junctions(ith_junction).Center(1));
            assert(alongDistance - thisBuilding.Length/2 > crossBand - 1e-9);
        end
    end
end
assert(strcmp(network.EgoStart.Road,'1') && network.EgoStart.LaneID==-2 && network.EgoStart.Direction==1);
network = fcn_AnimateCar3D_fillRoad(Preset='urbanGrid', CrossStreets=1, BlockLength=60);
assert(numel(network.Junctions)==1 && numel(network.Roads)==4);

%% TEST case: Heights: hilly (grade within limits) and banked (down to the inside of curves)
figNum = 20009;
titleString = sprintf('TEST case: Heights: hilly (grade within limits) and banked (down to the inside of curves)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

flatRoad = fcn_AnimateCar3D_fillRoad(Preset='curvy');
[~, ~, flatZ] = fcn_AnimateCar3D_getRoadPoints(flatRoad, (0:1:flatRoad.Length)', T=3);
assert(all(flatZ==0));
hillyRoad = fcn_AnimateCar3D_fillRoad(Preset='curvy', Elevation='hilly', CurveGradeRadius=0);   % (no curve knots: random spacing only)
sFine = (0:0.5:hillyRoad.Length)';
[~, ~, hillZ, hillAngles] = fcn_AnimateCar3D_getRoadPoints(hillyRoad, sFine);
assert(max(abs(tan(hillAngles(:,1)))) <= 0.06 + 1e-9 && max(hillZ) - min(hillZ) > 1);
gradeChange = diff(tan(hillAngles(:,1)))./diff(sFine)*100;
assert(max(abs(gradeChange)) <= 0.35 + 1e-6);                            % (grade change per 100 m)
% (knots spaced randomly: the grade's corners are not all 50 m apart)
knotSpacing = diff([hillyRoad.ElevationProfile.S]);
assert(numel(unique(round(knotSpacing))) > 2 && all(knotSpacing >= 20 - 1e-9) && all(knotSpacing <= 120));
gentle = fcn_AnimateCar3D_fillRoad(Preset='curvy', Elevation='hilly', MaxGradeChange=0.02);
[~, ~, ~, gentleAngles] = fcn_AnimateCar3D_getRoadPoints(gentle, sFine);
assert(max(abs(diff(tan(gentleAngles(:,1)))./diff(sFine)*100)) <= 0.02 + 1e-6);
lastwarn('');
evalc('fcn_AnimateCar3D_fillRoad(Preset=''curvy'', Elevation=''hilly'', MaxGradeChange=0.8);');   % (the warning, not shown)
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'AnimateCar3D:fillRoad:steepGradeChange'));
assert(abs(hillZ(1)) < 1e-12 && abs(hillAngles(1,1)) < 1e-12);           % (starts at 0, level)
mountain = fcn_AnimateCar3D_fillRoad(Preset='curvy', Elevation='mountain');
[~, ~, mountainZ, mountainAngles] = fcn_AnimateCar3D_getRoadPoints(mountain, sFine);
[~, peak] = max(mountainZ);
assert(abs(sFine(peak) - mountain.Length/2) < 60 && max(mountainZ) > 5 && max(abs(tan(mountainAngles(:,1)))) <= 0.06 + 1e-9);
capped = fcn_AnimateCar3D_fillRoad(Preset='curvy', Elevation='hilly', MaxHeightRange=1);
[~, ~, cappedZ] = fcn_AnimateCar3D_getRoadPoints(capped, sFine);
assert(max(cappedZ) - min(cappedZ) <= 1 + 1e-6);
gentle = fcn_AnimateCar3D_fillRoad(Preset='curvy', Elevation='hilly', MaxGrade=0.02);
[~, ~, ~, gentleAngles] = fcn_AnimateCar3D_getRoadPoints(gentle, sFine);
assert(max(abs(tan(gentleAngles(:,1)))) <= 0.02 + 1e-9);
bankedRoad = fcn_AnimateCar3D_fillRoad(Preset='curvy', CrossSlope='banked');
% (60 m in: a left curve; 250 m in: a right curve; at 20 m: straight)
[~, ~, ~, bankAngles] = fcn_AnimateCar3D_getRoadPoints(bankedRoad, [20; 100; 230]);
assert(abs(bankAngles(1,2)) < 1e-12 && bankAngles(2,2) < 0 && bankAngles(3,2) > 0);
assert(abs(tan(bankAngles(3,2)) - 0.06) < 1e-9);                         % (the tightest curve: 50 m radius)
[~, ~, insideZ] = fcn_AnimateCar3D_getRoadPoints(bankedRoad, [100; 100], T=[3; -3]);
assert(insideZ(1) < insideZ(2));                                         % (left curve: the left side lower)

%% TEST case: The race course: traced from a photo, closed, straights of two 12 ft lanes
figNum = 20011;
titleString = sprintf('TEST case: The race course: traced from a photo, closed, straights of two 12 ft lanes');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[raceRoad, raceOptions] = fcn_AnimateCar3D_fillRoad(Preset='raceCourse', FigNum=figNum);
assert(strcmp(raceRoad.Name,'raceCourse') && raceRoad.Loop && abs(raceRoad.Length - 452.4) < 1);
% (closed: the end meets the start, in place and heading)
[ends] = fcn_AnimateCar3D_getRoadPoints(raceRoad, [0; raceRoad.Length - 1e-9]);
assert(norm(ends(1,1:2) - ends(2,1:2)) < 0.01 && abs(angdiff(ends(1,3), ends(2,3))) < 1e-3);
% (the start: heading west on the bottom straight, two 12 ft lanes)
assert(abs(ends(1,3) - pi) < 1e-6);
section = raceRoad.LaneSections(1);
assert(abs(section.Right(1).Width(1) - 12*0.3048) < 1e-3 && abs(section.Left(1).Width(1) - 12*0.3048) < 1e-3);
% (the top straight: a broken center line)
topSections = arrayfun(@(sec) strcmp(sec.Center.RoadMark.Type, 'broken'), raceRoad.LaneSections);
assert(sum(topSections) >= 10);
% (banked curbs somewhere, the pit lane beside the start, walls, stripes, a start line)
curbHeights = arrayfun(@(sec) max([sec.Right(3).Height(2), sec.Left(3).Height(2)]), raceRoad.LaneSections);
assert(sum(curbHeights > 0.05) > 15 && max(curbHeights) < 0.2);
assert(numel(section.Left)==4 && abs(section.Left(4).Width(1) - 12*0.3048) < 1e-3);
types = {raceRoad.Objects.Type};
assert(sum(strcmp(types,'wall'))==10 && sum(strcmp(types,'stripe'))==3 && all([raceRoad.Objects(strcmp(types,'wall')).Height]==1.35));
% (paths: one lap along the track's center and each half)
assert(numel(raceOptions)==3 && strcmp(raceOptions{1}.Name,'track center') && abs(raceOptions{1}.S(end) - raceRoad.Length) < 1);

%% TEST case: The race course variants: hilly, banked, and both
figNum = 20012;
titleString = sprintf('TEST case: The race course variants: hilly, banked, and both');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

hillyRace = fcn_AnimateCar3D_fillRoad(Preset='raceCourse', Elevation='hilly', FigNum=-1);
sLap = (0:0.5:hillyRace.Length - 0.5)';
[lapPoints, ~, lapZ, lapAngles] = fcn_AnimateCar3D_getRoadPoints(hillyRace, sLap);
assert(max(lapZ) - min(lapZ) > 2 && max(lapZ) - min(lapZ) <= 4 + 1e-6);           % (about 4 m)
assert(max(abs(tan(lapAngles(:,1)))) <= 0.06 + 0.01);                             % (grades up to 6%)
[~, ~, closeZ] = fcn_AnimateCar3D_getRoadPoints(hillyRace, [0; hillyRace.Length - 1e-6]);
assert(abs(diff(closeZ)) < 0.01);                                                  % (the loop's heights close)
onStraights = abs(lapPoints(:,2)) < 1e-6 | abs(lapPoints(:,2) - max(lapPoints(:,2))) < 1e-6;
assert(max(abs(lapAngles(onStraights,1))) < 2e-3);                                 % (the straights level)
bankedRace = fcn_AnimateCar3D_fillRoad(Preset='raceCourse', CrossSlope='banked', FigNum=-1);
[~, ~, ~, bankAngles] = fcn_AnimateCar3D_getRoadPoints(bankedRace, sLap);
assert(max(abs(bankAngles(:,2))) > 0.05 && max(abs(bankAngles(:,2))) <= atan(0.06) + 1e-9);
% (down to the inside: mostly opposite in sign to the curvature; one curve the other way)
curvatures = zeros(numel(bankedRace.PlanView),1);
for ith_geometry = 1:numel(bankedRace.PlanView)
    if strcmp(bankedRace.PlanView(ith_geometry).Type, 'arc')
        curvatures(ith_geometry) = bankedRace.PlanView(ith_geometry).Curvature;
    end
end
geometryRoll = [bankedRace.LateralProfile.Superelevation.A]';
flagCurved = abs(curvatures) > 1/30 & abs(geometryRoll) > 0.03;
agree = sign(geometryRoll(flagCurved))==-sign(curvatures(flagCurved));
assert(mean(agree) > 0.8 && any(~agree));
bothRace = fcn_AnimateCar3D_fillRoad(Preset='raceCourse', Elevation='hilly', CrossSlope='banked', FigNum=-1);
assert(numel(bothRace.ElevationProfile) > 100 && numel(bothRace.LateralProfile.Superelevation) > 100);

%% TEST case: The mountain road: long, winding, climbing and descending, clear of itself
figNum = 20010;
titleString = sprintf('TEST case: The mountain road: long, winding, climbing and descending, clear of itself');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

mountainRoad = fcn_AnimateCar3D_fillRoad(Preset='mountain');
assert(mountainRoad.Length >= 2000 && mountainRoad.Length < 2400);
sAlong = (0:5:mountainRoad.Length)';
[points, ~, heights, angles] = fcn_AnimateCar3D_getRoadPoints(mountainRoad, sAlong);
assert(max(heights) > 60 && max(abs(tan(angles(:,1)))) <= 0.12 + 1e-9 && max(abs(tan(angles(:,1)))) > 0.09 && any(abs(angles(:,2)) > 0.02));   % (climbs at up to 12%; banked)
assert(strcmp(mountainRoad.TerrainShape, 'mountain'));
% (uphill all the way to the summit, downhill all the way after)
sClimb = (100:5:mountainRoad.Length/2 - 100)';
sDescend = (mountainRoad.Length/2 + 100:5:mountainRoad.Length - 100)';
[~, ~, ~, climbAngles] = fcn_AnimateCar3D_getRoadPoints(mountainRoad, sClimb);
[~, ~, ~, descendAngles] = fcn_AnimateCar3D_getRoadPoints(mountainRoad, sDescend);
assert(all(climbAngles(:,1) > 0) && all(descendAngles(:,1) < 0));
% (the grade eases on tight curves: on each arc, at most 12% * R/150, and
% at least 20% of 12%)
for ith_geometry = 1:numel(mountainRoad.PlanView)
    geometry = mountainRoad.PlanView(ith_geometry);
    if strcmp(geometry.Type, 'arc') && abs(geometry.Curvature) > 1/150
        sArc = linspace(geometry.S, geometry.S + geometry.Length, 20)';
        [~, ~, ~, arcAngles] = fcn_AnimateCar3D_getRoadPoints(mountainRoad, sArc);
        arcLimit = 0.12*max(0.2, 1/(abs(geometry.Curvature)*150));
        assert(max(abs(tan(arcAngles(:,1)))) <= arcLimit + 1e-6);
    end
end
% (and without easing, the hairpins are as steep as the rest)
unEased = fcn_AnimateCar3D_fillRoad(Preset='mountain', CurveGradeRadius=0);
hairpin = find(arrayfun(@(g) strcmp(g.Type,'arc') && abs(g.Curvature) > 1/30, unEased.PlanView), 1);
sArc = linspace(unEased.PlanView(hairpin).S, unEased.PlanView(hairpin).S + unEased.PlanView(hairpin).Length, 20)';
[~, ~, ~, arcAngles] = fcn_AnimateCar3D_getRoadPoints(unEased, sArc);
assert(max(abs(tan(arcAngles(:,1)))) > 0.04);
farApart = abs(sAlong - sAlong') > 150;
distances = hypot(points(:,1) - points(:,1)', points(:,2) - points(:,2)');
assert(min(distances(farApart)) > 25);
assert(sum(strcmp({mountainRoad.PlanView.Type}, 'arc')) > 10 && strcmp(mountainRoad.LaneSections.Center.RoadMark.Type, 'solid solid'));
flatMountain = fcn_AnimateCar3D_fillRoad(Preset='mountain', Elevation='flat', CrossSlope='none', Length=500, Seed=3);
[~, ~, flatHeights] = fcn_AnimateCar3D_getRoadPoints(flatMountain, (0:5:flatMountain.Length)');
assert(all(flatHeights==0));

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

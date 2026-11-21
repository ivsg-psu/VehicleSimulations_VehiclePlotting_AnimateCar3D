% script_test_fcn_AnimateCar3D_getTireContacts.m
% Tests fcn_AnimateCar3D_getTireContacts
% Finds the road surface under a vehicle and under each of its tires.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_getTireContacts
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_getTireContacts
%   % * (fill in items here)


%% Set up the workspace
close all

twoLane = fcn_AnimateCar3D_fillRoad(Preset='twoLane', FigNum=-1);

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

%% DEMO case: A vehicle over hills and banked curves: the road under each tire
figNum = 10001;
titleString = sprintf('DEMO case: A vehicle over hills and banked curves: the road under each tire');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

hills = fcn_AnimateCar3D_fillExampleScenario('curvyHills', FigNum=-1);
contacts = fcn_AnimateCar3D_getTireContacts(hills.Road, hills.Motions{1}.Pose, FigNum=figNum);

% Check variable types
assert(isstruct(contacts) && isequal(contacts.TireNames, {'FL','RL','RR','FR'}));

% Check variable sizes
N = size(hills.Motions{1}.Pose, 1);
assert(isequal(size(contacts.TireZ), [N 4]) && isequal(size(contacts.TireXY), [N 4 2]) && isequal(size(contacts.TireNormal), [N 4 3]));
assert(isequal(size(contacts.Pose), [N 6]) && isequal(size(contacts.CenterNormal), [N 3]));

% Check variable values: unit normals pointing up; heights that vary
normalLengths = sqrt(sum(contacts.TireNormal.^2, 3));
assert(all(abs(normalLengths(:) - 1) < 1e-9) && all(contacts.TireNormal(:,:,3) > 0.9, 'all'));
assert(max(contacts.TireZ(:)) - min(contacts.TireZ(:)) > 1);

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

%% TEST case: A flat road: zero heights, normals straight up, a level pose
figNum = 20001;
titleString = sprintf('TEST case: A flat road: zero heights, normals straight up, a level pose');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

flatPoses = [10 -1.8 0; 50 -1.8 0.1; 100 1.8 pi];
flat = fcn_AnimateCar3D_getTireContacts(twoLane, flatPoses);
assert(all(abs(flat.TireZ(:)) < 1e-12) && all(abs(flat.TireGrade(:)) < 1e-12) && all(abs(flat.TireCrossSlope(:)) < 1e-12));
assert(all(abs(flat.TireNormal(:,:,3) - 1) < 1e-12, 'all') && all(abs(flat.Pose(:,3:5)) < 1e-12, 'all'));
% (the tires: front at the wheelbase, each pair half a track to the side)
tireXY = squeeze(flat.TireXY(1,:,:));
assert(max(abs(tireXY - [10 + 2.8, -1.8 + 0.8; 10, -1.8 + 0.8; 10, -1.8 - 0.8; 10 + 2.8, -1.8 - 0.8]), [], 'all') < 1e-12);
assert(abs(flat.CenterXY(1,1) - 11.4) < 1e-12);

%% TEST case: Hills: heights match the road; grades along the heading; pitch from the grade
figNum = 20002;
titleString = sprintf('TEST case: Hills: heights match the road; grades along the heading; pitch from the grade');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

hilly = fcn_AnimateCar3D_fillRoad(Preset='twoLane', Elevation='hilly', Seed=2, FigNum=-1);
sAlong = (20:10:250)';
centerPoints = fcn_AnimateCar3D_getRoadPoints(hilly, sAlong, LaneID=-1);
hillPoses = [centerPoints(:,1:2), centerPoints(:,3)];
hill = fcn_AnimateCar3D_getTireContacts(hilly, hillPoses, LaneHeights=false);
roadZ = fcn_AnimateCar3D_getRoadHeight(hilly, reshape(hill.TireXY, [], 2));
assert(max(abs(roadZ - hill.TireZ(:))) < 1e-9);
% (the grade: the elevation's slope, as the road heads along +x)
[~, ~, aheadZ] = fcn_AnimateCar3D_getRoadPoints(hilly, sAlong + 1.4 + 0.01);
[~, ~, behindZ] = fcn_AnimateCar3D_getRoadPoints(hilly, sAlong + 1.4 - 0.01);
assert(max(abs(hill.CenterGrade - (aheadZ - behindZ)/0.02)) < 2e-3);
assert(max(abs(hill.Pose(:,5) + atan((mean(hill.TireZ(:,[1 4]),2) - mean(hill.TireZ(:,[2 3]),2))/2.8))) < 1e-9);   % (uphill: nose up, negative)
% (driving the other way, the grade turns over)
reversed = fcn_AnimateCar3D_getTireContacts(hilly, [hill.CenterXY + [1.4 0], pi*ones(numel(sAlong),1)], LaneHeights=false);
assert(max(abs(reversed.CenterGrade + hill.CenterGrade)) < 2e-3);

%% TEST case: Banking: cross slope from the superelevation; roll from the cross slope
figNum = 20003;
titleString = sprintf('TEST case: Banking: cross slope from the superelevation; roll from the cross slope');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[banked, bankedOptions] = fcn_AnimateCar3D_fillRoad(Preset='curvy', CrossSlope='banked', FigNum=-1);
path = bankedOptions{1};
rows = 1:10:numel(path.S);
bank = fcn_AnimateCar3D_getTireContacts(banked, [path.XY(rows,:) path.Heading(rows)], LaneHeights=false);
[~, sHere] = fcn_AnimateCar3D_getRoadHeight(banked, bank.CenterXY);
records = banked.LateralProfile.Superelevation;
recordIndex = discretize(sHere, [[records.S], Inf]);
ds = sHere - [records(recordIndex).S]';
superelevation = [records(recordIndex).A]' + [records(recordIndex).B]'.*ds + [records(recordIndex).C]'.*ds.^2 + [records(recordIndex).D]'.*ds.^3;
assert(max(abs(bank.CenterCrossSlope)) > 0.03);
assert(max(abs(bank.CenterCrossSlope - tan(superelevation))) < 0.005);           % (the bank, read across the heading)
assert(all(sign(bank.Pose(abs(bank.CenterCrossSlope) > 0.01, 4)) == sign(bank.CenterCrossSlope(abs(bank.CenterCrossSlope) > 0.01))));   % (left higher: roll positive)

%% TEST case: Lane heights: a tire up on the curb; the race course's banked curbs
figNum = 20004;
titleString = sprintf('TEST case: Lane heights: a tire up on the curb; the race course''s banked curbs');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

urban = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet', FigNum=-1);
% (the right tires on the sidewalk: the lane is 3.6 m, the curb 0.15 m)
onCurb = fcn_AnimateCar3D_getTireContacts(urban, [30 -3.6 0], TrackFront=1.6);
assert(all(abs(onCurb.TireZ(3:4) - 0.15) < 1e-9) && all(abs(onCurb.TireZ(1:2)) < 1e-9));   % (RR and FR up)
assert(abs(onCurb.Pose(4) + atan(0.15/1.6)) < 1e-9);                 % (the right side up: roll negative)
race = fcn_AnimateCar3D_fillRoad(Preset='raceCourse', FigNum=-1);
curbSections = find(arrayfun(@(section) numel(section.Right) >= 3 && section.Right(3).Width(1) > 0.8 && section.Right(3).Height(end) > 0.05, race.LaneSections));
curbSection = race.LaneSections(curbSections(1));
curbCenter = fcn_AnimateCar3D_getRoadPoints(race, curbSection.S + 1, LaneID=-3);
onRaceCurb = fcn_AnimateCar3D_getTireContacts(race, [curbCenter(1:2) - 1.4*[cos(curbCenter(3)) sin(curbCenter(3))], curbCenter(3)]);
assert(abs(onRaceCurb.CenterZ - curbSection.Right(3).Height(end)/2) < 0.2*curbSection.Right(3).Height(end));   % (halfway up the bank)
assert(onRaceCurb.CenterCrossSlope < -0.05);                         % (rising outward, to the right)

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
contacts = fcn_AnimateCar3D_getTireContacts(twoLane, [10 -1.8 0], FigNum=[]);
assert(isequal(size(contacts.TireZ), [1 4]));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
contacts = fcn_AnimateCar3D_getTireContacts(twoLane, [10 -1.8 0], FigNum=-1);
assert(isequal(size(contacts.TireZ), [1 4]));

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

%% FAIL case: Poses that are not N x 3 or N x 6
if 1==0
    fcn_AnimateCar3D_getTireContacts(twoLane, [1 2]);
end

%% FAIL case: A negative wheelbase
if 1==0
    fcn_AnimateCar3D_getTireContacts(twoLane, [1 2 0], Wheelbase=-1);
end

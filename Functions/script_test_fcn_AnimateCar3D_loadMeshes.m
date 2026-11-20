% script_test_fcn_AnimateCar3D_loadMeshes.m
% Tests fcn_AnimateCar3D_loadMeshes
% Loads meshes at two levels of detail for the scene player.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_loadMeshes
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_loadMeshes
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

%% DEMO case: The sample car and the Prius, at both levels of detail
figNum = 10001;
titleString = sprintf('DEMO case: The sample car and the Prius, at both levels of detail');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

meshSet = fcn_AnimateCar3D_loadMeshes({'sample','2013_Toyota_Prius_Four'}, FigNum=figNum);

% Check variable types
assert(isstruct(meshSet));
assert(iscell(meshSet.IDs));
assert(isfield(meshSet,'sample') && isfield(meshSet, matlab.lang.makeValidName('2013_Toyota_Prius_Four')));

% Check variable sizes
entry = meshSet.(matlab.lang.makeValidName('2013_Toyota_Prius_Four'));
assert(isequal(size(entry.Size),[1 3]));
assert(isscalar(entry.RearOverhang));

% Check variable values: the low mesh is much smaller (the face budget
% is approximate: simplifying keeps wheels and lamps whole), the size
% matches the Prius (4.48 m long), and the rear overhang is about 0.86 m
assert(entry.LowFaces <= 400*1.5 && entry.LowFaces < entry.FullFaces/5);
assert(abs(entry.Size(1) - 4.48) < 0.02);
assert(abs(entry.RearOverhang - 0.856) < 0.05);
assert(isequal(meshSet.IDs, {'sample','2013_Toyota_Prius_Four'}));

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

%% TEST case: The plain box, and the other simple shapes
meshSet = fcn_AnimateCar3D_loadMeshes({'box','sample'});
assert(isequal(meshSet.box.Size,[1 1 1]) && meshSet.box.RearOverhang==0.5 && isempty(meshSet.box.Full));
meshSet = fcn_AnimateCar3D_loadMeshes({'Pedestrian','bar','cylinder'});
assert(isequal(meshSet.IDs, {'pedestrian','bar','cylinder'}));
assert(isequal(meshSet.pedestrian.Size,[0.35 0.55 1.75]) && meshSet.bar.RearOverhang==0);
assert(strcmp(meshSet.cylinder.Shape.ID,'cylinder'));

%% TEST case: Add meshes to a set already loaded
sampleSet = fcn_AnimateCar3D_loadMeshes('sample');
loadTimer = tic;
bigSet = fcn_AnimateCar3D_loadMeshes({'sample','box','pedestrian'}, MeshSet=sampleSet);
assert(toc(loadTimer) < 1);                 % the sample car is not made again
assert(isequal(bigSet.IDs, {'sample','box','pedestrian'}) && isequal(bigSet.sample, sampleSet.sample));

%% TEST case: One ID as text, and a different face count
figNum = 20001;
titleString = sprintf('TEST case: One ID as text, and a different face count');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

meshSet = fcn_AnimateCar3D_loadMeshes('2014_Ford_TransitConnect_XLTCargoLWB', LowFaces=200);
entry = meshSet.(matlab.lang.makeValidName('2014_Ford_TransitConnect_XLTCargoLWB'));
% (Below a few hundred faces the count stops falling: wheels and lamps are
% kept whole. The Transit's 14984 faces come down to about 300.)
assert(entry.LowFaces < 400 && entry.LowFaces < entry.FullFaces/20);
assert(abs(entry.Size(1) - 4.818) < 0.03);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
meshSet = fcn_AnimateCar3D_loadMeshes('sample', FigNum=[]);
assert(isfield(meshSet,'sample'));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
meshSet = fcn_AnimateCar3D_loadMeshes('sample', FigNum=-1);
assert(isfield(meshSet,'sample'));

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

%% FAIL case: A vehicle that does not exist
if 1==0
    fcn_AnimateCar3D_loadMeshes('2099_No_Such_Car');
end

%% FAIL case: Too few faces
if 1==0
    fcn_AnimateCar3D_loadMeshes('sample', LowFaces=5);
end

% script_test_fcn_AnimateCar3D_loadMeshes.m
% Tests fcn_AnimateCar3D_loadMeshes
% Loads meshes, with their detail levels, for the scene player.
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

%% DEMO case: The sample car and the Prius, with their levels
figNum = 10001;
titleString = sprintf('DEMO case: The sample car and the Prius, with their levels');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

meshSet = fcn_AnimateCar3D_loadMeshes({'sample','2013_Toyota_Prius_Four'}, FigNum=figNum);

% Check variable types
assert(isstruct(meshSet));
assert(iscell(meshSet.IDs));
assert(isfield(meshSet,'sample') && isfield(meshSet, matlab.lang.makeValidName('2013_Toyota_Prius_Four')));

% Check variable sizes
entry = meshSet.(matlab.lang.makeValidName('2013_Toyota_Prius_Four'));
assert(isequal(size(entry.Size),[1 3]) && isequal(size(entry.BoxCenter),[1 3]));
assert(isscalar(entry.RearOverhang) && isscalar(entry.SizeDiagonal));

% Check variable values: the Prius's ladder (from its levels file), its
% size (4.48 m long, D = 5.14 m), and its rear overhang (about 0.86 m)
assert(isequal(entry.LevelFaces, [1026 512 256 128 64 32 16 5]));
assert(entry.Levels(end).IsBox && ~any([entry.Levels(1:end-1).IsBox]));
assert(entry.TopScreenSize==105 && abs(entry.Levels(1).MaxScreenSize-105)<1e-9);
assert(all(diff([entry.Levels.MaxScreenSize]) < 0));
assert(abs(entry.Size(1) - 4.48) < 0.02);
assert(abs(entry.SizeDiagonal - 5.14) < 0.01);
assert(abs(entry.RearOverhang - 0.856) < 0.05);
assert(isequal(meshSet.IDs, {'sample','2013_Toyota_Prius_Four'}));
% The sample car is small: its ladder starts below 105 px (a level that
% would need its 636 faces or more is not made)
assert(meshSet.sample.Levels(1).MaxScreenSize < 105 && meshSet.sample.LevelFaces(1) < meshSet.sample.FullFaces);

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
assert(isempty(meshSet.box.Levels) && abs(meshSet.box.SizeDiagonal - sqrt(3)) < 1e-9);
meshSet = fcn_AnimateCar3D_loadMeshes({'Pedestrian','bar','cylinder'});
assert(isequal(meshSet.IDs, {'pedestrian','bar','cylinder'}));
assert(isequal(meshSet.pedestrian.Size,[0.35 0.55 1.75]) && meshSet.bar.RearOverhang==0);
assert(abs(meshSet.pedestrian.BoxCenter(3) - 1.75/2) < 0.05);       % the box center is at half height
assert(strcmp(meshSet.cylinder.Shape.ID,'cylinder'));

%% TEST case: The sample car's cache
cacheFile = [tempname '.mat'];
cacheTimer = tic;
firstSet = fcn_AnimateCar3D_loadMeshes('sample', SampleCacheFile=cacheFile);
firstSeconds = toc(cacheTimer);
assert(isfile(cacheFile));
cacheTimer = tic;
secondSet = fcn_AnimateCar3D_loadMeshes('sample', SampleCacheFile=cacheFile);
secondSeconds = toc(cacheTimer);
assert(isequaln(firstSet.sample, secondSet.sample));            % the same mesh and levels
assert(secondSeconds < 0.5 && secondSeconds < firstSeconds/4);  % from the cache
fprintf(1,'   Sample car: %.2f s made, %.2f s from the cache\n', firstSeconds, secondSeconds);
% A cache from another CarMesh3D copy is not used: it is made again
cached = load(cacheFile);
cached.cacheKey.CarMesh3DName = 'CarMesh3D_1999_01_01';
save(cacheFile, '-struct', 'cached');
cacheTimer = tic;
thirdSet = fcn_AnimateCar3D_loadMeshes('sample', SampleCacheFile=cacheFile);
assert(toc(cacheTimer) > 4*secondSeconds && isequaln(thirdSet.sample, firstSet.sample));
cached = load(cacheFile);
assert(~strcmp(cached.cacheKey.CarMesh3DName, 'CarMesh3D_1999_01_01'));   % saved again
delete(cacheFile);
% No cache
noCacheSet = fcn_AnimateCar3D_loadMeshes('sample', SampleCacheFile='');
assert(isequaln(noCacheSet.sample, firstSet.sample));

%% TEST case: Add meshes to a set already loaded
sampleSet = fcn_AnimateCar3D_loadMeshes('sample');
loadTimer = tic;
bigSet = fcn_AnimateCar3D_loadMeshes({'sample','box','pedestrian'}, MeshSet=sampleSet);
assert(toc(loadTimer) < 1);                 % the sample car is not made again
assert(isequal(bigSet.IDs, {'sample','box','pedestrian'}) && isequaln(bigSet.sample, sampleSet.sample));

%% TEST case: One ID as text (the Transit Connect)
figNum = 20001;
titleString = sprintf('TEST case: One ID as text (the Transit Connect)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

meshSet = fcn_AnimateCar3D_loadMeshes('2014_Ford_TransitConnect_XLTCargoLWB');
entry = meshSet.(matlab.lang.makeValidName('2014_Ford_TransitConnect_XLTCargoLWB'));
assert(isequal(entry.LevelFaces, [1144 572 286 142 70 36 18 5]));
assert(abs(entry.Size(1) - 4.818) < 0.03 && abs(entry.SizeDiagonal - 5.58) < 0.01);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
meshSet = fcn_AnimateCar3D_loadMeshes('box', FigNum=[]);
assert(isfield(meshSet,'box'));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
meshSet = fcn_AnimateCar3D_loadMeshes('box', FigNum=-1);
assert(isfield(meshSet,'box'));

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

%% FAIL case: A mesh set that is not one
if 1==0
    fcn_AnimateCar3D_loadMeshes('sample', MeshSet=struct('a',1));
end

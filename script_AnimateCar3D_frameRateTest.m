% script_AnimateCar3D_frameRateTest.m
% How fast can fcn_AnimateCar3D_playScene draw dense traffic?
%
% Synthetic traffic drives on 19 lanes around an ego vehicle (about half the
% lanes each way, right-hand traffic: lanes on the right of the ego's
% direction, y < 0, drive toward +x, "up" the screen; lanes on the left
% toward -x), wrapping around a 200 m window centered on the ego so the
% density stays constant. Each step, a stand-in for the selector
% applies the selector's rule (sizes on screen, from this camera): the
% largest vehicles on screen are near (full meshes, up to NearMax, over
% 105 px), the next middle (reduced meshes drawn separately, up to
% MiddleMax, over 37 px), and the rest far (reduced meshes merged in one
% patch), each with the detail level made for its size.
%
% Three kinds of runs are timed:
%   all near   every vehicle drawn with its full mesh (no tiers): the
%              cost without the tier system
%   levels     the rule above: NearMax full meshes, MiddleMax separate
%              reduced meshes, and the rest merged at their levels
%   boxes far  the same tiers, but middle vehicles all at the finest
%              level and far vehicles as boxes (as before detail levels):
%              the cost of the merged levels
%
% For each run, the time per step is split into the player's update
% (fcn_AnimateCar3D_playScene) and MATLAB's drawing (drawnow). Results
% are printed, saved to Data/frameRate_results.csv, and plotted in
% Images/frameRate.png. The numbers depend on the computer and its
% graphics card.
%
% New graphics: the player makes a vehicle's graphics the first time a
% mesh is needed at a tier and level with no free graphics to reuse (for
% example, when a middle vehicle moves to another detail level). Each
% run also reports, over its timed steps, how many steps made new
% graphics, and the player's time on those steps and on the others.
%
% Then a demonstration: 1000 vehicles with detail levels, saved as
% Images/denseTraffic_1000vehicles.gif (flag_saveGif).
%
% Run script_demo_AnimateCar3D first, so that the paths are set.
%
% This script was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_AnimateCar3D_frameRateTest
%   % * First write of the code (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_AnimateCar3D_frameRateTest
%   % * Tiers and detail levels by size on screen (the selector's rule),
%   %   % in place of distances; added the 'boxes far' runs
%   % * Far vehicles past the middle count capped at the merge size's level
%   % * Right-hand traffic (lanes with y < 0 drive toward +x); the ego on
%   %   % the first lane to the right; timing of steps that make new
%   %   % graphics; the 1000-vehicle demonstration GIF

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_AnimateCar3D_frameRateTest
%   % * Use the selector itself (with a catalog of the wrapping traffic)
%   %   % in place of the stand-in


%% Settings
if isempty(which('fcn_AnimateCar3D_playScene')) || isempty(which('fcn_CarMesh3D_plotVehicle'))
    error('Run script_demo_AnimateCar3D first, so that AnimateCar3D and CarMesh3D are on the path.');
end

% The runs: {name, number of vehicles, NearMax, MiddleMax}
runList = {
    'all near',   25,   25,   0
    'all near',   50,   50,   0
    'all near',  100,  100,   0
    'levels',    100,   10,  40
    'levels',    250,   10,  40
    'levels',    500,   10,  40
    'levels',   1000,   10,  40
    'boxes far', 250,   10,  40
    'boxes far',1000,   10,  40
    };
topScreenSize = 105;    % px: near above this size on screen
mergeBelowSize = 37;    % px: far (merged) below this size
minScreenSize = 1;      % px: not drawn below this size
warmupSteps = 10;       % steps not timed (graphics being created)
timedSteps = 40;        % steps timed
sampleTime = 0.05;      % s per step
figureSize = [960 540]; % pixels
flag_saveGif = 1;       % 1 to save the 1000-vehicle demonstration GIF
egoY = -1.8;            % the ego's lane: the first to the right

% Vehicles: the ego and the traffic use the reference vehicles
meshIDs = {'2013_Toyota_Prius_Four','2014_Ford_TransitConnect_XLTCargoLWB'};
meshSet = fcn_AnimateCar3D_loadMeshes(meshIDs, FigNum=-1);


%% Run each case
Nruns = size(runList,1);
results = table('Size',[Nruns 14], ...
    'VariableTypes',[{'string'}, repmat({'double'},1,13)], ...
    'VariableNames',{'Run','Vehicles','NearMax','MiddleMax','MeanNear','MeanMiddle','MeanFar','MergedFaces','UpdateMs','DrawMs', ...
    'CreateSteps','Created','CreateStepUpdateMs','OtherStepUpdateMs'});
for ith_run = 1:Nruns
    [runName, Nvehicles, nearMax, middleMax] = runList{ith_run,:};
    fprintf(1,'Run %d of %d: %s, %d vehicles ... ', ith_run, Nruns, runName, Nvehicles);

    % A fresh figure and scene
    close all;
    figureHandle = figure(1);
    set(figureHandle, 'Position', [50 50 figureSize], 'Color', 'w');
    fcn_CarMesh3D_plotScene(GroundExtent=[-130 130 -60 60], GridSpacing=10, FigNum=1);
    axesHandle = gca;
    axis(axesHandle, 'off');
    set(axesHandle, 'Projection', 'perspective');

    % The traffic (the same random traffic for every run of this size)
    traffic = fcn_INTERNAL_makeTraffic(Nvehicles, meshIDs, 1000+Nvehicles);
    if strcmp(runName,'all near')
        sizeLimits = [0 0 0];             % every vehicle near, at any size
    else
        sizeLimits = [topScreenSize mergeBelowSize minScreenSize];
    end
    axesPixels = getpixelposition(axesHandle);
    pixelScale = min(axesPixels(3:4))/(2*tand(48/2));      % (the view angle spans the axes' smaller side)
    mergedFaces = zeros(warmupSteps+timedSteps, 1);

    % The steps
    playerState = [];
    egoX = 0;
    egoSpeed = 11;
    stepTimes = zeros(warmupSteps+timedSteps, 2);
    tierCounts = zeros(warmupSteps+timedSteps, 3);
    createdCounts = zeros(warmupSteps+timedSteps, 1);
    for ith_step = 1:(warmupSteps+timedSteps)
        egoX = egoX + egoSpeed*sampleTime;
        traffic = fcn_INTERNAL_moveTraffic(traffic, sampleTime, egoX);

        % Stand-in for the selector: tiers and levels by size on screen
        cameraPosition = [egoX-38 -14 34];
        displayList = fcn_INTERNAL_sizedList(traffic, meshSet, cameraPosition, pixelScale, nearMax, middleMax, ...
            sizeLimits, strcmp(runName,'boxes far'), ith_step*sampleTime);
        displayList = fcn_AnimateCar3D_fillDisplayList(Instance='ego', MeshID=meshIDs{1}, Pose=[egoX egoY 0], ...
            WheelSpin=repmat(egoX/0.317,1,4), Color=[0.05 0.2 0.6], AppendTo=displayList, FigNum=-1);

        % Draw it, and time the player and the drawing separately
        playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=playerState, FigNum=-1);
        campos(axesHandle, cameraPosition);
        camtarget(axesHandle, [egoX+28 0 0]);
        camva(axesHandle, 48);
        drawTimer = tic;
        drawnow;
        stepTimes(ith_step,:) = [playerState.Stats.UpdateSeconds, toc(drawTimer)];
        tierCounts(ith_step,:) = [playerState.Stats.NumNear, playerState.Stats.NumMiddle, playerState.Stats.NumFar];
        mergedFaces(ith_step) = playerState.Stats.NumMergedFaces;
        createdCounts(ith_step) = playerState.Stats.NumCreated;
    end
    timedRows = warmupSteps+1:warmupSteps+timedSteps;
    flagCreate = createdCounts(timedRows) > 0;
    timedUpdate = 1000*stepTimes(timedRows,1);
    results(ith_run,:) = {runName, Nvehicles, nearMax, middleMax, ...
        mean(tierCounts(timedRows,1)), mean(tierCounts(timedRows,2)), mean(tierCounts(timedRows,3)), ...
        mean(mergedFaces(timedRows)), mean(timedUpdate), 1000*mean(stepTimes(timedRows,2)), ...
        sum(flagCreate), sum(createdCounts(timedRows)), mean(timedUpdate(flagCreate)), mean(timedUpdate(~flagCreate))};
    fprintf(1,'%.0f ms per step (%.0f update + %.0f draw), %.1f steps per second; %d of %d steps made new graphics\n', ...
        results.UpdateMs(ith_run)+results.DrawMs(ith_run), results.UpdateMs(ith_run), results.DrawMs(ith_run), ...
        1000/(results.UpdateMs(ith_run)+results.DrawMs(ith_run)), sum(flagCreate), timedSteps);

    % Keep a picture of the densest run with levels
    if strcmp(runName,'levels') && Nvehicles==max(cell2mat(runList(:,2)))
        title(axesHandle, sprintf('%d vehicles: %.0f near, %.0f middle, %.0f far (merged, %.0f faces)', Nvehicles, ...
            results.MeanNear(ith_run), results.MeanMiddle(ith_run), results.MeanFar(ith_run), results.MergedFaces(ith_run)));
        drawnow;
        snapshot = getframe(figureHandle);
        imwrite(snapshot.cdata, fullfile(pwd,'Images','frameRate_denseTraffic.png'));
    end
    fcn_AnimateCar3D_playScene([], meshSet, PlayerState=playerState, Action='clear');
end
results.TotalMs = results.UpdateMs + results.DrawMs;
results.StepsPerSecond = 1000./results.TotalMs;


%% Report
disp(results);
writetable(results, fullfile(pwd,'Data','frameRate_results.csv'));

figure(2);
clf;
set(gcf, 'Position', [100 100 760 420], 'Color', 'w');
hold on;
runColors = [0.80 0.30 0.20; 0.15 0.45 0.75; 0.55 0.55 0.55];
runNames = {'all near','levels','boxes far'};
legendHandles = gobjects(0);
for ith_name = 1:3
    rows = results.Run==runNames{ith_name};
    legendHandles(end+1) = plot(results.Vehicles(rows), results.StepsPerSecond(rows), '-o', ...
        'Color', runColors(ith_name,:), 'MarkerFaceColor', runColors(ith_name,:), 'LineWidth', 1.5); %#ok<SAGROW>
end
yline(20, ':', '20 steps per second', 'Color', [0.4 0.4 0.4]);
set(gca, 'XScale', 'log', 'XTick', [25 50 100 250 500 1000]);
xlabel('Vehicles in the scene');
ylabel('Steps per second (update + drawing)');
legend(legendHandles, {'All near (full meshes)', sprintf('Levels by size on screen (up to %d near, %d middle, rest merged)', runList{end,3}, runList{end,4}), ...
    'Same tiers, far as boxes'}, 'Location', 'northeast');
title(sprintf('fcn\\_AnimateCar3D\\_playScene frame rate (%s)', version('-release')));
grid on;
box on;
drawnow;
snapshot = getframe(gcf);
imwrite(snapshot.cdata, fullfile(pwd,'Images','frameRate.png'));


%% A demonstration: 1000 vehicles, with detail levels
% The same traffic and camera as the densest 'levels' run, drawn for 5 s
% and saved as a GIF (one fixed color map, so small colored details keep
% their colors). The caption shows the tiers and the time per step.
if flag_saveGif
    Nvehicles = 1000;
    gifFile = fullfile(pwd,'Images','denseTraffic_1000vehicles.gif');
    close all;
    figureHandle = figure(1);
    set(figureHandle, 'Position', [50 50 figureSize], 'Color', 'w');
    fcn_CarMesh3D_plotScene(GroundExtent=[-130 400 -60 60], GridSpacing=10, FigNum=1);
    axesHandle = gca;
    axis(axesHandle, 'off');
    set(axesHandle, 'Projection', 'perspective');
    axesPixels = getpixelposition(axesHandle);
    pixelScale = min(axesPixels(3:4))/(2*tand(48/2));
    caption = annotation(figureHandle, 'textbox', [0 0.9 1 0.1], 'String', '', 'EdgeColor','none', ...
        'HorizontalAlignment','center', 'FontSize', 11, 'Interpreter','none');
    traffic = fcn_INTERNAL_makeTraffic(Nvehicles, meshIDs, 1000+Nvehicles);
    playerState = [];
    egoX = 0;
    egoSpeed = 11;
    gifColorMap = [];
    for ith_step = 1:100
        egoX = egoX + egoSpeed*sampleTime;
        traffic = fcn_INTERNAL_moveTraffic(traffic, sampleTime, egoX);
        cameraPosition = [egoX-38 -14 34];
        displayList = fcn_INTERNAL_sizedList(traffic, meshSet, cameraPosition, pixelScale, 10, 40, ...
            [topScreenSize mergeBelowSize minScreenSize], false, ith_step*sampleTime);
        displayList = fcn_AnimateCar3D_fillDisplayList(Instance='ego', MeshID=meshIDs{1}, Pose=[egoX egoY 0], ...
            WheelSpin=repmat(egoX/0.317,1,4), Color=[0.05 0.2 0.6], AppendTo=displayList, FigNum=-1);
        playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=playerState, FigNum=-1);
        campos(axesHandle, cameraPosition);
        camtarget(axesHandle, [egoX+28 0 0]);
        camva(axesHandle, 48);
        drawTimer = tic;
        drawnow;
        stepMs = 1000*(playerState.Stats.UpdateSeconds + toc(drawTimer));
        stats = playerState.Stats;
        set(caption, 'String', sprintf('%d vehicles (right-hand traffic): %d near, %d middle, %d far merged (%d faces); %.0f ms per step', ...
            Nvehicles, stats.NumNear, stats.NumMiddle, stats.NumFar, stats.NumMergedFaces, stepMs));
        if ith_step > 10 && mod(ith_step,2)==0       % (after the first graphics are made)
            drawnow;
            frame = getframe(figureHandle);
            if isempty(gifColorMap)
                [frameIndexed, gifColorMap] = rgb2ind(frame.cdata, 255, 'nodither');
                imwrite(frameIndexed, gifColorMap, gifFile, 'gif', 'LoopCount', Inf, 'DelayTime', 2*sampleTime);
            else
                frameIndexed = rgb2ind(frame.cdata, gifColorMap, 'nodither');
                imwrite(frameIndexed, gifColorMap, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', 2*sampleTime);
            end
        end
    end
    fcn_AnimateCar3D_playScene([], meshSet, PlayerState=playerState, Action='clear');
    fprintf(1,'Saved %s\n', gifFile);
end


%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_makeTraffic
function traffic = fcn_INTERNAL_makeTraffic(Nvehicles, meshIDs, randomSeed)
% Random traffic on 20 lanes (3.6 m apart), half each way, spread over a
% 200 m window, leaving the ego's lane (y = -1.8) free; 70% of vehicles
% use the first mesh, 30% the second
randomStream = RandStream('mt19937ar', 'Seed', randomSeed);
laneY = (-9.5:9.5)*3.6;
laneY = laneY(abs(laneY + 1.8) > 0.1);
lane = randi(randomStream, numel(laneY), Nvehicles, 1);
traffic = struct;
traffic.Instance = compose('car%d', (1:Nvehicles)');
traffic.MeshID = meshIDs(1 + (rand(randomStream, Nvehicles, 1) > 0.7));
traffic.MeshID = traffic.MeshID(:);
traffic.Direction = -sign(laneY(lane))';                     % right-hand traffic: y < 0 goes +x, y > 0 goes -x
traffic.X = -100 + 200*rand(randomStream, Nvehicles, 1);
traffic.Y = laneY(lane)';
traffic.Speed = 8 + 6*rand(randomStream, Nvehicles, 1);
palette = [0.75 0.75 0.78; 0.10 0.10 0.12; 0.85 0.15 0.12; 0.95 0.95 0.95; 0.20 0.35 0.65; 0.55 0.55 0.58];
traffic.Color = palette(randi(randomStream, size(palette,1), Nvehicles, 1), :);
traffic.Spin = zeros(Nvehicles,1);
end % Ends fcn_INTERNAL_makeTraffic

%% fcn_INTERNAL_moveTraffic
function traffic = fcn_INTERNAL_moveTraffic(traffic, sampleTime, egoX)
% Move each vehicle along its lane, and wrap it around the 200 m window
% centered on the ego
step = traffic.Direction .* traffic.Speed * sampleTime;
traffic.X = traffic.X + step;
traffic.Spin = traffic.Spin + abs(step)/0.317;
relativeX = traffic.X - egoX;
traffic.X = egoX + mod(relativeX + 100, 200) - 100;
end % Ends fcn_INTERNAL_moveTraffic

%% fcn_INTERNAL_sizedList
function displayList = fcn_INTERNAL_sizedList(traffic, meshSet, cameraPosition, pixelScale, nearMax, middleMax, ...
    sizeLimits, flagBoxesFar, timeNow)
% Stand-in for the selector, with its rule: each vehicle's size on screen
% (D x pixelScale / distance to its box center); the largest are near (up
% to nearMax, over sizeLimits(1)), the next middle (up to middleMax, over
% sizeLimits(2)), the rest far (over sizeLimits(3)); middle and far
% vehicles get the level made for their size (or, with flagBoxesFar, the
% finest level and a box)
N = numel(traffic.Instance);
yaw = (traffic.Direction < 0)*pi;
sizeDiagonals = zeros(N,1);
centerOffsets = zeros(N,3);
levelSizes = cell(N,1);
[uniqueIDs, ~, idIndex] = unique(traffic.MeshID);
for ith_id = 1:numel(uniqueIDs)
    entry = meshSet.(matlab.lang.makeValidName(uniqueIDs{ith_id}));
    rows = idIndex==ith_id;
    sizeDiagonals(rows) = entry.SizeDiagonal;
    centerOffsets(rows,:) = repmat(entry.BoxCenter, sum(rows), 1);
    levelSizes(rows) = {[entry.Levels.MaxScreenSize]};
end
centers = [traffic.X + cos(yaw).*centerOffsets(:,1), traffic.Y + cos(yaw).*centerOffsets(:,2), centerOffsets(:,3)];
screenSizes = sizeDiagonals*pixelScale ./ sqrt(sum((centers - cameraPosition).^2, 2));
[~, order] = sort(screenSizes, 'descend');
tiers = repmat({'none'}, N, 1);
nearRows = order(screenSizes(order) >= sizeLimits(1));
nearRows = nearRows(1:min(end, nearMax));
tiers(nearRows) = {'near'};
middleRows = order(strcmp(tiers(order),'none') & screenSizes(order) >= sizeLimits(2));
middleRows = middleRows(1:min(end, middleMax));
tiers(middleRows) = {'middle'};
tiers(strcmp(tiers,'none') & screenSizes >= sizeLimits(3)) = {'far'};
levels = zeros(N,1);
for ith_row = 1:N
    maxSizes = levelSizes{ith_row};
    switch tiers{ith_row}
        case 'middle'
            if flagBoxesFar
                levels(ith_row) = 1;
            else
                levels(ith_row) = max([0, find(maxSizes >= screenSizes(ith_row), 1, 'last')]);
            end
        case 'far'
            if flagBoxesFar
                levels(ith_row) = numel(maxSizes);       % the box
            else
                % (no finer than the level made for the merge size: the
                % selector's cap on vehicles past the middle count)
                levels(ith_row) = max([1, find(maxSizes >= screenSizes(ith_row), 1, 'last'), ...
                    find(maxSizes >= sizeLimits(2), 1, 'last')]);
            end
    end
end
shown = ~strcmp(tiers,'none');
displayList = fcn_AnimateCar3D_fillDisplayList(Time=timeNow, Instance=traffic.Instance(shown), ...
    MeshID=traffic.MeshID(shown), Pose=[traffic.X(shown), traffic.Y(shown), yaw(shown)], Tier=tiers(shown), ...
    WheelSpin=repmat(traffic.Spin(shown),1,4), Color=traffic.Color(shown,:), Level=levels(shown), ...
    ScreenSize=screenSizes(shown), FigNum=-1);
end % Ends fcn_INTERNAL_sizedList

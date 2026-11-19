% script_AnimateCar3D_frameRateTest.m
% How fast can fcn_AnimateCar3D_playScene draw dense traffic?
%
% Synthetic traffic drives on 20 lanes around an ego vehicle (half the
% lanes each way), wrapping around a 200 m window centered on the ego so
% the density stays constant. Each step, a simple stand-in for the
% selector gives the nearest vehicles the near tier, the next ones the
% middle tier, and the rest within FarDistance the far tier (boxes).
%
% Two kinds of runs are timed:
%   all near   every vehicle drawn with its full mesh (no tiers): the
%              cost without the tier system
%   tiered     NearMax full meshes, MiddleMax low-detail meshes, and the
%              rest as boxes
%
% For each run, the time per step is split into the player's update
% (fcn_AnimateCar3D_playScene) and MATLAB's drawing (drawnow). Results
% are printed, saved to Data/frameRate_results.csv, and plotted in
% Images/frameRate.png. The numbers depend on the computer and its
% graphics card.
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

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_AnimateCar3D_frameRateTest
%   % * Replace the stand-in tier rule with the selector, once it exists


%% Settings
if isempty(which('fcn_AnimateCar3D_playScene')) || isempty(which('fcn_CarMesh3D_plotVehicle'))
    error('Run script_demo_AnimateCar3D first, so that AnimateCar3D and CarMesh3D are on the path.');
end

% The runs: {name, number of vehicles, NearMax, MiddleMax}
runList = {
    'all near',  25,   25,   0
    'all near',  50,   50,   0
    'all near', 100,  100,   0
    'tiered',   100,   10,  40
    'tiered',   250,   10,  40
    'tiered',   500,   10,  40
    'tiered',  1000,   10,  40
    };
nearDistance = 30;      % m: near tier only within this distance
middleDistance = 70;    % m: middle tier only within this distance
farDistance = 100;      % m: nothing drawn beyond this distance
warmupSteps = 10;       % steps not timed (graphics being created)
timedSteps = 40;        % steps timed
sampleTime = 0.05;      % s per step
figureSize = [960 540]; % pixels

% Vehicles: the ego and the traffic use the reference vehicles
meshIDs = {'2013_Toyota_Prius_Four','2014_Ford_TransitConnect_XLTCargoLWB'};
meshSet = fcn_AnimateCar3D_loadMeshes(meshIDs, FigNum=-1);


%% Run each case
Nruns = size(runList,1);
results = table('Size',[Nruns 9], ...
    'VariableTypes',{'string','double','double','double','double','double','double','double','double'}, ...
    'VariableNames',{'Run','Vehicles','NearMax','MiddleMax','MeanNear','MeanMiddle','MeanFar','UpdateMs','DrawMs'});
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
        tierLimits = [inf inf inf];       % every vehicle near, at any distance
    else
        tierLimits = [nearDistance middleDistance farDistance];
    end

    % The steps
    playerState = [];
    egoX = 0;
    egoSpeed = 11;
    stepTimes = zeros(warmupSteps+timedSteps, 2);
    tierCounts = zeros(warmupSteps+timedSteps, 3);
    for ith_step = 1:(warmupSteps+timedSteps)
        egoX = egoX + egoSpeed*sampleTime;
        traffic = fcn_INTERNAL_moveTraffic(traffic, sampleTime, egoX);

        % Stand-in for the selector: tiers by distance and count
        displayList = fcn_INTERNAL_tieredList(traffic, egoX, nearMax, middleMax, tierLimits, ith_step*sampleTime);
        displayList = fcn_AnimateCar3D_fillDisplayList(Instance='ego', MeshID=meshIDs{1}, Pose=[egoX 0 0], ...
            WheelSpin=repmat(egoX/0.317,1,4), Color=[0.05 0.2 0.6], AppendTo=displayList, FigNum=-1);

        % Draw it, and time the player and the drawing separately
        playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=playerState, FigNum=-1);
        campos(axesHandle, [egoX-38 -14 34]);
        camtarget(axesHandle, [egoX+28 0 0]);
        camva(axesHandle, 48);
        drawTimer = tic;
        drawnow;
        stepTimes(ith_step,:) = [playerState.Stats.UpdateSeconds, toc(drawTimer)];
        tierCounts(ith_step,:) = [playerState.Stats.NumNear, playerState.Stats.NumMiddle, playerState.Stats.NumFar];
    end
    timedRows = warmupSteps+1:warmupSteps+timedSteps;
    results(ith_run,:) = {runName, Nvehicles, nearMax, middleMax, ...
        mean(tierCounts(timedRows,1)), mean(tierCounts(timedRows,2)), mean(tierCounts(timedRows,3)), ...
        1000*mean(stepTimes(timedRows,1)), 1000*mean(stepTimes(timedRows,2))};
    fprintf(1,'%.0f ms per step (%.0f update + %.0f draw), %.1f steps per second\n', ...
        results.UpdateMs(ith_run)+results.DrawMs(ith_run), results.UpdateMs(ith_run), results.DrawMs(ith_run), ...
        1000/(results.UpdateMs(ith_run)+results.DrawMs(ith_run)));

    % Keep a picture of the densest tiered run
    if strcmp(runName,'tiered') && Nvehicles==max(cell2mat(runList(:,2)))
        title(axesHandle, sprintf('%d vehicles: %.0f near, %.0f middle, %.0f boxes', Nvehicles, ...
            results.MeanNear(ith_run), results.MeanMiddle(ith_run), results.MeanFar(ith_run)));
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
runColors = [0.80 0.30 0.20; 0.15 0.45 0.75];
runNames = {'all near','tiered'};
legendHandles = gobjects(0);
for ith_name = 1:2
    rows = results.Run==runNames{ith_name};
    legendHandles(end+1) = plot(results.Vehicles(rows), results.StepsPerSecond(rows), '-o', ...
        'Color', runColors(ith_name,:), 'MarkerFaceColor', runColors(ith_name,:), 'LineWidth', 1.5); %#ok<SAGROW>
end
yline(20, ':', '20 steps per second', 'Color', [0.4 0.4 0.4]);
set(gca, 'XScale', 'log', 'XTick', [25 50 100 250 500 1000]);
xlabel('Vehicles in the scene');
ylabel('Steps per second (update + drawing)');
legend(legendHandles, {'All near (full meshes)', sprintf('Tiered (%d near, %d middle, rest boxes)', runList{end,3}, runList{end,4})}, 'Location', 'northeast');
title(sprintf('fcn\\_AnimateCar3D\\_playScene frame rate (%s)', version('-release')));
grid on;
box on;
drawnow;
snapshot = getframe(gcf);
imwrite(snapshot.cdata, fullfile(pwd,'Images','frameRate.png'));


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
% 200 m window; 70% of vehicles use the first mesh, 30% the second
randomStream = RandStream('mt19937ar', 'Seed', randomSeed);
laneY = (-9.5:9.5)*3.6;
lane = randi(randomStream, numel(laneY), Nvehicles, 1);
traffic = struct;
traffic.Instance = compose('car%d', (1:Nvehicles)');
traffic.MeshID = meshIDs(1 + (rand(randomStream, Nvehicles, 1) > 0.7));
traffic.MeshID = traffic.MeshID(:);
traffic.Direction = sign(laneY(lane))';                      % lanes with y > 0 go +x
traffic.Direction(traffic.Direction==0) = 1;
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

%% fcn_INTERNAL_tieredList
function displayList = fcn_INTERNAL_tieredList(traffic, egoX, nearMax, middleMax, tierLimits, timeNow)
% Stand-in for the selector: the nearest vehicles (up to nearMax, within
% tierLimits(1)) are near, the next (up to middleMax, within
% tierLimits(2)) middle, the rest within tierLimits(3) far
distance = hypot(traffic.X - egoX, traffic.Y);
[sortedDistance, order] = sort(distance);
N = numel(order);
tiers = repmat({'none'}, N, 1);
rank = (1:N)';
tiers(rank<=nearMax & sortedDistance<=tierLimits(1)) = {'near'};
flagMiddle = strcmp(tiers,'none') & rank<=nearMax+middleMax & sortedDistance<=tierLimits(2);
tiers(flagMiddle) = {'middle'};
flagFar = strcmp(tiers,'none') & sortedDistance<=tierLimits(3);
tiers(flagFar) = {'far'};
shown = ~strcmp(tiers,'none');
rows = order(shown);
yaw = (traffic.Direction(rows) < 0)*pi;
displayList = fcn_AnimateCar3D_fillDisplayList(Time=timeNow, Instance=traffic.Instance(rows), ...
    MeshID=traffic.MeshID(rows), Pose=[traffic.X(rows), traffic.Y(rows), yaw], Tier=tiers(shown), ...
    WheelSpin=repmat(traffic.Spin(rows),1,4), Color=traffic.Color(rows,:), FigNum=-1);
end % Ends fcn_INTERNAL_tieredList

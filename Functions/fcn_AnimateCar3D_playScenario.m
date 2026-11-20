function playResult = fcn_AnimateCar3D_playScenario(scenario, options)
% fcn_AnimateCar3D_playScenario

% Plays a scenario held in memory (for example, from
% fcn_AnimateCar3D_fillExampleScenario) in one call: draws the scene
% (the ground and the road), the centerline options, and the objects
% moving, with a camera following one of them, and can save a GIF. The
% whole animation loop (catalog, camera, selector, player, frames) is
% done here, so a script needs only:
%
%       scenario = fcn_AnimateCar3D_fillExampleScenario('laneChange');
%       fcn_AnimateCar3D_playScenario(scenario);
%
% FORMAT:
%
%       playResult = fcn_AnimateCar3D_playScenario(scenario,...
%           (TimeStep=seconds), (CameraSettings=settings),...
%           (CameraFollow=instance), (ShowOptions=flag), (Caption=flag),...
%           (GifFile=fileName), (GifDelay=seconds), (FigNum=figNum))
%
% INPUTS:
%
%      scenario: a structure with Road (a road or road network from
%      fcn_AnimateCar3D_fillRoad), SceneList, Motions, and optionally
%      CenterlineOptions, Name, and Description.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      TimeStep: seconds of scenario time between frames. Default 0.1.
%
%      CameraSettings: a CarMesh3D camera (fcn_CarMesh3D_fillCameraSettings).
%      Default: 22 m behind the followed object, 16 m to its right, 10 m
%      up, looking 18 m ahead (the camera of the road pictures); [] keeps
%      the camera as it is.
%
%      CameraFollow: the instance the camera follows. Default 'ego'.
%
%      ShowOptions: draw the centerline options on the road (solid
%      colored lines, never white or yellow). Default true.
%
%      Caption: a caption with the scenario's name, description, time,
%      and the followed object's speed. Default true.
%
%      GifFile: a GIF to save ('' for none, the default); GifDelay:
%      seconds per GIF frame (default: TimeStep, real time).
%
%      FigNum: the figure to draw in. Default 1. (-1: fast mode, no
%      input checks, the current figure.)
%
% OUTPUTS:
%
%      playResult: Catalog, MeshSet, PlayerState, Figure, Axes, Times
%      (the frames' times), and GifFrames.
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_loadMeshes, fcn_AnimateCar3D_buildCatalog,
%      fcn_AnimateCar3D_plotRoad, fcn_AnimateCar3D_fillDisplayCriteria,
%      fcn_AnimateCar3D_getObjectState, fcn_AnimateCar3D_selectObjects,
%      fcn_AnimateCar3D_playScene; CarMesh3D: fcn_CarMesh3D_plotScene,
%      fcn_CarMesh3D_fillCameraSettings, fcn_CarMesh3D_updateCamera
%
% EXAMPLES:
%
%       scenario = fcn_AnimateCar3D_fillExampleScenario('curvyVaryingSpeed');
%       fcn_AnimateCar3D_playScenario(scenario, GifFile='curvy.gif');
%
%       See the script: script_test_fcn_AnimateCar3D_playScenario.m for a
%       full test suite, and script_examples_AnimateCar3D.m.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_playScenario
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_playScenario
%   % * Path lines (trails) for the moving objects; a top-down view option



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    scenario
    options.TimeStep = 0.1              % seconds between frames
    options.CameraSettings = 'default'  % fcn_CarMesh3D_fillCameraSettings; [] keeps the camera
    options.CameraFollow = 'ego'        % instance the camera follows
    options.ShowOptions = true          % draw the centerline options
    options.Caption = true              % name, description, and time
    options.GifFile = ''                % GIF to save
    options.GifDelay = []               % seconds per GIF frame; [] for TimeStep
    options.FigNum = 1                  % figure to draw in; -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
flag_max_speed = 0; % The default. This runs code with all error checking
if isequal(options.FigNum,-1)
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS");
    MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above


        % Check the scenario
        if ~(isstruct(scenario) && all(isfield(scenario, {'Road','SceneList','Motions'})))
            error('scenario must have Road, SceneList, and Motions (see fcn_AnimateCar3D_fillExampleScenario)');
        end

        % Check the options
        if ~(isnumeric(options.TimeStep) && isscalar(options.TimeStep) && options.TimeStep > 0)
            error('TimeStep must be a positive number of seconds');
        end
        if ~(ischar(options.CameraSettings) || isstruct(options.CameraSettings) || isempty(options.CameraSettings))
            error('CameraSettings must come from fcn_CarMesh3D_fillCameraSettings, or be []');
        end
        if ~isempty(options.GifDelay) && ~(isnumeric(options.GifDelay) && isscalar(options.GifDelay) && options.GifDelay > 0)
            error('GifDelay must be a positive number of seconds, or []');
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed)
    temp = options.FigNum;
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp;
        flag_do_plots = 1;
    end
end

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%% Meshes and the catalog
sceneList = scenario.SceneList;
meshIDs = unique({sceneList.MeshID});
meshSet = fcn_AnimateCar3D_loadMeshes(meshIDs, FigNum=-1);
catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=scenario.Motions, FigNum=-1);

%%%% The figure: ground (no grid lines), the road, the centerline options
if isequal(options.FigNum, -1)
    figureHandle = gcf;
else
    figureHandle = figure(options.FigNum);
end
clf(figureHandle);
set(figureHandle, 'Color', 'w');
pathPoints = cell2mat(cellfun(@(motion) motion.Pose(:,1:2), scenario.Motions(:), 'UniformOutput', false));
if isfield(scenario, 'CenterlineOptions') && ~isempty(scenario.CenterlineOptions)
    pathPoints = [pathPoints; cell2mat(cellfun(@(option) option.XY, scenario.CenterlineOptions(:), 'UniformOutput', false))];
end
extent = [min(pathPoints(:,1)) - 150, max(pathPoints(:,1)) + 150, min(pathPoints(:,2)) - 150, max(pathPoints(:,2)) + 150];
fcn_CarMesh3D_plotScene(GroundExtent=extent, GridSpacing=0, GroundColor=[0.55 0.62 0.48], FigNum=figureHandle.Number);
axesHandle = get(figureHandle, 'CurrentAxes');
set(axesHandle, 'Position', [0 0 1 0.9]);
roadHandles = fcn_AnimateCar3D_plotRoad(scenario.Road, AxesHandle=axesHandle, FigNum=-1);
if options.ShowOptions && isfield(scenario, 'CenterlineOptions')
    pathColors = [0.10 0.35 0.85; 0.85 0.33 0.10; 0.49 0.18 0.56; 0.47 0.67 0.19; 0.30 0.75 0.93; 0.64 0.08 0.18];
    for ith_option = 1:numel(scenario.CenterlineOptions)
        thisOption = scenario.CenterlineOptions{ith_option};
        line(axesHandle, thisOption.XY(:,1), thisOption.XY(:,2), 0.04*ones(size(thisOption.S)), 'LineWidth', 1.5, ...
            'Color', pathColors(mod(ith_option-1, size(pathColors,1))+1,:), 'Tag', 'AnimateCar3D centerline option');
    end
end
axis(axesHandle, 'equal');
axis(axesHandle, 'off');
set(axesHandle, 'XLim', extent(1:2), 'YLim', extent(3:4), 'ZLim', [-0.5 40], 'Projection', 'perspective');
cameraSettings = options.CameraSettings;
if ischar(cameraSettings) && strcmp(cameraSettings, 'default')
    cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='kite', Position=[-22 -16 10], Target=[18 1 0], FieldOfView=45, FigNum=-1);
end
followIndex = find(strcmp({catalog.Objects.Instance}, options.CameraFollow), 1);

%%%% The frames
criteria = fcn_AnimateCar3D_fillDisplayCriteria();
selectorState = [];
playerState = [];
frameTimes = (catalog.TimeStart:options.TimeStep:catalog.TimeEnd)';
gifDelay = options.GifDelay;
if isempty(gifDelay)
    gifDelay = options.TimeStep;
end
gifColorMap = [];
gifFrames = 0;
for ith_frame = 1:numel(frameTimes)
    thisTime = frameTimes(ith_frame);
    if ~isgraphics(figureHandle)
        break;
    end
    if ~isempty(cameraSettings) && ~isempty(followIndex)
        followState = fcn_AnimateCar3D_getObjectState(catalog, followIndex, thisTime, Detail='pose', FigNum=-1);
        if followState.Exists
            fcn_CarMesh3D_updateCamera(cameraSettings, followState.Pose, Time=thisTime, AxesHandle=axesHandle, FigNum=-1);
        end
    end
    [displayList, selectorState] = fcn_AnimateCar3D_selectObjects(catalog, thisTime, criteria, SelectorState=selectorState, ...
        Camera=axesHandle, MeshSet=meshSet);
    playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=playerState, FigNum=figureHandle.Number);
    if options.Caption
        followSpeed = NaN;
        if ~isempty(followIndex)
            % (the followed object's speed, from its poses just before and after)
            nearTimes = min(max(thisTime + [-0.05 0.05], catalog.TimeStart), catalog.TimeEnd);
            nearStates = fcn_AnimateCar3D_getObjectState(catalog, followIndex, nearTimes(1), Detail='full', FigNum=-1);
            nearStates(2) = fcn_AnimateCar3D_getObjectState(catalog, followIndex, nearTimes(2), Detail='full', FigNum=-1);
            if diff(nearTimes) > 0 && all([nearStates.Exists])
                followSpeed = norm(nearStates(2).Pose(1:2) - nearStates(1).Pose(1:2))/diff(nearTimes);
            end
        end
        fcn_INTERNAL_caption(figureHandle, scenario, thisTime, followSpeed, options.CameraFollow);
    end
    drawnow;
    if ~isempty(options.GifFile)
        [gifColorMap, gifFrames] = fcn_INTERNAL_gifFrame(figureHandle, char(options.GifFile), gifColorMap, gifFrames, gifDelay);
    end
end

playResult = struct('Catalog',catalog, 'MeshSet',meshSet, 'PlayerState',playerState, 'Figure',figureHandle, ...
    'Axes',axesHandle, 'Times',frameTimes, 'GifFrames',gifFrames, 'RoadHandles',roadHandles);

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots

    % (the scenario is drawn above, in figure FigNum)
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

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

%% fcn_INTERNAL_caption
function fcn_INTERNAL_caption(figureHandle, scenario, thisTime, followSpeed, followName)
% A caption: the scenario's name and description, the time, and the
% followed object's speed
captionLines = {sprintf('t = %.1f s', thisTime)};
if isfield(scenario, 'Name')
    captionLines{1} = sprintf('%s: t = %.1f s', scenario.Name, thisTime);
end
if isfinite(followSpeed)
    captionLines{1} = sprintf('%s; %s speed %.1f m/s', captionLines{1}, followName, followSpeed);
end
if isfield(scenario, 'Description')
    captionLines{2} = scenario.Description;
end
caption = findall(figureHandle, 'Tag', 'AnimateCar3D scenario caption');
if isempty(caption)
    annotation(figureHandle, 'textbox', [0 0.9 1 0.1], 'String', captionLines, 'Tag', 'AnimateCar3D scenario caption', ...
        'EdgeColor','none', 'HorizontalAlignment','center', 'VerticalAlignment','middle', 'FontSize', 10, 'Interpreter','none');
else
    set(caption(1), 'String', captionLines);
end
end % Ends fcn_INTERNAL_caption

%% fcn_INTERNAL_gifFrame
function [gifColorMap, gifFrames] = fcn_INTERNAL_gifFrame(figureHandle, gifFile, gifColorMap, gifFrames, gifDelay)
% One GIF frame, with one fixed color map (from the first frame, plus a
% color cube), so small colored details keep their colors
frame = getframe(figureHandle);
if isempty(gifColorMap)
    [~, firstColors] = rgb2ind(frame.cdata, 40, 'nodither');
    [cubeR, cubeG, cubeB] = ndgrid(linspace(0,1,6));
    gifColorMap = [firstColors; cubeR(:) cubeG(:) cubeB(:)];
    imwrite(rgb2ind(frame.cdata, gifColorMap, 'nodither'), gifColorMap, gifFile, 'gif', 'LoopCount', Inf, 'DelayTime', gifDelay);
else
    imwrite(rgb2ind(frame.cdata, gifColorMap, 'nodither'), gifColorMap, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', gifDelay);
end
gifFrames = gifFrames + 1;
end % Ends fcn_INTERNAL_gifFrame

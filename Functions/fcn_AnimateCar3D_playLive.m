function liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, options)
% fcn_AnimateCar3D_playLive

% Plays live data from a watched folder: the whole live loop in one call,
% so a script need not write it. Each step it:
%
%   1. watches the folder (fcn_AnimateCar3D_watchFolder, at most every
%      CheckInterval seconds of clock time),
%   2. updates the catalog with new, grown, and deleted files
%      (fcn_AnimateCar3D_updateCatalog), and applies any change to the
%      folder's displayCriteria.txt (fcn_AnimateCar3D_changeDisplayCriteria),
%   3. loads the meshes of any new mesh IDs (fcn_AnimateCar3D_loadMeshes),
%   4. chooses the time to show: it advances with the clock (times
%      PlaybackSpeed), never closer than DisplayDelay seconds to the
%      newest data, so the picture moves smoothly although data arrives
%      in bursts,
%   5. points the camera (a CarMesh3D camera, fcn_CarMesh3D_updateCamera,
%      following the object CameraFollow),
%   6. selects and draws (fcn_AnimateCar3D_selectObjects,
%      fcn_AnimateCar3D_playScene), with a caption,
%   7. saves a GIF frame (GifFile).
%
% Two ways to use it:
%
%   Run until done (the default, Steps=Inf): one call plays until there
%   has been no new data for StopAfter seconds (and the picture has
%   caught up), the figure is closed, or MaxSeconds have passed.
%
%       fcn_AnimateCar3D_playLive(liveFolder, meshSet);
%
%   One step per call (Steps=1), for a script that does other work in
%   its own loop (for example, writes the data itself):
%
%       liveState = [];
%       while isempty(liveState) || ~liveState.Done
%           ... (the script's own work) ...
%           liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=liveState, Steps=1);
%       end
%
% If the figure is empty, a ground (fcn_CarMesh3D_plotScene, GroundExtent)
% is drawn first; to use your own scene, draw it in the figure before the
% first call.
%
% FORMAT:
%
%       liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet,...
%           (LiveState=liveState), (Steps=n), (Criteria=criteria),...
%           (DefaultMeshID=meshID), (CheckInterval=s), (ForceCheck=flag),...
%           (DisplayDelay=s), (PlaybackSpeed=factor), (ShowTime=t),...
%           (CameraSettings=settings), (CameraFollow=instance),...
%           (StopAfter=s), (MaxSeconds=s), (GroundExtent=extent),...
%           (Caption=caption), (GifFile=fileName), (GifEvery=n), (GifDelay=s),...
%           (Action=action), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      liveFolder: the watched folder (see fcn_AnimateCar3D_watchFolder
%      for what goes in it).
%
%      meshSet: from fcn_AnimateCar3D_loadMeshes. Mesh IDs that appear
%      later are loaded as they appear (kept in liveState.MeshSet). A mesh
%      that cannot be loaded (for example, a misspelled ID) gives a
%      warning once, and its objects are drawn as boxes of their size
%      (liveState.FailedMeshIDs lists them).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      LiveState: the output of the last call; [] (default) to start.
%
%      Steps: steps to take in this call: Inf (default) to run until done,
%      or a number (1 for one step per call).
%
%      Criteria: the display criteria to start with
%      (fcn_AnimateCar3D_fillDisplayCriteria). Default: the defaults.
%      Changed while running by the folder's displayCriteria.txt.
%
%      DefaultMeshID: the mesh of objects whose files do not say one.
%      Default: the first mesh in meshSet.
%
%      CheckInterval: seconds (clock time) between folder checks [1].
%      ForceCheck: check the folder at every step [false].
%
%      DisplayDelay: how far behind the newest data the picture stays,
%      seconds [1].
%      PlaybackSpeed: scene seconds per clock second [1].
%      ShowTime: the scene time to show at this step, in place of the
%      clock (for scripted playback and tests) [[]: from the clock]. A
%      time past the newest data read so far is not drawn.
%
%      CameraSettings: a CarMesh3D camera
%      (fcn_CarMesh3D_fillCameraSettings) [Mode='kite']; [] keeps the
%      camera as set before.
%      CameraFollow: the instance the camera follows ['ego']. If it is
%      not in the data, the camera is left as it is.
%
%      StopAfter: in run mode, stop after this many seconds (clock time)
%      with no new data, once the picture has caught up [10]. Inf keeps
%      the animation open however long no data comes (for example, field
%      data collection), until the figure is closed or MaxSeconds pass.
%      While no new data comes, the picture is not redrawn.
%      MaxSeconds: in run mode, stop after this many seconds (clock time)
%      in all [Inf].
%
%      GroundExtent: the ground drawn in an empty figure, [xmin xmax ymin
%      ymax] [[-100 500 -60 60]].
%
%      Caption: true (default) for a caption with the time shown, the
%      newest data, the number of objects, and the tiers; false for none;
%      or text (a string or a cell array of lines) added below it.
%
%      GifFile: a GIF file to save frames to ['': none]; GifEvery: save
%      every n-th drawn step [1]; GifDelay: seconds each frame shows [0.1].
%
%      Action: 'play' (default), or 'clear' to delete the drawn graphics
%      (and nothing else).
%
%      FigNum: the figure to draw in [1]. -1 skips the input checks (fast
%      mode) and draws in the current figure.
%
% OUTPUTS:
%
%      liveState: pass back on the next call. Fields:
%           Done: true when the run is over (see StopAfter, MaxSeconds;
%               also when the figure is closed), with DoneReason
%           ShowTime: the scene time last shown; LatestTime: the newest
%               data
%           Catalog, Criteria, MeshSet, WatchState, SelectorState,
%           PlayerState: the parts of the loop
%           Figure, Axes: where it draws
%           Stats: Steps (in all), StepsDrawn, Checks, CriteriaChanges,
%               the last step's NumObjects, NumNear, NumMiddle, NumFar,
%               NumPaths, and mean StepSeconds (watch to draw)
%           GifFrames: frames saved
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_watchFolder, fcn_AnimateCar3D_updateCatalog,
%      fcn_AnimateCar3D_changeDisplayCriteria,
%      fcn_AnimateCar3D_fillDisplayCriteria, fcn_AnimateCar3D_loadMeshes,
%      fcn_AnimateCar3D_getObjectState, fcn_AnimateCar3D_selectObjects,
%      fcn_AnimateCar3D_playScene; CarMesh3D: fcn_CarMesh3D_plotScene,
%      fcn_CarMesh3D_fillCameraSettings, fcn_CarMesh3D_updateCamera
%
% EXAMPLES:
%
%       meshSet = fcn_AnimateCar3D_loadMeshes({'2013_Toyota_Prius_Four','sample'});
%       fcn_AnimateCar3D_playLive('C:\simulator\output', meshSet, GifFile='run.gif');
%
%       See the script: script_test_fcn_AnimateCar3D_playLive.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_playLive
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_playLive
%   % * An optional TargetFrameRate input, to pace the run mode (it now draws as fast as it can)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    liveFolder
    meshSet
    options.LiveState = []              % from the last call; [] to start
    options.Steps = Inf                 % Inf: run until done; 1: one step
    options.Criteria = []               % display criteria to start with
    options.DefaultMeshID = ''          % '' for the first mesh in meshSet
    options.CheckInterval = 1           % seconds (clock) between folder checks
    options.ForceCheck = false          % check at every step
    options.DisplayDelay = 1            % seconds behind the newest data
    options.PlaybackSpeed = 1           % scene seconds per clock second
    options.ShowTime = []               % scene time to show now; [] from the clock
    options.CameraSettings = 'default'  % fcn_CarMesh3D_fillCameraSettings; [] keeps the camera
    options.CameraFollow = 'ego'        % instance the camera follows
    options.StopAfter = 10              % seconds (clock) with no new data; Inf keeps it open
    options.MaxSeconds = Inf            % seconds (clock) in all
    options.GroundExtent = [-100 500 -60 60]   % ground for an empty figure
    options.Caption = true              % true, false, or extra text
    options.GifFile = ''                % GIF to save frames to
    options.GifEvery = 1                % save every n-th drawn step
    options.GifDelay = 0.1              % seconds each GIF frame shows
    options.Action = 'play'             % 'play' or 'clear'
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


        % Check the liveFolder and meshSet inputs
        if ~(ischar(liveFolder) || isstring(liveFolder)) || ~isfolder(liveFolder)
            error('liveFolder must be an existing folder');
        end
        if ~(isstruct(meshSet) && isfield(meshSet,'IDs'))
            error('meshSet must come from fcn_AnimateCar3D_loadMeshes');
        end

        % Check the LiveState input
        if ~isempty(options.LiveState) && ~(isstruct(options.LiveState) && isfield(options.LiveState,'WatchState'))
            error('LiveState must come from fcn_AnimateCar3D_playLive');
        end

        % Check the numbers
        positiveNames = {'Steps','CheckInterval','PlaybackSpeed','StopAfter','MaxSeconds','GifEvery','GifDelay'};
        for ith_name = 1:numel(positiveNames)
            thisValue = options.(positiveNames{ith_name});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || thisValue<=0
                error('%s must be a positive number', positiveNames{ith_name});
            end
        end
        if ~isnumeric(options.DisplayDelay) || ~isscalar(options.DisplayDelay) || options.DisplayDelay<0
            error('DisplayDelay must be a non-negative number of seconds');
        end
        if ~isempty(options.ShowTime) && ~(isnumeric(options.ShowTime) && isscalar(options.ShowTime))
            error('ShowTime must be a time in seconds, or []');
        end
        if ~(isnumeric(options.GroundExtent) && numel(options.GroundExtent)==4)
            error('GroundExtent must be [xmin xmax ymin ymax]');
        end

        % Check the choices
        if ~any(strcmpi(options.Action, {'play','clear'}))
            error('Action must be ''play'' or ''clear''');
        end
        if ~(islogical(options.Caption) || ischar(options.Caption) || isstring(options.Caption) || iscellstr(options.Caption))
            error('Caption must be true, false, or text');
        end
        if ~(ischar(options.CameraSettings) || isstruct(options.CameraSettings) || isempty(options.CameraSettings))
            error('CameraSettings must come from fcn_CarMesh3D_fillCameraSettings, or be []');
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


liveFolder = char(liveFolder);

%%%% Clear: delete the drawn graphics
if strcmpi(options.Action,'clear')
    liveState = options.LiveState;
    if ~isempty(liveState) && ~isempty(liveState.PlayerState)
        liveState.PlayerState = fcn_AnimateCar3D_playScene([], liveState.MeshSet, PlayerState=liveState.PlayerState, Action='clear');
    end
    if ~isempty(liveState) && isgraphics(liveState.Figure)
        delete(findall(liveState.Figure, 'Tag', 'AnimateCar3D live caption'));
    end
    return;
end

%%%% Start: the state, the figure, and the scene
liveState = options.LiveState;
if isempty(liveState)
    liveState = fcn_INTERNAL_newState(liveFolder, meshSet, options);
end
if ~isempty(options.Criteria)
    if isempty(options.LiveState)
        liveState.Criteria = options.Criteria;
    end
end
cameraSettings = options.CameraSettings;
if ischar(cameraSettings) && strcmp(cameraSettings,'default')
    cameraSettings = liveState.DefaultCamera;
end
defaultMeshID = char(options.DefaultMeshID);
if isempty(defaultMeshID)
    defaultMeshID = liveState.MeshSet.IDs{1};
end

%%%% The steps
stepCount = 0;
while stepCount < options.Steps
    stepCount = stepCount + 1;
    stepTimer = tic;
    liveState.Stats.Steps = liveState.Stats.Steps + 1;
    if ~isgraphics(liveState.Figure)
        liveState = fcn_INTERNAL_finish(liveState, 'the figure was closed');
        break;
    end

    % 1, 2. Watch the folder; update the catalog and the criteria
    flagForce = options.ForceCheck || liveState.Stats.Checks==0;
    [update, liveState.WatchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=liveState.WatchState, ...
        DefaultMeshID=defaultMeshID, MinInterval=options.CheckInterval, Force=flagForce);
    if update.Checked
        liveState.Stats.Checks = liveState.Stats.Checks + 1;
        flagNewData = ~isempty(update.Add) || ~isempty(update.Remove) || update.LatestTime > liveState.LatestTime;
        if ~isempty(update.Add) || ~isempty(update.Remove)
            [liveState.Catalog, ~, liveState.SelectorState] = fcn_AnimateCar3D_updateCatalog(liveState.Catalog, ...
                Add=update.Add, Motions=update.Motions, Remove=update.Remove, SelectorState=liveState.SelectorState);
        end
        if ~isempty(update.CriteriaFile)
            liveState.Criteria = fcn_AnimateCar3D_changeDisplayCriteria(liveState.Criteria, update.CriteriaFile, OnError='warn');
            liveState.Stats.CriteriaChanges = liveState.Stats.CriteriaChanges + 1;
        end
        if isfinite(update.LatestTime)
            liveState.LatestTime = update.LatestTime;
        end
        liveState.NumObjects = update.NumInstances;
        if flagNewData
            liveState.LastDataClock = toc(liveState.StartClock);
        end
    end

    % 3. Meshes for new mesh IDs: loaded as they appear; a mesh that
    % cannot be loaded is drawn as a box (its objects' MeshID becomes 'box')
    if ~isempty(liveState.Catalog) && ~isempty(liveState.Catalog.Objects)
        catalogMeshes = unique({liveState.Catalog.Objects.MeshID});
        catalogMeshes = catalogMeshes(~cellfun(@isempty, catalogMeshes));
        newMeshes = catalogMeshes(~ismember(lower(catalogMeshes), lower([liveState.MeshSet.IDs, liveState.FailedMeshIDs])));
        for ith_mesh = 1:numel(newMeshes)
            try
                liveState.MeshSet = fcn_AnimateCar3D_loadMeshes(newMeshes(ith_mesh), MeshSet=liveState.MeshSet, FigNum=-1);
            catch loadError
                warning('AnimateCar3D:playLive:meshNotLoaded', 'Mesh ''%s'' could not be loaded (%s); its objects are drawn as boxes.', ...
                    newMeshes{ith_mesh}, loadError.message);
                liveState.FailedMeshIDs{end+1} = newMeshes{ith_mesh};
            end
        end
        if ~isempty(liveState.FailedMeshIDs)
            flagFailed = ismember(lower({liveState.Catalog.Objects.MeshID}), lower(liveState.FailedMeshIDs));
            if any(flagFailed)
                if ~any(strcmpi(liveState.MeshSet.IDs, 'box'))
                    liveState.MeshSet = fcn_AnimateCar3D_loadMeshes({'box'}, MeshSet=liveState.MeshSet, FigNum=-1);
                end
                [liveState.Catalog.Objects(flagFailed).MeshID] = deal('box');
            end
        end
    end

    % 4. The time to show: with the clock, at most DisplayDelay behind the
    % newest data (or as given)
    clockNow = toc(liveState.StartClock);
    newestShowable = liveState.LatestTime - options.DisplayDelay;
    if ~isempty(options.ShowTime)
        showTime = options.ShowTime;
    elseif isnan(liveState.ShowTime)
        showTime = newestShowable;
    else
        showTime = min(liveState.ShowTime + (clockNow - liveState.LastStepClock)*options.PlaybackSpeed, newestShowable);
        showTime = max(showTime, liveState.ShowTime);         % (never backward)
    end
    liveState.LastStepClock = clockNow;
    flagChanged = update.Checked && (flagNewData || ~isempty(update.CriteriaFile));
    flagIdle = ~flagChanged && isequal(showTime, liveState.ShowTime) && liveState.Stats.StepsDrawn > 0;
    flagDrawable = ~flagIdle && ~isempty(liveState.Catalog) && ~isempty(liveState.Catalog.Objects) && isfinite(showTime) ...
        && showTime >= liveState.Catalog.TimeStart && showTime <= liveState.LatestTime + 1e-9;

    if flagDrawable
        liveState.ShowTime = showTime;
        figure(liveState.Figure);

        % 5. The camera: follow its object, if it exists now
        if ~isempty(cameraSettings) && ~isempty(options.CameraFollow)
            followIndex = find(strcmp({liveState.Catalog.Objects.Instance}, options.CameraFollow), 1);
            if ~isempty(followIndex) && liveState.Catalog.Objects(followIndex).StartTime <= showTime ...
                    && liveState.Catalog.Objects(followIndex).EndTime >= showTime
                followState = fcn_AnimateCar3D_getObjectState(liveState.Catalog, followIndex, showTime, Detail='pose', FigNum=-1);
                fcn_CarMesh3D_updateCamera(cameraSettings, followState.Pose, Time=showTime, AxesHandle=liveState.Axes, FigNum=-1);
            end
        end

        % 6. Select and draw, with a caption
        [displayList, liveState.SelectorState] = fcn_AnimateCar3D_selectObjects(liveState.Catalog, showTime, liveState.Criteria, ...
            SelectorState=liveState.SelectorState, Camera=liveState.Axes, MeshSet=liveState.MeshSet);
        liveState.PlayerState = fcn_AnimateCar3D_playScene(displayList, liveState.MeshSet, PlayerState=liveState.PlayerState, ...
            FigNum=liveState.Figure.Number);
        selectorStats = liveState.SelectorState.Stats;
        liveState.Stats.NumNear = selectorStats.NumNear;
        liveState.Stats.NumMiddle = selectorStats.NumMiddle;
        liveState.Stats.NumFar = selectorStats.NumFar;
        liveState.Stats.NumPaths = selectorStats.NumPaths;
        liveState.Stats.NumObjects = liveState.NumObjects;
        fcn_INTERNAL_caption(liveState, options.Caption);
        drawnow;
        liveState.Stats.StepsDrawn = liveState.Stats.StepsDrawn + 1;

        % 7. A GIF frame
        if ~isempty(options.GifFile) && mod(liveState.Stats.StepsDrawn-1, options.GifEvery)==0
            liveState = fcn_INTERNAL_saveGifFrame(liveState, char(options.GifFile), options.GifDelay);
        end
    end
    liveState.Stats.StepSecondsTotal = liveState.Stats.StepSecondsTotal + toc(stepTimer);
    liveState.Stats.StepSeconds = liveState.Stats.StepSecondsTotal/liveState.Stats.Steps;

    % Done? No new data for StopAfter seconds and caught up; or too long
    clockNow = toc(liveState.StartClock);
    flagCaughtUp = ~isfinite(newestShowable) || isnan(liveState.ShowTime) || liveState.ShowTime >= newestShowable - 1e-9;
    if clockNow - liveState.LastDataClock > options.StopAfter && flagCaughtUp
        liveState = fcn_INTERNAL_finish(liveState, sprintf('no new data for %g s', options.StopAfter));
        break;
    end
    if clockNow > options.MaxSeconds
        liveState = fcn_INTERNAL_finish(liveState, sprintf('MaxSeconds (%g s) reached', options.MaxSeconds));
        break;
    end
    if ~flagDrawable && stepCount < options.Steps
        pause(0.05);                                          % (waiting for data)
    end
end

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

    % (playLive draws into its own figure; nothing more to plot)
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

%% fcn_INTERNAL_newState
function liveState = fcn_INTERNAL_newState(liveFolder, meshSet, options)
% A new live state; the figure, with a ground if it is empty
liveState = struct;
liveState.Folder = liveFolder;
liveState.Done = false;
liveState.DoneReason = '';
liveState.ShowTime = NaN;
liveState.LatestTime = -Inf;
liveState.NumObjects = 0;
liveState.Catalog = [];
liveState.Criteria = fcn_AnimateCar3D_fillDisplayCriteria();
liveState.MeshSet = meshSet;
liveState.FailedMeshIDs = {};
liveState.WatchState = [];
liveState.SelectorState = [];
liveState.PlayerState = [];
liveState.StartClock = tic;
liveState.LastDataClock = 0;
liveState.LastStepClock = 0;
liveState.DefaultCamera = fcn_CarMesh3D_fillCameraSettings(Mode='kite', FigNum=-1);
liveState.GifFrames = 0;
liveState.GifColorMap = [];
liveState.Stats = struct('Steps',0, 'StepsDrawn',0, 'Checks',0, 'CriteriaChanges',0, 'NumObjects',0, 'NumNear',0, ...
    'NumMiddle',0, 'NumFar',0, 'NumPaths',0, 'StepSeconds',0, 'StepSecondsTotal',0);

% The figure: the current one in fast mode, else FigNum
if isequal(options.FigNum, -1)
    liveState.Figure = gcf;
else
    liveState.Figure = figure(options.FigNum);
end
liveState.Axes = get(liveState.Figure, 'CurrentAxes');
if isempty(liveState.Axes)
    set(liveState.Figure, 'Color', 'w');
    fcn_CarMesh3D_plotScene(GroundExtent=options.GroundExtent, GridSpacing=10, FigNum=liveState.Figure.Number);
    liveState.Axes = get(liveState.Figure, 'CurrentAxes');
    axis(liveState.Axes, 'off');
end
set(liveState.Axes, 'Projection', 'perspective');
end % Ends fcn_INTERNAL_newState

%% fcn_INTERNAL_finish
function liveState = fcn_INTERNAL_finish(liveState, reason)
% Mark the run done
liveState.Done = true;
liveState.DoneReason = reason;
end % Ends fcn_INTERNAL_finish

%% fcn_INTERNAL_caption
function fcn_INTERNAL_caption(liveState, captionOption)
% A caption at the top of the figure: the time shown, the newest data,
% the objects, and the tiers; plus the user's text
if isequal(captionOption, false)
    return;
end
stats = liveState.Stats;
captionLines = {sprintf('showing t = %.1f s; newest data %.1f s; %d objects', liveState.ShowTime, liveState.LatestTime, ...
    stats.NumObjects), sprintf('%d near, %d middle, %d far', stats.NumNear, stats.NumMiddle, stats.NumFar)};
if ischar(captionOption) || isstring(captionOption) || iscellstr(captionOption)
    captionLines = [captionLines, cellstr(captionOption)];
end
caption = findall(liveState.Figure, 'Tag', 'AnimateCar3D live caption');
if isempty(caption)
    annotation(liveState.Figure, 'textbox', [0 0.86 1 0.14], 'String', captionLines, 'Tag', 'AnimateCar3D live caption', ...
        'EdgeColor','none', 'HorizontalAlignment','center', 'VerticalAlignment','middle', 'FontSize', 10, 'Interpreter','none');
else
    set(caption(1), 'String', captionLines);
end
end % Ends fcn_INTERNAL_caption

%% fcn_INTERNAL_saveGifFrame
function liveState = fcn_INTERNAL_saveGifFrame(liveState, gifFile, gifDelay)
% One GIF frame, with one fixed color map (from the first frame, plus a
% color cube), so small colored details keep their colors
frame = getframe(liveState.Figure);
if isempty(liveState.GifColorMap)
    [~, firstColors] = rgb2ind(frame.cdata, 40, 'nodither');
    [cubeR, cubeG, cubeB] = ndgrid(linspace(0,1,6));
    liveState.GifColorMap = [firstColors; cubeR(:) cubeG(:) cubeB(:)];
    imwrite(rgb2ind(frame.cdata, liveState.GifColorMap, 'nodither'), liveState.GifColorMap, gifFile, 'gif', ...
        'LoopCount', Inf, 'DelayTime', gifDelay);
else
    imwrite(rgb2ind(frame.cdata, liveState.GifColorMap, 'nodither'), liveState.GifColorMap, gifFile, 'gif', ...
        'WriteMode', 'append', 'DelayTime', gifDelay);
end
liveState.GifFrames = liveState.GifFrames + 1;
end % Ends fcn_INTERNAL_saveGifFrame

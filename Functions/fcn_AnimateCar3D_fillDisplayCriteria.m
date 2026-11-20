function criteria = fcn_AnimateCar3D_fillDisplayCriteria(options)
% fcn_AnimateCar3D_fillDisplayCriteria

% The display criteria: the rules the selector uses to decide which
% objects to draw, and how. The selector reads them at every step, so a
% script can change any field while an animation runs (for example, to
% widen the view or lower the counts).
%
% How each object is drawn is set by its SIZE ON SCREEN, in pixels: the
% diagonal D of its bounding box (in its own frame) as it would look from
% the camera, D x (the axes' smaller side, pixels) / (2 x distance x
% tan(view angle/2)), with the distance to the box's center:
%
%   'near'     larger than TopScreenSize: the full mesh (wheels, lights,
%              body motion); at most NearCount objects
%   'middle'   from MergeBelowSize to TopScreenSize: a reduced mesh (the
%              detail level made for its size), drawn as its own object;
%              at most MiddleCount objects
%   'far'      from MinScreenSize to MergeBelowSize: a reduced mesh (down
%              to a box), all such objects merged into ONE patch; at most
%              FarCount objects
%   (none)     smaller than MinScreenSize: not drawn
%
% Objects are placed largest on screen first; one over a count goes to
% the next tier down. Simple shapes (pedestrians, posts) are always far.
%
% The region (which objects are candidates):
%
%   'cameraView' (default)  objects inside the camera's field of view
%                (plus ViewMargin), up to MaxDistance from the camera.
%                Needs the camera (see fcn_AnimateCar3D_selectObjects);
%                without one, the selector uses a circle of radius
%                MaxDistance around Center.
%   'circle'     objects within Radius of Center.
%   'box'        objects inside a BoxSize rectangle around Center,
%                aligned with the global axes or with Center's heading.
%
% With a camera, sizes on screen are measured from the camera in any
% region. Without one ('circle' or 'box' regions), they are measured
% from Center, as if seen by a camera there with NominalScale (the
% default, 618, is an axes 450 px on its smaller side with a 40 degree
% view). Center can be:
%
%   'ego' (default)   follows the ego vehicle
%   any instance name follows that object
%   'camera'          follows the camera's target (a camera can pan a
%                     scene, with the ego passing in and out of view)
%   [x y]             fixed in the global frame
%   @(t) [x y]        moves with time (or @(t) [x y yaw], for 'box' with
%                     BoxAlign='heading')
%
% FORMAT:
%
%       criteria = fcn_AnimateCar3D_fillDisplayCriteria(...
%           (Region=region), (Center=center), (Radius=meters),...
%           (BoxSize=[length width]), (BoxAlign=align), (ViewMargin=degrees),...
%           (MaxDistance=m), (TopScreenSize=px), (MergeBelowSize=px),...
%           (MinScreenSize=px), (NominalScale=px),...
%           (NearCount=n), (MiddleCount=n), (FarCount=n),...
%           (Hysteresis=fraction), (RolesShown=roles), (AlwaysShown=roles),...
%           (AlwaysShowBranches=flag), (FixedTiers=pairs),...
%           (HideParentAtSplit=flag), (BranchAlpha=alpha),...
%           (ConfederateColor=rgb), (BranchPaths=flag), (PathRoles=roles),...
%           (PathTrail=flag), (PathPreview=kind), (TrailSeconds=s),...
%           (PreviewSeconds=s), (PathLineType=type), (PathLineWidth=pt),...
%           (PathRibbonWidth=m), (PathColorPolicy=policy), (PathColor=rgb),...
%           (PathPalette=colors), (PathColormap=colors),...
%           (PathColorLimits=[low high]), (MarkerStyles=styles),...
%           (MarkerOn=where), (FigNum=figNum))
%
% INPUTS:
%
%     (all optional, given as Name=Value pairs; defaults in brackets)
%
%      Region: 'cameraView', 'circle', or 'box' ['cameraView']
%      Center: see above ['ego']
%      Radius: for 'circle', meters [100]
%      BoxSize: for 'box', [length width] in meters [200 80]
%      BoxAlign: for 'box', 'global' or 'heading' ['global']
%      ViewMargin: for 'cameraView', degrees added around the view [5]
%
%      MaxDistance: nothing farther from the camera (or Center) is drawn,
%      except always-shown objects; it bounds the selector's search of
%      the catalog, since a bus is still a pixel at 7 km. Meters [500]
%
%      TopScreenSize: above this size on screen, near (the full mesh).
%      Pixels [105] (CarMesh3D's levels are made up to 105 px)
%      MergeBelowSize: below this size, far (merged). Pixels [37]
%      MinScreenSize: below this size, not drawn. Pixels [1]
%      NominalScale: without a camera, size on screen = D x NominalScale
%      / distance. Pixels [618]
%
%      NearCount, MiddleCount, FarCount: the most objects drawn at each
%      tier [10, 40, Inf]. Ties go to the larger object on screen,
%      whatever its role.
%
%      Hysteresis: once drawn at a tier (or a detail level), an object
%      keeps it until its size on screen passes the boundary by this
%      fraction; the same margin applies to the region. Stops objects at
%      a boundary from flickering. [0.10]
%
%      RolesShown: roles that may be drawn [all: ego, traffic,
%      confederate, pedestrian, movingItem, static]
%      AlwaysShown: roles drawn wherever they are, even outside the
%      region [{'ego','confederate'}]
%      AlwaysShowBranches: draw every branch wherever it is [true]
%      FixedTiers: N x 2 cell array of {role, tier}: roles always drawn at
%      that tier [{'ego','near'}]
%
%      HideParentAtSplit: stop drawing a parent once its first branch
%      splits off [true]
%      BranchAlpha: the opacity of branches with no alpha of their own
%      [0.35]
%      ConfederateColor: the tint of confederates with no color of their
%      own [0.85 0.15 0.10]
%
%      PATH LINES on the ground (displayList.Paths, drawn by the player).
%      A trail is where an object has been; a preview is where it will go
%      (live objects have no known future, so no preview). At a split,
%      each branch's line starts at the split point and its parent's line
%      runs up to it (always).
%      BranchPaths: when any member of a family (a parent and its
%      branches) is drawn, draw every member's path [true]
%      PathRoles: other roles whose paths are drawn while they are drawn,
%      for example {'ego','pedestrian'} [{}]
%      PathTrail: draw trails [true]
%      PathPreview: draw previews: 'none', 'thin' (half the width), or
%      'same' (as the trail) ['none']
%      TrailSeconds, PreviewSeconds: how far back a trail and how far
%      ahead a preview reach, seconds [Inf, Inf: all]
%      PathLineType: 'line' (screen lines: the same width in points at
%      any distance), 'ribbon' (strips on the ground, PathRibbonWidth
%      meters wide, shrinking with distance), or 'ribbonAndLine' (a
%      ribbon with a 1 pt line down its middle, so it never breaks up far
%      away) ['line']
%      PathLineWidth: points [2]; PathRibbonWidth: meters [0.6]
%      PathColorPolicy: the color of paths without colors of their own
%      (a motion's PathColor, which always comes first): 'object' (the
%      object's tint), 'branch' (PathPalette by branch number, so branch
%      2 of the ego and branch 2 of another vehicle match; parents as
%      'object'), 'family' (each family the color of its root object),
%      or 'fixed' (PathColor for all) ['object']
%      PathColor: the color for 'fixed', and for objects drawn in their
%      mesh's own colors (no tint) [0.3 0.3 0.3]
%      PathPalette: M x 3 colors for 'branch' [MATLAB's lines colors
%      without the yellow]. Defaults avoid white and yellow, which look
%      like lane markings.
%      PathColormap: M x 3 colors for values (a motion's PathColor given
%      as K x 1), low to high [256 colors from blue through purple to
%      red; no yellow or white, which look like lane markings]
%      PathColorLimits: [low high] values at the ends of the colormap, or
%      [] for the range of all values in the catalog's motions (fixed for
%      the whole scene, so colors do not shift as it plays) [[]]
%      MarkerStyles: a cell array of marker styles, each a cell array of
%      line property Name, Value pairs (for example {'Marker','s',
%      'MarkerSize',20, 'Color',[1 0 0]}); a motion's PathMarker values
%      index into it. A style with no 'Color' takes its path's color.
%      [{{'Marker','o','MarkerSize',6}}]
%      MarkerOn: where markers are drawn: 'trail', 'preview', or 'both'
%      ['trail']
%
%      FigNum: a figure number to plot the tiers: size on screen against
%      distance, for a car (D = 5 m) seen without a camera. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      criteria: a structure with every setting above as a field.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       criteria = fcn_AnimateCar3D_fillDisplayCriteria();          % follow the camera's view
%       criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Center=[120 0], Radius=60);
%       criteria.NearCount = 5;                                       % change while running
%       criteria.MergeBelowSize = 1e4;                                % merge everything not near
%
%       See the script: script_test_fcn_AnimateCar3D_fillDisplayCriteria.m
%       for a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillDisplayCriteria
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillDisplayCriteria
%   % * Path lines: BranchPaths, PathRoles, PathTrail, PathPreview,
%   %   % TrailSeconds, PreviewSeconds, PathLineType, PathLineWidth,
%   %   % PathRibbonWidth, PathColorPolicy, PathColor, PathPalette,
%   %   % PathColormap, PathColorLimits, MarkerStyles, MarkerOn
%   % * Tiers set by size on screen in pixels (TopScreenSize,
%   %   % MergeBelowSize, MinScreenSize, NominalScale), in place of distances
%   %   % (NearDistance, MiddleDistance, FarDistance); MaxDistance bounds the
%   %   % search. The far tier is now reduced meshes merged in one patch

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillDisplayCriteria
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    options.Region = 'cameraView'       % 'cameraView', 'circle', or 'box'
    options.Center = 'ego'              % 'ego', an instance, 'camera', [x y], or @(t)
    options.Radius = 100                % meters ('circle')
    options.BoxSize = [200 80]          % [length width] meters ('box')
    options.BoxAlign = 'global'         % 'global' or 'heading' ('box')
    options.ViewMargin = 5              % degrees ('cameraView')
    options.MaxDistance = 500           % meters
    options.TopScreenSize = 105         % pixels: above, near (full mesh)
    options.MergeBelowSize = 37         % pixels: below, far (merged)
    options.MinScreenSize = 1           % pixels: below, not drawn
    options.NominalScale = 618          % pixels: size = D x scale / distance, without a camera
    options.NearCount = 10
    options.MiddleCount = 40
    options.FarCount = Inf
    options.Hysteresis = 0.10           % fraction
    options.RolesShown = {'ego','traffic','confederate','pedestrian','movingItem','static'}
    options.AlwaysShown = {'ego','confederate'}
    options.AlwaysShowBranches = true
    options.FixedTiers = {'ego','near'}
    options.HideParentAtSplit = true
    options.BranchAlpha = 0.35
    options.ConfederateColor = [0.85 0.15 0.10]
    options.BranchPaths = true          % path lines for drawn families of branches
    options.PathRoles = {}              % other roles with path lines
    options.PathTrail = true            % draw trails
    options.PathPreview = 'none'        % 'none', 'thin', or 'same'
    options.TrailSeconds = Inf          % seconds of trail
    options.PreviewSeconds = Inf        % seconds of preview
    options.PathLineType = 'line'       % 'line', 'ribbon', or 'ribbonAndLine'
    options.PathLineWidth = 2           % points
    options.PathRibbonWidth = 0.6       % meters
    options.PathColorPolicy = 'object'  % 'object', 'branch', 'family', or 'fixed'
    options.PathColor = [0.3 0.3 0.3]   % for 'fixed', and objects with no tint
    options.PathPalette = []            % M x 3; [] for lines colors without the yellow
    options.PathColormap = []           % M x 3; [] for blue-purple-red (256)
    options.PathColorLimits = []        % [low high]; [] for the range of all values
    options.MarkerStyles = {{'Marker','o','MarkerSize',6}}   % indexed by a motion's PathMarker
    options.MarkerOn = 'trail'          % 'trail', 'preview', or 'both'
    options.FigNum = []                 % figure to sketch the criteria; -1 for fast mode
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


        % Check the region inputs
        if ~any(strcmp(options.Region, {'cameraView','circle','box'}))
            error('Region must be ''cameraView'', ''circle'', or ''box''');
        end
        center = options.Center;
        if ~(ischar(center) || isstring(center) || isa(center,'function_handle') || (isnumeric(center) && numel(center)==2))
            error('Center must be ''ego'', an instance name, ''camera'', [x y], or a function of time');
        end
        if ~any(strcmp(options.BoxAlign, {'global','heading'}))
            error('BoxAlign must be ''global'' or ''heading''');
        end
        if ~isnumeric(options.BoxSize) || numel(options.BoxSize)~=2 || any(options.BoxSize<=0)
            error('BoxSize must be [length width], positive');
        end

        % Check the numeric settings
        positiveNames = {'Radius','MaxDistance','TopScreenSize','MergeBelowSize','NominalScale'};
        for ith_name = 1:numel(positiveNames)
            thisValue = options.(positiveNames{ith_name});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || thisValue<=0
                error('%s must be a positive number', positiveNames{ith_name});
            end
        end
        countNames = {'NearCount','MiddleCount','FarCount'};
        for ith_name = 1:numel(countNames)
            thisValue = options.(countNames{ith_name});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || thisValue<0 || (isfinite(thisValue) && thisValue~=round(thisValue))
                error('%s must be a whole number (or Inf)', countNames{ith_name});
            end
        end
        if ~isnumeric(options.MinScreenSize) || ~isscalar(options.MinScreenSize) || options.MinScreenSize<0
            error('MinScreenSize must be a non-negative number');
        end
        if ~(options.TopScreenSize >= options.MergeBelowSize && options.MergeBelowSize >= options.MinScreenSize)
            error('TopScreenSize, MergeBelowSize, and MinScreenSize must not increase (top >= merge >= min)');
        end
        if ~isnumeric(options.Hysteresis) || ~isscalar(options.Hysteresis) || options.Hysteresis<0
            error('Hysteresis must be a non-negative fraction');
        end
        if ~isnumeric(options.ViewMargin) || ~isscalar(options.ViewMargin) || options.ViewMargin<0
            error('ViewMargin must be a non-negative number of degrees');
        end

        % Check the role inputs
        validRoles = {'ego','traffic','confederate','pedestrian','movingItem','static'};
        if ~all(ismember(cellstr(options.RolesShown), validRoles)) || ~all(ismember(cellstr(options.AlwaysShown), validRoles))
            error('RolesShown and AlwaysShown must hold roles from: %s', strjoin(validRoles,', '));
        end
        if ~iscell(options.FixedTiers) || (~isempty(options.FixedTiers) && (size(options.FixedTiers,2)~=2 ...
                || ~all(ismember(options.FixedTiers(:,2), {'near','middle','far'}))))
            error('FixedTiers must be an N x 2 cell array of {role, tier}, with tier ''near'', ''middle'', or ''far''');
        end

        % Check the style inputs
        if ~isnumeric(options.BranchAlpha) || ~isscalar(options.BranchAlpha) || options.BranchAlpha<0 || options.BranchAlpha>1
            error('BranchAlpha must be from 0 to 1');
        end
        if ~isnumeric(options.ConfederateColor) || numel(options.ConfederateColor)~=3
            error('ConfederateColor must be [r g b]');
        end

        % Check the path inputs
        for flagName = {'BranchPaths','PathTrail'}
            thisValue = options.(flagName{1});
            if ~(islogical(thisValue) || isnumeric(thisValue)) || ~isscalar(thisValue)
                error('%s must be true or false', flagName{1});
            end
        end
        if ~(iscellstr(options.PathRoles) || ischar(options.PathRoles) || isstring(options.PathRoles))
            error('PathRoles must be a cell array of role names');
        end
        choiceInputs = {'PathPreview', {'none','thin','same'}; 'PathLineType', {'line','ribbon','ribbonAndLine'}; ...
            'PathColorPolicy', {'object','branch','family','fixed'}; 'MarkerOn', {'trail','preview','both'}};
        for ith_choice = 1:size(choiceInputs,1)
            thisValue = options.(choiceInputs{ith_choice,1});
            if ~(ischar(thisValue) || isstring(thisValue)) || ~any(strcmpi(thisValue, choiceInputs{ith_choice,2}))
                error('%s must be one of: %s', choiceInputs{ith_choice,1}, strjoin(choiceInputs{ith_choice,2}, ', '));
            end
        end
        for secondsName = {'TrailSeconds','PreviewSeconds'}
            thisValue = options.(secondsName{1});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || thisValue<0
                error('%s must be a non-negative number (Inf for all)', secondsName{1});
            end
        end
        for widthName = {'PathLineWidth','PathRibbonWidth'}
            thisValue = options.(widthName{1});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || thisValue<=0
                error('%s must be a positive number', widthName{1});
            end
        end
        if ~isnumeric(options.PathColor) || numel(options.PathColor)~=3
            error('PathColor must be [r g b]');
        end
        for colorsName = {'PathPalette','PathColormap'}
            thisValue = options.(colorsName{1});
            if ~isempty(thisValue) && ~(isnumeric(thisValue) && size(thisValue,2)==3 && all(thisValue(:)>=0 & thisValue(:)<=1))
                error('%s must be an M x 3 array of colors from 0 to 1, or []', colorsName{1});
            end
        end
        if ~isempty(options.PathColorLimits) && ~(isnumeric(options.PathColorLimits) && numel(options.PathColorLimits)==2 ...
                && options.PathColorLimits(2) > options.PathColorLimits(1))
            error('PathColorLimits must be [low high], with high above low, or []');
        end
        fcn_INTERNAL_checkMarkerStyles(options.MarkerStyles);
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


criteria = options;
criteria = rmfield(criteria, 'FigNum');
criteria.PathRoles = cellstr(criteria.PathRoles);
criteria.BranchPaths = logical(criteria.BranchPaths);
criteria.PathTrail = logical(criteria.PathTrail);
for choiceName = {'PathPreview','PathLineType','PathColorPolicy','MarkerOn'}
    criteria.(choiceName{1}) = char(criteria.(choiceName{1}));
end
if isempty(criteria.PathPalette)
    paletteColors = lines(7);
    criteria.PathPalette = paletteColors([1 2 4 5 6 7],:);      % (without the yellow)
end
if isempty(criteria.PathColormap)
    colorStops = [0.10 0.35 0.85; 0.55 0.20 0.70; 0.85 0.15 0.10];   % blue, purple, red
    criteria.PathColormap = interp1([0 0.5 1], colorStops, linspace(0,1,256)');
end
if isstring(criteria.Center)
    criteria.Center = char(criteria.Center);
end
criteria.RolesShown = cellstr(criteria.RolesShown);
criteria.AlwaysShown = cellstr(criteria.AlwaysShown);
criteria.ConfederateColor = criteria.ConfederateColor(:)';

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

    figure(figNum);
    clf;
    hold on;
    sizeDiagonal = 5;                                  % a car
    distances = logspace(0, log10(criteria.MaxDistance), 300);
    screenSizes = sizeDiagonal*criteria.NominalScale./distances;
    bandEdges = [criteria.TopScreenSize criteria.MergeBelowSize criteria.MinScreenSize];
    bandNames = {'near: full mesh','middle: reduced, separate','far: reduced, merged'};
    bandColors = [0.85 0.2 0.1; 0.95 0.6 0.1; 0.5 0.5 0.5];
    topEdges = [max(screenSizes(1), bandEdges(1))*2, bandEdges];
    for ith_band = 1:3
        patch([1 criteria.MaxDistance criteria.MaxDistance 1], [topEdges(ith_band+1) topEdges(ith_band+1) topEdges(ith_band) topEdges(ith_band)], ...
            bandColors(ith_band,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', bandNames{ith_band});
        crossing = sizeDiagonal*criteria.NominalScale/bandEdges(ith_band);
        if crossing <= criteria.MaxDistance
            text(crossing, bandEdges(ith_band), sprintf('  %.0f px at %.0f m', bandEdges(ith_band), crossing), ...
                'VerticalAlignment', 'bottom', 'Color', 0.6*bandColors(ith_band,:));
        end
    end
    plot(distances, screenSizes, 'k-', 'LineWidth', 1.5, 'DisplayName', sprintf('a car (D = %g m)', sizeDiagonal));
    set(gca, 'XScale', 'log', 'YScale', 'log');
    xlim([1 criteria.MaxDistance]);
    ylim([max(criteria.MinScreenSize,0.5)/2, topEdges(1)]);
    grid on;
    xlabel('Distance [m]');
    ylabel('Size on screen [px]');
    legend('Location','southwest');
    title(sprintf('Display criteria (%s region): counts %g near, %g middle, %g far', criteria.Region, ...
        criteria.NearCount, criteria.MiddleCount, criteria.FarCount));
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

%% fcn_INTERNAL_checkMarkerStyles
function fcn_INTERNAL_checkMarkerStyles(markerStyles)
% Each marker style: a cell array of line property Name, Value pairs
if ~iscell(markerStyles) || isempty(markerStyles)
    error('MarkerStyles must be a cell array of styles, each a cell array of Name, Value pairs');
end
lineProperties = lower(properties('matlab.graphics.primitive.Line'));
for ith_style = 1:numel(markerStyles)
    thisStyle = markerStyles{ith_style};
    if ~iscell(thisStyle) || mod(numel(thisStyle),2)~=0 || ~all(cellfun(@(n) ischar(n) || isstring(n), thisStyle(1:2:end)))
        error('MarkerStyles{%d} must be a cell array of Name, Value pairs, for example {''Marker'',''s'',''MarkerSize'',10}', ith_style);
    end
    unknownNames = setdiff(lower(cellstr(thisStyle(1:2:end))), lineProperties);
    if ~isempty(unknownNames)
        error('MarkerStyles{%d} has a name that is not a line property: %s', ith_style, strjoin(unknownNames, ', '));
    end
end
end % Ends fcn_INTERNAL_checkMarkerStyles

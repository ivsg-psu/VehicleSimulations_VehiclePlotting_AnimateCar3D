function criteria = fcn_AnimateCar3D_fillDisplayCriteria(options)
% fcn_AnimateCar3D_fillDisplayCriteria

% The display criteria: the rules the selector uses to decide which
% objects to draw, and at which detail tier. The selector reads them at
% every step, so a script can change any field while an animation runs
% (for example, to widen the view or lower the tier counts).
%
% The region (which objects are candidates):
%
%   'cameraView' (default)  objects inside the camera's field of view
%                (plus ViewMargin), up to FarDistance from the camera.
%                Tier distances are measured from the camera, since
%                closeness to the camera is what makes an object look big.
%                Needs the camera (see fcn_AnimateCar3D_selectObjects);
%                without one, the selector uses a circle around Center.
%   'circle'     objects within Radius of Center.
%   'box'        objects inside a BoxSize rectangle around Center,
%                aligned with the global axes or with Center's heading.
%
% For 'circle' and 'box', tier distances are measured from Center:
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
%           (NearDistance=m), (NearCount=n), (MiddleDistance=m),...
%           (MiddleCount=n), (FarDistance=m), (FarCount=n),...
%           (Hysteresis=fraction), (RolesShown=roles), (AlwaysShown=roles),...
%           (AlwaysShowBranches=flag), (FixedTiers=pairs),...
%           (HideParentAtSplit=flag), (BranchAlpha=alpha),...
%           (ConfederateColor=rgb), (FigNum=figNum))
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
%      NearDistance, NearCount: the near tier (full meshes): at most
%      NearCount objects, within NearDistance meters [30, 10]
%      MiddleDistance, MiddleCount: the middle tier (low-detail meshes)
%      [70, 40]
%      FarDistance, FarCount: the far tier (boxes) [100, Inf]. Nothing
%      beyond FarDistance is drawn (except always-shown objects).
%      Ties go to the nearest object, whatever its role.
%
%      Hysteresis: once shown at a tier, an object keeps it until it is
%      beyond the tier's distance times (1 + Hysteresis); the same margin
%      applies to the region. Stops objects at a boundary from flickering
%      between tiers. [0.10]
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
%      FigNum: a figure number to sketch the region and tiers. Empty
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
    options.NearDistance = 30           % meters
    options.NearCount = 10
    options.MiddleDistance = 70         % meters
    options.MiddleCount = 40
    options.FarDistance = 100           % meters
    options.FarCount = Inf
    options.Hysteresis = 0.10           % fraction
    options.RolesShown = {'ego','traffic','confederate','pedestrian','movingItem','static'}
    options.AlwaysShown = {'ego','confederate'}
    options.AlwaysShowBranches = true
    options.FixedTiers = {'ego','near'}
    options.HideParentAtSplit = true
    options.BranchAlpha = 0.35
    options.ConfederateColor = [0.85 0.15 0.10]
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
        positiveNames = {'Radius','NearDistance','MiddleDistance','FarDistance'};
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
        if ~(options.NearDistance <= options.MiddleDistance && options.MiddleDistance <= options.FarDistance)
            error('NearDistance, MiddleDistance, and FarDistance must increase');
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
    tierDistances = [criteria.NearDistance criteria.MiddleDistance criteria.FarDistance];
    tierNames = {'near','middle','far'};
    tierColors = [0.85 0.2 0.1; 0.95 0.6 0.1; 0.5 0.5 0.5];
    angles = linspace(0, 2*pi, 181);
    switch criteria.Region
        case 'cameraView'
            halfAngle = deg2rad(30 + criteria.ViewMargin);     % a sketch: a 60 degree view
            for ith_tier = 3:-1:1
                arcAngles = linspace(-halfAngle, halfAngle, 60);
                fill([0 tierDistances(ith_tier)*cos(arcAngles) 0], [0 tierDistances(ith_tier)*sin(arcAngles) 0], ...
                    tierColors(ith_tier,:), 'FaceAlpha', 0.25, 'EdgeColor', tierColors(ith_tier,:));
            end
            plot(0, 0, 'k^', 'MarkerFaceColor', 'k');
            text(0, 0, '  camera', 'VerticalAlignment', 'top');
        case 'circle'
            for ith_tier = 3:-1:1
                radius = min(tierDistances(ith_tier), criteria.Radius);
                fill(radius*cos(angles), radius*sin(angles), tierColors(ith_tier,:), 'FaceAlpha', 0.25, 'EdgeColor', tierColors(ith_tier,:));
            end
            plot(0, 0, 'k+', 'MarkerSize', 10);
        case 'box'
            halfL = criteria.BoxSize(1)/2;
            halfW = criteria.BoxSize(2)/2;
            fill([-halfL halfL halfL -halfL], [-halfW -halfW halfW halfW], [0.5 0.5 0.5], 'FaceAlpha', 0.15);
            for ith_tier = 2:-1:1
                fill(tierDistances(ith_tier)*cos(angles), tierDistances(ith_tier)*sin(angles), tierColors(ith_tier,:), ...
                    'FaceAlpha', 0.25, 'EdgeColor', tierColors(ith_tier,:));
            end
            plot(0, 0, 'k+', 'MarkerSize', 10);
    end
    for ith_tier = 1:3
        text(tierDistances(ith_tier), 0, sprintf(' %s (%g m)', tierNames{ith_tier}, tierDistances(ith_tier)), ...
            'Color', 0.6*tierColors(ith_tier,:));
    end
    axis equal;
    grid on;
    xlabel('Distance [m]');
    title(sprintf('Display criteria: %s region (counts: %g near, %g middle, %g far)', criteria.Region, ...
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

% (none)

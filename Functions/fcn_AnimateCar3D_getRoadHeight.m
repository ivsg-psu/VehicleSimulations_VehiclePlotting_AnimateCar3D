function [zValues, sValues, tValues, roadIndex] = fcn_AnimateCar3D_getRoadHeight(road, pointsXY, options)
% fcn_AnimateCar3D_getRoadHeight

% Finds the road surface's height under XY points: each point is matched
% to the nearest place on a road's reference line (its s and t), and the
% height there is the road's elevation plus its superelevation's tilt
% (see fcn_AnimateCar3D_getRoadPoints). For a road network, the nearest
% road is used. Points off the end of a road take the height at its end.
%
% FORMAT:
%
%       [zValues, sValues, tValues, roadIndex] = fcn_AnimateCar3D_getRoadHeight(...
%           road, pointsXY, (Spacing=meters), (FigNum=figNum))
%
% INPUTS:
%
%      road: a road or a road network, from fcn_AnimateCar3D_fillRoad.
%
%      pointsXY: N x 2 points.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Spacing: meters between the reference-line samples searched (the
%      match is then refined along the line). Default 0.5.
%
%      FigNum: a figure to plot the heights along the points. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      zValues: N x 1 heights; sValues, tValues: N x 1, each point's road
%      coordinates; roadIndex: N x 1, which road of the network (1 for a
%      single road).
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_getRoadPoints
%
% EXAMPLES:
%
%       road = fcn_AnimateCar3D_fillRoad(Preset='curvy', Elevation='hilly');
%       zValues = fcn_AnimateCar3D_getRoadHeight(road, [50 -1.8; 100 0]);
%
%       See the script: script_test_fcn_AnimateCar3D_getRoadHeight.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_getRoadHeight
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_getRoadHeight
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    road
    pointsXY
    options.Spacing = 0.5         % meters between reference-line samples
    options.FigNum = []           % figure to plot the heights; -1 for fast mode
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


        % Check the inputs
        if ~(isstruct(road) && (isfield(road,'PlanView') || isfield(road,'Roads')))
            error('road must come from fcn_AnimateCar3D_fillRoad');
        end
        if ~(isnumeric(pointsXY) && size(pointsXY,2)==2)
            error('pointsXY must be N x 2 points');
        end
        if ~(isnumeric(options.Spacing) && isscalar(options.Spacing) && options.Spacing > 0)
            error('Spacing must be a positive number of meters');
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


if isfield(road, 'Roads')
    roads = road.Roads;
else
    roads = road;
end
Npoints = size(pointsXY,1);
bestDistance = Inf(Npoints,1);
sValues = zeros(Npoints,1);
tValues = zeros(Npoints,1);
roadIndex = ones(Npoints,1);
for ith_road = 1:numel(roads)
    thisRoad = roads(ith_road);
    sGrid = unique([0:options.Spacing:thisRoad.Length, thisRoad.Length])';
    reference = fcn_AnimateCar3D_getRoadPoints(thisRoad, sGrid, FigNum=-1);
    % Nearest reference sample to each point (in chunks, to bound memory)
    nearest = zeros(Npoints,1);
    distance = zeros(Npoints,1);
    chunkSize = max(1, floor(2e6/numel(sGrid)));
    for chunkStart = 1:chunkSize:Npoints
        rows = chunkStart:min(Npoints, chunkStart + chunkSize - 1);
        squaredDistance = (pointsXY(rows,1) - reference(:,1)').^2 + (pointsXY(rows,2) - reference(:,2)').^2;
        [minimum, nearest(rows)] = min(squaredDistance, [], 2);
        distance(rows) = sqrt(minimum);
    end
    % Refined: s moved along the tangent, t across
    toPoint = pointsXY - reference(nearest,1:2);
    heading = reference(nearest,3);
    sHere = min(max(sGrid(nearest) + toPoint(:,1).*cos(heading) + toPoint(:,2).*sin(heading), 0), thisRoad.Length);
    tHere = -toPoint(:,1).*sin(heading) + toPoint(:,2).*cos(heading);
    better = distance < bestDistance;
    bestDistance(better) = distance(better);
    sValues(better) = sHere(better);
    tValues(better) = tHere(better);
    roadIndex(better) = ith_road;
end

%%%% Heights at those road coordinates
zValues = zeros(Npoints,1);
for ith_road = unique(roadIndex)'
    rows = roadIndex==ith_road;
    [~, ~, zValues(rows)] = fcn_AnimateCar3D_getRoadPoints(roads(ith_road), sValues(rows), T=tValues(rows), FigNum=-1);
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

    figure(figNum);
    clf;
    scatter3(pointsXY(:,1), pointsXY(:,2), zValues, 12, zValues, 'filled');
    colormap(gca, [linspace(0.10,0.85,64)' linspace(0.35,0.15,64)' linspace(0.85,0.10,64)']);   % (blue to red)
    colorbar;
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    zlabel('Height [m]');
    title(sprintf('Road heights at %d points', Npoints));
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



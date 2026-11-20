function handles = fcn_AnimateCar3D_plotTerrain(terrain, options)
% fcn_AnimateCar3D_plotTerrain

% Draws the ground from fcn_AnimateCar3D_fillTerrain: grass on the grid
% (flat-colored quads, shaded a little so the ground does not look like
% one sheet), and its block trees. Near the road the ground is drawn on
% the full grid; farther out, on a coarser grid (every CoarseStep-th
% point), to keep the face count down. Trees on the near side of the road
% (the side of traffic in the right-hand lanes, where a following camera
% is) are drawn see-through. Everything is in at most three patches.
%
% FORMAT:
%
%       handles = fcn_AnimateCar3D_plotTerrain(terrain, (GrassColor=rgb),...
%           (NearSideAlpha=alpha), (NearDistance=meters), (CoarseStep=n),...
%           (TimeOfDay=timeOfDay), (AxesHandle=axesHandle), (FigNum=figNum))
%
% INPUTS:
%
%      terrain: from fcn_AnimateCar3D_fillTerrain.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      GrassColor: [r g b]. Default [] (the road's grass, [0.42 0.55
%      0.32]; at night, darker).
%
%      TimeOfDay: 'day' (default) or 'night' (the grass and trees darker,
%      as fcn_AnimateCar3D_plotRoad's night colors).
%
%      NearSideAlpha: the opacity of near-side trees. Default 0.3.
%
%      NearDistance: meters from the road within which the ground is
%      drawn on the full grid. Default 60; Inf for the full grid
%      everywhere.
%
%      CoarseStep: grid points per coarse cell, farther out. Default 4; 1
%      for the full grid everywhere.
%
%      AxesHandle: the axes to draw in. Default: FigNum's axes, or the
%      current axes.
%
%      FigNum: the figure to draw in. Empty (default): the current axes.
%      -1: fast mode (no input checks).
%
% OUTPUTS:
%
%      handles: Ground, Trees, SeeThrough (patch handles; empty if
%      none), Axes, NumFaces, and NumGroundFaces.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See fcn_AnimateCar3D_fillTerrain, and the script:
%       script_test_fcn_AnimateCar3D_plotTerrain.m for a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_plotTerrain
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_plotTerrain
%   % * Full grid near the road, coarse farther out (NearDistance, CoarseStep);
%   % * TimeOfDay ('night': darker grass and trees)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_plotTerrain
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    terrain
    options.GrassColor = []                  % [r g b]; [] for the road's grass (darker at night)
    options.TimeOfDay = 'day'                % 'day' or 'night'
    options.NearSideAlpha = 0.3              % opacity of near-side trees
    options.NearDistance = 60                % meters: full grid within this of the road
    options.CoarseStep = 4                   % grid points per coarse cell, farther out
    options.AxesHandle = []                  % axes to draw in
    options.FigNum = []                      % figure to draw in; -1 for fast mode
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


        % Check the terrain
        if ~(isstruct(terrain) && all(isfield(terrain, {'X','Y','Z','Distance','Shade','Trees'})))
            error('terrain must come from fcn_AnimateCar3D_fillTerrain');
        end
        if ~((ischar(options.TimeOfDay) || isstring(options.TimeOfDay)) && any(strcmpi(char(options.TimeOfDay), {'day','night'})))
            error('TimeOfDay must be ''day'' or ''night''');
        end
        if ~isempty(options.GrassColor) && ~(isnumeric(options.GrassColor) && numel(options.GrassColor)==3)
            error('GrassColor must be [r g b]');
        end
        if ~(isnumeric(options.NearDistance) && isscalar(options.NearDistance) && options.NearDistance >= 0)
            error('NearDistance must be a number, 0 or more');
        end
        if ~(isnumeric(options.CoarseStep) && isscalar(options.CoarseStep) && options.CoarseStep >= 1 && options.CoarseStep==round(options.CoarseStep))
            error('CoarseStep must be a whole number, 1 or more');
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


%%%% The axes
if ~isempty(options.FigNum) && ~isequal(options.FigNum, -1)
    figure(options.FigNum);
end
axesHandle = options.AxesHandle;
if isempty(axesHandle)
    axesHandle = gca;
end
flagNewAxes = isempty(get(axesHandle, 'Children'));
hold(axesHandle, 'on');
patchStyle = {'EdgeColor','none', 'FaceColor','flat', 'FaceLighting','flat', 'AmbientStrength',0.6, ...
    'DiffuseStrength',0.5, 'SpecularStrength',0, 'Parent',axesHandle};

%%%% The ground: full-grid quads in coarse cells near the road, one quad
%%%% per coarse cell farther out
[gridX, gridY] = meshgrid(terrain.X, terrain.Y);
[Ny, Nx] = size(gridX);
Nnodes = Ny*Nx;
nodeIndex = reshape(1:Nnodes, Ny, Nx);
step = options.CoarseStep;
coarseRows = unique([1:step:Ny, Ny]);
coarseCols = unique([1:step:Nx, Nx]);
NcoarseY = numel(coarseRows) - 1;
NcoarseX = numel(coarseCols) - 1;
% (each fine cell's coarse cell)
rowCell = repelem((1:NcoarseY)', diff(coarseRows));
colCell = repelem((1:NcoarseX)', diff(coarseCols));
% (coarse cells near the road: any of their points within NearDistance)
flagNearNode = terrain.Distance <= options.NearDistance;
nearCells = false(NcoarseY, NcoarseX);
for ith_row = 1:NcoarseY
    for jth_col = 1:NcoarseX
        block = flagNearNode(coarseRows(ith_row):coarseRows(ith_row+1), coarseCols(jth_col):coarseCols(jth_col+1));
        nearCells(ith_row, jth_col) = any(block(:));
    end
end
if step==1
    nearCells(:) = true;
end
% Fine quads
flagFine = nearCells(rowCell, colCell);
corner = nodeIndex(1:end-1, 1:end-1);
corner = corner(flagFine);
fineShade = terrain.Shade(flagFine);
faces = [corner, corner + 1, corner + Ny + 1, corner + Ny];
shades = fineShade(:);
% Coarse quads, far out
[farRow, farCol] = find(~nearCells);
coarseCorner = @(rowList, colList) nodeIndex(sub2ind([Ny Nx], rowList(:), colList(:)));
farFaces = [coarseCorner(coarseRows(farRow), coarseCols(farCol)), coarseCorner(coarseRows(farRow+1), coarseCols(farCol)), ...
            coarseCorner(coarseRows(farRow+1), coarseCols(farCol+1)), coarseCorner(coarseRows(farRow), coarseCols(farCol+1))];
farShade = terrain.Shade(sub2ind([Ny-1 Nx-1], coarseRows(farRow(:))', coarseCols(farCol(:))'));
faces = [faces; farFaces];
shades = [shades; farShade(:)];
% Coarse quads under the near cells next to far ones, lowered a little:
% they fill the hairline gaps where the two grids meet
farNeighbor = false(NcoarseY, NcoarseX);
farNeighbor(2:end,:) = farNeighbor(2:end,:) | ~nearCells(1:end-1,:);
farNeighbor(1:end-1,:) = farNeighbor(1:end-1,:) | ~nearCells(2:end,:);
farNeighbor(:,2:end) = farNeighbor(:,2:end) | ~nearCells(:,1:end-1);
farNeighbor(:,1:end-1) = farNeighbor(:,1:end-1) | ~nearCells(:,2:end);
[seamRow, seamCol] = find(nearCells & farNeighbor);
seamFaces = Nnodes + [coarseCorner(coarseRows(seamRow), coarseCols(seamCol)), coarseCorner(coarseRows(seamRow+1), coarseCols(seamCol)), ...
            coarseCorner(coarseRows(seamRow+1), coarseCols(seamCol+1)), coarseCorner(coarseRows(seamRow), coarseCols(seamCol+1))];
seamShade = terrain.Shade(sub2ind([Ny-1 Nx-1], coarseRows(seamRow(:))', coarseCols(seamCol(:))'));
faces = [faces; seamFaces];
shades = [shades; seamShade(:)];
% (only the points used)
allVertices = [gridX(:) gridY(:) terrain.Z(:); gridX(:) gridY(:) terrain.Z(:) - 0.5];
[usedPoints, ~, newIndex] = unique(faces(:));
faces = reshape(newIndex, size(faces));
flagNight = strcmpi(char(options.TimeOfDay), 'night');
nightFactor = 1;
if flagNight
    nightFactor = 0.55;
end
grassColor = options.GrassColor;
if isempty(grassColor)
    grassColor = nightFactor*[0.42 0.55 0.32];
end
grassColors = min(shades.*grassColor(:)', 1);
handles = struct('Ground',[], 'Trees',[], 'SeeThrough',[], 'Axes',axesHandle, 'NumFaces',size(faces,1), 'NumGroundFaces',size(faces,1));
handles.Ground = patch('Vertices',allVertices(usedPoints,:), 'Faces',faces, 'FaceVertexCData',grassColors, ...
    patchStyle{:}, 'Tag','AnimateCar3D terrain');

%%%% Trees: trunk and canopy boxes; near-side ones see-through
trunkColor = nightFactor*[0.40 0.28 0.18];
canopyColor = nightFactor*[0.24 0.46 0.20];
for flagNear = [false true]
    if isempty(terrain.Trees)
        break;
    end
    these = terrain.Trees([terrain.Trees.Side] < 0 == flagNear);
    if isempty(these)
        continue;
    end
    vertices = zeros(16*numel(these), 3);
    treeFaces = zeros(12*numel(these), 4);
    treeColors = zeros(12*numel(these), 3);
    boxFaces = [1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8; 5 6 7 8; 1 4 3 2];
    for ith_tree = 1:numel(these)
        tree = these(ith_tree);
        trunk = fcn_INTERNAL_box(tree.XYZ, 0.3, tree.XYZ(3), tree.XYZ(3) + 0.45*tree.Height);
        canopy = fcn_INTERNAL_box(tree.XYZ, tree.Width, tree.XYZ(3) + 0.45*tree.Height, tree.XYZ(3) + tree.Height);
        base = 16*(ith_tree-1);
        vertices(base+1:base+16,:) = [trunk; canopy];
        treeFaces(12*(ith_tree-1)+1:12*ith_tree,:) = [base + boxFaces; base + 8 + boxFaces];
        treeColors(12*(ith_tree-1)+1:12*ith_tree,:) = [repmat(trunkColor, 6, 1); repmat(canopyColor, 4, 1); 0.9*canopyColor; canopyColor];
    end
    if flagNear
        handles.SeeThrough = patch('Vertices',vertices, 'Faces',treeFaces, 'FaceVertexCData',treeColors, patchStyle{:}, ...
            'FaceAlpha',options.NearSideAlpha, 'Tag','AnimateCar3D terrain see-through');
    else
        handles.Trees = patch('Vertices',vertices, 'Faces',treeFaces, 'FaceVertexCData',treeColors, patchStyle{:}, ...
            'Tag','AnimateCar3D terrain trees');
    end
    handles.NumFaces = handles.NumFaces + size(treeFaces,1);
end
if flagNewAxes
    axis(axesHandle, 'equal');
    zlim(axesHandle, [min(terrain.Z(:)) - 1, max(terrain.Z(:)) + 30]);
    view(axesHandle, -30, 35);
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

    % (the terrain is drawn above)
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

%% fcn_INTERNAL_box
function corners = fcn_INTERNAL_box(centerXYZ, boxWidth, zLow, zHigh)
% A square box's 8 corners, axis-aligned, centered at centerXYZ(1:2)
halfWidth = boxWidth/2;
square = centerXYZ(1:2) + halfWidth*[-1 -1; 1 -1; 1 1; -1 1];
corners = [square, zLow*ones(4,1); square, zHigh*ones(4,1)];
end % Ends fcn_INTERNAL_box

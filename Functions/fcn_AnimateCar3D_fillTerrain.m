function terrain = fcn_AnimateCar3D_fillTerrain(road, options)
% fcn_AnimateCar3D_fillTerrain

% Fills the ground around a road (or road network) so that it rises and
% falls with the road: a grid of heights, held just under the road and
% its edges, and smooth everywhere else.
%
% Two shapes:
%   'fitted' - the smoothest surface that meets the road (each free grid
%              height is the average of its four neighbors, Laplace's
%              equation, with the grid's outer edges free). Far from the
%              road the ground levels out between the road's heights.
%   'mountain' - a mountain whose peak rises PeakHeight above the
%              road's highest point, beside it (far enough off it that
%              the average slope up to the peak is at most 60%, and as
%              far from the rest of the road as it can be). Its slopes
%              below the road are fitted to the road's
%              heights at each distance from the peak, then the road is
%              cut and filled into them: a smooth correction (Laplace's
%              equation again) that is zero at the grid's outer edges.
%   The default comes from the road: 'mountain' for the 'mountain'
%   preset of fcn_AnimateCar3D_fillRoad (road.TerrainShape), else
%   'fitted'.
%
% It also places block trees at random (repeatably, from Seed), kept
% clear of the road, gives the grass a smooth, gentle variation in shade,
% and records each grid point's distance to the road (so the far ground
% can be drawn coarser, see fcn_AnimateCar3D_plotTerrain).
%
% Draw it with fcn_AnimateCar3D_plotTerrain (and the road with
% fcn_AnimateCar3D_plotRoad, ShowBanks=false). A PROTOTYPE: planned to
% move to the scene-building repository.
%
% FORMAT:
%
%       terrain = fcn_AnimateCar3D_fillTerrain(road, (Margin=meters),...
%           (GridSpacing=meters), (TreesPerHectare=n), (TreeClearance=meters),...
%           (Shape=shape), (PeakHeight=meters), (Seed=seed), (FigNum=figNum))
%
% INPUTS:
%
%      road: a road or a road network, from fcn_AnimateCar3D_fillRoad.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Margin: meters of ground beyond the road's extent. Default []: the
%      road's TerrainMargin if it has one (the race course: 30), else 150.
%
%      GridSpacing: meters between grid points. Default []: the road's
%      TerrainGridSpacing if it has one (the race course: 1), else 5.
%
%      TreesPerHectare: block trees per 10,000 m^2 of ground. Default []:
%      the road's own TreesPerHectare if it has one (the race course: 0),
%      else 6;
%      0 for none.
%
%      TreeClearance: meters from the road's outer edge to the nearest
%      tree. Default 8.
%
%      Shape: 'fitted' or 'mountain' (see above). Default '': the road's
%      TerrainShape if it has one, else 'fitted'.
%
%      PeakHeight: for a 'mountain', meters from the road's highest point
%      up to the peak. Default 250.
%
%      Seed: random seed for the trees and the grass's shading. Default 1.
%
%      FigNum: a figure to draw the ground, trees, and road in. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      terrain: X (1 x Nx), Y (1 x Ny), Z (Ny x Nx) heights; Distance
%      (Ny x Nx, meters from each grid point to the nearest road edge
%      point); Shade (Ny-1 x Nx-1, the grass's brightness, smooth, from
%      0.97 to 1.03); Shape; Peak ([x y z] of a 'mountain', else []);
%      Trees (a structure array: XYZ, Height, Width, and Side: -1 on the
%      right of the nearest road, the near side, +1 on its left).
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_getRoadPoints, fcn_AnimateCar3D_getRoadHeight;
%      for the plot, fcn_AnimateCar3D_plotTerrain, fcn_AnimateCar3D_plotRoad
%
% EXAMPLES:
%
%       road = fcn_AnimateCar3D_fillRoad(Preset='mountain');
%       terrain = fcn_AnimateCar3D_fillTerrain(road);
%       fcn_AnimateCar3D_plotTerrain(terrain, FigNum=1);
%       fcn_AnimateCar3D_plotRoad(road, ShowBanks=false, FigNum=1);
%
%       See the script: script_test_fcn_AnimateCar3D_fillTerrain.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillTerrain
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillTerrain
%   % * Added the Shape option ('mountain' ground, cut and filled for the road),
%   % * the Distance output, and smooth, gentle grass shading

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillTerrain
%   % * Terrain for the race course (between road sections); more than one peak on long mountain roads



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    road
    options.Margin = []           % meters of ground beyond the road; [] for the road's TerrainMargin, else 150
    options.GridSpacing = []      % meters between grid points; [] for the road's TerrainGridSpacing, else 5
    options.TreesPerHectare = []  % block trees per 10,000 m^2; 0 for none; [] for the road's (TreesPerHectare field), else 6
    options.TreeClearance = 8     % meters from the road's outer edge
    options.Shape = ''            % 'fitted' or 'mountain'; '' for the road's TerrainShape
    options.PeakHeight = 250      % 'mountain': meters above the road's highest point
    options.Seed = 1              % random seed: trees and grass shading
    options.FigNum = []           % figure to draw in; -1 for fast mode
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


        % Check the road
        if ~(isstruct(road) && (isfield(road,'PlanView') || isfield(road,'Roads')))
            error('road must come from fcn_AnimateCar3D_fillRoad');
        end

        % Check the numbers
        numberNames = {'Margin','GridSpacing','TreeClearance','PeakHeight','Seed'};
        if ~isempty(options.TreesPerHectare) && ~(isnumeric(options.TreesPerHectare) && isscalar(options.TreesPerHectare) && options.TreesPerHectare >= 0)
            error('TreesPerHectare must be a number, 0 or more, or []');
        end
        for ith_name = 1:numel(numberNames)
            thisValue = options.(numberNames{ith_name});
            if ~(isnumeric(thisValue) && (isempty(thisValue) || isscalar(thisValue)) && all(thisValue >= 0))
                error('%s must be a number, 0 or more', numberNames{ith_name});
            end
        end
        if ~isempty(options.GridSpacing) && options.GridSpacing <= 0
            error('GridSpacing must be positive');
        end

        % Check the shape
        if ~isempty(options.Shape) && ~any(strcmp(options.Shape, {'fitted','mountain'}))
            error('Shape must be ''fitted'' or ''mountain''');
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

%%%% The roads' footprints: each road's outer edges (t on each side), by s
edgePoints = zeros(0,2);
edgeZ = zeros(0,1);
footprints = struct('S',{}, 'RightT',{}, 'LeftT',{}, 'RightXYZ',{}, 'LeftXYZ',{});
for ith_road = 1:numel(roads)
    thisRoad = roads(ith_road);
    sEdge = unique([0:2:thisRoad.Length, thisRoad.Length])';
    % (the outer edges of each lane section's outermost lanes: the lanes
    % may change from section to section)
    sectionStarts = [thisRoad.LaneSections.S];
    sectionIndex = max(sum(sEdge >= sectionStarts, 2), 1);
    rightEdge = zeros(numel(sEdge),3); rightT = zeros(numel(sEdge),1); rightZ = rightT;
    leftEdge = rightEdge; leftT = rightT; leftZ = rightT;
    for ith_section = unique(sectionIndex)'
        rows = sectionIndex==ith_section;
        section = thisRoad.LaneSections(ith_section);
        [~, rightOrder] = max(abs([section.Right.ID]));
        [~, leftOrder] = max(abs([section.Left.ID]));
        [rightEdge(rows,:), rightT(rows), rightZ(rows)] = fcn_AnimateCar3D_getRoadPoints(thisRoad, sEdge(rows), LaneID=section.Right(rightOrder).ID, LaneEdge='outer', FigNum=-1);
        [leftEdge(rows,:), leftT(rows), leftZ(rows)] = fcn_AnimateCar3D_getRoadPoints(thisRoad, sEdge(rows), LaneID=section.Left(leftOrder).ID, LaneEdge='outer', FigNum=-1);
    end
    edgePoints = [edgePoints; rightEdge(:,1:2); leftEdge(:,1:2)]; %#ok<AGROW>
    edgeZ = [edgeZ; rightZ; leftZ]; %#ok<AGROW>
    footprints(ith_road) = struct('S',sEdge, 'RightT',rightT, 'LeftT',leftT, ...
        'RightXYZ',[rightEdge(:,1:2) rightZ], 'LeftXYZ',[leftEdge(:,1:2) leftZ]);
end

%%%% The shape under the correction: none ('fitted'), or a mountain
shapeChoice = options.Shape;
if isempty(shapeChoice)
    shapeChoice = 'fitted';
    if isfield(road, 'TerrainShape') && ~isempty(road.TerrainShape)
        shapeChoice = road.TerrainShape;
    end
end
peakXYZ = [];
extentXY = edgePoints;
if strcmp(shapeChoice, 'mountain')
    peakXYZ = fcn_INTERNAL_peak(footprints, edgePoints, edgeZ, options.PeakHeight);
    extentXY = [extentXY; peakXYZ(1:2) + 0.5*options.PeakHeight*[-1 -1; 1 1]];   % (the grid reaches past the peak)
end

%%%% The grid
spacing = fcn_INTERNAL_roadDefault(options.GridSpacing, road, 'TerrainGridSpacing', 5);
margin = fcn_INTERNAL_roadDefault(options.Margin, road, 'TerrainMargin', 150);
xGrid = (floor((min(extentXY(:,1)) - margin)/spacing):ceil((max(extentXY(:,1)) + margin)/spacing))*spacing;
yGrid = (floor((min(extentXY(:,2)) - margin)/spacing):ceil((max(extentXY(:,2)) + margin)/spacing))*spacing;
[gridX, gridY] = meshgrid(xGrid, yGrid);
Nnodes = numel(gridX);

%%%% Held heights: under the road and a band around it (just below the
%%%% road's surface there, so the road always shows)
[roadZ, nodeS, nodeT, nodeRoad] = fcn_AnimateCar3D_getRoadHeight(road, [gridX(:) gridY(:)], Spacing=1, FigNum=-1);
band = 1.5*spacing;
flagHeld = false(Nnodes,1);
heldZ = zeros(Nnodes,1);
for ith_road = 1:numel(roads)
    rows = nodeRoad==ith_road;
    footprint = footprints(ith_road);
    rightT = interp1(footprint.S, footprint.RightT, nodeS(rows));
    leftT = interp1(footprint.S, footprint.LeftT, nodeS(rows));
    inside = nodeT(rows) >= rightT - band & nodeT(rows) <= leftT + band;
    % (the height at the nearest point of the road's footprint)
    clampedT = min(max(nodeT(rows), rightT), leftT);
    [~, ~, nearestZ] = fcn_AnimateCar3D_getRoadPoints(roads(ith_road), nodeS(rows), T=clampedT, FigNum=-1);
    rowIndex = find(rows);
    flagHeld(rowIndex(inside)) = true;
    heldZ(rowIndex(inside)) = nearestZ(inside) - 0.25;
end
flagHeld = flagHeld & isfinite(roadZ);

%%%% Free heights: Laplace's equation (each the average of its neighbors;
%%%% at the grid's edges, of the neighbors it has)
[Ny, Nx] = size(gridX);
nodeIndex = reshape(1:Nnodes, Ny, Nx);
rowsI = [];
colsJ = [];
values = [];
for shift = [0 1; 0 -1; 1 0; -1 0]'
    from = nodeIndex(max(1,1-shift(1)):min(Ny,Ny-shift(1)), max(1,1-shift(2)):min(Nx,Nx-shift(2)));
    to = nodeIndex(max(1,1+shift(1)):min(Ny,Ny+shift(1)), max(1,1+shift(2)):min(Nx,Nx+shift(2)));
    rowsI = [rowsI; from(:)]; %#ok<AGROW>
    colsJ = [colsJ; to(:)]; %#ok<AGROW>
    values = [values; ones(numel(from),1)]; %#ok<AGROW>
end
adjacency = sparse(rowsI, colsJ, values, Nnodes, Nnodes);
neighborCount = full(sum(adjacency, 2));
laplacian = spdiags(neighborCount, 0, Nnodes, Nnodes) - adjacency;
%%%% Each grid point's distance to the road (to its edge points)
nodeDistance = fcn_INTERNAL_nearestDistance([gridX(:) gridY(:)], edgePoints);

baseZ = zeros(Nnodes,1);
flagEdge = false(Ny, Nx);
if strcmp(shapeChoice, 'mountain')
    baseZ = fcn_INTERNAL_mountain(peakXYZ, edgePoints, edgeZ, options.PeakHeight, gridX(:), gridY(:));
    flagEdge([1 end],:) = true;
    flagEdge(:,[1 end]) = true;
end

%%%% Free heights: Laplace's equation for the correction to the shape
%%%% (held under the road; for a mountain, zero at the grid's outer edges)
flagFixed = flagHeld | (flagEdge(:) & ~flagHeld);
fixedValue = zeros(Nnodes,1);
fixedValue(flagHeld) = heldZ(flagHeld) - baseZ(flagHeld);
free = ~flagFixed;
correction = fixedValue;
if any(free) && any(flagFixed)
    correction(free) = laplacian(free, free) \ (-laplacian(free, flagFixed)*fixedValue(flagFixed));
end
gridZ = reshape(baseZ + correction, Ny, Nx);
if ~isempty(peakXYZ)
    peakXYZ(3) = interp2(gridX, gridY, gridZ, peakXYZ(1), peakXYZ(2));
end

%%%% Grass shading, and trees
randomStream = RandStream('mt19937ar', 'Seed', options.Seed + 3000);
% (smooth noise: random values blurred over about 25 m, then scaled to
% within 3% either way)
noise = randomStream.randn(Ny-1, Nx-1);
blurCells = max(1, 25/spacing);
kernel = exp(-0.5*((-ceil(2*blurCells):ceil(2*blurCells))/blurCells).^2);
kernel = kernel/sum(kernel);
noise = conv2(kernel, kernel, noise, 'same')./max(conv2(kernel, kernel, ones(Ny-1, Nx-1), 'same'), eps);
shade = 1 + 0.03*noise/max(max(abs(noise(:))), eps);
area = (xGrid(end) - xGrid(1))*(yGrid(end) - yGrid(1));
treesPerHectare = options.TreesPerHectare;
if isempty(treesPerHectare)
    treesPerHectare = 6;
    if isfield(road, 'TreesPerHectare') && ~isempty(road.TreesPerHectare)
        treesPerHectare = road.TreesPerHectare;     % (e.g. the race course: none)
    end
end
Ncandidates = round(treesPerHectare*area/1e4);
trees = struct('XYZ',{}, 'Height',{}, 'Width',{}, 'Side',{});
if Ncandidates > 0
    candidateXY = [xGrid(1) + (xGrid(end) - xGrid(1))*randomStream.rand(Ncandidates,1), ...
                   yGrid(1) + (yGrid(end) - yGrid(1))*randomStream.rand(Ncandidates,1)];
    treeHeights = 4 + 3*randomStream.rand(Ncandidates,1);
    treeWidths = 2.4 + 1.2*randomStream.rand(Ncandidates,1);
    [~, treeS, treeT, treeRoad] = fcn_AnimateCar3D_getRoadHeight(road, candidateXY, Spacing=1, FigNum=-1);
    keep = true(Ncandidates,1);
    for ith_road = 1:numel(roads)
        rows = treeRoad==ith_road;
        footprint = footprints(ith_road);
        rightT = interp1(footprint.S, footprint.RightT, treeS(rows));
        leftT = interp1(footprint.S, footprint.LeftT, treeS(rows));
        keep(rows) = treeT(rows) < rightT - options.TreeClearance | treeT(rows) > leftT + options.TreeClearance;
    end
    candidateZ = interp2(gridX, gridY, gridZ, candidateXY(:,1), candidateXY(:,2));
    for ith_tree = find(keep)'
        trees(end+1) = struct('XYZ',[candidateXY(ith_tree,:) candidateZ(ith_tree)], 'Height',treeHeights(ith_tree), ...
            'Width',treeWidths(ith_tree), 'Side',sign(treeT(ith_tree))); %#ok<AGROW>
    end
end

terrain = struct('X',xGrid, 'Y',yGrid, 'Z',gridZ, 'Distance',reshape(nodeDistance, Ny, Nx), 'Shade',shade, ...
    'Shape',shapeChoice, 'Peak',peakXYZ, 'Trees',trees);

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
    fcn_AnimateCar3D_plotTerrain(terrain, FigNum=figNum);
    fcn_AnimateCar3D_plotRoad(road, ShowBanks=false, FigNum=figNum);
    view(-35, 25);
    if ~isempty(terrain.Peak)
        plot3(terrain.Peak(1), terrain.Peak(2), terrain.Peak(3) + 1, 'k^', 'MarkerFaceColor','k');
    end
    title(sprintf('Ground (%s): %d x %d grid, %d trees', terrain.Shape, numel(terrain.X), numel(terrain.Y), numel(terrain.Trees)));
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

%% fcn_INTERNAL_roadDefault
function value = fcn_INTERNAL_roadDefault(given, road, fieldName, fallback)
% The given value; if empty, the road's own (a field of that name), else
% the fallback
value = given;
if isempty(value)
    value = fallback;
    if isfield(road, fieldName) && ~isempty(road.(fieldName))
        value = road.(fieldName);
    end
end
end % Ends fcn_INTERNAL_roadDefault

%% fcn_INTERNAL_nearestDistance
function distances = fcn_INTERNAL_nearestDistance(queryXY, pointsXY)
% Each query point's distance to the nearest of pointsXY (in chunks)
distances = zeros(size(queryXY,1),1);
chunkSize = max(1, floor(4e6/max(1,size(pointsXY,1))));
for firstRow = 1:chunkSize:size(queryXY,1)
    rows = firstRow:min(size(queryXY,1), firstRow + chunkSize - 1);
    squared = (queryXY(rows,1) - pointsXY(:,1)').^2 + (queryXY(rows,2) - pointsXY(:,2)').^2;
    distances(rows) = sqrt(min(squared, [], 2));
end
end % Ends fcn_INTERNAL_nearestDistance

%% fcn_INTERNAL_peak
function peakXYZ = fcn_INTERNAL_peak(footprints, edgePoints, edgeZ, peakHeight)
% The peak: beside the road's summit, to either side, at a few angles,
% from far enough that the average slope up to it is at most 60% to 150 m
% farther; the candidate farthest from all of the road
summitZ = -Inf;
for ith_road = 1:numel(footprints)
    middleZ = (footprints(ith_road).RightXYZ(:,3) + footprints(ith_road).LeftXYZ(:,3))/2;
    [thisMax, thisIndex] = max(middleZ);
    if thisMax > summitZ
        summitZ = thisMax;
        rightXY = footprints(ith_road).RightXYZ(thisIndex,1:2);
        leftXY = footprints(ith_road).LeftXYZ(thisIndex,1:2);
    end
end
summitXY = (rightXY + leftXY)/2;
leftward = (leftXY - rightXY)/max(norm(leftXY - rightXY), eps);
nearest = max(60, peakHeight/0.6);
candidates = zeros(0,2);
for side = [-1 1]
    for angle = [-30 0 30]*pi/180
        direction = side*leftward*[cos(angle) sin(angle); -sin(angle) cos(angle)];
        candidates = [candidates; summitXY + (nearest:10:nearest + 150)'*direction]; %#ok<AGROW>
    end
end
clearance = fcn_INTERNAL_nearestDistance(candidates, edgePoints);
[~, best] = max(clearance);
peakXYZ = [candidates(best,:), max(edgeZ) + peakHeight];
end % Ends fcn_INTERNAL_peak

%% fcn_INTERNAL_mountain
function baseZ = fcn_INTERNAL_mountain(peakXYZ, edgePoints, edgeZ, peakHeight, nodeX, nodeY)
% A mountain shape: heights that fall with distance from the peak,
% fitted to the road's heights where the road is
peakXY = peakXYZ(1:2);

%%%% The slopes: the road's heights against distance from the peak, made
%%%% to fall with distance (isotonic regression), then smoothed and
%%%% extended up to the peak and down beyond the road
roadR = hypot(edgePoints(:,1) - peakXY(1), edgePoints(:,2) - peakXY(2));
[roadR, order] = sort(roadR);
fitZ = -fcn_INTERNAL_isotonic(-(edgeZ(order) - 0.25));
nodeR = hypot(nodeX - peakXY(1), nodeY - peakXY(2));
knotR = (0:5:max([nodeR; roadR]) + 10)';
[uniqueR, firstOf] = unique(roadR);
knotZ = interp1(uniqueR, fitZ(firstOf), min(max(knotR, uniqueR(1)), uniqueR(end)));
before = knotR < uniqueR(1);
knotZ(before) = knotZ(before) + (peakXYZ(3) - knotZ(1))*(uniqueR(1) - knotR(before))/uniqueR(1);   % (up to the peak)
after = knotR > uniqueR(end);
floorZ = min(edgeZ) - max(15, 0.25*peakHeight);
knotZ(after) = max(floorZ, knotZ(after) - 0.20*(knotR(after) - uniqueR(end)));   % (down beyond the road)
knotZ = movmean(movmean(knotZ, 9), 9);                                 % (no ridges or rings)
baseZ = interp1(knotR, knotZ, nodeR, 'pchip', knotZ(end));
end % Ends fcn_INTERNAL_mountain

%% fcn_INTERNAL_isotonic
function fitted = fcn_INTERNAL_isotonic(values)
% The closest non-decreasing sequence (least squares): pool adjacent
% violators
values = values(:);
blockMean = zeros(size(values));
blockSize = zeros(size(values));
Nblocks = 0;
for ith_value = 1:numel(values)
    Nblocks = Nblocks + 1;
    blockMean(Nblocks) = values(ith_value);
    blockSize(Nblocks) = 1;
    while Nblocks > 1 && blockMean(Nblocks-1) > blockMean(Nblocks)
        pooledSize = blockSize(Nblocks-1) + blockSize(Nblocks);
        blockMean(Nblocks-1) = (blockMean(Nblocks-1)*blockSize(Nblocks-1) + blockMean(Nblocks)*blockSize(Nblocks))/pooledSize;
        blockSize(Nblocks-1) = pooledSize;
        Nblocks = Nblocks - 1;
    end
end
fitted = repelem(blockMean(1:Nblocks), blockSize(1:Nblocks));
end % Ends fcn_INTERNAL_isotonic

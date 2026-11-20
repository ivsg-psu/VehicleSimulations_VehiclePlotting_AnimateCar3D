function handles = fcn_AnimateCar3D_plotRoad(road, options)
% fcn_AnimateCar3D_plotRoad

% Draws a road, or a road network (from fcn_AnimateCar3D_fillRoad, laid
% out as ASAM OpenDRIVE roads and junctions): the lane surfaces, colored
% by lane type, with steps where heights change (curbs); the road marks
% on the lanes' outer edges (solid, broken, and double lines, white or
% yellow); junction surfaces; and the road objects (concrete barriers,
% crosswalks, stop lines, lane arrows, block trees, buildings, and
% standing pedestrians). A PROTOTYPE: planned to move to a
% scene-building repository.
%
% To stay fast in animations, everything is drawn in three patches (one
% for the surfaces, one for the marks, one for the objects), with flat
% colors and no edges. Curved roads are sampled every SampleSpacing
% meters along s.
%
% FORMAT:
%
%       handles = fcn_AnimateCar3D_plotRoad(road, (SampleSpacing=meters),...
%           (ShowObjects=flag), (ShowBanks=flag), (BuildingAlpha=alpha),...
%           (NearSideAlpha=alpha), (Colors=colors),...
%           (AxesHandle=axesHandle), (FigNum=figNum))
%
% INPUTS:
%
%      road: a road, or a road network (with Roads and Junctions), from
%      fcn_AnimateCar3D_fillRoad.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      SampleSpacing: meters between samples along the road. Default 2.
%
%      ShowObjects: draw the road's objects. Default true.
%
%      ShowBanks: on a road above or below the ground (z = 0), a grassy
%      bank from each road edge to the ground. Default true; false when
%      the ground follows the road (fcn_AnimateCar3D_fillTerrain).
%
%      BuildingAlpha: the buildings' opacity, 0 to 1. Default 1 (solid).
%      Below 1, the buildings are drawn in their own (fourth) patch, see-
%      through, so a camera behind them still sees the traffic.
%      (Transparency costs some drawing time.)
%
%      NearSideAlpha: the opacity of buildings and trees on the near side
%      (the right of the reference line: the side of traffic in the
%      right-hand lanes, where a camera following traffic is). Default
%      0.3; 1 for solid. A building is drawn at the lower of
%      BuildingAlpha and NearSideAlpha.
%
%      Colors: a structure of colors to change ([r g b], 0 to 1), by
%      name: lane types (driving, shoulder, border, median, curb,
%      walking, other), mark colors (white, yellow), and objects
%      (barrier, crosswalk, treeTrunk, treeCanopy, building). Default []
%      (the defaults).
%
%      AxesHandle: the axes to draw in. Default: FigNum's axes, or the
%      current axes.
%
%      FigNum: the figure to draw in. Empty (default): the current axes
%      (a new figure if there is none). -1 for fast mode (no input
%      checks; draws in AxesHandle or the current axes).
%
% OUTPUTS:
%
%      handles: Surface, Marks, Objects (patch handles; Objects is empty
%      if there are none), SeeThrough (the see-through buildings and
%      trees: one patch for each opacity; empty if none), Axes, and
%      NumFaces (faces drawn in all).
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_getRoadPoints
%
% EXAMPLES:
%
%       road = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet');
%       fcn_AnimateCar3D_plotRoad(road, FigNum=1);
%
%       See the script: script_test_fcn_AnimateCar3D_plotRoad.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_plotRoad
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_plotRoad
%   % * Junction surfaces and stop lines (with intersections); elevation



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    road
    options.SampleSpacing = 2      % meters between samples along the road
    options.ShowObjects = true     % draw the road's objects
    options.ShowBanks = true       % grassy banks from raised or lowered road edges to the ground (z = 0)
    options.BuildingAlpha = 1      % buildings' opacity (below 1: see-through)
    options.NearSideAlpha = 0.3    % opacity of near-side (right) buildings and trees
    options.Colors = []            % colors to change, by name
    options.AxesHandle = []        % axes to draw in
    options.FigNum = []            % figure to draw in; -1 for fast mode
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


        % Check the road input
        flagRoad = isstruct(road) && all(isfield(road, {'PlanView','LaneSections','Objects','Length'}));
        flagNetwork = isstruct(road) && all(isfield(road, {'Roads','Junctions'}));
        if ~(flagRoad || flagNetwork)
            error('road must come from fcn_AnimateCar3D_fillRoad');
        end

        % Check the options
        if ~(isnumeric(options.SampleSpacing) && isscalar(options.SampleSpacing) && options.SampleSpacing > 0)
            error('SampleSpacing must be a positive number of meters');
        end
        for alphaName = {'BuildingAlpha','NearSideAlpha'}
            alphaValue = options.(alphaName{1});
            if ~(isnumeric(alphaValue) && isscalar(alphaValue) && alphaValue >= 0 && alphaValue <= 1)
                error('%s must be from 0 to 1', alphaName{1});
            end
        end
        if ~isempty(options.Colors) && ~isstruct(options.Colors)
            error('Colors must be a structure of [r g b] colors, by name');
        end
        if ~isempty(options.AxesHandle) && ~isgraphics(options.AxesHandle, 'axes')
            error('AxesHandle must be an axes');
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


colors = fcn_INTERNAL_colors(options.Colors);
spacing = options.SampleSpacing;
if isfield(road, 'Roads')
    roads = road.Roads;                     % a road network
    junctions = road.Junctions;
else
    roads = road;
    junctions = [];
end
surface = fcn_INTERNAL_emptyMesh;
marks = fcn_INTERNAL_emptyMesh;
objects = fcn_INTERNAL_emptyMesh;
buildingAlphas = [];                        % one see-through patch per opacity
buildingMeshes = {};
for ith_road = 1:numel(roads)
    road = roads(ith_road);

    %%%% Lane surfaces, and the steps between lanes of different heights
    Nsections = numel(road.LaneSections);
    for ith_section = 1:Nsections
        section = road.LaneSections(ith_section);
        if ith_section < Nsections
            sectionEnd = road.LaneSections(ith_section+1).S;
        else
            sectionEnd = road.Length;
        end
        sSamples = fcn_INTERNAL_sectionSamples(road.PlanView, section, sectionEnd, spacing, fcn_INTERNAL_isLevel(road));
        for sideLanes = {section.Right, section.Left}
            lanes = sideLanes{1};
            if isempty(lanes)
                continue;
            end
            [~, order] = sort(abs([lanes.ID]));
            lanes = lanes(order);
            previousHeight = 0;
            for ith_lane = 1:numel(lanes)
                thisLane = lanes(ith_lane);
                laneColor = fcn_INTERNAL_laneColor(colors, thisLane.Type);
                [inner, ~, innerZ] = fcn_AnimateCar3D_getRoadPoints(road, sSamples, LaneID=thisLane.ID, LaneEdge='inner', FigNum=-1);
                [outer, ~, outerZ] = fcn_AnimateCar3D_getRoadPoints(road, sSamples, LaneID=thisLane.ID, LaneEdge='outer', FigNum=-1);
                innerPoints = [inner(:,1:2), innerZ + thisLane.Height(1)];
                outerPoints = [outer(:,1:2), outerZ + thisLane.Height(2)];
                surface = fcn_INTERNAL_addStrip(surface, innerPoints, outerPoints, laneColor);
                if abs(thisLane.Height(1) - previousHeight) > 1e-9          % a step (a curb face)
                    surface = fcn_INTERNAL_addStrip(surface, [inner(:,1:2), innerZ + previousHeight], innerPoints, laneColor);
                end
                if ith_lane==numel(lanes) && thisLane.Height(2) > 1e-9      % the outer side down to the road surface
                    surface = fcn_INTERNAL_addStrip(surface, outerPoints, [outer(:,1:2), outerZ], laneColor);
                end
                if options.ShowBanks && ith_lane==numel(lanes) && max(abs(outerZ)) > 0.01   % a grassy bank to the ground (z = 0)
                    bankWidth = max(2, 2*abs(outerZ));
                    bank = fcn_AnimateCar3D_getRoadPoints(road, sSamples, LaneID=thisLane.ID, LaneEdge='outer', ...
                        T=sign(thisLane.ID)*bankWidth, FigNum=-1);
                    surface = fcn_INTERNAL_addStrip(surface, [outer(:,1:2), outerZ], [bank(:,1:2), zeros(size(outerZ))], colors.border);
                end
                previousHeight = thisLane.Height(2);

                % The road mark on this lane's outer edge
                marks = fcn_INTERNAL_addMark(marks, road, thisLane.RoadMark, sSamples, thisLane.ID, thisLane.Height(2), colors);
            end
        end
        % The center lane's mark, on the reference line
        marks = fcn_INTERNAL_addMark(marks, road, section.Center.RoadMark, sSamples, 0, 0, colors);
    end

    %%%% Objects
    if options.ShowObjects
        for ith_object = 1:numel(road.Objects)
            thisObject = road.Objects(ith_object);
            objectAlpha = 1;
            if strcmp(thisObject.Type, 'building')
                objectAlpha = options.BuildingAlpha;
            end
            if any(strcmp(thisObject.Type, {'building','tree'})) && thisObject.T < 0
                objectAlpha = min(objectAlpha, options.NearSideAlpha);
            end
            if objectAlpha >= 1
                objects = fcn_INTERNAL_addObject(objects, road, thisObject, spacing, colors);
            else
                meshIndex = find(buildingAlphas==objectAlpha, 1);
                if isempty(meshIndex)
                    buildingAlphas(end+1) = objectAlpha; %#ok<AGROW>
                    buildingMeshes{end+1} = fcn_INTERNAL_emptyMesh; %#ok<AGROW>
                    meshIndex = numel(buildingAlphas);
                end
                buildingMeshes{meshIndex} = fcn_INTERNAL_addObject(buildingMeshes{meshIndex}, road, thisObject, spacing, colors);
            end
        end
    end

end % (each road)

%%%% Junctions: flat surfaces, and curb faces
for ith_junction = 1:numel(junctions)
    surface = fcn_INTERNAL_addJunction(surface, junctions(ith_junction), colors);
end

%%%% Draw: three patches
if isequal(options.FigNum, -1) || isempty(options.FigNum)
    axesHandle = options.AxesHandle;
    if isempty(axesHandle)
        axesHandle = gca;
    end
else
    figure(options.FigNum);
    axesHandle = options.AxesHandle;
    if isempty(axesHandle)
        axesHandle = gca;
    end
end
flagNewAxes = isempty(get(axesHandle, 'Children'));
hold(axesHandle, 'on');
patchStyle = {'EdgeColor','none', 'FaceColor','flat', 'FaceLighting','flat', 'AmbientStrength',0.6, ...
    'DiffuseStrength',0.5, 'SpecularStrength',0, 'Parent',axesHandle};
handles = struct('Surface',[], 'Marks',[], 'Objects',[], 'SeeThrough',[], 'Axes',axesHandle, 'NumFaces',0);
handles.Surface = patch('Vertices',surface.Vertices, 'Faces',surface.Faces, 'FaceVertexCData',surface.Colors, ...
    patchStyle{:}, 'Tag','AnimateCar3D road surface');
handles.Marks = patch('Vertices',marks.Vertices, 'Faces',marks.Faces, 'FaceVertexCData',marks.Colors, ...
    patchStyle{:}, 'Tag','AnimateCar3D road marks');
if ~isempty(objects.Faces)
    handles.Objects = patch('Vertices',objects.Vertices, 'Faces',objects.Faces, 'FaceVertexCData',objects.Colors, ...
        patchStyle{:}, 'Tag','AnimateCar3D road objects');
end
handles.SeeThrough = gobjects(0);
buildingHeights = 0;
for ith_mesh = 1:numel(buildingMeshes)
    thisMesh = buildingMeshes{ith_mesh};
    handles.SeeThrough(end+1) = patch('Vertices',thisMesh.Vertices, 'Faces',thisMesh.Faces, 'FaceVertexCData',thisMesh.Colors, ...
        patchStyle{:}, 'FaceAlpha',buildingAlphas(ith_mesh), 'Tag','AnimateCar3D road see-through');
    handles.NumFaces = handles.NumFaces + size(thisMesh.Faces,1);
    buildingHeights = max([buildingHeights; thisMesh.Vertices(:,3)]);
end
handles.NumFaces = handles.NumFaces + size(surface.Faces,1) + size(marks.Faces,1) + size(objects.Faces,1);
if flagNewAxes
    % (Heights from below the road to 10 m or more, so a camera above a
    % flat road is inside the axes and the road is not clipped away)
    axis(axesHandle, 'equal');
    zlim(axesHandle, [min([-0.5; surface.Vertices(:,3) - 0.5]), max([10; surface.Vertices(:,3) + 10; objects.Vertices(:,3) + 2; buildingHeights + 2])]);
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

    % (the road is drawn above, in figure FigNum)
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

%% fcn_INTERNAL_colors
function colors = fcn_INTERNAL_colors(userColors)
% Default colors (no white or yellow except the marks and crosswalks),
% then the user's changes
colors = struct('driving',[0.33 0.33 0.34], 'shoulder',[0.46 0.46 0.45], 'border',[0.42 0.55 0.32], ...
    'median',[0.46 0.46 0.45], 'curb',[0.70 0.70 0.68], 'walking',[0.74 0.73 0.70], 'other',[0.40 0.40 0.40], ...
    'white',[0.96 0.96 0.94], 'yellow',[0.96 0.76 0.12], 'barrier',[0.72 0.71 0.68], 'crosswalk',[0.96 0.96 0.94], ...
    'treeTrunk',[0.40 0.28 0.18], 'treeCanopy',[0.24 0.46 0.20], 'building',[0.70 0.67 0.60]);
if ~isempty(userColors)
    userNames = fieldnames(userColors);
    for ith_name = 1:numel(userNames)
        if ~isfield(colors, userNames{ith_name})
            error('Colors has no color named ''%s''', userNames{ith_name});
        end
        colors.(userNames{ith_name}) = userColors.(userNames{ith_name});
    end
end
end % Ends fcn_INTERNAL_colors

%% fcn_INTERNAL_laneColor
function laneColor = fcn_INTERNAL_laneColor(colors, laneType)
% The color of a lane type
if isfield(colors, laneType)
    laneColor = colors.(laneType);
else
    laneColor = colors.other;
end
end % Ends fcn_INTERNAL_laneColor

%% fcn_INTERNAL_samples
function sSamples = fcn_INTERNAL_samples(sStart, sEnd, spacing, breakpoints)
% Samples along s, every spacing meters, with the ends and the geometry
% starts in between
breakpoints = breakpoints(breakpoints > sStart & breakpoints < sEnd);
sSamples = unique([sStart:spacing:sEnd, sEnd, breakpoints(:)'])';
end % Ends fcn_INTERNAL_samples

%% fcn_INTERNAL_isLevel
function flagLevel = fcn_INTERNAL_isLevel(road)
% True if the road's elevation and superelevation do not change along s
flagLevel = true;
recordSets = {};
if isfield(road, 'ElevationProfile')
    recordSets{end+1} = road.ElevationProfile;
end
if isfield(road, 'LateralProfile') && isstruct(road.LateralProfile) && isfield(road.LateralProfile, 'Superelevation')
    recordSets{end+1} = road.LateralProfile.Superelevation;
end
for ith_set = 1:numel(recordSets)
    records = recordSets{ith_set};
    if ~isempty(records) && (numel(records) > 1 || any([records.B, records.C, records.D]~=0))
        flagLevel = false;
    end
end
end % Ends fcn_INTERNAL_isLevel

%% fcn_INTERNAL_sectionSamples
function sSamples = fcn_INTERNAL_sectionSamples(planView, section, sectionEnd, spacing, flagLevel)
% Samples along a lane section: every spacing meters on curves, and only
% every 50 m on straight lines when every lane's width is constant and
% the road's heights are level (a straight, level strip needs no more),
% so straight roads stay sparse
allLanes = [section.Left(:); section.Right(:)];
flagConstantWidths = flagLevel && (isempty(allLanes) || all(arrayfun(@(lane) all(lane.Width(2:4)==0), allLanes)));
sSamples = [section.S; sectionEnd];
for ith_geometry = 1:numel(planView)
    geometryStart = max(planView(ith_geometry).S, section.S);
    geometryEnd = min(planView(ith_geometry).S + planView(ith_geometry).Length, sectionEnd);
    if geometryEnd <= geometryStart
        continue;
    end
    thisSpacing = spacing;
    if strcmp(planView(ith_geometry).Type, 'line') && flagConstantWidths
        thisSpacing = max(spacing, 50);
    end
    sSamples = [sSamples; fcn_INTERNAL_samples(geometryStart, geometryEnd, thisSpacing, [])]; %#ok<AGROW>
end
sSamples = unique(sSamples);
end % Ends fcn_INTERNAL_sectionSamples

%% fcn_INTERNAL_emptyMesh
function mesh = fcn_INTERNAL_emptyMesh
% An empty list of quads, with a color for each
mesh = struct('Vertices',zeros(0,3), 'Faces',zeros(0,4), 'Colors',zeros(0,3));
end % Ends fcn_INTERNAL_emptyMesh

%% fcn_INTERNAL_joinFaces
function faces = fcn_INTERNAL_joinFaces(faces, newFaces)
% Stack face lists of different widths, padding with NaN
Ncolumns = max(size(faces,2), size(newFaces,2));
faces = [faces, NaN(size(faces,1), Ncolumns - size(faces,2)); newFaces, NaN(size(newFaces,1), Ncolumns - size(newFaces,2))];
end % Ends fcn_INTERNAL_joinFaces

%% fcn_INTERNAL_addQuads
function mesh = fcn_INTERNAL_addQuads(mesh, quadCorners, zValue, faceColor)
% Flat quadrilaterals (each 4 x 2 corners, in a cell array) at height zValue
for ith_quad = 1:numel(quadCorners)
    base = size(mesh.Vertices,1);
    mesh.Vertices = [mesh.Vertices; quadCorners{ith_quad}, zValue*ones(4,1)];
    mesh.Faces = fcn_INTERNAL_joinFaces(mesh.Faces, base + (1:4));
    mesh.Colors = [mesh.Colors; faceColor];
end
end % Ends fcn_INTERNAL_addQuads

%% fcn_INTERNAL_addJunction
function mesh = fcn_INTERNAL_addJunction(mesh, junction, colors)
% A junction's flat surfaces (by type) and its curb faces
for ith_surface = 1:numel(junction.Surfaces)
    thisSurface = junction.Surfaces(ith_surface);
    mesh = fcn_INTERNAL_addQuads(mesh, {thisSurface.Corners}, thisSurface.Height, fcn_INTERNAL_laneColor(colors, thisSurface.Type));
end
for ith_face = 1:numel(junction.CurbFaces)
    ends = junction.CurbFaces(ith_face).Ends;
    mesh = fcn_INTERNAL_addStrip(mesh, [ends, zeros(2,1)], [ends, junction.CurbFaces(ith_face).Height*ones(2,1)], colors.curb);
end
end % Ends fcn_INTERNAL_addJunction

%% fcn_INTERNAL_arrowQuads
function quads = fcn_INTERNAL_arrowQuads(arrowName)
% A lane arrow, 5 m long, as quadrilaterals in (u along the direction of
% travel, v to its left), centered on u = 0
shaft = @(uEnd) [-2.5 -0.075; uEnd -0.075; uEnd 0.075; -2.5 0.075];
straightHead = [1.2 -0.35; 2.5 0; 2.5 0; 1.2 0.35];
turnArm = [0.45 0; 0.75 0; 0.75 0.6; 0.45 0.6];
turnHead = [0.25 0.6; 0.95 0.6; 0.6 1.2; 0.6 1.2];
mirror = @(quad) quad.*[1 -1];
switch arrowName
    case 'straight'
        quads = {shaft(1.2), straightHead};
    case 'left'
        quads = {shaft(0.75), turnArm, turnHead};
    case 'right'
        quads = {shaft(0.75), mirror(turnArm), mirror(turnHead)};
    case 'straightRight'
        quads = {shaft(1.2), straightHead, mirror(turnArm), mirror(turnHead)};
    case 'straightLeft'
        quads = {shaft(1.2), straightHead, turnArm, turnHead};
    otherwise
        error('Arrow ''%s'' is not known', arrowName);
end
end % Ends fcn_INTERNAL_arrowQuads

%% fcn_INTERNAL_addStrip
function mesh = fcn_INTERNAL_addStrip(mesh, firstPoints, secondPoints, faceColor)
% Quads between two rows of N points
Npoints = size(firstPoints,1);
if Npoints < 2
    return;
end
base = size(mesh.Vertices,1);
k = (1:Npoints-1)';
faces = base + [k, k+1, Npoints+k+1, Npoints+k];
mesh.Vertices = [mesh.Vertices; firstPoints; secondPoints];
mesh.Faces = fcn_INTERNAL_joinFaces(mesh.Faces, faces);
mesh.Colors = [mesh.Colors; repmat(faceColor, Npoints-1, 1)];
end % Ends fcn_INTERNAL_addStrip

%% fcn_INTERNAL_addMark
function mesh = fcn_INTERNAL_addMark(mesh, road, roadMark, sSamples, laneID, surfaceHeight, colors)
% A road mark along a lane's outer edge (or the reference line): one or
% two lines, solid or broken; in a double mark, the first is on the left
lineTypes = split(string(roadMark.Type), ' ')';
if isempty(lineTypes) || strcmp(lineTypes(1), "none")
    return;
end
markColor = colors.white;
if strcmpi(roadMark.Color, 'yellow')
    markColor = colors.yellow;
end
markWidth = roadMark.Width;
if numel(lineTypes)==1
    lineOffsets = 0;
else
    lineOffsets = [1 -1]*markWidth;              % (a gap of one line width)
end
zMark = surfaceHeight + 0.02;                   % (above the road surface's height)
for ith_line = 1:numel(lineTypes)
    if strcmp(lineTypes(ith_line), "broken")
        period = roadMark.LineLength + roadMark.LineSpace;
        dashStarts = sSamples(1):period:sSamples(end);
        pieces = cell(1, numel(dashStarts));
        for ith_dash = 1:numel(dashStarts)
            dashEnd = min(dashStarts(ith_dash) + roadMark.LineLength, sSamples(end));
            inside = sSamples(sSamples > dashStarts(ith_dash) & sSamples < dashEnd);
            pieces{ith_dash} = unique([dashStarts(ith_dash); inside(:); dashEnd]);
        end
    else
        pieces = {sSamples};
    end
    for ith_piece = 1:numel(pieces)
        sPiece = pieces{ith_piece};
        if numel(sPiece) < 2
            continue;
        end
        [leftEdge, leftZ] = fcn_INTERNAL_markEdge(road, sPiece, laneID, lineOffsets(ith_line) + markWidth/2);
        [rightEdge, rightZ] = fcn_INTERNAL_markEdge(road, sPiece, laneID, lineOffsets(ith_line) - markWidth/2);
        mesh = fcn_INTERNAL_addStrip(mesh, [rightEdge(:,1:2), rightZ + zMark], [leftEdge(:,1:2), leftZ + zMark], markColor);
    end
end
end % Ends fcn_INTERNAL_addMark

%% fcn_INTERNAL_markEdge
function [points, zValues] = fcn_INTERNAL_markEdge(road, sValues, laneID, tOffset)
% Points offset from a lane's outer edge (or from the reference line),
% and the road surface's height there
if laneID==0
    [points, ~, zValues] = fcn_AnimateCar3D_getRoadPoints(road, sValues, T=tOffset, FigNum=-1);
else
    [points, ~, zValues] = fcn_AnimateCar3D_getRoadPoints(road, sValues, LaneID=laneID, LaneEdge='outer', T=tOffset, FigNum=-1);
end
end % Ends fcn_INTERNAL_markEdge

%% fcn_INTERNAL_addBox
function mesh = fcn_INTERNAL_addBox(mesh, center, heading, boxLength, boxWidth, zLow, zHigh, faceColor, topColor)
% A box: center [x y], turned by heading, from zLow to zHigh
along = [cos(heading) sin(heading)]*boxLength/2;
across = [-sin(heading) cos(heading)]*boxWidth/2;
corners = [center - along - across; center + along - across; center + along + across; center - along + across];
vertices = [corners, zLow*ones(4,1); corners, zHigh*ones(4,1)];
faces = [1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8; 5 6 7 8; 1 4 3 2];
base = size(mesh.Vertices,1);
mesh.Vertices = [mesh.Vertices; vertices];
mesh.Faces = fcn_INTERNAL_joinFaces(mesh.Faces, base + faces);
mesh.Colors = [mesh.Colors; repmat(faceColor, 4, 1); topColor; faceColor];
end % Ends fcn_INTERNAL_addBox

%% fcn_INTERNAL_addObject
function mesh = fcn_INTERNAL_addObject(mesh, road, object, spacing, colors)
% One road object. S and T place its center; an object with Repeat true
% runs along the road from S for Length (as OpenDRIVE's <repeat>).
objectColor = object.Color;
switch object.Type
    case 'barrier'
        % A concrete (Jersey) barrier: its profile swept along the road
        if isempty(objectColor), objectColor = colors.barrier; end
        profile = [-0.50 0; -0.50 0.10; -0.33 0.41; -0.125 1; 0.125 1; 0.33 0.41; 0.50 0.10; 0.50 0];
        profile = profile .* [object.Width object.Height];
        sFrom = object.S;
        if ~object.Repeat
            sFrom = object.S - object.Length/2;
        end
        sSamples = fcn_INTERNAL_samples(max(sFrom, 0), min(sFrom + object.Length, road.Length), spacing, [road.PlanView.S]);
        Nsamples = numel(sSamples);
        rows = cell(1, size(profile,1));
        for ith_point = 1:size(profile,1)
            [points, ~, roadZ] = fcn_AnimateCar3D_getRoadPoints(road, sSamples, T=object.T + profile(ith_point,1), FigNum=-1);
            rows{ith_point} = [points(:,1:2), roadZ + object.ZOffset + profile(ith_point,2)];
        end
        for ith_point = 1:size(profile,1)-1
            mesh = fcn_INTERNAL_addStrip(mesh, rows{ith_point+1}, rows{ith_point}, objectColor);
        end
        for endRow = [1 Nsamples]                        % end caps (two quads each)
            capPoints = cellfun(@(row) row(endRow,:), rows, 'UniformOutput', false);
            capPoints = vertcat(capPoints{:});
            base = size(mesh.Vertices,1);
            mesh.Vertices = [mesh.Vertices; capPoints];
            mesh.Faces = fcn_INTERNAL_joinFaces(mesh.Faces, base + [1 2 7 8; 2 3 6 7; 3 4 5 6]);
            mesh.Colors = [mesh.Colors; repmat(objectColor, 3, 1)];
        end
    case 'crosswalk'
        % Continental stripes: bars along the road, 0.6 m wide, 0.6 m apart
        if isempty(objectColor), objectColor = colors.crosswalk; end
        stripeStarts = (object.T - object.Width/2):1.2:(object.T + object.Width/2 - 0.6 + 1e-9);
        sEnds = object.S + [-1 1]*object.Length/2;
        for tStripe = stripeStarts
            [edgeA, ~, zA] = fcn_AnimateCar3D_getRoadPoints(road, sEnds', T=tStripe, FigNum=-1);
            [edgeB, ~, zB] = fcn_AnimateCar3D_getRoadPoints(road, sEnds', T=tStripe + 0.6, FigNum=-1);
            mesh = fcn_INTERNAL_addStrip(mesh, [edgeA(:,1:2), zA + 0.025], [edgeB(:,1:2), zB + 0.025], objectColor);
        end
    case 'stopLine'
        % A flat white bar across the lanes
        sEnds = object.S + [-1 1]*object.Length/2;
        [edgeA, ~, zA] = fcn_AnimateCar3D_getRoadPoints(road, sEnds', T=object.T - object.Width/2, FigNum=-1);
        [edgeB, ~, zB] = fcn_AnimateCar3D_getRoadPoints(road, sEnds', T=object.T + object.Width/2, FigNum=-1);
        mesh = fcn_INTERNAL_addStrip(mesh, [edgeA(:,1:2), zA + 0.025], [edgeB(:,1:2), zB + 0.025], colors.white);
    case 'arrow'
        % A lane arrow, turned to the direction of travel (the road's
        % heading plus Hdg), scaled to Length
        [place, ~, placeZ] = fcn_AnimateCar3D_getRoadPoints(road, object.S, T=object.T, FigNum=-1);
        heading = place(3) + object.Hdg;
        along = [cos(heading) sin(heading)];
        left = [-sin(heading) cos(heading)];
        quads = fcn_INTERNAL_arrowQuads(object.Name);
        for ith_quad = 1:numel(quads)
            uv = quads{ith_quad}.*[object.Length/5 1];
            quads{ith_quad} = place(1:2) + uv(:,1)*along + uv(:,2)*left;
        end
        mesh = fcn_INTERNAL_addQuads(mesh, quads, placeZ + 0.02, colors.white);
    case 'pedestrian'
        % A standing person (the simple 'pedestrian' shape), facing Hdg
        shape = fcn_AnimateCar3D_fillSimpleShape('pedestrian', FigNum=-1);
        [place, ~, placeZ] = fcn_AnimateCar3D_getRoadPoints(road, object.S, T=object.T, FigNum=-1);
        heading = place(3) + object.Hdg;
        zBase = placeZ + object.ZOffset + fcn_INTERNAL_heightAt(road, object.S, object.T);
        local = shape.Vertices.*[object.Length object.Width object.Height];
        vertices = [place(1) + local(:,1)*cos(heading) - local(:,2)*sin(heading), ...
                    place(2) + local(:,1)*sin(heading) + local(:,2)*cos(heading), zBase + local(:,3)];
        if isempty(objectColor), objectColor = [0.30 0.35 0.50]; end
        faceColors = shape.FaceColor;
        flagOwnColor = any(isnan(faceColors), 2);
        faceColors(flagOwnColor,:) = repmat(objectColor, sum(flagOwnColor), 1);
        faceColors = min(faceColors.*shape.FaceShade, 1);
        base = size(mesh.Vertices,1);
        mesh.Vertices = [mesh.Vertices; vertices];
        mesh.Faces = fcn_INTERNAL_joinFaces(mesh.Faces, base + shape.Faces);
        mesh.Colors = [mesh.Colors; faceColors];
    case 'tree'
        % A block tree: a trunk, and a canopy from 45% of its height up
        [place, ~, placeZ] = fcn_AnimateCar3D_getRoadPoints(road, object.S, T=object.T, FigNum=-1);
        canopyColor = colors.treeCanopy;
        if ~isempty(objectColor), canopyColor = objectColor; end
        zBase = placeZ + object.ZOffset + fcn_INTERNAL_heightAt(road, object.S, object.T);
        mesh = fcn_INTERNAL_addBox(mesh, place(1:2), place(3) + object.Hdg, 0.3, 0.3, zBase, zBase + 0.45*object.Height, ...
            colors.treeTrunk, colors.treeTrunk);
        mesh = fcn_INTERNAL_addBox(mesh, place(1:2), place(3) + object.Hdg, object.Length, object.Width, ...
            zBase + 0.45*object.Height, zBase + object.Height, canopyColor, 0.9*canopyColor);
    otherwise
        % A building, or any other object: a box
        if isempty(objectColor), objectColor = colors.building; end
        [place, ~, placeZ] = fcn_AnimateCar3D_getRoadPoints(road, object.S, T=object.T, FigNum=-1);
        zBase = placeZ + object.ZOffset + fcn_INTERNAL_heightAt(road, object.S, object.T);
        mesh = fcn_INTERNAL_addBox(mesh, place(1:2), place(3) + object.Hdg, object.Length, object.Width, ...
            zBase, zBase + object.Height, objectColor, 0.8*objectColor);
end
end % Ends fcn_INTERNAL_addObject

%% fcn_INTERNAL_heightAt
function height = fcn_INTERNAL_heightAt(road, sValue, tValue)
% The surface height of the lane at (s, t); 0 off the road
height = 0;
sectionIndex = max(sum(sValue >= [road.LaneSections.S]), 1);
section = road.LaneSections(sectionIndex);
if tValue < 0
    lanes = section.Right;
else
    lanes = section.Left;
end
for ith_lane = 1:numel(lanes)
    [~, innerT] = fcn_AnimateCar3D_getRoadPoints(road, sValue, LaneID=lanes(ith_lane).ID, LaneEdge='inner', FigNum=-1);
    [~, outerT] = fcn_AnimateCar3D_getRoadPoints(road, sValue, LaneID=lanes(ith_lane).ID, LaneEdge='outer', FigNum=-1);
    if (tValue - innerT)*(tValue - outerT) <= 0
        height = mean(lanes(ith_lane).Height);
        return;
    end
end
end % Ends fcn_INTERNAL_heightAt

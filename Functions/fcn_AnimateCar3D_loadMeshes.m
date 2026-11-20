function meshSet = fcn_AnimateCar3D_loadMeshes(meshIDs, options)
% fcn_AnimateCar3D_loadMeshes

% Loads the vehicle meshes a scene needs, once, before animating. Each
% vehicle is kept as its full mesh and its ladder of detail levels from
% CarMesh3D (fcn_CarMesh3D_loadDetailLevels), with the sizes the
% selector needs to work out how big it is on screen:
%
%   Full     the finished CarMesh3D mesh (drawn while the vehicle is
%            larger than TopScreenSize on screen: wheels, lights, body
%            motion)
%   Levels   reduced meshes, each made for a largest size on screen
%            (MaxScreenSize, pixels), from finest to coarsest; the last
%            is a box
%
% A vehicle with no levels file has its levels made here (a few
% seconds; CarMesh3D warns, CarMesh3D:detailLevelsMade). Save them with
% the vehicle by running its CarMesh3D vehicle script, Step 6b.
%
% The sample car has no vehicle folder, so its mesh and levels are made
% once and kept in a cache file in MATLAB's temporary folder
% (AnimateCar3D_sampleMeshCache.mat), named by the CarMesh3D copy in use.
% The cache is used while its CarMesh3D copy, levels format, and levels
% maker match; otherwise it is made again.
%
% Meshes are named by their CarMesh3D vehicle ID (the Data folder name,
% YEAR_Make_Model_Trimline), 'sample' for CarMesh3D's built-in sample
% car scaled to a generic sedan, or a simple shape: 'box', 'bar',
% 'cylinder', or 'pedestrian' (see fcn_AnimateCar3D_fillSimpleShape), for
% static objects, pedestrians, moving items, and vehicles known only by
% their size. Simple shapes have no levels: they are always drawn merged
% (all in one patch), sized by their display list Size (or their default
% size).
%
% While a live animation runs, new mesh IDs can appear: give the mesh
% set already loaded as MeshSet, and only the new meshes are loaded.
%
% FORMAT:
%
%       meshSet = fcn_AnimateCar3D_loadMeshes(meshIDs,...
%           (MeshSet=meshSet), (SampleCacheFile=file), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      meshIDs: a vehicle ID, or a cell array of them. Each must be a
%      vehicle in the CarMesh3D Data folder with a finished mesh
%      (vehicleMesh_<ID>.mat), 'sample', or a simple shape name.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      MeshSet: a mesh set from an earlier call. The new IDs are added to
%      it; IDs it already has are not loaded again. Default [].
%
%      SampleCacheFile: the sample car's cache file. Default
%      fullfile(tempdir, 'AnimateCar3D_sampleMeshCache.mat'); '' for no
%      cache (made every time).
%
%      FigNum: a figure number to show each vehicle's full mesh and its
%      levels. Empty (default) for no figure; -1 for fast mode (no input
%      checks).
%
% OUTPUTS:
%
%      meshSet: a structure with one field per mesh. The field name is
%      the ID made into a valid MATLAB name with
%      matlab.lang.makeValidName (for example, x2013_Toyota_Prius_Four),
%      and each field holds:
%           ID: the vehicle ID
%           Full: the finished mesh ([] for a simple shape)
%           Levels: the detail levels (from CarMesh3D), a structure array
%               with fields MaxScreenSize, Faces, IsBox, and Mesh ([] for
%               the box); 0 x 1 for a simple shape
%           Size: [length width height] in meters
%           RearOverhang: rear axle to rear bumper, in meters (places the
%               box: the vehicle origin is on the ground below the rear
%               axle)
%           SizeDiagonal: D, the diagonal of the bounding box in the
%               object's own frame, meters (the size-on-screen standard)
%           BoxCenter: the center of that box in the object's own frame
%               (distances on screen are measured to it)
%           TopScreenSize: the largest size on screen the levels were
%               made for (above it, the full mesh is drawn)
%           FullFaces: the full mesh's face count; LevelFaces: each
%               level's
%           Shape: for a simple shape, the shape (from
%               fcn_AnimateCar3D_fillSimpleShape); [] for a vehicle
%      meshSet.IDs lists the IDs in the order given (simple shape names
%      in lower case).
%
% DEPENDENCIES:
%
%      CarMesh3D: fcn_CarMesh3D_findVehicleFiles,
%      fcn_CarMesh3D_loadDetailLevels, fcn_CarMesh3D_makeDetailLevels,
%      fcn_CarMesh3D_simplifyMesh, fcn_CarMesh3D_fillVehicleSpec,
%      fcn_CarMesh3D_fillSampleMesh, fcn_CarMesh3D_labelParts,
%      fcn_CarMesh3D_fitMeshToSpec, fcn_CarMesh3D_plotVehicle
%      fcn_AnimateCar3D_fillSimpleShape
%
% EXAMPLES:
%
%       meshSet = fcn_AnimateCar3D_loadMeshes({'2013_Toyota_Prius_Four','sample'});
%
%       See the script: script_test_fcn_AnimateCar3D_loadMeshes.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadMeshes
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadMeshes
%   % * Loads each vehicle's detail levels from CarMesh3D
%   %   % (fcn_CarMesh3D_loadDetailLevels; made if missing), with
%   %   % SizeDiagonal, BoxCenter, and TopScreenSize, in place of one
%   %   % low-detail mesh made with fcn_CarMesh3D_simplifyMesh. Removed the
%   %   % LowFaces option and the Low and LowFaces fields
%   % * The sample car's mesh and levels are kept in a cache file
%   %   % (SampleCacheFile, in MATLAB's temporary folder)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadMeshes
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    meshIDs
    options.MeshSet = []      % an existing mesh set to add to
    options.SampleCacheFile = fullfile(tempdir, 'AnimateCar3D_sampleMeshCache.mat')   % '' for no cache
    options.FigNum = []       % figure to show the meshes; -1 for fast mode
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


        % Check the meshIDs input
        if ~(ischar(meshIDs) || isstring(meshIDs) || iscellstr(meshIDs))
            error('meshIDs must be a vehicle ID or a cell array of vehicle IDs');
        end

        % Check the SampleCacheFile input
        if ~(ischar(options.SampleCacheFile) || isstring(options.SampleCacheFile))
            error('SampleCacheFile must be a file name, or '''' for no cache');
        end

        % Check the MeshSet input
        if ~isempty(options.MeshSet) && ~(isstruct(options.MeshSet) && isfield(options.MeshSet,'IDs'))
            error('MeshSet must come from fcn_AnimateCar3D_loadMeshes');
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


meshIDs = cellstr(meshIDs);
[~, simpleIDs] = fcn_AnimateCar3D_fillSimpleShape('', FigNum=-1);
flagSimple = ismember(lower(meshIDs), simpleIDs);
meshIDs(flagSimple) = lower(meshIDs(flagSimple));
if isempty(options.MeshSet)
    meshSet = struct;
    meshSet.IDs = cell(1,0);
else
    meshSet = options.MeshSet;      % add only the meshes not loaded yet
end
meshIDs = setdiff(meshIDs(:)', meshSet.IDs, 'stable');
meshSet.IDs = [meshSet.IDs, meshIDs];
noLevels = struct('MaxScreenSize',{}, 'Faces',{}, 'IsBox',{}, 'Mesh',{});
for ith_mesh = 1:length(meshIDs)
    thisID = meshIDs{ith_mesh};

    % A simple shape (box, bar, cylinder, pedestrian): no mesh and no
    % levels; its default size, its origin where the shape puts it, and
    % its box (from the shape's corners at that size)
    if any(strcmp(thisID, simpleIDs))
        shape = fcn_AnimateCar3D_fillSimpleShape(thisID, FigNum=-1);
        corners = shape.Vertices .* shape.DefaultSize;   % x = length*(unit x + RearFraction) - overhang = length*unit x
        cornerLow = min(corners,[],1);
        cornerHigh = max(corners,[],1);
        meshSet.(thisID) = struct('ID',thisID, 'Full',[], 'Levels',noLevels, 'Size',shape.DefaultSize, ...
            'RearOverhang',shape.RearFraction*shape.DefaultSize(1), 'SizeDiagonal',norm(cornerHigh-cornerLow), ...
            'BoxCenter',(cornerLow+cornerHigh)/2, 'TopScreenSize',Inf, 'FullFaces',0, 'LevelFaces',zeros(1,0), 'Shape',shape);
        continue;
    end

    % The full mesh, and its levels
    if strcmpi(thisID,'sample')
        [fullMesh, detailLevels] = fcn_INTERNAL_sampleMesh(char(options.SampleCacheFile));
    else
        vehicleFiles = fcn_CarMesh3D_findVehicleFiles(thisID, FigNum=-1);
        if ~vehicleFiles.HasMesh
            error('The vehicle %s has no finished mesh (%s). Run its CarMesh3D vehicle script first.', thisID, vehicleFiles.MeshFile);
        end
        loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
        fullMesh = loaded.vehicleMesh;
        detailLevels = fcn_CarMesh3D_loadDetailLevels(thisID, MakeIfMissing=true, FigNum=-1);
    end

    % The size, from the mesh itself (so the box matches what is drawn)
    vertexMin = min(fullMesh.Vertices,[],1);
    vertexMax = max(fullMesh.Vertices,[],1);

    entry = struct;
    entry.ID = thisID;
    entry.Full = fullMesh;
    entry.Levels = detailLevels.Levels;
    entry.Size = vertexMax - vertexMin;
    entry.RearOverhang = -vertexMin(1);
    entry.SizeDiagonal = detailLevels.SizeDiagonal;
    entry.BoxCenter = detailLevels.BoxCenter(:)';
    entry.TopScreenSize = detailLevels.TopScreenSize;
    entry.FullFaces = size(fullMesh.Faces,1);
    entry.LevelFaces = [detailLevels.Levels.Faces];
    entry.Shape = [];
    meshSet.(matlab.lang.makeValidName(thisID)) = entry;
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
    plotIDs = meshSet.IDs(~ismember(meshSet.IDs, simpleIDs));
    Nmeshes = length(plotIDs);
    Ncolumns = 1 + max([0, cellfun(@(id) sum(~[meshSet.(matlab.lang.makeValidName(id)).Levels.IsBox]), plotIDs)]);
    tiledlayout(max(Nmeshes,1), Ncolumns, 'TileSpacing','compact', 'Padding','compact');
    for ith_mesh = 1:Nmeshes
        entry = meshSet.(matlab.lang.makeValidName(plotIDs{ith_mesh}));
        meshLevels = entry.Levels(~[entry.Levels.IsBox]);
        for ith_column = 1:1+numel(meshLevels)
            nexttile((ith_mesh-1)*Ncolumns + ith_column);
            if ith_column==1
                fcn_CarMesh3D_plotVehicle(entry.Full, FigNum=-1);
                titleText = sprintf('%s: full (%d faces)', strrep(entry.ID,'_',' '), entry.FullFaces);
            else
                fcn_CarMesh3D_plotVehicle(meshLevels(ith_column-1).Mesh, FigNum=-1);
                titleText = sprintf('to %.0f px (%d)', meshLevels(ith_column-1).MaxScreenSize, meshLevels(ith_column-1).Faces);
            end
            axis equal off;
            view(-35,20);
            title(titleText, 'FontSize', 8);
        end
    end
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

%% fcn_INTERNAL_sampleMesh
function [fullMesh, detailLevels] = fcn_INTERNAL_sampleMesh(cacheFile)
% The sample car and its levels, from the cache file if it was made by
% the same CarMesh3D copy, levels format, and levels maker; else made
% (about 3 s) and saved
makerFile = which('fcn_CarMesh3D_makeDetailLevels');
carMesh3DRoot = fileparts(fileparts(makerFile));
[~, carMesh3DName] = fileparts(carMesh3DRoot);
cacheKey = struct('CarMesh3DName',carMesh3DName, 'CarMesh3DRoot',carMesh3DRoot, ...
    'MakerDate',fcn_INTERNAL_fileDate(makerFile));
if ~isempty(cacheFile) && isfile(cacheFile)
    try
        cached = load(cacheFile, 'cacheKey', 'fullMesh', 'detailLevels');
        if isequal(cached.cacheKey, cacheKey) && isfield(cached.detailLevels,'FormatVersion') ...
                && cached.detailLevels.FormatVersion==1
            fullMesh = cached.fullMesh;
            detailLevels = cached.detailLevels;
            return;
        end
    catch
        % (an unreadable cache is made again)
    end
end
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
fullMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=-1);
fullMesh = fcn_CarMesh3D_labelParts(fullMesh, FigNum=-1);
fullMesh = fcn_CarMesh3D_fitMeshToSpec(fullMesh, vehicleSpec, FigNum=-1);
fullMesh = fcn_CarMesh3D_simplifyMesh(fullMesh, FigNum=-1);
detailLevels = fcn_CarMesh3D_makeDetailLevels(fullMesh, FigNum=-1);
if ~isempty(cacheFile)
    try
        save(cacheFile, 'cacheKey', 'fullMesh', 'detailLevels');
    catch
        % (a folder that cannot be written: no cache)
    end
end
end % Ends fcn_INTERNAL_sampleMesh

%% fcn_INTERNAL_fileDate
function fileDate = fcn_INTERNAL_fileDate(fileName)
% A file's modification time (so a changed levels maker remakes the cache)
fileInfo = dir(fileName);
fileDate = fileInfo.datenum;
end % Ends fcn_INTERNAL_fileDate

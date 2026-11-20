function meshSet = fcn_AnimateCar3D_loadMeshes(meshIDs, options)
% fcn_AnimateCar3D_loadMeshes

% Loads the vehicle meshes a scene needs, once, before animating. Each
% mesh is kept at two levels of detail, for the scene player's tiers:
%
%   Full   the finished CarMesh3D mesh (near tier: wheels, lights)
%   Low    the same mesh simplified to a few hundred faces (middle tier)
%
% and the vehicle's size, for drawing it as a box (far tier).
%
% Meshes are named by their CarMesh3D vehicle ID (the Data folder name,
% YEAR_Make_Model_Trimline), 'sample' for CarMesh3D's built-in sample
% car scaled to a generic sedan, or a simple shape: 'box', 'bar',
% 'cylinder', or 'pedestrian' (see fcn_AnimateCar3D_fillSimpleShape), for
% static objects, pedestrians, moving items, and vehicles known only by
% their size. Simple shapes are always drawn the far tier's way (all in
% one patch), sized by their display list Size (or their default size).
%
% While a live animation runs, new mesh IDs can appear: give the mesh
% set already loaded as MeshSet, and only the new meshes are loaded.
%
% FORMAT:
%
%       meshSet = fcn_AnimateCar3D_loadMeshes(meshIDs,...
%           (LowFaces=numFaces), (MeshSet=meshSet), (FigNum=figNum))
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
%      LowFaces: the face count of the low-detail meshes. Default 400.
%      (The count is a target: the result can be somewhat higher.)
%
%      MeshSet: a mesh set from an earlier call. The new IDs are added to
%      it; IDs it already has are not loaded again. Default [].
%
%      FigNum: a figure number to show each mesh at both detail levels.
%      Empty (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      meshSet: a structure with one field per mesh. The field name is
%      the ID made into a valid MATLAB name with
%      matlab.lang.makeValidName (for example, x2013_Toyota_Prius_Four),
%      and each field holds:
%           ID: the vehicle ID
%           Full: the finished mesh
%           Low: the low-detail mesh
%           Size: [length width height] in meters
%           RearOverhang: rear axle to rear bumper, in meters (places the
%               box: the vehicle origin is on the ground below the rear
%               axle)
%           FullFaces, LowFaces: face counts
%           Shape: for a simple shape, the shape (from
%               fcn_AnimateCar3D_fillSimpleShape); [] for a vehicle
%      meshSet.IDs lists the IDs in the order given (simple shape names
%      in lower case).
%
% DEPENDENCIES:
%
%      CarMesh3D: fcn_CarMesh3D_findVehicleFiles,
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

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_loadMeshes
%   % * Save the low-detail mesh with each vehicle in CarMesh3D, so it is not
%   %   % remade every time



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    meshIDs
    options.LowFaces = 400    % faces in the low-detail (middle tier) meshes
    options.MeshSet = []      % an existing mesh set to add to
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

        % Check the MeshSet input
        if ~isempty(options.MeshSet) && ~(isstruct(options.MeshSet) && isfield(options.MeshSet,'IDs'))
            error('MeshSet must come from fcn_AnimateCar3D_loadMeshes');
        end

        % Check the LowFaces input
        if ~isnumeric(options.LowFaces) || ~isscalar(options.LowFaces) || options.LowFaces<20
            error('LowFaces must be a number of 20 or more');
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
for ith_mesh = 1:length(meshIDs)
    thisID = meshIDs{ith_mesh};

    % A simple shape (box, bar, cylinder, pedestrian): no mesh; its
    % default size, and its origin where the shape puts it
    if any(strcmp(thisID, simpleIDs))
        shape = fcn_AnimateCar3D_fillSimpleShape(thisID, FigNum=-1);
        meshSet.(thisID) = struct('ID',thisID, 'Full',[], 'Low',[], 'Size',shape.DefaultSize, ...
            'RearOverhang',shape.RearFraction*shape.DefaultSize(1), 'FullFaces',0, 'LowFaces',0, 'Shape',shape);
        continue;
    end

    % The full mesh
    if strcmpi(thisID,'sample')
        vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
        fullMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=-1);
        fullMesh = fcn_CarMesh3D_labelParts(fullMesh, FigNum=-1);
        fullMesh = fcn_CarMesh3D_fitMeshToSpec(fullMesh, vehicleSpec, FigNum=-1);
        fullMesh = fcn_CarMesh3D_simplifyMesh(fullMesh, FigNum=-1);
    else
        vehicleFiles = fcn_CarMesh3D_findVehicleFiles(thisID, FigNum=-1);
        if ~vehicleFiles.HasMesh
            error('The vehicle %s has no finished mesh (%s). Run its CarMesh3D vehicle script first.', thisID, vehicleFiles.MeshFile);
        end
        loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
        fullMesh = loaded.vehicleMesh;
    end

    % The low-detail mesh
    if size(fullMesh.Faces,1) > options.LowFaces
        lowMesh = fcn_CarMesh3D_simplifyMesh(fullMesh, TargetFaces=options.LowFaces, FigNum=-1);
    else
        lowMesh = fullMesh;
    end

    % The size, from the mesh itself (so the box matches what is drawn)
    vertexMin = min(fullMesh.Vertices,[],1);
    vertexMax = max(fullMesh.Vertices,[],1);

    entry = struct;
    entry.ID = thisID;
    entry.Full = fullMesh;
    entry.Low = lowMesh;
    entry.Size = vertexMax - vertexMin;
    entry.RearOverhang = -vertexMin(1);
    entry.FullFaces = size(fullMesh.Faces,1);
    entry.LowFaces = size(lowMesh.Faces,1);
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
    for ith_mesh = 1:Nmeshes
        entry = meshSet.(matlab.lang.makeValidName(plotIDs{ith_mesh}));
        detailNames = {'Full','Low'};
        for ith_detail = 1:2
            subplot(Nmeshes, 2, 2*(ith_mesh-1)+ith_detail);
            fcn_CarMesh3D_plotVehicle(entry.(detailNames{ith_detail}), FigNum=-1);
            axis equal off;
            view(-35,20);
            title(sprintf('%s: %s detail (%d faces)', strrep(entry.ID,'_',' '), lower(detailNames{ith_detail}), ...
                size(entry.(detailNames{ith_detail}).Faces,1)), 'FontSize', 9);
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

% (none)

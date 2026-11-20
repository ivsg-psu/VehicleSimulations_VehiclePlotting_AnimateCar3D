function displayList = fcn_AnimateCar3D_fillDisplayList(options)
% fcn_AnimateCar3D_fillDisplayList

% Builds a display list: everything the scene player draws at one time
% step, and nothing else. Later the selector will build it from the
% object catalog; for now it can be built directly from arrays in memory.
%
% Each row of the inputs is one object (one vehicle). Each object has a
% detail tier:
%
%   'near'    full mesh: wheels spin and steer, the body rolls, pitches,
%             and heaves, lights switch
%   'middle'  a reduced mesh (one of the vehicle's detail levels), drawn
%             as its own object, moved by its pose only
%   'far'     a reduced mesh, down to a box; all far objects are merged
%             into one patch, so thousands cost little
%
% Which detail level a middle or far object uses is its Level (an index
% into its mesh's Levels, from fcn_AnimateCar3D_loadMeshes), or, if Level
% is NaN, the level made for its ScreenSize (the coarsest whose
% MaxScreenSize is at least ScreenSize). With neither, a middle object
% uses the finest level and a far object a box.
%
% Simple shapes ('box', 'bar', 'cylinder', 'pedestrian'; see
% fcn_AnimateCar3D_fillSimpleShape) have no mesh, so they are always
% 'far': they are merged with the far objects, each in its own shape.
%
% FORMAT:
%
%       displayList = fcn_AnimateCar3D_fillDisplayList(...
%           Instance=names, MeshID=ids, Pose=poses,...
%           (Tier=tiers), (Time=time),...
%           (WheelSpin=spin), (SteerAngle=steer), (WheelLift=lift),...
%           (BodyRoll=roll), (BodyPitch=pitch), (BodyHeave=heave),...
%           (LightStates=states), (Color=colors), (Alpha=alphas),...
%           (Size=sizes), (Level=levels), (ScreenSize=pixels),...
%           (AppendTo=displayList), (FigNum=figNum))
%
%      All inputs are Name=Value pairs, in any order. N is the number of
%      objects (rows).
%
% INPUTS:
%
%      Instance: N names, unique within the scene (cell array, or one
%      name as text). The player keeps an object's graphics from step to
%      step by this name.
%
%      MeshID: the mesh of each object: one ID for all, or N IDs. The
%      IDs are those given to fcn_AnimateCar3D_loadMeshes.
%
%      Pose: N x 3 [x y yaw] or N x 6 [x y z roll pitch yaw], in the
%      global frame (meters, radians), for the vehicle's origin: the
%      ground below the rear axle. z, roll, and pitch are the road under
%      the vehicle (as in CarMesh3D).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Tier: 'near' (default), 'middle', or 'far': one for all, or N.
%      Simple shapes ('box', 'pedestrian', ...) are always 'far'.
%
%      Time: the time of this step, in seconds. Default 0.
%
%      WheelSpin (N x 4), SteerAngle (N x 2), WheelLift (N x 4),
%      BodyRoll, BodyPitch, BodyHeave (N x 1): as in
%      fcn_CarMesh3D_plotVehicle, with wheels in [FL FR RL RR] order.
%      Used for near objects only. Default zeros.
%
%      LightStates: N x 1 structure array of light states (as in
%      fcn_CarMesh3D_plotVehicle), or empty (default) for lights off.
%      Near objects only.
%
%      Color: N x 3 colors to tint each object (or one row for all);
%      NaN rows keep the mesh's own colors (default). For far boxes,
%      the box color (NaN gives gray).
%
%      Alpha: N x 1 opacity from 0 to 1 (or one value for all). Default 1.
%
%      Size: N x 3 [length width height] of far boxes and simple
%      shapes; NaN rows (the default) take the size of the object's mesh.
%
%      Level: N x 1 detail level of middle and far objects: an index into
%      the mesh's Levels, 0 for the full mesh, or NaN (the default) to
%      choose from ScreenSize. Ignored for near objects.
%
%      ScreenSize: N x 1 size on screen, pixels (as the selector works it
%      out), or NaN (the default).
%
%      AppendTo: a display list to add these objects to (for example,
%      the ego vehicle then the traffic). Instance names must stay
%      unique.
%
%      FigNum: a figure number to plot the objects from above (position,
%      heading, and tier). Empty (default) for no figure; -1 for fast
%      mode (no input checks).
%
% OUTPUTS:
%
%      displayList: a structure with fields
%           Time: the time
%           Objects: structure array of near and middle objects, with
%               fields Instance, MeshID, Tier, Pose (1 x 6), WheelSpin,
%               SteerAngle, WheelLift, BodyRoll, BodyPitch, BodyHeave,
%               LightStates, Color, Alpha, Level, ScreenSize
%           Boxes: the far objects (merged), as arrays: Instance (cell),
%               MeshID (cell), Pose (M x 6), Size (M x 3), Color (M x 3),
%               Level (M x 1), ScreenSize (M x 1)
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_fillSimpleShape
%
% EXAMPLES:
%
%       displayList = fcn_AnimateCar3D_fillDisplayList(Instance={'ego','car1'},...
%           MeshID='sample', Pose=[0 0 0; 12 3.5 0], Tier={'near','far'});
%
%       See the script: script_test_fcn_AnimateCar3D_fillDisplayList.m for
%       a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillDisplayList
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillDisplayList
%   % * Added Level and ScreenSize (for detail levels); the far tier is now
%   %   % reduced meshes merged in one patch

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillDisplayList
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    options.Instance = {}        % N names
    options.MeshID = {}          % one mesh ID, or N
    options.Pose = zeros(0,3)    % N x 3 [x y yaw] or N x 6
    options.Tier = 'near'        % 'near', 'middle', 'far': one, or N
    options.Time = 0             % seconds
    options.WheelSpin = []       % N x 4
    options.SteerAngle = []      % N x 2
    options.WheelLift = []       % N x 4
    options.BodyRoll = []        % N x 1
    options.BodyPitch = []       % N x 1
    options.BodyHeave = []       % N x 1
    options.LightStates = []     % N x 1 structure array
    options.Color = []           % N x 3 (or 1 x 3); NaN keeps mesh colors
    options.Alpha = []           % N x 1 (or one value)
    options.Size = []            % N x 3 box sizes; NaN uses the mesh size
    options.Level = []           % N x 1 detail levels; NaN chooses from ScreenSize
    options.ScreenSize = []      % N x 1 sizes on screen, pixels
    options.AppendTo = []        % a display list to add to
    options.FigNum = []          % figure to plot from above; -1 for fast mode
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


        Ncheck = numel(cellstr(options.Instance));

        % Check the Instance input
        if ~(ischar(options.Instance) || isstring(options.Instance) || iscellstr(options.Instance))
            error('Instance must be a name or a cell array of names');
        end
        if numel(unique(cellstr(options.Instance))) ~= Ncheck
            error('Instance names must be unique');
        end

        % Check the MeshID input
        if ~(ischar(options.MeshID) || isstring(options.MeshID) || iscellstr(options.MeshID))
            error('MeshID must be a mesh ID or a cell array of them');
        end
        if ~any(numel(cellstr(options.MeshID)) == [1 Ncheck])
            error('MeshID must have 1 or %d entries', Ncheck);
        end

        % Check the Pose input
        if ~isnumeric(options.Pose) || size(options.Pose,1)~=Ncheck || ~any(size(options.Pose,2)==[3 6])
            error('Pose must be N x 3 [x y yaw] or N x 6 [x y z roll pitch yaw], with N = %d', Ncheck);
        end

        % Check the Tier input
        tierCheck = cellstr(options.Tier);
        if ~any(numel(tierCheck)==[1 Ncheck]) || ~all(ismember(tierCheck,{'near','middle','far'}))
            error('Tier must be ''near'', ''middle'', or ''far'' (one for all, or %d)', Ncheck);
        end

        % Check the sized numeric inputs
        sizedInputs = {'WheelSpin',4; 'SteerAngle',2; 'WheelLift',4; 'BodyRoll',1; 'BodyPitch',1; 'BodyHeave',1; 'Size',3; ...
            'Level',1; 'ScreenSize',1};
        for ith_input = 1:size(sizedInputs,1)
            thisValue = options.(sizedInputs{ith_input,1});
            if ~isempty(thisValue) && (~isnumeric(thisValue) || ~isequal(size(thisValue),[Ncheck sizedInputs{ith_input,2}]))
                error('%s must be %d x %d', sizedInputs{ith_input,1}, Ncheck, sizedInputs{ith_input,2});
            end
        end

        % Check the Color and Alpha inputs
        if ~isempty(options.Color) && (~isnumeric(options.Color) || size(options.Color,2)~=3 || ~any(size(options.Color,1)==[1 Ncheck]))
            error('Color must be 1 x 3 or %d x 3', Ncheck);
        end
        if ~isempty(options.Alpha) && (~isnumeric(options.Alpha) || ~any(numel(options.Alpha)==[1 Ncheck]) || any(options.Alpha<0 | options.Alpha>1))
            error('Alpha must be one value or %d values, from 0 to 1', Ncheck);
        end

        % Check the LightStates input
        if ~isempty(options.LightStates) && (~isstruct(options.LightStates) || numel(options.LightStates)~=Ncheck)
            error('LightStates must be a structure array with %d entries', Ncheck);
        end

        % Check the AppendTo input
        if ~isempty(options.AppendTo) && ~(isstruct(options.AppendTo) && all(isfield(options.AppendTo,{'Time','Objects','Boxes'})) ...
                && isfield(options.AppendTo.Boxes,'Level'))
            error('AppendTo must be a display list');
        end
        if ~isempty(options.AppendTo)
            existingNames = [{options.AppendTo.Objects.Instance}, options.AppendTo.Boxes.Instance(:)'];
            if any(ismember(cellstr(options.Instance), existingNames))
                error('Instance names must be unique: some are already in AppendTo');
            end
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


instanceNames = cellstr(options.Instance);
instanceNames = instanceNames(:);
N = numel(instanceNames);

% Expand the "one for all" inputs to N rows, and fill defaults
meshIDs = fcn_INTERNAL_expandCell(options.MeshID, N);
tiers = fcn_INTERNAL_expandCell(options.Tier, N);
[~, simpleIDs] = fcn_AnimateCar3D_fillSimpleShape('', FigNum=-1);
flagSimple = ismember(lower(meshIDs), simpleIDs);
meshIDs(flagSimple) = lower(meshIDs(flagSimple));
tiers(flagSimple) = {'far'};          % simple shapes have no mesh: always drawn the far way
poses = options.Pose;
if size(poses,2)==3
    poses = [poses(:,1:2), zeros(N,3), poses(:,3)];
end
wheelSpin  = fcn_INTERNAL_orZeros(options.WheelSpin, N, 4);
steerAngle = fcn_INTERNAL_orZeros(options.SteerAngle, N, 2);
wheelLift  = fcn_INTERNAL_orZeros(options.WheelLift, N, 4);
bodyRoll   = fcn_INTERNAL_orZeros(options.BodyRoll, N, 1);
bodyPitch  = fcn_INTERNAL_orZeros(options.BodyPitch, N, 1);
bodyHeave  = fcn_INTERNAL_orZeros(options.BodyHeave, N, 1);
if isempty(options.Color)
    colors = nan(N,3);
else
    colors = repmat(options.Color, N/size(options.Color,1), 1);
end
if isempty(options.Alpha)
    alphas = ones(N,1);
else
    alphas = repmat(options.Alpha(:), N/numel(options.Alpha), 1);
end
if isempty(options.Size)
    sizes = nan(N,3);
else
    sizes = options.Size;
end
levels = fcn_INTERNAL_orNaN(options.Level, N);
screenSizes = fcn_INTERNAL_orNaN(options.ScreenSize, N);

% Start from AppendTo, or an empty list
if isempty(options.AppendTo)
    displayList = struct;
    displayList.Time = options.Time;
    displayList.Objects = repmat(fcn_INTERNAL_emptyObject, 0, 1);
    displayList.Boxes = struct('Instance',{cell(0,1)}, 'MeshID',{cell(0,1)}, ...
        'Pose',zeros(0,6), 'Size',zeros(0,3), 'Color',zeros(0,3), 'Level',zeros(0,1), 'ScreenSize',zeros(0,1));
else
    displayList = options.AppendTo;
end

% Near and middle objects
flagObject = ~strcmp(tiers,'far');
objectRows = find(flagObject);
newObjects = repmat(fcn_INTERNAL_emptyObject, numel(objectRows), 1);
for ith_object = 1:numel(objectRows)
    row = objectRows(ith_object);
    newObjects(ith_object).Instance = instanceNames{row};
    newObjects(ith_object).MeshID = meshIDs{row};
    newObjects(ith_object).Tier = tiers{row};
    newObjects(ith_object).Pose = poses(row,:);
    newObjects(ith_object).WheelSpin = wheelSpin(row,:);
    newObjects(ith_object).SteerAngle = steerAngle(row,:);
    newObjects(ith_object).WheelLift = wheelLift(row,:);
    newObjects(ith_object).BodyRoll = bodyRoll(row);
    newObjects(ith_object).BodyPitch = bodyPitch(row);
    newObjects(ith_object).BodyHeave = bodyHeave(row);
    if ~isempty(options.LightStates)
        newObjects(ith_object).LightStates = options.LightStates(row);
    end
    newObjects(ith_object).Color = colors(row,:);
    newObjects(ith_object).Alpha = alphas(row);
    newObjects(ith_object).Level = levels(row);
    newObjects(ith_object).ScreenSize = screenSizes(row);
end
displayList.Objects = [displayList.Objects(:); newObjects];

% Far boxes
boxRows = find(~flagObject);
displayList.Boxes.Instance = [displayList.Boxes.Instance(:); instanceNames(boxRows)];
displayList.Boxes.MeshID = [displayList.Boxes.MeshID(:); meshIDs(boxRows)];
displayList.Boxes.Pose = [displayList.Boxes.Pose; poses(boxRows,:)];
displayList.Boxes.Size = [displayList.Boxes.Size; sizes(boxRows,:)];
displayList.Boxes.Color = [displayList.Boxes.Color; colors(boxRows,:)];
displayList.Boxes.Level = [displayList.Boxes.Level; levels(boxRows)];
displayList.Boxes.ScreenSize = [displayList.Boxes.ScreenSize; screenSizes(boxRows)];

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
    tierNames = {'near','middle','far'};
    tierColors = [0.85 0.2 0.1; 0.95 0.6 0.1; 0.5 0.5 0.5];
    tierMarkers = {'o','s','.'};
    legendHandles = gobjects(0);
    legendNames = {};
    for ith_tier = 1:3
        if ith_tier<3
            theseObjects = displayList.Objects(strcmp({displayList.Objects.Tier}, tierNames{ith_tier}));
            thesePoses = reshape([theseObjects.Pose], 6, [])';
        else
            thesePoses = displayList.Boxes.Pose;
        end
        if isempty(thesePoses)
            continue;
        end
        legendHandles(end+1) = plot(thesePoses(:,1), thesePoses(:,2), tierMarkers{ith_tier}, ...
            'Color', tierColors(ith_tier,:), 'MarkerFaceColor', tierColors(ith_tier,:), 'MarkerSize', 6); %#ok<AGROW>
        quiver(thesePoses(:,1), thesePoses(:,2), 2*cos(thesePoses(:,6)), 2*sin(thesePoses(:,6)), 0, ...
            'Color', tierColors(ith_tier,:));
        legendNames{end+1} = sprintf('%s (%d)', tierNames{ith_tier}, size(thesePoses,1)); %#ok<AGROW>
    end
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    title(sprintf('Display list at t = %.2f s', displayList.Time));
    if ~isempty(legendHandles)
        legend(legendHandles, legendNames, 'Location', 'best');
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

%% fcn_INTERNAL_emptyObject
function emptyObject = fcn_INTERNAL_emptyObject
% One display list object, with every field
emptyObject = struct('Instance','', 'MeshID','', 'Tier','near', 'Pose',zeros(1,6), ...
    'WheelSpin',zeros(1,4), 'SteerAngle',zeros(1,2), 'WheelLift',zeros(1,4), ...
    'BodyRoll',0, 'BodyPitch',0, 'BodyHeave',0, 'LightStates',[], ...
    'Color',nan(1,3), 'Alpha',1, 'Level',NaN, 'ScreenSize',NaN);
end % Ends fcn_INTERNAL_emptyObject

%% fcn_INTERNAL_expandCell
function values = fcn_INTERNAL_expandCell(input, N)
% One text value for all N, or N values, as an N x 1 cell array
values = cellstr(input);
values = values(:);
if numel(values)==1
    values = repmat(values, N, 1);
end
end % Ends fcn_INTERNAL_expandCell

%% fcn_INTERNAL_orNaN
function values = fcn_INTERNAL_orNaN(input, N)
% The input as an N x 1 column, or NaN if it was not given
if isempty(input)
    values = nan(N,1);
else
    values = input(:);
end
end % Ends fcn_INTERNAL_orNaN

%% fcn_INTERNAL_orZeros
function values = fcn_INTERNAL_orZeros(input, N, Ncolumns)
% The input, or zeros if it was not given
if isempty(input)
    values = zeros(N, Ncolumns);
else
    values = input;
end
end % Ends fcn_INTERNAL_orZeros

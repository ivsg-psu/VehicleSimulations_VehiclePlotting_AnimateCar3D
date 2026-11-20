function [shape, shapeIDs] = fcn_AnimateCar3D_fillSimpleShape(shapeID, options)
% fcn_AnimateCar3D_fillSimpleShape

% Returns one of the simple shapes used for objects that have no vehicle
% mesh: pedestrians, moving items (gate arms, garage doors, trains), and
% static objects (buildings, poles). Simple shapes are always drawn the
% way far-tier vehicles are, all together in one patch, so thousands of
% them stay cheap; unlike far-tier boxes, they turn in roll and pitch as
% well as yaw, so a gate arm can rise.
%
% THE SHAPES (Size is [length width height], meters):
%
%   'box'         a box; its origin at the center of its bottom face.
%                 Default size [1 1 1]. Static objects, trucks known only
%                 by their size, trains (one box per car), garage doors.
%   'bar'         a box whose origin is at the center of its rear end
%                 (half way up), so it swings about that end: a gate arm.
%                 Default size [4 0.12 0.12].
%   'cylinder'    an upright 12-sided cylinder; origin at the center of
%                 its base. Default size [0.3 0.3 1]: posts, bollards.
%   'pedestrian'  a standing person: legs, body, and head, facing +x;
%                 origin on the ground between the feet. Default size
%                 [0.35 0.55 1.75]. The legs and head keep their own
%                 colors; the body takes the object's color.
%
% Each shape is stored in unit form: vertices for a size of [1 1 1], and
% scaled by each object's size when drawn.
%
% FORMAT:
%
%       [shape, shapeIDs] = fcn_AnimateCar3D_fillSimpleShape((shapeID), (FigNum=figNum))
%
% INPUTS:
%
%      (none)
%
%     (OPTIONAL INPUTS)
%
%      shapeID: one of the shape names above (upper or lower case). Empty
%      or left out: no shape is returned, only the list of names.
%
%      FigNum (a Name=Value pair): a figure number to draw the shape at
%      its default size. Empty (default) for no figure; -1 for fast mode
%      (no input checks).
%
% OUTPUTS:
%
%      shape: a structure with fields
%           ID: the shape's name
%           Vertices: Nv x 3, for a size of [1 1 1]: x from
%               -RearFraction to 1-RearFraction, y from -0.5 to 0.5, z
%               from 0 to 1 ('bar': z from -0.5 to 0.5)
%           Faces: Nf x m vertex indices, counterclockwise seen from
%               outside, padded with NaN for faces with fewer than m
%               corners
%           FaceColor: Nf x 3 fixed colors; NaN rows take the object's
%               color
%           FaceShade: Nf x 1 brightness factor (1.15 for tops, so they
%               stand out)
%           DefaultSize: [length width height]
%           RearFraction: the part of the length behind the origin
%      ([] if no shapeID was given.)
%
%      shapeIDs: the names of all simple shapes, a cell array.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       shape = fcn_AnimateCar3D_fillSimpleShape('pedestrian');
%       [~, shapeIDs] = fcn_AnimateCar3D_fillSimpleShape;
%
%       See the script: script_test_fcn_AnimateCar3D_fillSimpleShape.m
%       for a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillSimpleShape
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillSimpleShape
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    shapeID = ''
    options.FigNum = []             % figure to draw the shape; -1 for fast mode
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


        % Check the shapeID input
        if ~(ischar(shapeID) || isstring(shapeID))
            error('shapeID must be text: one of box, bar, cylinder, pedestrian');
        end
        if ~isempty(char(shapeID)) && ~any(strcmpi(char(shapeID), {'box','bar','cylinder','pedestrian'}))
            error('Unknown simple shape %s. Use one of: box, bar, cylinder, pedestrian', char(shapeID));
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


shapeIDs = {'box','bar','cylinder','pedestrian'};
shapeID = lower(char(shapeID));
shape = [];
switch shapeID
    case ''
        % Only the list of names

    case 'box'
        % Eight corners; five faces (the bottom is never seen)
        cornerRadius = 0.5/cos(pi/4);                    % corners at +-0.5
        [vertices, faces] = fcn_INTERNAL_prism([0.5 0], cornerRadius, cornerRadius, 4, pi/4, 0, 1, true, false);
        shape = fcn_INTERNAL_shape('box', vertices, faces, nan(size(faces,1),3), [1 1 1], 0.5);

    case 'bar'
        % A box from x = 0 to 1, z from -0.5 to 0.5, all six faces (it can
        % be seen from below when raised)
        cornerRadius = 0.5/cos(pi/4);
        [vertices, faces] = fcn_INTERNAL_prism([0.5 0], cornerRadius, cornerRadius, 4, pi/4, -0.5, 0.5, true, true);
        shape = fcn_INTERNAL_shape('bar', vertices, faces, nan(size(faces,1),3), [4 0.12 0.12], 0);

    case 'cylinder'
        [vertices, faces] = fcn_INTERNAL_prism([0.5 0], 0.5, 0.5, 12, 0, 0, 1, true, false);
        shape = fcn_INTERNAL_shape('cylinder', vertices, faces, nan(size(faces,1),3), [0.3 0.3 1], 0.5);

    case 'pedestrian'
        % Legs (dark), body (the object's color), and head (skin), each
        % an eight-sided prism; the body and head have bottoms (seen
        % where they overhang)
        [legVertices, legFaces] = fcn_INTERNAL_prism([0.5 0], 0.42, 0.30, 8, pi/8, 0, 0.48, true, false);
        [bodyVertices, bodyFaces] = fcn_INTERNAL_prism([0.5 0], 0.5, 0.5, 8, pi/8, 0.48, 0.84, true, true);
        [headVertices, headFaces] = fcn_INTERNAL_prism([0.55 0], 0.34, 0.17, 8, pi/8, 0.87, 1.0, true, true);
        vertices = [legVertices; bodyVertices; headVertices];
        for ith_axis = 1:2      % stretch to exactly 1 x 1 (x from 0 to 1, y from -0.5 to 0.5)
            axisRange = [min(vertices(:,ith_axis)) max(vertices(:,ith_axis))];
            vertices(:,ith_axis) = (vertices(:,ith_axis) - mean(axisRange))/diff(axisRange) + 0.5*(ith_axis==1);
        end
        faces = fcn_INTERNAL_stackFaces({legFaces, bodyFaces + size(legVertices,1), ...
            headFaces + size(legVertices,1) + size(bodyVertices,1)});
        faceColors = [repmat([0.20 0.22 0.30], size(legFaces,1), 1); nan(size(bodyFaces,1),3); ...
            repmat([0.87 0.72 0.60], size(headFaces,1), 1)];
        shape = fcn_INTERNAL_shape('pedestrian', vertices, faces, faceColors, [0.35 0.55 1.75], 0.5);
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

    if ~isempty(shape)
        figure(figNum);
        clf;
        defaultColor = [0.05 0.20 0.60];
        vertices = shape.Vertices;
        vertices(:,1) = vertices(:,1) - shape.RearFraction;
        vertices = vertices .* shape.DefaultSize;
        faceColors = shape.FaceColor;
        faceColors(any(isnan(faceColors),2),:) = repmat(defaultColor, sum(any(isnan(faceColors),2)), 1);
        faceColors = min(1, faceColors .* shape.FaceShade);
        patch('Faces',shape.Faces, 'Vertices',vertices, 'FaceVertexCData',faceColors, 'FaceColor','flat', ...
            'EdgeColor',[0.3 0.3 0.3]);
        hold on;
        plot3(0, 0, 0, 'r+', 'MarkerSize', 12, 'LineWidth', 2);    % the origin
        axis equal;
        grid on;
        view(-35, 20);
        camlight;
        xlabel('x [m]');
        ylabel('y [m]');
        zlabel('z [m]');
        title(sprintf('Simple shape ''%s'' at its default size (+: origin)', shape.ID));
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

%% fcn_INTERNAL_prism
function [vertices, faces] = fcn_INTERNAL_prism(centerXY, radiusX, radiusY, Nsides, startAngle, zLow, zHigh, flagTop, flagBottom)
% An upright prism with Nsides sides around centerXY, from zLow to zHigh:
% side faces (quads), and optionally a top and a bottom (Nsides corners)
angles = startAngle + (0:Nsides-1)'*2*pi/Nsides;
ringX = centerXY(1) + radiusX*cos(angles);
ringY = centerXY(2) + radiusY*sin(angles);
vertices = [ringX ringY zLow*ones(Nsides,1); ringX ringY zHigh*ones(Nsides,1)];
lowIndex = (1:Nsides)';
nextIndex = [2:Nsides 1]';
faces = [lowIndex, nextIndex, nextIndex+Nsides, lowIndex+Nsides];   % counterclockwise from outside
width = max(4, Nsides);
faces = [faces, nan(Nsides, width-4)];
if flagTop
    faces = [faces; (Nsides+1:2*Nsides), nan(1, width-Nsides)];
end
if flagBottom
    faces = [faces; (Nsides:-1:1), nan(1, width-Nsides)];
end
end % Ends fcn_INTERNAL_prism

%% fcn_INTERNAL_stackFaces
function faces = fcn_INTERNAL_stackFaces(faceSets)
% Stack face arrays of different widths, padding with NaN
width = max(cellfun(@(f) size(f,2), faceSets));
faces = zeros(0, width);
for ith_set = 1:numel(faceSets)
    thisSet = faceSets{ith_set};
    faces = [faces; thisSet, nan(size(thisSet,1), width-size(thisSet,2))]; %#ok<AGROW>
end
end % Ends fcn_INTERNAL_stackFaces

%% fcn_INTERNAL_shape
function shape = fcn_INTERNAL_shape(shapeID, vertices, faces, faceColors, defaultSize, rearFraction)
% Put a shape together: x moved so the origin is RearFraction from the
% rear; tops (faces whose corners are all at the highest z of their
% part, facing up) brighter
vertices(:,1) = vertices(:,1) - rearFraction;
Nfaces = size(faces,1);
faceShade = ones(Nfaces,1);
for ith_face = 1:Nfaces
    corners = faces(ith_face, ~isnan(faces(ith_face,:)));
    if numel(corners) > 4 || (numel(corners)==4 && all(abs(diff(vertices(corners,3))) < 1e-12))
        cornerXYZ = vertices(corners,:);
        normalVector = cross(cornerXYZ(2,:)-cornerXYZ(1,:), cornerXYZ(3,:)-cornerXYZ(1,:));
        if normalVector(3) > 0
            faceShade(ith_face) = 1.15;
        end
    end
end
shape = struct('ID',shapeID, 'Vertices',vertices, 'Faces',faces, 'FaceColor',faceColors, ...
    'FaceShade',faceShade, 'DefaultSize',defaultSize, 'RearFraction',rearFraction);
end % Ends fcn_INTERNAL_shape

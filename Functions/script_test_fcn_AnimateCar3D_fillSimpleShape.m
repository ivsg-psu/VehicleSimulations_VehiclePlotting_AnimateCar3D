% script_test_fcn_AnimateCar3D_fillSimpleShape.m
% Tests fcn_AnimateCar3D_fillSimpleShape
% Returns the simple shapes used for pedestrians, moving items, and static objects.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillSimpleShape
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillSimpleShape
%   % * (fill in items here)


%% Set up the workspace
close all


%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: A pedestrian
figNum = 10001;
titleString = sprintf('DEMO case: A pedestrian');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

[shape, shapeIDs] = fcn_AnimateCar3D_fillSimpleShape('pedestrian', FigNum=figNum);

% Check variable types
assert(isstruct(shape) && iscell(shapeIDs));

% Check variable sizes
assert(size(shape.Vertices,2)==3 && size(shape.FaceColor,1)==size(shape.Faces,1));
assert(numel(shape.FaceShade)==size(shape.Faces,1));

% Check variable values
assert(isequal(shapeIDs, {'box','bar','cylinder','pedestrian'}));
assert(abs(min(shape.Vertices(:,3))) < 1e-12 && abs(max(shape.Vertices(:,3))-1) < 1e-12);
assert(all(abs(shape.Vertices(:,2)) <= 0.5 + 1e-12));
assert(isequal(shape.DefaultSize, [0.35 0.55 1.75]));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Every shape: unit size, origin, and faces facing out
figNum = 20001;
titleString = sprintf('TEST case: Every shape: unit size, origin, and faces facing out');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[~, shapeIDs] = fcn_AnimateCar3D_fillSimpleShape;
for ith_shape = 1:numel(shapeIDs)
    shape = fcn_AnimateCar3D_fillSimpleShape(shapeIDs{ith_shape});
    vertexRange = max(shape.Vertices) - min(shape.Vertices);
    assert(all(abs(vertexRange - 1) < 1e-9), 'Shape %s is not of unit size', shape.ID);
    assert(abs(min(shape.Vertices(:,1)) + shape.RearFraction) < 1e-9);
    shapeCenter = mean(shape.Vertices, 1);
    for ith_face = 1:size(shape.Faces,1)
        corners = shape.Faces(ith_face, ~isnan(shape.Faces(ith_face,:)));
        cornerXYZ = shape.Vertices(corners,:);
        normalVector = cross(cornerXYZ(2,:)-cornerXYZ(1,:), cornerXYZ(3,:)-cornerXYZ(1,:));
        if ~strcmp(shape.ID,'pedestrian')   % (the pedestrian's parts have their own centers)
            assert(dot(normalVector, mean(cornerXYZ,1) - shapeCenter) > 0, 'A face of %s faces inward', shape.ID);
        end
    end
end
box = fcn_AnimateCar3D_fillSimpleShape('BOX');
assert(size(box.Faces,1)==5 && sum(box.FaceShade>1)==1);           % no bottom; a bright top
bar = fcn_AnimateCar3D_fillSimpleShape('bar');
assert(size(bar.Faces,1)==6 && abs(min(bar.Vertices(:,3))+0.5) < 1e-12 && abs(min(bar.Vertices(:,1))) < 1e-12);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
shape = fcn_AnimateCar3D_fillSimpleShape('cylinder', FigNum=[]);
assert(size(shape.Faces,1)==13);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
shape = fcn_AnimateCar3D_fillSimpleShape('cylinder', FigNum=-1);
assert(size(shape.Faces,1)==13);

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: An unknown shape
if 1==0
    fcn_AnimateCar3D_fillSimpleShape('tree');
end

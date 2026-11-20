function [criteria, changedNames] = fcn_AnimateCar3D_changeDisplayCriteria(criteria, changes, options)
% fcn_AnimateCar3D_changeDisplayCriteria

% Changes some of the display criteria while an animation runs, keeping
% the rest. The changes come from a structure (in a script) or from a
% small text file (so that a person, or another program, can change what
% is shown while a live animation runs, without stopping it). The result
% is checked the same way as by fcn_AnimateCar3D_fillDisplayCriteria.
%
% THE TEXT FILE has one change per line, as Name = value. Lines starting
% with % or # are comments, and blank lines are skipped. Names are those
% of fcn_AnimateCar3D_fillDisplayCriteria. Values are written as:
%
%   numbers         MaxDistance = 300      BoxSize = 200 80
%                   (brackets and commas are allowed: [200, 80])
%   true or false   HideParentAtSplit = false
%   a list of text  RolesShown = ego, confederate, pedestrian
%   text            Region = circle        Center = ego
%   tier pairs      FixedTiers = ego near; confederate middle
%
% A Center of two numbers is a fixed point; Center cannot be a function
% in the file.
%
% FORMAT:
%
%       [criteria, changedNames] = fcn_AnimateCar3D_changeDisplayCriteria(criteria, changes,...
%           (OnError=onError), (FigNum=figNum))
%
% INPUTS:
%
%      criteria: from fcn_AnimateCar3D_fillDisplayCriteria (or this
%      function).
%
%      changes: a structure with the fields to change, or the name of a
%      text file of changes (see above).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      OnError: 'error' (default) stops on a bad change; 'warn' gives a
%      warning and returns the criteria unchanged, so that a typing
%      mistake in a live file does not stop the animation.
%
%      FigNum: a figure number to sketch the new criteria (as
%      fcn_AnimateCar3D_fillDisplayCriteria does). Empty (default) for no
%      figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      criteria: the criteria with the changes made.
%
%      changedNames: a cell array of the names whose values changed
%      (empty if none, or if the changes were rejected with OnError
%      'warn').
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_fillDisplayCriteria
%
% EXAMPLES:
%
%       criteria = fcn_AnimateCar3D_changeDisplayCriteria(criteria, struct('MaxDistance',300));
%       criteria = fcn_AnimateCar3D_changeDisplayCriteria(criteria, 'liveFolder/displayCriteria.txt', OnError='warn');
%
%       See the script: script_test_fcn_AnimateCar3D_changeDisplayCriteria.m
%       for a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_changeDisplayCriteria
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_changeDisplayCriteria
%   % * Examples and checks for the size-on-screen criteria (MaxDistance,
%   %   % TopScreenSize, and so on, in place of the tier distances)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_changeDisplayCriteria
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    criteria
    changes
    options.OnError = 'error'           % 'error' or 'warn'
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


        % Check the criteria input
        if ~(isstruct(criteria) && isscalar(criteria) && all(isfield(criteria,{'Region','TopScreenSize','RolesShown'})))
            error('criteria must come from fcn_AnimateCar3D_fillDisplayCriteria');
        end

        % Check the changes input
        if ~(isstruct(changes) && isscalar(changes)) && ~((ischar(changes) || isstring(changes)) && isfile(changes))
            error('changes must be a structure or the name of an existing text file');
        end

        % Check the OnError input
        if ~any(strcmp(options.OnError, {'error','warn'}))
            error('OnError must be ''error'' or ''warn''');
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


oldCriteria = criteria;
changedNames = cell(1,0);
try
    % The changes, as a structure
    if ischar(changes) || isstring(changes)
        changes = fcn_INTERNAL_readFile(char(changes), criteria);
    end

    % Every name must be a criteria name
    changeNames = fieldnames(changes)';
    unknownNames = setdiff(changeNames, fieldnames(criteria)');
    if ~isempty(unknownNames)
        error('Unknown display criteria name(s): %s', strjoin(unknownNames, ', '));
    end

    % Change them, then check the whole set
    merged = criteria;
    for ith_name = 1:numel(changeNames)
        merged.(changeNames{ith_name}) = changes.(changeNames{ith_name});
    end
    mergedArguments = namedargs2cell(merged);
    criteria = fcn_AnimateCar3D_fillDisplayCriteria(mergedArguments{:});

    allNames = fieldnames(criteria)';
    for ith_name = 1:numel(allNames)
        if ~isequaln(criteria.(allNames{ith_name}), oldCriteria.(allNames{ith_name}))
            changedNames{end+1} = allNames{ith_name}; %#ok<AGROW>
        end
    end
catch ME
    if strcmp(options.OnError,'warn')
        warning('AnimateCar3D:criteriaNotChanged', 'The display criteria were not changed: %s', ME.message);
        criteria = oldCriteria;
        changedNames = cell(1,0);
    else
        rethrow(ME);
    end
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

    plotArguments = namedargs2cell(criteria);
    fcn_AnimateCar3D_fillDisplayCriteria(plotArguments{:}, 'FigNum', figNum);
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

%% fcn_INTERNAL_readFile
function changes = fcn_INTERNAL_readFile(fileName, criteria)
% Read Name = value lines; each value is read according to the kind of
% value the criteria already has under that name
changes = struct;
fileLines = splitlines(fileread(fileName));
for ith_line = 1:numel(fileLines)
    thisLine = strtrim(fileLines{ith_line});
    if isempty(thisLine) || any(thisLine(1)=='%#')
        continue;
    end
    equalsAt = find(thisLine=='=', 1);
    if isempty(equalsAt)
        error('Line %d of %s has no "=": %s', ith_line, fileName, thisLine);
    end
    thisName = strtrim(thisLine(1:equalsAt-1));
    valueText = strtrim(thisLine(equalsAt+1:end));
    if ~isfield(criteria, thisName)
        error('Unknown display criteria name on line %d of %s: %s', ith_line, fileName, thisName);
    end
    changes.(thisName) = fcn_INTERNAL_readValue(valueText, criteria.(thisName), thisName);
end
end % Ends fcn_INTERNAL_readFile

%% fcn_INTERNAL_readValue
function value = fcn_INTERNAL_readValue(valueText, currentValue, thisName)
% One value, read as the same kind as the current one
cleanText = strtrim(regexprep(valueText, '[\[\]{}'']', ' '));
numbers = str2double(split(strtrim(regexprep(cleanText, '[,\s]+', ' '))));
flagNumbers = ~isempty(cleanText) && all(~isnan(numbers) | strcmpi(split(strtrim(regexprep(cleanText,'[,\s]+',' '))),'inf'));
if strcmp(thisName,'FixedTiers')
    pairTexts = strtrim(split(cleanText, ';'));
    pairTexts = pairTexts(~cellfun(@isempty, pairTexts));
    value = cell(numel(pairTexts), 2);
    for ith_pair = 1:numel(pairTexts)
        parts = split(strtrim(regexprep(pairTexts{ith_pair}, '[,\s]+', ' ')));
        if numel(parts)~=2
            error('FixedTiers needs pairs like "ego near; traffic middle"');
        end
        value(ith_pair,:) = parts';
    end
elseif islogical(currentValue)
    if any(strcmpi(cleanText, {'true','1','yes','on'}))
        value = true;
    elseif any(strcmpi(cleanText, {'false','0','no','off'}))
        value = false;
    else
        error('%s must be true or false', thisName);
    end
elseif iscell(currentValue)
    if isempty(cleanText)
        value = cell(1,0);
    else
        value = split(strtrim(regexprep(cleanText, '[,\s]+', ' ')))';
    end
elseif strcmp(thisName,'Center') && flagNumbers
    value = numbers(:)';
elseif ischar(currentValue) || isstring(currentValue) || isa(currentValue,'function_handle') || strcmp(thisName,'Center')
    value = cleanText;
elseif flagNumbers
    value = numbers(:)';
else
    error('%s must be a number or numbers: %s', thisName, valueText);
end
end % Ends fcn_INTERNAL_readValue

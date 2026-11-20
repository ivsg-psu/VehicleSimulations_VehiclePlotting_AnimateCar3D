function [update, watchState] = fcn_AnimateCar3D_watchFolder(folder, options)
% fcn_AnimateCar3D_watchFolder

% Watches a folder of live data: on each call (at most once every
% MinInterval seconds) it lists the folder, finds the files that are new,
% have grown or changed, or were deleted, and reads the new and changed
% ones. It returns what changed, ready for fcn_AnimateCar3D_updateCatalog
% (and fcn_AnimateCar3D_changeDisplayCriteria). The animation loop calls
% it each step; most calls return at once, with nothing checked.
%
% WHAT THE FOLDER HOLDS (files whose names start with ".", "_", or "~"
% are skipped, so a program can write a file under such a name and then
% rename it):
%
%   <instance>.csv     the motion of one object, in the CarMesh3D motion
%                      format (see fcn_CarMesh3D_loadMotionCSV: time, X,
%                      Y, yaw, and any other motion columns). The file
%                      name is the instance name. It may grow as new rows
%                      are added; it needs at least 2 rows to be read.
%   <name>.csv with an id column
%                      many objects in the long traffic format (see
%                      fcn_AnimateCar3D_loadTrafficFile: id, time, X, Y,
%                      yaw, and an optional size). Instances are
%                      <name>_<id>.
%   sceneList.csv      (optional) the scene list (see
%                      fcn_AnimateCar3D_loadSceneList): roles, meshes,
%                      colors, branches, time offsets. It may list objects
%                      whose files do not exist yet. A row's motionFile,
%                      if given, names the file in this folder that holds
%                      its motion (otherwise the file is <instance>.csv).
%                      Objects not listed get DefaultRole and
%                      DefaultMeshID.
%   displayCriteria.txt (optional) changes to the display criteria (see
%                      fcn_AnimateCar3D_changeDisplayCriteria).
%
% READING ONLY WHAT IS NEW: a motion or traffic file that has grown by
% rows added at its end is not read again whole: only the new rows are
% read (with the last row read before, so units, yaw, and at least 2
% rows carry over), and they are joined to the motions already read. A
% file being written may end partway through a row: the complete rows
% are read, and the rest is read at a later call, once complete.
%
% DELETED AND REPLACED FILES: a deleted file removes its objects (unless
% another file now holds them). A file is taken as REPLACED, and read
% again whole, if it is shorter than what was read, if its first bytes
% (the header and first rows) or the last row read have changed, if it
% has the same size but a new date, or if its new rows go back in time;
% objects no longer in it are removed. (An edit in the middle of a file
% that keeps both its first bytes and the last row read is not seen: to
% change a file, write a new one, under a name starting with "_", and
% rename it.) The scene list and the criteria file are always read whole,
% once their last row is complete. A file that cannot be read yet is
% reported in Skipped and tried again on the next check.
%
% The watcher keeps each object's motion read so far (in watchState), so
% memory grows with the data, as the catalog's does.
%
% FORMAT:
%
%       [update, watchState] = fcn_AnimateCar3D_watchFolder(folder,...
%           (WatchState=watchState), (MinInterval=seconds), (Force=flag),...
%           (DefaultMeshID=meshID), (DefaultRole=role),...
%           (SceneListName=fileName), (CriteriaName=fileName),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      folder: the folder to watch. It must exist (it may be empty).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      WatchState: the watchState output of the last call; [] (default)
%      for the first call.
%
%      MinInterval: seconds (of clock time) between checks. Default 1.
%
%      Force: true to check now, whatever the time since the last check.
%      Default false. (The first call always checks.)
%
%      DefaultMeshID, DefaultRole: for objects not in the folder's scene
%      list. Defaults 'sample' and 'traffic'.
%
%      SceneListName, CriteriaName: the names of the scene list and
%      display criteria files. Defaults 'sceneList.csv' and
%      'displayCriteria.txt'.
%
%      FigNum: a figure number to plot the motions read in this call,
%      from above. Empty (default) for no figure; -1 for fast mode (no
%      input checks).
%
% OUTPUTS:
%
%      update: a structure with fields
%           Checked: true if the folder was checked in this call
%           Add: scene list rows of objects that are new or changed (for
%               fcn_AnimateCar3D_updateCatalog's Add input). Rows changed
%               only by the scene list have no motion, so the catalog
%               keeps the motion it has.
%           Motions: the motions read (for its Motions input)
%           Remove: instances whose files were deleted (for its Remove
%               input)
%           CriteriaFile: the display criteria file, if it is new or
%               changed; '' otherwise
%           LatestTime: the latest scene time in all the live data (the
%               newest data the animation can show); -Inf if none
%           AddedFiles, ChangedFiles, DeletedFiles: file names
%           AppendedFiles: changed files of which only new rows were read
%           ReplacedFiles: changed files read again whole (see above)
%           BytesRead: the bytes read from motion and traffic files
%           Skipped: files not read in this check, with the reason
%               (structure array with fields File and Reason)
%           NumInstances: the objects now in the folder
%           CheckSeconds: the time this call took
%
%      watchState: what the next call needs to know (the files seen,
%      which objects each holds, and the folder's scene list).
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_loadSceneList, fcn_AnimateCar3D_loadTrafficFile
%      CarMesh3D: fcn_CarMesh3D_loadMotionCSV
%
% EXAMPLES:
%
%       watchState = [];
%       catalog = [];
%       while true
%           [update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState);
%           if update.Checked
%               catalog = fcn_AnimateCar3D_updateCatalog(catalog, Add=update.Add, ...
%                   Motions=update.Motions, Remove=update.Remove);
%           end
%           ... select and draw at a time up to update.LatestTime ...
%       end
%
%       See the script: script_test_fcn_AnimateCar3D_watchFolder.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_watchFolder
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_watchFolder
%   % * Reads only the new rows of a grown file; finds replaced files
%   %   (read again whole) and deleted ones; reads the complete rows of a
%   %   file whose last row is not complete

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_watchFolder
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    folder
    options.WatchState = []                 % from the last call; [] for the first
    options.MinInterval = 1                 % seconds between checks
    options.Force = false                   % check now
    options.DefaultMeshID = 'sample'        % mesh of objects not in the scene list
    options.DefaultRole = 'traffic'         % role of objects not in the scene list
    options.SceneListName = 'sceneList.csv'
    options.CriteriaName = 'displayCriteria.txt'
    options.FigNum = []                     % figure to plot what was read; -1 for fast mode
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


        % Check the folder input
        if ~(ischar(folder) || isstring(folder)) || ~isfolder(folder)
            error('folder must be an existing folder');
        end

        % Check the WatchState input
        if ~isempty(options.WatchState) && ~(isstruct(options.WatchState) && isfield(options.WatchState,'Files'))
            error('WatchState must be the watchState output of fcn_AnimateCar3D_watchFolder');
        end

        % Check the MinInterval and Force inputs
        if ~isnumeric(options.MinInterval) || ~isscalar(options.MinInterval) || options.MinInterval<0
            error('MinInterval must be a non-negative number of seconds');
        end
        if ~(islogical(options.Force) || isnumeric(options.Force)) || ~isscalar(options.Force)
            error('Force must be true or false');
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


checkTimer = tic;
folder = char(folder);
watchState = options.WatchState;
update = struct('Checked',false, 'Add',[], 'Motions',[], 'Remove',{cell(1,0)}, 'CriteriaFile','', ...
    'LatestTime',-Inf, 'AddedFiles',{cell(1,0)}, 'ChangedFiles',{cell(1,0)}, 'DeletedFiles',{cell(1,0)}, ...
    'AppendedFiles',{cell(1,0)}, 'ReplacedFiles',{cell(1,0)}, 'BytesRead',0, 'Skipped',struct('File',{}, 'Reason',{}), 'NumInstances',0, 'CheckSeconds',0);

% The first call: an empty memory
if isempty(watchState)
    watchState = struct;
    watchState.Folder = folder;
    watchState.Files = struct('Name',{}, 'Bytes',{}, 'Date',{});
    watchState.FileInstances = containers.Map('KeyType','char','ValueType','any');
    watchState.BaseRows = containers.Map('KeyType','char','ValueType','any');
    watchState.EndTimes = containers.Map('KeyType','char','ValueType','double');   % before time offsets
    watchState.Motions = containers.Map('KeyType','char','ValueType','any');       % each object's motion read so far
    watchState.FileRecords = containers.Map('KeyType','char','ValueType','any');   % how far each file was read
    watchState.LatestTime = -Inf;
    watchState.SceneRows = [];
    watchState.LastCheck = [];
    watchState.NumChecks = 0;
end

% Time to check?
if ~isempty(watchState.LastCheck) && ~options.Force && toc(watchState.LastCheck) < options.MinInterval
    update.LatestTime = watchState.LatestTime;
    update.NumInstances = watchState.EndTimes.Count;
    update.CheckSeconds = toc(checkTimer);
    return;
end
watchState.LastCheck = tic;
watchState.NumChecks = watchState.NumChecks + 1;
update.Checked = true;

%%%% 1. What is in the folder now, against what was there
listing = dir(folder);
listing = listing(~[listing.isdir]);
names = {listing.name};
flagSkipName = cellfun(@(n) any(n(1)=='._~'), names);
flagWatched = endsWith(names, '.csv', 'IgnoreCase',true) | strcmpi(names, options.CriteriaName);
listing = listing(~flagSkipName & flagWatched);
currentNames = {listing.name};
previousNames = {watchState.Files.Name};
[~, previousRow] = ismember(currentNames, previousNames);
flagAdded = previousRow==0;
flagChanged = false(size(flagAdded));
for ith_file = find(~flagAdded)
    previousFile = watchState.Files(previousRow(ith_file));
    flagChanged(ith_file) = listing(ith_file).bytes ~= previousFile.Bytes || listing(ith_file).datenum ~= previousFile.Date;
end
deletedNames = setdiff(previousNames, currentNames);
update.AddedFiles = currentNames(flagAdded);
update.ChangedFiles = currentNames(flagChanged);
update.DeletedFiles = deletedNames;
toRead = find(flagAdded | flagChanged);

% The scene list and the criteria file are read whole, so they must be
% complete (end with a line end); motion files are read up to their last
% complete row
sceneListRow = find(strcmpi(currentNames, options.SceneListName));
criteriaRow = find(strcmpi(currentNames, options.CriteriaName));
flagComplete = true(size(toRead));
for ith_read = 1:numel(toRead)
    fileName = currentNames{toRead(ith_read)};
    if ismember(toRead(ith_read), [sceneListRow criteriaRow]) && ~fcn_INTERNAL_isComplete(fullfile(folder, fileName))
        flagComplete(ith_read) = false;
        update.Skipped(end+1) = struct('File',fileName, 'Reason','the last row is not complete yet');
    end
end
toRead = toRead(flagComplete);
flagRead = false(size(currentNames));   % read successfully in this check

%%%% 2. The scene list
flagSceneListChanged = false;
for ith_read = toRead(ismember(toRead, sceneListRow))
    try
        watchState.SceneRows = fcn_AnimateCar3D_loadSceneList(fullfile(folder, currentNames{ith_read}), FigNum=-1);
        flagSceneListChanged = true;
        flagRead(ith_read) = true;
    catch ME
        update.Skipped(end+1) = struct('File',currentNames{ith_read}, 'Reason',ME.message);
    end
end
if any(strcmpi(deletedNames, options.SceneListName))
    watchState.SceneRows = [];
    flagSceneListChanged = true;
end
[listedNames, listedFiles] = fcn_INTERNAL_listedNames(watchState.SceneRows);

%%%% 3. The display criteria file
for ith_read = toRead(ismember(toRead, criteriaRow))
    update.CriteriaFile = fullfile(folder, currentNames{ith_read});
    flagRead(ith_read) = true;
end

%%%% 4. Motion files: read the new and changed ones
defaultRow = fcn_AnimateCar3D_loadSceneList(struct('instance','default', 'role',char(options.DefaultRole), ...
    'meshID',char(options.DefaultMeshID)), FigNum=-1);
addRows = repmat(defaultRow, 0, 1);
addMotions = repmat(fcn_INTERNAL_emptyMotion(''), 0, 1);
motionRows = toRead(~ismember(toRead, [sceneListRow criteriaRow]));
removeCandidates = {};
for ith_read = motionRows
    fileName = currentNames{ith_read};
    filePath = fullfile(folder, fileName);
    [~, fileStem] = fileparts(fileName);
    fileBytes = listing(ith_read).bytes;
    flagKnown = isKey(watchState.FileRecords, fileName);
    try
        % Only the new rows, if the file has grown by rows added at its end
        readKind = 'full';
        if flagKnown
            record = watchState.FileRecords(fileName);
            if fcn_INTERNAL_isAppended(filePath, record, fileBytes, watchState.Files(previousRow(ith_read)).Date, listing(ith_read).datenum)
                [chunkText, newRecord, numBytes] = fcn_INTERNAL_readAppended(filePath, record, fileBytes);
                readKind = 'append';
                if isempty(chunkText)
                    readKind = 'none';
                else
                    try
                        [motionsRead, baseRows] = fcn_INTERNAL_loadChunk(chunkText, newRecord.IsTraffic, fileName, fileStem, ...
                            listedNames, listedFiles, defaultRow, options);
                        [motionsRead, flagJoined] = fcn_INTERNAL_joinMotions(motionsRead, watchState.Motions);
                        if ~flagJoined
                            readKind = 'full';     % (new rows went back in time, or other columns)
                        end
                    catch
                        readKind = 'full';
                    end
                end
            end
        end
        if strcmp(readKind,'full')
            [chunkText, newRecord, numBytes] = fcn_INTERNAL_readWhole(filePath, fileBytes);
            if isempty(chunkText)
                readKind = 'none';
            else
                [motionsRead, baseRows] = fcn_INTERNAL_loadChunk(chunkText, newRecord.IsTraffic, fileName, fileStem, ...
                    listedNames, listedFiles, defaultRow, options);
            end
        end
    catch ME
        update.Skipped(end+1) = struct('File',fileName, 'Reason',ME.message);
        continue;
    end
    if strcmp(readKind,'none')
        update.Skipped(end+1) = struct('File',fileName, 'Reason','no complete new row yet');
        continue;
    end
    if newRecord.Offset < fileBytes
        update.Skipped(end+1) = struct('File',fileName, 'Reason','the last row is not complete yet (the rows before it were read)');
    end
    flagRead(ith_read) = true;
    update.BytesRead = update.BytesRead + numBytes;
    watchState.FileRecords(fileName) = newRecord;
    if strcmp(readKind,'append')
        update.AppendedFiles{end+1} = fileName;
    elseif flagKnown
        update.ReplacedFiles{end+1} = fileName;
    end

    % The objects in this file: a whole read gives them all (objects that
    % were in it before but are not now are removed); new rows add to them
    instancesNow = {motionsRead.Instance};
    if isKey(watchState.FileInstances, fileName)
        instancesBefore = watchState.FileInstances(fileName);
        if strcmp(readKind,'full')
            removeCandidates = [removeCandidates, setdiff(instancesBefore, instancesNow)]; %#ok<AGROW>
        else
            instancesNow = [instancesBefore, setdiff(instancesNow, instancesBefore, 'stable')];
        end
    end
    watchState.FileInstances(fileName) = instancesNow;
    for ith_motion = 1:numel(motionsRead)
        thisName = motionsRead(ith_motion).Instance;
        if strcmp(readKind,'full') || ~isKey(watchState.BaseRows, thisName)
            watchState.BaseRows(thisName) = baseRows(ith_motion);
        end
        thisRow = fcn_INTERNAL_rowFor(thisName, watchState);
        addRows(end+1,1) = thisRow; %#ok<AGROW>
        addMotions(end+1,1) = motionsRead(ith_motion); %#ok<AGROW>
        watchState.Motions(thisName) = motionsRead(ith_motion);
        watchState.EndTimes(thisName) = motionsRead(ith_motion).Time(end);
    end
end

%%%% 5. Deleted motion files; objects no file holds any more are removed
for ith_deleted = 1:numel(deletedNames)
    if isKey(watchState.FileInstances, deletedNames{ith_deleted})
        removeCandidates = [removeCandidates, watchState.FileInstances(deletedNames{ith_deleted})]; %#ok<AGROW>
        remove(watchState.FileInstances, deletedNames{ith_deleted});
    end
    if isKey(watchState.FileRecords, deletedNames{ith_deleted})
        remove(watchState.FileRecords, deletedNames{ith_deleted});
    end
end
heldNames = watchState.FileInstances.values;
heldNames = [heldNames{:}];
update.Remove = setdiff(unique(removeCandidates, 'stable'), heldNames, 'stable');
for ith_gone = 1:numel(update.Remove)
    for mapName = {'EndTimes','BaseRows','Motions'}
        if isKey(watchState.(mapName{1}), update.Remove{ith_gone})
            remove(watchState.(mapName{1}), update.Remove{ith_gone});
        end
    end
end
% (an object removed and added in the same check is only added)
if ~isempty(update.Remove) && ~isempty(addRows)
    update.Remove = setdiff(update.Remove, {addRows.Instance}, 'stable');
end

%%%% 6. A changed scene list changes the rows of every object already here
if flagSceneListChanged
    rowNames = {addRows.Instance};
    liveNames = watchState.EndTimes.keys;
    for ith_live = 1:numel(liveNames)
        if ~any(strcmp(rowNames, liveNames{ith_live}))
            addRows(end+1,1) = fcn_INTERNAL_rowFor(liveNames{ith_live}, watchState); %#ok<AGROW>
        end
    end
end

% Remember the files read (and the deleted ones are gone); a file that
% could not be read keeps its old entry, so it is tried again
newFiles = watchState.Files(~ismember(previousNames, deletedNames));
for ith_file = find(flagRead)
    thisEntry = struct('Name',currentNames{ith_file}, 'Bytes',listing(ith_file).bytes, 'Date',listing(ith_file).datenum);
    existingRow = find(strcmp({newFiles.Name}, currentNames{ith_file}), 1);
    if isempty(existingRow)
        newFiles(end+1) = thisEntry; %#ok<AGROW>
    else
        newFiles(existingRow) = thisEntry;
    end
end
watchState.Files = newFiles;

update.Add = addRows;
update.Motions = addMotions;
watchState.LatestTime = fcn_INTERNAL_latestTime(watchState);
update.LatestTime = watchState.LatestTime;
update.NumInstances = watchState.EndTimes.Count;
update.CheckSeconds = toc(checkTimer);

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
    for ith_motion = 1:numel(update.Motions)
        plot(update.Motions(ith_motion).Pose(:,1), update.Motions(ith_motion).Pose(:,2), '.-', ...
            'DisplayName', update.Motions(ith_motion).Instance);
    end
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    title(sprintf('Read %d motions; %d removed; latest time %.1f s', numel(update.Motions), ...
        numel(update.Remove), update.LatestTime), 'Interpreter','none');
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

%% fcn_INTERNAL_isComplete
function flagComplete = fcn_INTERNAL_isComplete(filePath)
% True if the file is not empty and ends with a line end
flagComplete = false;
fileID = fopen(filePath, 'r');
if fileID < 0
    return;
end
cleanup = onCleanup(@() fclose(fileID));
if fseek(fileID, -1, 'eof') ~= 0
    return;     % empty
end
lastCharacter = fread(fileID, 1, 'uint8=>double');
flagComplete = ~isempty(lastCharacter) && (lastCharacter==10 || lastCharacter==13);
end % Ends fcn_INTERNAL_isComplete

%% fcn_INTERNAL_readBytes
function bytes = fcn_INTERNAL_readBytes(filePath, startByte, numBytes)
% numBytes bytes of a file, from byte startByte (0 for the first)
bytes = zeros(1,0,'uint8');
if numBytes <= 0
    return;
end
fileID = fopen(filePath, 'r');
if fileID < 0
    error('The file could not be opened');
end
cleanup = onCleanup(@() fclose(fileID));
fseek(fileID, startByte, 'bof');
bytes = fread(fileID, numBytes, 'uint8=>uint8')';
end % Ends fcn_INTERNAL_readBytes

%% fcn_INTERNAL_isAppended
function flagAppended = fcn_INTERNAL_isAppended(filePath, record, fileBytes, previousDate, fileDate)
% True if the file is what was read before, with rows added at its end:
% no shorter, the same first bytes, the same last row read, and (if it
% has the same size) the same date
flagAppended = false;
if fileBytes < record.Offset || (fileBytes == record.Offset && fileDate ~= previousDate)
    return;
end
if ~isequal(fcn_INTERNAL_readBytes(filePath, 0, numel(record.Head)), record.Head)
    return;
end
tailStart = record.Offset - numel(record.TailLine);
flagAppended = isequal(fcn_INTERNAL_readBytes(filePath, tailStart, numel(record.TailLine)), record.TailLine);
end % Ends fcn_INTERNAL_isAppended

%% fcn_INTERNAL_readWhole
function [chunkText, record, numBytes] = fcn_INTERNAL_readWhole(filePath, fileBytes)
% The file up to its last complete row, and a record of what was read
bytes = fcn_INTERNAL_readBytes(filePath, 0, fileBytes);
lineEnds = find(bytes==10);
chunkText = '';
record = [];
numBytes = 0;
if numel(lineEnds) < 2                    % (a header and at least one row)
    return;
end
numBytes = lineEnds(end);
bytes = bytes(1:numBytes);
headerLine = strtrim(char(bytes(1:lineEnds(1))));
columnNames = strtrim(lower(split(string(headerLine), ',')));
record = struct('Offset',numBytes, 'Head',bytes(1:min(512,numBytes)), 'TailLine',bytes(lineEnds(end-1)+1:numBytes), ...
    'Header',headerLine, 'IsTraffic',any(columnNames=="id"), 'IDColumn',find(columnNames=="id",1), ...
    'IDTails',containers.Map('KeyType','char','ValueType','any'));
if record.IsTraffic
    record = fcn_INTERNAL_rememberIDTails(record, bytes(lineEnds(1)+1:end));
end
chunkText = char(bytes);
end % Ends fcn_INTERNAL_readWhole

%% fcn_INTERNAL_readAppended
function [chunkText, record, numBytes] = fcn_INTERNAL_readAppended(filePath, record, fileBytes)
% The complete rows added since the last read, after the header and the
% last row read before (of each object in a traffic file), so that
% every chunk can be read like a file
newBytes = fcn_INTERNAL_readBytes(filePath, record.Offset, fileBytes - record.Offset);
lineEnds = find(newBytes==10);
chunkText = '';
numBytes = 0;
if isempty(lineEnds)
    return;
end
numBytes = lineEnds(end);
newBytes = newBytes(1:numBytes);
if record.IsTraffic
    newIDs = fcn_INTERNAL_lineIDs(newBytes, record.IDColumn);
    overlap = zeros(1,0,'uint8');
    for thisID = unique(newIDs, 'stable')
        if isKey(record.IDTails, thisID{1})
            overlap = [overlap, record.IDTails(thisID{1})]; %#ok<AGROW>
        end
    end
    if record.IDTails.Count > 0                             % (a copy, not a handle to the old one)
        record.IDTails = containers.Map(record.IDTails.keys, record.IDTails.values);
    else
        record.IDTails = containers.Map('KeyType','char','ValueType','any');
    end
    record = fcn_INTERNAL_rememberIDTails(record, newBytes);
else
    overlap = record.TailLine;
end
chunkText = [record.Header newline char(overlap) char(newBytes)];
record.Offset = record.Offset + numBytes;
newLineEnds = [0 lineEnds];
record.TailLine = newBytes(newLineEnds(end-1)+1:numBytes);
end % Ends fcn_INTERNAL_readAppended

%% fcn_INTERNAL_lineIDs
function ids = fcn_INTERNAL_lineIDs(bytes, idColumn)
% The id of each row (bytes of whole rows)
rows = splitlines(strtrim(string(char(bytes))));
rows = rows(strlength(rows) > 0);
parts = split(rows, ',', 2);
if isvector(parts) && numel(rows)==1
    parts = parts(:)';
end
ids = cellstr(strtrim(parts(:, idColumn)))';
end % Ends fcn_INTERNAL_lineIDs

%% fcn_INTERNAL_rememberIDTails
function record = fcn_INTERNAL_rememberIDTails(record, bytes)
% The last row of each object in a traffic file (bytes of whole rows)
lineEnds = find(bytes==10);
lineStarts = [1 lineEnds(1:end-1)+1];
ids = fcn_INTERNAL_lineIDs(bytes, record.IDColumn);
[uniqueIDs, lastRow] = unique(ids, 'last');
for ith_id = 1:numel(uniqueIDs)
    record.IDTails(uniqueIDs{ith_id}) = bytes(lineStarts(lastRow(ith_id)):lineEnds(lastRow(ith_id)));
end
end % Ends fcn_INTERNAL_rememberIDTails

%% fcn_INTERNAL_loadChunk
function [motionsRead, baseRows] = fcn_INTERNAL_loadChunk(chunkText, flagTraffic, fileName, fileStem, listedNames, listedFiles, defaultRow, options)
% Read the motions in a chunk (a header and whole rows), through a
% temporary file, with the same readers as a whole file
chunkFile = [tempname '.csv'];
fileID = fopen(chunkFile, 'w');
fwrite(fileID, chunkText);
fclose(fileID);
cleanup = onCleanup(@() delete(chunkFile));
if flagTraffic
    [fileRows, fileMotions] = fcn_AnimateCar3D_loadTrafficFile(chunkFile, MeshID=char(options.DefaultMeshID), ...
        Role=char(options.DefaultRole), InstancePrefix=[fileStem '_'], FigNum=-1);
    baseRows = fileRows;
    motionsRead = repmat(fcn_INTERNAL_emptyMotion(''), numel(fileMotions), 1);
    for ith_motion = 1:numel(fileMotions)
        motionsRead(ith_motion) = fcn_INTERNAL_normalizeMotion(fileMotions(ith_motion), fileMotions(ith_motion).Instance);
    end
else
    fileIndex = find(strcmpi(listedFiles, fileName), 1);
    if isempty(fileIndex)
        instanceName = fileStem;
    else
        instanceName = listedNames{fileIndex};
    end
    readMotion = fcn_CarMesh3D_loadMotionCSV(chunkFile, FigNum=-1);
    motionsRead = fcn_INTERNAL_normalizeMotion(readMotion, instanceName);
    baseRows = defaultRow;
    baseRows.Instance = instanceName;
end
end % Ends fcn_INTERNAL_loadChunk

%% fcn_INTERNAL_joinMotions
function [joined, flagJoined] = fcn_INTERNAL_joinMotions(newMotions, storedMotions)
% Join the rows read now to each object's motion read before. The
% chunk starts with the last row read before: rows at or before that
% time are dropped, and yaw is shifted by whole turns to match it. Not
% joined (flagJoined false) if new rows go back in time or the columns
% differ. Wheel spin (summed by the motion reader from the start of what
% it reads) carries on from its last value. Values the reader works out
% from neighboring rows (steering and speed from the path, when the file
% does not give them) may differ slightly at the row where chunks meet.
joined = newMotions;
flagJoined = true;
fieldNames = {'Time','Pose','WheelSpin','SteerAngle','WheelLift','BodyRoll','BodyPitch','BodyHeave','LightStates'};
for ith_motion = 1:numel(newMotions)
    thisName = newMotions(ith_motion).Instance;
    if ~isKey(storedMotions, thisName)
        continue;                           % a new object: all its rows are new
    end
    oldMotion = storedMotions(thisName);
    newMotion = newMotions(ith_motion);
    lastTime = oldMotion.Time(end);
    flagOverlap = abs(newMotion.Time - lastTime) <= 1e-9;
    flagKeep = newMotion.Time > lastTime + 1e-9;
    if any(~flagOverlap & ~flagKeep) || size(newMotion.Pose,2) ~= size(oldMotion.Pose,2)
        flagJoined = false;
        return;
    end
    if any(flagOverlap)
        overlapRow = find(flagOverlap,1);
        yawColumn = size(newMotion.Pose,2);
        yawShift = 2*pi*round((oldMotion.Pose(end,yawColumn) - newMotion.Pose(overlapRow,yawColumn))/(2*pi));
        newMotion.Pose(:,yawColumn) = newMotion.Pose(:,yawColumn) + yawShift;
        % Wheel spin is summed from the start of what is read: carry on
        % from where it was
        if ~isempty(newMotion.WheelSpin) && ~isempty(oldMotion.WheelSpin) && size(newMotion.WheelSpin,2)==size(oldMotion.WheelSpin,2)
            newMotion.WheelSpin = newMotion.WheelSpin + (oldMotion.WheelSpin(end,:) - newMotion.WheelSpin(overlapRow,:));
        end
    end
    for ith_field = 1:numel(fieldNames)
        oldValue = oldMotion.(fieldNames{ith_field});
        newValue = newMotion.(fieldNames{ith_field});
        if isempty(oldValue) && isempty(newValue)
            continue;
        end
        if isempty(oldValue) ~= isempty(newValue) || size(oldValue,2) ~= size(newValue,2)
            flagJoined = false;
            return;
        end
        try
            joined(ith_motion).(fieldNames{ith_field}) = [oldValue; newValue(flagKeep,:)];
        catch
            flagJoined = false;
            return;
        end
    end
end
end % Ends fcn_INTERNAL_joinMotions

%% fcn_INTERNAL_emptyMotion
function motion = fcn_INTERNAL_emptyMotion(instanceName)
% One motion, with every field the catalog reads
motion = struct('Instance',instanceName, 'Time',zeros(0,1), 'Pose',zeros(0,6), 'WheelSpin',[], ...
    'SteerAngle',[], 'WheelLift',[], 'BodyRoll',[], 'BodyPitch',[], 'BodyHeave',[], 'LightStates',[]);
end % Ends fcn_INTERNAL_emptyMotion

%% fcn_INTERNAL_normalizeMotion
function motion = fcn_INTERNAL_normalizeMotion(inputMotion, instanceName)
% The same fields for every motion, so they can be joined
motion = fcn_INTERNAL_emptyMotion(instanceName);
motion.Time = double(inputMotion.Time(:));
motion.Pose = double(inputMotion.Pose);
for fieldName = {'WheelSpin','SteerAngle','WheelLift','BodyRoll','BodyPitch','BodyHeave','LightStates'}
    if isfield(inputMotion, fieldName{1})
        motion.(fieldName{1}) = inputMotion.(fieldName{1});
    end
end
end % Ends fcn_INTERNAL_normalizeMotion

%% fcn_INTERNAL_listedNames
function [listedNames, listedFiles] = fcn_INTERNAL_listedNames(sceneRows)
% The instances in the folder's scene list, and the file each names
% (just the name and extension; '' if none)
if isempty(sceneRows)
    listedNames = {};
    listedFiles = {};
    return;
end
listedNames = {sceneRows.Instance};
listedFiles = cell(size(listedNames));
for ith_row = 1:numel(sceneRows)
    [~, fileStem, fileExtension] = fileparts(sceneRows(ith_row).MotionFile);
    listedFiles{ith_row} = [fileStem fileExtension];
end
end % Ends fcn_INTERNAL_listedNames

%% fcn_INTERNAL_rowFor
function thisRow = fcn_INTERNAL_rowFor(instanceName, watchState)
% An object's scene row: its row in the folder's scene list if listed
% (with the size from its file where the list gives none), otherwise
% the row made when its file was read. The motion file is left empty:
% the motion is given in memory.
thisRow = watchState.BaseRows(instanceName);
if ~isempty(watchState.SceneRows)
    listedIndex = find(strcmp({watchState.SceneRows.Instance}, instanceName), 1);
    if ~isempty(listedIndex)
        fileSize = thisRow.Size;
        thisRow = watchState.SceneRows(listedIndex);
        if all(isnan(thisRow.Size))
            thisRow.Size = fileSize;
        end
    end
end
thisRow.MotionFile = '';
end % Ends fcn_INTERNAL_rowFor

%% fcn_INTERNAL_latestTime
function latestTime = fcn_INTERNAL_latestTime(watchState)
% The latest scene time in the live data (each object's last time plus
% its time offset)
latestTime = -Inf;
liveNames = watchState.EndTimes.keys;
for ith_live = 1:numel(liveNames)
    thisRow = fcn_INTERNAL_rowFor(liveNames{ith_live}, watchState);
    latestTime = max(latestTime, watchState.EndTimes(liveNames{ith_live}) + thisRow.TimeOffset);
end
end % Ends fcn_INTERNAL_latestTime

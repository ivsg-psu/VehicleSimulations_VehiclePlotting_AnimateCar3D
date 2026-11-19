
%% Introduction to and Purpose of the Code
% This is the explanation of the code that can be found by running
%       script_demo_AnimateCar3D.m
% This is a script to demonstrate the functions within the AnimateCar3D code
% library. This code repo is typically located at:
%   https://github.com/ivsg-psu/VehicleSimulations_VehiclePlotting_AnimateCar3D
%
% If you have questions or comments, please contact Sean Brennan at
% sbrennan@psu.edu
%
% The purpose of the code is animate mesh representations of vehicles in 3D
% scenes, quickly, without needing to install extra toolboxes or use 3D
% immersive visualization toolsets (CARLA, RoadRunner, Simscape, etc.).
%
% AnimateCar3D uses the CarMesh3D library for its vehicle meshes and its
% single-vehicle plotting functions. By default, the released CarMesh3D
% installed in the Utilities folder is used. To develop both libraries at
% the same time, set flag_useWorkingCarMesh3D = 1 below (or set the
% environment variable ANIMATECAR3D_CARMESH3D_PATH to a CarMesh3D folder)
% to use a working copy of CarMesh3D instead. Either way, exactly one copy
% of CarMesh3D is left on the MATLAB path.

% REVISION HISTORY:
% 
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_AnimateCar3D
%   % * First prototype of the library (drafted with Claude)
%   % * Core include repos are: {'CarMesh3D'}
%   % * Naming: each function fcn_AnimateCar3D_<name> is tested by
%   %   % script_test_fcn_AnimateCar3D_<name> in the Functions folder;
%   %   % scripts that demonstrate the code more generally are named
%   %   % script_AnimateCar3D_<name>
%   % * Removed the BreakDataIntoLaps template leftovers
%   % * Exactly one copy of CarMesh3D is kept on the path: the installed
%   %   % release (default), or a working copy (flag_useWorkingCarMesh3D)


% TO-DO:
% - 2026_11_19 by Sean Brennan, sbrennan@psu.edu
%   % * Need to add to-do items here


%% Make sure we are running out of root directory
st = dbstack; 
thisFile = which(st(1).file);
[filepath,name,ext] = fileparts(thisFile);
cd(filepath);

%% Choose which copy of CarMesh3D to use
% 0: the released CarMesh3D installed in Utilities (default)
% 1: a working copy, for developing CarMesh3D and AnimateCar3D together.
%    The working copy is workingCarMesh3DFolder below, or, if that is
%    empty, the folder in the environment variable
%    ANIMATECAR3D_CARMESH3D_PATH, or, if that is empty too, a CarMesh3D
%    folder next to this one.
flag_useWorkingCarMesh3D = 0;
workingCarMesh3DFolder = '';
if ~isempty(getenv('ANIMATECAR3D_CARMESH3D_PATH'))
	flag_useWorkingCarMesh3D = 1;
end

%% START OF STANDARD INSTALLER CODE %%%%%%%%%

%%% Clear paths and folders, if needed
if 1==1
	clear flag_AnimateCar3D_Folders_Initialized
end

if 1==0
	fcn_INTERNAL_clearUtilitiesFromPathAndFolders;
end

if 1==0
	% Resets all paths to factory default
	restoredefaultpath;
end


% Do we need to set up the work space?
if ~exist('flag_AnimateCar3D_Folders_Initialized','var') || 0==flag_AnimateCar3D_Folders_Initialized
	fcn_INTERNAL_setupWorkspace;
	flag_AnimateCar3D_Folders_Initialized = 1;
else
	fprintf(1,'Skipping installs as it appears this was completed previously in this session.\n');
end

%%%% END OF STANDARD INSTALLER CODE %%%%%%%%%

%% Keep exactly one copy of CarMesh3D on the path
% Done on every run (it is fast), since other work in the same MATLAB
% session may have added another copy of CarMesh3D to the path
carMesh3DRoot = fcn_INTERNAL_selectCarMesh3DCopy(flag_useWorkingCarMesh3D, workingCarMesh3DFolder);


%% Check if repo is ready for release
if 1==0
	figNum = 999999;
	repoShortName = '_ANIMATECAR3D_';
	fcn_DebugTools_testRepoForRelease(repoShortName, (figNum));
end

%% Start of Demo Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____ _             _            __   _____                          _____          _
%  / ____| |           | |          / _| |  __ \                        / ____|        | |
% | (___ | |_ __ _ _ __| |_    ___ | |_  | |  | | ___ _ __ ___   ___   | |     ___   __| | ___
%  \___ \| __/ _` | '__| __|  / _ \|  _| | |  | |/ _ \ '_ ` _ \ / _ \  | |    / _ \ / _` |/ _ \
%  ____) | || (_| | |  | |_  | (_) | |   | |__| |  __/ | | | | | (_) | | |___| (_) | (_| |  __/
% |_____/ \__\__,_|_|   \__|  \___/|_|   |_____/ \___|_| |_| |_|\___/   \_____\___/ \__,_|\___|
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Start%20of%20Demo%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Welcome to the demo code for the AnimateCar3D library!')
fprintf(1,'Using CarMesh3D from: %s\n', carMesh3DRoot);


%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%§

%% function fcn_INTERNAL_clearUtilitiesFromPathAndFolders
function fcn_INTERNAL_clearUtilitiesFromPathAndFolders
% Clear out the variables
clear global flag* FLAG*
clear flag*
clear path

% Clear out any path directories under Utilities
path_dirs = regexp(path,'[;]','split');
utilities_dir = fullfile(pwd,filesep,'Utilities');
for ith_dir = 1:length(path_dirs)
    utility_flag = strfind(path_dirs{ith_dir},utilities_dir);
    if ~isempty(utility_flag)
        rmpath(path_dirs{ith_dir});
    end
end

% Delete the Utilities folder, to be extra clean!
if  exist(utilities_dir,'dir')
    [status,message,message_ID] = rmdir(utilities_dir,'s');
    if 0==status
        error('Unable remove directory: %s \nReason message: %s \nand message_ID: %s\n',utilities_dir, message,message_ID);
    end
end

end % Ends fcn_INTERNAL_clearUtilitiesFromPathAndFolders

%% function fcn_INTERNAL_checkForPriorDebugInstall
function [flag_previousInstallFound, func_handle_addSubdirectoriesToPath, func_handle_autoInstallRepos, func_handle_isThisComputerOnline] = fcn_INTERNAL_checkForPriorDebugInstall

% Initialize default outputs
flag_previousInstallFound = false;
func_handle_addSubdirectoriesToPath = [];
func_handle_autoInstallRepos  = [];
func_handle_isThisComputerOnline  = [];

% Navigate to the Utilities directory
utilitiesFolderSearch = fullfile(pwd,'Utilities');
if exist(utilitiesFolderSearch,'dir')
	dirCommand = fullfile(utilitiesFolderSearch,'DebugTools*.');
	debugsInstalled = dir(dirCommand);

	% Were any DebugTools installs found?
	if ~isempty(debugsInstalled)
		flag_previousInstallFound = true; % Mark flag that it was found
		mostRecentDebugInstall = fullfile(debugsInstalled(end).folder,debugsInstalled(end).name,'Functions');

		currentFolder = pwd; % Save the current folder

		cd(mostRecentDebugInstall); % Move into the utilities folder

		% Create a function handles
		func_handle_addSubdirectoriesToPath = @fcn_DebugTools_addSubdirectoriesToPath;
		func_handle_autoInstallRepos = @fcn_DebugTools_autoInstallRepos;
		func_handle_isThisComputerOnline = @fcn_DebugTools_isThisComputerOnline;

		% Return to the root directory
		cd(currentFolder);
	end
end
end % Ends fcn_INTERNAL_checkForPriorDebugInstall


%% function fcn_INTERNAL_checkForAutoinstall
function [flag_previousInstallFound, func_handle_autoInstallRepos] = fcn_INTERNAL_checkForAutoinstall

flag_previousInstallFound = false;

% Navigate to the Utilities directory
autoinstallFolderSearch = fullfile(pwd,'Installer');
if exist(autoinstallFolderSearch,'dir')
	flag_previousInstallFound = true;% Set flag to indicate it was found
	currentFolder = pwd; % Save the current folder
	cd(autoinstallFolderSearch); % Move into the Installer folder
	func_handle_autoInstallRepos = @fcn_DebugTools_autoInstallRepos; % Create function handle
	cd(currentFolder); % Return to the root directory
end
end % fcn_INTERNAL_checkForAutoinstall


%% fcn_INTERNAL_selectCarMesh3DCopy
function carMesh3DRoot = fcn_INTERNAL_selectCarMesh3DCopy(flag_useWorkingCopy, workingFolder)
% Removes every CarMesh3D folder from the MATLAB path, then adds back only
% the chosen copy: the newest release in Utilities (CarMesh3D_<date>), or
% a working copy. Checks that MATLAB then finds exactly one copy of the
% CarMesh3D functions, and returns the root folder of that copy.
%
% A path entry belongs to a CarMesh3D copy if one of its folder names is
% CarMesh3D or starts with CarMesh3D_ (as releases in Utilities do).

% Which copy?
if flag_useWorkingCopy
	if isempty(workingFolder)
		workingFolder = getenv('ANIMATECAR3D_CARMESH3D_PATH');
	end
	if isempty(workingFolder)
		workingFolder = fullfile(fileparts(pwd),'CarMesh3D');
	end
	carMesh3DRoot = char(workingFolder);
	sourceDescription = 'working copy';
else
	releases = dir(fullfile(pwd,'Utilities','CarMesh3D_*'));
	releases = releases([releases.isdir]);
	if isempty(releases)
		error('No CarMesh3D release was found in %s. Run this script while online so that it can be installed.', fullfile(pwd,'Utilities'));
	end
	releaseNames = sort({releases.name});   % Dated names, so the last is the newest
	carMesh3DRoot = fullfile(pwd,'Utilities',releaseNames{end});
	sourceDescription = sprintf('release %s', releaseNames{end});
end
if ~isfolder(fullfile(carMesh3DRoot,'Functions'))
	error('The CarMesh3D folder %s has no Functions folder. Check the folder name.', carMesh3DRoot);
end

% Remove every CarMesh3D folder from the path
pathEntries = strsplit(path, pathsep);
flagCarMesh3D = false(size(pathEntries));
for ith_entry = 1:length(pathEntries)
	folderNames = regexp(pathEntries{ith_entry}, '[\\/]', 'split');
	flagCarMesh3D(ith_entry) = any(strcmp(folderNames,'CarMesh3D') | startsWith(folderNames,'CarMesh3D_'));
end
if any(flagCarMesh3D)
	rmpath(pathEntries{flagCarMesh3D});
end

% Add back only the chosen copy
addpath(genpath(fullfile(carMesh3DRoot,'Functions')));
if isfolder(fullfile(carMesh3DRoot,'Data'))
	addpath(genpath(fullfile(carMesh3DRoot,'Data')));
end

% Check that exactly one copy is found
foundCopies = which('fcn_CarMesh3D_plotVehicle','-all');
if length(foundCopies)~=1 || ~startsWith(foundCopies{1}, carMesh3DRoot)
	error('Expected exactly one copy of CarMesh3D, from %s, but found:\n%s', carMesh3DRoot, strjoin(foundCopies, newline));
end
fprintf(1,'CarMesh3D: using the %s (%s)\n', sourceDescription, carMesh3DRoot);

% Let AnimateCar3D functions and tests know which copy is in use
setenv('MATLABFLAG_ANIMATECAR3D_CARMESH3D_ROOT', carMesh3DRoot);
end % Ends fcn_INTERNAL_selectCarMesh3DCopy


%% fcn_INTERNAL_setupWorkspace
function fcn_INTERNAL_setupWorkspace 

%% Install dependencies
% Define a universal resource locator (URL) pointing to the repos of
% dependencies to install. Note that DebugTools is always installed
% automatically, first, even if not listed:
ith_repo = 0;



ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/VehicleSimulations_VehiclePlotting_CarMesh3D';
dependencySubfolders{ith_repo} = {'Functions','Data'};
dependencyInstallRootName{ith_repo} = 'CarMesh3D';
dependencySubdependencyRootNames{ith_repo} = {}; %#ok<NASGU>

% Check if prior installs exist
[flag_previousDebugFound, func_handle_addSubdirectoriesToPath, func_handle_autoInstallReposDebug, func_handle_isThisComputerOnline] = fcn_INTERNAL_checkForPriorDebugInstall;
[flag_previousAutoinstallFound, func_handle_autoInstallReposAutoinstall] = fcn_INTERNAL_checkForAutoinstall;

if ~flag_previousDebugFound && ~flag_previousAutoinstallFound
	error('Installers are missing. Irrecoverable error!');
else
	% Decide which autoInstaller to use, defaulting to the most recent
	% one
	if flag_previousDebugFound
		func_handle_autoInstallRepos = func_handle_autoInstallReposDebug;
	else
		func_handle_autoInstallRepos = func_handle_autoInstallReposAutoinstall;
	end
end

% Check if online?
if flag_previousDebugFound
	flag_isOnline = func_handle_isThisComputerOnline();
else
	flag_isOnline = true; % Default to assuming online
end

% If computer is onffline, install folders manually
if ~flag_isOnline
	fprintf(1,'This computer appears to be offline. The code will be run with libraries that are already installed. However, any updates to these libraries including bug fixes may be missed. Use code with caution!\n');
	fprintf(1,'Press any key to continue.\n');
	% pause;

	if ~flag_previousDebugFound
		error('Computer appears offline and no prior installs found of debug folders. A prior install of this folder is needed to proceed. Quitting.');
	end
	pathToSearch = fullfile(pwd,'Utilities');
	subfolders = dir(pathToSearch);
	subfolders = subfolders([subfolders.isdir]);
	namedSubfolders = subfolders(~ismember({subfolders.name},{'.','..'}));
	existingFolderNameList = {namedSubfolders.name}';

	dependencyInstallRootName = [{'DebugTools'},dependencyInstallRootName(:)']';
	dependencySubfolders      = [{{'Functions','Data'}},dependencySubfolders(:)']';
	% Add each locally available dependency to the MATLAB path
	for ith_repo = 1:length(dependencyInstallRootName)
		thisRootName = dependencyInstallRootName{ith_repo};

		if ~contains(existingFolderNameList,thisRootName)
			error('A required dependency, named %.s, was not found among the packages already installed in the Utilities folder. A prior install of this folder is needed to proceed. Quitting.',thisRootName);
		else
			folderIndexToAdd = find(contains(existingFolderNameList,thisRootName),1);
		end

		fprintf(1,'\tAdding already installed library to the path: %s\n',namedSubfolders(folderIndexToAdd).name);
		thisFolderRoot = fullfile(namedSubfolders(folderIndexToAdd).folder,namedSubfolders(folderIndexToAdd).name);
		func_handle_addSubdirectoriesToPath(thisFolderRoot,dependencySubfolders{ith_repo});
	end

else
	% Clear prior global variable flags
	clear global FLAG_*

	% Call the function to do the install
	func_handle_autoInstallRepos(dependencyURLs, dependencySubfolders, (0), (-1));
end

% Add this function's folders to the path
this_project_folders = {...
	'Functions','Data'};
fprintf(1,'\tAdding this project folders to the path: \n');
for ith_folder = 1:length(this_project_folders)
	thisFolder = this_project_folders{ith_folder};
	fprintf(1,'\t\tAdding subfolder: %s\n',thisFolder);
end
fcn_DebugTools_addSubdirectoriesToPath(pwd,this_project_folders)


%% Set environment flags for input checking in AnimateCar3D library
% These are values to set if we want to check inputs or do debugging
setenv('MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS','1');
setenv('MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG','0');

%% Set up warnings
thisVersion = version('-release');
thisVersionYear = str2double(thisVersion(1:4));

% Confirm that this is 2025b
if ~strcmpi(thisVersion,'2025b')

	% Save current backtrace state, turn it off, issue the warning, then restore
	saved = warning("query","backtrace");
	warning("off","backtrace");
	if thisVersionYear<2025
		warning('Expected release versions 2025a or 2025b, but found older release %s instead.',thisVersion);
		fcn_DebugTools_cprintf('*red','Many errors may be introduced by using an older MATLAB version.\n Students using out-of-date versions are far more likely to face additional challenges in completing assignments.\n');
    elseif thisVersionYear>2025
		warning('Expected release versions 2025a or 2025b, but found newer release %s instead.',thisVersion);
		fcn_DebugTools_cprintf('*red','Newer versions have not been tested yet but should work.\nStudents are asked to report any code discrepancies so that the code can remain up-to-date!.\n');
	end
	warning(saved);
	fprintf(1,'Press any key to continue.\n');
	pause;
end

thisPath = pwd;

% Confirm that path contains no spaces
if contains(thisPath,' ')
	warning('A space character was found in the working path: %s. Spaces in file names and paths can cause evaluation errors in some of the functions within this code set.',thisPath);
	fcn_DebugTools_cprintf('*red','Please consider installing the code into a folder that has no spaces.');
	fprintf(1,'Press any key to continue.\n');
	pause;
end

% Confirm that path contains no minus signs
if contains(thisPath,'-')
	warning('A minus character was found in the working path: %s. Minus signs in file names and paths will cause evaluation errors in some of the functions within this code set.',thisPath);
	fcn_DebugTools_cprintf('*red','Please re-install the code into a folder that has no minus signs in the path name.');
	fprintf(1,'Press any key to continue.\n');
	pause;
end


% %% Create Submissions folder
% if ~exist(fullfile(pwd,'Submissions'),'dir')
% 	mkdir('Submissions');
% end
% 
% %% Create StudentWork folder
% if ~exist(fullfile(pwd,'StudentWork'),'dir')
% 	mkdir('StudentWork');
% end

end % Ends fcn_INTERNAL_setupWorkspace


%%% This function converts a series of XYZ coordinates into a path filament
%%% cropping model (filamentWithTorsion) for Dynamo.
%%%
%%% At minimum, it requires the target catalogue name.
%%% i.e., crop_table = pts_to_filament('catalogueName');
%%%
%%% At maximum, it takes the catalogue name, dz, dphi
%%% i.e., crop_table = pts_to_filament('catalogueName', dz, dphi)
%%%         dz is the step between cropping points in pixels
%%%         dphi is the change in rotation about the helical axis
%%%
%%% maybe set dz to the subunit rise and dphi to the twist of known helical parameters
%%% Or, maybe set dz to the rise of a fill turn and dphi to the pitch
%%%         default dz = 2
%%%         default dphi = 60
%%%
%%% The file names should follow the convention
%%% *_#_*_#_*.xyz
%%% The first '#' is taken to be the catalogue index for the cognate
%%% tomogram and the second '#' the filament number in that tomogram. 
%%%
%%% Author: (TL UCSD 2020)
function [crop_table] = pts_to_filament(catalogueName, dz, dphi)

% Check user inputs
if nargin > 3
    error('pts_to_filament(): Too many inputs, takes 3 at most')
end

if ~exist(catalogueName, 'dir')
    error('Could not find specified catalogue, make sure path is correct')
end

% Fill optional inputs with default values
switch nargin
    case 1
        dz = 2;
        dphi = 60;
    case 2
        dphi = 60;
end


% Have user open directory
fprintf('****Select IMOD coordinates directory in dialogue window****\n\n\n')
imodDir = uigetdir('Select IMOD coordinates directory');

% Get requisite files into a struct
pointsFiles = dir(fullfile(imodDir,'*.xyz'));

% Create a figure
figure(1);
clf;

% Get number of models
N = length(pointsFiles);
% Number of rows for sub-ploting
spRows = ceil(N/4);

% read in catalogue
catCall = sprintf('%s.ctlg', catalogueName);
dynCat = dread(catCall);

% Pre-allocate cell array holding matrices for generating the cropping table later
tm = cell(1,N);

counter=1; % Loop counter
for i = 1:N
    
    % Parse file names for ease later and for indicies
    % Points
    pFileName = pointsFiles(i).name;
    pFullFileName = fullfile(imodDir, pFileName);
    
    % Indicies
    splitName = split(pFileName, '_');
    vIdx = str2double(splitName(2));
    mIdx = str2double(splitName(4));
    
    % Indicate which file that is being worked on
    fprintf('Now processing files %s\n', pFileName) 
    
    % Initialize a dynanmo membraneByLevels model and add points
    m = dmodels.filamentWithTorsion;
   
    % Read in files are point cloud models
    tmpP = dynamo_model_import('xyz', pFullFileName);
    
    % Fill membraneByLevelsModel
    m.points = tmpP.points;
    
    % Cosmetics
    m.marker_size = 3;
    
    % Name the model
    modelName = sprintf('filament_vol_%d_mod_%d',vIdx,mIdx); 
    modelFileName = sprintf('%s.omd', modelName);
    m.name = modelName;
    m.file = modelFileName;

    % Creation of eqispaced control points
    m.backboneUpdate();

    m.subunits_dz = dz;
    m.subunits_dphi = dphi;

    m.updateCrop();

    % Link to target volume and save
    m.linkCatalogue(catalogueName,'i',vIdx);
    m.saveInCatalogue();
   
    fprintf('Finished and saved %s to catalogue\n', modelName)
    
    % Plotting each filament on a subplot
    h = subplot(spRows,4,i);
    
    m.plotPoints(h,'refresh',false,'hold_limits',false);        % plots points delivered by the user
    m.plotTablePoints(h,'refresh',false,'hold_limits',false);   % plots computed table Points
    m.plotTableSketch(h,'refresh',false,'hold_limits',false);
    
    % name each subplot by the model
    t = sprintf('Vol-%d filament-%d', vIdx,mIdx);
    title(t);
    axis(h, 'equal');
    
    % update plot
    drawnow;

    % Extract cropping table
    tm{counter} = m.grepTable();
    tm{counter} (:,13) = dynCat.volumes{vIdx}.ftype;
    tm{counter} (:,14) = dynCat.volumes{vIdx}.ytilt(1);
    tm{counter} (:,15) = dynCat.volumes{vIdx}.ytilt(2);
    tm{counter} (:,20) = vIdx;	% volume index
    tm{counter} (:,21) = counter; 	% filament index
   
    % Increment counter
    counter=counter+1;
    
end

% Merge cropping tables
crop_table = dynamo_table_merge(tm, 'linear_tags', 1);

% Write out cropping table
crop_table_name = sprintf('filament_dz%d_dphi%d.tbl', dz, dphi);
dwrite(crop_table, crop_table_name);

% Set figure name
set(gcf,'Name','Path Filament Models');

fprintf('\n\nConverted all files to filamentWithTorsions models for cropping!\n')

fprintf('Points cropped every: %d pixels \n', dz)

fprintf('Succesive points rotated by : %d degrees \n', dphi)

fprintf('Wrote out cropping table as: %s \n', crop_table_name)

fprintf('Done!\n\n')


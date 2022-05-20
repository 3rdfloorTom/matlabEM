%%% This function converts a series of XYZ coordinates into a surface
%%% cropping model for Dynamo.
%%%
%%% At minimum, it requires the target catalogue name.
%%% i.e., pts_to_membrane_model('catalogueName');
%%%
%%% It also accepts control point interval and mesh parameter as arguements
%%% i.e., pts_to_membrane_model('catalogueName', 25, 5);
%%% Otherwise it just uses default values.
%%%
%%% Upon running, a file explorer will open for the user to select the
%%% directory containing the .txt files specifying the surface point-clouds
%%% and centers. Cognate point-clouds and centers are expected to share the
%%% same rootname. The file names should follow the convention
%%% volume_#_model_#_points.txt, volume_#_model_#_center.txt
%%% The first '#' is taken to be the catalogue index for the cognate
%%% tomogram. 
%%%
%%% Author: TL (UCSD 2020)
function [crop_table] = pts_to_membrane_model(catalogueName, controlInterval, meshParameter)

% Check user inputs
if nargin > 3
    error('pts_to_membrane_model(): Too many inputs, takes 3 at most')
end

if ~exist(catalogueName, 'dir')
    error('Could not find specified catalogue, make sure path is correct')
end

% Fill optional inputs with default values
switch nargin
    case 1
        controlInterval = 25;
        meshParameter = 5;
    case 2
        
        meshParameter = 5;
end


% Have user open directory
fprintf('*****Select IMOD coordinates directory in dialogue window*****\n\n\n')
imodDir = uigetdir('Select IMOD coordinates directory');

% Get requisite files into a struct
pointsFiles = dir(fullfile(imodDir,'*_points.txt'));
centerFiles = dir(fullfile(imodDir,'*_center.txt'));


% Get number of models
N = length(pointsFiles);
% Number of columns and rows for sub-ploting
spCol = 4;
spRows = ceil(N/spCol);

% Create a figure
figure(1);
clf;

% Read catalogue
catCall = sprintf('%s.ctlg', catalogueName);
dynCat = dread(catCall);


% Pre-allocate table holding variable for speed
tm = cell(1,N);

counter=1;  % Loop counter
for i = 1:N
    
    % Parse file names for ease later and for indicies
    % Points
    pFileName = pointsFiles(i).name;
    pFullFileName = fullfile(imodDir, pFileName);
    
    % Centers
    cFileName = centerFiles(i).name;
    cFullFileName = fullfile(imodDir, cFileName);
    
    % Indicies
    splitName = split(pFileName, '_');
    vIdx = str2double(splitName(2));
    mIdx = str2double(splitName(4));
    
    % Indicate which file that is being worked on
    fprintf('Now processing files %s\n', pFileName) 
    
    % Initialize a dynanmo membraneByLevels model and add points
    m = dmodels.membraneByLevels;
   
    % Read in files are point cloud models
    tmpP = dynamo_model_import('xyz', pFullFileName);
    tmpC = dynamo_model_import('xyz', cFullFileName);
    
    % Fill membraneByLevelsModel
    m.points = tmpP.points;
    m.center = tmpC.points;
    
    % Make parse points into levels (guess direction)
    m.stratify;
    
    % Cosmetics
    m.marker_size = 2;
    
    % Name the model
    modelName = sprintf('memByLvl_vol_%d_mod_%d',vIdx,mIdx); 
    modelFileName = sprintf('%s.omd', modelName);
    m.name = modelName;
    m.file = modelFileName;

    % Creation of eqispaced control points
    m.control_interval = controlInterval;
    m.controlUpdate();

    % Create and refine depiction mesh
    m.createMesh();
    m.refineMesh();
    m.refineMesh();

    % Create the cropping mesh
    % Parameter below is essentially particle spacing
    m.crop_mesh_parameter = meshParameter;
    m.createCropMesh();
    %m.refineMesh();
    m.updateCrop();

    % Link to target volume and save
    m.linkCatalogue(catalogueName,'i',vIdx);
    m.saveInCatalogue();
   
    fprintf('Finished and saved %s to catalogue\n', modelName)
    
   % Plotting each surface on a subplot
    h = subplot(spRows,spCol,i);
    
    %m.plotMesh(h,'refresh',false,'hold_limits',false);
    m.plotSurface(h,'refresh',false,'hold_limits',false);
    m.plotTablePoints(h,'refresh',false,'hold_limits',false);
    m.plotTableSketch(h,'refresh',false,'hold_limits',false);
    
    % name each subplot by the model
    t = sprintf('Vol-%d surface-%d', vIdx,mIdx);
    title(t);
    
    % switch to axis(h, 'equal') if the 3D graphs look too funny
    %view([1,-1,1]);
    box on;
    axis equal;
    
    
    % update plot
    drawnow;
    
    % Extract cropping table
    tm{counter} = m.grepTable();
    tm{counter} (:,13) = dynCat.volumes{vIdx}.ftype;
    tm{counter} (:,14) = dynCat.volumes{vIdx}.ytilt(1);
    tm{counter} (:,15) = dynCat.volumes{vIdx}.ytilt(2);
    tm{counter} (:,20) = vIdx;	% volume index
    tm{counter} (:,21) = counter; 
    
    counter=counter+1;
end

% Merge cropping tables
crop_table = dynamo_table_merge(tm,'linear_tags',1);

% Write out cropping table
crop_table_name = sprintf('memByLvls_i%d_m%d.tbl', controlInterval, meshParameter);
dwrite(crop_table, crop_table_name);

set(gcf,'Name','Surface Cropping Models');

fprintf('Converted all files to membraneByLevel models for cropping!\n')
fprintf('Control point interval used: %d \n', controlInterval)
fprintf('Mesh spacing parameter used: %d \n', meshParameter)

fprintf('Wrote out cropping table as: %s: \n', crop_table_name)
fprintf('Done!\n\n')

end

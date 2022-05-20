%%% This function converts a series of XYZ coordinates
%%% cropping model for Dynamo.
%%%
%%% It orients them on previously written-out surface models (.omd)
%%% which should already be saved in the catalogue
%%%
%%% XYZ points for orienting are assumed to have the same volume and model indices 
%%% as the saved surface to use for orienting.
%%%
%%%
%%% At minimum, it requires the target catalogue name.
%%% i.e., pts_oriented_on_surface('catalogueName');
%%%
%%%
%%% The file names should follow the convention
%%% *_#_*_#_*.xyz
%%% The first '#' is taken to be the catalogue index for the cognate
%%% tomogram and the second '#' the surface number. 
%%%
%%% Author: (TL UCSD 2020)
function pts_oriented_on_surface(catalogueName)


% Check user inputs
if nargin > 1
    error('pts_oriented_on_surface(): Too many inputs, takes 1 at most')
end

if ~exist(catalogueName, 'dir')
    error('Could not find specified catalogue, make sure path is correct')
end

% Have user open directory
fprintf('*****Select IMOD coordinates directory in dialogue window****\n\n\n')
imodDir = uigetdir('Select IMOD coordinates directory');

% Get requisite files into a struct
pointsFiles = dir(fullfile(imodDir,'*.xyz'));

% Get number of models
N = length(pointsFiles);
% Number of columns and rows for sub-ploting
spCol = 4;
spRows = ceil(N/spCol);

% Create a figure
figure(1);
clf;

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
   
    % Read in files are point cloud models
    points = dynamo_model_import('xyz', pFullFileName);
        
    % Load membrane model from catalogue assuming typical file structure
    % A lot of work to built up a file path for dread
    sFileName = sprintf('memByLvl_vol_%d_mod_%d.omd', vIdx, mIdx);
    vDir = sprintf('volume_%d', vIdx);
    sFullFilePath = fullfile(catalogueName, 'tomograms', vDir, 'models', sFileName);
    surface = dread(sFullFilePath);
    
    % Alright, now for the sheningans
    % Link the models
    %points.linkedSurface = surface.mesh;
    %Update the crop angles to the surface normal
    %points.cropAnglesFromLinkedSurface();
    
    % Get table of points
    tmpTbl = points.grepTable(); 
    % Orient the table to the same face of the surface
    orientedTbl = dpktbl.triangulation.fillTable(surface, tmpTbl);
    consistentTbl = dynamo_table_flip_normals(orientedTbl,'center', surface.center);
    
    % Update crop angles of points table with oriented points
    points.crop_angles = consistentTbl(:,7:9);
    
    % Name the model
    modelName = sprintf('OrientedPts_vol_%d_mod_%d',vIdx,mIdx); 
    modelFileName = sprintf('%s.omd', modelName);
    points.name = modelName;
    points.file = modelFileName;

    % Link to target volume and save
    points.linkCatalogue(catalogueName,'i',vIdx);
    points.saveInCatalogue();
   
    fprintf('Finished and saved %s to catalogue\n', modelName)
    
   % Plotting each surface on a subplot
    h = subplot(spRows,spCol,i);
    
    points.marker_size = 3;
    points.sketch_length = 100;
    points.plotTablePoints(h,'refresh',false,'hold_limits',false);
    points.plotTableSketch(h,'refresh',false,'hold_limits',false);
    surface.plotSurface(h,'refresh',false, 'hold_limits', false);
    
    % name each subplot by the model
    t = sprintf('Vol-%d surface-%d', vIdx,mIdx);
    title(t);
    
    % switch to axis(h, 'equal') if the 3D graphs look too funny
    %
    axis(h, 'equal');
      
    % update plot
    drawnow;
    
end

set(gcf,'Name','Surface Cropping Models');

fprintf('Converted all files to oriented point models for cropping!\n')






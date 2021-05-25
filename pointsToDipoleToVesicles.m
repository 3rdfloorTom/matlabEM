.tbl%%% This function converts a contour-labelled pairs of XYZ coordinates into vesicle
%%% cropping model for Dynamo.
%%%
%%%%%% At minimum, it requires the target catalogue name.
%%% i.e., croppingTbl = pointsToDipoleToVesicles('catalogueName');
%%%
%%% At maximum, it takes the catalogue name, point separation, and distance
%%% from surface for cropping
%%% i.e., croppingTbl = pointsToDipoleToVesicles('catalogueName', separation, surfaceOffset)
%%%
%%%     separation, surfaceOffset takes units of pixels
%%%
%%% The file names should follow the convention
%%% *_#_*dipoles.xyz
%%% The first '#' is taken to be the catalogue index for the cognate
%%% tomogram. 
%%%
%%% Author: TL (UCSD 2021)
function [totalCrop] = pointsToDipoleToVesicles(catalogueName, separation, surfaceOffset)

% Check user inputs
if nargin > 3
    error('pointsToDipoleToVesicles(): Too many inputs, takes 3 at most')
end

if ~exist(catalogueName, 'dir')
    error('Could not find specified catalogue, make sure path is correct')
end

% Fill optional inputs with default values
switch nargin
    case 1
        separation = 20;
        surfaceOffset = 0;
    case 2
        
        surfaceOffset = 0;
end


% Have user open directory
fprintf('*****Select IMOD coordinates directory in dialogue window*****\n\n\n')
imodDir = uigetdir('Select IMOD coordinates directory');

% Get requisite files into a struct
dipoleFiles = dir(fullfile(imodDir,'*_dipoles.xyz'));

% Get number of models
N = length(dipoleFiles);
% Number of columns and rows for sub-ploting
spCol = 4;
spRows = ceil(N/spCol);

% Create a figure
figure(1);
clf;

% Read catalogue
catCall = sprintf('%s.ctlg', catalogueName);
dynCat = dread(catCall);

% loop through dipole files
objectCounter = 1; % Contour for object column 21 of table
for i = 1:N
    
    % Parse file names for ease later and for indicies
    % Points
    dFileName = dipoleFiles(i).name;
    dFullFileName = fullfile(imodDir, dFileName);
    
    % Get corresponding volume for file
    splitName = split(pFileName, '_');
    vIdx = str2double(splitName(2));
    
    % Indicate which file that is being worked on
    fprintf('Now processing files %s\n', dFileName) 
    
    % Read in file
    dipole_points = dread(dFullFileName);
    
    % Determine the number of unique contours/dipoles
    unique_contours = unique(dipole_points(:,1),'rows');
    n_dipoles = length(unique_contours);
    
    % loop through dipoles
    for j = 1:n_dipoles
        
        % Initialize a dynanmo vesicle model
        m = dmodels.vesicle();
        
        % Get index of point pairs (parse by contour)
        dipole_index = dipole_points(:,1) == unique_contours(j);
        
        % Get point pair
        dipole_pair = dipole_points(dipole_index,:);
        
        % Set the center and radius of vesicle
        m.center = dipole_pair(1,2:4);
        m.radius = norm(dipole_pair(2,2:4) - dipole_pair(1,2:4));
        
        % Set user-input cropping conditions
        m.separation = separation;
        m.crop_distance_from_surface = surfaceOffset;
        
        % Update the cropping model
        m.updateCrop();
     
        % Name the model for linking and saving to the catalogue
        modelName = sprintf('vesicle_vol_%d_mod_%d', vIdx, objectCounter);
        modelFileName = sprintf('%s.omd', modelName);
        
        m.name = modelName;
        m.file = modelFileName;
    
        m.linkCatalogue(catalogueName,'i',vIdx);
        m.saveInCatalogue();
        
        % Add new cropping table to matrix for merging later
        tm{objectCounter} = m.grepTable();
        tm{objectCounter} (:,13) = dynCat.volumes{vIdx}.ftype;
        tm{objectCounter} (:,14) = dynCat.volumes{vIdx}.ytilt(1);
        tm{objectCounter} (:,15) = dynCat.volumes{vIdx}.ytilt(2);
        tm{objectCounter} (:,20) = vIdx;	% volume index
        tm{objectCounter} (:,21) = objectCounter; 
    
        % Increment object counter
        objectCounter=objectCounter+1;
        
        fprintf('Finished and saved %s to catalogue\n', modelName)
        
        % Attempt to plot the vesicles
        h = subplot(spRows,spCol,j);
    
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
    end

end

% Merge cropping tables
totalCrop = dynamo_table_merge(tm,'linear_tags',1);

set(gcf,'Name','Vesicle Cropping Models');

fprintf('Converted all files to vesicle models for cropping!\n')
fprintf('Spacing interval used: %d \n', separation)
fprintf('Offset from surface used: %d \n', surfaceOffset)

end
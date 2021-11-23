%%% This function converts a contour-labelled pairs of XYZ coordinates into vesicle
%%% cropping model for Dynamo.
%%%
%%%%%% At minimum, it requires the target catalogue name.
%%% i.e., croppingTbl = pointsToDipole('catalogueName');
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
function [crop_table] = pointsToDipoles(catalogueName)

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

table_arr = cell(N);

% loop through dipole files
for i = 1:N
    
    % Parse file names for ease later and for indicies
    % Points
    dFileName = dipoleFiles(i).name;
    dFullFileName = fullfile(imodDir, dFileName);
    
    % Get corresponding volume for file
    splitName = split(dFileName, '_');
    vIdx = str2double(splitName(2));
    
    % Indicate which file that is being worked on
    fprintf('Now processing files %s\n', dFileName) 
    
    % Read in file
    dipole_points = dread(dFullFileName);
    
    % Determine the number of unique contours/dipoles
    unique_contours = unique(dipole_points(:,1),'rows');
    n_dipoles = length(unique_contours);
    
    %implement error check if length % 2 != 0?
    
    % Cell array for storing dipoles
    dipoles = {};
    
    % loop through dipole points
    for j = 1:2:(n_dipoles*2)
        
        % initialize dipole model
        dp_m = dmodels.dipole();
        
        % set center and north points in dipole model
        dp_m.center = dipole_points(j, 2:4);
        dp_m.north = dipole_points(j+1, 2:4);
        
        % add dipole model to cell array
        dipoles{(j+1)/2} = dp_m;
    
    end
    
    % initialize dipoleSet model and fill it with dipoles from above
    dpS_m = dmodels.dipoleSet;
    dpS_m.dipoles = dipoles;
 
    % update cropp table (i.e., establish Euler angles from dipole points)
    dpS_m.updateCrop();
    
    % Name the model
    model_name = sprintf('dipoles_vol_%d',vIdx); 
    model_filename = sprintf('%s.omd', model_name);
    dpS_m.name = model_name;
    dpS_m.file = model_filename;
    
    % Link to target volume and save for possible later use
    dpS_m.linkCatalogue(catalogueName,'i',vIdx);
    dpS_m.saveInCatalogue();
    
    % Export cropping table to cell array of tables
    table_arr{i} = dpS_m.grepTable();
    
    % Update crop table metadata from associated catalogue volume
    table_arr{i} (:,13) = dynCat.volumes{vIdx}.ftype;
    table_arr{i} (:,14) = dynCat.volumes{vIdx}.ytilt(1);
    table_arr{i} (:,15) = dynCat.volumes{vIdx}.ytilt(2);
    table_arr{i} (:,20) = vIdx;
    
    % for plotting (comment out if doing alot of dipoles...)
    
        % Cosmetics
        dpS_m.marker_size = 2;
        dpS_m.sketch_length = 100;
    
        % Plotting each set on a subplot
        h = subplot(spRows,spCol,i);
    
        %m.plotMesh(h,'refresh',false,'hold_limits',false);
        dpS_m.plotTablePoints(h,'refresh',false,'hold_limits',false);
        dpS_m.plotTableSketch(h,'refresh',false,'hold_limits',false);
    
        % name each subplot by the volume
        title(model_name);
    
        % switch to axis(h, 'equal') if the 3D graphs look too funny
        %view([1,-1,1]);
        box on;
        axis equal;
    
        % update plot
        drawnow;
    
end

% Merge cropping tables
crop_table = dynamo_table_merge(table_arr,'linear_tags',1);

% Write the cropping table to disk
table_filename=sprintf('dipoles_%s.tbl', catalogueName);
dwrite(crop_table, table_filename);

% Plotting for diagnostics
set(gcf,'Name','Dipole Cropping Models');

fprintf('Oriented all points for cropping!\n')
fprintf('A cropping table has been written out as %s \n', table_filename)
fprintf('Script Done!\n')

end

%%% This function converts a contour-labelled pairs of XYZ coordinates into vesicle
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
function [totalCrop] = pointsToDipole(catalogueName)

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
    
    dipoles = {};
    
    for j = 1:2:(n_dipoles*2)
        
        dp_m = dmodels.dipole();
        
        dp_m.center = dipole_points(j, 2:4);
        dp_m.north = dipole_points(j+1, 2:4);
        
        dipoles{(j+1)/2} = dp_m;
    
    end
    
    dpS_m = dmodels.dipoleSet();
    dpS_m.dipoles = dipoles;
      
    % Name the model
    modelName = sprintf('dipoles_vol_%d',vIdx); 
    modelFileName = sprintf('%s.omd', modelName);
    dpS_m.name = modelName;
    dpS_m.file = modelFileName;
    
    dpS_m.updateCrop();
    
end

% Merge cropping tables
totalCrop = dynamo_table_merge(tm,'linear_tags',1);

set(gcf,'Name','Vesicle Cropping Models');

fprintf('Converted all files to vesicle models for cropping!\n')
fprintf('Spacing interval used: %d \n', separation)
fprintf('Offset from surface used: %d \n', surfaceOffset)

end
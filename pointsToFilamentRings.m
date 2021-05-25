T%%% This function converts a series of XYZ coordinates along a filament axis into a
%%% cropping model (filament rings) for Dynamo.
%%%
%%% At minimum, it requires the target catalogue name.
%%% i.e., croppingTbl = pointsToFilamentRings('catalogueName');
%%%
%%% At maximum, it takes the catalogue name, dz, dphi
%%% i.e., croppingTbl = pointsToFilamentRings('catalogueName', zstep, radius, spr)
%%%         dz is separation (in pixels) along the filament axis of the rings
%%%	    radius distance (in pixels) from the centeral axis of the filament to the ring
%%%	    spr-Subunits Per Ring
%%%
%%% The file names should follow the convention
%%% *_#_*_#_*.xyz
%%% The first '#' is taken to be the catalogue index for the cognate
%%% tomogram and the second '#' the filament number in that tomogram. 
%%%
%%% Author: (TL UCSD 2020)
function [totalCrop] = FilamentRings(catalogueName, dz, radius, spr) %#ok<DEFNU>

% Check user inputs
if nargin ~= 4
    error('pointsToPathFilamentRings(): Too many inputs, takes 4 at most')
end

if ~exist(catalogueName, 'dir')
    error('Could not find specified catalogue, make sure path is correct')
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
    m = dmodels.filamentRings;
   
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

    % Add user inputs
    m.ringSeparation = dz;
    m.radius = radius;
    m.subunitsPerRing = spr;

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
    tm{counter} (:,21) = counter; % filament index
   
    % Increment counter
    counter=counter+1;
    
end

% Merge cropping tables
totalCrop = dynamo_table_merge(tm, 'linear_tags', 1);

% Set figure name
set(gcf,'Name','Filament Ring Models');

fprintf('\n\nConverted all files to filamentRing models for cropping!\n')

fprintf('Places a ring along the filament every %d pixels \n', dz)

fprintf('Cropped points from the ring assuming %d equally spaced subuntis per ring \n', spr)

fprintf('Using a radius of %d pixels from the filament axis \n', radius)

end
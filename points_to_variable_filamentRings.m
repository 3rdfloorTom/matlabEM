%%% This function converts a IMOD points file (containing object, contour,
%%% and xyz coordinates) to make filamentRings models with variable diameters in dynamo.
%%%
%%% object entries represent filaments
%%% contour 1 - represents the filament axis (>= 2 points)
%%% contour 2 - rpresents the diameter (2 points
%%%
%%% The file names should follow the convention
%%% *_#_filamentRings.coords
%%%
%%% The first '#' is taken to be the catalogue index for the cognate
%%% tomogram.
%%%
%%% At minimum, it requires the target catalogue name.
%%% i.e., crop_table =  points_to_variable_filamentRings('catalogue_name', ring_separation);
%%%
%%% Author: (TL UCSD 2022)
function [crop_table] = points_to_variable_filamentRings(catalogue_name, ring_separation)

% Check user inputs
if nargin ~= 2
    error('points_to_variable_filamentRings(): Too many inputs, takes 2')
end

if ~exist(catalogue_name, 'dir')
    error('Could not find specified catalogue, make sure path is correct')
end


% Have user open directory
fprintf('*****Select IMOD coordinates directory in dialogue window*****\n\n\n')
imodDir = uigetdir('Select IMOD coordinates directory');

% Get requisite files into a struct
points_files_list = dir(fullfile(imodDir,'*_filamentRings.coords'));

% Read in catalogue
cat_call = sprintf('%s.ctlg', catalogue_name);
dyn_cat = dread(cat_call);

% initialize an empty cell array for holding intermediate tables

% tube counter for reg specifier
tube_counter = 1;

for i = 1:length(points_files_list)

	points_file_name = points_files_list(i).name;
	full_points_file_name = fullfile(imodDir, points_file_name);

	% stuff for metadata 
	split_name = split(points_file_name, '_');
	vIdx = str2double(split_name(2));

	fprintf('Now processing filaments in %s\n', points_file_name);

	filament_points = dread(full_points_file_name);
	n_filaments = unique(filament_points(:,1), 'rows');

	for ii = 1:length(n_filaments)

		% Initialize a ring model
		m = dmodels.filamentRings;

    	% Take XYZ coordinates for object ii and contour 1 (filamnet path/axis)
		m.points = filament_points(filament_points(:,1)==n_filaments(ii) & filament_points(:,2)==1,3:5);
        m.backboneUpdate();
        
		% Take XYZ coordinate for object ii and contour 2 (diameter markers)
		diameter_points = filament_points(filament_points(:,1)==n_filaments(ii) & filament_points(:,2)==2,3:5);

		% Determine radius from contour 2 points marking the diameter
		radius = norm(diameter_points(1,:) - diameter_points(2,:)) / 2;

		% model parameters
        m.ringSeparation = ring_separation;
		m.radius = radius;
		m.subunitsPerRing = round(2*pi*radius/ring_separation,0);

		m.updateCrop();

		% assignment model name and storing in the catalogue
		model_name = sprintf('filament_vol_%d_mod_%d',vIdx,tube_counter); 
    	model_file_name = sprintf('%s.omd', model_name);
    	m.name = model_name;
    	m.file = model_file_name;
    	m.linkCatalogue(catalogue_name,'i',vIdx);
    	m.saveInCatalogue();

    	% store table in an array and upate tomogram and tube specific properties
    	table_array{tube_counter} = m.grepTable();
    	table_array{tube_counter} (:,13) = dyn_cat.volumes{vIdx}.ftype;
    	table_array{tube_counter} (:,14) = dyn_cat.volumes{vIdx}.ytilt(1);
    	table_array{tube_counter} (:,15) = dyn_cat.volumes{vIdx}.ytilt(2);
    	table_array{tube_counter} (:,20) = vIdx;
    	table_array{tube_counter} (:,21) = tube_counter;
    	table_array{tube_counter} (:,23) = radius;

    	tube_counter = tube_counter+1;

	end

end

crop_table = dynamo_table_merge(table_array, 'linear_tags', 1);

crop_table_name = sprintf('filament_rings_dz_%d.tbl', ring_separation);
dwrite(crop_table, crop_table_name);

fprintf('\n\nConverted all files to filamentRing models for cropping!\n')
fprintf('Total cropping points: %d\n', length(crop_table))
fprintf('Table written to: %s\n', crop_table_name)

end
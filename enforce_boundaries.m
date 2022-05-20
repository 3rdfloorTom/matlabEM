% Intended for use via the MATLAB IDE

clear
% Inputs

table_file = 'crop.tbl';
boundaries_dir = 'boundary_models'; % boundary models assumed to be on same coordinate system as the table.


% read in table
table = dread(table_file);

% Get unique tomogram files
tomo_n = unique(table(:,20), 'rows');

% Initialize a cell array to hold intermediate tables
table_arr = cell(size(tomo_n));

for i = 1:length(tomo_n)

    % prepare boundary file name based on tomogram number
    boundary_file_name = sprintf('volume_%d.xyz', tomo_n(i));
    full_boundary_file_name = fullfile(boundaries_dir, boundary_file_name);

    % read in boundary file
    boundary_points = dread(full_boundary_file_name);
    
    % sub_table for a given tomogram
    sub_table = table(table(:,20) == tomo_n(i),:);
    
    % create and alpha shape for bounding and bound the table
    boundary_shape = alphaShape(boundary_points,Inf);
    bounded_indices = inShape(boundary_shape, sub_table(:,24:26)+sub_table(:,4:6));
    bounded_sub_table = sub_table(bounded_indices,:);
    
    % store intermediate tables in cell array
    table_arr{i} = bounded_sub_table;
    
end

% merge intermediate tables and write table to disk
bounded_table = dynamo_table_merge(table_arr, 'linear_tags', 1);
bounded_table_file = sprintf('bounded_%s', table_file);
dwrite(bounded_table, bounded_table_file);

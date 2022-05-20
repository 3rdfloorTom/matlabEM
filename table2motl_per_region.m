
%%%% Make motive-lists per col-21 for viewing in Chimera with placeObjects
%%%%
%%%% Usage:
%%%% make_motive_lists_per_region('table_file_name')
%%%%
%%%% Author(s): TL UCSD (2022)
function table2motl_per_region(table_file_name)

% Arguement checks
if nargin ~= 1
    error('make_motive_lists_per_region(): Too many inputs, takes 1 table file name')
end

if isfile(table_file_name)
    table = dread(table_file_name);
    fprintf('\nRead in the table file:\t %s \n', table_file_name)
else
       error('Could not find specified table, make sure path is correct')
end


% Determine tube IDs
regions = unique(table(:,20:21), 'rows');

for i = 1:size(regions,1)
    
    tomo_id = regions(i,1);
    region_id = regions(i,2);
       
    % restrict table to tube
    region_inds = table(:,20) == tomo_id & table(:,21) == region_id;
    region_table = table(region_inds,:);
    
    region_motl = dynamo__table2motl(region_table);
    
    region_motl_file_name = sprintf('per_region_placeObjects/tomo_%d_region_%d.em',tomo_id,region_id);
    dwrite(region_motl, region_motl_file_name);
    
    fprintf('\nWrote out %s\n', region_motl_file_name);
end

fprintf('\nFinished writing out motive lists to directory: per_region_placeObjects/\n');
fprintf('\nDone!\n');
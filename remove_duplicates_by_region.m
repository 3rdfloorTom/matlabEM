%%% Remove duplicate particles within a given distance (in pixels)
%%% Removal performed on a per region basis (i.e., col-20 & col-21);
%%%
%%% Example running command:
%%% thresholded_table = remove_duplicates_by_region('table_file_name', distance_threshold)
%%%
%%% Author(s): TL 
function thresholded_table = remove_duplicates_by_region(table_file_name, distance_threshold)

% Arguement checks
if nargin ~= 2
    error('remove_duplicates_by_region(): Too many inputs, takes 2')
end

if isfile(table_file_name)
    table = dread(table_file_name);
    fprintf('\nRead in the table file:\t %s \n', table_file_name)
else
       error('Could not find specified table, make sure path is correct')
end


% Determine unique regions
regions = unique(table(:,20:21), 'rows');

% Intialize empty table for accumulating results
thresholded_table=[];

for i = 1:size(regions,1)
    
    fprintf('\ntomo %d  region %d ...\n', regions(i,1), regions(i,2));    
    
    % restrict table to region
    region_table = table(table(:,20) == regions(i,1) & table(:,21) == regions(i,2), :);
    
    % apply distance thresholding
    tmp_table = dpktbl.exclusionPerVolume(region_table,distance_threshold);
    
    % append result to growing table
    thresholded_table = cat(1,thresholded_table,tmp_table);
   
end

new_table_file_name = sprintf('dedupe_th%d_%s', distance_threshold, table_file_name);
dwrite(thresholded_table, new_table_file_name);

fprintf('\nFinished removing duplicates using a distance of %d\n', distance_threshold);
fprintf('Original particle count: %d\n', size(table,1));
fprintf('New particle count: %d\n', size(thresholded_table,1));

fprintf('\nNew table written out as: %s\n', new_table_file_name);

fprintf('\nDone!\n');

end

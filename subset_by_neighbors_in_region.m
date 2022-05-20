%%%% Removes duplicates based on grouping in col-20 AND col-21
%%%% particularly useful for close-packed/multilayered lattices
%%%%
%%%% Usage:
%%%% [table_select,table_exclude] = subset_by_neighbors_in_region('table_file_name', dmin, dmax, neighbor_min)
%%%%
%%%% Author(s): TL UCSD (2022)
function [table_select,table_exclude] = subset_by_neighbors_in_region(table_file_name, dmin, dmax, neighbor_min)

% Arguement checks
if nargin ~= 4
    error('subset_by_neighbors_in_region(): Takes exactly 4 inputs')
end

if isfile(table_file_name)
    table = dread(table_file_name);
    fprintf('\nRead in the table file:\t %s \n', table_file_name)
else
       error('Could not find specified table, make sure path is correct')
end

% build array of neighbors for each table index by calling
% neighbors_by_region()
neighbors = neighbors_by_region(table, dmin, dmax);

% take indices with at least minimum number of neighbors
select_idx = neighbors > neighbor_min;

% make select and excluded tables
table_select = table(select_idx, :);
table_exclude = table(~select_idx,:);

% make output table names
table_select_file  = sprintf('select_n%d_%s', neighbor_min, table_file_name);
table_exclude_file = sprintf('exclude_n%d_%s', neighbor_min, table_file_name);


% write out tables
dwrite(table_select, table_select_file);
dwrite(table_exclude, table_exclude_file);

fprintf('\nFinished selecting entries by neighbor count.\n\n');
fprintf('Input table %s contained %d particles\n', table_file_name, size(table,1));
fprintf('Select table %s contains %d particles\n', table_select_file, size(table_select, 1));
fprintf('Excluded table %s contains %d particles\n', table_exclude_file, size(table_exclude, 1));
fprintf('\nDone!\n');

end

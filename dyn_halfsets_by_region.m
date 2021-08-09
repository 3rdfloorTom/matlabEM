%%% This function creates halfsets for a Dynamo table by tomogram regions
%%% i.e., based on unique col-20 and col-21 pairs
%%%
%%% Minimal running tables a table file
%%% i.e., dyn_halfsets_by_region(table_file);
%%% and outputs halfsets files as:
%%%     'table_file_half_1.tbl'
%%%     'table_file_half_2.tbl'
%%%
%%% It will also return the halfsets as workspace variables
%%% i.e., [half_table_one, half_table_two] = dyn_halfsets_by_region(table_file)
%%%
%%% Author: TL (UCSD 2021)
function [table_half_one,table_half_two] = dyn_halfsets_across_region(table_file)

% Check inputs
if nargin ~= 1
    error('half_sets_by_region(): takes 1 required input')
end

% Read in table file using dynamo if it exists
if isfile(table_file)
    table = dread(table_file);
    fprintf('\nRead in the table file:\t %s \n', table_file)
else
       error('Could not find specified table, make sure path is correct')
end

% Obtain list of unique tomogram regions
tomo_region_list = unique(table(:,20:21),'rows');

% Initialize empty arrays for the halfsets
table_half_one = [];
table_half_two = [];

% Initialize empty array for size list
tomo_region_size_list = [];

    % Make size list
    for i = 1:size(tomo_region_list,1)
        
        % Generate region sub-table
        tomon = tomo_region_list(i,1);
        region = tomo_region_list(i,2);
        region_table = table((table(:,20)==tomon)&(table(:,21)==region),:);
        
        % Get size
        region_size = size(region_table,1);
        
        % Add indicies and region size to list
        tmpArr = [tomon region region_size];
        tomo_region_size_list = cat(1,tomo_region_size_list,tmpArr);

    end    
        
% Sort size list in descending order
tomo_region_size_list_sorted = sortrows(tomo_region_size_list,3,'descend');
        
    % Divy up particles into halfsets
    for i = 1:size(tomo_region_size_list_sorted,1)
        
        tomon = tomo_region_size_list_sorted(i,1);
        region = tomo_region_size_list_sorted(i,2);
        region_size = tomo_region_size_list_sorted(i,3);
     
        fprintf('\ntomo %d region %d contains %d particles:', tomon, region, region_size)
        
        region_table = table((table(:,20)==tomon)&(table(:,21)==region),:);
        
         % Concatenate region_table to smaller halfset table
        if size(table_half_one,1) < size(table_half_two,1)
            table_half_one = cat(1,table_half_one,region_table);
            fprintf('\tAdded particles to halfset-1\n')
        else
            table_half_two = cat(1, table_half_two,region_table);
            fprintf('\tAdded particles to halfset-2\n')
        end
        
    end
    
% Generate file names for output using rootname of input table
table_file_rootname = strrep(table_file,'.tbl','');
file_half_one = sprintf('%s_half_1.tbl',table_file_rootname);
file_half_two = sprintf('%s_half_2.tbl',table_file_rootname);

% Write halfset table to disk
dwrite(table_half_one, file_half_one);
dwrite(table_half_two, file_half_two);


% Report the results
fprintf('\n\nHalfset tables by tomogram regions have been written out!\n')
fprintf('\nHalfset-1 has been written as %s and contains %d particles', file_half_one, size(table_half_one,1))
fprintf('\nHalfset-2 has been written as %s and contains %d particles', file_half_two, size(table_half_two,1))

fprintf('\n\nScript has finished!\n\n')

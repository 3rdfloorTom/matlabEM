%%% This function takes two tables related by Z-inversion,
%%% it compares meanCC betweens the table regions (cols-20,21),
%%% and merges regions into a new table with the best meanCCs.
%%%
%%%
%%% Minimal running tables a table file
%%% i.e., dyn_Ztable_by_meanCC(table_file_one,table_file_two);
%%% and outputs:
%%%     'table_file_one_bestZ_byMeanCC.tbl'
%%%
%%% It will also return the workspace variable if run as:
%%% i.e., bestZ_table] = dyn_Ztable_by_meanCC(table_file_one,table_file_two)
%%%
%%% Author: TL (UCSD 2021)
function [bestZ_table] = dyn_Ztable_by_meanCC(table_file_one,table_file_two)

% Check inputs
if nargin ~= 2
    error('dyn_Ztable_by_meanCC(): takes 2 required input')
end

% Read in table files using dynamo if it exists
if isfile(table_file_one) && isfile(table_file_two)
    
    table_one = dread(table_file_one);
    fprintf('\nRead in the table file:\t %s \n', table_file_one)
    
    table_two = dread(table_file_two);
    fprintf('\nRead in the table file:\t %s \n', table_file_two)
else
       error('Could not find one or both of the specified tables, make sure paths are correct')
end



% Check table sizes to ensure they match
if size(table_one,1) ~= size(table_two,1)
    error('table sizes do NOT match!, these are not tables related by just a Z-inersion')
end
    
% Obtain list of unique tomogram regions
table_one_region_list = unique(table_one(:,20:21),'rows');
table_two_region_list = unique(table_two(:,20:21),'rows');   

% Check that the number of regions match 
if size(table_one_region_list,1) ~= size(table_two_region_list,1)
    error('the number of table regions do NOT match!, these are not tables related by just a Z-inersion')
end

% Initialize empty arrays for output table
bestZ_table = [];

    % Table parsing by region
    for i = 1:size(table_one_region_list,1)
        
        tomon = table_one_region_list(i,1);
        region = table_one_region_list(i,2);
     
        fprintf('\nWorking on tomo %d region %d', tomon, region)
        
        % Create region tables
        region_table_one = table_one((table_one(:,20)==tomon)&(table_one(:,21)==region),:);
        region_table_two = table_two((table_two(:,20)==tomon)&(table_two(:,21)==region),:);
        
        % Compare meanCC for both tables
        mean_CC_one = mean(region_table_one(:,10),1);
        mean_CC_two = mean(region_table_two(:,10),1);
        
        fprintf('\n 1st table meanCC: %d', mean_CC_one)
        fprintf('\n 2nd table meanCC: %d', mean_CC_two)        
        
         % Concatenate region_table_# with higher meanCC into bestZ_table
        if mean_CC_one > mean_CC_two
            bestZ_table = cat(1,bestZ_table,region_table_one);
            fprintf('\n\tAdded particles from 1st table')
        else
            bestZ_table = cat(1,bestZ_table,region_table_two);
            fprintf('\n\tAdded particles from 2nd table')
        end
        
    end
    
% Generate file names for output using rootname of input table
table_file_rootname = strrep(table_file_one,'.tbl','');
output_table_name = sprintf('%s_bestZ_byMeanCC.tbl',table_file_rootname);

% Write table to disk
dwrite(bestZ_table, output_table_name);

% Report the results
fprintf('\n\nA new table has been written out as: %s\n', output_table_name)
fprintf('\nOriginal meanCC of 1st table: %d', mean(table_one(:,10),1))
fprintf('\nOriginal meanCC of 2nd table: %d', mean(table_two(:,10),1))
fprintf('\nmeanCC of the new table: %d', mean(bestZ_table(:,10),1))

fprintf('\n\nScript has finished!\n\n')

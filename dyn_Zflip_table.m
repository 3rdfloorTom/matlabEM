%%% This function flips the normals/Z-axis of the input table
%%%
%%% Minimal running tables a table file
%%% i.e., dyn_Zflip_table(table_file);
%%% and outputs:
%%%     'table_file_Zflip.tbl'
%%%
%%% It will also return the workspace variable if run as:
%%% i.e., [table_Zflip] = dyn_Zflip_table(table_file)
%%%
%%% Author: TL (UCSD 2021)
function [table_Zflip] = dyn_Zflip_table(table_file)

% Check inputs
if nargin ~= 1
    error('dyn_Zflip_table(): takes 1 required input')
end

% Read in table file using dynamo if it exists
if isfile(table_file)
    table_Zflip = dread(table_file);
    fprintf('\nRead in the table file:\t %s \n', table_file)
else
    error('Could not find specified table, make sure path is correct')
end

% Flip last two euler angles of dynamo table (cols-8,9)
table_Zflip(:,8) = table_Zflip(:,8) + 180;
table_Zflip(:,9) = 180 - table_Zflip(:,9);

% Get table rootname for naming output
table_file_rootname = strrep(table_file,'.tbl','');
% Construct output name string and write it out
output_table_file_name = sprintf('%s_Zflip.tbl',table_file_rootname);

% Write flipped table to disk
dwrite(table_Zflip, output_table_file_name);


% Report the results
fprintf('\n\nThe Z-flipped table has been written as: %s', output_table_file_name)
fprintf('\n\nScript has finished!\n\n')


%%% Merge all Dynamo table files from within a user-specified directory
%%% Usage mergeTables();
function [merged_table] = merge_tables()

% Have user open directory
fprintf('*****Select directory containing .tbl files in dialogue window*****\n\n\n')
tblDir = uigetdir('Select target .tbl directory');

% Get requisite files into a struct
tblFiles = dir(fullfile(tblDir,'*.tbl'));

% Get number of tables
N = length(tblFiles);

% Initialize an empty array for new table
merged_table = [];

for i = 1:N
    
    % Generate full file name
    tblFileName = tblFiles(i).name;
    FulltblFileName = fullfile(tblDir, tblFileName);
    
    tmp_table = dread(FulltblFileName); 
    merged_table = cat(1,merged_table,tmp_table);
    
end

pctlCount = size(merged_table,1);

fprintf('\nFinished merging %d tables!\n', N);
fprintf('Newly merged table contains %d particles.\n\n', pctlCount);

end

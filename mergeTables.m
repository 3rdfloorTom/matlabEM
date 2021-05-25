%%% Merge all Dynamo table files from within a user-specified directory
%%% Usage mergeTables();
function [mergedTbl] = mergeTables()

% Have user open directory
fprintf('*****Select directory containing .tbl files in dialogue window*****\n\n\n')
tblDir = uigetdir('Select target .tbl directory');

% Get requisite files into a struct
tblFiles = dir(fullfile(tblDir,'*.tbl'));

% Get number of tables
N = length(tblFiles);

% Pre-allocate table holding cell-array for speed
tm = cell(1,N);

for i = 1:N
    
    % Generate full file name
    tblFileName = tblFiles(i).name;
    FulltblFileName = fullfile(tblDir, tblFileName);
    
    tm{i} = dread(FulltblFileName); 
    
end

% Merge cropping tables
mergedTbl = dynamo_table_merge(tm,'linear_tags',1);

pctlCount = size(mergedTbl,1);

fprintf('\nFinished merging %d tables!\n', N);
fprintf('Newly merged table contains %d particles.\n\n', pctlCount);

end
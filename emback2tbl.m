%%% Convert from a .em motivelist back to a .tbl using originating .tbl
%%%
%%% Writes out a new subset table based on tag ID matches between .em and
%%% .tbl files.
%%%
%%% Usage:
%%% emback2Tbl('emFile','tblFile')
function emback2tbl(emFile,tblFile)

% Check user inputs
if nargin ~= 2
    error('emBack2tbl(): takes 2 required inputs')
end


% Read things into dynamo data structures
emVar = dread(emFile);
tblVar = dread(tblFile);

% Get taglist subset
tagSubset = emVar(4,:);
tagFullset = tblVar(:,1);

% subset indicies
index = ismember(tagFullset, tagSubset);


% Put all member rows into a new table using logical indexing
newTbl = tblVar(index,:);

% Write out new table
emFileRootname = strrep(emFile,'.em','');
newTblFile = sprintf('%s_pObj_subset.tbl',emFileRootname);
dwrite(newTbl,newTblFile);

% Get particle count
pctlCount = size(newTbl,1);

fprintf('\nWrote out a new table containing %d particles: \t%s\n', pctlCount, newTblFile)

end
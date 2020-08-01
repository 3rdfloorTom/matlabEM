%%% Converts a dynamo table (.tbl) file into an .em formatted file
%%% for visualization in UCSF chimera using the Place Object plugin
%%% https://www2.mrc-lmb.cam.ac.uk/groups/briggs/resources/place-object/
%%%
%%% Usage:
%%% tbl2em(tableFile,tomoIndex)
function tbl2em(tableFile,tomoIndex)

% Check user inputs
if nargin ~= 2
    error('tbl2em(): takes 2 required inputs')
end

% Read in specific table/tomo using dynamo functions
fullTbl = dread(tableFile);
tomoTbl = dynamo_table_grep(fullTbl,'tomo',tomoIndex);

% Initialize empty matrix to build-up
emtrx = zeros(20,length(tomoTbl(:,1)));
            
emtrx(1,:) = tomoTbl(:,10);     % CC
emtrx(4,:) = tomoTbl(:,1);      % ptcl tag/number
emtrx(5,:) = tomoIndex;
emtrx(7,:) = tomoIndex;
emtrx(6,:) = tomoTbl(:,22);     % class/model
emtrx(8,:) = tomoTbl(:,24);     % X-coordinate in full tomogram
emtrx(9,:) = tomoTbl(:,25);     % Y-coordinate in full tomogram
emtrx(10,:) = tomoTbl(:,26);    % Z-coordinate in full tomogram
emtrx(11,:) = tomoTbl(:,4);     % X-shift in subvolume
emtrx(12,:) = tomoTbl(:,5);     % Y-shift in subvolume
emtrx(13,:) = tomoTbl(:,6);     % Z-shift in subvolume
emtrx(17,:) = tomoTbl(:,9);     % Phi/narot/Z' rotation
emtrx(18,:) = tomoTbl(:,7);     % Psi/tdrot/Z rotation
emtrx(19,:) = tomoTbl(:,8);     % Theta/tilt/X rotation
emtrx(20,:) = tomoTbl(:,34);    % reference

emfile = sprintf('%s_tomo_%d.em',tableFile,tomoIndex);
%writematrix(emtrx,emfile,'Delimiter','comma');
dwrite(emtrx,emfile);
fprintf('Wrote out file: %s\n', emfile)



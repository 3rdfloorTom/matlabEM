%%% Converts a dynamo table (.tbl) file into an AV3 em formatted file
%%% for a given tomogram for visualization in UCSF chimera using the 
%%% Place Object plugin
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

% indicies for all averaged particles
avgInd = tomoTbl(:,3) == 1;
% table of averaged particles
avgTbl = tomoTbl(avgInd,:);

% Initialize empty matrix to build-up
emtrx = zeros(20,length(tomoTbl(:,1)));
emtrxAvg = zeros(20,length(avgTbl(:,1)));
            
% Fill matrix
emtrx(1,:) = tomoTbl(:,10);     % CC
emtrx(4,:) = tomoTbl(:,1);      % ptcl tag/number
emtrx(5,:) = tomoIndex;         % tomogram index
emtrx(7,:) = tomoIndex;
emtrx(6,:) = tomoTbl(:,21);     % tomogram sub-area
emtrx(8,:) = tomoTbl(:,24);     % X-coordinate in full tomogram
emtrx(9,:) = tomoTbl(:,25);     % Y-coordinate in full tomogram
emtrx(10,:) = tomoTbl(:,26);    % Z-coordinate in full tomogram
emtrx(11,:) = tomoTbl(:,4);     % X-shift in subvolume
emtrx(12,:) = tomoTbl(:,5);     % Y-shift in subvolume
emtrx(13,:) = tomoTbl(:,6);     % Z-shift in subvolume
emtrx(17,:) = -tomoTbl(:,9);    % Phi/narot/Z' rotation
emtrx(18,:) = -tomoTbl(:,7);    % Psi/tdrot/Z rotation
emtrx(19,:) = -tomoTbl(:,8);    % Theta/tilt/X rotation
emtrx(20,:) = tomoTbl(:,22);    % Class


% Generate name of output .em file and write to disk with dynamo function
tableFileRootname = strrep(tableFile,'.tbl','');
emfile = sprintf('%s_tomo_%d_all.em',tableFileRootname,tomoIndex);
dwrite(emtrx,emfile);
fprintf('\nWrote out an motivelist for all particles: \n\t\t%s\n', emfile)

% Make average table if it contains fewer particles
if length(tomoTbl(:,1)) > length(avgTbl(:,1))
    % Fill matrix
    emtrxAvg(1,:) = avgTbl(:,10);     % CC
    emtrxAvg(4,:) = avgTbl(:,1);      % ptcl tag/number
    emtrxAvg(5,:) = tomoIndex;        % tomogram index
    emtrxAvg(7,:) = tomoIndex;
    emtrxAvg(6,:) = avgTbl(:,21);     % tomogram sub-area
    emtrxAvg(8,:) = avgTbl(:,24);     % X-coordinate in full tomogram
    emtrxAvg(9,:) = avgTbl(:,25);     % Y-coordinate in full tomogram
    emtrxAvg(10,:) = avgTbl(:,26);    % Z-coordinate in full tomogram
    emtrxAvg(11,:) = avgTbl(:,4);     % X-shift in subvolume
    emtrxAvg(12,:) = avgTbl(:,5);     % Y-shift in subvolume
    emtrxAvg(13,:) = avgTbl(:,6);     % Z-shift in subvolume
    emtrxAvg(17,:) = -avgTbl(:,9);    % Phi/narot/Z' rotation
    emtrxAvg(18,:) = -avgTbl(:,7);    % Psi/tdrot/Z rotation
    emtrxAvg(19,:) = -avgTbl(:,8);    % Theta/tilt/X rotation
    emtrxAvg(20,:) = avgTbl(:,22);    % Class
    
    emfileAvg = sprintf('%s_tomo_%d_averaged.em',tableFileRootname,tomoIndex);
    dwrite(emtrxAvg,emfileAvg);
    fprintf('\nWrote out a motivelist for particles used in average: \n\t\t%s\n', emfileAvg)
else
    fprintf('\nOnly writing one file since all particles were averaged\n')
end


%%% Uses MATLAB's alphaShape function to trim template-matching results from Warp-v1.09
%%% and group them with a '_rlnHelicalTubeID'
%%%
%%% All coordinates are assumed to be normalized
%%%
%%%

function alphaShape_wrp_tm_results()

% Have user open directories
fprintf('*****Select directory containing .star files in dialogue window*****\n\n\n')
star_dir = uigetdir('Select target .star directory');

fprintf('*****Select directory containing _boundary.coords files in dialogue window*****\n\n\n')
pts_dir = uigetdir('Select target _boundary.coords directory');

% Get requisite files into a struct
pts_files_list = dir(fullfile(pts_dir,'*_boundary.coords'));

object_counter = 1;

for i = 1:size(pts_files_list,1)

    % Generate full file name for boundary point clouds
    pts_file_name = fullfile(pts_dir, pts_files_list(i).name);
    pts_work = readmatrix(pts_file_name, 'FileType', 'text');
    
    % use base name of points file name to find the cognate star files by
    % using a wild-card
    base_name = split(pts_files_list(i).name, '_boundary.coords');
    starfile_name = fullfile(star_dir,[base_name{1} '*.star']);
    fprintf('Working on %s\n', base_name{1});
    
    % iterate over unique contours within the .pts files
    for ii = 1:size(unique(pts_work(:,1), 'rows'),1)       
        
       % make alphaShape
       boundary_shape = alphaShape(pts_work(pts_work(:,1)==ii,2:4),Inf);
       
       % bound table points to be within the alphaShape
       starfile_work = dread(starfile_name);
       bounded_points = inShape(boundary_shape, table2array(starfile_work.tbl(:,1:3)));
       starfile_work.tbl([~bounded_points],:) = []; 
       
       % add a region/object ID to the starfile as HelicalTubeID
       object_id_arr = zeros(size(starfile_work.tbl,1),1) + object_counter;
       starfile_work.addColumn(object_id_arr,'name', 'rlnHelicalTubeID');
       
       fprintf('\t\tfinished object %d with %d points\n', object_counter, size(starfile_work.tbl,1));
       
       % write out the bounded starfile for each object (merge later)
       new_starfile_name = sprintf('bounded_starfiles/%s_boundary_%d.star',base_name{1},object_counter);
       dwrite(starfile_work, new_starfile_name);
       
       object_counter = object_counter + 1;
       
    end % Close inner for-loop
    
    fprintf('Finished working on %s\n\n', base_name{1});
    
end % Close outer for-loop

fprintf('\n\nFinished all objects and wrote results to bounded_starfiles/ \n\n');
fprintf('\nNow working on merging all bounded starfiles\n\n');

% Get list of all bounded starfiles
starfile_list = dir(fullfile('bounded_starfiles/','*.star'));

% Read in the first starfile to use as base file for merging
privileged_starfile = dread(fullfile('bounded_starfiles/', starfile_list(1).name));

% loop over all of ther starfiles to merged into the one currently read in
for i = 2:size(starfile_list,1)
    
    % read in next starfile
    tmp_starfile_name = fullfile('bounded_starfiles/', starfile_list(i).name);
    tmp_starfile = dread(tmp_starfile_name);
    
    % concatenate to new starfile to growing starfile table
    privileged_starfile.tbl = vertcat(privileged_starfile.tbl, tmp_starfile.tbl);
    
end

dwrite(privileged_starfile, 'bounded_merged.star');

fprintf('\n\nFinished merging starfiles.\n');
fprintf('Written out bounded_merged.star with %d points.\n\n', size(privileged_starfile.tbl,1));
fprintf('Done!\n\n');

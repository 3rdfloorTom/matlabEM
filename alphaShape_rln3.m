%%% Use MATLABS alphaShape function to group particles and trim those falling out of bounds for a RELION-3 starfile.
%%%
%%% Boundary coordinates are assumed to be normalized, thus maximum XYZ dimensions are expected as input.
%%% If coordinates are not normalized, than just use 1's
%%%
%%% Author: TL UCSD 2022

function alphaShape_rln3(starfile_name, xdim, ydim, zdim)

%%% put arguement parsing here
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
    tomo_name = split(pts_files_list(i).name, '_boundary.coords');
    fprintf('\nWorking on tomogram: %s\n', tomo_name{1});
    
    % iterate over unique contours within the .pts files
    for ii = 1:size(unique(pts_work(:,1), 'rows'),1)       
        
       % make alphaShape after scaling boundary points
       scaled_pts = pts_work(pts_work(:,1)==ii,2:4);
       scaled_pts(:,1) = xdim*scaled_pts(:,1);
       scaled_pts(:,2) = ydim*scaled_pts(:,2);
       scaled_pts(:,3) = zdim*scaled_pts(:,3);
      
       boundary_shape = alphaShape(scaled_pts,Inf);
       
       % Read starfile
       starfile_work = dread(starfile_name);
       % restrict starfile to current tomogram
       tomo_n_inds = contains(starfile_work.tbl.rlnMicrographName, tomo_name{1});
       starfile_work.tbl([~tomo_n_inds],:) = [];
       
       % bound working starfile by alphaShape
       bounded_points = inShape(boundary_shape, [starfile_work.tbl.rlnCoordinateX, starfile_work.tbl.rlnCoordinateY, starfile_work.tbl.rlnCoordinateZ]);
       starfile_work.tbl([~bounded_points],:) = []; 
       
       % add a region/object ID to the starfile as HelicalTubeID
       object_id_arr = zeros(size(starfile_work.tbl,1),1) + object_counter;
       starfile_work.addColumn(object_id_arr,'name', 'rlnHelicalTubeID');
       
       fprintf('\t\tfinished object %d with %d points\n', object_counter, size(starfile_work.tbl,1));
       
       % write out the bounded starfile for each object (merge later)
       new_starfile_name = sprintf('bounded_starfiles_rln3/%s_boundary_%d.star',tomo_name{1},object_counter);
       dwrite(starfile_work, new_starfile_name);
       
       object_counter = object_counter + 1;
       
    end % Close inner for-loop
    
    fprintf('Finished working on %s\n\n', tomo_name{1});
    
end % Close outer for-loop

fprintf('\n\nFinished all objects and wrote results to bounded_starfiles_rln3/ \n\n');
fprintf('\nNow working on merging all bounded starfiles\n\n');

% Get list of all bounded starfiles
starfile_list = dir(fullfile('bounded_starfiles_rln3/','*.star'));

% Read in the first starfile to use as base file for merging
privileged_starfile = dread(fullfile('bounded_starfiles_rln3/', starfile_list(1).name));

% loop over all of ther starfiles to merged into the one currently read in
for i = 2:size(starfile_list,1)
    
    % read in next starfile
    tmp_starfile_name = fullfile('bounded_starfiles_rln3/', starfile_list(i).name);
    tmp_starfile = dread(tmp_starfile_name);
    
    % concatenate to new starfile to growing starfile table
    privileged_starfile.tbl = vertcat(privileged_starfile.tbl, tmp_starfile.tbl);
    
end

dwrite(privileged_starfile, 'bounded_merged_rln3.star');

fprintf('\n\nFinished merging starfiles.\n');
fprintf('Written out bounded_merged_rln3.star with %d points.\n\n', size(privileged_starfile.tbl,1));
fprintf('Done!\n\n');

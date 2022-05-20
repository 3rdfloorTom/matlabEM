%%%% Weight CC scores by orientation relative to the missing_wedge.
%%%%
%%%% Particularly usefull for tubular structure in which subunits from the
%%%% top and bottom possess abnormally lower CC scores due to the missing-wedge.
%%%%
%%%% Re-weighted CC's are normalized 0,1 on a per tube basis
%%%%
%%%% This script plots per-tube histograms in addition to writing out a new
%%%% table.
function [wedge_weighted_table] = wedge_weight_cc(table_file_name)

% Arguement checks
if nargin ~= 1
    error('wedge_weight_cc(): Incorrect inputs, takes 1 table file name as input')
end

if isfile(table_file_name)
    table = dread(table_file_name);
    fprintf('\nRead in the table file:\t %s \n', table_file_name)
else
       error('Could not find specified table, make sure path is correct')
end

% initialize empty table to hold re-weighted CC scores
wedge_weighted_table = table;

% Determine tube IDs
tubes = unique(table(:,20:21), 'rows');

% Create a figure for histograms
figure(1);
clf;

% Number of rows for sub-ploting
sub_plot_rows = ceil(size(tubes,1)/4);

% loop over the table to perform per-tube reweighting
for i = 1:size(tubes,1)
    
    tomo_id = tubes(i,1);
    tube_id = tubes(i,2);
       
    % restrict table to tube
    tube_inds = table(:,20) == tomo_id & table(:,21) == tube_id;
    tube_table = table(tube_inds,:);
    
    fprintf('\nWorking on tomo %d  tube %d from %d particles...\n', tomo_id, tube_id, size(tube_table,1));  
    
    % normalize tilt between 0,90
    normalized_tilts = abs(90 - tube_table(:,8));
    
    % fit a quadratic to the tilt vs cc
    [fit_poly, gof] = fit(normalized_tilts,tube_table(:,10), 'poly2');
    
    % divide cc by expected value based on fit curve
    wedge_weighted_cc = wedge_weighted_table(tube_inds,10)./(fit_poly.p1.*normalized_tilts.^2 + fit_poly.p2.* normalized_tilts + fit_poly.p3);
    
    % normalize between 0,1 & assigned to output table entries' CC values
    wedge_weighted_table(tube_inds,10) = wedge_weighted_cc/max(wedge_weighted_cc);
    
    % Plotting each tube on a subplot
    h = subplot(sub_plot_rows,4,i);
    
    h1 = histogram(table(tube_inds,10)/max(table(tube_inds,10)));
    h1.BinWidth = 0.05;
    hold on
    h2 = histogram(wedge_weighted_table(tube_inds,10));
    h2.BinWidth = 0.05;
    
    % name each subplot by the model
    t = sprintf('tomo-%d tube-%d', tomo_id, tube_id);
    title(t);
 
    % update plot
    drawnow;
    
end

legend('Original', 'Weighted');
% update plot
drawnow;
    
outfile_name = sprintf('rewgt_%s', table_file_name);
dwrite(wedge_weighted_table, outfile_name);



fprintf('\nFinished re-weighting CC values!\n');
fprintf('\nWrote out re-weighted table as: %s\n', outfile_name);
fprintf('\nDone!\n');

end
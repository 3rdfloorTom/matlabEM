% Wrapper to obtain lattice map with latticePlot functio stemming from a
% mispronounciation of "lattice".
%
% Compute and plot all pairwise distances between 2 tables.
%
% NOTE: the lattice2latticePlot.m function must be in the current MATLAB path for
% the wrapper to locate it.
%
%
% Parameters:
% - table_A_file: a dynamo formatted table file (reference-frame)
% - table_B_file: a dynamo formatted table file
% - dmax: max distance threshold for finding neighbours in pixels
% - dmin: min distance threshold for finding neighbours in pixels
% - plot_size: size of latticePlot in pixels, should be at least 2x dmax
% - binningFactor: amount to coarse tomogram coordinate system by
% - mask: same dimensions as plot_size for cleaning dataset based on the lattice plot created
%
% Minimal input formatting:
% lettuce2lettucePlot_wrapper('my_dynamo_A.tbl','my_dynamo_B.tbl' dmax);
% 
% Maximum input formmating:
% lettuce2lettucePlot_wrapper(table_A_file,table_B_file,dmax, dmin,plot_size,binningFactor,mask_file);
%
% Maximum output formmating:
% [latticePlotted,tags,pairs,table_select,table_exclude]=lettuce2lettucePlot_wrapper('my_dynamo_A.tbl','my_dynamo_B.tbl' dmax);

function [latticePlotted,tags,pairs,table_select,table_exclude]  = lettuce2lettucePlot_wrapper(table_A_file, table_B_file,dmax, dmin, plot_size,binningFactor,userMask)

% Check user inputs
if nargin > 7
    error('lettucePlot_wrapper(): Too many inputs, takes 7 at most')
end


% At least the table and dmax must be given
if nargin < 3
        error('lettucePlot_wrapper(): Too few inputs, takes at least 3 inputs')
end


if isfile(table_A_file) && isfile(table_B_file)
    ta = dread(table_A_file);
    tb = dread(table_B_file);
    fprintf('\nRead in the table_A file:\t %s \n', table_A_file)
    fprintf('\nRead in the table_A file:\t %s \n', table_B_file)
else
       error('Could not find one of the specified table, make sure path is correct')
end


switch nargin
    case 3
             dmin=1;
             plot_size = 2 * (dmax + 1);
             binningFactor = 1;
             mask = ones(plot_size,plot_size,plot_size);
             maskStatus = 0;
             
    case 4
             plot_size = 2 * (dmax + 1);
             binningFactor = 1;
             mask = ones(plot_size,plot_size,plot_size);
             maskStatus = 0;
             
    case 5
             binningFactor = 1;
             mask = ones(plot_size,plot_size,plot_size);
             maskStatus = 0;
             
    case 6
            mask = ones(plot_size,plot_size,plot_size);
            maskStatus = 0;
            
    case 7
            if isfile(userMask)
               mask = dread(userMask);
               maskStatus = 1;
            else
                mask = ones(plot_size,plot_size,plot_size);
                maskStatus = 0;
            end
            
end

if dmin >= dmax
     dmin = 1;
     fprintf('dmin must be smaller than dmax!\n')
     fprintf('Setting dmin to a default value of:\t %d \n', dmin)
end

if plot_size <= (2 * dmax)
    plot_size = 2 * (dmax + 1);
    fprintf('Designated plot_size is too small!\n')
    fprintf('Setting plot_size to a value of:\t %d \n', plot_size)
end

if maskStatus == 0
    fprintf('A user provided mask could not be found.\n')
    fprintf('Using a default mask of all ones. \n')
else
    fprintf('A user provided mask has been found.\n')
    fprintf('Results will be masked using:\t %s\n', userMask)
end

fprintf('\n');

fprintf('Using a max distance (dmax) of:\t\t %d\n', dmax)
fprintf('Using a min distance (dmin) of:\t\t %d\n', dmin)
fprintf('Using a plot size of:\t\t\t %d\n', plot_size)
fprintf('Using a binning factor of:\t\t %d\n\n', binningFactor)

ta(:,[4:6,24:26]) = ta(:,[4:6,24:26])./binningFactor; % bin
tb(:,[4:6,24:26]) = tb(:,[4:6,24:26])./binningFactor; % bin
fprintf('Now looping through tomograms and sub-regions...\n');

[latticePlotted, tags, pairs, table_select, table_exclude] = lattice2latticePlot(ta,tb,dmax,dmin,plot_size,mask);

[~, tableFileRootnameA, ~] = fileparts(table_A_file);
[~, tableFileRootnameB, ~] = fileparts(table_B_file);
if maskStatus == 1
    
    [~, maskRootname, ~]  = fileparts(userMask);
    latticeFile = sprintf('%s_to_%s_dmax_%d_dmin_%d_mask_%s.em',tableFileRootnameA,tableFileRootnameB,dmax,dmin,maskRootname);

    selectTblFile = sprintf('%s_to_%s_dmax_%d_dmin_%d_mask_%s_select.tbl',tableFileRootnameA,tableFileRootnameB,dmax,dmin,maskRootname);
    excludeTblFile = sprintf('%s_to_%s_dmax_%d_dmin_%d_mask_%s_exclude.tbl',tableFileRootnameA,tableFileRootnameB,dmax,dmin,maskRootname);

    dwrite(table_select, selectTblFile);
    dwrite(table_exclude, excludeTblFile);
else
    latticeFile = sprintf('%s_to_%s_dmax_%d_dmin_%d.em',tableFileRootnameA,tableFileRootnameB,dmax,dmin);
end

dwrite(latticePlotted,latticeFile);

fprintf('\nGenerated the lattice plot!\n')
fprintf('Wrote the lattice plot to disk as: %s \n\n', latticeFile)
fprintf('Now working a projection heatmap \n')


sqPlot=squeeze(sum(latticePlotted,3));
%rotPlot=rot90(sqPlot);

h = heatmap(rotPlot, 'Colormap', flipud(gray));
h.Title = "Lattice plot projection";
grid off

fprintf('Finished working on the projection heatmap!\n\n')

if maskStatus == 1
    fprintf('Applied user supplied mask to lattice plot.\n')
    fprintf('Wrote out table of selected particles as:\t %s\n', selectTblFile)
    fprintf('Wrote out table of excluded particles as:\t %s\n', excludeTblFile)
end

fprintf('Script has finished!\n\n')

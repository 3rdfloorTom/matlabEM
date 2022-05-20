% Wrapper to obtain lattice map with latticePlot function stemming from a
% mispronounciation of "lattice" and the joy I get from calling it the "lettuce wrapper".
%
% NOTE: the latticePlot.m function must be in the current MATLAB path for
% the wrapper to locate it.
%
% When running for the first time on a dataset, inspect the initial latticePlot for prominent neighbours. Then use this to design masks
% that can select particles based on the spatial relationship between particles in the lattice.
%
% Then, run a second time with a supplied mask to select specific particles
%
% Parameters:
% - inputTbl: a dynamo formatted table file
% - dmax: max distance threshold for finding neighbours in pixels
% - dmin: min distance threshold for finding neighbours in pixels
% - plot_size: size of latticePlot in pixels, should be at least 2x dmax
% - binningFactor: amount to coarse tomogram coordinate system by
% - mask: same dimensions as plot_size for cleaning dataset based on the lattice plot created
%
% Minimal input formatting:
% lettucePlot_wrapper('my_dynamo.tbl', dmax);
% 
% Maximum input formmating:
% lettucePlot_wrapper('my_dyanmo_table.tbl', dmax, dmin, plot_size, binningFactor , 'my_mask_for_selection.mrc')
%
% Maximum output formmating:
% [latticePlotted,tags,pairs,table_select,table_exclude]=lettucePlot_wrapper('my_dynamo.tbl', dmax);

function [latticePlotted,tags,pairs,table_select,table_exclude]  = lettucePlot_wrapper(inputTbl, dmax, dmin, plot_size,binningFactor,userMask)

% Check user inputs
if nargin > 6
    error('lettucePlot_wrapper(): Too many inputs, takes 6 at most')
end


% At least the table and dmax must be given
if nargin < 2
        error('lettucePlot_wrapper(): Too few inputs, takes at least 2 inputs')
end


if isfile(inputTbl)
    t = dread(inputTbl);
    fprintf('\nRead in the table file:\t %s \n', inputTbl)
else
       error('Could not find specified table, make sure path is correct')
end


switch nargin
    case 2
             dmin=1;
             plot_size = 2 * (dmax + 1);
             binningFactor = 1;
             mask = ones(plot_size,plot_size,plot_size);
             maskStatus = 0;
             
    case 3
             plot_size = 2 * (dmax + 1);
             binningFactor = 1;
             mask = ones(plot_size,plot_size,plot_size);
             maskStatus = 0;
             
    case 4
             binningFactor = 1;
             mask = ones(plot_size,plot_size,plot_size);
             maskStatus = 0;
             
    case 5
            mask = ones(plot_size,plot_size,plot_size);
            maskStatus = 0;
            
    case 6
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

t(:,[4:6,24:26]) = t(:,[4:6,24:26])./binningFactor; % bin
fprintf('Now looping through tomograms and sub-regions...\n');

[latticePlotted, tags, pairs, table_select, table_exclude] = latticePlot(t,dmax,dmin,plot_size,mask);

[~, tableFileRootname, ~] = fileparts(inputTbl);
if maskStatus == 1
    
    [~, maskRootname, ~]  = fileparts(userMask);
    latticeFile = sprintf('%s_dmax_%d_dmin_%d_mask_%s.em',tableFileRootname,dmax,dmin,maskRootname);

    selectTblFile = sprintf('%s_dmax_%d_dmin_%d_mask_%s_select.tbl',tableFileRootname,dmax,dmin,maskRootname);
    excludeTblFile = sprintf('%s_dmax_%d_dmin_%d_mask_%s_exclude.tbl',tableFileRootname,dmax,dmin,maskRootname);

    dwrite(table_select, selectTblFile);
    dwrite(table_exclude, excludeTblFile);
else
    latticeFile = sprintf('%s_dmax_%d_dmin_%d.em',tableFileRootname,dmax,dmin);
end

dwrite(latticePlotted,latticeFile);

fprintf('\nGenerated the lattice plot!\n')
fprintf('Wrote the lattice plot to disk as: %s \n\n', latticeFile)
fprintf('Now working a projection heatmap \n')


sqPlot=squeeze(sum(latticePlotted,3));
%rotPlot=rot90(sqPlot);

h = heatmap(sqPlot, 'Colormap', flipud(gray));
h.Title = "Lattice plot projection";
grid off

fprintf('Finished working on the projection heatmap!\n\n')

if maskStatus == 1
    fprintf('Applied user supplied mask to lattice plot.\n')
    fprintf('Wrote out table of selected particles as:\t %s\n', selectTblFile)
    fprintf('Wrote out table of excluded particles as:\t %s\n', excludeTblFile)
end

fprintf('Script has finished!\n\n')

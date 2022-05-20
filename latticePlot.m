% Plot of lattice neighbours

% Rationale: this can be a helpful to visualise the extent of order in lattice assemblies. This function iterates over every particle
% to find neighbours within a certain distance range (dmax and dmin), calculate their relative orientation, and fill a lattice plot volume (dimensions
% specified by plot_size) to represent neighbouring particles for all particles in a dataset.
%
% When running for the first time on a dataset, inspect the initial latticePlot for prominent neighbours. Then use this to design masks
% that can select particles based on the spatial relationship between particles in the lattice.
%
% Parameters
% - table: dynamo formatted table
% - dmax: max distance threshold for finding neighbours (pixels)
% - dmin: min distance threshold for finding neighbours (pixels)
% - plot_size: size of latticePlot in pixels, should be at least 2x dmax. Even numbers only.
% - mask: same dimensions as plot_size for cleaning dataset based on the lattice plot created


function [latticeMap,tags,pairs,table_select,table_exclude] = latticePlot(table,d_max,d_min,plot_size,mask)

    % copy for final selection
    table2 = table;
    
    % for lattice plot
    latticeMap = zeros(plot_size,plot_size,plot_size);
    
    % cell array of pixel values for mask
    ptlist = cell((plot_size^3),1);
    ptlistmask = ptlist;
    
    % mask indices
    maski = find(mask(:));
    
    % empty lists for selected tags and pairs
    tags = []; 
    pairs = [];
    
    % apply shifts and zero them
    table(:,24) = table(:,4) + table(:,24);    
    table(:,25) = table(:,5) + table(:,25);
    table(:,26) = table(:,6) + table(:,26);
    table(:,4:6) = 0;

    % split table by tomo / sub-region (dynamo tbl col. 20 and 21)
    tomo_list = unique(table(:,20:21),'rows');
    for i = 1:size(tomo_list,1)
        
        % restrict table
        tomon = tomo_list(i,1);
        region = tomo_list(i,2);
        tablet = table((table(:,20)==tomon)&(table(:,21)==region),:);

        disp(['tomo ' num2str(tomon) ' region ' num2str(region) '...']);

        for ii = 1:size(tablet,1)
        
            % particle and shifts
            p = tablet(ii,:);
        
            % find all distances and select those between thresholds
            d = sqrt(((tablet(:,24)-p(24)).^2)+((tablet(:,25)-p(25)).^2)+((tablet(:,26)-p(26)).^2));
            td = tablet((d<d_max)&(d>d_min),:);
            
            for j = 1:size(td,1)
                
                % find translation
                x = td(j,24) - p(24);
                y = td(j,25) - p(25);
                z = td(j,26) - p(26);
                
                % rotate vector
                rot = dynamo_euler2matrix([-p(9),-p(8),-p(7)]);
                rotr = round(rot'*[x;y;z]);
                rotr = rotr + ((plot_size/2) + 1); % vector w/r to volume centre
                latticeMap(rotr(1),rotr(2),rotr(3)) =  latticeMap(rotr(1),rotr(2),rotr(3)) + 1;

                ind = sub2ind(repmat(plot_size,[1,3]),rotr(1),rotr(2),rotr(3));
                
                % mask by matching linear indices
                if ismember(ind,maski)
                    ptlistmask{ind} = [ptlistmask{ind},p(1)];
                    tags = cat(1,tags,p(1),td(j,1));
                    pairs = [pairs;p(1),td(j,1)];
                end
                
                % store tag in linear indices of pixels
                ptlist{ind} = [ptlist{ind},p(1)];
                
            end
        end
    end

tags = unique(tags);
table_select = table2(ismember(table(:,1),tags),:);
table_exclude = table2(~ismember(table(:,1),tags),:);
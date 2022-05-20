% Plot of lattice neighbours between two tables

% Rationale: this can be a helpful tool to visualise the extent of order in lattice assemblies. This function iterates over every particle
% to find neighbours within a certain distance range (dmax and dmin), calculate their relative orientation, and fill a lattice plot volume (dimensions
% specified by plot_size) to represent neighbouring particles for all particles in a dataset.
%
% When running for the first time on a dataset, inspect the initial latticePlot for prominent neighbours. Then use this to design masks
% that can select particles based on the spatial relationship between particles in the lattice.
%
% Parameters
% - table: a dynamo formatted table
% - dmax: max distance threshold for finding neighbours
% - dmin: min distance threshold for finding neighbours
% - plot_size: size of latticePlot in pixels, should be at least 2x dmax
% - mask: same dimensions as plot_size for cleaning dataset based on the lattice plot created


function [latticePlot,tags,pairs,table_select,table_exclude] = lattice2latticePlot(table_A,table_B,d_max,d_min,plot_size,mask)

    % copy for final selection
    table_A2 = table_A;
    %table_B2 = table_B;
    
    % for lattice plot
    latticePlot = zeros(plot_size,plot_size,plot_size);
    
    % cell array of pixel values for mask
    ptlist = cell((plot_size^3),1);
    ptlistmask = ptlist;
    
    % mask indices
    maski = find(mask(:));
    
    % empty lists for selected tags and pairs
    tags = []; 
    pairs = [];
    
    % apply shifts and zero them
    table_A(:,24) = table_A(:,4) + table_A(:,24);    
    table_A(:,25) = table_A(:,5) + table_A(:,25);
    table_A(:,26) = table_A(:,6) + table_A(:,26);
    table_A(:,4:6) = 0;
    
    table_B(:,24) = table_B(:,4) + table_B(:,24);    
    table_B(:,25) = table_B(:,5) + table_B(:,25);
    table_B(:,26) = table_B(:,6) + table_B(:,26);
    table_B(:,4:6) = 0;

    
    % split table by tomo / sub-region (dynamo tbl col. 20 and 21)
    tomo_list_A = unique(table_A(:,20:21),'rows');
    for i = 1:size(tomo_list_A,1)
        
        % restrict table
        tomon = tomo_list_A(i,1);
        region = tomo_list_A(i,2);
        
        tablet_A = table_A((table_A(:,20)==tomon)&(table_A(:,21)==region),:);
        %tablet_tmp=tablet_A;
        %tablet_tmp(:,:)=0;
        
        tablet_B = table_B((table_B(:,20)==tomon)&(table_B(:,21)==region),:);
        %size_B = size(tablet_B,1);
        %tablet_tmp(1:size_B,:)=tablet_B;
        
        disp(['tomo ' num2str(tomon) ' region ' num2str(region) '...']);

        for ii = 1:size(tablet_B,1)
        
            % particle and shifts
            p = tablet_B(ii,:);
        
            % find all distances and select those between thresholds
            % compute differences by substracting all points in B from A
            d = sqrt(((tablet_A(:,24)-p(24)).^2)+((tablet_A(:,25)-p(25)).^2)+((tablet_A(:,26)-p(26)).^2));
            td = tablet_A((d<d_max)&(d>d_min),:);
            
            for j = 1:size(td,1)
                
                % find translation
                x = td(j,24) - p(24);
                y = td(j,25) - p(25);
                z = td(j,26) - p(26);
                
                % rotate vector
                rot = dynamo_euler2matrix([-p(9),-p(8),-p(7)]);
                rotr = round(rot'*[x;y;z]);
                rotr = rotr + ((plot_size/2) + 1); % vector w/r to volume centre
                latticePlot(rotr(1),rotr(2),rotr(3)) =  latticePlot(rotr(1),rotr(2),rotr(3)) + 1;

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
table_select = table_A2(ismember(table_A(:,1),tags),:);
table_exclude = table_A2(~ismember(table_A(:,1),tags),:);

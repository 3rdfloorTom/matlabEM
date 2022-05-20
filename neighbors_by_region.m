function n_neighbors = neighbors_by_region(table, min_dist, max_dist)
    
    % read table if provided as file name
    if ischar(table)
        table = dread(table);
    end
    
    % Initialize marix for results
    n_neighbors = zeros(size(table, 1), 1);
    
    % get unique tomogram index values
    regions = unique(table(:,20:21), 'rows');
    
    for i = 1:size(regions,1)
        
        % restrict table to current region
        region_idx = table(:, 20) == regions(i,1)  &  table(:,21) == regions(i,2);
        region_table = table(region_idx, :);
        
        % get xyz coords (shifts + position)
        xyz = region_table(:, 4:6) + region_table(:, 24:26);
        
        % get neighbours in range
        distance_matrix = squareform(pdist(xyz));
        neighbors = distance_matrix >= min_dist & distance_matrix <= max_dist;
        n_neighbors_tmp = sum(neighbors, 1);
        
        % insert in output
        n_neighbors(region_idx) = n_neighbors_tmp;
    
    end
end

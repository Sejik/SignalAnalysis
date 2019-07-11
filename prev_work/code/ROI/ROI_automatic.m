%% Econnectome ROI automatic

for num = 1:10
    labels = BA(num);
    centers = [X(num) Y(num) Z(num)];
    radius = 10;
    
    model.cortex = load('colincortex.mat');
    XI = model.cortex.colincortex.Vertices;

    dists = sqrt( (XI(:,1)-centers(1)).^2 + (XI(:,2)-centers(2)).^2 + (XI(:,3)-centers(3)).^2 );
    vidx = find(dists<radius);
    vertices = {vidx};
    numv = 20516;
    
    clear XI dists model radius vidx;
    
    save(num2str(num), 'labels', 'vertices', 'numv', 'centers');
end



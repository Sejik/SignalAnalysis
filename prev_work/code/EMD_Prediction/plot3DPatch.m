function plot3DPatch(Data,minD,maxD,noShades,viewAngle,elAngle)

%Data = array of 400, 200 or 148 parcel data
%minD = minimum of colour range
%maxD = maximum of colour range
%noShades = number of steps in colour range
%viewAngle = view angle of 3D brain
%elAngle = elevation angle of 3D brain

%Note: If manually rotating figure you will need to reset the lighting with
%camlight('headlight')


%% import data
load('PatchData.mat');

%% Scale data to range selected (minD:maxD with noShades)
if ~(exist('minD','var'))
    minD = min(Data);
    maxD = max(Data);
end
sizeSlice = (maxD - minD) / noShades;

Data(Data<minD) = minD;
Data(Data>maxD) = maxD;

nans = isnan(Data);
Data = floor((Data - minD)/sizeSlice);
Data(nans) = -1; %nans will be coloured black
cmap = jet(noShades);
cmap = [0 0 0; cmap];


%% create patch

noParcels = length(Data);
switch(noParcels)
    case 400
        lst = lsts400;
    case 200
        lst = lsts200;
    case 148
        lst = lsts149;
end

%colour all triangles in a parcel the same colour
p.CData = nan(length(TriangleVertexCoordinatesDBL0),1);
for i = 1:noParcels
    p.CData(lst(i).lst + 1) = Data(i);
end

%substitute triangles not assigned to a patch with the nearest triangle
notThere = find(isnan(p.CData));
p.CData(notThere) = p.CData(instead);
p.Vertices = [TriangleVertexCoordinatesDBL0 TriangleVertexCoordinatesDBL1 + 20 TriangleVertexCoordinatesDBL2];

p.Faces = ([TriX + 1 TriY + 1 TriZ + 1]);
p.EdgeColor = 'none';
p.facecolor = 'interp';

%% plot Patch
figure
colormap(cmap);
set(gcf,'color','white');
patch(p)
axis([-90 90 -90 90 -90 90])
axis square
axis off
view(elAngle,viewAngle)
set(gca,'clim',[-1 noShades]);
camlight('headlight')
material dull

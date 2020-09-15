%%% Comment about usage
%%%
function pltMemByLvlsCrops(modelFile)

% Read in model
m = dread(modelFile);

% Some cosmetics for the plot
figureM = figure();
figureM.Name = 'Cropping points and orientation';
haxis = gca;
view([1,-1,1]);
box on;
axis equal;

fprintf('This can take quite a bit of time to plot, please hang-on...');

% Now plot
m.plotTableSketch(haxis,'hold_limits', false);
m.plotTablePoints(haxis,'hold_limits',true);
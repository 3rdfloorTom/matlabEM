%%% This script plots all of the half-map FSCs for a Dynamo alignment run.
%%% It assumes running from one directory above the alignment directory.
%%%
%%% Usage:
%%% plot_all_the_dfscs('myAlignmentJob', Ang/px)
function plot_all_the_dfscs(alignmentJob,pixelSize)

% Check user inputs
if nargin ~= 2
    error('plot_all_the_dfscs(): takes 2 required inputs')
end

% Get all of the iteration directories
resultsList = dir(fullfile(alignmentJob,'results','ite_*','averages','*.fsc'));
resultsLength = length(resultsList);

% Get PATH and filename for each FSC file
averageDirs = {resultsList.folder};
fscFiles = {resultsList.name};

% Initializing cell array to hold legend names
Iteration = cell(resultsLength,1);

% Initialize figure
figure;
hold on

for k = 1:resultsLength 
    
    % Build-up list of iterations for legend
    Iteration{k,1} = sprintf('%04d', k);
    
    % Build the filename of the FSC file and read into variable using
    % Dynamo function 'dread'
    filename = fullfile(averageDirs{k},fscFiles{k});
    fsc = dread(filename);

    % Get number of Fourier pixels and convert to spatial frequency
    n_samples = size(fsc, 2);
    nyquist_freq = 1 / ( 2 * pixelSize );
    spectral_idx = 1:n_samples;
    fraction_of_nyquist = spectral_idx / n_samples;
    spatial_frequency = fraction_of_nyquist * nyquist_freq;
    
    % Yes, I'm plotting in a for-loop, sue me.
    plot(spatial_frequency, fsc,'-o','LineWidth',1.5);

end

% Plot formatting non-sense
ptitle = sprintf('Half-map FSCs for %s',alignmentJob);
title(ptitle)
xlabel('Spatial Frequency, 1/\AA','Interpreter','latex','Fontsize',12)
ylabel('Fourier Shell Correlation','Fontsize', 12)
ylim([0.0 1.2])

numCols = round(resultsLength / 5);

leg = legend(Iteration{:,1},'AutoUpdate','off', 'NumColumns', numCols);
legTitle = get(leg,'Title');
set(legTitle,'String','Iteration');

yline(0.5, '--', "FSC=0.5");
yline(0.143, '--', "FSC=0.143");

% Release figure/plotting
hold off

%%% This script plots half-map FSC for a Dynamo alignment iteration
%%% It assumes running from one directory above the alignment directory
%%%
%%% Usage:
%%% plot_this_dfsc('myAlignmentJob', iteration, angpix)
function plot_this_dfsc(alignmentJob,iteration,pixelSize)

% Check user inputs
if nargin ~= 3
    error('plot_this_dfsc(): takes 3 required inputs')
    
end

% Make file path to fsc file and read it into a dynamo variable
ite = sprintf('ite_%04d',iteration);
fscFile = sprintf('eo_fsc_ref_001_ite_%04d.fsc',iteration);
filename = fullfile(alignmentJob,'results',ite,'averages',fscFile);

fsc = dread(filename);

% Get resolution info and convert to spatial frequency
n_samples = size(fsc, 2);
nyquist_freq = 1 / ( 2 * pixelSize );
spectral_idx = 1:n_samples;

fraction_of_nyquist = spectral_idx / n_samples;
spatial_frequency = fraction_of_nyquist * nyquist_freq;

resolution_ang = spatial_frequency.^-1;

% Get position of cut-offs and send to stdout
idx05 = fsc > 0.5;
shells05 = resolution_ang(idx05);
resolution_at_05 = shells05(end)

idx0143 = fsc > 0.143;
shells0143 = resolution_ang(idx0143);
resolution_at_0143 = shells0143(end)

figure
hold on

plot(spatial_frequency, fsc,'-o','LineWidth',2)

ptitle = sprintf('Half-map FSC for %s iter-%d', alignmentJob, iteration);
title(ptitle)
xlabel('Spatial Frequency, 1/\AA','Interpreter','latex','Fontsize',12)
ylabel('Fourier Shell Correlation', 'Fontname', 'Helvetica', 'Fontsize', 12)
ylim([0.0 1.2])

yline(0.5, '--', "FSC=0.5");
yline(0.143, '--', "FSC=0.143");

hold off
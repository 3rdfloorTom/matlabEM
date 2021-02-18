%%% This function generates a mean intensity surface of the input volume
%%% along the specified dimension. It uses Dynamo functions to read the
%%% volume as a ws variable.
%%%
%%% Input volume is assumed to be a a file (i.e., not a ws variable).
%%% Specifiy the dimension as 'X','Y', or 'Z' ('x','y','z' also work).
%%%
%%% Example usage:
%%%
%%% outputSurface=meanSurface('someVolume.em','x');
%%% 
%%% Remember to write your mean surface to disk as needed.
%%%
%%% Author: TL (UCSD 2020)
function [meanSurf] = meanSurface(volumeFile,dimension)

% Check user inputs
if nargin > 2
    error('meanSurface(): Too many inputs, takes 2 at most')
end

% Fill optional inputs with default values
if nargin == 1
    dimension = 'X';
end

switch dimension
    
    case {'X','x'}
        dim = 1;
    case {'Y','y'}
        dim = 2;
    case {'Z','z'}
        dim = 3;
    otherwise
        Warning('Invalid dimension: dimension must be X,Y,or Z (x,y,or z).')
        Warning('Defaulting to averaging along X')
        dim = 1;
end

% Read in volume file
inputSurface = dread(volumeFile);
% Average input along the specified dimension
inputAvg = mean(inputSurface,dim);


% Get input side-length
inputSidelength = size(inputSurface);
% Prepare empty volume for filling with mean intensity values
meanSurf = zeros(inputSidelength);

% Inelegant way to fill the meanSurface based on specified direction...
switch dim
    case 1
        for i=1:inputSidelength
            meanSurf(i,:,:) = inputAvg;
        end
    case 2
        for i=1:inputSidelength
            meanSurf(:,i,:) = inputAvg;
        end
    case 3
        for i=1:inputSidelength
            meanSurf(:,:,i) = inputAvg;
        end
    otherwise
        error('Something has gone horribly wrong...')
end

fprintf('A mean intensity surface along %s has been prepared! \n', dimension)

end
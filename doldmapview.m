% Wrapper to old version of dmapview (better on in my opinion...)
%
% Orthoslice based viewer for (small) sets of (small) volumes or single cubes.
%
% INPUT
%
%        data:    - single volume (as cube or filename)
%                 - small sets of volumes (cell arrays of cubes or filenames)
%
%
% Parameter/Value
%
%
%        'bin'    This is a useful parameter when working with big
%                 particles that could block the memory.
%
%        'mask'   Passes an additional chain that will be used as mask.
%
%
%
%  I/O parameters:
%
%   'append'      0/1.
%                 1: If switched on, the passed volume(s)
%                    will join the scene with the ones already contained in
%                    the memory of mapview.
%                 0: (default). The passed volume(s) replace the previous
%                    contents of mapview.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% EXAMPLES of SYNTAX
%
%  doldmapview(volumes);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  SYNTAX
%  
%  doldmapview filename
%  doldmapview filename
%
%  SEE ALSO
%  An older version of this utility can be invoked by:
%  dpkdev.legacy.dynamo_mapview();
function [varargout] = doldmapview(varargin)
if nargout==0; 
    dpkdev.legacy.dynamo_mapview(varargin{:});
  else
    for i=1:nargout
       varargout{i}={NaN};
    end
    varargout{:} = dpkdev.legacy.dynamo_mapview(varargin{:});
end 

function newPathList = RemoveGITPaths(pathList)
% newPathList = RemoveSVNPaths(pathList)
% Removes any .git paths from the pathList.  If no pathList is specified,
% then the program sets pathList to the result of the 'path' command.  This
% function returns a 'pathsep' delimited list of paths omitting the .svn
% paths.

% History:
% Adapted from RemoveSVNPaths present in Psychtoolbox

% If no pathList was passed to the function we'll just grab the one from
% Matlab.
if nargin ~= 1
    % Grab the path list.
    pathList = path;
end

% use the general path-remover, targeting ".svn"
newPathList = RemoveMatchingPaths(pathList, [filesep '.git']);

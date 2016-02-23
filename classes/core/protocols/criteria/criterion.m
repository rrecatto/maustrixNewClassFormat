classdef criterion
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function s=criterion(varargin)
        % CRITERION  class constructor.  ABSTRACT CLASS -- DO NOT INSTANTIATE
        % s=criterion()

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'criterion'))
                        s = varargin{1};
                    else
                        error('Input argument is not a criterion object')
                    end

                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function graduate = checkCriterion(criterion,subject,trainingStep,trialRecords, compiledRecords)
            graduate=0;
        end
        
        function outStr = getNameFragment(cr)
        % returns abbreviated class name
        % should be overriden by criterion-specific strings
        % used to generate names for trainingSteps

            outStr = class(cr);

        end % end function
        
    end
    
end


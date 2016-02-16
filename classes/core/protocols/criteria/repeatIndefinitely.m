classdef repeatIndefinitely
    
    properties
    end
    
    methods
        function s=repeatIndefinitely(varargin)
            % REPEATINDEFINITELY  class constructor.
            % s=repeatIndefinitely()

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s=struct([]);
                    s = class(s,'repeatIndefinitely',criterion());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'repeatIndefinitely'))
                        s = varargin{1};
                    else
                        error('Input argument is not a repeatIndefinitely object')
                    end

                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function graduate = checkCriterion(criterion,subject,trainingStep,trialRecords, compiledRecords)
            graduate=0;
        end
        
        function d=display(s)
            d='repeat indefinitely';
        end
        
        
    end
    
end


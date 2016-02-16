classdef scheduler
    
    properties
    end
    
    methods
        function s=scheduler(varargin)
            % SCHEDULER  class constructor.  ABSTRACT CLASS -- DO NOT INSTANTIATE
            % s=scheduler()

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s=struct();
                    s = class(s,'scheduler');
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'scheduler'))
                        s = varargin{1};
                    else
                        error('Input argument is not a scheduler object')
                    end

                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [keepWorking secsRemainingTilStateFlip updateScheduler scheduler] = checkSchedule(scheduler,subject,trainingStep,trialRecords,sessionNumber)
            keepWorking=1;
            secsRemainingTilStateFlip=0;
            updateScheduler=0;
            newScheduler=[];
        end
        
        function outStr = getNameFragment(sch)
            % returns abbreviated class name
            % should be overriden by scheduler-specific strings
            % used to generate names for trainingSteps

            outStr = class(sch);

        end % end function
        
    end
    
end


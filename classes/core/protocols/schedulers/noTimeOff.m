classdef noTimeOff<scheduler
    
    properties
    end
    
    methods
        function s=noTimeOff()
            % NOTIMEOFF  class constructor.  
            % s=noTimeOff()

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'noTimeOff'))
                        s = varargin{1};
                    else
                        error('Input argument is not a noTimeOff object')
                    end
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function  [keepWorking secsRemainingTilStateFlip  updateScheduler scheduler]= checkSchedule(scheduler,subject,trainingStep, trialRecords,sessionNumber)
            keepWorking=1;
            secsRemainingTilStateFlip=0;
            updateScheduler=0;
        end
        
        function d=display(s)
            d='no time off';
        end
        
        
    end
    
end


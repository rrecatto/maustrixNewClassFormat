classdef minutesPerSession<scheduler

    properties
        numTrialsNeeded = 1;
    end
    
    methods
        function s=numTrialsDoneCriterion(varargin)
            % NUMTRIALSDONECRITERION  class constructor.  
            % s=numTrialsDoneCriterion([numTrialsNeeded])

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'numTrialsDoneCriterion'))
                        s = varargin{1};
                    elseif isscalar(varargin{1})
                        s.numTrialsNeeded = varargin{1};
                        
                    else
                        error('Input argument is not a numTrialsDoneCriterion object')
                    end
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [keepWorking secsRemainingTilStateFlip updateScheduler scheduler] = checkSchedule (scheduler, subject, trainingStep, trialRecords, sessionNumber)
            %find the trials of this session
            %
            if ~isempty(trialRecords)
                trialsThisSession=trialRecords([trialRecords.sessionNumber]==sessionNumber);
            else
                trialsThisSession=trialRecords;
            end

            if size(trialsThisSession,2)>1

                startTime=datenum(trialsThisSession(1).date);
            else
                startTime=now;
            end

            if (now-startTime)*(24*60)>scheduler.minutes
                keepWorking=0;
            else
                keepWorking=1;
            end

            secsRemainingTilStateFlip=(now-startTime)*24*60*60;
            updateScheduler=0;
        end

        function d=display(s)
            d=['hour range (minutesPerSession: ' num2str(s.minutes) ')'];
        end
        
        function [hoursBetweenSessions] = getCurrentHoursBetweenSession(s)
            hoursBetweenSessions=s.hoursBetweenSessions;
        end
        
    end
    
end


classdef nTrialsThenWait<scheduler
    
    properties
        possibleNumTrials=0;
        possibleHoursBetweenSessions=0;
        probOfNumTrials=0;
        probOfHoursBetweenSessions=0;
        numTrials=0;
        hoursBetweenSessions=0;
        isOn=0;
        lastCompletedSessionEndTime=0;
    end
    
    methods
        function s=nTrialsThenWait(varargin)
            % NTRIALSTHENWAIT  class constructor.  
            % s=nTrialsThenWait(possibleNumTrials,probOfNumTrials,possibleHoursBetweenSessions,probOfHoursBetweenSessions)
            % s=nTrialsThenWait([200,300,500],[1/3,1/3,1/3],[5],[1])

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'nTrialsThenWait'))
                        s = varargin{1};
                    else
                        error('Input argument is not a nTrialsThenWait object')
                    end
                case 4
                    if all(varargin{1}>=0) && all(varargin{3}>=0)
                        %these are a list off possible values
                        s.possibleNumTrials=varargin{1};
                        s.possibleHoursBetweenSessions=varargin{3};
                    else
                        error('all values of possibleNumTrials and possibleHoursBetweenSessions must be >= 0')
                    end

                    if (sum(varargin{2})==1) && (sum(varargin{4})==1) && length(varargin{1})==length(varargin{2}) && length(varargin{3})==length(varargin{4})
                        %these are the probability of each of the possible values
                        s.probOfNumTrials=varargin{2};
                        s.probOfHoursBetweenSessions=varargin{4};
                    else
                        varargin{1};
                        varargin{2};
                        varargin{3};
                        varargin{4};
                        error('probability values must sum to one a be the same length as the possible values')
                    end

                    s.numTrials=0;
                    s.hoursBetweenSessions=0;
                    s.isOn=1;
                    s.lastCompletedSessionEndTime=0;

                    
                otherwise
                    error('Wrong number of input arguments')
            end

                    s = setNewHoursBetweenSession(s);
                    s = setNewNumTrials(s);
        
        end
        
        function [keepWorking secsRemainingTilStateFlip updateScheduler scheduler] = checkSchedule (scheduler, subject, trainingStep, trialRecords, sessionNumber)

            % scheduler=nTrialsThenWait([200,300,500],[1/3,1/3,1/3],[5],[1])
            % a=now;
            % b=now;
            % c=now;
            % d=now;
            % e=now;
            % sessionStartStops=[a,b;c,d;e,0];
            % [keepWorking secsRemainingTilStateFlip updateScheduler scheduler] = checkSchedule(scheduler,1,sessionStartStops,[],[])


            % if isa(trainingStep,'trainingStep')
            %     
            %     %GET FROM THE TRAININGSTEP!
            %     [sessionRecords ]=getSessionRecords(trainingStep);
            %     if size(sessionRecords,1)>0
            %         sessionStarts=sessionRecords(:,1);  
            %         sessionStops=sessionRecords(:,2);  
            %     else
            %         sessionStarts=now;
            %         sessionStops=0;
            %         trialsCompleted=0;
            %     end
            % else
            %     error('must be a training step')
            % end


             if size(trialRecords,1)>0
                    trialsThisSession=[trialRecords.sessionNumber]==sessionNumber;
                    trialsCompleted=sum(trialsThisStep);    
             else
                    trialsCompleted=0;
                    scheduler.isOn=1;  % start out on if there are no trials in history
             end


             %why calculate this at all if we can save it in the state of the scheduler
             %calulate if scheduler isOn only if not first session & trial
            % if ~isempty(sessionStops)
            %     scheduler.isOn=(0>sessionStops(end)-sessionStarts(end))    %if there is no stop time, its 0, so stop-start is negative when scheduler is on
            % end

            %initialize
            updateScheduler=0;
            %in the long run, its okay to update the the scheuler alot, b/c it won't be
            %the whole ratrix, but just the training step. Thus its safe to be able to
            %save the scheduler after every trial (not just after session start stops)
            %If set to 0, this script still has extra calls to updateScheduler that enforces
            %session-only changes.   


            %if the first session and the scheduler is off, need a reference time point
            if scheduler.lastCompletedSessionEndTime==0 && ~scheduler.isOn
                scheduler.lastCompletedSessionEndTime=now;
                updateScheduler=1;
                %note: if scheduler.isOn at start (which it is hard coded to be) then lastCompletedSessionEndTime will be
                %called on the N+1th trial before the wait mode
            end

            prevSessionEndTime=scheduler.lastCompletedSessionEndTime;
            %prevSessionEndTime=max(sessionStops(:))  %be aware of first session see below

            %this is a check for the first session, which is tricky because there is no real prevSessionEndTime
            %we don't worry about this, b/c we save scheduler.lastCompletedSessionEndTime
            %     if (prevSessionEndTime==0) | (isempty(prevSessionEndTime))
            %         warning('this must be the first session')  % but thats okay if the 
            %         sessionNum=length(sessionStops)
            %         if scheduler.isOn && sessionNum==1
            %             %no problem
            %         else
            %             sessionStops=sessionStops
            %             prevSessionEndTime=prevSessionEndTime
            %             error('unexpected sessionStartStops')
            %         end
            %     end


            if scheduler.isOn==1
                %check to see if numTrials for this session has passed
                if trialsCompleted<scheduler.numTrials

                    keepWorking=1;
                    secsRemainingTilStateFlip=-1;
                else
                    disp(sprintf('turning off schedulder b/c reached end of session after %d',scheduler.numTrials))
                    scheduler.isOn=0  
                    scheduler.lastCompletedSessionEndTime=now; 
                    scheduler=setNewHoursBetweenSession(scheduler);
                    keepWorking=0;
                    secsRemainingTilStateFlip=scheduler.hoursBetweenSessions*3600;
                    updateScheduler=1;
                end   

            elseif scheduler.isOn==0
                %check to see if hoursBetweenSession has passed 
                hrsSince=etime(datevec(now),prevSessionEndTime)/3600
                if  hrsSince<scheduler.hoursBetweenSessions
                    keepWorking=0;
                    secsRemainingTilStateFlip=(scheduler.hoursBetweenSessions-hrsSince)*3600;
                else
                    %turn on schedulder
                    disp(sprintf('turning on schedulder b/c reached end of waiting period in %d hours',scheduler.hoursBetweenSessions))
                    scheduler.isOn=1; 
                    scheduler=setNewNumTrials(scheduler)
                    keepWorking=1;
                    secsRemainingTilStateFlip=-1;

                    updateScheduler=1;
                end        
            else
                error('scheduler.isOn must be 0 or 1')
            end

        end

        function d=display(s)
            d=['nTrialsThenWait (numTrials: ' num2str(s.numTrials) ' hoursBetweenSessions: ' num2str(s.hoursBetweenSessions) ')'];
            disp(d);
            disp(['possibleNumTrials: ' num2str(s.possibleNumTrials)])
            disp(['probOfNumTrials: ' num2str(s.probOfNumTrials)])
            disp(['possibleHoursBetweenSessions: ' num2str(s.possibleHoursBetweenSessions)])
            disp(['probOfHoursBetweenSessions: ' num2str(s.probOfHoursBetweenSessions)])
            disp(['isOn: ' num2str(s.isOn)])
            disp(['lastCompletedSessionEndTime: ' num2str(s.lastCompletedSessionEndTime)])
        end
        
        function [hoursBetweenSessions] = getCurrentHoursBetweenSession(s)

            hoursBetweenSessions=s.hoursBetweenSessions;

        end
        
        function [s] = setNewHoursBetweenSession(s)
            %draw from the dsitribution of possibleNumTrials

            index=min(find(rand<cumsum(s.probOfHoursBetweenSessions)));
            s.hoursBetweenSessions=s.possibleHoursBetweenSessions(index);
            %out=s.hoursBetweenSessions;
        end
        
        function [s] = setNewNumTrials(s)
            %draw from the dsitribution of possibleNumTrials

            index=min(find(rand<cumsum(s.probOfNumTrials)));
            s.numTrials=s.possibleNumTrials(index);
            %out=s.numTrials;

        end
        
    end
    
end


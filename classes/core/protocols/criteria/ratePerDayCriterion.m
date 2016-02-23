classdef ratePerDayCriterion<criterion

    properties
        trialsPerDay=0;
        consecutiveDays=0;
    end
    
    methods
        function s=ratePerDayCriterion(varargin)
            % RATEPERDAYCRITERION  class constructor.  
            % s=ratePerDayCriterion(trialsPerDay,consecutiveDays)

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'ratePerDayCriterion'))
                        s = varargin{1};
                    else
                        error('Input argument is not a ratePerDayCriterion object')
                    end
                case 2
                    if varargin{1}>=0 && varargin{2}>=0
                        s.trialsPerDay=varargin{1};
                        s.consecutiveDays=varargin{2};
                    else
                        error('trialsPerDay and consecutiveDays must be >= 0')
                    end
                    
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [graduate, details] = checkCriterion(c,subject,trainingStep,trialRecords, compiledRecords)

            %determine what type trialRecord are
            recordType='compiledData'; %circularBuffer

            thisStep=[trialRecords.trainingStepNum]==trialRecords(end).trainingStepNum;
            trialsUsed=trialRecords(thisStep);

            graduate=true;
            if ~isempty(trialRecords)
                %get the correct vector
                switch recordType
                    case 'largeData'
                        dates = floor(datenum(cell2mat({trialsUsed.date}'))); % the actual dates of each trials
                        stochastic = [trialsUsed.didStochasticResponse];
                        humanResponse = [trialsUsed.didHumanResponse];
                        forcedRewards = [trialsUsed.containedForcedRewards]==1;

                        goodDates = dates(~stochastic | ~humanResponse & ~forcedRewards);
                        daysRun = unique(dates);
                        for i = length(daysRun):-1:length(daysRun)-c.consecutiveDays+1
                            if i>0
                                graduate = graduate && sum(goodDates==daysRun(i))>=c.trialsPerDay;
                            end
                        end
                    case 'compiledData'
                        datesTR = floor(datenum(cell2mat({trialsUsed.date}'))); % the actual dates of each trials
                        trialNumTR = [trialsUsed.trialNumber];
                        stochasticTR = [trialsUsed.didStochasticResponse];
                        humanResponseTR = [trialsUsed.didHumanResponse];
                        forcedRewardsTR = [trialsUsed.containedForcedRewards]==1;

                        if ~isempty(compiledRecords)
                            whichCompiledTrials = compiledRecords.compiledTrialRecords.step == trialRecords(end).trainingStepNum;
                            trialNumCR = compiledRecords.compiledTrialRecords.trialNumber(whichCompiledTrials);
                            datesCR = floor(compiledRecords.compiledTrialRecords.date(whichCompiledTrials)); % the actual dates of each trials
                            stochasticCR = compiledRecords.compiledTrialRecords.didStochasticResponse(whichCompiledTrials);
                            humanResponseCR = compiledRecords.compiledTrialRecords.containedManualPokes(whichCompiledTrials);
                            forcedRewardsCR = compiledRecords.compiledTrialRecords.containedForcedRewards(whichCompiledTrials);

                            % remove trialsAlready in TR
                            whichAlreadyAvailableinTR = ismember(trialNumCR,intersect(trialNumCR,trialNumTR));
                            try
                                dates = [datesCR(~whichAlreadyAvailableinTR) makerow(datesTR)];
                            catch
                                sca;
                                keyboard
                            end
                            stochastic = [stochasticCR(~whichAlreadyAvailableinTR) stochasticTR];
                            humanResponse = [humanResponseCR(~whichAlreadyAvailableinTR) humanResponseTR];
                            forcedRewards = [forcedRewardsCR(~whichAlreadyAvailableinTR) forcedRewardsTR];
                        else
                            dates = [makerow(datesTR)];
                            stochastic = [stochasticTR];
                            humanResponse = [humanResponseTR];
                            forcedRewards = [forcedRewardsTR];
                        end
                        goodDates = dates(~stochastic & ~humanResponse & ~forcedRewards);
                        daysRun = unique(dates);
                        for i = length(daysRun):-1:length(daysRun)-c.consecutiveDays+1
                            if i>0
                                graduate = graduate && sum(goodDates==daysRun(i))>=c.trialsPerDay;
                            end
                        end
                    otherwise
                        error('unknown trialRecords type')
                end

            end


            %play graduation tone

            if graduate
                beep;
                pause(.2);
                beep;
                pause(.2);
                beep;
                pause(1);
                [junk, stepNum]=getProtocolAndStep(subject);
                for i=1:stepNum+1
                    beep;
                    pause(.4);
                end
                if (nargout > 1)
                    details.date = now;
                    details.criteria = c;
                    details.graduatedFrom = stepNum;
                    details.allowedGraduationTo = stepNum + 1;
                    details.trialsPerDay = c.trialsPerDay;
                end
            end
        end % end function
        
        function d=display(s)
            d=['rate criterion (trialsPerDay: ' num2str(s.trialsPerDay) ' consecutiveDays: ' num2str(s.consecutiveDays) ')'];
        end
        
        
    end
    
end


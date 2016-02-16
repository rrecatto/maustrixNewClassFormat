classdef adaptiveReinforcement

    properties
        rewardSizeULorMS=0;
        minReward = .01;
        maxPenalty = 25000;
        minPenalty = 1000;
        adaptationMethod = '';
        currentReward = 1;
        currentPenalty = 1000;
        lastChangedTrial = NaN;
        lastChangedDate = NaN;
        targetTrialRate = 50;    % past 7 working days
        targetPerformance = .99; % on previous 200 trials
        history = {};
    end
    
    methods
        function r=adaptiveReinforcement(varargin)
            % ||adaptiveReinforcement||  class constructor.
            % r=adaptiveReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,...
            %   msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff, minReward, minPenalty, maxPenalty, adaptationMethod)
            switch nargin
                case 0
                    % if no input arguments, create a default object


                    r = class(r,'adaptiveReinforcement',reinforcementManager());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'adaptiveReinforcement'))
                        r = varargin{1};
                    else
                        error('Input argument is not a adaptiveReinforcement object')
                    end
                case 14
                    r = class(r,'adaptiveReinforcement',...
                        reinforcementManager(varargin{4},varargin{8},varargin{7},varargin{5},varargin{6},varargin{2},varargin{3}));
                    r = setRewardSizeULorMS(r,varargin{1});
                    r.minReward = varargin{9};
                    r.minPenalty = varargin{10};
                    r.maxPenalty = varargin{11};
                    r.adaptationMethod = varargin{12};
                    r.targetTrialRate = varargin{13};
                    r.targetPerformance = varargin{14};

                    if getMsPenalty(r) < r.minPenalty
                        error('Penalty too low, please set penalty lower than r.minPenalty');
                    elseif getMsPenalty(r) > r.maxPenalty
                        error('Penalty too high, please set penalty higher than r.maxPenalty');
                    end


                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        
        function [r, rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM] = ...
    calcReinforcement(r,trialRecords, compiledRecord, subject)


            %% check if scalar needs to be changed
            [r,updateRM] = updateReinforcementManagerIfNecessary(r,compiledRecord,trialRecords, subject);
            %% collect all the return values

            % ## CURRENT REWARD IS REPLACING r.scalar IN CURRENT SETUP OF CLASSES
            rewardSizeULorMS= r.currentReward*r.rewardSizeULorMS;
            requestRewardSizeULorMS = getRequestRewardSizeULorMS(r);

            % ## CURRENT PENALTY IS REPLACING r.msPenalty IN CURRENT SETUP
            msPenalty=getMsPenalty(r);
            r.currentPenalty = msPenalty;
            msPuff=getMsPuff(r);
            msRewardSound=rewardSizeULorMS*getFractionOpenTimeSoundIsOn(r);
            msPenaltySound=r.currentPenalty*getFractionPenaltySoundIsOn(r);

            if updateRM
                r = setScalar(r,r.currentReward);
            %     r = setRewardSizeULorMS(r,rewardSizeULorMS);
                r = setRequestRewardSizeULorMS(r,requestRewardSizeULorMS); % to make consistent with other reinfMgrs

                r = setMsPenalty(r,msPenalty);
            end


            % % rewardSizeULorMS= getScalar(r)*r.rewardSizeULorMS;
            % % requestRewardSizeULorMS = getScalar(r)* getRequestRewardSizeULorMS(r);
            % % msPenalty=getMsPenalty(r);
            % % msPenaltySound=getMsPenalty(r)*getFractionPenaltySoundIsOn(r);



        end
        
        function out=getCurrentPenalty(r)
            out=r.currentPenalty;
        end
        
        function out=getCurrentReward(r)
            out=r.currentReward;
        end
        
        function out=getLastChangedTrial(r)
            out=r.lastChangedTrial;
        end
        
        function [pctCorrect, trialRate,rm] = getPercentageAndTrialsFromRecords(rm,trialRecords, compiledRecords)

            % pctcorrect is the % correct over previous 200 trials. Need to ensure that
            % the adaptationMethod.checkEvery(in trials) is >200

            % trialRate is numTrials/day over the last 7 days

            %% calcualte pctCorrect
            fieldNames = fields(trialRecords);

            forcedRewards = 0;
            stochastic = 0;
            humanResponse = 0;

            warnStatus = false;

            trialsInTR = [trialRecords.trialNumber];
            if ~isempty(compiledRecords)
                trialsFromCR = compiledRecords.compiledTrialRecords.trialNumber;
                trialsFromCRToBeIncluded = ~ismember(trialsFromCR,trialsInTR);
                allStepNums = [compiledRecords.compiledTrialRecords.step(trialsFromCRToBeIncluded) trialRecords.trainingStepNum];
            else
                trialsFromCRToBeIncluded = [];
                allStepNums = [trialRecords.trainingStepNum];
            end

            td(length(trialRecords)).correct = nan;
            for tnum = 1:length(trialRecords)
                if isfield(trialRecords(tnum),'trialDetails') && ~isempty(trialRecords(tnum).trialDetails) ...
                        && ~isempty(trialRecords(tnum).trialDetails.correct)
                    td(tnum).correct = trialRecords(tnum).trialDetails.correct;
                else
                    td(tnum).correct = nan;
                end
            end

            if ~isempty(compiledRecords)
                allCorrects = [compiledRecords.compiledTrialRecords.correct(trialsFromCRToBeIncluded) td.correct];
            else
                allCorrects = [td.correct];
            end

            if ismember({'containedForcedRewards'},fieldNames)
                ind = find(cellfun(@isempty,{trialRecords.containedForcedRewards}));
                if ~isempty(ind)
                    warning('using pessimistic values for containedForcedRewards');
                    for i=1:length(ind)
                        trialRecords(ind(i)).containedForcedRewards = 1;
                    end
                end
                forcedRewards = [trialRecords.containedForcedRewards]==1;
            else 
                warnStatus = true;
            end

            if ~isempty(compiledRecords)
                allForcedRewards = [compiledRecords.compiledTrialRecords.containedForcedRewards(trialsFromCRToBeIncluded) forcedRewards];
            else
                allForcedRewards = [forcedRewards];
            end

            if ismember({'didStochasticResponse'},fieldNames)
                ind = find(cellfun(@isempty,{trialRecords.didStochasticResponse}));
                if ~isempty(ind)
                    warning('using pessimistic values for didStochasticResponse');
                    for i=1:length(ind)
                        trialRecords(ind(i)).didStochasticResponse = 1;
                    end
                end
                stochastic = [trialRecords.didStochasticResponse];
            else 
                warnStatus = true;
            end

            if ~isempty(compiledRecords)
                allStochastic = [compiledRecords.compiledTrialRecords.didStochasticResponse(trialsFromCRToBeIncluded) stochastic];
            else
                allStochastic = [stochastic];
            end

            if ismember({'didHumanResponse'},fieldNames)
                ind = find(cellfun(@isempty,{trialRecords.didHumanResponse}));
                if ~isempty(ind)
                    warning('using pessimistic values for didHumanResponse');
                    for i=1:length(ind)
                        trialRecords(ind(i)).didHumanResponse = 1;
                    end
                end
                humanResponse = [trialRecords.didHumanResponse];
            else 
                warnStatus = true;
            end

            if ~isempty(compiledRecords)
                allHumanResponse = [compiledRecords.compiledTrialRecords.didHumanResponse(trialsFromCRToBeIncluded) humanResponse];
            else
                allHumanResponse = [humanResponse];
            end

            if warnStatus
                warning(['checkCriterion found trialRecords of the older format. some necessary fields are missing. ensure presence of ' ...
                '''containedForcedRewards'',''didStochasticResponse'' and ''didHumanResponse'' in trialRecords to remove this warning']);
            end

            % get the last N trials
            try
            allCorrects = allCorrects(end-199:end);
            allForcedRewards = allForcedRewards(end-199:end);
            allStochastic = allStochastic(end-199:end);
            allHumanResponse = allHumanResponse(end-199:end);

            catch
                allCorrects = ones(1,200);
                allForcedRewards = zeros(1,200);
                allStochastic = zeros(1,200);
                allHumanResponse = zeros(1,200);
            end

            % remove the "bad trials"
            allCorrects = allCorrects(~allStochastic & ~allHumanResponse & ~allForcedRewards & ~isnan(allCorrects));

            pctCorrect = sum(allCorrects)/length(allCorrects);


            %% calcualte Trialrate

            % delete repeats
            td(length(trialRecords)).date = nan;
            for tnum = 1:length(trialRecords)
                if isfield(trialRecords(tnum),'date') && ~isempty(trialRecords(tnum).date)
                    td(tnum).date = floor(datenum(trialRecords(tnum).date));
                else
                    td(tnum).date = nan;
                end
            end

            if ~isempty(compiledRecords)
                allDates = [compiledRecords.compiledTrialRecords.date(trialsFromCRToBeIncluded) td.date];
            else
                allDates = [td.date];
            end


            % get last 7 days mod(now,7) == 1 is saturday, mod(now,7) == 2 is sunday.
            %start with today
            lastSevenDays = length(allDates(find(floor(allDates)==floor(allDates(end)))));
            dayToExtract = floor(allDates(end));
            for i = 1:6
                %update day
                dayToExtract = dayToExtract - 1;

                %skip saturday/sunday
                if mod(dayToExtract,7) == 2
                    dayToExtract = dayToExtract - 2;
                end

                %add trial number to liste
                daysValue = length(allDates(find(floor(allDates)==dayToExtract)));
                lastSevenDays = [lastSevenDays daysValue];
            end

            trialRate = mean(lastSevenDays);


        end
        
        function out=getRewardSizeULorMS(r)
            out=r.rewardSizeULorMS;
        end
        
        
        function r=setRewardSizeULorMS(r, v)
            if v>=0 && isreal(v) && isscalar(v) && isnumeric(v)
                r.rewardSizeULorMS=v;
            else
                error('rewardSizeULorMS must be real numeric scalar >=0')
            end
        end
        
        
        function r = updateHistoryAndValues(r, flag, lastUpdateDate, lastUpdateTrial, currentTrial, pctCorrect, trialRate, subject)
            %updates values and history based off of passed in flag
            %
            %creates history in form: history = [ subjectID, lastChangedDate, lastChangedTrial, currentDate, currentTrial, lastPenalty, ...
            %                                    lastRewardScalar, newPenalty, newRewardScalar, pctCorrect, trialRate, comments]

            %built depending on how flag is set
            comments = [];

            switch flag
                case 1 %trialRate NOT met and pctCorrect NOT met then email
                    % if the animal does not meet trialRate and pctCorrect requirements
                    % AND is the requestReward is zero, then turn it up. Else send
                    % message!
                    switch upper(r.adaptationMethod.type)
                        case 'STAIRCASE'
                            reqReward = getRequestRewardSizeULorMS(r);
                            if reqReward>0
                                comments = ['Problem with subject ', num2str(getID(subject)), '! TrialRate (', num2str(trialRate), ') and pctCorrect (', ...
                                    num2str(pctCorrect), ') not up to par. Maybe consider moving back a level? Leaving penalty/reward as is for now.'];
                                gmail('sbalaji1984@gmail.com','NOTICE: from adaptiveReinforcement',comments);
                                newPenalty = r.currentPenalty; %penalty/reward unaffected
                                newReward = r.currentReward;
                            else
                                comments = ['Trying to increase trial rate first by increasing the request reward'];
                                r = setRequestRewardSizeULorMS(r,10);
                                newPenalty = r.currentPenalty; %penalty/reward unaffected
                                newReward = r.currentReward;
                            end
                        otherwise
                            error('adaptationMethod.type not recognized');
                    end


                case 2 %trialRate NOT met pctCorrect IS met then lower reward length to encourage more trials
                    switch upper(r.adaptationMethod.type)
                        case 'STAIRCASE'
                            comments = ['Trial rate NOT met but pctCorrect IS met, lowering reward to encourage more trials. '];
                            newReward = r.currentReward - r.adaptationMethod.stepSizeScalar;
                            if newReward < r.minReward %if drops below min
                                comments = [comments, num2str(newReward), ' is less than minimum allowed reward. Setting '...
                                    'new reward to ', num2str(r.minReward), ' (r.minReward).'];
                                newReward = r.minReward;
                            else
                                %nothing new to report
                            end

                        otherwise
                            error('adaptationMethod.type not recognized');
                    end

                    newPenalty = r.currentPenalty; %penalty unaffected


                case 3 %trialRate IS met but pctCorrect NOT met then increase timeout time to encourage better decision making
                    switch upper(r.adaptationMethod.type)
                        case 'STAIRCASE'
                            reqReward = getRequestRewardSizeULorMS(r);
                            if reqReward>0
                                % incase trialRate is met, then set the request reward
                                % to 0!
                                r = setRequestRewardSizeULorMS(r,0);
                                comments = ['Trial rate IS met - setting request reward to 0'];
                                newPenalty = r.currentPenalty;
                            else
                                comments = ['Trial rate IS met but pctCorrect NOT met, increasing timeout to encourage better decision making '];
                                newPenalty = r.currentPenalty + r.adaptationMethod.stepSizePenalty;
                                if newPenalty > r.maxPenalty
                                    comments = [comments, num2str(newPenalty), ' is greater than maximum allowed penalty. Setting '...
                                        'new penalty to ', num2str(r.minReward), ' (r.maxPenalty).'];
                                    newPenalty= r.maxPenalty;
                                else
                                    %nothing new to report
                                end
                            end
                        otherwise
                            error('adaptationMethod.type not recognized');
                    end

                    newReward = r.currentReward; %reward unaffected.

                case 4 %trialRate IS met and pctCorrect IS met then lower timeout to get more trials in
                    switch upper(r.adaptationMethod.type)
                        case 'STAIRCASE'
                            comments = ['Trial rate IS met and pctCorrect IS met, decreasing timeout to get in more trials. '];
                            newPenalty = r.currentPenalty - r.adaptationMethod.stepSizePenalty;
                            if newPenalty < r.minPenalty
                                comments = [comments, num2str(newPenalty), ' is less than minimum allowed penalty. Setting '...
                                    'new penalty to ', num2str(r.minReward), ' (r.minPenalty).'];
                                newPenalty= r.minPenalty;
                            else
                                %nothing new to report
                            end
                        otherwise
                            error('adaptationMethod.type not recognized');
                    end

                    newReward = r.currentReward; %reward unaffected.

                otherwise
                    error('flag set incorrectly');
            end

            % update all values in reinforcement manager before returning
            history = [getID(subject),',', num2str(lastUpdateDate),',', num2str(lastUpdateTrial),',', num2str(floor(now)),',', num2str(currentTrial),',', num2str(r.currentPenalty),',', ...
                num2str(r.currentReward),',', num2str(newPenalty),',', num2str(newReward),',', num2str(pctCorrect),',',num2str(trialRate),',COMMENTS:', comments];

            r.currentReward = newReward;
            r.currentPenalty = newPenalty;
            r.history = {r.history; history};
        end
        
        function r = updateHistoryFirstTime(r, currentTrial, subject)


            %creates history in form: history = [subjectID, lastChangedDate, lastChangedTrial, currentDate, currentTrial, lastPenalty, ... 
            %                                    lastRewardScalar, newPenalty, newRewardScalar, pctCorrect, trialRate, comments]

            comments = 'First run, no update needed, using default values';

            history = [getID(subject),',', 'NaN,', 'NaN,', num2str(floor(now)),',', num2str(currentTrial),',', num2str(r.currentPenalty),',', num2str(r.currentReward),',', ...
                       num2str(r.currentPenalty),',', num2str(r.currentReward), ',NaN,', 'NaN,COMMENTS:', comments];

            % since first time, can just set history to this single element
            r.history = history;
        end
        
        function [r,updateRM] = updateReinforcementManagerIfNecessary(r,compiledRecord,trialRecords, subject)

            firstUpdate = false;
            updateRM = 0;

            %store these to add to history later.
            lastUpdateDate = r.lastChangedDate;
            lastUpdateTrial = r.lastChangedTrial;

            switch upper(r.adaptationMethod.checkEveryType)
                case 'TRIALS'
                    if isnan(r.lastChangedTrial)
                        firstUpdate = true;

                        r.lastChangedTrial = trialRecords(length(trialRecords)).trialNumber;
                        r.lastChangedDate = floor(now);

                        updateRM = 1;
                    elseif r.lastChangedTrial + r.adaptationMethod.frequency <= trialRecords(length(trialRecords)).trialNumber
                        r.lastChangedTrial = trialRecords(length(trialRecords)).trialNumber;
                        r.lastChangedDate = floor(now);

                        updateRM = 1;
                    else
                        updateRM = 0;
                    end

                case 'DAYS'
                    if isnan(r.lastChangedDate)
                        firstUpdate = true;

                        r.lastChangedTrial = trialRecords(length(trialRecords)).trialNumber;
                        r.lastChangedDate = floor(now);

                        updateRM = 1;
                    elseif r.lastChangedDate + r.adaptationMethod.frequency <= floor(now)
                        r.lastChangedTrial = trialRecords(length(trialRecords)).trialNumber;
                        r.lastChangedDate = floor(now);

                        updateRM = 1;
                    else
                        updateRM = 0;
                    end      
                otherwise
                    error('adaptationMethod.checkEveryType not recognized');
            end

            % if first update, reflect that in history and return default values
            if firstUpdate
                r = updateHistoryFirstTime(r,trialRecords(length(trialRecords)).trialNumber, subject);
                return
            end

            [pctCorrect, trialRate,r] = getPercentageAndTrialsFromRecords(r,trialRecords, compiledRecord);
            % if just updateRM then changes may need to be made to reward or penalty values
            if updateRM
                %if trialRate NOT met and pctCorrect NOT met then email
                if trialRate < r.targetTrialRate && pctCorrect < r.targetPerformance
                    flag = 1;
                %elseif JUST trialRate NOT met then lower reward length to encourage more trials
                elseif trialRate < r.targetTrialRate
                    flag = 2;
                end
                %if trialRate IS met but pctCorrect NOT met then increase timeout time to encourage better decision making
                if trialRate >= r.targetTrialRate && pctCorrect < r.targetPerformance
                    flag = 3;
                %elseif trialRate IS met and pctCorrect IS met then lower timeout to get more trials in
                elseif trialRate >= r.targetTrialRate
                    flag = 4;
                end

                r = updateHistoryAndValues(r, flag, lastUpdateDate, lastUpdateTrial, trialRecords(length(trialRecords)).trialNumber, pctCorrect, trialRate, subject);
            end


        end

        
        
    end
    
end


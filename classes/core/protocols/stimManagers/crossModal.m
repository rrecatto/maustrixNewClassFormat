classdef crossModal<stimManager
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Determine how to switch between sets (~200? or per day?) of trials
        % Whether we are currently in the initially blocked trials
        isBlocking = false;
        % trialNum - What trial number we are currently on for the current modality
        trialNum = [];
        % currentModality - Which modality is currently active [ 0 - hemifield; 1 - stereoDiscrim ]
        currentModality = [];
        % blockingLength - How long blocking is done for
        blockingLength = [];
        % Determine how often the modality should switch
        modalitySwitchType = []; % 'Never' 'ByNumberOfTrials' 'ByNumberOfHoursRun' 'ByNumberOfDaysWorked'
        modalitySwitchParameter = []; %  []      200                2                    1
        modalitySwitchMethod = []; % 'Alternating' 'Random'
        modalityTimeStarted = [];
        audioStimulus = []; % Where to store the calculated audioStimulus
        % Hold the underlying component stim managers
        hemifieldFlicker = [];
        stereoDiscrim = [];
    end
    
    methods
        function s=crossModal(varargin)
            % Cross Modal class constructor.
            % s =
            % crossModal(switchType,switchParameter,switchMethod,blockingLength,currentModality,[pixPerCycs],[targetContrasts],[distractorContrasts],fieldWidthPct,fieldHeightPct,mean,stddev,thresh,flickerType,yPositionPercent,soundFreq,[soundChannelAmplitudes],maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            % hemifieldFlicker([pixPerCycs],[targetContrasts],[distractorContrasts],fieldWidthPct,fieldHeightPct,mean,stddev,thresh,flickerType,yPositionPercent,maxWidth,maxHeight,scaleFactor,interTrialLuminance) 
            % mean, contrasts, yPositionPercent normalized (0 <= value <= 1)
            % stereoDiscrim(mean,freq,[amplitudes],maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            %
            % E.G. 
            %
            % switchType              = 'ByNumberOfTrials';
            % switchParameter         = 220;
            % switchMethod            = 'Random';
            % blockingLength          = 20;
            % currentModality         = []; % Default
            % pixPerCycs              =[20];
            % targetContrasts         =[0.8];
            % distractorContrasts     =[];
            % fieldWidthPct           = 0.2;
            % fieldHeightPct          = 0.2;
            % mean                    =.5;
            % stddev                  =.04; % Only used for Gaussian Flicker
            % thresh                  =.00005;
            % flickerType             =0; % 0 - Binary Flicker; 1 - Gaussian Flicker
            % yPosPct                 =.65;
            % maxWidth                =800;
            % maxHeight               =600;
            % scaleFactor             =[1 1];
            % interTrialLuminance     =.5;
            % soundFreq               = 200;
            % soundAmp                = [0 0.5];
            % s=crossModal(switchType,switchParameter,switchMethod,blockingLength,currentModality,pixPerCycs,targetContrasts,distractorContrasts,fieldWidthPct,fieldHeightPct,mean,stddev,thresh,flickerType,yPosPct,soundFreq,soundAmp,maxWidth,maxHeight,scaleFactor,interTrialLuminance);
            %

            switch nargin
            case 0 
            % if no input arguments, create a default object
                s.hemifieldFlicker = hemifieldFlicker();
                s.stereoDiscrim = stereoDiscrim();
                
            case 1
            % if single argument of this class type, return it
                if (isa(varargin{1},'crossModal'))
                    s = varargin{1}; 
                else
                    error('Input argument is not a crossModal object')
                end
            case 21
                % number of blocking trials initially .... might be stochastic?
                % 
                % create object using specified values
                s.modalitySwitchType = varargin{1}; % How often the modality switches
                s.modalitySwitchParameter = varargin{2}; % Parameter for the Switch Type
                s.modalitySwitchMethod = varargin{3}; % Whether the switch should be random, or if it should alternate
                s.blockingLength = varargin{4}; % How many trials to block initially
                s.currentModality = varargin{5}; % What modality should be relevant when initialized (empty if randomly assigned)

                i = 6; % Index where arguments for the component stim managers start
                s.hemifieldFlicker = hemifieldFlicker(varargin{i},varargin{i+1},varargin{i+2},varargin{i+3},varargin{i+4},varargin{i+5},varargin{i+6},...
                    varargin{i+7},varargin{i+8},varargin{i+9},varargin{i+12},varargin{i+13},varargin{i+14},varargin{i+15});
                s.stereoDiscrim = stereoDiscrim(varargin{i+5},varargin{i+10},varargin{i+11},varargin{i+12},varargin{i+13},varargin{i+14},varargin{i+15});
                

            otherwise
                error('Wrong number of input arguments')
            end
        end
        
        function analysis(sm,detailRecords,subjectID)
            if all(detailRecords.HFdetailsPctCorrectionTrials==.5) && all(detailRecords.SDdetailsPctCorrectionTrials==.5) && all(strcmp(detailRecords.modalitySwitchMethod,'Random')) && all(strcmp(detailRecords.modalitySwitchType,'ByNumberOfHoursRun'))
                %pass
            else
                unique(detailRecords.HFdetailsPctCorrectionTrials) 
                unique(detailRecords.SDdetailsPctCorrectionTrials) 
                unique(detailRecords.modalitySwitchMethod)
                unique(detailRecords.modalitySwitchType)
                warning('standard crossModal config violated')
            end

            options=cellfun(@union,detailRecords.targetPorts,detailRecords.distractorPorts,'UniformOutput',false);

            goods=detailRecords.isCorrection==0 ...
                & cellfun(@ismember,num2cell(detailRecords.response),options) ...
                & ~detailRecords.containedManualPokes ...
                & ~detailRecords.didHumanResponse ...
                & ~detailRecords.containedForcedRewards ...
                & ~detailRecords.didStochasticResponse;

            %any time isBlocking or currentModality changes state, increment session number.  also when trial is more than an hour since previous trial.
            sessionNum=cumsum([1    sign(    double((24*diff(detailRecords.date))>1)    +   abs(diff(detailRecords.isBlocking))   +   abs(diff(detailRecords.currentModality))   )   ]);

            agrees=detailRecords.HFtargetPorts==detailRecords.SDtargetPorts;
            conflicts=detailRecords.HFtargetPorts~=detailRecords.SDtargetPorts;
            if any(agrees & conflicts) || any(~agrees & ~conflicts)
                error('can''t agree and conflict or do neither')
            end

            alpha=.05;

            visual.agree.perf.phat=[];
            visual.agree.perf.pci=[];
            visual.agree.bias.phat=[];
            visual.agree.bias.pci=[];
            visual.conflict.perf.phat=[];
            visual.conflict.perf.pci=[];
            visual.conflict.bias.phat=[];
            visual.conflict.bias.pci=[];
            visual.alone.perf.phat=[];
            visual.alone.perf.pci=[];
            visual.alone.bias.phat=[];
            visual.alone.bias.pci=[];

            visual.sessions.crossModal=[];
            visual.sessions.alone=[];

            audio=visual;

            trialsIncluded=0;
            minTrials=25; %if higher than blockingLength, will miss alones
            for i=1:max(sessionNum)
                trials=sessionNum==i & goods;

                if sum(trials)>=minTrials
                    trialsIncluded=trialsIncluded+sum(trials);

                    isBlocking=unique(detailRecords.isBlocking(trials));
                    modality=unique(detailRecords.currentModality(trials));

                    if length(isBlocking) == 1 && length(modality) == 1
                        switch modality
                            case 0
                                type=visual;
                            case 1
                                type=audio;
                            otherwise
                                error('bad modality')
                        end

                        if ~isBlocking
                            totalAgrees=sum(trials & agrees);
                            correctAgrees=sum(trials & agrees & detailRecords.correct);
                            responseRightAgrees=sum(trials & agrees & detailRecords.response==3);

                            totalConflicts=sum(trials & conflicts);
                            correctConflicts=sum(trials & conflicts & detailRecords.correct);
                            responseRightConflicts=sum(trials & conflicts & detailRecords.response==3);

                            [phat pci]=binofit([correctAgrees responseRightAgrees correctConflicts responseRightConflicts],[totalAgrees totalAgrees totalConflicts totalConflicts],alpha);
                        else
                            totalAlones=sum(trials);
                            correctAlones=sum(trials & detailRecords.correct);
                            responseRightAlones=sum(trials & detailRecords.response==3);
                            [phat pci]=binofit([correctAlones responseRightAlones],[totalAlones totalAlones],alpha);
                        end

                        if all(pci(:,1)<pci(:,2))
                            if ~isBlocking
                                ind=1;
                                type.agree.perf.phat(end+1)=phat(ind);
                                type.agree.perf.pci(end+1,:)=pci(ind,:);

                                ind=2;
                                type.agree.bias.phat(end+1)=phat(ind);
                                type.agree.bias.pci(end+1,:)=pci(ind,:);

                                ind=3;
                                type.conflict.perf.phat(end+1)=phat(ind);
                                type.conflict.perf.pci(end+1,:)=pci(ind,:);

                                ind=4;
                                type.conflict.bias.phat(end+1)=phat(ind);
                                type.conflict.bias.pci(end+1,:)=pci(ind,:);

                                type.sessions.crossModal(end+1)=i;
                            else
                                ind=1;
                                type.alone.perf.phat(end+1)=phat(ind);
                                type.alone.perf.pci(end+1,:)=pci(ind,:);

                                ind=2;
                                type.alone.bias.phat(end+1)=phat(ind);
                                type.alone.bias.pci(end+1,:)=pci(ind,:);

                                type.sessions.alone(end+1)=i;
                            end
                        else
                            error('pci''s came back descending')
                        end

                        switch modality
                            case 0
                                visual=type;
                            case 1
                                audio=type;
                            otherwise
                                error('bad modality')
                        end
                    else
                        error('found isBlocking or currentModality changing state during session')
                    end
                else
                    fprintf('skipping a %d session\n',sum(trials))
                end
            end
            fprintf('included %d clumped of %d good trials (%g%%)\n',trialsIncluded,sum(goods),round(100*trialsIncluded/sum(goods)));

            figure('Name',sprintf('%s: crossModal performance and bias',subjectID))
            c={'r' 'k'};
            subplot(3,2,1)
            makePerfBiasPlot(visual.sessions.alone,visual.alone,c);
            title('visual')
            ylabel('alone')

            subplot(3,2,2)
            makePerfBiasPlot(audio.sessions.alone,audio.alone,c);
            title('audio')

            subplot(3,2,3)
            makePerfBiasPlot(visual.sessions.crossModal,visual.agree,c);
            ylabel('agree')

            subplot(3,2,4)
            makePerfBiasPlot(audio.sessions.crossModal,audio.agree,c);

            subplot(3,2,5)
            makePerfBiasPlot(visual.sessions.crossModal,visual.conflict,c);
            ylabel('conflict')
            xlabel('session')

            subplot(3,2,6)
            makePerfBiasPlot(audio.sessions.crossModal,audio.conflict,c);
            xlabel('session')
            pth='C:\Documents and Settings\rlab\Desktop\detailedRecords';
            saveas(gcf,fullfile(pth,[subjectID '_crossModal']),'png');

            doParams=false;
            if doParams
                figure('Name',sprintf('%s: crossModal params',subjectID))
                subplot(6,1,1)
                plot(detailRecords.HFdetailsContrasts(:,goods)');
                title('HF Contrasts')

                subplot(6,1,2)
                plot(detailRecords.HFdetailsXPosPcts(:,goods)');
                title('HF X Pos')

                subplot(6,1,3)
                plot([detailRecords.SDdetailsLeftAmplitude(goods)' detailRecords.SDdetailsRightAmplitude(goods)']);
                title('SD amps')

                subplot(6,1,4)
                plot(detailRecords.blockingLength(goods));
                title('blocking length')

                subplot(6,1,5)
                plot(detailRecords.currentModalityTrialNum(goods));
                title('modality (0=HF(visual); 1=SD(auditory))')

                subplot(6,1,6)
                days=floor(detailRecords.date(goods));
                days=days-min(days);
                plot(days);
                title('day')
            end
        end
        
        function [stimulus updateSM resInd preRequestStim preResponseStim discrimStim LUT targetPorts distractorPorts ...
    details interTrialLuminance text indexPulses imagingTasks] = ...
    calcStim(stimulus,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % 1/3/0/09 - trialRecords now includes THIS trial
            indexPulses=[];
            imagingTasks=[];
            updateSM = true; % This is always true, because the audio stimulus is always set

            % Determine if the modality should switch
            if isempty(stimulus.currentModality)
                needToSwitch = true; % Have to choose something
            else
                needToSwitch = false;
                switch stimulus.modalitySwitchType
                    case 'Never'
                        %
                    case 'ByNumberOfTrials'
                        if stimulus.trialNum > stimulus.modalitySwitchParameter
                            needToSwitch = true;
                        end   
                    case 'ByNumberOfHoursRun'
                        timeDiff = now - stimulus.modalityTimeStarted;
                        timeDiffMax = datenum([ 0 0 0 stimulus.modalitySwitchParameter 0 0]);
                        if timeDiff > timeDiffMax
                            needToSwitch = true;
                        end
                    case 'ByNumberOfDaysWorked'
                        timeDiff = now - stimulus.modalityTimeStarted;
                        if timeDiff > stimulus.modalitySwitchParameter
                            needToSwitch = true;
                        end
                    otherwise
                        error('Unknown/unsupported modality switch type')
                end
            end

            % If need to switch modalities, set start time and select the new current
            % modality
            if needToSwitch
                stimulus.modalityTimeStarted = now;
                stimulus.trialNum = 1;
                if isempty(stimulus.currentModality) || strcmp(stimulus.modalitySwitchMethod,'Random') == 0  %edf: this looks like a bug -- why testing against zero?  expect 'Random' to alternate each day...
                    stimulus.currentModality = round(rand());
                else
                    stimulus.currentModality = setDiff([0 1],stimulus.currentModality);
                end
            end

            % Determine if blocking is still going on
            if stimulus.trialNum > stimulus.blockingLength 
                stimulus.isBlocking = false;
            else
                stimulus.isBlocking = true;
            end

            [stimulus.hemifieldFlicker HFupdateSM HFresInd HFout HFLUT HFscaleFactor HFtype HFtargetPorts HFdistractorPorts HFdetails HFinterTrialLuminance text] = ...
                calcStim(stimulus.hemifieldFlicker,trialManagerClass,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords);

            [stimulus.stereoDiscrim SDupdateSM SDresInd SDout SDLUT SDscaleFactor SDtype SDtargetPorts SDdistractorPorts SDdetails SDinterTrialLuminance text] = ...
                calcStim(stimulus,trialManagerClass,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords);

            % Update the stim manager if either of the component stim managers needed
            % updating
            updateSM = HFupdateSM || SDupdateSM || updateSM;

            % If stimulus is blocking, then block the appropriate stimulus
            if stimulus.isBlocking 
                if stimulus.currentModality == 0
                    % Visual modality, block sound
                    out = HFout;
                    LUT = HFLUT;
                    resInd = HFresInd;
                    scaleFactor = HFscaleFactor;
                    type = HFtype;
                    stimulus.audioStimulus = [];
                else
                    % Sound modality, block vision
                    out = SDout;
                    LUT = SDLUT;
                    resInd = SDresInd;
                    scaleFactor = SDscaleFactor;
                    type = SDtype;
                    stimulus.audioStimulus = getAudioStimulus(stimulus.stereoDiscrim);
                end
            else
                % When not blocking trials, the hemifield is always displayed
                %  and the audio stimulus always comes from stereoDiscrim
                out = HFout;
                LUT = HFLUT;
                scaleFactor = HFscaleFactor;
                type = HFtype;
                stimulus.audioStimulus = getAudioStimulus(stimulus.stereoDiscrim);
            end

            % The correct answer is dependent on which modality is selected
            if stimulus.currentModality == 0
                % Visual modality is relevant
                targetPorts = HFtargetPorts;
                distractorPorts = HFdistractorPorts;
                interTrialLuminance = HFinterTrialLuminance;
                details.correctionTrial = HFdetails.correctionTrial;
            else
                % Sound modality is relevant
                targetPorts = SDtargetPorts;
                distractorPorts = SDdistractorPorts;
                interTrialLuminance = SDinterTrialLuminance;
                details.correctionTrial = SDdetails.correctionTrial;
            end

            details.HFdetails = HFdetails;
            details.SDdetails = SDdetails;
            details.HFtargetPorts = HFtargetPorts;
            details.SDtargetPorts = SDtargetPorts;
            details.HFdistractorPorts = HFdistractorPorts;
            details.SDdistractorPorts = SDdistractorPorts;
            details.HFcorrectionTrial = HFdetails.correctionTrial;
            details.SDcorrectionTrial = SDdetails.correctionTrial;
            details.currentModality = stimulus.currentModality;
            details.blockingLength = stimulus.blockingLength;
            details.isBlocking = stimulus.isBlocking;
            details.currentModalityTrialNum = stimulus.trialNum; % How many trials were run on this modality so far
            details.modalitySwitchMethod = stimulus.modalitySwitchMethod;
            details.modalitySwitchType = stimulus.modalitySwitchType;

            discrimStim=[];
            discrimStim.stimulus=out;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];

            preRequestStim=[];
            preRequestStim.stimulus=interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;

            preResponseStim=discrimStim;
            preResponseStim.punishResponses=false;

            % Increment trial num
            stimulus.trialNum = stimulus.trialNum+1;

        end

        function d=display(s)
            d=['crossModal (switchType: ' s.modalitySwitchType '\n' ...
                '(switchTypeParameter: ' num2str(s.modalitySwitchParameter) '\n' ...
                '(switchMethod: ' s.modalitySwitchMethod '\n' ...
                '(blockingLength: ' num2str(s.blockingLength) '\n' ...
                '(currentModality: ' s.currentModality '\n' ...
                '\n\nSUBCOMPONENT STIM: ' display(s.hemifieldFlicker) ...
                '\n\nSUBCOMPONENT STIM: ' display(s.stereoDiscrim) '\n\n'];
            d=sprintf(d);
        end
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)

            %ok, trialRecords could just be the stimDetails, determined by this class's
            %calcStim.  but you might want to do some processing that is sensitive to
            %the combination of stimDetails and trialRecord values outside of stimDetails.

            %basicRecords is most things outside of stimDetails (already processed into our format), but trialRecords is more complete

            % 1/20/09 - replaced all extractions with extractFieldAndEnsure (will populate with nans instead of erroring)
            if ~all(strcmp({trialRecords.trialManagerClass},'nAFC'))
                error('only works for nAFC trial manager')
            end

            newLUT=LUTparams.compiledLUT;

            try
                stimDetails=[trialRecords.stimDetails];
                temp=[stimDetails.HFdetails];    
                [out.HFdetailsPctCorrectionTrials newLUT] = extractFieldAndEnsure(temp,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.HFdetailsCorrectionTrial newLUT] = extractFieldAndEnsure(temp,{'correctionTrial'},'scalar',newLUT);
                [out.HFdetailsContrasts newLUT] = extractFieldAndEnsure(temp,{'contrasts'},'equalLengthVects',newLUT);
                [out.HFdetailsXPosPcts newLUT] = extractFieldAndEnsure(temp,{'xPosPcts'},'equalLengthVects',newLUT);
            %     out.HFdetailsPctCorrectionTrials=ensureScalar({temp.pctCorrectionTrials});
            %     out.HFdetailsCorrectionTrial=ensureScalar({temp.correctionTrial});
            %     out.HFdetailsContrasts=ensureEqualLengthVects({temp.contrasts});
            %     out.HFdetailsXPosPcts=ensureEqualLengthVects({temp.xPosPcts});

                temp=[stimDetails.SDdetails];
                [out.SDdetailsPctCorrectionTrials newLUT] = extractFieldAndEnsure(temp,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.SDdetailsCorrectionTrial newLUT] = extractFieldAndEnsure(temp,{'correctionTrial'},'scalar',newLUT);
                [out.SDdetailsContrasts newLUT] = extractFieldAndEnsure(temp,{'contrasts'},'equalLengthVects',newLUT);
                [out.SDdetailsXPosPcts newLUT] = extractFieldAndEnsure(temp,{'xPosPcts'},'equalLengthVects',newLUT);
            %     out.SDdetailsPctCorrectionTrials=ensureScalar({temp.pctCorrectionTrials});
            %     out.SDdetailsCorrectionTrial=ensureScalar({temp.correctionTrial});
            %     out.SDdetailsLeftAmplitude=ensureScalar({temp.leftAmplitude});
            %     out.SDdetailsRightAmplitude=ensureScalar({temp.rightAmplitude});

                [out.HFtargetPorts newLUT] = extractFieldAndEnsure(stimDetails,{'HFtargetPorts'},'scalar',newLUT);
                [out.SDtargetPorts newLUT] = extractFieldAndEnsure(stimDetails,{'SDtargetPorts'},'scalar',newLUT);
                [out.HFdistractorPorts newLUT] = extractFieldAndEnsure(stimDetails,{'HFdistractorPorts'},'scalar',newLUT);
                [out.SDdistractorPorts newLUT] = extractFieldAndEnsure(stimDetails,{'SDdistractorPorts'},'scalar',newLUT);
            %     out.HFtargetPorts=ensureScalar({stimDetails.HFtargetPorts});
            %     out.SDtargetPorts=ensureScalar({stimDetails.SDtargetPorts});
            %     out.HFdistractorPorts=ensureScalar({stimDetails.HFdistractorPorts});
            %     out.SDdistractorPorts=ensureScalar({stimDetails.SDdistractorPorts});

                checkTargets(sm.hemifieldFlicker,out.HFdetailsXPosPcts,out.HFdetailsContrasts,num2cell(out.HFtargetPorts),num2cell(out.HFdistractorPorts),basicRecords.numPorts);
                checkTargets(sm.stereoDiscrim,out.SDdetailsLeftAmplitude,out.SDdetailsRightAmplitude,num2cell(out.SDtargetPorts),num2cell(out.SDdistractorPorts),basicRecords.numPorts);

                [out.HFcorrectionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'HFcorrectionTrial'},'scalar',newLUT);
                [out.SDcorrectionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'SDcorrectionTrial'},'scalar',newLUT);
            %     out.HFcorrectionTrial=ensureScalar({stimDetails.HFcorrectionTrial});
            %     out.SDcorrectionTrial=ensureScalar({stimDetails.SDcorrectionTrial});

                if ~all(out.HFcorrectionTrial==out.HFdetailsCorrectionTrial) ||...
                        ~all(out.SDcorrectionTrial==out.SDdetailsCorrectionTrial)
                    error('SD or HF correctionTrial doesn''t match detailsCorrectionTrial')
                end

                [out.currentModality newLUT] = extractFieldAndEnsure(stimDetails,{'currentModality'},'scalar',newLUT);
            %     out.currentModality=ensureScalar({stimDetails.currentModality});

                if ~all(arrayfun(@checkAnswers,out.currentModality,out.HFtargetPorts,out.HFdistractorPorts,out.SDtargetPorts,out.SDdistractorPorts,basicRecords.targetPorts,basicRecords.distractorPorts))
                    error('inconsistent record')
                end

                out.correctionTrial=nan*ones(1,length(trialRecords));
                out.correctionTrial(out.currentModality==0)=out.HFcorrectionTrial(out.currentModality==0);
                out.correctionTrial(out.currentModality==1)=out.SDcorrectionTrial(out.currentModality==1);
                if any(isnan(out.correctionTrial))
                    error('not all correctionTrial assigned')
                end

                [out.blockingLength newLUT] = extractFieldAndEnsure(stimDetails,{'blockingLength'},'scalar',newLUT);
                [out.isBlocking newLUT] = extractFieldAndEnsure(stimDetails,{'isBlocking'},'scalar',newLUT);
                [out.currentModalityTrialNum newLUT] = extractFieldAndEnsure(stimDetails,{'currentModalityTrialNum'},'scalar',newLUT);
            %     out.blockingLength=ensureScalar({stimDetails.blockingLength});
            %     out.isBlocking=ensureScalar({stimDetails.isBlocking});
            %     out.currentModalityTrialNum=ensureScalar({stimDetails.currentModalityTrialNum});

                [out.modalitySwitchMethod newLUT] = extractFieldAndEnsure(stimDetails,{'modalitySwitchMethod'},{'typedVector','char'},newLUT);
                [out.modalitySwitchType newLUT] = extractFieldAndEnsure(stimDetails,{'modalitySwitchType'},{'typedVector','char'},newLUT);
            %     out.modalitySwitchMethod=ensureTypedVector({stimDetails.modalitySwitchMethod},'char');
            %     out.modalitySwitchType=ensureTypedVector({stimDetails.modalitySwitchType},'char');
            catch ex
                out=handleExtractDetailFieldsException(sm,ex,trialRecords);
            end

            verifyAllFieldsNCols(out,length(trialRecords));
        end

        function out=checkAnswers(modality,HFtarg,HFdistr,SDtarg,SDdistr,targs,distrs)
            if isscalar(targs) && isscalar(distrs)
                targ=targs{1};
                distr=distrs{1};
            else
                error('only works with scalar targs and distrs')
            end
            switch modality
                case 0
                    if targ==HFtarg && distr==HFdistr
                        %pass
                    else
                        error('HF targ or distr mismatch')
                    end
                case 1
                    if targ==SDtarg && distr==SDdistr
                        %pass
                    else
                        error('SD targ or distr mismatch')
                    end
                otherwise
                    modality
                    error('unrecognized modality')
            end
            out=true;
        end

        function stim=getAudioStimulus(s)
            stim = s.audioStimulus;
        end

        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case 'freeDrinks'
                        out=1;
                    case 'nAFC'
                        out=1;
                    otherwise
                        out=0;
                end
            else
                error('need a trialManager object')
            end
        end
        
        function testAnalysis(sm)

            blockLength=400;
            numBlocks=30;
            auditoryPerf=.7;
            visualPerf=.9;
            interference=.1;

            detailRecords.HFdetailsPctCorrectionTrials=[];
            detailRecords.SDdetailsPctCorrectionTrials=[];
            detailRecords.modalitySwitchMethod={};
            detailRecords.modalitySwitchType={};
            detailRecords.containedManualPokes=[];
            detailRecords.didHumanResponse=[];
            detailRecords.containedForcedRewards=[];
            detailRecords.didStochasticResponse=[];

            detailRecords.date=[];
            detailRecords.isBlocking=[];
            detailRecords.currentModality=[];
            detailRecords.isCorrection=[];
            detailRecords.HFtargetPorts=[];
            detailRecords.SDtargetPorts=[];

            detailRecords.targetPorts={};
            detailRecords.distractorPorts={};

            detailRecords.correct=[];
            detailRecords.response=[];

            ports=[1 3];
            t=now;
            for n=1:numBlocks
                t=t+1;
                modality=rand>.5;

                for b=1:blockLength
                    detailRecords.HFdetailsPctCorrectionTrials(end+1)=.5;
                    detailRecords.SDdetailsPctCorrectionTrials(end+1)=.5;
                    detailRecords.modalitySwitchMethod{end+1}='Random';
                    detailRecords.modalitySwitchType{end+1}='ByNumberOfHoursRun';
                    detailRecords.isCorrection(end+1)=0;
                    detailRecords.containedManualPokes(end+1)=0;
                    detailRecords.didHumanResponse(end+1)=0;
                    detailRecords.containedForcedRewards(end+1)=0;
                    detailRecords.didStochasticResponse(end+1)=0;

                    detailRecords.currentModality(end+1)=modality;

                    t=t+.01;
                    detailRecords.date(end+1)=t;

                    if .3<b/blockLength
                        detailRecords.isBlocking(end+1)=0;
                    else
                        detailRecords.isBlocking(end+1)=1;
                    end

                    detailRecords.HFtargetPorts(end+1)=ports((rand>.5)+1);
                    detailRecords.SDtargetPorts(end+1)=ports((rand>.5)+1);

                    if modality
                        detailRecords.targetPorts{end+1}=detailRecords.SDtargetPorts(end);
                    else
                        detailRecords.targetPorts{end+1}=detailRecords.HFtargetPorts(end);
                    end
                    detailRecords.distractorPorts{end+1}=ports(fliplr(ports==detailRecords.targetPorts{end}));

                    if modality
                        perf=auditoryPerf;
                    else
                        perf=visualPerf;
                    end

                    if ~detailRecords.isBlocking(end)
                        if detailRecords.HFtargetPorts(end)==detailRecords.SDtargetPorts(end)
                            perf=perf+interference;
                        else
                            perf=perf-interference;
                        end
                    end

                    detailRecords.correct(end+1)=rand<perf;
                    if detailRecords.correct(end)
                        detailRecords.response(end+1)=detailRecords.targetPorts{end};
                    else
                        detailRecords.response(end+1)=detailRecords.distractorPorts{end};
                    end
                end
            end

            analysis(sm,detailRecords,'test');
        end
        
        
    end
    
end


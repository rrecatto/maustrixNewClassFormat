classdef stereoDiscrim
    
    properties
        mean = 0;
        freq = 0;
        amplitudes = [];
        stimSound = []; % Sound to play for the stimulus
        audioStimulus = true;

    end
    
    methods
        function s=stereoDiscrim(varargin)
            % Stereo Discrim class constructor.
            % s =
            % stereoDiscrim(mean,freq,[amplitudes],maxWidth,maxHeight,scaleFactor,interTrialLuminance) 
            % mean normalized (0 <= value <= 1)
            % Description of arguments:
            % =========================
            % mean - Mean brightness
            % freq - (Fundamental) frequency of sound to play
            % [amplitudes] - [low high] sound amplitudes from 0<=x<=1

            switch nargin
            case 0 
            % if no input arguments, create a default object
                s = class(s,'stereoDiscrim',stimManager());    
            case 1
            % if single argument of this class type, return it
                if (isa(varargin{1},'stereoDiscrim'))
                    s = varargin{1}; 
                else
                    error('Input argument is not a stereoDiscrim object')
                end
            case 7
            % create object using specified values        
                if varargin{1} >=0
                    s.mean=varargin{1};
                else
                    error('0 <= mean <= 1')
                end

                if varargin{2} > 0
                    s.freq=varargin{2};
                else
                    error('freq must be > 0')
                end

                if length(varargin{3}) == 2 && all(varargin{3}>=0) 
                    s.amplitudes=varargin{3};
                else
                    error('require two stereo amplitudes and they must be >= 0')
                end

                s = class(s,'stereoDiscrim',stimManager(varargin{4},varargin{5},varargin{6},varargin{7}));   

            otherwise
                error('Wrong number of input arguments')
            end
        end
        
        function analysis(sm,detailRecords,subjectID)
            if all(detailRecords.pctCorrectionTrials==.5)
                %pass
            else
                unique(detailRecords.pctCorrectionTrials)
                warning('standard stereoDiscrim config violated')
            end

            options=cellfun(@union,detailRecords.targetPorts,detailRecords.distractorPorts,'UniformOutput',false);

            goods=detailRecords.isCorrection==0 ...
                & cellfun(@ismember,num2cell(detailRecords.response),options) ...
                & ~detailRecords.containedManualPokes ...
                & ~detailRecords.didHumanResponse ...
                & ~detailRecords.containedForcedRewards ...
                & ~detailRecords.didStochasticResponse;

            amps=sort([detailRecords.leftAmplitude;detailRecords.rightAmplitude]);

            %any time amplitdues change, increment session number.  also when trial is more than an hour since previous trial.
            sessionNum=cumsum([1    sign(    double((24*diff(detailRecords.date))>1)    +   sum(abs(diff(amps')'))    )   ]);


            alpha=.05;

            data.perf.phat=[];
            data.perf.pci=[];
            data.bias.phat=[];
            data.bias.pci=[];
            amplitudes=[];
            sessions=[];

            trialsIncluded=0;
            minTrials=25;
            for i=1:max(sessionNum)
                trials=sessionNum==i & goods;

                if sum(trials)>=minTrials
                    trialsIncluded=trialsIncluded+sum(trials);

                    a=unique(amps(:,trials)','rows');
                    if size(a,1)~=1
                        error('found multiple amplitudes within a session')
                    end
                    amplitudes(end+1,:)=a;

                    total=sum(trials);
                    correct=sum(trials & detailRecords.correct);
                    responseRight=sum(trials & detailRecords.response==3);
                    [phat pci]=binofit([correct responseRight],[total total],alpha);

                    if all(pci(:,1)<pci(:,2))

                        ind=1;
                        data.perf.phat(end+1)=phat(ind);
                        data.perf.pci(end+1,:)=pci(ind,:);

                        ind=2;
                        data.bias.phat(end+1)=phat(ind);
                        data.bias.pci(end+1,:)=pci(ind,:);

                        sessions(end+1)=i;
                    else
                        error('pci''s came back descending')
                    end
                else
                    fprintf('skipping a %d session\n',sum(trials))
                end
            end
            fprintf('included %d clumped of %d good trials (%g%%)\n',trialsIncluded,sum(goods),round(100*trialsIncluded/sum(goods)));

            figName=sprintf('%s: stereoDiscrim performance and bias',subjectID);
            figure('Name',figName)
            subplot(2,1,1)
            c={'r' 'k'};
            makePerfBiasPlot(sessions,data,c);
            title(figName);

            subplot(2,1,2)
            for i=1:length(sessions)
                plot(sessions(i),amplitudes(i,:),'k*','MarkerSize',10)
                hold on
            end
            xlim([1 max(sessions)])
            ylim([min(amplitudes(:)) max(amplitudes(:))]+[-1 1]*range(amplitudes(:))*.1)
            title('amplitudes')
            xlabel('session')


            pth='C:\Documents and Settings\rlab\Desktop\detailedRecords';
            saveas(gcf,fullfile(pth,[subjectID '_stereoDiscrim']),'png');
        end
        
        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =... 
    calcStim(stimulus,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % 1/3/0/09 - trialRecords now includes THIS trial
            %LUT = Screen('LoadCLUT', 0);
            %LUT=LUT/max(LUT(:));

            indexPulses=[];
            imagingTasks=[];

            LUTBitDepth=8;
            numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
            ramp=[0:fraction:1];
            LUT= [ramp;ramp;ramp]';

            [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));

            updateSM=0;
            details.correctionTrial=0;
            toggleStim=true;
            text='stereoDiscrim';

            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus);

            switch trialManagerClass
                case 'freeDrinks'
                    type='cache';
                    % fli: this never gets used anyways, so why is it still here?
                    % Determine what the last response was
            %         if ~isempty(trialRecords) && length(trialRecords)>=2
            %             lastResponse=find(trialRecords(end-1).response);
            %             if length(lastResponse)>1
            %                 lastResponse=lastResponse(1);
            %             end
            %         else
            %             lastResponse=[];
            %         end
                    % Go to port with sound, ignore wrong answers
                    '##################CALC STIM RESPONSE PORTS#################'
                    responsePorts
                    % Go to port with sound, ignore wrong answers
                    tp=round(rand);
                    if(tp == 0)
                        targetPorts = responsePorts(1); % Left
                    else
                        targetPorts = responsePorts(end); % Right
                    end
                    distractorPorts=[];
                case 'nAFC'
                    type='loop';%int32([10 10]); % This is 'timedFrames'

                    %edf: 11.25.06: copied correction trial logic from hack addition to cuedGoToFeatureWithTwoFlank
                    %edf: 11.15.06 realized we didn't have correction trials!
                    %changing below...

                    details.pctCorrectionTrials=.5; % need to change this to be passed in from trial manager
                    details.bias = getRequestBias(trialManager);

                    if ~isempty(trialRecords) && length(trialRecords)>=2
                        lastRec=trialRecords(end-1);
                    else
                        lastRec=[];
                    end
                    [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass);


                    distractorPorts=setdiff(responsePorts,targetPorts);
                    targetPorts

                otherwise
                    error('unknown trial manager class')
            end

            % Use the amplitudes and the target port to determine how to set the spread
            if targetPorts == 1 % Left Bias -- this is hacky, how to tell if port is left or not?
                details.leftAmplitude = max(stimulus.amplitudes);
                details.rightAmplitude = min(stimulus.amplitudes);
            else % Right Bias
                details.leftAmplitude = min(stimulus.amplitudes);
                details.rightAmplitude = max(stimulus.amplitudes);
            end
            sSound = soundClip('stimSoundBase','allOctaves',[stimulus.freq],20000);
            stimulus.stimSound = soundClip('stimSound','dualChannel',{sSound,details.leftAmplitude},{sSound,details.rightAmplitude});

            out=zeros(min(height,getMaxHeight(stimulus)),min(width,getMaxWidth(stimulus)),2);
            out(:,:,1)=stimulus.mean;
            out(:,:,2)=stimulus.mean;

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
        end
        
        function checkTargets(sm,leftAmplitude,rightAmplitude,targetPorts,distractorPorts,numPorts)
            if ~any(leftAmplitude==rightAmplitude)
                targetIsRight=leftAmplitude<rightAmplitude;
            else
                error('left and right amplitude are equal')
            end
            checkNafcTargets(targetIsRight,targetPorts,distractorPorts,numPorts);
        end
        
        function d=display(s)
            type='';
            d=['stereoDiscrim (n target, m distractor fields, ' type ' type)\n'...
                '\t\t\tfreq:\t[' num2str(s.freq) ... 
                ']\n\t\t\tamplitudes:\t[' num2str(s.amplitudes)];
            d=sprintf(d);
        end
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;
            if ~all(strcmp({trialRecords.trialManagerClass},'nAFC'))
                warning('only works for nAFC trial manager')
                out=struct;
            else

                try
                    stimDetails=[trialRecords.stimDetails];

                    [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                    [out.leftAmplitude newLUT] = extractFieldAndEnsure(stimDetails,{'leftAmplitude'},'equalLengthVects',newLUT);
                    [out.rightAmplitude newLUT] = extractFieldAndEnsure(stimDetails,{'rightAmplitude'},'equalLengthVects',newLUT);
            %         out.correctionTrial=ensureScalar({stimDetails.correctionTrial});
            %         out.pctCorrectionTrials=ensureScalar({stimDetails.pctCorrectionTrials});
            %         out.leftAmplitude=ensureEqualLengthVects({stimDetails.leftAmplitude});
            %         out.rightAmplitude=ensureEqualLengthVects({stimDetails.rightAmplitude});

                    checkTargets(sm,out.leftAmplitude,out.rightAmplitude,basicRecords.targetPorts,basicRecords.distractorPorts,basicRecords.numPorts);
                catch ex
                    out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                end
            end
            verifyAllFieldsNCols(out,length(trialRecords));
        end
        
        function stim=getAudioStimulus(s)
            stim = s.stimSound;
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
        
        
    end
    
end


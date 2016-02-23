classdef hemifieldFlicker<stimManager
    
    properties
        numCalcIndices = [];
        targetContrasts = []; 
        distractorContrasts = []; 
        fieldWidthPct = 0;
        fieldHeightPct = 0;
        mean = 0;
        stddev = 0;
        thresh = 0;
        flickerType = 0; 
        yPosPct = 0; 
    end
    
    methods
        function s=hemifieldFlicker(varargin)
            % Hemifield Flicker  class constructor.
            % s =
            % hemifieldFlicker([pixPerCycs],[targetContrasts],[distractorContrasts],fieldWidthPct,fieldHeightPct,mean,stddev,thresh,flickerType,yPositionPercent,maxWidth,maxHeight,scaleFactor,interTrialLuminance) 
            % mean, contrasts, yPositionPercent normalized (0 <= value <= 1)
            % Description of arguments:
            % =========================
            % targetContrasts - Number of fields for target ports and the contrast imposed on each
            % distractorContrasts - Number of fields for distractor ports and the contrast imposed on each
            % fieldWidthPct - Width (horizontal) in X axis as a percentage of screen (0 <= fieldWidth <= 1)
            % fieldHeightPct - Height (vertical) in Y axis as a percentage of screen (0 <= fieldHeight <= 1)
            % mean - Mean brightness
            % stddev - Standard deviation of contrast (for Gaussian)
            % thresh - in normalized luminance units, the value below which the stim should not appear 
            % flickerType - 0 for binary flicker; 1 for Gaussian flicker
            % yPosPct - Position in Y axis (vertical) of screen to present the fields

            switch nargin
            case 0 
            % if no input arguments, create a default object
                
            case 1
            % if single argument of this class type, return it
                if (isa(varargin{1},'hemifieldFlicker'))
                    s = varargin{1}; 
                else
                    error('Input argument is not a hemifieldFlicker object')
                end
            case 14
            % create object using specified values        
                if all(varargin{1})>0
                    s.numCalcIndices=varargin{1};
                else
                    error('numCalcIndices must be > 0')
                end

                if all(isnumeric(varargin{2})) && all(isnumeric(varargin{3}))
                    s.targetContrasts=varargin{2};
                    s.distractorContrasts=varargin{3};
                else
                    error('target and distractor contrasts must be numbers')
                end

                if varargin{4} >= 0 && varargin{4}<=1
                    s.fieldWidthPct=varargin{4};
                else
                    error('fieldWidthPct must be >= 0')
                end

                if varargin{5} >= 0 && varargin{5}<=1
                    s.fieldHeightPct=varargin{5};
                else
                    error('fieldHeightPct must be >= 0')
                end    

                if varargin{6} >=0
                    s.mean=varargin{6};
                else
                    error('0 <= mean <= 1')
                end

                if varargin{7} >= 0
                    s.stddev=varargin{7};
                else
                    error('stddev must be >= 0')
                end

                if varargin{8} >= 0
                    s.thresh=varargin{8};
                else
                    error('thresh must be >= 0')
                end

                if isnumeric(varargin{9})
                    s.flickerType=varargin{9};
                else
                    error('flickerType must be 0 at this time (only binary flicker supported)')
                end

                if isnumeric(varargin{10})
                    s.yPosPct=varargin{10};
                else
                    error('yPositionPercent must be numeric')
                end

                

            otherwise
                error('Wrong number of input arguments')
            end
        end
        
        function analysis(sm,detailRecords,subjectID)
            if all(detailRecords.pctCorrectionTrials==.5)
                %pass
            else
                unique(detailRecords.pctCorrectionTrials)
                warning('standard hemifieldFlicker config violated')
            end

            options=cellfun(@union,detailRecords.targetPorts,detailRecords.distractorPorts,'UniformOutput',false);

            goods=detailRecords.isCorrection==0 ...
                & cellfun(@ismember,num2cell(detailRecords.response),options) ...
                & ~detailRecords.containedManualPokes ...
                & ~detailRecords.didHumanResponse ...
                & ~detailRecords.containedForcedRewards ...
                & ~detailRecords.didStochasticResponse;

            contrasts=detailRecords.contrasts;
            xPosPcts=detailRecords.xPosPcts;
            if ~any(contrasts(:)<0) && ~any(xPosPcts(:)<0) %nan<0 gives 0
                contrasts(isnan(contrasts))=-1;
                xPosPcts(isnan(xPosPcts))=-1;

                contrasts=sort(contrasts);
                xPosPcts=sort(xPosPcts);

                %any time flickers change location or contrast, increment session number (location change doesn't count if singleton).  also when trial is more than an hour since previous trial.
                sessionNum=cumsum([1    sign(    double((24*diff(detailRecords.date))>1)    +   sum(abs(diff(contrasts')'))   +  (sum(abs(diff(xPosPcts')'))>0 & sum(xPosPcts(:,2:end)~=-1)~=1)  )   ]);
            else
                error('found contrasts or xPosPcts less than zero')
            end

            alpha=.05;

            data.perf.phat=[];
            data.perf.pci=[];
            data.bias.phat=[];
            data.bias.pci=[];
            sessionContrasts={};
            sessionXPosPcts={};
            sessions=[];

            trialsIncluded=0;
            minTrials=25;
            for i=1:max(sessionNum)
                trials=sessionNum==i & goods;

                if sum(trials)>=minTrials
                    trialsIncluded=trialsIncluded+sum(trials);

                    sessionContrasts{end+1}=unique(contrasts(:,trials)','rows');
                    sessionXPosPcts{end+1}=unique(xPosPcts(:,trials)','rows');
                    if size(sessionContrasts{end},1)~=1 || (size(sessionXPosPcts{end},1)~=1 && ~all(sum((sessionXPosPcts{end}~=-1)')==1))
                        error('found multiple contrasts or positions within a session')
                    end
                    sessionContrasts{end}=sessionContrasts{end}(sessionContrasts{end}~=-1);
                    sessionXPosPcts{end}=sessionXPosPcts{end}(sessionXPosPcts{end}~=-1);
                    sessionXPosPcts{end}=sessionXPosPcts{end}(:)';

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

            figName=sprintf('%s: hemifieldFlicker performance and bias',subjectID);
            figure('Name',figName)
            subplot(3,1,1)
            c={'r' 'k'};
            makePerfBiasPlot(sessions,data,c);
            title(figName);

            subplot(3,1,2)
            for i=1:length(sessions)
            plot(sessions(i),sessionContrasts{i},'k*','MarkerSize',10)
            hold on
            end
            xlim([1 max(sessions)])
            ylim([min([sessionContrasts{:}]) max([sessionContrasts{:}])]+[-1 1]*range([sessionContrasts{:}])*.1)
            title('contrasts')

            subplot(3,1,3)
            for i=1:length(sessions)
            plot(sessions(i),sessionXPosPcts{i},'k*','MarkerSize',10)
            hold on
            end
            xlim([1 max(sessions)])
            ylim([min([sessionXPosPcts{:}]) max([sessionXPosPcts{:}])]+[-1 1]*range([sessionXPosPcts{:}])*.1)
            title('x positions')
            xlabel('session')


            pth='C:\Documents and Settings\rlab\Desktop\detailedRecords';
            saveas(gcf,fullfile(pth,[subjectID '_hemifieldFlicker']),'png');
        end

        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =... 
    calcStim(stimulus,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % 1/3/0/09 - trialRecords now includes THIS trial
            %LUT = Screen('LoadCLUT', 0);
            %LUT=LUT/max(LUT(:));
            indexPulses=[];
            imagingTasks=[];
            [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));

            LUTBitDepth=8;
            numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
            ramp=[0:fraction:1];
            LUT= [ramp;ramp;ramp]';

            text='hemifield';
            updateSM=0;
            correctionTrial=0;

            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus);

            details.pctCorrectionTrials=getPercentCorrectionTrials(trialManager);
            details.bias = getRequestBias(trialManager);

            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);
            switch trialManagerClass
                case 'freeDrinks'
                    type={'indexedFrames',[]};%int32([10 10]); % This is 'timedFrames'
                case 'nAFC'
                    type={'indexedFrames',[]};%int32([10 10]); % This is 'timedFrames'
                otherwise
                    error('unsupported trialManagerClass');
            end

            numTargs=length(stimulus.targetContrasts);
            details.contrasts = stimulus.targetContrasts(ceil(rand(length(targetPorts),1)*numTargs));
            details.correctionTrial=correctionTrial;

            numDistrs=length(stimulus.distractorContrasts);
            if numDistrs>0
                numFields=length(targetPorts)+length(distractorPorts);
                details.contrasts = [details.contrasts; stimulus.distractorContrasts(ceil(rand(length(distractorPorts),1)*numDistrs))];
                distractorLocs=distractorPorts;
            else
                numFields=length(targetPorts);
                distractorLocs=[];
            end
            % Set the randomly calculated frame indices
            type{2} = round(rand(stimulus.numCalcIndices,1)*(2^numFields-1)+1); 

            xPosPcts = [linspace(0,1,totalPorts+2)]';
            xPosPcts = xPosPcts(2:end-1);
            details.xPosPcts = xPosPcts([targetPorts'; distractorLocs']);

            params = [repmat([stimulus.fieldWidthPct stimulus.fieldHeightPct],numFields,1) details.contrasts repmat([stimulus.thresh],numFields,1) details.xPosPcts repmat([stimulus.yPosPct],numFields,1)];
            out(:,:,1:2^numFields)=computeFlickerFields(params,stimulus.flickerType,stimulus.mean,min(width,getMaxWidth(stimulus)),min(height,getMaxHeight(stimulus)),0);

            %EDF: 02.08.07 -- i think this is only supposed to be for nafc but not sure...
            %was causing free drinks stim to only show up for first frame...
            %if strcmp(trialManagerClass,'nAFC')%pmm also suggests this:  && strcmp(type,'trigger')
            %    out(:,:,3)=stimulus.mean;
            %end
            %DFP: 01.04.08 -- I needed this for both freeDrinks and nAFC, because the
            %index doesn't rotate without an empty stimulus at the end
            out(:,:,3)=stimulus.mean;


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

            postDiscrimStim = [];

        end % end function

        function checkTargets(sm,xPosPcts,contrasts,targetPorts,distractorPorts,numPorts)

            if size(xPosPcts,1)==size(contrasts,1)
                if size(contrasts,1)>1
                    [junk inds]=sort(xPosPcts);
                    sz=size(contrasts);
                    inds=sub2ind(sz,inds,repmat(1:sz(2),sz(1),1));
                    temp=contrasts(inds);
                    [junk inds]=max(temp);
                    [answers cols]=find(repmat(max(temp),size(temp,1),1)==temp);
                    targetIsRight=logical(answers-1);
                    if ~all(cols'==1:size(temp,2))
                        error('nonunique answer')
                    end
                else
                    if ~any(xPosPcts==.5)
                        targetIsRight=xPosPcts>.5;
                    else
                        error('xPosPct at .5')
                    end
                end
            else
                size(xPosPcts,1)
                size(contrasts,1)
                error('dims of contrasts and xPosPcts don''t match')
            end
            % checkNafcTargets(targetIsRight,targetPorts,distractorPorts,numPorts);
            % 3/15/09 - fli removed this check because found trialRecords with freeDrinks-like target/distractor but nAFC tm
            % see behavior/pmmTrialRecords/subjects/225/trialRecords_6811-7091_20080502T113147-20080502T130836.mat
            % trialRecords(1)
        end
        
        function d=display(s)
            type='';
            switch s.flickerType
                case 0
                    type = 'binary flicker';
                case 1
                    type = 'Gaussian flicker';
                otherwise
                    error('Invalid hemifield flicker type in display()')
            end
            d=['hemifieldFlicker (n target, m distractor fields, ' type ' type)\n'...
                '\t\t\tnumCalcIndices:\t[' num2str(s.numCalcIndices) ... 
                ']\n\t\t\ttarget contrasts:\t[' num2str(s.targetContrasts) ...
                ']\n\t\t\tdistractor contrasts:\t[' num2str(s.distractorContrasts) ...
                ']\n\t\t\tfieldWidthPct:\t' num2str(s.fieldWidthPct) ...
                ']\n\t\t\tfieldHeightPct:\t' num2str(s.fieldHeightPct) ...
                ']\n\t\t\tmean:\t' num2str(s.mean) ...
                '\n\t\t\tstddev:\t' num2str(s.stddev) ...
                '\n\t\t\tthresh:\t' num2str(s.thresh) ...
                '\n\t\t\tpct from top:\t' num2str(s.yPosPct)];
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
                    [out.contrasts newLUT] = extractFieldAndEnsure(stimDetails,{'contrasts'},'equalLengthVects',newLUT);
                    [out.xPosPcts newLUT] = extractFieldAndEnsure(stimDetails,{'xPosPcts'},'equalLengthVects',newLUT);
            %         out.correctionTrial=ensureScalar({stimDetails.correctionTrial});
            %         out.pctCorrectionTrials=ensureScalar({stimDetails.pctCorrectionTrials});
            %         out.contrasts=ensureEqualLengthVects({stimDetails.contrasts});
            %         out.xPosPcts=ensureEqualLengthVects({stimDetails.xPosPcts});

                    checkTargets(sm,out.xPosPcts,out.contrasts,basicRecords.targetPorts,basicRecords.distractorPorts,basicRecords.numPorts);
                catch ex
                    if strcmp(ex.message,'not all same length')
                        warning('bailing: found trials with varying numbers of flickers -- happens rarely in some of dan''s early data')
                        out=struct;
                    else
                        out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                    end
                end
            end
            verifyAllFieldsNCols(out,length(trialRecords));
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


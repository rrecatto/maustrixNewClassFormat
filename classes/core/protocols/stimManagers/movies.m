classdef movies<stimManager
    
    properties
        directory = '';
        background=0;
        yPositionPercent=0;
        cache=[];
        trialDistribution={};
        imageSelectionMode=[];

        % added 12/8/08 - size and rotation parameters
        size=[];
        % uniformly select on this range each trial,
        % and scale the size of image by this factor 
        rotation=[];
        sizeyoked=[];
        rotationyoked=[];
        % if 1, the size of distractor is scaled by
        % the same amount as the target; if 0,
        % independently draw a scale factor for the distractor 
        selectedSizes=[]; % not user-defined; this gets set by calcStim as the randomly drawn value from the size range
        selectedRotations=[]; % not user-defined; this gets set by calcStim as the randomly drawn value from the rotation range
        images=[]; % used for expert mode
        pctCorrectionTrials=[];
        drawingMode='expert';
    end
    
    methods
        function s=movies(varargin)
            % IMAGES  class constructor.
            % s = images(directory,yPositionPercent,background,maxWidth,maxHeight,scaleFactor,interTrialLuminance,...
            %   trialDistribution,imageSelectionMode,size,sizeyoked,rotation,rotationyoked,pctCorrectionTrials[,drawingMode])
            % yPositionPercent (0 <= value <= 1), in normalized units of the diagonal of the stim region
            % trialDistribution in format { { {imagePrefixN imagePrefixP} .1}...
            %                               { {imagePrefixP imagePrefixM} .9}...
            %                             }
            % first image listed for each trial is correct answer
            % trial chosen according to probabilities provided (will be normalized)
            % image names should not include path or extension
            % images must reside in directory indicated and be .png's with alpha channels
            % 
            % imageSelectionMode is either 'normal' or 'deck' (deck means we make use of the deck-style card selection used in v0.8)
            % size is a [2x1] vector that specifies a range from which to randomly select a size for the images (varies from 0-1)
            % sizeyoked is a flag that indicates if all images have same size, or if to randomly draw a size for each image
            % rotation is a [2x1] vector that specifies ar range from which to randomly select a rotation value for the images (in degrees!)
            % rotationyoked is a flag that indicates if all images have same rotation, or if to randomly draw a rotation for each image
            % drawingMode is an optional argument that specifies drawing in 'expert' versus 'static' mode (default is 'expert'


            switch nargin
                case 0
                    % if no input arguments, create a default object

                    

                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'images'))
                        s = varargin{1};
                    else
                        error('Input argument is not an images object')
                    end
                case {14 15}
                    % create object using specified values

                    if ischar(varargin{1})
                        s.directory=varargin{1};
                        try
                            d=isdir(s.directory); % may fail due to windows networking/filesharing bug, but unlikely at construction time
                        catch ex
                            disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                            error('can''t load that directory')
                        end
                    else
                        error('directory must be fully resolved string')
                    end

                    if isreal(varargin{2}) && isscalar(varargin{2}) && varargin{2}>=0 && varargin{2}<=1
                        s.yPositionPercent=varargin{2};
                    else
                        error('yPositionPercent must be real scalar 0<=yPositionPercent<=1')
                    end

                    if isreal(varargin{3}) && isscalar(varargin{3}) && varargin{3}>=0 && varargin{3}<=1
                        s.background=varargin{3};
                    else
                        error('background must be real scalar 0<=background<=1')
                    end

                    if iscell(varargin{8}) && isvector(varargin{8}) && ~isempty(varargin{8})
                        valid=true;
                        for i=1:length(varargin{8})
                            entry=varargin{8}{i};
                            if ~all(size(entry)==[1 2]) || ~iscell(entry) || ~iscell(entry{1}) || ~isvector(entry{1}) ...
                                    || ~all(cellfun(@ischar,entry{1})) ||~all(cellfun(@isvector,entry{1})) ...
                                    || ~isscalar(entry{2}) || ~isreal(entry{2}) || ~(entry{2}>=0)

                                entry
                                entry{1}
                                entry{2}

                                valid=false;
                                break
                            end
                        end

                        if valid
                            s.trialDistribution=varargin{8};
                        else
                            error('cell entries in trialDistribution must be 1x2 cells of format {imagePrefixN imagePrefixP} prob}')
                        end
                    else
                        varargin{8}
                        size(varargin{8})
                        error('trialDistribution must be nonempty vector cell array')
                    end

                    %imageSelectionMode
                    if ischar(varargin{9}) && (strcmp(varargin{9},'normal') || strcmp(varargin{9},'deck'))
                        s.imageSelectionMode=varargin{9};
                    else
                        error('imageSelectionMode must be either ''normal'' or ''deck''');
                    end

                    %size
                    if isvector(varargin{10}) && length(varargin{10})==2 && isnumeric(varargin{10}) && ...
                            all(varargin{10}>0) && all(varargin{10}<=1) && varargin{10}(2)>=varargin{10}(1)
                        s.size=varargin{10};
                    else
                        error('size must be a 2-element vector between 0 and 1');
                    end

                    %sizeyoked
                    if islogical(varargin{11})
                        s.sizeyoked=varargin{11};
                    else
                        error('sizeyoked must be a logical');
                    end

                    %rotation
                    if isvector(varargin{12}) && length(varargin{12})==2 && isnumeric(varargin{12})
                        s.rotation=varargin{12};
                    else
                        error('rotation must be a 2-element vector');
                    end

                    %rotationyoked
                    if islogical(varargin{13})
                        s.rotationyoked=varargin{13};
                    else
                        error('rotationyoked must be a logical');
                    end

                    %pctCorrectionTrials
                    if ~isempty(varargin{14}) && isnumeric(varargin{14}) && varargin{14}>=0 && varargin{14}<=1
                        s.pctCorrectionTrials=varargin{14};
                    else
                        error('pctCorrectionTrials must be >=0 and <=1');
                    end

                    %mode
                    if nargin==15
                        if ischar(varargin{15}) && (strcmp(varargin{15},'expert') || strcmp(varargin{15},'cache'))
                            s.drawingMode=varargin{15};
                        else
                            error('drawingMode must be ''expert'' or ''cache''');
                        end
                    end       

                    

                    validateImages(s); %error if can't load images or bad format

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

            finalStep=7;
            goods = goods & detailRecords.trainingStepNum==finalStep; %danger!

            [a junk difficulty]=unique(sort(detailRecords.suffices)','rows');

            difficulties=unique(difficulty);
            if any(difficulties~=[1:size(a,1)]')
                error('bad difficulties')
            end

            badDifficulties=find(sum((a==0)')); %these should be coming through as nans -- why are they zeros?  see extractDetailFields...

            if ~isempty(badDifficulties)
                a=a([1:size(difficulties,1)]~=badDifficulties,:);
                difficulties=difficulties([1:size(difficulties,1)]~=badDifficulties,:);
                goods=goods' & difficulty~=badDifficulties;
            end

            alpha=.05;
            for d=1:length(difficulties)
                trials = goods & difficulty==difficulties(d);
                correct(d)=sum(trials' & detailRecords.correct);
                total(d) = sum(trials);
                strs{d}=sprintf('%d-%d',a(d,1),a(d,2));
            end

            [data.phat data.pci]=binofit(correct,total,alpha);

            if all(data.pci(:,1)<data.pci(:,2))
                figName=sprintf('%s: morph performance',subjectID);
                figure('Name',figName)
                makeConfPlot(1:length(difficulties),data,'k');
                title(figName);
                    set(gca,'XTick',1:length(difficulties));
                set(gca,'XTickLabel',strs);
            else
                error('pci''s came back descending')
            end

            pth='C:\Documents and Settings\rlab\Desktop\detailedRecords';
            saveas(gcf,fullfile(pth,[subjectID '_morph']),'png');
        end
        
        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =... 
    calcStim(stimulus,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % see ratrixPath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)

            LUT=makeStandardLUT(LUTbits);
            [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));

            type = stimulus.drawingMode; % 12/9/08 - user can specify to use 'cache' (default) or 'expert' mode (optional)
            indexPulses=[];
            imagingTasks=[];
            % ====================================================================================
            % if we are in deck mode, do card selection and checking
            % else, just assign ind randomly based on the trialDistribution
            if strcmp(stimulus.imageSelectionMode,'deck')
                numImages = length(getDist(stimulus));
                % 1/28/09 - fixed to correctly reset decksFinished counter at the start of a new trainingStep, because
                % this assumes that calcStim now receives ALL trialRecords instead of up to trialRecords(end-1)
                if length(trialRecords)>1
                    if trialRecords(end).trainingStepNum ~= trialRecords(end-1).trainingStepNum % if this is the first trial of a new step
                        % reset decksFinished to 0, cardsRemaining should be empty
                        details.decksFinished=0;
                        details.cardsRemaining=[];
                    else % same step
                        if isfield(trialRecords(end-1),'stimDetails') && isfield(trialRecords(end-1).stimDetails,'decksFinished') ...
                                && isfield(trialRecords(end-1).stimDetails,'cardsRemaining')
                            details.decksFinished=trialRecords(end-1).stimDetails.decksFinished;
                            details.cardsRemaining=trialRecords(end-1).stimDetails.cardsRemaining;
                        else
                            details.decksFinished=0;
                            details.cardsRemaining=[];
                        end
                    end
                else
                    % this is the first trial
                    details.decksFinished=0;
                    details.cardsRemaining=[];
                end

                % if cardsRemaining is empty, then generate a new deck - this only happens once during initialization
                if isempty(details.cardsRemaining)
                    details.cardsRemaining=randperm(numImages);
                elseif length(details.cardsRemaining) == 1
                    % because we remove the last card, and then check and increment decksFinished
                    % - now, we will draw the last card from a deck in trial N, and move on to trial N+1 without incrementing decksFinished
                    % when we get to trial N+1, this will catch that the deck only has one card and then increment decksFinished and reshuffle a new deck
                    % if only card left is the exemplar
                    details.cardsRemaining = randperm(numImages);
                    % this means we finished a deck - store this in details
                    details.decksFinished = details.decksFinished + 1; % - we can use this to check graduation criteria

                    %     finishedADeck = true;
                    %     break
                end

                % how to draw from distribution? - two step process
                % first draw from full trialDistribution to decide exemplar/morph
                % then, if morph - if morph card still remaining, use it, otherwise select a random morph card from deck
                indFromTrialDistribution=min(find(rand<cumsum(getDist(stimulus)))); %draw from trialDistribution
                if indFromTrialDistribution ~= 1 % if this is not exemplar
                    % check if morph card remains
                    if ~isempty(find(details.cardsRemaining == indFromTrialDistribution))
                        indOfCardsLeft = find(details.cardsRemaining == indFromTrialDistribution);
                    else
                        % morph card already used, pick a random one - MAKE SURE YOU DONT PICK EXEMPLAR
                        exemplarIndex = find(details.cardsRemaining == 1);
                        indOfCardsLeft = exemplarIndex;
                        while (indOfCardsLeft == exemplarIndex || indOfCardsLeft == 0) % keep picking randomly until you hit a morph
                            indOfCardsLeft=round(rand*length(details.cardsRemaining));
                        end
                    end
                    % pick the correct element from cardsLeft, and remove it from the stim manager
                    ind = details.cardsRemaining(indOfCardsLeft);
                    details.cardsRemaining(indOfCardsLeft) = []; % delete the element that got selected
                else
                    % this is exemplar
                    ind = indFromTrialDistribution;
                end

                % pickedIndices(end+1) = ind;
                details.cardSelected = ind;
                % details.cardsRemaining = details.cardsRemaining;

                % finished doing deck handling
            else
                % 'normal' mode
                ind=min(find(rand<cumsum(getDist(stimulus)))); %draw from trialDistribution
            end

            % ====================================================================================
            % do image preparation
            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus);

            % 12/8/08 - randomly draw from size and rotation; store values into selectedSize and selectedRotations, and also write to details
            % goes hand in hand with dynamic mode for doing the rotation and scaling
            % 12/15/08 - moved up here so that these values can get sent to checkImages->prepareImages (for static mode rotation/scaling)
            if stimulus.sizeyoked
                stimulus.selectedSizes = repmat(stimulus.size(1) + rand(1)*(stimulus.size(2)-stimulus.size(1)),1,totalPorts);
            else
                % draw a random size for every image
                stimulus.selectedSizes=zeros(1,totalPorts);
                for i=1:totalPorts
                    stimulus.selectedSizes(i) = stimulus.size(1) + rand(1)*(stimulus.size(2)-stimulus.size(1));
                end
            end
            if stimulus.rotationyoked
                stimulus.selectedRotations = repmat(round(stimulus.rotation(1) + rand(1)*(stimulus.rotation(2)-stimulus.rotation(1))),1,totalPorts);
            else
                stimulus.selectedRotations = zeros(1,totalPorts);
                for i=1:totalPorts
                    stimulus.selectedRotations(i) = round(stimulus.rotation(1) + rand(1)*(stimulus.rotation(2)-stimulus.rotation(1)));
                end
            end
            %from PR: how to get this passed to calcstim as user defined param?
            %response from edf: add fields to the class (in its constructor)
            normalizeHistograms=false;
            pctScreenFill=0.75;
            backgroundcolor=uint8(intmax('uint8')*stimulus.background);
            [stimulus updateSM ims]=checkImages(stimulus,uint8(ind),backgroundcolor, pctScreenFill, normalizeHistograms,width,height);

            %ims comes back as a nX2 cell array, where n is number of images specified in the trialDistribution entry we requested
            %ims{:,1} is the image data, ims{:,2} are details (like the file name)

            if strcmp(trialManagerClass,'freeDrinks') && size(ims,1)==length(responsePorts)-1
                responsePorts=responsePorts(1:end-1); %free drinks trial will have one extra response port
            end

            details.pctCorrectionTrials=getPercentCorrectionTrials(trialManager);
            details.bias = getRequestBias(trialManager);


            if ~isempty(trialRecords) && length(trialRecords)>1 % added length check because now we get trialRecords(end) (includes this trial)
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);
            %assign the correct answer to the target port (defined to be first file listed in the trialDistribution entry)
            pics=cell(totalPorts,2);
            pics(targetPorts,:)={ims{1,:}}; %note the ROUND parens -- ugly!

            % 12/9/08 - check that we have enough ims in our trialDistribution for the number of distractor ports
            if size(ims,1)<length(distractorPorts)
                error('trialDistribution has fewer entries than distractor ports')
            end 

            %randomly assign distractors
            % inds=2:length(responsePorts);
            % [garbage order]=sort(rand(1,length(responsePorts)-1));
            % changed 12/9/08 - select n random distractor images from imagelist, where n = number of distractor ports
            inds=2:size(ims,1);
            [garbage order]=sort(rand(1,size(ims,1)-1)); 
            inds=inds(order);

            for i=1:length(distractorPorts)
                dp=distractorPorts(i);
                pics(dp,:)={ims{inds(end),:}};
                inds=inds(1:end-1);
            end

            out = [pics{:,1}];
            details.imageDetails={pics{:,2}};

            fileNames='';
            for i=1:length(details.imageDetails)
                if ~isempty(details.imageDetails{i})
                    fileNames=[fileNames details.imageDetails{i}.name ' '];
                end
            end




            details.size=stimulus.size;
            details.rotation=stimulus.rotation;
            details.selectedSizes=stimulus.selectedSizes;
            details.selectedRotations=stimulus.selectedRotations;
            details.sizeyoked=stimulus.sizeyoked;

            details.trialDistribution = stimulus.trialDistribution;

            % center images over left/right ports (hardcoded portpos)
            portpos=linspace(0,width,totalPorts+2);
            portpos(1)=[];
            portpos(end)=[];
            for i=1:size(pics,1)
                if ~isempty(pics{i,1})
                    pics{i,2}=[portpos(i)-floor(size(pics{i,1},2)/2) portpos(i)+floor(size(pics{i,1},2)/2)-1];
                end
            end
            stimulus.images=pics;
            % details.images=stimulus.images; % dont store full image - takes up too much space

            % 1/22/09 - expert mode
            if strcmp(type,'expert')
                stim=details;
                stim.height=height;
                stim.width=width;
                stim.floatprecision=0;
            end

            discrimStim=[];
            discrimStim.stimulus=stim;
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

            if details.correctionTrial;
                text='correction trial!';
            else
                d=getDist(stimulus);
                text=sprintf('trial type %d (%g%%) (%s)',ind,round(100*d(ind)),fileNames);
            end
        end
        
        function s=decache(s)
            s.cache={};
            s.images={};
        end
        
        function d=display(s)
            d=['images loaded from ' doubleSlashes(s.directory) '\n'];
            d=sprintf(d);
        end
        
        function [doFramePulse expertCache dynamicDetails textLabel i dontclear indexPulse] = ...
    drawExpertFrame(stimulus,stim,i,phaseStartTime,totalFrameNum,window,textLabel,destRect,...
    filtMode,expertCache,ifi,scheduledFrameNum,dropFrames,dontclear,dynamicDetails)
            % implements expert mode for images - calls PTB drawing functions directly, leaving drawText and drawingFinished to stimOGL
            %
            % state.destRect
            % state.floatprecision
            % state.filtMode
            % state.window
            % state.img
            %
            % stimManager.selectedSizes
            % stimManager.selectedRotations

            indexPulse=false;

            % increment i
            if dropFrames
                i=scheduledFrameNum;
            else
                i=i+1;
            end
            doFramePulse=true;
            floatprecision=0;

            % % try simple thing for now
            % imagestex=Screen('MakeTexture',state.window,state.img,0,0,state.floatprecision);
            % 
            % % Draw images texture, rotated by "rotation":
            % newDestRect=state.destRect*stimManager.selectedSize;
            % Screen('DrawTexture', state.window, imagestex,[],newDestRect, ...
            %     stimManager.selectedRotations, state.filtMode);
            Screen('FillRect', window, 0);
            Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE); % necessary to do the transparency blending

            imgs=stimulus.images;
            for j=1:size(imgs,1) % for each actual image, not the entire screen
                if ~isempty(imgs{j,1})
                    % if not empty, then rotate and draw
                    imgToProcess=imgs{j,1};
                    % rotate
                    imagetex=Screen('MakeTexture',window,imgToProcess,0,0,floatprecision);

                    % get img bounds in terms of normalized 0-1, then apply destRect
                    destHeight=destRect(4)-destRect(2);
                    destWidth=destRect(3)-destRect(1);
                    normImg=[imgs{j,2}(1) 0 imgs{j,2}(2) stim.height];
                    normImg=normImg ./ [stim.width stim.height stim.width stim.height];
                    thisDestRect=[destWidth*normImg(1)+destRect(1) destHeight*normImg(2)+destRect(2)...
                        destWidth*normImg(3)+destRect(1) destHeight*normImg(4)+destRect(2)];
                    % do image scaling now
                    thisDestHeight=thisDestRect(4)-thisDestRect(2)+1;
                    newHeight=thisDestHeight*stimulus.selectedSizes(j);
                    deltaHeight=(thisDestHeight-newHeight)/2;

                    thisDestWidth=thisDestRect(3)-thisDestRect(1)+1;
                    newWidth=thisDestWidth*stimulus.selectedSizes(j);
                    deltaWidth=(thisDestWidth-newWidth)/2;

                    newDestRect=[thisDestRect(1)+deltaWidth thisDestRect(2)+deltaHeight thisDestRect(3)-deltaWidth thisDestRect(4)-deltaHeight];
                    % draw
                    Screen('DrawTexture',window,imagetex,[],newDestRect,stimulus.selectedRotations(j),filtMode);
                    % clear imagetex from vram
                    Screen('Close',imagetex);
                end
            end

            % disable alpha blending (for text)
            Screen('BlendFunction',window,GL_ONE,GL_ZERO);

        end % end function

        function [out scale] = errorStim(stimManager,numFrames)
            scale=0;

            out = uint8(double(intmax('uint8'))*(0*ones(1,1,numFrames))); %BLACK screen
            % flicker intmax('uint8')*uint8(rand(1,1,numFrames)>.5);
        end
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;

            nAFCindex = find(strcmp(LUTparams.compiledLUT,'nAFC'));
            if isempty(nAFCindex) || (~isempty(nAFCindex) && ~all([basicRecords.trialManagerClass]==nAFCindex))
                warning('only works for nAFC trial manager')
                out=struct;
            else
                try
                    stimDetails=[trialRecords.stimDetails];
                    [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);

                    ims={stimDetails.imageDetails};
                    [out.leftIm newLUT] = extractFieldAndEnsure(cellfun(@(x)x{1},ims,'UniformOutput',true),{'name'},{'typedVector','char'},newLUT);
                    [out.rightIm newLUT] = extractFieldAndEnsure(cellfun(@(x)x{3},ims,'UniformOutput',true),{'name'},{'typedVector','char'},newLUT);
            %         out.leftIm=ensureTypedVector(cellfun(@(x)x{1}.name,ims,'UniformOutput',false),'char');
            %         out.rightIm=ensureTypedVector(cellfun(@(x)x{3}.name,ims,'UniformOutput',false),'char');
                    out.suffices=nan*zeros(2,length(trialRecords)); %for some reason these are turning into zeros in the compiled file...  why?
                    % maybe add deck stuff here - might be added to stimDetails (as in v0.8)
                    % out.cardSelected
                    % out.cardsRemaining
                    % out.decksFinished
                catch ex
                    out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                    verifyAllFieldsNCols(out,length(trialRecords));
                    return
                end

                % 12/15/08 - now we have the trialDistribution in stimDetails, so check that either leftIm or rightIm was a target,
                % and that the other one was a distractor in the same image list (in trialDistribution)
                if ~any(strcmp(out.leftIm,out.rightIm))
                    % leftIm and rightIm are not the same, now check that only one of them is a target
                    tds = {stimDetails.trialDistribution};
                    % for each trialDistribution, check that either the leftIm or rightIm is a target
                    leftImIsTarget=zeros(1,length(tds));
                    rightImIsTarget=zeros(1,length(tds));
                    for i=1:length(tds)
                        leftImIsTarget(i)=isATargetInTrialDistribution(out.leftIm{i},out.rightIm{i},tds{i});
                        rightImIsTarget(i)=isATargetInTrialDistribution(out.rightIm{i},out.leftIm{i},tds{i});
                    end
                    % now check the XOR of leftImIsTarget and rightImIsTarget (one of them must be the target)
                    if ~all(xor(leftImIsTarget,rightImIsTarget))
                        leftImIsTarget
                        out.leftIm
                        rightImIsTarget
                        out.rightIm
                        error('found a trial without a valid target image');
                    end
                    % check that the target/distractor based on trialDistribution and imageDetails matches basicRecords.targetPorts/distractorPorts
                    targetIsRight=logical(rightImIsTarget);
                    checkNafcTargets(targetIsRight,basicRecords.targetPorts,basicRecords.distractorPorts,basicRecords.numPorts);

                else
                    error('left and right images are equal');
                end

                % 1/2/09 - LUT-ize
                [indices newLUT] = addOrFindInLUT(newLUT, out.leftIm);
                out.leftIm = indices+LUTparams.lastIndex;
                [indices newLUT] = addOrFindInLUT(newLUT, out.rightIm);
                out.rightIm = indices+LUTparams.lastIndex;

                % we dont need this check ? 12/12/08
            %     if ~any(strcmp(out.leftIm,out.rightIm))
            %         %assume lower suffix is target and prefix is paintbrush_flashlight
            %         %to generalize this, need to have saved the constructor's image distribution argument in trialRecord.stimDetails
            %         prefix='paintbrush_flashlight';
            %         [a b]=textscan([out.leftIm{:}],[prefix '%d']);
            %         [c d]=textscan([out.rightIm{:}],[prefix '%d']);
            %         if b==length([out.leftIm{:}]) && d==length([out.rightIm{:}])
            %             out.suffices=[a{1} c{1}]';
            %             targetIsRight=a{1}>c{1};
            %             checkNafcTargets(targetIsRight,basicRecords.targetPorts,basicRecords.distractorPorts,basicRecords.numPorts);
            %         else
            %             unique(out.leftIm)
            %             warning('prefix wasn''t paintbrush_flashlight or suffix wasn''t number -- bailing on checking target')
            %         end
            %     else
            %         error('left and right images are equal')
            %     end
            end
            verifyAllFieldsNCols(out,length(trialRecords));

        end % end main function


        %% HELPER FUNCTION
        function out = isATargetInTrialDistribution(target, distractor, td)
            % returns the index of the trialDistribution in which target is the target image
            % also checks that if out~=0 (ie target is a target for the trialDistribution) that the distractor is a member of that td list
            out=0;
            for i=1:length(td)
                if strcmp(target,td{i}{1}{1}) % check against target in this list of the td
                    if out~=0
                        error('found image to be target in multiple trialDistribution lists');
                    else
                        out=i;
                        % check that distractor is in this td list
                        foundDistractor = ismember(distractor,td{i}{1});
                        if ~foundDistractor
                            error('found target image, but no corresponding distractor in trialDistribution list');
                        end
                    end
                end
            end

        end % end function
        
        function moreStim(stimManager,state)
            % implements expert mode for images - calls PTB drawing functions directly, leaving drawText and drawingFinished to stimOGL
            %
            % state.destRect
            % state.floatprecision
            % state.filtMode
            % state.window
            % state.img
            %
            % stimManager.selectedSizes
            % stimManager.selectedRotation

            % % try simple thing for now
            % imagestex=Screen('MakeTexture',state.window,state.img,0,0,state.floatprecision);
            % 
            % % Draw images texture, rotated by "rotation":
            % newDestRect=state.destRect*stimManager.selectedSize;
            % Screen('DrawTexture', state.window, imagestex,[],newDestRect, ...
            %     stimManager.selectedRotation, state.filtMode);
            Screen('FillRect', state.window, 0);
            Screen('BlendFunction', state.window, GL_SRC_ALPHA, GL_ONE); % necessary to do the transparency blending

            imgs=stimManager.images;
            for i=1:size(imgs,1) % for each actual image, not the entire screen
                if ~isempty(imgs{i,1})
                    % if not empty, then rotate and draw
                    imgToProcess=imgs{i,1};
                    % rotate
                    imagetex=Screen('MakeTexture',state.window,imgToProcess,0,0,state.floatprecision);
                    thisDestRect=state.destRect;
                    thisDestRect(3)=imgs{i,2}(2);
                    thisDestRect(1)=imgs{i,2}(1);
                    % do image scaling now
                    thisDestHeight=thisDestRect(4)-thisDestRect(2)+1;
                    newHeight=thisDestHeight*stimManager.selectedSizes(i);
                    deltaHeight=(thisDestHeight-newHeight)/2;

                    thisDestWidth=thisDestRect(3)-thisDestRect(1)+1;
                    newWidth=thisDestWidth*stimManager.selectedSizes(i);
                    deltaWidth=(thisDestWidth-newWidth)/2;

                    newDestRect=[thisDestRect(1)+deltaWidth thisDestRect(2)+deltaHeight thisDestRect(3)-deltaWidth thisDestRect(4)-deltaHeight];
                    % draw
                    Screen('DrawTexture',state.window,imagetex,[],newDestRect,stimManager.selectedRotation,state.filtMode);
                end
            end

            % disable alpha blending (for text)
            Screen('BlendFunction',state.window,GL_ONE,GL_ZERO);

        end % end function

        function out=stationOKForStimManager(stimManager,s)
            if isa(s,'station')
                shortest_img_list = Inf;
                for i=1:length(stimManager.trialDistribution)
                    list = stimManager.trialDistribution{i};
                    num_imgs = length(list{1});
                    if num_imgs < shortest_img_list
                        shortest_img_list = num_imgs;
                    end
                end
                out = getNumPorts(s)<=1+shortest_img_list;
            else
                error('need a station object')
            end
    
        end % end function
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case {'freeDrinks' 'nAFC' 'oddManOut'}
                        out=true;
                    otherwise
                        out=false;
                end
            else
                error('need a trialManager object')
            end
        end
        
        function d=getDist(s)
            d=zeros(1,length(s.trialDistribution));
            for i=1:length(s.trialDistribution)
                d(i)=s.trialDistribution{i}{2};
            end
            d=d/sum(d);
        end
        
        function [d n]=getImageNames(s)
            n=[];
            names={};
            for i=1:length(s.trialDistribution)
                if isempty(n)
                    n=length(s.trialDistribution{i}{1});
            % 12/9/08 - do we need this error check?
            %     elseif n~=length(s.trialDistribution{i}{1})
            %         error('due to caching of scaled images, all trial entries in distribution must specify same number of images')
                end
                for j=1:length(s.trialDistribution{i}{1})
                    names{end+1} = s.trialDistribution{i}{1}{j};
                end
            end
            d=unique(names); %guaranteed to be sorted
        end
        
        function [im m alpha]=loadRemoteImage(s,name,ext)
            completed=false;
            nAttempts=0;
            maxAttempts=5;
            while ~completed
                nAttempts = nAttempts+1;
                try
                    [im m alpha]=imread(fullfile(s.directory,[name ext]));  %,'BackgroundColor',zeros(1,3)); this would composite against black and return empty alpha
                    completed=true;
                catch ex
                    %expect remote reads to fail cuz of windows networking/file sharing bug
                    pauseDur = rand+nAttempts-1; %linearly increase, but be nondeterministic
                    fprintf('attempt %d: failed to read %s, trying again in %g secs\n',nAttempts,fullfile(s.directory,[name ext]),pauseDur)
                    disp(['CAUGHT ERROR: ' getReport(ex,'extended')])

                    if nAttempts>maxAttempts
                        [nAttempts maxAttempts]
                        error('exceeded maxAttempts')
                    end

                    beep %feedback when ptb screen is up -- ratrix can appear to be dead for long periods without this -- better would be screen output, but that requries some rearchitecting
                    pause(pauseDur);
                end

            end
        end
        
        function [image deltas]=prepareImages(ims,alphas,screenSize,threshPct,pctScreenFill,backgroundcolor, normalizeHistograms,selectedSizes,selectedRotation)
%[image deltas]=prepareImages(ims,alphas,screenSize,threshPct,pctScreenFill,[backgroundcolor],[normalizeHistograms],[selectedSizes],[selectedRotation])
%INPUTS
% ims                   cell array of image matrices, any real numeric type, no restrictions on values
% screenSize
% threshPct
% pctScreenFill         
% backgroundcolor       uint8, default black
% normalizeHistograms	default true
%OUTPUTS
% image                 cell array of prepared images, can be horizontally concatenated
% deltas                ratio errors in area normalization (imresize does not work sub-pixel)
%
% 12/15/08 - fli added static-mode rotation/scaling

if ~exist('backgroundcolor','var')
    backgroundcolor=uint8(0);
elseif ~isa(backgroundcolor,'uint8')
    error('backgroundcolor must be uint8')
end

if ~exist('normalizeHistograms','var')
    normalizeHistograms=true;
end
if ~exist('selectedSizes','var')
    selectedSizes=ones(1,length(ims));
end
if ~exist('selectedRotation','var')
    selectedRotation=0;
end


%%%%%%%%%%%%%%%%%%%%%%%%
% 12/15/08 - do imrotate
for i=1:length(ims)
    ims{i} = imrotate(ims{i},-selectedRotation); % negative of selectedRotation because PTB uses clockwise orientation, whereas imrotate uses CCW
    alphas{i} = imrotate(alphas{i},-selectedRotation);
end

%%%%%%%%%%%%%%%%%%%%%%%%
maxPixel=0;
subjects={};
areas=[];
for i=1:length(ims)
    if ~isempty(ims{i})
        ims{i}=double(ims{i});
        if all(size(alphas{i})==size(ims{i})) && isinteger(alphas{i}) && all(alphas{i}(:)>=0) && all(alphas{i}(:)<=intmax('uint8')) % && max(alphas{i}(:))>200 %why did i think i needed this?
            ims{i}=(double(alphas{i})/double(intmax('uint8'))).*ims{i}; %essentially composites alpha against a black background
        else
            size(alphas{i})
            size(ims{i})
            isinteger(alphas{i})
            all(alphas{i}(:)>=0)
            all(alphas{i}(:)<=intmax('uint8'))
            max(alphas{i}(:))>200
            error('unexpected alpha')
        end

        imax=max(ims{i}(:));
        maxPixel=max(maxPixel,imax);
        %alphas{i}=alphas{i}>0;

        [subjects{i} areas(i) alphas{i}]=cropSubject(ims{i},alphas{i},imax*threshPct,uint32(floor(pctScreenFill.*screenSize./[1 length(ims)])));
    else
        subjects{i}=[];
        areas(i)=0;
    end
end


'equalizing areas'
[equalized deltas alphas]=equalizeAreas(subjects,alphas,areas,maxPixel,threshPct);



for i=1:length(equalized)
    size(equalized{i})


end

if normalizeHistograms
    'equalizing hists'
    equalized=equalizeHistograms(equalized,maxPixel);
    'computed'
end
% figure
% subplot(2,1,1)
% doHists(subjects,maxPixel,'originals');
% subplot(2,1,2)
% doHists(equalized,maxPixel,'equalized');

%need black background for two reasons -- don't want to saturate out the
%visual system and don't want aspect ratio of boudning box to be
%discriminable

%original=alignImages(subjects,screenSize,0,0);
image=alignImages(equalized,screenSize,backgroundcolor,backgroundcolor);
%figure
%imshow(image)
%figure
%imshow(original)

%image=[image;original];

%figure
%imshow(medfilt2(image));

%image=medfilt2(image);

end

    function [images deltas alphas]=equalizeAreas(images,alphas,areas,bgColor,threshPct)
        method='ratio';
        maxLoops=30;
        deltas=cell(1,length(images));
        target=min(areas(~cellfun(@isempty,images)));
        for i=1:length(images)
            if ~isempty(images{i})
                if areas(i)>target %had to switch to shrinking rather than growing, cuz otherwise can exceed screen size.  this is cuz images typically already cropped and zoomed to max size for screen, any increase due to an area adjustment can easily exceed this.

                    %images{i}(isnan(images{i}))=bgColor; %may still be necessary for pixel method?
                    switch method
                        case 'pixel'
                            n=1;
                            last=0;
                            verts={};
                            horizs={};
                            while any(last(end,:)<max(areas)) %need to change this to shrinking!
                                %n
                                verts{n}=imresize(images{i},size(images{i})+[1 nan]*n);
                                horizs{n}=imresize(images{i},size(images{i})+[nan 1]*n);
                                'should error now cuz calling cropSubject with empty alpha -- haven''t updated this code!'
                                [verts{n} last(n,1)]=cropSubject(verts{n},[],bgColor*threshPct);
                                [horizs{n} last(n,2)]=cropSubject(horizs{n},[],bgColor*threshPct);
                                n=n+1;
                            end
                            last=last-max(areas);
                            best=min(last(:));
                            [r c]=ind2sub(size(last),find(last==best));
                            switch c(1)
                                case 1
                                    images{i}=verts{r(1)};
                                case 2
                                    images{i}=horizs{r(1)};
                                otherwise
                                    error('should never happen')
                            end
                        case 'ratio'
                            clear temp
                            clear tempAlpha

                            tolerance=.0001;
                            factorRange=[0 2*target/areas(i)];
                            delta=10*tolerance;
                            m=1;
                            bestBigger={};
                            bestSmaller={};
                            while abs(delta)>tolerance && m<maxLoops
                                beep %feedback when ptb screen is up -- ratrix can appear to be dead for long periods without this -- better would be screen output, but that requries some rearchitecting
                                
                                factor=mean(factorRange);

                                factorRange
                                target
                                areas

                                temp=uint8(images{i});%sets nans to zeros, plus imresize exceeds dynamic range on double input, and is much slower
                                temp=imresize(temp,factor);
                                tempAlpha=imresize(alphas{i},size(temp));
                                temp=double(temp);
                                [temp areas(i)]=cropSubject(temp,tempAlpha,bgColor*threshPct);

                                delta=(areas(i)/target)-1;
                                if delta>0
                                    factorRange(2)=factor;
                                    if isempty(bestBigger) || bestBigger{1}>delta
                                        bestBigger{1}=delta;
                                        bestBigger{2}=size(temp);
                                        bestBigger{3}=tempAlpha;
                                        bestBigger{4}=temp;
                                    end
                                else
                                    factorRange(1)=factor;
                                    if isempty(bestSmaller) || bestSmaller{1}<delta
                                        bestSmaller{1}=delta;
                                        bestSmaller{2}=size(temp);
                                        bestSmaller{3}=tempAlpha;
                                        bestSmaller{4}=temp;
                                    end
                                end

                                'temp size'
                                [size(temp) areas(i)]

                                %resize by fractions that don't change the image
                                %size doesn't change the number of non-nan pixels,
                                %even when passing doubles to resize -- so can't
                                %get perfect match :(   (thought this used to work)
                                %but anyway, that means we don't have to go to
                                %maxLoops
                                if ~isempty(bestBigger) && ~isempty(bestSmaller) && (all(bestBigger{2}-bestSmaller{2}==[0 1]) || all(bestBigger{2}-bestSmaller{2}==[1 0]))
                                    if bestBigger{1}>abs(bestSmaller{1})
                                        delta = bestSmaller{1};
                                        tempAlpha=bestSmaller{3};
                                        temp=bestSmaller{4};
                                    else
                                        delta = bestBigger{1};
                                        tempAlpha=bestBigger{3};
                                        temp=bestBigger{4};
                                    end
                                    'stopping early'
                                    break
                                end

                                m=m+1;
                            end
                            if abs(delta)>tolerance
                                warning('area matching didn''t converge - delta is %g', delta)
                            end
                            alphas{i}=tempAlpha;
                            deltas{i}=delta;
                            images{i}=temp;
                        otherwise
                            error('bad method')
                    end
                elseif areas(i)<target
                    error('found a non-empty image with area less than the target, but target should be smallest non-empty area')
                end
            end
        end
    end


    function [subject area alpha]=cropSubject(image,alpha,thresh,targetDims)

        subject=nanBackground(image,alpha,thresh);

        crop=~isnan(subject);
        sides=sum(crop);
        topAndBottom=sum(crop');
        subject=subject(min(find(topAndBottom)):max(find(topAndBottom)),min(find(sides)):max(find(sides)));
        alpha=    alpha(min(find(topAndBottom)):max(find(topAndBottom)),min(find(sides)):max(find(sides)));

        if exist('targetDims','var') && ~isempty(subject)
            if isvector(targetDims) && length(targetDims)==2 && isinteger(targetDims) && all(targetDims>0)
                %subject(isnan(subject))=0;
                subject=uint8(subject); %will turn nans to zeros, should check bit depth is 8, seems to be necessary to not have doubles or imresize goes outside dynamic range

                subjectTaller = imresize(subject, [double(targetDims(1)) nan]);

                if any(size(subjectTaller)>targetDims)
                    subjectWider = imresize(subject, [nan double(targetDims(2))]);
                    if any(size(subjectWider)>targetDims)
                        error('resizing didn''t work')
                    else
                        subject=subjectWider;
                    end
                else
                    subject=subjectTaller;
                end

                if any(subject(:)>intmax('uint8')) || any(subject(:)<0)
                    error('imresize exceeded dynamic range')
                end

                subject=double(subject);

                alpha=imresize(alpha,size(subject));
                subject=nanBackground(subject,alpha,thresh);
            else
                error('bad targetDims')
            end
        end

        area=sum(~isnan(subject(:)));



        % imshow(uint8(subject));
        % class(subject)
        % [min(subject(:)) max(subject(:))]
        % sum(isnan(subject(:)))/prod(size(subject))
        % 'this is subj4'
        % pause
        %
        % imshow(alpha);
        % class(alpha)
        % [min(alpha(:)) max(alpha(:))]
        % 'this is alpha'
        % pause

    end

    function image=nanBackground(image,alpha,thresh)
        if isempty(alpha) %|| true %this true is just temporary, see else clause
            mask=image>=thresh;
            background=bwselect(mask,[1 1 size(mask,2) size(mask,2)],[1 size(mask,1) 1 size(mask,1)],4);
            error('empty alpha -- no longer supported!')
        else %for some reason this is causing the area equalization to get bigger than the screen size every few trials
            %until i can figure this out, we don't use alpha to determine background
            if all(size(image)==size(alpha))
                background = alpha==0;
            else
                error('image and alpha not same size')
            end
        end
        image(background)=nan;
    end


    function doHists(images,maxPixel,desc)
        bins=0:maxPixel;
        for i=1:length(images)
            pic=images{i}(:);
            pic=pic(~isnan(pic));
            counts(i,:)=hist(pic(:),bins);
            names{i}=sprintf('image %d',i);
        end

        plot(bins,counts')
        legend(names)
        title(desc)
        xlabel('pixel value')
        ylabel('frequency')
    end

    function image=alignImages(images,screenSize,insetColor,backgroundColor)

        for i=1:length(images)
            [heights(i) widths(i)]=size(images{i});
        end

        [shortestFirst order]=sort(heights);
        tallest = heights(order(end));

        [thinestFirst order]=sort(widths);
        widest=widths(order(end));

        if isempty(screenSize)
            screenSize=[tallest length(images)*widest];
        end

        tallest
        widest

        backgroundSize=[screenSize(1),floor(screenSize(2)/length(images))];
        image=[];
        for i=1:length(images)
            pic=centerImageInBackground(images{i},insetColor,[tallest widest]);
            size(pic)
            backgroundSize
            image=[image centerImageInBackground(pic,backgroundColor,backgroundSize)];

            %subplot(length(images)+1,1,i)
            %hist(double(pic(:)),0:255)
        end
        %subplot(length(images)+1,1,length(images)+1)
        %hist(double(image(:)),0:255)
        %pause
    end


    function images=equalizeHistograms(images,maxPixel)
        method = 'edf';

        %everything here is too low contrast -- here's a better idea:
        %find the distributions of the images and crosscorrelate them to align them
        %(can't just average cuz you'd get a multimodal thing)
        %then scale the result to max contrast

        %actually, uniform is OK

        dist='uniform';
        allData=[];
        for i=1:length(images)
            if ~isempty(images{i})
                imdata{i}=round(images{i}(:));
                [imVals{i} inds{i}]=sort(imdata{i});
                imdata{i}=imdata{i}(~isnan(imdata{i}));
                counts(i)=length(imdata{i});
                [means(i) contrasts(i)]=normfit(imdata{i});
                allData=[allData imdata{i}'];
            end
        end

        for i=1:length(images)
            if ~isempty(images{i})
                vals=.5+(0:maxPixel);
                switch dist
                    case 'gaussian'
                        targetDist=round(diff([0 counts(i)*normcdf(vals,maxPixel/2,mean(contrasts))]));
                        targetDist(end)=targetDist(1); %account for the (symmetric) mass in the tails...

                        %this method wasn't integrting properly
                        %targetDist=round(counts(i)*normpdf(vals,maxPixel/2,mean(contrasts)));
                        %targetDist([1 end])=round(counts(i)*normcdf(0,maxPixel/2,mean(contrasts))); %account for the (symmetric) mass in the tails...

                        %[sum(targetDist) counts(i)]

                    case 'gamma'
                        g=gamfit(allData);
                        targetDist=round(diff([0 counts(i)*gamcdf(vals,g(1),g(2))]));
                        targetDist(end)=targetDist(end)+counts(i)-sum(targetDist); %clip the top
                    case 'uniform'
                        targetDist=round(repmat(counts(i)/length(vals),1,length(vals)));
                        targetDist(end)=targetDist(end)+counts(i)-sum(targetDist); %account for rounding error

                        counts(i)
                        sum(targetDist)

                    otherwise
                        error('bad dist')
                end


                switch method
                    case 'ipt'
                        %would like to use histeq in image processing toolbox -- probably faster
                        %BUT it cannot ignore the background (no nan or alpha input) and doesn't guarantee an exact histogram match
                        %this demo code ignores targetDist shape -- converts to uniform dist (gives higher contrast)

                        images{i}=uint8(images{i}); %removes nans, histeq doesn't seem to like double input
                        images{i} = histeq(images{i}, repmat(floor(counts(i)/length(targetDist)),1,length(targetDist)));
                        images{i}=double(images{i});

                    case 'edf'

                        temp=nan*zeros(size(images{i}));

                        uniques=unique(imVals{i});
                        uniques=uniques(~isnan(uniques));
                        for valNum=1:length(uniques)
                            valNum
                            scrambleInds=find(imVals{i}==uniques(valNum));
                            [garbage scramble]=sort(rand(1,length(scrambleInds)));
                            targets=inds{i}(scrambleInds);
                            inds{i}(scrambleInds)=targets(scramble);
                        end

                        currVal=1;
                        for valNum=1:length(vals)
                            temp(inds{i}(currVal:min(counts(i),currVal+targetDist(valNum)-1)))=vals(valNum);
                            currVal=currVal+targetDist(valNum);
                        end
                        images{i}=temp;

                    otherwise
                        error('bad method')
                end
            end
        end
    end

    function image=centerImageInBackground(im,backgroundColor,sz)

        if(any(sz<size(im)))
            sz
            size(im)
            error('supplied screen size not big enough')
        end

        im(isnan(im))=backgroundColor;
        [height width]=size(im);
        heightDiff=sz(1)-height;
        widthDiff=sz(2)-width;
        topBuffer=floor(heightDiff/2);
        bottomBuffer=ceil(heightDiff/2);
        leftBuffer=floor(widthDiff/2);
        rightBuffer=ceil(widthDiff/2);
        topBuffer=backgroundColor*uint8(ones(topBuffer,leftBuffer+width+rightBuffer));
        bottomBuffer=backgroundColor*uint8(ones(bottomBuffer,leftBuffer+width+rightBuffer));

        % sz
        %
        % size(topBuffer)
        % size(backgroundColor*uint8(ones(height,leftBuffer)))
        % size(im)
        % size(backgroundColor*uint8(ones(height,rightBuffer)))
        % size(bottomBuffer)

        image=[topBuffer; backgroundColor*uint8(ones(height,leftBuffer)) uint8(im) backgroundColor*uint8(ones(height,rightBuffer)); bottomBuffer];
    end

        %my algorithm is cool, but matlab's is faster :(
        %images{i}=replaceContiguousPixelsAndCrop(images{i},[1 1; 1 size(images{i},2); size(images{i},1) size(images{i},2); size(images{i},1) 1],nan);
        function image=replaceContiguousPixelsAndCrop(image,pts,replace)
            while ~isempty(pts)
                ptInds=sub2ind(size(image),pts(:,1),pts(:,2));
                targetColor=unique(image(ptInds));
                if ~isscalar(targetColor)
                    error('pts aren''t all same color')
                end
                image(ptInds)=replace;
                newpts=[];
                for i=1:size(pts,1)
                    pt=pts(i,:);
                    neighbors=[-1 0;1 0;0 1;0 -1];
                    neighbors=repmat(pt,size(neighbors,1),1)+neighbors;
                    newpts=[newpts;neighbors(all((neighbors>0 & neighbors<=repmat(size(image),size(neighbors,1),1))'),:)];
                    newpts=unique(newpts,'rows');
                end
                pts=newpts(image(sub2ind(size(image),newpts(:,1),newpts(:,2)))==targetColor,:);
            end
            boundaries=image~=replace;
            sides=sum(boundaries);
            topAndBottom=sum(boundaries');
            image=image(min(find(topAndBottom)):max(find(topAndBottom)),min(find(sides)):max(find(sides)));
        end

        function preprocess
            loc='\\132.239.158.169\resources\paintbrush_flashlight\paintbrush_flashlight\';
            d=dir([loc '*.png']);
            imNames={d.name};

            for i=1:length(imNames)
                [im{i} garbage alpha{i}]=imread([loc imNames{i}]);

                if length(size(im{i}))==3
                    'im was rgb'
                    im{i}=uint8(floor(sum(im{i},3)/3)); %convert to greyscale
                end
            end

            [out deltas]=prepareImages(im,alpha,[1200 1920*length(imNames)/2],.95,.9);

            outDir='C:\Documents and Settings\rlab\Desktop\preprocessedImages\';
            mkdir(outDir);
            imWidth=size(out,2)/length(imNames);
            for i=1:length(imNames)
                colRange=(1:imWidth)+(i-1)*imWidth;
                im=out(:,colRange);
                imwrite(im,[outDir imNames{i}],'png');
                [t1 t2 t3]=imread([outDir imNames{i}]);
                if ~isempty(t3)
                    imshow(t3);
                    error('saved alpha not empty')
                end
                if ~all(t1(:)==im(:))
                    imshow([im t1 im-t1])
                    error('saved not equal to read')
                end
            end
        end

        function [ims alphas names ext n]=validateImages(s)
            ext='.png';
            ims={};
            alphas={};
            names={};

            [d n]=getImageNames(s);

            tic
            for i=1:length(d)

                name=d{i};

                [im m alpha]=loadRemoteImage(s,name,ext);

                if ~strcmp(class(im),'uint8') || ~ismember(length(size(im)),[2 3]) || (length(size(im))==3 && size(im,3)~=3) || isempty(alpha) || ~isempty(m)
                    size(im)
                    error('images must be png with alpha channel - unexpected image format for %s: %s',fullfile(s.directory,[name ext]),class(im))
                end

                if length(size(im))==3
                    im=uint8(floor(sum(im,3)/3)); %convert to greyscale
                end

                names{end+1}=name;
                ims{end+1}=im;
                alphas{end+1}=alpha;
            end

            disp(sprintf('\nwasted %g secs loading %d images\n',toc,i))
        end
        
        
    end
    
end


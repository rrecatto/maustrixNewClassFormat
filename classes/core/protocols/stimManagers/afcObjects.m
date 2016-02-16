classdef afcObjects
 
    properties
        shape = [];
        objSize = [];
        orientation = [];
        contrast = [];
        maxDuration = Inf;
        location = [];
        normalizationMethod = 'none';
        backgroundLuminance = [];
        invertedContrast = [];
        mask = [];
        drawMode = 'cache'; % or 'expert'
        objectType = 'blocked'; % or 'edged'
        params = [];
        thresh = 0;

        image = []; % used for expert mode

        LUT =[];
        LUTbits=0;

        doCombos=true;
        doPostDiscrim = false;
    end
    
    methods
        function s = afcObjects(varargin)
            % AFCOBJECTS  class constructor.
            % 
            % s = afcObjects(shapes,sizes,orientations,contrasts,locations,maxDuration,normalizationMethod,backgroundLuminance,invertedContrast,mask,drawMode,params,'other inputs to stim Manager')
            % Each of the following arguments is a {[],[]} cell, each element is a
            % vector of size N

            % shapes -{{'triangle','square','pentagon','hexagon','octagon','circle'},{'triangle','square','pentagon','hexagon','octagon','circle'}}
            % sizes - horizontal fraction
            % orientations - in radians
            % contrasts - [0,1] (michelson contrast)
            % maxDuration - in seconds (can only be one number)
            % locations - belongs to [0,1]
            %           OR: a RFestimator object that will get an estimated location when needed
            %           OR: a location distribution object
            % normalizationMethod - 'equalizeLuminanceByChangingContrast','equalizeLuminanceByChangingSize', or 'none'
            % backgroundLuminance - [0<backgroundLuminance<1]
            % thresh - >0
            % doCombos

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s = class(s,'afcObjects',stimManager());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'afcObjects'))
                        s = varargin{1};
                    else
                        error('Input argument is not a gratings object')
                    end
                case 19
                    % create object using specified values
                    shape = varargin{1};
                    objSize = varargin{2};
                    orientation = varargin{3};
                    contrast = varargin{4};
                    maxDuration = varargin{5};
                    location = varargin{6};
                    normalizationMethod = varargin{7};
                    backgroundLuminance = varargin{8};
                    invertedContrast = varargin{9};
                    drawMode = varargin{10};
                    objectType = varargin{11};
                    mask = varargin{12};
                    thresh = varargin{13};
                    maxWidth = varargin{14};
                    maxHeight = varargin{15};
                    scaleFactor = varargin{16};
                    interTrialLuminance = varargin{17};
                    doCombos = varargin{18};
                    doPostDiscrim=varargin{19};


                    % doCombos
                    if islogical(doCombos)
                        s.doCombos = doCombos;
                    else
                        doCombos
                        error('doCombos not in the right format');
                    end

                    % shape
                    allowedShapes = {'triangle','square','pentagon','hexagon','octagon','circle'};
                    if iscell(shape) && length(shape)==2 && ...
                            iscell(shape{1}) && all(ismember(shape{1},allowedShapes)) && iscell(shape{2}) && all(ismember(shape{2},allowedShapes))
                        s.shape = shape;
                        L1 = length(shape{1});
                        L2 = length(shape{2});
                    else
                        shape
                        error('shape not in the right format');
                    end

                    % size
                    if iscell(objSize) && length(objSize)==2 && ...
                            isnumeric(objSize{1}) && ...
                            isnumeric(objSize{2})
                        s.objSize = objSize;
                        if ~doCombos && length(objSize{1})~=L1 && length(objSize{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    elseif iscell(objSize) && length(objSize) == 2 & ...
                            iscell(objSize{1}) && all(cellfun(@isstruct,objSize{1})) && ...
                            iscell(objSize{2}) && all(cellfun(@isstruct,objSize{2}))
                        s.size = objSize;
                    else
                        objSize
                        error('objSize not in the right format');
                    end

                    % orientation
                    if iscell(orientation) && length(orientation)==2 && ...
                            isnumeric(orientation{1}) && all(~isinf(orientation{1})) && isnumeric(orientation{2}) &&  all(~isinf(orientation{2}))
                        s.orientation = orientation;
                        if ~doCombos && length(orientation{1})~=L1 && length(orientation{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        orientation
                        error('orientation not in the right format');
                    end

                    % contrast
                    if iscell(contrast) && length(contrast)==2 && ...
                            isnumeric(contrast{1}) && all(contrast{1}>=0) && all(contrast{1}<=1) && isnumeric(contrast{2}) && all(contrast{2}>=0) && all(contrast{2}<=1)
                        s.contrast = contrast;
                        if ~doCombos && length(contrast{1})~=L1 && length(contrast{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        contrast
                        error('contrast not in the right format');
                    end

                    % maxDuration
                    if iscell(maxDuration) && length(maxDuration)==2 && ...
                            isnumeric(maxDuration{1}) && all(maxDuration{1}>0) && isnumeric(maxDuration{2}) && all(maxDuration{2}>0)
                        s.maxDuration = maxDuration;
                        if ~doCombos && length(maxDuration{1})~=L1 && length(maxDuration{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        maxDuration
                        error('maxDuration not in the right format');
                    end

                    % location
                    if iscell(location) && length(location)==2 && ...
                            isnumeric(location{1}) && all(all((location{1}>=0))) && size(location{1},2)==2 && ...
                            isnumeric(location{2}) && all(all((location{2}>=0))) && size(location{2},2)==2                
                        s.location = location;
                        if ~doCombos && length(location{1})~=L1 && length(location{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    elseif iscell(location) && length(location) == 2 && ...
                            isa(location,'locationObj') && isa(location,'locationObj')
                        s.location = location;
                    else
                        location
                        error('location not in the right format');
                    end

                    % normalizationMethod
                    if ischar(normalizationMethod) && ismember(normalizationMethod,{'equalizeLuminance' , 'none'})
                        s.normalizationMethod = normalizationMethod;
                    else
                        normalizationMethod
                        error('normalizationMethod not the right format');
                    end

                    % backgroundLuminance
                    if iscell(backgroundLuminance) && length(backgroundLuminance)==2 && ...
                            isnumeric(backgroundLuminance{1}) && all(backgroundLuminance{1}>=0) && all(backgroundLuminance{1}<=1) && ...
                            isnumeric(backgroundLuminance{2}) && all(backgroundLuminance{2}>=0) && all(backgroundLuminance{2}<=1)
                        s.backgroundLuminance = backgroundLuminance;
                    else
                        backgroundLuminance
                        error('backgroundLuminance not the right format');
                    end

                    % invertedContrast
                    if iscell(invertedContrast) && length(invertedContrast)==2 && ...
                            islogical(invertedContrast{1}) && islogical(invertedContrast{2})
                        s.invertedContrast = invertedContrast;
                    else
                        invertedContrast
                        error('invertedContrast not the right format');
                    end

                    % mask
                    if iscell(mask) && length(mask)==2
                        s.mask = mask;
                    else
                        mask
                        error('mask not the right format');
                    end

                    % drawMode
                    if iscell(drawMode) && length(drawMode)==2
                        s.drawMode = drawMode;
                    else
                        drawMode
                        error('drawMode not the right format');
                    end

                    % objectType
                    if iscell(objectType) && length(objectType)==2
                        s.objectType = objectType;
                    else
                        objectType
                        error('objectType not the right format');
                    end

                    % thresh
                    if thresh>=0
                        s.thresh = thresh;
                    else
                        thresh
                        error('thresh not the right format');
                    end

                    % doPostDiscrim
                    if doPostDiscrim
                        % make sure that maxDuration is set to finite values
                        if any(isinf(maxDuration{1})) || any(isinf(maxDuration{2}))
                            error('cannot have post-discrim phase and infnite discrim phase. reconsider');
                        end
                        s.doPostDiscrim = true;
                    else
                        s.doPostDiscrim = false;
                    end
                    s = class(s,'afcObjects',stimManager(maxWidth,maxHeight,scaleFactor,interTrialLuminance));
                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end

        end
        
        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,interTrialStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =... 
    calcStim(stimulus,trialManager,allowRepeats,resolutions,displaySize,LUTbits,...
    responsePorts,totalPorts,trialRecords,compiledRecords, arduinoCONN)
            % see ratrixPath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)
            indexPulses=[];
            imagingTasks=[];

            trialManagerClass = class(trialManager);

            [LUT stimulus updateSM]=getLUT(stimulus,LUTbits);

            [junk, mac] = getMACaddress();
            switch mac
                case {'A41F7278B4DE','A41F729213E2','A41F726EC11C','A41F729211B1' } %gLab-Behavior rigs
                    [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
                case {'7845C4256F4C', '7845C42558DF'}
                    [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[50],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
                otherwise 
                    [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
            end

            if isnan(resolutionIndex)
                resolutionIndex=1;
            end

            scaleFactor=getScaleFactor(stimulus); % dummy value since we are phased anyways; the real scaleFactor is stored in each phase's stimSpec
            interTrialLuminance = getInterTrialLuminance(stimulus); 
            interTrialDuration = getInterTrialDuration(stimulus);

            details.pctCorrectionTrials=getPercentCorrectionTrials(trialManager); % need to change this to be passed in from trial manager
            details.bias = getRequestBias(trialManager);

            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            % target port selection
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);


            toggleStim=true; type='expert';
            dynamicMode = true; %false %true

            height = min(height,getMaxHeight(stimulus));
            width = min(width,getMaxWidth(stimulus));


            % choose stimulus
            if stimulus.doCombos
                % choose a random value for each
                if length(targetPorts)==1
                    stim = [];
                    if targetPorts == 1 % the first of the possible values
                        % shape
                        tempVar = randperm(length(stimulus.shape{1}));
                        stim.shape = stimulus.shape{1}{tempVar(1)};

                        % objSize
                        tempVar = randperm(length(stimulus.objSize{1}));
                        stim.objSize = stimulus.objSize{1}(tempVar(1));

                        % orientation
                        tempVar = randperm(length(stimulus.orientation{1}));
                        stim.orientation = stimulus.orientation{1}(tempVar(1));

                        % contrast
                        tempVar = randperm(length(stimulus.contrast{1}));
                        stim.contrast = stimulus.contrast{1}(tempVar(1));

                        % maxDuration
                        tempVar = randperm(length(stimulus.maxDuration{1}));
                        if ~ismac
                            stim.maxDuration = stimulus.maxDuration{1}(tempVar(1))*hz;
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = stimulus.maxDuration{1}(tempVar(1))*60;
                        end

                        % location
                        tempVar = randperm(size(stimulus.location{1},1));
                        stim.location = stimulus.location{1}(tempVar(1),:);

                        % backgroundLuminance
                        tempVar = randperm(length(stimulus.backgroundLuminance{1}));
                        stim.backgroundLuminance = stimulus.backgroundLuminance{1}(tempVar(1));

                        % invertedContrast
                        tempVar = randperm(length(stimulus.invertedContrast{1}));
                        stim.invertedContrast = stimulus.invertedContrast{1}(tempVar(1));

                        % objectType
                        tempVar = randperm(length(stimulus.objectType(1)));
                        stim.objectType = stimulus.objectType{1}{tempVar(1)};

                        stim.drawMode = stimulus.drawMode{1};
                    elseif targetPorts == 3% the second of the possible values
                        % shape
                        tempVar = randperm(length(stimulus.shape{2}));
                        stim.shape = stimulus.shape{2}{tempVar(1)};

                        % objSize
                        tempVar = randperm(length(stimulus.objSize{2}));
                        stim.objSize = stimulus.objSize{2}(tempVar(1));

                        % orientation
                        tempVar = randperm(length(stimulus.orientation{2}));
                        stim.orientation = stimulus.orientation{2}(tempVar(1));

                        % contrast
                        tempVar = randperm(length(stimulus.contrast{2}));
                        stim.contrast = stimulus.contrast{2}(tempVar(1));

                        % maxDuration
                        tempVar = randperm(length(stimulus.maxDuration{2}));
                        if ~ismac
                            stim.maxDuration = stimulus.maxDuration{2}(tempVar(1))*hz;
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = stimulus.maxDuration{2}(tempVar(1))*60;
                        end

                        % location
                        tempVar = randperm(size(stimulus.location{2},1));
                        stim.location = stimulus.location{2}(tempVar(1),:);

                        % backgroundLuminance
                        tempVar = randperm(length(stimulus.backgroundLuminance{2}));
                        stim.backgroundLuminance = stimulus.backgroundLuminance{2}(tempVar(1));

                        % invertedContrast
                        tempVar = randperm(length(stimulus.invertedContrast{2}));
                        stim.invertedContrast = stimulus.invertedContrast{2}(tempVar(1));

                        % objectType
                        tempVar = randperm(length(stimulus.objectType{2}));
                        stim.objectType = stimulus.objectType{2}(tempVar(1));

                        stim.drawMode = stimulus.drawMode{1};
                    else 
                        error('eh? should not come here at all')
                    end
                else
                    error('not geared for more than one target port. whats wrong??');
                end
            else
                if length(targetPorts)==1
                    if targetPorts == 1
                        tempVar = randperm(length(stimulus.shape{1}));
                        which = tempVar(1);
                        stim.shape = stimulus.shape{1}{which};
                        stim.objSize = stimulus.objSize{1}(which);
                        stim.orientation = stimulus.orientation{1}(which);
                        stim.contrast = stimulus.contrast{1}(which);
                        if ~ismac
                            stim.maxDuration = stimulus.maxDuration{1}(which)*hz;
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = stimulus.maxDuration{1}(which)*60;
                        end
                        stim.location = stimulus.location{1}(which,:);
                        stim.backgroundLuminance = stimulus.backgroundLuminance{1}(which);
                        stim.invertedContrast = stimulus.invertedContrast{1}(which);
                        stim.objectType = stimulus.objectType{1}(which);
                    elseif targetPorts == 3
                        tempVar = randperm(length(stimulus.shape{2}));
                        which = tempVar(1);
                        stim.shape = stimulus.shape{2}{which};
                        stim.objSize = stimulus.objSize{2}(which);
                        stim.orientation = stimulus.orientation{2}(which);
                        stim.contrast = stimulus.contrast{2}(which);
                        if ~ismac
                            stim.maxDuration = stimulus.maxDuration{2}(which)*hz;
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = stimulus.maxDuration{2}(which)*60;
                        end
                        stim.location = stimulus.location{2}(which,:);
                        stim.backgroundLuminance = stimulus.backgroundLuminance{2}(which);
                        stim.invertedContrast = stimulus.invertedContrast{2}(which);
                        stim.objectType = stimulus.objectType{2}(which);
                    else
                        error('eh? should not come here at all')
                    end
                else
                    error('not geared for more than one target port. whats wrong??');
                end
            end
            % normalizationMethod,mean,thresh,height,width,scaleFactor,interTrialLuminance
            stim.normalizationMethod=stimulus.normalizationMethod;
            stim.height=height;
            stim.width=width;
            stim.thresh=stimulus.thresh;
            stim.doCombos=stimulus.doCombos;
            details.chosenStim = stim;


            % lets make the images and store in stimulus....
            [imX imY] = meshgrid(1:width,1:height); 
            im = stim.backgroundLuminance*ones(size(imX));
            % {'triangle','square','pentagon','hexagon','octagon','circle'};
            switch stim.shape
                case 'triangle'
                    locX = stim.location(1)*width;
                    locY = stim.location(2)*height;
                    error('not yet!');
                case 'square'
                    locX = stim.location(1)*width;
                    locY = stim.location(2)*height;
                    L = stim.objSize*height;
                    im1 = ((imX-locX)>-L/2) & ((imX-locX)<L/2);
                    im2 = ((imY-locY)>-L/2) & ((imY-locY)<L/2);
                    im(im1 & im2) = 1;
                case 'circle'
                    locX = stim.location(1)*width;
                    locY = stim.location(2)*height;
                    L = stim.objSize*height;
                    im1 = ((imX-locX).^2+(imY-locY).^2)<=(L/2)^2;
                    im(im1) = 1;
            end
            stimulus.image = 255*im;

            [details, stim] = setupLED(details, stim, stimulus.LEDParams,arduinoCONN);

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

            postDiscrimStim = [];

            interTrialStim.duration = interTrialDuration;

            details.interTrialDuration = interTrialDuration;
            if details.correctionTrial;
                text='correction trial!';
            else
                text = '';
            end
        end
        
        function [doFramePulse, expertCache, dynamicDetails, textLabel, i, dontclear, indexPulse] = ...
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

            imgToProcess=stimulus.image;

            imagetex=Screen('MakeTexture',window,imgToProcess,0,0,floatprecision);
            % draw
            Screen('DrawTexture',window,imagetex);
            % clear imagetex from vram
            Screen('Close',imagetex);


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
            out = [];
            % error('not yet');
            % nAFCindex = find(strcmp(LUTparams.compiledLUT,'nAFC'));
            % if isempty(nAFCindex) || (~isempty(nAFCindex) && ~all([basicRecords.trialManagerClass]==nAFCindex))
            %     warning('only works for nAFC trial manager')
            %     out=struct;
            % else
            %     try
            %         stimDetails=[trialRecords.stimDetails];
            %         [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
            %         [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
            % 
            %         ims={stimDetails.imageDetails};
            %         [out.leftIm newLUT] = extractFieldAndEnsure(cellfun(@(x)x{1},ims,'UniformOutput',true),{'name'},{'typedVector','char'},newLUT);
            %         [out.rightIm newLUT] = extractFieldAndEnsure(cellfun(@(x)x{3},ims,'UniformOutput',true),{'name'},{'typedVector','char'},newLUT);
            %         out.suffices=nan*zeros(2,length(trialRecords)); %for some reason these are turning into zeros in the compiled file...  why?
            %     catch ex
            %         out=handleExtractDetailFieldsException(sm,ex,trialRecords);
            %         verifyAllFieldsNCols(out,length(trialRecords));
            %         return
            %     end
            % verifyAllFieldsNCols(out,length(trialRecords));
        end % end main function

        function s=fillLUT(s,method,linearizedRange,plotOn);
            %function s=fillLUT(s,method,linearizedRange [,plotOn]);
            %stim=fillLUT(stim,'linearizedDefault');
            %note: this calculates and fits gamma with finminsearch each time
            %might want a fast way to load the default which is the same each time
            %edf wants to migrate this to a ststion method  - this code is redundant
            %for each stim -- ACK!


            if ~exist('plotOn','var')
                plotOn=0;
            end

            useUncorrected=0;

            switch method
                case 'mostRecentLinearized'

                    method
                    error('that method for getting a LUT is not defined');
                case 'linearizedDefault'

                    %WARNING:  need to get gamma from measurements of ratrix workstation with NEC monitor and new graphics card 


                    LUTBitDepth=8;

                    %sample from lower left of triniton, pmm 070106
                        %sent=       [0      0.0667    0.1333    0.2000    0.2667    0.3333    0.4000    0.4667    0.5333  0.6000    0.6667    0.7333    0.8000    0.8667    0.9333    1.0000];
                        %measured_R= [0.0052 0.0058    0.0068    0.0089    0.0121    0.0167    0.0228    0.0304    0.0398  0.0510    0.065     0.080     0.097     0.117     0.139     0.1645];       
                        %measured_G= [0.0052 0.0053    0.0057    0.0067    0.0085    0.0113    0.0154    0.0208    0.0278  0.036     0.046     0.059     0.073     0.089     0.107     0.128 ];
                        %measured_B= [0.0052 0.0055    0.0065    0.0077    0.0102    0.0137    0.0185    0.0246    0.0325  0.042     0.053     0.065     0.081     0.098     0.116     0.138];  

                    %sample values from FE992_LM_Tests2_070111.smr: (actually logged them: pmm 070403) -used physiology graphic card
                        sent=       [0      0.0667    0.1333    0.2000    0.2667    0.3333    0.4000    0.4667    0.5333  0.6000    0.6667    0.7333    0.8000    0.8667    0.9333    1.0000];
                        measured_R= [0.0034 0.0046    0.0077    0.0128    0.0206    0.0309    0.0435    0.0595    0.0782  0.1005    0.1260    0.1555    0.189     0.227     0.268     0.314 ];
                        measured_G= [0.0042 0.0053    0.0073    0.0110    0.0167    0.0245    0.0345    0.047     0.063   0.081     0.103     0.127     0.156     0.187     0.222     0.260 ];
                        measured_B= [0.0042 0.0051    0.0072    0.0105    0.0160    0.0235    0.033     0.0445    0.0595  0.077     0.097     0.120     0.1465    0.176     0.208     0.244 ];

                        %oldCLUT = Screen('LoadNormalizedGammaTable', w, linearizedCLUT,1);
                case 'useThisMonitorsUncorrectedGamma'

                    LUTBitDepth=8;
                    numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID); 
                    ramp=[0:fraction:1];
                    grayColors= [ramp;ramp;ramp]';
                    %maybe ask for red / green / blue gun only
                    uncorrected=grayColors;
                    useUncorrected=1;

                case 'localCalibStore'
                    try
                        temp = load(fullfile(getRatrixPath,'monitorCalibration','tempCLUT.mat'));
                        uncorrected = temp.linearizedCLUT;
                        useUncorrected=1;
                    catch ex
                        disp('did you store local calibration details at all????');
                        rethrow(ex)
                    end

                case 'calibrateNow'

                    %[measured_R measured_G measured_B] measureRGBscale()
                    method
                    error('that method for getting a LUT is not defined');
                otherwise
                    method
                    error('that method for getting a LUT is not defined');
            end

            if useUncorrected
                linearizedCLUT=uncorrected;
            else
                linearizedCLUT=zeros(2^LUTBitDepth,3);
                if plotOn
                    subplot([311]);
                end
                [linearizedCLUT(:,1) g.R]=fitGammaAndReturnLinearized(sent, measured_R, linearizedRange, 2^LUTBitDepth,plotOn);

                if plotOn
                    subplot([312]);
                end
                [linearizedCLUT(:,2) g.G]=fitGammaAndReturnLinearized(sent, measured_G, linearizedRange, 2^LUTBitDepth,plotOn);

                if plotOn
                    subplot([313]);
                end
                [linearizedCLUT(:,3) g.B]=fitGammaAndReturnLinearized(sent, measured_B, linearizedRange, 2^LUTBitDepth,plotOn);
            end

            s.LUT=linearizedCLUT;
        end

        function s=flushLUT(s)
            %method to flush the look up table, see fillLUT

            s.LUT=[];   
            s.LUTbits=0;
        end
        
        function [out s updateSM]=getLUT(s,bits)
            if isempty(s.LUT) || s.LUTbits~=bits
                updateSM=true;
                s.LUTbits=bits;
                [a b] = getMACaddress;
                if ismember(b,{'7CD1C3E5176F',... balaji Macbook air
                        '180373337162',...
                        })
                    s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
                else
                    s=fillLUT(s,'localCalibStore');
                end

            else
                updateSM=false;
            end
            out=s.LUT;
        end
        
        function out=stationOKForStimManager(stimManager,s)
            out = true;
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

        
        
    end
    
end


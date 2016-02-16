classdef trialManager
    properties
        soundMgr = soundManager();
        reinforcementMgr = reinforcementManager();
        delayMgr = delayManager();
        description = '';
        frameDropCorner = {};
        dropFrames = false;
        saveDetailedFramedrops = false;
        requestPorts = 'center';
        showText = 'full';
        responseWindowMs = [0 Inf];
        percentCorrectionTrials = 0;
    end
    
    methods
        function t = trialManager(varargin)
            switch nargin
                case 0
                    %pass
                case 9
                    validateattributes(varargin{1},{'soundManager'},{'nonempty'});
                    t.soundMgr = varargin{1};
                    
                    validateattributes(varargin{2},{'reinforcementManager'},{'nonempty'});
                    t.reinforcementMgr = varargin{2};
                    
                    validateattributes(varargin{3},{'delayManager'},{'nonempty'})
                    t.delayMgr = varargin{3};
                    
                    validateattributes(varargin{4},{'boolean'},{'scalar'});
                    t.frameDropCorner = varargin{4};
                    
                    validateattributes(varargin{5},{'boolean'},{'scalar'})
                    t.dropFrames = varargin{5};
                    
                    assert(ismember(varargin{6},{'center','left','right','any'}))
                    t.requestPorts = varargin{6};
                    
                    validateattributes(varargin{7},{'boolean'},{'scalar'})
                    t.saveDetailedFramedrops = varargin{7};
 
                    validateattributes(varargin{8},{'boolean'},{'scalar'})
                    t.responseWindowMs = varargin{8};
                    
                    validateattributes(varargin{9},{'boolean'},{'scalar'})
                    t.showText = varargin{9};
                    
            end
        end
        
        function out=boxOKForTrialManager(t,b,r)
            validateattributes(b,{'box'},{'nonempty'});
            validateattributes(r,{'ratrix'},{'nonempty'});
            
            out=0;
            stations=getStationsForBoxID(r,getID(b));
            for i=1:length(stations)
                if stationOKForTrialManager(t,stations(i))
                    out=1;
                end
            end
        end
        
        function textures = cacheTextures(tm, strategy, stim, window, floatprecision)
            
            % Note that if finalScreenLuminance is blank (ie for phased stim), then it does not get loaded as a texture
            
            if ~(ischar(strategy) && strcmp(strategy,'expert')) && (floatprecision~=0 || ~strcmp(class(stim),'uint8'))
                error('expects floatprecision to be 0 and stim to be uint8 so that maketexture is fast')
            end
            
            textures=[];
            
            switch strategy
                case 'textureCache'
                    %load all frames into VRAM
                    
                    if ~isempty(stim) % necessary because size([],3)==1 stupidly enough
                        textures=zeros(1,size(stim,3));
                        for i=1:size(stim,3)
                            if window>=0
                                textures(i)=Screen('MakeTexture', window, squeeze(stim(:,:,i)),0,0,floatprecision); %need floatprecision=0 for remotedesktop
                            end
                        end
                    end
                    
                    if window>=0
                        
                        if false
                            % actually not recommended (tho doc makes it sound like a good idea)
                            % http://tech.groups.yahoo.com/group/psychtoolbox/message/9165
                            [resident texidresident] = Screen('PreloadTextures', window);
                            
                            if resident ~= 1
                                fprintf('error: some textures not cached');
                                find(texidresident~=1)
                            end
                        end
                    end
                    
                case 'noCache'
                    %pass
                case 'expert'
                    % no caching of textures should happen
                otherwise
                    error('unrecognized strategy')
            end
            
        end
        
        function out = checkPorts(tm,targetPorts,distractorPorts)
            out=true;
        end % end function
        
        function t=decache(t)
            t.soundMgr=decache(t.soundMgr);
        end
        
        function [floatprecision stim] = determineColorPrecision(tm, stim, strategy)
            
            if ~isempty(strategy) && strcmp(strategy, 'expert')
                floatprecision = []; % no default floatprecision for expert mode - override during drawExpertFrame or will throw error
            else
                floatprecision=0;
                if isreal(stim)
                    switch class(stim)
                        case {'double','single'}
                            if any(stim(:)>1) || any(stim(:)<0)
                                error('stim had elements <0 or >1 ')
                            else
                                floatprecision=1;%will tell maketexture to use 0.0-1.0 format with 16bpc precision (2 would do 32bpc)
                            end
                            
                            %maketexture barfs on singles
                            if strcmp(class(stim),'single')
                                stim=double(stim);
                            end
                            
                        case 'uint8'
                            %do nothing
                        case 'uint16'
                            stim=single(stim)/intmax('uint16');
                            floatprecision=1;
                        case 'logical'
                            stim=uint8(stim)*intmax('uint8'); %force to 8 bit
                        otherwise
                            error('unexpected stim variable class; currently stimOGL expects double, single, unit8, uint16, or logical')
                    end
                else
                    stim
                    class(stim)
                    error('stim  must be real')
                end
                
                if floatprecision ~=0 || ~strcmp(class(stim),'uint8')
                    %convert stim/floatprecision to uint8 so when drawFrameUsingTextureCache calls maketexture it is fast
                    %(especially when strategy is noCache and we make each texture during each frame)
                    floatprecision=0;
                    warning('off','MATLAB:intConvertNonIntVal')
                    stim=uint8(stim*double(intmax('uint8')));
                    warning('on','MATLAB:intConvertNonIntVal')
                end
                
            end
            
        end
        
        function destRect = determineDestRect(tm, window, station, metaPixelSize, stim, strategy)
            
            if window>=0
                [scrWidth scrHeight]=Screen('WindowSize', window);
            else
                scrWidth=getWidth(station);
                scrHeight=getHeight(station);
            end
            
            if ~isempty(strategy) && strcmp(strategy, 'expert')
                stimheight = stim.height;
                stimwidth = stim.width;
            else
                stimheight=size(stim,1);
                stimwidth=size(stim,2);
            end
            
            if metaPixelSize == 0
                scaleFactor = [scrHeight scrWidth]./[stimheight stimwidth];
            elseif length(metaPixelSize)==2 && all(metaPixelSize)>0
                scaleFactor = metaPixelSize;
            elseif isempty(metaPixelSize)
                % empty only for 'reinforced' phases, in which case we dont care what destRect is, since it will get overriden anyways
                % during updateTrialState(tm)
                scaleFactor = [1 1];
            else
                error('bad metaPixelSize argument')
            end
            if any(scaleFactor.*[stimheight stimwidth]>[scrHeight scrWidth])
                scaleFactor.*[stimheight stimwidth]
                scaleFactor
                stimheight
                stimwidth
                [scrHeight scrWidth]
                error('metaPixelSize argument too big')
            end
            
            height = scaleFactor(1)*stimheight;
            width = scaleFactor(2)*stimwidth;
            
            if window>=0
                scrRect = Screen('Rect', window);
                scrLeft = scrRect(1); %am i retarted?  why isn't [scrLeft scrTop scrRight scrBottom]=Screen('Rect', window); working?  deal doesn't work
                scrTop = scrRect(2);
                scrRight = scrRect(3);
                scrBottom = scrRect(4);
                scrWidth= scrRight-scrLeft;
                scrHeight=scrBottom-scrTop;
            else
                scrLeft = 0;
                scrTop = 0;
                scrRight = scrWidth;
                scrBottom = scrHeight;
            end
            
            destRect = round([(scrWidth/2)-(width/2) (scrHeight/2)-(height/2) (scrWidth/2)+(width/2) (scrHeight/2)+(height/2)]); %[left top right bottom]
            
        end
        
        function d=display(t)
            d=[t.description sprintf('\n\t\t\tsoundManager:\t') display(t.soundMgr)];
        end
        
        function [trialManager, updateTM, newSM, updateSM, stopEarly trialRecords, station] ...
                = doTrial(trialManager,station,stimManager,subject,r,rn,trialRecords,sessionNumber,compiledRecords)
            % This function handles most of the per-trial functionality, including stim creation and display, reward handling, and trialRecord recording.
            % Main functions called: calcStim, createStimSpecsFromParams, stimOGL
            % INPUTS:
            %   trialManager - the trial manager object
            %   station - the station object
            %   stimManager - the stim manager object
            %   subject - the subject object
            %   r - the ratrix object
            %   rn - the rnet object
            %   trialRecords - a vector of the current session's trialRecords (includes some history from prev. session until they get replaced by current session)
            %   sessionNumber - the current session number
            % OUTPUTS:
            %   trialManager - the (potentially modified) trial manager object
            %   updateTM - a flag indicating if the trialManager needs to be persisted
            %   newSM - a possibly new stimManager object
            %   updateSM - a flag indicating if the stimManager needs to be persisted
            %   stopEarly - a flag to stop running trials
            %   trialRecords - the updated trial records
            %   station - the (potentially modified) station object
            
            verbose=1;
            updateTM=false;
            stopEarly=0;
            
            % verbose - flag for verbose output
            % constants - returned from getConstants(rn) if we have a rnet
            % trialInd - the index of the current trialRecord
            % p - current training protocol
            % t - current training step index
            % ts - current trainingStep object
            
            if isa(station,'station') && isa(stimManager,'stimManager') && isa(r,'ratrix') && isa(subject,'subject') && ((isempty(rn) && strcmp(getRewardMethod(station),'localTimed')) || isa(rn,'rnet'))
                if stationOKForTrialManager(trialManager,station)
                    
                    if ~isempty(rn)
                        constants = getConstants(rn);
                    end
                    
                    trialInd=length(trialRecords)+1;
                    [p t]=getProtocolAndStep(subject);
                    ts = getTrainingStep(p,t);
                    
                    if trialInd>1
                        trialRecords(trialInd).trialNumber=trialRecords(trialInd-1).trialNumber+1;
                    else
                        trialRecords(trialInd).trialNumber=1;
                    end
                    
                    if isa(stimManager,'stimManager')
                        trialRecords(trialInd).sessionNumber = sessionNumber;
                        trialRecords(trialInd).date = datevec(now);
                        trialRecords(trialInd).box = structize(getBoxFromID(r,getBoxIDForSubjectID(r,getID(subject))));
                        trialRecords(trialInd).station = structize(station);
                        trialRecords(trialInd).protocolName = getName(p);
                        trialRecords(trialInd).trainingStepNum = t;
                        trialRecords(trialInd).numStepsInProtocol = getNumTrainingSteps(p);
                        trialRecords(trialInd).protocolVersion = getProtocolVersion(subject);
                        
                        trialRecords(trialInd).reinforcementManager = [];
                        trialRecords(trialInd).reinforcementManagerClass = [];
                        
                        stns=getStationsForBoxID(r,getBoxIDForSubjectID(r,getID(subject)));
                        for stNum=1:length(stns)
                            trialRecords(trialInd).stationIDsInBox{stNum} = getID(stns(stNum));
                        end
                        
                        trialRecords(trialInd).subjectsInBox = getSubjectIDsForBoxID(r,getBoxIDForSubjectID(r,getID(subject)));
                        trialRecords(trialInd).trialManager = structize(decache(trialManager));
                        trialRecords(trialInd).stimManagerClass = class(stimManager);
                        trialRecords(trialInd).stepName = getStepName(ts);
                        trialRecords(trialInd).trialManagerClass = class(trialManager);
                        trialRecords(trialInd).scheduler = structize(getScheduler(ts));
                        trialRecords(trialInd).criterion = structize(getCriterion(ts));
                        trialRecords(trialInd).schedulerClass = class(getScheduler(ts));
                        trialRecords(trialInd).criterionClass = class(getCriterion(ts));
                        
                        trialRecords(trialInd).neuralEvents = [];
                        
                        switch trialManager.displayMethod
                            case 'ptb'
                                resolutions=getResolutions(station);
                            case 'LED'
                                resolutions=[];
                            otherwise
                                error('shouldn''t happen')
                        end
                        
                        % calcStim should return the following:
                        %	newSM - a (possibly) modified stimManager object
                        %	updateSM - a flag whether or not to copy newSM to ratrix
                        %	resInd - for setting resolution - DO NOT CHANGE
                        %	preRequestStim - a struct containing all stim-specifc parameters to create a stimSpec for the pre-request phase
                        %	preResponseStim - a struct containing all stim-specific parameters to create a stimSpec for the pre-response phase
                        %	discrimStim - a struct containing the parameters to create a stimSpec for the discriminandum phase
                        %		the parameters needed are: stimType, stim(actual movie frames), scaleFactor, [phaseLabel], [framesUntilTransition], [startFrame], [phaseType]
                        %		note that not all of these may be used, depending on the trialManager's delayManager and responseWindow parameters
                        %	LUT - the color lookup table - DO NOT CHANGE now; but eventually this should be a cell array of parameters to get the CLUT from oracle!
                        %	trialRecords(trialInd).targetPorts - target ports DO NOT CHANGE
                        %	trialRecords9trialInd).distractorPorts - distractor ports DO NOT CHANGE (both port sets are constant across the trial)
                        %	stimulusDetails - stimDetails DO NOT CHANGE
                        %	trialRecords(trialInd).interTrialLuminance - itl DO NOT CHANGE
                        %	text - DO NOT CHANGE
                        %	indexPulses - DO NOT CHANGE
                        
                        % now, we should ALWAYS call createStimSpecsFromParams, which should do the following:
                        %	INPUTS: preRequestStim, preResponseStim, discrimStim, targetPorts, distractorPorts, requestPorts,interTrialLuminance,hz,indexPulses
                        %	OUTPUTS: stimSpecs, startingStimSpecInd
                        %		- should handle creation of default phase setup for nAFC/freeDrinks, and also handle additional phases depending on delayManager and responseWindow
                        %		- how then does calcStim return a set of custom phases? - it no longer can, because we are forcing calcstim to return 3 structs...to discuss later?
                        [newSM, ...
                            updateSM, ...
                            resInd, ...
                            preRequestStim, ...
                            preResponseStim, ...
                            discrimStim, ...
                            postDiscrimStim, ...
                            interTrialStim, ...
                            LUT, ...
                            trialRecords(trialInd).targetPorts, ...
                            trialRecords(trialInd).distractorPorts, ...
                            stimulusDetails, ...
                            trialRecords(trialInd).interTrialLuminance, ...
                            text, ...
                            indexPulses, ...
                            imagingTasks] ...
                            = calcStim(stimManager, ...
                            trialManager, ...
                            getAllowRepeats(trialManager), ...
                            resolutions, ...
                            getDisplaySize(station), ...
                            getLUTbits(station), ...
                            getResponsePorts(trialManager,getNumPorts(station)), ...
                            getNumPorts(station), ...
                            trialRecords, ...
                            compiledRecords);
                        
                        % test must a single string now - dont bother w/ complicated stuff here
                        if ~ischar(text)
                            error('text must be a string');
                        end
                        
                        switch trialManager.displayMethod
                            case 'ptb'
                                [station trialRecords(trialInd).resolution trialRecords(trialInd).imagingTasks]=setResolutionAndPipeline(station,resolutions(resInd),imagingTasks);
                            case 'LED'
                                trialRecords(trialInd).resolution.width=uint8(1);
                                trialRecords(trialInd).resolution.height=uint8(1);
                                trialRecords(trialInd).resolution.pixelSize=uint8(16); %should set using 2nd output of openNidaqForAnalogOutput
                                trialRecords(trialInd).resolution.hz=resInd;
                            otherwise
                                error('shouldn''t happen')
                        end
                        
                        [newSM, updateSM, stimulusDetails]=postScreenResetCheckAndOrCache(newSM,updateSM,stimulusDetails); %enables SM to check or cache their tex's if they control that
                        
                        trialRecords(trialInd).station = structize(station); %wait til now to record, so we get an updated ifi measurement in the station object
                        
                        refreshRate=1/getIFI(station); %resolution.hz is 0 on OSX
                        
                        % check port logic (depends on trialManager class)
                        if (isempty(trialRecords(trialInd).targetPorts) || isvector(trialRecords(trialInd).targetPorts))...
                                && (isempty(trialRecords(trialInd).distractorPorts) || isvector(trialRecords(trialInd).distractorPorts))
                            
                            portUnion=[trialRecords(trialInd).targetPorts trialRecords(trialInd).distractorPorts];
                            %                 if isa(stimManager,'changeDetectorSM')
                            %                     % this is a weird situation which needs more thought
                            %                     % but right now hard code the requiremenbts
                            %                     if trialRecords(trialInd).targetPorts==2 && all(ismember(trialRecords(trialInd).distractorPorts,[1,3]))
                            %                         % okay....
                            %                     else
                            %                         error('shit hits the fan');
                            %                     end
                            %                 else
                            if length(unique(portUnion))~=length(portUnion) ||...
                                    any(~ismember(portUnion, getResponsePorts(trialManager,getNumPorts(station))))
                                
                                trialRecords(trialInd).targetPorts
                                trialRecords(trialInd).distractorPorts
                                getResponsePorts(trialManager,getNumPorts(station))
                                trialRecords(trialInd).targetPorts
                                trialRecords(trialInd).distractorPorts
                                getResponsePorts(trialManager,getNumPorts(station))
                                sca;
                                keyboard
                                error('targetPorts and distractorPorts must be disjoint, contain no duplicates, and subsets of responsePorts')
                            end
                            %                 end
                        else
                            trialRecords(trialInd).targetPorts
                            trialRecords(trialInd).distractorPorts
                            error('targetPorts and distractorPorts must be row vectors')
                        end
                        
                        checkPorts(trialManager,trialRecords(trialInd).targetPorts,trialRecords(trialInd).distractorPorts);
                        
                        [stimSpecs startingStimSpecInd] = createStimSpecsFromParams(trialManager,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,interTrialStim,...
                            trialRecords(trialInd).targetPorts,trialRecords(trialInd).distractorPorts,getRequestPorts(trialManager,getNumPorts(station)),...
                            trialRecords(trialInd).interTrialLuminance,refreshRate,indexPulses);
                        trialManager.validateStimSpecs(stimSpecs);
                        
                        [tempSoundMgr updateSndM] = cacheSounds(getSoundManager(trialManager),station);
                        trialManager = setSoundManager(trialManager, tempSoundMgr);
                        updateTM = updateTM || updateSndM;
                        
                        trialRecords(trialInd).stimManager = structize(decache(newSM)); %many rouge stimManagers have a LUT cached in them and aren't decaching it -- hopefully will be fixed by the LUT fixing... (http://132.239.158.177/trac/rlab_hardware/ticket/224)
                        stimulusDetails=structize(stimulusDetails);
                        
                        manualOn=0;
                        if length(trialRecords)>1
                            if ~(trialRecords(trialInd-1).leftWithManualPokingOn)
                                manualOn=0;
                            elseif trialRecords(trialInd-1).containedManualPokes
                                manualOn=1;
                            else
                                error('should never happen')
                            end
                        end
                        
                        %             [rm updateRM] =cache(getReinforcementManager(trialManager),trialRecords, subject);
                        %             updateTM = updateTM || updateRM;
                        
                        drawnow;
                        currentValveStates=verifyValvesClosed(station);
                        
                        pStr=[trialRecords(trialInd).protocolName '(' num2str(trialRecords(trialInd).protocolVersion.manualVersion) 'm:' num2str(trialRecords(trialInd).protocolVersion.autoVersion) 'a)' ' step:' num2str(trialRecords(trialInd).trainingStepNum) '/' num2str(trialRecords(trialInd).numStepsInProtocol) ];
                        
                        trialLabel=sprintf('session:%d trial:%d (%d)',sessionNumber,sum(trialRecords(trialInd).sessionNumber == [trialRecords.sessionNumber]),trialRecords(trialInd).trialNumber);
                        
                        if ~isempty(getDatanet(station))
                            % 4/11/09 - also save the stimRecord here, before trial starts (but just the stimManagerClass)
                            % also send over the filename of the neuralRecords file (so we can create it on the phys side, and then append every 30 secs)
                            datanet_constants = getConstants(getDatanet(station));
                            if ~isempty(getDatanet(station))
                                [garbage stopEarly] = handleCommands(getDatanet(station),[]);
                            end
                            if ~stopEarly
                                commands=[];
                                commands.cmd = datanet_constants.stimToDataCommands.S_TRIAL_START_EVENT_CMD;
                                cparams=[];
                                cparams.neuralFilename = sprintf('neuralRecords_%d-%s.mat',trialRecords(trialInd).trialNumber,datestr(trialRecords(trialInd).date,30));
                                cparams.stimFilename = sprintf('stimRecords_%d-%s.mat',trialRecords(trialInd).trialNumber,datestr(trialRecords(trialInd).date, 30));
                                cparams.time=datenum(trialRecords(trialInd).date);
                                cparams.trialNumber=trialRecords(trialInd).trialNumber;
                                cparams.stimManagerClass=trialRecords(trialInd).stimManagerClass;
                                cparams.stepName=getStepName(ts);
                                cparams.stepNumber=t;
                                commands.arg=cparams;
                                [gotAck] = sendCommandAndWaitForAck(getDatanet(station), commands);
                                
                                ratID=getID(subject);
                                trialStartTime=datestr(trialRecords(trialInd).date, 30);
                                trialNum=trialRecords(trialInd).trialNumber;
                                stimManagerClass=trialRecords(trialInd).stimManagerClass;
                                stepName=trialRecords(trialInd).stepName;
                                frameDropCorner=trialManager.frameDropCorner;
                                
                                try
                                    stim_path = fullfile(getStorePath(getDatanet(station)), 'stimRecords');
                                    save(fullfile(stim_path,cparams.stimFilename),'ratID','trialStartTime','trialNum','stimManagerClass','stimulusDetails','frameDropCorner','refreshRate','stepName');
                                catch ex
                                    warningStr=sprintf('unable to save to %s',stim_path);
                                    error(warningStr);
                                end
                            end
                        end
                        
                        if isfield(stimulusDetails, 'big') % edf: why did this used to also test for isstruct(stimulusDetails) ?
                            stimulusDetails = rmfield(stimulusDetails, 'big');
                            
                            %also, maybe one day these exist and need removing:
                            % phaseRecords{i}.responseDetails.expertDetails.big
                        end
                        
                        trialRecords(trialInd).stimDetails = stimulusDetails;
                        
                        % stopEarly could potentially be set by the datanet's handleCommands (if server tells this client to shutdown
                        % while we are in doTrial)
                        if ~stopEarly
                            [trialManager stopEarly,...
                                trialRecords,...
                                eyeData,...
                                eyeDataFrameInds,...
                                gaze,...
                                station,...
                                ratrixSVNInfo,...
                                ptbSVNInfo] ...
                                = stimOGL( ...
                                trialManager, ...
                                stimSpecs,  ...
                                startingStimSpecInd, ...
                                newSM, ...
                                LUT, ...
                                trialRecords(trialInd).targetPorts, ...
                                trialRecords(trialInd).distractorPorts, ...
                                getRequestPorts(trialManager, getNumPorts(station)), ...
                                trialRecords(trialInd).interTrialLuminance, ...
                                station, ...
                                manualOn, ...
                                .1, ... % 10% should be ~1 ms of acceptable frametime error
                                text,rn,getID(subject),class(newSM),pStr,trialLabel,getEyeTracker(station),0,trialRecords);
                        end
                        
                        if ~isempty(getEyeTracker(station))
                            %[junk junk eyeDataVarNames]=getSample(getEyeTracker(station)); %throws out a sample in order to get variable names... dirty
                            saveEyeData(getEyeTracker(station),eyeData,eyeDataFrameInds,getEyeDataVarNames(getEyeTracker(station)),gaze,trialRecords(trialInd).trialNumber,trialRecords(trialInd).date)
                        end
                        
                        trialRecords(trialInd).trainingStepName = generateStepName(ts,ratrixSVNInfo,ptbSVNInfo);
                        
                        if stopEarly
                            'got stopEarly 1'
                        end
                        
                        currentValveStates=verifyValvesClosed(station);
                        
                        if ~ischar(trialRecords(trialInd).result)
                            %                 resp=find(trialRecords(trialInd).result);
                            %                 if length(resp)==1
                            %                     trialRecords(trialInd).correct = ismember(resp,trialRecords(trialInd).targetPorts);
                            %                 end
                            %             elseif ischar(trialRecords(trialInd).result) && strcmp(trialRecords(trialInd).result, 'multiple ports')
                            % keep doing trials if response was 'multiple ports'
                            %             elseif ischar(trialRecords(trialInd).result) && strcmp(trialRecords(trialInd).result, 'none')
                            % temporarily continue doing trials if response = 'none'
                            % edf: how would stimOGL exit while leaving response as 'none'?  passive viewing?  (empty responseOptions)
                            % if so, why do you say 'temporarily'?  also, should verify that this really was a passive viewing.
                            %
                            % i think response is also 'none' if there is a bad error in stimOGL,
                            % like an rnet error, in which case we should not continue trials
                            % we need to flag any error with a special response so we know what's going on and don't continue
                        elseif ischar(trialRecords(trialInd).result) && strcmp(trialRecords(trialInd).result, 'manual flushPorts')
                            type='flushPorts';
                            typeParams=[];
                            validInputs={};
                            validInputs{1}=0:getNumPorts(station);
                            validInputs{2}=[1 100];
                            validInputs{3}=[0 10];
                            validInputs{4}=[0 60];
                            fpVars = userPrompt(getPTBWindow(station),validInputs,type,typeParams);
                            portsToFlush=fpVars(1);
                            if portsToFlush==0 % 0 is a special flag that means do all ports (for calibration, we need interleaved ports)
                                portsToFlush=1:getNumPorts(station);
                            end
                            flushPorts(station,fpVars(3),fpVars(2),fpVars(4),portsToFlush);
                            stopEarly=false; % reset stopEarly/quit to be false, so continue doing trials
                        elseif ischar(trialRecords(trialInd).result) && (strcmp(trialRecords(trialInd).result, 'nominal') || ...
                                strcmp(trialRecords(trialInd).result, 'multiple ports') || strcmp(trialRecords(trialInd).result,'timedout'))
                            % keep doing trials
                        else
                            trialRecords(trialInd).result
                            if strcmp(trialRecords(trialInd).result,'manual training step')
                                updateTM=true; % to make sure that soundMgr gets decached and passed back to the subject/doTrial where the k+t happens
                            end
                            fprintf('setting stopEarly\n')
                            stopEarly = 1;
                        end
                        
                        if ~isempty(getDatanet(station)) %&& ~stopEarly
                            [garbage garbage] = handleCommands(getDatanet(station),[]);
                            datanet_constants = getConstants(getDatanet(station));
                            commands=[];
                            commands.cmd = datanet_constants.stimToDataCommands.S_TRIAL_END_EVENT_CMD;
                            cparams=[];
                            cparams.time = now;
                            commands.arg=cparams;
                            [gotAck] = sendCommandAndWaitForAck(getDatanet(station), commands);
                        end
                        
                        trialRecords(trialInd).reinforcementManager = structize(trialManager.reinforcementManager);
                        trialRecords(trialInd).reinforcementManagerClass = class(trialManager.reinforcementManager);
                        
                        currentValveStates=verifyValvesClosed(station);
                        
                        while ~isempty(rn) && commandsAvailable(rn,constants.priorities.AFTER_TRIAL_PRIORITY) && ~stopEarly
                            if ~isConnected(r)
                                stopEarly=true;
                            end
                            com=getNextCommand(rn,constants.priorities.AFTER_TRIAL_PRIORITY);
                            if ~isempty(com)
                                [good cmd args]=validateCommand(rn,com);
                                if good
                                    switch cmd
                                        case constants.serverToStationCommands.S_SET_VALVES_CMD
                                            requestedValveState=args{1};
                                            isPrime=args{2};
                                            if isPrime
                                                
                                                timeout=-5;
                                                
                                                [stopEarly trialRecords(trialInd).primingValveErrorDetails(end+1),...
                                                    trialRecords(trialInd).latencyToOpenPrimingValves(end+1),...
                                                    trialRecords(trialInd).latencyToClosePrimingValveRecd(end+1),...
                                                    trialRecords(trialInd).latencyToClosePrimingValves(end+1),...
                                                    trialRecords(trialInd).actualPrimingDuration(end+1),...
                                                    garbage,...
                                                    garbage]...
                                                    = clientAcceptReward(...
                                                    rn,...
                                                    com,...
                                                    station,...
                                                    timeout,...
                                                    valveStart,...
                                                    requestedValveState,...
                                                    [],...
                                                    isPrime);
                                                
                                                if stopEarly
                                                    'got stopEarly 7'
                                                end
                                                
                                                currentValveStates=verifyValvesClosed(station);
                                            else
                                                sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'client received non-priming S_SET_VALVES_CMD outside of a trial');
                                            end
                                        otherwise
                                            stopEarly=clientHandleVerifiedCommand(rn,com,cmd,args,constants.statuses.IN_SESSION_BETWEEN_TRIALS);
                                            
                                            if stopEarly
                                                'got stopEarly 8'
                                            end
                                    end
                                end
                            end
                        end
                        
                        currentValveStates=verifyValvesClosed(station);
                        
                        if stopEarly
                            trialManager.soundMgr=uninit(trialManager.soundMgr,station);
                        end
                        if stopEarly
                            trialManager.soundMgr=uninit(trialManager.soundMgr,station);
                        end
                        
                    else
                        error('need a stimManager')
                    end
                else
                    error('station not ok for trialManager')
                end
            else
                
                sca
                
                if ~isa(station,'station')
                    error('no station')
                end
                if ~isa(stimManager, 'stimManager')
                    error('no stimManager')
                end
                if ~isa(subject, 'subject')
                    error('no subject')
                end
                if ~isa(r, 'ratrix')
                    error('no ratrix')
                end
                if ~isa(rn, 'rnet') && isempty(rn)
                    error('no rnet %s', getRewardMethod(station))
                end
                if ~isa(rn, 'rnet')
                    error('non-empty rnet %s', getRewardMethod(station))
                end
                
                error('need station, stimManager, subject, ratrix, and rnet objects')
            end
        end
        
        function rewardValves = forceRewards(tm,rewardValves)
            %forceRewards Does nothing here
        end
        
        function a = getAllowRepeats(tm)
            % default getAllowRepeats for superclass trialManager - just return true!
            % this allows doTrial to call this function even though it is only meant for use for the freeDrinks tm
            a=true;
        end
        
        function out=stationOKForTrialManager(t,s)
            if isa(s,'station')
                out = getNumPorts(s)>=3;
            else
                error('need a station object')
            end
        end
        
        function [tm trialDetails result spec rewardSizeULorMS requestRewardSizeULorMS ...
                msPuff msRewardSound msPenalty msPenaltySound floatprecision textures destRect] = ...
                updateTrialState(tm, sm, result, spec, ports, lastPorts, ...
                targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                floatprecision, textures, destRect, ...
                requestRewardDone, punishResponses)
            % This function is a TM base class method to update trial state before every flip.
            % Things done here include:
            % - check for request rewards
            
            rewardSizeULorMS=0;
            requestRewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            
            if isfield(trialRecords(end),'trialDetails') && isfield(trialRecords(end).trialDetails,'correct')
                correct=trialRecords(end).trialDetails.correct;
            else
                correct=[];
            end
            
            if ~isempty(result) && ischar(result) && strcmp(result,'timeout') && isempty(correct) && strcmp(getPhaseLabel(spec),'reinforcement')
                correct=0;
                result='timedout';
                trialDetails=[];
                trialDetails.correct=correct;
            elseif ~isempty(result) && ischar(result) && strcmp(result,'timeout') && isempty(correct) && strcmp(getPhaseLabel(spec),'itl')
                % timeout during 'itl' phase - neither correct nor incorrect (only happens when no stim is shown)
                result='timedout';
                trialDetails=[];
            else
                trialDetails=[];
            end
            
            
            if (any(ports(requestPorts)) && ~any(lastPorts(requestPorts))) && ... % if a request port is triggered
                    ((strcmp(getRequestMode(getReinforcementManager(tm)),'nonrepeats') && ~any(ports&lastRequestPorts)) || ... % if non-repeat
                    strcmp(getRequestMode(getReinforcementManager(tm)),'all') || ...  % all requests
                    ~requestRewardDone) % first request
                
                [rm garbage requestRewardSizeULorMS garbage garbage garbage garbage updateRM] =...
                    calcReinforcement(getReinforcementManager(tm),trialRecords, []);
                if updateRM
                    tm=setReinforcementManager(tm,rm);
                end
            end
            
            
        end  % end function
        
        function out = get.percentCorrectionTrials(t)
            out = 0;
        end
        
    end
    
    methods(Static)
        function validateStimSpecs(stimSpecs)
            for i=1:length(stimSpecs)
                spec = stimSpecs{i};
                cr = getTransitions(spec);
                fr = getFramesUntilTransition(spec);
                stimType = getStimType(spec);
                
                if ischar(stimType) && strcmp(stimType,'expert')
                    s=getStim(spec);
                    if isstruct(s) && isfield(s,'height') && isfield(s,'width')
                        % pass
                    elseif isa(s,'stimManager')
                        % pass for now
                    else
                        sca;
                        keyboard
                        error('in ''expert'' mode, stim must be a struct with fields ''height'' and ''width''');
                    end
                end
                
                if strcmp(cr{1}, 'none') && (isempty(fr) || (isscalar(fr) && fr<=0))
                    error('must have a transition port set or a transition by timeout');
                end
            end
        end
        
    end
    
    methods(Access=private)
        function createStimSpecsFromParams(tm)
            error('cannot call this on trialManager')
        end
        
        function [loop trigger frameIndexed timeIndexed indexedFrames timedFrames strategy toggleStim] = determineStrategy(tm, stim, type, responseOptions, framesUntilTransition)
            
            if length(size(stim))>3
                error('stim must be 2 or 3 dims')
            end
            
            loop=0;
            trigger=0;
            frameIndexed=0; % Whether the stim is indexed with a list of frames
            timeIndexed=0; % Whether the stim is timed with a list of frames
            indexedFrames = []; % List of indices referencing the frames
            timedFrames = [];
            toggleStim=true; % default, overriden by {'trigger',toggleStim}
            
            if iscell(type)
                if length(type)~=2
                    error('Stim type of cell should be of length 2')
                end
                switch type{1}
                    case 'indexedFrames'
                        frameIndexed = 1;
                        loop=1;
                        trigger=0;
                        indexedFrames = type{2};
                        if isNearInteger(indexedFrames) && isvector(indexedFrames) && all(indexedFrames>0) && all(indexedFrames<=size(stim,3))
                            strategy = 'textureCache';
                        else
                            class(indexedFrames)
                            size(indexedFrames)
                            indexedFrames
                            size(stim,3)
                            error('bad vector for indexedFrames type: must be a vector of integer indices into the stim frames (btw 1 and stim dim 3)')
                        end
                    case 'timedFrames'
                        timeIndexed = 1;
                        timedFrames = type{2};
                        if isinteger(timedFrames) && isvector(timedFrames) && size(stim,3)==length(timedFrames) && all(timedFrames(1:end-1)>=1) && timedFrames(end)>=0
                            strategy = 'textureCache';
                            %dontclear = 1;  %might save time, but breaks on lame graphics cards (such as integrated gfx on asus mobos?)
                        else
                            error('bad vector for timedFrames type: must be a vector of length equal to stim dim 3 of integers > 0 (number or refreshes to display each frame). A zero in the final entry means hold display of last frame.')
                        end
                    case 'trigger'   %2 static frames -- if request, show frame 1; else show frame 2
                        strategy = 'textureCache';
                        loop = 0;
                        trigger = 1;
                        toggleStim=type{2};
                        if size(stim,3)~=2
                            error('trigger type must have stim with exactly 2 frames')
                        end
                    otherwise
                        error('Unsupported stim type using a cell, either indexedFrames or timedFrames')
                end
            else
                switch type
                    case 'static'   %static 1-frame stimulus
                        strategy = 'textureCache';
                        if size(stim,3)~=1
                            error('static type must have stim with exactly 1 frame')
                        end
                    case 'cache'    %dynamic n-frame stimulus (play once)
                        strategy = 'textureCache';
                    case 'loop'     %dynamic n-frame stimulus (loop)
                        strategy = 'textureCache';
                        loop = 1;
                    case 'dynamic'
                        error('dynamic type not yet implemented')
                    case 'expert' %callback stimManager.drawExpertFrame() to call ptb drawing methods, but leave frame labels, framedrop corner, and 'drawingfinished' to stimOGL
                        strategy='expert';
                    otherwise
                        error('unrecognized stim type, must be ''static'', ''cache'', ''loop'', ''dynamic'', ''expert'', {''indexedFrames'' [frameIndices]}, or {''timedFrames'' [frameTimes]}')
                end
            end
            
            if isempty(responseOptions) && isempty(framesUntilTransition) && (trigger || loop || (timeIndexed && timedFrames(end)==0) || frameIndexed)
                trigger
                loop
                timeIndexed
                frameIndexed
                error('can''t loop with no response ports -- would have no way out')
            end
            
            if strcmp(strategy,'textureCache') % texture precaching causes dropped frames (~1 per 45mins @ 100Hz)
                strategy = 'noCache';
            end
            
        end
        
        function drawFrameUsingTextureCache(tm, window, i, frameNum, stimSize, lastI, dontclear, texture, destRect, filtMode, labelFrames, ...
                xOrigTextPos, yNewTextPos, strategy,floatprecision)
            
            if window>=0
                if i>0 && i <= stimSize
                    if i~=lastI || (dontclear~=1) %only draw if texture different from last one, or if every flip is redrawn
                        if strcmp(strategy,'noCache')
                            texture=Screen('MakeTexture', window, texture,0,0,floatprecision); %need floatprecision=0 for remotedesktop
                        end
                        Screen('DrawTexture', window, texture,[],destRect,[],filtMode);
                        if strcmp(strategy,'noCache')
                            Screen('Close',texture);
                        end
                    else
                        if labelFrames
                            thisMsg=sprintf('This frame stim index (%d) is staying here without drawing new textures %d',i,frameNum);
                            Screen('DrawText',window,thisMsg,xOrigTextPos,yNewTextPos-20,100*ones(1,3));
                        end
                    end
                else
                    if stimSize==0
                        %probably a penalty stim with zero duration
                    else
                        i
                        sprintf('stimSize: %d',stimSize)
                        error('request for an unknown frame')
                    end
                end
            end
            
            
        end
        
        function xTextPos = drawText(tm, window, labelFrames, subID, xOrigTextPos, yTextPos, normBoundsRect, stimID, protocolStr, ...
                textLabel, trialLabel, i, frameNum, manual, didManual, didAPause, ptbVersion, ratrixVersion, numDrops, numApparentDrops, phaseInd, phaseType,textType)
            
            %DrawFormattedText() won't be any faster cuz it loops over calls to Screen('DrawText'), tho it would clean this code up a bit.
            
            xTextPos=xOrigTextPos;
            brightness=100;
            switch textType
                case 'full'
                    if labelFrames
                        [xTextPos] = Screen('DrawText',window,['ID:' subID ],xOrigTextPos,yTextPos,brightness*ones(1,3));
                        xTextPos=xTextPos+50;
                        [garbage,yTextPos] = Screen('DrawText',window,['trlMgr:' class(tm) ' stmMgr:' stimID  ' prtcl:' protocolStr ],xTextPos,yTextPos,brightness*ones(1,3));
                    end
                    yTextPos=yTextPos+1.5*normBoundsRect(4);
                    
                    if labelFrames
                        if iscell(textLabel)  % this is a reoccuring cost per frame... could be before the loop... pmm
                            txtLabel=textLabel{i};
                        else
                            txtLabel=textLabel;
                        end
                        if iscell(phaseType)
                            phaseTypeDisplay=phaseType{1};
                        else
                            phaseTypeDisplay=phaseType;
                        end
                        [garbage,yTextPos] = Screen('DrawText',window,sprintf('priority:%g %s stimInd:%d frame:%d drops:%d(%d) stim:%s, phaseInd:%d strategy:%s',Priority(),trialLabel,i,frameNum,numDrops,numApparentDrops,txtLabel,phaseInd,phaseTypeDisplay),xTextPos,yTextPos,brightness*ones(1,3));
                        yTextPos=yTextPos+1.5*normBoundsRect(4);
                        
                        [garbage,yTextPos] = Screen('DrawText',window,sprintf('ptb:%s',ptbVersion),xTextPos,yTextPos,brightness*ones(1,3));
                        yTextPos=yTextPos+1.5*normBoundsRect(4);
                        
                        [garbage,yTextPos] = Screen('DrawText',window,sprintf('ratrix:%s',ratrixVersion),xTextPos,yTextPos,brightness*ones(1,3));
                        yTextPos=yTextPos+1.5*normBoundsRect(4);
                    end
                case 'light'
                    [garbage,yTextPos] = Screen('DrawText',window,sprintf('%s stimInd:%d frame:%d drops:%d(%d)',trialLabel,i,frameNum,numDrops,numApparentDrops),xTextPos,yTextPos,brightness*ones(1,3));
                    yTextPos=yTextPos+1.5*normBoundsRect(4);
                otherwise
                    error('unsupported')
            end
            
            if manual
                manTxt='on';
            else
                manTxt='off';
            end
            if didManual
                [garbage,yTextPos] = Screen('DrawText',window,sprintf('trial record will indicate manual poking on this trial (k+m to toggle for next trial: %s)',manTxt),xTextPos,yTextPos,brightness*ones(1,3));
                yTextPos=yTextPos+1.5*normBoundsRect(4);
            end
            
            if didAPause
                %[garbage,yTextPos] = ...
                Screen('DrawText',window,'trial record will indicate a pause occurred on this trial',xTextPos,yTextPos,brightness*ones(1,3));
                %yTextPos=yTextPos+1.5*normBoundsRect(4);
            end
            
            
        end
        
        function [timestamps headroom] = flipFrameAndDoPulse(tm, window, dontclear, framesPerUpdate, ifi, paused, doFramePulse,station,timestamps)
            
            timeStamps.enteredFlipFrameAndDoPulse=GetSecs;
            
            if window>=0
                Screen('DrawingFinished',window,dontclear); % supposed to enhance performance
                % this usually returns fast but on asus mobos sometimes takes up to 2ms.
                % it is not strictly necessary and there have been some hints
                % that it actually hurts performance -- mario usually does not (but
                % sometimes does) include it in demos, and has mentioned to be suspect of
                % it.  it's almost certainly very sensitive to driver version.
                % we may want to consider testing effects of removing it or giving user control over it.
            end
            timestamps.drawingFinished=GetSecs;
            
            timestamps.when=timestamps.vbl+(framesPerUpdate-0.8)*ifi; %this 0.8 is critical -- get frame drops if it is 0.2.  mario uses 0.5.  in theory any number 0<x<1 should give identical results.
            %                                                         %discussion at http://tech.groups.yahoo.com/group/psychtoolbox/message/9165
            
            
            
            if doFramePulse && ~paused
                setStatePins(station,'frame',true);
            end
            
            timestamps.prePulses=GetSecs;
            headroom=(timestamps.vbl+(framesPerUpdate)*ifi)-timestamps.prePulses;
            
            if window>=0
                [timestamps.vbl sos timestamps.ft timestamps.missed]=Screen('Flip',window,timestamps.when,dontclear);
                %http://psychtoolbox.org/wikka.php?wakka=FaqFlipTimestamps
                %vbl=vertical blanking time, when bufferswap occurs (corrected by beampos logic if available/reliable)
                %sos=stimulus onset time -- vbl + a computed constant corresponding to the duration of the vertical blanking (a delay in when, after vbl, that the swap actually happens, depends on a lot of guts)
                %ft=timestamp from the end of flip's execution
            else
                waitTime=GetSecs()-timestamps.when;
                if waitTime>0
                    WaitSecs(waitTime);
                end
                timestamps.ft=timestamps.when;
                timestamps.vbl=ft;
                timestamps.missed=0;
            end
            
            if doFramePulse && ~paused
                setStatePins(station,'frame',false);
            end
            
            
            timestamps.postFlipPulse=GetSecs;
            
            if timestamps.ft-timestamps.vbl>.15*ifi
                %this occurs when my osx laptop runs on battery power
                fprintf('long delay inside flip after the swap-- ft-vbl:%.15g%% of ifi, now-vbl:%.15g\n',(timestamps.ft-timestamps.vbl)/ifi,GetSecs-timestamps.vbl)
            end
            
        end
        
        function [didAPause, paused, done, result, doValves, ports, ...
                didValves, didHumanResponse, manual, doPuff, pressingM, pressingP, overheadTime, initTime, kDownTime] ...
                = handleKeyboard(tm, keyCode, didAPause, paused, done, result, doValves, ports, didValves, ...
                didHumanResponse, manual, doPuff, pressingM, pressingP, originalPriority, priorityLevel, KbConstants)
            
            % note: this function pretty much updates a bunch of flags....
            
            overheadTime=GetSecs;
            
            mThisLoop = 0;
            pThisLoop = 0;
            
            shiftDown=any(keyCode(KbConstants.shiftKeys));
            ctrlDown=any(keyCode(KbConstants.controlKeys));
            atDown=any(keyCode(KbConstants.atKeys));
            kDown=any(keyCode(KbConstants.kKey));
            tDown=any(keyCode(KbConstants.tKey));
            fDown=any(keyCode(KbConstants.fKey));
            eDown=any(keyCode(KbConstants.eKey));
            portsDown=false(1,length(KbConstants.portKeys));
            numsDown=false(1,length(KbConstants.numKeys));
            
            % arrowKeyDown=false; % initialize this variable
            % 1/9/09 - phil to add stuff about arrowKeyDown
            for pNum=1:length(KbConstants.portKeys)
                portsDown(pNum)=any(keyCode(KbConstants.portKeys{pNum}));
                % arrowKeyDown=arrowKeyDown || any(strcmp(KbName(keys(keyNum)),{'left','down','right'}));
            end
            
            for nNum=1:length(KbConstants.numKeys)
                numsDown(nNum)=any(keyCode(KbConstants.numKeys{nNum}));
            end
            
            initTime=GetSecs;
            %map a 1-key shortcut left center right reponse - this
            %            if arrowKeyDown
            %                 for keyNum=1:length(keys)
            %                     keyName=KbName(keys(keyNum));
            %                     if strcmp(keyName,'left')
            %                         %doValves(1)=1;
            %                         ports(1)=1;
            %                         didHumanResponse=true;
            %                     end
            %                     if strcmp(keyName,'down')
            %                         %doValves(2)=1;
            %                         ports(2)=1;
            %                         didHumanResponse=true;
            %                     end
            %                     if  strcmp(keyName,'right')
            %                         %doValves(3)=1;
            %                         ports(3)=1;
            %                         didHumanResponse=true;
            %                     end
            %                 end
            %            end
            
            if kDown
                if any(keyCode(KbConstants.pKey))
                    pThisLoop=1;
                    
                    if ~pressingP
                        
                        didAPause=1;
                        paused=~paused;
                        
                        if paused
                            Priority(originalPriority);
                        else
                            Priority(priorityLevel);
                        end
                        
                        pressingP=1;
                    end
                elseif any(keyCode(KbConstants.qKey)) && ~paused
                    done=1;
                    result='manual kill';
                elseif tDown
                    done=1;
                    result=sprintf('manual training step');
                elseif fDown
                    result=sprintf('manual flushPorts');
                    didHumanResponse=true;
                    done=1;
                elseif eDown
                    error('some kind of error here to test stuff...');
                elseif any(portsDown)
                    if ctrlDown
                        doValves(portsDown)=1;
                        didValves=true;
                    else
                        ports(portsDown)=1;
                        didHumanResponse=true;
                    end
                elseif any(keyCode(KbConstants.mKey))
                    mThisLoop=1;
                    
                    if ~pressingM && ~paused
                        %         if ~paused
                        
                        manual=~manual;
                        dispStr=sprintf('set manual to %d\n',manual);
                        disp(dispStr);
                        pressingM=1;
                    end
                elseif any(keyCode(KbConstants.aKey))
                    doPuff=true;
                elseif any(keyCode(KbConstants.rKey)) && strcmp(getRewardMethod(station),'localPump')
                    doPrime(station);
                end
            end
            if shiftDown && atDown
                'WARNING!!!  you just hit shift-2 ("@"), which mario declared a synonym to sca (screen(''closeall'')) -- everything is going to break now'
                done=1;
                result='shift-2 kill';
            end
            
            kDownTime=GetSecs;
            if ~mThisLoop && pressingM
                pressingM=0;
            end
            if ~pThisLoop && pressingP
                pressingP=0;
            end
            
        end
        
        function [tm, done, newSpecInd, specInd, updatePhase, transitionedByTimeFlag, transitionedByPortFlag, result,...
                isRequesting, lastSoundsLooped, getSoundsTime, soundsDoneTime, framesDoneTime, ...
                portSelectionDoneTime, isRequestingDoneTime, goDirectlyToError] = ...
                handlePhasedTrialLogic(tm, done, ...
                ports, lastPorts, station, specInd, phaseType, transitionCriterion, framesUntilTransition, numFramesInStim,...
                framesInPhase, isFinalPhase, trialDetails, stimDetails, result, ...
                stimManager, msRewardSound, mePenaltySound, targetOptions, distractorOptions, requestOptions, ...
                playRequestSoundLoop, isRequesting, soundNames, lastSoundsLooped)
            
            updatePhase=0;
            newSpecInd = specInd;
            transitionedByTimeFlag = false;
            transitionedByPortFlag = false;
            goDirectlyToError=false;
            
            % ===================================================
            % Check against framesUntilTransition - Transition BY TIME
            % if we are at grad by time, then manually set port to the correct one
            % note that we will need to flag that this was done as "auto-request"
            if ~isempty(framesUntilTransition) && framesInPhase == framesUntilTransition - 1 % changed to framesUntilTransition-1 % 8/19/08
                % find the special 'timeout' transition (the port set should be empty)
                newSpecInd = transitionCriterion{find(cellfun('isempty',transitionCriterion))+1};
                % this will always work as long as we guarantee the presence of this special indicator (checked in stimSpec constructor)
                updatePhase = 1;
                if isFinalPhase
                    done = 1;
                    %      error('we are done by time');
                end
                %error('transitioned by time in phase %d', specInd);
                transitionedByTimeFlag = true;
                if isempty(result)
                    result='timeout';
                    if isRequesting
                        isRequesting=false;
                    else
                        isRequesting=true;
                    end
                end
            end
            
            
            % Check against transition by numFramesInStim (based on size of the stimulus in 'cache' or 'timedIndexed' mode)
            % in other modes, such as 'loop', this will never pass b/c numFramesInStim==Inf
            if framesInPhase==numFramesInStim
                % find the special 'timeout' transition (the port set should be empty)
                newSpecInd = transitionCriterion{cellfun('isempty',transitionCriterion)+1};
                % this will always work as long as we guarantee the presence of this special indicator (checked in stimSpec constructor)
                updatePhase = 1;
                if isFinalPhase
                    done = 1;
                    %      error('we are done by time');
                end
            end
            
            framesDoneTime=GetSecs;
            
            % Check for transition by port selection
            for gcInd=1:2:length(transitionCriterion)-1
                if ~isempty(transitionCriterion{gcInd}) && any(logical(ports(transitionCriterion{gcInd})))
                    % we found port in this port set
                    % first check if we are done with this trial, in which case we do nothing except set done to 1
                    if isFinalPhase
                        done = 1;
                        updatePhase = 1;
                        %              'we are done with this trial'
                        %              specInd
                    else
                        % move to the next phase as specified by graduationCriterion
                        %      specInd = transitionCriterion{gcInd+1};
                        newSpecInd = transitionCriterion{gcInd+1};
                        %             if (specInd == newSpecInd)
                        %                 error('same indices at %d', specInd);
                        %             end
                        updatePhase = 1;
                    end
                    transitionedByPortFlag = true;
                    
                    % set result to the ports array when it is triggered during a phase transition (ie result will be whatever the last port to trigger
                    %   a transition was)
                    result = ports;
                    
                    if length(find(ports))>1
                        goDirectlyToError=true;
                    end
                    
                    % we should stop checking all the criteria if we already passed one (essentially first come first served)
                    break;
                end
            end
            
            if done && isempty(result)
                % this means we were on 'autopilot', so the result should technically be nominal for this trial
                result='nominal';
            end
            
            portSelectionDoneTime=GetSecs;
            
            % =================================================
            % SOUNDS
            % changed from newSpecInd to specInd (cannot anticipate phase transition b/c it hasnt called updateTrialState to set correctness)
            soundsToPlay = getSoundsToPlay(stimManager, ports, lastPorts, specInd, phaseType, framesInPhase,msRewardSound, mePenaltySound, ...
                targetOptions, distractorOptions, requestOptions, playRequestSoundLoop, class(tm), trialDetails, stimDetails);
            getSoundsTime=GetSecs;
            % soundsToPlay is a cell array of sound names {{playLoop sounds}, {playSound sounds}} to be played at current frame
            % validate soundsToPlay here (make sure they are all members of soundNames)
            if ~isempty(setdiff(soundsToPlay{1},soundNames)) || ~all(cellfun(@(x) ismember(x{1},soundNames),soundsToPlay{2}))
                error('getSoundsToPlay assigned sounds that are not in the soundManager!');
            end
            
            % first end any loops that were looping last frame but should no longer be looped
            stopLooping=setdiff(lastSoundsLooped,soundsToPlay{1});
            for snd=stopLooping
                tm.soundMgr = playLoop(tm.soundMgr,snd,station,0);
            end
            
            % then start any loops that weren't already looping
            startLooping=setdiff(soundsToPlay{1},lastSoundsLooped);
            for snd=startLooping
                if ~isempty(snd)
                    tm.soundMgr = playLoop(tm.soundMgr,snd,station,1);
                end
            end
            
            lastSoundsLooped = soundsToPlay{1};
            
            % now play one-time sounds
            for i=1:length(soundsToPlay{2})
                tm.soundMgr = playSound(tm.soundMgr,soundsToPlay{2}{i}{1},soundsToPlay{2}{i}{2}/1000.0,station);
            end
            
            soundsDoneTime=GetSecs;
            
            
            % set isRequesting when request port is hit according to these rules:
            %   if isRequesting was already 1, then set it to 0
            %   if isRequesting was 0, then set it to 1
            %   (basically flip the bit every time request port is hit)
            %
            if any(ports(requestOptions)) && ~any(lastPorts(requestOptions))
                if isRequesting
                    isRequesting=false;
                else
                    isRequesting=true;
                end
            end
            
            isRequestingDoneTime=GetSecs;
        end
        
        function [done quit valveErrorDetail serverValveStates serverValveChange response newValveState requestRewardDone requestRewardOpenCmdDone] ...
                = handleServerCommands(tm, rn, done, quit, requestRewardStarted, requestRewardStartLogged, requestRewardOpenCmdDone, ...
                requestRewardDone, station, ports, serverValveStates, doValves, response)
            
            valveErrorDetail=[];
            serverValveChange = false;
            
            if ~isConnected(rn)
                done=true; %should this also set quit?
                quit=true; % 7/1/09 - also set quit (copied from v1.0.1)
            end
            
            constants=getConstants(rn);
            
            %serverValveStates=currentValveState; %what was the purpose of this line?  serverValveStates should only be changed by SET_VALVES_CMD
            %needed to remove, cuz was causing keyboard control to make valves stick open
            
            while commandsAvailable(rn,constants.priorities.IMMEDIATE_PRIORITY) && ~done && ~quit
                %logwrite('handling IMMEDIATE priority command in stimOGL');
                if ~isConnected(rn)
                    done=true;%should this also set quit?
                    quit=true; % 7/1/09 - also set quit (copied from v1.0.1)
                end
                com=getNextCommand(rn,constants.priorities.IMMEDIATE_PRIORITY);
                if ~isempty(com)
                    [good cmd args]=validateCommand(rn,com);
                    %logwrite(sprintf('command is %d',cmd));
                    if good
                        switch cmd
                            
                            case constants.serverToStationCommands.S_SET_VALVES_CMD
                                isPrime=args{2};
                                if isPrime
                                    if requestRewardStarted && ~requestRewardDone
                                        quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'stimOGL received priming S_SET_VALVES_CMD while a non-priming request reward was unfinished');
                                    else
                                        timeout=-1;
                                        [quit valveErrorDetail]=clientAcceptReward(rn,...
                                            com,...
                                            station,...
                                            timeout,...
                                            valveStart,...
                                            requestedValveState,...
                                            [],...
                                            isPrime);
                                        if quit
                                            done=true;
                                        end
                                    end
                                else
                                    if all(size(ports)==size(args{1}))
                                        
                                        serverValveStates=args{1};
                                        serverValveChange=true;
                                        
                                        if requestRewardStarted && requestRewardStartLogged && ~requestRewardDone
                                            if requestRewardOpenCmdDone
                                                if all(~serverValveStates)
                                                    requestRewardDone=true;
                                                else
                                                    quit=sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'stimOGL received S_SET_VALVES_CMD for closing request reward but not all valves were indicated to be closed');
                                                end
                                            else
                                                if all(serverValveStates==requestRewardPorts)
                                                    requestRewardOpenCmdDone=true;
                                                else
                                                    quit=sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'stimOGL received S_SET_VALVES_CMD for opening request reward but wrong valves were indicated to be opened');
                                                end
                                            end
                                        else
                                            quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'stimOGL received unexpected non-priming S_SET_VALVES_CMD');
                                        end
                                    else
                                        quit=sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'stimOGL received inappropriately sized S_SET_VALVES_CMD arg');
                                    end
                                end
                                
                            case constants.serverToStationCommands.S_REWARD_COMPLETE_CMD
                                if requestRewardDone
                                    quit=sendAcknowledge(rn,com);
                                else
                                    if requestRewardStarted
                                        quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'client received S_REWARD_COMPLETE_CMD apparently not preceeded by open and close S_SET_VALVES_CMD''s');
                                    else
                                        quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'client received S_REWARD_COMPLETE_CMD not preceeded by C_REWARD_CMD (MID_TRIAL)');
                                    end
                                end
                            otherwise
                                %the following lines referred to 'done' rather than 'quit' -- this is the bug that leads to the 'i am the king' bug?
                                quit=clientHandleVerifiedCommand(rn,com,cmd,args,constants.statuses.MID_TRIAL);
                                if quit
                                    response='server kill';
                                end
                        end
                    end
                end
            end
            newValveState=doValves|serverValveStates;
            
        end
        
        function [tm, Quit, trialRecords, eyeData, eyeDataFrameInds, gaze, frameDropCorner, station] ...
                = runRealTimeLoop(tm, window, ifi, stimSpecs, startingStimSpecInd, phaseData, stimManager, ...
                targetOptions, distractorOptions, requestOptions, interTrialLuminance, interTrialPrecision, ...
                station, manual,timingCheckPct,textLabel,rn,subID,stimID,protocolStr,ptbVersion,ratrixVersion,trialLabel,msAirpuff, ...
                originalPriority, verbose, eyeTracker, frameDropCorner,trialRecords)
            % This function does the real-time looping for stimulus presentation. The rough order of events per loop:
            %   - (possibly) update phase-specific information
            %   - call updateTrialState to set correctness and determine rewards
            %   - update stim frame index and draw new frame as needed
            %   - (possibly) get eyeTracker data
            %   - check for keyboard input
            %   - check for port input
            %   - carry out logic (whether we need to transition phases, what responses we got, what sounds to play)
            %   - carry out rewards
            %   - check for server and datanet commands
            %   - carry out airpuffs
            
            securePins(station);
            setStatePins(station,'trial',true); % start the trial
            % =====================================================================================================================
            %   show movie following mario's 'ProgrammingTips' for the OpenGL version of PTB
            %   http://www.kyb.tuebingen.mpg.de/bu/people/kleinerm/ptbosx/ptbdocu-1.0.5MK4R1.html
            %   except we drop frames (~1 per 45mins at 100Hz) if we preload all textures as he recommends, so we make and load them each frame
            
            % high level important settings -- should move all to stimManager
            filtMode = 0;               %how to compute the pixel values when the texture is drawn scaled
            %                           %0 = Nearest neighbour filtering, 1 = Bilinear filtering (default, and BAD)
            
            framesPerUpdate = 1;        %set number of monitor refreshes for each one of your refreshes
            
            labelFrames = 1;            %print a frame ID on each frame (makes frame calculation slow!)
            textType = getShowText(tm);
            showText = ~strcmp(textType,'off'); %whether or not to call draw text to print any text on screen
            
            
            Screen('Preference', 'TextRenderer', 1);  % consider moving to station.startPTB
            Screen('Preference', 'TextAntiAliasing', 1); % consider moving to station.startPTB
            Screen('Preference', 'TextAlphaBlending', 1);
            
            if ismac
                %http://psychtoolbox.org/wikka.php?wakka=FaqPerformanceTuning1
                %Screen('DrawText'): This is fast and low-quality on MS-Windows and beautiful but slow on OS/X.
                %also not good enough on asus mobo w/8600
                
                %setting textrenderer and textantialiasing to 0 not good enough
                labelFrames=0;
            end
            
            dontclear = 2;              %will be passed to flip
            %                           %0 = flip will set framebuffer to background (slow, but other options fail on some gfx cards, like the integrated gfx on our asus mobos?)
            %                           %1 = flip will leave the buffer as is ("incremental drawing" - but unclear if it copies the buffer just drawn into the buffer you're about to draw to, or if it is from a frame before that...)
            %                           %2 = flip does nothing, buffer state undefined (you must draw into each pixel if you care) - fastest
            % =====================================================================================================================
            
            trialInd=length(trialRecords);
            expertCache=[];
            ports=logical(0*readPorts(station));
            stochasticPorts = ports;
            lastPorts=ports;
            lastRequestPorts=ports;
            playRequestSoundLoop=false;
            
            requestRewardStarted=false;
            requestRewardStartLogged=false;
            requestRewardDone=false;
            requestRewardDurLogged=false;
            requestRewardOpenCmdDone=false;
            
            rewardCurrentlyOn=false;
            msRewardOwed=0;
            msRequestRewardOwed=0;
            msAirpuffOwed=0;
            airpuffOn=false;
            lastAirpuffTime=[];
            msRewardSound=0;
            msPenaltySound=0;
            lastRewardTime=[];
            thisRewardPhaseNum=[];
            thisAirpuffPhaseNum=[];
            
            Quit=false;
            responseOptions = union(targetOptions, distractorOptions);
            done=0;
            containedExpertPhase=0;
            eyeData=[];
            eyeDataFrameInds=[];
            gaze=[];
            soundNames=getSoundNames(getSoundManager(tm));
            
            phaseInd = startingStimSpecInd; % which phase we are on (index for stimSpecs and phaseData)
            phaseNum = 0; % increasing counter for each phase that we visit (may not match phaseInd if we repeat phases) - start at 0 b/c we increment during updatePhase
            updatePhase = 1; % are we starting a new phase?
            
            lastI = 0;
            isRequesting=0;
            
            lastSoundsLooped={};
            totalFrameNum=1; % for eyetracker
            totalEyeDataInd=1;
            doFramePulse=1;
            
            doValves=0*ports;
            newValveState=doValves;
            doPuff=false;
            
            % =========================================================================
            
            timestamps.loopStart=0;
            timestamps.phaseUpdated=0;
            timestamps.frameDrawn=0;
            timestamps.frameDropCornerDrawn=0;
            timestamps.textDrawn=0;
            timestamps.drawingFinished=0;
            timestamps.when=0;
            timestamps.prePulses=0;
            timestamps.postFlipPulse=0;
            timestamps.missesRecorded=0;
            timestamps.eyeTrackerDone=0;
            timestamps.kbCheckDone=0;
            timestamps.keyboardDone=0;
            timestamps.enteringPhaseLogic=0;
            timestamps.phaseLogicDone=0;
            timestamps.rewardDone=0;
            timestamps.serverCommDone=0;
            timestamps.phaseRecordsDone=0;
            timestamps.loopEnd=0;
            timestamps.prevPostFlipPulse=0;
            timestamps.vbl=0;
            timestamps.ft=0;
            timestamps.missed=0;
            timestamps.lastFrameTime=0;
            
            timestamps.logicGotSounds=0;
            timestamps.logicSoundsDone=0;
            timestamps.logicFramesDone=0;
            timestamps.logicPortsDone=0;
            timestamps.logicRequestingDone=0;
            
            timestamps.kbOverhead=0;
            timestamps.kbInit=0;
            timestamps.kbKDown=0;
            
            % =========================================================================
            
            responseDetails.numMisses=0;
            responseDetails.numApparentMisses=0;
            
            responseDetails.numUnsavedMisses=0;
            responseDetails.numUnsavedApparentMisses=0;
            
            responseDetails.misses=[];
            responseDetails.apparentMisses=[];
            
            responseDetails.afterMissTimes=[];
            responseDetails.afterApparentMissTimes=[];
            
            responseDetails.missIFIs=[];
            responseDetails.apparentMissIFIs=[];
            
            responseDetails.missTimestamps=timestamps;
            responseDetails.apparentMissTimestamps=timestamps;
            
            responseDetails.numDetailedDrops=1000;
            
            responseDetails.nominalIFI=ifi;
            responseDetails.tries={};
            responseDetails.times={};
            responseDetails.durs={};
            % responseDetails.requestRewardDone=false;
            responseDetails.requestRewardPorts={};
            responseDetails.requestRewardStartTime={};
            responseDetails.requestRewardDurationActual={};
            
            responseDetails.startTime=[];
            
            % =========================================================================
            
            phaseRecordAllocChunkSize = 1;
            [phaseRecords(1:length(stimSpecs)).responseDetails]= deal(responseDetails);
            
            [phaseRecords(1:length(stimSpecs)).proposedRewardDurationMSorUL] = deal(0);
            [phaseRecords(1:length(stimSpecs)).proposedAirpuffDuration] = deal(0);
            [phaseRecords(1:length(stimSpecs)).proposedPenaltyDurationMSorUL] = deal(0);
            [phaseRecords(1:length(stimSpecs)).actualRewardDurationMSorUL] = deal(0);
            [phaseRecords(1:length(stimSpecs)).actualAirpuffDuration] = deal(0);
            
            [phaseRecords(1:length(stimSpecs)).valveErrorDetails]=deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToOpenValves]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToCloseValveRecd]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToCloseValves]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToRewardCompleted]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToRewardCompletelyDone]= deal([]);
            [phaseRecords(1:length(stimSpecs)).primingValveErrorDetails]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToOpenPrimingValves]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToClosePrimingValveRecd]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToClosePrimingValves]= deal([]);
            [phaseRecords(1:length(stimSpecs)).actualPrimingDuration]= deal([]);
            
            [phaseRecords(1:length(stimSpecs)).containedManualPokes]= deal([]);
            [phaseRecords(1:length(stimSpecs)).leftWithManualPokingOn]= deal([]);
            [phaseRecords(1:length(stimSpecs)).containedAPause]= deal([]);
            [phaseRecords(1:length(stimSpecs)).didHumanResponse]= deal([]);
            [phaseRecords(1:length(stimSpecs)).containedForcedRewards]= deal([]);
            [phaseRecords(1:length(stimSpecs)).didStochasticResponse]= deal([]);
            
            % =========================================================================
            
            headroom=nan(1,responseDetails.numDetailedDrops);
            
            if ~isempty(rn)
                constants = getConstants(rn);
            end
            
            if strcmp(getRewardMethod(station),'serverPump')
                if isempty(rn) || ~isa(rn,'rnet')
                    error('need an rnet for station with rewardMethod of serverPump')
                end
            end
            
            [keyIsDown,secs,keyCode]=KbCheck; %load mex files into ram + preallocate return vars
            GetSecs;
            Screen('Screens');
            
            if window>0
                standardFontSize=12;
                oldFontSize = Screen('TextSize',window,standardFontSize);
                [normBoundsRect, offsetBoundsRect]= Screen('TextBounds', window, 'TEST');
            end
            
            KbName('UnifyKeyNames'); %does not appear to choose keynamesosx on windows - KbName('KeyNamesOSX') comes back wrong
            
            %consider using RestrictKeysForKbCheck for speedup of KbCheck
            
            KbConstants.allKeys=KbName('KeyNames');
            KbConstants.allKeys=lower(cellfun(@char,KbConstants.allKeys,'UniformOutput',false));
            KbConstants.controlKeys=find(cellfun(@(x) ~isempty(x),strfind(KbConstants.allKeys,'control')));
            KbConstants.shiftKeys=find(cellfun(@(x) ~isempty(x),strfind(KbConstants.allKeys,'shift')));
            KbConstants.kKey=KbName('k');
            KbConstants.pKey=KbName('p');
            KbConstants.qKey=KbName('q');
            KbConstants.mKey=KbName('m');
            KbConstants.aKey=KbName('a');
            KbConstants.rKey=KbName('r');
            KbConstants.tKey=KbName('t');
            KbConstants.fKey=KbName('f');
            KbConstants.eKey=KbName('e');
            KbConstants.atKeys=find(cellfun(@(x) ~isempty(x),strfind(KbConstants.allKeys,'@')));
            KbConstants.asciiOne=double('1');
            KbConstants.portKeys={};
            for i=1:length(ports)
                KbConstants.portKeys{i}=find(strncmp(char(KbConstants.asciiOne+i-1),KbConstants.allKeys,1));
            end
            KbConstants.numKeys={};
            for i=1:10
                KbConstants.numKeys{i}=find(strncmp(char(KbConstants.asciiOne+i-1),KbConstants.allKeys,1));
            end
            
            priorityLevel=MaxPriority('GetSecs','KbCheck');
            
            Priority(priorityLevel);
            
            % =========================================================================
            
            if ~isempty(eyeTracker)
                perTrialSyncing=false; %could pass this in if we ever decide to use it; now we don't
                if perTrialSyncing && isa(eyeTracker,'eyeLinkTracker')
                    status=Eyelink('message','SYNCTIME');
                    if status~=0
                        error('message error, status: %g',status)
                    end
                end
                
                framesPerAllocationChunk=getFramesPerAllocationChunk(eyeTracker);
                
                
                if isa(eyeTracker,'eyeLinkTracker')
                    eyeData=nan(framesPerAllocationChunk,length(getEyeDataVarNames(eyeTracker)));
                    eyeDataFrameInds=nan(framesPerAllocationChunk,1);
                    gaze=nan(framesPerAllocationChunk,2);
                else
                    error('no other methods')
                end
            end
            
            % =========================================================================
            
            didAPause=0;
            didManual=false;
            paused=0;
            pressingM=0;
            pressingP=0;
            framesSinceKbInput = 0;
            shiftDown=false;
            ctrlDown=false;
            atDown=false;
            kDown=false;
            portsDown=false(1,length(ports));
            pNum=0;
            
            trialRecords(trialInd).result=[]; %initialize
            trialRecords(trialInd).correct=[];
            analogOutput=[];
            startTime=0;
            logIt=true;
            lookForChange=false;
            punishResponses=[];
            
            % =========================================================================
            % do first frame and  any stimulus onset synched actions
            % make sure everything after this point is preallocated
            % efficiency is crticial from now on
            
            if window>0
                % draw interTrialLuminance first
                if true  % trunk should always leave this true, only false for a local test
                    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    interTrialTex=Screen('MakeTexture', window, interTrialLuminance,0,0,interTrialPrecision); %need floatprecision=0 for remotedesktop
                    Screen('DrawTexture', window, interTrialTex,phaseData{end}.destRect, [], filtMode);
                    [timestamps.vbl, sos, startTime]=Screen('Flip',window);
                else
                    % %to find out properties of the interTrialTex
                    %     allWindows=Screen('Windows');
                    %     texIDsThere=allWindows(find(Screen(allWindows,'WindowKind')==-1))
                    %     tx=screen('getImage',interTrialTex,[],[],2);
                    %     tx(:)
                    %     interTrialTex
                    %     sca
                    %     keyboard
                end
            end
            
            timestamps.lastFrameTime=GetSecs;
            timestamps.missesRecorded       = timestamps.lastFrameTime;
            timestamps.eyeTrackerDone       = timestamps.lastFrameTime;
            timestamps.kbCheckDone          = timestamps.lastFrameTime;
            timestamps.keyboardDone         = timestamps.lastFrameTime;
            timestamps.enteringPhaseLogic   = timestamps.lastFrameTime;
            timestamps.phaseLogicDone       = timestamps.lastFrameTime;
            timestamps.rewardDone           = timestamps.lastFrameTime;
            timestamps.serverCommDone       = timestamps.lastFrameTime;
            timestamps.phaseRecordsDone     = timestamps.lastFrameTime;
            timestamps.loopEnd              = timestamps.lastFrameTime;
            timestamps.prevPostFlipPulse    = timestamps.lastFrameTime;
            
            %show stim -- be careful in this realtime loop!
            while ~done && ~Quit;
                timestamps.loopStart=GetSecs;
                
                xOrigTextPos = 10;
                xTextPos=xOrigTextPos;
                yTextPos = 20;
                
                if updatePhase == 1
                    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    setStatePins(station,'stim',false);
                    setStatePins(station,'phase',true);
                    
                    startTime=GetSecs(); % startTime is now per-phase instead of per trial, since corresponding times in responseDetails are also per-phase
                    phaseNum=phaseNum+1;
                    if phaseNum>length(phaseRecords)
                        
                        nextPhaseRecordNum=length(phaseRecords)+1;
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).responseDetails]= deal(responseDetails);
                        
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).proposedRewardDurationMSorUL] = deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).proposedAirpuffDuration] = deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).proposedPenaltyDurationMSorUL] = deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).actualRewardDurationMSorUL] = deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).actualAirpuffDuration] = deal([]);
                        
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).valveErrorDetails]=deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToOpenValves]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToCloseValveRecd]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToCloseValves]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToRewardCompleted]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToRewardCompletelyDone]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).primingValveErrorDetails]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToOpenPrimingValves]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToClosePrimingValveRecd]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToClosePrimingValves]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).actualPrimingDuration]= deal([]);
                        
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).containedManualPokes]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).leftWithManualPokingOn]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).containedAPause]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).didHumanResponse]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).containedForcedRewards]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).didStochasticResponse]= deal([]);
                    end
                    
                    i=0;
                    frameIndex=0;
                    frameNum=1;
                    phaseStartTime=GetSecs;
                    firstVBLofPhase=timestamps.vbl;
                    
                    didPulse=0;
                    didValves=0;
                    arrowKeyDown=false;
                    
                    currentValveState=getValves(station); % if valve reward is still going from previous phase, we force it closed. in other words, make sure your phases are long enough for the rewards that happen in them!
                    serverValveChange=false;
                    serverValveStates=false;
                    didStochasticResponse=false;
                    didHumanResponse=false;
                    
                    % =========================================================================
                    phase = phaseData{phaseInd};
                    floatprecision = phase.floatprecision;
                    frameIndexed = phase.frameIndexed;
                    loop = phase.loop;
                    trigger = phase.trigger;
                    timeIndexed = phase.timeIndexed;
                    indexedFrames = phase.indexedFrames;
                    timedFrames = phase.timedFrames;
                    strategy = phase.strategy;
                    toggleStim = phase.toggleStim; %lickometer % now passed in from calcStim
                    phaseRecords(phaseNum).toggleStim=toggleStim; % flag for whether the end of a beam break ends the request state
                    destRect = phase.destRect;
                    textures = phase.textures;
                    
                    % =========================================================================
                    spec = stimSpecs{phaseInd};
                    stim = getStim(spec);
                    transitionCriterion = getTransitions(spec);
                    framesUntilTransition = getFramesUntilTransition(spec);
                    phaseType = getPhaseType(spec);
                    punishLastResponse=punishResponses;
                    punishResponses = getPunishResponses(spec);
                    
                    % =========================================================================
                    
                    framesInPhase = 0;
                    if ~isempty(getStartFrame(spec))
                        i=getStartFrame(spec);
                        framesInPhase=i;
                    end
                    
                    if ischar(strategy) && strcmp(strategy,'cache')
                        numFramesInStim = size(stim)-i;
                    elseif timeIndexed
                        if timedFrames(end)==0
                            numFramesInStim = Inf; % hold last frame, so even in 'cache' mode we are okay
                        else
                            numFramesInStim = sum(timedFrames);
                        end
                    else
                        numFramesInStim = Inf;
                    end
                    
                    isFinalPhase = getIsFinalPhase(spec);
                    autoTrigger = getAutoTrigger(spec);
                    
                    % =========================================================================
                    
                    phaseRecords(phaseNum).dynamicDetails=[];
                    phaseRecords(phaseNum).loop = loop;
                    phaseRecords(phaseNum).trigger = trigger;
                    phaseRecords(phaseNum).strategy = strategy;
                    phaseRecords(phaseNum).autoTrigger = autoTrigger;
                    phaseRecords(phaseNum).timeoutLengthInFrames = framesUntilTransition;
                    phaseRecords(phaseNum).floatprecision = floatprecision;
                    phaseRecords(phaseNum).phaseType = phaseType;
                    phaseRecords(phaseNum).phaseLabel = getPhaseLabel(spec);
                    
                    phaseRecords(phaseNum).responseDetails.startTime = startTime;
                    
                    updatePhase = 0;
                    
                    % =========================================================================
                    
                    setStatePins(station,'phase',false);
                    if isStim(spec)
                        setStatePins(station,'stim',true);
                    end
                    
                    if any(getLED(spec))
                        LEDStatus = getLED(spec);
                        setStatePins(station,'LED1',LEDStatus(1));
                        if length(LEDStatus)==2, setStatePins(station,'LED2',LEDStatus(2)); end
                    else
                        setStatePins(station,'LED1',false);
                        setStatePins(station,'LED2',false);
                    end
                    
                    if strcmp(tm.displayMethod,'LED')
                        station=stopPTB(station); %should handle this better -- LED setting is trialManager specific, so other training steps will expect ptb to still exist
                        %would prefer to never startPTB until a trialManager needs it,and then start it at the proper res the first time
                        %trialManager.doTrial should startPTB if it wants one and there isn't one, and stop it if there is one and it doesn't want it
                        %note that ifi is not coming in empty on the first trial and the leftover value from the screen is misleading, need to fix...
                        
                        didLEDphase=false;
                    end
                end % fininshed with phaseUpdate
                
                timestamps.phaseUpdated=GetSecs;
                doFramePulse=true;
                
                if ~paused
                    % here should be the function that also checks to see if we should assign trialRecords.correct
                    % and trialRecords.response, and also does tm-specific reward checks (nAFC should check to update reward/airpuff
                    % if first frame of a 'reinforced' phase)
                    [tm, trialRecords(trialInd).trialDetails, trialRecords(trialInd).result, spec, ...
                        rewardSizeULorMS, requestRewardSizeULorMS, ...
                        msPuff, msRewardSound, msPenalty, msPenaltySound, floatprecision, textures, destRect] = ...
                        updateTrialState(tm, stimManager, trialRecords(trialInd).result, spec, ports, lastPorts, ...
                        targetOptions, requestOptions, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                        floatprecision, textures, destRect, ...
                        requestRewardDone, punishLastResponse);
                    
                    
                    if rewardSizeULorMS~=0
                        doRequestReward=false;
                        msRewardOwed=msRewardOwed+rewardSizeULorMS;
                        phaseRecords(phaseNum).proposedRewardDurationMSorUL = rewardSizeULorMS;
                    elseif msPenalty~=0
                        doRequestReward=false;
                        msAirpuffOwed=msAirpuffOwed+msPuff;
                        phaseRecords(phaseNum).proposedAirpuffDuration = msPuff;
                        phaseRecords(phaseNum).proposedPenaltyDurationMSorUL = msPenalty;
                    end
                    framesUntilTransition=getFramesUntilTransition(spec);
                    stim=getStim(spec);
                    scaleFactor=getScaleFactor(spec);
                    
                    if requestRewardSizeULorMS~=0
                        doRequestReward=true;
                        msRequestRewardOwed=msRequestRewardOwed+requestRewardSizeULorMS;
                        phaseRecords(phaseNum).responseDetails.requestRewardPorts{end+1}=ports;
                        phaseRecords(phaseNum).responseDetails.requestRewardStartTime{end+1}=GetSecs();
                        phaseRecords(phaseNum).responseDetails.requestRewardDurationActual{end+1}=0;
                        
                        lastRequestPorts=ports;
                        playRequestSoundLoop=true;
                        requestRewardDone=true;
                    end
                    
                    lastPorts=ports;
                    
                    if strcmp(tm.displayMethod,'LED') && ~didLEDphase
                        [phaseRecords, analogOutput, outputsamplesOK, numSamps] = LEDphase(tm,phaseInd,analogOutput,phaseRecords,...
                            spec,interTrialLuminance,stim,frameIndexed,indexedFrames,loop,trigger,timeIndexed,timedFrames,station);
                        didLEDphase=true;
                    end
                end
                
                if window>0
                    if ~paused
                        scheduledFrameNum=ceil((GetSecs-firstVBLofPhase)/(framesPerUpdate*ifi)); %could include pessimism about the time it will take to get from here to the flip and how much advance notice flip needs
                        % this will surely have drift errors...
                        % note this does not take pausing into account -- edf thinks we should get rid of pausing
                        
                        switch strategy
                            case {'textureCache','noCache'}
                                [tm, frameIndex, i, done, doFramePulse, didPulse] ...
                                    = updateFrameIndexUsingTextureCache(tm, frameIndexed, loop, trigger, timeIndexed, frameIndex, indexedFrames, size(stim,3), isRequesting, ...
                                    i, frameNum, timedFrames, responseOptions, done, doFramePulse, didPulse, scheduledFrameNum);
                                try
                                    indexPulse=getIndexPulse(spec,i);
                                catch ex
                                    sca
                                    i
                                    warning('indexPulse problem because i=0... seems to be more of a problem during reinforcement... does this depend on timeouts?');
                                    getReport(ex)
                                    keyboard
                                end
                                
                                switch strategy
                                    case 'textureCache'
                                        drawFrameUsingTextureCache(tm, window, i, frameNum, size(stim,3), lastI, dontclear, textures(i), destRect, ...
                                            filtMode, labelFrames, xOrigTextPos, yTextPos);
                                    case 'noCache'
                                        drawFrameUsingTextureCache(tm, window, i, frameNum, size(stim,3), lastI, dontclear, squeeze(stim(:,:,i)), destRect, ...
                                            filtMode, labelFrames, xOrigTextPos, yTextPos,strategy,floatprecision);
                                end
                                
                            case 'expert'
                                [doFramePulse, expertCache, phaseRecords(phaseNum).dynamicDetails, textLabel, i, dontclear, indexPulse] ...
                                    = drawExpertFrame(stimManager,stim,i,phaseStartTime,totalFrameNum,window,textLabel,...
                                    destRect,filtMode,expertCache,ifi,scheduledFrameNum,tm.dropFrames,dontclear,...
                                    phaseRecords(phaseNum).dynamicDetails);
                            otherwise
                                sca;
                                keyboard
                                error('unrecognized strategy');
                        end
                        
                        setStatePins(station,'index',indexPulse);
                        
                        timestamps.frameDrawn=GetSecs;
                        
                        if frameDropCorner.on
                            Screen('FillRect', window, frameDropCorner.seq(frameDropCorner.ind), frameDropCorner.rect);
                            frameDropCorner.ind=frameDropCorner.ind+1;
                            if frameDropCorner.ind>length(frameDropCorner.seq)
                                frameDropCorner.ind=1;
                            end
                        end
                        
                        timestamps.frameDropCornerDrawn=GetSecs;
                        
                        %text commands are supposed to be last for performance reasons
                        if manual
                            didManual=1;
                        end
                        if window>=0 && showText
                            xTextPos = drawText(tm, window, labelFrames, subID, xOrigTextPos, yTextPos, normBoundsRect, stimID, protocolStr, ...
                                textLabel, trialLabel, i, frameNum, manual, didManual, didAPause, ptbVersion, ratrixVersion,phaseRecords(phaseNum).responseDetails.numMisses, phaseRecords(phaseNum).responseDetails.numApparentMisses, phaseInd, getStimType(spec),textType);
                        end
                        
                        timestamps.textDrawn=GetSecs;
                        
                    else
                        %do we need to copy previous screen?
                        %Screen('CopyWindow', window, window);
                        if window>=0
                            Screen('FillRect',window)
                            Screen('DrawText',window,'paused (k+p to toggle)',xTextPos,yTextPos,100*ones(1,3));
                        end
                    end
                    
                    [timestamps, headroom(totalFrameNum)] = flipFrameAndDoPulse(tm, window, dontclear, framesPerUpdate, ifi, paused, doFramePulse,station,timestamps);
                    lastI=i;
                    
                    [phaseRecords(phaseNum).responseDetails, timestamps] = ...
                        saveMissedFrameData(tm, phaseRecords(phaseNum).responseDetails, frameNum, timingCheckPct, ifi, timestamps);
                    
                    timestamps.missesRecorded=GetSecs;
                else
                    
                    if ~isempty(analogOutput) || window<=0 || strcmp(tm.displayMethod,'LED')
                        phaseRecords(phaseNum).LEDintermediateTimestamp=GetSecs; %need to preallocate
                        phaseRecords(phaseNum).intermediateSampsOutput=get(analogOutput,'SamplesOutput'); %need to preallocate
                        
                        if ~isempty(framesUntilTransition)
                            %framesUntilTransition is calculated off of the screen's ifi which is not correct when using LED
                            framesUntilTransition=framesInPhase+2; %prevent handlePhasedTrialLogic from tripping to next phase
                        end
                        
                        %note this logic is related to updateFrameIndexUsingTextureCache
                        if ~loop && (get(analogOutput,'SamplesOutput')>=numSamps || ~outputsamplesOK)
                            if isempty(responseOptions)
                                done=1;
                            end
                            if ~isempty(framesUntilTransition)
                                framesUntilTransition=framesInPhase+1; %cause handlePhasedTrialLogic to trip to next phase
                            end
                        end
                    end
                    
                end
                
                % =========================================================================
                
                if ~isempty(eyeTracker)
                    if ~checkRecording(eyeTracker)
                        sca
                        error('lost tracker connection!')
                    end
                    [gazeEstimates, samples] = getSamples(eyeTracker);
                    % gazeEstimates should be a Nx2 matrix, samples should be Nx43 matrix, totalFrameNum is the frame number we are on
                    numEyeTrackerSamples = size(samples,1);
                    
                    if (totalEyeDataInd+numEyeTrackerSamples)>length(eyeData) %if samples from this frame make us exceed size of eyeData
                        
                        %edf notes that this method is more expensive than necessary -- by expanding the matrix in this way, the old matrix still has to be copied in
                        %instead, consider using a cell array and adding your new allocation chunk as an {end+1} cell with your matrix of nans, then no copying will be necessary
                        %then you can concat all your cells at the end of the trial
                        
                        %  allocateMore
                        newEnd=length(eyeData)+ framesPerAllocationChunk;
                        %             disp(sprintf('did allocation to eyeTrack data; up to %d samples enabled',newEnd))
                        eyeData(end+1:newEnd,:)=nan;
                        eyeDataFrameInds(end+1:newEnd,:)=nan;
                        gaze(end+1:newEnd,:)=nan;
                    end
                    
                    if ~isempty(gazeEstimates) && ~isempty(samples)
                        gaze(totalEyeDataInd:totalEyeDataInd+numEyeTrackerSamples-1,:) = gazeEstimates;
                        eyeData(totalEyeDataInd:totalEyeDataInd+numEyeTrackerSamples-1,:) = samples;
                        eyeDataFrameInds(totalEyeDataInd:totalEyeDataInd+numEyeTrackerSamples-1,:) = totalFrameNum;
                        totalEyeDataInd = totalEyeDataInd + numEyeTrackerSamples;
                    end
                end
                
                timestamps.eyeTrackerDone=GetSecs;
                
                % =========================================================================
                % all trial logic follows
                
                if ~paused
                    ports=readPorts(station);
                end
                doValves=0*ports;
                doPuff=false;
                
                [keyIsDown,secs,keyCode]=KbCheck; % do this check outside of function to save function call overhead
                timestamps.kbCheckDone=GetSecs;
                
                if keyIsDown
                    [didAPause, paused, done, trialRecords(trialInd).result, doValves, ports, didValves, didHumanResponse, manual, ...
                        doPuff, pressingM, pressingP,timestamps.kbOverhead,timestamps.kbInit,timestamps.kbKDown] ...
                        = handleKeyboard(tm, keyCode, didAPause, paused, done, trialRecords(trialInd).result, doValves, ports, didValves, didHumanResponse, ...
                        manual, doPuff, pressingM, pressingP, originalPriority, priorityLevel, KbConstants);
                end
                
                timestamps.keyboardDone=GetSecs;
                
                % do stochastic port hits after keyboard so that wont happen if another port already triggered
                if ~paused
                    if ~isempty(autoTrigger) && ~any(ports)
                        for j=1:2:length(autoTrigger)
                            if rand<autoTrigger{j}
                                ports(autoTrigger{j+1}) = 1;
                                stochasticPorts = ports;
                                didStochasticResponse=true; %edf: shouldn't this only be if one was tripped?
                                break;
                            end
                        end
                    end
                end
                
                if ~paused
                    % end of a response
                    if lookForChange && any(ports~=lastPorts) % end of a response
                        phaseRecords(thisResponsePhaseNum).responseDetails.durs{end+1} = GetSecs() - respStart;
                        lookForChange=false;
                        logIt=true;
                        if ~toggleStim % beambreak mode (once request ends, stop showing stim)
                            isRequesting=~isRequesting;
                        end
                        
                        % 1/21/09 - how should we handle tries? - do we count attempts that occur during a phase w/ no port transitions (ie timeout only)?
                        % start of a response
                    elseif any(ports~=lastPorts) && logIt
                        phaseRecords(phaseNum).responseDetails.tries{end+1} = ports;
                        phaseRecords(phaseNum).responseDetails.times{end+1} = GetSecs() - startTime;
                        respStart = GetSecs();
                        playRequestSoundLoop = false;
                        logIt=false;
                        lookForChange=true;
                        thisResponsePhaseNum=phaseNum;
                    end
                end
                
                timestamps.enteringPhaseLogic=GetSecs;
                if ~paused
                    [tm, done, newSpecInd, phaseInd, updatePhase, transitionedByTimeFlag, ...
                        transitionedByPortFlag, trialRecords(trialInd).result, isRequesting, lastSoundsLooped, ...
                        timestamps.logicGotSounds, timestamps.logicSoundsDone, timestamps.logicFramesDone, ...
                        timestamps.logicPortsDone, timestamps.logicRequestingDone, goDirectlyToError] ...
                        = handlePhasedTrialLogic(tm, done, ...
                        ports, lastPorts, station, phaseInd, phaseType, transitionCriterion, framesUntilTransition, numFramesInStim, framesInPhase, isFinalPhase, ...
                        trialRecords(trialInd).trialDetails, trialRecords(trialInd).stimDetails, trialRecords(trialInd).result, ...
                        stimManager, msRewardSound, msPenaltySound, targetOptions, distractorOptions, requestOptions, ...
                        playRequestSoundLoop, isRequesting, soundNames, lastSoundsLooped);
                    % if goDirectlyToError, then reset newSpecInd to the first error phase in stimSpecs
                    if goDirectlyToError
                        newSpecInd=find(strcmp(cellfun(@getPhaseType,stimSpecs,'UniformOutput',false),'reinforced'));
                    end
                    
                    
                end
                timestamps.phaseLogicDone=GetSecs;
                
                % =========================================================================
                
                
                
                % =========================================================================
                % reward handling
                % calculate elapsed time since last loop, and decide whether to start/stop reward
                if isempty(thisRewardPhaseNum)
                    % default to this phase's phaseRecord, but we will hard-set this during a rStart, so that
                    % the last loop of a reward gets added to the correct N-th phaseRecord, instead of the (N+1)th
                    % this happens b/c the phaseNum gets updated before reward stuff...
                    thisRewardPhaseNum = phaseNum;
                end
                
                if ~isempty(lastRewardTime) && rewardCurrentlyOn
                    rewardCheckTime = GetSecs();
                    elapsedTime = rewardCheckTime - lastRewardTime;
                    if strcmp(getRewardMethod(station),'localTimed')
                        if ~doRequestReward % this was a normal reward, log it
                            msRewardOwed = msRewardOwed - elapsedTime*1000.0;
                            phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL = phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL + elapsedTime*1000.0;
                        else % this was a request reward, dont log it
                            msRequestRewardOwed = msRequestRewardOwed - elapsedTime*1000.0;
                            phaseRecords(thisRewardPhaseNum).responseDetails.requestRewardDurationActual{end}=phaseRecords(thisRewardPhaseNum).responseDetails.requestRewardDurationActual{end}+elapsedTime*1000.0;
                        end
                    elseif strcmp(getRewardMethod(station),'localPump')
                        % in localPump mode, msRewardOwed gets zeroed out after the call to station/doReward
                    end
                end
                lastRewardTime = GetSecs();
                rStart = msRewardOwed+msRequestRewardOwed > 0.0 && ~rewardCurrentlyOn;
                rStop = msRewardOwed+msRequestRewardOwed <= 0.0 && rewardCurrentlyOn;
                
                if rStart
                    thisRewardPhaseNum=phaseNum;
                    % used to properly put reward logging data in their respective phaseRecords
                    % default is current phase, but will set after rStart
                    stochasticPorts = forceRewards(tm,stochasticPorts);
                end
                
                if rStop % if stop, then reset owed time to zero
                    msRewardOwed=0;
                    msRequestRewardOwed=0;
                end
                currentValveStates=getValves(station);
                
                % =========================================================================
                % if any doValves, override this stuff
                % newValveState will be used to keep track of doValves stuff - figure out server-based use later
                if any(doValves~=newValveState)
                    switch getRewardMethod(station)
                        case 'localTimed'
                            [newValveState, phaseRecords(phaseNum).valveErrorDetails]=...
                                setAndCheckValves(station,doValves,currentValveStates,phaseRecords(phaseNum).valveErrorDetails,GetSecs,'doValves');
                        case 'localPump'
                            if any(doValves)
                                if window<=0 || strcmp(tm.displayMethod,'LED')
                                    ifi
                                    error('ifi will not be appropriate here when using LED')
                                else
                                    error('edf asks when this condition occurs?  shouldn''t all pump reward happen below in rStart?  primeMLsPerSec looks concerningly arbitrary.  is it for k+r (pump priming)?  in that case we need not be concerned about blocking/framedrops -- and the trial should be aborted with a flag that this happened.')
                                    % 3/3/09 - error for now if not in 'static' mode b/c doReward blocks real-time loop
                                    stimType=getStimType(spec);
                                    if ~ischar(stimType) || ~strcmp(stimType,'static')
                                        error('localPump only supported with a static stimulus until blocking is resolved');
                                    end
                                    primeMLsPerSec=1.0;
                                    station=doReward(station,primeMLsPerSec*ifi,doValves,true);
                                end
                            end
                            newValveState=0*doValves; % set newValveStates to 0 because localPump locks the loop while calling doReward
                        otherwise
                            error('unsupported rewardMethod');
                    end
                    
                else
                    if rStart || rStop
                        rewardValves=zeros(1,getNumPorts(station));
                        % we give the reward at whatever port is specified by the current phase (weird...fix later?)
                        % the default if the current phase does not have a transition port is the requestOptions (input to stimOGL)
                        % 1/29/09 - fix, but for now rewardValves is jsut wahtever the current port triggered is (this works for now..)
                        if strcmp(class(ports),'double') %happens on osx, why?
                            ports=logical(ports);
                        end
                        rewardValves(ports|stochasticPorts)=1;
                        
                        rewardValves=logical(rewardValves);
                        
                        
                        
                        if length(rewardValves) ~= 3
                            error('rewardValves has %d and currentValveStates has %d with port = %d', length(rewardValves), length(currentValveStates), port);
                        end
                        
                        switch getRewardMethod(station)
                            case 'localTimed'
                                if rStart
                                    rewardValves = forceRewards(tm,rewardValves); % used in the reinforced autopilot state
                                    rewardCurrentlyOn = true;
                                    [currentValveStates, phaseRecords(thisRewardPhaseNum).valveErrorDetails]=...
                                        setAndCheckValves(station,rewardValves,currentValveStates,phaseRecords(thisRewardPhaseNum).valveErrorDetails,lastRewardTime,'correct reward open');
                                elseif rStop
                                    rewardCurrentlyOn = false;
                                    [currentValveStates, phaseRecords(thisRewardPhaseNum).valveErrorDetails]=...
                                        setAndCheckValves(station,zeros(1,getNumPorts(station)),currentValveStates,phaseRecords(thisRewardPhaseNum).valveErrorDetails,lastRewardTime,'correct reward close');
                                    % also add the additional time that reward was on from rewardCheckTime to now
                                    rewardCheckToValveCloseTime = GetSecs() - rewardCheckTime;
                                    %                         rewardCheckToValveCloseTime
                                    if ~doRequestReward
                                        phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL = phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL + rewardCheckToValveCloseTime*1000.0;
                                        %                             phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL
                                        %                             'stopping normal reward'
                                    else
                                        phaseRecords(thisRewardPhaseNum).responseDetails.requestRewardDurationActual{end}=phaseRecords(thisRewardPhaseNum).responseDetails.requestRewardDurationActual{end}+rewardCheckToValveCloseTime*1000.0;
                                        %                             'stopping request reward'
                                    end
                                    % newValveState=doValves|rewardValves; % this shouldnt be used for now...figure out later...
                                else
                                    error('has to be either start or stop - should not be here');
                                end
                            case 'localPump'
                                if rStart
                                    rewardCurrentlyOn=true;
                                    % 3/3/09 - error for now if not in 'static' mode b/c doReward blocks real-time loop
                                    stimType=getStimType(spec);
                                    if ~ischar(stimType) || ~strcmp(stimType,'static')
                                        error('localPump only supported with a static stimulus until blocking is resolved');
                                    end
                                    station=doReward(station,(msRewardOwed+msRequestRewardOwed)/1000,rewardValves);
                                    phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL = phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL + msRewardOwed;
                                    msRewardOwed=0;
                                    msRequestRewardOwed=0;
                                    requestRewardDone=true;
                                elseif rStop
                                    rewardCurrentlyOn=false;
                                end
                            case 'serverPump'
                                
                                [currentValveState,phaseRecords(thisRewardPhaseNum).valveErrorDetails,...
                                    Quit,serverValveChange, phaseRecords(thisRewardPhaseNum).responseDetails,...
                                    requestRewardStartLogged, requestRewardDurLogged, phaseRecords(thisRewardPhaseNum)] = ...
                                    serverPumpRewards(tm, rn, station, newValveState, currentValveState, ...
                                    phaseRecords(thisRewardPhaseNum).valveErrorDetails,startTime, serverValveChange, ...
                                    requestRewardStarted,requestRewardStartLogged, rewardValves, requestRewardDone,...
                                    requestRewardDurLogged, phaseRecords(thisRewardPhaseNum).responseDetails, Quit, ...
                                    phaseRecords(thisRewardPhaseNum));
                                
                            otherwise
                                error('unsupported rewardMethod');
                        end
                    end
                    
                end % end valves
                
                timestamps.rewardDone=GetSecs;
                
                if ~isempty(rn) || strcmp(getRewardMethod(station),'serverPump')
                    [done, Quit, phaseRecords(thisRewardPhaseNum).valveErrorDetails, serverValveStates, serverValveChange, ...
                        trialRecords(trialInd).result, newValveState, ...
                        requestRewardDone, requestRewardOpenCmdDone] ...
                        = handleServerCommands(tm, rn, done, Quit, requestRewardStarted, ...
                        requestRewardStartLogged, requestRewardOpenCmdDone, ...
                        requestRewardDone, station, ports, serverValveStates, doValves, ...
                        trialRecords(trialInd).result);
                elseif isempty(rn) && strcmp(getRewardMethod(station),'serverPump')
                    error('need a rnet for serverPump')
                end
                
                % also do datanet handling here
                % this should only handle 'server Quit' commands for now.... (other stuff is caught by doTrial/bootstrap)
                if ~isempty(getDatanet(station))
                    [~, Quit] = handleCommands(getDatanet(station),[]);
                end
                
                timestamps.serverCommDone=GetSecs;
                
                % =========================================================================
                % airpuff
                if isempty(thisAirpuffPhaseNum)
                    thisAirpuffPhaseNum=phaseNum;
                end
                
                if ~isempty(lastAirpuffTime) && airpuffOn
                    airpuffCheckTime = GetSecs();
                    elapsedTime = airpuffCheckTime - lastAirpuffTime;
                    msAirpuffOwed = msAirpuffOwed - elapsedTime*1000.0;
                    phaseRecords(thisAirpuffPhaseNum).actualAirpuffDuration = phaseRecords(thisAirpuffPhaseNum).actualAirpuffDuration + elapsedTime*1000.0;
                end
                
                aStart = msAirpuffOwed > 0 && ~airpuffOn;
                aStop = msAirpuffOwed <= 0 && airpuffOn; % msAirpuffOwed<=0 also catches doPuff==false, and will stop airpuff when k+a is lifted
                if aStart || doPuff
                    thisAirpuffPhaseNum = phaseNum; % set default airpuff phase num
                    setPuff(station, true);
                    airpuffOn = true;
                elseif aStop
                    doPuff = false;
                    airpuffOn = false;
                    setPuff(station, false);
                    airpuffCheckToSetPuffTime = GetSecs() - airpuffCheckTime; % time from the airpuff check to after setPuff returns
                    % increase actualAirpuffDuration by this 'lag' time...
                    phaseRecords(thisAirpuffPhaseNum).actualAirpuffDuration = phaseRecords(thisAirpuffPhaseNum).actualAirpuffDuration + airpuffCheckToSetPuffTime*1000.0;
                end
                lastAirpuffTime = GetSecs();
                
                % =========================================================================
                
                if updatePhase
                    phaseRecords(phaseNum).transitionedByPortResponse = transitionedByPortFlag;
                    phaseRecords(phaseNum).transitionedByTimeout = transitionedByTimeFlag;
                    phaseRecords(phaseNum).containedManualPokes = didManual;
                    phaseRecords(phaseNum).leftWithManualPokingOn = manual;
                    phaseRecords(phaseNum).containedAPause = didAPause;
                    phaseRecords(phaseNum).containedForcedRewards = didValves;
                    phaseRecords(phaseNum).didHumanResponse = didHumanResponse;
                    phaseRecords(phaseNum).didStochasticResponse = didStochasticResponse;
                    
                    phaseRecords(phaseNum).responseDetails.totalFrames = frameNum;
                    % how do we only clear the textures from THIS phase (since all textures for all phases are precached....)
                    % close all textures from this phase if in non-expert mode
                    %         if ~strcmp(strategy,'expert')
                    %             Screen('Close');
                    %         else
                    %             expertCleanUp(stimManager);
                    %         end
                    containedExpertPhase=strcmp(strategy,'expert') || containedExpertPhase;
                end
                
                timestamps.phaseRecordsDone=GetSecs;
                
                if ~paused
                    framesInPhase = framesInPhase + 1; % moved from handlePhasedTrialLogic to prevent copy on write
                    
                    phaseInd = newSpecInd;
                    frameNum = frameNum + 1;
                    totalFrameNum = totalFrameNum + 1;
                    framesSinceKbInput = framesSinceKbInput + 1;
                end
                timestamps.loopEnd=GetSecs;
            end
            
            securePins(station);
            
            trialRecords(trialInd).phaseRecords=phaseRecords;
            % per-trial records, collected from per-phase stuff
            trialRecords(trialInd).containedAPause=any([phaseRecords.containedAPause]);
            trialRecords(trialInd).didHumanResponse=any([phaseRecords.didHumanResponse]);
            trialRecords(trialInd).containedForcedRewards=any([phaseRecords.containedForcedRewards]);
            trialRecords(trialInd).didStochasticResponse=any([phaseRecords.didStochasticResponse]);
            trialRecords(trialInd).containedManualPokes=didManual;
            trialRecords(trialInd).leftWithManualPokingOn=manual;
            
            if ~isempty(analogOutput)
                evts=showdaqevents(analogOutput);
                if ~isempty(evts)
                    evts
                end
                
                stop(analogOutput);
                delete(analogOutput); %should pass back to caller and preserve for next trial so intertrial works and can avoid contruction costs
            end
            
            
            if ~containedExpertPhase
                Screen('Close'); %leaving off second argument closes all textures but leaves windows open
            else
                %maybe once this was per phase, but now its per trial
                expertPostTrialCleanUp(stimManager);
            end
            
            
            Priority(originalPriority);
            
            
        end 
        
        function [responseDetails timestamps] = saveMissedFrameData(tm, responseDetails, frameNum, timingCheckPct, ifi, timestamps)
            
            debug=false;
            type='';
            thisIFI=timestamps.vbl-timestamps.lastFrameTime;
            
            if timestamps.missed>0
                type='caught';
                responseDetails.numMisses=responseDetails.numMisses+1;
                
                if  responseDetails.numMisses<responseDetails.numDetailedDrops
                    
                    responseDetails.misses(responseDetails.numMisses)=frameNum;
                    responseDetails.afterMissTimes(responseDetails.numMisses)=GetSecs();
                    responseDetails.missIFIs(responseDetails.numMisses)=thisIFI;
                    if tm.saveDetailedFramedrops
                        responseDetails.missTimestamps(responseDetails.numMisses)=timestamps; %need to figure out: Error: Subscripted assignment between dissimilar structures
                    end
                else
                    responseDetails.numUnsavedMisses=responseDetails.numUnsavedMisses+1;
                end
                
            else
                thisIFIErrorPct = abs(1-thisIFI/ifi);
                if  thisIFIErrorPct > timingCheckPct
                    type='unnoticed';
                    
                    responseDetails.numApparentMisses=responseDetails.numApparentMisses+1;
                    
                    if responseDetails.numApparentMisses<responseDetails.numDetailedDrops
                        responseDetails.apparentMisses(responseDetails.numApparentMisses)=frameNum;
                        responseDetails.afterApparentMissTimes(responseDetails.numApparentMisses)=GetSecs();
                        responseDetails.apparentMissIFIs(responseDetails.numApparentMisses)=thisIFI;
                        if tm.saveDetailedFramedrops
                            responseDetails.apparentMissTimestamps(responseDetails.numApparentMisses)=timestamps; %need to figure out: Error: Subscripted assignment between dissimilar structures
                        end
                    else
                        responseDetails.numUnsavedApparentMisses=responseDetails.numUnsavedApparentMisses+1;
                    end
                    
                end
            end
            
            if ~strcmp(type,'') && debug
                printDroppedFrameReport(1,timestamps,frameNum,thisIFI,ifi,type); %fid=1 is stdout (screen)
            end
            
            timestamps.lastFrameTime=timestamps.vbl;
            timestamps.prevPostFlipPulse=timestamps.postFlipPulse;
            
        end
        
        function frameDropCorner = setCLUTandFrameDropCorner(tm, window, station, LUT, frameDropCorner)
            
            if window>=0
                [scrWidth scrHeight]=Screen('WindowSize', window);
            else
                scrWidth=getWidth(station);
                scrHeight=getHeight(station);
            end
            
            if window>=0
                scrRect = Screen('Rect', window);
                scrLeft = scrRect(1); %am i retarted?  why isn't [scrLeft scrTop scrRight scrBottom]=Screen('Rect', window); working?  deal doesn't work
                scrTop = scrRect(2);
                scrRight = scrRect(3);
                scrBottom = scrRect(4);
                scrWidth= scrRight-scrLeft;
                scrHeight=scrBottom-scrTop;
            else
                scrLeft = 0;
                scrTop = 0;
            end
            
            frameDropCorner.left  =scrLeft               + scrWidth *(frameDropCorner.loc(2) - frameDropCorner.size(2)/2);
            frameDropCorner.right =frameDropCorner.left  + scrWidth *frameDropCorner.size(2);
            frameDropCorner.top   =scrTop                + scrHeight*(frameDropCorner.loc(1) - frameDropCorner.size(1)/2);
            frameDropCorner.bottom=frameDropCorner.top   + scrHeight*frameDropCorner.size(1);
            frameDropCorner.rect=[frameDropCorner.left frameDropCorner.top frameDropCorner.right frameDropCorner.bottom];
            
            [oldCLUT, dacbits, reallutsize] = Screen('ReadNormalizedGammaTable', window);
            
            if isreal(LUT) && all(size(LUT)==[256 3])
                if any(LUT(:)>1) || any(LUT(:)<0)
                    error('LUT values must be normalized values between 0 and 1')
                end
                try
                    oldCLUT = Screen('LoadNormalizedGammaTable', window, LUT,0); %apparently it's ok to use a window ptr instead of a screen ptr, despite the docs
                catch ex
                    %if the above fails, we lose our window
                    
                    ex.message
                    error('couldnt set clut')
                end
                currentCLUT = Screen('ReadNormalizedGammaTable', window);
                
                if all(all(abs(currentCLUT-LUT)<0.00001))
                    %pass
                else
                    oldCLUT
                    currentCLUT
                    LUT             %requested
                    currentCLUT-LUT %error
                    error('the LUT is not what you think it is')
                end
                
                switch tm.frameDropCorner{1}
                    case 'off'
                    case 'flickerRamp'
                        inds=findClosestInds(tm.frameDropCorner{2},mean(currentCLUT'));
                        frameDropCorner.seq=size(currentCLUT,1):-1:inds(1);
                        frameDropCorner.seq(2,:)=inds(2);
                        frameDropCorner.seq=frameDropCorner.seq(:); %interleave them
                    case 'sequence'
                        frameDropCorner.seq=findClosestInds(tm.frameDropCorner{2},mean(currentCLUT'));
                    otherwise
                        error('shouldn''t happen')
                end
            else
                reallutsize
                error('LUT must be real 256 X 3 matrix')
            end
            
        end
        
        function [tm quit trialRecords eyeData eyeDataFrameInds gaze station ratrixSVNInfo ptbSVNInfo] ...
                = stimOGL(tm, stimSpecs, startingStimSpecInd, stimManager, LUT, targetOptions, distractorOptions, requestOptions, interTrialLuminance, ...
                station, manual,timingCheckPct,textLabel,rn,subID,stimID,protocolStr,trialLabel,eyeTracker,msAirpuff,trialRecords)
            % This function gets ready for stimulus presentation by precaching textures (unless expert mode), and setting up some other small stuff.
            % All of the actual real-time looping is handled by runRealTimeLoop.
            
            
            verbose = false;
            responseOptions = union(targetOptions, distractorOptions);
            
            originalPriority = Priority;
            
            %ListenChar(2);
            %FlushEvents('keyDown');
            %edf moved these to station.doTrials() so that we don't get garbage sent to matlab windows from between-trial keypresses.
            %however, whether they're here or there, we still seem to get garbage -- figure out why!
            %something wrong with flushevents?
            
            phaseData = cell(1,length(stimSpecs));
            
            if strcmp(tm.displayMethod,'ptb')
                window=getPTBWindow(station);
                if window<=0
                    error('window must be >0')
                end
                HideCursor;
            else
                window=0;
            end
            ifi=getIFI(station);
            
            frameDropCorner.size=[.05 .05];
            frameDropCorner.loc=[1 0];
            frameDropCorner.on=~strcmp(tm.frameDropCorner{1},'off');
            frameDropCorner.ind=1;
            
            try
                [garbage ptbVer]=PsychtoolboxVersion;
                ptbVersion=sprintf('%d.%d.%d(%s %s)',ptbVer.major,ptbVer.minor,ptbVer.point,ptbVer.flavor,ptbVer.revstring);
                ptbSVNInfo=sprintf('%d.%d.%d%s at %d',ptbVer.major,ptbVer.minor,ptbVer.point,ptbVer.flavor,ptbVer.revision);
                try
                    [runningSVNversion repositorySVNversion url]=getSVNRevisionFromXML(getRatrixPath);
                    ratrixVersion=sprintf('%s (%d of %d)',url,runningSVNversion,repositorySVNversion);
                    ratrixSVNInfo=sprintf('%s@%d',url,runningSVNversion);
                catch ex
                    ratrixVersion='no network connection';
                    ratrixSVNInfo = ratrixVersion;
                end
                frameDropCorner = setCLUTandFrameDropCorner(tm, window, station, LUT, frameDropCorner);
                
                for i=1:length(stimSpecs)
                    spec = stimSpecs{i};
                    stim = getStim(spec);
                    type = getStimType(spec);
                    metaPixelSize = getScaleFactor(spec);
                    framesUntilTransition = getFramesUntilTransition(spec);
                    
                    [phaseData{i}.loop phaseData{i}.trigger phaseData{i}.frameIndexed phaseData{i}.timeIndexed ...
                        phaseData{i}.indexedFrames phaseData{i}.timedFrames phaseData{i}.strategy phaseData{i}.toggleStim] = determineStrategy(tm, stim, type, responseOptions, framesUntilTransition);
                    
                    [phaseData{i}.floatprecision stim] = determineColorPrecision(tm, stim, phaseData{i}.strategy);
                    stimSpecs{i}=setStim(spec,stim);
                    
                    if window>0
                        phaseData{i}.destRect = determineDestRect(tm, window, station, metaPixelSize, stim, phaseData{i}.strategy);
                        
                        phaseData{i}.textures = cacheTextures(tm, phaseData{i}.strategy, stim, window, phaseData{i}.floatprecision);
                    else
                        
                        phaseData{i}.destRect=[];
                        phaseData{i}.textures=[];
                        
                    end
                end
                
                [interTrialPrecision interTrialLuminance] = determineColorPrecision(tm, interTrialLuminance, 'static');
                
                [tm quit trialRecords eyeData eyeDataFrameInds gaze frameDropCorner station] ...
                    = runRealTimeLoop(tm, window, ifi, stimSpecs, startingStimSpecInd, phaseData, stimManager, ...
                    targetOptions, distractorOptions, requestOptions, interTrialLuminance, interTrialPrecision, ...
                    station, manual,timingCheckPct,textLabel,rn,subID,stimID,protocolStr,ptbVersion,ratrixVersion,trialLabel,msAirpuff, ...
                    originalPriority, verbose,eyeTracker,frameDropCorner,trialRecords);
                
            catch ex
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                
                securePins(station);
                
                Screen('CloseAll');
                Priority(originalPriority);
                ShowCursor(0);
                FlushEvents('mouseUp','mouseDown','keyDown','autoKey','update');
                ListenChar(0);
                
                if IsWin
                    daqreset;
                end
                
                if ~isempty(eyeTracker)
                    cleanUp(eyeTracker);
                end
                
                trialRecords(end).response=sprintf('error_in_StimOGL: %s',ex.message);
                
                rethrow(ex);
            end
        end
        
        
        function [tm frameIndex i done doFramePulse didPulse] ...
                = updateFrameIndexUsingTextureCache(tm, frameIndexed, loop, trigger, timeIndexed, frameIndex, indexedFrames,...
                stimSize, isRequesting, ...
                i, frameNum, timedFrames, responseOptions, done, doFramePulse, didPulse, scheduledFrameNum)
            
            % This method calculates the correct frame index (which frame of the movie to play at the given loop)
            
            if frameIndexed
                if loop
                    if tm.dropFrames
                        frameIndex = mod(scheduledFrameNum,length(indexedFrames));
                        if frameIndex==0
                            frameIndex=length(indexedFrames);
                        end
                    else
                        % frameIndex = mod(frameIndex,length(indexedFrames)-1)+1; %02.03.09 edf notices this has same problem as loop condition (next). changing to:
                        frameIndex = mod(frameIndex,length(indexedFrames))+1;
                    end
                else
                    if tm.dropFrames
                        frameIndex = min(length(indexedFrames),scheduledFrameNum);
                    else
                        frameIndex = min(length(indexedFrames),frameIndex+1);
                    end
                end
                i = indexedFrames(frameIndex);
            elseif loop
                if tm.dropFrames
                    i = mod(scheduledFrameNum,stimSize);
                    if i==0
                        i=stimSize;
                    end
                else
                    % i = mod(i,stimSize-1)+1; %original was incorrect!  never gets to last frame
                    
                    % 8/16/08 - changed to:
                    %     i = mod(i+1,stimSize);
                    %     if i == 0
                    %         i = stimSize;
                    %     end
                    
                    % 02.03.09 edf changing to:
                    i = mod(i,stimSize)+1;
                end
                
            elseif trigger
                if isRequesting
                    i=1;
                else
                    i=2;
                end
                
            elseif timeIndexed
                
                %should precache cumsum(double(timedFrames))
                if tm.dropFrames
                    i=min(find(scheduledFrameNum<=cumsum(double(timedFrames))));
                else
                    i=min(find(frameNum<=cumsum(double(timedFrames))));
                end
                
                if isempty(i)  %if we have passed the last stim frame
                    i=length(timedFrames);  %hold the last frame if the last frame duration specified was zero
                    if timedFrames(end)
                        error('currently broken')
                        
                        i=i+1;      %otherwise move on to the finalScreenLuminance blank screen -- this will probably error on the phased architecture, need to advance phase, but it's too late by this point?
                        % from fan:
                        % > i think this would have to be handled by the framesUntilTransition timeout.
                        % > it would be up to the user to correctly pass in a framesUntilTransition
                        % > argument of 600 frames if they vector of timedFrames sums up to 600 and does
                        % > not end in zero. phaseify could automatically handle this, but new calcStims
                        % > would have to be aware of this.
                        
                    end
                end
                
            else
                
                if tm.dropFrames
                    i=min(scheduledFrameNum,stimSize);
                else
                    i=min(i+1,stimSize);
                end
                
                if isempty(responseOptions) && i==stimSize
                    done=1;
                end
                
                if i==stimSize && didPulse
                    doFramePulse=0;
                end
                didPulse=1;
            end
            
            
        end
    end
end
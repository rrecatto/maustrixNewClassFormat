classdef manualCmrMotionEyeCal
    
    properties
        background=[];
        numSweeps=[];

        LUT=[];
        LUTbits=0;

        % constant values for this stim manager - drawExpertFrame will reference these values
        stateValues={'initialize','move camera to A','recording at A','move camera to B','recording at B','done'};
        stateTransitionValues=[2 3 4 5 2 1];
        stateDurationValues=[10 10 5 10 5 10]; % in seconds
    end
    
    methods
        function s=manualCmrMotionEyeCal(varargin)
            % MANUALCMRMOTIONEYECAL  class constructor.

            % s = manualCmrMotionEyeCal(background,numSweeps,
            %       maxWidth,maxHeight,scaleFactor,interTrialLuminance)

            switch nargin
                case 0
                    % if no input arguments, create a default object

                    s = class(s,'manualCmrMotionEyeCal',stimManager());
                case 1
                    % if input is of this class type
                    if (isa(varargin{1},'manualCmrMotionEyeCal'))
                        s = varargin{1};
                    else
                        error('Input argument is not a manualCmrMotionEyeCal object')
                    end
                case 6
                    % create object using specified values

                    % background
                    if isscalar(varargin{1})
                        s.background = varargin{1};
                    else
                        error('background must be a scalar');
                    end
                    % numSweeps
                    if isscalar(varargin{2}) && isinteger(varargin{2}) && varargin{2}>0
                        s.numSweeps=varargin{2};
                    else
                        error('numSweeps must be a positive integer');
                    end

                    s = class(s,'manualCmrMotionEyeCal',stimManager(varargin{3},varargin{4},varargin{5},varargin{6}));
                otherwise
                    error('invalid number of input arguments');
            end

        end % end function

        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =...
    calcStim(stimulus,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % see ratrixPath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)
            % 1/3/0/09 - trialRecords now includes THIS trial
            indexPulses=[];
            imagingTasks=[];
            LUTbits
            displaySize
            [LUT stimulus updateSM]=getLUT(stimulus,LUTbits);
            [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
            % [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[ 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));

            if isnan(resolutionIndex)
                resolutionIndex=1;
            end

            toggleStim=true;
            type = 'expert';
            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus);

            details=[];
            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);

            % ================================================================================
            background = stimulus.background;

            % 10/31/08 - dynamic mode stim is a struct of parameters
            stim = [];
            stim.height = min(height,getMaxHeight(stimulus));
            stim.width = min(width,getMaxWidth(stimulus));
            stim.background=background;

            discrimStim=[];
            discrimStim.stimulus=stim;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            onlyOnce=find(ismember(stimulus.stateValues,{'initialize','done'}));
            discrimStim.framesUntilTimeout=hz*...
                (sum(double(stimulus.stateDurationValues(setdiff(1:length(stimulus.stateDurationValues),onlyOnce))))...
                *double(stimulus.numSweeps)+sum(double(stimulus.stateDurationValues(onlyOnce))));
            preRequestStim=[];
            preRequestStim.stimulus=interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;

            preResponseStim=discrimStim;
            preResponseStim.punishResponses=false;

            % details.big = {'expert', stim.seedValues}; % store in 'big' so it gets written to file
            % variables to be stored for recalculation of stimulus from seed value for rand generator
            details.strategy='expert';
            details.height=stim.height;
            details.width=stim.width;
            % =============================
            % do a bunch of stuff to get the correct frame indices for the recording intervals (so physAnalysis can access these values in the stimRecord)
            details.recordingIntervalsA=[];
            details.recordingIntervalsB=[];

            Aind=find(strcmp(stimulus.stateValues,'recording at A'));
            Bind=find(strcmp(stimulus.stateValues,'recording at B'));
            Agap=hz*stimulus.stateDurationValues(Aind);
            Atransition=stimulus.stateTransitionValues(Aind);
            while Atransition~=Aind
                Agap=Agap+stimulus.stateDurationValues(Atransition)*hz;
                Atransition=stimulus.stateTransitionValues(Atransition);
            end
            Bgap=hz*stimulus.stateDurationValues(Bind);
            Btransition=stimulus.stateTransitionValues(Bind);
            while Btransition~=Bind
                Bgap=Bgap+stimulus.stateDurationValues(Btransition)*hz;
                Btransition=stimulus.stateTransitionValues(Btransition);
            end

            for i=1:double(stimulus.numSweeps)
                details.recordingIntervalsA(i,1)=hz*sum(stimulus.stateDurationValues(1:Aind-1))+1+(i-1)*Agap;
                details.recordingIntervalsA(i,2)=hz*sum(stimulus.stateDurationValues(1:Aind))+(i-1)*Agap;
                details.recordingIntervalsB(i,1)=hz*sum(stimulus.stateDurationValues(1:Bind-1))+1+(i-1)*Bgap;
                details.recordingIntervalsB(i,2)=hz*sum(stimulus.stateDurationValues(1:Bind))+(i-1)*Bgap;
            end


            % ================================================================================
            text='expert manualCmrMotionEyeCal';

        end % end function
        
        function [doFramePulse expertCache dynamicDetails textLabel i dontclear indexPulse] = ...
    drawExpertFrame(stimulus,stim,i,phaseStartTime,totalFrameNum,window,textLabel,destRect,filtMode,...
    expertCache,ifi,scheduledFrameNum,dropFrames,dontclear,dynamicDetails)
            % 10/31/08 - implementing expert mode for whiteNoise
            % this function calculates a expert frame, and then makes and draws the texture; nothing needs to be done in runRealTimeLoop
            % this should be a stimManager-specific implementation (if expert mode is supported for the given stimulus)
            indexPulse=false;

            numSweepsToDo=stimulus.numSweeps;

            % increment i
            if dropFrames
                i=scheduledFrameNum;
            else
                i=i+1;
            end
            % stimulus = stimManager
            doFramePulse=true;

            if isempty(dynamicDetails)
                dynamicDetails.recordingIntervalsA=[];
                dynamicDetails.recordingIntervalsB=[];
            end
            Asize=size(dynamicDetails.recordingIntervalsA,1);
            Bsize=size(dynamicDetails.recordingIntervalsB,1);
            % ================================================================================

            %background
            Screen('FillRect', window, stimulus.background*WhiteIndex(window));
            % % 11/14/08 - moved the make and draw to stimManager specific getexpertFrame b/c they might draw differently
            % % dynTex = Screen('MakeTexture', window, expertFrame,0,0,floatprecision);
            % % Screen('DrawTexture', window, dynTex,[],stimLocation,[],filtMode);
            % % % clear dynTex from vram
            % % Screen('Close',dynTex);

            % text options
            xTextPos=25;
            yTextPos=55;

            % calculate the stim logic (what camera position, init, move camera, etc)
            % currently allowed states:
            %   'initialize'
            %   'move camera to A'
            %   'recording at A'
            %   'move camera to B'
            %   'recording at B'
            %   'done'

            if isempty(expertCache)
                expertCache.state='initialize';
                expertCache.startFrameOfCurrentPosition=totalFrameNum;
                expertCache.numSweepsDone=0;
            end
            elapsedFrames=totalFrameNum-expertCache.startFrameOfCurrentPosition;
            elapsed=elapsedFrames*ifi;
            ind=find(strcmp(expertCache.state,stimulus.stateValues));

            % check for transition to next state
            if elapsed>=stimulus.stateDurationValues(ind)
                if strcmp(expertCache.state,'recording at B')
                    % end of a recording interval at B
                    dynamicDetails.recordingIntervalsB(Bsize,2)=totalFrameNum-1;
                    expertCache.numSweepsDone=expertCache.numSweepsDone+1;
                elseif strcmp(expertCache.state,'recording at A')
                    dynamicDetails.recordingIntervalsA(Asize,2)=totalFrameNum-1;
                elseif strcmp(expertCache.state,'done')
                    expertCache.numSweepsDone=0;
                end
                if expertCache.numSweepsDone==numSweepsToDo
                    expertCache.state='done';
                else
                    expertCache.state=stimulus.stateValues{stimulus.stateTransitionValues(ind)};
                end
                elapsed=0;
                ind=find(strcmp(expertCache.state,stimulus.stateValues));
                expertCache.startFrameOfCurrentPosition=totalFrameNum;
            end

            % logic for storing recording intervals (in terms of frame indices -> eyeDataStimInds)
            if expertCache.startFrameOfCurrentPosition==totalFrameNum % that means this frame is the first of a new position
                if strcmp(expertCache.state,'recording at A')
                    dynamicDetails.recordingIntervalsA(Asize+1,1)=totalFrameNum;
                elseif strcmp(expertCache.state,'recording at B')
                    dynamicDetails.recordingIntervalsB(Bsize+1,1)=totalFrameNum;
                end
            end

            % show appropriate text
            txt=sprintf('%d frames have elapsed (%d remaining) in state %s totalFrameNum:%d',...
                elapsedFrames,floor((stimulus.stateDurationValues(ind)-elapsed)/ifi),expertCache.state,totalFrameNum);
            Screen('DrawText',window,txt,xTextPos,yTextPos,100*ones(1,3));
            yTextPos=yTextPos+15;
            txt=sprintf('numSweepsDone: %d/%d',expertCache.numSweepsDone,numSweepsToDo);
            Screen('DrawText',window,txt,xTextPos,yTextPos,100*ones(1,3));

        end % end function

        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;

            try
                stimDetails=[trialRecords.stimDetails];
                [out.strategy newLUT] = extractFieldAndEnsure(stimDetails,{'strategy'},'scalarLUT',newLUT);

            catch ex
                out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                verifyAllFieldsNCols(out,length(trialRecords));
                return
            end

            verifyAllFieldsNCols(out,length(trialRecords));
        end
        
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
                case 'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5'
                    conn=dbConn();
                    [junk mac] = getMACaddress();

                    if ~strcmp(mac,'00095B8E6171')
                        warning('using uncorrected gamma for non-rig monitors')
                        LUTBitDepth=8;
                        numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
                        ramp=[0:fraction:1];
                        grayColors= [ramp;ramp;ramp]';
                        %maybe ask for red / green / blue gun only
                        uncorrected=grayColors;
                        useUncorrected=1;
                    else
                        % going to consider saving the calibration in a local file. see
                        % if the local file was created that day. elase download and
                        % use file
                        checkLocal = true;
                        downloadCLUT = true;
                        if checkLocal
                            a = dir(getRatrixPath);
                            if any(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')) && ...
                                    datenum(a(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')).date)>floor(now)
                                temp = load(fullfile(getRatrixPath,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat'));
                                uncorrected = temp.cal.linearizedCLUT;
                                useUncorrected=1; % its already corrected
                                downloadCLUT = false;
                            end
                        end
                        if downloadCLUT
                            timeRange=[datenum('05-15-2011 00:01','mm-dd-yyyy HH:MM') datenum('05-15-2011 23:59','mm-dd-yyyy HH:MM')];
                            cal=getCalibrationData(conn,mac,timeRange);
                            closeConn(conn)
                            uncorrected = cal.linearizedCLUT;
                            useUncorrected=1; % its already corrected
                            % now save cal
                            filename = fullfile(getRatrixPath,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat');
                            save(filename,'cal');
                        end
                    end
                case 'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5'
                    conn=dbConn();
                    [junk mac] = getMACaddress();        
                    if ~strcmp(mac,'00095B8E6171')
                        warning('using uncorrected gamma for non-rig monitors')
                        LUTBitDepth=8;
                        numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
                        ramp=[0:fraction:1];
                        grayColors= [ramp;ramp;ramp]';
                        %maybe ask for red / green / blue gun only
                        uncorrected=grayColors;
                        useUncorrected=1;
                    else
                        % going to consider saving the calibration in a local file. see
                        % if the local file was created that day. elase download and
                        % use file
                        checkLocal = true;
                        downloadCLUT = true;
                        if checkLocal
                            a = dir(getRatrixPath);
                            if any(ismember({a.name},'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat')) && ...
                                datenum(a(ismember({a.name},'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat')).date)>floor(now)
                                temp = load(fullfile(getRatrixPath,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat'));
                                uncorrected = temp.cal.linearizedCLUT;
                                useUncorrected=1; % its already corrected
                                downloadCLUT = false;
                            end
                        end
                        if downloadCLUT
                            timeRange=[datenum('03-19-2011 00:01','mm-dd-yyyy HH:MM') datenum('03-19-2011 15:00','mm-dd-yyyy HH:MM')];
                            cal=getCalibrationData(conn,mac,timeRange);
                            closeConn(conn)
                            uncorrected = cal.linearizedCLUT;
                            useUncorrected=1; % its already corrected
                            % now save cal
                            filename = fullfile(getRatrixPath,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat');
                            save(filename,'cal');
                        end
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
        
        function [out s updateSM]=getLUT(s,bits);
            if isempty(s.LUT) || s.LUTbits~=bits
                updateSM=true;
                s.LUTbits=bits;
                s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
            else
                updateSM=false;
            end
            out=s.LUT;
        end

        function [analysisdata cumulativedata] = physAnalysis(stimManager,spikeRecord,stimulusDetails,plotParameters,parameters,cumulativedata,eyeData,LFPRecord)
            % error('remove this error when you update physAnalysis to be manualCmrMotionEyeCal');

            analysisdata=[];
            if ~isfield(cumulativedata,'medianA')
                cumulativedata.medianA=[];
            end
            if ~isfield(cumulativedata,'medianB')
                cumulativedata.medianB=[];
            end
            if ~isfield(cumulativedata,'trialNumberA')
                cumulativedata.trialNumberA=[];
            end
            if ~isfield(cumulativedata,'trialNumberB')
                cumulativedata.trialNumberB=[];
            end

            % stimManager is the stimulus manager
            % spikes is a logical vector of size (number of neural data samples), where 1 represents a spike happening
            % correctedFrameIndices is an nx2 array of frame start and stop indices - [start stop], n = number of frames
            % stimulusDetails are the stimDetails from calcStim (hopefully they contain all the information needed to reconstruct stimData)
            % photoDiode - currently not used
            % plotParameters - currently not used
            % 4/17/09 - spikeRecord contains all the data from this ENTIRE trial, but we should only do analysis on the current chunk
            % to prevent memory problems

            intervalsA=stimulusDetails.recordingIntervalsA;
            intervalsB=stimulusDetails.recordingIntervalsB;
            figure
            title('position A')
            xlabel('eye position (cr-p)')
            hold on
            for i=1:size(intervalsA,1)
                %get eyeData for phase-eye analysis
                % do this separately for each recording interval
                which=eyeData.eyeDataFrameInds>=intervalsA(i,1)&eyeData.eyeDataFrameInds<=intervalsA(i,2);
                if isempty(find(which)) % this interval never actually ran - so skip and go to next
                    continue;
                end
                medianEyeSig=doPlot(eyeData,which);
                cumulativedata.medianA=[cumulativedata.medianA; medianEyeSig];
                cumulativedata.trialNumberA=[cumulativedata.trialNumberA; parameters.trialNumber];
            end

            figure
            title('position B')
            xlabel('eye position (cr-p)')
            hold on
            for i=1:size(intervalsB,1)
                %get eyeData for phase-eye analysis
                % do this separately for each recording interval
                which=eyeData.eyeDataFrameInds>=intervalsB(i,1)&eyeData.eyeDataFrameInds<=intervalsB(i,2);
                if isempty(find(which)) % this interval never actually ran - so skip and go to next
                    continue;
                end
                medianEyeSig=doPlot(eyeData,which);
                cumulativedata.medianB=[cumulativedata.medianB; medianEyeSig];
                cumulativedata.trialNumberB=[cumulativedata.trialNumberB; parameters.trialNumber];
            end

        end % end function


        function medianEyeSig=doPlot(eyeData,which)
            thisIntEyeData=eyeData;
            thisIntEyeData.eyeData=thisIntEyeData.eyeData(which,:);

            [px py crx cry]=getPxyCRxy(thisIntEyeData,10);
            eyeSig=[crx-px cry-py];
            eyeSig(end,:)=[]; % remove last ones to match (not principled... what if we should throw out the first ones?)

            % throw out any nans before calculating median
            toRemove=isnan(eyeSig(:,1));
            eyeSig(toRemove,:)=[];

            medianEyeSig=[median(eyeSig(:,1)) median(eyeSig(:,2))];
            plot(medianEyeSig(1),medianEyeSig(2),'.g','MarkerSize',24);
            plot(eyeSig(:,1)',eyeSig(:,2)','.b','MarkerSize',4);
        end
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case {'autopilot','reinforcedAutopilot'}
                        out=1;
                    otherwise
                        out=0;
                end
            else
                error('need a trialManager object')
            end
        end
        
        function retval = worthPhysAnalysis(sm,quality,analysisExists,overwriteAll)
            % returns true if worth spike sorting given the values in the quality struct
            % default method for all stims - can be overriden for specific stims
            %
            % quality.passedQualityTest (from analysisManager's getFrameTimes)
            % quality.frameIndices
            % quality.frameTimes
            % quality.frameLengths (this was used by getFrameTimes to calculate passedQualityTest)

            retval=~analysisExists; % so we dont repeat the same analysis for every chunk in this trial!

        end % end function


    end
    
end


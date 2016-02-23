classdef bipartiteField<stimManager
    
    properties
        receptiveFieldLocation=[];
        frequencies=[]; % really this is not freq, but rather 1/freq (lower value = more cycles)
        duration=[];
        repetitions=[];
        LUT=[];
        LUTbits=0;
        frames=[]; % internal variable for dynamic mode - never should be user-set
    end
    
    methods
        function s=bipartiteField(varargin)
            % BIPARTITEFIELD  class constructor.

            % s = bipartiteField(receptiveFieldLocation,frequencies,duration,repetitions,maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            % receptiveFieldLocation - fractional location of receptive field; used to decide where to make the partition
            % frequencies - an array of frequencies for switching from low to high luminance (black to white); in hz requested
            % duration - seconds to spend in each frequency
            % repetitions - number of times to cycle through all frequencies
            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if input is of this class type
                    if (isa(varargin{1},'bipartiteField'))
                        s = varargin{1};
                    else
                        error('Input argument is not a bipartiteField object')
                    end
                case 8
                    % create object using specified values
                    % receptiveFieldLocation
                    if (isvector(varargin{1}) && length(varargin{1}) == 2) || isa(varargin{1},'RFestimator')
                        s.receptiveFieldLocation = varargin{1};
                    else
                        error('receptiveFieldLocation must be a two-element array [xPos yPos] as fractional locations, or an RFestimator');
                    end
                    % frequencies
                    if isvector(varargin{2}) && isnumeric(varargin{2})
                        if all(varargin{2}>=2)
                            s.frequencies = varargin{2};
                        else
                            error('frequencies must be >2');
                        end
                    else
                        error('frequencies must be numeric');
                    end
                    % duration
                    if isscalar(varargin{3})
                        s.duration = varargin{3};
                    else
                        error('duration must be a scalar');
                    end
                    % repetitions
                    if isscalar(varargin{4}) && isnumeric(varargin{4})
                        s.repetitions = varargin{4};
                    else
                        error('repetitions must be a scalar');
                    end
                    

                otherwise
                    error('invalid number of input arguments');
            end
        end
        
        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,interTrialStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =...
    calcStim(stimulus,trialManager,allowRepeats,resolutions,displaySize,LUTbits,...
    responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % see ratrixPath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)
            % 1/30/09 - trialRecords includes THIS trial now
            trialManagerClass =class(trialManager);
            indexPulses=[];
            imagingTasks=[];

            LUTbits
            displaySize
            [LUT stimulus updateSM]=getLUT(stimulus,LUTbits);
            [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));

            if isnan(resolutionIndex)
                resolutionIndex=1;
            end

            type = 'cache';
            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus); 
            interTrialDuration = getInterTrialDuration(stimulus);

            details.pctCorrectionTrials=getPercentCorrectionTrials(trialManager); % need to change this to be passed in from trial manager
            details.bias = getRequestBias(trialManager);

            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);

            % ================================================================================
            % start calculating frames now

            height = min(height,getMaxHeight(stimulus));
            width = min(width,getMaxWidth(stimulus));
            frequencies = stimulus.frequencies;
            duration = stimulus.duration;
            repetitions = stimulus.repetitions;

            % error if requested frequency exceeds monitor refresh rate
            % if any(frequencies>hz)
            %     error('requested frequency exceeds monitor refresh rate');
            % end

            % calculate total number of monitor frames to spend in each frequency
            numFramesPerFreq = hz * duration; % in frames
            numFramesToMake = numFramesPerFreq * length(frequencies) * repetitions;

            framesL=[];
            framesR=[];


            if isa(stimulus.receptiveFieldLocation,'RFestimator')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                partition=getCenter(stimulus.receptiveFieldLocation,subjectID,trialRecords);
            else
                partition=stimulus.receptiveFieldLocation;
            end

            % calculate the number of pixels horizontally on each side (reduced using gcd)
            leftlength=floor(partition(1)*width);
            rightstart=ceil(partition(1)*width);
            rightlength=width-rightstart;
            sz=gcd(leftlength,rightlength);
            numLeftPixels=leftlength/sz;
            numRightPixels=rightlength/sz;

            % now for each requested frequency, map to the monitor frame rate
            for i=1:length(frequencies)
                numSampsAtThisFreq=numFramesPerFreq; % for each frequency, calculate the frames
                samps = [1:numSampsAtThisFreq]*2*pi; % linearly spaced with one extra samp, then throw away last one (2pi)
                % now "stretch" out samps to map to the monitor refresh rate (hz)
                msamps=samps ./ frequencies(i);

                framesL = [framesL 0.5*cos(msamps)+0.5];
                framesR = [framesR 0.5*cos(msamps+pi)+0.5];
            end

            % now repmat to number of reps
            framesL = repmat(framesL, [1 repetitions]);
            framesR = repmat(framesR, [1 repetitions]);

            if length(framesL) ~= length(framesR)
                error('wtf');
            end
            if length(framesL) ~= numFramesToMake
                numFramesToMake
                length(framesL)
                numFramesPerFreq
                frequencies
                error('uh oh');
            end

            % stim.frames(1,:) = framesL(:);
            % stim.frames(2,:) = framesR(:);

            % 11/7/08 - dynamic mode stim is a struct of parameters
            % stim = [];
            % stim.height = height;
            % stim.width = width;
            % stim.frames(1,:) = framesL(:);
            % stim.frames(2,:) = framesR(:);
            % stim.numLeftPixels = numLeftPixels;
            % stim.numRightPixels = numRightPixels;

            stim=zeros(1,numLeftPixels+numRightPixels,length(framesL));
            for i=1:length(framesL)
                stim(1,1:numLeftPixels,i) = framesL(i);
                stim(1,numLeftPixels+1:end,i) = framesR(i);
            end

            [details, stim] = setupLED(details, stim, stimulus.LEDParams,arduinoCONN);

            discrimStim=[];
            discrimStim.stimulus=stim;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            discrimStim.framesUntilTimeout=numFramesToMake;

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
            % return out.stimSpecs, out.scaleFactors for each phase (only one phase for now?)
            details.frequencies=frequencies;
            details.duration=duration;
            details.repetitions=repetitions;
            details.partition=partition;
            details.numLeftPixels=numLeftPixels;
            details.numRightPixels=numRightPixels;
            details.stim=stim;

            % ================================================================================
            if strcmp(trialManagerClass,'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('duration: %g',stimulus.duration);
            end

        end % end function
        
        function [doFramePulse, expertCache, dynamicDetails, textLabel, i, dontclear, indexPulse] = ...
    drawExpertFrame(stimulus,stim,i,phaseStartTime,totalFrameNum,window,textLabel,destRect,filtMode,...
    expertCache,ifi,scheduledFrameNum,dropFrames,dontclear,dynamicDetails)
            % 11/7/08 - implementing expert mode for bipartiteField 
            % this function calculates an expert frame, and then makes and draws the texture; nothing needs to be done in runRealTimeLoop
            % this should be a stimManager-specific implementation (if expert mode is supported for the given stimulus)
            indexPulse=false;
            floatprecision=1;

            % increment i
            if dropFrames
                i=scheduledFrameNum;
            else
                i=i+1;
            end
            % stimulus = stimManager
            doFramePulse=true;
            % ================================================================================
            % start calculating frames now

            % get parameters from stim
            % only need stim.numLeftPixels and stim.numRightPixels

            % expertFrame = zeros(height,width,1);

            % 11/7/08 - this causes an enormous number of frame drops (>1 per actual frame) - find a better way
            % % left side
            % expertFrame(:,1:floor(partition(1)*width),1) = stim.frames(1,i);
            % % right side
            % expertFrame(:,ceil(partition(1)*width):end,1) = stim.frames(2,i);

            % expertFrame = ones(height,floor(partition(1)*width))*stim.frames(1,i); % left side
            % expertFrame = [expertFrame ones(height,width-ceil(partition(1)*width))*stim.frames(2,i)]; % right side

            % % method 2
            % % try drawing only 1xWidth pixels (since same vertically)
            % expertFrame = ones(1,width);
            % expertFrame(1,1:floor(partition(1)*width)) = stim.frames(1,i);
            % expertFrame(1,ceil(partition(1)*width):end,1) = stim.frames(2,i);

            % method 3
            % same as method 2, but also reduce size horizontally by trying to find gcd of the two sides
            expertFrame = ones(1,stim.numLeftPixels+stim.numRightPixels);
            expertFrame(1,1:stim.numLeftPixels) = stim.frames(1,i);
            expertFrame(1,stim.numLeftPixels+1:end) = stim.frames(2,i);


            % 11/14/08 - moved the make and draw to stimManager specific getexpertFrame b/c they might draw differently
            dynTex = Screen('MakeTexture', window, expertFrame,0,0,floatprecision);
            Screen('DrawTexture', window, dynTex,[],destRect,[],filtMode);
            Screen('Close',dynTex); % close this texture to remove from VRAM

        end % end function

        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;

            try
                stimDetails=[trialRecords.stimDetails];
                [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.duration newLUT] = extractFieldAndEnsure(stimDetails,{'duration'},'scalar',newLUT);
                [out.repetitions newLUT] = extractFieldAndEnsure(stimDetails,{'repetitions'},'scalar',newLUT);
                [out.partition newLUT] = extractFieldAndEnsure(stimDetails,{'partition'},'equalLengthVects',newLUT);
                [out.numLeftPixels newLUT] = extractFieldAndEnsure(stimDetails,{'numLeftPixels'},'scalar',newLUT);
                [out.numRightPixels newLUT] = extractFieldAndEnsure(stimDetails,{'numRightPixels'},'scalar',newLUT);

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
        
        function [out s updateSM]=getLUT(s,bits);
            if isempty(s.LUT) || s.LUTbits~=bits
                updateSM=true;
                s.LUTbits=bits;
                %s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
                %s=fillLUT(s,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5'); % March 2011 ViewSonic
            %     s=fillLUT(s,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5'); % May 2011 Westinghouse
                s=fillLUT(s,'localCalibStore',[0 1],false);
            else
                updateSM=false;
            end
            out=s.LUT;
        end
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case 'freeDrinks'
                        out=1;
                    case 'nAFC'
                        out=1;
                    case {'autopilot','reinforcedAutopilot'}
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


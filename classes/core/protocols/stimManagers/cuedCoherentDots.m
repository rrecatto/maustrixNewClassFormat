classdef cuedCoherentDots
    
    properties
        screen_width = 100;         % for matrix
        screen_height = 100;        % for matrix
        num_dots = 100;             % Number of dots to display
        coherence = .8;             % Percent of dots to move in a specified direction
        speed = 1;                  % How fast do our little dots move
        contrast = 1;               % contrast of the dots
        dot_size = 9;               % Width of dots in pixels
        movie_duration = 2;         % in seconds
        rewards_and_probability = [50, 500; .1 .9]    % first row is reward values; second row is probability of that reward
        cue_sounds = {'smallRewardSound','jackpotSound'};
        pctCorrectionTrials=.1;
        replayMode='loop';

        LUT=[];
        LUTbits=0;
    end
    
    methods
        function s=cuedCoherentDots(varargin)
            % COHERENTDOTS  class constructor.
            % s=coherentDots(screen_width,screen_height,num_dots,coherence,speed,contrast,
            %   dot_size,movie_duration,rewards_and_probability,cue_sounds,screen_zoom,maxWidth,maxHeight,pctCorrectionTrials,
            %   [replayMode,interTrialLuminance])
            %
            %   screen_width - width of sourceRect (determines size of texture to make)
            %   screen_height - height of sourceRect (determines size of texture to make)
            %   num_dots - number of dots to draw
            %   coherence - either a single coherence value, or a 2-element array specifying a range of coherence values from which to draw randomly every trial
            %   speed - either a single speed value, or a 2-element array specifying a range to randomly draw from every trial
            %   contrast - either a single contrast value, or a 2-element array specifying a range to randomly draw from every trial
            %   dot_size - size in pixels of each dot (square)
            %   movie_duration - length of the movie in seconds
            %   screen_zoom - scaleFactor argument passed to stimManager constructor
            %   interTrialLuminance - (optional) defaults to 0
            %   

            eps = 0.0000001;

            screen_zoom = [6 6];

            switch nargin
            case 0 
            % if no input arguments, create a default object

            s = class(s,'cuedCoherentDots',stimManager());

            case 1
            % if single argument of this class type, return it
                if (isa(varargin{1},'cuedCoherentDots'))
                    s = varargin{1}; 
                else
                    error('Input argument is not an cuedCoherentDots object')
                end
            case {15 16 17}
                % screen_width
                if (floor(varargin{1}) - varargin{1} < eps)
                    s.screen_width = varargin{1};
                else
                    varargin{1}
                    error('screen_width must be an integer')
                end
                % screen_height
                if (floor(varargin{2}) - varargin{2} < eps)
                    s.screen_height = varargin{2};
                else
                    error('screen_height must be an integer')
                end
                % num_dots
                if (floor(varargin{3}) - varargin{3} < eps)
                    s.num_dots = varargin{3};
                else
                    error('num_dots must be an integer')
                end
                % coherence
                if (isfloat(varargin{4}))
                    s.coherence = 1;
                    if (length(varargin{4}) == 1)
                        if (varargin{4} >= 0 && varargin{4} <= 1)
                            s.coherence = varargin{4};
                        else
                            error('Coherence must be between 0 and 1')
                        end
                    elseif (length(varargin{4}) == 2)
                        if (varargin{4}(1) >= 0 && varargin{4}(1) <= 1 && varargin{4}(2) >= 0 && varargin{4}(2) <= 1 && (varargin{4}(2) - varargin{4}(1) > 0))
                            s.coherence=varargin{4};
                        else
                            error('Coherence must be between 0 and 1, with max > min')
                        end
                    else
                        error ('Coherence must be either a 1x2 or 1x1 set of floats')
                    end
                else
                    error('Coherence level must be a 1x1 or 1x2 array between 0 and 1')
                end
                % speed
                if (isfloat(varargin{5})) && (isscalar(varargin{5}) || length(varargin{5})==2)
                    if (length(varargin{5})==2) && ~(varargin{5}(1)<=varargin{5}(2))
                        error('range of speed must be [min max]');
                    end
                    s.speed = varargin{5};
                else
                    error('speed (pixels/frame) must be a double or a 2-element array specifying a range')
                end
                % contrast
                if (length(varargin{6})==1 || length(varargin{6})==2) && all(isnumeric(varargin{6})) && ...
                        all(varargin{6} >=0) && all(varargin{6} <=1)
                    if length(varargin{6})==2 && ~(varargin{6}(1)<=varargin{6}(2))
                        error('range of contrast must be [min max]');
                    end
                    s.contrast = varargin{6};
                else
                    error('contrast must be >=0 and <=1 and be a single number or a 2-element array specifying a range');
                end
                % dot_size
                if length(varargin{7})==1 && (floor(varargin{7}) - varargin{7} < eps)
                    s.dot_size = varargin{7};
                elseif length(varargin{7})==2 && all(floor(varargin{7}) - varargin{7} < eps) && varargin{7}(1)<=varargin{7}(2)
                    s.dot_size = varargin{7};
                else
                    error('dot_size must be an integer or a 2-element array specifying a valid range')
                end
                % movie_duration
                if (floor(varargin{8}) - varargin{8} < eps)
                    s.movie_duration = varargin{8};
                elseif length(varargin{8})==2 && all(floor(varargin{8}) - varargin{8} < eps) && varargin{8}(1)<=varargin{8}(2)
                    s.movie_duration = varargin{8};
                else
                    error('movie_duration must be an integer or a 2-element array specifying a valid range')
                end

                % rewards_and_probability {9}
                rewards_and_probability = varargin{9};
                if ~isnumeric(rewards_and_probability) || size(rewards_and_probability,1)~=2
                    error('rewards_and_probability must be a 2 by n matrix of reward values and associated probabilities');
                elseif ~all(rewards_and_probability(1,:)>=0)
                    error('Rewards must be non-negative.')
                elseif ~all(rewards_and_probability(2,:)>=0) || sum(rewards_and_probability(2,:))~=1
                    error('Probabilities must be non-negative and sum to 1')
                else
                    s.rewards_and_probability = rewards_and_probability;
                end


                % cue_sounds {10}
                if iscell(varargin{10})
                    if all(cellfun(@ischar, varargin{10}(1,:))) && all(size(varargin{10})==size(rewards_and_probability)) && all(cellfun(@isnumeric,varargin{10}(2,:)))
                        s.cue_sounds = varargin{10};
                    else
                        error('cue_sounds must be a cell array of sound names whose length is the same as the number of associated reward values')
                    end
                else
                    error('cue_sounds must be a cell array of sound names whose length is the same as the number of associated reward values')
                end
                % screen_zoom
                if (length(varargin{11}) == 2 && isnumeric(varargin{11}))
                    screen_zoom = varargin{11};
                else
                    error('screen_zoom must be a 1x2 array with integer values')
                end

                % pctCorrectionTrials
                if isscalar(varargin{14}) && varargin{14}<=1 && varargin{14}>=0
                    s.pctCorrectionTrials=varargin{14};
                else
                    error('pctCorrectionTrials must be a scalar between 0 and 1');
                end

                for i=15:16
                    if i <= nargin
                        args{i}=varargin{i};
                    else
                        args{i}=[];
                    end
                end

                % replayMode
                if ~isempty(args{15})
                    if ischar(args{15}) && (strcmp(args{15},'loop') || strcmp(args{15},'once'))
                        s.replayMode=args{15};
                    else
                        error('replay mode must be ''loop'' or ''once''');
                    end
                else
                    s.replayMode='loop';
                end

                % maxWidth, maxHeight, scale factor, intertrial luminance
                if isempty(args{16})
                    s = class(s,'cuedCoherentDots',stimManager(varargin{12},varargin{13},screen_zoom,uint8(0)));   
                else
                    % check intertrial luminance
                    if args{16} >=0 && args{16} <= 1
                        s = class(s,'cuedCoherentDots',stimManager(varargin{12},varargin{13},screen_zoom,uint8(args{16}*intmax('uint8'))));
                    else
                        error('interTrialLuminance must be <=1 and >=0 - will be converted to a uint8 0-255');
                    end
                end

            otherwise
                nargin
                error('Wrong number of input arguments')
            end
        end
        
        function [stimulus, updateSM, resolutionIndex, preRequestStim, preResponseStim, discrimStim,postDiscrimStim,interTrialStim, LUT, targetPorts, distractorPorts, ...
    details, interTrialLuminance, text, indexPulses, imagingTasks] = ...
    calcStim(stimulus,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % 1/30/09 - trialRecords now includes THIS trial
            s = stimulus;
            indexPulses=[];
            imagingTasks=[];
            %LUT = Screen('LoadCLUT', 0);
            %LUT=LUT/max(LUT(:));

            % TODO:  Change this
            % out = 1;

            % LUTBitDepth=8;
            % numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
            % ramp=[0:fraction:1];
            % LUT= [ramp;ramp;ramp]';
            [LUT stimulus updateSM]=getLUT(stimulus,LUTbits);

            [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));

            if isnan(resolutionIndex)
                resolutionIndex=1;
            end


            % updateSM=0;     % For intertrial dependencies
            % isCorrection=0;     % For correction trials to force to switch sides

            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus); 
            interTrialDuration = getInterTrialDuration(stimulus);

            details.pctCorrectionTrials=stimulus.pctCorrectionTrials; % need to change this to be passed in from trial manager
            details.bias = getRequestBias(trialManager);

            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass);

            if length(targetPorts)==1
                if targetPorts == 1
                    % animal should go left
                    dotDirection = pi
                elseif targetPorts == 3
                    dotDirection = 0
                else
                    error('Zah?  This should never happen!')
                end
                static=false;
                if length(s.movie_duration)==2
                    selectedDuration = s.movie_duration(1) + rand(1)*(s.movie_duration(2)-s.movie_duration(1));
                else
                    selectedDuration = s.movie_duration;
                end
            else
                % if more than one target port, then we can only have a static image!
                warning('more than one target port found by coherentDots calcStim - calculating a static dots image ONLY!');
                static=true;
                dotDirection=-1;
                selectedDuration=1/hz;
            end

            num_frames = floor(hz * selectedDuration);

            alldotsxy = [rand(s.num_dots,1)*(s.screen_width-1)+1 ...
                          rand(s.num_dots,1)*(s.screen_height-1)+1];
            dot_history = zeros(s.num_dots,2,num_frames);

            dots_movie = uint8(zeros(s.screen_height, s.screen_width, num_frames));

            %% ===================================================================================
            % 11/20/08 - fli
            % do all random picking here (from coherence, size, contrast, speed as necessary)
            %   s.coherence -> selectedCoherence
            %   s.dot_size -> selectedDotSize
            %   s.contrast -> selectedContrast
            %   s.speed -> selectedSpeed
            % coherence
            if length(s.coherence)==2
                selectedCoherence = s.coherence(1) + rand(1)*(s.coherence(2)-s.coherence(1));
            else
                selectedCoherence = s.coherence;
            end
            % dot_size
            if length(s.dot_size)==2
                selectedDotSize = round(s.dot_size(1) + rand(1)*(s.dot_size(2)-s.dot_size(1)));
            else
                selectedDotSize = s.dot_size;
            end
            % contrast
            if length(s.contrast)==2
                selectedContrast = s.contrast(1) + rand(1)*(s.contrast(2)-s.contrast(1));
            else
                selectedContrast = s.contrast;
            end
            % speed
            if length(s.speed)==2
                selectedSpeed = s.speed(1) + rand(1)*(s.speed(2)-s.speed(1));
            else
                selectedSpeed = s.speed;
            end

            % trial value
            p=cumsum(s.rewards_and_probability(2,:));
            r = rand(1);
            ind = find(r<p,1,'first');
            selectedTrialValue = s.rewards_and_probability(1,ind);

            % sound
            sound_name = s.cue_sounds{1,ind};
            sound_duration = s.cue_sounds{2,ind};

            % ===================================================================================
            %shape = zeros(dot_size,2);
            % Make a square shape
            shape = ones(selectedDotSize);

            %% Draw those dots!

            frame = zeros(s.screen_height,s.screen_width);
            frame(sub2ind(size(frame),floor(alldotsxy(:,2)),floor(alldotsxy(:,1)))) = 1;
            frame = conv2(frame,shape,'same');
            frame(frame > 0) = 255;
            dot_history(:,:,1) = alldotsxy;
            dots_movie(:,:,1) = uint8(frame);
            % alldotsxy(:,1);
            % alldotsxy(:,2);

            if ~static

                vx = selectedSpeed*cos(dotDirection);
                vy = selectedSpeed*sin(dotDirection);

                for i=1:num_frames
                    frame = zeros(s.screen_height,s.screen_width);
                    frame(sub2ind(size(frame),floor(alldotsxy(:,2)),floor(alldotsxy(:,1)))) = 1;
                    frame = conv2(frame,shape,'same');
                    frame(frame > 0) = 255;
                    dots_movie(:,:,i) = uint8(frame);
                    dot_history(:,:,i) = alldotsxy;

                    % Randomly find who's going to be coherent and who isn't
                    move_coher = rand(s.num_dots,1) < selectedCoherence;
                    move_randomly = ~move_coher;

                    num_out = sum(move_randomly);

                    if (num_out ~= s.num_dots)
                        alldotsxy(move_coher,1) = alldotsxy(move_coher,1) + vx;
                        alldotsxy(move_coher,2) = alldotsxy(move_coher,2) + vy;
                    end
                    if (num_out)
                        alldotsxy(move_randomly,:) = [rand(num_out,1)*(s.screen_width-1)+1 ...
                            rand(num_out,1)*(s.screen_height-1)+1];
                    end

                    overboard = alldotsxy(:,1) > s.screen_width | alldotsxy(:,2) > s.screen_height | ...
                        floor(alldotsxy(:,1)) <= 0 | floor(alldotsxy(:,2)) <= 0;
                    num_out = sum(overboard);
                    if (num_out)
                        alldotsxy(overboard,:) = [rand(num_out,1)*(s.screen_width-1)+1 ...
                            rand(num_out,1)*(s.screen_height-1)+1];
                    end

                end
            end

            out = dots_movie*selectedContrast;


            if strcmp(stimulus.replayMode,'loop')
                type='loop';
            elseif strcmp(stimulus.replayMode,'once')
                type='cache';
                out(:,:,end+1)=0;
            else
                error('unknown replayMode');
            end

            %% details.stimStruct = structize(stimulus);
            details.dotDirection = dotDirection;
            details.dotxy = alldotsxy;
            details.coherence = s.coherence;
            details.dot_size = s.dot_size;
            details.contrast = s.contrast;
            details.speed = s.speed;
            details.rewards_and_probability = s.rewards_and_probability;
            details.cue_sound_name = sound_name;
            details.cue_sound_duration = sound_duration;

            details.selectedCoherence = selectedCoherence;
            details.selectedDotSize = selectedDotSize;
            details.selectedContrast = selectedContrast;
            details.selectedSpeed = selectedSpeed;
            details.selectedDuration = selectedDuration;
            details.selectedTrialValue = selectedTrialValue;

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

            preResponseStim=preRequestStim;
            postDiscrimStim = [];
            interTrialStim.duration = interTrialDuration;
            details.interTrialDuration = interTrialDuration;
            if (strcmp(trialManagerClass,'nAFC') || strcmp(trialManagerClass,'goNoGo')) && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('coherence: %g dot_size: %g contrast: %g speed: %g',selectedCoherence,selectedDotSize,selectedContrast,selectedSpeed);
            end
        end
        
        function d=display(s)
            d=['coherentDots (n target, m distractor gabors, randomized phase, equal spatial frequency, p>=n+m horiz positions)\n'...
                '\t\t\tpixPerCycs:\t[' num2str(1) ... 
                ']\n\t\t\ttarget orientations:\t[' num2str(1) ...
                ']\n\t\t\tdistractor orientations:\t[' num2str(1) ...
                ']\n\t\t\tmean:\t' num2str(1) ...
                '\n\t\t\tradius:\t' num2str(1) ...
                '\n\t\t\tcontrast:\t' num2str(1) ...
                '\n\t\t\tthresh:\t' num2str(1) ...
                '\n\t\t\tpct from top:\t' num2str(1)];
            d=sprintf(d);

            %%% TODO:  change this
            %%% num2str(s.pixPerCycs)
        end
        
        function [out scale] = errorStim(stimManager,numFrames)
            scale=0;

            out = uint8(ones(1,1,numFrames));
        end
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;

            nAFCindex = find(strcmp(LUTparams.compiledLUT,'nAFC'));
            if ~isempty(nAFCindex) && ~all([basicRecords.trialManagerClass]==nAFCindex)
                warning('only works for nAFC trial manager')
                out=struct;
            else

                try
                    stimDetails=[trialRecords.stimDetails];
                    [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                    [out.dotDirection newLUT] = extractFieldAndEnsure(stimDetails,{'dotDirection'},'scalar',newLUT);
                    [out.coherence newLUT] = extractFieldAndEnsure(stimDetails,{'coherence'},'equalLengthVects',newLUT);
                    [out.dot_size newLUT] = extractFieldAndEnsure(stimDetails,{'dot_size'},'equalLengthVects',newLUT);
                    [out.contrast newLUT] = extractFieldAndEnsure(stimDetails,{'contrast'},'equalLengthVects',newLUT);
                    [out.speed newLUT] = extractFieldAndEnsure(stimDetails,{'speed'},'equalLengthVects',newLUT);

                    [out.selectedCoherence newLUT] = extractFieldAndEnsure(stimDetails,{'selectedCoherence'},'scalar',newLUT);
                    [out.selectedDotSize newLUT] = extractFieldAndEnsure(stimDetails,{'selectedDotSize'},'scalar',newLUT);
                    [out.selectedContrast newLUT] = extractFieldAndEnsure(stimDetails,{'selectedContrast'},'scalar',newLUT);
                    [out.selectedSpeed newLUT] = extractFieldAndEnsure(stimDetails,{'selectedSpeed'},'scalar',newLUT);
                    [out.selectedDuration newLUT] = extractFieldAndEnsure(stimDetails,{'selectedDuration'},'scalar',newLUT);

                    % 12/16/08 - this stuff might be common to many stims
                    % should correctionTrial be here in compiledDetails (whereas it was originally in compiledTrialRecords)
                    % or should extractBasicRecs be allowed to access stimDetails to get correctionTrial?

                catch ex
                    out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                    verifyAllFieldsNCols(out,length(trialRecords));
                    return
                end

            end
            verifyAllFieldsNCols(out,length(trialRecords));
        end
        
        function s=fillLUT(s,method,linearizedRange,plotOn);
            %function s=fillLUT(s,method,linearizedRange [,plotOn]);
            %stim=fillLUT(stim,'linearizedDefault');
            %note:
            % PR added method 'hardwiredLinear' (hardwired linearized lut range 0-1)
            %   note, this could also be loaded from file

            if ~exist('plotOn','var')
                plotOn=0;
            end

            useUncorrected=0;

            switch method
                case 'hardwiredLinear' % added PR 5/5/09
                    uncorrected=makelinearlutPR;
                    useUncorrected=1;
                case 'mostRecentLinearized' % not supported

                    method
                    error('that method for getting a LUT is not defined');

                case 'linearizedDefault' % 

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

                    sensorValues = [measured_R, measured_G, measured_B];
                    sensorRange = [min(sensorValues), max(sensorValues)];
                    gamutRange = [min(sent), max(sent)];
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
                [linearizedCLUT(:,1) g.R]=fitGammaAndReturnLinearized(sent, measured_R, linearizedRange, sensorRange, gamutRange, 2^LUTBitDepth,plotOn);

                if plotOn
                    subplot([312]);
                end
                [linearizedCLUT(:,2) g.G]=fitGammaAndReturnLinearized(sent, measured_G, linearizedRange, sensorRange, gamutRange, 2^LUTBitDepth,plotOn);

                if plotOn
                    subplot([313]);
                end
                [linearizedCLUT(:,3) g.B]=fitGammaAndReturnLinearized(sent, measured_B, linearizedRange, sensorRange, gamutRange, 2^LUTBitDepth,plotOn);
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
            %     s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
                % s=fillLUT(s,'linearizedDefault',[0 1],false);
                s=fillLUT(s,'hardwiredLinear',[0 1],false);
            else
                updateSM=false;
            end
            out=s.LUT;
        end
        
        function soundsToPlay = getSoundsToPlay(stimManager, ports, lastPorts, phase, phaseType,stepsInPhase,msRewardSound, msPenaltySound, ...
    targetOptions, distractorOptions, requestOptions, playRequestSoundLoop, trialManagerClass, trialDetails,stimDetails)
            % see doc in stimManager.calcStim.txt

            playLoopSounds={};
            playSoundSounds={};

            % nAFC setup:
            if strcmp(trialManagerClass, 'nAFC')
                % play white noise (when responsePort triggered during phase 1)
                if strcmp(phaseType,'pre-request') && (any(ports(targetOptions)) || any(ports(distractorOptions)))
                    playLoopSounds{end+1} = 'trySomethingElseSound';
                elseif ismember(phaseType,{'pre-response'}) && stepsInPhase == 0
                    playSoundSounds{end+1} = {stimDetails.cue_sound_name,stimDetails.cue_sound_duration};
            % %     elseif phase == 2 && any(ports(requestOptions))  
            % %         % play stim sound (when stim is requested during phase 2)
            % %         playLoopSounds{end+1} = 'keepGoingSound';
                elseif strcmp(phaseType,'reinforced') && stepsInPhase <= 0 && ~isempty(trialDetails.correct) && trialDetails.correct
                    % play correct sound
                    playSoundSounds{end+1} = {'correctSound', msRewardSound};
                elseif strcmp(phaseType,'reinforced') && stepsInPhase <= 0 && (~isempty(trialDetails.correct) && ~trialDetails.correct)
                    % play wrong sound
                    playSoundSounds{end+1} = {'wrongSound', msPenaltySound};
                end   
            % freeDrinks setup
            % this will have to be fixed for passiveViewing (either as a flag on freeDrinks or as a new trialManager)
            elseif strcmp(trialManagerClass, 'freeDrinks')
                % play white noise (when any port that is not a target is triggered)
                if ismember(phaseType,{'discrim','pre-response'}) && ~isempty(targetOptions) && any(ports(setdiff(1:length(ports), targetOptions))) % normal freeDrinks
                    playLoopSounds{end+1} = 'trySomethingElseSound';
                elseif ismember(phaseType,{'discrim','pre-response'}) && ~isempty(requestOptions) && any(ports(requestOptions)) % passiveViewing freeDrinks
                    % check that the requestMode and requestRewardDone also pass 
                    % same logic as in the request reward handling, but for sound
                    % play keepGoing sound?
                    if playRequestSoundLoop
                        playLoopSounds{end+1} = 'keepGoingSound';
                    end
                end
                % play correct/error sound
                if strcmp(phaseType,'reinforced') && stepsInPhase <= 0
                    if ~isempty(msRewardSound) && msRewardSound>0
                        playSoundSounds{end+1} = {'correctSound', msRewardSound};
                    elseif ~isempty(msPenaltySound) && msPenaltySound>0
                        playSoundSounds{end+1} = {'wrongSound', msPenaltySound};
                    end
                end
            elseif strcmp(trialManagerClass, 'autopilot')
                % do nothing because we don't play any sounds in this case
            else
                trialManagerClass
                error('default getSoundsToPlay should only be for non-phased cases');
            end

            soundsToPlay = {playLoopSounds, playSoundSounds};

        end % end function
        
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


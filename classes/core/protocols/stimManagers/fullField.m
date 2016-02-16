classdef fullField
    
    properties
        contrasts=[];
        frequencies=[];
        durations=[];
        radii = [];
        adiusType = 'hardEdge';
        numRepeats=[];

        doCombos=true;
        ordering = [];

        annuli = [];
        location = [];
        normalizationMethod='normalizeDiagonal';
        mean = 0;
        thresh = 0;
        changeableAnnulusCenter=false;
        changeableRadiusCenter=false;

        LUT=[];
        LUTbits=0;

        LEDParams = [];
    end
    
    methods
        function s=fullField(varargin)
            % FULLFIELD  class constructor.

            % s = fullField(contrast,frequencies,durations,repetitions,maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            % modified balaji May 7 2011
            % s = fullField(frequencies,contrasts,durations,radii,annuli,location,normalizationMethod,mean,thresh,numRepeats,
            %       maxWidth,maxHeight,scaleFactor,interTrialLuminance[,doCombos]) 
            % contrast - contrast of the single pixel (difference between high and low luminance endpoints) - in the 0.0-1.0 scale
            % frequencies - an array of frequencies for switching from low to high luminance (black to white); in hz requested
            % durations - seconds to spend in each frequency
            % repetitions - number of times to cycle through all frequencies


            s.ordering.method = 'ordered';
            s.ordering.seed = [];
            s.ordering.includeBlank = false;
            
            s.LEDParams.active = false;
            s.LEDParams.numLEDs = 0;
            s.LEDParams.IlluminationModes = {};

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s = class(s,'fullField',stimManager());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'fullField'))
                        s = varargin{1};
                    else
                        error('Input argument is not a gratings object')
                    end
                case {14 15 16 17 18}

                    % create object using specified values
                    % check for doCombos argument first (it decides other error checking)
                    if nargin>14

                        if islogical(varargin{15})
                            s.doCombos=varargin{15};
                            s.ordering.method = 'ordered';
                            s.ordering.seed = [];
                            s.ordering.includeBlank = false;
                        elseif iscell(varargin{15}) && (length(varargin{15})==3)
                            s.doCombos = varargin{15}{1}; if ~islogical(varargin{15}{1}), error('doCombos should be a logical'), end;
                            s.ordering.method = varargin{15}{2}; if ~ismember(varargin{15}{2},{'twister','state','seed'}), error('unknown ordering method'), end;
                            s.ordering.seed = varargin{15}{3}; if (~(ischar(varargin{15}{3})&&strcmp(varargin{15}{3},'clock'))&&(~isnumeric(varargin{15}{3}))), ...
                                    error('seed should either be a number or set to ''clock'''), end;
                            s.ordering.includeBlank = false;
                        elseif iscell(varargin{15}) && (length(varargin{15})==4)
                            s.doCombos = varargin{15}{1}; if ~islogical(varargin{15}{1}), error('doCombos should be a logical'), end;
                            s.ordering.method = varargin{15}{2}; if ~ismember(varargin{15}{2},{'twister','state','seed'}), error('unknown ordering method'), end;
                            s.ordering.seed = varargin{15}{3}; if (~(ischar(varargin{15}{3})&&strcmp(varargin{15}{3},'clock'))&&(~isnumeric(varargin{15}{3}))), ...
                                    error('seed should either be a number or set to ''clock'''), end;
                            s.ordering.includeBlank = varargin{15}{4}; if ~islogical(varargin{15}{4}), error('includeBlank should be a logical'), end;
                        else
                            error('unknown way to specify doCombos. its either just a logical or a cell length 3.');
                        end
                    end

                    % frequencies
                    if isvector(varargin{1}) && isnumeric(varargin{1}) && all(varargin{1})>0
                        s.frequencies=varargin{1};
                    else
                        error('frequencies must all be > 0')
                    end

                    % contrasts
                    if isvector(varargin{2}) && isnumeric(varargin{2})
                        s.contrasts=varargin{2};
                    else
                        error('contrasts must be numbers');
                    end

                     % durations
                    if isnumeric(varargin{3}) && all(all(varargin{3}>0))
                        s.durations=varargin{3};
                    else
                        error('all durations must be >0');
                    end

                    % radii
                    if isnumeric(varargin{4}) && all(varargin{4}>0) && all(~isinf(varargin{4}))
                        s.radii=varargin{4};
                    elseif iscell(varargin{4}) && (length(varargin{4})==2)
                        s.radii = varargin{4}{1};
                        s.radiusType = varargin{4}{2};
                        if ~all(varargin{4}{1}>0) || ~any(strcmp(varargin{4}{2},{'gaussian','hardEdge'}))
                            varargin{4}
                            error('radii should be all non-negative, non-infinite and the radiusType should be ''gaussian'' or ''hardEdge''');
                        end
                    else
                        error('radii must be >= 0 and <inf');
                    end

                    % annuli
                    if isnumeric(varargin{5}) && all(varargin{5}>=0)
                        s.annuli=varargin{5};
                    else
                        error('all annuli must be >= 0');
                    end

                    % numRepeats
                    if isinteger(varargin{10}) || isinf(varargin{10}) || isNearInteger(varargin{10})
                        s.numRepeats=varargin{10};
                    end

                    % check that if doCombos is false, then all parameters must be same length
                    if ~s.doCombos
                        paramLength = length(s.frequencies);
                        if paramLength~=length(s.contrasts) || paramLength~=length(s.durations)...
                                || paramLength~=length(s.radii) || paramLength~=length(s.annuli)
                            error('if doCombos is false, then all parameters (pixPerCycs, driftfrequencies, orientations, contrasts, phases, durations, radii, annuli) must be same length');
                        end
                    end           


                    % location
                    if isnumeric(varargin{6}) && all(varargin{6}>=0) && all(varargin{6}<=1)
                        s.location=varargin{6};
                    elseif isa(varargin{6},'RFestimator')
                        s.location=varargin{6};
                    elseif isa(varargin{6},'wnEstimator') && strcmp(getType(varargin{9}),'binarySpatial')
                        s.location=varargin{6};            
                    else
                        error('all location must be >= 0 and <= 1, or location must be an RFestimator object or a wnEstimator object');
                    end

                    % normalizationMethod
                    if ischar(varargin{7})
                        if ismember(varargin{7},{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'})
                            s.normalizationMethod=varargin{7};
                        else
                            error('normalizationMethod must be ''normalizeVertical'', ''normalizeHorizontal'', or ''normalizeDiagonal'', or ''none''')
                        end
                    end

                    % mean
                    if varargin{8} >= 0 && varargin{8}<=1
                        s.mean=varargin{8};
                    else
                        error('0 <= mean <= 1')
                    end

                    % thres
                    if varargin{9} >= 0
                        s.thresh=varargin{9};
                    else
                        error('thresh must be >= 0')
                    end

                    if nargin>15
                        if ismember(varargin{16},[0 1])
                            s.changeableAnnulusCenter=logical(varargin{16});
                        else
                            error('gratingWithChangeableAnnulusCenter must be true / false')
                        end
                    end

                    if nargin>16
                        if ismember(varargin{17},[0 1])
                            s.changeableRadiusCenter=logical(varargin{17});
                        else
                            error('gratingWithChangeableRadiusCenter must be true / false')
                        end
                    end

                    if nargin>17
                        % LED state
                        if isstruct(varargin{18})
                            s.LEDParams = varargin{18};
                        else
                            error('LED state should be a structure');
                        end
                        if s.LEDParams.numLEDs>0
                            % go through the Illumination Modes and check if they seem
                            % reasonable
                            cumulativeFraction = 0;
                            if s.LEDParams.active && isempty(s.LEDParams.IlluminationModes)
                                error('need to provide atleast one illumination mode if LEDs is to be active');
                            end
                            for i = 1:length(s.LEDParams.IlluminationModes)
                                if any(s.LEDParams.IlluminationModes{i}.whichLED)>s.LEDParams.numLEDs
                                    error('asking for an LED that is greater than numLEDs')
                                else
                                    if length(s.LEDParams.IlluminationModes{i}.whichLED)~= length(s.LEDParams.IlluminationModes{i}.intensity) || ...
                                            any(s.LEDParams.IlluminationModes{i}.intensity>1) || any(s.LEDParams.IlluminationModes{i}.intensity<0)
                                        error('specify a single intensity for each of the LEDs and these intensities hould lie between 0 and 1');
                                    else
                                        cumulativeFraction = [cumulativeFraction cumulativeFraction(end)+s.LEDParams.IlluminationModes{i}.fraction];
                                    end
                                end
                            end

                            if abs(cumulativeFraction(end)-1)>eps
                                error('the cumulative fraction should sum to 1');
                            else
                                s.LEDParams.cumulativeFraction = cumulativeFraction;
                            end
                        end
                    end

                    % both changeableRadiusCentre and changeabkeAnnulusCentre cannot be
                    % true at the same time
                    if s.changeableAnnulusCenter && s.changeableRadiusCenter
                        error('cannot set changeableAnnulusCentre and changeableRadusCentre to true at the same time');
                    end

                    s = class(s,'fullField',stimManager(varargin{11},varargin{12},varargin{13},varargin{14}));

                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end    
        end

        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,interTrialStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =...
    calcStim(stimulus,trialManager,allowRepeats,resolutions,displaySize,LUTbits,...
    responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % see ratrixPath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stim,Managers)
            % 1/3/0/09 - trialRecords now includes THIS trial
            trialManagerClass=class(trialManager);

            indexPulses=[];
            imagingTasks=[];
            LUTbits
            displaySize
            [LUT stimulus updateSM]=getLUT(stimulus,LUTbits);
            [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));

            if isnan(resolutionIndex)
                resolutionIndex=1;
            end

            scaleFactor=getScaleFactor(stimulus); % dummy value since we are phased anyways; the real scaleFactor is stored in each phase's stimSpec
            interTrialLuminance = getInterTrialLuminance(stimulus);
            interTrialDuration = getInterTrialDuration(stimulus);
            toggleStim=true;
            type='expert';

            dynamicMode = true; % do things dynamically
            % dynamicMode=false;

            % =====================================================================================================

            details.pctCorrectionTrials=getPercentCorrectionTrials(trialManager);
            details.bias = getRequestBias(trialManager);

            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);

            % =====================================================================================================
            % start calculating frames now
            % set up params for computeGabors
            height = min(height,getMaxHeight(stimulus));
            width = min(width,getMaxWidth(stimulus));


            % temporal frequency
            if isa(stimulus.frequencies,'grEstimator')&&strcmp(getType(stimulus.frequencies),'driftfrequencies')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                singleUnitDetails.subjectID = subjectID;
                details.frequencies=chooseValues(stimulus.frequencies,singleUnitDetails);
            else
                details.frequencies=stimulus.frequencies;
            end

            %contrasts
            if isa(stimulus.contrasts,'grEstimator')&&strcmp(getType(stimulus.contrasts),'contrasts')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                singleUnitDetails.subjectID = subjectID;
                details.contrasts=chooseValues(stimulus.contrasts,singleUnitDetails);
            else
                details.contrasts=stimulus.contrasts;
            end


            if isa(stimulus.location,'RFestimator')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                details.location=getCenter(stimulus.location,subjectID,trialRecords);
            elseif isa(stimulus.location,'wnEstimator')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                    singleUnitDetails.subjectID = subjectID;
                details.location=chooseValues(stimulus.location,{singleUnitDetails});
            else
                details.location=stimulus.location;
            end

            details.durations=stimulus.durations;

            if isa(stimulus.radii,'grEstimator')&&strcmp(getType(stimulus.radii),'radii')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                singleUnitDetails.subjectID = subjectID;
                details.radii=chooseValues(stimulus.radii,singleUnitDetails);
            else
                details.radii=stimulus.radii; % 1/7/09 - renamed from pixPerCycs to spatialFrequencies (to avoid clashing with compile process)
            end

            details.radiusType = stimulus.radiusType;
            details.annuli=stimulus.annuli;
            details.numRepeats=stimulus.numRepeats;
            details.doCombos=stimulus.doCombos;
            details.method = stimulus.ordering.method;
            details.seed = stimulus.ordering.seed;
            details.includeBlank = stimulus.ordering.includeBlank;
            if ischar(details.seed) && strcmp(details.seed,'clock')
                seedVal =sum(100*clock);
                details.seed = seedVal;
                stimulus.ordering.seed = seedVal;
            end
            details.changeableAnnulusCenter=stimulus.changeableAnnulusCenter;
            details.changeableRadiusCenter=stimulus.changeableRadiusCenter;

            details.width=width;
            details.height=height;

            % NOTE: all fields in details should be MxN now

            % =====================================================================================================
            stim=[];

            stim.width=details.width;
            stim.height=details.height;
            stim.location=details.location;
            stim.numRepeats=details.numRepeats;
            stim.changeableAnnulusCenter=details.changeableAnnulusCenter;
            stim.changeableRadiusCenter=details.changeableRadiusCenter;

            % details has the parameters before combos, stim should have them after combos are taken
            if stimulus.doCombos
                % do combos here
                mode = {details.method,details.seed};
                comboMatrix = generateFactorialCombo({details.frequencies,details.contrasts,details.durations,details.radii,details.annuli},[],[],mode);
                stim.frequencies=comboMatrix(1,:);
                stim.contrasts=comboMatrix(2,:); %starting phases in radians
                stim.durations=round(comboMatrix(3,:)*hz); % CONVERTED FROM seconds to frames
                stim.radii=comboMatrix(4,:);
                stim.annuli=comboMatrix(5,:);
            else
                stim.frequencies=details.frequencies;
                stim.contrasts=details.contrasts;
                stim.durations=round(details.durations*hz); % CONVERTED FROM seconds to frames    
                stim.radii=details.radii;
                stim.annuli=details.annuli;
            end

            % support for includeBlank
            if details.includeBlank
                stim.frequencies(end+1)=stim.frequencies(end);
                stim.contrasts(end+1)=0; % the blank is a zero contrast stimulus
                stim.durations(end+1)=round(stim.durations(end)*hz); % CONVERTED FROM seconds to frames
                stim.radii(end+1)=stim.radii(end);
                stim.annuli(end+1)=stim.annuli(end);
            end

            % convert from radii=[0.8 0.8 0.6 1.2 0.7] to [1 1 2 3 4] (stupid unique automatically sorts when we dont want to)
            [a b] = unique(fliplr(stim.radii)); 
            unsortedUniques=stim.radii(sort(length(stim.radii)+1 - b));
            [garbage stim.maskInds]=ismember(stim.radii,unsortedUniques);

            % now make our cell array of masks and the maskInd vector that indexes into the masks for each combination of params
            % compute mask only once if radius is not infinite
            stim.masks=cell(1,length(unsortedUniques));
            for i=1:length(unsortedUniques)
                if unsortedUniques(i)==Inf
                    stim.masks{i}=[];
                else
                    mask=[];
                    maskParams=[unsortedUniques(i) 999 0 0 ...
                    1.0 stimulus.thresh details.location(1) details.location(2)]; %11/12/08 - for some reason mask contrast must be 2.0 to get correct result

                    switch details.radiusType
                        case 'gaussian'
                            mask(:,:,1)=ones(height,width,1)*stimulus.mean;
                            mask(:,:,2)=computeGabors(maskParams,0,width,height,...
                                'none', stimulus.normalizationMethod,0,0);

                            % necessary to make use of PTB alpha blending: 1 - 
                            mask(:,:,2) = 1 - mask(:,:,2); % 0 = transparent, 255=opaque (opposite of our mask)
                            stim.masks{i}=mask;
                        case 'hardEdge'
                            mask(:,:,1)=ones(height,width,1)*stimulus.mean;
                            [WIDTH HEIGHT] = meshgrid(1:width,1:height);
                            mask(:,:,2)=double((((WIDTH-width*details.location(1)).^2)+((HEIGHT-height*details.location(2)).^2)-((unsortedUniques(i))^2*(height^2)))>0);
                            stim.masks{i}=mask;

                    end
                end
            end
            % convert from annuli=[0.8 0.8 0.6 1.2 0.7] to [1 1 2 3 4] (stupid unique automatically sorts when we dont want to)
            [a b] = unique(fliplr(stim.annuli)); 
            unsortedUniquesAnnuli=stim.annuli(sort(length(stim.annuli)+1 - b));
            [garbage stim.annuliInds]=ismember(stim.annuli,unsortedUniquesAnnuli);
            % annuli array
            annulusCenter=stim.location;
            stim.annuliMatrices=cell(1,length(unsortedUniquesAnnuli));
            for i=1:length(unsortedUniquesAnnuli)
                annulus=[];
                annulusRadius=unsortedUniquesAnnuli(i);
                annulusRadiusInPixels=sqrt((height/2)^2 + (width/2)^2)*annulusRadius;
                annulusCenterInPixels=[width height].*annulusCenter; % measured from top left corner; % result is [x y]
                % center=[256 712];
                %     center=[50 75];
                [x,y]=meshgrid(-width/2:width/2,-height/2:height/2);
                annulus(:,:,1)=ones(height,width,1)*stimulus.mean;
                bool=(x+width/2-annulusCenterInPixels(1)).^2+(y+height/2-annulusCenterInPixels(2)).^2 < (annulusRadiusInPixels+0.5).^2;
                annulus(:,:,2)=bool(1:height,1:width);
                stim.annuliMatrices{i}=annulus;
            end

            if isinf(stim.numRepeats)
                timeout=[];
            else
                timeout=sum(stim.durations)*stim.numRepeats;
            end

            % LEDParams

            [details, stim] = setupLED(details, stim, stimulus.LEDParams,arduinoCONN);

            discrimStim=[];
            discrimStim.stimulus=stim;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            discrimStim.framesUntilTimeout=timeout;

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
            % =====================================================================================================
            % return out.stimSpecs, out.scaleFactors for each phase (only one phase for now?)
            % details.big = out; % store in 'big' so it gets written to file % 1/6/09 - unnecessary since we will no longer use cached mode
            details.stimManagerClass = class(stimulus);
            details.trialManagerClass = trialManagerClass;

            if strcmp(trialManagerClass,'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('thresh: %g',stimulus.thresh);
            end
        end
        
        function [doFramePulse, expertCache, dynamicDetails, textLabel, i, dontclear, indexPulse] = ...
    drawExpertFrame(stimulus,stim,i,phaseStartTime,totalFrameNum,window,textLabel,destRect,filtMode,...
    expertCache,ifi,scheduledFrameNum,dropFrames,dontclear,dynamicDetails)
            % 11/14/08 - implementing expert mode for fullField
            % this function calculates an expert frame, and then makes and draws the texture; nothing needs to be done in runRealTimeLoop
            % this should be a stimManager-specific implementation (if expert mode is supported for the given stimulus)

            floatprecision=1;

            % increment i
            if dropFrames
                i=scheduledFrameNum;
            else
                i=i+1;
            end
            % stimulus = stimManager

            doFramePulse=true;

            % expertCache should contain masktexs and annulitexs
            if isempty(expertCache)
                expertCache.masktexs=[];
                expertCache.annulitexs=[];

                if stim.changeableAnnulusCenter % initialize
                    %start with mouse in the center
                    [a,b]=WindowCenter(window);
                    SetMouse(a,b,window);
                    expertCache.annulusInd=1;
                    expertCache.positionShift=[0 0];
                    expertCache.framesTillLeftClickAllowed=0;
                    % cache all annuli right away ... will cause some drop frames... but
                    % then since its changeable we are not so precise in absolute time

                    %record the state of the first frame
                    dynamicDetails{1}.annulusDestRec=destRect;
                    dynamicDetails{1}.annulusInd=expertCache.annulusInd;
                    dynamicDetails{1}.frame=i;

                    for j=1:length(unique(stim.annuliInds))
                        expertCache.annulitexs{j}=... % expertCache.annulitexs{stim.annuliInds(gratingToDraw)}=...
                            Screen('MakeTexture',window,double(stim.annuliMatrices{j}),0,0,floatprecision);
                    end
                end
            end
            % ================================================================================
            % start calculating frames now
            numGratings = length(stim.frequencies); % number of gratings
            % find which grating we are supposed to draw
            gratingInds = cumsum(stim.durations(:));
            gratingToDraw = min(find(mod(i-1,gratingInds(end))+1<=gratingInds));


            % stim.pixPerCycs - frequency of the grating (how wide the bars are)
            % stim.orientations - angle of the grating
            % stim.driftfrequencies - frequency of the phase (how quickly we go through a 0:2*pi cycle of the sine curve) - in cycles per second
            % stim.locations - where to center each grating (modifies destRect)
            % stim.contrasts - contrast of the grating
            % stim.durations - duration of each grating (in frames)
            % stim.masks - the masks to be used (empty if unmasked)
            % stim.annuliMatrices - the annuli to be used

            black=0.0;
            % white=stim.contrasts(gratingToDraw);
            white=1.0;
            gray = (white-black)/2;

            %stim.velocities(gratingToDraw) is in cycles per second
            cycsPerFrameVel = stim.frequencies(gratingToDraw)*ifi; % in units of cycles/frame
            offset = 2*pi*cycsPerFrameVel*i;
            nextOffset = 2*pi*cycsPerFrameVel*(i+1);
            indexPulse=mod(offset,4*pi)>mod(nextOffset,4*pi);  % every 2 cycles


            % Create a 1D vector x based on the frequency pixPerCycs
            % make the grating twice the normal width (to cover entire screen if rotated)
            x = 1:stim.width;
            grating=stimulus.mean*stim.contrasts(gratingToDraw)*cos(offset)+stimulus.mean; % grating is the cos curve, with our calculated phase offset (based on driftfrequency) and initial phase
            % grating=repmat(grating, [1 2]);
            % Make grating texture
            gratingtex=Screen('MakeTexture',window,grating,0,0,floatprecision);

            % set srcRect
            srcRect=[0 0 size(grating,2) 1];

            % Draw grating texture, rotated by "angle":
            destWidth = destRect(3)-destRect(1);
            destHeight = destRect(4)-destRect(2);
            destRectForGrating = [destRect(1)-destWidth/2, destRect(2)-destHeight, destRect(3)+destWidth/2,destRect(4)+destHeight];
            Screen('DrawTexture', window, gratingtex, srcRect, destRectForGrating, 0, filtMode);

            if ~isempty(stim.masks)
                % Draw gaussian mask over grating: We need to subtract 0.5 from
                % the real size to avoid interpolation artifacts that are
                % created by the gfx-hardware due to internal numerical
                % roundoff errors when drawing rotated images:
                % Make mask to texture
                %     texsize=1024;
                %     mask=ones(2*texsize+1, 2*texsize+1, 2) * gray;
                %     [x,y]=meshgrid(-1*texsize:1*texsize,-1*texsize:1*texsize);
                %     mask(:, :, 2)=white * (1 - exp(-((x/90).^2)-((y/90).^2)));
                %     grating=repmat(grating, [stim.height 1]).*stim.mask;
                Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % necessary to do the transparency blending
                if isempty(expertCache.masktexs)
                    expertCache.masktexs=cell(1,length(unique(stim.maskInds)));
                end
                if isempty(expertCache.masktexs{stim.maskInds(gratingToDraw)}) && ~isempty(stim.masks{stim.maskInds(gratingToDraw)})
                    expertCache.masktexs{stim.maskInds(gratingToDraw)} = ...
                        Screen('MakeTexture',window,stim.masks{stim.maskInds(gratingToDraw)},0,0,floatprecision);
                end

                if isempty(expertCache.annulitexs)
                    expertCache.annulitexs=cell(1,length(unique(stim.annuliInds)));
                end
                if isempty(expertCache.annulitexs{stim.annuliInds(gratingToDraw)})
                    expertCache.annulitexs{stim.annuliInds(gratingToDraw)}=...
                        Screen('MakeTexture',window,double(stim.annuliMatrices{stim.annuliInds(gratingToDraw)}),...
                        0,0,floatprecision);
                end

                % Draw mask texture: (with no rotation)
                if ~isempty(stim.masks{stim.maskInds(gratingToDraw)})
                    Screen('DrawTexture', window, expertCache.masktexs{stim.maskInds(gratingToDraw)}, [], destRect,[], filtMode);
                end
                % start calculating frames now

                if stim.changeableAnnulusCenter
                    [mouseX, mouseY, buttons]=GetMouse(window);
                    if buttons(1) % right click if you want to update the position... only persists this trial!
                        [a,b]=WindowCenter(window);
                        %shift stimulus away from predefined location by the amount that the mouse is away from center
                        expertCache.positionShift=[mouseX-a mouseY-b];
                    end

                    expertCache.framesTillLeftClickAllowed=max(0,expertCache.framesTillLeftClickAllowed-1);  %count down till 0

                    if buttons(3) && expertCache.framesTillLeftClickAllowed==0 % left click if you want to update the size... only persists this trial!
                        anSizes=unique(stim.annuliInds);
                        %whichSize=(mod(expertCache.annulusInd-1,length(anSizes))+1)+1;
                        whichSize=mod(expertCache.annulusInd,length(anSizes))+1; % if you were at the end, you will advance to 1
                        anInd=find(stim.annuliInds==anSizes(whichSize));
                        expertCache.annulusInd=anInd(1);
                        expertCache.framesTillLeftClickAllowed=10; % lock out 10 frames till next change allowed
                    end

                    %sustain the moved stim location regardless of mouse down
                    annulusDestRec=destRect+expertCache.positionShift([1 2 1 2]);

                    if any(buttons)
                        %only send dynamic details on frames that change positions by mouse down
                        dynamicDetails{end+1}.annulusDestRec=annulusDestRec;
                        dynamicDetails{end}.annulusInd=expertCache.annulusInd;
                        dynamicDetails{end}.frame=i;
                        %dynamicDetails.sendDuringRealtimeloop=true;
                    end

                    %stim.annuliInds(gratingToDraw) === annulusInd
                    expertCache.annulitexs{stim.annuliInds(expertCache.annulusInd)}
                    Screen('DrawTexture',window,expertCache.annulitexs{stim.annuliInds(expertCache.annulusInd)},[],annulusDestRec,[],filtMode);
                else
                    annulusDestRec=destRect;
                    Screen('DrawTexture',window,expertCache.annulitexs{stim.annuliInds(gratingToDraw)},[],annulusDestRec,[],filtMode);
                end


            end

            %textLabel=sprintf('annInd: %d',expertCache.annulusInd) %only used for a test
            inspect=0;
            if inspect & i>3
                [oldmaximumvalue oldclampcolors] = Screen('ColorRange', window)
                x=Screen('getImage', window)
                tx=Screen('getImage', gratingtex)
                unique(tx(:)')
                figure; hist(double(tx(:)'),200)
                figure; imagesc(tx); % what is this? mean up front and then black heavy grating?
                unique(tx(:)')
                figure; hist(double(tx(:)'),200)
                sca
                keyboard
            end


            % clear the gratingtex from vram
            Screen('Close',gratingtex);


        end % end function
        
        function retval = enableCumulativePhysAnalysis(sm)
            % returns true if physAnalysis knows how to deal with, and wants each chunk
            % as it comes.  true for getting each chunk, false for getting the
            % combination of all chunks after analysisManagerByChunk has detected
            % spikes, sorted them, and rebundled them as spikes in their chunked format

            retval=true; %stim managers could sub class this method if they want to run on EVERY CHUNK, as opposed to the end of the trial
        end % end function
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;

            try
                stimDetails=[trialRecords.stimDetails];
                [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.duration newLUT] = extractFieldAndEnsure(stimDetails,{'duration'},'scalar',newLUT);
                [out.repetitions newLUT] = extractFieldAndEnsure(stimDetails,{'repetitions'},'scalar',newLUT);

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

                    if ~strcmp(mac,'001D7D9ACF80')
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
                            if true||any(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')) && ...
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
        
        function out = getDetails(sm,stim,what)

            switch what
                case 'sweptParameters'
                    names={'frequencies','contrasts','durations','radii','annuli'};

                    numValsPerParam = [length(stim.stimulusDetails.frequencies) length(stim.stimulusDetails.contrasts)...
                        length(stim.stimulusDetails.durations) length(stim.stimulusDetails.radii) length(stim.stimulusDetails.annuli)];

                    out=names(find(numValsPerParam>1));
                otherwise
                    error('unknown what');
            end
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

        function out = getPhysAnalysisObject(sm,subject,tr,channels,dataPath,stim,c,monitor,rigState)
            if ~exist('c','var')||isempty(c)
                c = struct([]);
            end
            out = ffAnalysis(subject,tr,channels,dataPath,stim,c,monitor,rigState);
        end
        
        function out = getType(sm,stim)

            sweptParameters = getDetails(sm,stim,'sweptParameters');
            n= length(sweptParameters);
            switch n
                case 1
                    % sweep of a single datatype
                    switch sweptParameters{1}
                        case 'frequencies'
                            out = 'tfFullField';
                        case 'contrasts'
                            out = 'cntrFullField';
                        case 'radii'
                            out = 'radiiGratings';
                        case 'annuli'
                            out = 'annuliGratings';
                        otherwise
                            out = 'undefinedGratings';
                    end
                otherwise
                    error('multiple sweeps are un supported');
            end
        end
        
        function [analysisdata cumulativedata] = physAnalysis(stimManager,spikeRecord,stimulusDetails,plotParameters,parameters,cumulativedata,eyeData,LFPRecord)


            %% processed clusters and spikes
            theseSpikes = logical(spikeRecord.processedClusters);
            spikes=spikeRecord.spikes(theseSpikes);
            spikeWaveforms = spikeRecord.spikeWaveforms(theseSpikes,:);
            spikeTimestamps = spikeRecord.spikeTimestamps(theseSpikes);

            %% SET UP RELATION stimInd <--> frameInd
            numStimFrames=max(spikeRecord.stimInds);
            analyzeDrops=true;
            if analyzeDrops
                stimFrames=spikeRecord.stimInds;
                correctedFrameIndices=spikeRecord.correctedFrameIndices;
            else
                stimFrames=1:numStimFrames;
                firstFramePerStimInd=~[0 diff(spikeRecord.stimInds)==0];
                correctedFrameIndices=spikeRecord.correctedFrameIndices(firstFramePerStimInd);
            end

            %% 
            trials = repmat(parameters.trialNumber,length(stimFrames),1);

            %% is there randomization?
            if ~isfield(stimulusDetails,'method')
                mode = {'ordered',[]};
            else
                mode = {stimulusDetails.method,stimulusDetails.seed};
            end

            %% get the stimulusCombo
            if stimulusDetails.doCombos==1
                comboMatrix = generateFactorialCombo({stimulusDetails.frequencies,stimulusDetails.contrasts,stimulusDetails.durations,stimulusDetails.radii,stimulusDetails.annuli},[],[],mode);

                frequencies=comboMatrix(1,:);
                contrasts=comboMatrix(2,:); %starting phases in radians
                durations=round(comboMatrix(3,:)*parameters.refreshRate); % CONVERTED FROM seconds to frames
                radii=comboMatrix(4,:);
                annuli=comboMatrix(5,:);

                repeat=ceil(stimFrames/sum(durations));
                numRepeats=ceil(numStimFrames/sum(durations));
                chunkEndFrame=[cumsum(repmat(durations,1,numRepeats))];
                chunkStartFrame=[0 chunkEndFrame(1:end-1)]+1;
                chunkStartFrame = chunkStartFrame';
                chunkEndFrame = chunkEndFrame';
                numChunks=length(chunkStartFrame);
                trialsByChunk = repmat(parameters.trialNumber,numChunks,1);
                numTypes=length(durations); %total number of types even having multiple sweeps  
            else
                error('analysis not handled yet for this case')
            end

            numValsPerParam=...
                [length(unique(frequencies)) length(unique(contrasts)) length(unique(durations))...
                length(unique(radii))  length(unique(annuli))];

            %% find which parameters are swept
            names={'frequencies','contrasts','durations','radii','annuli'};

            sweptParameters = names(find(numValsPerParam>1));
            numSweptParams = length(sweptParameters);
            valsSwept = cell(length(sweptParameters),0);
            for sweptNo = 1:length(find(numValsPerParam>1))
                valsSwept{sweptNo} = eval(sweptParameters{sweptNo});
            end

            % durations of each condition should be unique
            if length(unique(durations))==1
                duration=unique(durations);
            else
                error('multiple durations can''t rely on mod to determine the frame type')
            end

            stimInfo.stimulusDetails = stimulusDetails;
            stimInfo.refreshRate = parameters.refreshRate;
            stimInfo.sweptParameters = sweptParameters;
            stimInfo.numSweptParams = numSweptParams;
            stimInfo.valsSwept = valsSwept;
            stimInfo.numTypes = numTypes;

            %% to begin with no attempt will be made to group acording to type
            typesUnordered=repmat([1:numTypes],duration,numRepeats);
            typesUnordered=typesUnordered(stimFrames); % vectorize matrix and remove extras
            repeats = reshape(repmat([1:numRepeats],[duration*numTypes 1]),[duration*numTypes*numRepeats 1]);
            repeats = repeats(stimFrames);
            samplingRate=parameters.samplingRate;

            % calc phase per frame, just like dynamic
            cycsPerFrameVel = frequencies(typesUnordered)*1/(parameters.refreshRate); % in units of cycles/frame
            risingPhases = 2*pi*cycsPerFrameVel.*stimFrames';
            phases=mod(risingPhases,2*pi); 
            phases = phases';

            % count the number of spikes per frame
            % spikeCount is a 1xn vector of (number of spikes per frame), where n = number of frames
            spikeCount=zeros(size(correctedFrameIndices,1),1);
            for i=1:length(spikeCount) % for each frame
                spikeCount(i)=length(find(spikes>=correctedFrameIndices(i,1)&spikes<=correctedFrameIndices(i,2))); % inclusive?  policy: include start & stop
            end
            if numSweptParams>1
                error('unsupported case');
            end
            valsActual = valsSwept{1};
            valsOrdered = sort(valsSwept{1});
            types = nan(size(typesUnordered));
            for i = 1:length(valsOrdered)
                types(typesUnordered==i) = find(valsOrdered==valsActual(i));
            end



            % update what we know about te analysis to analysisdata
            analysisdata.stimInfo = stimInfo;
            analysisdata.trialNumber = parameters.trialNumber;
            analysisdata.subjectID = parameters.subjectID;
            % here be the meat of the analysis
            analysisdata.spikeCount = spikeCount;
            analysisdata.phases = phases;
            analysisdata.types = types;
            analysisdata.repeats = repeats;

            % analysisdata.firingRateByPhase = firingRateByPhase;
            analysisdata.spikeWaveforms = spikeWaveforms;
            analysisdata.spikeTimestamps = spikeTimestamps;


            % for storage in cumulative data....sort the relevant fields
            stimInfo.frequencies = sort(unique(frequencies));
            stimInfo.contrasts = sort(unique(contrasts));
            stimInfo.durations = sort(unique(durations));
            stimInfo.radii = sort(unique(radii));
            stimInfo.annuli = sort(unique(annuli));

            %get eyeData for phase-eye analysis
            if ~isempty(eyeData)
                [px py crx cry]=getPxyCRxy(eyeData,10);
                eyeSig=[crx-px cry-py];
                eyeSig(end,:)=[]; % remove last ones to match (not principled... what if we should throw out the first ones?)

                if length(unique(eyeSig(:,1)))>10 % if at least 10 x-positions

                    regionBoundsXY=[1 .5]; % these are CRX-PY bounds of unknown degrees
                    [within ellipses]=selectDenseEyeRegions(eyeSig,1,regionBoundsXY);

                    whichOne=0; % various things to look at
                    switch whichOne
                        case 0
                            %do nothing
                        case 1 % plot eye position and the clusters
                            regionBoundsXY=[1 .5]; % these are CRX-PY bounds of unknown degrees
                            within=selectDenseEyeRegions(eyeSig,3,regionBoundsXY,true);
                        case 2  % coded by phase
                            [n phaseID]=histc(phases,edges);
                            figure; hold on;
                            phaseColor=jet(numPhaseBins);
                            for i=1:numPhaseBins
                                plot(eyeSig(phaseID==i,1),eyeSig(phaseID==i,2),'.','color',phaseColor(i,:))
                            end
                        case 3
                            density=hist3(eyeSig);
                            imagesc(density)
                        case 4
                            eyeMotion=diff(eyeSig(:,1));
                            mean(eyeMotion>0)/mean(eyeMotion<0);   % is close to 1 so little bias to drift and snap
                            bound=3*std(eyeMotion(~isnan(eyeMotion)));
                            motionEdges=linspace(-bound,bound,100);
                            count=histc(eyeMotion,motionEdges);

                            figure; bar(motionEdges,log(count),'histc'); ylabel('log(count)'); xlabel('eyeMotion (crx-px)''')

                            figure; plot(phases',eyeMotion,'.'); % no motion per phase (more interesting for sqaure wave single freq)
                    end
                else
                    disp(sprintf('no good eyeData on trial %d',parameters.trialNumber))
                end
                analysisdata.eyeData = eyeSig;
            else
                analysisdata.eyedata = [];
                eyeSig = [];
            end

            %% now update cumulativedata
            if isempty(cumulativedata)
                cumulativedata.trialNumbers = parameters.trialNumber;
                cumulativedata.subjectID = parameters.subjectID;
                cumulativedata.stimInfo = stimInfo;
                cumulativedata.spikeCount = spikeCount; % i shall not store firingRateByPhase in cumulative
                cumulativedata.phases = phases;
                cumulativedata.types = types;
                cumulativedata.repeats = repeats;
                cumulativedata.spikeWaveforms = spikeWaveforms;
                cumulativedata.spikeTimestamps = spikeTimestamps;    
                cumulativedata.eyeData = eyeSig;
            elseif ~isequal(rmfield(cumulativedata.stimInfo,{'stimulusDetails','refreshRate','valsSwept'}),rmfield(stimInfo,{'stimulusDetails','refreshRate','valsSwept'}))
                keyboard
                error('something mighty fishy going on here.is it just an issue to do with repeats?');

            else % now concatenate only along the first dimension of phaseDensity and other stuff
                cumulativedata.trialNumbers = [cumulativedata.trialNumbers;parameters.trialNumber];
                cumulativedata.spikeCount = [cumulativedata.spikeCount;spikeCount]; % i shall not store firingRateByPhase in cumulative
                cumulativedata.phases = [cumulativedata.phases;phases];
                cumulativedata.types = [cumulativedata.types;types];
                repeats = repeats+max(cumulativedata.repeats);
                cumulativedata.repeats = [cumulativedata.repeats;repeats]; % repeats always gets added!
                cumulativedata.spikeWaveforms = [cumulativedata.spikeWaveforms;spikeWaveforms];
                cumulativedata.spikeTimestamps = [cumulativedata.spikeTimestamps;spikeTimestamps];
                cumulativedata.eyeData = [cumulativedata.eyeData;eyeSig];
            end
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


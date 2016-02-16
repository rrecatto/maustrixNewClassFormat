classdef gratings
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pixPerCycs = [];
        driftfrequencies = [];
        orientations = [];
        phases = [];
        contrasts = [];
        durations = [];
        numRepeats = [];

        radii = [];
        radiusType = 'gaussian';
        annuli = [];
        location = [];
        waveform='square';
        normalizationMethod='normalizeDiagonal';
        mean = 0;
        thresh = 0;
        changeableAnnulusCenter=false;
        changeableRadiusCenter=false;

        LUT =[];
        LUTbits=0;

        doCombos=true;
        ordering = [];

        LEDParams = [];
    end
    
    methods
        function s=gratings(varargin)
            % GRATINGS  class constructor.
            % s = gratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,durations,radii,annuli,location,
            %       waveform,normalizationMethod,mean,thresh,numRepeats,
            %       maxWidth,maxHeight,scaleFactor,interTrialLuminance[,doCombos])
            % Each of the following arguments is a 1xN vector, one element for each of N gratings
            % pixPerCycs - specified as in orientedGabors
            % driftfrequency - specified in cycles per second for now; the rate at which the grating moves across the screen
            % orientations - in radians
            % phases - starting phase of each grating frequency (in radians)
            %
            % contrasts - normalized (0 <= value <= 1) - Mx1 vector
            %
            % durations - up to MxN, specifying the duration (in seconds) of each pixPerCycs/contrast pair
            %
            % radii - the std dev of the enveloping gaussian, (by default in normalized units of the diagonal of the stim region) - can be of length N (N masks)
            % annuli - the radius of annuli that are centered inside the grating (in same units as radii)
            % location - a 2x1 vector, specifying x- and y-positions where the gratings should be centered; in normalized units as fraction of screen
            %           OR: a RFestimator object that will get an estimated location when needed
            % waveform - 'square', 'sine', or 'none'
            % normalizationMethod - 'normalizeDiagonal' (default), 'normalizeHorizontal', 'normalizeVertical', or 'none'
            % mean - must be between 0 and 1
            % thresh - must be greater than 0; in normalized luminance units, the value below which the stim should not appear
            % numRepeats - how many times to cycle through all combos
            % doCombos - a flag that determines whether or not to take the factorialCombo of all parameters (default is true)
            %   does the combinations in the following order:
            %   pixPerCycs > driftfrequencies > orientations > contrasts > phases > durations
            %   - if false, then takes unique selection of these parameters (they all have to be same length)
            %   - in future, handle a cell array for this flag that customizes the
            %   combo selection process.. if so, update analysis too
            % Mar 3 2011 - include blank trials.

            s.ordering.method = 'ordered';
            s.ordering.seed = [];
            s.ordering.includeBlank = false;

            s.LEDParams.active = false;
            s.LEDParams.numLEDs = 0;
            s.LEDParams.IlluminationModes = {};

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s = class(s,'gratings',stimManager());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'gratings'))
                        s = varargin{1};
                    else
                        error('Input argument is not a gratings object')
                    end
                case {18 19 20 21 22}

                    % create object using specified values
                    % check for doCombos argument first (it decides other error checking)
                    if nargin>18

                        if islogical(varargin{19})
                            s.doCombos=varargin{19};
                            s.ordering.method = 'ordered';
                            s.ordering.seed = [];
                            s.ordering.includeBlank = false;
                        elseif iscell(varargin{19}) && (length(varargin{19})==3)
                            s.doCombos = varargin{19}{1}; if ~islogical(varargin{19}{1}), error('doCombos should be a logical'), end;
                            s.ordering.method = varargin{19}{2}; if ~ismember(varargin{19}{2},{'twister','state','seed'}), error('unknown ordering method'), end;
                            s.ordering.seed = varargin{19}{3}; if (~(ischar(varargin{19}{3})&&strcmp(varargin{19}{3},'clock'))&&(~isnumeric(varargin{19}{3}))), ...
                                    error('seed should either be a number or set to ''clock'''), end;
                            s.ordering.includeBlank = false;
                        elseif iscell(varargin{19}) && (length(varargin{19})==4)
                            s.doCombos = varargin{19}{1}; if ~islogical(varargin{19}{1}), error('doCombos should be a logical'), end;
                            s.ordering.method = varargin{19}{2}; if ~ismember(varargin{19}{2},{'twister','state','seed'}), error('unknown ordering method'), end;
                            s.ordering.seed = varargin{19}{3}; if (~(ischar(varargin{19}{3})&&strcmp(varargin{19}{3},'clock'))&&(~isnumeric(varargin{19}{3}))), ...
                                    error('seed should either be a number or set to ''clock'''), end;
                            s.ordering.includeBlank = varargin{19}{4}; if ~islogical(varargin{19}{4}), error('includeBlank should be a logical'), end;
                        else
                            error('unknown way to specify doCombos. its either just a logical or a cell length 3.');
                        end
                    end
                    % pixPerCycs
                    if isvector(varargin{1}) && isnumeric(varargin{1})
                        s.pixPerCycs=varargin{1};
                    elseif isa(varargin{1},'SFestimator');
                        s.pixPerCycs = varargin{1};
                    else
                        error('pixPerCycs must be numbers OR an SFEstimator Object');
                    end
                    % driftfrequency
                    if isvector(varargin{2}) && isnumeric(varargin{2}) && all(varargin{2})>0
                        s.driftfrequencies=varargin{2};
                    else
                        error('driftfrequencies must all be > 0')
                    end
                    % orientations
                    if isvector(varargin{3}) && isnumeric(varargin{3})
                        s.orientations=varargin{3};
                    else
                        error('orientations must be numbers')
                    end
                    % phases
                    if isvector(varargin{4}) && isnumeric(varargin{4})
                        s.phases=varargin{4};
                    else
                        error('phases must be numbers');
                    end
                    % contrasts
                    if isvector(varargin{5}) && isnumeric(varargin{5}) && all(varargin{5}>=0 & varargin{5}<=1)
                        s.contrasts=varargin{5};
                    else
                        error('contrasts must be numbers between 0 and 1');
                    end
                     % durations
                    if isnumeric(varargin{6}) && all(all(varargin{6}>0))
                        s.durations=varargin{6};
                    else
                        error('all durations must be >0');
                    end
                    % radii
                    if isnumeric(varargin{7}) && all(varargin{7}>0) && all(~isinf(varargin{7}))
                        s.radii=varargin{7};
                    elseif iscell(varargin{7}) && (length(varargin{7})==2)
                        s.radii = varargin{7}{1};
                        s.radiusType = varargin{7}{2};
                        if ~all(varargin{7}{1}>0) || ~any(strcmp(varargin{7}{2},{'gaussian','hardEdge'}))
                            error('radii should be all non-negative, non-infinite and the radiusType should be ''gaussian'' or ''hardEdge''');
                        end
                    else
                        error('radii must be >= 0');
                    end
                    % annuli
                    if isnumeric(varargin{8}) && all(varargin{8}>=0)
                        s.annuli=varargin{8};
                    else
                        error('all annuli must be >= 0');
                    end
                    % numRepeats
                    if isinteger(varargin{14}) || isinf(varargin{14}) || isNearInteger(varargin{14})
                        s.numRepeats=varargin{14};
                    end

                    % check that if doCombos is false, then all parameters must be same length
                    if ~s.doCombos
                        paramLength = length(s.pixPerCycs);
                        if paramLength~=length(s.driftfrequencies) || paramLength~=length(s.orientations) || paramLength~=length(s.contrasts) ...
                                || paramLength~=length(s.phases) || paramLength~=length(s.durations) || paramLength~=length(s.radii) ...
                                || paramLength~=length(s.annuli)
                            error('if doCombos is false, then all parameters (pixPerCycs, driftfrequencies, orientations, contrasts, phases, durations, radii, annuli) must be same length');
                        end
                    end           


                    % location
                    if isnumeric(varargin{9}) && all(varargin{9}>=0) && all(varargin{9}<=1)
                        s.location=varargin{9};
                    elseif isa(varargin{9},'RFestimator')
                        s.location=varargin{9};
                    elseif isa(varargin{9},'wnEstimator')
                        s.location=varargin{9};
                    else
                        error('all location must be >= 0 and <= 1, or location must be an RFestimator object');
                    end
                    % waveform
                    if ischar(varargin{10})
                        if ismember(varargin{10},{'sine', 'square', 'none','catcam530a','haterenImage1000'})
                            s.waveform=varargin{10};
                        else
                            error('waveform must be ''sine'', ''square'', ''catcam530a'', or ''none''')
                        end
                    end
                    % normalizationMethod
                    if ischar(varargin{11})
                        if ismember(varargin{11},{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'})
                            s.normalizationMethod=varargin{11};
                        else
                            error('normalizationMethod must be ''normalizeVertical'', ''normalizeHorizontal'', or ''normalizeDiagonal'', or ''none''')
                        end
                    end
                    % mean
                    if varargin{12} >= 0 && varargin{12}<=1
                        s.mean=varargin{12};
                    else
                        error('0 <= mean <= 1')
                    end
                    % thres
                    if varargin{13} >= 0
                        s.thresh=varargin{13};
                    else
                        error('thresh must be >= 0')
                    end

                    if nargin>19
                        if ismember(varargin{20},[0 1])
                            s.changeableAnnulusCenter=logical(varargin{20});
                        else
                            error('gratingWithChangeableAnnulusCenter must be true / false')
                        end
                    end

                    if nargin>20
                        if ismember(varargin{21},[0 1])
                            s.changeableRadiusCenter=logical(varargin{21});
                        else
                            error('gratingWithChangeableRadiusCenter must be true / false')
                        end
                    end

                    if nargin>21
                        % LED state
                        if isstruct(varargin{22})
                            s.LEDParams = varargin{22};
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

                    s = class(s,'gratings',stimManager(varargin{15},varargin{16},varargin{17},varargin{18}));

                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
        end
        
        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,interTrialStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =...
    calcStim(stimulus,trialManager,allowRepeats,resolutions,displaySize,LUTbits,...
    responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % see ratrixPath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)
            % 1/3/0/09 - trialRecords now includes THIS trial
            indexPulses=[];
            imagingTasks=[];
            LUTbits
            displaySize
            [LUT stimulus updateSM]=getLUT(stimulus,LUTbits);
            % [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
            [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
            trialManagerClass = class(trialManager);
            OLED=false;
            if OLED
                error('forced to 60 Hz... do you realize that?')
                desiredWidth=800;
                desiredHeight=600;
                desiredHertz=60;
                ratrixEnforcedColor=32;
                resolutionIndex=find(([resolutions.height]==desiredHeight) & ([resolutions.width]==desiredWidth) & ([resolutions.pixelSize]==ratrixEnforcedColor) & ([resolutions.hz]==desiredHertz));
                height=resolutions(resolutionIndex).height
                width=resolutions(resolutionIndex).width
                hz=resolutions(resolutionIndex).hz
                if getMaxWidth(stimulus)~=desiredWidth
                    getMaxWidth(stimulus)
                    desiredWidth
                    error('not expected for OLED')
                end
            end
            if isnan(resolutionIndex)
                resolutionIndex=1;
            end

            scaleFactor=getScaleFactor(stimulus); % dummy value since we are phased anyways; the real scaleFactor is stored in each phase's stimSpec
            interTrialLuminance = getInterTrialLuminance(stimulus); 
            interTrialDuration = getInterTrialDuration(stimulus);
            toggleStim=true;
            type='expert';

            dynamicMode = true; % do things dynamically as in driftdemo2
            % dynamicMode=false;

            % =====================================================================================================

            details.pctCorrectionTrials=.5; % need to change this to be passed in from trial manager
            details.bias = getRequestBias(trialManager);

            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);

            % =====================================================================================================

            % set up params for computeGabors
            height = min(height,getMaxHeight(stimulus));
            width = min(width,getMaxWidth(stimulus));


            % temporal frequency
            if isa(stimulus.driftfrequencies,'grEstimator')&&strcmp(getType(stimulus.driftfrequencies),'driftfrequencies')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                singleUnitDetails.subjectID = subjectID;
                details.driftfrequencies=chooseValues(stimulus.driftfrequencies,singleUnitDetails);
            else
                details.driftfrequencies=stimulus.driftfrequencies;
            end

            %orientation
            if isa(stimulus.orientations,'grEstimator')&&strcmp(getType(stimulus.orientations),'orientations')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                singleUnitDetails.subjectID = subjectID;
                details.orientations=chooseValues(stimulus.orientations,singleUnitDetails);
            else
                details.orientations=stimulus.orientations;
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


            details.phases=stimulus.phases;

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

            if isa(stimulus.pixPerCycs,'grEstimator')&&strcmp(getType(stimulus.pixPerCycs),'spatialFrequencies')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                singleUnitDetails.subjectID = subjectID;
                details.spatialFrequencies=chooseValues(stimulus.pixPerCycs,singleUnitDetails);    
            else
                details.spatialFrequencies=stimulus.pixPerCycs; % 1/7/09 - renamed from pixPerCycs to spatialFrequencies (to avoid clashing with compile process)
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

            details.waveform=stimulus.waveform;

            details.width=width;
            details.height=height;

            % NOTE: all fields in details should be MxN now

            % =====================================================================================================

            % =====================================================================================================
            % dynamic mode
            % for now we will attempt to calculate each frame on-the-fly, 
            % but we might need to precache all contrast/orientation/pixPerCycs pairs and then rotate phase dynamically
            % still pass out stimSpecs as in cache mode, but the 'stim' is a struct of parameters
            % stim.pixPerCycs - frequency of the grating (how wide the bars are)
            % stim.orientations - angle of the grating
            % stim.velocities - frequency of the phase (how quickly we go through a 0:2*pi cycle of the sine curve)
            % stim.location - where to center each grating (modifies destRect)
            % stim.contrasts - contrast of the grating
            % stim.durations - duration of each grating (in frames)
            % stim.mask - the mask to be used (empty if unmasked)
            stim=[];

            stim.width=details.width;
            stim.height=details.height;
            stim.location=details.location;
            stim.numRepeats=details.numRepeats;
            stim.waveform=details.waveform;
            stim.changeableAnnulusCenter=details.changeableAnnulusCenter;
            stim.changeableRadiusCenter=details.changeableRadiusCenter;

            % details has the parameters before combos, stim should have them after combos are taken
            if stimulus.doCombos
                % do combos here
                mode = {details.method,details.seed};
                comboMatrix = generateFactorialCombo({details.spatialFrequencies,details.driftfrequencies,details.orientations,...
                    details.contrasts,details.phases,details.durations,details.radii,details.annuli},[],[],mode);
                stim.pixPerCycs=comboMatrix(1,:);
                stim.driftfrequencies=comboMatrix(2,:);
                stim.orientations=comboMatrix(3,:);
                stim.contrasts=comboMatrix(4,:); %starting phases in radians
                stim.phases=comboMatrix(5,:);
                stim.durations=round(comboMatrix(6,:)*hz); % CONVERTED FROM seconds to frames
                stim.radii=comboMatrix(7,:);
                stim.annuli=comboMatrix(8,:);
            else
                stim.pixPerCycs=details.spatialFrequencies;
                stim.driftfrequencies=details.driftfrequencies;
                stim.orientations=details.orientations;
                stim.contrasts=details.contrasts;
                stim.phases=details.phases;
                stim.durations=round(details.durations*hz); % CONVERTED FROM seconds to frames    
                stim.radii=details.radii;
                stim.annuli=details.annuli;
            end

            % support for includeBlank
            if details.includeBlank
                stim.pixPerCycs(end+1) = stim.pixPerCycs(end);
                stim.driftfrequencies(end+1)=stim.driftfrequencies(end);
                stim.orientations(end+1)=stim.orientations(end);
                stim.contrasts(end+1)=0; % the blank is a zero contrast stimulus
                stim.phases(end+1)=stim.phases(end);
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

            switch stimulus.waveform
                case 'haterenImage1000'
                    path='\\132.239.158.183\rlab_storage\pmeier\vanhateren\iml_first1000';
                            imName='imk01000.iml';
                    f1=fopen(fullfile(path,imName),'rb','ieee-be');
                    w=1536;h=1024;
                    im=fread(f1,[w,h],'uint16');
                    im=im';
                    %          subplot(2,2,1); hist(im(:))
                    %          subplot(2,2,2); imagesc(im); colormap(gray)
                     im=im-mean(im(:));
                     im=0.5*im/std(im(:));
                     im(im>1)=1;
                     im(im<-1)=-1;
                     %         subplot(2,2,3); hist(im(:))
                     %         subplot(2,2,4); imagesc(im); colormap(gray)
                     details.images=im;
                     stim.images=details.images;
                case 'catcam530a'
                    path='\\132.239.158.183\rlab_storage\pmeier\CatCam\labelb000530a';
                    imName='Catt0910.tif';
                    im=double(imread(fullfile(path,imName)));
                    im=im-mean(im(:));
                    im=0.5*im/std(im(:));
                    im(im>1)=1;
                    im(im<-1)=-1;
                    %         subplot(1,2,1); hist(im(:))
                    %         subplot(1,2,2); imagesc(im); colormap(gray)
                    details.images=im;
                    stim.images=details.images;
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
            details.percentCorrectionTrials = getPercentCorrectionTrials(trialManager);
            if strcmp(trialManagerClass,'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('thresh: %g',stimulus.thresh);
            end
        end
        
        function commonName = commonNameForStim(stimType,params)
            classType = class(stimType);

            numSpatialFrequencies = length(params.spatialFrequencies);
            numDriftfrequencies = length(params.driftfrequencies);
            numOrientations = length(params.orientations);

            stimAxes = [numSpatialFrequencies numDriftfrequencies numOrientations];
            sweepTypes = {'spatGr','tempGr','orGr','cntrGr','radGr'};
            sweepUnits = {'spatFreqs.','tempFreqs.','orientations.','contrasts.','radii.'};

            if length(find(stimAxes>1))>1
                complexStimType = true;
                stimIsSwept = true;
                sweepType = '';
            elseif length(find(stimAxes>1))==1
                complexStimType = false;
                stimIsSwept = true;
                sweepType = sweepTypes{stimAxes>1};
                sweepUnit = sweepUnits{stimAxes>1};
            else
                complexStimType = false;
                stimIsSwept = false;
            end

            if params.annuli 
                if isfield(params, 'changeableAnnulusCenter') && params.changeableAnnulusCenter
                    annuliStr = 'with mannulus.';
                else
                    annuliStr = 'with annulus.';
                end
            else
                annuliStr = '';
            end

            if ~complexStimType && stimIsSwept
                if isfield(params,'waveform')
                    commonName = sprintf('%s: %d %s %s waveform: %s.',sweepType,stimAxes(stimAxes>1),sweepUnit,annuliStr,params.waveform);
                else
                    commonName = sprintf('%s: %d %s %s waveform: %s.',sweepType,stimAxes(stimAxes>1),sweepUnit,annuliStr,'not specified');
                end
            elseif ~complexStimType && ~stimIsSwept
                if isfield(params,'waveform')
                    commonName = sprintf('%s: %s waveform: %s.','No param sweep',annuliStr,params.waveform);
                else
                    commonName = sprintf('%s: %s waveform: %s.','No param sweep',annuliStr,'not specified');
                end
            else
                commonName = 'complex grating stimulus';
            end
        end
        
        function paramsIdentical = compareStimRecords(stimType,params1,params2)
            stimParameters = {'spatialFrequencies','driftfrequencies','orientations','phases','contrasts',...
                    'location','durations','radii','annuli','numRepeats','doCombos','changeableAnnulusCenter','waveform'};
            diffIn = {};
            %==========================================================================
            % BEGIN NUMERIC DATA TYPES
            % check for spatialFrequencies
            if isfield(params1,'spatialFrequencies') && isfield(params2,'spatialFrequencies') && ...
                    length(params1.spatialFrequencies)==length(params2.spatialFrequencies) && ...
                    all(sort(params1.spatialFrequencies)==sort(params2.spatialFrequencies))
                % do nothing
            else
                diffIn{end+1} = {'spatialFrequencies'};
            end

            % check for driftfrequencies
            if isfield(params1,'driftfrequencies') && isfield(params2,'driftfrequencies') && ...
                    length(params1.driftfrequencies)==length(params2.driftfrequencies) && ...
                    all(sort(params1.driftfrequencies)==sort(params2.driftfrequencies))
                % do nothing
            else
                diffIn{end+1} = {'driftfrequencies'};
            end

            % check for orientations
            if isfield(params1,'orientations') && isfield(params2,'orientations') && ...
                    length(params1.orientations)==length(params2.orientations) && ...
                    all(sort(params1.orientations)==sort(params2.orientations))
                % do nothing
            else
                diffIn{end+1} = {'orientations'};
            end

            % check for phases
            if isfield(params1,'phases') && isfield(params2,'phases') && ...
                    length(params1.phases)==length(params2.phases) && ...
                    all(sort(params1.phases)==sort(params2.phases))
                % do nothing
            else
                diffIn{end+1} = {'phases'};
            end

            % check for contrasts
            if isfield(params1,'contrasts') && isfield(params2,'contrasts') && ...
                    length(params1.contrasts)==length(params2.contrasts) && ...
                    all(sort(params1.contrasts)==sort(params2.contrasts))
                % do nothing
            else
                diffIn{end+1} = {'contrasts'};
            end

            % check for location
            if isfield(params1,'location') && isfield(params2,'location') && ...
                    length(params1.location)==length(params2.location) && ...
                    all(sort(params1.location)==sort(params2.location))
                % do nothing
            else
                diffIn{end+1} = {'location'};
            end

            % check for durations
            if isfield(params1,'durations') && isfield(params2,'durations') && ...
                    length(params1.durations)==length(params2.durations) && ...
                    all(sort(params1.durations)==sort(params2.durations))
                % do nothing
            else
                diffIn{end+1} = {'durations'};
            end

            % check for radii
            if isfield(params1,'radii') && isfield(params2,'radii') && ...
                    length(params1.radii)==length(params2.radii) && ...
                    all(sort(params1.radii)==sort(params2.radii))
                % do nothing
            else
                diffIn{end+1} = {'radii'};
            end

            % check for annuli
            if isfield(params1,'annuli') && isfield(params2,'annuli') && ...
                    length(params1.annuli)==length(params2.annuli) && ...
                    all(sort(params1.annuli)==sort(params2.annuli))
                % do nothing
            else
                diffIn{end+1} = {'annuli'};
            end

            % check for numRepeats
            if isfield(params1,'numRepeats') && isfield(params2,'numRepeats') && ...
                    length(params1.numRepeats)==length(params2.numRepeats) && ...
                    all(sort(params1.numRepeats)==sort(params2.numRepeats))
                % do nothing
            else
                diffIn{end+1} = {'numRepeats'};
            end
            % END OF NUMERIC DATA TYPES
            %==========================================================================
            %==========================================================================
            % BEGIN LOGICAL DATA TYPES

            stimParameters = {'doCombos','changeableAnnulusCenter','waveform'};

            % check for doCombos
            if isfield(params1,'doCombos') && isfield(params2,'doCombos') && ...
                    length(params1.doCombos)==length(params2.doCombos) && ...
                    all(params1.doCombos==params2.doCombos)
                % do nothing
            else
                diffIn{end+1} = {'doCombos'};
            end

            % check for changeableAnnulusCenter
            if isfield(params1,'changeableAnnulusCenter') && isfield(params2,'changeableAnnulusCenter') && ...
                    length(params1.changeableAnnulusCenter)==length(params2.changeableAnnulusCenter) && ...
                    all(params1.changeableAnnulusCenter==params2.changeableAnnulusCenter)
                % do nothing
            else
                diffIn{end+1} = {'changeableAnnulusCenter'};
            end

            % END LOGICAL DATA TYPES
            %==========================================================================
            %==========================================================================
            % BEGIN STRING DATA TYPES

            % check for waveform
            if isfield(params1,'waveform') && isfield(params2,'waveform') && strcmp(params1.waveform,params2.waveform)
                % do nothing
            else
                diffIn{end+1} = {'waveform'};
            end

            % END STRING DATA TYPES
            %==========================================================================

            paramsIdentical = isempty(diffIn);
        end

        function displayCumulativePhysAnalysis(sm,cumulativedata,parameters)
            devON = false;
            if devON
                displayCumulativePhysAnalysisDev(sm,cumulativedata,parameters)
                return;
            end
            % setup for plotting
            sweptParameter = char(cumulativedata.stimInfo.sweptParameters);
            numTypes = cumulativedata.stimInfo.numTypes;
            vals = cumulativedata.stimInfo.(sweptParameter);
            [junk order] = sort(vals,'ascend');
            if strcmp(sweptParameter,'orientations')
                vals=rad2deg(vals);
            end

            if all(rem(vals,1)==0)
                format='%2.0f';
            else
                format='%1.2f';
            end
            for i=1:length(vals);
                valNames{i}=num2str(vals(order(i)),format);
            end;

            colors=jet(numTypes);
            figure(parameters.figHandle); % new for each trial
            clf(parameters.figHandle);
            set(gcf,'position',[100 300 560 620])
            figName = sprintf('%s. %s. trialRange: %s',parameters.trodeName,parameters.stepName,mat2str(parameters.trialRange));
            set(gcf,'Name',figName,'NumberTitle','off')

            subplot(3,2,1); hold off; %p=plot([1:numPhaseBins]-.5,rate')
            colordef white

            numRepeats = cumulativedata.stimInfo.stimulusDetails.numRepeats;


            numPhaseBins = cumulativedata.numPhaseBins;
            rate = cumulativedata.rate(order,:);
            rateSEM = cumulativedata.rateSEM(order,:);
            pow = cumulativedata.pow(order);
            coh = cumulativedata.coh(order);
            cohLB = cumulativedata.cohLB(order);
            temp = cumulativedata.phaseDensity;
            for i = 1:numTypes
                phaseDensity((i-1)*numRepeats+1:i*numRepeats,:) = temp((order(i)-1)*numRepeats+1:order(i)*numRepeats,:);
            end
            powSEM = cumulativedata.powSEM(order);
            cohSEM = cumulativedata.cohSEM(order);
            eyeData = cumulativedata.eyeData;

            plot([0 numPhaseBins], [rate(1) rate(1)],'color',[1 1 1]); hold on;% to save tight axis chop
            x=[1:numPhaseBins]-.5;
            for i=1:numTypes
                plot(x,rate(order(i),:),'color',colors(order(i),:))
                plot([x; x],[rate(order(i),:); rate(order(i),:)]+(rateSEM(order(i),:)'*[-1 1])','color',colors(order(i),:))
            end
            maxPowerInd=find(pow==max(pow));
            if length(maxPowerInd)>1
                maxPowerInd = maxPowerInd(1);
            end
            if ~isempty(pow)
                plot(x,rate(maxPowerInd,:),'color',colors(maxPowerInd,:),'lineWidth',2);
            end
            xlabel('phase');  set(gca,'XTickLabel',{'0','pi','2pi'},'XTick',([0 .5 1]*numPhaseBins)); ylabel('rate'); set(gca,'YTickLabel',[0:.1:1]*cumulativedata.refreshRate,'YTick',[0:.1:1])
            axis tight

            %rate density over phase... doubles as a legend
            subplot(3,2,2); hold off;
            im=zeros([size(phaseDensity) 3]);
            hues=rgb2hsv(colors);  % get colors to match jet
            hues=repmat(hues(:,1)',numRepeats,1); % for each rep
            hues=repmat(hues(:),1,numPhaseBins);  % for each phase bin
            im(:,:,1)=hues; % hue
            im(:,:,2)=1; % saturation
            im(:,:,3)=phaseDensity/max(phaseDensity(:)); % value
            rgbIm=hsv2rgb(im);
            image(rgbIm); hold on
            axis([0 size(im,2) 0 size(im,1)]+.5);
            ylabel(sweptParameter); set(gca,'YTickLabel',valNames,'YTick',size(im,1)*([1:length(vals)]-.5)/length(vals))
            xlabel('phase');  set(gca,'XTickLabel',{'0','pi','2pi'},'XTick',([0 .5 1]*numPhaseBins)+.5);

            subplot(3,2,3); hold off; plot(mean(rate'),'k','lineWidth',2); hold on; %legend({'Fo'})
            xlabel(sweptParameter); set(gca,'XTickLabel',valNames,'XTick',[1:length(vals)]); ylabel('rate (f0)'); set(gca,'YTickLabel',[0:.1:1]*cumulativedata.refreshRate); %,'YTick',[0:.1:1]
            set(gca,'XLim',[1 length(vals)])


            subplot(3,2,4); hold off
            if ~isempty(pow)
                modulation=pow./(cumulativedata.refreshRate*mean(rate'));
                plot(pow,'k','lineWidth',1); hold on;
                plot(modulation,'--k','lineWidth',2); hold on;
                cohScaled=coh*max(pow); %1 is peak FR
                plot(cohScaled,'color',[.8 .8 .8],'lineWidth',1);
                sigs=find(cohLB>0);
                plot(sigs,cohScaled(sigs),'o','color',[.6 .6 .6]);
                legend({'f1','f1/f0','coh'})


                plot([1:length(vals); 1:length(vals)],[pow; pow]+(powSEM'*[-1 1])','k')
                %plot([1:length(vals); 1:length(vals)],[pow; pow]+(powSEM'*[-1 1])','k')
                plot([1:length(vals); 1:length(vals)]+0.1,[coh; coh]+(cohSEM'*[-1 1])','color',[.8 .8 .8])
                xlabel(sweptParameter); set(gca,'XTickLabel',valNames,'XTick',[1:length(vals)]); ylabel('modulation (f1/f0)');
                ylim=get(gca,'YLim'); yvals=[ ylim(1) mean(ylim) ylim(2)];set(gca,'YTickLabel',yvals,'YTick',yvals)
                set(gca,'XLim',[1 length(vals)])
            else
                xlabel(sprintf('not enough data for all %s yet',sweptParameter))
            end
            meanRate=cumulativedata.spikeCount;
            isi=diff(cumulativedata.spikeTimestamps)*1000;
            N=sum(isi<cumulativedata.ISIviolationMS); percentN=100*N/length(isi);
            ylim=get(gca,'YLim');

            subplot(3,2,5);
            numBins=40; maxTime=10; % ms
            edges=linspace(0,maxTime,numBins); [count]=histc(isi,edges);
            hold off; bar(edges,count,'histc'); axis([0 maxTime get(gca,'YLim')]);
            hold on; plot(cumulativedata.ISIviolationMS([1 1]),get(gca,'YLim'),'k' )
            xvalsName=[0 cumulativedata.ISIviolationMS maxTime]; xvals=xvalsName*cumulativedata.samplingRate/(1000*numBins);
            set(gca,'XTickLabel',xvalsName,'XTick',xvals)
            infoString=sprintf('viol: %2.2f%%\n(%d /%d)',percentN,N,length(isi))
            text(xvals(3),max(count),infoString,'HorizontalAlignment','right','VerticalAlignment','top');
            ylabel('count'); xlabel('isi (ms)')

            subplot(3,2,6); hold off;
            if ~isempty(eyeData)
                [px py crx cry]=getPxyCRxy(eyeData,10);
                eyeSig=[crx-px cry-py];
                eyeSig(end,:)=[]; % remove last ones to match (not principled... what if we should throw out the first ones?)
                plot(eyeSig(1,1),eyeSig(1,2),'.k');  hold on; % plot one dot to flush history
                if exist('ellipses','var')
                    plotEyeElipses(eyeSig,ellipses,within,true)
                else
                    text(.5,.5,'no good eye data')
                end
                xlabel('eye position (cr-p)')
            else
                text(.5,.5,'no eye data')
            end

            % now plot the spikes
            ax = axes('Position',[0.91 0.91 0.08 0.08]);

            plot(cumulativedata.spikeWaveforms','r')
            axis tight
            set(ax,'XTick',[],'Ytick',[]);

        end
        
        function displayCumulativePhysAnalysisDev(sm,cumulativedata,parameters)
            return
            % setup for plotting
            if cumulativedata.stimInfo.numSweptParams>1
                error('unsupported number of parameters');
            end
            sweptParameter = char(cumulativedata.stimInfo.sweptParameters);
            numTypes = cumulativedata.stimInfo.numTypes;
            vals = cumulativedata.stimInfo.(sweptParameter);
            [junk order] = sort(vals,'ascend');
            if strcmp(sweptParameter,'orientations')
                vals=rad2deg(vals);
            end

            if all(rem(vals,1)==0)
                format='%2.0f';
            else
                format='%1.2f';
            end
            for i=1:length(vals);
                valNames{i}=num2str(vals(order(i)),format);
            end;

            colors=jet(numTypes);
            figure(parameters.figHandle); % new for each trial
            clf(parameters.figHandle);
            set(gcf,'position',[100 300 560 620])
            figName = sprintf('%s. %s. trialRange: %s',parameters.trodeName,parameters.stepName,mat2str(parameters.trialRange));
            set(gcf,'Name',figName,'NumberTitle','off')

            subplot(3,2,1); hold off; %p=plot([1:numPhaseBins]-.5,rate')
            colordef white

            numRepeats = cumulativedata.stimInfo.numRepeats;
            numPhaseBins = cumulativedata.stimInfo.numPhaseBins;
            phaseDensity = cumulativedata.phaseDensity(:,:,order);
            rate = squeeze(sum(phaseDensity,1));
            rateSEM = squeeze(std(phaseDensity,[],1));
            pow = cumulativedata.pow(order);
            coh = cumulativedata.coh(order);
            cohLB = cumulativedata.cohLB(order);
            temp = cumulativedata.phaseDensity;
            for i = 1:numTypes
                phaseDensity((i-1)*numRepeats+1:i*numRepeats,:) = temp((order(i)-1)*numRepeats+1:order(i)*numRepeats,:);
            end
            powSEM = cumulativedata.powSEM(order);
            cohSEM = cumulativedata.cohSEM(order);
            eyeData = cumulativedata.eyeData;

            plot([0 numPhaseBins], [rate(1) rate(1)],'color',[1 1 1]); hold on;% to save tight axis chop
            x=[1:numPhaseBins]-.5;
            for i=1:numTypes
                plot(x,rate(order(i),:),'color',colors(order(i),:))
                plot([x; x],[rate(order(i),:); rate(order(i),:)]+(rateSEM(order(i),:)'*[-1 1])','color',colors(order(i),:))
            end
            maxPowerInd=find(pow==max(pow));
            if length(maxPowerInd)>1
                maxPowerInd = maxPowerInd(1);
            end
            if ~isempty(pow)
                plot(x,rate(maxPowerInd,:),'color',colors(maxPowerInd,:),'lineWidth',2);
            end
            xlabel('phase');  set(gca,'XTickLabel',{'0','pi','2pi'},'XTick',([0 .5 1]*numPhaseBins)); ylabel('rate'); set(gca,'YTickLabel',[0:.1:1]*cumulativedata.refreshRate,'YTick',[0:.1:1])
            axis tight

            %rate density over phase... doubles as a legend
            subplot(3,2,2); hold off;
            im=zeros([size(phaseDensity) 3]);
            hues=rgb2hsv(colors);  % get colors to match jet
            hues=repmat(hues(:,1)',numRepeats,1); % for each rep
            hues=repmat(hues(:),1,numPhaseBins);  % for each phase bin
            im(:,:,1)=hues; % hue
            im(:,:,2)=1; % saturation
            im(:,:,3)=phaseDensity/max(phaseDensity(:)); % value
            rgbIm=hsv2rgb(im);
            image(rgbIm); hold on
            axis([0 size(im,2) 0 size(im,1)]+.5);
            ylabel(sweptParameter); set(gca,'YTickLabel',valNames,'YTick',size(im,1)*([1:length(vals)]-.5)/length(vals))
            xlabel('phase');  set(gca,'XTickLabel',{'0','pi','2pi'},'XTick',([0 .5 1]*numPhaseBins)+.5);

            subplot(3,2,3); hold off; plot(mean(rate'),'k','lineWidth',2); hold on; %legend({'Fo'})
            xlabel(sweptParameter); set(gca,'XTickLabel',valNames,'XTick',[1:length(vals)]); ylabel('rate (f0)'); set(gca,'YTickLabel',[0:.1:1]*cumulativedata.refreshRate); %,'YTick',[0:.1:1]
            set(gca,'XLim',[1 length(vals)])


            subplot(3,2,4); hold off
            if ~isempty(pow)
                modulation=pow./(cumulativedata.refreshRate*mean(rate'));
                plot(pow,'k','lineWidth',1); hold on;
                plot(modulation,'--k','lineWidth',2); hold on;
                cohScaled=coh*max(pow); %1 is peak FR
                plot(cohScaled,'color',[.8 .8 .8],'lineWidth',1);
                sigs=find(cohLB>0);
                plot(sigs,cohScaled(sigs),'o','color',[.6 .6 .6]);
                legend({'f1','f1/f0','coh'})


                plot([1:length(vals); 1:length(vals)],[pow; pow]+(powSEM'*[-1 1])','k')
                %plot([1:length(vals); 1:length(vals)],[pow; pow]+(powSEM'*[-1 1])','k')
                plot([1:length(vals); 1:length(vals)]+0.1,[coh; coh]+(cohSEM'*[-1 1])','color',[.8 .8 .8])
                xlabel(sweptParameter); set(gca,'XTickLabel',valNames,'XTick',[1:length(vals)]); ylabel('modulation (f1/f0)');
                ylim=get(gca,'YLim'); yvals=[ ylim(1) mean(ylim) ylim(2)];set(gca,'YTickLabel',yvals,'YTick',yvals)
                set(gca,'XLim',[1 length(vals)])
            else
                xlabel(sprintf('not enough data for all %s yet',sweptParameter))
            end
            meanRate=cumulativedata.spikeCount;
            isi=diff(cumulativedata.spikeTimestamps)*1000;
            N=sum(isi<cumulativedata.ISIviolationMS); percentN=100*N/length(isi);
            ylim=get(gca,'YLim');

            subplot(3,2,5);
            numBins=40; maxTime=10; % ms
            edges=linspace(0,maxTime,numBins); [count]=histc(isi,edges);
            hold off; bar(edges,count,'histc'); axis([0 maxTime get(gca,'YLim')]);
            hold on; plot(cumulativedata.ISIviolationMS([1 1]),get(gca,'YLim'),'k' )
            xvalsName=[0 cumulativedata.ISIviolationMS maxTime]; xvals=xvalsName*cumulativedata.samplingRate/(1000*numBins);
            set(gca,'XTickLabel',xvalsName,'XTick',xvals)
            infoString=sprintf('viol: %2.2f%%\n(%d /%d)',percentN,N,length(isi))
            text(xvals(3),max(count),infoString,'HorizontalAlignment','right','VerticalAlignment','top');
            ylabel('count'); xlabel('isi (ms)')

            subplot(3,2,6); hold off;
            if ~isempty(eyeData)
                [px py crx cry]=getPxyCRxy(eyeData,10);
                eyeSig=[crx-px cry-py];
                eyeSig(end,:)=[]; % remove last ones to match (not principled... what if we should throw out the first ones?)
                plot(eyeSig(1,1),eyeSig(1,2),'.k');  hold on; % plot one dot to flush history
                if exist('ellipses','var')
                    plotEyeElipses(eyeSig,ellipses,within,true)
                else
                    text(.5,.5,'no good eye data')
                end
                xlabel('eye position (cr-p)')
            else
                text(.5,.5,'no eye data')
            end

            % now plot the spikes
            ax = axes('Position',[0.91 0.91 0.08 0.08]);

            plot(cumulativedata.spikeWaveforms','r')
            axis tight
            set(ax,'XTick',[],'Ytick',[]);

        end

        function [doFramePulse, expertCache, dynamicDetails, textLabel, i, dontclear, indexPulse] = ...
    drawExpertFrame(stimulus,stim,i,phaseStartTime,totalFrameNum,window,textLabel,destRect,filtMode,...
    expertCache,ifi,scheduledFrameNum,dropFrames,dontclear,dynamicDetails)
            % 11/14/08 - implementing expert mode for gratings
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
            numGratings = length(stim.pixPerCycs); % number of gratings
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
            cycsPerFrameVel = stim.driftfrequencies(gratingToDraw)*ifi; % in units of cycles/frame
            offset = 2*pi*cycsPerFrameVel*i;
            nextOffset = 2*pi*cycsPerFrameVel*(i+1);
            indexPulse=mod(offset,4*pi)>mod(nextOffset,4*pi);  % every 2 cycles


            % Create a 1D vector x based on the frequency pixPerCycs
            % make the grating twice the normal width (to cover entire screen if rotated)
            x = (1:stim.width*2)*2*pi/stim.pixPerCycs(gratingToDraw);
            switch stim.waveform
                case 'sine'
                    grating=stim.contrasts(gratingToDraw)*stimulus.mean*cos(x + offset+stim.phases(gratingToDraw))+stimulus.mean; % grating is the cos curve, with our calculated phase offset (based on driftfrequency) and initial phase
                case 'square'
                    grating=stim.contrasts(gratingToDraw)*stimulus.mean*square(x + offset+stim.phases(gratingToDraw)+pi/2)+stimulus.mean; % same as sine, but adjust for cosine
                case 'squareUp4th'
                    grating=stim.contrasts(gratingToDraw)*(-1+2*(mod([x + offset+stim.phases(gratingToDraw)+pi/2],pi*2)<pi/4))+stimulus.mean; % same as square above, but only up 1/8, as opposed to 1/2 the time... matched onset
                case {'catcam530a','haterenImage1000'}
                    whichPixels=ceil(mod((1:stim.width*2)+(cycsPerFrameVel*i*size(stim.images,2)),size(stim.images,2)));
                    whichPixels(whichPixels==0)=size(stim.images,2);
                    whichSequence=stim.phases(gratingToDraw); % this chooses the y line to take a horizontal luminance sequence from
                    shape=stim.images(whichSequence,whichPixels);
                    grating=stim.contrasts(gratingToDraw)*shape+stimulus.mean;
                otherwise
                    stim.waveform
                    error('that waveform is not coded')
            end

            % grating=repmat(grating, [1 2]);
            % Make grating texture
            gratingtex=Screen('MakeTexture',window,grating,0,0,floatprecision);

            % set srcRect
            srcRect=[0 0 size(grating,2) 1];

            % Draw grating texture, rotated by "angle":
            destWidth = destRect(3)-destRect(1);
            destHeight = destRect(4)-destRect(2);
            destRectForGrating = [destRect(1)-destWidth/2, destRect(2)-destHeight, destRect(3)+destWidth/2,destRect(4)+destHeight];
            Screen('DrawTexture', window, gratingtex, srcRect, destRectForGrating, ...
                (180/pi)*stim.orientations(gratingToDraw), filtMode);

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
                if isempty(expertCache.masktexs{stim.maskInds(gratingToDraw)})
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
                Screen('DrawTexture', window, expertCache.masktexs{stim.maskInds(gratingToDraw)}, [], destRect,[], filtMode);
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
                    Screen('DrawTexture',window,expertCache.annulitexs{stim.annuliInds(expertCache.annulusInd)},[],annulusDestRec,[],filtMode);
                else
                    annulusDestRec=destRect;
                    Screen('DrawTexture',window,expertCache.annulitexs{stim.annuliInds(gratingToDraw)},[],annulusDestRec,[],filtMode);
                end
                Screen('Close',expertCache.masktexs{stim.maskInds(gratingToDraw)});

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
                [out.doCombos newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);

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

            if ~exist('linearizedRange','var') || isempty(linearizedRange)
                linearizedRange = [0 1];
            end

            if ~exist('plotOn','var')
                plotOn=0;
            end

            useUncorrected=0;

            switch method
                case 'mostRecentLinearized'    
                    method
                    error('that method for getting a LUT is not defined');
                case 'tempLinearRedundantCode'   
                    LUTBitDepth=8;
                    numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID); 
                    ramp=[0:fraction:1];
                    grayColors= [ramp;ramp;ramp]';
                    %maybe ask for red / green / blue gun only
                    linearizedCLUT=grayColors;
                case '2009Trinitron255GrayBoxInterpBkgnd.5'

                    conn=dbConn();
                    mac='0018F35DFAC0'  % from the phys rig
                    timeRange=[datenum('06-09-2009 23:01','mm-dd-yyyy HH:MM') datenum('06-11-2009 23:59','mm-dd-yyyy HH:MM')];
                    cal=getCalibrationData(conn,mac,timeRange);
                    closeConn(conn)

                    LUTBitDepth=8;
                    spyderCdPerMsquared=cal.measuredValues;
                    stim=cal.details.method{2};
                    vals=double(reshape(stim(:,:,1,:),[],size(stim,4)));
                    if all(diff(spyderCdPerMsquared)>0) && length(spyderCdPerMsquared)==length(vals)
                        range=diff(spyderCdPerMsquared([1 end]));
                        floorSpyder=spyderCdPerMsquared(1);
                        desiredVals=linspace(floorSpyder+range*linearizedRange(1),floorSpyder+range*linearizedRange(2),2^LUTBitDepth);
                        newLUT = interp1(spyderCdPerMsquared,vals,desiredVals,'linear')/vals(end); %consider pchip
                        linearizedCLUT = repmat(newLUT',1,3);
                    else
                        error('vals not monotonic -- should fit parametrically or check that data collection OK')
                    end
                case 'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5'
                    conn=dbConn();
                    [junk mac] = getMACaddress();

                    if ~strcmp(mac,'001D7D9ACF80')% how come mac changed??? it was this prev... 00095B8E6171
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
                            if true || (any(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')) && ...
                                    datenum(a(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')).date)>floor(now))
                                temp = load(fullfile(getRatrixPath,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat'));
                                linearizedCLUT = temp.cal.linearizedCLUT;
                                downloadCLUT = false;
                            end
                        end
                        if downloadCLUT
                            timeRange=[datenum('05-15-2011 00:01','mm-dd-yyyy HH:MM') datenum('05-15-2011 23:59','mm-dd-yyyy HH:MM')];
                            cal=getCalibrationData(conn,mac,timeRange);
                            closeConn(conn)
                            linearizedCLUT = cal.linearizedCLUT;
                            % now save cal
                            filename = fullfile(getRatrixPath,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat');
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
                        linearizedCLUT=grayColors;
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
                                linearizedCLUT = temp.cal.linearizedCLUT;
                                downloadCLUT = false;
                            end
                        end
                        if downloadCLUT
                            timeRange=[datenum('03-19-2011 00:01','mm-dd-yyyy HH:MM') datenum('03-19-2011 15:00','mm-dd-yyyy HH:MM')];
                            cal=getCalibrationData(conn,mac,timeRange);
                            closeConn(conn)
                            linearizedCLUT = cal.linearizedCLUT;
                            % now save cal
                            filename = fullfile(getRatrixPath,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat');
                            save(filename,'cal');
                        end
                    end
                case 'calibrateNow'
                    %[measured_R measured_G measured_B] measureRGBscale()
                    method
                    error('that method for getting a LUT is not defined');
                case 'localCalibStore'
                    try
                        temp = load(fullfile(getRatrixPath,'monitorCalibration','tempCLUT.mat'));
                        linearizedCLUT = temp.linearizedCLUT;
                    catch ex
                        disp('did you store local calibration details at all????');
                        rethrow(ex)
                    end
                otherwise
                    method
                    error('that method for getting a LUT is not defined');
            end

            method
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
                    sweepnames={'spatialFrequencies','driftfrequencies','orientations','contrasts','phases','durations','radii','annuli'};

                    numValsPerParam = [length(stim.stimulusDetails.spatialFrequencies) length(stim.stimulusDetails.driftfrequencies) length(stim.stimulusDetails.orientations)...
                        length(stim.stimulusDetails.contrasts) length(stim.stimulusDetails.phases) length(stim.stimulusDetails.durations)...
                        length(stim.stimulusDetails.radii) length(stim.stimulusDetails.annuli)];

                    out=sweepnames(find(numValsPerParam>1));
                otherwise
                    error('unknown what');
            end
        end
        
        function [out s updateSM]=getLUT(s,bits);
            if isempty(s.LUT) || s.LUTbits~=bits
                updateSM=true;
                s.LUTbits=bits;
            %     s=fillLUT(s,'useThisMonitorsUncorrectedGamma');  %TEMP - don't commit
            %     s=fillLUT(s,'tempLinearRedundantCode');
                %s=fillLUT(s,'2009Trinitron255GrayBoxInterpBkgnd.5');
                %s=fillLUT(s,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5'); % March 2011 ViewSonic
            %     s=fillLUT(s,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5'); % May 2011 Westinghouse
                [a b] = getMACaddress;
                if ismember(b,{'7CD1C3E5176F',... balaji Macbook air
                        })
                    s=fillLUT(s,'tempLinearRedundantCode');
                else
                    s=fillLUT(s,'localCalibStore');
                end
            else
                updateSM=false;
            end
            out=s.LUT;
        end


        function out = getPhysAnalysisObject(sm,subject,tr,channels,dataPath,stim,c,mon,rigState)

            if ~exist('c','var')||isempty(c)
                c = struct([]);
            end
            out = grAnalysis(subject,tr,channels,dataPath,stim,c,mon,rigState);
        end
        
        function out = getRadiusType(stimulus)
            out = stimulus.radiusType;
        end
        
        function out = getType(sm,stim)
            sweptParameters = getDetails(sm,stim,'sweptParameters');
            n= length(sweptParameters);
            switch n
                case 1
                    % sweep of a single datatype
                    switch sweptParameters{1}
                        case 'spatialFrequencies'
                            out = 'sfGratings';
                        case 'driftfrequencies'
                            out = 'tfGrating';
                        case 'orientations'
                            out = 'orGratings';
                        case 'contrasts'
                            out = 'cntrGrating';
                        case 'radii'
                            out = 'radiiGratings';
                        case 'annuli'
                            out = 'annuliGratings';
                        otherwise
                            out = 'undefinedGratings';
                    end
                case 2        
                    if any(ismember(sweptParameters,'contrasts')) && ...
                                    any(ismember(sweptParameters,'radii'))
                                out = 'cntr-radGratings';
                    else
                        warning('only special analysis included');
                        out = 'unsupported';
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
                comboMatrix = generateFactorialCombo({stimulusDetails.spatialFrequencies,stimulusDetails.driftfrequencies,stimulusDetails.orientations,...
                    stimulusDetails.contrasts,stimulusDetails.phases,stimulusDetails.durations,stimulusDetails.radii,stimulusDetails.annuli},[],[],mode);
                pixPerCycs=comboMatrix(1,:);
                driftfrequencies=comboMatrix(2,:);
                orientations=comboMatrix(3,:);
                contrasts=comboMatrix(4,:); %starting phases in radians
                startPhases=comboMatrix(5,:);
                durations=round(comboMatrix(6,:)*parameters.refreshRate); % CONVERTED FROM seconds to frames
                radii=comboMatrix(7,:);
                annuli=comboMatrix(8,:);

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
                [length(unique(pixPerCycs)) length(unique(driftfrequencies))  length(unique(orientations))...
                length(unique(contrasts)) length(unique(startPhases)) length(unique(durations))...
                length(unique(radii))  length(unique(annuli))];

            %% find which parameters are swept
            names={'pixPerCycs','driftfrequencies','orientations','contrasts','startPhases',...
                'durations','radii','annuli'};

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
            % stimInfo.pixPerCycs = unique(pixPerCycs);
            % stimInfo.driftfrequencies = unique(driftfrequencies);
            % stimInfo.orientations = unique(orientations);
            % stimInfo.contrasts = unique(contrasts);
            % stimInfo.startPhases = unique(startPhases);
            % stimInfo.durations = unique(durations);
            % stimInfo.radii = unique(radii);
            % stimInfo.annuli = unique(annuli);
            % stimInfo.numRepeats = numRepeats;
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
            x = 2*pi./pixPerCycs(typesUnordered); % adjust phase for spatial frequency, using pixel=1 which is likely always offscreen, given roation and oversizeness
            cycsPerFrameVel = driftfrequencies(typesUnordered)*1/(parameters.refreshRate); % in units of cycles/frame
            offset = 2*pi*cycsPerFrameVel.*stimFrames';
            risingPhases=x+offset+startPhases(typesUnordered);
            phases=mod(risingPhases,2*pi); 
            phases = phases';

            % count the number of spikes per frame
            % spikeCount is a 1xn vector of (number of spikes per frame), where n = number of frames
            spikeCount=zeros(size(correctedFrameIndices,1),1);
            for i=1:length(spikeCount) % for each frame
                spikeCount(i)=length(find(spikes>=correctedFrameIndices(i,1)&spikes<=correctedFrameIndices(i,2))); % inclusive?  policy: include start & stop
            end
            switch numSweptParams
                case 1        
                    valsActual = valsSwept{1};
                    valsOrdered = sort(valsSwept{1});
                    types = nan(size(typesUnordered));
                    for i = 1:length(valsOrdered)
                        types(typesUnordered==i) = find(valsOrdered==valsActual(i));
                    end
                case 2
                    types = nan(size(typesUnordered));
                    numSwept1 = length(unique(valsSwept{1})); 
                    numSwept2 = length(unique(valsSwept{2}));
                    valsSwept1 = unique(valsSwept{1});
                    valsSwept2 = unique(valsSwept{2});

                    for i = 1:numSwept1
                        for j = 1:numSwept2
                            types(typesUnordered==((i-1)*numSwept2+j)) = find((valsSwept{1}==valsSwept1(i))&(valsSwept{2}==valsSwept2(j)));
                        end
                    end
                case 3
                    error('not yet supported')
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
            stimInfo.pixPerCycs = sort(unique(pixPerCycs));
            stimInfo.driftfrequencies = sort(unique(driftfrequencies));
            stimInfo.orientations = sort(unique(orientations));
            stimInfo.contrasts = sort(unique(contrasts));
            stimInfo.startPhases = sort(unique(startPhases));
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

        function [analysisdata cumulativedata] = physAnalysisDev(stimManager,spikeRecord,stimulusDetails,plotParameters,parameters,cumulativedata,eyeData,LFPRecord)

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
                comboMatrix = generateFactorialCombo({stimulusDetails.spatialFrequencies,stimulusDetails.driftfrequencies,stimulusDetails.orientations,...
                    stimulusDetails.contrasts,stimulusDetails.phases,stimulusDetails.durations,stimulusDetails.radii,stimulusDetails.annuli},[],[],mode);
                pixPerCycs=comboMatrix(1,:);
                driftfrequencies=comboMatrix(2,:);
                orientations=comboMatrix(3,:);
                contrasts=comboMatrix(4,:); %starting phases in radians
                startPhases=comboMatrix(5,:);
                durations=round(comboMatrix(6,:)*parameters.refreshRate); % CONVERTED FROM seconds to frames
                radii=comboMatrix(7,:);
                annuli=comboMatrix(8,:);

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
                [length(unique(pixPerCycs)) length(unique(driftfrequencies))  length(unique(orientations))...
                length(unique(contrasts)) length(unique(startPhases)) length(unique(durations))...
                length(unique(radii))  length(unique(annuli))];

            %% find which parameters are swept
            names={'pixPerCycs','driftfrequencies','orientations','contrasts','startPhases',...
                'durations','radii','annuli'};

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
            % stimInfo.pixPerCycs = unique(pixPerCycs);
            % stimInfo.driftfrequencies = unique(driftfrequencies);
            % stimInfo.orientations = unique(orientations);
            % stimInfo.contrasts = unique(contrasts);
            % stimInfo.startPhases = unique(startPhases);
            % stimInfo.durations = unique(durations);
            % stimInfo.radii = unique(radii);
            % stimInfo.annuli = unique(annuli);
            % stimInfo.numRepeats = numRepeats;
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
            x = 2*pi./pixPerCycs(typesUnordered); % adjust phase for spatial frequency, using pixel=1 which is likely always offscreen, given roation and oversizeness
            cycsPerFrameVel = driftfrequencies(typesUnordered)*1/(parameters.refreshRate); % in units of cycles/frame
            offset = 2*pi*cycsPerFrameVel.*stimFrames';
            risingPhases=x+offset+startPhases(typesUnordered);
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
            stimInfo.pixPerCycs = sort(unique(pixPerCycs));
            stimInfo.driftfrequencies = sort(unique(driftfrequencies));
            stimInfo.orientations = sort(unique(orientations));
            stimInfo.contrasts = sort(unique(contrasts));
            stimInfo.startPhases = sort(unique(startPhases));
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
                    case 'goNoGo'
                        out=1;
                    otherwise
                        out=0;
                end
            else
                error('need a trialManager object')
            end
        end
        
        function retval = worthPhysAnalysis(sm,quality,analysisExists,overwriteAll,isLastChunkInTrial)
            % returns true if worth spike sorting given the values in the quality struct
            % default method for all stims - can be overriden for specific stims
            %
            % quality.passedQualityTest (from analysisManager's getFrameTimes)
            % quality.frameIndices
            % quality.frameTimes
            % quality.frameLengths (this was used by getFrameTimes to calculate passedQualityTest)

            %retval=quality.passedQualityTest;


            % keyboard
            if length(quality.passedQualityTest)>1
                %if many chunks, the last one might have no frames or spikes, but the
                %analysis should still complete if the the previous chunks are all
                %good. to be very thourough, a stim manager may wish to confirm that
                %the reason for last chunk failing, if it did, is an acceptable reason.
                qualityOK=all(quality.passedQualityTest(1:end-1));
                warning('setting qualityOK to true here');
                qualityOK = true;
            else
                qualityOK=quality.passedQualityTest;
            end

            retval=qualityOK && ...
                (isLastChunkInTrial || enableChunkedPhysAnalysis(sm)) &&...    
                (overwriteAll || ~analysisExists);
        end % end function


        
        
    end
    
end


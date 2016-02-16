classdef afcGratingsWithOrientedSurround

    properties
        pixPerCycsCenter = [];
        pixPerCycsSurround = [];
        driftfrequenciesCenter = [];
        driftfrequenciesSurround = [];
        orientationsCenter = [];
        orientationsSurround = [];
        phasesCenter = [];
        phasesSurround = [];
        contrastsCenter = [];
        contrastsSurround = [];

        maxDuration = [];

        radiiCenter = [];
        radiiSurround = [];
        radiusType = 'gaussian';
        location = [];
        waveform='square'; 
        normalizationMethod='normalizeDiagonal';
        mean = 0;
        thresh = 0;

        LUT =[];
        LUTbits=0;

        doCombos=true;
        doPostDiscrim = false; 

        LEDParams;
        
    end
    
    methods
        function s=afcGratingsWithOrientedSurround(varargin)
            % AFCGRATINGSWITHORIENTEDSURROUND  class constructor.
            % 
            % s = afcGratingsWithOrientedSurround({pixPerCycsCenter,pixPerCycsSurround},{driftfrequenciesCenter,driftfrequenciesSurround},{orientationsCenter,orientationsSurround},...
            %       {phasesCenter,phasesSurround},{contrastsCenter,contrastsSurround},maxDuration,radii,location,
            %       waveformCenter,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            % Each of the following arguments is a {[],[]} cell, each element is a
            % vector of size N

            % pixPerCycs -
            % pix/Cycle {{centerLeft,centerRight},{surroundLeft,surroundRight}}
            % driftfrequency - cyc/s {{centerLeft,centerRight},{surroundLeft,surroundRight}}
            % orientations - in radians {{centerLeft,centerRight},{surroundLeft,surroundRight}}
            % phases - in radians {{centerLeft,centerRight},{surroundLeft,surroundRight}}
            % contrasts - [0,1] {{centerLeft,centerRight},{surroundLeft,surroundRight}}
            % maxDuration - in seconds (can only be one number)
            % radii - normalized diagonal units
            % annuli - normalized diagonal units
            % location - belongs to [0,1]
            %           OR: a RFestimator object that will get an estimated location when needed
            % waveform - 'square', 'sine', or 'none'
            % normalizationMethod - 'normalizeDiagonal', 'normalizeHorizontal', 'normalizeVertical', or 'none'
            % mean - 0<=m<=1
            % thresh - >0
            % doCombos

            s.LEDParams.active = false;
            s.LEDParams.numLEDs = 0;
            s.LEDParams.IlluminationModes = {};

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s = class(s,'afcGratingsWithOrientedSurround',stimManager());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'afcGratingsWithOrientedSurround'))
                        s = varargin{1};
                    else
                        error('Input argument is not a gratings object')
                    end
                case {17 18 19 20}
                    % create object using specified values
                    pixPerCycs = varargin{1};
                    driftfrequencies = varargin{2};
                    orientations = varargin{3};
                    phases = varargin{4};
                    contrasts = varargin{5};

                    maxDuration = varargin{6};
                    radii = varargin{7};
                    radiusType = varargin{8};
                    location = varargin{9};
                    waveform = varargin{10};
                    normalizationMethod = varargin{11};
                    mean = varargin{12};
                    thresh = varargin{13};
                    maxWidth = varargin{14};
                    maxHeight = varargin{15};
                    scaleFactor = varargin{16};
                    interTrialLuminance = varargin{17};
                    doCombos = varargin{18};
                    doPostDiscrim = false;
                    if(nargin==19)
                        doPostDiscrim=varargin{19};
                    end

                    % pixPerCycs
                    if islogical(doCombos)
                        s.doCombos = doCombos;
                    else
                        doCombos
                        error('doCombos not in the right format');
                    end

                    % pixPerCycs
                    if iscell(pixPerCycs) && length(pixPerCycs)==2 && ...
                            iscell(pixPerCycs{1}) && iscell(pixPerCycs{2}) && length(pixPerCycs{1}) == 2 && length(pixPerCycs{2}) == 2 && ...
                            isnumeric(pixPerCycs{1}{1}) && all(pixPerCycs{1}{1}>0) && isnumeric(pixPerCycs{1}{2}) && all(pixPerCycs{1}{2}>0) && ...
                            isnumeric(pixPerCycs{2}{1}) && all(pixPerCycs{2}{1}>0) && isnumeric(pixPerCycs{2}{2}) && all(pixPerCycs{2}{2}>0)
                        s.pixPerCycsCenter = pixPerCycs{1};
                        s.pixPerCycsSurround = pixPerCycs{2};
                        L11 = length(pixPerCycs{1}{1});
                        L12 = length(pixPerCycs{1}{2});
                        L21 = length(pixPerCycs{2}{1});
                        L22 = length(pixPerCycs{2}{2});
                        if ~doCombos && (L11~=L21 ||L12~=L22)
                            error('cannot not doCombos and not have the same number of center and surround lengths');
                        end
                    else
                        pixPerCycs
                        error('pixPerCycs not in the right format');
                    end

                    % driftfrequencies
                    if iscell(driftfrequencies) && length(driftfrequencies)==2 && ...
                            iscell(driftfrequencies{1}) && iscell(driftfrequencies{2}) && length(driftfrequencies{1}) == 2 && length(driftfrequencies{2}) == 2 && ...
                            isnumeric(driftfrequencies{1}{1}) && all(driftfrequencies{1}{1}>=0) && isnumeric(driftfrequencies{1}{2}) && all(driftfrequencies{1}{2}>=0) && ...
                            isnumeric(driftfrequencies{2}{1}) && all(driftfrequencies{2}{1}>=0) && isnumeric(driftfrequencies{2}{2}) && all(driftfrequencies{2}{2}>=0)
                        s.driftfrequenciesCenter = driftfrequencies{1};
                        s.driftfrequenciesSurround = driftfrequencies{2};
                        if ~doCombos && length(driftfrequencies{1}{1})~=L11 && length(driftfrequencies{1}{2})~=L12 && length(driftfrequencies{2}{1})~=L21 && length(driftfrequencies{2}{2})~=L22
                            error('the lengths don''t match. ')
                        end
                    else
                        driftfrequencies
                        error('driftfrequencies not in the right format');
                    end

                    % orientations
                    if iscell(orientations) && length(orientations)==2 && ...
                            iscell(orientations{1}) && iscell(orientations{2}) && length(orientations{1}) == 2 && length(orientations{2}) == 2 && ...
                            isnumeric(orientations{1}{1}) && isnumeric(orientations{1}{2}) && ...
                            isnumeric(orientations{2}{1}) && isnumeric(orientations{2}{2})
                        s.orientationsCenter = orientations{1};
                        s.orientationsSurround = orientations{2};
                        if ~doCombos && length(orientations{1}{1})~=L11 && length(orientations{1}{2})~=L12 && length(orientations{2}{1})~=L21 && length(orientations{2}{2})~=L22
                            error('the lengths don''t match. ')
                        end
                    else
                        orientations
                        error('orientations not in the right format');
                    end

                    % phases
                    if iscell(phases) && length(phases)==2 && ...
                            iscell(phases{1}) && iscell(phases{2}) && length(phases{1}) == 2 && length(phases{2}) == 2 && ...
                            isnumeric(phases{1}{1}) && isnumeric(phases{1}{2}) && ...
                            isnumeric(phases{2}{1}) && isnumeric(phases{2}{2})
                        s.phasesCenter = phases{1};
                        s.phasesSurround = phases{2};
                        if ~doCombos && length(phases{1}{1})~=L11 && length(phases{1}{2})~=L12 && length(phases{2}{1})~=L21 && length(phases{2}{2})~=L22
                            error('the lengths don''t match. ')
                        end
                    else
                        phases
                        error('phases not in the right format');
                    end

                    % contrasts
                    if iscell(contrasts) && length(contrasts)==2 && ...
                            iscell(contrasts{1}) && iscell(contrasts{2}) && length(contrasts{1}) == 2 && length(contrasts{2}) == 2 && ...
                            isnumeric(contrasts{1}{1}) && all(contrasts{1}{1}>=0) && isnumeric(contrasts{1}{2}) && all(contrasts{1}{2}>=0) && ...
                            isnumeric(contrasts{2}{1}) && all(contrasts{2}{1}>=0) && isnumeric(contrasts{2}{2}) && all(contrasts{2}{2}>=0)
                        s.contrastsCenter = contrasts{1};
                        s.contrastsSurround = contrasts{2};
                        if ~doCombos && length(contrasts{1}{1})~=L11 && length(contrasts{1}{2})~=L12 && length(contrasts{2}{1})~=L21 && length(contrasts{2}{2})~=L22
                            error('the lengths don''t match. ')
                        end
                    else
                        contrasts
                        error('contrasts not in the right format');
                    end

                    % maxDuration
                    if iscell(maxDuration) && length(maxDuration)==2 && ...
                            isnumeric(maxDuration{1}) && all(maxDuration{1}>0) && isnumeric(maxDuration{2}) && all(maxDuration{2}>0)
                        s.maxDuration = maxDuration;
                        if ~doCombos && length(maxDuration{1})~=L11 && length(maxDuration{2})~=L22
                            error('the lengths don''t match. ')
                        end
                    else
                        maxDuration
                        error('maxDuration not in the right format');
                    end

                    % radii
                    if iscell(radii) && length(radii)==2 && ...
                            iscell(radii{1}) && iscell(radii{2}) && length(radii{1}) == 2 && length(radii{2}) == 2 && ...
                            isnumeric(radii{1}{1}) && all(radii{1}{1}>=0) && isnumeric(radii{1}{2}) && all(radii{1}{2}>=0) && ...
                            isnumeric(radii{2}{1}) && all(radii{2}{1}>=0) && isnumeric(radii{2}{2}) && all(radii{2}{2}>=0)
                        s.radiiCenter = radii{1};
                        s.radiiSurround = radii{2};
                        if ~doCombos && length(radii{1}{1})~=L11 && length(radii{1}{2})~=L12 && length(radii{2}{1})~=L21 && length(radii{2}{2})~=L22
                            error('the lengths don''t match. ')
                        elseif doCombos && (max(radii{1}{1})>min(radii{2}{1}) ||max(radii{1}{2})>min(radii{2}{2}))
                            error('cannot choose a combo with center radii larger than surround if doCombos is true');
                        end
                    else
                        radii
                        error('radii not in the right format');
                    end


                    % radiusType
                    if ischar(radiusType) && ismember(radiusType,{'gaussian','hardEdge'})
                        s.radiusType = radiusType;
                    else
                        radiusType
                        error('radiusType not in the right format');
                    end


                    % location
                    if iscell(location) && length(location)==2 && ...
                            isnumeric(location{1}) && all(location{1}>=0) && size(location{1},2)==2 && ...
                            isnumeric(location{2}) && all(location{2}>=0) && size(location{2},2)==2                
                        s.location = location;
                        if ~doCombos && length(location{1})~=L1 && length(location{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        location
                        error('location not in the right format');
                    end

                    % waveform
                    if ischar(waveform) && ismember(waveform,{'sine','square'})
                        s.waveform = waveform;
                    else
                        waveform
                        error('waveform not the right format');
                    end

                    % normalizationMethod
                    if ischar(normalizationMethod) && ismember(normalizationMethod,{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'})
                        s.normalizationMethod = normalizationMethod;
                    else
                        normalizationMethod
                        error('normalizationMethod not the right format');
                    end

                    % mean
                    if mean>=0 && mean<=1
                        s.mean = mean;
                    else
                        mean
                        error('mean not the right format');
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

                    if nargin>19
                        % LED state
                        if isstruct(varargin{20})
                            s.LEDParams = varargin{20};
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

                    s = class(s,'afcGratingsWithOrientedSurround',stimManager(maxWidth,maxHeight,scaleFactor,interTrialLuminance));
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
            trialManagerClass = class(trialManager);
            % 1/30/09 - trialRecords now includes THIS trial
            indexPulses=[];
            imagingTasks=[];
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
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);


            toggleStim=true; type='expert';
            dynamicMode = true; %false %true

            % set up params for computeGabors
            height = min(height,getMaxHeight(stimulus));
            width = min(width,getMaxWidth(stimulus));

            % lets save some of the details for later
            possibleStims.pixPerCycsCenter          = stimulus.pixPerCycsCenter;
            possibleStims.pixPerCycsSurround        = stimulus.pixPerCycsSurround;

            possibleStims.driftfrequenciesCenter    = stimulus.driftfrequenciesCenter;
            possibleStims.driftfrequenciesSurround  = stimulus.driftfrequenciesSurround;

            possibleStims.orientationsCenter        = stimulus.orientationsCenter;
            possibleStims.orientationsSurround      = stimulus.orientationsSurround;

            possibleStims.phasesCenter              = stimulus.phasesCenter;
            possibleStims.phasesSurround            = stimulus.phasesSurround;

            possibleStims.contrastsCenter           = stimulus.contrastsCenter;
            possibleStims.contrastsSurround         = stimulus.contrastsSurround;

            possibleStims.waveform                  = stimulus.waveform;
            possibleStims.maxDuration               = {stimulus.maxDuration{1}*hz,stimulus.maxDuration{2}*hz};

            possibleStims.radiiCenter               = stimulus.radiiCenter;
            possibleStims.radiiSurround             = stimulus.radiiSurround;

            possibleStims.radiusType                = stimulus.radiusType;
            possibleStims.location                  = stimulus.location;
            possibleStims.normalizationMethod       = stimulus.normalizationMethod;
            possibleStims.mean                      = stimulus.mean;
            possibleStims.thresh                    = stimulus.thresh;
            possibleStims.width                     = width;
            possibleStims.height                    = height;
            possibleStims.doCombos                  = stimulus.doCombos;
            details.possibleStims                   = possibleStims;
            details.afcGratingType                  = getType(stimulus,structize(stimulus));

            % whats the chosen stim?
            if stimulus.doCombos
                % choose a random value for each
                if length(targetPorts)==1
                    stim = [];
                    if targetPorts == 1 % the first of the possible values
                        % pixPerCycsCenter
                        tempVar = randperm(length(stimulus.pixPerCycsCenter{1}));
                        stim.pixPerCycsCenter = stimulus.pixPerCycsCenter{1}(tempVar(1));

                        % pixPerCycsSurround
                        tempVar = randperm(length(stimulus.pixPerCycsSurround{1}));
                        stim.pixPerCycsSurround = stimulus.pixPerCycsSurround{1}(tempVar(1));

                        % driftfrequenciesCenter
                        tempVar = randperm(length(stimulus.driftfrequenciesCenter{1}));
                        stim.driftfrequenciesCenter = stimulus.driftfrequenciesCenter{1}(tempVar(1));

                        % driftfrequenciesSurround
                        tempVar = randperm(length(stimulus.driftfrequenciesSurround{1}));
                        stim.driftfrequenciesSurround = stimulus.driftfrequenciesSurround{1}(tempVar(1));

                        % orientationsCenter
                        tempVar = randperm(length(stimulus.orientationsCenter{1}));
                        stim.orientationsCenter = stimulus.orientationsCenter{1}(tempVar(1));

                        % orientationsSurround
                        tempVar = randperm(length(stimulus.orientationsSurround{1}));
                        stim.orientationsSurround = stimulus.orientationsSurround{1}(tempVar(1));

                        % phasesCenter
                        tempVar = randperm(length(stimulus.phasesCenter{1}));
                        stim.phasesCenter = stimulus.phasesCenter{1}(tempVar(1));

                        % phasesSurround
                        tempVar = randperm(length(stimulus.phasesSurround{1}));
                        stim.phasesSurround = stimulus.phasesSurround{1}(tempVar(1));

                        % contrastsCenter
                        tempVar = randperm(length(stimulus.contrastsCenter{1}));
                        stim.contrastsCenter = stimulus.contrastsCenter{1}(tempVar(1));

                        % contrastsSurround
                        tempVar = randperm(length(stimulus.contrastsSurround{1}));
                        stim.contrastsSurround = stimulus.contrastsSurround{1}(tempVar(1));

                        % waveform
                        stim.waveform = stimulus.waveform;

                        % maxDuration
                        tempVar = randperm(length(stimulus.maxDuration{1}));
                        if ~ismac
                            stim.maxDuration = stimulus.maxDuration{1}(tempVar(1))*hz;
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = stimulus.maxDuration{1}(tempVar(1))*60;
                        end

                        % radiiCenter
                        tempVar = randperm(length(stimulus.radiiCenter{1}));
                        stim.radiiCenter = stimulus.radiiCenter{1}(tempVar(1));

                        % radiiSurround
                        tempVar = randperm(length(stimulus.radiiSurround{1}));
                        stim.radiiSurround = stimulus.radiiSurround{1}(tempVar(1));

                        % location
                        tempVar = randperm(size(stimulus.location{1},1));
                        stim.location = stimulus.location{1}(tempVar(1),:);
                    elseif targetPorts == 3% the second of the possible values
                        % pixPerCycsCenter
                        tempVar = randperm(length(stimulus.pixPerCycsCenter{2}));
                        stim.pixPerCycsCenter = stimulus.pixPerCycsCenter{2}(tempVar(1));

                        % pixPerCycsSurround
                        tempVar = randperm(length(stimulus.pixPerCycsSurround{2}));
                        stim.pixPerCycsSurround = stimulus.pixPerCycsSurround{2}(tempVar(1));

                        % driftfrequenciesCenter
                        tempVar = randperm(length(stimulus.driftfrequenciesCenter{2}));
                        stim.driftfrequenciesCenter = stimulus.driftfrequenciesCenter{2}(tempVar(1));

                        % driftfrequenciesSurround
                        tempVar = randperm(length(stimulus.driftfrequenciesSurround{2}));
                        stim.driftfrequenciesSurround = stimulus.driftfrequenciesSurround{2}(tempVar(1));

                        % orientationsCenter
                        tempVar = randperm(length(stimulus.orientationsCenter{2}));
                        stim.orientationsCenter = stimulus.orientationsCenter{2}(tempVar(1));

                        % orientationsSurround
                        tempVar = randperm(length(stimulus.orientationsSurround{2}));
                        stim.orientationsSurround = stimulus.orientationsSurround{2}(tempVar(1));

                        % phasesCenter
                        tempVar = randperm(length(stimulus.phasesCenter{2}));
                        stim.phasesCenter = stimulus.phasesCenter{2}(tempVar(1));

                        % phasesSurround
                        tempVar = randperm(length(stimulus.phasesSurround{2}));
                        stim.phasesSurround = stimulus.phasesSurround{2}(tempVar(1));

                        % contrastsCenter
                        tempVar = randperm(length(stimulus.contrastsCenter{2}));
                        stim.contrastsCenter = stimulus.contrastsCenter{2}(tempVar(1));

                        % contrastsSurround
                        tempVar = randperm(length(stimulus.contrastsSurround{2}));
                        stim.contrastsSurround = stimulus.contrastsSurround{2}(tempVar(1));

                        % waveform
                        stim.waveform = stimulus.waveform;

                        % maxDuration
                        tempVar = randperm(length(stimulus.maxDuration{2}));
                        if ~ismac
                            stim.maxDuration = stimulus.maxDuration{2}(tempVar(1))*hz;
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = stimulus.maxDuration{2}(tempVar(1))*60;
                        end

                        % radiiCenter
                        tempVar = randperm(length(stimulus.radiiCenter{2}));
                        stim.radiiCenter = stimulus.radiiCenter{2}(tempVar(1));

                        % radiiSurround
                        tempVar = randperm(length(stimulus.radiiSurround{2}));
                        stim.radiiSurround = stimulus.radiiSurround{2}(tempVar(1));

                        % location
                        tempVar = randperm(size(stimulus.location{2},1));
                        stim.location = stimulus.location{2}(tempVar(1),:);
                    else 
                        error('eh? should not come here at all')
                    end
                else
                    error('not geared for more than one target port. whats wrong??');
                end
            else
                if length(targetPorts)==1
                    if targetPorts == 1
                        tempVar = randperm(length(stimulus.pixPerCycs{1}));
                        which = tempVar(1);            
                        stim.pixPerCycsCenter=stimulus.pixPerCycsCenter{1}(which);
                        stim.pixPerCycsSurround=stimulus.pixPerCycsSurround{1}(which);
                        stim.driftfrequenciesCenter=stimulus.driftfrequenciesCenter{1}(which);
                        stim.driftfrequenciesSurround=stimulus.driftfrequenciesSurround{1}(which);
                        stim.orientationsCenter=stimulus.orientationsCenter{1}(which);
                        stim.orientationsSurround=stimulus.orientationsSurround{1}(which);
                        stim.phasesCenter=stimulus.phasesCenter{1}(which);
                        stim.phasesSurround=stimulus.phasesSurround{1}(which);
                        stim.contrastsCenter=stimulus.contrastsCenter{1}(which);
                        stim.contrastsSurround=stimulus.contrastsSurround{1}(which);
                        stim.waveform=stimulus.waveform;
                        if ~ismac
                            stim.maxDuration=stimulus.maxDuration{1}(which)*hz;
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = stimulus.maxDuration{1}(which)*60;
                        end
                        stim.radiiCenter=stimulus.radiiCenter{1}(which);
                        stim.radiiSurround=stimulus.radiiSurround{1}(which);
                        stim.annuli=stimulus.annuli{1}(which);
                        stim.location=stimulus.location{1}(which,:);
                    elseif targetPorts == 3
                        tempVar = randperm(length(stimulus.pixPerCycs{2}));
                        which = tempVar(1);            
                        stim.pixPerCycsCenter=stimulus.pixPerCycsCenter{2}(which);
                        stim.pixPerCycsSurround=stimulus.pixPerCycsSurround{2}(which);
                        stim.driftfrequenciesCenter=stimulus.driftfrequenciesCenter{2}(which);
                        stim.driftfrequenciesSurround=stimulus.driftfrequenciesSurround{2}(which);
                        stim.orientationsCenter=stimulus.orientationsCenter{2}(which);
                        stim.orientationsSurround=stimulus.orientationsSurround{2}(which);
                        stim.phasesCenter=stimulus.phasesCenter{2}(which);
                        stim.phasesSurround=stimulus.phasesSurround{2}(which);
                        stim.contrastsCenter=stimulus.contrastsCenter{2}(which);
                        stim.contrastsSurround=stimulus.contrastsSurround{2}(which);
                        stim.waveform=stimulus.waveform;
                        if ~ismac
                            stim.maxDuration=stimulus.maxDuration{2}(which)*hz;
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = stimulus.maxDuration{2}(which)*60;
                        end
                        stim.radiiCenter=stimulus.radiiCenter{2}(which);
                        stim.radiiSurround=stimulus.radiiSurround{2}(which);
                        stim.annuli=stimulus.annuli{2}(which);
                        stim.location=stimulus.location{2}(which,:);
                    else
                        error('eh? should not come here at all')
                    end
                else
                    error('not geared for more than one target port. whats wrong??');
                end
            end
            % normalizationMethod,mean,thresh,height,width,scaleFactor,interTrialLuminance
            stim.radiusType = stimulus.radiusType;
            stim.normalizationMethod=stimulus.normalizationMethod;
            stim.height=height;
            stim.width=width;
            stim.mean=stimulus.mean;
            stim.thresh=stimulus.thresh;
            stim.doCombos=stimulus.doCombos;
            details.chosenStim = stim;

            % have a version in ''details''
            details.doCombos                        = stimulus.doCombos;

            details.pixPerCycsCenter                = stim.pixPerCycsCenter;
            details.driftfrequenciesCenter          = stim.driftfrequenciesCenter;
            details.orientationsCenter              = stim.orientationsCenter;
            details.phasesCenter                    = stim.phasesCenter;
            details.contrastsCenter                 = stim.contrastsCenter;
            details.radiiCenter                     = stim.radiiCenter;

            details.pixPerCycsSurround              = stim.pixPerCycsSurround;
            details.driftfrequenciesSurround        = stim.driftfrequenciesSurround;
            details.orientationsSurround            = stim.orientationsSurround;
            details.phasesSurround                  = stim.phasesSurround;
            details.contrastsSurround               = stim.contrastsSurround;
            details.radiiSurround                   = stim.radiiSurround;

            details.maxDuration                   = stim.maxDuration;
            details.waveform                      = stim.waveform;

            % radiiCenter
            if stim.radiiCenter==Inf
                sca;
                error('center cannot have infinite radius');
            else
                mask=[];
                maskParams=[stim.radiiCenter 999 0 0 ...
                    1.0 stim.thresh stim.location(1) stim.location(2)]; %11/12/08 - for some reason mask contrast must be 2.0 to get correct result

                switch details.chosenStim.radiusType
                    case 'gaussian'
                            mask(:,:,1)=ones(height,width,1)*stim.mean;
                            mask(:,:,2)=computeGabors(maskParams,0,width,height,...
                                'none', stim.normalizationMethod,0,0);
                            % necessary to make use of PTB alpha blending: 1 -
                            mask(:,:,2) = 1 - mask(:,:,2); % 0 = transparent, 255=opaque (opposite of our mask)
                            stim.centerMask{1}=mask;
                    case 'hardEdge'
                            mask(:,:,1)=ones(height,width,1)*stimulus.mean;
                            [WIDTH HEIGHT] = meshgrid(1:width,1:height);
                            mask(:,:,2)=double((((WIDTH-width*details.chosenStim.location(1)).^2)+((HEIGHT-height*details.chosenStim.location(2)).^2)-((stim.radiiCenter)^2*(height^2)))>0);
                            stim.centerMask{1}=mask;
                end    
                stim.centerSize = 2*stim.radiiCenter*height;
            end
            details.centerMask = stim.centerMask;
            details.centerSize = stim.centerSize;
            % radiiSurround
            if stim.radiiSurround==Inf
                stim.surroundMask = [];
            else
                mask=[];
                maskParams=[stim.radiiSurround 999 0 0 ...
                    1.0 stim.thresh stim.location(1) stim.location(2)]; %11/12/08 - for some reason mask contrast must be 2.0 to get correct result

                switch details.chosenStim.radiusType
                    case 'gaussian'
                            mask(:,:,1)=ones(height,width,1)*stim.mean;
                            mask(:,:,2)=computeGabors(maskParams,0,width,height,...
                                'none', stim.normalizationMethod,0,0);
                            % necessary to make use of PTB alpha blending: 1 -
                            mask(:,:,2) = 1 - mask(:,:,2); % 0 = transparent, 255=opaque (opposite of our mask)
                            stim.surroundMask{1}=mask;
                    case 'hardEdge'
                            mask(:,:,1)=ones(height,width,1)*stimulus.mean;
                            [WIDTH HEIGHT] = meshgrid(1:width,1:height);
                            mask(:,:,2)=double((((WIDTH-width*details.chosenStim.location(1)).^2)+((HEIGHT-height*details.chosenStim.location(2)).^2)-((stim.radiiSurround)^2*(height^2)))>0);
                            stim.surroundMask{1}=mask;
                end    
            end
            details.surroundMask = stim.surroundMask;


            if isinf(stim.maxDuration)
                timeout=[];
            else
                timeout=stim.maxDuration;
            end

            [details, stim] = setupLED(details, stim, stimulus.LEDParams,arduinoCONN);

            discrimStim=[];
            discrimStim.stimulus=stim;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            if isnan(timeout)
                sca;
                keyboard;
            end
            discrimStim.framesUntilTimeout=timeout;

            preRequestStim=[];
            preRequestStim.stimulus=interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;

            preResponseStim = [];

            if stimulus.doPostDiscrim
                postDiscrimStim = preRequestStim;
            else
                postDiscrimStim = [];
            end

            interTrialStim.duration = interTrialDuration;

            details.interTrialDuration = interTrialDuration;
            details.stimManagerClass = class(stimulus);
            details.trialManagerClass = trialManagerClass;
            details.scaleFactor = scaleFactor;

            if strcmp(trialManagerClass,'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('thresh: %g',stimulus.thresh);
            end
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

            doFramePulse=true;
            indexPulse = false;


            % expertCache should contain masktexs and annulitexs
            if isempty(expertCache)
                expertCache.masktexs=[];
                expertCache.annulitexs=[];
            end

            black=0.0;
            white=1.0;
            gray = (white-black)/2;

            %stim.velocities is in cycles per second
            cycsPerFrameVelCenter = stim.driftfrequenciesCenter*ifi; % in units of cycles/frame
            cycsPerFrameVelSurround = stim.driftfrequenciesSurround*ifi; % in units of cycles/frame
            offsetCenter = 2*pi*cycsPerFrameVelCenter*i;
            offsetSurround = 2*pi*cycsPerFrameVelSurround*i;

            % Create a 1D vector x based on the frequency pixPerCycs
            % make the grating twice the normal width (to cover entire screen if rotated)
            xCenter = (1:stim.width*2)*2*pi/stim.pixPerCycsCenter;
            xSurround = (1:stim.width*2)*2*pi/stim.pixPerCycsSurround;
            switch stim.waveform
                case 'sine'
                    gratingCenter=stim.contrastsCenter*cos(xCenter + offsetCenter+stim.phasesCenter)/2+stimulus.mean; 
                    gratingSurround=stim.contrastsSurround*cos(xSurround + offsetSurround+stim.phasesSurround)/2+stimulus.mean; 
                case 'square'
                    gratingCenter=stim.contrastsCenter*square(xCenter + offsetCenter+stim.phasesCenter)/2+stimulus.mean;
                    gratingSurround=stim.contrastsSurround*square(xSurround + offsetSurround+stim.phasesSurround)/2+stimulus.mean;
            end
            % Make grating texture
            gratingtexCenter=Screen('MakeTexture',window,gratingCenter,0,0,floatprecision);
            gratingtexSurround=Screen('MakeTexture',window,gratingSurround,0,0,floatprecision);

            % set srcRect
            srcRectCenter=[0 0 size(gratingCenter,2) 1];
            srcRectSurround=[0 0 size(gratingSurround,2) 1];

            % Draw grating texture, rotated by "angle" for surround:
            destWidth = destRect(3)-destRect(1);
            destHeight = destRect(4)-destRect(2);
            destRectForGratingSurround = [destRect(1)-destWidth/2, destRect(2)-destHeight, destRect(3)+destWidth/2,destRect(4)+destHeight];
            Screen('DrawTexture', window, gratingtexSurround, srcRectSurround, destRectForGratingSurround,(180/pi)*stim.orientationsSurround, filtMode);
            try
                if ~isempty(stim.surroundMask)
                    % Draw gaussian mask over grating: We need to subtract 0.5 from
                    % the real size to avoid interpolation artifacts that are
                    % created by the gfx-hardware due to internal numerical
                    % roundoff errors when drawing rotated images:
                    % Make mask to texture
                    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % necessary to do the transparency blending
                    if isempty(expertCache.masktexs)
                        expertCache.masktexs= Screen('MakeTexture',window,double(stim.surroundMask{1}),0,0,floatprecision);
                    end
                    % Draw mask texture: (with no rotation)
                    Screen('DrawTexture', window, expertCache.masktexs, [], destRect,[], filtMode);
                end
            catch
                sca;
                keyboard
            end
            dst2Rect = [0 0 stim.centerSize stim.centerSize];
            dst2Rect = CenterRect(dst2Rect,destRect);
            % Disable alpha-blending, restrict following drawing to alpha channel:
            Screen('Blendfunction', window, GL_ONE, GL_ZERO, [0 0 0 1]);

            % Clear 'dstRect' region of framebuffers alpha channel to zero:
            Screen('FillRect', window, [0 0 0 0], dst2Rect);

            % Fill circular 'dstRect' region with an alpha value of 255:
            Screen('FillOval', window, [0 0 0 255], dst2Rect);

            Screen('Blendfunction', window, GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA, [1 1 1 1]);

            % Draw 2nd grating texture, but only inside alpha == 255 circular
            % aperture, and at an angle of 90 degrees:
            Screen('DrawTexture', window, gratingtexCenter, [0 0 stim.centerSize stim.centerSize], dst2Rect, stim.orientationsCenter);

            % clear the gratingtex from vram
            Screen('Close',gratingtexCenter);
            Screen('Close',gratingtexSurround);
        end % end function
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;

            try
            %     stimDetails=[trialRecords.stimDetails];
                stimDetails(length(trialRecords)).correctionTrial = NaN;
                for i = 1:length(trialRecords)
                    if isstruct(trialRecords(i).stimDetails)
                        stimDetails(i).pctCorrectionTrials = trialRecords(i).stimDetails.pctCorrectionTrials;
                        stimDetails(i).correctionTrial = trialRecords(i).stimDetails.correctionTrial;
                        stimDetails(i).afcGratingType = trialRecords(i).stimDetails.afcGratingType;
                        stimDetails(i).doCombos = trialRecords(i).stimDetails.doCombos;
                        stimDetails(i).pixPerCycsCenter = trialRecords(i).stimDetails.pixPerCycsCenter;
                        stimDetails(i).driftfrequenciesCenter = trialRecords(i).stimDetails.driftfrequenciesCenter;
                        stimDetails(i).orientationsCenter = trialRecords(i).stimDetails.orientationsCenter;
                        stimDetails(i).phasesCenter = trialRecords(i).stimDetails.phasesCenter;
                        stimDetails(i).contrastsCenter = trialRecords(i).stimDetails.contrastsCenter;
                        stimDetails(i).radiiCenter = trialRecords(i).stimDetails.radiiCenter;
                        stimDetails(i).pixPerCycsSurround = trialRecords(i).stimDetails.pixPerCycsSurround;
                        stimDetails(i).driftfrequenciesSurround = trialRecords(i).stimDetails.driftfrequenciesSurround;
                        stimDetails(i).orientationsSurround = trialRecords(i).stimDetails.orientationsSurround;
                        stimDetails(i).phasesSurround = trialRecords(i).stimDetails.phasesSurround;
                        stimDetails(i).contrastsSurround = trialRecords(i).stimDetails.contrastsSurround;
                        stimDetails(i).radiiSurround = trialRecords(i).stimDetails.radiiSurround;
                        stimDetails(i).maxDuration = trialRecords(i).stimDetails.maxDuration;
                        stimDetails(i).waveform = trialRecords(i).stimDetails.waveform;
                        stimDetails(i).centerSize = trialRecords(i).stimDetails.centerSize;
                        stimDetails(i).surroundMask = trialRecords(i).stimDetails.surroundMask;
                        stimDetails(i).stimManagerClass = trialRecords(i).stimDetails.stimManagerClass;
                        stimDetails(i).trialManagerClass = trialRecords(i).stimDetails.trialManagerClass;
                        stimDetails(i).scaleFactor = trialRecords(i).stimDetails.scaleFactor;

                    else
                        stimDetails(i).pctCorrectionTrials = nan;
                        stimDetails(i).correctionTrial = nan;
                        stimDetails(i).afcGratingType = 'n/a';
                        stimDetails(i).doCombos = nan;
                        stimDetails(i).pixPerCycsCenter = nan;
                        stimDetails(i).driftfrequenciesCenter = nan;
                        stimDetails(i).orientationsCenter = nan;
                        stimDetails(i).phasesCenter = nan;
                        stimDetails(i).contrastsCenter = nan;
                        stimDetails(i).radiiCenter = nan;
                        stimDetails(i).pixPerCycsSurround = nan;
                        stimDetails(i).driftfrequenciesSurround = nan;
                        stimDetails(i).orientationsSurround = nan;
                        stimDetails(i).phasesSurround = nan;
                        stimDetails(i).contrastsSurround = nan;
                        stimDetails(i).radiiSurround = nan;
                        stimDetails(i).maxDuration = nan;
                        stimDetails(i).waveform = 'n/a';
                        stimDetails(i).centerSize = nan;
                        stimDetails(i).surroundMask = nan;
                        stimDetails(i).stimManagerClass = 'n/a';
                        stimDetails(i).trialManagerClass = 'n/a';
                        stimDetails(i).scaleFactor = nan;

                    end
                end
                [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.doCombos newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);

                [out.pixPerCycsCenter newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCycsCenter'},'scalar',newLUT);
                [out.driftfrequenciesCenter newLUT] = extractFieldAndEnsure(stimDetails,{'driftfrequenciesCenter'},'scalar',newLUT);
                [out.orientationsCenter newLUT] = extractFieldAndEnsure(stimDetails,{'orientationsCenter'},'scalar',newLUT);
                [out.phasesCenter newLUT] = extractFieldAndEnsure(stimDetails,{'phasesCenter'},'scalar',newLUT);
                [out.contrastsCenter newLUT] = extractFieldAndEnsure(stimDetails,{'contrastsCenter'},'scalar',newLUT);
                [out.radiiCenter newLUT] = extractFieldAndEnsure(stimDetails,{'radiiCenter'},'scalar',newLUT);

                [out.pixPerCycsSurround newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCycsSurround'},'scalar',newLUT);
                [out.driftfrequenciesSurround newLUT] = extractFieldAndEnsure(stimDetails,{'driftfrequenciesSurround'},'scalar',newLUT);
                [out.orientationsSurround newLUT] = extractFieldAndEnsure(stimDetails,{'orientationsSurround'},'scalar',newLUT);
                [out.phasesSurround newLUT] = extractFieldAndEnsure(stimDetails,{'phasesSurround'},'scalar',newLUT);
                [out.contrastsSurround newLUT] = extractFieldAndEnsure(stimDetails,{'contrastsSurround'},'scalar',newLUT);
                [out.radiiSurround newLUT] = extractFieldAndEnsure(stimDetails,{'radiiSurround'},'scalar',newLUT);


                [out.maxDuration newLUT] = extractFieldAndEnsure(stimDetails,{'maxDuration'},'scalar',newLUT);    
                [out.afcGratingType newLUT] = extractFieldAndEnsure(stimDetails,{'afcGratingType'},'scalarLUT',newLUT);

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
                    if stim.doCombos
                        if isfield(stim,'spatialFrequenciesCenter')
                            sweepnames={'spatialFrequenciesCenter','driftfrequenciesCenter','phasesCenter','contrastsCenter','radiiCenter','spatialFrequenciesSurround','driftfrequenciesSurround','phasesSurround','contrastsSurround','maxDuration','radiiSurround'};
                        elseif isfield(stim,'pixPerCycsCenter')
                            sweepnames={'pixPerCycsCenter','driftfrequenciesCenter','phasesCenter','contrastsCenter','radiiCenter','pixPerCycsSurround','driftfrequenciesSurround','phasesSurround','contrastsSurround','maxDuration','radiiSurround'};
                        end
                        which = [false false false false false false false];
                        for i = 1:length(sweepnames)
                            if length(stim.(sweepnames{i}){1})>1 || length(stim.(sweepnames{i}){2})>1
                                which(i) = true;
                            end
                        end
                        out=sweepnames(which);

                        warning('gonna assume same number of orientations for both ports? is that wise?')
                        if length(stim.orientationsSurround{1})==1 % gonna be intelligent and consider changes by pi to be identical orientations (but they are opposite directions)
                            % nothing there was no orientation sweep
                        elseif length(stim.orientationsSurround{1})==2
                            if diff(mod(stim.orientationsSurround{1},pi))<0.000001 && diff(mod(stim.orientationsSurround{2},pi))<0.000001%allowing for small changes during serialization
                                % they are the same
                            else
                                out{end+1} = 'orientationsSurround';
                            end
                        else
                            % then length >2 then automatically there is some sweep
                            out{end+1} = 'orientationsSurround';
                        end

                        if length(stim.orientationsCenter{1})==1 % gonna be intelligent and consider changes by pi to be identical orientations (but they are opposite directions)
                            % nothing there was no orientation sweep
                        elseif length(stim.orientationsCenter{1})==2
                            if diff(mod(stim.orientationsCenter{1},pi))<0.000001 && diff(mod(stim.orientationsCenter{2},pi))<0.000001%allowing for small changes during serialization
                                % they are the same
                            else
                                out{end+1} = 'orientationsCenter';
                            end
                        else
                            % then length >2 then automatically there is some sweep
                            out{end+1} = 'orientationsCenter';
                        end


                    else
                        error('unsupported');
                    end
                otherwise
                    error('unknown what');
            end
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
        
        function out = getType(sm,stim)
            sweptParameters = getDetails(sm,stim,'sweptParameters');
            n= length(sweptParameters);
            switch n
                case 0
                    out = 'afcGratings_noSweep';
                case 1
                    % sweep of a single datatype
                    switch sweptParameters{1}
                        case {'pixPerCycs','spatialFrequencies'}
                            out = 'afcGratings_sfSweep';
                        case 'driftfrequencies'
                            out = 'afcGratings_tfSweep';
                        case 'orientations'
                            out = 'afcGratings_orSweep';
                        case 'phases'
                            out = 'afcGratings_phaseSweep';
                        case 'contrasts'
                            out = 'afcGratings_cntrSweep';
                        case 'maxDuration'
                            out = 'afcGratings_durnSweep';
                        case 'radii'
                            out = 'afcGratings_radSweep';
                        case 'annuli'
                            out = 'afcGratings_annSweep';                
                        otherwise
                            out = 'undefinedGratings';
                    end
                case 2        
                    if all(ismember(sweptParameters,{'contrasts','radii'}))
                        out = 'afcGratings_cntrXradSweep';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                case 3
                    if all(ismember(sweptParameters,{'contrasts','pixPerCycs','driftFrequencies'}))
                        out = 'afcGratings_cntrXsfXtfSweep';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                case 4
                    if all(ismember(sweptParameters,{'contrasts','pixPerCycs','driftfrequencies','orientations'}))
                        out = 'afcGratings_cntrXsfXtfXorSweep';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                otherwise
                    error('unsupported type. if you want this make a name for it');
            end
        end
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case 'freeDrinks'
                        out=0;
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

        
        
    end
    
end


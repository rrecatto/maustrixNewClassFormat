classdef changeDetectorSM<stimManager
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stim1 = [];
        stim2 = [];
        durationToFlip = []; % Secs
        durationAfterFlip = []; % Secs
        LUT = [];
        LUTbits = [];
    end
    
    methods
        function s=changeDetectorSM(varargin)
            % CHANGEDETECTORSM  class constructor.
            % s = changeDetectorSM(stim1,stim2,durationToFlip,durationAfterFlip,maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            % changeDetectorSM stim is a combo stim that makes use of 2 separate stimuli.
            % It includes the discrimStim from stim1 and the discrimStim from stim2 as
            % the basis for the discrimination step.
            %
            % Responses during the first stim epoch is punished
            % 
            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'changeDetectorSM'))
                        s = varargin{1};
                    else
                        error('Input argument is not a changeDetectorSM object')
                    end
                case {8}
                    stim1 = varargin{1};
                    stim2 = varargin{2};
                    durationToFlip = varargin{3};
                    durationAfterFlip = varargin{4};
                    maxWidth = varargin{5};
                    maxHeight = varargin{6};
                    scaleFactor = varargin{7};
                    interTrialLuminance = varargin{8};

                    % error check
                    if isa(stim1,'stimManager')
                        s.stim1 = stim1;
                    else
                        class(stim1)
                        error('changeDetectorSM:wrongStimType','stim1 is of the wrong type');
                    end

                    if isa(stim2,'stimManager')
                        s.stim2 = stim2;
                    else
                        class(stim2)
                        error('changeDetectorSM:wrongStimType','stim2 is of the wrong type');
                    end

                    if isnumeric(durationToFlip)&&length(durationToFlip)==1
                        s.durationToFlip.type = 'delta';
                        s.durationToFlip.params = durationToFlip;
                    elseif isstruct(durationToFlip)
                        durationToFlip = validateDuration(durationToFlip);
                        s.durationToFlip = durationToFlip;
                    else
                        error('changeDetectorSM:wrongDurationType','durationToFlip should be a scalar or should a struct of appropriate type');
                    end

                    if isnumeric(durationAfterFlip)&&length(durationAfterFlip)==1
                        s.durationAfterFlip.type = 'delta';
                        s.durationAfterFlip.params = durationAfterFlip;
                    elseif isstruct(durationAfterFlip)
                        durationAfterFlip = validateDuration(durationAfterFlip);
                        s.durationAfterFlip = durationAfterFlip;
                    else
                        error('changeDetectorSM:wrongDurationType','durationAfterFlip should be a scalar or should a struct of appropriate type');
                    end

                    

                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
            end

            function out = validateDuration(in)
                if ~isstruct(in)
                    class(in)
                    error('assumes an struct input');
                end
                if ~isfield(in,'type') || ~ischar(in.type)
                    error('''in'' must contain a character type');
                end
                if ~isfield(in,'params')
                    error('''in'' needs a params');
                end

                out = [];

                switch in.type
                    case 'delta'
                        out.type = 'delta';
                        if ~isnumeric(in.params)&&length(in.params)==1
                            error('delta distribution assumes a scalar param')
                        end
                        out.params = in.params;

                    case 'uniform'
                        out.type = 'uniform';
                        if isvector(in.params) && isnumeric(in.params) && length(in.params)==2
                            out.params.range = sort(in.params);
                        else
                            error('uniform distribution assumes numeric vector of size 2');
                        end

                    case 'discrete-uniform'
                        out.type = 'discrete-uniform';
                        if isvector(in.params.range) && isnumeric(in.params.range) && length(in.params.range)==2
                            out.params.range = sort(in.params.range);
                        else
                            error('discrete-uniform distribution assumes numeric vector of size 2');
                        end
                        if iswholenumber(in.params.n)
                            out.params.n = in.params.n;
                        else
                            error('discrete-uniform distribution assumes whole number divisions');
                        end

                    case 'exponential'
                        out.type = 'exponential';
                        if isnumeric(in.params.lambda)&&length(in.params.lambda)==1
                            out.params.lambda = in.params.lambda;
                        else
                            error('lambda needs to be a scalar');
                        end

                        if isfield(in.params,'minDuration')
                            if isnumeric(in.params.minDuration)&&length(in.params.minDuration)==1 
                                out.params.minDuration = in.params.minDuration;
                            else
                                error('minDuration needs to be a scalar');
                            end
                        else
                            out.params.minDuration = 0;
                        end

                    case 'gaussian'
                        out.type = 'gaussian';
                        if isnumeric(in.params.m) && length(in.params.m)==1 && in.params.m>0
                            out.params.m = in.params.m;
                        else
                            error('mean needs to be a scalar >0');
                        end

                        if isnumeric(in.params.sd) && length(in.params.sd)==1 && in.params.sd>0
                            out.params.sd = in.params.sd;
                        else
                            error('sd needs to be a scalar >0');
                        end

                        if isfield(in.params,'cutoffDuration') % only allow flip durations >cutoffDuration
                            if isnumeric(in.params.cutoffDuration) && length(in.params.cutoffDuration)==1 && in.params.cutoffDuration>0
                                out.params.cutoffDuration = in.params.cutoffDuration;
                            else
                                error('cutoffDuration needs to be a scalar >0');
                            end
                        else
                            out.params.cutoffDuration = 0; % forcing it here
                        end

                    otherwise
                        error('unsupported distribution type');
                end
            end
        
            function [doFramePulse, expertCache, dynamicDetails, textLabel, i, dontclear, indexPulse] = ...
                drawExpertFrame(stimulus,stim,i,phaseStartTime,totalFrameNum,window,textLabel,destRect,filtMode,...
                expertCache,ifi,scheduledFrameNum,dropFrames,dontclear,dynamicDetails)
            % 11/14/08 - implementing expert mode for changeDetector.

            currStimObj = stim.stimObject;
            currStimObjDetails = stim.details;
            currStimObjDetails.height = stim.height;
            currStimObjDetails.width = stim.width;


            [doFramePulse, expertCache, dynamicDetails, textLabel, i, dontclear, indexPulse] = ...
                drawExpertFrame(currStimObj,currStimObjDetails,i,phaseStartTime,totalFrameNum,window,textLabel,destRect,filtMode,...
                expertCache,ifi,scheduledFrameNum,dropFrames,dontclear,dynamicDetails);
            end

            function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
                newLUT=LUTparams.compiledLUT;

                try
                    stimDetails=[trialRecords.stimDetails];
                    [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                    [out.doCombos newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);
                    [out.pixPerCycs newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCycs'},'scalar',newLUT);
                    [out.driftfrequencies newLUT] = extractFieldAndEnsure(stimDetails,{'driftfrequencies'},'scalar',newLUT);
                    [out.orientations newLUT] = extractFieldAndEnsure(stimDetails,{'orientations'},'scalar',newLUT);
                    [out.phases newLUT] = extractFieldAndEnsure(stimDetails,{'phases'},'scalar',newLUT);
                    [out.contrasts newLUT] = extractFieldAndEnsure(stimDetails,{'contrasts'},'scalar',newLUT);
                    [out.maxDuration newLUT] = extractFieldAndEnsure(stimDetails,{'maxDuration'},'scalar',newLUT);
                    [out.radii newLUT] = extractFieldAndEnsure(stimDetails,{'radii'},'scalar',newLUT);
                    [out.annuli newLUT] = extractFieldAndEnsure(stimDetails,{'annuli'},'scalar',newLUT);
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
                            if isfield(stim,'spatialFrequencies')
                                names={'spatialFrequencies','driftfrequencies','phases','contrasts','maxDuration','radii','annuli'};
                            elseif isfield(stim,'pixPerCycs')
                                names={'pixPerCycs','driftfrequencies','phases','contrasts','maxDuration','radii','annuli'};
                            end
                            which = [false false false false false false false];
                            for i = 1:length(names)
                                if length(stim.(names{i}){1})>1 || length(stim.(names{i}){2})>1
                                    which(i) = true;
                                end
                            end
                            out=names(which);

                            warning('gonna assume same number of orientations for both ports? is that wise?')
                            if length(stim.orientations{1})==1 % gonna be intelligent and consider changes by pi to be identical orientations (but they are opposite directions)
                                % nothing there was no orientation sweep
                            elseif length(stim.orientations{1})==2
                                if diff(mod(stim.orientations{1},pi))<0.000001 && diff(mod(stim.orientations{2},pi))<0.000001%allowing for small changes during serialization
                                    % they are the same
                                else
                                    out{end+1} = 'orientations';
                                end
                            else
                                % then length >2 then automatically there is some sweep
                                out{end+1} = 'orientations';
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
                %     s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
                    s=fillLUT(s,'localCalibStore');

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
            
            function out = sampleDistribution(s,which)
                switch which
                    case 'durationToFlip'
                        relevant = s.durationToFlip;
                    case 'durationAfterFlip'
                        relevant = s.durationAfterFlip;
                    otherwise
                        error('notsupported')
                end
                out = [];

                switch relevant.type
                    case 'delta'
                        out = relevant.params;
                    case 'uniform'
                        out = relevant.params.range(1)+diff(relevant.params.range)*rand;
                    case 'discrete-uniform'
                        possibles = linspace(relevant.params.range(1),relevant.params.range(2),relevant.params.n);
                        which = randparm(relevant.params.n);
                        which = which(1);
                        out = possibles(which);
                    case 'exponential'
                        error('not yet');
                    case 'gaussian'
                        error('not yet');
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
                        case 'changeDetectorTM'
                            out = 1;
                        otherwise
                            out=0;
                    end
                else
                    error('need a trialManager object')
                end
            end
            
    
 
    end
    
end


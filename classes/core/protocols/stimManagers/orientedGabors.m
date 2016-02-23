classdef orientedGabors<stimManager
    
    properties
        pixPerCycs = [];
        targetOrientations = [];
        distractorOrientations = [];

        mean = 0;
        radius = 0;
        contrasts = 0;
        thresh = 0;
        yPosPct = 0;

        LUT =[];
        LUTbits=0;
        waveform='square';
        normalizedSizeMethod='normalizeDiagonal';

    end
    
    methods
        function s=orientedGabors(varargin)
            % ORIENTEDGABORS  class constructor.
            % s = orientedGabors([pixPerCycs],[targetOrientations],[distractorOrientations],mean,radius,contrasts,thresh,yPositionPercent,maxWidth,maxHeight,scaleFactor,interTrialLuminance,[waveform],[normalizedSizeMethod])
            % orientations in radians
            % mean, contrasts, yPositionPercent normalized (0 <= value <= 1)
            % radius is the std dev of the enveloping gaussian, (by default in normalized units of the diagonal of the stim region)
            % thresh is in normalized luminance units, the value below which the stim should not appear

            switch nargin
                case 0
                    % if no input arguments, create a default object

                    

                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'orientedGabors'))
                        s = varargin{1};
                    else
                        error('Input argument is not an orientedGabors object')
                    end
                case {12 14}
                    % create object using specified values

                    if all(varargin{1})>0
                        s.pixPerCycs=varargin{1};
                    else
                        error('pixPerCycs must all be > 0')
                    end

                    if all(isnumeric(varargin{2})) && all(isnumeric(varargin{3}))
                        s.targetOrientations=varargin{2};
                        s.distractorOrientations=varargin{3};
                    else
                        error('target and distractor orientations must be numbers')
                    end

                    if varargin{4} >= 0 && varargin{4}<=1
                        s.mean=varargin{4};
                    else
                        error('0 <= mean <= 1')
                    end

                    if varargin{5} >=0
                        s.radius=varargin{5};
                    else
                        error('radius must be >= 0')
                    end

                    if all(isnumeric(varargin{6}))
                        s.contrasts=varargin{6};
                    else
                        error('contrasts must be numeric')
                    end

                    if varargin{7} >= 0
                        s.thresh=varargin{7};
                    else
                        error('thresh must be >= 0')
                    end

                    if isnumeric(varargin{8})
                        s.yPosPct=varargin{8};
                    else
                        error('yPositionPercent must be numeric')
                    end

                    if nargin==14
                        if ~isempty(varargin{13})
                            if ismember(varargin{13},{'sine', 'square', 'none'})
                                s.waveform=varargin{13};
                            else
                                error('waveform must be ''sine'', ''square'', or ''none''')
                            end
                        end
                        if ~isempty(varargin{14})
                            if ismember(varargin{14},{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'})
                                s.normalizedSizeMethod=varargin{14};
                            else
                                error('normalizeMethod must be ''normalizeVertical'', ''normalizeHorizontal'', or ''normalizeDiagonal'', or ''none''')
                            end
                        end
                    end

                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,interTrialStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =...
    calcStim(stimulus,trialManager,allowRepeats,resolutions,displaySize,LUTbits,...
    responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % see ratrixPath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)
            % 1/3/0/09 - trialRecords now includes THIS trial
            trialManagerClass = class(trialManager);
            indexPulses=[];
            imagingTasks=[];
            LUTbits
            displaySize
            [LUT, stimulus, updateSM]=getLUT(stimulus,LUTbits);
            [junk, mac] = getMACaddress();
            switch mac
                case {'A41F7278B4DE','A41F729213E2','A41F726EC11C','A41F729211B1' } %gLab-Behavior rigs 1,2,3
                    [resolutionIndex, height, width, hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
                case {'7845C4256F4C', '7845C42558DF'} %gLab-Behavior rigs 4,5
                    [resolutionIndex, height, width, hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
                otherwise 
                    [resolutionIndex, height, width, hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
            end

            if isnan(resolutionIndex)
                resolutionIndex=1;
            end

            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus); 
            interTrialDuration = getInterTrialDuration(stimulus);

            details.pctCorrectionTrials = getPercentCorrectionTrials(trialManager); % need to change this to be passed in from trial manager
            details.bias = getRequestBias(trialManager);

            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            switch trialManagerClass
                case 'freeDrinksAlternate'
                    twoRecsAgo = [];
                    if ~isempty(trialRecords) && length(trialRecords)>=3
                        twoRecsAgo = trialRecords(end-2);
                    end
                    [targetPorts, distractorPorts, details]=assignPorts(details,{lastRec, twoRecsAgo},responsePorts,trialManagerClass,allowRepeats);
                otherwise
                    [targetPorts, distractorPorts, details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);
            end
            switch trialManagerClass
                case {'freeDrinks','freeDrinksCenterOnly','freeDrinksSidesOnly','freeDrinksAlternate'}
                    type='loop';
                case 'nAFC'
                    type={'trigger',true};
                case 'autopilot'
                    type='loop';
                case 'goNoGo'
                    type={'trigger',true};
                otherwise
                    error('unsupported trialManagerClass');
            end

            numFreqs=length(stimulus.pixPerCycs);
            details.pixPerCyc=stimulus.pixPerCycs(ceil(rand*numFreqs));

            numTargs=length(stimulus.targetOrientations);
            % fixes 1xN versus Nx1 vectors if more than one targetOrientation
            if size(stimulus.targetOrientations,1)==1 && size(stimulus.targetOrientations,2)>1
                targetOrientations=stimulus.targetOrientations';
            else
                targetOrientations=stimulus.targetOrientations;
            end
            if size(stimulus.distractorOrientations,1)==1 && size(stimulus.distractorOrientations,2)>1
                distractorOrientations=stimulus.distractorOrientations';
            else
                distractorOrientations=stimulus.distractorOrientations;
            end

            details.orientations = targetOrientations(ceil(rand(length(targetPorts),1)*numTargs));

            numDistrs=length(stimulus.distractorOrientations);
            if numDistrs>0
                numGabors=length(targetPorts)+length(distractorPorts);
                details.orientations = [details.orientations; distractorOrientations(ceil(rand(length(distractorPorts),1)*numDistrs))];
                distractorLocs=distractorPorts;
            else
                numGabors=length(targetPorts);
                distractorLocs=[];
            end
            details.phases=rand(numGabors,1)*2*pi;

            xPosPcts = [linspace(0,1,totalPorts+2)]';
            xPosPcts = xPosPcts(2:end-1);
            details.xPosPcts = xPosPcts([targetPorts'; distractorLocs']);

            details.contrast=stimulus.contrasts(ceil(rand*length(stimulus.contrasts))); % pick a random contrast from list

            params = [repmat([stimulus.radius details.pixPerCyc],numGabors,1) details.phases details.orientations repmat([details.contrast stimulus.thresh],numGabors,1) details.xPosPcts repmat([stimulus.yPosPct],numGabors,1)];
            out(:,:,1)=computeGabors(params,stimulus.mean,min(width,getMaxWidth(stimulus)),min(height,getMaxHeight(stimulus)),stimulus.waveform, stimulus.normalizedSizeMethod,0);
            if iscell(type) && strcmp(type{1},'trigger')
                out(:,:,2)=stimulus.mean;
            end

            if strcmp(trialManagerClass,'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('pixPerCyc: %g',details.pixPerCyc);
            end


            discrimStim=[];
            discrimStim.stimulus=out;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.ledON = [false false];
            switch trialManagerClass
                case {'freeDrinks','freeDrinksCenterOnly','freeDrinksSidesOnly','freeDrinksAlternate'}
                    fdLikelihood = getFreeDrinkLikelihood(trialManager);
            %         if fdLikelihood>0 && ~isempty(responsePorts)
            %             autoTrigger = {fdLikelihood,responsePorts};
            %         end
                    autoTrigger = {};
                    for i = 1:length(responsePorts)
                        autoTrigger{end+1} = fdLikelihood;
                        autoTrigger{end+1} = responsePorts(i);
                    end
            %         if fdLikelihood>0 && ~isempty(responsePorts)
            %             discrimStim.autoTrigger = {fdLikelihood,responsePorts};
            %         else
            %             discrimStim.autoTrigger = [];
            %         end
            discrimStim.autoTrigger = autoTrigger;
                case {'nAFC','autopilot','goNoGo'}
                    discrimStim.autoTrigger=[];
            end

            preRequestStim=[];
            preRequestStim.stimulus=interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;
            preRequestStim.ledON = [false false];

            preResponseStim=discrimStim;
            preResponseStim.punishResponses=false;
            preResponseStim.ledON = [false false];

            postDiscrimStim = [];

            interTrialStim.duration = interTrialDuration;
            details.interTrialDuration = interTrialDuration;
        end % end function
        
        function d=display(s)
            d=['orientedGabors (n target, m distractor gabors, randomized phase, equal spatial frequency, p>=n+m horiz positions)\n'...
                '\t\t\tpixPerCycs:\t[' num2str(s.pixPerCycs) ... 
                ']\n\t\t\ttarget orientations:\t[' num2str(s.targetOrientations) ...
                ']\n\t\t\tdistractor orientations:\t[' num2str(s.distractorOrientations) ...
                ']\n\t\t\tmean:\t' num2str(s.mean) ...
                '\n\t\t\tradius:\t' num2str(s.radius) ...
                '\n\t\t\tcontrast:\t' num2str(s.contrast) ...
                '\n\t\t\tthresh:\t' num2str(s.thresh) ...
                '\n\t\t\tpct from top:\t' num2str(s.yPosPct)];
            d=sprintf(d);
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
                    [out.pixPerCyc newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCyc'},'none',newLUT);
                    [out.orientations newLUT] = extractFieldAndEnsure(stimDetails,{'orientations'},'none',newLUT);
                    [out.phases newLUT] = extractFieldAndEnsure(stimDetails,{'phases'},'none',newLUT);
                    [out.xPosPcts newLUT] = extractFieldAndEnsure(stimDetails,{'xPosPcts'},'none',newLUT);
                    [out.contrast newLUT] = extractFieldAndEnsure(stimDetails,{'contrast'},'scalar',newLUT);

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
            %     s=fillLUT(s,'hardwiredLinear',[0 1],false);
                [a b] = getMACaddress;
                if ismember(b,{'7CD1C3E5176F',... balaji Macbook air
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
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case {'freeDrinks','freeDrinksCenterOnly','freeDrinksSidesOnly','freeDrinksAlternate'}
                        out=1;
                    case 'nAFC'
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


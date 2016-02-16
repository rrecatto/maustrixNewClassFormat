classdef contrastDynamics
    
    properties
        background = 0.5;
        LUT=[];
        LUTbits=0;

        blankOn = false;
        blankDuration = 0;

        LEDParams;

        stimSpec;
    end
    
    methods
        function s=contrastDynamics(varargin)
            % CONTRASTDYNAMICS  class constructor.
            s.LEDParams.active = false;
            s.LEDParams.fraction = 0;
            s.LEDParams.fractionMode = 'byTrial';
            s.LEDParams.LEDStimMode = 'continuous';
            s.LEDParams.LEDStimModeParams = [];

            s.stimSpec.type = 'sequential';
            s.stimSpec.pattern = 'grating';
            s.stimSpec.orientation = 0;
            s.stimSpec.contrastSpace = {1,100,'logspace'};
            s.stimSpec.radiusSpace = {0.2, 0.2, 'logspace'};
            s.stimSpec.location = [0.5 0.5];
            s.stimSpec.numStimuli = 100;
            s.stimSpec.numFramesPerStim = 1;

            % other ways to input stimspec
            % s.stimSpec.type = 'sequential';
            % s.stimSpec.pattern = 'grating';
            % s.stimSpec.orientation = 0;
            % s.stimSpec.contrasts = 0;
            % s.stimSpec.radii = 0.2;
            % s.stimSpec.numStimuli = 100;

            % s.stimSpec.type = 'random';
            % s.stimSpec.pattern = 'grating';
            % s.stimSpec.orientation = 0;
            % s.stimSpec.contrasts = logspace(log10(1),log10(100),10);
            % s.stimSpec.radii = 0.2;
            % s.stimSpec.numStimuli = 100;
            % s.stimSpec.randomizer = 'twister'
            % 
            % 
            % s.stimSpec.type = 'sequential';
            % s.stimSpec.pattern = 'naturalNoise';
            % s.stimSpec.orientation = 0;
            % s.stimSpec.contrasts = logspace(log10(1),log10(100),10);
            % s.stimSpec.radii = 0.2;
            % s.stimSpec.numStimuli = 100;



            switch nargin
                case 0
                    % if no input arguments, create a default object

                    s = class(s,'contrastDynamics',stimManager());
                case 1
                    % if input is of this class type
                    if (isa(varargin{1},'contrastDynamics'))
                        s = varargin{1};
                    else
                        error('Input argument is not a whiteNoiseBubble object')
                    end
                case 7
                    % background
                    if isscalar(varargin{1})
                        s.background = varargin{1};
                    elseif iscell(varargin{1})
                        s.background = varargin{1}{1};
                        s.blankOn = true;
                        s.blankDuration = varargin{1}{2};
                    else
                        error('background must be a scalar or a cell with a blanking duration');
                    end

                    stimSpec = varargin{2};
                    if ~isstruct(stimSpec)
                        stimSpec;
                        error('stimSpec needs to be a struct');
                    end
                    % some error checks for stiomspec
                    if ~isempty(stimSpec)
                        s.stimSpec = stimSpec;
                    end

                    LEDParams = varargin{3};
                    if ~isempty(LEDParams)
                        s.LEDParams = LEDParams
                    end

                    s = class(s,'contrastDynamics',stimManager(varargin{4},varargin{5},varargin{6},varargin{7}));
                otherwise
                    error('invalid number of input arguments');
            end
        end
        
        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,interTrialStim,LUT,targetPorts,distractorPorts,...
    details,interTrialLuminance,text,indexPulses,imagingTasks] =...
    calcStim(stimulus,trialManager,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % see ratrixPath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)
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

            toggleStim=true;
            type = 'expert';
            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus); 
            interTrialDuration = getInterTrialDuration(stimulus);

            details.pctCorrectionTrials=getPercentCorrectionTrials(trialManager);
            details.bias = getRequestBias(trialManager);

            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);

            % ================================================================================
            % start calculating frames now


            numFrames = stimulus.stimSpec.numStimuli*stimulus.stimSpec.numFramesPerStim;

            stim.contrasts = nan(1,numFrames);
            stim.radius= nan(1,numFrames);

            stim.location = stimulus.stimSpec.location;

            switch stimulus.stimSpec.type
                case 'sequential'
                    switch stimulus.stimSpec.contrastSpace{3}
                        case 'logspace'
                            contrasts = logspace(log10(stimulus.stimSpec.contrastSpace{1}), log10(stimulus.stimSpec.contrastSpace{2}), stimulus.stimSpec.numStimuli);
                        case 'linspace'
                            contrasts = linspace(stimulus.stimSpec.contrastSpace{1}, stimulus.stimSpec.contrastSpace{2}, stimulus.stimSpec.numStimuli);
                    end
                    contrasts = repmat(contrasts,stimulus.stimSpec.numFramesPerStim,1);
                    stim.contrasts = reshape(contrasts,1,numFrames);

                    switch stimulus.stimSpec.radiusSpace{3}
                        case 'logspace'
                            radii = logspace(log10(stimulus.stimSpec.radiusSpace{1}), log10(stimulus.stimSpec.radiusSpace{2}), stimulus.stimSpec.numStimuli);
                        case 'linspace'
                            radii = linspace(stimulus.stimSpec.radiusSpace{1}, stimulus.stimSpec.radiusSpace{2}, stimulus.stimSpec.numStimuli);
                    end
                    radii = repmat(radii,stimulus.stimSpec.numFramesPerStim,1);
                    stim.radii = reshape(radii,1,numFrames);
                case 'random'
                    error('not yet')
            end
            % 10/31/08 - dynamic mode stim is a struct of parameters

            stim.height = min(height,getMaxHeight(stimulus));
            stim.width = min(width,getMaxWidth(stimulus));

            % LEDParams

            [details, stim] = setupLED(details, stim, stimulus.LEDParams,arduinoCONN);

            discrimStim=[];
            discrimStim.stimulus=stim;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            discrimStim.framesUntilTimeout=numFrames;

            preRequestStim=[];
            preRequestStim.stimulus=interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;

            postDiscrimStim = [];
            preResponseStim = [];

            interTrialStim.duration = interTrialDuration;
            details.interTrialDuration = interTrialDuration;
            % details.big = {'expert', stim.seedValues}; % store in 'big' so it gets written to file
            % variables to be stored for recalculation of stimulus from seed value for rand generator
            details.strategy='expert';
            details.contrasts = stim.contrasts;
            details.radii =stim.radii;
            details.numFrames=numFrames;
            if isempty(numFrames)
                details.repeatFramesON = true;
            else
                details.repeatFramesON = false;
            end
            details.height=stim.height;
            details.width=stim.width;
            % ================================================================================
            if strcmp(trialManagerClass,'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('contrastSequece');
            end
        end
        
        function commonName = commonNameForStim(stimType,params)
            classType = class(stimType);

            if all(params.spatialDim == [1 1])
                if strcmp(params.distribution.type,'gaussian')
                    commonName = 'ffgwn';
                elseif strcmp(params.distribution.type,'binary')
                    commonName = 'ffbinwn';
                else
                    commonName = classType;
                end
            elseif params.spatialDim(1)==1
                commonName = 'h-bars';
            elseif params.spatialDim(2)==1
                commonName = 'v-bars';
            elseif strcmp(params.distribution.type,'binary')
                commonName = sprintf('%dX%d binary checkerboard',params.spatialDim(2),params.spatialDim(1));
            else
                commonName = classType;
            end
        end
        
        function [paramsIdentical diffIn] = compareStimRecords(stimType,params1,params2)
            paramsList = {{'strategy'},{'spatialDim'},{'patternType'},{'distribution','type'}};
            diffIn = {};

            % checking for strategy
            if isfield(params1,'strategy') && isfield(params2,'strategy') && strcmp(params1.strategy,params2.strategy)
                % do nothing
            else
                diffIn{end+1} = {'strategy'};
            end

            % check for spatialDim
            if isfield(params1,'spatialDim') && isfield(params2,'spatialDim') && all(params1.spatialDim==params2.spatialDim)
                % do nothing
            else
                diffIn{end+1} = {'spatialDim'};
            end

            % check for patternType
            if isfield(params1,'patternType') && isfield(params2,'patternType') && strcmp(params1.patternType,params2.patternType)
                % do nothing
            else
                diffIn{end+1} = {'patternType'};
            end

            % check for distribution.type
            if isfield(params1,'distribution') && isfield(params1.distribution,'type') && ...
                    isfield(params2,'distribution') && isfield(params2.distribution,'type') && ...
                    strcmp(params1.distribution.type,params2.distribution.type)
                % do nothing
            else
                diffIn{end+1} = {'distribution','type'};
            end

            paramsIdentical = isempty(diffIn);
        end


        function displayCumulativePhysAnalysis(sm,cumulativedata,parameters)
            % allows for display without recomputation


            % make sure data exists
            if isempty(cumulativedata)
                warning('NOT DISPLAYING INFO FOR TRIAL %d BECAUSE CUMULATIVE DATA IS EMPTY',parameters.trialRange(end));

                return
            end
            analysisdata = cumulativedata.lastAnalysis;
            analysisdata.singleChunkTemporalRecord(1,:)=...
            getTemporalSignal(sm,analysisdata.STA,analysisdata.STV,analysisdata.numSpikes,'bright');

            % stimulus info
            stimulusDetails = parameters.stimRecords.stimulusDetails;
            whiteVal=255;
            spatialSmoothingOn=true;
            doSTC=false;
            xtraPlot={'spaceTimeContext'}; % eyes, spaceTimeContext, montage

            % timeWindowMs
            timeWindowMsStim=[200 50]; % parameter [300 50]
            timeWindowMsLFP =[1000 1000];

            % refreshRate - try to retrieve from neuralRecord (passed from stim computer)
            if isfield(parameters, 'refreshRate')
                refreshRate = parameters.refreshRate;
            else
                %error('dont use default refreshRate');
                refreshRate = 100;
            end

            % calculate the number of frames in the window for each spike
            timeWindowFramesStim=ceil(timeWindowMsStim*(refreshRate/1000));

            if spatialSmoothingOn
                filt=... a mini gaussian like fspecial('gaussian')
                    [0.0113  0.0838  0.0113;
                    0.0838  0.6193  0.0838;
                    0.0113  0.0838  0.0113];
            end

            if isfield(stimulusDetails,'distribution')
                switch stimulusDetails.distribution.type
                    case 'gaussian'
                        std = stimulusDetails.distribution.std;
                        meanLuminance = stimulusDetails.distribution.meanLuminance;
                    case 'binary'
                        p=stimulusDetails.distribution.probability;
                        hiLoDiff=(stimulusDetails.distribution.hiVal-stimulusDetails.distribution.lowVal);
                        std=hiLoDiff*p*(1-p);
                        meanLuminance=(p*stimulusDetails.distribution.hiVal)+((1-p)*stimulusDetails.distribution.lowVal);
                end
            else
                error('dont use old convention for whiteNoise');
                %old convention prior to april 17th, 2009
                %stimulusDetails.distribution.type='gaussian';
                %std = stimulusDetails.std;
                %meanLuminance = stimulusDetails.meanLuminance;
            end



            % cumulative
            [brightSignal brightCI brightInd]=getTemporalSignal(sm,cumulativedata.cumulativeSTA,cumulativedata.cumulativeSTV,cumulativedata.cumulativeNumSpikes,'bright');
            [darkSignal darkCI darkInd]=getTemporalSignal(sm,cumulativedata.cumulativeSTA,cumulativedata.cumulativeSTV,cumulativedata.cumulativeNumSpikes,'dark');

            rng=[min(cumulativedata.cumulativeSTA(:)) max(cumulativedata.cumulativeSTA(:))];

            % 11/25/08 - update GUI
            % create the figure and name it
            if length(parameters.trialRange)>1
                figureName = sprintf('%s on %s. trialRange :%d -> %d',parameters.stepName,parameters.trodeName,min(parameters.trialRange),max(parameters.trialRange));
            else
                figureName = sprintf('%s on %s. trialRange :%d',parameters.stepName,parameters.trodeName,parameters.trialRange);
            end
            figure(parameters.figHandle)
            set(gcf,'NumberTitle','off','Name',figureName,'Units','pixels','position',[100 100 800 700]);


            % is it a spatial signal? or fullfield?
            doSpatial=~(size(cumulativedata.cumulativeSTA,1)==1 & size(cumulativedata.cumulativeSTA,2)==1); % if spatial dimentions exist

            % %% spatial signal (best via bright)
            if doSpatial
                oP = get(gcf,'OuterPosition');
                set(gcf,'OuterPosition',[oP(1) oP(2) 2*oP(3) oP(4)]);
                % change here for which context
                contextType = 'bright';%'bright'; 'dark';
                switch contextType
                    case 'dark'
                        contextInd = darkInd;
                    case 'bright'
                        contextInd = brightInd;
                    otherwise
                        error('unknown context type');
                end

                %fit model to best spatial
                stdThresh=1;
                [STAenvelope STAparams] =fitGaussianEnvelopeToImage(cumulativedata.cumulativeSTA(:,:,contextInd(3)),stdThresh,false,false,false);
                cx=STAparams(2)*size(STAenvelope,2)+1;
                cy=STAparams(3)*size(STAenvelope,1)+1;
                stdx=size(STAenvelope,2)*STAparams(5);
                stdy=size(STAenvelope,1)*STAparams(5);
                e1 = fncmb(fncmb(rsmak('circle'),[stdx*1 0;0 stdy*1]),[cx;cy]);
                e2 = fncmb(fncmb(rsmak('circle'),[stdx*2 0;0 stdy*2]),[cx;cy]);
                e3 = fncmb(fncmb(rsmak('circle'),[stdx*3 0;0 stdy*3]),[cx;cy]);


                %get significant pixels and denoised spots
                switch stimulusDetails.distribution.type
                    case 'gaussian'
                        stdStimulus = std*whiteVal;
                    case 'binary'
                        stdStimulus = std*whiteVal*100; % somthing very large to prevent false positives... need to figure it out analytically.. maybe use different function
                        %std=hiLoDiff*p*(1-p);
                end
                meanLuminanceStimulus = meanLuminance*whiteVal;
                [bigSpots sigPixels]=getSignificantSTASpots(cumulativedata.cumulativeSTA(:,:,contextInd(3)),cumulativedata.cumulativeNumSpikes,meanLuminanceStimulus,stdStimulus,ones(3),3,0.05);
                [bigIndY bigIndX]=find(bigSpots~=0);
                [sigIndY sigIndX]=find(sigPixels~=0);

                % clear the figure and start anew
                clf(parameters.figHandle);

                % cumulative modulation
                cumuModAx = subplot(2,4,1);
                im=single(squeeze(cumulativedata.cumulativeSTA(:,:,contextInd(3))));
                if spatialSmoothingOn
                    im=imfilter(im,filt,'replicate','same');
                end
                if rng(1)==rng(2)
                    rng = [0 255];
                end
                imagesc(im,rng);
                %colorbar; %colormap(blueToRed(meanLuminanceStimulus,rng));
                hold on; plot(brightInd(2), brightInd(1),'y+')
                hold on; plot(darkInd(2)  , darkInd(1),  'y-')
                hold on; plot(bigIndX     , bigIndY,     'y.')
                hold on; plot(sigIndX     , sigIndY,     'y.','markerSize',1)
                minTrial=min(cumulativedata.cumulativeTrialNumbers);
                maxTrial=max(cumulativedata.cumulativeTrialNumbers);
                xlabel(sprintf('cumulative (%d.%d --> %d.%d)',...
                    minTrial,min(cumulativedata.cumulativeChunkIDs(find(cumulativedata.cumulativeTrialNumbers==minTrial))),...
                    maxTrial,max(cumulativedata.cumulativeChunkIDs(find(cumulativedata.cumulativeTrialNumbers==maxTrial)))));
                %fnplt(e1,1,'g'); fnplt(e2,1,'g'); fnplt(e3,1,'g'); % plot ellipses

                % latest trial modulation
                singTrModAx = subplot(2,4,2);    
                %hold off; imagesc(squeeze(STA(:,:,contextInd(3))),[min(STA(:)) max(STA(:))]);
                if ~(min(analysisdata.STA(:))==max(analysisdata.STA(:)))
                    hold off; imagesc(squeeze(analysisdata.STA(:,:,contextInd(3))),[min(analysisdata.STA(:)) max(analysisdata.STA(:))]);
                else
                    warning('hard coding some stuff here...')
                    hold off; imagesc(squeeze(analysisdata.STA(:,:,contextInd(3))),[0 255]);
                end
                hold on; plot(brightInd(2), brightInd(1),'y+')
                hold on; plot(darkInd(2)  , darkInd(1),'y-')
                %colorbar;
                colormap(gray);
                %colormap(blueToRed(meanLuminanceStimulus,rng,true));

                fnplt(e1,1,'g'); fnplt(e2,1,'g'); fnplt(e3,1,'g'); % plot elipses

                xlabel(sprintf('this trial/chunk (%d-%d)',analysisdata.trialNumber,analysisdata.chunkID))

                % draw the temporal for the relevant only
                relevantTempOnlyAx = subplot(2,4,5);
                timeMs=linspace(-timeWindowMsStim(1),timeWindowMsStim(2),size(cumulativedata.cumulativeSTA,3));
                ns=length(timeMs);
                hold off; plot(timeWindowFramesStim([1 1])+1, [0 whiteVal],'k');
                hold on;  plot([1 ns],meanLuminance([1 1])*whiteVal,'k')
                % try
                %     plot([1:ns], analysisdata.singleChunkTemporalRecord, 'color',[.8 .8 1])
                % catch
                %     keyboard
                % end
                fh=fill([1:ns fliplr([1:ns])]',[darkCI(:,1); flipud(darkCI(:,2))],'b'); set(fh,'edgeAlpha',0,'faceAlpha',.5)
                fh=fill([1:ns fliplr([1:ns])]',[brightCI(:,1); flipud(brightCI(:,2))],'r'); set(fh,'edgeAlpha',0,'faceAlpha',.5)
                plot([1:ns], darkSignal(:)','b')
                plot([1:ns], brightSignal(:)','r')

                switch contextType
                    case 'dark'
                        peakFrame = find(darkSignal==min(darkSignal(:)));
                    case 'bright'
                        peakFrame = find(brightSignal==max(brightSignal(:)));
                    otherwise
                        error('unknown context type');
                end

                timeInds=[1 peakFrame(end) timeWindowFramesStim(1)+1 size(cumulativedata.cumulativeSTA,3)];
                set(gca,'XTick',unique(timeInds),'XLim',minmax(timeInds));
                Labels = {};
                whichTimeInds = unique(timeInds);
                for tInd = 1:length(whichTimeInds)
                    Labels{tInd} = sprintf('%2.0f',timeMs(whichTimeInds(tInd)));
                end
                set(gca,'XTickLabel',Labels);
                set(gca,'YLim',[minmax([analysisdata.singleChunkTemporalRecord(:)' darkCI(:)' brightCI(:)'])+[-5 5]])
                ylabel('RGB(gunVal)')
                xlabel('msec')

                % xtraPlot
                xtraPlotax = subplot(2,4,[3 4 7 8]);
                switch xtraPlot{1}
                    case 'montage'
                        % montage(reshape(cumulativedata.cumulativeSTA,[size(cumulativedata.STA,1) size(cumulativedata.STA,2) 1 size(cumulativedata.STA,3) ] ), 'DisplayRange',rng)
                        montage(reshape(cumulativedata.cumulativeSTA,[size(STA,1) size(STA,2) 1 size(STA,3) ] ),'DisplayRange',rng)
                        colormap(blueToRed(meanLuminanceStimulus,rng,true));
                        % %% spatial signal (all)
                        % for i=1:
                        % subplot(4,n,2*n+i)
                        % imagesc(STA(:,:,i),'range',[min(STA(:)) min(STA(:))]);
                        % end

                        if max(parameters.trialNumber)==318
                            keyboard
                        end
                    case 'eyes'

                        figure(parameters.trialNumber)
                        if exist('ellipses','var')
                            plotEyeElipses(eyeSig,ellipses,within,true);
                        else
                            msg=sprintf('no good eyeData on trial %d\n will analyze all data',parameters.trialNumber)
                            text(.5,.5, msg)
                        end
                    case 'spaceTimeContext'
                        %uses defaults on phys monitor may 2009, might not be up to
                        %date after changes in hardware

                        %user controls these somehow... params?
                        eyeToMonitorMm=250;
                        contextSize=3;
                        pixelPad=0.1; %fractional pad 0-->0.5


                        %stimRect=[500 1000 800 1200]; %need to get this stuff!
                        stimRect=[0 0 stimulusDetails.width stimulusDetails.height]; %need to get this! now forcing full screen
                        stimRectFraction=stimRect./[stimulusDetails.width stimulusDetails.height stimulusDetails.width stimulusDetails.height];
                        [vRes hRes]=getAngularResolutionFromGeometry(size(analysisdata.STA,2),size(analysisdata.STA,1),eyeToMonitorMm,stimRectFraction);
                        contextResY=vRes(contextInd(1),contextInd(2));
                        contextResX=hRes(contextInd(1),contextInd(2));


                        contextOffset=-contextSize:1:contextSize;
                        n=length(contextOffset); % 2*c+1
                        contextIm=ones(n,n)*meanLuminanceStimulus;
                        selection=nan(n,n);
                        maxAmp=max(abs(meanLuminanceStimulus-rng))*2; %normalize to whatever lobe is larger: positive or negative
                        hold off; plot(0,0,'.')
                        hold on
                        for i=1:n
                            yInd=contextInd(1)+contextOffset(i);
                            for j=1:n
                                xInd=contextInd(2)+contextOffset(j);
                                if xInd>0 && xInd<=size(analysisdata.STA,2) && yInd>0 && yInd<=size(analysisdata.STA,1)
                                    %make the image
                                    selection(i,j)=sub2ind(size(analysisdata.STA),yInd,xInd,contextInd(3));
                                    contextIm(i,j)=cumulativedata.cumulativeSTA(selection(i,j));
                                    %get temporal signal
                                    [stixSig stixCI stixtInd]=getTemporalSignal(sm,cumulativedata.cumulativeSTA,cumulativedata.cumulativeSTV,cumulativedata.cumulativeNumSpikes,selection(i,j));
                                    yVals{i,j}=((1-pixelPad*2)   *  (stixSig(:)-meanLuminanceStimulus)/maxAmp)  +  n-i+1; % pad, normalize, and then postion in grid
                                    xVals{i,j}=linspace(j-.5+pixelPad,j+.5-pixelPad,length(stixSig(:)));

                                end
                            end
                        end


                        if rng(1)>meanLuminanceStimulus
                            warning('MEAN lum in ouside of range... black color in plot may not be zero influence...maybe due to binary?')
                            %force to edge
                            meanLuminanceStimulus=rng(1)+0.01*diff(rng);
                        end

                        if rng(2)<meanLuminanceStimulus
                            warning('MEAN lum in ouside of range... black value may not be zero influence...maybe due to binary?')
                            meanLuminanceStimulus=rng(2)-0.01*diff(rng);
                        end

                        % plot the image
                        imagesc(flipud(contextIm),rng)
                        colormap(blueToRed(meanLuminanceStimulus,rng,true));

                        %plot the temporal signal
                        for i=1:n
                            for j=1:n
                                if ~isnan(selection(i,j))
                                    plot(xVals{i,j},yVals{i,j},'y')
                                end
                            end
                        end

                        % we only take the degrees of the selected pixel.
                        %neighbors may differ by a few % depending how big they are,
                        %geometery, etc.


                        axis([.5 n+.5 .5 n+.5])
                        set(gca,'xTick',[]); set(gca,'yTick',[])
                        xlabel(sprintf('%2.1f deg/pix',contextResX));
                        ylabel(sprintf('%2.1f deg/pix',contextResY));

                    otherwise
                        error('bad xtra plot request')
                end

                waveFormAx = subplot(2,4,6);
                % now draw the spike waveforms
                plot(cumulativedata.cumulativeSpikeWaveforms','r')
                set(waveFormAx,'XTick',[],'Ytick',[]);
                axis tight

            else
                % full field!
                clf(parameters.figHandle);
                temporalonlyAx = axes;
                timeMs=linspace(-timeWindowMsStim(1),timeWindowMsStim(2),size(cumulativedata.cumulativeSTA,3));
                ns=length(timeMs);
                hold off; plot(timeWindowFramesStim([1 1])+1, [0 whiteVal],'k');
                hold on;  plot([1 ns],meanLuminance([1 1])*whiteVal,'k')
                % try
                %     plot([1:ns], analysisdata.singleChunkTemporalRecord, 'color',[.8 .8 1])
                % catch
                %     keyboard
                % end
                fh=fill([1:ns fliplr([1:ns])]',[darkCI(:,1); flipud(darkCI(:,2))],'b'); set(fh,'edgeAlpha',0,'faceAlpha',.5)
                fh=fill([1:ns fliplr([1:ns])]',[brightCI(:,1); flipud(brightCI(:,2))],'r'); set(fh,'edgeAlpha',0,'faceAlpha',.5)
                plot([1:ns], darkSignal(:)','b')
                plot([1:ns], brightSignal(:)','r')

                peakFrame=find(brightSignal==max(brightSignal(:)));
                timeInds=[1 peakFrame(end) timeWindowFramesStim(1)+1 size(cumulativedata.cumulativeSTA,3)];
                set(gca,'XTickLabel',unique(timeMs(timeInds)),'XTick',unique(timeInds),'XLim',minmax(timeInds));
                set(gca,'YLim',[minmax([analysisdata.singleChunkTemporalRecord(:)' darkCI(:)' brightCI(:)'])+[-5 5]])
                ylabel('RGB(gunVal)')
                xlabel('msec')
                % now draw the spike waveforms
                waveAx = axes('Position',[0.91 0.91 0.08 0.08]);
                plot(cumulativedata.cumulativeSpikeWaveforms','r')
                set(waveAx,'XTick',[],'Ytick',[]);
                axis tight
            end

        end
        
        function [doFramePulse, expertCache, dynamicDetails, textLabel, i, dontclear, indexPulse] = ...
    drawExpertFrame(stimulus,stim,i,phaseStartTime,totalFrameNum,window,textLabel,destRect,filtMode,...
    expertCache,ifi,scheduledFrameNum,dropFrames,dontclear,dynamicDetails)
            % 10/31/08 - implementing expert mode for whiteNoise
            % this function calculates a expert frame, and then makes and draws the texture; nothing needs to be done in runRealTimeLoop
            % this should be a stimManager-specific implementation (if expert mode is supported for the given stimulus)
            indexPulse=false;
            floatprecision=1;

            %initialize first frame
            if stimulus.blankOn
                doBlank = true;
            else
                doBlank = false;
            end
            radiusType = 'gaussian';
            if isempty(expertCache)
                % this happens at the beginning of the trial. this stimManager will do
                % something interesting - it will cache the computed masks at some
                % location and then recall it for future use

                expertCache.uniqueRadii = unique(stim.radii);
                expertCache.radiiMasks = {};
                expertCache.currentLocation = [0.5 0.5];
                warning ('need to worry about sending in the currentLocation')

                % check if the computed mask function exists

                SCRATCHFOLDER = getenv('SCRATCHFOLDER');
                needToCalcMasks = true;
                if exist(fullfile(SCRATCHFOLDER,'radiiMasks.mat'),'file')
                    temp = load(fullfile(SCRATCHFOLDER,'radiiMasks.mat'));

                    if temp.uniqueRadii == unique(stim.radii)
                        needToCalcMasks = false;
                        for rad = 1:length(expertCache.uniqueRadii)
                            expertCache.radiiMasks{rad} = Screen('MakeTexture',window,double(temp.radMasks{rad}),0,0,floatprecision);
                        end
                    end
                end

                if needToCalcMasks
                    uniqueRadii = expertCache.uniqueRadii;
                    radMasks = {};
                    for rad = 1:length(uniqueRadii)
                        uniqueRadii(rad)
                        mask=[];
                        switch radiusType
                            case 'gaussian'
                                maskParams=[expertCache.uniqueRadii(rad) 999 0 0 ...
                                    1.0 0.00005 expertCache.currentLocation(1) expertCache.currentLocation(2)]; %11/12/08 - for some reason mask contrast must be 2.0 to get correct result
                                mask(:,:,1)=ones(stim.height,stim.width,1)*0.5;
                                try
                                mask(:,:,2)=computeGabors(maskParams,0,stim.width,stim.height,...
                                    'none', 'normalizeDiagonal',0,0);
                                catch
                                    memory
                                    whos
                                end
                                mask(:,:,2) = 1-mask(:,:,2);
                            case 'hardEdge'
                                %             mask(:,:,1)=ones(2*stim.height,2*stim.width,1)*stimulus.mean;
                                %             [WIDTH HEIGHT] = meshgrid(1:2*stim.width,1:2*stim.height);
                                %             mask(:,:,2)=double((((WIDTH-width*details.location(1)).^2)+((HEIGHT-height*details.location(2)).^2)-((unsortedUniques(i))^2*(height^2)))>0);
                                %             stim.masks{i}=mask;
                                error('not yet');

                        end
                        radMasks{rad} = mask;
                        expertCache.radiiMasks{rad} = Screen('MakeTexture',window,double(mask),0,0,floatprecision);
                    end
                    save(fullfile(SCRATCHFOLDER,'radiiMasks.mat'),'uniqueRadii','radMasks');
                end
            end

            % increment i
            if dropFrames
                i=scheduledFrameNum;
            else
                i=i+1;
            end

            % stimulus = stimManager
            doFramePulse=true;
            indexPulse = false;

            % ================================================================================

            % start calculating frames now
            stimLocation = stimulus.stimSpec.location;

            % this needs to change

            % rand('state',2000);
            % lumDiff=stim.distribution.hiVal-stim.distribution.lowVal;
            hiVal = 1; loVal = 0; grey = (hiVal+loVal)/2;
            expertFrame = grey+(double(rand([9 16])<grey)-grey)*(stim.contrasts(i)/100);

            Screen('FillRect', window, stimulus.background*WhiteIndex(window));
            % 11/14/08 - moved the make and draw to stimManager specific getexpertFrame b/c they might draw differently

            dynTex = Screen('MakeTexture', window, expertFrame,0,0,floatprecision);
            Screen('DrawTexture', window, dynTex,[],destRect,[],filtMode);

            % Blending for making bubbles
            Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % necessary to do the transparency blending
            Screen('DrawTexture', window, expertCache.radiiMasks{expertCache.uniqueRadii==stim.radii(i)}, [], destRect,[], filtMode);


            % clear dynTex from vram
            Screen('Close',dynTex);

        end % end function

        function retval = enableChunkedPhysAnalysis(sm)
            % returns true if physAnalysis knows how to deal with, and wants each chunk
            % as it comes. 

            retval=true; %white noise wants to run on EVERY CHUNK, as opposed to the end of the trial
            % this helps for memory problems on really long trials... its also have the
            % cumulative analysis is currently built to work

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
            %     [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.strategy newLUT] = extractFieldAndEnsure(stimDetails,{'strategy'},'scalarLUT',newLUT);
                [out.seedValues newLUT] = extractFieldAndEnsure(stimDetails,{'seedValues'},'equalLengthVects',newLUT);
                [out.spatialDim newLUT] = extractFieldAndEnsure(stimDetails,{'spatialDim'},'equalLengthVects',newLUT);
                [out.stixelSize newLUT] = extractFieldAndEnsure(stimDetails,{'stixelSize'},'equalLengthVects',newLUT);
                [out.std newLUT] = extractFieldAndEnsure(stimDetails,{'distribution','std'},'scalar',newLUT);
                [out.meanLuminance newLUT] = extractFieldAndEnsure(stimDetails,{'distribution','meanLuminance'},'scalar',newLUT);
                [out.distributionType newLUT] = extractFieldAndEnsure(stimDetails,{'distribution','type'},'scalarLUT',newLUT);
                [out.patternType newLUT] = extractFieldAndEnsure(stimDetails,{'patternType'},'scalarLUT',newLUT);
                [out.numFrames newLUT] = extractFieldAndEnsure(stimDetails,{'numFrames'},'scalar',newLUT);

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
                            if true|| (any(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')) && ...
                                    datenum(a(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')).date)>floor(now))
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
            if isfield(stim,'stimulusDetails')
                stim = stim.stimulusDetails;
            end
            switch what
                case 'spatialDim'
                    out=stim.spatialDim;
                case 'distType'
                    out = stim.distribution.type;
                otherwise
                    error('unknown what');
            end
        end
        
        function [out s updateSM]=getLUT(s,bits);
            if isempty(s.LUT) || s.LUTbits~=bits
                updateSM=true;
                s.LUTbits=bits;
            %     s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
                %s=fillLUT(s,'2009Trinitron255GrayBoxInterpBkgnd.5');
                %s=fillLUT(s,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5'); % March 2011 ViewSonic
            %     s=fillLUT(s,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5'); % May 2011 Westinghouse
                [a b] = getMACaddress;
                if ismember(b,{'7CD1C3E5176F'})...,... balaji Macbook air

                    s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
                else
                    s=fillLUT(s,'localCalibStore');
                end

            else
                updateSM=false;
            end
            out=s.LUT;
        end

        function [meanLuminance std] = getMeanLuminanceAndStd(sm,stimInfo)
            if isfield(stimInfo,'stimulusDetails')
                stimInfo = stimInfo.stimulusDetails;
            end
            switch stimInfo.distribution.type
                case 'gaussian'
                    std = stimInfo.distribution.std;
                    meanLuminance = stimInfo.distribution.meanLuminance;
                case 'binary'
                    p=stimInfo.distribution.probability;
                    hiLoDiff=(stimInfo.distribution.hiVal-stimInfo.distribution.lowVal);
                    std=hiLoDiff*p*(1-p);
                    meanLuminance=(p*stimInfo.distribution.hiVal)+((1-p)*stimInfo.distribution.lowVal);
            end

        end

        function out = getPhysAnalysisObject(sm,subject,tr,channels,dataPath,stim,c,monitor,rigState)
            if ~exist('c','var')||isempty(c)
                c = struct([]);
            end
            out = wnAnalysis(subject,tr,channels,dataPath,stim,c,monitor,rigState);
        end

        
        function [sig CI ind]=getTemporalSignal(sm,STA,STV,numSpikes,selection)
            switch class(selection)
                case 'char'
                    switch selection
                        case 'bright'
                            [ind]=find(STA==max(STA(:)));  %shortcut for a relavent region
                        case 'dark'
                            [ind]=find(STA==min(STA(:)));
                        otherwise
                            selection
                            error('bad selection')
                    end

                case 'double'
                    temp=cumprod(size(STA));
                    if iswholenumber(selection) && all(size(selection)==1) && selection<=temp(end)
                        ind=selection;
                    else
                        error('bad selection as a double, which should be an index into STA')
                    end
                otherwise
                    error('bad class for selection')

            end

            try
                %if numSpikes==0 || all(isnan(STA(:)))
                %    ind=1; %to prevent downstream errors, just make one up  THIS DOES
                %    NOT FULLY WORK... need to be smarter... prob no spikes this trial
                %end
                if  numSpikes==0
                    ind=1; %to prevent downstream errors, just make one up
                else
                    ind=ind(1); %use the first one if there is a tie. (more common with low samples)
                end
            catch
                keyboard
            end

            [X Y T]=ind2sub(size(STA),ind);
            ind=[X Y T];
            sig = STA(X,Y,:);
            if nargout>1
                er95= sqrt(STV(X,Y,:)/numSpikes)*1.96; % b/c std error(=std/sqrt(N)) of mean * 1.96 = 95% confidence interval for gaussian, norminv(.975)
                CI=repmat(sig(:),1,2)+er95(:)*[-1 1];
            end
        end

        function out = getType(sm,stim)

            nDim = getDetails(sm,stim,'spatialDim');
            distType = getDetails(sm,stim,'distType');
            switch prod(nDim)
                case 1
                    out=[distType 'FullField'];
                otherwise
                    out=[distType 'Spatial'];
            end
        end
        
        function [analysisdata cumulativedata] = physAnalysis(stimManager,spikeRecord,stimulusDetails,~,parameters,cumulativedata,eyeData,~)
            % stimManager is the stimulus manager
            % spikes is a logical vector of size (number of neural data samples), where 1 represents a spike happening
            % correctedFrameIndices is an nx2 array of frame start and stop indices - [start stop], n = number of frames
            % stimulusDetails are the stimDetails from calcStim (hopefully they contain all the information needed to reconstruct stimData)
            % photoDiode - currently not used
            % plotParameters - currently not used
            % 4/17/09 - spikeRecord contains all the data from this ENTIRE trial, but we should only do analysis on the current chunk
            % to prevent memory problems
                % only analyze currentChunk's data for spikes
                which=find(spikeRecord.chunkIDForDetectedSpikes==spikeRecord.currentChunk);
                % get the relevant spikes
                spikeRecord.spikes=spikeRecord.spikes(which);
                spikeRecord.spikeTimestamps=spikeRecord.spikeTimestamps(which);
                spikeRecord.spikeWaveforms=spikeRecord.spikeWaveforms(which,:);
                spikeRecord.assignedClusters=spikeRecord.assignedClusters(which,:);
                spikeRecord.processedClusters = spikeRecord.processedClusters(which);
                spikeRecord.chunkIDForDetectedSpikes=spikeRecord.chunkIDForDetectedSpikes(which);

                % only analyze currentChunk's data for corrected Frames
                which=find(spikeRecord.chunkIDForCorrectedFrames==spikeRecord.currentChunk);
                spikeRecord.correctedFrameIndices=spikeRecord.correctedFrameIndices(which,:);
                spikeRecord.stimInds=spikeRecord.stimInds(which);
                %spikeRecord.photoDiode=spikeRecord.photoDiode(which);  % HACK! we need this, right?

                % this part is no longer necessary as "spikeDetails is removewhichSubSampled from all analyses
                %     which=find(spikeRecord.chunkID==spikeRecord.currentChunk);
                %     spikeRecord.spikeDetails=spikeRecord.spikeDetails(which);

                if size(spikeRecord.correctedFrameIndices,1)==0 || size(spikeRecord.spikes,1)==0
                    %if this chunk has either no spikes or no stim frames, then return the cumulative data as is
                    analysisdata=[];
                    cumulativedata=cumulativedata;
                    warning(sprintf('skipping white noise analysis for trial %d chunk %d because there are %d stim frames and %d spikes',...
                        parameters.trialNumber,spikeRecord.currentChunk,size(spikeRecord.correctedFrameIndices,1),size(spikeRecord.spikes,1)))
                    return
                end

                %SET UP RELATION stimInd <--> frameInd
                analyzeDrops=true;
                if analyzeDrops
                    stimFrames=spikeRecord.stimInds;
                    correctedFrameIndices=spikeRecord.correctedFrameIndices;
                else
                    numStimFrames=max(spikeRecord.stimInds);
                    stimFrames=1:numStimFrames;
                    firstFramePerStimInd=~[0 diff(spikeRecord.stimInds)==0];
                    correctedFrameIndices=spikeRecord.correctedFrameIndices(firstFramePerStimInd);
                end

                %CHOOSE CLUSTER
                allSpikes=spikeRecord.spikes; %all waveforms
                allSpikeWaveforms = spikeRecord.spikeWaveforms;
                waveInds=allSpikes; % location of all waveforms
                thisCluster = (spikeRecord.processedClusters==1);
                %     if isstruct(spikeRecord.spikeDetails) && ismember({'processedClusters'},fields(spikeRecord.spikeDetails))
                %         if length([spikeRecord.spikeDetails.processedClusters])~=length(waveInds)
                %             length([spikeRecord.spikeDetails.processedClusters])
                %             length(waveInds)
                %             error('spikeDetails does not correspond to the spikeRecord''s spikes');
                %         end
                %         thisCluster=[spikeRecord.spikeDetails.processedClusters]==1;
                %     else
                %         thisCluster=logical(ones(size(waveInds)));
                %         %use all (photodiode uses this)
                %     end
                allSpikes(~thisCluster)=[]; % remove spikes that dont belong to thisCluster
                relevantSpikeWaveforms = allSpikeWaveforms(thisCluster,:);

                %% logic for subsampling
                if parameters.subSampleSpikes
                    oldSeed=rand('twister');
                    seedVal =sum(100*clock);
                    rand('twister',seedVal);
                    p = parameters.subSampleProb;
                    whichSubSample = rand(1,length(allSpikes))<p;
                    allSpikes = allSpikes(whichSubSample);
                    relevantSpikeWaveforms = relevantSpikeWaveforms(find(whichSubSample),:);
                    rand('twister',oldSeed);
                end

                % timeWindowMs
                timeWindowMsStim=[300 50]; % parameter [300 50]
                timeWindowMsLFP =[1000 1000];
                % refreshRate - try to retrieve from neuralRecord (passed from stim computer)
                if isfield(parameters, 'refreshRate')
                    refreshRate = parameters.refreshRate;
                else
                    error('dont use default refreshRate');
                    refreshRate = 100;
                end

                % calculate the number of frames in the window for each spike
                timeWindowFramesStim=ceil(timeWindowMsStim*(refreshRate/1000));

                if (ischar(stimulusDetails.strategy) && strcmp(stimulusDetails.strategy,'expert')) || ...
                        (exist('fieldsInLUT','var') && ismember('stimDetails.strategy',fieldsInLUT) && strcmp(LUTlookup(sessionLUT,stimulusDetails.strategy),'expert'))
                    seeds=stimulusDetails.seedValues;
                    spatialDim = stimulusDetails.spatialDim;

                    if isfield(stimulusDetails,'distribution')
                        switch stimulusDetails.distribution.type
                            case 'gaussian'
                                stdev = stimulusDetails.distribution.std;
                                meanLuminance = stimulusDetails.distribution.meanLuminance;
                            case 'binary'
                                p=stimulusDetails.distribution.probability;
                                hiLoDiff=(stimulusDetails.distribution.hiVal-stimulusDetails.distribution.lowVal);
                                stdev=hiLoDiff*p*(1-p);
                                meanLuminance=(p*stimulusDetails.distribution.hiVal)+((1-p)*stimulusDetails.distribution.lowVal);
                        end
                    else
                        error('dont use old convention for whiteNoise');
                        %old convention prior to april 17th, 2009
                        %stimulusDetails.distribution.type='gaussian';
                        %stdev = stimulusDetails.std;
                        %meanLuminance = stimulusDetails.meanLuminance;
                    end
                end
                height=stimulusDetails.height;
                width=stimulusDetails.width;
                whiteV=whiteVal(stimManager);
                meanValue=whiteV*meanLuminance;

                % stimData is the entire movie shown for this trialwhichSubSample
                % removed 1/26/09 and replaced with stimulusDetailswhichSubSample
                % reconstruct stimData from stimulusDetails - stimManager specific method
                stimData=nan(spatialDim(2),spatialDim(1),length(stimFrames));
                for i=1:length(stimFrames)

                    %recompute stim - note: all sha1ing would have to happen w/o whiteVal and round

                    switch stimulusDetails.distribution.type
                        case 'gaussian'
                            % we only have enough seeds for a single repeat of whiteNoise; if numRepeats>1, need to modulo
                            randn('state',seeds(mod(stimFrames(i)-1,length(seeds))+1));
                            %randn('state',seeds(stimFrames(i)));
                            stixels = round(whiteV*(randn(spatialDim([2 1]))*stdev+meanLuminance));
                            stixels(stixels>whiteV)=whiteV;
                            stixels(stixels<0)=0;
                        case 'binary'
                            rand('state',seeds(mod(stimFrames(i)-1,length(seeds))+1));
                            stixels = round(whiteV* (stimulusDetails.distribution.lowVal+(double(rand(spatialDim([2 1]))<stimulusDetails.distribution.probability)*hiLoDiff)));
                        otherwise
                            error('never')
                    end

                    %stixels=randn(spatialDim);  % for test only
                    % =======================================================
                    % method 1 - resize the movie frame to full pixel size
                    % for each stixel row, expand it to a full pixel row
                    %                         for stRow=1:size(stixels,1)
                    %                             pxRow=[];
                    %                             for stCol=1:size(stixels,2) % for each column stixel, repmat it to width/spatialDim
                    %                                 pxRow(end+1:end+factor) = repmat(stixels(stRow,stCol), [1 factor]);
                    %                             end
                    %                             % now repmat pxRow vertically in stimData
                    %                             stimData(factor*(stRow-1)+1:factor*stRow,:,i) = repmat(pxRow, [factor 1]);
                    %                         end
                    %                         % reset variables
                    %                         pxRow=[];
                    % =======================================================
                    % method 2 - leave stimData in stixel size
                    stimData(:,:,i) = stixels;


                    % =======================================================
                end

                if any(isnan(stimData))
                    error('missed a frame in reconstruction')
                end

                %Check num stim frames makes sense
                if size(spikeRecord.correctedFrameIndices,1)~=size(stimData,3)
                    calculatedNumberOfFrames = size(spikeRecord.correctedFrameIndices,1)
                    storedNumberOfFrames = size(stimData,3)
                    error('the number of frame start/stop times does not match the number of movie frames');
                end

                % details fpr milliSecondPrecision
                if parameters.milliSecondPrecision
                    if parameters.pixelOfInterest(1)>spatialDim(2) || parameters.pixelOfInterest(2)>spatialDim(1)
                        error('cannot look at a pixel greater than the given spatial dimension of stim');
                    end
                    selectedStim = squeeze(stimData(parameters.pixelOfInterest(1),parameters.pixelOfInterest(2),:));
                end
                analysisdata=[];
                % figure out safe "piece" size based on spatialDim and timeWindowFramesStim
                % we only need to reduce the size of spikeswhichSubSample
                switch parameters.milliSecondPrecision
                    case false
                        maxSpikes=floor(10000000/(spatialDim(1)*spatialDim(2)*sum(timeWindowFramesStim))); % equiv to 100 spikes at 64x64 spatial dim, 36 frame window
                        starts=[1:maxSpikes:length(allSpikes) length(allSpikes)+1];
                        for piece=1:(length(starts)-1)
                            spikes=allSpikes(starts(piece):(starts(piece+1)-1));
                            % count the number of spikes per frame
                            % spikeCount is a 1xn vector of (number of spikes per frame), where n = number of frames
                            spikeCount=zeros(1,size(correctedFrameIndices,1));
                            for i=1:length(spikeCount) % for each frame
                                spikeCount(i)=length(find(spikes>=correctedFrameIndices(i,1)&spikes<=correctedFrameIndices(i,2)));
                                %     spikeCount(i)=sum(spikes(spikeRecord.correctedFrameIndices(i,1):spikeRecord.correctedFrameIndices(i,2)));  % inclusive?  policy: include start & stop
                            end


                            %figure out which spikes to use based on eyeData
                            if ~isempty(eyeData)
                                [px py crx cry eyeTime]=getPxyCRxy(eyeData);
                                eyeSig=[crx-px cry-py];
                                if length(unique(eyeSig(:,1)))>10 % if at least 10 x-positions
                                    regionBoundsXY=[.5 .5]; % these are CRX-PY bounds of unknown degrees
                                    minMaxFractionExcluded=0.05;
                                    [within ellipses]=selectDenseEyeRegions(eyeSig,1,regionBoundsXY,minMaxFractionExcluded);
                                    % currently only look at frames in which each sample was within bounds (conservative)
                                    %framesEyeSamples=unique(eyeData.eyeDataFrameInds);  % this is not every frame!
                                    framesSomeEyeWithin=unique(eyeData.eyeDataFrameInds(within));  % at least one sable within
                                    framesSomeEyeNotIn=unique(eyeData.eyeDataFrameInds(~within));  % at least one smple without
                                    framesAllEyeWithin=setdiff(framesSomeEyeWithin,framesSomeEyeNotIn);

                                end
                            end

                            % grab the window for each spike, and store into triggers
                            % triggers is a 4-d matrix:
                            % each 3d element is a movie corresponding to the spike (4th dim)
                            numSpikingFrames=sum(spikeCount>0);
                            numSpikes = sum(spikeCount);
                            triggerInd = 1;
                            % triggers = zeros(stim_width, stim_height, # of window frames per spike, number of spikes)
                            %initialize trigger with mean values for temporal border padding

                            try
                                triggers=meanValue(ones(size(stimData,1),size(stimData,2),sum(timeWindowFramesStim)+1,numSpikes)); % +1 is for the frame that is on the spike
                            catch ex
                                disp(['CAUGHT EX (in whiteNoise.physAnalysis):' getReport(ex)]);
                                memory
                                keyboard
                            end
                            for i=find(spikeCount>0) % for each index that has spikes
                                %every frame with a spike count, gets included... it is multiplied by the number of spikes in that window
                                framesBefore = timeWindowFramesStim(1);
                                framesAfter = timeWindowFramesStim(2);
                                % border handling (if spike was in first frame, cant get any framesBefore)
                                if i-framesBefore <= 0
                                    framesBefore = i-1;
                                end
                                if i+framesAfter > size(stimData,3)
                                    framesAfter = size(stimData,3) - i - 1;
                                end
                                % and in a stim trigger for each spike
                                triggers(:,:,1:framesBefore+framesAfter+1,triggerInd:(triggerInd+spikeCount(i)-1))= ...
                                    repmat(stimData(:,:,[i-framesBefore:i+framesAfter]),[1 1 1 spikeCount(i)]); % pad for border handling?
                                triggerInd = triggerInd+spikeCount(i);
                            end


                            % spike triggered average
                            STA=mean(triggers,4);    %the mean over instances of the trigger
                            try
                                STV=var(triggers,0,4);  %the variance over instances of the trigger (not covariance!)
                                % this is not the "unbiased variance" but the second moment of the sample about its mean
                            catch ex
                                getReport(ex); % common place to run out of memory
                                STV=nan(size(STA)); % thus no confidence will be reported
                            end


                            % fill in partialdata with new values
                            partialdata=[];
                            partialdata.STA = STA;
                            partialdata.STV = STV;
                            partialdata.numSpikes = numSpikes;
                            partialdata.trialNumber=parameters.trialNumber;
                            partialdata.chunkID=parameters.chunkID;
                            partialdata.spikeWaveforms = relevantSpikeWaveforms;
                            partialdata.stimInfo = stimulusDetails;
                            partialdata.timeWindowMsStim = timeWindowMsStim;
                            partialdata.timeWindowMsLFP = timeWindowMsLFP;
                            partialdata.refreshRate =  refreshRate;
                            partialdata.std = stdev;
                            partialdata.meanLuminance = meanLuminance;
                            if isempty(analysisdata) %first piece
                                analysisdata=partialdata;
                            else % not the first piece of analysisdata
                                [analysisdata] = updateAnalysis(analysisdata,partialdata);
                            end

                        end %loop over safe "pieces"
                    case true

                        timeWidowAtGivenPrecision = timeWindowMsStim/parameters.precisionInMS;
                        try
                            triggers = nan(length(allSpikes),sum(timeWidowAtGivenPrecision)+1);
                        catch ex
                            disp(['CAUGHT EX (in whiteNoise.physAnalysis):' getReport(ex)]);
                            memory
                            keyboard
                        end
                        % bin stim to the required precision
                        % the recording happened all the way upto correctedFrameIndices(end,2)
                        sampledStim = nan(1,ceil(correctedFrameIndices(end,2)*1000*parameters.precisionInMS/parameters.samplingRate));
                        for i = 1:size(correctedFrameIndices,1)
                            % find corresponding index into the sampledStim
                            which = ceil(correctedFrameIndices(i,1)*1000*parameters.precisionInMS/parameters.samplingRate):...
                                ceil(correctedFrameIndices(i,2)*1000*parameters.precisionInMS/parameters.samplingRate);
                            sampledStim(which) = selectedStim(i);
                        end

                        for i = 1:length(allSpikes)
                            ind = ceil(allSpikes(i)*1000*parameters.precisionInMS/parameters.samplingRate);
                            ind = (ind-timeWidowAtGivenPrecision(1)):(ind+timeWidowAtGivenPrecision(2));
                            if any(ind<=0|ind>length(sampledStim))
                                continue; % reject all inappropriate spikes
                            end
                            triggers(i,:) = sampledStim(ind);
                        end

                        [r c] = find(isnan(triggers)); % remove the nans
                        triggers(unique(r),:) = [];
                        STA = mean(triggers,1);
                        STV = var(triggers,0,1);
                        numSpikes = size(triggers,1);

                        partialdata=[];
                        partialdata.STA = STA;
                        partialdata.STV = STV;
                        partialdata.numSpikes = numSpikes;
                        partialdata.trialNumber=parameters.trialNumber;
                        partialdata.chunkID=parameters.chunkID;
                        partialdata.spikeWaveforms = relevantSpikeWaveforms;
                        partialdata.stimInfo = stimulusDetails;
                        partialdata.timeWindowMsStim = timeWindowMsStim;
                        partialdata.timeWindowMsLFP = timeWindowMsLFP;
                        partialdata.refreshRate =  refreshRate;
                        partialdata.std = stdev;
                        partialdata.meanLuminance = meanLuminance;
                        if isempty(analysisdata) %first piece
                            analysisdata=partialdata;
                        else % not the first piece of analysisdata
                            [analysisdata] = updateAnalysis(analysisdata,partialdata);
                        end

                end

                % now get the spikeTriggeredLFPs
                try
                    %LFPs = zeros(length(spikes),ceil((sum(timeWindowMsLFP)/1000)*mean(LFPRecord.LFPSamplingRateHz)),size(LFPRecord.data,2));
                catch ex
                    getReport(ex)
                    memory
                    keyboard
                end

                processedSpikeTimeStamps = spikeRecord.spikeTimestamps(thisCluster);
                unprocessedSpikeNum = [];
                %     for currSpikeNum = 1:length(spikes)
                %         currTimeStamp = processedSpikeTimeStamps(currSpikeNum);
                %         if ((currTimeStamp-(timeWindowMsLFP(1)/1000))<min(spikeRecord.spikeTimestamps))...
                %                 ||((currTimeStamp+(timeWindowMsLFP(2)/1000))>max(spikeRecord.spikeTimestamps))
                %             % only process those LFP samples where you are guaranteed that
                %             % the neural signal exists in the LFPRecord for that chunk!
                %             unprocessedSpikeNum = [unprocessedSpikeNum currSpikeNum];
                %
                %         else
                %             relevantLFPRecord = LFPRecord.data((LFPRecord.dataTimes>(currTimeStamp-(timeWindowMsLFP(1)/1000)))&...
                %                 (LFPRecord.dataTimes<(currTimeStamp+(timeWindowMsLFP(2)/1000))),:);
                %             LFPs(currSpikeNum,:,:) = resample(relevantLFPRecord,ceil((sum(timeWindowMsLFP)/1000)*mean(LFPRecord.LFPSamplingRateHz)),...
                %                 length(relevantLFPRecord));
                %         end
                %     end
                %     LFPs(unprocessedSpikeNum,:,:) = [];
                %     ST_LFPA = mean(LFPs,1);
                %     ST_LFPV = var(LFPs,0,1);
                %     numSpikesForLFP = size(LFPs,1);


                % now we should have our analysisdata for all "pieces"
                % if the cumulative values don't exist (first analysis)
                % 6/23/09 fli - why do we always do this first thing instead of checking for cumulative values???
                % sometimes empty... think about : isempty(cumulativedata) ||


                if isempty(allSpikes) && ~parameters.milliSecondPrecision
                    analysisdata.STA=meanValue(ones(size(stimData,1),size(stimData,2),sum(timeWindowFramesStim)+1));
                    analysisdata.STV=zeros(size(analysisdata.STA));
                    analysisdata.numSpikes=0;
                    analysisdata.trialNumber = parameters.trialNumber;
                    analysisdata.chunkID = parameters.chunkID;
                    analysisdata.stimInfo = stimulusDetails;
                elseif isempty(allSpikes) && parameters.milliSecondPrecision
                    analysisdata.STA=meanValue(ones(size(STA)));
                    analysisdata.STV=zeros(size(analysisdata.STA));
                    analysisdata.numSpikes=0;
                    analysisdata.trialNumber = parameters.trialNumber;
                    analysisdata.chunkID = parameters.chunkID;
                    analysisdata.stimInfo = stimulusDetails;
                end

                try
                    x=isempty(cumulativedata) || ~isfield(cumulativedata, 'cumulativeSTA')  || ~all(size(analysisdata.STA)==size(cumulativedata.cumulativeSTA)); %first trial through with these parameters
                catch
                    warning('here')
                    keyboard
                end

                if  isempty(cumulativedata) || ~isfield(cumulativedata, 'cumulativeSTA')  || ~all(size(analysisdata.STA)==size(cumulativedata.cumulativeSTA)) %first trial through with these parameters
                    cumulativedata=[];
                    cumulativedata.cumulativeSTA = analysisdata.STA;
                    cumulativedata.cumulativeSTV = analysisdata.STV;
                    cumulativedata.timeWindowMsStim = analysisdata.timeWindowMsStim;
                    cumulativedata.timeWindowMsLFP = analysisdata.timeWindowMsLFP;
                    cumulativedata.cumulativeNumSpikes = analysisdata.numSpikes;
                    if analysisdata.numSpikes
                        cumulativedata.cumulativeSpikeWaveforms = analysisdata.spikeWaveforms;
                    else
                        cumulativedata.cumulativeSpikeWaveforms = [];
                    end
                    cumulativedata.cumulativeTrialNumbers=parameters.trialNumber;
                    cumulativedata.cumulativeChunkIDs=parameters.chunkID;
                    cumulativedata.stimInfo = analysisdata.stimInfo;
                    cumulativedata.stimInfo.refreshRate = analysisdata.refreshRate;

                    %cumulativedata.cumulativeST_LFPA = ST_LFPA;
                    %cumulativedata.cumulativeST_LFPV = ST_LFPV;
                    %cumulativedata.numSpikesForLFP = numSpikesForLFP;
                    analysisdata.singleChunkTemporalRecord=[];
                    addSingleTrial=true;
                elseif isempty(find(parameters.trialNumber==cumulativedata.cumulativeTrialNumbers&...
                        parameters.chunkID==cumulativedata.cumulativeChunkIDs))
                    cumulativedata = updateCumulative(cumulativedata,analysisdata);
                    %only for new trials or new chunks
                    %         [cumulativedata.cumulativeSTA cumulativedata.cumulativeSTV cumulativedata.cumulativeNumSpikes ...
                    %             cumulativedata.cumulativeTrialNumbers cumulativedata.cumulativeChunkIDs] = ... %% cumulativedata.cumulativeST_LFPA ...
                    %             ...cumulativedata.cumulativeST_LFPV cumulativedata.numSpikesForLFP] = ...
                    %             updateCumulative(cumulativedata.cumulativeSTA,cumulativedata.cumulativeSTV,cumulativedata.cumulativeNumSpikes,...
                    %             cumulativedata.cumulativeTrialNumbers,cumulativedata.cumulativeChunkIDs,...,cumulativedata.cumulativeST_LFPA,...
                    %             1,1,1,...%cumulativedata.cumulativeST_LFPV, cumulativedata.numSpikesForLFP,...
                    %             analysisdata.STA,analysisdata.STV,analysisdata.numSpikes,...
                    %             analysisdata.trialNumber,analysisdata.chunkID,1,1,1); %ST_LFPA,ST_LFPV,numSpikesForLFP);

                    addSingleTrial=true;
                else % repeat sweep through same trial
                    %do nothing
                    addSingleTrial=false;
                end

                if addSingleTrial
                    %this trial..history of bright ones saved
                    analysisdata.singleChunkTemporalRecord(1,:)=...
                        getTemporalSignal(analysisdata.STA,analysisdata.STV,analysisdata.numSpikes,'bright');
                end
                cumulativedata.lastAnalysis = analysisdata;
        end




        function new=hasNewParameters(stimManager,analysisdata,stimulusDetails) %first trial through with these parameters
            new=false;

            %different size
            if  ~all(size(analysisdata.STA)==size(analysisdata.cumulativeSTA))
                new=true;
            end

            %different distribution
            if ~strcmp(analysisdata.distribution.type,stimulusDetails.distribution.type)
                new=true;
            end

            %different parameters - a pretty general check of the params
            if ~new % only  check if they are the same distribution
                f=fields(stimulusDetails.distribution);
                numFields=length(f);
                %check all numverical parameters (note for future: won't work for uneven vector lengths or strings)
                for i=2:numFields; % skip type i=1
                    if ~all(stimulusDetails.distribution.(f{i})==analysisdata.distribution.(f{i}))
                        new=true;
                    end
                end
            end
        end

        % function [cSTA cSTV cNumSpikes cSpikeWaveforms cTrialNumbers cChunkIDs cST_LFPA cST_LFPV cNumSpikesForLFP] = updateCumulative(cSTA,cSTV,...
        %     cNumSpikes,cSpikeWaveforms,cTrialNumbers,cChunkIDs,cST_LFPA,cST_LFPV,cNumSpikesForLFP,STA,STV,numSpikes,trialNumbers,chunkID,ST_LFPA,...
        %     ST_LFPV,numSpikesForLFP)
        function cumulative = updateAnalysis(cumulative,partial)
            fieldsInPartial = {'STA','STV','numSpikes','spikeWaveforms','trialNumber','chunkID','ST_LFPA','ST_LFPV','numSpikesForLFP','timeWindowMsStim','timeWindowMsLFP','refreshRate','std','meanLuminance'};
            fieldsInCumulative = {'STA','STV','numSpikes','spikeWaveforms','trialNumber',...
                'chunkID','ST_LFPA','ST_LFPV','numSpikesForLFP','timeWindowMsStim','timeWindowMsStim','refreshRate','std','meanLuminance'};

            fieldsThatGetUpdated = {'STA','STV','ST_LFPA','ST_LFPV'};
            fieldsThatGetStackedOn = {'spikeWaveforms','trialNumber','chunkID'};
            fieldsThatGetSummed = {'numSpikes','numSpikesForLFP'};
            fieldsThatAreSetOnce = {'timeWindowMsStim','timeWindowMsLFP','refreshRate','std','meanLuminance'};

            for currField = fieldsInPartial
                if isfield(partial,currField{:})
                    if any(strcmp(currField,fieldsThatGetUpdated)) && ~any(isnan(partial.(currField{:})(:))) && (cumulative.numSpikes+partial.numSpikes)
                        index = find(strcmp(currField,fieldsInPartial));
                        cumulative.(fieldsInCumulative{index}) = ...
                            (cumulative.(fieldsInCumulative{index})*cumulative.numSpikes + ...
                            partial.(fieldsInPartial{index})*partial.numSpikes)/(cumulative.numSpikes+partial.numSpikes);
                    end
                    if any(strcmp(currField,fieldsThatGetStackedOn)) && ~any(isnan(partial.(currField{:})(:)))
                        index = find(strcmp(currField,fieldsInPartial));
                        cumulative.(fieldsInCumulative{index}) = ...
                            [cumulative.(fieldsInCumulative{index});partial.(fieldsInPartial{index})];
                    end
                    if any(strcmp(currField,fieldsThatGetSummed)) && ~any(isnan(partial.(currField{:})(:)))
                        index = find(strcmp(currField,fieldsInPartial));
                        cumulative.(fieldsInCumulative{index}) = ...
                            cumulative.(fieldsInCumulative{index})+ partial.(fieldsInPartial{index});
                    end
                    if any(strcmp(currField,fieldsThatAreSetOnce)) && ~isfield(cumulative,currField{:})
                        index = find(strcmp(currField,fieldsInPartial));
                        cumulative.(fieldsInCumulative{index}) = partial.(fieldsInPartial{index});
                    end
                end
            end
        end


        function cumulative = updateCumulative(cumulative,partial)

            fieldsInPartial = {'STA','STV','numSpikes','spikeWaveforms','trialNumber','chunkID','ST_LFPA','ST_LFPV','numSpikesForLFP','timeWindowMsStim','timeWindowMsLFP','refreshRate','std','meanLuminance'};
            fieldsInCumulative = {'cumulativeSTA','cumulativeSTV','cumulativeNumSpikes','cumulativeSpikeWaveforms','cumulativeTrialNumbers',...
                'cumulativeChunkIDs','cumulativeST_LFPA','cumulativeST_LFPV','cumulativeNumSpikesForLFP','timeWindowMsStim','timeWindowMsLFP','refreshRate','std','meanLuminance'};

            fieldsThatGetUpdated = {'STA','STV','ST_LFPA','ST_LFPV'};
            fieldsThatGetStackedOn = {'spikeWaveforms','trialNumber','chunkID'};
            fieldsThatGetSummed = {'numSpikes','numSpikesForLFP'};
            fieldsThatAreSetOnce = {'timeWindowMsStim','timeWindowMsLFP','refreshRate','std','meanLuminance'};

            for currField = fieldsInPartial
                if isfield(partial,currField{:})
                    if any(strcmp(currField,fieldsThatGetUpdated)) && ~any(isnan(partial.(currField{:})(:))) && (cumulative.cumulativeNumSpikes+partial.numSpikes)
                        index = find(strcmp(currField,fieldsInPartial));
                        cumulative.(fieldsInCumulative{index}) = ...
                            (cumulative.(fieldsInCumulative{index})*cumulative.cumulativeNumSpikes + ...
                            partial.(fieldsInPartial{index})*partial.numSpikes)/(cumulative.cumulativeNumSpikes+partial.numSpikes);
                    end
                    if any(strcmp(currField,fieldsThatGetStackedOn)) && ~any(isnan(partial.(currField{:})(:)))
                        index = find(strcmp(currField,fieldsInPartial));
                        cumulative.(fieldsInCumulative{index}) = ...
                            [cumulative.(fieldsInCumulative{index});partial.(fieldsInPartial{index})];
                    end
                    if any(strcmp(currField,fieldsThatGetSummed)) && ~any(isnan(partial.(currField{:})(:)))
                        index = find(strcmp(currField,fieldsInPartial));
                        cumulative.(fieldsInCumulative{index}) = ...
                            cumulative.(fieldsInCumulative{index})+ partial.(fieldsInPartial{index});
                    end
                    if any(strcmp(currField,fieldsThatAreSetOnce)) && ~isfield(cumulative,currField{:})
                        index = find(strcmp(currField,fieldsInPartial));
                        cumulative.(fieldsInCumulative{index}) = partial.(fieldsInPartial{index});
                    end
                end
            end


            % % only update the cumulatives if the partials are NOT nan (arithmetic w/ nans wipes out any valid numbers)
            % if ~any(isnan(STA(:)))
            %     cSTA=(cSTA*cNumSpikes + STA*numSpikes) / (cNumSpikes + numSpikes);
            % else
            %     warning('found NaNs in partial STA - did not update cumulative STA')
            % end
            % if ~any(isnan(STV(:)))
            %     cSTV=(cSTV*cNumSpikes + STV*numSpikes) / (cNumSpikes + numSpikes);
            % else
            %     warning('found NaNs in partial STV - did not update cumulative STV');
            % end
            %
            % if exist('cST_LFPA','var') % updateCumulative is also used for piece-wise data
            %     if ~any(isnan(ST_LFPA(:)))
            %         cST_LFPA=(cST_LFPA*cNumSpikesForLFP + ST_LFPA*numSpikesForLFP) / (cNumSpikesForLFP + numSpikesForLFP);
            %     else
            %         warning('found NaNs in partial cST_LFPA - did not update cumulative ST_LFPA')
            %     end
            %     if ~any(isnan(ST_LFPV(:)))
            %         cST_LFPV=(cST_LFPV*cNumSpikesForLFP + ST_LFPV*numSpikesForLFP) / (cNumSpikesForLFP + numSpikesForLFP);
            %     else
            %         warning('found NaNs in partial ST_LFPV - did not update cumulative ST_LFPV');
            %     end
            %     cNumSpikesForLFP = cNumSpikesForLFP + numSpikesForLFP;
            % else
            %     cST_LFPA = [];
            %     cST_LFPV = [];
            %     cNumSpikesForLFP = [];
            % end
            %
            % cNumSpikes=cNumSpikes + numSpikes;
            % cTrialNumbers=[cTrialNumbers trialNumbers];
            % cChunkIDs=[cChunkIDs chunkID];
        end
        
        function [analysisdata cumulativedata] = physAnalysisPlots(stimManager,spikeRecord,stimulusDetails,plotParameters,parameters,cumulativedata,eyeData,LFPRecord)
            % stimManager is the stimulus manager
            % spikes is a logical vector of size (number of neural data samples), where 1 represents a spike happening
            % correctedFrameIndices is an nx2 array of frame start and stop indices - [start stop], n = number of frames
            % stimulusDetails are the stimDetails from calcStim (hopefully they contain all the information needed to reconstruct stimData)
            % photoDiode - currently not used
            % plotParameters - currently not used
            % 4/17/09 - spikeRecord contains all the data from this ENTIRE trial, but we should only do analysis on the current chunk
            % to prevent memory problems
                % only analyze currentChunk's data for spikes
                which=find(spikeRecord.chunkIDForDetectedSpikes==spikeRecord.currentChunk);
                % get the relevant spikes
                spikeRecord.spikes=spikeRecord.spikes(which);
                spikeRecord.spikeTimestamps=spikeRecord.spikeTimestamps(which);
                spikeRecord.spikeWaveforms=spikeRecord.spikeWaveforms(which,:);
                spikeRecord.assignedClusters=spikeRecord.assignedClusters(which,:);
                spikeRecord.processedClusters = spikeRecord.processedClusters(which);
                spikeRecord.chunkIDForDetectedSpikes=spikeRecord.chunkIDForDetectedSpikes(which);

                % only analyze currentChunk's data for corrected Frames
                which=find(spikeRecord.chunkIDForCorrectedFrames==spikeRecord.currentChunk);
                spikeRecord.correctedFrameIndices=spikeRecord.correctedFrameIndices(which,:);
                spikeRecord.stimInds=spikeRecord.stimInds(which);
                %spikeRecord.photoDiode=spikeRecord.photoDiode(which);  % HACK! we need this, right?

                % this part is no longer necessary as "spikeDetails is removewhichSubSampled from all analyses
                %     which=find(spikeRecord.chunkID==spikeRecord.currentChunk);
                %     spikeRecord.spikeDetails=spikeRecord.spikeDetails(which);

                if size(spikeRecord.correctedFrameIndices,1)==0 || size(spikeRecord.spikes,1)==0
                    %if this chunk has either no spikes or no stim frames, then return the cumulative data as is
                    analysisdata=[];
                    cumulativedata=cumulativedata;
                    warning(sprintf('skipping white noise analysis for trial %d chunk %d because there are %d stim frames and %d spikes',...
                        parameters.trialNumber,spikeRecord.currentChunk,size(spikeRecord.correctedFrameIndices,1),size(spikeRecord.spikes,1)))
                    return
                end

                %SET UP RELATION stimInd <--> frameInd
                analyzeDrops=true;
                if analyzeDrops
                    stimFrames=spikeRecord.stimInds;
                    correctedFrameIndices=spikeRecord.correctedFrameIndices;
                else
                    numStimFrames=max(spikeRecord.stimInds);
                    stimFrames=1:numStimFrames;
                    firstFramePerStimInd=~[0 diff(spikeRecord.stimInds)==0];
                    correctedFrameIndices=spikeRecord.correctedFrameIndices(firstFramePerStimInd);
                end

                %CHOOSE CLUSTER
                allSpikes=spikeRecord.spikes; %all waveforms
                allSpikeWaveforms = spikeRecord.spikeWaveforms;
                waveInds=allSpikes; % location of all waveforms
                thisCluster = (spikeRecord.processedClusters==1);
                %     if isstruct(spikeRecord.spikeDetails) && ismember({'processedClusters'},fields(spikeRecord.spikeDetails))
                %         if length([spikeRecord.spikeDetails.processedClusters])~=length(waveInds)
                %             length([spikeRecord.spikeDetails.processedClusters])
                %             length(waveInds)
                %             error('spikeDetails does not correspond to the spikeRecord''s spikes');
                %         end
                %         thisCluster=[spikeRecord.spikeDetails.processedClusters]==1;
                %     else
                %         thisCluster=logical(ones(size(waveInds)));
                %         %use all (photodiode uses this)
                %     end
                allSpikes(~thisCluster)=[]; % remove spikes that dont belong to thisCluster
                relevantSpikeWaveforms = allSpikeWaveforms(thisCluster,:);

                %% logic for subsampling
                if parameters.subSampleSpikes
                    oldSeed=rand('twister');
                    seedVal =sum(100*clock);
                    rand('twister',seedVal);
                    p = parameters.subSampleProb;
                    whichSubSample = rand(1,length(allSpikes))<p;
                    allSpikes = allSpikes(whichSubSample);
                    relevantSpikeWaveforms = relevantSpikeWaveforms(find(whichSubSample),:);
                    rand('twister',oldSeed);
                end

                % xtra user paramss
                spatialSmoothingOn=true;
                doSTC=false;
                xtraPlot={'spaceTimeContext'}; % eyes, spaceTimeContext, montage

                % timeWindowMs
                timeWindowMsStim=[300 50]; % parameter [300 50]
                timeWindowMsLFP =[1000 1000];
                % refreshRate - try to retrieve from neuralRecord (passed from stim computer)
                if isfield(parameters, 'refreshRate')
                    refreshRate = parameters.refreshRate;
                else
                    error('dont use default refreshRate');
                    refreshRate = 100;
                end

                % calculate the number of frames in the window for each spike
                timeWindowFramesStim=ceil(timeWindowMsStim*(refreshRate/1000));

                if spatialSmoothingOn
                    filt=... a mini gaussian like fspecial('gaussian')
                        [0.0113  0.0838  0.0113;
                        0.0838  0.6193  0.0838;
                        0.0113  0.0838  0.0113];
                end

                if (ischar(stimulusDetails.strategy) && strcmp(stimulusDetails.strategy,'expert')) || ...
                        (exist('fieldsInLUT','var') && ismember('stimDetails.strategy',fieldsInLUT) && strcmp(LUTlookup(sessionLUT,stimulusDetails.strategy),'expert'))
                    seeds=stimulusDetails.seedValues;
                    spatialDim = stimulusDetails.spatialDim;

                    if isfield(stimulusDetails,'distribution')
                        switch stimulusDetails.distribution.type
                            case 'gaussian'
                                std = stimulusDetails.distribution.std;
                                meanLuminance = stimulusDetails.distribution.meanLuminance;
                            case 'binary'
                                p=stimulusDetails.distribution.probability;
                                hiLoDiff=(stimulusDetails.distribution.hiVal-stimulusDetails.distribution.lowVal);
                                std=hiLoDiff*p*(1-p);
                                meanLuminance=(p*stimulusDetails.distribution.hiVal)+((1-p)*stimulusDetails.distribution.lowVal);
                        end
                    else
                        error('dont use old convention for whiteNoise');
                        %old convention prior to april 17th, 2009
                        %stimulusDetails.distribution.type='gaussian';
                        %std = stimulusDetails.std;
                        %meanLuminance = stimulusDetails.meanLuminance;
                    end
                end
                height=stimulusDetails.height;
                width=stimulusDetails.width;
                whiteV=whiteVal(stimManager);
                meanValue=whiteV*meanLuminance;

                % stimData is the entire movie shown for this trialwhichSubSample
                % removed 1/26/09 and replaced with stimulusDetailswhichSubSample
                % reconstruct stimData from stimulusDetails - stimManager specific method
                stimData=nan(spatialDim(2),spatialDim(1),length(stimFrames));
                for i=1:length(stimFrames)

                    %recompute stim - note: all sha1ing would have to happen w/o whiteVal and round

                    switch stimulusDetails.distribution.type
                        case 'gaussian'
                            % we only have enough seeds for a single repeat of whiteNoise; if numRepeats>1, need to modulo
                            randn('state',seeds(mod(stimFrames(i)-1,length(seeds))+1));
                            %randn('state',seeds(stimFrames(i)));
                            stixels = round(whiteV*(randn(spatialDim([2 1]))*std+meanLuminance));
                            stixels(stixels>whiteV)=whiteV;
                            stixels(stixels<0)=0;
                        case 'binary'
                            rand('state',seeds(mod(stimFrames(i)-1,length(seeds))+1));
                            stixels = round(whiteV* (stimulusDetails.distribution.lowVal+(double(rand(spatialDim([2 1]))<stimulusDetails.distribution.probability)*hiLoDiff)));
                        otherwise
                            error('never')
                    end

                    %stixels=randn(spatialDim);  % for test only
                    % =======================================================
                    % method 1 - resize the movie frame to full pixel size
                    % for each stixel row, expand it to a full pixel row
                    %                         for stRow=1:size(stixels,1)
                    %                             pxRow=[];
                    %                             for stCol=1:size(stixels,2) % for each column stixel, repmat it to width/spatialDim
                    %                                 pxRow(end+1:end+factor) = repmat(stixels(stRow,stCol), [1 factor]);
                    %                             end
                    %                             % now repmat pxRow vertically in stimData
                    %                             stimData(factor*(stRow-1)+1:factor*stRow,:,i) = repmat(pxRow, [factor 1]);
                    %                         end
                    %                         % reset variables
                    %                         pxRow=[];
                    % =======================================================
                    % method 2 - leave stimData in stixel size
                    stimData(:,:,i) = stixels;


                    % =======================================================
                end

                if any(isnan(stimData))
                    error('missed a frame in reconstruction')
                end

                %Check num stim frames makes sense
                if size(spikeRecord.correctedFrameIndices,1)~=size(stimData,3)
                    calculatedNumberOfFrames = size(spikeRecord.correctedFrameIndices,1)
                    storedNumberOfFrames = size(stimData,3)
                    error('the number of frame start/stop times does not match the number of movie frames');
                end



                analysisdata=[];
                % figure out safe "piece" size based on spatialDim and timeWindowFramesStim
                % we only need to reduce the size of spikeswhichSubSample
                maxSpikes=floor(10000000/(spatialDim(1)*spatialDim(2)*sum(timeWindowFramesStim))); % equiv to 100 spikes at 64x64 spatial dim, 36 frame window
                starts=[1:maxSpikes:length(allSpikes) length(allSpikes)+1];
                for piece=1:(length(starts)-1)
                    spikes=allSpikes(starts(piece):(starts(piece+1)-1));


                    % count the number of spikes per frame
                    % spikeCount is a 1xn vector of (number of spikes per frame), where n = number of frames

                    spikeCount=zeros(1,size(correctedFrameIndices,1));
                    for i=1:length(spikeCount) % for each frame
                        spikeCount(i)=length(find(spikes>=correctedFrameIndices(i,1)&spikes<=correctedFrameIndices(i,2)));
                        %     spikeCount(i)=sum(spikes(spikeRecord.correctedFrameIndices(i,1):spikeRecord.correctedFrameIndices(i,2)));  % inclusive?  policy: include start & stop
                    end


                    %figure out which spikes to use based on eyeData
                    if ~isempty(eyeData)
                        [px py crx cry eyeTime]=getPxyCRxy(eyeData);
                        eyeSig=[crx-px cry-py];

                        if length(unique(eyeSig(:,1)))>10 % if at least 10 x-positions

                            regionBoundsXY=[.5 .5]; % these are CRX-PY bounds of unknown degrees
                            minMaxFractionExcluded=0.05;
                            [within ellipses]=selectDenseEyeRegions(eyeSig,1,regionBoundsXY,minMaxFractionExcluded);


                            % currently only look at frames in which each sample was within bounds (conservative)
                            %framesEyeSamples=unique(eyeData.eyeDataFrameInds);  % this is not every frame!
                            framesSomeEyeWithin=unique(eyeData.eyeDataFrameInds(within));  % at least one sable within
                            framesSomeEyeNotIn=unique(eyeData.eyeDataFrameInds(~within));  % at least one smple without
                            framesAllEyeWithin=setdiff(framesSomeEyeWithin,framesSomeEyeNotIn);


                            if 0 %remove when eye out of bound and view temporal selected data
                                warning('don''t know if eyeDataFrameInds are the correct values -  need to check frame drops, etc')
                                error('will this account for the chunked spike analysis?')
                                %stimFrameseyeData.eyeDataFrameInds)...?
                                %stimFrames(framesSomeEyeNotIn)...?

                                figure
                                %plot(eyeTime, eyeSig(:,1),'k',eyeTime(within), eyeSig(within,1),'c.')
                                plot(eyeData.eyeDataFrameInds, eyeSig(:,1),'k',eyeData.eyeDataFrameInds(within), eyeSig(within,1),'c.')
                                hold on; plot(stimFrames,spikeCount,'r')

                                spikeCount(framesSomeEyeNotIn)=0;  % need to know if these are stimFramesor Nth frame that occured...
                                plot(stimFrames,spikeCount,'c');
                            end
                        end
                    end

                    % grab the window for each spike, and store into triggers
                    % triggers is a 4-d matrix:
                    % each 3d element is a movie corresponding to the spike (4th dim)
                    numSpikingFrames=sum(spikeCount>0);
                    numSpikes = sum(spikeCount);
                    triggerInd = 1;
                    % triggers = zeros(stim_width, stim_height, # of window frames per spike, number of spikes)
                    %initialize trigger with mean values for temporal border padding


                    try
                        triggers=meanValue(ones(size(stimData,1),size(stimData,2),sum(timeWindowFramesStim)+1,numSpikes)); % +1 is for the frame that is on the spike
                    catch ex
                        disp(['CAUGHT EX (in whiteNoise.physAnalysis):' getReport(ex)]);
                        memory
                        keyboard
                    end
                    for i=find(spikeCount>0) % for each index that has spikes
                        %every frame with a spike count, gets included... it is multiplied by the number of spikes in that window
                        framesBefore = timeWindowFramesStim(1);
                        framesAfter = timeWindowFramesStim(2);
                        % border handling (if spike was in first frame, cant get any framesBefore)
                        if i-framesBefore <= 0
                            framesBefore = i-1;
                        end
                        if i+framesAfter > size(stimData,3)
                            framesAfter = size(stimData,3) - i - 1;
                        end
                        % and in a stim trigger for each spike
                        triggers(:,:,1:framesBefore+framesAfter+1,triggerInd:(triggerInd+spikeCount(i)-1))= ...
                            repmat(stimData(:,:,[i-framesBefore:i+framesAfter]),[1 1 1 spikeCount(i)]); % pad for border handling?
                        triggerInd = triggerInd+spikeCount(i);
                    end


                    % spike triggered average
                    STA=mean(triggers,4);    %the mean over instances of the trigger
                    try
                        STV=var(triggers,0,4);  %the variance over instances of the trigger (not covariance!)
                        % this is not the "unbiased variance" but the second moment of the sample about its mean
                    catch ex
                        getReport(ex); % common place to run out of memory
                        STV=nan(size(STA)); % thus no confidence will be reported
                    end


                    % fill in partialdata with new values
                    partialdata=[];
                    partialdata.STA = STA;
                    partialdata.STV = STV;
                    partialdata.numSpikes = numSpikes;
                    partialdata.trialNumber=parameters.trialNumber;
                    partialdata.chunkID=parameters.chunkID;
                    partialdata.spikeWaveforms = relevantSpikeWaveforms;
                    partialdata.stimInfo = stimulusDetails;
                    partialdata.timeWindowMsStim = timeWindowMsStim;
                    partialdata.timeWindowMsLFP = timeWindowMsLFP;
                    partialdata.refreshRate =  refreshRate;
                    partialdata.std = std;
                    partialdata.meanLuminance = meanLuminance;
                    if isempty(analysisdata) %first piece
                        analysisdata=partialdata;
                    else % not the first piece of analysisdata
                        [analysisdata] = updateAnalysis(analysisdata,partialdata);
                    end

                end %loop over safe "pieces"


                % now get the spikeTriggeredLFPs
                try
                    %LFPs = zeros(length(spikes),ceil((sum(timeWindowMsLFP)/1000)*mean(LFPRecord.LFPSamplingRateHz)),size(LFPRecord.data,2));
                catch ex
                    getReport(ex)
                    memory
                    keyboard
                end

                processedSpikeTimeStamps = spikeRecord.spikeTimestamps(thisCluster);
                unprocessedSpikeNum = [];
                %     for currSpikeNum = 1:length(spikes)
                %         currTimeStamp = processedSpikeTimeStamps(currSpikeNum);
                %         if ((currTimeStamp-(timeWindowMsLFP(1)/1000))<min(spikeRecord.spikeTimestamps))...
                %                 ||((currTimeStamp+(timeWindowMsLFP(2)/1000))>max(spikeRecord.spikeTimestamps))
                %             % only process those LFP samples where you are guaranteed that
                %             % the neural signal exists in the LFPRecord for that chunk!
                %             unprocessedSpikeNum = [unprocessedSpikeNum currSpikeNum];
                %
                %         else
                %             relevantLFPRecord = LFPRecord.data((LFPRecord.dataTimes>(currTimeStamp-(timeWindowMsLFP(1)/1000)))&...
                %                 (LFPRecord.dataTimes<(currTimeStamp+(timeWindowMsLFP(2)/1000))),:);
                %             LFPs(currSpikeNum,:,:) = resample(relevantLFPRecord,ceil((sum(timeWindowMsLFP)/1000)*mean(LFPRecord.LFPSamplingRateHz)),...
                %                 length(relevantLFPRecord));
                %         end
                %     end
                %     LFPs(unprocessedSpikeNum,:,:) = [];
                %     ST_LFPA = mean(LFPs,1);
                %     ST_LFPV = var(LFPs,0,1);
                %     numSpikesForLFP = size(LFPs,1);


                % now we should have our analysisdata for all "pieces"
                % if the cumulative values don't exist (first analysis)
                % 6/23/09 fli - why do we always do this first thing instead of checking for cumulative values???
                % sometimes empty... think about : isempty(cumulativedata) ||


                if isempty(allSpikes)
                    analysisdata.STA=meanValue(ones(size(stimData,1),size(stimData,2),sum(timeWindowFramesStim)+1));
                    analysisdata.STV=zeros(size(analysisdata.STA));
                    analysisdata.numSpikes=0;
                    analysisdata.trialNumber = parameters.trialNumber;
                    analysisdata.chunkID = parameters.chunkID;
                    analysisdata.stimInfo = stimulusDetails;
                end

                try
                    x=isempty(cumulativedata) || ~isfield(cumulativedata, 'cumulativeSTA')  || ~all(size(analysisdata.STA)==size(cumulativedata.cumulativeSTA)); %first trial through with these parameters
                catch
                    warning('here')
                    keyboard
                end

                if  isempty(cumulativedata) || ~isfield(cumulativedata, 'cumulativeSTA')  || ~all(size(analysisdata.STA)==size(cumulativedata.cumulativeSTA)) %first trial through with these parameters
                    cumulativedata=[];
                    cumulativedata.cumulativeSTA = analysisdata.STA;
                    cumulativedata.cumulativeSTV = analysisdata.STV;
                    cumulativedata.timeWindowMsStim = analysisdata.timeWindowMsStim;
                    cumulativedata.timeWindowMsLFP = analysisdata.timeWindowMsLFP;
                    cumulativedata.cumulativeNumSpikes = analysisdata.numSpikes;
                    if analysisdata.numSpikes
                        cumulativedata.cumulativeSpikeWaveforms = analysisdata.spikeWaveforms;
                    else
                        cumulativedata.cumulativeSpikeWaveforms = [];
                    end
                    cumulativedata.cumulativeTrialNumbers=parameters.trialNumber;
                    cumulativedata.cumulativeChunkIDs=parameters.chunkID;
                    cumulativedata.stimInfo = analysisdata.stimInfo;
                    cumulativedata.stimInfo.refreshRate = analysisdata.refreshRate;

                    %cumulativedata.cumulativeST_LFPA = ST_LFPA;
                    %cumulativedata.cumulativeST_LFPV = ST_LFPV;
                    %cumulativedata.numSpikesForLFP = numSpikesForLFP;
                    analysisdata.singleChunkTemporalRecord=[];
                    addSingleTrial=true;
                elseif isempty(find(parameters.trialNumber==cumulativedata.cumulativeTrialNumbers&...
                        parameters.chunkID==cumulativedata.cumulativeChunkIDs))
                    cumulativedata = updateCumulative(cumulativedata,analysisdata);
                    %only for new trials or new chunks
                    %         [cumulativedata.cumulativeSTA cumulativedata.cumulativeSTV cumulativedata.cumulativeNumSpikes ...
                    %             cumulativedata.cumulativeTrialNumbers cumulativedata.cumulativeChunkIDs] = ... %% cumulativedata.cumulativeST_LFPA ...
                    %             ...cumulativedata.cumulativeST_LFPV cumulativedata.numSpikesForLFP] = ...
                    %             updateCumulative(cumulativedata.cumulativeSTA,cumulativedata.cumulativeSTV,cumulativedata.cumulativeNumSpikes,...
                    %             cumulativedata.cumulativeTrialNumbers,cumulativedata.cumulativeChunkIDs,...,cumulativedata.cumulativeST_LFPA,...
                    %             1,1,1,...%cumulativedata.cumulativeST_LFPV, cumulativedata.numSpikesForLFP,...
                    %             analysisdata.STA,analysisdata.STV,analysisdata.numSpikes,...
                    %             analysisdata.trialNumber,analysisdata.chunkID,1,1,1); %ST_LFPA,ST_LFPV,numSpikesForLFP);

                    addSingleTrial=true;
                else % repeat sweep through same trial
                    %do nothing
                    addSingleTrial=false;
                end

                if addSingleTrial
                    %this trial..history of bright ones saved
                    analysisdata.singleChunkTemporalRecord(1,:)=...
                        getTemporalSignal(analysisdata.STA,analysisdata.STV,analysisdata.numSpikes,'bright');
                end
                cumulativedata.lastAnalysis = analysisdata;

                % cumulative
                [brightSignal brightCI brightInd]=getTemporalSignal(cumulativedata.cumulativeSTA,cumulativedata.cumulativeSTV,cumulativedata.cumulativeNumSpikes,'bright');
                [darkSignal darkCI darkInd]=getTemporalSignal(cumulativedata.cumulativeSTA,cumulativedata.cumulativeSTV,cumulativedata.cumulativeNumSpikes,'dark');

                rng=[min(cumulativedata.cumulativeSTA(:)) max(cumulativedata.cumulativeSTA(:))];

                % 11/25/08 - update GUI
                %figure(plotParameters.handle); % make the figure current and then plot into it
                if plotParameters.showSpikeAnalysis
                    figureName = [num2str(min(cumulativedata.cumulativeTrialNumbers)) '-' num2str(max(cumulativedata.cumulativeTrialNumbers))];
                    figure(min(cumulativedata.cumulativeTrialNumbers));
                    set(gcf,'Name',figureName); % trialBased is better
                    set(gcf,'Units','pixels');
                    set(gcf,'position',[100 100 800 700]);
                end
                % size(analysisdata.cumulativeSTA)


                % or use analysisdata.STA?
                doSpatial=~(size(analysisdata.STA,1)==1 & size(analysisdata.STA,2)==1); % if spatial dimentions exist
                doSpatial = false;
                % %% spatial signal (best via bright)
                if doSpatial

                    contextInd=brightInd;

                    %fit model to best spatial
                    stdThresh=1;
                    [STAenvelope STAparams] =fitGaussianEnvelopeToImage(cumulativedata.cumulativeSTA(:,:,contextInd(3)),stdThresh,false,false,false);
                    cx=STAparams(2)*size(STAenvelope,2)+1;
                    cy=STAparams(3)*size(STAenvelope,1)+1;
                    stdx=size(STAenvelope,2)*STAparams(5);
                    stdy=size(STAenvelope,1)*STAparams(5);
                    e1 = fncmb(fncmb(rsmak('circle'),[stdx*1 0;0 stdy*1]),[cx;cy]);
                    e2 = fncmb(fncmb(rsmak('circle'),[stdx*2 0;0 stdy*2]),[cx;cy]);
                    e3 = fncmb(fncmb(rsmak('circle'),[stdx*3 0;0 stdy*3]),[cx;cy]);


                    %get significant pixels and denoised spots
                    switch stimulusDetails.distribution.type
                        case 'gaussian'
                            stdStimulus = std*whiteV;
                        case 'binary'
                            stdStimulus = std*whiteV*100; % somthing very large to prevent false positives... need to figure it out analytically.. maybe use different function
                            %std=hiLoDiff*p*(1-p);
                    end
                    meanLuminanceStimulus = meanLuminance*whiteV;
                    [bigSpots sigPixels]=getSignificantSTASpots(cumulativedata.cumulativeSTA(:,:,contextInd(3)),cumulativedata.cumulativeNumSpikes,meanLuminanceStimulus,stdStimulus,ones(3),3,0.05);
                    [bigIndY bigIndX]=find(bigSpots~=0);
                    [sigIndY sigIndX]=find(sigPixels~=0);
                    if plotParameters.showSpikeAnalysis
                        subplot(2,2,1)
                    end
                    %     im=single(squeeze(analysisdata.cumulativeSTA(:,:,contextInd(3))));
                    %    imagesc(squeeze(cumulativedata.cumulativeSTA(:,:,contextInd(3))),rng);
                    im=single(squeeze(cumulativedata.cumulativeSTA(:,:,contextInd(3))));

                    if spatialSmoothingOn
                        im=imfilter(im,filt,'replicate','same');
                    end
                    if plotParameters.showSpikeAnalysis
                        imagesc(im,rng);
                        %colorbar; %colormap(blueToRed(meanLuminanceStimulus,rng));
                        hold on; plot(brightInd(2), brightInd(1),'y+')
                        hold on; plot(darkInd(2)  , darkInd(1),  'y-')
                        hold on; plot(bigIndX     , bigIndY,     'y.')
                        hold on; plot(sigIndX     , sigIndY,     'y.','markerSize',1)
                        minTrial=min(cumulativedata.cumulativeTrialNumbers);
                        maxTrial=max(cumulativedata.cumulativeTrialNumbers);
                        xlabel(sprintf('cumulative (%d.%d --> %d.%d)',...
                            minTrial,min(cumulativedata.cumulativeChunkIDs(find(cumulativedata.cumulativeTrialNumbers==minTrial))),...
                            maxTrial,max(cumulativedata.cumulativeChunkIDs(find(cumulativedata.cumulativeTrialNumbers==maxTrial)))));
                        fnplt(e1,1,'g'); fnplt(e2,1,'g'); fnplt(e3,1,'g'); % plot elipses


                        subplot(2,2,2)

                        %hold off; imagesc(squeeze(STA(:,:,contextInd(3))),[min(STA(:)) max(STA(:))]);
                        hold off; imagesc(squeeze(analysisdata.STA(:,:,contextInd(3))),[min(analysisdata.STA(:)) max(analysisdata.STA(:))]);
                        hold on; plot(brightInd(2), brightInd(1),'y+')
                        hold on; plot(darkInd(2)  , darkInd(1),'y-')
                        %colorbar;
                        colormap(gray);
                        %colormap(blueToRed(meanLuminanceStimulus,rng,true));

                        fnplt(e1,1,'g'); fnplt(e2,1,'g'); fnplt(e3,1,'g'); % plot elipses

                        xlabel(sprintf('this trial/chunk (%d-%d)',analysisdata.trialNumber,analysisdata.chunkID))

                        subplot(2,2,3)
                    end
                end

                timeMs=linspace(-timeWindowMsStim(1),timeWindowMsStim(2),size(analysisdata.STA,3));
                ns=length(timeMs);
                if plotParameters.showSpikeAnalysis
                    hold off; plot(timeWindowFramesStim([1 1])+1, [0 whiteV],'k');
                    hold on;  plot([1 ns],meanLuminance([1 1])*whiteV,'k')
                    try
                        plot([1:ns], analysisdata.singleChunkTemporalRecord, 'color',[.8 .8 1])
                    catch
                        keyboard
                    end
                    fh=fill([1:ns fliplr([1:ns])]',[darkCI(:,1); flipud(darkCI(:,2))],'b'); set(fh,'edgeAlpha',0,'faceAlpha',.5)
                    fh=fill([1:ns fliplr([1:ns])]',[brightCI(:,1); flipud(brightCI(:,2))],'r'); set(fh,'edgeAlpha',0,'faceAlpha',.5)
                    plot([1:ns], darkSignal(:)','b')
                    plot([1:ns], brightSignal(:)','r')

                    peakFrame=find(brightSignal==max(brightSignal(:)));
                    timeInds=[1 peakFrame(end) timeWindowFramesStim(1)+1 size(analysisdata.STA,3)];
                    set(gca,'XTickLabel',unique(timeMs(timeInds)),'XTick',unique(timeInds),'XLim',minmax(timeInds));
                    set(gca,'YLim',[minmax([analysisdata.singleChunkTemporalRecord(:)' darkCI(:)' brightCI(:)'])+[-5 5]])
                    ylabel('RGB(gunVal)')
                    xlabel('msec')
                end

                if plotParameters.showSpikeAnalysis&&doSpatial
                    subplot(2,2,4)

                    switch xtraPlot{1}
                        case 'montage'
                            % montage(reshape(cumulativedata.cumulativeSTA,[size(cumulativedata.STA,1) size(cumulativedata.STA,2) 1 size(cumulativedata.STA,3) ] ), 'DisplayRange',rng)
                            montage(reshape(cumulativedata.cumulativeSTA,[size(STA,1) size(STA,2) 1 size(STA,3) ] ),'DisplayRange',rng)
                            colormap(blueToRed(meanLuminanceStimulus,rng,true));
                            % %% spatial signal (all)
                            % for i=1:
                            % subplot(4,n,2*n+i)
                            % imagesc(STA(:,:,i),'range',[min(STA(:)) min(STA(:))]);
                            % end

                            if max(parameters.trialNumber)==318
                                keyboard
                            end
                        case 'eyes'

                            figure(parameters.trialNumber)
                            if exist('ellipses','var')
                                plotEyeElipses(eyeSig,ellipses,within,true);
                            else
                                msg=sprintf('no good eyeData on trial %d\n will analyze all data',parameters.trialNumber)
                                text(.5,.5, msg)
                            end
                        case 'spaceTimeContext'
                            %uses defaults on phys monitor may 2009, might not be up to
                            %date after changes in hardware

                            %user controls these somehow... params?
                            eyeToMonitorMm=330;
                            contextSize=2;
                            pixelPad=0.1; %fractional pad 0-->0.5


                            %stimRect=[500 1000 800 1200]; %need to get this stuff!
                            stimRect=[0 0 stimulusDetails.width stimulusDetails.height]; %need to get this! now forcing full screen
                            stimRectFraction=stimRect./[stimulusDetails.width stimulusDetails.height stimulusDetails.width stimulusDetails.height];
                            [vRes hRes]=getAngularResolutionFromGeometry(size(STA,2),size(STA,1),eyeToMonitorMm,stimRectFraction);
                            contextResY=vRes(contextInd(1),contextInd(2));
                            contextResX=hRes(contextInd(1),contextInd(2));


                            contextOffset=-contextSize:1:contextSize;
                            n=length(contextOffset); % 2*c+1
                            contextIm=ones(n,n)*meanLuminanceStimulus;
                            selection=nan(n,n);
                            maxAmp=max(abs(meanLuminanceStimulus-rng))*2; %normalize to whatever lobe is larger: positive or negative
                            hold off; plot(0,0,'.')
                            hold on
                            for i=1:n
                                yInd=contextInd(1)+contextOffset(i);
                                for j=1:n
                                    xInd=contextInd(2)+contextOffset(j);
                                    if xInd>0 && xInd<=size(STA,2) && yInd>0 && yInd<=size(STA,1)
                                        %make the image
                                        selection(i,j)=sub2ind(size(STA),yInd,xInd,contextInd(3));
                                        contextIm(i,j)=cumulativedata.cumulativeSTA(selection(i,j));
                                        %get temporal signal
                                        [stixSig stixCI stixtInd]=getTemporalSignal(cumulativedata.cumulativeSTA,cumulativedata.cumulativeSTV,cumulativedata.cumulativeNumSpikes,selection(i,j));
                                        yVals{i,j}=((1-pixelPad*2)   *  (stixSig(:)-meanLuminanceStimulus)/maxAmp)  +  n-i+1; % pad, normalize, and then postion in grid
                                        xVals{i,j}=linspace(j-.5+pixelPad,j+.5-pixelPad,length(stixSig(:)));

                                    end
                                end
                            end

                            % plot the image
                            imagesc(flipud(contextIm),rng)
                            colormap(blueToRed(meanLuminanceStimulus,rng,true));

                            %plot the temporal signal
                            for i=1:n
                                for j=1:n
                                    if ~isnan(selection(i,j))
                                        plot(xVals{i,j},yVals{i,j},'y')
                                    end
                                end
                            end

                            % we only take the degrees of the selected pixel.
                            %neighbors may differ by a few % depending how big they are,
                            %geometery, etc.


                            axis([.5 n+.5 .5 n+.5])
                            set(gca,'xTick',[]); set(gca,'yTick',[])
                            xlabel(sprintf('%2.1f deg/pix',contextResX));
                            ylabel(sprintf('%2.1f deg/pix',contextResY));

                        otherwise
                            error('bad xtra plot request')
                    end

                end

                %figure(min(cumulativedata.cumulativeTrialNumbers)+1000);
                % set(gcf,'Name','LFP Analysis','NumberTitle','off');
                %     ST_LFPTime = linspace(-1000,1000,length(cumulativedata.cumulativeST_LFPA));
                %     plot(ST_LFPTime,cumulativedata.cumulativeST_LFPA,'LineWidth',2);
                %imagesc([-1000 1000],[1 14],squeeze(cumulativedata.cumulativeST_LFPA)');colorbar;
                %     hold on;
                %     plot(ST_LFPTime,cumulativedata.cumulativeST_LFPA+sqrt(cumulativedata.cumulativeST_LFPV));
                %     plot(ST_LFPTime,cumulativedata.cumulativeST_LFPA-sqrt(cumulativedata.cumulativeST_LFPV));
                %     hold off;

                % drawnow
        end


       

        function retval = whiteVal(sm)
                %definition of white 
                retval=255;
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

            if length(quality.passedQualityTest)>1 && ~enableChunkedPhysAnalysis(sm)
                %if many chunks, the last one might have no frames or spikes, but the
                %analysis should still complete if the the previous chunks are all
                %good. to be very thourough, a stim manager may wish to confirm that
                %the reason for last chunk failing, if it did, is an acceptable reason.
                qualityOK=all(quality.passedQualityTest(1:end-1));


                %&& size(quality.chunkIDForFrames,1)>0
            else
                %if there is only one, or you will try to analyze each chunk as you get it, then only check this one
                qualityOK=quality.passedQualityTest(end);
            %     warning('forcing qualityOK to true');
            %     qualityOK = true;
            %     if quality.passedQualityTest(end)==0
            %        if size(find(quality.chunkIDForCorrectedFrames==quality.chunkID(end)),1)==0
            %            %known error... some recording can extend beyond last frame
            %            disp('failed quality b/c no stim frames this chunk')
            %        else
            %            keyboard
            %            warning('failed quality for unknown reason')
            %     end
            end

            retval=qualityOK && ...
                (isLastChunkInTrial || enableChunkedPhysAnalysis(sm)) &&...    
                (overwriteAll || ~analysisExists);
            warning('forcing retval to true');
            retval=true;
        end % end function




        
        
    end
    
end


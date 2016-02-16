classdef phaseReverseGratings
    
    properties
        pixPerCycs = [];
        frequencies = [];
        orientations = [];
        startPhases = [];
        waveform='square';


        contrasts = [];
        durations = [];
        radii = [];
        annuli = [];
        location = [];
        phaseform = 'sine';
        normalizationMethod='normalizeDiagonal';
        mean = 0;
        thresh = 0;
        numRepeats = [];

        changeableAnnulusCenter=false;
        doCombos=true;
        ordering = [];

        LUT =[];
        LUTbits=0;
    end
    
    methods
        function s=phaseReverseGratings(varargin)
            % PHASEREVERSEGRATINGS  class constructor.
            % s = phaseReverseGratings(pixPerCycs,frequencies,orientations,startPhases,doCombos
            %       contrasts,durations,radii,annuli,location,waveform,normalizationMethod,mean,thresh,numRepeats,maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            %
            % Each of the following arguments is a 1xN vector, one element for each of N gratings
            % pixPerCycs - specified as in orientedGabors
            % frequencies - specified in cycles per second for now; the rate at which the grating moves across the screen
            % orientations - in radians
            % startPhases - starting phase of each grating frequency (in radians)%
            % contrasts - normalized (0 <= value <= 1) - Mx1 vector%
            % durations - up to MxN, specifying the duration (in seconds) of each pixPerCycs/contrast pair
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

            % special only to phaseReverseGratings
            s.ordering.method = 'ordered';
            s.ordering.seed = [];

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s = class(s,'phaseReverseGratings',phaseReverse());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'phaseReverseGratings'))
                        s = varargin{1};
                    else
                        error('Input argument is not a phaseReverseGratings object')
                    end
                case {19 20 21}
                    % create object using specified values
                    % special to phaseReverseGratings
                    % pixPerCycs

                    if isvector(varargin{1}) && isnumeric(varargin{1})
                        s.pixPerCycs=varargin{1};
                    else
                        error('pixPerCycs must be numbers');
                    end
                    % frequencies
                    if isvector(varargin{2}) && isnumeric(varargin{2}) && all(varargin{2})>0
                        s.frequencies=varargin{2};
                    else
                        error('frequencies must all be > 0')
                    end
                    % orientations
                    if isvector(varargin{3}) && isnumeric(varargin{3})
                        s.orientations=varargin{3};
                    else
                        error('orientations must be numbers')
                    end
                    % phases
                    if isvector(varargin{4}) && isnumeric(varargin{4})
                        s.startPhases=varargin{4};
                    else
                        error('startPhases must be numbers');
                    end
                    % waveform
                    if ischar(varargin{5})
                        if ismember(varargin{5},{'sine', 'square', 'none','catcam530a','haterenImage1000'})
                            s.waveform=varargin{5};
                        else
                            error('waveform must be ''sine'', ''square'', ''catcam530a'', or ''none''')
                        end
                    end

                    % general to phaseReverse
                    % contrasts
                    if isvector(varargin{6}) && isnumeric(varargin{6})
                        s.contrasts=varargin{6};
                    else
                        error('contrasts must be numbers');
                    end
                    % durations
                    if isnumeric(varargin{7}) && all(all(varargin{7}>0))
                        s.durations=varargin{7};
                    else
                        error('all durations must be >0');
                    end
                    % radii
                    if isnumeric(varargin{8}) && all(varargin{8}>0)
                        s.radii=varargin{8};
                    else
                        error('radii must be >= 0');
                    end
                    % annuli
                    if isnumeric(varargin{9}) && all(varargin{9}>=0)
                        s.annuli=varargin{9};
                    else
                        error('all annuli must be >= 0');
                    end
                    % numRepeats
                    if isinteger(varargin{15}) || isinf(varargin{15}) || isNearInteger(varargin{15})
                        s.numRepeats=varargin{15};
                    end

                    % location
                    if isnumeric(varargin{10}) && all(varargin{10}>=0) && all(varargin{10}<=1)
                        s.location=varargin{10};
                    elseif isa(varargin{10},'RFestimator')
                        s.location=varargin{10};
                    else
                        error('all location must be >= 0 and <= 1, or location must be an RFestimator object');
                    end

                    % phaseform
                    if ischar(varargin{11})
                        if ismember(varargin{11},{'sine', 'square'})
                            s.phaseform=varargin{11};
                        else
                            error('phaseform must be ''sine'' or ''square''')
                        end
                    end
                    % normalizationMethod
                    if ischar(varargin{12})
                        if ismember(varargin{12},{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'})
                            s.normalizationMethod=varargin{12};
                        else
                            error('normalizationMethod must be ''normalizeVertical'', ''normalizeHorizontal'', or ''normalizeDiagonal'', or ''none''')
                        end
                    end
                    % mean
                    if varargin{13} >= 0 && varargin{13}<=1
                        s.mean=varargin{13};
                    else
                        error('0 <= mean <= 1')
                    end
                    % thres
                    if varargin{14} >= 0
                        s.thresh=varargin{14};
                    else
                        error('thresh must be >= 0')
                    end


                    if nargin==19
                        s = class(s,'phaseReverseGratings',phaseReverse(varargin{6},varargin{7},varargin{8},varargin{9},varargin{10},varargin{11},varargin{12},...
                        varargin{13},varargin{14},varargin{15},varargin{16},varargin{17},varargin{18},varargin{19}));
                    elseif nargin==20
                        s = class(s,'phaseReverseGratings',phaseReverse(varargin{6},varargin{7},varargin{8},varargin{9},varargin{10},varargin{11},varargin{12},...
                        varargin{13},varargin{14},varargin{15},varargin{16},varargin{17},varargin{18},varargin{19},varargin{20}));
                    elseif nargin==21
                        % check for doCombos argument first (it decides other error checking)
                        if islogical(varargin{21})
                            s.doCombos=varargin{21};
                            s.ordering.method = 'ordered';
                            s.ordering.seed = [];
                        elseif iscell(varargin{21})&&(length(varargin{21})==3)
                            s.doCombos = varargin{21}{1}; if ~islogical(s.doCombos), error('doCombos has to be a logical'),end;
                            s.ordering.method = varargin{21}{2}; if ~ismember(s.ordering.method,{'twister','state','seed'}), error('unknown ordering method'), end;
                            s.ordering.seed = varargin{21}{3};
                        else
                            error('unknown way to specify doCombos. its either just a logical or a cell length 3.');                    
                        end
                        s = class(s,'phaseReverseGratings',phaseReverse(varargin{6},varargin{7},varargin{8},varargin{9},varargin{10},varargin{11},varargin{12},...
                            varargin{13},varargin{14},varargin{15},varargin{16},varargin{17},varargin{18},varargin{19},varargin{20}));
                    end
                    if ~s.doCombos
                        paramLength = length(s.pixPerCycs);
                        if paramLength~=length(s.frequencies) || paramLength~=length(s.orientations) || paramLength~=length(s.contrasts) ...
                                || paramLength~=length(s.phases) || paramLength~=length(s.durations) || paramLength~=length(s.radii) ...
                                || paramLength~=length(s.annuli)
                            error('if doCombos is false, then all parameters (pixPerCycs, frequencies, orientations, contrasts, phases, durations, radii, annuli) must be same length');
                        end
                    end

                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end



                    % check that if doCombos is false, then all parameters must be same length

            %         

            %         if nargin>18
            %             if ismember(varargin{19},[0 1])
            %                 s.changeableAnnulusCenter=logical(varargin{19});
            %             else
            %                 error('gratingWithChangeableAnnulusCenter must be true / false')
            %             end
            %         end

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
            [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));

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

            details.pctCorrectionTrials=getPercentCorrectionTrials(trialManager);
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
            numFrequencies = length(stimulus.pixPerCycs);
            numContrasts = length(stimulus.contrasts);
            details.spatialFrequencies=stimulus.pixPerCycs; % 1/7/09 - renamed from pixPerCycs to spatialFrequencies (to avoid clashing with compile process)
            details.frequencies=stimulus.frequencies;
            details.orientations=stimulus.orientations;
            details.startPhases=stimulus.startPhases;
            details.contrasts=stimulus.contrasts;
            if isa(stimulus.location,'RFestimator')
                if size(trialRecords(end).subjectsInBox,2)==1
                    subjectID=char(trialRecords(end).subjectsInBox);
                else
                    error('only one subject allowed')
                end
                details.location=getCenter(stimulus.location,subjectID,trialRecords);
            else
                details.location=stimulus.location;
            end
            details.durations=stimulus.durations;
            details.radii=stimulus.radii;
            details.annuli=stimulus.annuli;
            details.numRepeats=stimulus.numRepeats;
            details.doCombos=stimulus.doCombos;
            details.method = stimulus.ordering.method;
            details.seed = stimulus.ordering.seed;
            if ischar(details.seed) && strcmp(details.seed,'clock')
                seedVal = sum(100*clock);
                details.seed = seedVal;
                stimulus.ordering.seed = seedVal;
            end
            details.changeableAnnulusCenter=stimulus.changeableAnnulusCenter;
            details.waveform=stimulus.waveform;
            details.phaseform = stimulus.phaseform;
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
            stim.phaseform = details.phaseform;

            % details has the parameters before combos, stim should have them after combos are taken
            if stimulus.doCombos
                % do combos here
                mode = {details.method,details.seed};
                comboMatrix = generateFactorialCombo({details.spatialFrequencies,details.frequencies,details.orientations,...
                    details.contrasts,details.startPhases,details.durations,details.radii,details.annuli},[],[],mode);
                stim.pixPerCycs=comboMatrix(1,:);
                stim.frequencies=comboMatrix(2,:);
                stim.orientations=comboMatrix(3,:);
                stim.contrasts=comboMatrix(4,:); %starting phases in radians
                stim.phases=comboMatrix(5,:);
                stim.durations=round(comboMatrix(6,:)*hz); % CONVERTED FROM seconds to frames
                stim.radii=comboMatrix(7,:);
                stim.annuli=comboMatrix(8,:);
            else
                stim.pixPerCycs=details.spatialFrequencies;
                stim.frequencies=details.driftfrequencies;
                stim.orientations=details.orientations;
                stim.contrasts=details.contrasts;
                stim.phases=details.phases;
                stim.durations=round(details.durations*hz); % CONVERTED FROM seconds to frames    
                stim.radii=details.radii;
                stim.annuli=details.annuli;
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
                    % now calculate mask for this grating - we need to pass a mean of 0 to correctly make a mask
                    mask(:,:,1)=ones(height,width,1)*stimulus.mean;
                    mask(:,:,2)=computeGabors(maskParams,0,width,height,...
                        'none', stimulus.normalizationMethod,0,0);

                    % necessary to make use of PTB alpha blending: 1 - 
                    mask(:,:,2) = 1 - mask(:,:,2); % 0 = transparent, 255=opaque (opposite of our mask)
                    stim.masks{i}=mask;
                end
            end
            % convert from annuli=[0.8 0.8 0.6 1.2 0.7] to [1 1 2 3 4] (stupid unique automatically sorts when we dont want to)
            [a b] = unique(fliplr(stim.annuli)); 
            unsortedUniques=stim.annuli(sort(length(stim.annuli)+1 - b));
            [garbage stim.annuliInds]=ismember(stim.annuli,unsortedUniques);
            % annuli array
            annulusCenter=stim.location;
            stim.annuliMatrices=cell(1,length(unsortedUniques));
            for i=1:length(unsortedUniques)
                annulus=[];
                annulusRadius=unsortedUniques(i);
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
        
        function display(sm)
            pixPerCycs          = sm.pixPerCycs
            frequencies         = sm.frequencies
            orientations        = sm.orientations
            LUT                 = sm.LUT
            LUTbits             = sm.LUTbits
            startPhases         = sm.startPhases 
            contrasts           = sm.contrasts 
            durations           = sm.durations
            radii               = sm.radii
            annuli              = sm.annuli
            location            = sm.location
            waveform            = sm.waveform
            phaseform           = sm.phaseform
            normalizationMethod = sm.normalizationMethod
            mean                = sm.mean 
            thresh              = sm.thresh 
            numRepeats          = sm.numRepeats 
        end

        function displayCumulativePhysAnalysis(sm,cumulativedata,parameters)
            % setup for plotting
            sweptParameter = char(cumulativedata.stimInfo.sweptParameter);
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
            xlabel(sweptParameter); set(gca,'XTickLabel',valNames,'XTick',[1:length(vals)]); ylabel('rate (f0)'); set(gca,'YTickLabel',[0:.1:1]*cumulativedata.refreshRate,'YTick',[0:.1:1])
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

        function [doFramePulse expertCache dynamicDetails textLabel i dontclear indexPulse] = ...
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
            cycsPerFrameVel = stim.frequencies(gratingToDraw)*ifi; % in units of cycles/frame
            phase = 2*pi*cycsPerFrameVel*i;
            nextphase = 2*pi*cycsPerFrameVel*(i+1);
            indexPulse=mod(phase,4*pi)>mod(nextphase,4*pi);  % every 2 cycles


            % Create a 1D vector x based on the frequency pixPerCycs
            % make the grating twice the normal width (to cover entire screen if rotated)

            x = (1:stim.width*2)*2*pi/stim.pixPerCycs(gratingToDraw);
            switch stim.waveform
                case 'sine'
                    switch stim.phaseform
                        case 'sine'
                            grating=stim.contrasts(gratingToDraw)*cos(phase)*cos(x + stim.phases(gratingToDraw))+stimulus.mean; % grating is the cos curve, with our calculated phase offset (based on driftfrequency) and initial phase
                        case 'square'
                            grating=stim.contrasts(gratingToDraw)*square(phase)*cos(x + stim.phases(gratingToDraw))+stimulus.mean; % grating is the cos curve, with our calculated phase offset (based on driftfrequency) and initial phase
                        otherwise
                            stim.phaseform
                            error('that phaseform is not coded');
                    end        
                case 'square'
                    switch stim.phaseform
                        case 'sine'
                            grating=stim.contrasts(gratingToDraw)*cos(phase)*square(x +stim.phases(gratingToDraw)+pi/2)+stimulus.mean; % same as sine, but adjust for cosine
                        case 'square'
                            grating=stim.contrasts(gratingToDraw)*square(phase)*square(x +stim.phases(gratingToDraw)+pi/2)+stimulus.mean; % same as sine, but adjust for cosine
                        otherwise
                            stim.phaseform
                            error('that phaseform is not coded');
                    end
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
                case 'localCalibStore'
                    try
                        temp = load(fullfile(getRatrixPath,'monitorCalibration','tempCLUT.mat'));
                        uncorrected = temp.linearizedCLUT;
                        linearizedCLUT=uncorrected;
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
                %s=fillLUT(s,'useThisMonitorsUncorrectedGamma');  %TEMP - don't commit
                %s=fillLUT(s,'tempLinearRedundantCode');
                %s=fillLUT(s,'2009Trinitron255GrayBoxInterpBkgnd.5');
                %s=fillLUT(s,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5'); % March 2011 ViewSonic
            %     s=fillLUT(s,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5'); % May 2011 Westinghouse
                s=fillLUT(s,'localCalibStore');
            else
                updateSM=false;
            end
            out=s.LUT;
        end
        
        function [analysisdata cumulativedata] = physAnalysis(stimManager,spikeRecord,stimulusDetails,plotParameters,parameters,cumulativedata,eyeData,LFPRecord)
            % stimManager is the stimulus manager
            % spikes is an index into neural data samples of the time of a spike
            % correctedFrameIndices is an nx2 array of frame start and stop indices - [start stop], n = number of frames
            % stimulusDetails are the stimDetails from calcStim (hopefully they contain
            % all the information needed to reconstruct stimData)
            % plotParameters - currently not used

            %initalize analysisdata
            analysisdata.analysisdone = false;

            % processed clusters and spikes
            theseSpikes = logical(spikeRecord.processedClusters);
            spikesThis=spikeRecord.spikes(theseSpikes);
            spikeWaveformsThis = spikeRecord.spikeWaveforms(theseSpikes,:);
            spikeTimestampsThis = spikeRecord.spikeTimestamps(theseSpikes);

            %SET UP RELATION stimInd <--> frameInd
            numStimFramesThis=max(spikeRecord.stimInds);
            analyzeDrops=true;
            if analyzeDrops
                stimFramesThis=spikeRecord.stimInds;
                correctedFrameIndicesThis=spikeRecord.correctedFrameIndices;
            else
                stimFramesThis=1:numStimFrames;
                firstFramePerStimIndThis=~[0 diff(spikeRecord.stimInds)==0];
                correctedFrameIndicesThis=spikeRecord.correctedFrameIndices(firstFramePerStimInd);
            end

            trialsThis = repmat(parameters.trialNumber,length(stimFramesThis),1);
            if ~isfield(stimulusDetails,'method')
                mode = {'ordered',[]};
            else
                mode = {stimulusDetails.method,stimulusDetails.seed};
            end
            % get the stimulusCombo
            if stimulusDetails.doCombos==1
                comboMatrix = generateFactorialCombo({stimulusDetails.spatialFrequencies,stimulusDetails.frequencies,stimulusDetails.orientations,...
                    stimulusDetails.contrasts,stimulusDetails.startPhases,stimulusDetails.durations,stimulusDetails.radii,stimulusDetails.annuli},[],[],mode);
                pixPerCycsThis=comboMatrix(1,:);
                driftfrequenciesThis=comboMatrix(2,:);
                orientationsThis=comboMatrix(3,:);
                contrastsThis=comboMatrix(4,:); %starting phases in radians
                startPhasesThis=comboMatrix(5,:);
                durationsThis=round(comboMatrix(6,:)*parameters.refreshRate); % CONVERTED FROM seconds to frames
                radiiThis=comboMatrix(7,:);
                annuliThis=comboMatrix(8,:);

                repeatThis=ceil(stimFramesThis/sum(durationsThis));
                numRepeatsThis=ceil(numStimFramesThis/sum(durationsThis));
                chunkEndFrameThis=[cumsum(repmat(durationsThis,1,numRepeatsThis))];
                chunkStartFrameThis=[0 chunkEndFrameThis(1:end-1)]+1;
                chunkStartFrameThis = chunkStartFrameThis';
                chunkEndFrameThis = chunkEndFrameThis';
                %chunkStartFrame(chunkStartFrame>numStimFrames)=[]; %remove chunks that were never reached. OK TO LEAVE IF WE INDEX BY OTHER THINGS
                %chunkEndFrame(chunkStartFrame>numStimFrames)=[]; %remove chunks that were never reached.
                numChunksThis=length(chunkStartFrameThis);
                trialsByChunkThis = repmat(parameters.trialNumber,numChunksThis,1);
                numTypesThis=length(durationsThis);   
            else
                error('analysis not handled yet for this case')
            end

            numValsPerParamThis=...
                [length(unique(pixPerCycsThis)) length(unique(driftfrequenciesThis))  length(unique(orientationsThis))  length(unique(contrastsThis)) length(unique(startPhasesThis)) length(unique(durationsThis))  length(unique(radiiThis))  length(unique(annuliThis))];
            if sum(numValsPerParamThis>1)==1
                names={'pixPerCycs','driftfrequencies','orientations','contrasts','startPhases','durations','radii','annuli'};
                sweptParameterThis=names(find(numValsPerParamThis>1));
            else
                error('analysis only for one value at a time now')
                return % to skip
            end

            valsThis = eval(sprintf('%s%s',char(sweptParameterThis),'This'));

            % durations of each condition should be unique
            if length(unique(durationsThis))==1
                durationThis=unique(durationsThis);
                typesThis=repmat([1:numTypesThis],durationThis,numRepeatsThis);
                typesThis=typesThis(stimFramesThis); % vectorize matrix and remove extras
            else
                error('multiple durations can''t rely on mod to determine the frame type')
            end

            samplingRate=parameters.samplingRate;

            % calc phase per frame, just like dynamic
            xThis = 2*pi./pixPerCycsThis(typesThis); % adjust phase for spatial frequency, using pixel=1 which is likely always offscreen, given roation and oversizeness
            cycsPerFrameVelThis = driftfrequenciesThis(typesThis)*1/(parameters.refreshRate); % in units of cycles/frame
            offsetThis = 2*pi*cycsPerFrameVelThis.*stimFramesThis';
            risingPhasesThis=xThis + offsetThis+startPhasesThis(typesThis);
            phasesThis=mod(risingPhasesThis,2*pi); phasesThis = phasesThis';

            % count the number of spikes per frame
            % spikeCount is a 1xn vector of (number of spikes per frame), where n = number of frames
            spikeCountThis=zeros(size(correctedFrameIndicesThis,1),1);
            for i=1:length(spikeCountThis) % for each frame
                spikeCountThis(i)=length(find(spikesThis>=correctedFrameIndicesThis(i,1)&spikesThis<=correctedFrameIndicesThis(i,2))); % inclusive?  policy: include start & stop
            end

            % always analyze on all the data!
            if ~isfield(cumulativedata,'trialNumber')
                trialNumbers = parameters.trialNumber;
                cumulativedata.trialNumber = parameters.trialNumber;
            else
                trialNumbers = [cumulativedata.trialNumber parameters.trialNumber];
                cumulativedata.trialNumber = parameters.trialNumber;
            end

            stimInfo.pixPerCycs = pixPerCycsThis;
            stimInfo.driftfrequencies = driftfrequenciesThis;
            stimInfo.orientations = orientationsThis;
            stimInfo.contrasts = contrastsThis;
            stimInfo.startPhases = startPhasesThis;
            stimInfo.durations = durationsThis;
            stimInfo.radii = radiiThis;
            stimInfo.annuli = annuliThis;
            stimInfo.numRepeats = numRepeatsThis;
            stimInfo.numTypes = numTypesThis;
            stimInfo.vals = valsThis;
            stimInfo.sweptParameter = sweptParameterThis;

            if ~isfield(cumulativedata,'stimInfo')
                cumulativedata.stimInfo = stimInfo;
            else
                if ~isequal(cumulativedata.stimInfo,stimInfo)
                    warning('something fishy going on here');
                    analysisdata = [];
                    return
                end
            end

            numTrials = length(trialNumbers);

            numPhaseBins=8;
            edges=linspace(0,2*pi,numPhaseBins+1);
            events=zeros(numRepeatsThis,numTypesThis,numPhaseBins);
            eventsThis=events;
            possibleEvents=events;
            possibleEventsThis = eventsThis;
            phaseDensity=zeros(numRepeatsThis*numTypesThis,numPhaseBins);
            phaseDensityThis=zeros(numRepeatsThis*numTypesThis,numPhaseBins);
            pow=nan(numRepeatsThis,numTypesThis);
            powThis = pow;

            [chunkStartFrame chunkEndFrame trialsByChunk...
            stimFrames spikeCount phases types repeat trials cumulativedata]...
            = getCompleteRecords(chunkStartFrameThis, chunkEndFrameThis, trialsByChunkThis,...
            stimFramesThis,spikeCountThis,phasesThis,typesThis, repeatThis,trialsThis,cumulativedata);

            for i=1:numRepeatsThis
                for j=1:numTypesThis
                    whichType=find(types==j & repeat==i);
                    whichTypeThis = find(trials==parameters.trialNumber & types==j & repeat==i);
                    if length(whichType)>5  % need some spikes, 2 would work mathematically ??is this maybe spikeCount(whichType)
                        [n phaseID]=histc(phases(whichType),edges);
                        [nThis phaseIDThis] = histc(phases(whichTypeThis),edges);
                        for k=1:numPhaseBins
                            whichPhase=find(phaseID==k);
                            whichPhaseThis = find(phaseIDThis==k);
                            events(i,j,k)=sum(spikeCount(whichType(whichPhase)));
                            eventsThis(i,j,k)=sum(spikeCount(whichTypeThis(whichPhaseThis)));
                            possibleEvents(i,j,k)=length(whichPhase);
                            possibleEventsThis(i,j,k)=length(whichPhaseThis);

                            %in last repeat density = 0, for parsing and avoiding misleading half data
                            if 1 %numRepeats~=i
                                y=(j-1)*(numRepeatsThis)+i;
                                phaseDensity(y,k)=events(i,j,k)/possibleEvents(i,j,k);
                                phaseDensityThis(y,k)=eventsThis(i,j,k)/possibleEventsThis(i,j,k);
                            end
                        end

                        % find the power in the spikes at the freq of the grating
                        fy=fft(.5+cos(phases(whichType))/2); %fourier of stim
                        fx=fft(spikeCount(whichType)); % fourier of spikes
                        fy=abs(fy(2:floor(length(fy)/2))); % get rid of DC and symetry
                        fx=abs(fx(2:floor(length(fx)/2)));
                        peakFreqInd=find(fy==max(fy)); % find the right freq index using stim
                        pow(i,j)=fx(peakFreqInd); % determine the power at that freq

                        % find the power in the spikes at the freq of the grating
                        fyThis=fft(.5+cos(phases(whichTypeThis))/2); %fourier of stim
                        fxThis=fft(spikeCount(whichTypeThis)); % fourier of spikes
                        fyThis=abs(fyThis(2:floor(length(fyThis)/2))); % get rid of DC and symetry
                        fxThis=abs(fxThis(2:floor(length(fxThis)/2)));
                        peakFreqIndThis=find(fyThis==max(fyThis)); % find the right freq index using stim
                        powThis(i,j)=fx(peakFreqIndThis); % determine the power at that freq

                        % coherency
                        chrParam.tapers=[3 5]; % same as default, but turns off warning
                        chrParam.err=[2 0.05];  % use 2 for jacknife
                        fscorr=true;
                        % should check chronux's chrParam,trialave=1 to see how to
                        % handle CI's better.. will need to do all repeats at once
                        [C,phi,S12,S1,S2,f,zerosp,confC,phistd,Cerr]=...
                            coherencycpb(cos(phases(whichType)),spikeCount(whichType),chrParam,fscorr);
                        [CThis,phiThis,S12This,S1This,S2This,fThis,zerospThis,confCThis,phistdThis,CerrThis]=...
                            coherencycpb(cos(phases(whichTypeThis)),spikeCount(whichTypeThis),chrParam,fscorr);

                        if ~zerosp
                            peakFreqInds=find(S1>max(S1)*.95); % a couple bins near the peak of
                            [junk maxFreqInd]=max(S1);
                            coh(i,j)=mean(C(peakFreqInds));
                            cohLB(i,j)=Cerr(1,maxFreqInd);
                        else
                            coh(i,j)=nan;
                            cohLB(i,j)=nan;
                        end

                        if ~zerospThis
                            peakFreqIndsThis=find(S1This>max(S1This)*.95); % a couple bins near the peak of
                            [junk maxFreqIndThis]=max(S1This);
                            cohThis(i,j)=mean(CThis(peakFreqIndsThis));
                            cohLBThis(i,j)=Cerr(1,maxFreqIndThis);
                        else
                            cohThis(i,j)=nan;
                            cohLBThis(i,j)=nan;
                        end

                    end
                end
            end


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
            end




            % events(events>possibleEvents)=possibleEvents % note: more than one spike could occur per frame, so not really binomial
            % [pspike pspikeCI]=binofit(events,possibleEvents);

            fullRate=events./possibleEvents;
            fullRateThis = eventsThis./possibleEventsThis;
            rate=reshape(sum(events,1)./sum(possibleEvents,1),numTypesThis,numPhaseBins); % combine repetitions
            rateThis = reshape(sum(eventsThis,1)./sum(possibleEventsThis,1),numTypesThis,numPhaseBins);

            [repInds typeInds]=find(isnan(pow));
            [repIndsThis typeIndsThis] = find(isnan(powThis));

            pow(unique(repInds),:)=[];   % remove reps with bad power estimates
            coh(unique(repInds),:)=[];   % remove reps with bad power estimates
            cohLB(unique(repInds),:)=[]; % remove reps with bad power estimates

            powThis(unique(repIndsThis),:)=[];   % remove reps with bad power estimates
            cohThis(unique(repIndsThis),:)=[];   % remove reps with bad power estimates
            cohLBThis(unique(repIndsThis),:)=[]; % remove reps with bad power estimates

            if numRepeatsThis>2
                rateSEM=reshape(std(events(1:end-1,:,:)./possibleEvents(1:end-1,:,:)),numTypesThis,numPhaseBins)/sqrt(numRepeatsThis-1);
                rateSEMThis=reshape(std(eventsThis(1:end-1,:,:)./possibleEventsThis(1:end-1,:,:)),numTypesThis,numPhaseBins)/sqrt(numRepeatsThis-1);
            else
                rateSEM=nan(size(rate));
                rateSEMThis = nan(size(rate));
            end

            if size(pow,1)>1
                powSEM=std(pow)/sqrt(size(pow,1));
                pow=mean(pow);

                cohSEM=std(coh)/sqrt(size(coh,1));
                coh=mean(coh);
                cohLB=mean(cohLB);  % do you really want the mean of the lower bound?
            else
                powSEM=nan(1,size(pow,2));
                cohSEM=nan(1,size(pow,2));
                cohLB_SEM=nan(1,size(pow,2));
            end

            if size(powThis,1)>1
                powSEMThis=std(powThis)/sqrt(size(powThis,1));
                powThis=mean(powThis);

                cohSEMThis=std(cohThis)/sqrt(size(cohThis,1));
                cohThis=mean(cohThis);
                cohLBThis=mean(cohLBThis);  % do you really want the mean of the lower bound?
            else
                powSEMThis=nan(1,size(powThis,2));
                cohSEMThis=nan(1,size(powThis,2));
                cohLB_SEMThis=nan(1,size(powThis,2));
            end

            cumulativedata.numPhaseBins = numPhaseBins;
            cumulativedata.phaseDensity = phaseDensity;
            cumulativedata.pow = pow;
            cumulativedata.coh = coh;
            cumulativedata.cohLB = cohLB;
            cumulativedata.rate = rate;
            cumulativedata.rateSEM = rateSEM;
            cumulativedata.powSEM = powSEM;
            cumulativedata.cohSEM = cohSEM;
            cumulativedata.cohLB = cohLB;
            cumulativedata.ISIviolationMS = parameters.ISIviolationMS;
            cumulativedata.eyeData = [];
            cumulativedata.refreshRate = parameters.refreshRate;
            cumulativedata.samplingRate = parameters.samplingRate;


            if ~isfield(cumulativedata,'spikeWaveforms')
                cumulativedata.spikeWaveforms = spikeWaveformsThis;
                cumulativedata.spikeTimestamps = spikeTimestampsThis;
            else
                cumulativedata.spikeWaveforms = [cumulativedata.spikeWaveforms;spikeWaveformsThis];
                cumulativedata.spikeTimestamps = [cumulativedata.spikeTimestamps;spikeTimestampsThis];
            end

            analysisdata.phaseDensity = phaseDensityThis;
            analysisdata.pow = powThis;
            analysisdata.coh = cohThis;
            analysisdata.cohLB = cohLBThis;
            analysisdata.rate = rateThis;
            analysisdata.rateSEM = rateSEMThis;
            analysisdata.powSEM = powSEMThis;
            analysisdata.cohSEM = cohSEMThis;
            analysisdata.cohLB = cohLBThis;
            analysisdata.trialNumber = parameters.trialNumber;
            analysisdata.ISIviolationMS = parameters.ISIviolationMS;
            analysisdata.spikeWaveforms = spikeWaveformsThis;

        end

        function [chunkStartFrame chunkEndFrame trialsByChunk...
                stimFrames spikeCount phases type repeat trials cumulativedata]...
                = getCompleteRecords(chunkStartFrameThis, chunkEndFrameThis, trialsByChunkThis,...
                stimFramesThis,spikeCountThis,phasesThis,typeThis,repeatThis,trialsThis,cumulativedata)
            if ~isfield(cumulativedata,'chunkStartFrame')
                chunkStartFrame = chunkStartFrameThis;
                chunkEndFrame = chunkEndFrameThis;
                trialsByChunk = trialsByChunkThis;
                stimFrames = stimFramesThis;
                spikeCount = spikeCountThis;
                phases = phasesThis;
                type = typeThis;
                repeat = repeatThis;
                trials = trialsThis;
                % update the cumulativedata
                cumulativedata.chunkStartFrame = chunkStartFrame;
                cumulativedata.chunkEndFrame = chunkEndFrame;
                cumulativedata.trialsByChunk = trialsByChunk;
                cumulativedata.stimFrames = stimFrames;
                cumulativedata.spikeCount = spikeCount;
                cumulativedata.phases = phases;
                cumulativedata.type = type;
                cumulativedata.repeat = repeat;
                cumulativedata.trials = trials;
            else
                chunkStartFrame = [cumulativedata.chunkStartFrame; chunkStartFrameThis];
                chunkEndFrame = [cumulativedata.chunkEndFrame; chunkEndFrameThis];
                trialsByChunk = [cumulativedata.trialsByChunk; trialsByChunkThis];
                stimFrames = [cumulativedata.stimFrames; stimFramesThis];
                spikeCount = [cumulativedata.spikeCount; spikeCountThis];
                phases = [cumulativedata.phases; phasesThis];
                type = [cumulativedata.type; typeThis];
                repeat = [cumulativedata.repeat; repeatThis];
                trials = [cumulativedata.trials; trialsThis];
                % update the cumulativedata
                cumulativedata.chunkStartFrame = chunkStartFrame;
                cumulativedata.chunkEndFrame = chunkEndFrame;
                cumulativedata.trialsByChunk = trialsByChunk;
                cumulativedata.stimFrames = stimFrames;
                cumulativedata.spikeCount = spikeCount;
                cumulativedata.phases = phases;
                cumulativedata.type = type;
                cumulativedata.repeat = repeat;
                cumulativedata.trials = trials;
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



            if length(quality.passedQualityTest)>1
                %if many chunks, the last one might have no frames or spikes, but the
                %analysis should still complete if the the previous chunks are all
                %good. to be very thourough, a stim manager may wish to confirm that
                %the reason for last chunk failing, if it did, is an acceptable reason.
                qualityOK=all(quality.passedQualityTest(1:end-1));
            else
                qualityOK=quality.passedQualityTest;
            end

            retval=qualityOK && ...
                (isLastChunkInTrial || enableChunkedPhysAnalysis(sm)) &&...    
                (overwriteAll || ~analysisExists);

        end % end function

        
        
    end
    
end


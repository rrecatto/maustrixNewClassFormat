classdef filteredNoise<stimManager
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cache={};
        seed={};
        sha1={};
        hz=[];
        inds={};
        fieldNames={'port','distribution','startFrame','loopDuration','numLoops','locationDistribution','maskRadius','patchDims','patchHeight','patchWidth','background','orientation','kernelSize','kernelDuration','ratio','filterStrength','bound'};
    end
    
    methods
        function s=filteredNoise(varargin)
            % FILTEREDNOISE  class constructor.
            % s = filteredNoise(in,maxWidth, maxHeight, scaleFactor, interTrialLuminance)
            %
            % in is a struct array with one entry for each correct answer port:
            % in.port                       1x1 integer denoting correct port for the parameters specified in this entry ("column") in the struct array
            %
            % stim properties:
            % in.distribution               'binary', 'uniform', or one of the following forms:
            %                                   {'sinusoidalFlicker',[temporalFreqs],[contrasts],gapSecs} - each freq x contrast combo will be shown for equal time in random order, total time including gaps will be in.loopDuration
            %                                   {'gaussian',clipPercent,seed} - choose variance so that clipPercent of an infinite stim would be clipped (includes both low and hi)
            %                                           seed - either 'new' or scalar uint32 
            %                                   {path, origHz, clipVal, clipType} - path is to a file (either .txt or .mat, extension omitted, .txt loadable via load()) containing a single vector of stim values named 'noise', with original sampling rate origHz.
            %                                       clipType:
            %                                       'normalized' will normalize whole file to clipVal (0-1), setting darkest val in file to 0 and values over clipVal to 1.
            %                                       'ptile' will normalize just the contiguous part of the file you are using to 0-1, clipping top clipVal (0-1) proportion of vals (considering only the contiguous part of the file you are using)
            % in.startFrame                 'randomize' or integer indicating fixed frame number to start with
            % in.loopDuration               in seconds (will be rounded to nearest multiple of frame duration, if distribution is a file, pass 0 to loop the whole file)
            %                               to make uniques and repeats, pass {numRepeats numUniques numCycles chunkSeconds centerThirdContrasts} - chunk refers to one repeat/unique - distribution cannot be sinusoidalFlicker
            %                                        centerThirdContrasts -- a vector of contrast values -1 to 1 to loop over, setting center 1/3 of each chunk
            % in.numLoops                   must be >0 or inf, fractional values ok (will be rounded to nearest frame)
            %
            % patch properties:
            % in.locationDistribution       2-d density, will be normalized to stim area
            % in.maskRadius                 std dev of the enveloping gaussian, normalized to diagonal of stim area (values <=0 mean no mask)
            % in.patchDims                  [height width]
            % in.patchHeight                0-1, normalized to stim area height
            % in.patchWidth                 0-1, normalized to stim area width
            % in.background                 0-1, normalized (luminance outside patch)
            %
            % filter properties:
            % in.orientation                filter orientation in radians, 0 is vertical, positive is clockwise
            % in.kernelSize                 0-1, normalized to diagonal of patch
            % in.kernelDuration             in seconds (will be rounded to nearest multiple of frame duration)
            % in.ratio                      ratio of short to long axis of gaussian kernel (1 means circular, no effective orientation)
            % in.filterStrength             0 means no filtering (kernel is all zeros, except 1 in center), 1 means pure mvgaussian kernel (center not special), >1 means surrounding pixels more important
            % in.bound                      .5-1 edge percentile for long axis of kernel when parallel to window

            for i=1:length(s.fieldNames)
                s.(s.fieldNames{i})=[];
            end

            switch nargin
                case 0  % if no input arguments, create a default object
                    
                case 1
                    if (isa(varargin{1},'filteredNoise'))	% if single argument of this class type, return it
                        s = varargin{1};
                    else
                        error('Input argument is not a filteredNoise object')
                    end
                case 5
                    if isstruct(varargin{1})  &&   all(ismember(fieldNames,fields(varargin{1})))  % create object using specified values

                        for j=1:length(varargin{1})
                            in=varargin{1}(j);

                            if isinteger(in.port) && in.port>0 && isscalar(in.port)
                                %pass
                            else
                                error('port must be scalar positive integer')
                            end


                            if isreal(in.orientation) && isscalar(in.orientation)
                                %pass
                            else
                                error('orientation must be real scalar')
                            end

                            if (isscalar(in.startFrame) && isinteger(in.startFrame) && in.startFrame>0)
                                varargin{1}(j).startFrame=uint32(in.startFrame); %otherwise our frame indices can't exceed the max of the datatype of the startframe, and there's no colon operator on uint64...
                            elseif strcmp(in.startFrame,'randomize')
                                %pass
                            else
                                error('start frame must be scalar integer >0 or ''randomize''')
                            end


                            isSinusoidalFlicker=false;
                            if isvector(in.distribution) && ischar(in.distribution) && ismember(in.distribution,{'uniform','binary'})
                                %pass
                            elseif iscell(in.distribution)
                                tmp.special=in.distribution{1};
                                if all(size(in.distribution)==[1 4]) && ismember(tmp.special,{'sinusoidalFlicker','squareFlicker'})
                                    tmp.freqs=in.distribution{2};
                                    tmp.contrasts=in.distribution{3};
                                    tmp.gapSecs=in.distribution{4};
                                    if isvector(tmp.freqs) && isreal(tmp.freqs) && isnumeric(tmp.freqs) && all(tmp.freqs>=0) && ...
                                            isvector(tmp.contrasts) && isreal(tmp.contrasts) && isnumeric(tmp.contrasts) && all(tmp.contrasts>=0) && all(tmp.contrasts<=1) && ...
                                            isscalar(tmp.gapSecs) && isreal(tmp.gapSecs) && isnumeric(tmp.gapSecs) && tmp.gapSecs>=0
                                        isSinusoidalFlicker=true;
                                    else
                                        error('temporalFreqs and contrasts must be real numeric vectors >=0, contrasts must be <=1, gapSecs must be real numeric scalar >=0')
                                    end
                                elseif all(size(in.distribution)==[1 3]) && strcmp(tmp.special,'gaussian')
                                    tmp.clipPercent=in.distribution{2};
                                    tmp.seed=in.distribution{3};

                                    if isscalar(tmp.clipPercent) && tmp.clipPercent>=0 && tmp.clipPercent<=1 && isreal(tmp.clipPercent)
                                        %pass
                                    else
                                        error('clipPercent must be real scalar 0<=x<=1')
                                    end

                                    if (isscalar(tmp.seed) && isa(tmp.seed,'uint32')) || (ischar(tmp.seed) && isvector(tmp.seed) && strcmp(tmp.seed,'new'))
                                        %pass
                                    else
                                        error('seed must be scalar uint32 or ''new''')
                                    end

                                elseif all(size(in.distribution)==[1 4]) && ismember(in.distribution{4},{'ptile','normalized'}) && any([exist([tmp.special '.txt'],'file') exist([tmp.special '.mat'],'file')]==2)
                                    tmp.origHz=in.distribution{2};
                                    tmp.clipVal=in.distribution{3};
                                    tmp.clipType=in.distribution{4};

                                    if isscalar(tmp.origHz) && tmp.origHz>0 && isreal(tmp.origHz) && isfloat(tmp.origHz)
                                        %pass
                                    else
                                        error('origHz must be real float scalar > 0')
                                    end

                                    if isscalar(tmp.clipVal) && tmp.clipVal>=0 && tmp.clipVal<=1 && isreal(tmp.clipVal)
                                        %pass
                                    else
                                        error('clipVal must be real scalar 0<=x<=1')
                                    end
                                else
                                    error('cell vector distribution must be one of {''gaussian'',clipPercent},  {''sinusoidalFlicker'',[temporalFreqs],[contrasts],gapSecs}, {filePath, origHz, clipVal, clipType} (filePath a string containing a file name (either .txt or .mat, extension omitted, .txt loadable via load()), clipType in {''ptile'',''normalized''}')
                                end
                                varargin{1}(j).distribution=tmp;
                            else
                                in.distribution
                                error('distribution must be one of ''uniform'', ''binary'', or a cell vector')
                            end

                            if isscalar(in.loopDuration) && isreal(in.loopDuration) && in.loopDuration>=0
                                %pass
                            elseif iscell(in.loopDuration) && isvector(in.loopDuration) && all(size(in.loopDuration)==[1 5]) && ~isSinusoidalFlicker
                                tmp.numRepeats = in.loopDuration{1};
                                tmp.numUniques = in.loopDuration{2};
                                tmp.numCycles =  in.loopDuration{3};
                                tmp.chunkSeconds =  in.loopDuration{4};
                                tmp.centerThirdContrasts = in.loopDuration{5};
                                if isscalar(tmp.numRepeats) && isinteger(tmp.numRepeats) && tmp.numRepeats>=0 && ...
                                        isscalar(tmp.numUniques) && isinteger(tmp.numUniques) && tmp.numUniques>=0 && ...
                                        isscalar(tmp.numCycles) && isinteger(tmp.numCycles) && tmp.numCycles>0 && ...
                                        isscalar(tmp.chunkSeconds) && isreal(tmp.chunkSeconds) && isnumeric(tmp.chunkSeconds) && tmp.chunkSeconds>0 && ...
                                        isvector(tmp.centerThirdContrasts) && isreal(tmp.centerThirdContrasts)% && all(tmp.centerThirdContrasts>=-1) && all(tmp.centerThirdContrasts<=1)
                                    %convert to doubles to avoid int overflow issues when used in computeFilteredNoise
                                    tmp.numRepeats = double(tmp.numRepeats);
                                    tmp.numUniques = double(tmp.numUniques);
                                    tmp.numCycles =  double(tmp.numCycles);
                                    tmp.chunkSeconds =  double(tmp.chunkSeconds);
                                    tmp.centerThirdContrasts = double(tmp.centerThirdContrasts);
                                    varargin{1}(j).loopDuration=tmp;
                                else
                                    error('numRepeats and numUniques must be scalar integers >=0, numCycles must be scalar integer >0, chunkSeconds must be scalar numeric real >0, and centerThirdContrasts must be vector of reals')
                                end
                            else
                                error('loopDuration must be real scalar >=0, zero loopDuration means 1 static looped frame, except for file stims, where it means play the whole file instead of a subset. to make uniques and repeats, pass {numRepeats numUniques numCycles chunkSeconds centerThirdContrasts} - chunk refers to one repeat/unique - distribution cannot be sinusoidalFlicker')
                            end

                            if in.numLoops>0 && isscalar(in.numLoops) && isreal(in.numLoops)
                                %pass
                            else
                                error('numLoops must be >0 real scalar or inf')
                            end

                            if isreal(in.maskRadius) && isscalar(in.maskRadius)
                                %pass
                            else
                                error('maskRadius must be real scalar')
                            end

                            pos={in.kernelDuration in.filterStrength};
                            for i=1:length(pos)
                                if isscalar(pos{i}) && isreal(pos{i}) && pos{i}>=0
                                    %pass
                                else
                                    error('kernelDuration and filterStrength must be real scalars >=0')
                                end
                            end


                            norms={in.background in.patchHeight in.patchWidth in.kernelSize in.ratio};
                            goodNorms=true;
                            for i=1:length(norms)
                                if isscalar(norms{i}) && isreal(norms{i}) && norms{i}<=1
                                    if norms{i}>0
                                        %pass
                                    else
                                        if i==1 && in.background==0
                                            %pass
                                        elseif i==4 && in.kernelSize==0
                                            %pass
                                        else
                                            goodNorms=false;
                                        end
                                    end
                                else
                                    goodNorms=false;
                                end
                            end
                            if ~goodNorms
                                error('background, patchHeight, patchWidth, kernelSize, and ratio must be 0<x<=1, real scalars (exception: background and kernelSize can be 0, zero kernelSize means no spatial extent beyond 1 pixel (may still have kernelDuration>0))')
                            end


                            if length(size(in.locationDistribution))==2 && isreal(in.locationDistribution) && all(in.locationDistribution(:)>=0) && sum(in.locationDistribution(:))>0
                                %pass
                            else
                                error('locationDistribution must be 2d real and >=0 with at least one nonzero entry')
                            end


                            if all(size(in.patchDims)==[1 2]) && all(in.patchDims)>0 && strcmp(class(in.patchDims),'uint16')
                                %pass
                            else
                                error('patchDims should be [height width] uint16 > 0')
                            end


                            if ~isreal(in.bound) || ~isscalar(in.bound) || in.bound<=.5 || in.bound>=1
                                error('bound must be real scalar .5<x<1')
                            end


                        end

                        in=varargin{1};

                        for i=1:length(fieldNames)
                            s.(fieldNames{i})={in.(fieldNames{i})};
                        end

                        
                    else
                        required=fieldNames'
                        have=fields(varargin{1})
                        setdiff(required,have)
                        error('input must be struct with all of the above fields')

                    end
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [stimulus,updateSM,resolutionIndex,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,interTrialStim,LUT,targetPorts,distractorPorts, ...
    details,interTrialLuminance,text,indexPulse,imagingTasks] =...
    calcStim(stimulus,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % see ratrixPath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)
            % 1/3/0/09 - trialRecords now includes THIS trial
            imagingTasks=[];

            if ~all(ismember([stimulus.port{:}],responsePorts))
                error('not all the expected correct response ports were available in responsePorts')
            end

            LUT=makeLinearizedLUT('trinitron');%makeStandardLUT(LUTbits);

            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus); 
            interTrialDuration = getInterTrialDuration(stimulus);

            details.pctCorrectionTrials=.5; % need to change this to be passed in from trial manager
            details.bias = getRequestBias(trialManager);

            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);

            typeInd=find([stimulus.port{:}]==targetPorts);

            if isinf(stimulus.numLoops{typeInd})
                type='loop';
            else
                type='cache';
            end

            if length(typeInd)==0
                error('no matching target port')
            elseif length(typeInd)>1
                typeInd=typeInd(ceil(rand*length(typeInd))); %choose random type with matching port for this trial
            end

            if ~isempty(resolutions)
                [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[100 60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
            else
                if isfield(stimulus.distribution{typeInd},'origHz')
                    resolutionIndex=stimulus.distribution{typeInd}.origHz;
                else
                    resolutionIndex=100; %for LED
                end
                height=1;
                width=1;
                hz=resolutionIndex;
            end

            if hz==0
                if ismac
                    hz=60; %assume laptop lcd
                else
                    error('got 0 hz on non-mac')
                end
            end

            fprintf('about to compute stim\n')
            if isempty(stimulus.cache) || isempty(stimulus.hz) || stimulus.hz~=hz
                stimulus=computeFilteredNoise(stimulus,hz);

                if false && isstruct(stimulus.loopDuration{typeInd}) && size(stimulus.cache{typeInd},1)==1 && size(stimulus.cache{typeInd},2)==1
                    sca

                    if isfield(stimulus.distribution{typeInd}, 'origHz')
                        efStimOrig=load([stimulus.distribution{typeInd}.special '.txt']);
                        subplot(2,1,1)

                        plot(efStimOrig(1: round(stimulus.distribution{typeInd}.origHz * stimulus.loopDuration{typeInd}.chunkSeconds  )))
                        subplot(2,1,2)
                    end

                    efStim=squeeze(stimulus.cache{typeInd});

                    chunkLength = length(efStim)/(stimulus.loopDuration{typeInd}.numCycles * (stimulus.loopDuration{typeInd}.numRepeats+stimulus.loopDuration{typeInd}.numUniques));
                    numChunks = length(efStim)/chunkLength;
                    if numChunks ~= round(numChunks) || chunkLength ~= round(chunkLength)
                        error('partial chunk')
                    end
                    for ef=1:numChunks
                        plot(efStim((1:chunkLength)+(ef-1)*chunkLength)-ef)
                        hold on
                    end

                    keyboard
                end

                updateSM=true;
            else
                updateSM=false;
            end
            fprintf('done computing stim\n')

            pre=stimulus.cache{typeInd};

            details.hz=stimulus.hz;

            detailFields={'distribution','startFrame','loopDuration','maskRadius','patchDims','patchHeight','patchWidth','background','orientation','kernelSize','kernelDuration','ratio','filterStrength','bound','inds','seed','sha1'};
            for i=1:length(detailFields)
                details.(detailFields{i})=stimulus.(detailFields{i}){typeInd};
            end

            if ~isstruct(details.loopDuration)
                if strcmp(details.startFrame,'randomize')
                    details.startFrame=ceil(rand*size(pre,3));
                end

                if details.startFrame>size(pre,3)
                    details.startFrame
                    size(pre)
                    error('startFrame was too large')
                end
                pre=pre(:,:,[details.startFrame:size(pre,3) 1:details.startFrame-1]);
                indexPulse=false(1,size(pre,3));
                indexPulse(1)=true;
            else
                chunkLength = size(pre,3)/(details.loopDuration.numCycles * (details.loopDuration.numRepeats+details.loopDuration.numUniques));
                numChunks = size(pre,3)/chunkLength;
                if numChunks ~= round(numChunks) || chunkLength ~= round(chunkLength)
                    error('partial chunk')
                end
                indexPulse=false(1,chunkLength);
                indexPulse(1)=true;
                indexPulse=repmat(indexPulse,1,numChunks);
            end

            h=size(pre,1);
            w=size(pre,2);

            if ~isempty(resolutions)

                details.location=drawFrom2Ddist(stimulus.locationDistribution{typeInd});

                if false %correct positioning/sizing - imresize runs out of memory for long stims - could do in a for loop?
                    maxPositionalError=.01;
                    if any([h/details.patchHeight w/details.patchWidth] < 1/maxPositionalError) %if pre's size is too small or the patch size is too large, positioning/sizing will be too coarse
                        pre=imresize(pre,[details.patchHeight details.patchWidth]/maxPositionalError,'nearest');
                        h=size(pre,1);
                        w=size(pre,2);
                    end
                end

                out=details.background*ones(round(h/details.patchHeight),round(w/details.patchWidth),size(pre,3));
                rinds=ceil(size(out,1)*details.location(2)+[1:h]-(h+1)/2);
                cinds=ceil(size(out,2)*details.location(1)+[1:w]-(w+1)/2);
                rbad = rinds<=0 | rinds > size(out,1);
                cbad = cinds<=0 | cinds > size(out,2);

                out(rinds(~rbad),cinds(~cbad),:)=pre(~rbad,~cbad,:);

                width=size(out,2);
                height=size(out,1);
                d=sqrt(sum([height width].^2));
                [a b]=meshgrid(1:width,1:height);
                if details.maskRadius>0
                    mask=reshape(mvnpdf([a(:) b(:)],[width height].*details.location,(details.maskRadius*d)^2*eye(2)),height,width);
                else
                    mask=ones(height,width);
                end
                mask=mask/max(mask(:)); %DO NOT also normalize bottom to zero!  will effectively change radius to be same as patch size.

                out=(out-details.background).*mask(:,:,ones(1,size(pre,3)))+details.background;
            else
                if any([h w]~=1)
                    error('LED only works with 1x1 output')
                end
                out=pre;
            end

            if any(out(:)<0) || any(out(:)>1)
                error('vals outside range somehow')
            end
            %out(out<0)=0;
            %out(out>1)=1;
            %out=uint8(double(intmax('uint8'))*out);

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

            preResponseStim=discrimStim;
            preResponseStim.punishResponses=false;

            postDiscrimStim = [];

            interTrialStim.duration = interTrialDuration;

            details.interTrialDuration = interTrialDuration;
            if isfield(details,'correctionTrial') && details.correctionTrial;
                text='correction trial!';
            else
                text=sprintf('target: %d',targetPorts);
            end
        end
        
        function s=decache(s)
            s.cache={};
            s.seed={};
            s.sha1={};
            s.hz=[];
            s.inds={};
        end
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case {'nAFC','autopilot','freeDrinks','reinforcedAutopilot'}
                        out=true;
                    otherwise
                        out=false;
                end
            else
                error('need a trialManager object')
            end
        end
        
        function checkHateren
            fileName='ts001.txt';
            hz=1200;
            newHz=100;

            durs=[8 33*8 45*60];
            cols={'r' 'g' 'b'};

            cut=12800;% of 32767 =  intmax('int16')
            bottom=1/3;

            binSize=30;

            norm=true;

            clc
            close all

            x=load(fileName);

            if norm
                x=normalize(x);
                cut=cut/double(intmax('int16'));
                binSize=binSize/double(intmax('int16'));
            end

            bins=(0:binSize:max(x));
            times=(0:(length(x)-1))/hz;

            newX=resample(x,newHz,hz);
            newX(newX<0)=0;
            if norm
                %newX=normalize(newX); %DO NOT NORMALIZE!  resampling has added some (negative) artifacts that will cause normalization to dramatically reduce contrast! 
                newX(newX>1)=1;
            else
                newX(newX>intmax('int16'))=intmax('int16');
            end
            newTimes=(0:(length(newX)-1))/newHz;

            for i=1:length(durs)
                subplot(length(durs)+1,1,i)

                inds=1:durs(i)*hz;
                y=x(inds);
                theseTimes=times(inds);
                plot(theseTimes,y,cols{i})

                hold on
                inds=1:durs(i)*newHz;
                newY=newX(inds);
                plot(newTimes(inds),newY,'k')

                plot([0 max(theseTimes)],cut*ones(1,2),'k')
                plot([0 max(theseTimes)],bottom*cut*ones(1,2),'k')

                h{i}=hist(y,bins);
                newH{i}=hist(newY,bins);

                strs{i}=sprintf('first %g secs - %g%%/%g%% are above %g, %g%%/%g%% are below %g',durs(i),pct(sum(y>cut)/length(y),1),pct(sum(newY>cut)/length(newY),1),cut,pct(sum(y<cut*bottom)/length(y),1),pct(sum(newY<cut*bottom)/length(newY),1),bottom);
                title(strs{i})
            end

            maxH=0;
            subplot(length(durs)+1,1,length(durs)+1)
            for i=1:length(h)
                normalized=h{i}/sum(h{i});
                if max(normalized)>maxH
                    maxH=max(normalized);
                end
                semilogy(bins,normalized,cols{i})
                hold on

                normalized=newH{i}/sum(newH{i});
                semilogy(bins,normalized,'k')
            end
            semilogy(cut*ones(1,2),[10^-10 maxH],'k')
            semilogy(bottom*cut*ones(1,2),[10^-10 maxH],'k')
        end

        function out=pct(val,decs)
            out=round(100*10^decs*val)/10^decs;
        end

        %can use ratrix\classes\util\matlaby\normalize if don't mind doubleified output
        function x=normalize(x)
            x=x-min(x(:));
            x=x/max(x(:));
        end
        
        %intent: stim output always btw 0-1 (DO NOT NORMALIZE to cover whole range - example would be dark segment of natural timeseries)
        function stimulus=computeFilteredNoise(stimulus,hz)
            stimulus.hz=hz;
            filteringOK = false;

            for i=1:length(stimulus.port)

                %convert to double to avoid int overflow problems
                sz=double(stimulus.patchDims{i}); %[height, width]

                scale=floor(stimulus.kernelSize{i}*sqrt(sum(sz.^2)));
                if rem(scale,2)==0
                    scale=scale+1; %want nearest odd integer
                end

                bound=norminv(stimulus.bound{i},0,1); %only appropriate cuz marginal of mvnorm along one of its axes is norm with same variance as that eigenvector's eigenvalue

                %a multivariate gaussian's equidensity contours are ellipsoids
                %principle axes given by the eigenvectors of its covariance matrix
                %the eigenvalues are the squared relative lengths
                %sigma = ULU' where U's columns are unit eigenvectors (a rotation matrix) and L is a diagonal matrix of eigenvalues
                axes=eye(2); %note that interpretation depends on axis xy vs. axis ij
                rot=[cos(stimulus.orientation{i}) -sin(stimulus.orientation{i}); sin(stimulus.orientation{i}) cos(stimulus.orientation{i})];
                axes=rot*axes;
                sigma=axes*diag([stimulus.ratio{i} 1].^2)*axes';

                [a b]=meshgrid(linspace(-bound,bound,scale));
                kernel=reshape(mvnpdf([a(:) b(:)],0,sigma),scale,scale);
                kernel=stimulus.filterStrength{i}*kernel/max(kernel(:));

                kernel(ceil(scale/2),ceil(scale/2))=1; %so filterStrength=0 means identity

                dur=round(stimulus.kernelDuration{i}*hz);
                if dur==0
                    k=kernel;
                else
                    t=normpdf(linspace(-bound,bound,dur),0,1);

                    for j=1:dur
                        k(:,:,j)=kernel*t(j);
                    end
                end

                k=k/sqrt(sum(k(:).^2));  %to preserve contrast (tho only for gaussian stimuli)
                %filtering effectively summed a bunch of independent gaussians with variances determined by the kernel entries
                %if X ~ N(0,a) and Y ~ N(0,b), then X+Y ~ N(0,a+b) and cX ~ N(0,ac^2)
                %must be a deep reason this is same as pythagorean
                %note that stim mean must be zero for this to work!

                if isstruct(stimulus.loopDuration{i})
                    chunkSize=round(hz*stimulus.loopDuration{i}.chunkSeconds); %number of frames in a single repeat or unique
                    frames=chunkSize*(1 + stimulus.loopDuration{i}.numCycles*stimulus.loopDuration{i}.numUniques); %the number of raw frames we need, before making the repeats/uniques
                    totalFrames=stimulus.loopDuration{i}.numCycles*chunkSize*(stimulus.loopDuration{i}.numRepeats+stimulus.loopDuration{i}.numUniques);
                else
                    frames=max(1,round(stimulus.loopDuration{i}*hz));
                end

                if ~isfield(stimulus.distribution{i},'seed') || strcmp(stimulus.distribution{i}.seed,'new')
                    maxSeed=2^32-1;
                    s=GetSecs;
                    stimulus.seed{i}=round((s-floor(s))*maxSeed);
                else
                    stimulus.seed{i}=double(stimulus.distribution{i}.seed);
                end
                stimulus.inds{i}=[];
                if isstruct(stimulus.distribution{i}) && ismember(stimulus.distribution{i}.special,{'sinusoidalFlicker','squareFlicker'})
                    stimulus.distribution{i}.conditions=getShuffledCross({stimulus.distribution{i}.contrasts,stimulus.distribution{i}.freqs});
                    noise=[];
                    dur=(stimulus.loopDuration{i}/length(stimulus.distribution{i}.conditions))-stimulus.distribution{i}.gapSecs;
                    for j=1:length(stimulus.distribution{i}.conditions)
                        noise=[noise stimulus.distribution{i}.conditions{j}{1}*makeSinusoid(hz,stimulus.distribution{i}.conditions{j}{2},dur,stimulus.distribution{i}.special) zeros(1,round(stimulus.distribution{i}.gapSecs*hz))];
                    end
                    noise=.5+noise/2;

                    %these should not be needed, and happen later anyway
                    %noise(noise>1)=1;
                    %noise(noise<0)=0;

                    noise=permute(noise,[3 1 2]);
                    repmat(noise,[sz 1]); %shouldn't this be noise=?

                    if ~all(sz==1)
                        error('the code is probably wrong for size other than [1 1]')
                    end
                elseif ischar(stimulus.distribution{i}) && ismember( stimulus.distribution{i},  {'binary','uniform'} )
                    % consider adding offset/contrast for these types
                    rand('twister',stimulus.seed{i});
                    noise=rand([sz frames]);
                    if strcmp(stimulus.distribution{i},'binary')
                        noise=(noise>.5);
                    end
                elseif isstruct(stimulus.distribution{i})
                    switch stimulus.distribution{i}.special
                        case 'gaussian'

                            randn('state',stimulus.seed{i});
                            noise=randn([sz frames])*pickContrast(.5,stimulus.distribution{i}.clipPercent) +.5;

                            hiClipInds=noise>1;
                            loClipInds=noise<0;
                            fprintf('*** gaussian: clipping %g%% of values (should be %g%%)\n',100*(sum(hiClipInds(:))+sum(loClipInds(:)))/numel(noise),100*stimulus.distribution{i}.clipPercent)

                            %these will happen later, and screw up the gaussian-contrast-preserving filtering if done now
                            %noise(hiClipInds)=1;
                            %noise(loClipInds)=0;

                            filteringOK=true;
                        otherwise
                            if ~isstruct(stimulus.loopDuration{i}) && stimulus.loopDuration{i}==0
                                frames=0;
                            end
                            [noise stimulus.inds{i}]=loadStimFile(stimulus.distribution{i}.special,stimulus.distribution{i}.origHz,hz,frames/hz,stimulus.startFrame{i});

                            if size(noise,1)>1
                                noise=noise';
                            end

                            noise=permute(noise,[3 1 2]);
                            repmat(noise,[sz 1]); %shouldn't this be noise=?

                            if ~all(sz==1)
                                error('the code is probably wrong for size other than [1 1]')
                            end

                            switch stimulus.distribution{i}.clipType
                                case 'normalized'
                                    %DO NOT NORMALIZE - want to keep clip relative to whole file
                                    clipPoint=stimulus.distribution{i}.clipVal;
                                case 'ptile'
                                    noise=normalize(noise);
                                    clipPoint=prctile(noise,100*(1-stimulus.distribution{i}.clipVal));
                                otherwise
                                    error('bad clipType')
                            end

                            clipInds=noise>clipPoint;
                            fprintf('*** hateren: clipping %g%% of values (should be 1%% to match reinagel reid 2000)\n',100*sum(clipInds(:))/numel(noise))
                            noise(clipInds)=clipPoint;
                            noise=noise/clipPoint; %DO NOT NORMALIZE in case the whole clip is darker than the clip val or brighter than zero
                            fprintf('*** hateren: %g%% values below 1/3 of max (should be 73%% to match reinagel reid 2000)\n',100*sum(noise(:)<(1/3)*max(noise(:)))/numel(noise))
                    end

                else
                    stimulus.distribution{i}
                    error('bad distribution')
                end

                if isstruct(stimulus.loopDuration{i})
                    if isstruct(stimulus.distribution{i}) && strcmp(stimulus.distribution{i}.special,'sinusoidalFlicker')
                        error('can''t have rpts/unqs for sinusoidalFlicker')
                    end

                    new=nan*zeros(size(noise,1),size(noise,2),totalFrames);
                    rpt=noise(:,:,1:chunkSize);

                    clipNow=true;  %if we don't clip now, lowering the contrast will bring more values in range, so the stim won't be exactly preserved
                    %but note clipping now slightly screws up gaussian contrast preserving filtering below
                    if clipNow && ~all(stimulus.loopDuration{i}.centerThirdContrasts>=1)
                        rpt(rpt<0)=0;
                        rpt(rpt>1)=1;
                    end

                    start=1;
                    unqPos=chunkSize+1;
                    contrastMask=ones(size(rpt));
                    contrastFix=zeros(size(rpt));
                    contrastInds=round(chunkSize/3) : round(2*chunkSize/3);
                    contrastMaskInd=0;
                    for c=1:stimulus.loopDuration{i}.numCycles
                        for r=1:stimulus.loopDuration{i}.numRepeats
                            thisContrast=stimulus.loopDuration{i}.centerThirdContrasts(mod(contrastMaskInd,length(stimulus.loopDuration{i}.centerThirdContrasts))+1);
                            contrastMask(:,:,contrastInds)=thisContrast;
                            contrastFix(:,:,contrastInds)=(1-thisContrast)/2; %keeps mean at .5
                            contrastMaskInd=contrastMaskInd+1;

                            new(:,:,start:start+chunkSize-1)=rpt.*contrastMask+contrastFix;
                            start=start+chunkSize;
                        end
                        for u=1:stimulus.loopDuration{i}.numUniques
                            new(:,:,start:start+chunkSize-1)=noise(:,:,unqPos:unqPos+chunkSize-1);
                            start=start+chunkSize;
                            unqPos=unqPos+chunkSize;
                        end
                    end
                    if any(isnan(new(:)))
                        error('miss!')
                    end
                    if unqPos~=1+size(noise,3)
                        error('miss!')
                    end
                    noise=new;
                end

                try
                    stimulus.sha1{i} = hash(noise,'SHA-1');
                catch ex
                    if ~isempty(findstr('OutOfMemoryError',ex.message))
                        stimulus.sha1{i} = hash(noise(1:1000),'SHA-1');
                    else
                        rethrow(ex);
                    end
                end

                t=zeros(size(k));
                t(ceil(length(t(:))/2))=1;
                if all(rem(size(k),2)==1) && all(k(:)==t(:))
                    %identity kernel, don't waste time filtering
                    stim=noise;
                    for j=1:4
                        beep;pause(.1);
                    end
                else
                    if ~filteringOK
                        error('you shouldn''t filter non-gaussian stims')
                    end

                    theMean=mean(noise(:));
                    tic
                    %stim=convn(noise,k,'same'); %slower than imfilter
                    stim=imfilter(noise-theMean,k,'circular')+theMean; %allows looping, does it keep edges nice?

                    %for reasonable stims, takes 6x realtime on fast systems
                    %i have circular filtering worked out by hand in matlab, to translate to gpu shader to get realtime speed
                    %tho note problems: http://tech.groups.yahoo.com/group/psychtoolbox/message/8742

                    %http://blogs.mathworks.com/steve/2006/11/28/separable-convolution-part-2/#comment-21123
                    %alternative: work out how to do in fourier domain
                    %from cris niell: ifft(randn*freqs*exp(2*pi*i*phases)  (here, randn and phases are space x space x time)
                    %requires some fftshifting, symmetry issues, etc.

                    fprintf('took %g to filter noise\n',toc)
                end

                stim(stim>1)=1;%DO NOT NORMALIZE!!!
                stim(stim<0)=0;

                saveOutput=false;
                if saveOutput
                    bitDepth=8;
                    if size(stim,1)==1 && size(stim,2)==1 && isstruct(stimulus.loopDuration{i})
                        numChunks=stimulus.loopDuration{i}.numCycles*(stimulus.loopDuration{i}.numUniques + stimulus.loopDuration{i}.numRepeats);
                        plottable=reshape(floor(stim*2^bitDepth),chunkSize,numChunks)+repmat(2^bitDepth*(0:numChunks-1),chunkSize,1);
                        save(sprintf('filteredNoise_%d_%s_%.100g.mat',i,datestr(now,30),GetSecs),'plottable','stim')
                    else
                        warning('can''t save/plot stim that isn''t 1x1xn or doesn''t have rpts/unqs')
                    end
                end

                comparePreAndPostFilteredDistributions=false;
                if comparePreAndPostFilteredDistributions
                    % for some reason, filtered is coming out slightly lower contrast... why?  rounding errors?

                    sca
                    noise(noise>1)=1;
                    noise(noise<0)=0;
                    [h b]=hist(stim(:),1000);
                    h2=hist(noise(:),b);
                    subplot(2,1,1)
                    plot(b,[h' h2'])
                    legend({'filtered','unfiltered'})
                    xlim([-.1 1.1])
                    subplot(2,1,2)
                    plot(b,h-h2)
                    hold on
                    plot(b,ones(1,length(b)))
                    legend('filtered-unfiltered')
                    xlim([-.1 1.1])
                    keyboard
                end

                if isinf(stimulus.numLoops{i})
                    stimulus.cache{i}=stim;
                else
                    f=floor(stimulus.numLoops{i});
                    r=round((stimulus.numLoops{i}-f)*size(stim,3));
                    stimulus.cache{i}=repmat(stim,[1,1,f]);
                    stimulus.cache{i}(:,:,end+1:end+r)=stim(:,:,1:r);
                end

            end
        end
        
        function grainedNoise
            error('this is just old scratch work')
            close all
            clc

            sz=[50 50]; %height, width

            angles=[linspace(0,pi,10) pi/2+pi/10]; %radians, where 0 is vertical, positive is CW
            ratio=1/3; %ratio of long axis to short axis length

            amp=.025;%.0175; %1; %0 means no filtering (kernel is all zeros, except 1 in center), 1 means pure mvgaussian kernel (center not special), >1 means surrounding pixels more important

            scale = .5; %kernel size relative to stim, normalized to diagonal of stim
            bound=.99; %edge percentile for long axis of kernel when parallel to window

            bits=8;

            if ratio<=0 || ratio>1
                error('0<ratio<=1')
            end

            if scale<=0 || scale>1
                error('0<scale<=1')
            end
            scale=floor(scale*sqrt(sum(sz.^2)));
            if rem(scale,2)==0
                scale=scale+1; %want nearest odd integer
            end
            scale

            if bound<=.5 || bound>=1
                error('.5<=bound<=1')
            end
            bound=norminv(bound,0,1); %only appropriate cuz marginal of mvnorm along one of its axes is norm with same variance as that eigenvector's eigenvalue

            noise=randn(sz);

            colormap(gray(2^bits))
            for i=1:length(angles)
                %a multivariate gaussian's equidensity contours are ellipsoids
                %principle axes given by the eigenvectors of its covariance matrix
                %the eigenvalues are the squared relative lengths
                %sigma = ULU' where U's columns are unit eigenvectors (a rotation matrix) and L is a diagonal matrix of eigenvalues
                axes=eye(2); %note that interpretation depends on axis xy vs. axis ij
                rot=[cos(angles(i)) -sin(angles(i)); sin(angles(i)) cos(angles(i))];
                axes=rot*axes;
                sigma=axes*diag([ratio 1].^2)*axes';

                [a b]=meshgrid(linspace(-bound,bound,scale));
                kernel=reshape(mvnpdf([a(:) b(:)],0,sigma),scale,scale);
                kernel=amp*kernel/max(kernel(:));

                kernel(ceil(scale/2),ceil(scale/2))=1; %so amp=0 means identity
                kernel=kernel/sqrt(sum(kernel(:).^2));  %to preserve contrast
                %filtering effectively summed a bunch of independent gaussians with variances determined by the kernel entries
                %if X ~ N(0,a) and Y ~ N(0,b), then X+Y ~ N(0,a+b) and cX ~ N(0,ac^2)
                %must be a deep reason this is same as pythagorean

                stim=filter2(kernel,noise);
                %stim=stim/sqrt(sum(kernel(:).^2)); %alternative to above, but cooler to have self correcting kernel operator

                numplots=4;

                axes=rot*diag([ratio 1]);
                subplot(numplots,length(angles),i)
                plot([0 axes(1,1)],[0 axes(2,1)])
                hold on
                plot([0 axes(1,2)],[0 axes(2,2)])
                axis([-1 1 -1 1])
                axis equal
                axis ij

                subplot(numplots,length(angles),length(angles)+i)
                imagesc(kernel);
                axis image

                subplot(numplots,length(angles),2*length(angles)+i)
                image(rescale(stim,2^bits-1));
                axis image

                subplot(numplots,length(angles),3*length(angles)+i)
                [a b]=hist(noise(:),100);
                c=hist(stim(:),b);
                plot(b,[a' c'])
            end

            if true
                frames=60*2;%100*20;
                dur=15;

                noise=randn([sz frames]);
                t=normpdf(linspace(-bound,bound,dur),0,1);

                plotSTkern=false;
                if plotSTkern
                    figure
                end
                colormap(gray(2^bits))
                for i=1:dur
                    k(:,:,i)=kernel*t(i);
                    if plotSTkern
                        subplot(1,dur,i)
                        imagesc(k(:,:,i),[0 1])
                        axis image
                    end
                end
                k=k/sqrt(sum(k(:).^2));
                %stim=convn(noise,k,'same');
                tic
                stim=imfilter(noise,k,'circular'); %allows looping, does it keep edges nice?
                toc
                stim=1+rescale(stim,2^bits-1);

                save('stim.mat','stim');

                plotFrames=false;
                if plotFrames
                    n=ceil(sqrt(frames+1));
                    figure
                end
                map=colormap(gray(2^bits));
                noise=1+rescale(noise,2^bits-1);
                [a b]=hist(noise(:),100);
                reps=10;
                for i=1:frames
                    M(frames*(0:reps-1)+i) = im2frame(stim(:,:,i),map);
                    if plotFrames
                        subplot(ceil((frames+1)/n),n,i)
                        image(stim(:,:,i));
                        axis image

                        subplot(n,n,n^2)
                        hold on
                        c=hist(stim(:,:,i),b);
                        plot(b,c/sum(c))
                    end
                end
                if plotFrames
                    plot(b,a/sum(a),'r')
                end
                movie2avi(M,'mCinepak','compression','Cinepak','quality',100,'fps',60)
            end
        end

        function out=rescale(in,mx)
            in=in-min(in(:));
            out=mx*in/max(in(:));
            if any(abs([min(out(:)) max(out(:))]-[0 mx])>.0000001)
                error('scale error')
            end
        end
        
        function [noise outInds]=loadStimFile(fileName,oldHz,newHz,duration,startFrame)
            if 2==exist([fileName '.mat'],'file')
                noise=load([fileName '.mat']);
                noise=noise.noise;
            elseif 2==exist([fileName '.txt'],'file')
                tic
                noise=load([fileName '.txt']);
                fprintf('load took %g secs\n',toc)

                %textscan is slightly slower
                %     tic
                %     fid = fopen([fileName '.txt']);
                %     C = textscan(fid, '%d');
                %     fclose(fid);
                %     fprintf('textscan took %g secs\n',toc)
                %     noise=C{1};

                encodeAsInt=false;
                if encodeAsInt %no file size gain, but RAM gain
                    if any(noise ~= round(noise))
                        error('file contained some non-integers')
                    end

                    noise=noise-min(noise);

                    bits=ceil(log2(max(noise)));
                    bits=num2str(2^nextpow2(bits));
                    if ismember(bits,{'8' '16' '32' '64'})
                        intType=['uint' bits];
                        noise=feval(intType,noise);
                        if ~strcmp(class(noise),intType)
                            error('cast didn''t work')
                        end
                    else
                        error('couldn''t encode as uints')
                    end
                end

                save([fileName '.mat'],'noise');
            else
                error('can''t find file')
            end

            if ~(isvector(noise) && isreal(noise) && isnumeric(noise))
                error('file contents not real numeric vector')
            end

            noise=normalize(noise); %IMPORTANT that this is relative to the whole file!

            outInds=[];
            if duration>0
                lastAvailable=length(noise)-duration*oldHz+1;
                if strcmp(startFrame,'randomize')
                    start=ceil(rand*lastAvailable);
                elseif startFrame>0 && startFrame<=lastAvailable
                    start=double(startFrame);
                else
                    error('startFrame is too large and would require wrapping around to beginning of file')
                end
                inds=start:start+duration*oldHz-1;
                noise=noise(inds);
                outInds=[inds(1) inds(end)];
            end

            mins=(0:(length(noise)-1))/oldHz/60;
            doplot=false;
            if doplot
                plot(mins,noise,'r')
                hold on
            end

            if oldHz~=newHz
                method='resample';
                tic
                switch method
                    case 'resample'

                        newNoise=resample(noise,newHz,oldHz);

                    case 'integrate'

                        newMins=0:1/(newHz*60):max(mins);

                        newNoise=zeros(1,length(newMins));

                        for m=1:length(newNoise)

                            inds=find(mins>=newMins(m) & mins<newMins(m)+1/(newHz*60));
                            newNoise(m)=newNoise(m)+sum(noise(inds));

                            if m~=1
                                p=(newMins(m)-mins(min(inds)-1))*60*oldHz;
                                newNoise(m-1)=newNoise(m-1)+p*noise(min(inds)-1);
                                newNoise(m)=newNoise(m)+(1-p)*noise(min(inds)-1);
                            end

                            if rand>.99
                                fprintf('%g%% done\n',100*m/length(newNoise))
                            end
                        end

                        if doplot
                            plot(newMins,normalize(newNoise),'b')
                            plot(newMins,normalize(resample(noise,newHz,oldHz)),'g')
                            legend({'original','integrated','resampled'})
                        end

                    otherwise
                        error('bad method')
                end
                fprintf('resample took %g secs\n',toc);

                if length(noise)/oldHz~=length(newNoise)/newHz
                    error('resampling gave wrong length for new sig')
                end
                noise=newNoise;
                %noise=normalize(noise); MUST NOT NORMALIZE!  resampling has added artifacts outside of expected range such that normalizing will reduce contrast!
                %                                             plus, if you are in a dark chunk of the file, you want it to stay that way!
                noise(noise>1)=1;
                noise(noise<0)=0;
            end

        end

        
        
    end
    
end


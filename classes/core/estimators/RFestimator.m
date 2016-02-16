classdef RFestimator
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        centerParams=[];
        boundaryParams=[];
        eyeParams=[];
        dataSource=[];
        dateRange=[];

        cache=[];
    end
    
    methods
        function RFe = RFestimator(varargin)
        % RFestimator constructor
        %
        % RFe = RFestimator(centerParams,boundaryParams,eyeParams,dataSource,dateRange)
        %
        % centerParams - a cell array of {stimClass,method,params} used by getCenter
        % boundaryParams - a cell array of {stimClass,method,params} used by getBoundary
        %
        % stimClass - the type of stimulus used to induce a RF (eg 'whiteNoise')
        % method - method for estimating the receptive field (eg 'centerOfMass', 'significantCoherence', 'fitGaussian','lastDynamicSetting')
        % params - method-specific estimation parameters as a cell array
        % eyeParams - cell array of eye parameters, empty for now
        % dataSource - the path to the analysis files (always set to datanet_storage/) - this should not include ...demo1/analysis
        %(pmm: b/c we have to adapt to different subjects!) (fan:because we look there in the call to getNeuralAnalysis)
        % dateRange - range of dates within which to look for analysis results
        %
        % from phil:
        % always gets the most recent analysis result within RFestimator.dateRange
        % phys setup will choose dateRange=[floor(now) Inf] to specify today
        % centerDataSource='whiteNoise'; (%could be other stuff)
        %
        % centerParameters= {dataSource,method,params}
        % ie. {'whiteNoise','centerOfMass',{
        % alphaSignificantPixels medianFilter}}
        % boundaryParameters=  {dataSource,method,params}
        % ie. {'gratings','significantCoherence',alpha}
        % or {'gratings','ttestF1',pThresh}
        % or {'whiteNoise','fitGaussian',{medianFilter nStd2Bound}}
        % eyeParameters= []; % for now
        % methods: getCenter and getOuterRadiusBound
        % if fitGaussian, use the tools i started to prototype in fitRF=0 in the ifFeature calcStim, but these are not the final methods at all. lets review choices once its functional.  feel free to make changes & explain why.
        %
        %
        % if there is no RF estimate available in that range, error.
        % %how can we do this more gracefully...? its a costly and plausible mistake...
        %
        % set gratings to accept RFestimator object instead of  position
        % (then call getCenter on the object once on first trial to cache the values)
        % function: sweep multiple anuli over center of RF
        %
        % set gratings to accept RFestimator object instead of annulus radius, and call getOuterRadiusBound to cache it
        %
        %example test use:
        %path='\\132.239.158.183\rlab_storage\pmeier\backup\devNeuralData_090310\'
        % rf=RFestimator({'whiteNoise','fitGaussian',{2}},{'gratings','ttestF1',{0.03,'fft'}},[],path,[now-100 Inf]); x=getCenter(rf,'g')
        switch nargin
            case 0
                error('default object construction not allowed for RFestimator');
            case 1
                % if single argument of this class type, return it
                if (isa(varargin{1},'RFestimator'))
                    RFe = varargin{1};
                else
                    error('single argument must be a RFestimator object');
                end
            case 5
                % centerParams
                if iscell(varargin{1}) && length(varargin{1})==3
                    RFe.centerParams=varargin{1};
                else
                    error('centerParams must be a cell array of length 3');
                end
                % boundaryParams
                if iscell(varargin{2}) && length(varargin{2})==3
                    RFe.boundaryParams=varargin{2};
                else
                    error('boundaryParams must be a cell array of length 3');
                end

                % check centerParams
                if ~ischar(RFe.centerParams{1})
                    error('centerParams stimClass must be a string');
                end
                if ~iscell(RFe.centerParams{3}) && ~isempty(RFe.centerParams{3})
                    error('centerParams params must be a cell array or empty');
                else
                    p=RFe.centerParams{3}; % dynamic params
                end

                switch RFe.centerParams{1}
                    case 'whiteNoise'
                        switch RFe.centerParams{2}
                            case 'centerOfMass'
                                if ~isempty(p)
                                    error('no parameters for centerOfMass, use empty set')
                                end
                            case 'fitGaussian'
                                if ~(length(p)==1 & p{1}>0 & p{1}<10)
                                    error('first parameter must be a std threshold between 0 and 10')
                                end
                            case 'fitGaussianSigEnvelope'
                                isMedianFilter=( (all(size(p{3})==[3 3]) && islogical(p{3})) || (ischar(p{3}) && ismember(p{3},{'box','cross'})));
                                if ~(length(p)==3 & p{1}>0 & p{1}<10 & p{2}>0 & p{2}<1 & isMedianFilter)
                                    p
                                    std=p{1}
                                    alpha=p{2}
                                    medianFilter=p{3}
                                    isMedianFilter
                                    error('first parameter must be a std threshold between 0 and 10, second parameter must be an alpha between 0 and 1, third parameter must be a median filter: either a size 3 logical or ''box'' or ''cross''')
                                end
                            otherwise
                                error(sprintf('%s is a bad method for %s',RFe.centerParams{2},RFe.centerParams{1}))
                        end
                    case 'gratings'
                        switch RFe.centerParams{2}
                            case 'lastDynamicSetting'
                                if ~isempty(p)
                                    error('found a parameter, but none ae needed for lastDynamicSetting')
                                end
                            otherwise
                                RFe.centerParams{2}
                                error('that gratings center method does not exist')
                        end
                end


                % check boundaryParams
                if ~ischar(RFe.boundaryParams{1})
                    error('boundaryParams stimClass must be a string');
                end
                if ~iscell(RFe.boundaryParams{3}) && ~isempty(RFe.boundaryParams{3})
                    error('boundaryParams params must be a cell array or empty');
                else
                    p=RFe.boundaryParams{3}; % dynamic params
                end

                switch RFe.boundaryParams{1}
                    case 'whiteNoise'
                        switch RFe.boundaryParams{2}
                            case 'centerOfMass'
                                error('not allowed for the boundary method')
                            case 'fitGaussian'
                                if ~(length(p)==1 & p{1}>0 & p{1}<10)
                                    error('first parameter must be a std threshold between 0 and 10')
                                end
                            case 'fitGaussianSigEnvelope'
                                isMedianFilter=( (all(size(p{3})==[3 3]) && islogical(p{3})) || (ischar(p{3}) && ismember(p{3},{'box','cross'})))
                                if ~(length(p)==3 & p{1}>0 & p{1}<10 & p{2}>0 & p{2}<1 & isMedianFilter)
                                    p
                                    std=p{1}
                                    alpha=p{2}
                                    medianFilter=p{3}
                                    isMedianFilter
                                    error('first parameter must be a std threshold between 0 and 10, second parameter must be an alpha between 0 and 10, third parameter must be a median filter: either a size 3 logical or ''box'' or ''cross''')
                                end
                            otherwise
                                error(sprintf('%s is a bad method for %s',RFe.centerParams{2},RFe.centerParams{1}))
                        end
                    case 'gratings'
                        switch RFe.boundaryParams{2}
                            case 'significantCoherence'
                                error('not yet')
                            case 'ttestF1'
                                if ~(p{1}>0 && p{1}<1)
                                    p{1}
                                    error('must be alpha between 0 and 1')
                                end
                                switch p{2}
                                    case 'fft'
                                    otherwise
                                        p{2}
                                        error('must choose frequency estimation method')
                                end
                            case 'lastDynamicSetting'
                                 if ~isempty(p)
                                    error('found a parameter, but none ae needed for lastDynamicSetting')
                                end
                            otherwise
                                error(sprintf('%s is a bad method for %s',RFe.centerParams{2},RFe.centerParams{1}))
                        end
                end

                % eyeParams
                if iscell(varargin{3}) || isempty(varargin{3})
                    RFe.eyeParams=varargin{3};
                else
                    error('eyeParams must be a cell array or empty');
                end

                if ~isempty(varargin{4}) && ischar(varargin{4}) && isdir(varargin{4})
                    RFe.dataSource=varargin{4};
                else
                    RFe.dataSource
                    error('dataSource must be a valid directory path');
                end
                % dateRange
                if isvector(varargin{5}) && isnumeric(varargin{5}) && length(varargin{5})==2 && varargin{5}(1)<=varargin{5}(2)
                    RFe.dateRange=varargin{5};
                else
                    error('dateRange must be a 2-element vector specifying a valid range')
                end

                RFe=class(RFe,'RFestimator');

            otherwise
                error('unsupported number of input arguments');
        end

        end % end function
        
        function out =getDataSource(RFe)
            out=RFe.dataSource;
        end
        
        function [ctr source details]  = getCenter(RFe,subjectID,trialRecords)
            % This function calculates the center position of the receptive field, using the parameters on the object.
            % The result is returned as a 2-element array [x y] in normalized units as fraction of screen


            %TESTING
            %sca
            %keyboard
            %load('\\132.239.158.179\datanet_storage\demo1\analysis\physAnalysis_191-20090205T151316.mat')
            %load('\\132.239.158.179\datanet_storage\demo1\analysis\334-20090206T164500\physAnalysis_334-20090206T164500.mat')
            %load('\\132.239.158.183\rlab_storage\pmeier\backup\devNeuralData_090310\test\analysis\43-20090323T201947\physAnalysis_43-20090323T201947.mat')
            %load('\\132.239.158.183\rlab_storage\pmeier\backup\devNeuralData_090310\test\analysis\20-20090323T201110\physAnalysis_20-20090323T201110.mat')
            %load('\\132.239.158.183\rlab_storage\pmeier\backup\devNeuralData_090310\test\stimRecords\stimRecords_20-20090323T201110.mat')

            %sca
            %keyboard  % need to fix getPhysRecords
            %subjectID='test1';  % JUST TO SEE IF IT works;   must DELETE!


            details=[];
            if strcmp(RFe.centerParams{2},'lastDynamicSettings')
                % doesn't require the analysis to have run... or its data
            end


            switch RFe.centerParams{1}
                case 'spatialWhiteNoise'

                    [data success]=getPhysRecords(fullfile(getDataSource(RFe),subjectID),{'dateRange',RFe.dateRange},...
                        {'analysis','stim'},RFe.centerParams{1});

                    if ~success
                        error('bad phys load!')
                    else
                        analysisdata=data.cumulativedata;
                        stimulusDetails=data.stimulusDetails;
                    end

                    % for record keeping
                    source.subjectID=subjectID;
                    source.trialNum=data.trialNum;
                    source.timestamp=data.timestamp;

                    % find brightest point, to select time frame of interest
                    ind=find(max(analysisdata.cumulativeSTA(:))==analysisdata.cumulativeSTA(:));
                    [x y t]=ind2sub(size(analysisdata.cumulativeSTA),ind);
                    STA2d=analysisdata.cumulativeSTA(:,:,t);

                    switch RFe.centerParams{2}
                        case 'fitGaussian'
                            stdThresh=RFe.centerParams{3}{1}

                            [STAenvelope STAparams] =fitGaussianEnvelopeToImage(STA2d,stdThresh,false,false,false);
                            view=0;
                            if view
                                figure(7)
                                hold off; imagesc(STAenvelope); colormap(gray)
                                hold on; plot(STAparams(2)*size(STAenvelope,2)+1,STAparams(3)*size(STAenvelope,1)+1,'ro')
                            end
                            if nargout>2
                                details.STAparams=STAparams;
                                details.STAenvelope=STAenvelope;
                                details.STA2d=STA2d;
                            end
                        case 'fitGaussianSigEnvelope'

                            %for testing
                            %STA2d=computeGabors(stimParams,0.5,64,64,'square','normalizeVertical',0)+ 0.09*(randn(64,64) + 0.1);
                            %sigSpots=getSignificantSTASpots(STA,500,[],0.005);

                            stdThresh=RFe.centerParams{3}{1};
                            alpha=RFe.centerParams{3}{2};
                            medianFilter=RFe.centerParams{3}{3};
                            %fit a guassian to the binary significance image -- conservative
                            sigSpots=getSignificantSTASpots(STA2d,analysisdata.cumulativeNumSpikes,stimulusDetails.meanLuminance,stimulusDetails.std,medianFilter,alpha);
                            if ~length(union(unique(sigSpots),[0 1]))==2
                                error('more than one RF spot!')
                            end

                            [sigEnvelope sigConservativeParams] =fitGaussianEnvelopeToImage(sigSpots,stdThresh,salse,false,false);

                            %use the conservative field to narrow a better seach of the STA
                            [STAenvelope STAparams] =fitGaussianEnvelopeToImage(STA2d,stdThresh,sigEnvelope,false,false);

                            view=1;
                            if view
                                figure(7)
                                subplot(1,3,1); imagesc(sigSpots); colormap(gray)
                                subplot(1,3,2); imagesc(sigEnvelope); colormap(gray)
                                subplot(1,3,3); imagesc(STAenvelope); colormap(gray)
                            end

                            if nargout>2
                                details.STAparams=STAparams;
                                details.STAenvelope=STAenvelope;
                                details.sigEnvelope=sigEnvelope;
                                details.sigSpots=sigSpots;
                                details.STA2d=STA2d;
                            end
                        otherwise
                            error('unsupported method');
                    end

                    ctr=STAparams(2:3);
                case 'gratingWithChangeableAnnulusCenter'
                    switch RFe.centerParams{2}
                        case 'lastDynamicSettings'
                            %this does not need a phys analysis, rather it needs
                            %details of the dymanimic settings in the trialRecords!

                            %trialRecords.stimManagerClass
                            %cands=find(strcmp({trialRecords.stimManagerClass},'gratings'))
                            %this only finds the gratings candidates from THIS session,
                            %so instead we look for a signature field of gratingWithChangeableAnnulusCenter

                            ctr=[];
                            for i=length(trialRecords):-1:1  % go backwards through the trial records until changeableAnnulusCenter is found and true
                                if isfield(trialRecords(i).stimDetails,'changeableAnnulusCenter') && trialRecords(i).stimDetails.changeableAnnulusCenter==1
                                    useTrial=i; % the most recent trial with changeableAnnulusCenter
                                    trialRecords(useTrial).stimDetails.width;
                                    trialRecords(useTrial).stimDetails.height;

                                    whichPhase=1;  % could have a smarter way of doing this by finding it... autopilot uses 1
                                    pos=trialRecords(useTrial).phaseRecords(whichPhase).dynamicDetails{end}.annulusDestRec;

                                    ctr(1)=mean(pos([1 3]))/trialRecords(useTrial).stimDetails.width; %x
                                    ctr(2)=mean(pos([2 4]))/trialRecords(useTrial).stimDetails.height; %y

                                    source.subjectID=trialRecords(useTrial).subjectsInBox;
                                    source.trialNum=trialRecords(useTrial).trialNumber;
                                    source.timestamp=trialRecords(useTrial).date;

                                    break
                                end
                            end
                    end
                    if isempty(ctr)
                        numTrailsChecked=length(trialRecords)
                        error('there are no trials with gratings in the trial history!')
                    end


                otherwise
                    RFe.centerParams{2}
                    error('bad source')
            end

            if any(ctr>1) || any(ctr<0)
                warning('center is estimated to be off screen')
                beep; beep
                %force on screen
                ctr(ctr>1)=1;
                ctr(ctr<0)=0;
            end


        end % end function
        
        function [bound source details]  = getBoundary(RFe,subjectID,trialRecords)
            % This function calculates the std of the receptive field, using the parameters on the object.
            % The result is returned in std normalized units as fraction of screen


            details=[];
            switch RFe.centerParams{1}
                case 'spatialWhiteNoise'


                    [data success]=getPhysRecords(fullfile(getDataSource(RFe),subjectID),{'dateRange',RFe.dateRange},{'analysis','stim'},RFe.centerParams{1})
                    if ~success
                        error('bad phys load!')
                    else
                        analysisdata=data.cumulativedata;
                        stimulusDetails=data.stimulusDetails;
                    end

                    % for record keeping
                    source.subjectID=subjectID;
                    source.trialNum=data.trialNum;
                    source.timestamp=data.timestamp;

                    % find brightest point, to select time frame of interest
                    ind=find(max(analysisdata.cumulativeSTA(:))==analysisdata.cumulativeSTA(:));
                    [x y t]=ind2sub(size(analysisdata.cumulativeSTA),ind);
                    STA2d=analysisdata.cumulativeSTA(:,:,t);

                    switch RFe.centerParams{2}
                        case 'fitGaussian'
                            stdThresh=RFe.centerParams{3}{1};
                            [STAenvelope STAparams] =fitGaussianEnvelopeToImage(STA2d,stdThresh,false,false,false);

                            if nargout>2
                                details.STAparams=STAparams;
                                details.STAenvelope=STAenvelope;
                                details.STA2d=STA2d;
                            end

                            bound=[STAparams(5)];  % only one parameter = radial std
                        otherwise
                            error('currently unsupported method');
                    end

                case 'gratingWithChangeableAnnulusCenter'
                    switch RFe.centerParams{2}
                        case 'lastDynamicSettings'
                            %this does not need a phys analysis, rather it needs
                            %details of the dymanimic settings in the trialRecords!

                            %trialRecords.stimManagerClass
                            %cands=find(strcmp({trialRecords.stimManagerClass},'gratings'))
                            %this only finds the gratings candidates from THIS session,
                            %so instead we look for a signature field of gratingWithChangeableAnnulusCenter

                            bound=[];
                            for i=length(trialRecords):-1:1  % go backwards through the trial records until changeableAnnulusCenter is found and true
                                if isfield(trialRecords(i).stimDetails,'changeableAnnulusCenter') && trialRecords(i).stimDetails.changeableAnnulusCenter==1
                                    useTrial=i; % the most recent trial with changeableAnnulusCenter

                                    whichPhase=1;  % could have a smarter way of doing this by finding it... autopilot uses 1
                                    annulusInd=trialRecords(useTrial).phaseRecords(whichPhase).dynamicDetails{end}.annulusInd;

                                    bound=trialRecords(useTrial).stimDetails.annuli(annulusInd);

                                    source.subjectID=trialRecords(useTrial).subjectsInBox;
                                    source.trialNum=trialRecords(useTrial).trialNumber;
                                    source.timestamp=trialRecords(useTrial).date;

                                    break
                                end
                            end

                            if isempty(bound)
                                numTrailsChecked=length(trialRecords);
                                error('there are no trials with gratings in the trial history!')
                            end

                    end
                otherwise
                    RFe.centerParams{2}
                    error('bad source')
            end

        end

    end
    
end


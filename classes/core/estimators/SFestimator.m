classdef SFestimator
    
    properties
        dataSource = [];
        stimulusType = '';
        estimationMethod = '';
        params=[];
        dateRange = [];
        cache = [];
    end
    
    methods
        
        function SFe = SFestimator(varargin)
        % SFestimator constructor
        %
        % SFe = SFestimator(dataSource,estimationMethod,dateRange)
        %
        % originally from phil. balaji concurs:
        % always gets the most recent analysis result within SFestimator.dateRange
        % phys setup will choose dateRange=[floor(now) Inf] to specify today
        % dataSource = '\\132.239.158.179\datanet_storage'; Analysis storage location
        %
        % estimationMethod = {dataSource,method}
        % typical example
        % {'gratingsSF','highestF0'}
        % {'gratingsSF','highestF1'}
        % {'gratingsSF','highestCoh'}
        % {'gratingsSF','2XOptimalSF'}
        % {'gratingsSF','highestSigSF'}
        % {'gratingsSF','highestF1SFGreaterThan',64(PPC)}
        %
        % if there is no SF estimate available in that range, error.
        % %how can we do this more gracefully...? its a costly and plausible mistake...
        %
        % set gratings to accept SFestimator object instead of  pixPerCycs

        % example test use:
        % path='\\132.239.158.183\rlab_storage\pmeier\backup\devNeuralData_090310\'
        % SFe=SFestimator(path,{'gratingsSF','highestF1'},[now-100 Inf]);
        switch nargin
            case 0
                error('default object construction not allowed for SFestimator');
            case 1
                % if single argument of this class type, return it
                if (isa(varargin{1},'SFestimator'))
                    SFe = varargin{1};
                else
                    error('single argument must be a SFestimator object');
                end
            case 3
                if ~isempty(varargin{1}) && ischar(varargin{1}) && isdir(varargin{1})
                    SFe.dataSource=varargin{1};
                else
                    error('dataSource must be a valid directory path');
                end

                if iscell(varargin{2}) && ischar(varargin{2}{1})
                    switch varargin{2}{1}
                        case 'gratingsSF'
                            SFe.stimulusType = 'gratingsSF';
                            if ischar(varargin{2}{2}) && ismember(varargin{2}{2},{'highestF0','highestF1','highestCoh','2XOptimalSF','highestSigSF','highestF1SFGreaterThan'})
                                SFe.estimationMethod = varargin{2};
                            else
                                error('unknown method');
                            end
                        otherwise
                            error('unknown stimulusType');
                    end
                else
                    error('estimationMethod must be a cell input')
                end

                if isnumeric(varargin{3})
                    SFe.dateRange = varargin{3};
                end

                

            otherwise
                error('unsupported number of input arguments');
        end

        end % end function
        
        function out = chooseSFs(SFe,varargin)

            if nargin==2
                searchMode = 'latestSingleUnit';
                singleUnitDetails = varargin{1};
            else
                searchMode = 'trawlPhysAnalysis';
            end

            switch searchMode
                case 'latestSingleUnit'
                    % typically sUs are stored in dataSource,ratID,analysis,singleUnits
                    unitLocation = fullfile(SFe.dataSource,singleUnitDetails.subjectID,'analysis','singleUnits');
                    % find the singleUnit object of interest.
                    d = dir(unitLocation);
                    d = d(~ismember({d.name},{'.','..'}));
                    [junk order] = sort([d.datenum]);
                    d = d(order);
                    temp = load(fullfile(unitLocation,d(end).name));
                    sU = temp.currentUnit;
                otherwise
                    error('unknown method');
            end

            % we have the analysis. now do the choosing and give the output
            switch SFe.estimationMethod{1}
                case 'gratingsSF'
                    % get the sfGratings object from single unit. always use the last
                    % analysis
                    sfG = getSFs(sU);
                    sfG = sfG(end);
                    %get the analysis from the sfGratings object. 
                    analysis = getAnalysis(sfG);
                otherwise
                    error('unknown method');
            end

            switch SFe.estimationMethod{2}
                case 'highestF0'
                    out = analysis.spatialfrequencies(analysis.rate==max(analysis.rate));
                case 'highestF1'
                    out = analysis.spatialfrequencies(analysis.pow==max(analysis.pow));
                case 'highestCoh'
                    out = analysis.spatialfrequencies(analysis.coh==max(analysis.coh));
                case '2XOptimalSF'
                    out = analysis.spatialfrequencies(analysis.pow==max(analysis.pow))/2;
                case 'highestF1SFGreaterThan'
                    whichAllowed = analysis.spatialfrequencies<SFe.estimationMethod{3};
                    allowedAnalyses = analysis.pow(whichAllowed);
                    allowedSFs = analysis.spatialfrequencies(whichAllowed);
                    out = allowedSFs(allowedAnalyses==max(allowedAnalyses));
                otherwise
                    error('unknown method');
            end
        end
        
    end
    
end


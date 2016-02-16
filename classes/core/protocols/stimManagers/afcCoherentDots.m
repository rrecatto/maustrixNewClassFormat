classdef afcCoherentDots
    
    properties
        numDots = {100,100};                      % Number of dots to display
        bkgdNumDots = {0,0};                      % task irrelevant dots
        dotCoherence = {0.8, 0.8};                % Percent of dots to move in a specified direction
        bkgdCoherence = {0.8, 0.8};               % percent of bkgs dots moving in the specified direction
        dotSpeed = {1,1};                         % How fast do our little dots move (dotSize/sec)
        bkgdSpeed = {0.1,0.1};                    % speed of bkgd dots
        dotDirection = {[0],[pi]};                % 0 is to the right. pi is to the left
        bkgdDirection = {[0],[pi]};               % 0 is to the right. pi is to the left
        dotColor = {0,0};                         % can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen 
        bkgdDotColor = {0,0};                     % can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen 
        dotSize = {[9],[9]};                      % Width of dots in pixels
        bkgdSize = {[3],[3]};                     % Width in pixels
        dotShape = {{'circle'},{'circle'}};       % 'circle' or 'rectangle'
        bkgdShape = {{'rectangle'},{'rectangle'}};% 'circle' or 'rectangle'
        renderMode = {'flat'};                    % {'flat'} or {'perspective',[renderDistances]}
        renderDistance = NaN;                     % is 1 for flat and is a range for perspective
        maxDuration = {inf, inf};                 % in seconds (inf is until response)
        background = 0;                           % black background

        LUT =[];
        LUTbits=0;

        doCombos=true;
        ordering;
        doPostDiscrim = false; 

        LEDParams;
    end
    
    methods
        function s=afcCoherentDots(varargin)
            % AFCCOHERENTDOTS  class constructor.
            % this class is specifically designed for behavior.
            % s = afcCoherentDots(numDots,bkgdNumDots, dotCoherence,bkgdCoherence, dotSpeed,bkgdSpeed, dotDirection,bkgdDirection,...
            %       dotColor,bkgdColor, dotSize,bkgdSize, dotShape,bkgdShape, renderMode, maxDuration,background...
            %       maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, doPostDiscrim, LEDParams)
            %   numDots - number of dots to draw
            %   coherence - an array of numeric values >0 and <1
            %   speed - an array of positive numbers in units of dotSize/second
            %   direction - the direction the coheret dots move it. non coherent dots
            %         will do some kind of jiggle in all directions
            %   color - can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen 
            %   dotSize - size in pixels of each dot (square)
            %   dotShape - 'circle or 'rectangle'
            %   renderMode - 'perspective' or 'flat'
            %   maxDuration - length of the movie in seconds. particularly useful for
            %          stimli with specific time.... 
            %   screenZoom - scaleFactor argument passed to stimManager constructor
            %   interTrialLuminance - (optional) defaults to 0
            %   doCombos - whether to do combos or not...


            eps = 0.0000001;
            s.ordering.method = 'twister';
            s.ordering.seed = [];
            s.LEDParams.active = false;
            s.LEDParams.numLEDs = 0;
            s.LEDParams.IlluminationModes = {};
            
            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s = class(s,'afcCoherentDots',stimManager());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'afcCoherentDots'))
                        s = varargin{1};
                    else
                        error('Input argument is not a gratings object')
                    end
                case {22 23 24}
                    % create object using specified values
                    numDots = varargin{1};
                    bkgdNumDots = varargin{2};
                    dotCoherence = varargin{3};
                    bkgdCoherence = varargin{4};
                    dotSpeed = varargin{5};
                    bkgdSpeed = varargin{6};
                    dotDirection = varargin{7};
                    bkgdDirection = varargin{8};
                    dotColor = varargin{9};
                    bkgdDotColor = varargin{10};
                    dotSize = varargin{11};
                    bkgdSize = varargin{12};
                    dotShape = varargin{13};
                    bkgdShape = varargin{14};
                    renderMode = varargin{15};
                    maxDuration = varargin{16};
                    background = varargin{17};
                    maxWidth = varargin{18};
                    maxHeight = varargin{19};
                    scaleFactor = varargin{20};
                    interTrialLuminance = varargin{21};
                    doCombos = varargin{22};

                    if(nargin==23)
                        doPostDiscrim=varargin{23};
                    else
                        doPostDiscrim = false;
                    end

                    if (nargin==24)
                        LEDParams = varargin{24};
                    else
                        LEDParams = [];
                    end

                    % doCombos
                    if islogical(doCombos)
                        s.doCombos = doCombos;
                    elseif iscell(doCombos) && islogical(doCombos{1}) && iscell(doCombos{2}) && ...
                            ischar(doCombos{2}{1}) && ismember(doCombos{2}{1}, {'default','twister'})
                        s.doCombos = doCombos{1};
                        s.ordering.method = doCombos{2}{1};
                        if length(doCombos{2})==2
                            if isnumeric(doCombos{2}{2})
                                s.ordering.seed = doCombos{2}{2};
                            else
                                error('seed should be numeric');
                            end
                        end
                    else
                        doCombos
                        error('doCombos not in the right format');
                    end

                    % numDots
                    if iscell(numDots) && length(numDots)==2 && ...
                            isnumeric(numDots{1}) && all(numDots{1}>=0) && isnumeric(numDots{2}) && all(numDots{2}>=0)
                        s.numDots = numDots;
                        L1 = length(numDots{1});
                        L2 = length(numDots{2});
                    else
                        numDots
                        error('numDots not in the right format');
                    end

                    % bkgdNumDots
                    if iscell(bkgdNumDots) && length(bkgdNumDots)==2 && ...
                            isnumeric(bkgdNumDots{1}) && all(bkgdNumDots{1}>=0) && isnumeric(bkgdNumDots{2}) && all(bkgdNumDots{2}>=0)
                        s.bkgdNumDots = bkgdNumDots;
                        if ~doCombos && length(bkgdNumDots{1})~=L1 && length(bkgdNumDots{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        bkgdNumDots
                        error('bkgdNumDots not in the right format');
                    end

                    % dotCoherence
                    if iscell(dotCoherence) && length(dotCoherence)==2 && ...
                            isnumeric(dotCoherence{1}) && all(dotCoherence{1}>=0) && all(dotCoherence{1}<=1) && ...
                            isnumeric(dotCoherence{2}) && all(dotCoherence{2}>=0) && all(dotCoherence{2}<=1) 
                        s.dotCoherence = dotCoherence;
                        if ~doCombos && length(dotCoherence{1})~=L1 && length(dotCoherence{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        dotCoherence
                        error('dotCoherence not in the right format');
                    end

                    % bkgdCoherence
                    if iscell(bkgdCoherence) && length(bkgdCoherence)==2 && ...
                            isnumeric(bkgdCoherence{1}) && all(bkgdCoherence{1}>=0) && all(bkgdCoherence{1}<=1) && ...
                            isnumeric(bkgdCoherence{2}) && all(bkgdCoherence{2}>=0) && all(bkgdCoherence{2}<=1) 
                        s.bkgdCoherence = bkgdCoherence;
                        if ~doCombos && length(bkgdCoherence{1})~=L1 && length(bkgdCoherence{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        bkgdCoherence
                        error('bkgdCoherence not in the right format');
                    end

                    % dotSpeed
                    if iscell(dotSpeed) && length(dotSpeed)==2 && ...
                            isnumeric(dotSpeed{1}) && all(dotSpeed{1}>=0) && ...
                            isnumeric(dotSpeed{2}) && all(dotSpeed{2}>=0)
                        s.dotSpeed = dotSpeed;
                        if ~doCombos && length(dotSpeed{1})~=L1 && length(dotSpeed{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        dotSpeed
                        error('dotSpeed not in the right format');
                    end

                    % bkgdSpeed
                    if iscell(bkgdSpeed) && length(bkgdSpeed)==2 && ...
                            isnumeric(bkgdSpeed{1}) && all(bkgdSpeed{1}>=0) && ...
                            isnumeric(bkgdSpeed{2}) && all(bkgdSpeed{2}>=0)
                        s.bkgdSpeed = bkgdSpeed;
                        if ~doCombos && length(bkgdSpeed{1})~=L1 && length(bkgdSpeed{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        bkgdSpeed
                        error('bkgdSpeed not in the right format');
                    end

                    % dotDirection
                    if iscell(dotDirection) && length(dotDirection)==2 && ...
                            isnumeric(dotDirection{1}) && ...
                            isnumeric(dotDirection{2})
                        s.dotDirection = dotDirection;
                        if ~doCombos && length(dotDirection{1})~=L1 && length(dotDirection{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        dotDirection
                        error('dotDirection not in the right format');
                    end

                    % bkgdDirection
                    if iscell(bkgdDirection) && length(bkgdDirection)==2 && ...
                            isnumeric(bkgdDirection{1}) &&  ...
                            isnumeric(bkgdDirection{2})
                        s.bkgdDirection = bkgdDirection;
                        if ~doCombos && length(bkgdDirection{1})~=L1 && length(bkgdDirection{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        bkgdDirection
                        error('bkgdDirection not in the right format');
                    end

                    % dotColor
                    if iscell(dotColor) && length(dotColor)==2 && ...
                            isnumeric(dotColor{1}) &&  length(size(dotColor{1}))<=2 && ... % a 2-D array
                            all(all(dotColor{1}>=0)) && all(all(dotColor{1}<=1)) && ... % of the right values
                            ismember(size(dotColor{1},2),[1,3,4]) && ...  % and the right size (a column of gray values, a column of RGB values or a column of RGBA values)
                            isnumeric(dotColor{2}) &&  length(size(dotColor{2}))<=2 && ... % a 2-D array
                            all(all(dotColor{2}>=0)) && all(all(dotColor{2}<=1)) && ... % of the right values
                            ismember(size(dotColor{2},2),[1,3,4]) % and the right size (a column of gray values, a column of RGB values or a column of RGBA values)
                        s.dotColor = dotColor;
                        if ~doCombos && size(dotColor{1},1)~=L1 && size(dotColor{2},1)~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        dotColor
                        error('dotColor not in the right format');
                    end

                    % bkgdDotColor
                    if iscell(bkgdDotColor) && length(bkgdDotColor)==2 && ...
                            isnumeric(bkgdDotColor{1}) &&  length(size(bkgdDotColor{1}))<=2 && ... % a 2-D array
                            all(all(bkgdDotColor{1}>=0)) && all(all(bkgdDotColor{1}<=1)) && ... % of the right values
                            ismember(size(bkgdDotColor{1},2),[1,3,4]) && ...  % and the right size (a column of gray values, a column of RGB values or a column of RGBA values)
                            isnumeric(bkgdDotColor{2}) &&  length(size(bkgdDotColor{2}))<=2 && ... % a 2-D array
                            all(all(bkgdDotColor{2}>=0)) && all(all(bkgdDotColor{2}<=1)) && ... % of the right values
                            ismember(size(bkgdDotColor{2},2),[1,3,4])  % and the right size (a column of gray values, a column of RGB values or a column of RGBA values)
                        s.bkgdDotColor = bkgdDotColor;
                        if ~doCombos && size(bkgdDotColor{1},1)~=L1 && size(bkgdDotColor{2},1)~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        bkgdDotColor
                        error('bkgdDotColor not in the right format');
                    end


                    % dotSize
                    if iscell(dotSize) && length(dotSize)==2 && ...
                            isnumeric(dotSize{1}) && all(dotSize{1}>0) && ...
                            isnumeric(dotSize{2}) && all(dotSize{2}>0)
                        s.dotSize = dotSize;
                        if ~doCombos && length(dotSize{1})~=L1 && length(dotSize{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        dotSize
                        error('dotSize not in the right format');
                    end

                    % bkgdSize
                    if iscell(bkgdSize) && length(bkgdSize)==2 && ...
                            isnumeric(bkgdSize{1}) && all(bkgdSize{1}>0) && ...
                            isnumeric(bkgdSize{2}) && all(bkgdSize{2}>0)
                        s.bkgdSize = bkgdSize;
                        if ~doCombos && length(bkgdSize{1})~=L1 && length(bkgdSize{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        bkgdSize
                        error('bkgdSize not in the right format');
                    end


                    % dotShape
                    if iscell(dotShape) && length(dotShape)==2 && ...
                            iscell(dotShape{1}) && all(ismember(dotShape{1}, {'circle','square'})) && ...
                            iscell(dotShape{2}) && all(ismember(dotShape{2}, {'circle','square'}))
                        s.dotShape = dotShape;
                        if ~doCombos && length(dotShape{1})~=L1 && length(dotShape{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        dotShape
                        error('dotShape not in the right format');
                    end

                    % bkgdShape
                    if iscell(bkgdShape) && length(bkgdShape)==2 && ...
                            iscell(bkgdShape{1}) && all(ismember(bkgdShape{1}, {'circle','square'})) && ...
                            iscell(bkgdShape{2}) && all(ismember(bkgdShape{2}, {'circle','square'}))
                        s.bkgdShape = bkgdShape;
                        if ~doCombos && length(bkgdShape{1})~=L1 && length(bkgdShape{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        bkgdShape
                        error('bkgdShape not in the right format');
                    end

                    % renderMode
                    if iscell(renderMode) && ischar(renderMode{1}) && ismember(renderMode{1},{'flat','perspective'})
                        s.renderMode = renderMode{1};
                        switch renderMode{1}
                            case 'flat'
                                s.renderDistance = NaN;
                            case 'perspective'
                                if length(renderMode)==2 && isnumeric(renderMode{2}) && length(renderMode{2})==2 && all(renderMode{2}>0)
                                    s.renderDistance = renderMode{2};
                                else
                                    renderMode
                                    error('for ''perspective'', renderMode{2} should be a 2 numeric positive number');
                                end
                        end
                    else
                        renderMode
                        error('renderMode not in the right format');
                    end

                    % maxDuration
                    if iscell(maxDuration) && length(maxDuration)==2 && ...
                            isnumeric(maxDuration{1}) && all(maxDuration{1}>0) && ...
                            isnumeric(maxDuration{2}) && all(maxDuration{2}>0)
                        s.maxDuration = maxDuration;
                        if ~doCombos && length(maxDuration{1})~=L1 && length(maxDuration{2})~=L2
                            error('the lengths don''t match. ')
                        end
                    else
                        maxDuration
                        error('maxDuration not in the right format');
                    end

                    % background
                    if isnumeric(background)
                        s.background = background;
                    else
                        background
                        error('background not in the right format');
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

                    if nargin==24
                        % LED state
                        if isstruct(LEDParams)
                            s.LEDParams = LEDParams;
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


                    s = class(s,'afcCoherentDots',stimManager(maxWidth,maxHeight,scaleFactor,interTrialLuminance));
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
                case {'A41F7278B4DE','A41F729213E2','A41F726EC11C' } %gLab-Behavior rigs 1,2,3
                    [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
                case {'7845C4256F4C', '7845C42558DF','A41F729211B1'} %gLab-Behavior rigs 4,5,6
                    [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
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
            [targetPorts, distractorPorts, details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);


            toggleStim=true; type='expert';
            dynamicMode = true; %false %true

            % set up params for computeGabors
            height = min(height,getMaxHeight(stimulus));
            width = min(width,getMaxWidth(stimulus));

            % lets save some of the details for later
            possibleStims.numDots        = stimulus.numDots;
            possibleStims.bkgdNumDots    = stimulus.bkgdNumDots;
            possibleStims.dotCoherence   = stimulus.dotCoherence;
            possibleStims.bkgdCoherence  = stimulus.bkgdCoherence;
            possibleStims.dotSpeed       = stimulus.dotSpeed;
            possibleStims.bkgdSpeed      = stimulus.bkgdSpeed;
            possibleStims.dotDirection   = stimulus.dotDirection;
            possibleStims.bkgdDirection  = stimulus.bkgdDirection;
            possibleStims.dotColor       = stimulus.dotColor;
            possibleStims.bkgdDotColor   = stimulus.bkgdDotColor;
            possibleStims.dotSize        = stimulus.dotSize;
            possibleStims.bkgdSize       = stimulus.bkgdSize;
            possibleStims.dotShape       = stimulus.dotShape;
            possibleStims.bkgdShape      = stimulus.bkgdShape;
            possibleStims.renderMode     = stimulus.renderMode;
            possibleStims.maxDuration    = stimulus.maxDuration;
            possibleStims.background     = stimulus.background;
            possibleStims.doCombos       = stimulus.doCombos;
            details.possibleStims        = possibleStims;
            details.afcCoherentDotsType  = getType(stimulus,structize(stimulus));

            % whats the chosen stim?
            if targetPorts==1
                chosenStimIndex = 1;
            elseif targetPorts==3
                chosenStimIndex = 2;
            else
                error('cannot support this here')
            end

            stim = [];


            stim.height = height;
            stim.width = width;
            stim.rngMethod = stimulus.ordering.method;
            if isempty(stimulus.ordering.seed)
                stim.seedVal = sum(100*clock);
            end

            if stimulus.doCombos    
                % numDots
                tempVar = randperm(length(stimulus.numDots{chosenStimIndex}));
                stim.numDots = stimulus.numDots{chosenStimIndex}(tempVar(1));

                % bkgdNumDots
                tempVar = randperm(length(stimulus.bkgdNumDots{chosenStimIndex}));
                stim.bkgdNumDots = stimulus.bkgdNumDots{chosenStimIndex}(tempVar(1));

                % dotCoherence
                tempVar = randperm(length(stimulus.dotCoherence{chosenStimIndex}));
                stim.dotCoherence = stimulus.dotCoherence{chosenStimIndex}(tempVar(1));

                % bkgdCoherence
                tempVar = randperm(length(stimulus.bkgdCoherence{chosenStimIndex}));
                stim.bkgdCoherence = stimulus.bkgdCoherence{chosenStimIndex}(tempVar(1));

                % dotSpeed
                tempVar = randperm(length(stimulus.dotSpeed{chosenStimIndex}));
                stim.dotSpeed = stimulus.dotSpeed{chosenStimIndex}(tempVar(1));

                % bkgdSpeed
                tempVar = randperm(length(stimulus.bkgdSpeed{chosenStimIndex}));
                stim.bkgdSpeed = stimulus.bkgdSpeed{chosenStimIndex}(tempVar(1));

                % dotDirection
                tempVar = randperm(length(stimulus.dotDirection{chosenStimIndex}));
                stim.dotDirection = stimulus.dotDirection{chosenStimIndex}(tempVar(1));

                % bkgdDirection
                tempVar = randperm(length(stimulus.bkgdDirection{chosenStimIndex}));
                stim.bkgdDirection = stimulus.bkgdDirection{chosenStimIndex}(tempVar(1));

                % dotColor
                tempVar = randperm(size(stimulus.dotColor{chosenStimIndex},1));
                stim.dotColor = stimulus.dotColor{chosenStimIndex}(tempVar(1),:);

                % bkgdDotColor
                tempVar = randperm(size(stimulus.bkgdDotColor{chosenStimIndex},1));
                stim.bkgdDotColor = stimulus.bkgdDotColor{chosenStimIndex}(tempVar(1),:);

                % dotSize
                tempVar = randperm(length(stimulus.dotSize{chosenStimIndex}));
                stim.dotSize = stimulus.dotSize{chosenStimIndex}(tempVar(1));

                % bkgdSize
                tempVar = randperm(length(stimulus.bkgdSize{chosenStimIndex}));
                stim.bkgdSize = stimulus.bkgdSize{chosenStimIndex}(tempVar(1));

                % dotShape
                tempVar = randperm(length(stimulus.dotShape{chosenStimIndex}));
                stim.dotShape = stimulus.dotShape{chosenStimIndex}(tempVar(1));

                % bkgdShape
                tempVar = randperm(length(stimulus.bkgdShape{chosenStimIndex}));
                stim.bkgdShape = stimulus.bkgdShape{chosenStimIndex}(tempVar(1));

                % renderMode
                stim.renderMode = stimulus.renderMode;

                % maxDuration
                tempVar = randperm(length(stimulus.maxDuration{chosenStimIndex}));
                if ~ismac
                    stim.maxDuration = round(stimulus.maxDuration{chosenStimIndex}(tempVar(1))*hz);
                elseif ismac && hz==0
                    % macs are weird and return a hz of 0 when they really
                    % shouldnt. assume hz = 60 (hack)
                    stim.maxDuration = round(stimulus.maxDuration{chosenStimIndex}(tempVar(1))*60);
                end

                % background
                stim.background = stimulus.background;

                % doCombos
                stim.doCombos = stimulus.doCombos;

            else
                    % numDots
                tempVar = randperm(length(stimulus.numDots{chosenStimIndex}));
                which = tempVar(1);

                stim.numDots = stimulus.numDots{chosenStimIndex}(which);
                stim.bkgdNumDots = stimulus.bkgdNumDots{chosenStimIndex}(which);
                stim.dotCoherence = stimulus.dotCoherence{chosenStimIndex}(which);
                stim.bkgdCoherence = stimulus.bkgdCoherence{chosenStimIndex}(which);
                stim.dotSpeed = stimulus.dotSpeed{chosenStimIndex}(which);
                stim.bkgdSpeed = stimulus.bkgdSpeed{chosenStimIndex}(which);
                stim.dotDirection = stimulus.dotDirection{chosenStimIndex}(which);
                stim.bkgdDirection = stimulus.bkgdDirection{chosenStimIndex}(which);
                stim.dotColor = stimulus.dotColor{chosenStimIndex}(which,:);
                stim.bkgdDotColor = stimulus.bkgdDotColor{chosenStimIndex}(which,:);
                stim.dotSize = stimulus.dotSize{chosenStimIndex}(which);
                stim.bkgdSize = stimulus.bkgdSize{chosenStimIndex}(which);
                stim.dotShape = stimulus.dotShape{chosenStimIndex}(which);
                stim.bkgdShape = stimulus.bkgdShape{chosenStimIndex}(which);

                % waveform
                stim.renderMode = stimulus.renderMode;

                if ~ismac
                    stim.maxDuration = round(stimulus.maxDuration{chosenStimIndex}(which)*hz);
                elseif ismac && hz==0
                    % macs are weird and return a hz of 0 when they really
                    % shouldnt. assume hz = 60 (hack)
                    stim.maxDuration = round(stimulus.maxDuration{chosenStimIndex}(which)*60);
                end

                % background
                stim.background = stimulus.background;

                % doCombos
                stim.doCombos = stimulus.doCombos;

            end


            % have a version in ''details''
            details.doCombos       = stimulus.doCombos;
            details.numDots        = stim.numDots;
            details.bkgdNumDots    = stim.bkgdNumDots;
            details.dotCoherence   = stim.dotCoherence;
            details.bkgdCoherence  = stim.bkgdCoherence;
            details.dotSpeed       = stim.dotSpeed;
            details.bkgdSpeed      = stim.bkgdSpeed;
            details.dotDirection   = stim.dotDirection;
            details.bkgdDirection  = stim.bkgdDirection;
            details.dotColor       = stim.dotColor;
            details.bkgdDotColor   = stim.bkgdDotColor;
            details.dotSize        = stim.dotSize;
            details.bkgdSize       = stim.bkgdSize;
            details.dotShape       = stim.dotShape;
            details.bkgdShape      = stim.bkgdShape;
            details.renderMode     = stim.renderMode;
            details.maxDuration    = stim.maxDuration;
            details.background     = stim.background;
            details.rngMethod      = stim.rngMethod;
            details.seedVal        = stim.seedVal;
            details.height         = stim.height;
            details.width          = stim.width;


            if isinf(stim.maxDuration)
                timeout=[];
            else
                timeout=stim.maxDuration;
            end

            switch stim.renderMode
                case 'perspective'
                    % lets make the render distances work here
                    stim.dotsRenderDistance = stimulus.renderDistance(1) + rand(stim.numDots,1)*(stimulus.renderDistance(2) - stimulus.renderDistance(1));
                    stim.bkgdRenderDistance = stimulus.renderDistance(1) + rand(stim.bkgdNumDots,1)*(stimulus.renderDistance(2) - stimulus.renderDistance(1));

                    details.dotsRenderDistance = stim.dotsRenderDistance;
                    details.bkgdRenderDistance = stim.bkgdRenderDistance;
                case 'flat'
                    % lets make the render distances work here
                    stim.dotsRenderDistance = ones(stim.numDots,1);
                    stim.bkgdRenderDistance = ones(stim.bkgdNumDots,1);

                    details.dotsRenderDistance = stim.dotsRenderDistance;
                    details.bkgdRenderDistance = stim.bkgdRenderDistance;
            end

            % LEDParams
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
                text=sprintf('coh: %g',stim.dotCoherence);
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

            % expertCache will have the current state of the system
            if isempty(expertCache)
                expertCache.previousXYDots=[];
                expertCache.previousXYBkgd=[];
                expertCache.nextVelDots=[];
                expertCache.nextVelBkgd=[];
            end

            black=0.0;
            white=1.0;
            gray = (white-black)/2;

            try
            if i ==1
                % for the first frame we will set nextVel to 0
                expertCache.nextVelDots=zeros(stim.numDots,2);
                expertCache.nextVelBkgd=zeros(stim.bkgdNumDots,2);

                % save current state
                try
                    prevState = rng;
                catch
                    prevState = rand('seed');
                end
                % seed the random number generator with available values (peppered with
                % the current frame number
                try
                    rng(stim.seedVal,stim.rngMethod);
                catch
                    rand('seed',stim.seedVal);
                end


                currentXYDots = rand(stim.numDots,2).*repmat([stim.width,stim.height],stim.numDots,1);
                currentXYBkgd = rand(stim.bkgdNumDots,2).*repmat([stim.width,stim.height],stim.bkgdNumDots,1);

                expertCache.previousXYDots=currentXYDots;
                expertCache.previousXYBkgd=currentXYBkgd;

                try
                    rng(prevState);
                catch
                    rand('seed',prevState);
                end
            end

            % get previous positions. this is same as the random positions chosen for
            % the first frame
            oldXYDots=expertCache.previousXYDots;
            oldXYBkgd=expertCache.previousXYBkgd;

            % get velocities calculated from previous frame. no change in velocity for
            % first frame
            currentXYDots=oldXYDots+expertCache.nextVelDots;
            currentXYBkgd=oldXYBkgd+expertCache.nextVelBkgd;

            % there needs to be code here that checks for out of boundedness
            dotsX = currentXYDots(:,1); 
            dotsY = currentXYDots(:,2);
            currentXYDots((dotsX<0),1) = dotsX(dotsX<0)+stim.width;
            currentXYDots((dotsX>stim.width),1) = dotsX(dotsX>stim.width)-stim.width;
            currentXYDots((dotsY<0),2) = dotsY(dotsY<0)+stim.height;
            currentXYDots((dotsY>stim.height),1) = dotsY(dotsY>stim.height)-stim.height;


            bkgdX = currentXYBkgd(:,1);
            bkgdY = currentXYBkgd(:,2);
            currentXYBkgd((bkgdX<0),1) = bkgdX(bkgdX<0)+stim.width;
            currentXYBkgd((bkgdX>stim.width),1) = bkgdX(bkgdX>stim.width)-stim.width;
            currentXYBkgd((bkgdY<0),2) = bkgdY(bkgdY<0)+stim.height;
            currentXYBkgd((bkgdY>stim.height),1) = bkgdY(bkgdY>stim.height)-stim.height;

            % find dotSize from stim.dotsRenderDistance and stim.bkdgRenderDistance
            dotSize = stim.dotSize./stim.dotsRenderDistance;
            bkgdSize = stim.bkgdSize./stim.bkgdRenderDistance;

            % find dotColor
            dotColor = repmat(stim.dotColor,stim.numDots,1);
            bkgdColor = repmat(stim.bkgdDotColor, stim.bkgdNumDots,1);

            % fill up the background to start with
            Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            Screen('FillRect', window,255*stim.background);
            % now the background dots
            hasBkgd = ~isempty(currentXYBkgd);
            if hasBkgd
                Screen('DrawDots',window,currentXYBkgd',bkgdSize',255*bkgdColor');
            end
            % and the actual dots
            Screen('DrawDots',window,currentXYDots',dotSize',255*dotColor');

            % good now these positions go into the expertCache
            expertCache.previousXYDots = currentXYDots;
            expertCache.previousXYBkgd = currentXYBkgd;

            % done with the drawing for this frame - we need to worry about drawing the
            % next frame now

            % figure out the speeds of the individual dots
            dotSpeed = stim.dotSpeed./stim.dotsRenderDistance; % units of dotSize/sec
            bkgdSpeed = stim.bkgdSpeed./stim.bkgdRenderDistance; % units of bkgdSize/sec

            % choose the coherent ones
            try
                prevState = rng;
                rng(stim.seedVal+i,stim.rngMethod);
            catch
                prevState = rand('seed');
                rand('seed',stim.seedVal+i);
            end
            whichCoherentDots = rand(stim.numDots,1)<stim.dotCoherence;
            whichCoherentBkgd = rand(stim.bkgdNumDots,1)<stim.bkgdCoherence;
            try
                rng(prevState);
            catch
                rand('seed',prevState);
            end
            % choose the chosen stim angle for the coherentOnes
            dotDirection = stim.dotDirection.*double(whichCoherentDots);
            bkgdDirection = stim.bkgdDirection.*double(whichCoherentBkgd);

            % get the x and y velocities by doing the trigonometric transformations
            expertCache.nextVelDots = [dotSpeed.*cos(dotDirection) -dotSpeed.*sin(dotDirection)]*stim.dotSize*ifi;
            expertCache.nextVelBkgd = [bkgdSpeed.*cos(bkgdDirection) -bkgdSpeed.*sin(bkgdDirection)]*stim.bkgdSize*ifi;

            % for the non coherent ones, set velocity to zero. set position to random
            expertCache.nextVelDots(~whichCoherentDots,:) = repmat([0 0],sum(double(~whichCoherentDots)),1);
            expertCache.nextVelBkgd(~whichCoherentBkgd,:) = repmat([0 0],sum(double(~whichCoherentBkgd)),1);
            expertCache.previousXYDots(~whichCoherentDots,:) = repmat([0 0],sum(double(~whichCoherentDots)),1);
            expertCache.previousXYBkgd(~whichCoherentBkgd,:) = repmat([0 0],sum(double(~whichCoherentBkgd)),1);
            expertCache.previousXYDots = expertCache.previousXYDots + rand(stim.numDots,2).*repmat([stim.width,stim.height],stim.numDots,1).*double([~whichCoherentDots ~whichCoherentDots]);
            expertCache.previousXYBkgd = expertCache.previousXYBkgd + rand(stim.bkgdNumDots,2).*repmat([stim.width,stim.height],stim.bkgdNumDots,1).*double([~whichCoherentBkgd ~whichCoherentBkgd]);

            catch ex
                getReport(ex)
                sca;
                keyboard
            end

        end % end function
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;

            try
                stimDetails=[trialRecords.stimDetails];
                [out.correctionTrial, newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                [out.pctCorrectionTrials, newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.doCombos, newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);

                [out.numDots, newLUT] = extractFieldAndEnsure(stimDetails,{'numDots'},'scalar',newLUT);
                [out.bkgdNumDots, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdNumDots'},'scalar',newLUT);

                [out.dotCoherence, newLUT] = extractFieldAndEnsure(stimDetails,{'dotCoherence'},'scalar',newLUT);
                [out.bkgdCoherence, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdCoherence'},'scalar',newLUT);

                [out.dotSpeed, newLUT] = extractFieldAndEnsure(stimDetails,{'dotSpeed'},'scalar',newLUT);
                [out.bkgdSpeed, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdSpeed'},'scalar',newLUT);

                [out.dotDirection, newLUT] = extractFieldAndEnsure(stimDetails,{'dotDirection'},'scalar',newLUT);
                [out.bkgdDirection, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdDirection'},'scalar',newLUT);

                [out.dotColor, newLUT] = extractFieldAndEnsure(stimDetails,{'dotColor'},'equalLengthVects',newLUT);
                [out.bkgdDotColor, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdDotColor'},'equalLengthVects',newLUT);

                [out.dotSize, newLUT] = extractFieldAndEnsure(stimDetails,{'dotSize'},'scalar',newLUT);
                [out.bkgdSize, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdSize'},'scalar',newLUT);

                [out.dotShape, newLUT] = extractFieldAndEnsure(stimDetails,{'dotShape'},'scalarLUT',newLUT);
                [out.bkgdShape, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdShape'},'scalarLUT',newLUT);

                [out.maxDuration, newLUT] = extractFieldAndEnsure(stimDetails,{'maxDuration'},'scalar',newLUT);
                [out.background, newLUT] = extractFieldAndEnsure(stimDetails,{'background'},'scalar',newLUT);

                [out.height, newLUT] = extractFieldAndEnsure(stimDetails,{'height'},'scalar',newLUT);
                [out.width, newLUT] = extractFieldAndEnsure(stimDetails,{'width'},'scalar',newLUT);

                [out.seedVal, newLUT] = extractFieldAndEnsure(stimDetails,{'seedVal'},'scalar',newLUT);

                [out.rngMethod, newLUT] = extractFieldAndEnsure(stimDetails,{'rngMethod'},'scalarLUT',newLUT);

                [out.renderMode, newLUT] = extractFieldAndEnsure(stimDetails,{'renderMode'},'scalarLUT',newLUT);

            catch ex
                if ismember(ex.identifier,{'MATLAB:UnableToConvert'})
                    stimDetails(length(trialRecords)).correctionTrial = NaN;
                    for i = 1:length(trialRecords)
                        if isstruct(trialRecords(i).stimDetails)
                            stimDetails(i).pctCorrectionTrials = trialRecords(i).stimDetails.pctCorrectionTrials;
                            stimDetails(i).correctionTrial = trialRecords(i).stimDetails.correctionTrial;
                            stimDetails(i).afcGratingType = trialRecords(i).stimDetails.afcGratingType;
                            stimDetails(i).doCombos = trialRecords(i).stimDetails.doCombos;
                            stimDetails(i).pixPerCycs = trialRecords(i).stimDetails.pixPerCycs;
                            stimDetails(i).driftfrequencies = trialRecords(i).stimDetails.driftfrequencies;
                            stimDetails(i).orientations = trialRecords(i).stimDetails.orientations;
                            stimDetails(i).phases = trialRecords(i).stimDetails.phases;
                            stimDetails(i).contrasts = trialRecords(i).stimDetails.contrasts;
                            stimDetails(i).radii = trialRecords(i).stimDetails.radii;
                            stimDetails(i).maxDuration = trialRecords(i).stimDetails.maxDuration;         
                        else
                            stimDetails(i).pctCorrectionTrials = nan;
                            stimDetails(i).correctionTrial = nan;
                            stimDetails(i).afcGratingType = 'n/a';
                            stimDetails(i).doCombos = nan;
                            stimDetails(i).pixPerCycs = nan;
                            stimDetails(i).driftfrequencies = nan;
                            stimDetails(i).orientations = nan;
                            stimDetails(i).phases = nan;
                            stimDetails(i).contrasts = nan;
                            stimDetails(i).radii = nan;
                            stimDetails(i).maxDuration = nan;
                        end
                    end
                    [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                    [out.doCombos newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);

                    [out.pixPerCycsCenter newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCycs'},'scalar',newLUT);
                    [out.driftfrequenciesCenter newLUT] = extractFieldAndEnsure(stimDetails,{'driftfrequencies'},'scalar',newLUT);
                    [out.orientationsCenter newLUT] = extractFieldAndEnsure(stimDetails,{'orientations'},'scalar',newLUT);
                    [out.phasesCenter newLUT] = extractFieldAndEnsure(stimDetails,{'phases'},'scalar',newLUT);
                    [out.contrastsCenter newLUT] = extractFieldAndEnsure(stimDetails,{'contrasts'},'scalar',newLUT);
                    [out.radiiCenter newLUT] = extractFieldAndEnsure(stimDetails,{'radii'},'scalar',newLUT);

                    [out.maxDuration newLUT] = extractFieldAndEnsure(stimDetails,{'maxDuration'},'scalar',newLUT);
                    [out.afcGratingType newLUT] = extractFieldAndEnsure(stimDetails,{'afcGratingType'},'scalarLUT',newLUT);
                else
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
                        sweepnames={'numDots','dotCoherence','dotSpeed','dotDirection','dotSize','dotShape','maxDuration'};

                        which = [false false false false false false false];
                        for i = 1:length(sweepnames)
                            if length(stim.(sweepnames{i}){1})>1 || length(stim.(sweepnames{i}){2})>1
                                which(i) = true;
                            end
                        end
                        out1=sweepnames(which);

                        if stim.bkgdNumDots{1}>0 || stim.bkgdNumDots{2}>0
                            sweepnames={'bkgdNumDots','bkgdCoherence','bkgdSpeed','bkgdDirection','bkgdSize','bkgdShape'};
                            which = [false false false false false false];
                            for i = 1:length(sweepnames)
                                if length(stim.(sweepnames{i}){1})>1 || length(stim.(sweepnames{i}){2})>1
                                    which(i) = true;
                                end
                            end
                            out2=sweepnames(which);
                        else
                            out2 = {};
                        end

                        out = {out1{:},out2{:}};

                        if size(stim.dotColor{1},1)>1 || size(stim.dotColor{2},1)>1
                            out{end+1} = 'dotColor';
                        end

                        if size(stim.bkgdDotColor{1},1)>1 || size(stim.bkgdDotColor{2},1)>1
                            out{end+1} = 'bkgdDotColor';
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
                        case 'numDots'
                            out = 'afcCoherentDots_numDots';
                        case 'bkgdNumDots'
                            out = 'afcCoherentDots_bkgdNumDots';
                        case 'dotCoherence'
                            out = 'afcCoherentDots_dotCoherence';
                        case 'bkgdCoherence'
                            out = 'afcCoherentDots_bkgdCoherence';
                        case 'dotSpeed'
                            out = 'afcCoherentDots_dotSpeed';
                        case 'bkgdSpeed'
                            out = 'afcCoherentDots_bkgdSpeed';
                        case 'dotDirection'
                            out = 'afcCoherentDots_dotDirection';
                        case 'bkgdDirection'
                            out = 'afcCoherentDots_bkgdDirection';
                        case 'dotColor'
                            out = 'afcCoherentDots_dotColor';
                        case 'bkgdDotColor'
                            out = 'afcCoherentDots_bkgdDotColor';
                        case 'dotSize'
                            out = 'afcCoherentDots_dotSize';
                        case 'bkgdSize'
                            out = 'afcCoherentDots_bkgdSize';
                        case 'dotShape'
                            out = 'afcCoherentDots_dotShape';
                        case 'bkgdShape'
                            out = 'afcCoherentDots_bkgdShape';
                        case 'maxDuration'
                            out = 'afcCoherentDots_maxDuration';
                        otherwise
                            out = 'undefinedGratings';
                    end
                case 2        
                    error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                case 3
                    error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');    
                case 4
                    error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');    
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


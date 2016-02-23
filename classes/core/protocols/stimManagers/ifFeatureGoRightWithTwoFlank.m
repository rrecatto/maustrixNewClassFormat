classdef ifFeatureGoRightWithTwoFlank<stimManager
    
    properties
        pixPerCycs = [];
        goRightOrientations = [];
        goLeftOrientations = [];
        flankerOrientations = [];
        distractorOrientations = [];
        distractorFlankerOrientations = [];

        topYokedToBottomFlankerOrientation =1;
        topYokedToBottomFlankerContrast =1;

        goRightContrast = [];
        goLeftContrast = [];
        flankerContrast = [];

        mean = 0;
        cueLum=0;
        cueSize=1;

        xPositionPercent = 0;
        cuePercentTargetEcc = 0;
        stdGaussMask = 0;
        flankerOffset = 0;

        flankerOnOff=8;
        targetOnOff=0;
        thresh = 0;
        targetYPosPct = 0;
        toggleStim = 0;
        typeOfLUT = [];
        rangeOfMonitorLinearized=[];
        maxCorrectOnSameSide=-1;

        %ADD THESE!
        positionalHint=0; %fraction of screen hinted.
        xPosNoise=0; %
         yPosNoise=0; %

        %%%%%%%%%%%%% NEW VARIABLES CREATED TO SET DISTRACTORS MIRRORED FROM
        %%%%%%%%%%%%% TARGET AND FLANKERS %%%%%%%%%%%%%%%%%%%%% Y.Z
        displayTargetAndDistractor=0;
        phase=0;
        persistFlankersDuringToggle=[];

        distractorFlankerYokedToTargetFlanker = 1;
        distractorContrast = 0;
        distractorFlankerContrast = 0;
        distractorYokedToTarget=1;

        flankerYokedToTargetPhase =0;
        fractionNoFlanks=[];
        %%%%%%%%%%%%%% END %%%%%%%%%%%%%%%%%%%%%%


         shapedParameter=[];
         shapingMethod=[];
         shapingValues=[];

         gratingType='square';


         framesMotionDelay = [];
         numMotionStimFrames = [];
         framesPerMotionStim = [];

         protocolType=[];
         protocolVersion=[];
         protocolSettings = [];

         flankerPosAngle = [];
         percentCorrectionTrials = [];

         fpaRelativeTargetOrientation=[];
         fpaRelativeFlankerOrientation=[];

         blocking=[];
         fitRF=[];
         dynamicSweep=[];

        renderMode=[];

        dynamicFlicker=[];

        stdsPerPatch=0;

        %start deflated
        cache = [];

        LUT=[];
    end
    
    methods
        
        function s=ifFeatureGoRightWithTwoFlank(varargin)
            % ||ifFeatureGoRightWithTwoFlank||  class constructor.
            %derived from cuedGoToFeatureWithTwoFlank
            %function calls below are out of date; use getDefaultParameters; see setFlankerStimRewardAndTrialManager for signature
            % s = ifFeatureGoRightWithTwoFlank([pixPerCycs],[goRightOrientations],[goLeftOrientations],[flankerOrientations],topYokedToBottomFlankerOrientation,topYokedToBottomFlankerContrast,[goRightContrast],[goLeftContrast],[flankerContrast],mean,cueLum,cueSize,xPositionPercent,cuePercentTargetEcc,stdGaussMask,flankerOffset,framesJustFlanker,framesTargetOn,thresh,yPositionPercent,toggleStim,typeOfLUT,rangeOfMonitorLinearized,maxCorrectOnSameSide,positionalHint,xPosNoise,yPosNoise,displayTargetAndDistractor,phase,persistFlankersDuringToggle,maxWidth,maxHeight,scaleFactor,interTrialLuminance,percentCorrectionTrials)
            % s = ifFeatureGoRightWithTwoFlank([32],[pi/2],[pi/2],[0],1,1,[0.5],[0.5],[0.5],0.5,0,1,0.5,0,1/16,3,int8(8),int8(0),0.001,0.5,1,'useThisMonitorsUncorrectedGamma',[0 1],int8(-1),0,0,0,600,800,0,0.5)
            % s = ifFeatureGoRightWithTwoFlank([32],[0],[pi/2],[0],1,1,[0.5],[0.5],[0.5],0.5,0,1,0.5,0,1/16,3,int8(8),int8(0),0.001,0.5,1,4,1280,1024,0,0.5)
            %
            % p=getDefaultParameters(ifFeatureGoRightWithTwoFlank,'goToRightDetection', '1_9','Oct.09,2007');
            % sm=getStimManager(setFlankerStimRewardAndTrialManager(p, 'test'));
            % [sm updateSM out scaleFactor type targetPorts distractorPorts details interTrialLuminance] = calcStim(sm,'nAFC',100,3,[1 1 1],1280,1024,[]);
            % imagesc(out(:,:,1)); colormap(gray)

            % pixPerCycs = 32;
            % goRightOrientations = [pi/2];
            % goLeftOrientations = [pi/2];
            % flankerOrientations = [0,pi/2]; %choose a random orientation from this list
            % %
            % topYokedToBottomFlankerOrientation =1;
            % topYokedToBottomFlankerContrast =1;
            % %
            % goRightContrast = [0.1,0.2,0.3];    %choose a random contrast from this list each trial
            % goLeftContrast = [0];
            % flankerContrast = [1];
            % %
            % mean = 0.5;              %normalized luminance
            % cueLum=0;                %luminance of cue sqaure
            % cueSize=1;               %roughly in pixel radii
            % %
            % xPositionPercent = 0.5;  %target position in percent ScreenWidth
            % cuePercentTargetEcc=0.6; %fraction of distance from center to target  % NOT USED IN cuedGoToFeatureWithTwoFlank
            % stdGaussMask =  3;       %in fraction of vertical height
            % flankerOffset = 4;       %distance in stdGaussMask (3.5 just touches edge)
            % %
            % framesJustCue=int8(30);
            % framesStimOn=int8(0);      %if 0, then leave stim on, which is a blank
            % thresh = 0.001;
            % yPositionPercent = 0.5;
            %
            %Might be missing some arguments
            %here:toggleStim,typeOfLUT,rangeOfMonitorLinearized,maxCorrectOnSameSide,
            %and more, see getDefaultParams, or setFlankerStimRewardAndTrialManager
            % toggleStim = 1;
            % typeOfLUT= 'useThisMonitorsUncorrectedGamma';
            % rangeOfMonitorLinearized=[0 1];
            % s.maxCorrectOnSameSide=-1;
            %
            % positionalHint=0.2;
            % xPosNoise=0.1;%standard deviation of noise in fractional screen width
            % yPosNoise=0;%standard deviation of noise in fractional screen height
            % displayTargetAndDistractor = 0;
            %
            % orientations in radians , these a distributions of possible orientations
            % mean, cueLum, cueSize, contrast, yPositionPercent, xPositionPercent normalized (0 <= value <= 1)
            % stdGaussMask is the std dev of the enveloping gaussian, in normalized  units of the vertical height of the stimulus image
            % thresh is in normalized luminance units, the value below which the stim should not appear
            % cuePercentTargetEcc is an vestigal variable not used

            switch nargin
                case 0
                    % if no input arguments, create a default object

                    %start deflated
                    s.cache.mask =[];
                    s.cache.goRightStim=[];
                    s.cache.goLeftStim=[];
                    s.cache.flankerStim=[];
                    s.cache.distractorStim = [];
                    s.cache.distractorFlankerStim= [];

                    s.LUT=[];


                    %     s.goRightStim =zeros(2,2,1);
                    %     s.goLeftStim = zeros(2,2,1);
                    %     s.flankerStim =zeros(2,2,1);

                    

                case 1
                    % if single argument of this class type, return it
                    switch class(varargin{1})
                        case 'ifFeatureGoRightWithTwoFlank'
                            s = varargin{1};
                        case 'char'
                            p=getDefaultParameters(ifFeatureGoRightWithTwoFlank);
                            p.mean=0.5;
                            switch varargin{1}
                                case 'def'
                                    %do nothing
                                case 'basic'
                                     p.flankerOffset=3;
                                     p.flankerContrast=1;
                                     p.stdGaussMask=1/16;
                                     p.pixPerCycs=32;
                                     p.phase=0;     
                                case {'sevenLocs','sevenLocsFast'}
                                    p.flankerContrast=0;
                                    p.goLeftContrast=1;
                                    p.goRightContrast=1;
                                    p.stdGaussMask=1/16;
                                    p.pixPerCycs=32;
                                    if strcmp(varargin{1},'sevenLocsFast')
                                        p.targetOnOff=int32([100 120]);
                                        p.flankerOnOff=int32([100 120]);
                                    else
                                        p.targetOnOff=int32([100 150]);
                                        p.flankerOnOff=int32([100 150]);
                                    end
                                    p.renderMode='dynamic-precachedInsertion'; % dynamic-maskTimesGrating, dynamic-onePatchPerPhase,or dynamic-onePatch

                                    numLocs=7;
                                    vals=linspace(0,1,numLocs+2);
                                    vals=vals(2:end-1);

                                    p.dynamicSweep.sweepMode={'random',1};
                                    p.dynamicSweep.sweptValues=[vals];
                                    p.dynamicSweep.sweptParameters={'xPositionPercent'};
                                    p.dynamicSweep.numRepeats=4;

                                    %p.typeOfLUT='2009Trinitron255GrayBoxInterpBkgnd.5';
                                    p.typeOfLUT= 'useThisMonitorsUncorrectedGamma';        
                                case {'phys','configPhys','contrastPhys','contrastPhysOnePhase','flankersMatterPhys'...
                                    'flankerMattersOnePhase','physFullFieldTarget','physFullFieldContrast'}

                                    p.flankerContrast=1;
                                    p.goLeftContrast=1;
                                    p.goRightContrast=1;
                                    p.stdGaussMask=1/16;
                                    p.stdGaussMask=1/8;
                                    p.pixPerCycs=32;
                                    %p.pixPerCycs=128; %768
                                    %p.pixPerCycs=180; %768

                                    ;

                                    %                         p.targetOnOff=int32([40 60]);
                                    %                          p.flankerOnOff=int32([40 60]);
                                    p.targetOnOff=int32([200 220]);
                                    p.flankerOnOff=int32([200 220]);
                                    p.flankerOffset=3;


                                    p.goRightOrientations = [pi/12];
                                    p.goLeftOrientations =  [pi/12];
                                    p.flankerOrientations = [pi/12];
                                    p.flankerPosAngle = [pi/12];

                                    %temp
                                    p.stdGaussMask=1/4;
                                    p.pixPerCycs=64
                                    p.pixPerCycs=128


                                    %p.showText=false;
                                    locationMode=3;
                                    switch locationMode
                                        case 1
                                            RFdataSource='\\132.239.158.169\datanet_storage';
                                            p.fitRF = RFestimator({'spatialWhiteNoise','fitGaussian',{1}},{'spatialWhiteNoise','fitGaussian',{1}},[],RFdataSource,[now-100 Inf]);
                                        case 2 %ERRORS >> NEEDS FIXING
                                            RFdataSource='\\132.239.158.169\datanet_storage'; % not actually used for lastDynamicSettings
                                            p.fitRF = RFestimator({'gratingWithChangeableAnnulusCenter','lastDynamicSettings',[]},{'gratingWithChangeableAnnulusCenter','lastDynamicSettings',[]},[],RFdataSource,[now-100 Inf]);
                                        otherwise
                                            p.xPositionPercent=.6;% 5/12; %0.3;
                                            p.yPositionPercent=.45; %5/8; %0.7;
                                            p.xPositionPercent=5/9;
                                            p.yPositionPercent=3/7; 
                                            p.stdGaussMask=1/10;
                                            p.fitRF=[];
                                    end

                                    %p.goLeftOrientations=p.goLeftOrientations(1);
                                    %p.goRightOrientations=p.goRightOrientations(1);
                                    %p.flankerOrientations=p.flankerOrientations(1);
                                    %p.flankerPosAngle=p.flankerPosAngle(1);

                                    p.phase=[pi]*[0 0.5 1 1.5];                       
                                    p.renderMode='dynamic-precachedInsertion'; % dynamic-maskTimesGrating, dynamic-onePatchPerPhase,or dynamic-onePatch

                                    %p.dynamicSweep.sweepMode={'ordered'};
                                    p.dynamicSweep.sweepMode={'random','clock'}; % repeats on a trial are the same, but across trials will be different
                                    p.dynamicSweep.sweptValues=[];
                                    p.typeOfLUT='2009Trinitron255GrayBoxInterpBkgnd.5';
                                    p.typeOfLUT= 'useThisMonitorsUncorrectedGamma';
                                    p.rangeOfMonitorLinearized=[0.0 1];

                                    if strcmp(varargin{1},'phys')
                                        kind='contrastPhysOnePhase'; % the default
                                    else
                                        kind=varargin{1};
                                    end

                                    switch kind
                                        case 'configPhys'
                                            %do nothing
                                            p.dynamicSweep.sweptParameters={'targetOrientations','flankerOrientations','flankerPosAngle'};% 'flankerOffset'
                                            p.dynamicSweep.numRepeats=8;
                                        case 'contrastPhys'
                                            p.flankerContrast=[0 .25 .5 .75 1];
                                            p.goLeftContrast=[0 .25 .5 .75 1];
                                            p.goRightContrast=[0 .25 .5 .75 1];
                                            p.dynamicSweep.numRepeats=1;

                                            p.dynamicSweep.sweptParameters={'targetContrast','flankerContrast','phase'};% 'flankerOrientations'}%,'flankerOffset','flankerPosAngle'};

                                        case 'contrastPhysOnePhase'

                                            p.flankerContrast=[0 .25 .5 .75 1];
                                            p.goLeftContrast=[0 .25 .5 .75 1];
                                            p.goRightContrast=[0 .25 .5 .75 1];
                                            p.dynamicSweep.numRepeats=6;

                                            p.phase=0;% pi/2;
                                            p.dynamicSweep.sweptParameters={'targetContrast','flankerContrast'};% 'flankerOrientations'}%,'flankerOffset','flankerPosAngle'};  
                                        case 'flankersMatterPhys'
                                            p.flankerContrast=[0 1];
                                            p.goLeftContrast=[0 1];
                                            p.goRightContrast=[0 1];
                                            p.dynamicSweep.numRepeats=20;
                                            p.dynamicSweep.sweptParameters={'targetContrast','flankerContrast','phase'};% 'flankerOrientations'}%,'flankerOffset','flankerPosAngle'};
                                        case 'flankerMattersOnePhase'
                                            p.flankerContrast=[0 1];
                                            p.goLeftContrast=[0 1];
                                            p.goRightContrast=[0 1];
                                            p.dynamicSweep.numRepeats=40;  
                                            p.phase=pi/2; %choose a good one
                                            p.dynamicSweep.sweptParameters={'targetContrast','flankerContrast','phase'};% 'flankerOrientations'}%,'flankerOffset','flankerPosAngle'};  

                                        case  'physFullFieldTarget'
                                            p.stdGaussMask=Inf;
                                            p.flankerContrast=0;
                                            p.targetOnOff=int32([40 60]);
                                            p.flankerOnOff=int32([40 60]);
                                            p.dynamicSweep.sweptParameters={'phase'};
                                            p.dynamicSweep.numRepeats=40;
                                            p.xPositionPercent=.5;
                                            p.yPositionPercent=.5;
                                        case 'physFullFieldContrast'
                                            p.stdGaussMask=Inf;
                                            p.flankerContrast=0;
                                            p.targetOnOff=int32([40 60]);
                                            p.flankerOnOff=int32([40 60]);

                                            %  p.targetOnOff=int32([200 220]);
                                            %  p.flankerOnOff=int32([200 220]);

                                            p.xPositionPercent=.5;
                                            p.yPositionPercent=.5;

                                            p.goLeftContrast=[0 .25 .5 .75 1];
                                            p.goRightContrast=[0 .25 .5 .75 1];
                                            p.dynamicSweep.numRepeats=4;
                                            p.dynamicSweep.sweptParameters={'targetContrast','phase'};% 'flankerOrientations'}%,'flankerOffset','flankerPosAngle'};    
                                    end
                                case {'horizontalVerticalCalib','horizontalVerticalSFCalib','calibFlankerLocationOrientation','calibFlankerPresence'}
                                    %calib stims
                                    p.goLeftContrast=1;
                                    p.goRightContrast=1;
                                    p.pixPerCycs=32; 
                                    p.targetOnOff=int32([20 300]);
                                    p.flankerOnOff=int32([20 300]);
                                    p.targetOnOff=int32([10 80]);
                                    p.flankerOnOff=int32([10 80]);

                                    ors=[0 pi/2]; %[-pi/12 pi/12]; %
                                    p.goRightOrientations = ors;
                                    p.goLeftOrientations =  ors;
                                    p.flankerOrientations =  ors;

                                    switch varargin{1}
                                        case {'horizontalVerticalCalib','horizontalVerticalSFCalib'}
                                            p.flankerContrast=0;
                                            p.stdGaussMask=1/8;
                                            numPhases=16;
                                            temp=linspace(0,pi*2,numPhases+1)
                                            p.phase=temp(1:end-1);
                                            p.dynamicSweep.sweptParameters={'targetOrientations','phase'};

                                            if strcmp(varargin{1},'horizontalVerticalSFCalib')
                                                p.blocking.blockingMethod='nTrials';
                                                p.blocking.nTrials=1;
                                                p.blocking.shuffleOrderEachBlock=false;
                                                p.blocking.sweptParameters={'pixPerCycs'};
                                                p.pixPerCycs=2.^[2:8]; 
                                                p.blocking.sweptValues=p.pixPerCycs;
                                            end
                                        case 'calibFlankerLocationOrientation'
                                            p.flankerContrast=1;
                                            p.flankerPosAngle=p.goRightOrientations;
                                            p.stdGaussMask=1/16;
                                            p.phase=0;
                                            p.flankerOffset=3;
                                            p.dynamicSweep.sweptParameters={'targetOrientations','flankerOrientations','flankerPosAngle'};% 'flankerOffset'
                                        case 'calibFlankerPresence'
                                            p.flankerContrast=[0 1];
                                            p.flankerPosAngle=p.goRightOrientations;
                                            p.stdGaussMask=1/16;
                                            p.phase=0;
                                            p.flankerOffset=3;
                                            p.dynamicSweep.sweptParameters={'flankerContrast','flankerOrientations','flankerPosAngle'};% 
                                    end

                                    p.gratingType='sine';
                                    p.maxWidth=800;
                                    p.maxHeight=600;
                                    p.showText=false;
                                    locationMode=3;
                                    switch locationMode
                                        case 1
                                            RFdataSource='\\132.239.158.169\datanet_storage';
                                            p.fitRF = RFestimator({'spatialWhiteNoise','fitGaussian',{1}},{'spatialWhiteNoise','fitGaussian',{1}},[],RFdataSource,[now-100 Inf]);
                                        case 2
                                            RFdataSource='\\132.239.158.169\datanet_storage'; % not actually used for lastDynamicSettings
                                            p.fitRF = RFestimator({'gratingWithChangeableAnnulusCenter','lastDynamicSettings',[]},{'gratingWithChangeableAnnulusCenter','lastDynamicSettings',[]},[],RFdataSource,[now-100 Inf]);
                                        otherwise
                                            p.xPositionPercent=.5;
                                            p.yPositionPercent=.5; 
                                            p.fitRF=[];
                                    end


                                    p.renderMode='dynamic-precachedInsertion'; % dynamic-maskTimesGrating, dynamic-onePatchPerPhase,or dynamic-onePatch
                                    p.dynamicSweep.sweepMode={'ordered'};
                                    p.dynamicSweep.sweptValues=[];
                                    p.dynamicSweep.numRepeats=6;
                                    p.typeOfLUT='2009Trinitron255GrayBoxInterpBkgnd.5';
                                    p.typeOfLUT= 'useThisMonitorsUncorrectedGamma';

                                case 'testFlicker'

                                   %save space for the memory problem of making all the tex's
                                    %p.goLeftOrientations=p.goLeftOrientations(1);
                                    %p.goRightOrientations=p.goRightOrientations(1);
                                    %p.flankerOrientations=p.flankerOrientations(1);

                                    %p.stdGaussMask=Inf;
                                    p.stdGaussMask=1/16;
                                    p.flankerOffset=3;

                                    p.flankerContrast=0;
                                    p.goLeftContrast=1;
                                    p.goRightContrast=1;
                                    p.pixPerCycs=32;
                                    p.targetOnOff=int32([300 340]);
                                    p.flankerOnOff=int32([1 340]);
                                    p.renderMode='dynamic-precachedInsertion'; % dynamic-maskTimesGrating, dynamic-onePatchPerPhase,or dynamic-onePatch

                                    p.dynamicSweep.sweepMode={'ordered'};
                                    p.dynamicSweep.sweptValues=[];
                                    p.dynamicSweep.sweptParameters={'targetOrientations'};
                                    p.dynamicSweep.numRepeats=20;

                                    p.phase=0;%2*pi*[1:8]/8;   

                                    %example setup
                                    p.dynamicFlicker.flickerMode='random';
                                    p.dynamicFlicker.flickeringParameters={'flankerContrast','phase'};
                                    p.dynamicFlicker.flickeringValues{1}=[0 0 0 0 0 0 0 0 0 0 0 0 0.2];
                                    p.dynamicFlicker.flickeringValues{2}=p.phase;
                                    p.dynamicFlicker.framesSavedBeforeAfter=[300 100];


                                case '10'
                                    p.renderMode='ratrixGeneral-precachedInsertion';
                                otherwise
                                    varargin{1}
                                    error('Single input argument is bad')
                            end
                             s=getStimManager(setFlankerStimRewardAndTrialManager(p));
                        otherwise
                            class(varargin{1})
                            error('Single input argument is bad')
                    end
                case 61
                    % create object using specified values

                    if all(varargin{1})>0
                        s.pixPerCycs=varargin{1};
                    else
                        error('pixPerCycs must all be > 0')
                    end

                    if all(isnumeric(varargin{2})) && all(isnumeric(varargin{3})) && all(isnumeric(varargin{4})) && all(isnumeric(varargin{32})) && all(isnumeric(varargin{33}))
                        s.goRightOrientations=varargin{2};
                        s.goLeftOrientations=varargin{3};
                        s.flankerOrientations=varargin{4};
                        s.distractorOrientations=varargin{32};
                        s.distractorFlankerOrientations=varargin{33};
                    else
                        varargin{2}
                        varargin{3}
                        varargin{4}
                        varargin{32}
                        varargin{33}
                        error('target, distractor and flanker orientations must be numbers')
                    end

                    if varargin{5}==1 %|| varargin{5}==0
                        s.topYokedToBottomFlankerOrientation=varargin{5};
                    else
                        error('topYokedToBottomFlankerOrientation must be 1')
                    end

                    if varargin{6}==1 %|| varargin{6}==0
                        s.topYokedToBottomFlankerContrast=varargin{6};
                    else
                        error('topYokedToBottomFlankerContrast must be 1')
                    end

                    if all(varargin{7} >= 0 & varargin{7}<=1)
                        s.goRightContrast=varargin{7};
                    else
                        error('0 <= all goRightContrasts <= 1')
                    end

                    if all(varargin{8} >= 0 & varargin{8}<=1)
                        s.goLeftContrast=varargin{8};
                    else
                        error('0 <= all goLeftContrast <= 1')
                    end

                    if all(varargin{9} >= 0 & varargin{9}<=1)
                        s.flankerContrast=varargin{9};
                    else
                        error('0 <= all flankerContrast <= 1')
                    end

                    if varargin{10} >= 0 && varargin{10}<=1
                        s.mean=varargin{10};
                    else
                        error('0 <= mean <= 1')
                    end

                    if (varargin{11} >= 0 & varargin{11}<=1) | isempty(varargin{11})
                        s.cueLum=varargin{11};
                    else
                        error('0 <= cueLum <= 1')
                    end

                    if varargin{12} >= 0 && varargin{12}<=10
                        s.cueSize=varargin{12};
                    else
                        error('0 <= cueSize <= 10')
                    end

                    if varargin{13} >= 0 && varargin{13}<=1
                        s.xPositionPercent=varargin{13};
                    else
                        error('0 <= xPositionPercent <= 1')
                    end

                    if varargin{14} >= 0 && varargin{14}<=1
                        s.cuePercentTargetEcc=varargin{14};
                    else
                        error('0 <= cuePercentTargetEcc <= 1')
                    end

                    if varargin{15} >= 0
                        s.stdGaussMask=varargin{15};
                    else
                        error('0 <= stdGaussMask')
                    end

                    if varargin{16} >= 0
                        s.flankerOffset=varargin{16}; % also check to see if on screen... need stim.screenHeight
                    else
                        error('0 <= flankerOffset < something with a center that fits on the screen')
                    end

                    if all(varargin{17} > 0) && isinteger(varargin{17}) && size(varargin{17},2)==2 && varargin{17}(1)<varargin{17}(2)
                        s.flankerOnOff=varargin{17};
                    else
                        error('0 <= flankerOnOff; must be two increasing integers...this will become framesFlankerOnOff')
                    end

                    if all(varargin{18} > 0) && isinteger(varargin{18}) && size(varargin{18},2)==2 && varargin{18}(1)<varargin{18}(2)
                        s.targetOnOff=varargin{18};
                    else
                        error('0 <= targetOnOff; must be two increasing integers...this will become framesTargetOnOff')
                    end


                    if varargin{19} >= 0
                        s.thresh=varargin{19};
                    else
                        error('thresh must be >= 0')
                    end

                    if isnumeric(varargin{20}) && varargin{20} >= 0 && varargin{20}<=1
                        s.targetYPosPct=varargin{20};
                    else
                        error('yPositionPercent must be numeric')
                    end

                    if (isnumeric(varargin{21}) && (varargin{21}==1 || varargin{21}==1)) || islogical(varargin{21})
                        s.toggleStim=varargin{21};
                    else
                        error('toggleStim must be logical')
                    end

                    if any(strcmp(varargin{22},{'linearizedDefault','useThisMonitorsUncorrectedGamma','mostRecentLinearized','2009Trinitron255GrayBoxInterpBkgnd.5'}))
                        s.typeOfLUT=varargin{22};
                    else
                        error('typeOfLUT must be linearizedDefault, useThisMonitorsUncorrectedGamma, or mostRecentLinearized')
                    end

                    if 0<=varargin{23}& varargin{23}<=1 & size(varargin{23},1)==1 & size(varargin{23},2)==2
                        s.rangeOfMonitorLinearized=varargin{23};
                    else
                        error('rangeOfMonitorLinearized must be greater than or =0 and less than or =1')
                    end

                    if (0<varargin{24}| varargin{24}==-1 )& isinteger(varargin{24})
                        s.maxCorrectOnSameSide=varargin{24};
                    else
                        error('maxCorrectOnSameSide must be an integer greater than 0, or be equal to -1 in order to not limit at all')
                    end

                    if 0<=varargin{25}& varargin{25}<=1
                        s.positionalHint=varargin{25};
                    else
                        error('positionalHint must be greater than 0, and less than 1')
                    end

                    if 0<=varargin{26}
                        s.xPosNoise=varargin{26};
                    else
                        error('xPosNoise must be greater than 0')
                    end

                    if 0<=varargin{27}
                        s.yPosNoise=varargin{27};
                    else
                        error('yPosNoise must be greater than 0')
                    end

                    if 0==varargin{28}|1==varargin{28};
                        s.displayTargetAndDistractor=varargin{28};
                    else
                        error('displayTargetAndDistractor must be 0 or 1')
                    end

                    if all(0<=varargin{29}) & all(2*pi>=varargin{29});
                        s.phase=varargin{29}; %Phase can now be randomized 07/10/04 pmm
                    else
                        error('all phases must be >=0 and <=2*pi')
                    end

                    if (0==varargin{30}) | (1==varargin{30});
                        s.persistFlankersDuringToggle=varargin{30};
                    else
                        error('persistFlankersDuringToggle must be 0 or 1')
                    end

                    if (0==varargin{31}) | (1==varargin{31});
                        s.distractorFlankerYokedToTargetFlanker=varargin{31};
                    else
                        error('distractorFlankerYokedToTargetFlanker must be 0 or 1')
                    end

                    %see the other orientations
                    %s.distractorOrientations = 0; %32
                    %s.distractorFlankerOrientations = 0; %33

                    if all(varargin{34} >= 0 & varargin{34}<=1)
                        s.distractorContrast=varargin{34};
                    else
                        error('0 <= all distractorContrast <= 1')
                    end

                    if all(varargin{35} >= 0 & varargin{35}<=1)
                        s.distractorFlankerContrast=varargin{35};
                    else
                        error('0 <= all distractorFlankerContrast <= 1')
                    end

                    if (0==varargin{36}) | (1==varargin{36});
                        s.distractorYokedToTarget=varargin{36};
                    else
                        error('distractorYokedToTarget must be 0 or 1')
                    end

                    if (0==varargin{37}) | (1==varargin{37});
                        s.flankerYokedToTargetPhase=varargin{37};
                    else
                        error('flankerYokedToTargetPhase must be 0 or 1')
                    end

                    if all(varargin{38} >= 0 & varargin{38}<=1)
                        s.fractionNoFlanks=varargin{38};
                    else
                        error('0 <= all fractionNoFlanks <= 1')
                    end

                    if (isempty(varargin{39}) | any(strcmp(varargin{39},{'positionalHint', 'stdGaussMask','targetContrast','flankerContrast','xPosNoise'})))
                        s.shapedParameter=varargin{39};
                    else
                        error ('shapedParameter must be positionalHint or stdGaussianMask or targetContrast or flankerContrast or xPosNoise')
                    end

                    if (isempty(varargin{40}) | any(strcmp(varargin{40},{'exponentialParameterAtConstantPerformance', 'geometricRatioAtCriteria','linearChangeAtCriteria'})))
                        s.shapingMethod=varargin{40};
                    else
                        error ('shapingMethod must be exponentialParameterAtConstantPerformance or geometricRatioAtCriteria or linearChangeAtCriteria')
                    end

                    if isempty(s.shapingMethod)
                        s.shapingValues=[];
                    else %only check values if a method is selected
                        if (checkShapingValues(ifFeatureGoRightWithTwoFlank(),s.shapingMethod,varargin{41}))
                            s.shapingValues=varargin{41};
                        else
                            error ('wrong fields in shapingValues')
                        end
                    end

                    if  any(strcmp(varargin{42},{'square', 'sine'}))
                        s.gratingType=varargin{42};
                    else
                        error('waveform must be square or sine')
                    end

                    if  isnumeric(varargin{43}) && length(varargin{43})==1
                        s.framesMotionDelay=floor(varargin{43});
                    else
                        error('framesMotionDelay must be a single number')
                    end

                    if  isnumeric(varargin{44}) && length(varargin{44})==1
                        s.numMotionStimFrames=floor(varargin{44});
                    else
                        error('numMotionStimFrames must be a single number')
                    end

                    if  isnumeric(varargin{45}) && length(varargin{45})==1
                        s.framesPerMotionStim=floor(varargin{45});
                    else
                        error('framesPerMotionStim must be a single number')
                    end

                    if  any(strcmp(varargin{46},{'goToRightDetection', 'goToLeftDetection','tiltDiscrim','goToSide','goNoGo','cuedGoNoGo'}))
                        s.protocolType=varargin{46};
                    else
                        varargin{46}
                        error('protocolType must be goToRightDetection or goToLeftDetection or tiltDiscrim or goToSide')
                    end

                    if  any(strcmp(varargin{47},{'1_0','1_1','1_2','1_3','1_4','1_5','1_6','1_7','1_8','1_9','2_0','2_1','2_2','2_3','2_3reduced','2_4', '2_5validate','2_5','2_6','2_6validate','2_6special'}))
                        s.protocolVersion=varargin{47};
                    else
                        varargin{47}
                        error('protocolVersion must be very specific')
                    end

                    if  any(strcmp(varargin{48},{'Oct.09,2007','Apr.13,2009','May.02,2009','Dec.11,2009'}))
                        s.protocolSettings=varargin{48};
                    else
                        error('protocolSettings must be very specific string')
                    end

                    if  isnumeric(varargin{49}) && all(size(varargin{49},1)==1)
                        s.flankerPosAngle=varargin{49};
                    else
                        error('flankerPosAngle must be a numeric vector, for now size 1, maybe matrix one day')
                    end


                    if  varargin{50} >= 0 && varargin{50}<=1 && all(size(varargin{50})==1)
                        s.percentCorrectionTrials=varargin{50};
                    else
                        error('percentCorrectionTrials must be a single numer between 0 and 1')
                    end

                    if  isnan(varargin{51}) | (isnumeric(varargin{51}) && size(varargin{51},1)==1)

                        if ~isnan(varargin{51})
                            %error check that the right targets are there
                            relatives=varargin{51};
                            fpas=s.flankerPosAngle;
                            required=repmat(relatives,size(fpas,2),1)-repmat(fpas',1,size(relatives,2));
                            if all(ismember(required(:),s.goRightOrientations)) && all(ismember(required(:),s.goLeftOrientations));
                                %good
                            else
                                unique(required(:))
                                s.goRightOrientations
                                s.goLeftOrientations
                                error('both goLeft and goRight must have target orientations required for this fpaRelativeTargetOrientation' )
                            end
                        end
                        s.fpaRelativeTargetOrientation=varargin{51};
                    else
                        error('fpaRelativeTargetOrientation must be a vectors of numbers or NaN')
                    end

                    if  isnan(varargin{52}) | (isnumeric(varargin{52}) && size(varargin{52},1)==1)

                        if ~isnan(varargin{52})
                            %error check that the right flankers are there
                            relatives=varargin{52};
                            fpas=s.flankerPosAngle;
                            required=repmat(relatives,size(fpas,2),1)-repmat(fpas',1,size(relatives,2));
                            if all(ismember(required(:),s.flankerOrientations))
                                %good
                            else
                                unique(required(:))
                                s.flankerOrientations
                                error('flankerOrientations must have flanker orientations required for this fpaRelativeFlankerOrientation' )
                            end
                        end
                        s.fpaRelativeFlankerOrientation=varargin{52};

                    else
                        error('fpaRelativeTargetOrientation must be a vectors of numbers or NaN')
                    end

                    if (checkBlocking(ifFeatureGoRightWithTwoFlank(),varargin{53}))
                        s.blocking=varargin{53};
                    else
                        error ('wrong fields in blocking')
                    end

                    if isa(varargin{54},'RFestimator') || isempty(varargin{54})%(checkFitRF(ifFeatureGoRightWithTwoFlank(),varargin{54}))
                        s.fitRF=varargin{54};
                    else
                        error ('fitRF must be an RFestimator object or empty')
                    end

                    if (checkDynamicSweep(ifFeatureGoRightWithTwoFlank(),varargin{55}))
                        s.dynamicSweep=varargin{55};
                    else
                        error ('wrong fields in dynamicSweep')
                    end

                    if  any(strcmp(varargin{56},{'ratrixGeneral-maskTimesGrating', 'ratrixGeneral-precachedInsertion','dynamic-precachedInsertion','dynamic-maskTimesGrating','dynamic-onePatchPerPhase','dynamic-onePatch'}))
                        s.renderMode=varargin{56};   
                    else
                        error('renderMode must be ratrixGeneral-maskTimesGrating, ratrixGeneral-precachedInsertion,dynamic-precachedInsertion, dynamic-maskTimesGrating, dynamic-onePatchPerPhase,or dynamic-onePatch')
                    end

                    if (checkDynamicFlicker(ifFeatureGoRightWithTwoFlank(),varargin{57}))
                        s.dynamicFlicker=varargin{57};
                    else
                        error ('wrong fields in dynamicFlicker')
                    end

                    %s.phase=0; %no longer randomized;   would need movie for that (hieght x width x orientations x phase)
                    %maxHeight=varargin{22**old val};

                    %determine gabor window size within patch here
                    if ~isinf(s.stdGaussMask)
                        s.stdsPerPatch=4; %this is an even number that is very reasonable fill of square
                    else
                        s.stdsPerPatch=0;  % will create infinite radius  
                    end

                    %start deflated
                    s.cache.mask =[];
                    s.cache.goRightStim=[];
                    s.cache.goLeftStim=[];
                    s.cache.flankerStim=[];
                    s.cache.distractorStim = [];
                    s.cache.distractorFlankerStim= [];

                    s.LUT=[];

                    %error checks
                    if ~isempty(s.blocking) && (any(~isnan(s.fpaRelativeFlankerOrientation)) || any(~isnan(s.fpaRelativeTargetOrientation)))
                        frfo=s.fpaRelativeFlankerOrientation
                        frto=s.fpaRelativeTargetOrientation
                        s.blocking
                        warning('blocking interferes with fpa relative methods')
                        %maybe make sure relative value is being blockwd
                    end

                    firstSuper=nargin-3;
                    s = class(s,'ifFeatureGoRightWithTwoFlank',stimManager(varargin{firstSuper},varargin{firstSuper+1},varargin{firstSuper+2},varargin{firstSuper+3}));

                    %s=inflate(s);
                    %s=deflate(s);
                    %s=inflate(s);
                    if ~strcmp(s.typeOfLUT, 'useThisMonitorsUncorrectedGamma')
                        disp(sprintf('at start up will be linearizing monitor in range from %s to %s', num2str(s.rangeOfMonitorLinearized(1)), num2str(s.rangeOfMonitorLinearized(2))))
                    end
                    %s=fillLUT(s,s.typeOfLUT,s.rangeOfMonitorLinearized,0);


                otherwise
                    nargin
                    size(nargin)
                    error('Wrong number of input arguments')
            end

            % s=setSuper(s,s.stimManager);
        
        end
        
        function targetIsPresent=checkTargetIsPresent(sm,details)
            switch details.protocolType

                case {'goToRightDetection','goNoGo','cuedGoNoGo'}

                    %details.correctResponseIsLeft=-1; %goNoGo uses the stimulus that means "go right"==stimulus is there
                    %this is only the wierd historic convention of ifFeatureGoRightWithTwoFlank, 
                    %and future stim managers can use whatever fact they want in checkTargetIsPresent

                    if details.correctResponseIsLeft==1       
                          if details.targetContrast==0
                              targetIsPresent=false;
                          else 
                              error('should never get here');
                          end
                        elseif details.correctResponseIsLeft==-1 
                            if details.targetContrast==0
                                error('should never get here');
                            else
                                targetIsPresent=true;
                            end
                        else
                            error('Invalid response side value. details.correctResponseIsLeft must be -1 or 1.')
                        end

                case 'goToLeftDetection'
                    if details.correctResponseIsLeft==1       
                        if details.targetContrast==0
                            error('should never get here');
                        else
                            targetIsPresent=true;
                        end
                    elseif details.correctResponseIsLeft==-1
                        if details.targetContrast==0
                            targetIsPresent=false;
                        else
                            error('should never get here');
                        end
                    else
                        error('Invalid response side value. details.correctResponseIsLeft must be -1 or 1.')
                    end

                case {'tiltDiscrim','goToSide'}
                    error('Discrimination does not define if target is absent of present');

                otherwise
                    error('That protocolType is not handled');

            end
        end
        
        function details=computeSpatialDetails(stimulus,details);
            %for everything thats computed off of spatial details

            %LOCAL VALUES - derive from details only (or unchanging stim values ~ constants)
            height=details.height;
            width=details.width;

            [szX szY]=getPatchSize(stimulus);
            fracSizeX=szX/width;
            fracSizeY=szY/height;

            if ~isinf(details.stdGaussMask)
                dev = details.flankerOffset*details.stdGaussMask;
            else
                dev=0; % infinitelty large patches don't get translated at all
            end
            devY = dev.*cos(details.flankerPosAngles(1)); %caluate from details
            devX = dev.*sin(details.flankerPosAngles(1));
            nDevX= devX* (height/width); %normalized by the height:width ratio, so that when screen width is multiplied by the fraction x value, the linear displacement is appropriate

            %compute and save some details too
            details.deviation = dev;    %fractional devitation
            details.devPix=[devY*getMaxHeight(stimulus) devX*getMaxHeight(stimulus) ];  %pixel deviation, note: horizontal is still normalized to screen vertical, which is okay in square pixel world
            details.patchX1=ceil(getMaxHeight(stimulus)*details.stdGaussMask*stimulus.stdsPerPatch);
            details.patchX2=szX;
            details.stdGaussMaskPix=details.stdGaussMask*ceil(getMaxHeight(stimulus));


            stimFit = 0;
            resampleCounter = 0;
            while stimFit == 0
                %CREATE CENTERS
                numPatchesInserted=3;
                centers =...
                    ...%yPosPct                      yPosPct                          xPosPct                              xPosPct
                    [ details.yPositionPercent       details.yPositionPercent         details.xPositionPercent           details.xPositionPercent;...          %target
                    details.yPositionPercent+devY    details.yPositionPercent+devY    details.xPositionPercent-nDevX     details.xPositionPercent-nDevX;...    %top  (firstFlanker, on top if flankerPosAngle == 0)
                    details.yPositionPercent-devY    details.yPositionPercent-devY    details.xPositionPercent+nDevX     details.xPositionPercent+nDevX];      %bottom (secondFlanker, on bottom if flankerPosAngle == 0)

                if stimulus.displayTargetAndDistractor
                    numPatchesInserted=numPatchesInserted*2;
                    centers =repmat(centers,2,1);
                    %             [ stimulus.targetYPosPct        stimulus.targetYPosPct          xPosPct                xPosPct;...                   %target
                    %             stimulus.targetYPosPct+devY     stimulus.targetYPosPct+devY     xPosPct-nDevX          xPosPct-nDevX;...             %top
                    %             stimulus.targetYPosPct-devY     stimulus.targetYPosPct-devY     xPosPct+nDevX          xPosPct+nDevX ;...            %bottom
                    %             stimulus.targetYPosPct          stimulus.targetYPosPct          xPosPct                xPosPct;...                   %distractor
                    %             stimulus.targetYPosPct+devY     stimulus.targetYPosPct+devY     xPosPct-nDevX          xPosPct-nDevX;...             %top
                    %             stimulus.targetYPosPct-devY     stimulus.targetYPosPct-devY     xPosPct+nDevX          xPosPct+nDevX ];              %bottom
                end

                %DETERMINE SCREEN POSITIONS IN PIXELS
                pos = round(centers.* repmat([ height, height, width, width],numPatchesInserted,1)...          %convert to pixel vals
                    -  repmat([ floor(szY/2), -(ceil(szY/2)-1 ), floor(szX/2) -(ceil(szX/2)-1)],numPatchesInserted,1))+1; %account for patch size
                xPixHint = round(details.positionalHint * width)*sign(-details.correctResponseIsLeft); % x shift value in pixels caused by hint
                detail.xPixShiftHint = xPixHint;

                hintOffSet= repmat([0, 0, xPixHint, xPixHint], numPatchesInserted, 1);
                if stimulus.displayTargetAndDistractor
                    %first half move one direction, second half move the other
                    hintOffSet(numPatchesInserted/2+1:end,:)= -hintOffSet(1:numPatchesInserted/2,:)
                    %  hintOffSet= [repmat([0, 0,  xPixHint,  xPixHint], numPatchesInserted/2, 1);...
                    %  repmat([0, 0, -xPixHint, -xPixHint], numPatchesInserted/2, 1)];
                end
                pos = pos + hintOffSet;

                % CHECK ERROR WITHOUT NOISE - dynamic may pass
                if any(any((pos(:,1:2)<1) | (pos(:,1:2)>height) | (pos(:,3:4)<1) | (pos(:,3:4)>width))) && isempty(strfind(stimulus.renderMode,'dynamic'))
                    width
                    height
                    xPixHint
                    szY
                    centers
                    pos
                    sca
                    mfilename
                    %keyboard

                    error('At least one image patch is going to be off the screen.  Make patches smaller or closer together or check the size of xPosHint.')
                end

                % ADD NOISE TERMS TO PIXEL POSITIONS
                xPixShift = round(details.xPosNoiseStd * randn * width);  % x shift value in pixels caused by noise
                yPixShift = round(details.yPosNoiseStd * randn * height); % y shift value in pixels caused by noise
                details.xPosNoisePix = xPixShift;
                details.yPosNoisePix = yPixShift;
                details.xPosNoiseSample = xPixShift/width;
                details.yPosNoiseSample = yPixShift/height;

                pos = pos + repmat([yPixShift, yPixShift, xPixShift, xPixShift], numPatchesInserted, 1);

                %ERROR CHECK WITH NOISE
                if any(any((pos(:,1:2)<1) | (pos(:,1:2)>height) | (pos(:,3:4)<1) | (pos(:,3:4)>width))) && isempty(strfind(stimulus.renderMode,'dynamic'))
                    resampleCounter = resampleCounter+1;
                    display(sprintf('stimulus off screen because of noise, number of resamples = %d', resampleCounter));
                    if resampleCounter > 10
                        error('too many resamples, reconsider the size of the noise');
                    end
                else
                    stimFit = 1;
                    details.stimRects = pos;
                    details.PTBStimRects = [pos(:, 3), pos(:, 1), pos(:, 4), pos(:, 2)];
                end
            end
        end

        function [stimulus updateSM out LUT scaleFactor type targetPorts distractorPorts details interTrialLuminance] = controlledCalcStim(stimulus,trialManagerClass,frameRate,responsePorts,totalPorts,width,height,trialRecords, controlledParams)
            % This Function was made for the sole purpose of rendering stimuli for
            % Cosyne.
            % It accepts controlled parameters and renders those features 

            %setup for first trial...

            if ~stimIsCached(stimulus)
                stimulus=inflate(stimulus);
                setSeed(stimulus, 'seedFromClock');
                updateSM=1;
            else
                updateSM=0;
            end

            a=rand('seed');
            b=randn('seed');
            details.randomMethod='seedFromClock';
            details.randomSeed=[a(end) b(end)]; %if using twister method, this single number is pretty meaningless

            if ~isempty(stimulus.shapedParameter)
                [parameterChanged, stimulus]  = shapeParameter(stimulus, trialRecords); %will CopyOnWrite help?
                %else 'checkShape' and 'doShape' are different functions...
                if parameterChanged
                    updateSM=1;
                end
                details.currentShapedValue=stimulus.shapingValues.currentValue; 
            else
                details.currentShapedValue=nan; 
            end

            details.shapedParameter=stimulus.shapedParameter;
            details.shapingMethod=stimulus.shapingMethod;
            details.shapingValues=stimulus.shapingValues;  

            details.toggleStim=stimulus.toggleStim;

            if details.toggleStim==1
                type='trigger';
            else
                type='timedFrames'; %will be set to a vector
                %by virture of being a vector, not a string, will be treated as
                %timedFrames type

                %frameTimes=[stimulus.framesJustCue/2,stimulus.framesJustCue,stimulus.framesStimOn]; %edf divided the cue time in half -- impatient rats respond too early.  we should really prevent responses before stim (even after cue)
                %frameTimes=[1,4*stimulus.framesJustCue,stimulus.framesStimOn]; %edf hacked

                frameTimes=[stimulus.framesJustCue,stimulus.framesStimOn,int8(0)]; %pmm hacked
                type=frameTimes;
            end

            %scaleFactor = getScaleFactor(stimulus);
            scaleFactor = 0; %makes it full screen

            interTrialLuminance = getInterTrialLuminance(stimulus);

            LUT=getLUT(stimulus);
            details.LUT=LUT;  % in future, consider saving a LUT id?
            %interTrialLuminance = 0.5;

            %edf: 11.15.06 realized we didn't have correction trials!
            details.pctCorrectionTrials=0.5; % need to change this to be passed in from trial manager
            %details.pctCorrectionTrials=stimulus.percentCorrectionTrials; % need to change this to be passed in from trial manager

            details.maxCorrectForceSwitch=0;  % make sure this gets defined even if no trial records or free drinks

            if ~isempty(trialRecords)
                lastResponse=find(trialRecords(end).response);
                lastCorrect=trialRecords(end).correct;
                lastWasCorrection=trialRecords(end).stimDetails.correctionTrial;
                if length(lastResponse)>1
                    lastResponse=lastResponse(1);
                end
            else
                lastResponse=[];
                lastCorrect=[];
                lastWasCorrection=0;
            end

            switch trialManagerClass
                case 'freeDrinks'

                    targetPorts=setdiff(responsePorts,lastResponse);
                    distractorPorts=[];

                case 'nAFC'


                    %note that this implementation will not show the exact same
                    %stimulus for a correction trial, but just have the same side
                    %correct.  may want to change...
                    if ~isempty(lastCorrect) && ~isempty(lastResponse) && ~lastCorrect && (lastWasCorrection || rand<details.pctCorrectionTrials)
                        details.correctionTrial=1;
                        details.maxCorrectForceSwitch=0;
                        'correction trial!'
                        targetPorts=trialRecords(end).targetPorts;
                    else
                        details.correctionTrial=0;

                        [targetPorts hadToResample]=getSameLimitedResponsePort(responsePorts,stimulus.maxCorrectOnSameSide,trialRecords);
                        details.maxCorrectForceSwitch=hadToResample;
                        %targetPorts=responsePorts(ceil(rand*length(responsePorts)));
                        %old random selection is now inside helper function -pmm
                    end


                    distractorPorts=setdiff(responsePorts,targetPorts);
                    targetPorts
                otherwise
                    error('unknown trial manager class')
            end


            %CORRECT RESPONSE
            if targetPorts==1
                responseIsLeft=1;
            elseif targetPorts==3
                responseIsLeft=-1; % on the right
            else
                targetPorts
                error('Targetports is inappropriate.  Stimulus is defined for 3 ports with one correct L/R answer')
            end
            details.correctResponseIsLeft=responseIsLeft;

            %CALC CUE PARAMS

            ctr=[height/2 width/2 ];

            %cueIsLeft=((rand>0.5)*2)-1;
            %cueLoc=ctr-[0 round(cueIsLeft*stimulus.eccentricity/2*stimulus.cuePercentTargetEcc*width)];
            %cueRect=[cueLoc(1)-stimulus.cueSize cueLoc(1)+stimulus.cueSize cueLoc(2)-stimulus.cueSize cueLoc(2)+stimulus.cueSize];
            %details.cueIsLeft=cueIsLeft;


            calibStim = 0; %The notion of calibration is only defined in later trialManager versions, hard coded here.
            if ~calibStim
                %set variables for random selections
                a=Randi(size(stimulus.goRightOrientations,2));
                b=Randi(size(stimulus.goLeftOrientations,2));
                c=Randi(size(stimulus.flankerOrientations,2));
                z=Randi(size(stimulus.distractorOrientations,2));
                d=Randi(size(stimulus.goRightContrast,2));      %
                e=Randi(size(stimulus.goLeftContrast,2));
                f=Randi(size(stimulus.flankerContrast,2));
                g=Randi(size(stimulus.distractorContrast,2));
                h=Randi(size(stimulus.flankerOffset,2));
                p=Randi(size(stimulus.phase,2));
                pD=Randi(size(stimulus.phase,2));
                pF=Randi(size(stimulus.phase,2));
                m=Randi(size(stimulus.stdGaussMask,2));
                x=Randi(size(stimulus.pixPerCycs,2));
            else %calibrationModeOn
                %use frame to set values a-h , p
                % [a b c d e f g h p] = selectStimulusParameters(trialManager);
                 [a b c z d e f g h p pD pF m x] = selectStimulusParameters(stimulus);
                error('this should never happen, because there is no calibration mode');
                for i=1:10
                    beep
                end
                %override side corrrect
                % responseIsLeft=-1; % on the right
                % details.correctResponseIsLeft=responseIsLeft;
            end

            if exist('controlledParams', 'var')
            %  temp = mat2cell(controlledParams, 1, length(controlledParams))
            % [a b c z d e f g h p pD pF m x] = deal(temp{:})

            a = controlledParams(1);
            b = controlledParams(2);
            c = controlledParams(3);
            z = controlledParams(4);
            d = controlledParams(5);
            e = controlledParams(6);
            f = controlledParams(7);
            g = controlledParams(8);
            h = controlledParams(9);
            p = controlledParams(10);
            pD = controlledParams(11);
            pF= controlledParams(12);
            m = controlledParams(13);
            x = controlledParams(14);

            end

            %CONTRAST AND ORIENTATION
            if responseIsLeft==1
                details.targetContrast=stimulus.goLeftContrast((e));
                details.targetOrientation=stimulus.goLeftOrientations((b));
            elseif responseIsLeft==-1
                details.targetContrast=stimulus.goRightContrast((d));
                details.targetOrientation=stimulus.goRightOrientations((a));
            else
                error('Invalid response side value. responseIsLeft must be -1 or 1.')
            end

            details.distractorContrast=stimulus.distractorContrast((g));
            details.flankerContrast=stimulus.flankerContrast((f));
            details.flankerOrientation= stimulus.flankerOrientations((c));
            details.distratorOrientation = details.targetOrientation;



            %FUTURE CHECKS FOR FLANKERS
            if stimulus.topYokedToBottomFlankerContrast
                %details.topFlankerOrient=details.flankerOriention
                %details.bottomFlankerOrient=details.flankerOriention;
            else
                %draw from distribution again
                error('currently undefined; topYokedToBottomFlankerContrast must be 1');
                c=Randi(size(stimulus.flankerOrientations,2)); %Can't use c because you have to resample in order to be unique.
                details.bottomFlankerOrient=stimulus.flankerOrientations((c));
            end

            if stimulus.topYokedToBottomFlankerOrientation
                %currently do nothing
            else
                error('currently undefined; topYokedToBottomFlankerOreintation must be 1');
            end

            %FUTURE CHECKS FOR FLANKERS


            if stimulus.flankerYokedToTargetPhase  
                details.flankerPhase = stimulus.phase(p);
                details.targetPhase = stimulus.phase(p);
            else
                details.targetPhase = stimulus.phase(p);
                details.flankerPhase = stimulus.phase(pF);
            end

            if stimulus.distractorYokedToTarget
                details.distractorPhase = details.targetPhase;
                details.distractorOrientation = details.targetOrientation;
            else
                details.distractorPhase = stimulus.phase(pD);
                details.distractorOrientation = stimulus.distractorOrientations(z);
            end

            if stimulus.distractorFlankerYokedToTargetFlanker
                details.distractorFlankerContrast = details.flankerContrast;
                details.distractorFlankerOrientation = details.flankerOrientation;
                details.distractorFlankerPhase = details.flankerPhase;
            else
                details.distractorFlankerContrast = details.flankerContrast;
                details.distractorFlankerOrientation = stimulus.flankerOrientations((c));
                details.distractorFlankerPhase = stimulus.phase(pF);
            end

            if stimulus.fractionNoFlanks>rand
                %set all flanker contrasts to be zero for a fraction of the trials
                details.flankerContrast=0;
                details.distractorFlankerContrast=0;
                details.hasFlanks=0;
            else
                if details.flankerContrast>0 || details.distractorFlankerContrast>0
                    details.hasFlanks=1;
                else
                    details.hasFlanks=0;
                end
            end


            %SPATIAL PARAMS
            %ecc=stimulus.eccentricity/2;

            xPosPct=stimulus.xPositionPercent; % original line

            %xPosPct=xPosPct+.2*randn*xPosPct; %edf added to tinker

            devY = stimulus.flankerOffset(h)*stimulus.stdGaussMask;

            details.deviation = devY;    %fractional devitation
            details.devPix=devY*getMaxHeight(stimulus); %pixel deviation
            details.patchX1=ceil(getMaxHeight(stimulus)*stimulus.stdGaussMask*stimulus.stdsPerPatch);
            details.patchX2=size(stimulus.goLeftStim,2);

            details.xPositionPercent=stimulus.xPositionPercent; %stored
            details.yPositionPercent=stimulus.targetYPosPct; %stored

            %TEMPORAL PARAMS
            details.requestedNumberStimframes=type;

            %GRATING PARAMS
            details.stdGaussMask=stimulus.stdGaussMask(m);
            details.stdGaussMaskPix=stimulus.stdGaussMask*ceil(getMaxHeight(stimulus));
            radius=details.stdGaussMask;
            details.pixPerCycs=stimulus.pixPerCycs(x);
            details.gratingType=stimulus.gratingType;
            %details.phase=rand*2*pi;  %all phases yoked together

            %OLD WAY ON THE FLY
            %     params=...
            %  ...%radius             pix/cyc               phase           orientation                     contrast                      thresh           xPosPct                 yPosPct
            %     [ radius    details.pixPerCycs    details.phase   details.targetOrientation       details.targetContrast        stimulus.thresh  1/2-cueIsLeft*ecc    stimulus.targetYPosPct;...
            %       radius    details.pixPerCycs    details.phase   details.distractorOrientation   details.distractorContrast    stimulus.thresh  1/2+cueIsLeft*ecc    stimulus.targetYPosPct;...
            %       radius    details.pixPerCycs    details.phase   details.leftFlankerOrient       details.flankerContrast       stimulus.thresh  1/2-ecc              stimulus.targetYPosPct+dev;...
            %       radius    details.pixPerCycs    details.phase   details.leftFlankerOrient       details.flankerContrast       stimulus.thresh  1/2-ecc              stimulus.targetYPosPct-dev;...
            %       radius    details.pixPerCycs    details.phase   details.rightFlankerOrient      details.flankerContrast       stimulus.thresh  1/2+ecc              stimulus.targetYPosPct+dev;...
            %       radius    details.pixPerCycs    details.phase   details.rightFlankerOrient      details.flankerContrast       stimulus.thresh  1/2+ecc              stimulus.targetYPosPct-dev ];

            % mainStim=computeGabors(params,'square',stimulus.mean,min(width,getMaxWidth(stimulus)),min(height,getMaxHeight(stimulus)));
            % preStim=computeGabors(params(1,:),'square',stimulus.mean,min(width,getMaxWidth(stimulus)),min(height,getMaxHeight(stimulus)));
            % VERY OLD EXAMPLE params = [repmat([stimulus.radius details.pixPerCyc],numGabors,1) details.phases details.orientations repmat([stimulus.contrast stimulus.thresh],numGabors,1) details.xPosPcts repmat([stimulus.yPosPct],numGabors,1)];

            szY=size(stimulus.mask,1);
            szX=size(stimulus.mask,2);
            fracSizeX=szX/width;
            fracSizeY=szY/height;
            display (' @@@@@@@@@@@@@@@@@@@@ starting the while loop for stim shifts @@@@@@@@@@@@@@@@@@@@');
            stimFit = 0;
            resampleCounter = 0;
            while stimFit == 0
                %%%%%%%%%% CREATE CENTERS %%%%%%%%%%%%%%
                if stimulus.displayTargetAndDistractor ==0
                    numPatchesInserted=3;
                    centers =...
                        ...%yPosPct                      yPosPct                    xPosPct                   xPosPct
                        [ stimulus.targetYPosPct       stimulus.targetYPosPct        xPosPct                   xPosPct;...                   %target
                        stimulus.targetYPosPct+devY   stimulus.targetYPosPct+devY    xPosPct                   xPosPct;...                   %top
                        stimulus.targetYPosPct-devY   stimulus.targetYPosPct-devY    xPosPct                   xPosPct];                     %bottom

                elseif stimulus.displayTargetAndDistractor== 1
                    numPatchesInserted=6;
                    centers =...
                        ...%yPosPct                         yPosPct                         xPosPct             xPosPct
                        [ stimulus.targetYPosPct        stimulus.targetYPosPct          xPosPct             xPosPct;...                   %target
                        stimulus.targetYPosPct+devY     stimulus.targetYPosPct+devY     xPosPct             xPosPct;...                   %top
                        stimulus.targetYPosPct-devY     stimulus.targetYPosPct-devY     xPosPct             xPosPct;...                   %bottom
                        stimulus.targetYPosPct          stimulus.targetYPosPct          xPosPct             xPosPct;...                   %distractor
                        stimulus.targetYPosPct+devY     stimulus.targetYPosPct+devY     xPosPct             xPosPct;...                   %top
                        stimulus.targetYPosPct-devY     stimulus.targetYPosPct-devY     xPosPct             xPosPct];                     %bottom
                else
                    error('must be 0 or 1');
                end
                %%%%%%%%% END OF CREATE CENTERS %%%%%%%%%%%%%%%%%

                %%%%%%%%% DETERMINE SCREEN POSITIONS IN PIXELS %%%%%%%%%%%%%%%%

                pos = round(centers.* repmat([ height, height, width, width],numPatchesInserted,1)...          %convert to pixel vals
                    -  repmat([ floor(szY/2), -(ceil(szY/2)-1 ), floor(szX/2) -(ceil(szX/2)-1)],numPatchesInserted,1)); %account for patch size

                xPixHint = round(stimulus.positionalHint * width)*sign(-responseIsLeft); % x shift value in pixels caused by hint
                detail.xPixShiftHint = xPixHint;
                if stimulus.displayTargetAndDistractor ==0
                    hintOffSet= repmat([0, 0, xPixHint, xPixHint], numPatchesInserted, 1);
                else
                    %first half move one direction, second half move the other
                    hintOffSet= [repmat([0, 0,  xPixHint,  xPixHint], numPatchesInserted/2, 1);...
                                 repmat([0, 0, -xPixHint, -xPixHint], numPatchesInserted/2, 1)];
                end
                pos = pos + hintOffSet;

                if any(any((pos(:,1:2)<1) | (pos(:,1:2)>height) | (pos(:,3:4)<1) | (pos(:,3:4)>width)))
                    width
                    height
                    xPixHint
                    szY
                    centers
                    pos
                    error('At least one image patch is going to be off the screen.  Make patches smaller or closer together or check the size of xPosHint.')
                end % check error without noise

                %%%%%%%%%%% ADD NOISE TERMS TO PIXEL POSITIONS %%%%%%%%%%%%%%%

                xPixShift = round(stimulus.xPosNoise * randn * width); % x shift value in pixels caused by noise
                yPixShift = round(stimulus.yPosNoise * randn * height); % y shift value in pixels caused by noise
                details.xPixShiftNoise = xPixShift;
                details.yPixShiftNoise = yPixShift;

                pos = pos + repmat([yPixShift, yPixShift, xPixShift, xPixShift], numPatchesInserted, 1);

                if any(any((pos(:,1:2)<1) | (pos(:,1:2)>height) | (pos(:,3:4)<1) | (pos(:,3:4)>width)))
                    resampleCounter = resampleCounter+1;
                    display(sprintf('stimulus off screen because of noise, number of resamples = %d', resampleCounter));
                    if resampleCounter > 10
                        error('too many resamples, reconsider the size of the noise');
                    end
                else
                    stimFit = 1;
                    details.stimRects = pos;
                end % check error with noise
            end









            try

                %stim class is inherited from flankstim patch
                %just check flankerStim, assume others are same
                if isinteger(stimulus.flankerStim)
                    details.mean=stimulus.mean*intmax(class(stimulus.flankerStim));
                elseif isfloat(stimulus.flankerStim)
                    details.mean=stimulus.mean; %keep as float
                else
                    error('stim patches must be floats or integers')
                end
                stim=details.mean(ones(height,width,3,'uint8')); %the unit8 just makes it faster, it does not influence the clas of stim, rather the class of details determines that



                insertMethod='maskTimesGrating';
                details.insertMethod=insertMethod;



                    %PRESTIM  - flankers first
                    if details.flankerContrast > 0
                        stim(:,:,1)=insertPatch(stimulus,insertMethod,stim(:,:,1),pos(2,:),stimulus.mask,stimulus.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.flankerOrientation, details.flankerPhase,  details.pixPerCycs,details.mean,details.flankerContrast);
                        stim(:,:,1)=insertPatch(stimulus,insertMethod,stim(:,:,1),pos(3,:),stimulus.mask,stimulus.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.flankerOrientation, details.flankerPhase,  details.pixPerCycs,details.mean,details.flankerContrast);

                        if stimulus.displayTargetAndDistractor == 1 % add distractor flankers on the opposite side y.z
                            stim(:,:,1)=insertPatch(stimulus,insertMethod,stim(:,:,1),pos(5,:),stimulus.mask,stimulus.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.distractorFlankerOrientation, details.distractorFlankerPhase,  details.pixPerCycs,details.mean,details.distractorFlankerContrast);
                            stim(:,:,1)=insertPatch(stimulus,insertMethod,stim(:,:,1),pos(6,:),stimulus.mask,stimulus.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.distractorFlankerOrientation, details.distractorFlankerPhase,  details.pixPerCycs,details.mean,details.distractorFlankerContrast);
                        end
                    end

                    %MAIN STIM this could be a for loop except variables are stored
                    %as named types...
                    if responseIsLeft==1       % choose TARGET stim patch from LEFT candidates
                        stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(1,:),stimulus.mask,stimulus.goLeftStim, stimulus.goLeftOrientations, stimulus.phase, details.targetOrientation, details.targetPhase,  details.pixPerCycs,details.mean,details.targetContrast);
                        if stimulus.displayTargetAndDistractor == 1 % add distractor stimulus to the opposite side of the target y.z
                            if stimulus.distractorYokedToTarget
                                stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(4,:),stimulus.mask,stimulus.goLeftStim, stimulus.goLeftOrientations, stimulus.phase, details.targetOrientation, details.targetPhase,  details.pixPerCycs,details.mean,details.distractorContrast);
                            else
                                stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(4,:),stimulus.mask,stimulus.distractorStim, stimulus.distractorOrientations, stimulus.phase, details.distractorOrientation, details.distractorPhase,  details.pixPerCycs,details.mean,details.distractorContrast);
                            end
                        end
                    elseif responseIsLeft==-1 %% choose TARGET stim patch from RIGHT candidates
                        stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(1,:),stimulus.mask,stimulus.goRightStim,stimulus.goRightOrientations,stimulus.phase, details.targetOrientation, details.targetPhase,  details.pixPerCycs,details.mean,details.targetContrast);
                        if stimulus.displayTargetAndDistractor == 1 % add distractor stimulus to the opposite side of the target y.z
                            if stimulus.distractorYokedToTarget
                                stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(4,:),stimulus.mask,stimulus.goRightStim, stimulus.goRightOrientations, stimulus.phase, details.targetOrientation, details.targetPhase,  details.pixPerCycs,details.mean,details.distractorContrast);
                            else
                                stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(4,:),stimulus.mask,stimulus.distractorStim, stimulus.distractorOrientations, stimulus.phase, details.distractorOrientation, details.distractorPhase,  details.pixPerCycs,details.mean,details.distractorContrast);
                            end
                        end
                    else
                        error('Invalid response side value. responseIsLeft must be -1 or 1.')
                    end

                    %and flankers
                    if details.flankerContrast > 0
                        stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(2,:),stimulus.mask,stimulus.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.flankerOrientation, details.flankerPhase,  details.pixPerCycs,details.mean,details.flankerContrast);
                        stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(3,:),stimulus.mask,stimulus.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.flankerOrientation, details.flankerPhase,  details.pixPerCycs,details.mean,details.flankerContrast);
                        if stimulus.displayTargetAndDistractor == 1
                            stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(5,:),stimulus.mask,stimulus.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.distractorFlankerOrientation, details.distractorFlankerPhase,  details.pixPerCycs,details.mean,details.distractorFlankerContrast);
                            stim(:,:,2)=insertPatch(stimulus,insertMethod,stim(:,:,2),pos(6,:),stimulus.mask,stimulus.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.distractorFlankerOrientation, details.distractorFlankerPhase, details.pixPerCycs,details.mean,details.distractorFlankerContrast);
                        end
                    end


                    %           %PRESTIM  - flankers first
                    %           stim(:,:,1)=insertPatch(stim(:,:,1),pos(2,:),stimulus.flankerStim,stimulus.flankerOrientations, details.flankerOrientation, details.mean, details.flankerContrast);
                    %           stim(:,:,1)=insertPatch(stim(:,:,1),pos(3,:),stimulus.flankerStim,stimulus.flankerOrientations, details.flankerOrientation, details.mean, details.flankerContrast);
                    %
                    %           %MAIN STIM this could be a for loop except variables are stored
                    %           %as named types...
                    %           if responseIsLeft==1       % choose TARGET stim patch from LEFT candidates
                    %               stim(:,:,2)=insertPatch(stim(:,:,2),pos(1,:),stimulus.goLeftStim, stimulus.goLeftOrientations, details.targetOrientation, details.mean, details.targetContrast);
                    %           elseif responseIsLeft==-1 %% choose TARGET stim patch from RIGHT candidates
                    %               stim(:,:,2)=insertPatch(stim(:,:,2),pos(1,:),stimulus.goRightStim,stimulus.goRightOrientations,details.targetOrientation, details.mean, details.targetContrast);
                    %           else
                    %               error('Invalid response side value. responseIsLeft must be -1 or 1.')
                    %           end
                    %           %and flankers
                    %           stim(:,:,2)=insertPatch(stim(:,:,2),pos(2,:),stimulus.flankerStim,stimulus.flankerOrientations,details.flankerOrientation,details.mean,details.flankerContrast);
                    %           stim(:,:,2)=insertPatch(stim(:,:,2),pos(3,:),stimulus.flankerStim,stimulus.flankerOrientations,details.flankerOrientation,details.mean,details.flankerContrast);
                    %
                    %
                    %       BEFORE THE FUNCTION CALL
                    %           %PRESTIM  - flankers first
                    %           i=2;
                    %           orientInd=find(stimulus.flankerOrientations==details.flankerOrientation);  % choose top(check?) stim patch
                    %           stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),1)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),1)+(stimulus.flankerStim(:,:,orientInd)-details.mean)*details.flankerContrast;
                    %
                    %           i=3;
                    %           orientInd=find(stimulus.flankerOrientations==details.flankerOrientation);  % choose bottom(check?) stim patch
                    %           stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),1)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),1)+(stimulus.flankerStim(:,:,orientInd)-details.mean)*details.flankerContrast;
                    %
                    %           %MAIN STIM this could be a for loop except variables are stored as named types...
                    %
                    %           i=1;   %the target
                    %           if responseIsLeft==1
                    %               orientInd=find(stimulus.goLeftOrientations==details.targetOrientation);  % choose TARGET stim patch from LEFT candidates
                    %               stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.goLeftStim(:,:,orientInd)-details.mean).*details.targetContrast;
                    %           elseif responseIsLeft==-1
                    %               orientInd=find(stimulus.goRightOrientations==details.targetOrientation);  % choose TARGET stim patch from RIGHT candidates
                    %               stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.goRightStim(:,:,orientInd)-details.mean).*details.targetContrast;
                    %           else
                    %               error('Invalid response side value. responseIsLeft must be -1 or 1.')
                    %           end
                    %
                    %           i=2;
                    %           orientInd=find(stimulus.flankerOrientations==details.flankerOrientation);  % choose top(check?) stim patch
                    %           stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.flankerStim(:,:,orientInd)-details.mean)*details.flankerContrast;
                    %
                    %           i=3;
                    %           orientInd=find(stimulus.flankerOrientations==details.flankerOrientation);  % choose bottom(check?) stim patch
                    %           stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.flankerStim(:,:,orientInd)-details.mean)*details.flankerContrast;



                    %OLD EXAMPLE FROM 6 gratings  -- things changed since then: details.mean instead of stimulus.mean
                    %       i=i+1;
                    %       orientInd=find(stimulus.goLeftOrientations==details.distractorOrientation);  % choose DISTRACTOR stim patch
                    %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.distractorStim(:,:,orientInd)-stimulus.mean).*details.distractorContrast;
                    %
                    %       i=i+1;
                    %       orientInd=find(stimulus.flankerOrientations==details.rightFlankerOrient);  % choose RIGHT stim patch
                    %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.flankerStim(:,:,orientInd)-stimulus.mean)*details.flankerContrast;
                    %       i=i+1;
                    %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.flankerStim(:,:,orientInd)-stimulus.mean)*details.flankerContrast;
                    %
                    %       i=i+1;
                    %       orientInd=find(stimulus.flankerOrientations==details.leftFlankerOrient);  % choose LEFT stim patch
                    %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.flankerStim(:,:,orientInd)-stimulus.mean)*details.flankerContrast;
                    %       i=i+1;
                    %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.flankerStim(:,:,orientInd)-stimulus.mean)*details.flankerContrast;
                    %

                    %RENDER CUE - side cue not used, only fixation dot
                    %stim(cueRect(1)-stimulus.cueSize:cueRect(2)+stimulus.cueSize,cueRect(3)-stimulus.cueSize:cueRect(4)+stimulus.cueSize,1:3)=1-stimulus.cueLum; %edf added to make cue bigger and more contrasty
                    %stim(cueRect(1):cueRect(2),cueRect(3):cueRect(4),1:3)=stimulus.cueLum;
                    %stim(height/2-stimulus.cueSize:height/2+stimulus.cueSize,width/2-stimulus.cueSize:width/2+stimulus.cueSize)=stimulus.cueLum*intmax(class(stim));

                    %BW pix in corners for imagesc
                    cornerMarkerOn=1;
                    if cornerMarkerOn
                        stim(1)=0; stim(2)=255;
                    end

                    details.persistFlankersDuringToggle=stimulus.persistFlankersDuringToggle;
                    if strcmp(type,'trigger') && details.toggleStim==1
                        %only send 2 frames if in toggle stim mode
                        out=stim(:,:,end-1:end);
                        if details.persistFlankersDuringToggle
                            out(:,:,end)=stim(:,:,1);  %alternate with a prestim that has flankers, so only target flashes
                        end
                    else
                        %send all frames if in normal mode
                        out=stim;
                    end

                    %grayscale sweep for viewing purposes
                    drawColorBar=0;  %**add as a parameter in stimManager object
                    if drawColorBar
                        L=256; spacer=6;
                        maxLumVal=double (intmax(class(stim)));  %have to do the uint8
                        stim(end-(spacer+2):end-(spacer),end-(L+spacer):end-(1+spacer),1)=uint8(gray(L)'*maxLumVal);
                        stim(end-(spacer+2):end-(spacer),end-(L+spacer):end-(1+spacer),2)=uint8(gray(L)'*maxLumVal);
                    end

                    %grayscale sweep where the target goes
                    calibrateTest=0;  %**add as a parameter in stimManager object
                    if calibrateTest  %(LUTBitDepth,colorSweepBitDepth,numFramesPerCalibStep-int8,useRawOrStimLUT,surroundContext-mean/black/stim,)

                        %create lut
                        LUTBitDepth=8;
                        numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
                        ramp=[0:fraction:1];
                        LUT=[ramp;ramp;ramp]';  %pass a rawLUT to stimOGL
                        LUT=getLUT(stimulus);   %use the LUT stimManager has

                        colorSweepBitDepth=4;
                        numColors=2^colorSweepBitDepth; maxRequestedColorID=numColors-1; fraction=1/(maxRequestedColorID);
                        ramp=[0:fraction:1];
                        % this is where you might consider: redColors=  [ramp;nada;nada]';
                        colorIDs=ramp*maxColorID;  %currently doubles but will be uints when put into calibStim
                        numColors=size(colorIDs,2);

                        %calibStim=reshape(repmat(stim(:,:,1),1,numColors),height,width,numColors); % in context
                        %calibStim=details.mean(ones(height,width,numColors,'uint8'));              % in mean screen
                        calibStim=zeros(height,width,numColors,'uint8');                            % in black screen
                        for i=1:numColors
                            calibStim(pos(1,1):pos(1,2),pos(1,3):pos(1,4),i)=colorIDs(i);
                        end

                        numFramesPerCalibStep=int8(4);
                        type='timedFrames'; %will be set to a vector: by virture of being a vector, not a string, will be treated as timedFrames type
                        frameTimes=numFramesPerCalibStep(ones(1,numColors));
                        type=frameTimes;

                        out=calibStim;
                    end


            catch ex
                sca
                ShowCursor;
                rethrow(ex);
            end
        end


        function stim=insertPatch(s,insertMethod,stim,pos,maskVideo,featureVideo,featureOptions1, featureOptions2,chosenFeature1, chosenFeature2 ,chosenFeature3,mean,contrast)

                    %   size (featureOptions1) 
                    %   size (featureOptions2)
                    %   size (chosenFeature1)
                    %   size (chosenFeature2)
                    %   display('$$$$$$$$$$$')
                    %   featureOptions1=featureOptions1
                    %   chosenFeature1=chosenFeature1
                    %   featureOptions2=featureOptions2
                    %   chosenFeature2=chosenFeature2
                    %   featureOptions1 == chosenFeature1
                    %   featureOptions2 == chosenFeature2
                    %   featureInd1 = find(featureOptions1 == chosenFeature1)
                    %   featureInd2 = find(featureOptions2 == chosenFeature2)
                    %         size(featureVideo)
            switch insertMethod


                case 'directPTB'
                    error('not yet defined')
                case 'matrixInsertion'
                    %insert in stim
                    featureInd1 = find(featureOptions1 == chosenFeature1);
                    featureInd2 = find(featureOptions2 == chosenFeature2);
                    if isfloat(stim)
                        stim(pos(1):pos(2),pos(3):pos(4)) = stim(pos(1):pos(2),pos(3):pos(4))+(featureVideo(:,:,featureInd1, featureInd2)-mean)*contrast;
                    elseif isinteger(stim)
                        %in order to avoide saturation of unsigned integers, feature patch
                        %is split into 2 channels: above and below mean
                        patch=( single(featureVideo(:,:,featureInd1, featureInd2))-single(mean) )*contrast;
                        above=zeros(size(patch),class(stim));
                        below=above;
                        above(sign(patch)==1)=(patch(sign(patch)==1));
                        below(sign(patch)==-1)=(-patch(sign(patch)==-1));
                        stim(pos(1):pos(2),pos(3):pos(4))=stim(pos(1):pos(2),pos(3):pos(4))+above-below;
                    end
                case 'maskTimesGrating'
                    %featureVideo is simply the mask at different sizes, must be a structure{}
                    %maskInd = find(maskInd == chosenMask);
                    maskInd = 1;
                    patchX=ceil(getMaxHeight(s)*s.stdGaussMask(maskInd)*s.stdsPerPatch);  %stdGaussMask control patch size which control the radius 
                    patchY=patchX;

                    %       %radius      pixPerCyc      phase          %orientation
                    params= [Inf      chosenFeature3  chosenFeature2   chosenFeature1     1    s.thresh  1/2     1/2   ];
                    grating=computeGabors(params,0.5,patchX,patchY,s.gratingType,'normalizeVertical',1);
                    grating=(grating-0.5);


                    %contrast=contrast*contrastScale(s.gratingType,orientation,pixPerCyc)
                    % %find a better way to get contrast and save it in stimDetails --
                    % %trialManager version does this in the inflate
                    % extraParams.contrastScale = ones(1,max([length(s.goRightOrientations) length(s.goLeftOrientations) length(s.flankerOrientations) length(s.distractorOrientations)])); %5th parameter is contrast

                    %for a temp short cut, hardcode a look-up table per orientation right here,
                    %as long as stimDetails has a record of it.... pmm
                    %keep in mind it should be per spatial frequency too!



                    WHITE=double(intmax(class(stim)));
                    patch=(WHITE*contrast)*(maskVideo.*grating);

                    above=zeros(size(patch),class(stim));
                    below=above;
                    above(sign(patch)==1)=(patch(sign(patch)==1));
                    below(sign(patch)==-1)=(-patch(sign(patch)==-1));
                    stim(pos(1):pos(2),pos(3):pos(4))=stim(pos(1):pos(2),pos(3):pos(4))+above-below;

                    %disp(['patch range ' num2str(min(patch(:))) ' to '
                    %num2str(max(patch(:)))])
                    %figure; imagesc(stim)     

                otherwise

                    error ('unknown calculation method for inserting stim patches')
            end



            %   function stim=insertPatch(stim,pos,featureVideo,featureOptions,chosenFeature,mean,contrast)
            %     featureInd=find(featureOptions==chosenFeature);
            %     if isfloat(stim)
            %           stim(pos(1):pos(2),pos(3):pos(4))=stim(pos(1):pos(2),pos(3):pos(4))+(featureVideo(:,:,featureInd)-mean)*contrast;
            %     elseif isinteger(stim)
            %         %in order to avoide saturation of unsigned integers, feature patch
            %         %is split into 2 channels: above and below mean
            %         patch=( single(featureVideo(:,:,featureInd))-single(mean) )*contrast;
            %         above=zeros(size(patch),class(stim));
            %         below=above;
            %         above(sign(patch)==1)=(patch(sign(patch)==1));
            %         below(sign(patch)==-1)=(-patch(sign(patch)==-1));
            %         stim(pos(1):pos(2),pos(3):pos(4))=stim(pos(1):pos(2),pos(3):pos(4))+above-below;
            %     end
            %   end;
        end
          
        function [stim frameTimes]=createDiscriminandumContextOnOffMovie(t,empty,targetOnly,contextOnly,targetAndContext,targetOnOff,contextOnOff)
            %this makes a 2-5 frame stimulus for the timedFrames type in stimOGL,
            %set the displayMethod=frameTimes to use the appropriate timed frames


            [height width]=size(empty);

            if 0 % this code was used until Nov 1st, becasue it is simpler for some timing

                %     if targetOnOff(2)==contextOnOff(2)
                %         %okay because they both turn off at the same time
                %     else
                %         sca
                %         keyboard
                %         error ('targetAndContext expected to turn off at the same time')
                %     end
                %
                %     if targetOnOff(1)<contextOnOff(1)
                %         error('target can''t come first')
                %     elseif targetOnOff(1)>contextOnOff(1)
                %         stim=reshape([empty contextOnly targetAndContext empty],height,width,4);
                %     elseif targetOnOff(1)==contextOnOff(1)
                %         stim=reshape([empty targetAndContext empty],height,width,3);
                %     end
                %
                %     changeTimes=unique([targetOnOff contextOnOff]);
                %     if any(changeTimes==0)
                %         stim=stim(:,:,2:end); %this makes the first scene start right away with no mean screen
                %         frameTimes=[diff(changeTimes)]; % hold last frame using a zero
                %     else
                %         firstWait=changeTimes(1);
                %         frameTimes=[firstWait diff(changeTimes)]
                %     end
                %
                %
                %     %reshape([empty flankersOnly targetAndFlankers targetOnly empty],height,width,5); %general: for everything

            else %old code revived and improved on Nov. 1st b/c it accomplishes the same effects more generally
                changeTimes=unique([targetOnOff contextOnOff]);

                if any(changeTimes==0)
                    frameTimes=diff(changeTimes);
                    %this makes the first scene start right away with no mean screen
                    stimInd=1;
                else  %there is a delay beforethe first stim
                    firstWait=changeTimes(1);
                    frameTimes=[firstWait diff(changeTimes)]
                    %this lets the first stim frame be a mean screen
                    stimInd=2;
                end

                %make the meanscreen background movie
                stim=repmat(empty,[1 1 length(frameTimes)+1]);

                %    this commented out code is actually incorrect and very confusing  (the stim may end when the flanker should persist, but ends up shutting off the flanker)
                %     %the first frame with context or target or both
                %     if contextOnOff(1)<targetOnOff(1)
                %         %draw context first
                %         stim(:,:,stimInd)=contextOnly;
                %         if contextOnOff(2)<targetOnOff(1)
                %             %context is off before target is on
                %             stimInd=stimInd+1; %advance to leave a mean screen in between
                %         end
                %     elseif targetOnOff(1)<contextOnOff(1)
                %         %draw target first
                %         stim(:,:,stimInd)=targetOnly;
                %         if targetOnOff(2)<targetOnOff(1)
                %             %target is off before context is on
                %             stimInd=stimInd+1; %advance to leave a mean screen in between
                %         end
                %     elseif contextOnOff(1)==targetOnOff(1)
                %         stim(:,:,stimInd)=targetAndContext;
                %     end
                %
                %     %the second frame with context or target
                %     stimInd=stimInd+1;
                %     if contextOnOff(1)<targetOnOff(1)
                %         stim(:,:,stimInd)=targetOnly;
                %     elseif targetOnOff(1)<contextOnOff(1)
                %         stim(:,:,stimInd)=contextOnly;
                %     elseif contextOnOff(1)==targetOnOff(1)
                %         %determine which turns off first and draw the other
                %         if contextOnOff(2)<targetOnOff(2)
                %             stim(:,:,stimInd)=targetOnly;
                %         elseif targetOnOff(2)<contextOnOff(2)
                %             stim(:,:,stimInd)=contextOnly;
                %         elseif targetOnOff(2)==contextOnOff(2)
                %             %do nothing because they turn off together
                %         end
                %     end

                % calculate everything dirrectly... easier to understand
                for i=1:length(changeTimes)
                    time=changeTimes(i);  %the moment the change time happens

                    % on is inclusive but off is exclusive!
                    if time>=targetOnOff(1)  &&  time<targetOnOff(2)
                        targetIsOn=true;
                    else
                        targetIsOn=false;
                    end

                    if time>=contextOnOff(1)  &&  time<contextOnOff(2)
                        contextIsOn=true;
                    else
                        contextIsOn=false;
                    end

                    if targetIsOn && ~contextIsOn
                        stim(:,:,stimInd)=targetOnly;
                    elseif ~targetIsOn && contextIsOn
                        stim(:,:,stimInd)=contextOnly;

                    elseif   targetIsOn && contextIsOn
                        stim(:,:,stimInd)=targetAndContext;

                    elseif ~targetIsOn && ~contextIsOn
                        stim(:,:,stimInd)=empty;  % is already mean screen , but setting it again for clarity

                    else
                        error('impossible!')
                    end
                    stimInd=stimInd+1;

                end

                %and the last frame is already mean screen
            end


            %this adds a zero at the end which causes the last frame to be displayed indefinitely
            %also turns it into a int8 which it must be
            frameTimes=int8([frameTimes 0]);

            if length(frameTimes)~=size(stim,3)
                length(frameTimes)
                size(stim,3)
                error('must be the same length!')
            end

            debug=0;
            if debug
                sca
                for i=1:size(stim,3)
                    subplot(1,size(stim,3),i);
                    imagesc(stim(:,:,i),[0 255])
                    if i>1
                        title(changeTimes(i-1))
                    end
                    xlabel(frameTimes(i))
                    x=double(stim(:,:,i));
                    minmax(x(:)')
                    set(gca,'xTick',[],'yTick',[])
                end
                colormap(gray)
                subplot(1,size(stim,3),1);
                ylabel(sprintf('t:[%s]   c:[%s]',num2str(targetOnOff),num2str(contextOnOff)))
                keyboard

            end

        end

        function s=decache(s)
            %method to deflate stim patches and flush lut

            s=deflate(s);
            s=flushLUT(s);

        end

        function s=deflate(s)
            %method to deflate stim patches

            s.cache.mask =[];
            s.cache.goRightStim=[];
            s.cache.goLeftStim=[];
            s.cache.flankerStim=[];
            s.cache.distractorStim = [];
            s.cache.distractorFlankerStim= [];


            % choose to keep sweep values in record
            % if ~isempty(s.dynamicSweep) 
            %     if strcmp('manual', s.dynamicSweep.sweepMode{1})
            %         %don't do anything, 
            %     else
            %     dynamicSweep.sweptValues=[];
            %     end
            % end

            %choose to keep
            % s.cache.textures % just numbers, not always there
            % s.cache.typeSz % just numbers for debugging, not always there
        end
        
        function d=display(s)
 
            disp(struct(s))
            disp(struct(s.stimManager))

            d='see above';
            %d=['\t\stim: ' display(struct(s)) '\n\t\super: ' display(struct(s.stimManager))];
            %d=sprintf(d);
            %other people call this and expect a string...

        %     d=['orientedGabors (n target, m distractor gabors, randomized phase, equal spatial frequency, p>=n+m horiz positions)\n'...
        %         '\t\t\tpixPerCycs:\t[' num2str(s.pixPerCycs) ... 
        %         ']\n\t\t\ttarget orientations:\t[' num2str(s.targetOrientations) ...
        %         ']\n\t\t\tdistractor orientations:\t[' num2str(s.distractorOrientations) ...
        %         ']\n\t\t\tmean:\t' num2str(s.mean) ...
        %         '\n\t\t\tradius:\t' num2str(s.radius) ...
        %         '\n\t\t\tcontrast:\t' num2str(s.contrast) ...
        %         '\n\t\t\tthresh:\t' num2str(s.thresh) ...
        %         '\n\t\t\tpct from top:\t' num2str(s.yPosPct)];
        %     d=sprintf(d);
        end
        
        function displayCumulativePhysAnalysis(sm,cumulativeData,parameters)
            % called by analysis manager when overwrite spikes is false, and analsis
            % has generates a cumulative data for this range.  allows for display,
            % without recomputation
            %%

            c=cumulativeData;
            if isempty(c) || all(c.numSpikesAnalyzed==0) 
                disp('NO SPIKES --> SO SKIPPING CUM PHYS ANALYSIS FOR FLANKERS')
                return
            end

            if ~isfield(parameters,'plotsRequested') || isempty(parameters.plotsRequested)
                plotsRequested=c.plotsRequested;
            end
            %plotsRequested={'raster','viewSort'};



            plotsRequested={'viewSort','meanPhotoTargetSpike';'viewDrops','rasterDensity'};

            plotsRequested={'viewSort','viewDrops','rasterDensity';
                'plotEyes','photodiodeAlignment','raster';
                'meanPhotoTargetSpike','PSTH','ratePerCondition'};
            plotsRequested={'PSTH_context','PSTH','ratePerConditionOff';'raster','rasterDensity','photodiodeAlignment'};
            plotsRequested={'ratePerConditionOn','ratePerConditionOff';'raster','rasterDensity'};
            plotsRequested={'viewSort'};
            plotsRequested={'loglogISI','logISI'};
            plotsRequested={'ratePerConditionOn','ratePerConditionOff';'raster','rasterDensity'};

            if 0 %
                %filter out some of them
                amp= calculateFeatures(c.spikeWaveforms,{'peakToValley'});
                which=amp<.4
                c.spikeWaveforms=c.spikeWaveforms(which,:) % remove the filtered..
                if length(c.spike.times)~=size(c.spikeWaveforms,1)
                    error('need to track waveform identity, or better, only include the ones that are in c.spike')
                end
                f=fields(c.spike);
                for i=1:length(f)
                    c.spike.(f{i})=c.spike.(f{i})(which)
                end
            end
            %%

            [numConditions numCycles numInstances nthOccurence displayHeight]=getNumConditionsEtc(sm,c);




            [h w]=size(plotsRequested);
            figure(parameters.figHandle)
            set(gcf,'Name',sprintf('flankers trial [%d %d], %s',parameters.trialRange(1),parameters.trialRange(length(parameters.trialRange)),parameters.trodeName))
            set(gcf,'position',[10 40 1200 900])

            viewSort=any(ismember(plotsRequested(:),'viewSort'));
            if viewSort
                sub=find(strcmp(plotsRequested','viewSort'));
                subplot(h,w,sub)
                plot(c.spikeWaveforms([c.processedClusters]~=1,:)','color',[0.2 0.2 0.2]);  hold on
                plot(c.spikeWaveforms(find([c.processedClusters]==1),:)','r');
                waveLn=size(c.spikeWaveforms,2);
                set(gca,'xLim',[1 waveLn],'yTick',[])
                ylabel('volts'); xlabel('msec')
                centerGuess=24;
                waveLn*1000/c.samplingRate;
                preMs=centerGuess*1000/c.samplingRate;
                postMs=(waveLn-centerGuess)*1000/c.samplingRate;
                set(gca,'xTickLabel',[-preMs 0 postMs],'xTick',[1 centerGuess waveLn])
            end

            viewDrops=any(ismember(plotsRequested(:),'viewDrops'));
            if viewDrops
                sub=find(strcmp(plotsRequested','viewDrops'));
                subplot(h,w,sub)
                dropFraction=conv(c.droppedFrames,ones(1,100));
                plot(dropFraction)
                ylabel(sprintf('drops: %d',sum(c.droppedFrames)))
            end

            photodiodeAlignment=any(ismember(plotsRequested(:),'photodiodeAlignment'));
            if photodiodeAlignment
                sub=find(strcmp(plotsRequested','photodiodeAlignment'));
                subplot(h,w,sub)
                imagesc(c.photodiodeRaster);  colormap(gray);
            end


            meanPhotoTargetSpike=any(ismember(plotsRequested(:),'meanPhotoTargetSpike'));
            if meanPhotoTargetSpike
                sub=find(strcmp(plotsRequested','meanPhotoTargetSpike'));
                subplot(h,w,sub);hold on;

                meanLuminanceSignal=mean(c.photodiodeRaster);
                meanLuminanceSignal=meanLuminanceSignal-min(meanLuminanceSignal);
                meanLuminanceSignal=meanLuminanceSignal/max(meanLuminanceSignal);
                PSTH=mean(c.rasterDensity);
                PSTH=PSTH/max(PSTH);
                plot(meanLuminanceSignal,'r');
                plot(PSTH,'g');
                %plot(mean(tOn2),'.k');
                legend('photo','PSTH','Location','NorthWest') %'target',
                set(gca,'ytick',[0 1],'xtick',xlim,'xlim',[0 length(PSTH)]);
                xlabel('frame')
                title(sprintf('spikes: %d',sum(c.numSpikesAnalyzed)))
            end

            plotEyes=any(ismember(plotsRequested(:),'plotEyes'));
            if plotEyes
                sub=find(strcmp(plotsRequested','plotEyes'));
                subplot(h,w,sub);hold on;

                if ~isempty(c.eyeSig)
                    if length(unique(c.eyeSig(:,1)))>10 % if at least 10 x-positions
                        regionBoundsXY=[1 .5]; % these are CRX-PY bounds of unknown degrees
                        [within ellipses]=selectDenseEyeRegions(c.eyeSig,1,regionBoundsXY);
                    else
                        disp(sprintf('no good eyeData on trials [%s]',num2str(c.trialNumbers)))
                        text(0.5,0.5,'bad eye data')
                    end
                else
                    text(0.5,0.5,'no eye data');
                    set(gca,'xTick',[],'yTick',[])
                end
            end



            plotRasterDensity=any(ismember(plotsRequested(:),'rasterDensity'));
            if plotRasterDensity
                sub=find(strcmp(plotsRequested','rasterDensity'));
                subplot(h,w,sub); hold on;
                numRepeats=max(c.spike.repetition);
                imagesc(flipud(c.rasterDensity));  colormap(gray)
                yTickVal=(numRepeats/2)+[0:numConditions-1]*numRepeats;
                set(gca,'YTickLabel',fliplr(c.conditionNames),'YTick',yTickVal);
                ylabel([c.swept]);
                xlabel('time (msec)');

                dur=diff(c.targetOnOff);
                shiftAmount=c.targetOnOff(1)/2;
                xloc=[0  shiftAmount shiftAmount+dur c.targetOnOff(2)]+ 0.5;
                xvals=[ -shiftAmount 0 dur shiftAmount+dur]*c.ifi*1000;
                set(gca,'XTickLabel',xvals,'XTick',xloc);

                plot(xloc([2 2]),[0.5 size(c.rasterDensity,1)+0.5],'g')
                plot(xloc([3 3]),[0.5 size(c.rasterDensity,1)+0.5],'g')
                axis([xloc([1 4]) 0.5+[0 size(c.rasterDensity,1)]])

                set(gca,'TickLength',[0 0])
            end


            %%
            doRasterPlot=any(ismember(plotsRequested(:),'raster'));
            if doRasterPlot
                sub=find(strcmp(plotsRequested','raster'));
                subplot(h,w,sub); hold on;
                plotRaster(sm,c);
            end


            %OLD RASTER MAY HAVE USED A DIFFERENT HEIGHT?
            %CALCULATE DISPLAY HEIGHT
            %     for i=1:numConditions
            %         which=find(conditionPerCycle==i);
            %         %this is prob not needed, but it garauntees temporal order as a secondary sort
            %         [junk order]=sort(cycleOnset(which));
            %         which=which(order);
            %         nthOccurence(which)=1:length(which);  %nthOccurence of this condition in this list
            %     end
            %     instancesPerTrial=length(conditionPerCycle)/numConditions; % 24 in this test
            %     displayHeight=nthOccurence(spike.cycle)+(spike.condition-1)*instancesPerTrial;
            %     plotRaster=any(ismember(plotsRequested(:),'raster'));
            %     if plotRaster
            %         figure(parameters.trialNumber);
            %         sub=find(strcmp(plotsRequested','raster'));
            %         subplot(h,w,sub); hold on;
            %
            %         for i=1:numConditions
            %             which=spike.condition==i;
            %             plot(spike.relTimes(which),-displayHeight(which),'.','color',brighten(colors(i,:),-0.2))
            %         end
            %
            %         yTickVal=-fliplr((instancesPerTrial/2)+[0:numConditions-1]*instancesPerTrial);
            %         set(gca,'YTickLabel',fliplr(conditionNames),'YTick',yTickVal);
            %         ylabel([swept]);
            %
            %         xlabel('time (msec)');
            %         xvals=[ -timeToTarget 0  (double(s.targetOnOff)*ifi)-timeToTarget];
            %         set(gca,'XTickLabel',xvals*1000,'XTick',xvals);
            %
            %         n=length(cycleOnset);
            %         plot(xvals([2 2]),0.5+[-n 0],'k')
            %         plot(xvals([3 3]),0.5+[-n 0],'k')
            %
            %         axis([xvals([1 4]) 0.5+[-n 0]])
            %         set(gca,'TickLength',[0 0])
            %     end
            %%
            plotRatePerConditionOn=any(ismember(plotsRequested(:),'ratePerConditionOn'));
            if plotRatePerConditionOn
                sub=find(strcmp(plotsRequested','ratePerConditionOn'));
                subplot(h,w,sub); hold on;
                doRatePerCondition(c,'on') 
            end

            plotRatePerConditionOff=any(ismember(plotsRequested(:),'ratePerConditionOff'));
            if plotRatePerConditionOff
                sub=find(strcmp(plotsRequested','ratePerConditionOff'));
                subplot(h,w,sub); hold on;
                doRatePerCondition(c,'off') 
            end

            showPSTH=any(ismember(plotsRequested(:),'PSTH'));
            if showPSTH
                sub=find(strcmp(plotsRequested','PSTH'));
                subplot(h,w,sub); hold on;
                numTrials=length(unique(c.spike.trial));
                for i=1:numConditions
                    spTm=c.spike.relTimes(c.spike.condition==i);
                    countPerTrial=sum(c.spike.condition==i)/numTrials;
                    if countPerTrial>0
                        [fi,ti] = ksdensity(spTm,'width',.01);
                        plot(ti*1000,fi*countPerTrial/c.targetOnOff(2),'color',c.colors(i,:));
                        plot(spTm*1000,-i+0.5*(rand(1,length(spTm))-0.5),'.','color',brighten(c.colors(i,:),-0.9));
                        histc(spTm,[])
                    end
                end
                xlabel('time (msec)');
                timeToTarget=c.targetOnOff(1)*c.ifi/2;
                xvals=1000*[ -timeToTarget 0  (c.targetOnOff*c.ifi)-timeToTarget];
                set(gca,'xLim',xvals([1 4]))
                set(gca,'XTickLabel',xvals,'XTick',xvals);

                ylabel('rate');
                yl=ylim;
                set(gca,'yLim',[-(numConditions+1) yl(2)])
                set(gca,'yTickLabel',[0 yl(2)],'yTick',[0 yl(2)]);
            end

            showLoglogISI=any(ismember(plotsRequested(:),'loglogISI'));
            if showLoglogISI
                sub=find(strcmp(plotsRequested','loglogISI'));
                subplot(h,w,sub); hold on;
                isi=diff(c.spike.times);
                if any(isi<0)
                    error('assumed to be sorted')
                end
                isiB4=isi(1:end-1);
                isiAfter=isi(2:end);

                firstInBurst=isiAfter<0.008 & isiB4>.05;
                plot(log10(isiAfter),log10(isiB4),'k.'); hold on
                plot(log10(isiAfter(firstInBurst)),log10(isiB4(firstInBurst)),'r.')
                %loglog(isiAfter,isiB4,'k.')
                %loglog(isiAfter(firstInBurst),isiB4(firstInBurst),'r.')
                %i2si=c.spike.times(3:end)-c.spike.times(1:end-2);
                axis([-3 1 -3 1])
                vals=[1 10 100 1000 10000]
                set(gca,'xtick',[-3:1],'ytick',[-3:1],'ytickLabel',vals,'xtickLabel',vals)
                xlabel('isi after')
                ylabel('isi before')

            end

            showLogISI=any(ismember(plotsRequested(:),'logISI'));
            if showLogISI
                sub=find(strcmp(plotsRequested','logISI'));
                subplot(h,w,sub); hold on;
                isi=diff(c.spike.times)*1000;
                if any(isi<0)
                    error('assumed to be sorted')
                end
                edges=linspace(0,10,100);
                count=histc(isi,edges);
                bar(edges,count,'histc');

                set(gca,'xlim',[0 10])
                xlabel('isi')
                ylabel('count')

            end

            showPSTH_context=any(ismember(plotsRequested(:),'PSTH_context'));
            if showPSTH_context
                sub=find(strcmp(plotsRequested','PSTH_context'));
                subplot(h,w,sub); hold on;
                unqTrials=unique(c.spike.trial);
                numTrials=length(unqTrials);
                numRepeats=max(c.spike.repetition);
                minTrial=min(c.spike.trial);
                adjTrial=c.spike.trial-minTrial;
                cumulativeRep=adjTrial*numRepeats+c.spike.repetition;
                for i=1:numConditions
                    spTm=c.spike.relRepTimes(c.spike.condition==i);
                    countPerTrial=sum(c.spike.condition==i)/numTrials;
                    if countPerTrial>0
                        [fi,ti] = ksdensity(spTm,'width',.01);
                        time=1*20;
                        plot(ti,fi*countPerTrial/time,'color',c.colors(i,:));
                        plot(spTm,-cumulativeRep(c.spike.condition==i),'.','color',brighten(c.colors(i,:),-0.9));
                        %histc(spTm,[])
                    end
                end
                xlabel('time (sec)');
                %     timeToTarget=c.targetOnOff(1)*c.ifi/2;
                %     xvals=1000*[ -timeToTarget 0  (c.targetOnOff*c.ifi)-timeToTarget];
                %     set(gca,'xLim',xvals([1 4]))
                %     set(gca,'XTickLabel',xvals,'XTick',xvals);
                %
                ylabel('rate');
                yl=ylim;
                set(gca,'yLim',[-(max(cumulativeRep)+1) yl(2)])
                set(gca,'yTickLabel',[0 yl(2)],'yTick',[0 yl(2)],'xlim',[0 max(c.spike.relRepTimes)]);
            end



            cleanUpFigure
            drawnow
            %%
        end
            


        function doRatePerCondition(c,timeWindow)

            numConditions=length(c.conditionNames);
            numCycles=size(c.conditionPerCycle,1);
            numInstances=numCycles/numConditions; 

            dur=diff(c.targetOnOff)*c.ifi;
            numTrials=length(unique(c.spike.trial));
            numRepeats=max(c.spike.repetition);

            warning('add in repeat per trial')
            %which=(c.spike.relTimes<0 | c.spike.relTimes>dur); %perdiod before and after (contains off response)
            which=(c.spike.relTimes<0 ); % period before
            for r=1:numRepeats
                baseline(r)=sum(which & c.spike.repetition==r);
            end
            baselineRate=baseline./(c.targetOnOff(2)/2*c.ifi*numInstances*numTrials);
            meanBaseLine=mean(baselineRate);
            stdBaseLine=std(baselineRate)/sqrt(numRepeats);
            minmaxBaseLine=[min(baselineRate) max(baselineRate)];

            for i=1:numConditions
                switch timeWindow
                    case 'on'
                        which=(c.spike.condition==i & c.spike.relTimes>0 & c.spike.relTimes<dur);
                    case 'off'
                        which=(c.spike.condition==i & c.spike.relTimes>dur & c.spike.relTimes<dur*2);
                end
                count(i)=sum(which);
                for r=1:numRepeats
                    countPerRep(i,r)=sum(which & c.spike.repetition==r);
                end
            end
            meanRatePerCond=count/(dur*numInstances*numTrials);
            SEMRatePerCond=std(countPerRep/(dur*numInstances*numTrials/numRepeats),[],2)/sqrt(numRepeats);

            fill([0 0 numConditions([1 1])+1 ],minmaxBaseLine([2 1 1 2]),'m','FaceColor',[.9 .9 .9],'EdgeAlpha',0)
            fill([0 0 numConditions([1 1])+1 ],meanBaseLine+stdBaseLine*[1 -1 -1 1],'m','FaceColor',[.8 .8 .8],'EdgeAlpha',0)
            for i=1:numConditions
                errorbar(i,meanRatePerCond(i),SEMRatePerCond(i),'color',c.colors(i,:));
                plot(i,meanRatePerCond(i),'.','color',c.colors(i,:));
            end
            ylabel(sprintf('<rate>_{%s}',timeWindow));
            set(gca,'xLim',[0.5 numConditions+0.5]);
            yl=ylim;
            set(gca,'yLim',[0 yl(2)]);
            set(gca,'XTickLabel',c.conditionNames,'XTick',1:numConditions);
        end
            
        function [doFramePulse expertCache dynamicDetails textLabel i dontclear] = ...
    drawExpertFrame(stimulus,stim,i,phaseStartTime,window,textLabel,destRect,...
    filtMode,expertCache,ifi,scheduledFrameNum,dropFrames,dontclear)
            % remains untested
            % not used: phaseStartTime, destRect, filtMode, ifi
            % maybe should use: expertCache, scheduledFrameNum, dropFrames, dontclear
            %
            % old functioning: [dynDetails
            % textString]=doDynamicPTBFrame(t,phase,stimDetails,frame,timeSinceTrial,eyeRecords,RFestimate, w,textString)
            % new signature: [doFramePulse expertCache dynamicDetails textLabel i dontclear] = ...
            %drawExpertFrame(stimulus,stim,i,phaseStartTime,window,textLabel,destRect,filtMode,expertCache,ifi,scheduledFrameNum,dropFrames,dontclear)


            error('old code to be deleted')


            %properties of screen
            filterMode=1; %0 = Nearest neighbour filtering, 1 = Bilinear
            modulateColor=[];  % should be empty of interferes with global alpha
            textureShader=[];

            %setup
            typeInd = [];
            oInd = [];
            pInd = [];
            destinationRect=[];
            globalAlpha=[];  % will get overwritten per texture

            %init
            dynDetails=[];
            texNum=0;


            try
                %SETUP
                if i <5 %==1  OLD STIMOGL somehow it might start on 3 or 4, not one?
                    if isempty(strfind(stimulus.renderMode,'dynamic'))
                        stimulus.renderMode
                        error('cannot use pbt mode if trialManager is not set to the appropriate renderMode');
                        % current known conflict: inflate makes the wrong cache
                        % maybe  b/c inflation happens, then PTB reopens and recloses
                        % for resizing
                    end

                    if ~texsCorrespondToThisWindow(stimulus,window)
                    stimulus=inflate(stimulus); %very costly! should not happen!
                    disp(sprintf('UNEXPECTED REINFLATION! on frame %d',i))
                    if ~texsCorrespondToThisWindow(stimulus,window)
                        error('should be there now!')
                    end
                end
                end



                %[resident texidresident] = Screen('PreloadTextures', window)
                Screen('FillRect',window, stim.backgroundColor);


                phase='discriminandum';
                switch phase
                    case 'discriminandum'

                        %%% LOGIC
                        [targetIsOn flankerIsOn effectiveFrame cycleNum sweptID repetition]=isTargetFlankerOn(stimulus,i);
                        textLabel=sprintf('%2.2g stim#: %2.2g stimID: %2.2g rep: %2.2g', effectiveFrame,cycleNum,sweptID,repetition);

                        %update dynamic values if there
                        if ~isempty(stimulus.dynamicSweep)     
                            stim=setDynamicDetails(stimulus,stim,sweptID);
                        end

                        %set up target
                        if targetIsOn

                            %INDS FOR PATCH MODE -- type for many
                            texNum=texNum+1;
                            pInd(texNum)= find(stimulus.phase==stim.flankerPhase);
                            if stim.correctResponseIsLeft==1
                                typeInd(texNum)=2; %left
                                oInd(texNum)= find(stimulus.goLeftOrientations==stim.targetOrientation);
                            elseif stim.correctResponseIsLeft==-1
                                typeInd(texNum)=1; %right
                                oInd(texNum)= find(stimulus.goRightOrientations==stim.targetOrientation);
                            end
                            %PARAMS FOR GABOR RENDERING MODE - not all use
                            params(texNum,:)= [Inf  stimulus.pixPerCycs  stim.targetPhase stim.targetOrientation  1  stimulus.thresh  1/2   1/2 ];
                            %BASIC STUFF -- all use
                            globalAlpha(texNum) = stim.targetContrast;
                            destinationRect(texNum,:)=stim.PTBStimRects(1,:); %target is 1, top is 2, bottom is 3

                            if stimulus.displayTargetAndDistractor
                                texNum=texNum+1; %distractor
                                if stim.correctResponseIsLeft==1
                                    if stimulus.distractorYokedToTarget
                                        typeInd(texNum)=2; %left
                                        oInd(texNum)= find(stimulus.goLeftOrientations==stim.targetOrientation);
                                    else
                                        typeInd(texNum)=4; %distractor
                                        oInd(texNum)= find(stimulus.distractorOrientations==stim.distractorOrientation);
                                    end
                                elseif stim.correctResponseIsLeft==-1
                                    if stimulus.distractorYokedToTarget
                                        typeInd(texNum)=1; %right
                                        oInd(texNum)= find(stimulus.goRightOrientations==stim.targetOrientation);
                                    else
                                        typeInd(texNum)=4; %distractor
                                        oInd(texNum)= find(stimulus.distractorOrientations==stim.distractorOrientation);
                                    end
                                end
                                pInd(texNum)= find(stimulus.phase==stim.distractorPhase);
                                globalAlpha(texNum) = stim.distractorContrast;
                                destinationRect(texNum,:)=stim.PTBStimRects(4,:); %distractor is 4
                                params(texNum,:)= [Inf  stimulus.pixPerCycs  stim.distractorPhase distractorOrientation  1  stimulus.thresh  1/2   1/2 ];
                            end
                        end

                        %set up flanker
                        if flankerIsOn
                            %choose indices
                            if stimulus.topYokedToBottomFlankerOrientation & stimulus.topYokedToBottomFlankerContrast
                                texNum=texNum+1;
                                typeInd(texNum)=3; %flanker
                                oInd(texNum)= find(stimulus.flankerOrientations==stim.flankerOrientation);
                                pInd(texNum)= find(stimulus.phase==stim.flankerPhase);
                                globalAlpha(texNum) = stim.flankerContrast;
                                destinationRect(texNum,:)=stim.PTBStimRects(2,:); %top is 2, bottom is 3
                                params(texNum,:)= [Inf  stimulus.pixPerCycs  stim.flankerPhase stim.flankerOrientation  1  stimulus.thresh  1/2   1/2 ];

                                texNum=texNum+1;
                                typeInd(texNum)=3; %flanker
                                oInd(texNum)= oInd(texNum-1);
                                pInd(texNum)= pInd(texNum-1);
                                globalAlpha(texNum) =  globalAlpha(texNum-1);
                                destinationRect(texNum,:)=stim.PTBStimRects(3,:); %top is 2, bottom is 3
                                params(texNum,:)= [Inf  stimulus.pixPerCycs  stim.flankerPhase stim.flankerOrientation  1  stimulus.thresh  1/2   1/2 ];

                            else
                                error('topYokedToBottomFlankerContrast and topYokedToBottomFlankerOrientation must equal 1')
                            end
                            if stimulus.displayTargetAndDistractor
                                if stimulus.distractorFlankerYokedToTargetFlanker
                                    if stimulus.topYokedToBottomFlankerOrientation & stimulus.topYokedToBottomFlankerContrast
                                        texNum=texNum+1;
                                        typeInd(texNum)=3; %distractorFlanker(type 5) is drawn as a flanker(type 3)
                                        oInd(texNum)= find(stimulus.flankerOrientations==stim.flankerOrientation);
                                        pInd(texNum)= find(stimulus.phase==stim.flankerPhase);
                                        globalAlpha(texNum) = stim.distractorFlankerContrast;
                                        destinationRect(texNum,:)=stim.PTBStimRects(5,:); %top is 5, bottom is 6
                                        params(texNum,:)= [Inf  stimulus.pixPerCycs  stim.flankerPhase stim.flankerOrientation  1  stimulus.thresh  1/2   1/2 ];

                                        texNum=texNum+1;
                                        typeInd(texNum)=3; %distractorFlanker(type 5) is drawn as a flanker(type 3)
                                        oInd(texNum)= oInd(texNum-1);
                                        pInd(texNum)= pInd(texNum-1);
                                        globalAlpha(texNum) =  globalAlpha(texNum-1);
                                        destinationRect(texNum,:)=stim.PTBStimRects(6,:); %top is 5, bottom is 6
                                        params(texNum,:)= [Inf  stimulus.pixPerCycs  stim.flankerPhase stim.flankerOrientation  1  stimulus.thresh  1/2   1/2 ];
                                    else
                                        error('topYokedToBottomFlankerContrast and topYokedToBottomFlankerOrientation must equal 1')
                                    end
                                else
                                    error('distractorFlankerYokedToTargetFlanker must = 1');
                                end
                            end
                        end


                        if targetIsOn || flankerIsOn
                            version=stimulus.renderMode(strfind(stimulus.renderMode,'-')+1:end);
                            switch version
                                case 'precachedInsertion'
                                    %this first version of the code slavishly reproduces the method used in the
                                    %ratrixGeneral renderMode...in the future could be used to validate a
                                    %version where Gaussian Mask are stored seperate from grating and
                                    %orientations is handled by PTB and phase is handled by choice of
                                    %sourceRect

                                    %draw the patches
                                    N=size(oInd,2);
                                    %                         for n=1:N
                                    %                             disp(sprintf('frame=%d n=%d',i,n))
                                    %                             stimulus.cache.textures
                                    %                             thisTex=stimulus.cache.textures(typeInd(n),oInd(n),pInd(n))
                                    %                             screen('drawTexture',window,stimulus.cache.textures(typeInd(n),oInd(n),pInd(n)),[],destinationRect(n,:),[],filterMode,globalAlpha(n),modulateColor,textureShader)
                                    %                             %Screen('DrawTexture', windowPointer, texturePointer [,sourceRect] [,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [, modulateColor] [, textureShader]);
                                    %                         end


                                    texInds=sub2ind(size(stimulus.cache.textures),typeInd(1:N), oInd(1:N),pInd(1:N));
                                    %ALL AT ONCE IS OPTIMIZED
            %                         texInds=texInds
            %                         window=window
            %                         tex=stimulus.cache.textures(texInds)
            %                         srcRect=[]
            %                         dRect=destinationRect(1:N,:)'
            %                         rAngles=[]
            %                         filter=repmat(filterMode,1,N)
            %                         alpha=globalAlpha(1:N)
            %                         modColor=modulateColor
            %                         textShade=textureShader

                                    Screen('DrawTextures', window, stimulus.cache.textures(texInds) ,[] , destinationRect(1:N,:)', [], repmat(filterMode,1,N), globalAlpha(1:N), modulateColor, textureShader);
                                    %Screen('DrawTextures', windowPointer, texturePointer(s) [, sourceRect(s)] [, destinationRect(s)] [, rotationAngle(s)] [, filterMode(s)] [, globalAlpha(s)] [, modulateColor(s)] [, textureShader] [, specialFlags] [, auxParameters]);

            %                         mainIm=unique(Screen('GetImage', window))
            %                         oneTex=unique(Screen('GetImage', stimulus.cache.textures(1)))





                                case {'maskTimesGrating'}
                                    error('not tested yet')
                                    %this 2nd version of the code coped from  ratrixGeneral-maskTimesGrating
                                    % Gaussian Mask are stored seperate and gratings are recalculated

                                    maskInd = stimulus.stdGaussMask==details.stdGaussMask
                                    WHITE=double(intmax(class(stim)));
                                    %         above=zeros(size(patch),class(stim));
                                    %         below=above;
                                    %         above(sign(patch)==1)=(patch(sign(patch)==1));
                                    %         below(sign(patch)==-1)=(-patch(sign(patch)==-1));
                                    %         stim(pos(1):pos(2),pos(3):pos(4))=stim(pos(1):pos(2),pos(3):pos(4))+above-below;

                                    %draw the patches
                                    for n=1:size(params,1)
                                        contrast=1; %relying on global alpha
                                        grating=computeGabors(params(1,:),0.5,stim.patchX2,stim.patchX2,stimulus.gratingType,'normalizeVertical',0);
                                        patch=(WHITE*contrast)*(s.cache.maskVideo(maskInd).*(grating{n}-0.5));
                                        tex= screen('makeTexture',window,patch);
                                        screen('drawTexture',window,tex,[],destinationRect(n,:),[],filterMode,globalAlpha(n),modulateColor,textureShader)
                                        %Screen('DrawTexture', windowPointer, texturePointer [,sourceRect] [,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [, modulateColor] [, textureShader]);
                                    end
                                case {'onePatchPerPhase'}
                                    %this 3rd version of the code
                                    % one grating per phase is precomputed,
                                    % orientation handled by PTB's internal rotation

                                    rotAngles=rad2deg(params(:,4)');

                                    internalRotation=0; % a stim parameter? set in details by onePatchPerPhase?
                                    if internalRotation
                                        sflags = kPsychUseTextureMatrixForRotation;
                                        ind=1; % all phase tex the same size, so just use the first
                                        srcRect = CenterRect([0 0 stim.patchX2 stim.patchX2], Screen('Rect', stimulus.cache.textures(ind)));
                                        %                         srcRect = repmat(srcRect,length(pInd),1);
                                        %                         apparently only needs one of them
                                    else
                                        sflags = 0;
                                        srcRect = [];
                                    end

                                    for i=1:length(stimulus.phase)
                                        which=find(params(:,3)==stimulus.phase(i)); %which stims get drawn this phase
                                        if length(which)>0
                                            i=i
                                            window=window
                                            tex=stimulus.cache.textures(i)
                                            srcRect=srcRect'
                                            dRect=destinationRect(which,:)'
                                            rAngles=rotAngles(which)
                                            filter=repmat(filterMode,1,length(which))
                                            alpha=globalAlpha(which)
                                            modColor=modulateColor
                                            textShade=textureShader
                                            sflags=sflags
                                            Screen('DrawTextures', window, stimulus.cache.textures(i), srcRect', destinationRect(which,:)', rotAngles(which), repmat(filterMode,1,length(which)), globalAlpha(which),modulateColor,textureShader, sflags);
                                        end
                                    end

                                    %all at once

                                    %                     Screen('DrawTextures', window, stimulus.cache.textures([pInd]), srcRect', destinationRect', rotAngles, repmat(filterMode,1,length(pInd)), globalAlpha,modulateColor,textureShader, sflags);

                                case {'onePatch'}
                                    % phase handled by source selection
                                    error('never used')

                                otherwise
                                    error('bad version')
                            end
                        end
                    case 'penalty'
                        error('not coded yet');
                    case 'reward'
                        error('not coded yet');
                    case 'final'
                        error('not coded yet');
                    otherwise
                        error('not a known phase');
                end

                noise = 0;
                if noise
                    Screen('TransformTexture')
                    droppedRecord=zeros(frames,1); % my responsibility or the ratrix's?
                    drawTime=zeros(frames,1);
                end

                Screen('DrawingFinished', window);

            catch ex
                sca
                pInd
                oInd
                typeInd
                destinationRect
                globalAlpha

            %     ex.stack.line
            %     ex.stack.name
            %     ex.stack.file
                ShowCursor;

                rethrow(err);
            end
        end

        function inspectTexturesAndStop(stimulus,window,texInds)

            [oldmaximumvalue oldclampcolors] = Screen('ColorRange', window);
            x=Screen('GetImage', window);
            xd=Screen('GetImage', window,[],[],2);
            tx1=Screen('GetImage', stimulus.cache.textures(texInds(1)));
            tx2=Screen('GetImage', stimulus.cache.textures(texInds(2)));
            tx3=Screen('GetImage', stimulus.cache.textures(texInds(3)));

            tx1d=Screen('GetImage', stimulus.cache.textures(texInds(1)),[],[],2);
            tx2d=Screen('GetImage', stimulus.cache.textures(texInds(2)),[],[],2);

            [typeSz txs]=getTypeSizeOfTextures(stimulus, false);
            sca

            %stimulus.cache.typeSz
            figure; hist(double(xd(:)),255)
            fractionWhite=mean(xd(:)==1)
            screenRange=minmax(double(xd(:)'))
            tx1Range=minmax(double(tx1d(:)'))
            tx2Range=minmax(double(tx2d(:)'))
            if any(typeSz(:)~=stimulus.cache.typeSz(:))
                [type feature]=find(typeSz~=stimulus.cache.typeSz);
                badValues=typeSz(unique(type),feature);
                val=unique(txs{unique(type)})
                disp(sprintf('szX and szY have changed! : [%d   %d] its val is: %4.4f',badValues,val))
            else
                disp('sizes match... yay')
            end

            keyboard


            figure; imagesc(x)
            figure; imagesc(tx1)
            figure; hist(double(x(200:end,:)),255)
        end
            

        function [typeSz txs]=getTypeSizeOfTextures(stimulus, inspect)

            temp=cumprod(size(stimulus.cache.textures));
            stimulus.cache.textures
            numTexs=temp(end)
            for i=1:numTexs
                fprintf('getting tex: %d',stimulus.cache.textures(i));
                txs{i}=Screen('GetImage', stimulus.cache.textures(i),[],[],2);
                [type o p]=ind2sub(size(stimulus.cache.textures),i); %type,o,p
                typeSz(i,:)=[type o p size(txs{i}) stimulus.cache.textures(i)];
            end

            try
                plus=max(stimulus.cache.textures(:))+1;
                 xtraTex=Screen('GetImage',plus ,[],[],2)
                 xtraTypeSz=[nan nan nan size(xtraTex) plus]
            catch
                sca 
                keyboard
            end

            if inspect
                sca
                keyboard
                %%
                figure; colormap(gray)
                count=0
                for t=1:3
                    for o=1:2
                        which=find(typeSz(:,1)==t & typeSz(:,2)==o)
                        typeSz(which,:)
                        for i=1:length(which)
                            count=count+1;
                            subplot(6,length(which),count); imagesc( txs{which(i)}(:,:,1));
                            set(gca,'yTickLabel',t,'yTick',size(txs{which(i)},1)/2)
                            set(gca,'xTickLabel',typeSz(which(i),7),'xTick',size(txs{which(i)},1)/2)
                        end
                    end
                end
            end

        end
        
   
            
        function retval = enableCumulativePhysAnalysis(sm)
            % returns true if physAnalysis knows how to deal with, and wants each chunk
            % as it comes.  true for getting each chunk, false for getting the
            % combination of all chunks after analysisManagerByChunk has detected
            % spikes, sorted them, and rebundled them as spikes in their chunked format

            retval=true; %stim managers could sub class this method if they want to run on EVERY CHUNK, as opposed to the end of the trial

        end % end function

        function [out scale] = errorStim(stimManager,numFrames)
            scale=0;


            %it only flickers darker than the mean screen
            maxErrorLum=stimManager.mean/2;  
            maxErrorLum=max(maxErrorLum,4/255);  %so you see some flicker even on black backgrounds

            %add maxErrorLum to stimManager
            out = uint8(rand(1,1,numFrames)*maxErrorLum*double(intmax('uint8')));
        end
            

        function expertPostTrialCleanUp(s)
            %method to determine if it is cached

            %1. first try leaving it all open
            %this allows sm not to have to recache in expert mode
            %this should evantually run out of memory for opening too many stims


            %2. then try closing all the ones that stim does not track
            allWindows=Screen('Windows');
            texIDsThere=allWindows(find(Screen(allWindows,'WindowKind')==-1));

            nonStimManagerTexs=setdiff(texIDsThere,s.cache.textures(:));
            screen('close',nonStimManagerTexs);
        end

        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            % extract details for flankers
            %
            % quick init test after load in a trialRecord.mat
            %   LUTparams.compiledLUT='nAFC';
            %   basicRecords.trialManagerClass=1;
            %   x=extractDetailFields(ifFeatureGoRightWithTwoFlank,basicRecords,trialRecords,LUTparams)

            newLUT=LUTparams.compiledLUT;


            acceptableTmIndices = find(ismember(LUTparams.compiledLUT,{'nAFC','cuedGoNoGo'}));
            if ~isempty(acceptableTmIndices) && ~all(ismember([basicRecords.trialManagerClass],acceptableTmIndices))
                warning('only works for nAFC trial managers or cuedGoNoGo')
                out=struct;
            else

                try
                    stimDetails=[trialRecords.stimDetails];
                    [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
            %         out.correctionTrial=ensureScalar({stimDetails.correctionTrial});  %why did erik change correctionTrial to isCorrection in stim details?
            %         out.pctCorrectionTrials=ensureScalar({stimDetails.pctCorrectionTrials});

                    [out.correctResponseIsLeft newLUT] = extractFieldAndEnsure(stimDetails,{'correctResponseIsLeft'},'scalar',newLUT);
                    [out.targetContrast newLUT] = extractFieldAndEnsure(stimDetails,{'targetContrast'},'scalar',newLUT);
                    [out.phantomContrast newLUT] = extractFieldAndEnsure(stimDetails,{'phantomContrast'},'scalar',newLUT);
                    [out.targetOrientation newLUT] = extractFieldAndEnsure(stimDetails,{'targetOrientation'},'scalar',newLUT);
                    [out.flankerContrast newLUT] = extractFieldAndEnsure(stimDetails,{'flankerContrast'},'scalar',newLUT);
            %         out.correctResponseIsLeft=getDetail(trialRecords,'correctResponseIsLeft');
            %         out.targetContrast=getDetail(trialRecords,'targetContrast');
            %         out.targetOrientation=getDetail(trialRecords,'targetOrientation');
            %         out.flankerContrast=getDetail(trialRecords,'flankerContrast');

                    [out.deviation newLUT] = extractFieldAndEnsure(stimDetails,{'deviation'},'scalar',newLUT);
                    [out.targetPhase newLUT] = extractFieldAndEnsure(stimDetails,{'targetPhase'},'scalar',newLUT);
                    [out.flankerPhase newLUT] = extractFieldAndEnsure(stimDetails,{'flankerPhase'},'scalar',newLUT);
                    [out.currentShapedValue newLUT] = extractFieldAndEnsure(stimDetails,{'currentShapedValue'},'scalar',newLUT);
                    [out.pixPerCycs newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCycs'},'scalar',newLUT);
                    [out.stdGaussMask newLUT] = extractFieldAndEnsure(stimDetails,{'stdGaussMask'},'scalar',newLUT);
                    [out.xPosNoisePix newLUT] = extractFieldAndEnsure(stimDetails,{'xPosNoisePix'},'scalar',newLUT);
                    [out.yPosNoisePix newLUT] = extractFieldAndEnsure(stimDetails,{'yPosNoisePix'},'scalar',newLUT);

            %         out.deviation=getDetail(trialRecords,'deviation');
            %         out.targetPhase=getDetail(trialRecords,'targetPhase');
            %         out.flankerPhase=getDetail(trialRecords,'flankerPhase');
            %         out.currentShapedValue=getDetail(trialRecords,'currentShapedValue');
            %         out.pixPerCycs=getDetail(trialRecords,'pixPerCycs');
            %         out.stdGaussMask=getDetail(trialRecords,'stdGaussMask');
            %         out.xPosNoisePix=getDetail(trialRecords,'xPosNoisePix');
            %         out.yPosNoisePix=getDetail(trialRecords,'yPosNoisePix');

                    [out.blockID newLUT] = extractFieldAndEnsure(stimDetails,{'blockID'},'scalar',newLUT);
                    [out.trialThisBlock newLUT] = extractFieldAndEnsure(stimDetails,{'trialThisBlock'},'scalar',newLUT);
            %         out.blockID=getDetail(trialRecords,'blockID');


                    % take part of the vector
                    [out.flankerOrientation newLUT] = extractFieldAndEnsure(stimDetails,{'flankerOrientation'},{'NthValue',1},newLUT);
                    [out.flankerPosAngle newLUT] = extractFieldAndEnsure(stimDetails,{'flankerPosAngles'},{'NthValue',1},newLUT);
                    [out.flankerOff newLUT] = extractFieldAndEnsure(stimDetails,{'flankerOnOff'},{'NthValue',2},newLUT);
                    [out.redLUT newLUT] = extractFieldAndEnsure(stimDetails,{'LUT'},{'NthValue',256},newLUT);
            %         out.flankerOrientation=getDetail(trialRecords,'flankerOrientation',1);
            %         out.flankerPosAngle=getDetail(trialRecords,'flankerPosAngles',1);
            %         out.flankerOff=getDetail(trialRecords,'flankerOnOff',2);
            %         out.redLUT=getDetail(trialRecords,'LUT',256);

                    %if anything is defined
                    [out.fitRF newLUT] = extractFieldAndEnsure(stimDetails,{'fitRF'},'isDefinedAndNotEmpty',newLUT);
                    [out.blocking newLUT] = extractFieldAndEnsure(stimDetails,{'blocking'},'isDefinedAndNotEmpty',newLUT);
                    [out.dynamicSweep newLUT] = extractFieldAndEnsure(stimDetails,{'dynamicSweep'},'isDefinedAndNotEmpty',newLUT);
            %         out.fitRF=isDefined(trialRecords, 'fitRF');
            %         out.blocking=isDefined(trialRecords, 'blocking');
            %         out.dynamicSweep=isDefined(trialRecords, 'dynamicSweep');


                    [out.toggleStim newLUT] = extractFieldAndEnsure(stimDetails,{'toggleStim'},'scalar',newLUT);

                    % consider getting this into compiled records in the future...stimDetails.protocolType

                    % 4/8/09 - actualTargetOnOffMs and actualFlankerOnOffMs
                    % how to vectorize this? b/c we need to collect all the tries for a given trial
                    % only works in nAFC (because we can assume that 2nd phase is where stim presentation happens!)
                    % look in phaseRecords(2) for request times
                    % start of stim is assumed to be startTime=0 at phase 2
                    out.actualTargetOnSecs=ones(1,length(trialRecords))*nan;
                    out.actualTargetOnsetTime=ones(1,length(trialRecords))*nan;
                    out.actualFlankerOnSecs=ones(1,length(trialRecords))*nan;
                    out.actualFlankerOnsetTime=ones(1,length(trialRecords))*nan;
                    for i=1:length(trialRecords)

                       if 0 && ~isnan(trialRecords(i).stimDetails.flankerOnOff) && isnan(trialRecords(i).stimDetails.targetOnOff) ...
                               && trialRecords(i).stimDetails.flankerOnOff(2)==21 && trialRecords(i).stimDetails.targetOnOff(2)==26
                           warning('breaking here to inspect 231''s data, and method to calculate actualFlankerOnsetTime')
                           keyboard
                       end
                        try
                            % if we are doing new-style records (both toggle and timed mode)
                            if isfield(trialRecords(i),'phaseRecords') && ~isempty(trialRecords(i).phaseRecords)
                                % toggle mode
                                if trialRecords(i).stimDetails.toggleStim
                                    if ~isempty(trialRecords(i).phaseRecords(1).responseDetails.tries)
                                        tries=trialRecords(i).phaseRecords(1).responseDetails.tries{end};
                                        tries=[tries trialRecords(i).phaseRecords(2).responseDetails.tries];
                                        times=[0 trialRecords(i).phaseRecords(2).responseDetails.times]; % start of phase is when we assume toggle started
                                        nominalIFI=trialRecords(i).phaseRecords(2).responseDetails.nominalIFI;
                                        dropIFI=0;
                                        if any(trialRecords(i).phaseRecords(2).responseDetails.misses==1)
                                            dropIFI=trialRecords(i).phaseRecords(2).responseDetails.missIFIs(1)-nominalIFI;
                                        end
                                        [out.actualTargetOnSecs(i) out.actualTargetOnsetTime(i) out.actualFlankerOnSecs(i) ...
                                            out.actualFlankerOnsetTime(i)] = ...
                                            getDurationsAndOnsetTimesFromToggleMode(cell2mat(tries'),times,nominalIFI,dropIFI);
                                    else
                                        % no request therefore no stim happened
                                        out.actualTargetOnSecs(i)=0;
                                        out.actualTargetOnsetTime(i)=nan;
                                        out.actualFlankerOnSecs(i)=0;
                                        out.actualFlankerOnsetTime(i)=nan;
                                    end
                                else % timed mode
                                    tm= trialRecords(i).trialManager.trialManager;
                                    if isfield(tm,'dropFrames')
                                        dropFrames=tm.dropFrames;
                                    else
                                        dropFrames=false;
                                    end
                                    targetOnOff=trialRecords(i).stimDetails.targetOnOff;
                                    flankerOnOff=trialRecords(i).stimDetails.flankerOnOff;
                                    misses=trialRecords(i).phaseRecords(2).responseDetails.misses;
                                    missIFIs=trialRecords(i).phaseRecords(2).responseDetails.missIFIs;
                                    nominalIFI=trialRecords(i).phaseRecords(2).responseDetails.nominalIFI;

                                    [out.actualTargetOnSecs(i) out.actualFlankerOnSecs(i)] = ...
                                        calculateIntervalDuration(targetOnOff,flankerOnOff,misses,missIFIs,nominalIFI,dropFrames);

                                    % now figure out onset time...
                                    targetOnsetDelay=[1 targetOnOff(1)];
                                    flankerOnsetDelay=[1 flankerOnOff(1)];
                                    [actualTargetOnsetDelay actualFlankerOnsetDelay] = ...
                                        calculateIntervalDuration(targetOnsetDelay,flankerOnsetDelay,misses,missIFIs,nominalIFI,dropFrames);
                                    % actual onset time is the delay + the lick time + nominalIFI
                                    % do we want the absolute time or the time relative to the lick?
                                    %                 lickTime=trialRecords(i).phaseRecords(1).responseDetails.times(end);
                                    %                 lickTime=lickTime{1}+trialRecords(i).phaseRecords(1).responseDetails.startTime;
                                    %                 out.actualTargetOnsetTime(i)=lickTime+actualTargetOnsetDelay+nominalIFI;
                                    %                 out.actualFlankerOnsetTime(i)=lickTime+actualFlankerOnsetDelay+nominalIFI;
                                    out.actualTargetOnsetTime(i)=actualTargetOnsetDelay+nominalIFI;
                                    out.actualFlankerOnsetTime(i)=actualFlankerOnsetDelay+nominalIFI;
                                end

                            else % old-style records (only toggle mode)
                                if trialRecords(i).stimDetails.toggleStim
                                    tries=trialRecords(i).responseDetails.tries;
                                    times=trialRecords(i).responseDetails.times;
                                    nominalIFI=trialRecords(i).responseDetails.nominalIFI;
                                    dropIFI=0;
                                    [out.actualTargetOnSecs(i) out.actualTargetOnsetTime(i) out.actualFlankerOnSecs(i) ...
                                        out.actualFlankerOnsetTime(i)] = ...
                                        getDurationsAndOnsetTimesFromToggleMode(cell2mat(tries'),times,nominalIFI,dropIFI);
                                end
                            end
                        catch ex
                            % if something goes wrong for this trial, just leave as nans
                            getReport(ex)
                            continue;
                        end
                    end           


                    %     if 0 % FROM old COMPILED
                    %         % 12/16/08 - first 3 entries might be common to many stims
                    %         % should correctionTrial be here in compiledDetails (whereas it was originally in compiledTrialRecords)
                    %         % or should extractBasicRecs be allowed to access stimDetails to get correctionTrial?
                    %                 fieldNames={...
                    %         'correctionTrial',{'stimDetails','correctionTrial'};...             odd one b/c its still in stim details now
                    %         'pctCorrectionTrials',{'stimDetails','pctCorrectionTrials'};...     odd one b/c its still in stim details now
                    %         'maxCorrectForceSwitch',{'stimDetails','maxCorrectForceSwitch'};... odd one b/c its still in stim details now
                    %         ...
                    %         'correctResponseIsLeft',{'stimDetails','correctResponseIsLeft'};...
                    %         'targetContrast',{'stimDetails','targetContrast'};...
                    %         'targetOrientation',{'stimDetails','targetOrientation'};...
                    %         'flankerContrast',{'stimDetails','flankerContrast'};...
                    %         'flankerOrientation',{''};...
                    %         'deviation',{'stimDetails','deviation'};...
                    %         ...'devPix',{'stimDetails','devPix'};... removed b/c 2D: xpix & yPix, pmm 080603
                    %         'targetPhase',{'stimDetails','targetPhase'};...
                    %         'flankerPhase',{'stimDetails','flankerPhase'};...
                    %         'currentShapedValue',{'stimDetails','currentShapedValue'};...
                    %         'pixPerCycs',{'stimDetails','pixPerCycs'};...
                    %         'redLUT',{'stimDetails','redLUT'};...
                    %         'stdGaussMask',{'stimDetails','stdGaussMask'};...
                    %         'flankerPosAngle',{'stimDetails','flankerPosAngle'};...
                    %         };
                    %
                    %         for m=1:size(fieldNames,1)
                    %             switch fieldNames{m,1}
                    %
                    %                 case 'flankerOrientation'
                    %                     compiledTrialRecords.flankerOrientation(ranges{i}(1,j):ranges{i}(2,j))=nan;
                    %                     %some old managers had more than one orientation
                    %                     for tr=1:length(newTrialRecs)
                    %                         if ismember('stimDetails',fields(newTrialRecs(tr))) && ismember('flankerOrientation',fields(newTrialRecs(tr).stimDetails)) && ~isempty(newTrialRecs(tr).stimDetails.flankerOrientation)% if the field exists
                    %                             compiledTrialRecords.flankerOrientation(ranges{i}(1,j)+tr-1)=newTrialRecs(tr).stimDetails.flankerOrientation(1);
                    %                         end
                    %                     end
                    %
                    %                 case 'flankerPosAngle'
                    %                     compiledTrialRecords.flankerPosAngle(ranges{i}(1,j):ranges{i}(2,j))=nan;
                    %                     %use the first flankerPosAngle
                    %                     for tr=1:length(newTrialRecs)
                    %                         if ismember('stimDetails',fields(newTrialRecs(tr))) && ismember('flankerPosAngles',fields(newTrialRecs(tr).stimDetails)) && ~isempty(newTrialRecs(tr).stimDetails.flankerPosAngles)% if the field exists
                    %                             compiledTrialRecords.flankerPosAngle(ranges{i}(1,j)+tr-1)=newTrialRecs(tr).stimDetails.flankerPosAngles(1);
                    %                         end
                    %                     end
                    %                 case 'redLUT'
                    %                     compiledTrialRecords.redLUT(ranges{i}(1,j):ranges{i}(2,j))=nan;
                    %                     %only a single val from the LUT
                    %                     for tr=1:length(newTrialRecs)
                    %                         if ismember('stimDetails',fields(newTrialRecs(tr))) && ismember('LUT',fields(newTrialRecs(tr).stimDetails)) && ~isempty(newTrialRecs(tr).stimDetails.LUT)% if the field exists
                    %                             try
                    %                                 compiledTrialRecords.redLUT(ranges{i}(1,j)+tr-1)=newTrialRecs(tr).stimDetails.LUT(end,1);
                    %                             catch
                    %                                 keyboard
                    %                             end
                    %
                    %                         end
                    %                     end
                    %                 case {'maxCorrectForceSwitch','actualRewardDuration', 'manualVersion','autoVersion','didStochasticResponse','containedForcedRewards', 'didHumanResponse',...
                    %                         'totalFrames', 'startTime', 'numMisses',...
                    %                         'correctResponseIsLeft', 'targetContrast','targetOrientation', 'flankerContrast',...
                    %                         'deviation','targetPhase','flankerPhase','currentShapedValue','pixPerCycs','stdGaussMask','xPosNoisePix'}
                    %
                    %                     for tr=1:length(newTrialRecs)
                    %                         compiledTrialRecords.(fieldNames{m,1})(ranges{i}(1,j)+tr-1)=isThereAndNotEmpty(newTrialRecs(tr),fieldNames{m,2});
                    %                     end
                    %
                    %                 otherwise
                    %
                    %                     error(sprintf('no converter for field: %s',fieldNames{m,1}))
                    %             end
                    %             fprintf('%s ',fieldNames{m,1})
                    %         end
                    %         fprintf('}\n');
                    %     end % if 0

                catch ex
                    out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                    verifyAllFieldsNCols(out,length(trialRecords));
                    return
                end
            end
            verifyAllFieldsNCols(out,length(trialRecords));
        end


        function [actualTargetOnSecs actualTargetOnsetTime actualFlankerOnSecs actualFlankerOnsetTime] = ...
                getDurationsAndOnsetTimesFromToggleMode(tries,times,nominalIFI,dropIFI)
            firstRequest=find(tries(:,2),1,'first');
            if isempty(firstRequest)
                firstRequest=1;
                firstResponse=1;
            else
                firstLeft=find(tries(firstRequest:end,1),1,'first');
                firstRight=find(tries(firstRequest:end,3),1,'first');
                if isempty(firstLeft)
                    firstLeft=Inf;
                end
                if isempty(firstRight)
                    firstRight=Inf;
                end
                firstResponse=min(firstRight,firstLeft);
                if isempty(firstResponse)
                    firstResponse=1;
                end
                firstResponse=firstResponse+firstRequest-1;
            end
            allTimes=cell2mat(times(firstRequest:firstResponse));

            allDiffs=diff(allTimes);


            actualTargetOnSecs=sum(allDiffs(1:2:end));
            actualTargetOnsetTime=allTimes(1)+nominalIFI+dropIFI; % 4/13/09 - we estimate the onset time as the lick time of the first request + nominalIFI + dropIFI(if we know it from phaseRecords)!
            actualFlankerOnSecs=actualTargetOnSecs; % how do we know if flankers are on or not?
            actualFlankerOnsetTime=allTimes(1)+nominalIFI+dropIFI;
        end



        function [actualTargetOnSecs actualFlankerOnSecs] = ...
            calculateIntervalDuration(targetOnOff,flankerOnOff,misses,missIFIs,nominalIFI,dropFrames)

            targetInds=misses>=targetOnOff(1)&misses<targetOnOff(2);
            flankerInds=misses>=flankerOnOff(1)&misses<flankerOnOff(2);
            if dropFrames % dropFrames==true (harder case)
                lastMissedFrameBeforeInterval=find(misses<targetOnOff(1),1,'last');
                lastMissedFrameOfInterval=find(misses<targetOnOff(2),1,'last');
                numFramesLost=round(missIFIs(lastMissedFrameBeforeInterval)/nominalIFI)-1 ...
                    -(double(targetOnOff(1))-misses(lastMissedFrameBeforeInterval)); % equiv to (est. # of dropped frames eating into interval) - (distance away from interval)
                numFramesGained=round(missIFIs(lastMissedFrameOfInterval)/nominalIFI)-1 ...
                    -(double(targetOnOff(2))-misses(lastMissedFrameOfInterval)); % equiv to (est. # of dropped frames extending interval) - (distance away from interval)

                if isempty(numFramesLost) || numFramesLost<0
                    numFramesLost=0;
                end
                if isempty(numFramesGained) || numFramesGained<0
                    numFramesGained=0;
                end
                estTargetFramesInInterval=double(targetOnOff(2)-targetOnOff(1))+numFramesGained-numFramesLost;

                lastMissedFrameBeforeInterval=find(misses<flankerOnOff(1),1,'last');
                lastMissedFrameOfInterval=find(misses<flankerOnOff(2),1,'last');
                numFramesLost=round(missIFIs(lastMissedFrameBeforeInterval)/nominalIFI)-1 ...
                    -(double(flankerOnOff(1))-misses(lastMissedFrameBeforeInterval)); % equiv to (est. # of dropped frames eating into interval) - (distance away from interval)
                numFramesGained=round(missIFIs(lastMissedFrameOfInterval)/nominalIFI)-1 ...
                    -(double(flankerOnOff(2))-misses(lastMissedFrameOfInterval)); % equiv to (est. # of dropped frames extending interval) - (distance away from interval)
                if isempty(numFramesLost) || numFramesLost<0
                    numFramesLost=0;
                end
                if isempty(numFramesGained) || numFramesGained<0
                    numFramesGained=0;
                end
                estFlankerFramesInInterval=double(flankerOnOff(2)-flankerOnOff(1))+numFramesGained-numFramesLost;

                allMissIFIs=sum(missIFIs(targetInds));
                % number of undropped frames depends on the estNum of frames in the interval and the number/duration of all dropped frames within the interval
                numUndroppedTarget=round((nominalIFI*estTargetFramesInInterval - allMissIFIs) / nominalIFI);
                numUndroppedFlanker=round((nominalIFI*estFlankerFramesInInterval - allMissIFIs) / nominalIFI);
            else % dropFrames==false (easy case)
                % number of undropped frames is just the total expected number minus the number of drops
                numUndroppedTarget=double(targetOnOff(2)-targetOnOff(1))-length(find(targetInds));
                numUndroppedFlanker=double(flankerOnOff(2)-flankerOnOff(1))-length(find(flankerInds));
            end
            actualTargetOnSecs=sum(missIFIs(targetInds)) + ...
                numUndroppedTarget*nominalIFI;
            actualFlankerOnSecs=sum(missIFIs(flankerInds)) + ...
                numUndroppedFlanker*nominalIFI;
        end
        
        function s=fillLUT(s,method,linearizedRange,plotOn)
            %function s=fillLUT(s,method,linearizedRange [,plotOn]);
            %stim=fillLUT(stim,'linearizedDefault');
            %note: this calculates and fits gamma with finminsearch each time
            %might want a fast way to load the default which is the same each time
            %edf wants to migrate this to a ststion method  - this code is redundant
            %for each stim -- ACK!


            if ~exist('plotOn','var')
                plotOn=0;
            end


            switch method

                case 'mostRecentLinearized'
                           method
                    error('that method for getting a LUT is not defined');

                     dateRange=[0 Inf];
                    [suc mac]=getMACaddress;
                    if ~suc
                        error('can''t get mac!')
                    end
                    conn=dbConn();
                    cal=getCalibrationData(conn,mac,dateRange);
                    closeConn(conn)

                    linearizedCLUT=cal.linearizedCLUT;  %this is the full clut, we want a range

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

                    if plotOn
                        figure;
                        v=cal.validationValues;
                        lin=linspace(min(v),max(v),length(v));
                        err=v-lin;
                        subplot(2,2,1); plot(v,'r.'); hold on; plot(lin,'k'); plot(cal.measuredValues,'b');
                        xlabel('RGB'); ylabel('Y=cd2');
                        subplot(2,2,2); plot(100* err./v); ylabel('%err'); title(sprintf('max err frac: %3.3f',max(abs(err./v))))
                        subplot(2,2,3); hist(err./v); xlabel('%err'); title(sprintf('mean err frac: %3.3f',mean(abs(err./v))))
                        subplot(2,2,4); hist(err); xlabel('raw err (cd2)'); title(sprintf('max err cd2: %3.3f',max(abs(err))))
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
                                uncorrected = temp.cal.linearizedCLUT;
                                useUncorrected=1; % its already corrected
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

                    % trying to adapt to a change, i think made by fan, so as to normalize ranges
                    gamutRange=[0 1];
                    linearizedCLUT=zeros(2^LUTBitDepth,3);
                    if plotOn
                        subplot([311]);
                    end
                    sensorRange=minmax(measured_R);
                    [linearizedCLUT(:,1) g.R]=fitGammaAndReturnLinearized(sent, measured_R, linearizedRange,sensorRange, gamutRange, 2^LUTBitDepth,plotOn);

                    if plotOn
                        subplot([312]);
                    end
                    %sensorRange=minmax(measured_G);  % while this is more appropriate, it is not back compatible  (all were yoked to R range)
                    [linearizedCLUT(:,2) g.G]=fitGammaAndReturnLinearized(sent, measured_G, linearizedRange,sensorRange, gamutRange, 2^LUTBitDepth,plotOn);

                    if plotOn
                        subplot([313]);
                    end
                    %sensorRange=minmax(measured_B);  % while this is more appropriate, it is not back compatible  (all were yoked to R range)
                    [linearizedCLUT(:,3) g.B]=fitGammaAndReturnLinearized(sent, measured_B, linearizedRange,sensorRange, gamutRange, 2^LUTBitDepth,plotOn);
                case 'useThisMonitorsUncorrectedGamma'

                    LUTBitDepth=8;
                    numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
                    ramp=[0:fraction:1];
                    grayColors= [ramp;ramp;ramp]';
                    %maybe ask for red / green / blue gun only
                    uncorrected=grayColors;
                    linearizedCLUT=uncorrected;

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
        end
        
        function combinations=generateFlankerFactorialCombo(sm,sweptParameters,mode,parameters)
            %this helper function is a wrapper for factorial combo and handles the
            %logic of the mapping between stimulus manager fields and
            %this function only uses the values in parameters and ignores 

            if exist('parameters','var')
                %use parameters to generate values
            else
                parameters=struct(sm);
                error('never used before');
                %make sure to compare and validate with respect to default parameters
            end

            % include all contrasts and orientations whether or not they're from goLeft
            % or goRight, this reasoning makes sense for all protocolTypes
            % 'goToRightDetection', 'goToLeftDetection','tiltDiscrim','goToSide'


            for i=1:length(sweptParameters)
                switch sweptParameters{i}
                    case 'targetContrast'
                        parameters.targetContrast=unique([parameters.goRightContrast parameters.goLeftContrast]);
                        %only includes zero contrast if exist in both sides
                        if ~(any(parameters.goRightContrast==0) & any(parameters.goLeftContrast==0))
                            parameters.targetContrast(parameters.targetContrast==0)=[];
                        end
                    case 'targetOrientations'
                        parameters.targetOrientations=unique([parameters.goRightOrientations parameters.goLeftOrientations]);
                    otherwise
                        %add nothing
                end
            end

            combinations= generateFactorialCombo(parameters, sweptParameters,[],mode);
        end
        
        function    [value]  = getCurrentShapedValue(t)
            if ~isempty(t.shapingValues)
                if ~isempty(t.shapingValues.currentValue)
                    value = t.shapingValues.currentValue ;
                else
                    value = 'empty'; % this enforces some value to get returned, resulting in overwriting the empty value during initialization by something in the miniDatabase
                end

            else
                value = [];
            end
        end

        function [default t]=getDefaultParameters(t, protocolType,protocolVersion,defaultSettings)
            if ~exist('protocolType','var') || isempty(protocolType)
                protocolType='goToRightDetection';
            end

            if ~exist('protocolVersion','var') || isempty(protocolVersion)
                protocolVersion='2_4'; % 2_3 had a left error
            end

            if ~exist('defaultSettings','var') || isempty(defaultSettings)
                defaultSettings='Oct.09,2007';
            end

            switch defaultSettings
                case 'Oct.09,2007'

                    default.sndManager=makeStandardSoundManager();


                    default.maxWidth                =1024;
                    default.maxHeight               =768;
                    default.scaleFactor             =[1 1];
                    default.interTrialLuminance     =0.5;

                    default.pixPerCycs =64;
                    default.gratingType='square';
                    numPhase = 4; default.phase= 2*pi * [0: numPhase-1]/numPhase;
                    default.mean = 0.2;
                    default.rewardNthCorrect=1*[20,80,100,150,250];
                    default.scalar = 1;
                    %         default.scalarStartsCached = 0; %removed pmm 2008/05/02
                    default.maxCorrectOnSameSide=int8(4);

                    default.typeOfLUT= 'useThisMonitorsUncorrectedGamma';
                    default.rangeOfMonitorLinearized=[0.0 0.5];

                    default.flankerOffset = 0;
                    default.flankerContrast = [0];

                    %%%%%%%%% ADDED DEFAULT VALUES FOR DISPLAYING DISTRACTORS WITH
                    %%%%%%%%% FLANKERS %%%%%%%%%%%%%%%%%%%%%%%%% Y.Z


                    default.distractorOrientation = [0];
                    default.distractorContrast = 0;
                    default.distractorFlankerOrientation = [0];
                    default.distractorFlankerContrast = 0;
                    default.distractorYokedToTarget=1;
                    default.distractorFlankerYokedToTargetFlanker = 1;
                    default.flankerYokedToTargetPhase =0;
                    default.fractionNoFlanks=0;

                    %%%%%%%%%%%%%%%%%%%%% END %%%%%%%%%%%%%%%%%%

                    default.topYokedToBottomFlankerOrientation =1;
                    default.topYokedToBottomFlankerContrast =1;

                    default.shapedParameter=[];
                    default.shapingMethod=[];
                    default.shapingValues=[];

                    default.framesMotionDelay = Inf;
                    default.numMotionStimFrames = 0;
                    default.framesPerMotionStim = 0;

                    default.cueLum=[];                %luminance of cue square
                    default.cueSize=0;               %roughly in pixel radii

                    default.xPositionPercent = 0.5;  %target position in percent ScreenWidth
                    default.cuePercentTargetEcc=0.6; %fraction of distance from center to target  % NOT USED IN cuedGoToFeatureWithTwoFlank


                    % these were never used due to toggleStim ==1 
                    % they were defined up to Jan 2, 2009: 
                    %      default.framesTargetOn=int8(50);
                    %      default.framesJustFlanker=int8(2);   
                    % but then replaced by functionality and not name
                    % at that point all rats still havd toggleStim ==1 , but humans used toggleStim ==0
                    %       default.framesTargetOn=int8([0 5]);  % aka stimulus.framesStimOn; bad name
                    %       default.framesJustFlanker=int8([0 5]);    
                    % in order to be replaced evantually by framesTargetOnOff & framesFlankerOnOff
                    % in code that was written on jan 12, 2009 on the trunk
                    % but only took over rack1 temp when merge happened
                    default.targetOnOff= int8([1 10]);
                    default.flankerOnOff=int8([1 10]);

                    default.thresh = 0.001;
                    default.yPositionPercent = 0.5;
                    default.toggleStim = 1;

                    default.displayTargetAndDistractor =0;
                    default.xPosNoise=0.0;%standard deviation of noise in fractional screen width
                    default.yPosNoise=0;%standard deviation of noise in fractional screen height
                    default.persistFlankersDuringToggle=1;

                    default.msFlushDuration         =1000;
                    %default.rewardSizeULorMS        =0;     %not used! but still defined in nAFC.  Eventually remove. pmm
                    default.msMinimumPokeDuration   =10;
                    default.msMinimumClearDuration  =10;
                    %default.msPenalty               =4000;
                    %default.msRewardSoundDuration   =0; %not used! but still defined in nAFC.  Eventually remove. pmm

                    default.requestRewardSizeULorMS             =0;
                    default.percentCorrectionTrials             =.5; % starts being used on 09-Oct-2008 (always .5 before that)
                    default.msResponseTimeLimit                 =0;
                    default.pokeToRequestStim                   =1;
                    default.maintainPokeToMaintainStim          =1;
                    default.msMaximumStimPresentationDuration   =0;
                    default.maximumNumberStimPresentations      =0;
                    default.doMask                              =1;

                    % constant parameters for reinforcement manager
                    default.fractionOpenTimeSoundIsOn=0.6;
                    default.fractionPenaltySoundIsOn=1;

                    % software additions that explicitely state previously undefined defaults
                    default.flankerPosAngle=0; %May.30,2008

                    %these are explicitely overwritten in setShapingPMM
                    default.msPenalty=1000; %May.30,2008
                    default.scheduler=minutesPerSession(90,3); %May.30,2008
                    default.graduation = repeatIndefinitely(); %May.30,2008

                    default.msPuff=0; %July.18,2008

                    %default set to nan, which is same as before Nov.12,2008
                    %can be overwritten to get relative values
                    default.fpaRelativeTargetOrientation=nan;
                    default.fpaRelativeFlankerOrientation=nan;
                    %default.svnRev={'svn://132.239.158.177/projects/ratrix/tags/v1.0.1'}; %1/8/09 - added to support trunk version of trainingStep
                    default.svnRev={'svn://132.239.158.177/projects/ratrix/trunk'}; %duc's runs on trunk dec.11,2009

                    default.svnCheckMode='session';
                    %default.svnRev{2}=1920; %not used yet

                    default.blocking=[];
                    default.blockingExperiments=[]; %if defined turns on blocking in expt steps...first used by some versions on Jun.09,2009
                    default.fitRF=[];
                    default.dynamicSweep=[];

                    default.renderMode='ratrixGeneral-maskTimesGrating';

                    %for trial manager
                    default.eyeTracker=[];
                    default.eyeController=[];
                    default.datanet=[];

                    default.frameDropCorner={'off'};
                    default.dropFrames=true;  % dropped frames were added in and took effect after feb 2,2009; before: april 11th, 2009
                    default.displayMethod='ptb';
                    default.requestPorts='center';
                    default.saveDetailedFramedrops=true;

                    %for reinforcment manager
                    default.requestMode='first';  % only first request lick is rewarded

                    default.allowFreeDrinkRepeatsAtSameLocation=false;

                    default.dynamicFlicker=[];    % never was dynamicFlicker by default; oct 14, 2009

                    default.delayManager=[];  %defaults made explicit Oct 19, 2009
                    default.responseWindowMs=[0 Inf];
                    default.showText='full';
                    default.tmClass='nAFC';

                case 'Apr.13,2009'
                    %get the above defaults and add on
                    [default t]=getDefaultParameters(t,'unused','none','Oct.09,2007');
                    default.toggleStim = false;


                case 'May.02,2009'
                    [default t]=getDefaultParameters(t,'unused','none','Apr.13,2009'); % includes all previous
                    default.targetOnOff= int8([1 21]);
                    default.flankerOnOff=int8([1 21]);
                case 'Dec.11,2009'
                    [default t]=getDefaultParameters(t,'unused','none','May.02,2009'); % includes relevant previous
                    default.saveDetailedFramedrops=false;
                    default.showText='light';
                otherwise
                    error ('unknown default settings date')

            end


            % save these
            default.protocolType=protocolType;
            default.protocolVersion=protocolVersion;
            default.protocolSettings = defaultSettings;

            %% set protocol type
            switch protocolVersion
                case 'none'
                    % do nothing... just for internal setting calls... don't use
                case '1_0'
                    switch protocolType

                        case 'goToSide'
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [0,pi/2];
                            default.goLeftOrientations =  [0,pi/2];
                            default.flankerOrientations = [0,pi/2]; %choose a random orientation from this list\

                            default.stdGaussMask = 1/8;
                            default.positionalHint=0.2;
                            default.displayTargetAndDistractor=1;

                        case 'goToRightDetection'
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [0,pi/2];
                            default.goLeftOrientations =  [0,pi/2];
                            default.flankerOrientations = [0,pi/2]; %choose a random orientation from this list

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                        case 'goToLeftDetection'

                            default.goRightContrast = [0];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [0,pi/2];
                            default.goLeftOrientations =  [0,pi/2];
                            default.flankerOrientations = [0,pi/2]; %choose a random orientation from this list

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                        case 'tiltDiscrim'

                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];
                            %default.distractorContrast = [0]; %do we need this?
                            %note: displayTargetAndDistractor =0; in default

                            default.goRightOrientations = [pi/6];
                            default.goLeftOrientations =  [-pi/6];
                            default.flankerOrientations = 0; %[pi/6,0,-pi/6]; %choose a random orientation from this list
                            %default.topYokedToBottomFlankerOrientation =1;  %note this is redundant with default params

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;


                        otherwise
                            error('unknown type of protocol requested')
                    end

                case '1_1'
                    switch protocolType
                        case 'goToRightDetection'  % has four orientations
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [-pi/4,0,pi/4,pi/2]; %-45,0,45,90=horiz
                            default.goLeftOrientations =  [-pi/4,0,pi/4,pi/2];
                            default.flankerOrientations = [0,pi/2]; %choose a random orientation from this list

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;
                        case 'goToLeftDetection'  % has four orientations
                            default.goRightContrast = [0];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [-pi/4,0,pi/4,pi/2]; %-45,0,45,90=horiz
                            default.goLeftOrientations =  [-pi/4,0,pi/4,pi/2];
                            default.flankerOrientations = [0,pi/2]; %choose a random orientation from this list

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;
                        case 'tiltDiscrim' % has +/- 45

                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];
                            %default.distractorContrast = [0]; %do we need this?
                            %note: displayTargetAndDistractor =0; in default

                            default.goRightOrientations = [pi/4];
                            default.goLeftOrientations =  [-pi/4];
                            default.flankerOrientations = 0; %[pi/6,0,-pi/6]; %choose a random orientation from this list
                            %default.topYokedToBottomFlankerOrientation =1;  %note this is redundant with default params

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end

                case '1_2'
                    switch protocolType

                        case 'tiltDiscrim' % has +/- 45

                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];
                            %default.distractorContrast = [0]; %do we need this?
                            %note: displayTargetAndDistractor =0; in default

                            default.goRightOrientations = [pi/4];
                            default.goLeftOrientations =  [-pi/4];
                            default.flankerOrientations = 0; %[pi/6,0,-pi/6]; %choose a random orientation from this list
                            %default.topYokedToBottomFlankerOrientation =1;  %note this is redundant with default params

                            default.stdGaussMask = 1/8;
                            default.positionalHint=0.2;
                            default.displayTargetAndDistractor=0;

                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end
                case '1_3'  %no more horizontal targets
                    switch protocolType

                        case 'goToSide'
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [0];
                            default.goLeftOrientations =  [0];
                            default.flankerOrientations = [0,pi/2]; %choose a random orientation from this list

                            default.stdGaussMask = 1/8;
                            default.positionalHint=0.2;
                            default.displayTargetAndDistractor=1;

                        case 'goToRightDetection'
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [0];
                            default.goLeftOrientations =  [0];
                            default.flankerOrientations = [0,pi/2]; %choose a random orientation from this list

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                        case 'goToLeftDetection'

                            default.goRightContrast = [0];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [0];
                            default.goLeftOrientations =  [0];
                            default.flankerOrientations = [0,pi/2]; %choose a random orientation from this list

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end
                case {'1_4','1_7'}  %no more horizontal targets or flankers
                    switch protocolType

                        case 'goToSide'
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [0];
                            default.goLeftOrientations =  [0];
                            default.flankerOrientations = [0]; %choose a random orientation from this list

                            default.stdGaussMask = 1/8;
                            default.positionalHint=0.2;
                            default.displayTargetAndDistractor=1;

                        case 'goToRightDetection'
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [0];
                            default.goLeftOrientations =  [0];
                            default.flankerOrientations = [0]; %choose a random orientation from this list

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                        case 'goToLeftDetection'

                            default.goRightContrast = [0];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [0];
                            default.goLeftOrientations =  [0];
                            default.flankerOrientations = [0]; %choose a random orientation from this list

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end
                case '1_5'  %h-v  used by adam and pam
                    switch protocolType

                        case 'tiltDiscrim' % like 1_2 w/ its hint but has +/- 90 Horiz-Vert

                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];
                            %default.distractorContrast = [0]; %do we need this?
                            %note: displayTargetAndDistractor =0; in default

                            default.goRightOrientations = [0];
                            default.goLeftOrientations =  [pi/2];
                            default.flankerOrientations = 0; %[pi/6,0,-pi/6]; %choose a random orientation from this list
                            %default.topYokedToBottomFlankerOrientation =1;  %note this is redundant with default params

                            default.stdGaussMask = 1/8; %Smaller so the positional hint is more evident
                            default.positionalHint=0.1; %
                            default.displayTargetAndDistractor=0;

                        otherwise
                            protocolVersion=protocolVersion
                            protocolType=protocolType
                            error('unknown type of protocol for this version')
                    end

                case '1_6' % similar to 1_1 but all four flanker orients
                    switch protocolType
                        case 'goToRightDetection'  % has four orientations
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [-pi/4,0,pi/4,pi/2]; %-45,0,45,90=horiz
                            default.goLeftOrientations =  [-pi/4,0,pi/4,pi/2];
                            default.flankerOrientations =  [-pi/4,0,pi/4,pi/2];

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;
                        case 'goToLeftDetection'  % has four orientations
                            default.goRightContrast = [0];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [-pi/4,0,pi/4,pi/2]; %-45,0,45,90=horiz
                            default.goLeftOrientations =  [-pi/4,0,pi/4,pi/2];
                            default.flankerOrientations =  [-pi/4,0,pi/4,pi/2];

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;


                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end

                case '1_8' % only 2 orients and they are -15, 15
                    %!!!!MISTAKE version, not germline, used for only 2 days, lacks flankerPosAngle
                    %no real problem--could be construed as an unnessesary shaping step that eases from
                    %vertical to tipped flankerPositions

                    switch protocolType
                        case 'goToRightDetection'
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            orients=[-pi/12,pi/12];%%-15, 15
                            default.goRightOrientations = orients;
                            default.goLeftOrientations =  orients;
                            default.flankerOrientations = orients;

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;
                            default.phase=[0 pi];
                        case 'goToLeftDetection'  % has four orientations
                            default.goRightContrast = [0];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            orients=[-pi/8,pi/8]; %%-15, 15
                            default.goRightOrientations = orients;
                            default.goLeftOrientations =  orients;
                            default.flankerOrientations = orients;

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                            default.phase=[0 pi];
                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end
                case {'1_9', '2_1', '2_2','2_3','2_3reduced'} % only 2 orients and they are -15, 15   fixed and first used on Jun.04,2008 sadly, not the same angle L vs R
                    switch protocolType
                        case 'goToRightDetection'
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            orients=[-pi/12,pi/12];%%-15, 15
                            default.goRightOrientations = orients;
                            default.goLeftOrientations =  orients;
                            default.flankerOrientations = orients;

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;
                            default.phase=[0 pi];
                            default.flankerPosAngle=orients;

                        case 'goToLeftDetection'  % has four orientations
                            default.goRightContrast = [0];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            orients=[-pi/8,pi/8]; %%-22.5, 22.5  % MISTAKE!! this is a different angle for left rats! should be 15deg= pi/12 instead is 22.5 deg..
                            %leaving it incorrect b/c thats what it is for these rats!
                            default.goRightOrientations = orients;
                            default.goLeftOrientations =  orients;
                            default.flankerOrientations = orients;

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                            default.phase=[0 pi];
                            default.flankerPosAngle=orients;

                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end
                case {'2_4','2_5validate'} %like 2_3 but with fixed orientations for left
                    switch protocolType
                        case 'goToRightDetection'
                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            orients=[-pi/12,pi/12];%%-15, 15
                            default.goRightOrientations = orients;
                            default.goLeftOrientations =  orients;
                            default.flankerOrientations = orients;

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;
                            default.phase=[0 pi];
                            default.flankerPosAngle=orients;

                        case 'goToLeftDetection'  
                            default.goRightContrast = [0];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            orients=[-pi/12,pi/12]; %fixed, now -15, 15
                            default.goRightOrientations = orients;
                            default.goLeftOrientations =  orients;
                            default.flankerOrientations = orients;

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;

                            default.phase=[0 pi];
                            default.flankerPosAngle=orients;
                        case 'goNoGo'
                            default.goRightContrast = [1];    %RULE FOR CODE RE-USE: 'goDetection' uses "right" for "go"
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            orients=[-pi/12,pi/12];%%-15, 15
                            default.goRightOrientations = orients;
                            default.goLeftOrientations =  orients;
                            default.flankerOrientations = orients;

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;
                            default.phase=[0 pi];
                            default.flankerPosAngle=orients;


                            %set a few things unique to go-no-go
                            percentile=0.99;
                            value=10000;
                            fixedDelayMs=1000;
                            default.delayManager=flatHazard(percentile, value, fixedDelayMs);

                            default.responseWindowMs=[500 1500];  % do these conflict with one another?
                            default.responseLockoutMs=500;  % this is ONLY used by goNoGo (not cuedGoNoGo) and has not been tested thoroughly
                            %not clear why there are two.  maybe fan made
                            %responseLockoutMs first and responseWindowMs is more
                            %general, and he never removed the specific one from
                            %goNoGo? -pmm 12/13/09


                            default.requestPorts='none';
                            default.tmClass='goNoGo';
                            % default.rewardNthCorrect=1*[20,80,100,150,250];  % really? 
                        case 'cuedGoNoGo'
                            default.goRightContrast = [1];    %RULE FOR CODE RE-USE: 'goDetection' uses "right" for "go"
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];

                            orients=[-pi/12,pi/12];%%-15, 15
                            default.goRightOrientations = orients;
                            default.goLeftOrientations =  orients;
                            default.flankerOrientations = orients;

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0;
                            default.displayTargetAndDistractor=0;
                            default.phase=[0 pi];
                            default.flankerPosAngle=orients;


                            %set a few things unique to go-no-go
                            percentile=0.99;
                            value=10000; %use to shorten pre-request wait
                            fixedDelayMs=200;
                            default.delayManager=flatHazard(percentile, value, fixedDelayMs);
                            %default.delayManager=constantDelay(500);  % note: this line willinvalidatethe one above it

                            default.responseWindowMs=[300 1000]; 
                            %this first number should always be greater than 250 (else stim might be wrong)

                            default.requestPorts='none';
                            default.tmClass='cuedGoNoGo'; 


                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end
                case {'2_6','2_6special'}  % blocking in experiments
                    orients=[-pi/12,pi/12];%%-15, 15

                    if strcmp(protocolVersion,'2_6special')
                        orients=[-pi/8,pi/8]; %%-15, 15 %special back-compatibility for some rats
                        if strcmp(protocolType,'goToRightDetection')
                            error('not allowed..only for the old left side mistake')
                        end
                    end
                    default.goRightOrientations = orients;
                    default.goLeftOrientations =  orients;
                    default.flankerOrientations = orients;

                    default.stdGaussMask = 1/5;
                    default.positionalHint=0;
                    default.displayTargetAndDistractor=0;
                    default.phase=[0 pi];
                    default.flankerPosAngle=orients;


                    default.blockingExperiments.blockingMethod='nTrials';
                    default.blockingExperiments.nTrials=150;
                    default.blockingExperiments.shuffleOrderEachBlock=true;
                    default.blockingExperiments.sweptParameters=nan; % will be defined by the experiment step
                    default.blockingExperiments.sweptValues=nan;  % will be defined by the experiment step

                    switch protocolType
                        case 'goToRightDetection'
                            default.goRightContrast = [1];
                            default.goLeftContrast =  [0];
                            default.flankerContrast = [0];
                        case 'goToLeftDetection'
                            default.goRightContrast = [0];
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];
                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end

                case '2_0'
                    switch protocolType
                        case 'tiltDiscrim' %like 1_0, but protocol has auto shaping smaller targets

                            default.goRightContrast = [1];    %choose a random contrast from this list each trial
                            default.goLeftContrast =  [1];
                            default.flankerContrast = [0];

                            default.goRightOrientations = [pi/6];
                            default.goLeftOrientations =  [-pi/6];
                            default.flankerOrientations = 0; %[pi/6,0,-pi/6]; %choose a random orientation from this list

                            default.stdGaussMask = 1/5;
                            default.positionalHint=0; %
                            default.displayTargetAndDistractor=0;

                        otherwise
                            protocolVersion=protocolVersion
                            error('unknown type of protocol for this version')
                    end



                otherwise
                    error ('unknown version')
            end
        end
        
        function out=getFeaturePatchStim(t,patchX,patchY,type,parameters)
            %creates matrix of images size patchY x patchX x (whatever is necessary)
            %used for inflating different object types

            switch type
                case 'variableOrientationAndPhase'  % specific instance of gratings
                    orients=parameters{1};
                    phases=parameters{2};
                    staticParams=parameters{3};
                    normalizeMethod=parameters{4};
                    contrastScale=parameters{5};

                    % check
                    if size(staticParams, 2)~=8
                        error ('wrong numbers of params will be passed to computeGabors')
                    end
                    if ~isempty(contrastScale)
                        error('was never implimented')
                        %index=find(orients(i)==t.calib.orientations);
                    else
                        contrast=1;
                    end

                    %setup
                    out=zeros(patchY,patchX,length(orients), length(phases));
                    gaborParams=staticParams;
                    %params= radius   pix/cyc  phase orientation contrast thresh xPosPct yPosPct
                    for i=1:length(orients)
                        gaborParams(4)=orients(i); %4th parameter is orientation
                        gaborParams(5)=contrast;   %5th parameter is contrast
                        for j = 1: length(phases)
                            gaborParams(3)=phases(j);            %3rd parameter is the phase
                            out(:,:,i,j)=computeGabors(gaborParams,t.mean,patchX,patchY,t.gratingType,normalizeMethod,0);
                        end
                    end
                otherwise
                    error(sprintf('%s is not a defined type of feature',type))
            end
        end
        
        function [ interTrialLuminance ] = getInterTrialLuminance( stimulus )
            %GETINTERTRIALLUMINACE get luminance from the stimulus

            interTrialLuminance=stimulus.mean;
        end
        
        function out=getLUT(s);
            out=s.LUT;
        end

        function [numConditions numCycles numInstances nthOccurence displayHeight]=getNumConditionsEtc(sm,c)

            numConditions=length(c.conditionNames);
            numCycles=size(c.conditionPerCycle,1);
            %numTrialTypes=numCycles/numConditions; % whatever the group actually was acording to ths sm
            numInstances=numCycles/numConditions; % these 2 terms are the same

            for i=1:numConditions
                which=find(c.conditionPerCycle==i);
                %this is prob not needed, but it garauntees temporal order as a secondary sort
                try
                    [junk order]=sort(c.cycleOnset(which)); ... requires
                        which=which(order);
                    nthOccurence(which)=1:length(which);  %nthOccurence of this condition in this list
                catch ex
                    warning('oops')
                    keyboard
                end
            end
            displayHeight=nthOccurence(c.spike.cycle)+(c.spike.condition-1)*numInstances;

        end

        function [patchX patchY]=getPatchSize(s)
            maxHeight=getMaxHeight(s);

            patchX=ceil(maxHeight*s.stdGaussMask*s.stdsPerPatch);  %stdGaussMask control patch size which control the radius
            patchY=patchX;

            if isnan(patchY) % this is what you get when inf*0
                patchY=maxHeight;
                patchX=getMaxWidth(s);
            end
        end
        
        function    [value]  = getPercentCorrectionTrials(t)
            value = t.percentCorrectionTrials ;

        end
        
        function out = getPhysAnalysisObject(sm,subject,tr,channels,dataPath,stim,c)
            if ~exist('c','var')||isempty(c)
                c = struct([]);
            end
            out = fkrAnalysis(subject,tr,channels,dataPath,stim,c);
        end

        function out=getStimPatch(s,patchType,showIm)
            %out=getStimPatch(s,patchType,showIm)
            %im=getStimPatch(s,'right',1) where patchType is: 'right','left' or 'flanker'
            %imagesc(reshape(patch(:,:,1,1),size(patch,1),size(patch,2)))

            switch patchType
                case 'right'
                    out=s.cache.goRightStim;
                case 'left'
                    out=s.cache.goLeftStim;
                case 'flanker'
                    out=s.cache.flankerStim;
                otherwise
                    error('patch type must be right, left or flanker ')
            end

            if ~exist('showIm','var')
                showIm=0;
            end

            if showIm
                imshow(out(:,:,1,1));
            end
        end
        
        function name = getType(sm,stim)
            swept = stim.stimulusDetails.sm.dynamicSweep.sweptParameters;
            maskSz=stim.stimulusDetails.stdGaussMask;

            if isinf(maskSz)
                name='ff';
            else
                name='';
            end

            if any(strcmp(swept,'targetOrientations'))...
                    && any(strcmp(swept,'flankerOrientations'))...
                    && any(strcmp(swept,'flankerPosAngle'))...
                    && any(strcmp(swept,'phase'))...
                    && size(swept,2)==4;
                        name = [name 'fColin'];
            elseif any(strcmp(swept,'targetOrientations'))...
                    && any(strcmp(swept,'phase'))...
                    && size(swept,2)==2;
                 name = [name 'fOri'];
            elseif any(strcmp(swept,'targetContrast'))...
                    && any(strcmp(swept,'phase'))...
                    && size(swept,2)==2;
                name = [name 'fc'];
            elseif any(strcmp(swept,'phase'))...
                    && size(swept,2)==1;
                name = [name 'fPhase'];
            else 
                name = [name 'undefinedFlanker'];
            end

        end
        
        function    [value]  = hasUpdatablePercentCorrectionTrial(sm)
            % overrides false of superclass, true for this stimManager

              value = true;
        end
        
        function s=inflate(s,parts)
            %method to inflate stim patches

            if ~exist('parts','var') || isempty(parts)
               parts={'all'}; % inflate all parts if not specified which
            end

            if strcmp(parts{1},'all')
                parts={'stim','dynamicSweepValues','LUT'};
            end

            for i=1:length(parts)
                switch parts{i}
                    case 'stim'
                        %determine patch size
                        [patchX patchY]=getPatchSize(s);

                        %set defaults
                        contrastScale=[];
                        normalizeMethod='normalizeVertical';
                        %DETERMINE RADIUS OF GABOR
                        if s.thresh==0.001 && strcmp(normalizeMethod,'normalizeVertical')
                            radius=1/s.stdsPerPatch;
                        else
                            radius=1/s.stdsPerPatch;
                            s.thresh=s.thresh
                            thresh=0.001;
                            params =[radius 16 0 pi 1 thresh 1/2 1/2 ];
                            grating=computeGabors(params,0.5,200,200,s.gratingType,'normalizeVertical',1);
                            imagesc(abs(grating-0.5)>0.001)
                            imagesc(grating)

                            %find std -- works if square grating
                            h=(2*abs(0.5-grating(100,:)));
                            plot(h)
                            oneSTDboundary=find(abs(h-exp(-1))<0.01);  %(two vals)
                            oneStdInPix=diff(oneSTDboundary)/2
                            sca
                            error('Uncommon threshold for gabor edge; radius 1/s.stdsPerPatch normally used with thresh 0.001')
                        end

                        % params= radius   pix/cyc      phase orientation ontrast thresh % xPosPct yPosPct
                        staticParams =[radius  s.pixPerCycs(1)  -99    -99        1    s.thresh  1/2     1/2   ];  %only used by some renderMethods
                        mask=computeGabors([radius 999 0 0 1 s.thresh 1/2 1/2],0,patchX,patchY,'none',normalizeMethod,0);  %range from 0 to 1
                        %mask=getFeaturePatchStim(patchX,patchY,'squareGrating-variableOrientationAndPhase',0,0,[radius 1000 0 0 1 s.thresh 1/2 1/2],0);


                        circMask=double(mask>0.01);
                        staticParams(1)=Inf;

                        flankerStim=1; % just a place holder, may get overwritten
                        s.cache.flankerStim= uint8(double(intmax('uint8'))*(flankerStim));
                        %performs the follwoing function:
                        % if isinteger(stimulus.cache.flankerStim)
                        %         details.mean=stimulus.mean*intmax(class(stimulus.cache.flankerStim));
                        % end
                        %AND would have been used by dynamic, except that now by-passes
                        %this class setting placeholder in calcStim  with:
                        %details.backgroundColor=stimulus.mean*intmax('uint8'); 

                        if ~isempty(strfind(s.renderMode,'precachedInsertion'))
                            stimTypes=3; %exclude mask
                            goRightStim=getFeaturePatchStim(s,patchX,patchY,'variableOrientationAndPhase',{s.goRightOrientations,s.phase,staticParams,normalizeMethod,contrastScale});
                            goLeftStim= getFeaturePatchStim(s,patchX,patchY,'variableOrientationAndPhase',{s.goLeftOrientations, s.phase,staticParams,normalizeMethod,contrastScale});
                            flankerStim=getFeaturePatchStim(s,patchX,patchY,'variableOrientationAndPhase',{s.flankerOrientations,s.phase,staticParams,normalizeMethod,contrastScale});

                            if s.displayTargetAndDistractor
                                %only bother rendering if you need to display the distractor and distractorFlanker are unique from target & flanker
                                if ~s.distractorYokedToTarget
                                    distractorStim=getFeaturePatchStim(s,patchX,patchY,'variableOrientationAndPhase',{s.distractorOrientations,s.phase,staticParams,normalizeMethod,contrastScale});
                                    stimTypes=stimTypes+1;
                                else
                                    distractorStim=[];
                                end
                                if ~s.distractorFlankerYokedToTargetFlanker
                                    distractorFlankerStim= getFeaturePatchStim(s,patchX,patchY,'variableOrientationAndPhase',{s.flankerOrientations, s.phase,staticParams,normalizeMethod,contrastScale});
                                    stimTypes=stimTypes+1;
                                else
                                    distractorFlankerStim=[];
                                end
                            else
                                distractorStim=[];
                                distractorFlankerStim=[];
                            end
                        end

                        switch s.renderMode
                            case {'ratrixGeneral-maskTimesGrating'}
                                s.cache.mask= mask;  %keep as double
                            case {'symbolicFlankerFromServerPNG'}
                                s.cache.mask= ones(size(mask));  %keep as double

                                integerType='uint8';
                                symbolicIm=imread('\\reinagel-lab.ad.ucsd.edu\rlab\Rodent-Data\pmeier\flankerSupport\symbolicRender\symbolicRender.png');
                                % rgb2gray(symbolicIm) % don't need to cuz it already is BW!
                                % symbolicIm=cast(symbolicIm,integerType); % don't need to cuz it already is uint8!
                                symbolicIm=imresize(symbolicIm,size(mask));  %the right size
                                symbolicIm=fliplr(symbolicIm);  % the first one is tipped CW!
                                s.mean=1; %white background



                                if all(s.phase==0)
                                    %the 4th dimention is phase which is often one kind for these stims.
                                    %in this case 3 dims is enough
                                    symbolicIm(:,:,2)=fliplr(symbolicIm);  % and in the second orientation as a L/R mirror image
                                    s.cache.goRightStim= symbolicIm;
                                    s.cache.goLeftStim = symbolicIm;
                                    s.cache.flankerStim= symbolicIm;
                                elseif length(s.phase)==2 && all(s.phase==[0 pi])
                                    %if there are 2 phases, they could refer to targetphase OR
                                    %flanker phase, but symbolic will only render varying flanker
                                    %phases in this version
                                    four=symbolicIm;
                                    four(:,:,1,1)=symbolicIm;  % hack: repreat same ori
                                    four(:,:,2,1)=symbolicIm;  % hack: repreat same ori
                                    four(:,:,1,2)=symbolicIm;  % hack: repreat same ori
                                    four(:,:,2,2)=symbolicIm;  % hack: repreat same ori
                                    s.cache.goRightStim= four;  % no phase differences
                                    s.cache.goLeftStim = four;  % no phase differences

                                    symbolicImPhaseRev=imread('\\reinagel-lab.ad.ucsd.edu\rlab\Rodent-Data\pmeier\flankerSupport\symbolicRender\symbolicRender4stripe.png');
                                    symbolicImPhaseRev=imresize(symbolicImPhaseRev,size(mask));  %the right size
                                    symbolicImPhaseRev=fliplr(symbolicImPhaseRev);  % follow convention of 3 stripe

                                    %symbolicImPhaseRev=symbolicIm(:,:,1);  % not true yet, but see if it works
                                    %symbolicIm(:,:,1,1)=symbolicIm;         % 3 stripe
                                    four(:,:,1,2)=symbolicImPhaseRev;  % 4 stripe, both same ori
                                    four(:,:,2,2)=symbolicImPhaseRev;  % 4 stripe, both same ori

                                    s.cache.flankerStim= four;
                                elseif length(s.phase)==3 && all(s.phase==[0 pi/2 pi])
                                    %if there are 3 phases, they could refer to targetphase OR
                                    %flanker phase, but symbolic will only render varying flanker
                                    %phases in this version
                                    four=symbolicIm;
                                    four(:,:,1,1)=symbolicIm;  % hack: repreat same ori
                                    four(:,:,2,1)=symbolicIm;  % hack: repreat same ori
                                    four(:,:,1,2)=symbolicIm;  % hack: repreat same ori
                                    four(:,:,2,2)=symbolicIm;  % hack: repreat same ori
                                    four(:,:,1,3)=symbolicIm;  % hack: repreat same ori
                                    four(:,:,2,3)=symbolicIm;  % hack: repreat same ori
                                    s.cache.goRightStim= four;  % no phase differences
                                    s.cache.goLeftStim = four;  % no phase differences


                                    symbolicImPhaseRev=imread('\\reinagel-lab.ad.ucsd.edu\rlab\Rodent-Data\pmeier\flankerSupport\symbolicRender\symbolicRender4stripe.png');
                                    symbolicImPhaseRev=imresize(symbolicImPhaseRev,size(mask));  %the right size
                                    symbolicImPhaseRev=fliplr(symbolicImPhaseRev);  % follow convention of 3 stripe                    

                                    symbolicImHalfPi=imread('\\reinagel-lab.ad.ucsd.edu\rlab\Rodent-Data\pmeier\flankerSupport\symbolicRender\symbolicRenderHalfPi.png');
                                    symbolicImHalfPi=imresize(symbolicImHalfPi,size(mask));  %the right size
                                    symbolicImHalfPi=fliplr(symbolicImHalfPi);  % follow convention of 3 stripe

                                    %symbolicImPhaseRev=symbolicIm(:,:,1);  % not true yet, but see if it works
                                    %symbolicIm(:,:,1,1)=symbolicIm;         % 3 stripe
                                    four(:,:,1,2)=symbolicImHalfPi;    % 4 stripe asym, both same ori
                                    four(:,:,2,2)=symbolicImHalfPi;    % 4 stripe asym, both same ori
                                    four(:,:,1,3)=symbolicImPhaseRev;  % 4 stripe, both same ori
                                    four(:,:,2,3)=symbolicImPhaseRev;  % 4 stripe, both same ori

                                    s.cache.flankerStim= four;
                                else
                                    p=s.phase
                                    error('that kind of phase compbo is not allowed in symbolic mode')
                                end



                            case  'ratrixGeneral-precachedInsertion'

                                %%store these as int8 for more space... (consider int16 if better CLUT exists)
                                %%calcStim preserves class type of stim, and stim OGL accepts without rescaling
                                integerType='uint8';
                                s.cache.mask = cast(double(intmax(integerType))*(mask),integerType);

                                s.cache.goRightStim= cast(double(intmax(integerType))*(goRightStim), integerType);
                                s.cache.goLeftStim = cast(double(intmax(integerType))*(goLeftStim),integerType);
                                s.cache.flankerStim= cast(double(intmax(integerType))*(flankerStim),integerType);
                                s.cache.distractorStim = cast(double(intmax(integerType))*(distractorStim),integerType);
                                s.cache.distractorFlankerStim= cast(double(intmax(integerType))*(distractorFlankerStim),integerType);

                            case 'dynamic-maskTimesGrating'
                                %save the Mask and a single,oversized, unphased grating for each orientation
                                s.cache.orientValues=unique([s.goRightOrientations s.goLeftOrientations s.flankerOrientations s.distractorOrientations s.distractorFlankerOrientations]);
                                orientations=getFeaturePatchStim(s,2*patchX,2*patchY,'variableOrientationAndPhase',{s.cache.orientValues,[0],staticParams,normalizeMethod,contrastScale});
                                sz=size(orientations);
                                s.cache.orientations= reshape(orientations,sz([1 2 4])); %keep as float
                                keyboard
                            case 'dynamic-onePatchPerPhase'
                                gratings=getFeaturePatchStim(s,2*patchX,2*patchY,'variableOrientationAndPhase',{0,s.phase,staticParams,normalizeMethod,contrastScale});
                                sz=size(gratings);
                                s.cache.gratings= reshape(gratings,sz([1 2 4])); %keep as float
                                disp('pre-caching textures into PTB');
                                w=getWindow() %local helper function
                                for i=1:length(s.phase)
                                    s.cache.textures(i)=Screen('MakeTexture', w, s.cache.gratings(:,:,i), [], [], 2);
                                end
                                Screen('BlendFunction', w,GL_SRC_ALPHA, GL_ONE); % blend source then add it
                            case 'dynamic-precachedInsertion'
                                %pre-catch textures
                                try
                                    orientsPerType=[size(goRightStim,3) size(goLeftStim,3) size(flankerStim,3) size(distractorStim,3) size(distractorFlankerStim,3)] ;
                                    phasesPerType =[size(goRightStim,4) size(goLeftStim,4) size(flankerStim,4) size(distractorStim,4) size(distractorFlankerStim,4)] ;
                                    numOrients=max(orientsPerType(1:stimTypes));
                                    numPhases=max(phasesPerType(1:stimTypes));
                                    textures=nan(stimTypes,numOrients,numPhases);

                                    integerType='uint8';
                                    %s.cache.mask = cast(double(intmax(integerType))*(mask),integerType);
                                    s.cache.mask = cast(double(intmax(integerType))*(mask),'double');  % used for size checking in cleanup of texs

                                    %draws fine but overlaps
                                    %             cache{1}.features=cast(double(intmax(integerType))*(goRightStim), integerType);
                                    %             cache{2}.features=cast(double(intmax(integerType))*(goLeftStim), integerType);
                                    %             cache{3}.features=cast(double(intmax(integerType))*(flankerStim), integerType);
                                    %             cache{4}.features=cast(double(intmax(integerType))*(distractorStim), integerType);
                                    %             cache{5}.features=cast(double(intmax(integerType))*(distractorFlankerStim), integerType);

                                    %cache as double, range -1 to 1
                                    %             cache{1}.features=(goRightStim-s.mean)*2;
                                    %             cache{2}.features=(goLeftStim-s.mean)*2;
                                    %             cache{3}.features=(flankerStim-s.mean)*2;
                                    %             cache{4}.features=(distractorStim-s.mrean)*2;
                                    %             cache{5}.features=(distractorFlankerStim-s.mean)*2;

                                    %CIRC MASK
                                     %cache as double, range -.5 to .5
                                                cache{1}.features=repmat(circMask,[1 1 size(goRightStim,3) size(goRightStim,4)]).*(goRightStim-s.mean);
                                                cache{2}.features=repmat(circMask,[1 1 size(goLeftStim,3) size(goLeftStim,4)]).*(goLeftStim-s.mean);
                                                cache{3}.features=repmat(circMask,[1 1 size(flankerStim,3) size(flankerStim,4)]).*(flankerStim-s.mean);
                                                cache{4}.features=distractorStim-s.mean;  %not circ mask here, cuz not needed... its empty -pmm hack
                                                cache{5}.features=distractorFlankerStim-s.mean;

            %                         %cache as double, range -.5 to .5
            %                         cache{1}.features=(goRightStim-s.mean);
            %                         cache{2}.features=(goLeftStim-s.mean);
            %                         cache{3}.features=(flankerStim-s.mean);
            %                         cache{4}.features=distractorStim-s.mean;  %not circ mask here, cuz not needed... its empty -pmm hack
            %                         cache{5}.features=distractorFlankerStim-s.mean;


                                    %             %gratings range from [-0.5  1.5]...wierd
                                    %             %1*cos(linspace(0, pi,6))+0.5
                                    %
                                    %             %cache as double, range [-0.5  1.5]
                                    %             cache{1}.features=s.mean+(goRightStim-s.mean)*2;
                                    %             cache{2}.features=s.mean+(goLeftStim-s.mean)*2;
                                    %             cache{3}.features=s.mean+(flankerStim-s.mean)*2;
                                    %             cache{4}.features=s.mean+(distractorStim-s.mean)*2;
                                    %             cache{5}.features=s.mean+(distractorFlankerStim-s.mean)*2;

                                    disp('pre-caching textures into PTB');
                                    w=getWindow() %local helper function
                                    Screen('BlendFunction', w,GL_SRC_ALPHA, GL_ONE); % blend source then add it
                                    %interTrialTex= screen('makeTexture',w,0.5,[],[],2); % try to prevent conflicts... this shouldn't be necc. trak ticket/286 DOES NOT HELP
                                    for type=1:stimTypes
                                        for o=1:orientsPerType(type)
                                            for p=1:phasesPerType(type)
                                                %add an alpha channel - i don't think this is necc.
                                                %fourChannelIM=repmat(cache{type}.features(:,:,o,p), [1, 1, 4]);
                                                %fourChannelIM(:,:,4)=s.cache.mask;
                                                %textures(type,o,p)= screen('makeTexture',w,fourChannelIM);

                                                % Screen('BlendFunction',  textures(type,o,p),GL_SRC_ALPHA, GL_ONE); % blend source then add it; mario only does it once before the loop in garboriumDemo
                                                %textures(type,o,p)= screen('makeTexture',w,cache{type}.features(:,:,o,p)); %default has no control over precision%
                                                %textures(type,o,p)= screen('makeTexture',w,cache{type}.features(:,:,o,p),[],[],1); % NO ALPHA , FAN USES precision=1 for gratings, 0.5 centered doubles, [-.5 1.5]
                                                textures(type,o,p)= screen('makeTexture',w,cache{type}.features(:,:,o,p),[],[],2); % NO ALPHA , Mario uses precision= 2 for garboriumDemo, 0 centered doubles, +/-0.27

                                                %[oldmaximumvalue oldclampcolors] = Screen('ColorRange', w);   %this is [1 255], could that be limiting? fan's also has [1 255] inside of gratings expertFrame, so prob not
                                            end
                                        end
                                    end

                                    temp=cumprod(size(textures));
                                    numTexs=temp(end)
                                    for i=1:numTexs
                                        txs{i}=Screen('GetImage', textures(i),[],[],2);
                                        [type o p]=ind2sub(size(textures),i); %type,o,p
                                        typeSz(i,:)=[type o p size(txs{i}) textures(i)];
                                    end

                                    s.cache.typeSz=typeSz;

                                    %[resident [texidresident]] = Screen('PreloadTextures', windowPtr [, texids]); %%use preload?;

                                    %s.cache.maskTexture = screen('makeTexture',w,s.cache.mask);
                                    s.cache.textures=textures;
                                catch ex
                                    sca
                                    ShowCursor;
                                    rethrow(ex);
                                end
                            otherwise
                                s.renderMode
                                error('bad renderMode')
                        end

                    case 'LUT'
                        s=fillLUT(s,s.typeOfLUT,s.rangeOfMonitorLinearized,0);

                    case 'dynamicSweepValues'
                        if ~isempty(s.dynamicSweep)
                            %if isempty(s.dynamicSweep.sweptValues)
                                %fill them every trial, same if seed is set, random per trial if seed is 'clock'
                                s.dynamicSweep.sweptValues=generateFlankerFactorialCombo(s, s.dynamicSweep.sweptParameters, s.dynamicSweep.sweepMode, struct(s));
                                %updateSM=true;
                            %end
                        end


                        %SINCE: dymaic inflates after PTB, but needs this, inflate has been moved
                        %to the calc stim.  its also simplified
                        % if ~isempty(s.dynamicSweep)
                        %     if isempty(s.dynamicSweep.sweptValues)
                        %         %fill them ALL from the struct of the stim
                        %         s.dynamicSweep.sweptValues=generateFlankerFactorialCombo(s, s.dynamicSweep.sweptParameters, s.dynamicSweep.sweepMode, struct(s));
                        %     else
                        %         switch s.dynamicSweep.sweepMode{1}
                        %             case 'manual'
                        %                 % no factorial combo!
                        %                 %don't do anything... we just use the values that are there
                        %             case {'ordered','random'}
                        %                 %facorialize the given values
                        %
                        %                 warning('the only reason to get here is on a reinflate, but then sweptvalues will already have values, so not doing anything')
                        % %                 for i=1:length(s.dynamicSweep.sweptParameters)
                        % %                     parameters.(s.dynamicSweep.sweptParameters{i})=s.dynamicSweep.sweptValues(i,:)';
                        % %                 end
                        % %                 s.dynamicSweep.sweptValues=generateFlankerFactorialCombo(s, s.dynamicSweep.sweptParameters, s.dynamicSweep.sweepMode, parameters);
                        %              otherwise
                        %                 s.dynamicSweep.sweepMode{1}
                        %                 error('bad mode')
                        %         end
                        %     end
                        %
                        % end
                    otherwise
                        parts{i}
                        error('thats not a part of inflate')
                end
            end


            uniqueRepeatDrift=0;
            if uniqueRepeatDrift
                %%add some more for a test
                s.cache.A=cast(double(intmax(integerType))*(rand(1,256)),integerType);
                s.cache.B=cast(double(intmax(integerType))*(0.5+(sin([1:256]*2*pi/6)/2)),integerType);
                s.cache.ATex = screen('makeTexture',w,s.cache.A);
                s.cache.BTex = screen('makeTexture',w,s.cache.B);
            end
        end



        function w =getWindow()
            w=Screen('Windows');
            onScreenWindowIndex=find(Screen(Screen('Windows'),'WindowKind')==1);
            numOnscreenWindows=length(onScreenWindowIndex);

            if isempty(onScreenWindowIndex)
                error('can''t build textures b/c no window')
            else
                if numOnscreenWindows>1
                    w
                    w(onScreenWindowIndex)
                    numOnscreenWindows=numOnscreenWindows
                    error('expected only one window open, cant decide which')
                else
                    w=w(onScreenWindowIndex(1))
                end
            end
        end
        
        function out=isDynamicRender(stimulus);

            %faster (it might get called in the real time loop)
            out = ~isempty(strfind(stimulus.renderMode,'dynamic'));

            %slower
            %out=ismember(stimulus.renderMode,{'dynamic-precachedInsertion','dynamic-maskTimesGrating','dynamic-onePatchPerPhase','dynamic-onePatch'});
        end
        
        function   [targetIsOn flankerIsOn effectiveFrame cycleNum sweptID repetition]=isTargetFlankerOn(s,frame)
            %if a single frame, returns a pseudo logical value for each output (0 or 1) 
            %if multiple frames, returns a vector of zeros or sweptID
            %for logicals, use targetIsOn >0

            if ~isempty(s.dynamicSweep) 
                %determine the effective frame
                framesPerCycle=double(max([s.targetOnOff s.flankerOnOff]));
                cycleNum=floor(frame/framesPerCycle)+1;
                effectiveFrame=mod(frame, framesPerCycle); 

                %prevent frame values of 0 
                zeroInds=find(effectiveFrame==0);
                cycleNum(zeroInds)=cycleNum(zeroInds)-1;
                effectiveFrame(zeroInds)=framesPerCycle;

                %get the id of the swept params
                cyclesPerID=size(s.dynamicSweep.sweptValues,2);
                repetition=floor(cycleNum/cyclesPerID)+1;
                sweptID=mod(cycleNum, cyclesPerID); 

                 %prevent ID values of 0 
                zeroInds=find(sweptID==0);
                repetition(zeroInds)=repetition(zeroInds)-1;
                sweptID(zeroInds)=cyclesPerID;
            else
                effectiveFrame=frame;
                cycleNum=ones(size(frame));
                sweptID=ones(size(frame));
                repetition=ones(size(frame));
            end

            % on is inclusive but off is exclusive!  ... compbatible with
            % behavior that uses createDiscriminandumContextOnOffMovie
            targetIsOn=(effectiveFrame>=s.targetOnOff(1) & effectiveFrame<s.targetOnOff(2));
            flankerIsOn=(effectiveFrame>=s.flankerOnOff(1) & effectiveFrame<s.flankerOnOff(2));

            if length(frame)>1
                targetIsOn=double(targetIsOn).*sweptID;
                flankerIsOn=double(flankerIsOn).*sweptID;
            end
        end
        
        function s=orientedGabors(varargin)
            % ORIENTEDGABORS  class constructor.
            % s = orientedGabors([pixPerCycs],[targetOrientations],[distractorOrientations],mean,radius,contrast,thresh,yPositionPercent,maxWidth,maxHeight,scaleFactor,interTrialLuminance) 
            % orientations in radians
            % mean, contrast, yPositionPercent normalized (0 <= value <= 1)
            % radius is the std dev of the enveloping gaussian, in normalized units of the diagonal of the stim region
            % thresh is in normalized luminance units, the value below which the stim should not appear
            switch nargin
            case 0 
            % if no input arguments, create a default object

                s.pixPerCycs = [];
                s.targetOrientations = [];
                s.distractorOrientations = [];

                s.mean = 0;
                s.radius = 0;
                s.contrast = 0;
                s.thresh = 0;
                s.yPosPct = 0; 

                

            case 1
            % if single argument of this class type, return it
                if (isa(varargin{1},'orientedGabors'))
                    s = varargin{1}; 
                else
                    error('Input argument is not an orientedGabors object')
                end
            case 12
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

                if isnumeric(varargin{6})
                    s.contrast=varargin{6};
                else
                    error('contrast must be numeric')
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

                

            otherwise
                error('Wrong number of input arguments')
            end
        end
        
        function [analysisdata cumulativedata] = physAnalysis(stimManager,spikeRecord,stimulusDetails,plotParameters,parameters,cumulativedata,eyeData,LFPRecord)
            % stimManager is the stimulus manager
            % spikes is a logical vector of size (number of neural data samples), where 1 represents a spike happening
            % frameIndices is an nx2 array of frame start and stop indices - [start stop], n = number of frames
            % stimulusDetails are the stimDetails from calcStim (hopefully they contain all the information needed to reconstruct stimData)
            % photoDiode - currently not used
            % plotParameters - currently not used


            %plotsRequested=plotParameters.plotsRequested
            plotsRequested={'viewSort','viewDrops','rasterDensity';
                'plotEyes','spikeAlignment','raster';
                'meanPhotoTargetSpike','PSTH','ratePerCondition'};

            plotsRequested={'viewSort','ratePerCondition';
                'raster', 'PSTH'};


            %% common - should put in util function for all physAnalysis
            %CHOOSE CLUSTER
            allSpikes=spikeRecord.spikes; %all waveforms
            waveInds=allSpikes; % location of all waveforms
            if isfield(spikeRecord,'processedClusters')
                try
                    if  length([spikeRecord.processedClusters])~=length(waveInds)
                        length([spikeRecord.processedClusters])
                        length(waveInds)
                        error('spikeDetails does not correspond to the spikeRecord''s spikes');
                    end
                catch ex
                    warning('oops')
                    keyboard
                    getReport(ex)
                end
                thisCluster=[spikeRecord.processedClusters]==1;
            else
                thisCluster=logical(ones(size(waveInds)));
                %use all (photodiode uses this)
            end
            spikes=allSpikes;
            spikes(~thisCluster)=[]; % remove spikes that dont belong to thisCluster

            %SET UP RELATION stimInd <--> frameInd
            analyzeDrops=true;
            if analyzeDrops
                stimFrames=spikeRecord.stimInds;
                correctedFrameIndices=spikeRecord.correctedFrameIndices;
            else
                numStimFrames=max(spikeRecord.stimInds);
                stimFrames=1:numStimFrames;
                firstFramePerStimInd=~[0; diff(spikeRecord.stimInds)==0];
                correctedFrameIndices=spikeRecord.correctedFrameIndices(firstFramePerStimInd);
            end

            if isempty(stimFrames)
               analysisdata=[];
               warning('no frames... not doing analysis... returning cumulative ''as is''')
               return % end this function
            end

            % count the number of spikes per frame
            % spikeCount is a 1xn vector of (number of spikes per frame), where n = number of frames
            spikeCount=zeros(1,size(correctedFrameIndices,1));
            for i=1:length(spikeCount) % for each frame
                spikeCount(i)=length(find(spikes>=correctedFrameIndices(i,1)&spikes<=correctedFrameIndices(i,2)));
                %spikeCount(i)=sum(spikes(frameIndices(i,1):frameIndices(i,2)));  % inclusive?  policy: include start & stop
            end

            samplingRate=parameters.samplingRate;
            ifi=1/stimulusDetails.hz;      %in old mode used to be same as empiric (diff(spikeData.frameIndices'))/samplingRate;
            ifi2=1/parameters.refreshRate; %parameters.refreshRate might be wrong, so check it
            if (abs(ifi-ifi2)/ifi)>0.01  % 1 percent error tolerated
                ifi
                ifi2
                er=(abs(ifi-ifi2)/ifi)
                error('refresh rate doesn''t agree!')
            end

            if ~isempty(eyeData)
                [px py crx cry]=getPxyCRxy(eyeData);
                eyeSig=[crx-px cry-py];
                eyeSig(end,:)=[]; % remove last ones to match (not principled... what if we should throw out the first ones?)
            else
                eyeSig=[];
            end


            %% now stuff unique to flankers
            %SET stimulus and get basic features per frame 
            s=setStimFromDetails(stimManager, stimulusDetails);
            swept=s.dynamicSweep.sweptParameters;
            addToCumulativeData=isfield(cumulativedata,'swept')  && strcmp([cumulativedata.swept{:}],[swept{:}]);
            [targetIsOn flankerIsOn effectiveFrame cycleNum sweptID repetition]=isTargetFlankerOn(s,stimFrames);

            %  SHIFT sweptID & repetition & cycleNum by half the number of mean screen frames.  
            %   the purpose of this is to have the on and off response of a  sweptID condition 
            %   be displayed on the same raster. If we don't do this the off response
            %   wraps around onto the begining of the next (random) condition
            numMeanScreenFrames=min([s.targetOnOff s.flankerOnOff])/2;
            % because of wrapping cicularly, the off response to the FIRST condition is
            % actually the last ... something better in the long run could avoid this...
            % but i believe it is not analyzed in the density which rejects the last
            % repitition.

            sweptID   =[   sweptID(end-numMeanScreenFrames+1:end);    sweptID(1:end-numMeanScreenFrames) ];
            cycleNum  =[  cycleNum(end-numMeanScreenFrames+1:end);   cycleNum(1:end-numMeanScreenFrames) ];
            repetition=[repetition(end-numMeanScreenFrames+1:end); repetition(1:end-numMeanScreenFrames) ];
            modifiedEffectiveFrame=effectiveFrame;
            modifiedEffectiveFrame(1:numMeanScreenFrames)=1:numMeanScreenFrames;  % fix the first section


            %useful for plotting, not relied upon for other stuff
            droppedFrames=[diff(stimFrames)==0; 0];


            %%

            %assemble a vector struct per frame (like per trial)
            d.date=correctedFrameIndices(:,1)'/(samplingRate*60*60*24); %define field just to avoid errors
            for i=1:length(swept)
                switch swept{i}
                    case {'targetContrast','flankerContrast'}
                        d.(swept{i})=s.dynamicSweep.sweptValues(i,sweptID);
                    case 'targetOrientations'
                        d.targetOrientation=s.dynamicSweep.sweptValues(i,sweptID);
                    case 'flankerOrientations'
                        d.flankerOrientation=s.dynamicSweep.sweptValues(i,sweptID);
                    case 'phase'
                        d.targetPhase=s.dynamicSweep.sweptValues(i,sweptID);
                        d.flankerPhase=d.targetPhase;
                    otherwise
                        d.(swept{i})= s.dynamicSweep.sweptValues(i,sweptID);
                end
            end

            %get the condition inds depending on what was swept
            if any(strcmp(swept,'targetOrientations'))...
                    && any(strcmp(swept,'flankerOrientations'))...
                    && any(strcmp(swept,'flankerPosAngle'))...
                    && any(strcmp(swept,'phase'))...
                    && size(swept,2)==4;
                conditionType='colin+3';
                [conditionInds conditionNames haveData colors]=getFlankerConditionInds(d,[],conditionType);
                colors(2,:)=colors(3,:); % both pop-outs the same
                colors(4,:)=[.5 .5 .5]; % grey not black
                % elseif any(strcmp(swept,'targetContrast'))...
                %     && any(strcmp(swept,'flankerContrast'))...
                %     && size(swept,2)==2;
                %
                %     %flanker contrast only right now...
                %     [conditionInds conditionNames haveData colors]=getFlankerConditionInds(d,[],'fiveFlankerContrastsFullRange');

                %
            elseif any(strcmp(swept,'targetOrientations'))...
                    && any(strcmp(swept,'phase'))...
                    && size(swept,2)==2;
                conditionType='allTargetOrientationAndPhase';
                [conditionInds conditionNames haveData colors]=getFlankerConditionInds(d,[],conditionType);
            elseif any(strcmp(swept,'targetContrast'))...
                    && any(strcmp(swept,'phase'))...
                    && size(swept,2)==2;
                conditionType='allTargetContrastAndPhase'; % best
                %conditionType='allTargetContrasts'; % could use, but not best
                %conditionType='allPhases' % could use, but not best
                [conditionInds conditionNames haveData colors]=getFlankerConditionInds(d,[],conditionType);
            else 
                %default to each unique
                conditionsInds=zeros(max(sweptID),length(stimFrames));
                allSweptIDs=unique(sweptID);
                for i=1:length(allSweptIDs)
                    conditionInds(i,:)=sweptID==allSweptIDs(i);
                    conditionNames{i}=num2str(i);
                end
                colors=jet(length(allSweptIDs));
            end


            numConditions=size(conditionInds,1); % regroup as flanker conditions
            numTrialTypes=length(unique(sweptID)); % whatever the group actually was acording to ths sm
            numRepeats=max(repetition);
            numUniqueFrames=max(effectiveFrame);
            frameDurs=(correctedFrameIndices(:,2)-correctedFrameIndices(:,1))'/samplingRate;
            %% set the values into the conditions
            f=fields(d);
            f(ismember(f,'date'))=[];  % the date is not part of the condition
            for i=1:numConditions
                for j=1:length(f)
                    firstInstance=min(find(conditionInds(i,:)));
                    value=d.(f{j})(firstInstance);
                    if length(unique(d.(f{j})(find(conditionInds(i,:)))))~=1
                        error('more than 1 unique value in a condition is an error')
                    end
                    if isempty(value)
                        value=nan;
                    end
                    c.(f{j})(i)=value;

                    if addToCumulativeData && value~=cumulativedata.conditionValues.(f{j})(i)
                        cumulativedata.conditionValues
                        f{j}
                        cumulativedata.conditionValues.(f{j})(i)
                        value
                        error('these values must be the same to combine across trials')
                    end
                end
            end



            %% precalc usefull
            onsetFrame=diff([0; targetIsOn])>0;
            [conditionPerCycle junk]=find(conditionInds(:,onsetFrame));
            shiftedFrameOrder=[(1+numMeanScreenFrames):numUniqueFrames  1:numMeanScreenFrames];
            %% construct density for spikes and photodiode
            events=nan(numRepeats,numTrialTypes,numUniqueFrames);
            possibleEvents=events;
            photodiode=events;
            rasterDensity=ones(numRepeats*numTrialTypes,numUniqueFrames)*0.1;
            photodiodeRaster=rasterDensity;
            %tOn2=rasterDensity;
            fprintf('%d repeats',numRepeats)
            for i=1:numRepeats
                fprintf('.%d',i)
                for j=1:numTrialTypes
                    for k=1:numUniqueFrames
                        thisFrame=shiftedFrameOrder(k);
                        which=find(sweptID==j & repetition==i & effectiveFrame==thisFrame);
                        events(i,j,thisFrame)=sum(spikeCount(which));
                        possibleEvents(i,j,thisFrame)=length(which);
                        photodiode(i,j,thisFrame)=sum(spikeRecord.photoDiode(which))/sum(frameDurs(which));
                        if isempty(which)
                            warning(sprintf('count should be at least 1!, [i j thisFrame] = [%d %d %d]',i,j,thisFrame))
                            %the source of this error is the  SHIFT early on... maybe
                            %smarter code is needed to handle the shift
                            % wacky ideas: tack some on at the end?
                            % loop through and shift all dynamically?
                        end
                        %tOn(i,j,thisFrame)=mean(targetIsOn(which)>0.5); where is should be on

                        %in last repeat density = 0.1, for parsings and avoiding misleading half data
                        if numRepeats~=i
                            %y=(j-1)*(numRepeats)+i; % linear in order displayed
                            y=(conditionPerCycle(j)-1)*(numRepeats)+i; %unscambled to the order in conditiondInds
                            rasterDensity(y,k)=events(i,j,thisFrame)./possibleEvents(i,j,thisFrame);
                            photodiodeRaster(y,k)=photodiode(i,j,thisFrame);
                            %tOn2(y,thisFrame)=tOn(i,j,thisFrame); where is should be on
                        end
                    end
                end
            end

            %%

            rasterDensity(isnan(rasterDensity))=0;
            photodiodeRaster(photodiodeRaster==0.1)=mean(photodiodeRaster(:)); photodiodeRaster(1)=mean(photodiodeRaster(:));  % a known problem from drops

            fullRate=events./(possibleEvents*ifi);
            if numRepeats>2
                % don't remove if there is only 1
                fullPhotodiode=photodiode(2:end,:,:);
            else
                fullPhotodiode=photodiode;
            end
            rate=reshape(sum(events,1)./(sum(possibleEvents,1)*ifi),numTrialTypes,numUniqueFrames); % combine repetitions

            if numRepeats>2
                rateSEM=reshape(std(events(1:end-1,:,:)./(possibleEvents(1:end-1,:,:)*ifi)),numTrialTypes,numUniqueFrames)/sqrt(numRepeats-1);
                photodiodeSEM=reshape(std(photodiode(1:end-1,:,:)),numTrialTypes,numUniqueFrames)/sqrt(numRepeats-1);
                photodiode=reshape(mean(photodiode(2:end,:,:),1),numTrialTypes,numUniqueFrames); % combine repetitions
            else
                rateSEM=nan(size(rate));
                photodiodeSEM=nan(size(rate));
                photodiode=reshape(mean(photodiode,1),numTrialTypes,numUniqueFrames); % combine repetitions
            end

            % THIS SHOULD BE DELETEABLE, BUT CODE NEEDS TO BE RUN AND INSPECTED regarding
            %      frame=shiftedFrameOrder(k)
            % %place half the means screen in front and half behind
            % % maybe do this b4 on all of them
            % rate=rate(:,shiftedFrameOrder);
            % rateSEM=rateSEM(:,shiftedFrameOrder);
            % rasterDensity=rasterDensity(:,shiftedFrameOrder);
            % fullPhotodiode=fullPhotodiode(:,:,shiftedFrameOrder);
            % photodiode=photodiode(:,shiftedFrameOrder);
            % photodiodeSEM=photodiodeSEM(:,shiftedFrameOrder);
            % photodiodeRaster=photodiodeRaster(:,shiftedFrameOrder);


            %%  SOME DATA IS STORED PER SPIKE
                spike.times=spikeRecord.spikeTimestamps(thisCluster)';
                cycleOnset=spikeRecord.correctedFrameTimes(onsetFrame,1); % the time that the target starts
                repStartFrame=diff([0; repetition])>0;
                repStartTime=spikeRecord.correctedFrameTimes(repStartFrame,1); % the time that the rep starts

                %REMOVE SPIKES THAT ARE BEFORE THE FIRST STIM OF THE TRIAL BY MORE THAN ~ 200ms
                timeToTarget=double(s.targetOnOff(1))*ifi/2;
                tooEarly=spike.times<cycleOnset(1)-timeToTarget;
                spike.times(tooEarly)=[];

                %INIT AND SET PROPERTIES FOR EACH SPIKE
                spike.relTimes=zeros(size(spike.times));
                spike.relRepTimes=zeros(size(spike.times));
                spike.frame=zeros(size(spike.times));
                spike.cycle=zeros(size(spike.times));
                spike.condition=zeros(size(spike.times));
                for i=1:length(spike.times)
                    spike.cycle(i)=max(find(spike.times(i)>cycleOnset-timeToTarget)); % the stimulus cycle of each spike
                    spike.frame(i)=max(find(spike.times(i)>spikeRecord.correctedFrameTimes(:,1))); % the frame of each spike
                    spike.relTimes(i)=spike.times(i)-cycleOnset(spike.cycle(i)); % the relative time to the target onset of this cycle
                    spike.condition(i)=find(conditionInds(:,spike.frame(i))); % what condition this spike occurred in
                    spike.repetition(i)=repetition(spike.frame(i)); % what rep this spike occurred in
                    spike.relRepTimes(i)=spike.times(i)-repStartTime(spike.repetition(i)); % the relative time to the rep onset of this cycle
                end
                % save trial info per spike b/c going to have info across many trials
                spike.trial=parameters.trialNumber(ones(1,length(spike.times)))


            %% ADD to cumulativeData the stuff that was processed

            if addToCumulativeData

                cumulativedata.trialNumbers=[cumulativedata.trialNumbers parameters.trialNumber];
                cumulativedata.numFrames=[cumulativedata.numFrames length(stimFrames)];
                if  any(cumulativedata.targetOnOff~=double(s.targetOnOff))
                    error('not allowed to change targetOnOff between trials')
                end

                cumulativedata.spikeWaveforms=[cumulativedata.spikeWaveforms; spikeRecord.spikeWaveforms];
                cumulativedata.processedClusters=[cumulativedata.processedClusters; [spikeRecord.processedClusters]];
                if samplingRate~=cumulativedata.samplingRate;
                    error('switched sampling rate across these trials')
                end

                cumulativedata.totalDrops=sum(droppedFrames); % this summary statistic is trust worthy
                cumulativedata.droppedFrames=[cumulativedata.droppedFrames; droppedFrames];  % this is a crude concatenation across trials; and find(drops) should not be trusted withouit serious checking of groud facts.
                cumulativedata.eyeSig=[cumulativedata.eyeSig; eyeSig];

                %SPIKE
                f=fields(spike);
                for i=1:length(f)
                    cumulativedata.spike.(f{i})=[cumulativedata.spike.(f{i}) spike.(f{i})];
                end
                cumulativedata.cycleOnset=[cumulativedata.cycleOnset; cycleOnset];
                cumulativedata.numSpikesAnalyzed=[cumulativedata.numSpikesAnalyzed length(spike.times)];

                try
                    cumulativedata.conditionPerCycle=[cumulativedata.conditionPerCycle conditionPerCycle];
                    %[160 20] failed to join with size [2 1]
                catch
                    %hack!
                    warning('HACK! avoided a wired error by maing a fake veactor of ones and stuffing in whats here')
                    temp=ones(size(cumulativedata.conditionPerCycle,1),1)
                    temp(1:length(conditionPerCycle))=conditionPerCycle
                    keyboard
                    cumulativedata.conditionPerCycle=[cumulativedata.conditionPerCycle cumulativedata.conditionPerCycle()];
                end


                cumulativedata.photodiodeRaster=cumulativedata.photodiodeRaster + photodiodeRaster; %NEW: a sum of volts
                cumulativedata.rasterDensity=cumulativedata.rasterDensity + rasterDensity;          %NEW: a sum of counts
                %cumulativedata.photodiodeRaster=[cumulativedata.photodiodeRaster; photodiodeRaster]; %OLD: a vertical stack
                %cumulativedata.rasterDensity=[cumulativedata.rasterDensity; rasterDensity]; %OLD: a vertical stack

            else %reset
                %initialize if trial is new type, or enforce blank if starting fresh
                cumulativedata=[]; %wipe out whatever data we get

                %store only once at start:
                cumulativedata.plotsRequested=plotsRequested;
                cumulativedata.targetOnOff=double(s.targetOnOff);
                cumulativedata.ifi=ifi;
                cumulativedata.conditionNames=conditionNames;
                cumulativedata.colors=colors;
                cumulativedata.swept=swept;
                cumulativedata.conditionValues=c; % no need to add, b/c we confrimed they are the same

                % store cumulative:
                cumulativedata.trialNumbers=parameters.trialNumber;
                cumulativedata.numFrames=length(stimFrames);


                cumulativedata.spikeWaveforms=spikeRecord.spikeWaveforms;
                cumulativedata.processedClusters=[spikeRecord.processedClusters];
                cumulativedata.samplingRate=samplingRate;

                cumulativedata.totalDrops=sum(droppedFrames);
                cumulativedata.droppedFrames=droppedFrames;
                cumulativedata.eyeSig=eyeSig;

                %SPIKE
                cumulativedata.spike=spike;
                cumulativedata.cycleOnset=cycleOnset;
                cumulativedata.numSpikesAnalyzed=length(spike.times)% more accurate than sum(spikeCount) by a few spikes
                cumulativedata.conditionPerCycle=conditionPerCycle;

                cumulativedata.photodiodeRaster=photodiodeRaster;
                cumulativedata.rasterDensity=rasterDensity;
            end

            analysisdata=[]; % per chunk is not used ever yet.. only cumulatuve saves


            %% viewDropsAndCycles
            % sometime worth turning on... tho it may interfere with handles
            viewDropsAndCycles= 0; %sum(diff(stimFrames)==0)>0; % a side plot when drops exist
            if viewDropsAndCycles
                figure
                dropFraction=conv([diff(stimFrames)==0; 0],ones(1,100));
                subplot(6,1,1); plot(effectiveFrame)
                subplot(6,1,2); plot(stimFrames)
                %subplot(6,1,3); plot(cycleNum)
                subplot(6,1,3); plot(dropFraction)
                ylabel(sprintf('drops: %d',sum(diff(stimFrames)==0)))
                subplot(6,1,4); plot(sweptID)
                subplot(6,1,5); plot(repetition)
                subplot(6,1,6); plot(targetIsOn)
            end

            %% PHOTODIODE
            %%
            doPhotodiode=0;
            if doPhotodiode
                %figure; hold on;
                switch conditionType
                    case 'allTargetOrientationAndPhase'
                        %%
                        %close all

                        %%
                        subplot(1,2,1); hold on
                        title(sprintf('grating %dppc',stimulusDetails.pixPerCycs(1)))

                        ss=1+round(stimulusDetails.targetOnOff(1)/2);
                        ee=ss+round(diff(stimulusDetails.targetOnOff))-1;
                        or=unique(c.targetOrientation);
                        if or(1)==0 && or(2)==pi/2
                            l1='V';
                            l2='H';
                        elseif abs(or(1))==abs(or(2)) && or(1)<0 && or(2)>0
                            l1=sprintf('%2.0f CW',180*or(2)/pi);
                            l2='CCW';
                        else
                            l1='or1';
                            l2='or2'
                        end

                        for i=1:length(or)
                            which=find(c.targetOrientation==or(i));
                            pho=photodiode(which,:)';
                            [photoTime photoPhase ]=find(pho==max(pho(:)));
                            phoSEM=photodiodeSEM(photoPhase,:);

                            whichPlot='maxPhase'
                            switch whichPlot
                                case 'maxPhase'
                                    plot(1:numUniqueFrames,[pho(:,photoPhase) pho(:,photoPhase)],'.','color',colors(min(which),:));
                                case 'allRepsMaxPhase'
                                    theseData=reshape(fullPhotodiode(:,which(photoPhase),:),size(fullPhotodiode,1),[]);
                                    theFrames=repmat([1:numUniqueFrames],size(fullPhotodiode,1),1);
                                    plot(theFrames,theseData,'.','color',colors(min(which),:))
                            end

                            h(i)=plot(pho(:,photoPhase),'color',colors(min(which),:));
                            %plot([1:length(pho); 1:length(pho)],[pho(:,photoPhase) pho(:,photoPhase)]'+(phoSEM'*[-1 1])','color',colors(min(find(which)),:))
                        end
                        xlabel('frame #')
                        ylabel('sum(volts)')
                        legend(h,{l1,l2})
                        %set(gca,'xlim',[0 size(pho,1)*2],'ylim',[7 11])

                        subplot(1,2,2); hold on
                        for i=1:length(or)
                            which=find(c.targetOrientation==or(i));
                            pha=c.targetPhase(which);
                            pho=photodiode(which,:)';
                            [photoTime photoPhase ]=find(pho==max(pho(:)));

                            options=optimset('TolFun',10^-14,'TolX',10^-14);
                            lb=[0 0 -pi*2]; ub=[6000 4000 2*pi]; % lb=[]; ub=[];


                            p=linspace(0,4*pi,100);

                            whichPlot='allRepsOneTime';
                            switch whichPlot

                                case 'maxTime'
                                    params = lsqcurvefit(@(x,xdata) x(1)+x(2)*sin(xdata+x(3)),[1000 100 1],pha,pho(photoTime,:),lb,ub,options); params(3)=mod(params(3),2*pi);
                                    plot([pha pha+2*pi]+params(3),[pho(photoTime,:) pho(photoTime,:)],'.','color',colors(min(which),:));

                                    %plot([pha pha+2*pi]+params(3),[pho pho],'.','color',colors(min(find(which)),:));
                                case 'allRepsOneTime'
                                    params = lsqcurvefit(@(x,xdata) x(1)+x(2)*sin(xdata+x(3)),[1000 100 1],pha,pho(photoTime,:),lb,ub,options); params(3)=mod(params(3),2*pi);
                                    theseData=reshape(fullPhotodiode(:,which,photoTime),size(fullPhotodiode,1),[]);
                                    thePhases=repmat(pha+params(3),size(fullPhotodiode,1),1);
                                    plot(thePhases,theseData,'.','color',colors(min(which),:))
                                case 'allRepsTimeAveraged'

                                case  'timeAveragedRepAveraged'
                                    meanPho=mean(pho);
                                    validPho=~isnan(meanPho);
                                    params = lsqcurvefit(@(x,xdata) x(1)+x(2)*sin(xdata+x(3)),[1000 100 1],pha(validPho),meanPho(validPho),lb,ub,options); params(3)=mod(params(3),2*pi);
                                    plot([pha pha+2*pi]+params(3),[mean(pho) mean(pho)],'.','color',colors(min(which),:));
                                case  'stimOnTimeAveragedRepAveraged'
                                    meanPho=mean(pho(ss:ee,:));
                                    validPho=~isnan(meanPho);
                                    params = lsqcurvefit(@(x,xdata) x(1)+x(2)*sin(xdata+x(3)),[1000 100 1],pha(validPho),meanPho(validPho),lb,ub,options); params(3)=mod(params(3),2*pi);
                                    plot([pha pha+2*pi]+params(3),[meanPho meanPho],'.','color',colors(min(which),:));

                            end
                            plot(p,params(1)+params(2)*sin(p),'-','color',colors(min(which),:))


                            amp(i)=params(2);
                            mn(i)=params(1);
                        end
                        meanFloor=min(photodiode(:));
                        ratioDC=(mn(1)-meanFloor)/(mn(2)-meanFloor);
                        string=sprintf('%s:%s = %2.3f mean  %2.3f amp',l1,l2,ratioDC,abs(amp(1)/amp(2)));
                        title(string)
                        xlabel('phase (\pi)')
                        set(gca,'ytick',[ylim ],'yticklabel',[ylim ])
                        set(gca,'xtick',[0 pi 2*pi 3*pi 4*pi],'xticklabel',[0 1 2 3 4],'xlim',[0 6*pi]);%,'ylim',[1525 1600])
                        cleanUpFigure
                    otherwise
                        %% inspect distribution of photodiode output
                        close all
                        figure;
                        subplot(2,2,1); hist(photodiode(:),100)
                        xlabel ('luminance (volts)'); ylabel ('count')
                        subplot(2,2,2); plot(diff(spikeRecord.correctedFrameTimes',1)*1000,spikeRecord.photoDiode,'.');
                        xlabel('frame time (msec)'); ylabel ('luminance (volts)')
                        subplot(2,2,3); plot(spikeRecord.spikeWaveforms(8,:)')


                        %%

                        subplot(1,2,1); hold on
                        for i=1:numConditions
                            plot(x,photodiode(i,:),'color',colors(i,:));
                            plot([x; x]+(i*0.05),[photodiode(i,:); photodiode(i,:)]+(photodiodeSEM(i,:)'*[-1 1])','color',colors(i,:))
                        end
                        xlabel('time (msec)');
                        set(gca,'XTickLabel',xvals,'XTick',xloc);
                        ylabel('sum volts (has errorbars)');
                        set(gca,'Xlim',[1 numUniqueFrames])

                        %rate density over phase... doubles as a legend
                        subplot(1,2,2); hold on
                        im=zeros([size(rasterDensity) 3]);
                        hues=rgb2hsv(colors);  % get colors to match jet
                        hues=repmat(hues(:,1)',numRepeats,1); % for each rep
                        hues=repmat(hues(:),1,numUniqueFrames);  % for each phase bin
                        grey=repmat(all((colors==repmat(colors(:,1),1,3))'),numRepeats,1); % match grey vals to hues
                        im(:,:,1)=hues; % hue
                        im(grey(:)~=1,:,2)=0.6; % saturation
                        im(:,:,3)=rasterDensity/max(rasterDensity(:)); % value
                        rgbIm=hsv2rgb(im);
                        image(rgbIm);
                        axis([0 size(im,2) 0 size(im,1)]+.5);
                        set(gca,'YTickLabel',conditionNames,'YTick',size(im,1)*([1:length(conditionNames)]-.5)/length(conditionNames))
                        xlabel('time');
                        %set(gca,'XTickLabel',{'0','pi','2pi'},'XTick',([0 .5  1]*numPhaseBins)+.5);

                end
            end

        end

           
        function plotRaster(sm,c)

            [numConditions numCycles numInstances nthOccurence displayHeight]=getNumConditionsEtc(sm,c);

            hold on
            for i=1:numConditions
                which=c.spike.condition==i;
                plot(c.spike.relTimes(which),-displayHeight(which),'.','color',brighten(c.colors(i,:),-0.2))
            end

            yTickVal=-fliplr((numInstances/2)+[0:numConditions-1]*numInstances);
            set(gca,'YTickLabel',fliplr(c.conditionNames),'YTick',yTickVal);
            ylabel([c.swept]);

            xlabel('time (msec)');
            timeToTarget=c.targetOnOff(1)*c.ifi/2;
            xvals=[ -timeToTarget 0  (diff(c.targetOnOff*c.ifi))+[0 timeToTarget]];
            set(gca,'XTickLabel',xvals*1000,'XTick',xvals);

            n=diff(minmax([0 displayHeight]));
            plot(xvals([2 2]),0.5+[-n 0],'k')
            plot(xvals([3 3]),0.5+[-n 0],'k')

            axis([xvals([1 4]) 0.5+[-n 0]])
            set(gca,'TickLength',[0 0])
        end
  
        function [stimulus updateSM stimulusDetails]=postScreenResetCheckAndOrCache(stimulus,updateSM,stimulusDetails);
            % if screens are not correct, then recache

            %ideally, this should be the ONLY place that caching happens, and it should
            %only happen once in the begining.

            %non-dynamic renders still get cached before PTB screen size is set
            if isDynamicRender(stimulus)
                messedWithSpatialParametersNeedingReinflate=false;
                if ~isempty(stimulus.blocking)
                    warning('this is fragile and was only used once for calibration, SF')
                    if length(stimulus.blocking.sweptParameters)==1 ...
                            && strcmp(stimulus.blocking.sweptParameters{1},'pixPerCycs')...
                            && strcmp(stimulus.blocking.blockingMethod,'nTrials')...
                            && stimulus.blocking.nTrials==1 ...
                            && stimulus.blocking.shuffleOrderEachBlock==0
                        stimulus.pixPerCycs=circshift(stimulus.pixPerCycs,[1 2]);
                        stimulusDetails.pixPerCycs=stimulus.pixPerCycs(1);  %the first one gets used
                        messedWithSpatialParametersNeedingReinflate=true;
                    else
                        error('this is fragile and was only used once for calibration')
                    end
                end

                if ~stimIsCached(stimulus) || messedWithSpatialParametersNeedingReinflate
                    stimulus=inflate(stimulus,{'stim'});
                end
                updateSM=true;


                %maybe check if they are all good (both there and the right size)
                %maybe check that the one after does not exist
                %out=texsCorrespondToThisWindow(s,w)
                expectedSize=size(stimulus.cache.mask);
                texIDs=stimulus.cache.textures(:);
                tic
                fprintf('could save a little intertrial time by not checking texs every trial; confirming %d texs with ID: ',length(texIDs));
                for i=1:length(texIDs)
                    fprintf('%d.',texIDs(i));
                    %txs{i}=Screen('GetImage', texIDs(i),[],[],2);
                    tx=Screen('GetImage', texIDs(i),[],[],2);
                    if size(tx,1)~=expectedSize(1) || size(tx,2)~=expectedSize(2)
                        expectedSize
                        size(tx)
                        [type o p]=ind2sub(size(stimulus.cache.textures),i) %type,o,p
                        i
                        texIDs(i)
                        %typeSz(i,:)=[type o p size(txs{i}) stimulus.cache.textures(i)];
                        error('texs not the expected size... did someone change them?  check assumptions against stimulus.cache.typeSz')
                    end
                end
                display(sprintf('took: %2.2f sec',toc))

            else
                updateSM=updateSM; % leave as is
            end


        end
        
        function  [details a b c z d e f g h p pD pF m x fpa frto frfo] = selectStimulusParameters(stimulus,trialRecords,details)
            %set variables for random selections
            a=Randi(size(stimulus.goRightOrientations,2));
            b=Randi(size(stimulus.goLeftOrientations,2));
            c=Randi(size(stimulus.flankerOrientations,2));
            z=Randi(size(stimulus.distractorOrientations,2));
            d=Randi(size(stimulus.goRightContrast,2));
            e=Randi(size(stimulus.goLeftContrast,2));
            f=Randi(size(stimulus.flankerContrast,2));
            g=Randi(size(stimulus.distractorContrast,2));
            h=Randi(size(stimulus.flankerOffset,2));
            p=Randi(size(stimulus.phase,2));
            pD=Randi(size(stimulus.phase,2));
            pF=Randi(size(stimulus.phase,2));
            m=Randi(size(stimulus.stdGaussMask,2));
            x=Randi(size(stimulus.pixPerCycs,2));
            fpa=Randi(size(stimulus.flankerPosAngle,2));
            frto=Randi(size(stimulus.fpaRelativeTargetOrientation,2));
            frfo=Randi(size(stimulus.fpaRelativeFlankerOrientation,2));

            if ~isempty(stimulus.blocking)
                [details setValues]=setBlockedDetails(stimulus,trialRecords,details);

                for i=1:length(setValues)
                    switch stimulus.blocking.sweptParameters{i}
                        case 'targetOrientations';
                            switch stimulus.protocolType
                                case {'goToRightDetection'}
                                    a=find(stimulus.goRightOrientations==setValues(i));
                                    b=find(stimulus.goLeftOrientations==setValues(i));
                                    %USED TO b=allow random it's 0 contrast
                                case 'goToLeftDetection'
                                    %a=allow random it's 0 contrast
                                    a=find(stimulus.goRightOrientations==setValues(i));
                                    b=find(stimulus.goLeftOrientations==setValues(i));
                                case {'goToSide'}
                                    a=find(stimulus.goRightOrientations==setValues(i));
                                    b=find(stimulus.goLeftOrientations==setValues(i));
                                case {'tiltDiscrim'}
                                    error('don''t block orientations in tilt discrim')
                                otherwise
                                    error('unvalidated blocking with this type')
                            end
                        case 'targetContrast';
                            switch stimulus.protocolType
                                case {'goToRightDetection','cuedGoNoGo','goNoGo'}
                                    d=find(stimulus.goRightContrast==setValues(i));
                                    %e=allow random it's 0 contrast
                                case 'goToLeftDetection'
                                    %d=allow random it's 0 contrast
                                    e=find(stimulus.goLeftContrast==setValues(i));
                                case {'goToSide','tiltDiscrim'}
                                    d=find(stimulus.goRightContrast==setValues(i));
                                    e=find(stimulus.goLeftContrast==setValues(i));
                                otherwise
                                    error('unvalidated blocking with this type')
                            end
                        case 'flankerOn'
                            details.flankerOnOff(1)=setValues(i);
                        case 'flankerOff'
                            details.flankerOnOff(2)=setValues(i);
                        case 'flankerOrientations';             c=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        case 'distractorOrientations';          z=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        case 'flankerContrast';                 f=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        case 'distractorContrast';              g=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        case 'flankerOffset';                   h=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        case 'targetPhase';                     p =find(stimulus.phase==setValues(i));
                        case 'flankerPhase';                    pF=find(stimulus.phase==setValues(i));
                        case 'distractorPhase';                 pD=find(stimulus.phase==setValues(i));
                        case 'stdGaussMask';                    m=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        case 'pixPerCycs';                      x=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        case 'flankerPosAngle';                 fpa=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        case 'fpaRelativeTargetOrientation';    frto=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        case 'fpaRelativeFlankerOrientation';   frfo=find(stimulus.(stimulus.blocking.sweptParameters{i})==setValues(i));
                        otherwise
                            stimulus.blocking.sweptParameters{i}
                            error('not handled yet')
                    end
                end
            end

            if isempty(a) || isempty(b) || isempty(c) || isempty(z) || isempty(d)...
                    || isempty(e) || isempty(f) || isempty(g) || isempty(h) || isempty(p)...
                    || isempty(pD) || isempty(pF) || isempty(m) || isempty(x)...
                    || isempty(fpa) || isempty(frto) || isempty(frfo)
                keyboard
                stimulus
                stimulus.blocking
                stimulus.blocking.sweptValues
                error('empty parameter index! suggests that a requested block value is undefined in the stim')
            end

            details.blocking=stimulus.blocking;


            % %frameInd=t.calib.frame; % total numer of possible images with the given method
            % % frameInd=3;
            % % method='sweepAllPhasesPerTargetOrientation'
            % %
            % % numTargetOrientations = size(s.goRightOrientations,2);
            % % numTargetPhases = size(s.phase,2);
            % % numFlankerOrientations=size(s.flankerOrientations,2);
            % % numFlankerPhases = size(s.phase,2);
            %
            % %         numFlankerOrientations=size(stimulus.flankerOrientations,2);
            % %         numTargetContrast=size(stimulus.goRightContrast,2);
            % %         numFlankerContrast=size(stimulus.flankerContrast,2);
            % %         numFlankerOffset=size(stimulus.flankerOffset,2);
            %
            % %             a=Randi(size(t.goRightOrientations,2));
            % %             b=Randi(size(t.goLeftOrientations,2));
            % %             c=Randi(size(t.flankerOrientations,2));
            % %             z=Randi(size(t.distractorOrientations,2));
            % %             d=Randi(size(t.goRightContrast,2));      %
            % %             e=Randi(size(t.goLeftContrast,2));
            % %             f=Randi(size(t.flankerContrast,2));
            % %             g=Randi(size(t.distractorContrast,2));
            % %             h=Randi(size(t.flankerOffset,2));
            % %             p=Randi(size(t.phase,2));
            % %             pD=Randi(size(t.phase,2));
            % %             pF=Randi(size(t.phase,2));
            %
            %
            % switch method %t.calib.method
            %
            %     case 'sweepAllPhasesPerFlankTargetContext'
            %        %a = ceil(frameInd/(numPhases*numTargetOrientations));
            %
            %        p = mod(frameInd-1, numTargetPhases)+1; % outputs [1:16 1:16 1:16 ...] TargetPhase index
            %        a = ceil((mod(frameInd-1, numTargetOrientations*numTargetPhases)+1)/numTargetPhases); % TargetOrientation index
            %        c = ceil((mod(frameInd-1, numTargetOrientations*numTargetPhases*numFlankerOrientations)+1)/(numTargetPhases*numTargetOrientations)); % FlankerOrientation index
            %        d = 1;
            %        f = 1;
            %        h = 1;
            %        pF = ceil((mod(frameInd-1, numTargetOrientations*numTargetPhases*numFlankerOrientations*numFlankerPhases)+1)/(numTargetPhases*numTargetOrientations*numFlankerOrientations)); %FlankerPhase index
            %        x = 1; %pixPerCycs (ADD TO TM)
            %
            %        z = 1;	g = 1;	pD = 1;  % Distractor Terms
            %        b = a;	e = d;   % GoLeft Terms
            %        m = 1; %mask sizes (ADD TO TM)
            %     case 'sweepAllPhasesPerTargetOrientation'
            %        c=1; z=1; d=1; e=1; f=1; h=1; g=1; pD=1; pF=1; m=1; x=1;
            %
            % %        if any([t.flankerContrast~=0 t.flankerContrast~=0  t.flankerContrast~=0])
            % %            error ('flanker, distractor or flankerDistractor will be drawn on the screen, but shouldn''t')
            % %        end
            %
            %        a = ceil(frameInd/numTargetPhases);
            %        b = ceil(frameInd/numTargetPhases);
            %        p = mod(frameInd,numTargetPhases);
            %
            %        if p==0
            %            p = numTargetPhases;
            %        end
            %
            %
            %     case 'sweepAllContrastsPerPhase'
            %     otherwise
            %         error('unknown calibration method');
            % end
        end
        
        function [details setValues]=setBlockedDetails(stimulus,trialRecords,details)
            if ~isempty(stimulus.blocking)
                blocking=stimulus.blocking;

                %error check
                numBlocks=size(stimulus.blocking.sweptValues,2);
                numParameters=size(blocking.sweptValues,1);
                if length(blocking.sweptParameters)~=numParameters
                    numParameters=numParameters
                    size(blocking.sweptValues)
                    error('wrong number of parameters, value should be M x N == numParams x numBlocks')
                end

                isThere=ismember(blocking.sweptParameters,[fields(stimulus); {'targetContrast','targetOrientations','flankerOn', 'flankerOff'}']); 
                if ~all(isThere)
                    stimulus.blocking.sweptParameters{~isThere}
                    warning(sprintf('found a request for "%s"', [stimulus.blocking.sweptParameters{~isThere}] ))
                    error('it is expected that all blocked parameters are either fields on the stimulus manager or specially approved')
                end

                if any(strcmp(blocking.sweptParameters,'fpaRelativeTargetOrientation')) || any(strcmp(blocking.sweptParameters,'flankerOffset')) 
                    error('have not done a visual confirmation of blocked flankerOffset or fpa')
                    error('relative orientation has not been tested and confrimed yet..make sure that block force and orientation don''t collide')
                end

                if size(trialRecords,2)>0
                    thisTrial=trialRecords(end).trialNumber+1
                else
                    thisTrial=1;
                end


                switch stimulus.blocking.blockingMethod
                    case 'daily'
                        blockID=rem(ceil(now-blocking.anchorDay),numBlocks)
                    case 'nTrials'
                        blockID=rem(floor(thisTrial/blocking.nTrials),numBlocks)
                    otherwise
                        stimulus.blocking.blockingMethod
                        error('bad blocking method')
                end

                if blockID==0
                    %remainder of 0 counts as last blockID
                    blockID=numBlocks;
                end

                % figure out if the step is new
                if thisTrial>2
                    temp=diff([trialRecords.trainingStepNum]);
                    newStep=temp(end)~=0;
                else
                    newStep=false; % don't consider it a new step for the first 2 trials, avoid resent on second trial
                end

                % figure out if the parameters are new
                if  thisTrial>1
                    if isfield(trialRecords(end),'stimDetails') && isfield(trialRecords(end).stimDetails,'blockPermutation')
                        newNumberOfParameters=size(stimulus.blocking.sweptValues,2)~=size(trialRecords(end).stimDetails.blockPermutation,2);
                    else
                        newNumberOfParameters=true; % treat: from no params to some params --> new params
                    end
                else
                    newNumberOfParameters=true; % treat: from no params to some params --> new params
                end


                if thisTrial==1 || ~ismember('blockID',fields(trialRecords(end).stimDetails)) || newStep || ...  % if first trial, or first trial this step
                        newNumberOfParameters || ... if number of parameters change
                        (~stimulus.blocking.shuffleOrderEachBlock && trialRecords(end).stimDetails.blockID~=blockID) ||... % if changes in blockID which is unpermuted
                        (stimulus.blocking.shuffleOrderEachBlock && trialRecords(end).stimDetails.blockID~=trialRecords(end).stimDetails.blockPermutation(blockID))       % if changes in blockID which *IS* permuted
                    %start or reset
                    details.trialThisBlock=1;
                else
                    %advance
                    details.trialThisBlock=trialRecords(end).stimDetails.trialThisBlock+1;
                end

                %get the blockID into details
                if stimulus.blocking.shuffleOrderEachBlock
                    % if the first trial of the first block
                    if (details.trialThisBlock==1 && blockID==1) || newStep || newNumberOfParameters ||(~ismember('stimDetails',fields(trialRecords)) ||  ~ismember('blockPermutation',fields(trialRecords(end).stimDetails)))
                        details.blockPermutation=randperm(size(stimulus.blocking.sweptValues,2)); %reset
                    else
                        details.blockPermutation=trialRecords(end).stimDetails.blockPermutation; %keep it till reset block
                    end
                    details.blockID=details.blockPermutation(blockID);
                else
                    details.blockID=blockID;
                end

                %set values for this block
                for i=1:numParameters
                    %don't set directly in details
                    %details.(stimulus.blocking.sweptParameters{i})=stimulus.blocking.sweptValues(i,details.blockID)

                    %rather trace out the value so selectStimulusParameters can find the ID
                    setValues(i)=stimulus.blocking.sweptValues(i,details.blockID);
                end
            end

        end
        
        function    [t]  = setCurrentShapedValue(t, value)

            if isempty(t.shapingValues)
                error('no shaping value defined');
            else

                if isnumeric( value )
                    t.shapingValues.currentValue = value;
                    pass=checkShapingValues(t, t.shapingMethod, t.shapingValues);
                    if ~pass
                        t.shapingValues = t.shapingValues
                        t.shapingMethod = t.shapingMethod
                        error('bad shaping values')
                    end
                    switch t.shapedParameter
                        case 'targetContrast'
                            %we don't know which field to change because we do not know
                            %which protocol it is, so we call a function
                            t=setTargetContrast(t, value);

                        case 'stdGaussMask'
                            t.stdGaussMask=value;
                            decache(t);
                            cache(t);            
                        otherwise %use a general method to set the value

                            command = sprintf('t.%s = value;', t.shapedParameter);
                            try
                                eval(command)
                            catch
                                fields(t)
                                disp(command);
                                error('bad command');
                            end
                    end
                else
                    error('currentShapedValue must be a number')
                end
            end

        end

        function [stimDetails dynamicDetails]=setDynamicDetails(s,stimDetails,sweptID,dynamicDetails);
            %updates the value in stim details and recomputes, and updates relevant fields

            %init
            doSpatialUpdate=false;

            for i=1:length(s.dynamicSweep.sweptParameters)
                param=s.dynamicSweep.sweptParameters{i};
                value=s.dynamicSweep.sweptValues(i,sweptID);
                switch s.dynamicSweep.sweptParameters{i}
                    case 'targetOrientations'
                         stimDetails.targetOrientation=value;
                    case 'flankerOrientations'
                         stimDetails.flankerOrientation=value;
                    case {'flankerOffset','xPositionPercent'} %fields with same name, update spatial params
                        stimDetails.(param)=value;
                        doSpatialUpdate=true;
                    case 'flankerPosAngle' %set the top flanker
                        stimDetails.flankerPosAngles= value + [0 pi];
                        doSpatialUpdate=true;
                    case {'targetContrast','flankerContrast'}  % is the same in the details is the name in the stim manager and requres no computation
                        stimDetails.(param)=value;
                    case {'phase'} % all phases yoked together...
                        stimDetails.targetPhase=value;
                        stimDetails.flankerPhase=value;
                        stimDetails.distractorPhase=value;
                        stimDetails.distractorFlankerPhase=value;
                    otherwise
                        error(sprintf('bad param: %s',param))
                end

            end

            if doSpatialUpdate
                stimDetails=computeSpatialDetails(s,stimDetails);
            end
        end
        
        function [stimDetails dynamicDetails]=setDynamicFlicker(s,stimDetails,frame,dynamicDetails);
            %updates the value in stim details and recomputes, and updates relevant fields

            %init
            doSpatialUpdate=false;

            for i=1:length(s.dynamicFlicker.flickeringParameters)
                param=s.dynamicFlicker.flickeringParameters{i};

                switch s.dynamicFlicker.flickerMode
                    case 'random'
                        value=s.dynamicFlicker.flickeringValues{i}(randi(length(s.dynamicFlicker.flickeringValues{i})));
                    otherwise % 'sequence' uses frame
                        error('mode not yet supported')
                end

                switch param
                    case 'targetOrientations'
                         stimDetails.targetOrientation=value;
                    case 'flankerOrientations'
                         stimDetails.flankerOrientation=value;
                    case {'flankerOffset'} %fields with same name, update spatial params
                        stimDetails.(param)=value;
                        doSpatialUpdate=true;
                    case 'flankerPosAngle' %set the top flanker
                        stimDetails.flankerPosAngles= value + [0 pi];
                        doSpatialUpdate=true;
                    case {'targetContrast','flankerContrast'}  % is the same in the details is the name in the stim manager and requres no computation
                        stimDetails.(param)=value;
                    case {'phase'} % all phases yoked together...
                        stimDetails.targetPhase=value;
                        stimDetails.flankerPhase=value;
                        stimDetails.distractorPhase=value;
                        stimDetails.distractorFlankerPhase=value;
                    otherwise
                        error(sprintf('bad param: %s',param))
                end
            end

            if doSpatialUpdate
                stimDetails=computeSpatialDetails(s,stimDetails);
            end
        end
        
        function   out=setFloatPrecision(s)
            %dynamic mode sets screen precision

            out=2;
        end
        
        function t=setPercentCorrectionTrials(t, value)
            if all(size(value)==[1 1]) && value>=0 && value<=1
                t.percentCorrectionTrials=value;
            else
                value=value
                error('percent correction trial must a single number be between 0 and 1')
            end
        end
        
        function t=setPhase(t, value)
            if isvector(value) && isnumeric(value)
                t.phase=value;
                %force recache?
            else
                value=value
                error('phase must a vector of numbers')
            end
        end
        
        function t=setPixPerCycs(t, value)
            if isnumeric(value) && isvector(value) && value>=2 
                t.pixPerCycs=value;
            else
                value=value
                error('pixPerCycs must a vector of values >=2')
            end
        end
        
        function t=setRenderMode(t, value)
            if ismember(value,'symbolicFlankerFromServerPNG')
                t.renderMode=value;
            else
                renderMode=renderMode
                error('renderMode is only approved to be changed from X to symbolicFlankerFromServerPNG at this point')
            end
        end
        
        function initialSeed=setSeed(tm,method)
            %a way to set the seed 
            %initialSeed=setSeed(tm,'fromClock')

            switch method
                case 'seedFromClock'
                    %default for v4; useful for simplicity of saving
                    %good for animals side to go to
                    initialSeed=sum(100*clock);
                    rand('seed',initialSeed)    
                    randn('seed',initialSeed)  
                case 'twisterFromClock'
                    %default for v7.4+; better rands for truly random stimuli
                    initialSeed=sum(100*clock);
                    rand('twister',initialSeed)    
                    randn('state',initialSeed)  
                otherwise
                    error ('bad method');
            end

            % rand('seed',initialSeed)    %default for v4; old unused
            % rand('state',initialSeed)   %default for v5-v7.3, used in early ratrix before 20080209
            % rand('twister',initialSeed) %default for v7.4 +
            %the last one we initialized is twister
            %which means all rand calls will use the twister seed

            %also initialize randn
            % randn('seed',initialSeed)    %for v4; old unused
            % randn('state',initialSeed)   %for v5-v7.3, used in early ratrix

            %Draw a randn and a rand and confirm the state changes
            % rn1=randn('state');
            % randn
            % rn2=randn('state');
            % randnStateChanges=~all(rn1==rn2);
            % 
            % r1=rand('twister');
            % rand
            % r2=rand('twister');
            % randStateChanges=~all(r1==r2);
            % 
            % if randnStateChanges & randStateChanges
            %     %everything okay
            % else
            %     error ('don''t trust your random seed');
            % end
        end

        function t=setStdGaussMask(t, value)
            if all(size(value)==[1 1]) && value>=0 && value<=1
                t.stdGaussMask=value;
            else
                value=value
                error('setStdGaussMask must a single number be between 0 and 1')
            end
        end
        
        function s=setStimFromDetails(s,details)

            %first set the defaults
            p=getDefaultParameters(s);
            s=getStimManager(setFlankerStimRewardAndTrialManager(p));

            % then overwrite all the fields that we have in .sm
            f=fields(details.sm);
            for i = 1:length(f)
              s.(f{i})=details.sm.(f{i});
            end

        end
        
        function t=setTargetContrast(t, targetContrast)
            switch t.protocolType
                case 'goToSide'
                    t.goRightContrast = [targetContrast];    %choose a random contrast from this list each trial
                    t.goLeftContrast =  [targetContrast];
                case 'goToRightDetection'
                    t.goRightContrast = [targetContrast];    %choose a random contrast from this list each trial
                    t.goLeftContrast =  [0];
                case 'goToLeftDetection'
                    t.goRightContrast = [0];    %choose a random contrast from this list each trial
                    t.goLeftContrast =  [targetContrast];
                case 'tiltDiscrim'
                    t.goRightContrast = [targetContrast];    %choose a random contrast from this list each trial
                    t.goLeftContrast =  [targetContrast];
                otherwise
                    protocolType=t.protocolType
                    error('unknown type of protocol requested')
            end
        end
        
        function    [parameterChanged, t]  = shapeParameter(t, trialRecords)

            parameterChanged = false;

            %% doShape

            switch  t.shapingMethod
                case 'exponentialParameterAtConstantPerformance'
                    sca
                    error('code not written yet, will be completed when Yuan returns next year after the 2nd of January');
                case 'geometricRatioAtCriteria'
                    sca
                    error('code not written yet, will be completed when Yuan returns');
                case 'linearChangeAtCriteria'
                    if ~isempty(trialRecords)
                        %trialRecords=trialRecords([trialRecords.sessionNumber]==trialRecords(end).sessionNumber)%remove not this step
                        trialRecords=trialRecords([trialRecords.trainingStepNum]==trialRecords(end).trainingStepNum); %remove not this step
                        if ~isempty(trialRecords)
                            %select appropriate trials for shaping
                            try 
                                stimDetails=[trialRecords.stimDetails]; 
                            catch
                                %this adds in all of the new fields that are present in
                                %the most recent trials into the history
                                %It is used when new fields are added into stimDetials
                                %and horzcat does not work for unlike number of fields
                                %within a structure
                                trialRecords=fillMissingFields(trialRecords,{'stimDetails'},nan);
                                stimDetails=[trialRecords.stimDetails];
                            end

                            try
                            thisParameter=strcmp({stimDetails.shapedParameter},stimDetails(end).shapedParameter);
                            catch
                              stimDetails(end)
                              error('probably had a bad previous stimulus manager; can''t shape unless we know the previous state')
                            end
                            thisValue=([stimDetails.currentShapedValue]==stimDetails(end).currentShapedValue);
                            uncorrelated=~[stimDetails.correctionTrial] & ~[stimDetails.maxCorrectForceSwitch];
                            whichTrials=thisParameter&thisValue&uncorrelated;
                            trialRecords=trialRecords(whichTrials);
                        end
                    end
                    [aboveThresh ]=aboveThresholdPerformance(t.shapingValues.numTrials, t.shapingValues.performanceLevel, trialRecords);


                    %Testing ONLY!!
            %         
            %         delta = (t.shapingValues.goalValue-t.shapingValues.startValue)/double(t.shapingValues.numSteps)
            %         c=t.shapingValues.currentValue
            %         aboveThresh
            % 
            %         if ~isempty(trialRecords)
            %             x=[trialRecords.stimDetails]; y=[x.currentShapedValue]
            %             containsError=any(diff(y)<0)
            %         else
            %             containsError=false;
            %         end
            % 
            %         proposed=c+(delta*aboveThresh)
            %         if proposed<c
            %             warning('error about to happen');
            %             sca
            %             keyboard
            %         end
            %         
            %         if length(trialRecords)>20 
            %             sca
            %             keyboard
            %         end
            %             
            %         if length(trialRecords)>12 && stimDetails(end).currentShapedValue==0.1
            %             sca
            %             
            %           
            %             keyboard
            %             
            %             
            %         end


                    if aboveThresh
                        delta = (t.shapingValues.goalValue-t.shapingValues.startValue)/double(t.shapingValues.numSteps);
                        t.shapingValues.currentValue = t.shapingValues.currentValue + delta;
                        parameterChanged = true;
                        % if parameter has reached its goal or has exceeded it
                        % ...depends on currentValue never moving away from the goalValue
                        % current == start | sign(current - goal) == sign(current - start)
                        %if  t.shapingValues.currentValue == t.shapingValues.goalValue |sign(t.shapingValues.currentValue - t.shapingValues.goalValue) == sign(t.shapingValues.currentValue - t.shapingValues.goalValue)
                        % force graduation to the next step
                        % how should we do this? need to influence graduation in the
                        % trainingStep ...
                        %end
                        %instead use a criteria that checks the parameter in question:
                        %parameterThresholdCriterion('.stimDetails.targetContrast','<',0.1)
                    end
                otherwise
                    error('not an acceptable shaping method');
            end

            %% set value

            if parameterChanged
                switch t.shapedParameter
                    case {'positionalHint','flankerContrast','xPosNoise'}
                        t.(t.shapedParameter) = t.shapingValues.currentValue;
                    case 'stdGaussMask'
                        t.stdGaussMask=t.shapingValues.currentValue;
                        t=decache(t);
                        t=cache(t);
                    case 'targetContrast'
                        t=setTargetContrast(t,t.shapingValues.currentValue);
                    otherwise
                        error('that parameter cannot be shaped');
                end
            else
                newTM=0;
            end

            %move to quickloop, error check it
            if 0



                parameters.shapedParameter='flankerContrast';
                parameters.shapingMethod='linearChangeAtCriteria';
                parameters.shapingValues.numSteps=int8(9);
                parameters.shapingValues.performanceLevel=[0.9];
                parameters.shapingValues.numTrials=int8([2]);
                parameters.shapingValues.startValue=0.1;
                parameters.shapingValues.currentValue=0.1;
                parameters.shapingValues.goalValue=1;


                %     params.numSteps = 6;
                %     params.performanceLevel = 0.75;
                %     params.numTrials = [100];
                %     params.startValue = 0.2;
                %     params.currentValue = params.startValue;
                %     params.goalValue = 0.1;
                %     t.shapingValues = params;
                %     shapedParameter=
                %     shapingMethod=
                %     shapingValues=


                t.shapingMethod = 'exponentialParameterAtConstantPerformance'
                params.performanceLevel = 0.75;
                params.startValue = 0.2;
                params.currentValue = params.startValue;
                params.goalValue = 0.1;
                params.tau = 1/4;
                params.fractionalSmoothingWidth = 1/10;
                params.percentCI = 0.95;
                t.shapingValues = params;
                t.positionalHint = t.shapingValues.currentValue; % set the shaped parameter to start value

                t.shapingMethod = 'geometricRatioAtCriteria'
                params.ratio = 4/5;
                params.performanceLevel = 0.75;
                params.numTrials = [100];
                params.startValue = 0.2;
                params.currentValue = params.startValue;
                params.goalValue = 0.1;
                params.fractionalParameterThreshold = 0.05;
                t.shapingValues = params;
                t.positionalHint = t.shapingValues.currentValue;

                t.shapingMethod = 'linearChangeAtCriteria'
                params.numSteps = 6;
                params.performanceLevel = 0.75;
                params.numTrials = [100];
                params.startValue = 0.2;
                params.currentValue = params.startValue;
                params.goalValue = 0.1;
                t.shapingValues = params;
                t.positionalHint = t.shapingValues.currentValue;


            end
        end
        
        function isCached=stimIsCached(s)
            %method to determine if it is cached

            if ~isempty(s.cache) && size(s.cache.mask,1)>0
                isCached=1;
            else
                isCached=0;
            end

            % if size(s.cache.mask,1)>0
            %     isCached=1;
            %         
            % %     %confirm all there
            % %     if size(s.goRightStim,1)>0 & size(s.goLeftStim,1)>0 & size(s.flankerStim,1)>0
            % %         %okay
            % %     else
            % %         error('partially inflated stim')
            % %     end
            %     
            % else
            %     isCached=0;
            % end

        end
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case 'freeDrinks'
                        out=1;
                    case 'nAFC' %was old standard, now the phased one mimicks it
                        out=1;
                    case 'promptedNAFC' %used for eyeDevelopment
                        out=0;  % we don't use this anymore, but should switch to nAFC with delayManager 
                    case 'phasednAFC' %fans addition, new format, but same idea as NAFC
                        out=0;  % everything uses the phased version now... its just called normal nAFC
                    case {'autopilot','reinforcedAutopilot'}
                        out=1; % useful for physiology
                    case 'goNoGo'
                        out=1;
                    case 'cuedGoNoGo'
                        out=1; %can display flanks alone in which case appropriate response is "noGo"
                    otherwise % useful for headfixed
                        out=0;
                end
            else
                error('need a trialManager object')
            end
        end
        
        function out=texsCorrespondToThisWindow(s,w)
            %method to determine if tex is cached appropriate in this window, 
            %PTB expert mode

            out=false;

            if ismember({'textures'},fields(s.cache))

                allWindows=Screen('Windows');
                texIDsThere=allWindows(find(Screen(allWindows,'WindowKind')==-1));

                allTexsRequired=unique(s.cache.textures);
                allTexsRequired=allTexsRequired(~isnan(allTexsRequired));

                if all(ismember(allTexsRequired,texIDsThere));
                    out=true;
                end
            else
                error('can''t find texture field!')
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

            % retval=quality.passedQualityTest && isLastChunkInTrial;


            if length(quality.passedQualityTest)>1
                %if many chunks, the last one might have no frames or spikes, but the
                %analysis should still complete if the the previous chunks are all
                %good. to be very thourough, a stim manager may wish to confirm that
                %the reason for last chunk failing, if it did, is an acceptable reason.
                qualityOK=all(quality.passedQualityTest(1:end-1));
            else
                qualityOK=quality.passedQualityTest;
            end

            warning('forcing quality to be true')
            qualityOK=true;

            retval=qualityOK && ...
                (isLastChunkInTrial || enableChunkedPhysAnalysis(sm)) &&...    
                (overwriteAll || ~analysisExists);

        end % end function

    end
    
end


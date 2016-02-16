classdef ifFeatureGoRightWithTwoFlankTrialManager
    
    properties
        maxWidth=[];
        maxHeight=[];
        scaleFactor=[];
        interTrialLuminance=[];

        goRightOrientations = [];
        goLeftOrientations = [];
        flankerOrientations = [];
        distractorOrientations = [];
        distractorFlankerOrientations = [];
        topYokedToBottomFlankerOrientation =1;

        goRightContrast = [];
        goLeftContrast = [];
        flankerContrast = [];
        distractorContrast = 0;
        distractorFlankerContrast = 0;
        topYokedToBottomFlankerContrast =1;

        phase=0;
        flankerYokedToTargetPhase =0;

        pixPerCycs = 64; %if empty inflate fails
        stdGaussMask = 0;
        stdsPerPatch=4; %this is an even number that is very reasonable fill of square--has been hardcoded until 8/21/07. Before that, it was always 4.
        thresh = 0.001;
        gratingType='square';
        gaborNormalizeMethod = 'normalizeVertical';

        xPositionPercent = 0;
        targetYPosPct = 0;
        flankerOffset = 0;
        positionalHint=0; %fraction of screen hinted.
        xPosNoise=0; %
        yPosNoise=0; %
        cuePercentTargetEcc = 0;

        framesTargetOnOff=int8([1 100]);
        framesFlankerOnOff=int8([1 100]);

        typeOfLUT = 'linearizedDefault';
        rangeOfMonitorLinearized=[0 1];
        mean = 0;
        cueLum=0;
        cueSize=1;

        displayTargetAndDistractor=0;
        distractorYokedToTarget=1;

        distractorFlankerYokedToTargetFlanker = 1;
        fractionNoFlanks=[];
        toggleStim = 0;
        persistFlankersDuringToggle=[];

        msPenaltyFlashDuration=[];
        numPenaltyFlashes=[];
        maxDiscriminandumSecs=[];
        advancedOnRequestEnd=[];
        interTrialDimmingFraction=[];

        renderMode='ratrixGeneral';

        shapedParameter=[];
        shapingMethod=[];

        shapingValues=[];
        LUT=[];
        cache = [];
    end
    
    methods
        function tm=ifFeatureGoRightWithTwoFlankTrialManager(varargin)
            % ||ifFeatureGoRightWithTwoFlankTrialManager||  class constructor.
            % This is the first merging of the stimulus manager and the trial manager
            % PMM TVN 8/22/2007 first merge, quick for calibration
            % PMM Y.Z 12/05/2007 second merge, better for calcStim

            %t=ifFeatureGoRightWithTwoFlankTrialManager()

            switch nargin
                case 0
                    %
                    % orientations in radians , these a distributions of possible orientations
                    % mean, cueLum, cueSize, contrast, yPositionPercent, xPositionPercent normalized (0 <= value <= 1)
                    % stdGaussMask is the std dev of the enveloping gaussian, in normalized  units of the vertical height of the stimulus image
                    % thresh is in normalized luminance units, the value below which the stim should not appear
                    % cuePercentTargetEcc is an vestigal variable not used
                    t=s;

                    super.msFlushDuration=0;
                    super.rewardSizeULorMS=0;
                    super.msMinimumPokeDuration=0;
                    super.msMinimumClearDuration=0;
                    super.soundMgr=soundManager();
                    super.msPenalty=0;
                    super.msRewardSoundDuration=0;
                    super.reinforcementManager=reinforcementManager();
                    super.description='';

                    % These are the old nAFC fields
                    super.requestRewardSizeULorMS=0;
                    %         t.percentCorrectionTrials=0;
                    super.msResponseTimeLimit=0;
                    super.pokeToRequestStim=0;
                    super.maintainPokeToMaintainStim=0;
                    super.msMaximumStimPresentationDuration=0;
                    super.maximumNumberStimPresentations=0;
                    super.doMask=0;

                    % a=trialManager();
                    %    t = class(t,'nAFC',a);

                    % trialManager data members that this method depends on:
                    super.station  = 0;    %the station where this trial is running
                    super.window   = 1 ;   %pointer to target PTB window (should already be open)
                    super.ifi      = 0;    %inter-frame-interval for PTB window in seconds (measured when window was opened)
                    super.manualOn = 1;    %allow keyboard responses, quitting, pausing, rewarding, and manual poke indications
                    super.timingCheckPct = 0;      %percent of allowable frametime error before apparently dropped frame is reported
                    super.numFrameDropReports =1000;   %number of frame drops to keep detailed records of for this trial
                    super.percentCorrectionTrials  =0;    %probability that if this trial is incorrect that it will be repeated until correct
                    %note this needs to be moved here from wherever it currently is


                    t.cache.goRightStim=[];
                    t.cache.goLeftStim = [];
                    t.cache.flankerStim=[];
                    t.cache.distractorStim = [];
                    t.cache.distractorFlankerStim=[];

                    t.calib.frame=0;
                    %         t.calib.framesPerCycleRequested=0;
                    %         t.calib.framesPerCycleUsed=0;
                    %         t.calib.contrastNormalizationPerOrientation=[];
                    t.calib.method='sweepAllPhasesPerFlankTargetContext';
                    t.calib.data=[];

                    t.stimDetails=[];%per trial info will go here

                    size(fields(t))

                    t = class(t,'ifFeatureGoRightWithTwoFlankTrialManager',trialManager());
                    %ToDo: t = class(t,'ifFeatureGoRightWithTwoFlankTrialManager',nAFC(super.xxx,super.xxx));

                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'ifFeatureGoRightWithTwoFlankTrialManager'))
                        t = varargin{1};
                    else
                        error('Input argument is not a ifFeatureGoRightWithTwoFlankTrialManager object')
                    end
                case 2
                    if isa(varargin{1}, 'struct')
                        parameterStructure = varargin{1};
                    else
                        error('expecting first argument to be a parameterStructure that will be checked after blessing')
                    end

                    if isa(varargin{2}, 'struct')
                        super = varargin{2};
                    else
                        error('expecting second argument to be a structure that will be passed to the appropriate super class')
                    end

                    %ToDo: reflect new trialManager super class which probably owns old nAFC terms

                    t = errorCheck(ifFeatureGoRightWithTwoFlankTrialManager,parameterStructure);

                    rm=parameterStructure.rm;
                    parameterStructure = rmfield(parameterStructure, 'rm')
                    switch rm.type
                        case 'rewardNcorrectInARow'
                            requestRewardSizeULorMS=0;
                            requestMode='first';
                            msPuff=0;
                            %rewardNthCorrect,requestRewardSizeULorMS,requestMode,msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff
                            reinforcementMgr=rewardNcorrectInARow(rm.rewardNthCorrect,requestRewardSizeULorMS,requestMode,rm.msPenalty,rm.fractionOpenTimeSoundIsOn,rm.fractionPenaltySoundIsOn,rm.scalar,msPuff)
                            %reinforcementMgr=rewardNcorrectInARow(rm.rewardNthCorrect, rm.msPenalty,rm.fractionOpenTimeSoundIsOn,rm.fractionPenaltySoundIsOn, rm.scalar);
                        otherwise
                            error ('Not an allowed reinforment manager type')
                    end



                    parameterStructure
                    default=ifFeatureGoRightWithTwoFlankTrialManager;

                    paramField=fields(parameterStructure);
                    paramField{end+1}='trialManager' %add in the super class field which does not exist yet for the parameters
                    defaultField=fields(default)

                    hasAllFieldsInThatOrder(paramField,defaultField);

                    disp(sprintf('parameterStructure has %d fields and the default constructor has %d fields', size(paramField,1), size(defaultField,1)))

                    eyeController=[];
                    customDescription=super.description; %'old funky hybrid but works for cal';
                    frameDropCorner={'off'};
                    dropFrames=false;
                    displayMethod='ptb';
                    requestPorts='center';
                    saveDetailedFramedrops=false;
                    delayManager=[];
                    responseWindowMs=[];
                    showText=true;
                    t = class(parameterStructure,'ifFeatureGoRightWithTwoFlankTrialManager',trialManager(...
                        super.soundMgr,reinforcementMgr,eyeController,customDescription,frameDropCorner,dropFrames,displayMethod,requestPorts,saveDetailedFramedrops,delayManager,responseWindowMs,showText)...
                        );

                    %%Note: calcStim of this class requires some util functions:
                    %     function
                    %     out=getFeaturePatchStim(patchX,patchY,type,variableParams,staticParams,extraParams)
                    % As well as some inflate functions...maybe they should all be
                    % methods...PMM

                otherwise
                    error('Wrong number of input arguments')
            end


            %t = errorCheck(t);  %maybe get rid of this
            % t=setSuper(t,?);
            %t=setSuper(t,t.trialManager(?  %what's this?

            t=getCalibrationSettings(t,'uncalibrated');
            t = setCalibrationModeOn(t, 0);
            %t=inflate(t); % Note: The LUT's and the cache will now appear in the trialmanager...
            disp(sprintf('linearizing monitor in range from %s to %s', num2str(t.rangeOfMonitorLinearized(1)), num2str(t.rangeOfMonitorLinearized(2))))
            tm=fillLUT(t,t.typeOfLUT,t.rangeOfMonitorLinearized,0);

            disp(sprintf('sucessfully created: %s', class(tm)))

        end
        
        function fpb = acceptableNumberOfFramesPerBatch(trialManager)

            fpb = 10; % this is arbitrarily determined based on RAM
        end
        
        function fLum=addToLumStruct(trialManager, fLum, frameDetails, frameIndices, luminanceData)

            if isempty(fLum)
                fLum.targetLuminance = [];
                fLum.frameIndices= [];
                fLum.targetPhase = [];
                fLum.targetOrientation = [];
                fLum.targetContrast = [];
                fLum.flankerContrast = [];
                fLum.flankerOrientation = [];
                fLum.flankerPhase = [];
                fLum.deviation = [];
                fLum.xPositionPercent = [];
                fLum.yPositionPercent = [];
                fLum.stdGaussMask = [];
                fLum.mean = [];
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            temp = repmat(frameIndices, [size(luminanceData,2),1]);
            frameIndices = reshape(temp, 1,numel(temp)); % remapping the frame indices to repeat the number of measurement times

            luminanceData = reshape(luminanceData', 1, numel(luminanceData)); % remapping luminance data

            temp = [frameDetails{frameIndices}];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fLum.frameIndices= [fLum.frameIndices, frameIndices];
            fLum.targetPhase = [fLum.targetPhase, [temp.targetPhase]];
            fLum.targetOrientation = [fLum.targetOrientation,  [temp.targetOrientation]];
            fLum.targetLuminance = [fLum.targetLuminance,  luminanceData];
            fLum.targetContrast = [fLum.targetContrast, [temp.targetContrast]];
            fLum.flankerContrast = [fLum.flankerContrast, [temp.flankerContrast]];
            fLum.flankerOrientation = [fLum.flankerOrientation, [temp.flankerOrientation]];
            fLum.flankerPhase = [fLum.flankerPhase, [temp.flankerPhase]];
            fLum.deviation = [fLum.deviation, [temp.deviation]];
            fLum.xPositionPercent = [fLum.xPositionPercent, [temp.xPositionPercent]];
            fLum.yPositionPercent = [fLum.yPositionPercent, [temp.yPositionPercent]];
            fLum.stdGaussMask = [fLum.stdGaussMask, [temp.stdGaussMask]];
            fLum.mean = [fLum.mean, double([temp.mean])];
        end
        
        function [trialManager, updateTM, out, LUT, scaleFactor, type, targetPorts, distractorPorts, details, interTrialLuminance] = ...
    calcStim(trialManager,trialManagerClass,frameRate,responsePorts,totalPorts,width,height,trialRecords,compiledRecords,arduinoCONN)
            %this makes a target that has feature to go right or left
            %this is a discrimination paradigm
            %a detection paradigm follows if the left stims have 0 contrast
            %flankers above and below target, total of three stims

            stimulus=trialManager;
            % setSeed(stimulus, fromClock); this never gets called! use calStimBeta
            updateTM=0;

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

            %interTrialLuminance = getInterTrialLuminance(stimulus);
            interTrialLuminance = trialManager.interTrialLuminance;

            %LUT=getLUT(stimulus);
            LUT=trialManager.LUT;
            details.LUT=LUT;  % in future, consider saving a LUT id?
            %interTrialLuminance = 0.5;

            %edf: 11.15.06 realized we didn't have correction trials!

            details.pctCorrectionTrials=0.5; % need to change this to be passed in from trial manager

            details.maxCorrectForceSwitch=0;  % make sure this gets defined even if no trial records or free drinks

            if ~isempty(trialRecords)
                lastResponse=find(trialRecords(end).response);
                lastCorrect=trialRecords(end).correct;
                lastWasCorrection=trialRecords(end).correctionTrial;
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

            %     case 'nAFC'
                case 'ifFeatureGoRightWithTwoFlankTrialManager'  %note: this should be replaced by something like phasedNAFC

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
                        % correlations should be handled outside of calcStim
                        %[targetPorts hadToResample]=getSameLimitedResponsePort(responsePorts,stimulus.maxCorrectOnSameSide,trialRecords);
                        %details.maxCorrectForceSwitch=hadToResample;
                        targetPorts=responsePorts(ceil(rand*length(responsePorts)));
                        %old random selection is now inside helper function -pmm  
                    end


                    distractorPorts=setdiff(responsePorts,targetPorts);
            %         targetPorts
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
                    calibStim=logical(trialManager.calib.calibrationModeOn);
            %     calibStim
                if ~calibStim
                    %set variables for random selections
                    a=Randi(size(stimulus.goRightOrientations,2));
                    b=Randi(size(stimulus.goLeftOrientations,2));
                    c=Randi(size(stimulus.flankerOrientations,2));

                    d=Randi(size(stimulus.goRightContrast,2));      %
                    e=Randi(size(stimulus.goLeftContrast,2));
                    f=Randi(size(stimulus.flankerContrast,2));
                    h=Randi(size(stimulus.flankerOffset,2));
                    p=Randi(size(stimulus.phase,2));
            % note: lacks the parameters that calcStimBeta has

                else %calibrationModeOn
                    %use frame to set values a-h , p
                        [a b c z d e f g h p pD pF] = selectStimulusParameters(trialManager);

                    %override side corrrect
                    responseIsLeft=-1; % on the right
                    details.correctResponseIsLeft=responseIsLeft;
                end


                %CONTRAST AND ORIENTATION
                if responseIsLeft==1
                    details.targetContrast=stimulus.goLeftContrast(e);
                    details.targetOrientation=stimulus.goLeftOrientations(a);
                elseif responseIsLeft==-1
                    details.targetContrast=stimulus.goRightContrast(d);
                    details.targetOrientation=stimulus.goRightOrientations(a);
                else
                    error('Invalid response side value. responseIsLeft must be -1 or 1.')
                end

               details.flankerContrast=stimulus.flankerContrast(f);
               details.flankerOrientation= stimulus.flankerOrientations(c);

               %FUTURE CHECKS FOR FLANKERS
                if stimulus.topYokedToBottomFlankerContrast
                    %details.topFlankerOrient=details.flankerOriention
                    %details.bottomFlankerOrient=details.flankerOriention;
                else
                    %draw from distribution again
                    error('currently undefined; topYokedToBottomFlankerContrast must be 1');
                     c=Randi(size(stimulus.flankerOrientations,2)); %Can't use previous static c because you have to resample in order to be unique.
                    details.bottomFlankerOrient=stimulus.flankerOrientations(c);  
                end

                if stimulus.topYokedToBottomFlankerOrientation
                    %currently do nothing
                else
                    error('currently undefined; topYokedToBottomFlankerOreintation must be 1');
                end

                if stimulus.flankerYokedToTargetPhase

                    details.flankerPhase = stimulus.phase(p);
                    details.targetPhase = stimulus.phase(p);  
                else
                    details.targetPhase = stimulus.phase(p);
                    details.flankerPhase = stimulus.phase(pF);
                    warning('this only works for calibrationMode');
                    % will be okay in calcStimBeta or beyond
                end
                %SPATIAL PARAMS
                %ecc=stimulus.eccentricity/2;
                xPosPct=stimulus.xPositionPercent;
                dev=stimulus.flankerOffset(h)*stimulus.stdGaussMask;
                details.deviation=dev;    %fractional devitation
            %     details.devPix=dev*getMaxHeight(stimulus); %pixel deviation
            %     details.patchX1=ceil(getMaxHeight(stimulus)*stimulus.stdGaussMask*stimulus.stdsPerPatch);
                details.devPix=dev*trialManager.maxHeight; %pixel deviation
                details.patchX1=ceil(trialManager.maxHeight*stimulus.stdGaussMask*stimulus.stdsPerPatch);
                details.patchX2=size(trialManager.cache.goLeftStim,2);

                details.xPositionPercent=stimulus.xPositionPercent; %stored
                details.yPositionPercent=stimulus.targetYPosPct; %stored

                %TEMPORAL PARAMS
                details.requestedNumberStimframes=type;

                %GRATING PARAMS
                details.stdGaussMask=stimulus.stdGaussMask;
                %details.stdGaussMaskPix=stimulus.stdGaussMask*ceil(getMaxHeight(stimulus));
                details.stdGaussMaskPix=stimulus.stdGaussMask*ceil(trialManager.maxHeight);
                radius=stimulus.stdGaussMask;
                details.pixPerCycs=stimulus.pixPerCycs;
                %details.phase= rand*2*pi;  %all phases yoked together



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

                  numPatchesInserted=3; 
                  szY=size(trialManager.cache.goRightStim,1);
                  szX=size(trialManager.cache.goRightStim,2);

                  pos=round...
                  ...%yPosPct                      yPosPct                    xPosPct                   xPosPct
                ([ stimulus.targetYPosPct       stimulus.targetYPosPct        xPosPct                   xPosPct;...                   %target
                   stimulus.targetYPosPct+dev   stimulus.targetYPosPct+dev    xPosPct                   xPosPct;...                   %top
                   stimulus.targetYPosPct-dev   stimulus.targetYPosPct-dev    xPosPct                   xPosPct]...                   %bottom
                  .* repmat([ height            height                        width         width],numPatchesInserted,1))...          %convert to pixel vals
                  -  repmat([ floor(szY/2)      -(ceil(szY/2)-1 )             floor(szX/2) -(ceil(szX/2)-1)],numPatchesInserted,1); %account for patch size

                  if any(any((pos(:,1:2)<1) | (pos(:,1:2)>height) | (pos(:,3:4)<1) | (pos(:,3:4)>width)))
                      width
                      height
                      pos
                      error('At least one image patch is going to be off the screen.  Make patches smaller or closer together.')
                  end

                  try

                  %stim class is inherited from flankstim patch
                  %just check flankerStim, assume others are same
                  if isinteger(trialManager.cache.flankerStim) 
                    details.mean=stimulus.mean*intmax(class(trialManager.cache.flankerStim));
                  elseif isfloat(trialManager.cache.flankerStim)
                      details.mean=stimulus.mean; %keep as float
                  else
                      error('stim patches must be floats or integers')
                  end
                  stim=details.mean(ones(height,width,3,'uint8')); %the unit8 just makes it faster, it does not influence the clas of stim, rather the class of details determines that




                      %PRESTIM  - flankers first
                      stim(:,:,1)=insertPatch(stim(:,:,1),pos(2,:),trialManager.cache.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.flankerOrientation,details.flankerPhase, details.mean,details.flankerContrast);
                      stim(:,:,1)=insertPatch(stim(:,:,1),pos(3,:),trialManager.cache.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.flankerOrientation,details.flankerPhase, details.mean,details.flankerContrast);

                      %MAIN STIM this could be a for loop except variables are stored
                      %as named types...
                      if responseIsLeft==1       % choose TARGET stim patch from LEFT candidates
                          stim(:,:,2)=insertPatch(stim(:,:,2),pos(1,:),trialManager.cache.goLeftStim, stimulus.goLeftOrientations, stimulus.phase, details.targetOrientation, details.targetPhase, details.mean,details.targetContrast);  
                      elseif responseIsLeft==-1 %% choose TARGET stim patch from RIGHT candidates
                          stim(:,:,2)=insertPatch(stim(:,:,2),pos(1,:),trialManager.cache.goRightStim,stimulus.goRightOrientations,stimulus.phase, details.targetOrientation, details.targetPhase, details.mean,details.targetContrast);
                      else
                          error('Invalid response side value. responseIsLeft must be -1 or 1.')
                      end   
                      %and flankers
                      stim(:,:,2)=insertPatch(stim(:,:,2),pos(2,:),trialManager.cache.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.flankerOrientation, details.flankerPhase, details.mean,details.flankerContrast);
                      stim(:,:,2)=insertPatch(stim(:,:,2),pos(3,:),trialManager.cache.flankerStim,stimulus.flankerOrientations, stimulus.phase, details.flankerOrientation, details.flankerPhase, details.mean,details.flankerContrast);


                  %BEFORE THE FUNCTION CALL
            %           %PRESTIM  - flankers first
            %           i=2;
            %           orientInd=find(stimulus.flankerOrientations==details.flankerOrientation);  % choose top(check?) stim patch
            %           stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),1)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),1)+(trialManager.cache.flankerStim(:,:,orientInd)-details.mean)*details.flankerContrast;
            % 
            %           i=3;
            %           orientInd=find(stimulus.flankerOrientations==details.flankerOrientation);  % choose bottom(check?) stim patch
            %           stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),1)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),1)+(trialManager.cache.flankerStim(:,:,orientInd)-details.mean)*details.flankerContrast;
            % 
            %           %MAIN STIM this could be a for loop except variables are stored as named types...
            % 
            %           i=1;   %the target
            %           if responseIsLeft==1
            %               orientInd=find(stimulus.goLeftOrientations==details.targetOrientation);  % choose TARGET stim patch from LEFT candidates
            %               stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(trialManager.cache.goLeftStim(:,:,orientInd)-details.mean).*details.targetContrast;
            %           elseif responseIsLeft==-1
            %               orientInd=find(stimulus.goRightOrientations==details.targetOrientation);  % choose TARGET stim patch from RIGHT candidates
            %               stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(trialManager.cache.goRightStim(:,:,orientInd)-details.mean).*details.targetContrast;
            %           else
            %               error('Invalid response side value. responseIsLeft must be -1 or 1.')
            %           end
            % 
            %           i=2;
            %           orientInd=find(stimulus.flankerOrientations==details.flankerOrientation);  % choose top(check?) stim patch
            %           stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(trialManager.cache.flankerStim(:,:,orientInd)-details.mean)*details.flankerContrast;
            % 
            %           i=3;
            %           orientInd=find(stimulus.flankerOrientations==details.flankerOrientation);  % choose bottom(check?) stim patch
            %           stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(trialManager.cache.flankerStim(:,:,orientInd)-details.mean)*details.flankerContrast;



            %OLD EXAMPLE FROM 6 gratings  -- things changed since then: details.mean instead of stimulus.mean
            %       i=i+1;         
            %       orientInd=find(stimulus.goLeftOrientations==details.distractorOrientation);  % choose DISTRACTOR stim patch
            %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(stimulus.distractorStim(:,:,orientInd)-stimulus.mean).*details.distractorContrast;
            % 
            %       i=i+1;
            %       orientInd=find(stimulus.flankerOrientations==details.rightFlankerOrient);  % choose RIGHT stim patch
            %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(trialManager.cache.flankerStim(:,:,orientInd)-stimulus.mean)*details.flankerContrast;
            %       i=i+1;
            %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(trialManager.cache.flankerStim(:,:,orientInd)-stimulus.mean)*details.flankerContrast;
            %       
            %       i=i+1;
            %       orientInd=find(stimulus.flankerOrientations==details.leftFlankerOrient);  % choose LEFT stim patch
            %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(trialManager.cache.flankerStim(:,:,orientInd)-stimulus.mean)*details.flankerContrast;
            %       i=i+1;
            %       stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)=stim(pos(i,1):pos(i,2),pos(i,3):pos(i,4),2)+(trialManager.cache.flankerStim(:,:,orientInd)-stimulus.mean)*details.flankerContrast;
            %        

                  %RENDER CUE - side cue not used, only fixation dot
                  %stim(cueRect(1)-stimulus.cueSize:cueRect(2)+stimulus.cueSize,cueRect(3)-stimulus.cueSize:cueRect(4)+stimulus.cueSize,1:3)=1-stimulus.cueLum; %edf added to make cue bigger and more contrasty
                  %stim(cueRect(1):cueRect(2),cueRect(3):cueRect(4),1:3)=stimulus.cueLum;
                  stim(height/2-stimulus.cueSize:height/2+stimulus.cueSize,width/2-stimulus.cueSize:width/2+stimulus.cueSize)=stimulus.cueLum;

                  %BW pix in corners for imagesc
                  stim(1)=0; stim(2)=1;




                if strcmp(type,'trigger') && details.toggleStim==1
                    %only send 2 frames if in toggle stim mode
                    out=stim(:,:,end-1:end);
                else
                    %send all frames if in normal mode
                    out=stim;
                end

                %grayscale sweep for viewing purposes
                drawColorBar=1;  %**add as a parameter in stimManager object
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
                      %disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                      rethrow(ex);
                  end
      
        end
      
        function stim=insertPatch(stim,pos,featureVideo,featureOptions1, featureOptions2,chosenFeature1, chosenFeature2 ,mean,contrast)
        
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
        end
        
        function [t updateTM stimDetails stimSpec targetPorts details] = calcStimBeta(t,ifi,targetPorts,responsePorts,width,height,trialRecords)

            if ~stimIsCached(t)
                t=inflate(t);
                setSeed(t, 'seedFromClock');
                updateTM=1;
            else
                updateTM=0;
            end

            a=rand('seed');
            b=randn('seed');
            details.randomMethod='seedFromClock';
            details.randomSeed=[a(end) b(end)]; %if using twister method, this single number is pretty meaningless

            %% choose ratrix standard verse PTB method
            %this should be passed in during the dynamic mode
            %firstTimeThisTrial=getNewTrialParameters 
            %phase='discriminandum'; %{'session','trial','discriminandum','reward','penalty','final'}



            %% start main

            % choose parameters for this trial only 
            firstTimeThisTrial=1;
            if firstTimeThisTrial

            %% CORRECT RESPONSE

                targetPorts=targetPorts; %someone else should tell me what this is! or I call the correlation manager?
                %[targetPorts hadToResample]=getSameLimitedResponsePort(responsePorts,t.maxCorrectOnSameSide,trialRecords)
                %stimDetails.maxCorrectForceSwitch=hadToResample;
                %targetPorts=responsePorts(ceil(rand*length(responsePorts)));

            %     stimDetails.correctionTrial=correctionTrial;  %Todo: Can I get rid of this?
            %     if stimDetails.correctionTrial
            %     end

                if targetPorts==1
                    responseIsLeft=1;
                elseif targetPorts==3
                    responseIsLeft=-1; % on the right
                else
                    targetPorts
                    error('Targetports is inappropriate.  Stimulus is defined for 3 ports with one correct L/R answer')
                end
                stimDetails.correctResponseIsLeft=responseIsLeft;
            %% Shaped Params

            if ~isempty(t.shapedParameter)
               [parameterChanged t]  = shapeParameter(t, trialRecords)
               if parameterChanged
                    updateTM = 1;
               end
            end


            %% set params

                    calibStim=logical(t.calib.calibrationModeOn);
                    if ~calibStim
                        %set variables for random selections
                        a=Randi(size(t.goRightOrientations,2));
                        b=Randi(size(t.goLeftOrientations,2));
                        c=Randi(size(t.flankerOrientations,2));
                        z=Randi(size(t.distractorOrientations,2));
                        d=Randi(size(t.goRightContrast,2));      %
                        e=Randi(size(t.goLeftContrast,2));
                        f=Randi(size(t.flankerContrast,2));
                        g=Randi(size(t.distractorContrast,2));
                        h=Randi(size(t.flankerOffset,2));
                        p=Randi(size(t.phase,2));
                        pD=Randi(size(t.phase,2));
                        pF=Randi(size(t.phase,2));
                    else %calibrationModeOn
                        %use frame to set values a-h , p
                        [a b c z d e f g h p pD pF] = selectStimulusParameters(t);
                        %override side corrrect
                        responseIsLeft=-1; % on the right
                        stimDetails.correctResponseIsLeft=responseIsLeft;
                    end

                    %CONTRAST AND ORIENTATION
                    if responseIsLeft==1
                        stimDetails.targetContrast=t.goLeftContrast(e);
                        stimDetails.targetOrientation=t.goLeftOrientations(a);
                    elseif responseIsLeft==-1
                        stimDetails.targetContrast=t.goRightContrast(d);
                        stimDetails.targetOrientation=t.goRightOrientations(a);
                    else
                        error('Invalid response side value. responseIsLeft must be -1 or 1.')
                    end

                    stimDetails.distractorContrast=t.distractorContrast((g));
                    stimDetails.flankerContrast=t.flankerContrast((f));
                    stimDetails.flankerOrientation= t.flankerOrientations((c));
                    stimDetails.distratorOrientation = stimDetails.targetOrientation;


            %% CHECKS FOR FLANKERS
                    if t.topYokedToBottomFlankerContrast
                        %stimDetails.topFlankerOrient=stimDetails.flankerOriention
                        %stimDetails.bottomFlankerOrient=stimDetails.flankerOriention;
                    else
                        %draw from distribution again
                        error('currently undefined; topYokedToBottomFlankerContrast must be 1');
                        c=Randi(size(t.flankerOrientations,2)); %Can't use c because you have to resample in order to be unique.
                        stimDetails.bottomFlankerOrient=t.flankerOrientations((c));
                    end

                    if t.topYokedToBottomFlankerOrientation
                        %currently do nothing
                    else
                        error('currently undefined; topYokedToBottomFlankerOreintation must be 1');
                    end

                    if t.flankerYokedToTargetPhase  
                        stimDetails.flankerPhase = t.phase(p);
                        stimDetails.targetPhase = t.phase(p);
                    else
                        stimDetails.targetPhase = t.phase(p);
                        stimDetails.flankerPhase = t.phase(pF);
                    end

                    if t.distractorYokedToTarget
                        stimDetails.distractorPhase = stimDetails.targetPhase;
                        stimDetails.distractorOrientation = stimDetails.targetOrientation;
                    else
                        stimDetails.distractorPhase = t.phase(pD);
                        stimDetails.distractorOrientation = t.distractorOrientations(z);
                    end

                    if t.distractorFlankerYokedToTargetFlanker
                        stimDetails.distractorFlankerContrast = stimDetails.flankerContrast;
                        stimDetails.distractorFlankerOrientation = stimDetails.flankerOrientation;
                        stimDetails.distractorFlankerPhase = stimDetails.flankerPhase;
                    else
                        stimDetails.distractorFlankerContrast = stimDetails.flankerContrast;
                        stimDetails.distractorFlankerOrientation = t.flankerOrientations((c));
                        stimDetails.distractorFlankerPhase = t.phase(pF);
                    end

                    if t.fractionNoFlanks>rand
                        %set all flanker contrasts to be zero for a fraction of the trials
                        stimDetails.flankerContrast=0;
                        stimDetails.distractorFlankerContrast=0;
                        stimDetails.hasFlanks=0;
                    else
                        if stimDetails.flankerContrast>0 || stimDetails.distractorFlankerContrast>0
                            stimDetails.hasFlanks=1;
                        else
                            stimDetails.hasFlanks=0;
                        end
                    end

                    stimDetails.toggleStim=t.toggleStim;



            %% calculate positions

                    %choose screen size to compute stimulus at 
                    if t.maxHeight==height & t.maxWidth==width
                    height=t.maxHeight;
                    width=t.maxWidth;
                    else
                        height=height
                        width=width
                        t.maxHeight
                        t.maxWidth
                        error ('this monitor doesn''t have the right screen size for the trialManager')
                        %height=getMaxHeight(t)
                    end

                    %precompute short variables
                    ctr=[height/2 width/2 ]; 
                    xPosPct=t.xPositionPercent;
                    devY = t.flankerOffset((h))*t.stdGaussMask;
                    radius=t.stdGaussMask;
                    szY=size(t.cache.mask,1);
                    szX=size(t.cache.mask,2);
                    fracSizeX=szX/width;
                    fracSizeY=szY/height;
                    display ('calculating stimulus patch positions, which may have noise');
                    stimFit = 0;
                    resampleCounter = 0;

                    %these would be redundant with a deflated(t)
                    stimDetails.xPositionPercent=t.xPositionPercent; %stored
                    stimDetails.yPositionPercent=t.targetYPosPct; %stored
                    stimDetails.framesTargetOnOff=t.framesTargetOnOff;
                    stimDetails.framesFlankerOnOff=t.framesFlankerOnOff;
                    stimDetails.stdGaussMask=t.stdGaussMask;
                    stimDetails.pixPerCycs=t.pixPerCycs;
                    stimDetails.gratingType=t.gratingType;

                    %some computation required
                    stimDetails.deviation = devY;    %fractional devitation
                    stimDetails.devPix=devY*height; %pixel deviation
                    stimDetails.patchX1=ceil(height*t.stdGaussMask*t.stdsPerPatch);
                    stimDetails.patchX2=size(t.cache.mask,2);
                    stimDetails.stdGaussMaskPix=t.stdGaussMask*ceil(height);

                    while stimFit == 0
                        %%%%%%%%%% CREATE CENTERS %%%%%%%%%%%%%%
                        if t.displayTargetAndDistractor ==0
                            numPatchesInserted=3;
                            centers =...
                                ...%yPosPct                      yPosPct       xPosPct                   xPosPct
                                [ t.targetYPosPct       t.targetYPosPct        xPosPct                   xPosPct;...                   %target
                                t.targetYPosPct+devY   t.targetYPosPct+devY    xPosPct                   xPosPct;...                   %top
                                t.targetYPosPct-devY   t.targetYPosPct-devY    xPosPct                   xPosPct];                     %bottom

                        elseif t.displayTargetAndDistractor== 1
                            numPatchesInserted=6;
                            centers =...
                                ...%yPosPct                         yPosPct       xPosPct             xPosPct
                                [ t.targetYPosPct        t.targetYPosPct          xPosPct             xPosPct;...                   %target
                                t.targetYPosPct+devY     t.targetYPosPct+devY     xPosPct             xPosPct;...                   %top
                                t.targetYPosPct-devY     t.targetYPosPct-devY     xPosPct             xPosPct;...                   %bottom
                                t.targetYPosPct          t.targetYPosPct          xPosPct             xPosPct;...                   %distractor
                                t.targetYPosPct+devY     t.targetYPosPct+devY     xPosPct             xPosPct;...                   %top
                                t.targetYPosPct-devY     t.targetYPosPct-devY     xPosPct             xPosPct];                     %bottom
                        else
                            error('must be 0 or 1');
                        end

                        %%%%%%%%% DETERMINE SCREEN POSITIONS IN PIXELS %%%%%%%%%%%%%%%%

                        pos = round(centers.* repmat([ height, height, width, width],numPatchesInserted,1)...          %convert to pixel vals
                            -  repmat([ floor(szY/2), -(ceil(szY/2)-1 ), floor(szX/2) -(ceil(szX/2)-1)],numPatchesInserted,1)); %account for patch size

                        xPixHint = round(t.positionalHint * width)*sign(-responseIsLeft); % x shift value in pixels caused by hint
                        detail.xPixShiftHint = xPixHint;
                        if t.displayTargetAndDistractor ==0
                            hintOffSet= repmat([0, 0, xPixHint, xPixHint], numPatchesInserted, 1);
                        else
                            %first half move one direction, second half move the other
                            hintOffSet= [repmat([0, 0,  xPixHint,  xPixHint], numPatchesInserted/2, 1);...
                                         repmat([0, 0, -xPixHint, -xPixHint], numPatchesInserted/2, 1)];
                        end
                        pos = pos + hintOffSet;

                        if any(any((pos(:,1:2)<1) | (pos(:,1:2)>height) | (pos(:,3:4)<1) | (pos(:,3:4)>width)))

                            error('At least one image patch is going to be off the screen.  Make patches smaller or closer together or check the size of xPosHint.')
                        end % check error without noise

                        %%%%%%%%%%% ADD NOISE TERMS TO PIXEL POSITIONS %%%%%%%%%%%%%%%

                        xPixShift = round(t.xPosNoise * randn * width); % x shift value in pixels caused by noise
                        yPixShift = round(t.yPosNoise * randn * height); % y shift value in pixels caused by noise
                        stimDetails.xPixShiftNoise = xPixShift;
                        stimDetails.yPixShiftNoise = yPixShift;

                        pos = pos + repmat([yPixShift, yPixShift, xPixShift, xPixShift], numPatchesInserted, 1);

                        if any(any((pos(:,1:2)<1) | (pos(:,1:2)>height) | (pos(:,3:4)<1) | (pos(:,3:4)>width)))
                            resampleCounter = resampleCounter+1;
                            display(sprintf('stimulus off screen because of noise, number of resamples = %d', resampleCounter));
                            if resampleCounter > 10
                                error('too many resamples for stimulus patch position, reconsider the size of the noise');
                            end
                        else
                            stimFit = 1;
                            stimDetails.stimRects = pos;
                            stimDetails.PTBStimRects = [pos(:, 3), pos(:, 1), pos(:, 4), pos(:, 2)];
                        end % check error with noise
                    end

            %% prerender the stim

                    %stim class is inherited from flankstim patch
                    %just check flankerStim, assume others are same
                    if isinteger(t.cache.mask)                   
                        white=intmax(class(t.cache.mask));
                    elseif isfloat(t.cache.mask)
                        white=1;
                    else
                        error('stim patches must be floats or integers')
                    end

                     %PTB could define white differently, we rely on the convention of
                     %255 and having int8s 
            %         windowPtrs=Screen('Windows');
            %         w=max(windowPtrs); %ToDo: w=t.window
            %         white=WhiteIndex(w); %Todo: Move this to stimDetails in calcStim

                    stimDetails.mean=t.mean;
                    stimDetails.meanColor=t.mean*white;
                    stimDetails.dimmingAmount=t.interTrialDimmingFraction*white;


                stimDetails.targetColor=white*stimDetails.targetContrast;
                stimDetails.flankerColor=white*stimDetails.flankerContrast;
                stimDetails.backgroundColor=stimDetails.meanColor;

                end %trial parameter setup


            %% per frame data
            if strcmp(t.renderMode,'directPTB')
                % this section should only be used for setup at the beginging of the trial


                % set defaults
                forceEasy = 0;
                noiseFlankers = 0;
                phase='trial';
                % modify per phase
                switch phase
                    %case 'session'
                    case 'trial'
                    case 'discriminandum'
                    case 'reward'
                        forceEasy = 1;
                    case 'penalty'
                        forceEasy = 1;
                        %case 'final'
                    otherwise
                        error ('unknown phase')
                end

                % override some parameters
                if forceEasy
                    if t.targetContrast>0
                        t.targetContrast = 1; % if visible, make obvious
                    else
                        t.targetContrast = 0; % it hidden, keep hidden
                    end
                end

                if noiseFlankers
                end

                stimSpec=t.renderMode; %dynamic, expert
                details=[];

            else

            %% render the stim

            empty=stimDetails.meanColor(ones(height,width,'uint8')); %the unit8 just makes it faster, it does not influence the clas of stim, rather the class of details determines that
            insertMethod='matrixInsertion';
            stimDetails.insertMethod=insertMethod;

            flankersOnly=empty;
            flankersOnly(:,:)=insertPatch(insertMethod,flankersOnly(:,:),pos(2,:),t.cache.flankerStim,t.flankerOrientations, t.phase, stimDetails.flankerOrientation, stimDetails.flankerPhase, stimDetails.meanColor,stimDetails.flankerContrast);
            flankersOnly(:,:)=insertPatch(insertMethod,flankersOnly(:,:),pos(3,:),t.cache.flankerStim,t.flankerOrientations, t.phase, stimDetails.flankerOrientation, stimDetails.flankerPhase, stimDetails.meanColor,stimDetails.flankerContrast);
            if t.displayTargetAndDistractor == 1 % add distractor flankers on the opposite side y.z
                flankersOnly(:,:)=insertPatch(insertMethod,flankersOnly(:,:),pos(5,:),t.cache.flankerStim,t.flankerOrientations, t.phase, stimDetails.distractorFlankerOrientation, stimDetails.distractorFlankerPhase, stimDetails.meanColor,stimDetails.distractorFlankerContrast);
                flankersOnly(:,:)=insertPatch(insertMethod,flankersOnly(:,:),pos(6,:),t.cache.flankerStim,t.flankerOrientations, t.phase, stimDetails.distractorFlankerOrientation, stimDetails.distractorFlankerPhase, stimDetails.meanColor,stimDetails.distractorFlankerContrast);
            end
            if ~t.cueLum==-1; %skip cue
                flankersOnly(height/2-t.cueSize:height/2+t.cueSize,width/2-t.cueSize:width/2+t.cueSize)=t.cueLum*intmax(class(empty));
            end

            targetOnly=empty;
            %TARGET and DISTRACTOR this could be a for loop except variables are stored as named types...
            if responseIsLeft==1       % choose TARGET stim patch from LEFT candidates
                targetOnly(:,:)=insertPatch(insertMethod,targetOnly(:,:),pos(1,:),t.cache.goLeftStim, t.goLeftOrientations, t.phase, stimDetails.targetOrientation, stimDetails.targetPhase, stimDetails.meanColor,stimDetails.targetContrast);
            elseif responseIsLeft==-1 %% choose TARGET stim patch from RIGHT candidates
                targetOnly(:,:)=insertPatch(insertMethod,targetOnly(:,:),pos(1,:),t.cache.goRightStim,t.goRightOrientations,t.phase, stimDetails.targetOrientation, stimDetails.targetPhase, stimDetails.meanColor,stimDetails.targetContrast);
            else
                error('Invalid response side value. responseIsLeft must be -1 or 1.')
            end
            if ~t.cueLum==-1; %skip cue
                targetOnly(height/2-t.cueSize:height/2+t.cueSize,width/2-t.cueSize:width/2+t.cueSize)=t.cueLum*intmax(class(empty));
            end

            targetAndDistractor=targetOnly;
            if t.displayTargetAndDistractor == 1 % add distractor stimulus to the opposite side of the target y.z
                if responseIsLeft==1       % choose TARGET-equivalent DISTRACTOR stim patch from LEFT candidates
                    if t.distractorYokedToTarget
                        targetAndDistractor(:,:)=insertPatch(insertMethod,targetAndDistractor(:,:),pos(4,:),t.cache.goLeftStim, t.goLeftOrientations, t.phase, stimDetails.targetOrientation, stimDetails.targetPhase, stimDetails.meanColor,stimDetails.distractorContrast);
                    else
                        targetAndDistractor(:,:)=insertPatch(insertMethod,targetAndDistractor(:,:),pos(4,:),t.cache.distractorStim, t.distractorOrientations, t.phase, stimDetails.distractorOrientation, stimDetails.distractorPhase, stimDetails.meanColor,stimDetails.distractorContrast);
                    end
                elseif responseIsLeft==-1 %% choose TARGET-equivalent DISTRACTOR stim patch from RIGHT candidates
                    if t.distractorYokedToTarget
                        targetAndDistractor(:,:)=insertPatch(insertMethod,targetAndDistractor(:,:),pos(4,:),t.cache.goRightStim, t.goRightOrientations, t.phase, stimDetails.targetOrientation, stimDetails.targetPhase, stimDetails.meanColor,stimDetails.distractorContrast);
                    else
                        targetAndDistractor(:,:)=insertPatch(insertMethod,targetAndDistractor(:,:),pos(4,:),t.cache.distractorStim, t.distractorOrientations, t.phase, stimDetails.distractorOrientation, stimDetails.distractorPhase, stimDetails.meanColor,stimDetails.distractorContrast);
                    end
                end
            end

            targetAndFlankers=targetAndDistractor;
            %FLANKER
            targetAndFlankers(:,:)=insertPatch(insertMethod,targetAndFlankers(:,:),pos(2,:),t.cache.flankerStim,t.flankerOrientations, t.phase, stimDetails.flankerOrientation, stimDetails.flankerPhase, stimDetails.meanColor,stimDetails.flankerContrast);
            targetAndFlankers(:,:)=insertPatch(insertMethod,targetAndFlankers(:,:),pos(3,:),t.cache.flankerStim,t.flankerOrientations, t.phase, stimDetails.flankerOrientation, stimDetails.flankerPhase, stimDetails.meanColor,stimDetails.flankerContrast);
            if t.displayTargetAndDistractor == 1
                targetAndFlankers(:,:)=insertPatch(insertMethod,targetAndFlankers(:,:),pos(5,:),t.cache.flankerStim,t.flankerOrientations, t.phase, stimDetails.distractorFlankerOrientation, stimDetails.distractorFlankerPhase, stimDetails.meanColor,stimDetails.distractorFlankerContrast);
                targetAndFlankers(:,:)=insertPatch(insertMethod,targetAndFlankers(:,:),pos(6,:),t.cache.flankerStim,t.flankerOrientations, t.phase, stimDetails.distractorFlankerOrientation, stimDetails.distractorFlankerPhase, stimDetails.meanColor,stimDetails.distractorFlankerContrast);
            end



            %% build it to spec

                    metaPixelSize = [1 1]; %{} means scale to fullScreen
                    almostMeanScreen=stimDetails.meanColor+stimDetails.dimmingAmount;

                    darkScreen=0;
                    flashEasy=repmat(reshape([empty targetOnly],height,width,2),[1 1 (t.numPenaltyFlashes+1)]);
                    flashTimes=[repmat(ceil(ifi*t.msPenaltyFlashDuration), 1, double(t.numPenaltyFlashes)) 0];

                    silence=[];
                    responsivePorts=[];
                    goodTone=[];
                    badTone=[];


                    stimDetails.interSessionStim.stim =darkScreen;
                    stimDetails.interSessionStim.metalPixelSize =[];
                    stimDetails.interSessionStim.frameTimes =0;
                    stimDetails.interSessionStim.frameSounds =silence;

                    stimDetails.interTrialStim.stim =t.interTrialLuminance*white;
                    stimDetails.interTrialStim.metalPixelSize =[];
                    stimDetails.interTrialStim.frameTimes =0;
                    stimDetails.interTrialStim.frameSounds =responsivePorts;

                    if t.toggleStim
                        if t.persistFlankersDuringToggle
                        stimDetails.discriminandumStim.stim ={targetAndFlankers, flankersOnly};
                        else
                        stimDetails.discriminandumStim.stim ={targetAndFlankers, empty};
                        end
                        stimDetails.discriminandumStim.frameTimes =0;
                        stimDetails.loopDiscriminandum=1;
                    else
                        stimDetails.discriminandumStim.stim =createDiscriminandumContextOnOffMovie(t,empty,targetOnly,flankersOnly,targetAndFlankers,t.framesTargetOnOff,t.framesFlankerOnOff);
                        stimDetails.discriminandumStim.frameTimes =[getFrameChangeTimes(t) 0];
                        stimDetails.loopDiscriminandum=1;
                    end
                    stimDetails.discriminandumStim.metalPixelSize =[1 1];
                    stimDetails.discriminandumStim.frameSounds =responsivePorts;

                    stimDetails.rewardWaitStim.stim =flashEasy;
                    stimDetails.rewardWaitStim.metalPixelSize =[1 1];
                    stimDetails.rewardWaitStim.frameTimes =flashTimes;
                    stimDetails.rewardWaitStim.frameSounds =goodTone;

                    stimDetails.rewardStim.stim =flashEasy;
                    stimDetails.rewardStim.metalPixelSize =[1 1];
                    stimDetails.rewardStim.frameTimes =flashTimes;
                    stimDetails.rewardStim.frameSounds =goodTone;

                    stimDetails.penaltyStim.stim =flashEasy;
                    stimDetails.penaltyStim.metalPixelSize =[1 1];
                    stimDetails.penaltyStim.frameTimes =flashTimes;
                    stimDetails.penaltyStim.frameSounds =badTone;

                    stimDetails.finalStim.stim =almostMeanScreen;
                    stimDetails.finalStim.metalPixelSize =[];
                    stimDetails.finalStim.frameTimes =0;
                    stimDetails.finalStim.frameSounds =silence;

                    stimDetails.CLUT=t.LUT;
                    stimDetails.showScreenLabel=1;
                    stimDetails.displayText=sprintf('orientation is: %d',stimDetails.targetOrientation*180/pi);
                    stimDetails.reponseOptions.targetPorts=targetPorts;
                    stimDetails.reponseOptions.distractorPorts=setdiff(responsePorts,targetPorts);

                    stimDetails.requestOptions=2;
                    stimDetails.maxInterTrialSecs=600;
                    stimDetails.framePerRequest=0; %get all frames from one request
                    stimDetails.maxDiscriminandumSecs=t.maxDiscriminandumSecs;
                    stimDetails.advancedOnRequestEnd=t.advancedOnRequestEnd;
                    stimDetails.maxRewardLatencySecs=2;

                    stimSpec='standard'; %dynamic, expert
                    details=[]; %this used to contain the per trials details and be small

                    %question: how do we not save the giant stimuli but keep the
                    %relevant details? Shouldn't there be a seperate location for the
                    %large stimuli that are used but won't go into the records?
                    %either: decache (stimDetails)
                    %or: [stimDetails stimRecords]

                    %stimSpec.extremeVals = [0 intmax(class(stim))]    %[dimmestVal brightestVal]

            end
        end
        
        function pass=checkReinforcementManager(tm,rmStructure)
            %this function just checks the structure to see if it has the right
            %parameters... will probably be better to move this and call
            %errorCheck(reinforcementManager,rm) 

            f=fields(rmStructure);

            allowedFields = {'type',...
                'fractionOpenTimeSoundIsOn',... %moved to super class, but still checked -pmm 
                'fractionPenaltySoundIsOn',...  %moved to super class, but still checked -pmm 
                'rewardNthCorrect',...
                'msPenalty',...
                'scalar'};
            %     'scalarStartsCached'}; %deleted

            pass=0;
            if hasAllFieldsAndNoMore(f,allowedFields)
                pass=1;
            end
        end
        
        function pass=checkShapingValues(tm,shapingMethod,shapingValues)
            %this function only checks the the second and third argument, not the first

            pass=0;

            if ~isempty(shapingMethod)
                switch shapingMethod
                    case 'exponentialParameterAtConstantPerformance'
                        error ('need to write an error check')

                    case 'geometricRatioAtCriteria'
                        error ('need to write an error check')

                    case 'linearChangeAtCriteria'
                        if  ~(isinteger(shapingValues.numSteps) & shapingValues.numSteps>0)
                            error ('when using linearChangeAtCriteria, numSteps must be an integer greater than 0')
                        end
                        if  ~(isnumeric(shapingValues.performanceLevel) & all(shapingValues.performanceLevel>=0 & shapingValues.performanceLevel<=1))
                            error ('when using linearChangeAtCriteria, performanceLevel must be a between 0 and 1')
                        end
                        if ~(length(shapingValues.numTrials) == length(shapingValues.performanceLevel))
                            error ('numTrials vector and performanceLevel vector must be the same length')
                        end   
                        if  ~(isinteger(shapingValues.numTrials) & all(shapingValues.numTrials>0))
                            error ('when using linearChangeAtCriteria, numTrials must be an integer greater than 0')
                        end
                        if  ~isnumeric(shapingValues.startValue)
                            error ('when using linearChangeAtCriteria, startValue must be numeric')
                        end

                        if  ~isnumeric(shapingValues.goalValue)
                            error ('when using linearChangeAtCriteria, goalValue must be a numeric')
                        end
                end

                         if  ~isnumeric(shapingValues.currentValue)
                            error ('all methods must have a currentValue and it must be numeric')
                        end
            end

            pass=1;
        end
        
        function [stim frameTimes]=createDiscriminandumContextOnOffMovie(t,empty,targetOnly,contextOnly,targetAndContext,targetOnOff,contextOnOff)
            %this makes a 2-5 frame stimulus for the timedFrames type in stimOGL, 
            %set the displayMethod=frameTimes to use the appropriate timed frames


            [height width]=size(empty);

            if targetOnOff(2)==contextOnOff(2)
                %okay because they both turn off at the same time
            else
                error ('targetAndContext expected to turn off at the same time')
            end

            if targetOnOff(1)<contextOnOff(1)
                error('target can''t come first')
            elseif targetOnOff(1)>contextOnOff(1)
                stim=reshape([empty contextOnly targetAndContext empty],height,width,4);
            elseif targetOnOff(1)==contextOnOff(1)
                stim=reshape([empty contextOnly targetAndContext empty],height,width,4);
            end

            %reshape([empty flankersOnly targetAndFlankers targetOnly empty],height,width,5); %general: for everything

            if 0 %old code but it accomplishes the same effects more generally
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

                %this adds a zero at the end which causes the last frame to be displayed indefinitely
                %also turns it into a int8 which it must be
                frameTimes=int8([frameTimes 0]);

                %make the meanscreen background movie
                stim=background(ones([size(contextImage),size(frameTimes,2)]));

                %the first frame with context or target or both
                if contextOnOff(1)<targetOnOff(1)
                  %draw context first
                  stim(:,:,stimInd)=stim(:,:,stimInd)+contextImage;
                  if contextOnOff(2)<targetOnOff(1)
                      %context is off before target is on
                      stimInd=stimInd+1; %advance to leave a mean screen in between
                  end
                elseif targetOnOff(1)<contextOnOff(1)
                  %draw target first
                  stim(:,:,stimInd)=stim(:,:,stimInd)+targetImage;
                  if targetOnOff(2)<targetOnOff(1)
                      %target is off before context is on
                      stimInd=stimInd+1; %advance to leave a mean screen in between
                  end
                elseif contextOnOff(1)==targetOnOff(1)
                  stim(:,:,stimInd)=stim(:,:,stimInd)+contextImage+targetImage;
                end

                %the second frame with context or target
                stimInd=stimInd+1;
                if contextOnOff(1)<targetOnOff(1)
                  stim(:,:,stimInd)=stim(:,:,stimInd)+targetImage;
                elseif targetOnOff(1)<contextOnOff(1)
                  stim(:,:,stimInd)=stim(:,:,stimInd)+contextImage;
                elseif contextOnOff(1)==targetOnOff(1)
                  %determine which turns off first and draw the other
                  if contextOnOff(2)<targetOnOff(2)
                      stim(:,:,stimInd)=stim(:,:,stimInd)+targetImage;
                  elseif targetOnOff(2)<contextOnOff(2)
                      stim(:,:,stimInd)=stim(:,:,stimInd)+contextImage;
                  elseif targetOnOff(2)==contextOnOff(2)
                      %do nothing because they turn off together    
                  end 
                end

                %and the last frame is already mean screen
            end
        end

        function t=deflate(t)
            %method to deflate stim patches

            t.cache.goRightStim=[];
            t.cache.goLeftStim= [];
            t.cache.flankerStim=[];
            t.cache.distractorStim=[];
            t.cache.distractorFlankerStim=[];
            t.cache.orientationPhaseTextures=[];
        end
        
        % This code should be intergrated into the trialManager.calibrate

        function trialManager = doCalibration(trialManager,newHomogenousCalibration, screenType, skipSyncTest)

            if ~exist('screenType', 'var')
                screenType = 'CRT';
            elseif isempty(screenType)
                screenType = 'CRT';
            end

            if ~exist('skipSyncTest', 'var')
                skipSyncTest = 0;
            elseif isempty(skipSyncTest)
                skipSyncTest = 0;
            end

            if ~exist('newHomogenousCalibration', 'var')
                newHomogenousCalibration = 0;
            elseif isempty(newHomogenousCalibration)
                newHomogenousCalibration = 0;
            end
            %% Linearize Screen with homogenous patch

            if newHomogenousCalibration
                trialManager = setTypeOfLUT(trialManager, 'calibrateNow');  %linearizedDefault
                plotOn = 0;
                linearizedRange = [0 1];
                trialManager = fillLUT(trialManager,'calibrateNow',linearizedRange,plotOn);


            else
                trialManager = setTypeOfLUT(trialManager, 'linearizedDefault');
                plotOn = 0;
                trialManager = fillLUT(trialManager,'linearizedDefault',[0 1],plotOn);
            end

            %% Pattern Calibration

            % set some parameters so that we can use calcStim
            trialManager=trialManager;
            trialManagerClass=class(trialManager);
            % frameRate=[];%-99;
            ifi = [];
            responsePorts=[1 3];
            targetPorts = 3;
            totalPorts=[];%3;
            width=trialManager.maxWidth ;
            % width
            height=trialManager.maxHeight;
            % height
            trialRecords=[];
            %this should update, add:
            %trialPhase='discriminandum'
            %doingCalibration=1
            %[trialManager updateTM out LUT scaleFactor type targetPorts distractorPorts details interTrialLuminance] = calcStim(trialManager,trialManagerClass,frameRate,responsePorts,totalPorts,width,height,trialRecords);
            %im=out(:,:,2); %make sure calibrate mode passes out one image, not a video

            %create calibrationMovie
            setCalibrationModeOn(trialManager, 1);

            totalFrames = findTotalCalibrationFrames(trialManager);
            totalFrames
            numOrientations = size(trialManager.calib.orientations,2);
            trialManager.calib.contrastScale=ones(1,numOrientations);  %set to one to measure
            trialManager=inflate(trialManager);

            numBatches = getNumCalibrationBatches(trialManager);

            for batch = 1:numBatches
                disp(sprintf('****** Calibrating Batch %d ******', batch));
                [frameIndices] = getNumFramesNextCalibrationBatch(trialManager, batch);
                framesThisBatch = size(frameIndices,2);

                calibrationMovie = zeros(height, width, 3 , framesThisBatch, 'uint8');

                for i=1:framesThisBatch
                    trialManager = setCalibrationFrame(trialManager,frameIndices(i)); % setting the frame index for calibration [1:totalFrames]
                    %[trialManager updateTM out LUT scaleFactor type targetPorts distractorPorts frameDetails{frameIndices(i)} interTrialLuminance] = calcStim(trialManager,trialManagerClass,frameRate,responsePorts,totalPorts,width,height,trialRecords);
            %        calibrationMovie(:, :, :,i)=repmat( out(:, :, 2), [1, 1, 3]);
                    [trialManager updateTM frameDetails{frameIndices(i)} stimSpec targetPorts  details] = calcStimBeta(trialManager,ifi,targetPorts,responsePorts,width,height,trialRecords);
                    stimDetails = frameDetails{frameIndices(i)};
                    calibrationMovie(:, :, :,i)=repmat( stimDetails.discriminandumStim.stim{1}, [1, 1, 3]);
                end
                %     blackWhite =0;
                %     if blackWhite
                %         totalFrames = totalFrames + 2;
                %         blackFrame = zeros(height, width, 3);
                %         whiteFrame = 255.*ones(height, width, 3);
                %         calibrationMovie(:, :, :, end + 1) = blackFrame;
                %         calibrationMovie(:, :, :, end + 1) = whiteFrame;
                %     end

                %create positionFrame
                positionFrame=getCalibrationPositionFrame( trialManager );
                if batch > 1
                    positionFrame = [];
                end
                % get sensor data
                sensorMode = 'daq'; % 'spyder' is the other option ... passed in
                calibrationPhase= 'patterenedIntensity';
                %calibrationPhase = 'homogenousIntensity';
                screenNum=0;
                screenType = screenType;
                patchRect=[0 0 1 1];
                numFramesPerValue=int8(100);
                numInterValueFrames=int8(15);
                clut=repmat(linspace(0,1,2^8)',1,3);
                stim = calibrationMovie;
                interValueRGB= uint8(zeros(1,1,3));%uint8(round(2^8/2)*ones(1,1,3));
                background=[];
                parallelPortAddress='B888';
                framePulseCode=int8(1);

                %%%%% making sure the recordScreenCalibrationData function is running %%%%%%
                daqPath = '\\reinagel-lab.ad.ucsd.edu\rlab\Rodent-Data\daqXfer\Calibration'; % need to pass the daqPath
                if batch == 1
                    daqInitialization(daqPath);
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                [thisLuminanceData, details] = getScreenCalibrationData(trialManager, sensorMode, calibrationPhase, screenNum,screenType,patchRect,numFramesPerValue,numInterValueFrames,clut,stim,positionFrame, interValueRGB,background,parallelPortAddress,framePulseCode, skipSyncTest, batch);

                % insert this data into the larger matrix
                lumWidth = size(thisLuminanceData, 2);
                luminanceData(frameIndices, 1:size(thisLuminanceData, 2)) = thisLuminanceData;

                % this puts NaN's into all newly generated matrix positions (rather than
                % matlab's default of zero)
                if size(luminanceData > lumWidth)
                    whichNew = zeros(size(luminanceData));
                    whichNew(:, lumWidth+1:end) = 1;
                    whichNew(frameIndices, 1:size(thisLuminanceData, 2)) = 0;
                    luminanceData(whichNew ==1) = NaN;
                end
                %%%%%%%%%%%%%%% Adding the call to addToLumStruct - yuan %%%%%%%%%%%%%%%%%%%%%%%%%
                if ~exist('fLum', 'var')
                    fLum = [];
                end

                fLum = addToLumStruct(trialManager, fLum, frameDetails, frameIndices, thisLuminanceData)

                batch
                numBatches
            end

            fContrast = makeContrastStruct(trialManager, fLum)


            luminanceData
            batch = [];
            % interpret data
            size(luminanceData)
            contrastMethod='std'; %'peakToPeak'
            plotOn=0;
            [amplitudes, SNR] = getAmplitudeOfLuminanceData(trialManager, luminanceData, contrastMethod, batch, plotOn)
            dimmestInd= find(amplitudes == min(amplitudes));  % should be the dimmest thing
            contrast = amplitudes(dimmestInd)./amplitudes % multiplying by this will creat a reduction of contrast per orientation that should achieve iso-contrast for your sensor


            % store relevant data in trialManager
            trialManager.calib.rawData=luminanceData;
            trialManager.calib.interpretedData.contrastMethod=contrastMethod;
            trialManager.calib.interpretedData.amplitudes=amplitudes;
            trialManager.calib.interpretedData.SNR=SNR;

            %useable data - where does it go?
            trialManager.calib.contrastScale=contrast;
            trialManager=deflate(trialManager);
            trialManager=inflate(trialManager,1); % with new contrastScale!

            prevMovie=calibrationMovie;
            %create a new calibrationMovie
            setCalibrationModeOn(trialManager, 1);
            totalFrames = findTotalCalibrationFrames(trialManager);
            calibrationMovie = zeros(height, width, 3 , totalFrames, 'uint8');

            if 0 % to be fixed later with a function doValidation
            for i=1:1:totalFrames
                    trialManager = setCalibrationFrame(trialManager,frameIndices(i)); % setting the frame index for calibration [1:totalFrames]
                    %[trialManager updateTM out LUT scaleFactor type targetPorts distractorPorts frameDetails{frameIndices(i)} interTrialLuminance] = calcStim(trialManager,trialManagerClass,frameRate,responsePorts,totalPorts,width,height,trialRecords);
            %        calibrationMovie(:, :, :,i)=repmat( out(:, :, 2), [1, 1, 3]);
                    [trialManager updateTM frameDetails{frameIndices(i)} stimSpec targetPorts  details] = calcStimBeta(trialManager,ifi,targetPorts,responsePorts,width,height,trialRecords)
                    calibrationMovie(:, :, :,i)=repmat( stimDetails.discriminandumStim.stim{1}, [1, 1, 3]);
            end
            end
            %do it again
            stim = calibrationMovie;
            positionFrame=[];
            [luminanceDataValidation, details] = getScreenCalibrationData(trialManager, sensorMode, calibrationPhase, screenNum,screenType,patchRect,numFramesPerValue,numInterValueFrames,clut,stim,positionFrame, interValueRGB,background,parallelPortAddress,framePulseCode, skipSyncTest, batch);
            %%%%%%%%%%%%%%%%%%%%%%%%%
            daqFinish(daqPath); %%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%
            plotOn = 0;
            [validationAmplitudes, validationSNR] = getAmplitudeOfLuminanceData(trialManager, luminanceDataValidation, contrastMethod, batch, plotOn);
            dimmestInd= find(validationAmplitudes == min(validationAmplitudes));
            contrast = validationAmplitudes(dimmestInd)./validationAmplitudes;
            validationFractionalError=1-contrast;

            % store relevant data in trialManager
            trialManager.calib.rawValidationData=luminanceDataValidation;
            trialManager.calib.interpretedData.validationAmplitudes=validationAmplitudes;
            trialManager.calib.interpretedData.validationSNR=validationSNR;
            trialManager.calib.interpretedData.validationFractionalError=validationFractionalError;
        end

        function daqInitialization(daqPath)
            complete = 0;
            save(fullfile(daqPath, 'processComplete.mat'), 'complete');
            inputdlg('please start recordScreenCalibrationData.m', 'ok');
        end

        function daqFinish(daqPath)
            complete = 1;
            save(fullfile(daqPath, 'processComplete.mat'), 'complete');
        end
        
        function [stimDetails frameRecords]=doDynamicPTBFrame(t,phase,stimDetails,frame,timeSinceTrial,eyeRecords,RFestimate, w)

            if frame ==1
                if ~strcmp(t.renderMode,'directPTB')
                    error('cannot use pbt mode if trialManager is not set to the appropriate renderMode');
                    % current known conflict: inflate makes the wrong cache
                end

            end

            % windowPtrs=Screen('Windows');
            % w=max(windowPtrs); %ToDo: w=t.window

            try
                %properties of screen
                filterMode=0; %0 = Nearest neighbour filtering, 1 = Bilinear
                modulateColor=[];
                textureShader=[];

                %setup
                texNum=0;
                typeInd = [];
                oInd = [];
                pInd = [];


                switch phase
                    case 'discriminandum'


            version=1;
            switch version
                case 1
                        %this first version of the code slavishly reproduces the method used in the
                        %ratrixGeneral renderMode...in the future could be used to validate a
                        %version where Gaussian Mask are stored seperate from grating and
                        %orientations is handled by PTB and phase is handled by choice of
                        %sourceRect

                        %set up target
                        if (frame>=t.framesTargetOnOff(1) & frame<t.framesTargetOnOff(2))
                            %choose indices
                            texNum=texNum+1; %target
                            if stimDetails.correctResponseIsLeft==1
                                typeInd(texNum)=2; %left
                                oInd(texNum)= find(t.goLeftOrientations==stimDetails.targetOrientation);
                            elseif stimDetails.correctResponseIsLeft==-1
                                typeInd(texNum)=1; %right
                                oInd(texNum)= find(t.goRightOrientations==stimDetails.targetOrientation);
                            end
                            pInd(texNum)= find(t.phase==stimDetails.flankerPhase);
                            globalAlpha(texNum) = stimDetails.targetContrast;
                            destinationRect(texNum,:)=stimDetails.PTBStimRects(1,:); %target is 1, top is 2, bottom is 3

                            if t.displayTargetAndDistractor
                                texNum=texNum+1; %distractor
                                if stimDetails.correctResponseIsLeft==1
                                    if t.distractorYokedToTarget
                                        typeInd(texNum)=2; %left
                                        oInd(texNum)= find(t.goLeftOrientations==stimDetails.targetOrientation);
                                    else
                                        typeInd(texNum)=4; %distractor
                                        oInd(texNum)= find(t.distractorOrientations==stimDetails.distractorOrientation);
                                    end
                                elseif stimDetails.correctResponseIsLeft==-1
                                    if t.distractorYokedToTarget
                                        typeInd(texNum)=1; %right
                                        oInd(texNum)= find(t.goRightOrientations==stimDetails.targetOrientation);
                                    else
                                        typeInd(texNum)=4; %distractor
                                        oInd(texNum)= find(t.distractorOrientations==stimDetails.distractorOrientation);
                                    end
                                end
                                pInd(texNum)= find(t.phase==stimDetails.distractorPhase);
                                globalAlpha(texNum) = stimDetails.distractorContrast;
                                destinationRect(texNum,:)=stimDetails.PTBStimRects(4,:); %distractor is 4
                            end
                        end

                        %set up flanker
                        if (frame>=t.framesFlankerOnOff(1) & frame<t.framesFlankerOnOff(2))
                            %choose indices
                            if t.topYokedToBottomFlankerOrientation & t.topYokedToBottomFlankerContrast
                                texNum=texNum+1;
                                typeInd(texNum)=3; %flanker
                                oInd(texNum)= find(t.flankerOrientations==stimDetails.flankerOrientation);
                                pInd(texNum)= find(t.phase==stimDetails.flankerPhase);
                                globalAlpha(texNum) = stimDetails.flankerContrast;
                                destinationRect(texNum,:)=stimDetails.PTBStimRects(2,:); %top is 2, bottom is 3

                                texNum=texNum+1;
                                typeInd(texNum)=3; %flanker
                                oInd(texNum)= oInd(texNum-1);
                                pInd(texNum)= pInd(texNum-1);
                                globalAlpha(texNum) =  globalAlpha(texNum-1);
                                destinationRect(texNum,:)=stimDetails.PTBStimRects(3,:); %top is 2, bottom is 3
                            else
                                error('topYokedToBottomFlankerContrast and topYokedToBottomFlankerOrientation must equal 1')
                            end
                            if t.displayTargetAndDistractor
                                if t.distractorFlankerYokedToTargetFlanker
                                    if t.topYokedToBottomFlankerOrientation & t.topYokedToBottomFlankerContrast
                                        texNum=texNum+1;
                                        typeInd(texNum)=3; %distractorFlanker(type 5) is drawn as a flanker(type 3)
                                        oInd(texNum)= find(t.flankerOrientations==stimDetails.flankerOrientation);
                                        pInd(texNum)= find(t.phase==stimDetails.flankerPhase);
                                        globalAlpha(texNum) = stimDetails.distractorFlankerContrast;
                                        destinationRect(texNum,:)=stimDetails.PTBStimRects(5,:); %top is 5, bottom is 6

                                        texNum=texNum+1;
                                        typeInd(texNum)=3; %distractorFlanker(type 5) is drawn as a flanker(type 3)
                                        oInd(texNum)= oInd(texNum-1);
                                        pInd(texNum)= pInd(texNum-1);
                                        globalAlpha(texNum) =  globalAlpha(texNum-1);
                                        destinationRect(texNum,:)=stimDetails.PTBStimRects(6,:); %top is 5, bottom is 6
                                    else
                                        error('topYokedToBottomFlankerContrast and topYokedToBottomFlankerOrientation must equal 1')
                                    end
                                else
                                    error('distractorFlankerYokedToTargetFlanker must = 1');
                                end
                            end

                        end
                case 2
                    %use the mask?

                otherwise
                    error('bad version')
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

                Screen('FillRect',w, stimDetails.backgroundColor);
                Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


                noise = 0;
                if noise
                    Screen('TransformTexture')

                    droppedRecord=zeros(frames,1); % my responsibility or the ratrix's?
                    drawTime=zeros(frames,1);
                end

                %draw the patches
                for n=1:size(oInd,2)
                    screen('drawTexture',w,t.cache.orientationPhaseTextures(typeInd(n),oInd(n),pInd(n)),[],destinationRect(n,:),[],filterMode,globalAlpha(n),modulateColor,textureShader)
                    %Screen('DrawTexture', windowPointer, texturePointer [,sourceRect] [,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [, modulateColor] [, textureShader]);
                end
                Screen('DrawingFinished', w);

                frameRecords.xxx = [];  %ToDo: empirically test speed of saving frameRecords{i}.xxx outside this function versus frameRecords.xxx(i,:) inside this function

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

                rethrow(ex);
            end

        end
        
        function [stimDetails frameRecords]=doUniqueRepeatDriftFrame(t,phase,stimDetails,frame,timeSinceTrial,eyeRecords,RFestimate, w)
            %this would get called after a switch on the experiment field (class=UniqueRepeatDriftTwoFLank).  there is
            %probably an dynamicObject and it might be a method on that 

            %getExperimentParameters()
            experiementClass='uniqueRepeatDriftTwoFlank';
            targetDriftPixPerFrame = 1;
            flankerDriftPixPerFrame= 1;
            framesPerCondition=100;  %?calc this off of duration and ifi?
            conditions={'aa','au','ab','aa','ua','uu'}

            numConditions=length(conditions);

            %calc conditionFrame
            conditionFrame=mod(frame,framesPerCondition);
            if conditionFrame==0
                conditionFrame=framesPerCondition; %mod works funny
            end

            %precache elsewhere, confirm cached with right rendermode & exptClass
            % if frame ==1
            %     if ~strcmp(t.renderMode,'directPTB')
            %         error('cannot use pbt mode if trialManager is not set to the appropriate renderMode');
            %         % current known conflict: inflate makes the wrong cache
            %     end
            % 
            % end

            %precache uniques here:
               U=rand(1,256)*255;
               UTex = screen('makeTexture',w,U);



            % windowPtrs=Screen('Windows');
            % w=max(windowPtrs); %ToDo: w=t.window

            try
                %properties of screen
                filterMode=0; %0 = Nearest neighbour filtering, 1 = Bilinear
                modulateColor=[];
                textureShader=[];

                %setup
                texNum=0;
                typeInd = [];
                oInd = [];
                pInd = [];

                sca
            keyboard

                destinationRect(texNum,:)=stimDetails.PTBStimRects(1,:); %target is 1, top is 2, bottom is 3
                destinationRect(texNum,:)=stimDetails.PTBStimRects(3,:); %top is 2, bottom is 3



                Screen('FillRect',w, stimDetails.backgroundColor);
                Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


                noise = 0;
                if noise
                    Screen('TransformTexture')

                    droppedRecord=zeros(frames,1); % my responsibility or the ratrix's?
                    drawTime=zeros(frames,1);
                end

                %draw the patches
                for n=1:size(oInd,2)
                    screen('drawTexture',w,t.cache.orientationPhaseTextures(typeInd(n),oInd(n),pInd(n)),[],destinationRect(n,:),[],filterMode,globalAlpha(n),modulateColor,textureShader)
                    %Screen('DrawTexture', windowPointer, texturePointer [,sourceRect] [,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [, modulateColor] [, textureShader]);
                end
                Screen('DrawingFinished', w);

                frameRecords.xxx = [];  %ToDo: empirically test speed of saving frameRecords{i}.xxx outside this function versus frameRecords.xxx(i,:) inside this function

            catch ex
                sca
                pInd
                oInd
                typeInd
                destinationRect
                globalAlpha
                ShowCursor;

                rethrow(ex);
            end

        end

        function t=errorCheck(t,optionalStructure)
            %checks the values of the trialMangager if one arg supplied:
            %else confirms the values of the parameter structure: but must have the
            %correct class as the first arguement because it's a method


            %% setup

            tm=t; %so that that trialManager specific methods can be called...
            if exist('optionalStructure','var')
                t=optionalStructure; %you will be returned with the structure you checked
            end

            %% confirm that every field is an allowed field
            allowedFields = {...
                ...%may migrate
                'maxWidth',...
                'maxHeight',...
                'scaleFactor',...
                'interTrialLuminance',...
                ... %normals
                'goRightOrientations', ...
                'goLeftOrientations', ...
                'flankerOrientations', ...
                'distractorOrientations', ...
                'distractorFlankerOrientations', ...
                'topYokedToBottomFlankerOrientation', ...
                'goRightContrast', ...
                'goLeftContrast', ...
                'flankerContrast', ...
                'distractorContrast', ...
                'distractorFlankerContrast', ...
                'topYokedToBottomFlankerContrast', ...
                'phase', ...
                'flankerYokedToTargetPhase', ...
                'pixPerCycs', ...
                'stdGaussMask', ...
                'stdsPerPatch', ...
                'thresh', ...
                'gratingType', ...
                'gaborNormalizeMethod', ...
                'xPositionPercent', ...
                'targetYPosPct', ...
                'flankerOffset', ...
                'positionalHint', ...
                'xPosNoise', ...
                'yPosNoise', ...
                'cuePercentTargetEcc', ...
                'framesTargetOnOff', ...
                'framesFlankerOnOff', ...
                'typeOfLUT', ...
                'rangeOfMonitorLinearized', ...
                'mean', ...
                'cueLum', ...
                'cueSize', ...
                'displayTargetAndDistractor', ...
                'distractorYokedToTarget', ...
                'distractorFlankerYokedToTargetFlanker', ...
                'fractionNoFlanks', ...
                'toggleStim', ...
                'persistFlankersDuringToggle', ...
                'msPenaltyFlashDuration', ...
                'numPenaltyFlashes', ...
                'maxDiscriminandumSecs', ...
                'advancedOnRequestEnd', ...
                'interTrialDimmingFraction', ...
                'renderMode', ...
                'shapedParameter', ...
                'shapingMethod', ...
                ... %specials
                'shapingValues', ...
                'LUT', ...
                'cache', ...
                'calib', ...
                'stimDetails', ...
                'rm'};

            paramFields=fields(t);


            if strcmp(class(t),'ifFeatureGoRightWithTwoFlankTrialManager')
                %don't check for the rm which is only a field in the created parameterStructure
                allowedFields(find(strcmp('rm',allowedFields)))=[];

                %do check for the trialManager which is the last field of the blessed object
                allowedFields{end+1}='trialManager';
            end

            if ~hasAllFieldsInThatOrder(paramFields,allowedFields)
                error ('problem with fields in parameterStructure')
            end

            %% confirm that all allowed fields have the right values


            if ~(isnumeric(t.goRightOrientations))
                error('goRightOrientations must be numeric')
            end

            if ~(isnumeric(t.goLeftOrientations))
                error('goLeftOrientations must be numeric')
            end

            if ~(isnumeric(t.flankerOrientations))
                error('flankerOrientations must be numeric')
            end

            if ~(isnumeric(t.distractorOrientations))
                error('distractorOrientations must be numeric')
            end

            if ~(isnumeric(t.distractorFlankerOrientations))
                error('distractorFlankerOrientations must be numeric')
            end

            if ~(isnumeric(t.topYokedToBottomFlankerOrientation))
                error('topYokedToBottomFlankerOrientation must be numeric')
            end

            if ~(all(t.goRightContrast >= 0 & t.goRightContrast <=1))
                error('goRightContrast must be between 0 and 1')
            end

            if ~(all(t.goLeftContrast >= 0 & t.goLeftContrast <=1))
                error('goLeftContrast must be between 0 and 1')
            end

            if ~(all(t.flankerContrast >= 0 & t.flankerContrast <=1))
                error('flankerContrast must be between 0 and 1')
            end

            if ~(all(t.distractorFlankerContrast >= 0 & t.distractorFlankerContrast <=1))
                error('distractorFlankerContrast must be between 0 and 1')
            end

            if ~(all(t.topYokedToBottomFlankerContrast >= 0 & t.topYokedToBottomFlankerContrast <=1))
                error('topYokedToBottomFlankerContrast must be between 0 and 1')
            end

            if ~(all(0<=t.phase) & all(2*pi>=t.phase))
                error('phase must be numeric')
            end

            if ~((0==t.flankerYokedToTargetPhase) | (1==t.flankerYokedToTargetPhase))
                error('flankerYokedToTargetPhase must be 0 or 1')
            end

            if ~(all(t.pixPerCycs>0))
                error('pixPerCycs must be greater than 0')
            end

            if ~(t.stdGaussMask >= 0)
                error('stdGaussMask must be >= 0')
            end

            if ~(t.stdsPerPatch==4)
                error ('std for patch must be 4')
                %this is an even number that is very reasonable fill of square--has
                %been hardcoded until 8/21/07. Before that, it was always 4. After that
                %always 4.
            end

            if ~(t.thresh >= 0)
                error('thresh must be >= 0')
            end

            if ~(t.xPositionPercent >= 0 && t.xPositionPercent<=1)
                error('xPositionPercent must be >= 0 or <=1')
            end

            if ~(isnumeric(t.targetYPosPct) && t.targetYPosPct >= 0 && t.targetYPosPct<=1)
                error('targetYPosPct must be between 0 and 1 inclusive')
            end

            if ~(t.flankerOffset >= 0)
                error('flankerOffset must be >=0')
            else
                if (t.stdGaussMask == 1/16 && t.flankerOffset> 6)
                    error ('flanker may be off screen...remove this error and test it')
                end
            end

            if ~( 0<=t.positionalHint & t.positionalHint<=1 )
                error('positionalHint must be between 0 and 1 inclusive')
            end

            if ~(0<=t.xPosNoise)
                error('xPosNoise must be >=0')
            end

            if ~(0<=t.yPosNoise)
                error('yPosNoise must be >=0')
            end

            if ~(t.cuePercentTargetEcc >= 0 && t.cuePercentTargetEcc<=1)
                error('cuePercentTargetEcc must be between 0 and 1 inclusive')
            end

            if ~(strcmp(t.typeOfLUT,'linearizedDefault') || strcmp(t.typeOfLUT,'useThisMonitorsUncorrectedGamma') || strcmp(t.typeOfLUT,'mostRecentLinearized'))
                error('typeOfLUT must be linearizedDefault or useThisMonitorsUncorrectedGamma or mostRecentLinearized')
            end

            if ~(all(0<=t.rangeOfMonitorLinearized) & all(t.rangeOfMonitorLinearized<=1) & t.rangeOfMonitorLinearized(1)<t.rangeOfMonitorLinearized(2) & size(t.rangeOfMonitorLinearized,1)==1 & size(t.rangeOfMonitorLinearized,2)==2)
                error('rangeOfMonitorLinearized must be greater than or =0 and less than or =1')
            end

            if ~(t.mean >= 0 && t.mean<=1)
                error('0 <= mean <= 1')
            end

            if ~(t.cueLum >= 0 && t.cueLum<=1)
                error('0 <= cueLum <= 1')
            end

            if ~(t.cueSize >= 0 && t.cueSize<=10)
                error('0 <= cueSize <= 10')
            end

            if ~((0==t.displayTargetAndDistractor|1==t.displayTargetAndDistractor))
                error('displayTargetAndDistractor must be 0 or 1')
            end

            if ~((0==t.distractorYokedToTarget) | (1==t.distractorYokedToTarget))
                error('distractorYokedToTarget must be 0 or 1')
            end

            if ~((0==t.distractorFlankerYokedToTargetFlanker) | (1==t.distractorFlankerYokedToTargetFlanker))
                error('distractorFlankerYokedToTargetFlanker must be 0 or 1')
            end

            if ~(all(t.fractionNoFlanks >= 0 & t.fractionNoFlanks<=1))
                error('0 <= all fractionNoFlanks <= 1')
            end

            if ~(isnumeric(t.toggleStim))
                error('toggleStim must be logical')
            end


            if ~((0==t.persistFlankersDuringToggle) | (1==t.persistFlankersDuringToggle));
                error('persistFlankersDuringToggle must be 0 or 1')
            end

            if ~(any(strcmp(t.gratingType,{'square', 'sine'})))
                error ('gratingType must be square or sine')
            end

            if ~(strcmp(t.gaborNormalizeMethod,'normalizeVertical'))
                error ('gaborNormalizeMethod must be normalizeVertical')
            end

            if ~(all(t.framesTargetOnOff > 0) & isinteger(t.framesTargetOnOff) & t.framesTargetOnOff(1)<t.framesTargetOnOff(2) & size(t.framesTargetOnOff,1)==1 & size(t.framesTargetOnOff,2)==2)
                error ('framesTargetOnOff must be positive integers and on before off')
            end

            if ~(all(t.framesFlankerOnOff > 0) & isinteger(t.framesFlankerOnOff) & t.framesFlankerOnOff(1)<t.framesFlankerOnOff(2) & size(t.framesFlankerOnOff,1)==1 & size(t.framesFlankerOnOff,2)==2)
                error ('framesFlankerOnOff must be positive integers and on before off')
            end

            if ~(t.msPenaltyFlashDuration > 0)
                error ('msPenaltyFlashDuration must be greater than 0')
            end

            if ~(t.numPenaltyFlashes>0 & isinteger(t.numPenaltyFlashes))
                error ('numPenaltyFlashes must be an integer greater than 0');
            end

            if ~(t.maxDiscriminandumSecs >= 0)
                error ('maxDiscriminandumSecs must be greater or equal to 0')
            end

            if ~(t.advancedOnRequestEnd == 0 | t.advancedOnRequestEnd ==1)
                error ('advancedOnRequestEnd must be 0 or 1')
            end

            if ~(all(t.interTrialDimmingFraction >= 0 & t.interTrialDimmingFraction<=1))
                error('0 <= all interTrialDimmingFraction <= 1')
            end

            if ~(any(strcmp(t.renderMode,{'ratrixGeneral', 'directPTB'})))
                error ('renderMode must be ratrixGeneral or directPTB')
            end

            if ~(isempty(t.shapedParameter) | any(strcmp(t.shapedParameter,{'positionalHint', 'stdGaussianMask','targetContrast'})))
                error ('shapedParameter must be positionalHint or stdGaussianMask or targetContrast')
            end

            if ~(isempty(t.shapingMethod) | any(strcmp(t.shapingMethod,{'exponentialParameterAtConstantPerformance', 'geometricRatioAtCriteria','linearChangeAtCriteria'})))
                error ('shapingMethod must be exponentialParameterAtConstantPerformance or geometricRatioAtCriteria or linearChangeAtCriteria')
            end




            %% special fields

            if strcmp(class(t),'ifFeatureGoRightWithTwoFlankTrialManager')
                %don't check for the rm which is only a field in the created parameterStructure
                %it's okay stimDetails, calib, LUT or chache are no longer empty postuse

            else
                if ~(checkReinforcementManager(tm,t.rm))
                    error ('wrong fields in reinforcementManager')
                end

                if ~(isempty(t.stimDetails))
                    error ('stimDetails must be empty')
                end

                if ~(isempty(t.calib))
                    error ('calib must be empty')
                end

                if ~(isempty(t.LUT))
                    error ('LUT must be empty')
                end

                if ~(isempty(t.cache))
                    error ('cache must be empty')
                end

                if ~isempty(t.shapingValues) %only check values if a method is selected
                 if ~(checkShapingValues(tm,t.shapingMethod,t.shapingValues))
                    error ('wrong fields in shapingValues')
                 end
                end


            end
            %% May Migrate

            if ~(all(t.interTrialLuminance >= 0 & t.interTrialLuminance<=1))
                error('0 <= all interTrialLuminance <= 1')
            end

            if ~(all(t.maxHeight >= 1 & t.maxHeight<=2048) & (double(int16(t.maxHeight))-double(t.maxHeight)==0))
                isint=(double(int16(t.maxHeight))-double(t.maxHeight)==0)
                t.maxHeight
                error('1 <= all maxHeight <= 2048')
            end

            if ~(all(t.maxWidth >= 1 & t.maxWidth<=2048) & (double(int16(t.maxWidth))-double(t.maxWidth)==0))
                error('1 <= all maxWidth <= 2048')
            end

            if ~(all(t.scaleFactor >= 1 & t.scaleFactor<=999) & (double(int16(t.scaleFactor))-double(t.scaleFactor)==0))
                error('1 <= all scaleFactor <= 999')
            end
        end
        
        function t=fillLUT(t,method,linearizedRange,plotOn)
            %function s=fillLUT(s,method,linearizedRange [,plotOn]);
            %stim=fillLUT(stim,'linearizedDefault');
            %note: this calculates and fits gamma with finminsearch each time
            %might want a fast way to load the default which is the same each time

            LUTBitDepth=8;
            numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
            ramp=[0:fraction:1];
            grayColors= [ramp;ramp;ramp]';

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

                    numColors = size(sent,2);
                    sensorValues = [measured_R, measured_G, measured_B];
                    sensorRange = [min(sensorValues), max(sensorValues)];
                    gamutRange = [min(sent), max(sent)];

                    t.calib.RGBgamutValues = ([ramp; ramp; ramp]);
                    t.calib.RGBsensorValues = reshape(sensorValues, 3,numColors);
                    t.calib.sensorRange = sensorRange;
                    t.calib.gamutRange = gamutRange;
                    %oldCLUT = Screen('LoadNormalizedGammaTable', w, linearizedCLUT,1);
                case 'useThisMonitorsUncorrectedGamma'

                    %maybe ask for red / green / blue gun only
                    uncorrected=grayColors;
                    useUncorrected=1; 
                case 'calibrateNow'


                    %define inputs
                    sensorMode = 'daq'; % 'spyder' is the other option
                    trialManager=t;
                    screenNum=[];
                    screenType = 'CRT';
                    patchRect=[0 0 1 1];
                    numFramesPerValue=int8(30);
                    numInterValueFrames=int8(30);
                    clut=grayColors; % comperable to repmat(linspace(0,1,2^8)',1,3);
                    stim=[];
                    positionFrame=[];
                    interValueRGB= uint8(zeros(1,1,3));%uint8(round(2^8/2)*ones(1,1,3));
                    background=[];
                    parallelPortAddress=[];
                    framePulseCode=[];

                    %make stim
                    sampleBitDepth=4;
                    numColors=2^sampleBitDepth; 

                    maxColorID=2^8-1; %numColors-1; %ptb: accepts 255 as white, this could change one day
                    fraction=(maxColorID)/(numColors-1);
                    ramp=[0:fraction:maxColorID]; %ramp=[0:fraction:1];
                    dark = zeros(size(ramp));
                    sampleColors = [ramp dark dark; ...
                                    dark ramp dark; ...
                                    dark dark ramp];
                    stim = reshape(sampleColors,1,1,3,numColors*3);  %confirm its good
                    stim = uint8(stim);
                    %%%%%%%%%%%%%%%%%%%%%%%


                    calibrationPhase='homogenousIntensity'; 
                    [luminanceData, details] = getScreenCalibrationData(trialManager,sensorMode,calibrationPhase,screenNum,screenType,patchRect,numFramesPerValue,numInterValueFrames,clut,stim,positionFrame, interValueRGB,background,parallelPortAddress,framePulseCode);

                    measured_R=luminanceData(0*numColors+[1:numColors])
                    measured_G=luminanceData(1*numColors+[1:numColors])
                    measured_B=luminanceData(2*numColors+[1:numColors])

                    sent = ramp';       
                    sensorRange = [min(luminanceData), max(luminanceData)];
                    gamutRange = [min(sent), max(sent)];

                    t.calib.RGBgamutValues = ([ramp; ramp; ramp]);
                    t.calib.RGBsensorValues = reshape(luminanceData, 3,numColors);
                    t.calib.sensorRange = sensorRange;
                    t.calib.gamutRange = gamutRange;
                    %[measured_R measured_G measured_B] measureRGBscale()


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

            t.LUT=linearizedCLUT;
        end
        
        function [totalFrames] = findTotalCalibrationFrames(t)

            numTargetOrientations = size(t.goRightOrientations,2);
            numTargetPhases = size(t.phase,2);
            numFlankerOrientations=size(t.flankerOrientations,2);
            numFlankerPhases = size(t.phase,2);

            %         numTargetContrast=size(t.goRightContrast,2);
            %         numFlankerContrast=size(t.flankerContrast,2);
            %         numFlankerOffset=size(t.flankerOffset,2);
            switch t.calib.method
                case 'sweepAllPhasesPerFlankTargetContext'
                    %totalFrames=numPhases*numFlankerOrientations*numTargetOrientations; %totalFrames=numf*numT*numP;
                    totalFrames = numTargetOrientations*numTargetPhases*numFlankerOrientations*numFlankerPhases;
                    trialManager.calib.orientations= numTargetOrientations; %was: unique([goRight goLeft flank]); what is suppose to be placed here?
                case 'sweepAllPhasesPerTargetOrientation'
                    totalFrames=numTargetPhases*numTargetOrientations;
                    trialManager.calib.orientations=t.goRightOrientations;
                case 'sweepAllPhasesPerPossibleOrientation'
                    % toDo:
                    %numTargetOrientations=length(trialManager.calib.orientations!)
                    %unique([goRight goLeft flank distr])
                case 'sweepAllContrastsPerPhase'
                otherwise
                    err('Not a valid method.');
            end
        end
        
        function s=flushLUT(s)
            %method to flush the look up table, see fillLUT

            s.LUT=[];   

        end
        
        function [amplitude, overallMean, SNR, peak, trough] = getAmplitudeFromFlum(trialManager, measuredData, numRepeats, contrastMethod)

            % returns a value for measured contrast, mean, snr, and amplitude


            luminanceDataSegment = reshape(measuredData, numRepeats, numel(measuredData)/numRepeats)'

            if size(luminanceDataSegment,2)>1
                mn = mean(luminanceDataSegment');
            else
                mn = luminanceDataSegment;
            end

            switch contrastMethod
                case 'peakToPeak'
                    indexMax = find(mn == max(mn)); % this code will go away when an alternative method surfaces
                    indexMin = find(mn == min(mn));
                    st = std(luminanceDataSegment(indexMax,:) - luminanceDataSegment(indexMin, :));
                    stdError = st ./ sqrt(numRepeats);
                    amplitudeTop = max(mn) - mean(mn);
                    amplitudeBottom = mean(mn) - min(mn);

                    if abs(amplitudeTop - amplitudeBottom) < 0.01
                        amplitude = (amplitudeTop + amplitudeBottom)/2;
                    else

                        amplitude = (amplitudeTop + amplitudeBottom)/2;

                        warning('amplitudes are too different to trust this method of calculating signal strength');
                    end
                case 'std'
                    amplitude=std(mn);

                    if numRepeats>1
                        demeaned=luminanceDataSegment-repmat(mn', 1, numRepeats);
                        st = max(std(demeaned')); %max causes you to overestimate noise, underestimate SNR
                        stdError = st ./ sqrt(numRepeats);
                    else
                        stdError=NaN;
                    end

                otherwise
                    contrastMethod
                    error ('unsupported contrastMethod')
            end
            SNR= amplitude/stdError;
            overallMean = mean(mn);
            trough = min(mn);
            peak = max(mn);



            %     if plotOn
            %         [m n] = meshgrid( 1: size(luminanceDataSegment, 2), 1: size(luminanceDataSegment, 1));
            %         figure;
            %
            %         offset = 0.2;
            %         scatter(n(:)+offset, luminanceDataSegment(:));
            %
            %         hold on;
            %         if size(luminanceDataSegment,2)>1
            %             noisePerPhase = std(luminanceDataSegment')./sqrt(numRepeats);
            %         else
            %             noisePerPhase = zeros(size(luminanceDataSegment,1),1);
            %         end
            %         top = (noisePerPhase/2);
            %         bottom = -(noisePerPhase/2);
            %         %         size(top)
            %         %         size(bottom)
            %         %         size(mn)
            %         %         size([1:size(luminanceDataSegment,1)])
            %         errorbar([1:size(luminanceDataSegment,1)], mn, top, bottom);
            %
            %         plot(mn, 'r');
            %
            %         hold off;
            %
            %     end
        end
        
        function [amplitude, SNR] = getAmplitudeOfLuminanceData(t, luminanceData, contrastMethod, batch, plotOn)


            %get rid of bad nans
            % haveDate=find(~isnan(sum(luminanceData)));  % redundant with getScreenCalibrationData
            % luminanceData=luminanceData(:,haveDate);


            numOrientations = size(t.goRightOrientations,2); % how to
            numPhases = size(t.phase,2);
            numRepeats = size(luminanceData,2);

            if isempty(batch) % yuan thinks this sould work, but untested
                totalFrames = findTotalCalibrationFrames(t);
            else
                frameIndices = getNumFramesNextCalibrationBatch(t, batch);
                totalFrames = size(frameIndices, 2); % Note: totalFrames here means the number of frames per batch, so the frames in the last batch will be different from the previous ones
            end

            % %frameIndices = getNumFramesNextCalibrationBatch(t, batch);
            % numAnalysisChunks = getNumAnalysisChunks(t); %previously 'length(ss)', needs a method with a switch t.calib.method
            % % in for loop: frameIndices = getNumFramesNextCalibrationAnalysisChunk(t,numAnalysisChunk);
            % 
            % %this code could be superfluous, see put into getNumFramesNextCalibrationAnalysisChunk
            switch t.calib.method
                case 'sweepAllPhasesPerTargetOrientation'
                    ss = [1:numPhases:totalFrames];
                    ee = [ss(2:end)-1, totalFrames];
                case 'sweepAllPhasesPerFlankTargetContext'
                    if isempty(batch)
                    ss = [1:numPhases:totalFrames];
                    ee = [ss(2:end)-1, totalFrames];
                    else
                        ss = 1;
                        ee = totalFrames;
                    end

                otherwise
                    error('not an acceptable method');
            end


            %note (just for clarity, not to do) if consecutive:
            % ss=min(frameIndices)
            % ee=max(frameIndices)
            %toDo: rewrite code to work completely with frameIndices
            %replace all calls to 'ss(i): ee(i)' with 'frameIndices'


            % this would have to be if the luminanceData is frames per batch +2
            % because this gets called on individual batches
            % blackWhite was removed as an option on 01/06/08 pmm

            % if size(luminanceData, 1) ~= totalFrames
            %    size(luminanceData, 1)
            %     blackWhite = luminanceData(totalFrames+1: totalFrames + 2, : );
            %     luminanceData = luminanceData(1: totalFrames, : );
            % end

            SNR = zeros(1, length(ss));
            amplitude = zeros(1, length(ss));

            for i = 1:length(ss) % for each chunk of luminance data
                luminanceDataSegment = luminanceData(ss(i): ee(i),:);
                if size(luminanceDataSegment,2)>1
                    mn = mean(luminanceDataSegment');
                else
                    mn = luminanceDataSegment;
                end

                switch contrastMethod
                    case 'peakToPeak'
                        indexMax = find(mn == max(mn)); % this code will go away when an alternative method surfaces
                        indexMin = find(mn == min(mn));
                        st = std(luminanceDataSegment(indexMax,:) - luminanceDataSegment(indexMin, :));
                        stdError = st ./ sqrt(numRepeats);
                        amplitudeTop = max(mn) - mean(mn);
                        amplitudeBottom = mean(mn) - min(mn);

                        if abs(amplitudeTop - amplitudeBottom) < 0.01
                            amplitude(i) = (amplitudeTop + amplitudeBottom)/2;
                        else

                            amplitude(i) = (amplitudeTop + amplitudeBottom)/2;

                            warning('amplitudes are too different to trust this method of calculating signal strength');
                        end
                    case 'std'
                        amplitude(i)=std(mn);

                        if numRepeats>1
                            demeaned=luminanceDataSegment-repmat(mn', 1, numRepeats);
                            st = max(std(demeaned')); %max causes you to overestimate noise, underestimate SNR
                            stdError = st ./ sqrt(numRepeats);
                        else
                            stdError=NaN;
                        end

                    otherwise
                        contrastMethod
                        error ('unsupported contrastMethod')
                end
                SNR(i) = (amplitude(i))/stdError;

                if plotOn
                    [m n] = meshgrid( 1: size(luminanceDataSegment, 2), 1: size(luminanceDataSegment, 1));
                    figure;

                    offset = 0.2;
                    scatter(n(:)+offset, luminanceDataSegment(:));

                    hold on;
                    if size(luminanceDataSegment,2)>1
                        noisePerPhase = std(luminanceDataSegment')./sqrt(numRepeats);
                    else
                        noisePerPhase = zeros(size(luminanceDataSegment,1),1);
                    end
                    top = (noisePerPhase/2);
                    bottom = -(noisePerPhase/2);
                    %         size(top)
                    %         size(bottom)
                    %         size(mn)
                    %         size([1:size(luminanceDataSegment,1)])
                    errorbar([1:size(luminanceDataSegment,1)], mn, top, bottom);

                    plot(mn, 'r');

                    hold off;

                end
            end
        end
        
        function out=getAnalysisFields(s)
            %list of fields inside stimDetails, that are desired for analysis, and
            %should be in complied records

            out={'correctionTrial','.stimDetails.correctionTrial','int8';...
                'correctResponseIsLeft','.stimDetails.correctResponseIsLeft','int8';...
                'targetContrast','.stimDetails.targetContrast','double';...
                'targetOrientation','.stimDetails.targetOrientation','double';...
                'flankerContrast','.stimDetails.flankerContrast','double';...
                'flankerOrientation','.stimDetails.flankerOrientation(1)','double';... %need to deal with when there is more than 1 flanker!
                'deviation','.stimDetails.deviation','double';...
                'devPix','.stimDetails.devPix','double';...
                'targetPhase','.stimDetails.targetPhase','double';...
                'flankerPhase','.stimDetails.flankerPhase','double';...
                'currentShapedValue','.stimDetails.currentShapedValue','double';...
                'pixPerCycs','.stimDetails.pixPerCycs','double';...
                'redLUT','.stimDetails.LUT(end,1)','double';...
                'stdGaussMask','.stimDetails.stdGaussMask','double';...
                'maxCorrectForceSwitch','.stimDetails.maxCorrectForceSwitch','double'}
        end
        
        function out=getCalibration(t)

            out=t.calib;

        end
        
        function out=getCalibrationFrame(t)

            out=t.calib.frame;
        end
        
        function positionFrame = getCalibrationPositionFrame(t)  % 
            % positionFrame=getCalibrationPositionFrame(trialManager)

            width=t.maxWidth ;
            height=t.maxHeight;

            % switch type
            %    case 'fluxCapacitor'

            %        %old code centered -  definitely works
                    positionFrame = zeros(height, width, 'uint8');
            %         if 0
            %             [leftRight, topDown] = meshgrid( -width/2:1:width/2-1, -height/2:1:height/2-1);
            %             [locationBOTTOM] = ((topDown == round(leftRight*tan(pi/6)) | topDown == round(-leftRight*tan(pi/6))) & (topDown > 0));
            %             [locationTOP] = ((leftRight == 0)& (topDown < 0));
            %             positionFrame(locationBOTTOM | locationTOP) = 255;
            %         end

                    %new code general - probably works
                    xPos=0.5;
                    yPos=0.5;
                    pixFromLeft=round(xPos*width);  % round or floor or ceil?  test fraction with 1/3 of a pixel and 2/3 and 0.5...
                    pixFromRight=round((1-xPos)*width);
                    pixFromTop=round(yPos*height);
                    pixFromBottom=round((1-yPos)*height);
                    [leftRight, topDown] = meshgrid( -pixFromLeft:pixFromRight-1, -pixFromTop:pixFromBottom-1);
                    [locationBOTTOM] = ((topDown == round(leftRight*tan(pi/6)) | topDown == round(-leftRight*tan(pi/6))) & (topDown > 0));
                    [locationTOP] = ((-0.5 <= leftRight & leftRight <= 0.5)& (topDown < 0));
                    positionFrame(locationBOTTOM | locationTOP) = 255;

                    %oneline:
                    %positionFrame(((topDown == round(leftRight*tan(pi/6)) | topDown == round(-leftRight*tan(pi/6))) & (topDown > 0)) | ((-0.5 <= leftRight & leftRight <= 0.5)& (topDown < 0)))=255;
            %    otherwise
            %        error(' bad positionFrame type')
            %end



            % function trialManager = getSpyderPositionImage(trialManager)
            % 
            % This code should be intergrated into the trialManager.calibrate
            %
            % switch trialManager.calib.method
            % 
            %     case 'sweepAllPhasesPerTargetOrientation'
            %         
            %     case 'sweepAllFlankers'
            %     otherwise
            %       numPatchesInserted=1; 
            %       szY=size(trialManager.cache.goRightStim,1);
            %       szX=size(trialManager.cache.goRightStim,2);
            %     
            %       pos=round...
            %       ...%yPosPct                      yPosPct                    xPosPct                   xPosPct
            %     ([ stimulus.targetYPosPct       stimulus.targetYPosPct        xPosPct                   xPosPct;...                   %target
            %       .* repmat([ height            height                        width         width],numPatchesInserted,1))...          %convert to pixel vals
            %       -  repmat([ floor(szY/2)      -(ceil(szY/2)-1 )             floor(szX/2) -(ceil(szX/2)-1)],numPatchesInserted,1); %account for patch size
            %          
            %       if any(any((pos(:,1:2)<1) | (pos(:,1:2)>height) | (pos(:,3:4)<1) | (pos(:,3:4)>width)))
            %           width
            %           height
            %           pos
            %           error('At least one image patch is going to be off the screen.  Make patches smaller or closer together.')
            %       end
            % 
            % 
            %       %stim class is inherited from flankstim patch
            %       %just check flankerStim, assume others are same
            %       if isinteger(trialManager.cache.flankerStim) 
            %         details.mean=stimulus.mean*intmax(class(trialManager.cache.flankerStim));
            %       elseif isfloat(trialManager.cache.flankerStim)
            %           details.mean=stimulus.mean; %keep as float
            %       else
            %           error('stim patches must be floats or integers')
            %       end
            %       stim=details.mean(ones(height,width,3,'uint8')); %the unit8 just makes it faster, it does not influence the clas of stim, rather the class of details determines that
            %       
            %       
            %       insertPatch
            % end
            %
            % positionFrame=stim
        end
        
        function t=getCalibrationSettings(t, method)


                    %determine orientations used
            orientations = unique([t.goRightOrientations t.goLeftOrientations t.flankerOrientations t.distractorOrientations t.distractorFlankerOrientations]);
            t.calib.orientations=orientations;

            switch method
                 case 'uncalibrated'
                    t.calib.contrastScale=ones(size(orientations));
                case 'default'
                    t.calib.contrastScale=[1 0.95]
                    error('confirm defaults');
                case 'mostRecent'
                     error('loads from the appropriate location-- unwritten code');
                case 'calibrateNow'
                     error('should be doing calibration here-- unwritten code');
                otherwise
                    method
                    error('unknown method');
            end

        end
        
        function out=getCalibrationStruct(t)

            out =t.calib;
        end
        
        function [parameterStructure, super] = getDefaultParameters(tm)

            % create a parameter structure and a super structure with default parameters

            % super.soundMgr            =soundManager({soundClip('correctSound','allOctaves',[400],20000), ...
            %     soundClip('keepGoingSound','allOctaves',[300],20000), ...
            %     soundClip('trySomethingElseSound','gaussianWhiteNoise'), ...
            %     soundClip('wrongSound','tritones',[300 400],20000)});

            super.soundMgr = makeStandardSoundManager();


            s.maxWidth                =1024;
            s.maxHeight               =768;
            s.scaleFactor             =[1 1]; %1?
            s.interTrialLuminance     =0.5;


                    s.goRightOrientations = [0,pi/2]; %choose a random orientation from this list
                    s.goLeftOrientations =  [0,pi/2];
                    s.flankerOrientations = [0,pi/2]; 
                    s.distractorOrientations = [0];
                    s.distractorFlankerOrientations = [0];
                    s.topYokedToBottomFlankerOrientation =1;

                    s.goRightContrast = [1];   
                    s.goLeftContrast =  [1];   
                    s.flankerContrast = [0.25];
                    s.distractorContrast = 1;
                    s.distractorFlankerContrast = 0;
                    s.topYokedToBottomFlankerContrast =1;

                    numPhase = 4; 
                    s.phase= 2*pi * [0: numPhase-1]/numPhase;
                    s.flankerYokedToTargetPhase =0;


                    s.pixPerCycs = 32;
                    s.stdGaussMask = 1/16;
                    s.stdsPerPatch = 4;
                    s.thresh = 0.001;
                    s.gratingType='sine';
                    s.gaborNormalizeMethod = 'normalizeVertical';

                    s.xPositionPercent = 0.5;
                    s.targetYPosPct = 0.5;
                    s.flankerOffset = 5; %distance in stdGaussMask  (0-->5.9 when std is 1/16)
                    s.positionalHint=0; %fraction of screen hinted.
                    s.xPosNoise=0; %
                    s.yPosNoise=0; %
                    s.cuePercentTargetEcc = 0.6; 

                    s.framesTargetOnOff=int8([20 60]);
                    s.framesFlankerOnOff=int8([10 60]);

                    s.typeOfLUT = 'useThisMonitorsUncorrectedGamma';
                    s.rangeOfMonitorLinearized=[0 1];
                    s.mean = 0.5;              %normalized luminance - if not 0.5 then grating can be detected as mean lum changes
                    s.cueLum=0.5;              
                    s.cueSize=4;

                    s.displayTargetAndDistractor=0;
                    s.distractorYokedToTarget=1;

                    s.distractorFlankerYokedToTargetFlanker = 1;
                    s.fractionNoFlanks=0;
                    s.toggleStim = 1;
                    s.persistFlankersDuringToggle=1;

                    s.msPenaltyFlashDuration=100;
                    s.numPenaltyFlashes=int8(3);
                    s.maxDiscriminandumSecs=10;
                    s.advancedOnRequestEnd=0;
                    s.interTrialDimmingFraction=0.01;

                    s.renderMode='ratrixGeneral';

                    s.shapedParameter='positionalHint';
                    s.shapingMethod='linearChangeAtCriteria';
                    shapingValues.numSteps = uint8(6);
                    shapingValues.performanceLevel = 0.75;
                    shapingValues.numTrials = uint8([100]);
                    shapingValues.startValue = 0.2;
                    shapingValues.currentValue = shapingValues.startValue;
                    shapingValues.goalValue = 0.1;


                    s.shapingValues = shapingValues;
                    s.LUT=[];
                    s.cache=[];
                    s.calib=[];
                    s.stimDetails=[];

                    parameterStructure=s;
       

            super.msFlushDuration         =1000;
            super.rewardSizeULorMS        =150; %todo: ? get rid of because the reward manager has it
            super.msMinimumClearDuration  =10;
            super.msMinimumPokeDuration   =10;
            super.msPenalty               =4000; %todo: ? get rid of because the reward manager has it
            super.msRewardSoundDuration   =super.rewardSizeULorMS;

            super.msRequestRewardDuration             =0; %todo: this should move the reward manager
            super.percentCorrectionTrials             =.5; %todo: this should move the "correlation manager"
            super.msResponseTimeLimit                 =0;
            super.pokeToRequestStim                   =1;
            super.maintainPokeToMaintainStim          =1; %todo: ? does this still work?
            super.msMaximumStimPresentationDuration   =0;
            super.maximumNumberStimPresentations      =0;
            super.doMask                              =1;
            super.description='basicTrialManager';

            %new
            %todo: add these in?
            % super.station=                            [];
            % super.window=                             [];
            % super.ifi=                                [];
            % super.framePulsesEnabled=                 1;
            % super.manualEnabled=                      1;
            % super.manualOn=                           1;
            % super.timingCheckPct=                     [];
            % super.numFrameDropReports=                1000;
            % super.percentCorrectionTrials=            0.5;
            % super.percentRejectSameConsecutiveAnswer= [0 0 0 1];

            % parameters for reinforcement manager
            rm.type='rewardNcorrectInARow';
            rm.fractionOpenTimeSoundIsOn=0.6; %super rm
            rm.fractionPenaltySoundIsOn=1; %super rm
            rm.rewardNthCorrect=2*[20,80,100,150,250];
            rm.msPenalty=15000;  %is this in reinforcement manager?
            rm.scalar=1;
            %rm.scalarStartsCached=0;
            parameterStructure.rm=rm;
        end
        
        function out=getFeaturePatchStim(t,patchX,patchY,type,variableParam1, variableParam2, staticParams,extraParams)
            %creates matrix of images size patchY x patchX x length(variableParams1) x length(variableParams2)
            %used for inflating different object types
            %this could be a method, but it is generally useful 

            if size(staticParams, 2)~=8
                            variableParam1= variableParam1
                            variableParam2= variableParam2
                            staticParams = staticParams
                error ('wrong numbers of params will be passed to computeGabors')
            end

                switch type
                    case 'variableOrientation'
                        featurePatchStim=zeros(patchX,patchY,length(variableParam1));
                        params=staticParams;
                        %params= radius   pix/cyc  phase orientation contrast thresh xPosPct yPosPct
                         for i=1:length(variableParam1)
                            params(4)=variableParam1(i);            %4th parameter is orientation
                            %Get the right contrast...
                            index=find(variableParam1(i)==t.calib.orientations);
                            params(5)=t.calib.contrastScale(index); %5th parameter is contrast
                            featurePatchStim(:,:,i)=computeGabors(params,t.mean,patchX,patchY,t.gratingType,t.gaborNormalizeMethod,0);
                         end     
                    case 'variableOrientationAndPhase'
                        featurePatchStim=zeros(patchX,patchY,length(variableParam1), length(variableParam2));
                        params=staticParams;
                        %params= radius   pix/cyc  phase orientation contrast thresh xPosPct yPosPct
                         for i=1:length(variableParam1)

                            params(4)=variableParam1(i);            %4th parameter is orientation
                            index=find(variableParam1(i)==t.calib.orientations);
                            params(5)=t.calib.contrastScale(index); %5th parameter is contrast
                            for j = 1: length(variableParam2)
                            params(3)=variableParam2(j);            %3rd parameter is the phase
                            featurePatchStim(:,:,i,j)=computeGabors(params,t.mean,patchX,patchY,t.gratingType,t.gaborNormalizeMethod,0);
                            end
                         end 
                    otherwise
                        error(sprintf('%s is not a defined type of feature',type))
                end
                out=featurePatchStim;

            %sample call from the inflate of ifFeatureGoRightWithTwoFlank
            %     staticParams=[radius  s.pixPerCycs  s.phase    0        1    s.thresh  1/2     1/2   ];
            %     extraParams.normalizeMethod=normalizeMethod;
            %     extraParams.mean=s.mean;
            %     s.goRightStim=getFeaturePatchStim(patchX,patchY,'squareGrating-variableOrientation',s.goRightOrientations,staticParams,extraParams)
            %     s.goLeftStim= getFeaturePatchStim(patchX,patchY,'squareGrating-variableOrientation',s.goLeftOrientations, staticParams,extraParams)
            %     s.flankerStim=getFeaturePatchStim(patchX,patchY,'squareGrating-variableOrientation',s.flankerOrientations,staticParams,extraParams)
        end
        
        function frameChangeTimes=getFrameChangeTimes(t)

            A =t.framesTargetOnOff;
            B =t.framesFlankerOnOff;


            %test
            % A=int8([1 6])
            % B=int8([2 6]);

            frameChangeTimes = unique([A B]);

        end

        function out=getLUT(s);

            out=s.LUT;

        end
        
        function numBatches = getNumCalibrationBatches(trialManager)

            totalFrames = findTotalCalibrationFrames(trialManager);
            fpb = acceptableNumberOfFramesPerBatch(trialManager); 
            numBatches = ceil(totalFrames / fpb);
        end
        
        function [frameIndices] = getNumFramesNextCalibrationBatch(trialManager, batch)

            fpb = acceptableNumberOfFramesPerBatch(trialManager);
            lastBatch = getNumCalibrationBatches(trialManager);

            if batch == lastBatch
                totalFrames = findTotalCalibrationFrames(trialManager);
                frameIndices = (batch-1)*fpb+1: totalFrames;
            else
                frameIndices = (batch-1)*fpb+1: (batch)*fpb;
            end
        end
        
        function out=getOrientation(t)

            out=t.goRightOrientations;
            display('returning goRightOrientations');

        end
        
        function out=getOrientationCalibration(t);

            out=t.calib.contrastScale;

        end
        
        function out=getStimDetails(t)

            out=structize(t);
        end
        
        function out=getStimPatch(t, patch)

            switch patch
                case 'target'
                    out=t.cache.goRightStim;
                    disp('only goRightTarget returned');
                case 'flanker'
                    out=t.cache.flankerStim;
                otherwise
                    error('that patch not available');
            end

        end
        
        function t=inflate(t, applyContrastDampingToPatch)
            %method to inflate stim patches into cache

            %determine patch size
            % maxHeight=getMaxHeight(s);
            maxHeight=t.maxHeight;
            patchX=ceil(maxHeight*t.stdGaussMask*t.stdsPerPatch);  %stdGaussMask control patch size which control the radius
            patchY=patchX;

            %% DETERMINE RADIUS OF GABOR
            normalizeMethod= t.gaborNormalizeMethod;
            if t.thresh==0.001 && strcmp(normalizeMethod,'normalizeVertical')
                radius=1/t.stdsPerPatch;
            else
                radius=1/t.stdsPerPatch;
                t.thresh=t.thresh
                thresh=0.001;
                params =[radius 16 0 pi 1 thresh 1/2 1/2 ];
                grating=computeGabors(params,0.5,200,200,t.gratingType,'normalizeVertical',1);
                imagesc(abs(grating-0.5)>0.001)
                imagesc(grating)
                %error('Uncommon threshold for gabor edge; radius 1/t.stdsPerPatch normally used with thresh 0.001')

                %find std -- works if square grating
                h=(2*abs(0.5-grating(100,:)));
                plot(h)
                oneSTDboundary=find(abs(h-exp(-1))<0.01);  %(two vals)
                oneStdInPix=diff(oneSTDboundary)/2
            end

            %%
            if ~exist('applyContrastDampingToPatch','var')
                aa=0;
            else
                aa=applyContrastDampingToPatch;
            end


            %% make patches
            %     params= radius   pix/cyc      phase orientation ontrast thresh % xPosPct yPosPct
            staticParams =[radius  t.pixPerCycs  -99    -99        1    t.thresh  1/2     1/2   ];
            extraParams.normalizeMethod=normalizeMethod;
            extraParams.mean=t.mean;

            stimTypes=3; %exclude mask
            %mask=getFeaturePatchStim(t,patchX,patchY,'variableOrientationAndPhase',0,0,[radius 1000 0 0 1 t.thresh 1/2 1/2]);

            mask=computeGabors([radius 999 0 0 2 t.thresh 1/2 1/2],0,patchX,patchY,'none',t.gaborNormalizeMethod,0);  %range from 0 to 1

            goRightStim=getFeaturePatchStim(t,patchX,patchY,'variableOrientationAndPhase',t.goRightOrientations,t.phase,staticParams, setContrastScaleForOrientations(t,extraParams,t.goRightOrientations,aa));
            goLeftStim= getFeaturePatchStim(t,patchX,patchY,'variableOrientationAndPhase',t.goLeftOrientations,t.phase,staticParams, setContrastScaleForOrientations(t,extraParams,t.goLeftOrientations,aa));
            flankerStim=getFeaturePatchStim(t,patchX,patchY,'variableOrientationAndPhase',t.flankerOrientations,t.phase,staticParams, setContrastScaleForOrientations(t,extraParams,t.flankerOrientations,aa));


            if t.displayTargetAndDistractor
                %only bother rendering if you need to display the distractor and
                %distractorFlanker are unique from target & flanker
                if ~t.distractorYokedToTarget
                    distractorStim=getFeaturePatchStim(t,patchX,patchY,'variableOrientationAndPhase',t.distractorOrientations,t.phase,staticParams, setContrastScaleForOrientations(t,extraParams,t.distractorOrientations,aa));
                    stimTypes=stimTypes+1;
                else
                    distractorStim=[];
                end
                if ~t.distractorFlankerYokedToTargetFlanker
                    distractorFlankerStim =getFeaturePatchStim(t,patchX,patchY,'variableOrientationAndPhase',t.flankerOrientations,t.phase,staticParams, setContrastScaleForOrientations(t,extraParams,t.flankerOrientations,aa));
                    stimTypes=stimTypes+1;
                else
                    distractorFlankerStim=[];
                end
            else
                distractorStim=[];
                distractorFlankerStim=[];
            end


            switch t.renderMode
                case 'ratrixGeneral'

                    %     %store these as int8 for more space... (consider int16 if better CLUT exists)
                    %     %calcStim preserves class type of stim, and stim OGL accepts without rescaling
                    %     t.cache.goRightStim= uint8(double(intmax('uint8'))*(goRightStim));
                    %     t.cache.goLeftStim = uint8(double(intmax('uint8'))*(goLeftStim));
                    %     t.cache.flankerStim= uint8(double(intmax('uint8'))*(flankerStim));
                    %     t.cache.distractorStim = uint8(double(intmax('uint8'))*(distractorStim));
                    %     t.cache.distractorFlankerStim= uint8(double(intmax('uint8'))*(distractorFlankerStim));

                    %%store these as int8 for more space... (consider int16 if better CLUT exists)
                    %%calcStim preserves class type of stim, and stim OGL accepts without rescaling
                    integerType='uint8';
                    t.cache.mask = cast(double(intmax(integerType))*(mask),integerType);

                    t.cache.goRightStim= cast(double(intmax(integerType))*(goRightStim), integerType);
                    t.cache.goLeftStim = cast(double(intmax(integerType))*(goLeftStim),integerType);
                    t.cache.flankerStim= cast(double(intmax(integerType))*(flankerStim),integerType);
                    t.cache.distractorStim = cast(double(intmax(integerType))*(distractorStim),integerType);
                    t.cache.distractorFlankerStim= cast(double(intmax(integerType))*(distractorFlankerStim),integerType);

                case 'directPTB'

                    % Mask = ...
                    % another way of doing this might be to save the Mask and a single,
                    % oversized, unphased gratting for each orientation

                    %pre-catch textures
                    try

                        orientsPerType=[size(goRightStim,3) size(goLeftStim,3) size(flankerStim,3) size(distractorStim,3) size(distractorFlankerStim,3)] ;
                        phasesPerType =[size(goRightStim,4) size(goLeftStim,4) size(flankerStim,4) size(distractorStim,4) size(distractorFlankerStim,4)] ;
                        numOrients=max(orientsPerType(1:stimTypes));
                        numPhases=max(phasesPerType(1:stimTypes));
                        textures=nan(stimTypes,numOrients,numPhases);

                        integerType='uint8';
                        t.cache.mask = cast(double(intmax(integerType))*(mask),integerType);


                        cache{1}.features=cast(double(intmax(integerType))*(goRightStim), integerType);
                        cache{2}.features=cast(double(intmax(integerType))*(goLeftStim), integerType);
                        cache{3}.features=cast(double(intmax(integerType))*(flankerStim), integerType);
                        cache{4}.features=cast(double(intmax(integerType))*(distractorStim), integerType);
                        cache{5}.features=cast(double(intmax(integerType))*(distractorFlankerStim), integerType);

                        disp('pre-caching textures into PTB');
                        windowPtrs=Screen('Windows');
                        w=max(windowPtrs); %ToDo: w=t.window
                        for type=1:stimTypes
                            for o=1:orientsPerType(type)
                                for p=1:phasesPerType(type)
                                    textures(type,o,p)= screen('makeTexture',w,cache{type}.features(:,:,o,p));                                           
                                end
                            end
                        end

                        t.cache.maskTexture = screen('makeTexture',w,t.cache.mask);
                        t.cache.orientationPhaseTextures=textures;

                        uniqueRepeatDrift=1;
                        if uniqueRepeatDrift
                        %%add some more for a test
                        t.cache.A=cast(double(intmax(integerType))*(rand(1,256)),integerType);
                        t.cache.B=cast(double(intmax(integerType))*(0.5+(sin([1:256]*2*pi/6)/2)),integerType);
                        t.cache.ATex = screen('makeTexture',w,t.cache.A);
                        t.cache.BTex = screen('makeTexture',w,t.cache.B);
                        end

                    catch ex
                        sca
                        ShowCursor;
                        rethrow(ex);
                    end
        
            end
        end

        function extraParams=setContrastScaleForOrientations(t,extraParams,orientations,applyContrastDampingToPatch)
            %puts the right contrast scale for each orientation

            if isempty(t.calib.contrastScale)
                t.calib.contrastScale=ones(length(orientations));
            end

            if applyContrastDampingToPatch
                usedScale=t.calib.contrastScale
            else
                usedScale=ones(size(orientations));
            end

            for i=1:length(orientations)
                contrastScaleIndex=find(orientations(i)==t.calib.orientations);
                if isempty(contrastScaleIndex)
                    t.calib.orientations
                    orientations
                    error('an orientation present in flanker or goLeft or goRight is not present in t.calib.orientations; calibration breaks')
                end
                contrastScale(i)=usedScale(contrastScaleIndex);
            end
            extraParams.contrastScale=contrastScale;
        end
        
        function fContrast = makeContrastStruct(trialManager, fLum)


            %     fLum.targetLuminance = [];
            %     fLum.frameIndices= [];
            %     fLum.targetPhase = [];

            %     varyingParams = ...
            %     [fLum.targetOrientation;...
            %     fLum.targetContrast;...
            %     fLum.flankerContrast;...
            %     fLum.flankerOrientation;...
            %     fLum.flankerPhase;...
            %     fLum.deviation;...
            %     fLum.xPositionPercent;...
            %     fLum.yPositionPercent;...
            %     fLum.stdGaussMask;...
            %     fLum.mean]';

            dataNames = fieldnames(fLum);
            dataTemp = struct2cell(fLum); 
            dataTemp = cell2mat(dataTemp); % converting fLum into a numFields x data array

            [contexts junk contextInd] = unique(dataTemp(4:end,:)', 'rows');
            numRepeats = size(fLum.frameIndices,2) / size(unique(fLum.frameIndices),2);
            % cycles through the indices per phase (i.e two orientations: vertical and
            % horizontal)


            contrastMethod = 'std'; % this should be classified from the higher level function

            for i = 1:max(contextInd) 
                if (sum(contextInd == i)/numRepeats)~= size(trialManager.phase)
                    error('not enough phases to computer contrast structure');
                end
                % check that phase is monotonically increasing  ,   all(diff(phase) > 0) 
                measuredData = fLum.targetLuminance(contextInd == i);
                [fContrast.measuredContrast(i), fContrast.measuredMean(i), fContrast.measuredSNR(i), fContrast.measuredPeak(i), fContrast.measuredTrough(i)] = getAmplitudeFromFlum(trialManager, measuredData,  numRepeats, contrastMethod);
            end 

            fContrast.contexts = contexts;
            fContrast.dataNames = dataNames(4:end);
        end
        
        function goodEnough = qualityCheck(trialManager, luminanceData, calibrationPhase, batch)

            haveData=find(sum(~isnan(luminanceData)));
            numRecordedSoFar = length(haveData);
            % numRecordedSoFar

            goodEnough = 0;

            switch calibrationPhase
                case 'homogenousIntensity'
                    goodEnough = 1;  %only do it once
                case 'patterenedIntensity'

                    %using number of repetitions to limit
                    maxAllowed = 2;
                    if numRecordedSoFar >= maxAllowed-1
                        goodEnough = 1;
                    end

                    %alternately stop if sufficient SNR
                    contrastMethod='std';
                    plotOn = 0;
                    [amplitude, SNR] = getAmplitudeOfLuminanceData(trialManager, luminanceData(:,haveData), contrastMethod, batch, plotOn)
                    requiredSNR=60;
                    if all(SNR>requiredSNR)
                        goodEnough = 1;
                    end

                otherwise
                    error('bad phase')
            end


            % goodEnough = 1;  %only do it once
        end
        
        function seeCalibrationResults(t)

            totalFrames = findTotalCalibrationFrames(t);
            numOrientations = size(t.goRightOrientations,2);
            numPhases = size(t.phase,2);

            luminanceData=t.calib.rawData;
            validationData=t.calib.rawValidationData;

            numRepeats = size(luminanceData,2);

            if size(luminanceData, 1) ~= totalFrames
                blackWhite = luminanceData(totalFrames+1: totalFrames + 2, : );
                luminanceData = luminanceData(1: totalFrames, : );
            end

            switch t.calib.method
                case 'sweepAllPhasesPerTargetOrientation'
                    ss = [1:numPhases:totalFrames];
                    ee = [ss(2:end)-1, totalFrames];
                otherwise
                    error('not an acceptable method');
            end

            figure;
            hold on;

            for i = 1:length(ss) % for each chunk of luminance data
                luminanceDataSegment =  luminanceData(ss(i): ee(i),:);
                validationDataSegment= validationData(ss(i): ee(i),:);

                if size(luminanceDataSegment,2)>1
                    mn = mean(luminanceDataSegment');
                    Vmn = mean(validationDataSegment');
                else
                    mn = luminanceDataSegment;
                    Vmn = validationDataSegment;
                end

                %SNR(i) = amplitude(i))/stdError;


                [m n] = meshgrid( 1: size(luminanceDataSegment, 2), 1: size(luminanceDataSegment, 1));

                offset = 0.2;
                scatter(n(:)+offset, luminanceDataSegment(:),'b');
                scatter(n(:)+offset, validationDataSegment(:),'r');

                if size(luminanceDataSegment,2)>1
                    noisePerPhase = std(luminanceDataSegment')./sqrt(numRepeats);
                    validationNoisePerPhase = std(validationDataSegment')./sqrt(numRepeats);
                else
                    noisePerPhase = zeros(size(luminanceDataSegment,1),1);
                    validationNoisePerPhase =zeros(size(luminanceDataSegment,1),1);
                end

                top = (noisePerPhase/2);
                bottom = -(noisePerPhase/2);
                Vtop = (validationNoisePerPhase/2);
                Vbottom = -(validationNoisePerPhase/2);
                %         size(top)
                %         size(bottom)
                %         size(mn)
                %         size([1:size(luminanceDataSegment,1)])
                errorbar([1:size(luminanceDataSegment,1)], mn, top, bottom,'b');
                errorbar([1:size(luminanceDataSegment,1)], mn, Vtop, Vbottom,'r');

                if i==1
                    plot(mn, 'b');
                    plot(Vmn, 'r');
                else
                    plot(mn, 'k');
                    plot(Vmn, 'k');
                end

            end

        end
        
        function  [a b c z d e f g h p pD pF] = selectStimulusParameters(t)

            frameInd=t.calib.frame; % total numer of possible images with the given method



            numTargetOrientations = size(t.goRightOrientations,2);
            numTargetPhases = size(t.phase,2);
            numFlankerOrientations=size(t.flankerOrientations,2);
            numFlankerPhases = size(t.phase,2);

            %         numFlankerOrientations=size(stimulus.flankerOrientations,2);
            %         numTargetContrast=size(stimulus.goRightContrast,2);      
            %         numFlankerContrast=size(stimulus.flankerContrast,2);
            %         numFlankerOffset=size(stimulus.flankerOffset,2);

            %             a=Randi(size(t.goRightOrientations,2));
            %             b=Randi(size(t.goLeftOrientations,2));
            %             c=Randi(size(t.flankerOrientations,2));
            %             z=Randi(size(t.distractorOrientations,2));
            %             d=Randi(size(t.goRightContrast,2));      %
            %             e=Randi(size(t.goLeftContrast,2));
            %             f=Randi(size(t.flankerContrast,2));
            %             g=Randi(size(t.distractorContrast,2));
            %             h=Randi(size(t.flankerOffset,2));
            %             p=Randi(size(t.phase,2));
            %             pD=Randi(size(t.phase,2));
            %             pF=Randi(size(t.phase,2));


            switch t.calib.method

                case 'sweepAllPhasesPerFlankTargetContext'
                   %a = ceil(frameInd/(numPhases*numTargetOrientations));

                   p = mod(frameInd-1, numTargetPhases)+1; % outputs [1:16 1:16 1:16 ...] TargetPhase index
                   a = ceil((mod(frameInd-1, numTargetOrientations*numTargetPhases)+1)/numTargetPhases); % TargetOrientation index
                   c = ceil((mod(frameInd-1, numTargetOrientations*numTargetPhases*numFlankerOrientations)+1)/(numTargetPhases*numTargetOrientations)); % FlankerOrientation index
                   d = 1;
                   f = 1;    
                   h = 1;
                   pF = ceil((mod(frameInd-1, numTargetOrientations*numTargetPhases*numFlankerOrientations*numFlankerPhases)+1)/(numTargetPhases*numTargetOrientations*numFlankerOrientations)); %FlankerPhase index

                   z = 1;	g = 1;	pD = 1;  % Distractor Terms
                   b = a;	e = d;   % GoLeft Terms
                case 'sweepAllPhasesPerTargetOrientation'
                   c=1; z=1; d=1; e=1; f=1; h=1; g=1; pD=1; pF=1;

            %        if any([t.flankerContrast~=0 t.flankerContrast~=0  t.flankerContrast~=0])
            %            error ('flanker, distractor or flankerDistractor will be drawn on the screen, but shouldn''t')
            %        end

                   a = ceil(frameInd/numTargetPhases);
                   b = ceil(frameInd/numTargetPhases);
                   p = mod(frameInd,numTargetPhases);

                   if p==0
                       p = numTargetPhases;
                   end


                case 'sweepAllContrastsPerPhase'
                otherwise 
                    error('unknown calibration method');
            end
        end
        
        function t=setCalibrationFrame(t,frame)

            t.calib.frame=frame;
        end
        
        function t=setCalibrationMethod(t,method)

            t.calib.method=method;
        end
        
        function t=setCalibrationModeOn(t, state)

            if (state == 0)|(state == 1)
                t.calib.calibrationModeOn=state;
            else
                warning('failed to change state, must be 0 or 1');
            end
        end
      
        function t=setPixPerCycle(t, ppc, updateNow)

            if ~exist('updateNow', 'var')
                updateNow = 1;
            end

            t.pixPerCycs = ppc;

            if updateNow
            t = deflate(t);
            t = inflate(t);
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
        
        function t=setTargetOrientation(t, orientations, updateNow)

            % trialManager =setTargetOrientation(trialManager, [0, pi/2; 0, pi/2])

            if ~exist('updateNow', 'var')
                updateNow = 1;
            end

            if size(orientations,1) == 1
                orientations = repmat(orientations, 2, 1); % if only one list of orientations apply to left and right
            end 

            t.goRightOrientations = orientations(1,:);
            t.goLeftOrientations = orientations(2,:);



            if updateNow
            t = deflate(t);
            t = inflate(t);
            end
        end
        
        function t=setTypeOfLUT(t,method)

            t.typeOfLUT = method;
        end
        
        function    [parameterChanged, t]  = shapeParameter(t, trialRecords)

            parameterChanged = 0;

            %% doShape

            switch  t.shapingMethod
                case 'exponentialParameterAtConstantPerformance'
                    error('code not written yet, will be completed when Yuan returns next year after the 2nd of January');
                case 'geometricRatioAtCriteria'
                    error('code not written yet, will be completed when Yuan returns');
                case 'linearChangeAtCriteria'

                    if ~isempty(trialRecords)
                        %select appropriate trials for shaping
                        stimDetails=[trialRecords.stimDetails];
                        thisParameter=strcmp({stimDetails.shapedParameter},stimDetails(end).shapedParameter);
                        thisValue=([stimDetails.currentShapedValue]==stimDetails(end).currentShapedValue);
                        uncorrelated=~[stimDetails.correctionTrial] & ~[stimDetails.maxCorrectForceSwitch];
                        whichTrials=thisParameter&thisValue&uncorrelated;
                        trialRecords=trialRecords(whichTrials);
                    end

                    [aboveThresh ]=aboveThresholdPerformance(t.shapingValues.numTrials, t.shapingValues.performanceLevel, trialRecords);

                    if aboveThresh
                        delta = (t.shapingValues.goalValue-t.shapingValues.startValue)/double(t.shapingValues.numSteps);
                        t.shapingValues.currentValue = t.shapingValues.currentValue + delta;
                        parameterChanged = 1;
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
                    case 'positionalHint'
                        t.positinalHint = t.shapingValues.currentValue;
                    case 'stdGaussianMask'
                        t.stdGaussMask = t.shapingValues.currentValue;
                    case 'targetContrast'
                        t.targetContrast = t.shapingValues.currentValue;
                    case 'flankerContrast'
                        t.flankerContrast = t.shapingValues.currentValue;
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
        
        function isCached=stimIsCached(t)
            %method to determine if it is cached



            if isempty(t.cache)
                isCached=0;
            else
                switch t.renderMode
                    case 'ratrixGeneral'
                        if size(t.cache.goRightStim,1)>0
                            isCached=1;
                            %confirm all there
                            if size(t.cache.goRightStim,1)>0 & size(t.cache.goLeftStim,1)>0 & size(t.cache.flankerStim,1)>0
                                %okay
                            else
                                error('partially inflated stim')
                            end
                        else
                            isCached=0;
                        end
                    case 'directPTB'
                        if isempty(t.cache.orientationPhaseTextures)
                            isCached=0;
                        else
                            isCached=1;
                        end
                end
            end
        end
        
        
    end
    
end


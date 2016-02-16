function [ts_optim, ts_sfSweep, ts_ctrSweep, ts_orSweep, ts_durLimited, ts_durLimitedCtr, ts_durSweep] = createOrientationSteps_autoAdapt(svnRev,svnCheckMode,subID)


% basic details for stim
out.pixPerCycsOpt={[128],[128]};
out.pixPerCycsSweep={[16,32,64,128,256,512],[16,32,64,128,256,512]};

out.driftfrequenciesOpt={[0],[0]};

orsOpt = [45];
orsSweep = [0,3.33,6.67,10,13.33,16.67,20,45];
out.orientationsOpt={-deg2rad(orsOpt),deg2rad(orsOpt)};
out.orientationsSweep={-deg2rad(orsSweep),deg2rad(orsSweep)};

out.phasesOpt={[0 pi/4 pi/2 3*pi/4 pi],[0 pi/4 pi/2 3*pi/4 pi]};

out.contrastsOpt={1,1};
out.contrastsSweep={[0 0.05 0.1 0.15 0.2 0.3 0.4 1],[0 0.05 0.1 0.15 0.2 0.3 0.4 1]};
out.contrastsForDurs = {[0.15 1],[0.15,1]};

out.maxDurationOpt={inf,inf};
out.maxDurationLimited = {1,1};
out.maxDurationSweep={logspace(log10(0.020),log10(0.5),8),logspace(log10(0.02),log10(0.5),8)};
out.radiiOpt={0.5,0.5};
out.annuli={0,0};
out.location={[.5 .5],[0.5 0.5]};      % center of mask
out.waveform= 'sine';
out.radiusType='hardEdge';
out.normalizationMethod='normalizeDiagonal';
out.mean=0.5;
out.thresh=.00005;

[a, b] = getMACaddress();
switch b
    case 'A41F7278B4DE' %gLab-Behavior1
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    case 'A41F729213E2' %gLab-Behavior2
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    case 'A41F726EC11C' %gLab-Behavior3
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    case '7845C4256F4C' %gLab-Behavior4
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    case '7845C42558DF' %gLab-Behavior5
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    case 'A41F729211B1' %gLab-Behavior6
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    case 'BC305BD38BFB' %ephys-stim
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    case '180373337162' %ephys-data
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    case 'A41F72921700'
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    case 'F8BC128444CB' %robert-analysis
        out.maxWidth = 1920;
        out.maxHeight = 1080;
    otherwise
        a
        b
        warning('not sure which computer you are using. add that mac to this step. delete db and then continue. also deal with the other createStep functions.');
        keyboard;
end

out.scaleFactor=0;
out.interTrialLuminance=.5;
out.doCombos = true;

% details for reinforcement
out.rewardScalar = 0.2;
out.rewardSize = 50;
out.msPenalty = 5000;
out.doPostDiscrim = false;
out.doPostDiscrimDurSweep = true;


out = getStimAndRewardParams(out,subID);



afc_optim = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsOpt,out.maxDurationOpt,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim);

afc_sfSweep = afcGratings(out.pixPerCycsSweep,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsOpt,out.maxDurationOpt,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim);

afc_ctrSweep = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsSweep,out.maxDurationOpt,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim);

afc_orSweep = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsSweep,out.phasesOpt,out.contrastsOpt,out.maxDurationOpt,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim);

afc_durLimited = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsOpt,out.maxDurationLimited,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrimDurSweep);

afc_durWithCtr = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsForDurs,out.maxDurationLimited,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrimDurSweep);

afc_durSweep = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsForDurs,out.maxDurationSweep,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrimDurSweep);

% sound Manager
sm=makeStandardSoundManager();
% scheduler
sch=noTimeOff(); % runs until swapper ends session

% criterion
thresholdPC=performanceCriterionLatestStreak([0.8],int16([200]));
numTrialsCrit_varCtr = numTrialsDoneCriterion(1600); % 1600 trials = 8 conditions * 200 trials/condition
numTrialsCrit_varOr = numTrialsDoneCriterion(1600); % 1600 trials = 8 conditions * 200 trials/condition
numTrialsCrit_varSF = numTrialsDoneCriterion(1200); % 1200 trials = 6 conditions * 200 trials/condition
numTrialsCrit_DurLim = numTrialsDoneCriterion(400); % 400 trials = 2 conditions * 200 trials
numTrialsCrit_varDur = numTrialsDoneCriterion(1600); % 1600 trials = 8 conditions * 200 trials/condition

% reinf
percentCorrectionTrials = 0.3;

rewardSizeULorMS = 50;
requestRewardSizeULorMS = 10;
noRequestRewardSizeULorMS = 0;
requestMode               ='first';
msPenalty                 =5000;
fractionOpenTimeSoundIsOn =0.1;
fractionPenaltySoundIsOn  =0.1;
scalar                    =1;
msAirpuff                 =msPenalty;

minRewardScalar = 0.1;
minPenaltyMS = 2500;
maxPenaltyMS = 25000;
targetTrialRate = 200;
targetPctCorrect = .85;
adaptationMethod.type = 'staircase';
adaptationMethod.frequency = 500;
adaptationMethod.checkEveryType = 'trials';
adaptationMethod.stepSizeScalar = 0.05;
adaptationMethod.stepSizePenalty = 1000;

constantRewardsWithRequest=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,...
    msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);  %% rewardScalar, msPenalty are arguments to the function


adaptiveRewards=adaptiveReinforcement(rewardSizeULorMS,noRequestRewardSizeULorMS,requestMode,msPenalty,fractionOpenTimeSoundIsOn,...
    fractionPenaltySoundIsOn,scalar,msAirpuff,minRewardScalar,minPenaltyMS,maxPenaltyMS,adaptationMethod,targetTrialRate,targetPctCorrect);

tm= nAFC(sm, percentCorrectionTrials, adaptiveRewards);

% training step using other objects as passed in
ts_optim = trainingStep(tm, afc_optim, thresholdPC, sch, svnRev, svnCheckMode,'orOptimal');
ts_sfSweep = trainingStep(tm, afc_sfSweep, numTrialsCrit_varSF, sch, svnRev, svnCheckMode,'orSFSweep');
ts_ctrSweep = trainingStep(tm, afc_ctrSweep, numTrialsCrit_varCtr, sch, svnRev, svnCheckMode,'orCTRSweep');
ts_orSweep = trainingStep(tm, afc_orSweep, numTrialsCrit_varOr, sch, svnRev, svnCheckMode,'orORSweep');
ts_durLimited = trainingStep(tm, afc_durLimited, thresholdPC, sch, svnRev, svnCheckMode,'orDURLimited');
ts_durLimitedCtr = trainingStep(tm, afc_durWithCtr, numTrialsCrit_DurLim, sch, svnRev, svnCheckMode,'orDURLimited');
ts_durSweep = trainingStep(tm, afc_durSweep, numTrialsCrit_varDur, sch, svnRev, svnCheckMode,'orDUR_LowDur_Sweep');
end

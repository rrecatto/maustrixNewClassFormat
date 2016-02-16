function [ts_500,ts_100,ts_500LED,ts_100LED,ts_100VarCLED,ts_100VarCLEDPDPhases,ts_VarCAndLEDPDPhases] = createOrientationReturn_auto(svnRev,svnCheckMode,subID)


% basic details for stim
out.pixPerCycsOpt={[128],[128]};

out.driftfrequenciesOpt={[0],[0]};

orsOpt = [45];
out.orientationsOpt={-deg2rad(orsOpt),deg2rad(orsOpt)};

out.phasesOpt={[0 pi/4 pi/2 3*pi/4 pi],[0 pi/4 pi/2 3*pi/4 pi]};

out.contrastsOpt={1,1};
out.contrastsTest = {[0.15 1],[0.15,1]};
out.maxDurationHigh = {0.5,0.5};
out.maxDurationLow = {0.1,0.1};
out.maxDurationLowest = {0.048,0.048};

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
out.doPostDiscrim = true;


out = getStimAndRewardParams(out,subID);



%% setup basic LED Params
LEDParams.active = true;
LEDParams.numLEDs = 1;
LEDParams.IlluminationModes{1}.whichLED = 1;
LEDParams.IlluminationModes{1}.intensity = 1;
LEDParams.IlluminationModes{1}.fraction = 0.5;
LEDParams.IlluminationModes{2}.whichLED = 1;
LEDParams.IlluminationModes{2}.intensity = 0;
LEDParams.IlluminationModes{2}.fraction = 0.5;

%% stimManagers
afc_500 = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsOpt,out.maxDurationHigh,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim);

afc_100 = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsOpt,out.maxDurationLow,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim);

afc_500LED = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsOpt,out.maxDurationHigh,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim,LEDParams);

afc_100LED = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsOpt,out.maxDurationLow,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim,LEDParams);

afc_100VarCLED = afcGratings(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsTest,out.maxDurationLow,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim,LEDParams);

LEDAndPostDiscrimDetails(1).phaseType = 'post-discrim';
LEDAndPostDiscrimDetails(1).phaseLengthInFrames = 3;
LEDAndPostDiscrimDetails(1).LEDON = 'SameAsDiscrim';

LEDAndPostDiscrimDetails(2).phaseType = 'post-discrim';
LEDAndPostDiscrimDetails(2).phaseLengthInFrames = inf;
LEDAndPostDiscrimDetails(2).LEDON = 'Never';


afc_100VarCLEDPDPhases = afcGratingsPDPhases(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsTest,out.maxDurationLow,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim,LEDParams,LEDAndPostDiscrimDetails);

LEDParams.active = true;
LEDParams.numLEDs = 1;
LEDParams.IlluminationModes{1}.whichLED = 1;
LEDParams.IlluminationModes{1}.intensity = 1;
LEDParams.IlluminationModes{1}.fraction = 0.2;
LEDParams.IlluminationModes{2}.whichLED = 1;
LEDParams.IlluminationModes{2}.intensity = 0.75;
LEDParams.IlluminationModes{2}.fraction = 0.2;
LEDParams.IlluminationModes{3}.whichLED = 1;
LEDParams.IlluminationModes{3}.intensity = 0.5;
LEDParams.IlluminationModes{3}.fraction = 0.2;
LEDParams.IlluminationModes{4}.whichLED = 1;
LEDParams.IlluminationModes{4}.intensity = 0.25;
LEDParams.IlluminationModes{4}.fraction = 0.2;
LEDParams.IlluminationModes{5}.whichLED = 1;
LEDParams.IlluminationModes{5}.intensity = 0;
LEDParams.IlluminationModes{5}.fraction = 0.2;

afc_VarCAndLEDPDPhases = afcGratingsPDPhases(out.pixPerCycsOpt,out.driftfrequenciesOpt,out.orientationsOpt,out.phasesOpt,out.contrastsTest,out.maxDurationLowest,...
    out.radiiOpt,out.radiusType,out.annuli,out.location,out.waveform,out.normalizationMethod,out.mean,out.thresh,out.maxWidth,out.maxHeight,...
    out.scaleFactor,out.interTrialLuminance,out.doCombos,out.doPostDiscrim,LEDParams,LEDAndPostDiscrimDetails);

% sound Manager
sm=makeStandardSoundManager();
% scheduler
sch=noTimeOff(); % runs until swapper ends session

% reinf
rewardScalar = out.rewardScalar;
requestRewardSize = 0; 
rewardSize = out.rewardSize;
doAllRequests =	'first'; 
fractionSoundOn = 1; % this applies to beeps
fractionPenaltySoundOn = 0.10;  % fraction of the timeout that annoying error sound is on
msAirpuff = 0;
msPenalty = out.msPenalty;

percentCorrectionTrials = 0.5;

constantRewards=constantReinforcement(rewardSize,requestRewardSize,doAllRequests,msPenalty,fractionSoundOn,fractionPenaltySoundOn,rewardScalar,msAirpuff);

tm= nAFC(sm, percentCorrectionTrials, constantRewards);

% training step using other objects as passed in
ts_500 = trainingStep(tm, afc_500, repeatIndefinitely(), sch, svnRev, svnCheckMode,'or_500');
ts_100 = trainingStep(tm, afc_100, repeatIndefinitely(), sch, svnRev, svnCheckMode,'or_100');
ts_500LED = trainingStep(tm, afc_500LED, repeatIndefinitely(), sch, svnRev, svnCheckMode,'or_500LED');
ts_100LED = trainingStep(tm, afc_100LED, repeatIndefinitely(), sch, svnRev, svnCheckMode,'or_100LED');
ts_100VarCLED = trainingStep(tm, afc_100VarCLED, repeatIndefinitely(), sch, svnRev, svnCheckMode,'or_100VarCLED');
ts_100VarCLEDPDPhases = trainingStep(tm, afc_100VarCLEDPDPhases, repeatIndefinitely(), sch, svnRev, svnCheckMode,'or_100VarCLEDPDPhases');
ts_VarCAndLEDPDPhases = trainingStep(tm, afc_VarCAndLEDPDPhases, repeatIndefinitely(), sch, svnRev, svnCheckMode,'or_VarCAndLEDPDPhases');

end

function r = mousePhysAndBehavior_08122015(r,subjIDs,otherParams)
if ~isa(r,'ratrix')
    error('need a ratrix')
end
if ~all(ismember(subjIDs,getSubjectIDs(r)))
    error('not all those subject IDs are in that ratrix')
end

if ~exist('otherParams','var') || isempty(otherParams)
    otherParams.stepNum = 1;
end

[a,b] = getMACaddress;
switch b
    case 'BC305BD38BFB'
        maxWidth=1920;maxHeight=1080;
    otherwise
        maxWidth=1920;maxHeight=1080;
end


%% setup basic LED Params
LEDParams.active = true;
LEDParams.numLEDs = 1;
LEDParams.IlluminationModes{1}.whichLED = 1;
LEDParams.IlluminationModes{1}.intensity = 1;
LEDParams.IlluminationModes{1}.fraction = 0.5;
LEDParams.IlluminationModes{2}.whichLED = 1;
LEDParams.IlluminationModes{2}.intensity = 0;
LEDParams.IlluminationModes{2}.fraction = 0.5;

%% temporal stimuli
% full-field temporal
LEDParams.active = false;
frequencies=2.^(-1:4);phases=[0];
contrasts=[1]; durations=[3];
radius=5; annuli=0;
location=[.5 .5];
normalizationMethod='normalizeDiagonal';
mean=0.5; thresh=.00005; numRepeats=3;
scaleFactor=0;interTrialLuminance={.5,15};
doCombos={true,'twister','clock'};

changeableAnnulusCenter = false;
changeableRadiusCenter = false;
TRF= fullField(frequencies,contrasts,durations,radius,annuli,location,normalizationMethod,mean,thresh,numRepeats,...
       maxWidth,maxHeight,scaleFactor,interTrialLuminance,doCombos,changeableAnnulusCenter,changeableRadiusCenter,LEDParams);

%% gratings
% tuning for gratings
pixPerCycs={[128],[128]};
driftfreqs={[0],[0]};
ors = [0:15:90];
orientations={-deg2rad(ors),deg2rad(ors)};
phases={[0 pi/4 pi/2 3*pi/4 pi],[0 pi/4 pi/2 3*pi/4 pi]};

contrasts = {1,1};
maxDuration={0.5,0.5};
radii={1,1};annuli={0,0};location={[.5 .5],[0.5 0.5]};
waveform= 'sine';radiusType='hardEdge';normalizationMethod='normalizeDiagonal';
mean=0.5;thresh=.00005;

scaleFactor=0;
interTrialLuminance={.5,15};
doCombos = true;
doPostDiscrim = false;

maxWidth = 1920;
maxHeight = 1080;

LEDParams.active = false;
apGratings_tuning = afcGratings(pixPerCycs,driftfreqs,orientations,phases,contrasts,maxDuration,...
    radii,radiusType,annuli,location,waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,...
    scaleFactor,interTrialLuminance,doCombos,doPostDiscrim);

% basic details for stim
pixPerCycs={[128],[128]};
driftfreqs={[0],[0]};
ors = [45];
orientations={-deg2rad(ors),deg2rad(ors)};
phases={[0 pi/4 pi/2 3*pi/4 pi],[0 pi/4 pi/2 3*pi/4 pi]};

phases={0,0};
contrasts = {[0, 0.15 1],[0, 0.15,1]};
maxDurationSweep={[0.048 0.096 0.192],[0.048 0.096 0.192]};
radii={1,1};annuli={0,0};location={[.5 .5],[0.5 0.5]};
waveform= 'sine';radiusType='hardEdge';normalizationMethod='normalizeDiagonal';
mean=0.5;thresh=.00005;

scaleFactor=0;
interTrialLuminance={.5,15};
doCombos = true;
doPostDiscrim = false;

maxWidth = 1920;
maxHeight = 1080;

LEDParams.active = false;
apGratings = afcGratings(pixPerCycs,driftfreqs,orientations,phases,contrasts,maxDurationSweep,...
    radii,radiusType,annuli,location,waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,...
    scaleFactor,interTrialLuminance,doCombos,doPostDiscrim);

LEDParams.active = true;
apGratingsLED = afcGratings(pixPerCycs,driftfreqs,orientations,phases,contrasts,maxDurationSweep,...
    radii,radiusType,annuli,location,waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,...
    scaleFactor,interTrialLuminance,doCombos,doPostDiscrim,LEDParams);


%% reinforcedAutopilot
rewardSizeULorMS        =50;
requestRewardSizeULorMS =10;
requestMode='first';
msPenalty               =1000;
fractionOpenTimeSoundIsOn=1;
fractionPenaltySoundIsOn=1;
scalar=1;
msAirpuff=msPenalty;
rewardProbability = 0.1;
probConstantRewards=probabilisticConstantReinforcement(rewardSizeULorMS,rewardProbability,requestRewardSizeULorMS,requestMode,msPenalty,...
    fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);
constantRewards=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,msPenalty,...
    fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);
percentCorrectionTrials=.5; sm=makeStandardSoundManager();
eyeController=[];
frameDropCorner={'off'};dropFrames=false;
displayMethod='ptb'; requestPort='none'; 
saveDetailedFramedrops=false; delayManager=[]; responseWindowMs=[]; showText='light';

ap=reinforcedAutopilot(percentCorrectionTrials,sm,constantRewards,eyeController,frameDropCorner,dropFrames,...
    displayMethod,requestPort,saveDetailedFramedrops,delayManager,responseWindowMs,showText);

apProbReward=reinforcedAutopilot(percentCorrectionTrials,sm,probConstantRewards,eyeController,frameDropCorner,dropFrames,...
    displayMethod,requestPort,saveDetailedFramedrops,delayManager,responseWindowMs,showText);

%% trainingsteps

svnRev={'svn://132.239.158.177/projects/bsriram/Ratrix/branches/multiTrodeStable'};
svnCheckMode='session';


ts{1}= trainingStep(apProbReward,  apGratings_tuning, numTrialsDoneCriterionLatestStreak(150), noTimeOff(), svnRev, svnCheckMode,'gratings');
ts{2}= trainingStep(apProbReward,  apGratingsLED, repeatIndefinitely(), noTimeOff(), svnRev, svnCheckMode,'gratings_LED');
ts{3}= trainingStep(ap,  TRF, repeatIndefinitely(), noTimeOff(), svnRev, svnCheckMode,'trf');%temporal response function only slow temp freqs

p=protocol('mousePhysAndBehavior',{ts{1:3}});
stepNum=uint8(otherParams.stepNum);

for i=1:length(subjIDs),
    subj=getSubjectFromID(r,subjIDs{i});
    [subj, r]=setProtocolAndStep(subj,p,true,false,true,stepNum,r,'mousePhysAndBehavior','bas');
end


end
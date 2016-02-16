function pMouseTraining_bias = mouseTraining_bias(subID)
%% This protocol enables the following tasks:
% 1. biasL
% 2. biasR

% details for each subject are internally modifiable. 
% define subjects


% define ratrix version to use
svnRev={''};
svnCheckMode='none';


[orBiasL, orBiasR, orWithCorr] = createOrientationSteps_biased(svnRev,svnCheckMode,subID);

%%%%%%%%%%% FINALLY make a protocol and put rats on it %%%%%%%%%%%%%%%%%

% here is the protocol
descriptiveString='mouseTraining_biased';
looped = true;
pMouseTraining_bias = protocol(descriptiveString,{orBiasL, orBiasR, orWithCorr},looped);
end


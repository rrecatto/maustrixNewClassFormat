function pMouseTraining_OD = mouseTraining_Return(subID)
%% This protocol enables the following tasks:
% 1. stochastic free drinks
% 2. earned free drinks
% 3. object recognition 1
% 4. 45 and -45 degrees orientation task

% details for each subject are internally modifiable. 
% define subjects

ValidTestSubject={'demo1','999'};

% define ratrix version to use
svnRev={''};
svnCheckMode='none';
[~, ~, ~, ~, fd_Alt] = createFreeDrinksStepsAG_auto_Lever(svnRev,svnCheckMode,subID);

[or_500, or_100, or_500LED, or_100LED, or_100VarCLED, or_100VarLEDPDPhases, or_VarCAndLEDPDPhases] = createOrientationReturn_auto(svnRev,svnCheckMode,subID);

[or_optim] = createOrientationSteps_auto(svnRev,svnCheckMode,subID);

%%%%%%%%%%% FINALLY make a protocol and put rats on it %%%%%%%%%%%%%%%%%

% here is the protocol
descriptiveString='mouseTraining_Return';
pMouseTraining_OD = protocol(descriptiveString,{fd_Alt,or_500,or_100,or_500LED,or_100LED,or_100VarCLED,or_100VarLEDPDPhases,or_optim,or_VarCAndLEDPDPhases...
    });
end


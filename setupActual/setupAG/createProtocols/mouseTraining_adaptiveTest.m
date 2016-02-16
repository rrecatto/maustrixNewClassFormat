function pMouseTraining_adaptiveTest = mouseTraining_adaptiveTest(subID)
%% This protocol enables the following tasks:
% 1. object recognition

% details for each subject are internally modifiable. 
% define subjects

% define ratrix version to use
svnRev={''};
svnCheckMode='none';

[ts_obj_with_req, ts_obj, ts_obj2]=createObjectTrialSteps_adaptive(svnRev,svnCheckMode,subID);

%%%%%%%%%%% FINALLY make a protocol and put rats on it %%%%%%%%%%%%%%%%%

% here is the protocol
descriptiveString='mouseTraining_Motion';
pMouseTraining_adaptiveTest = protocol(descriptiveString,{ts_obj_with_req, ts_obj, ts_obj2});
end


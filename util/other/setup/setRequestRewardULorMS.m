function setRequestRewardULorMS(ids,val,stepNum,comment,auth)
if ~exist('auth','var')
    auth='unspecified'; %bad idea?
end

if ~exist('comment','var')
    comment='';
end

if ~exist('stepNum','var') || isempty(stepNum)
    stepNum='all';
end

setReinforcementParam('requestRewardULorMS',ids,val,stepNum,comment,auth);

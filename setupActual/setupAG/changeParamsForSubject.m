function changeParamsForSubject

pReturn = @mouseTraining_Return;
% pOD = @mouseTraining_OD;
pBias = @mouseTraining_bias;
% pOD_Rec = @mouseTraining_OD_Rec;
pAdaptiveTest = @mouseTraining_OD_RecAdapt;

%% gLab-Behavior 1
mac =  'A41F7278B4DE';

remoteFileLocation = '\\ghosh-nas.ucsd.edu\ghosh\Behavior\changeParams';

changeParamsFile = fullfile(remoteFileLocation,[mac '.mat']);
clear subjectChanges
try
    temp = load(changeParamsFile);
    subjectChanges = temp.subjectChanges;
    if ~isempty(subjectChanges)
        disp('why didnt we run this through?');
        keyboard;
    end
catch ex
    if strcmp(ex.identifier,'MATLAB:load:couldNotReadFile')
        % probably because there exists no mac.mat file
        subjectChanges = {};
    end
end

subjectID = '272';
% sub = subject(subjectID,'mouse','c57bl/6j','male','10/26/2014','unknown','a 10/26/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% sent back to step 3 7/15
% auto graduate to orientation - not sure why failing
% increased rew and timeout 8/20
% reduce reward to try to get to do more trials 8/25
% reduced reward and timeout 8/31
% increased reward and timeout 9/8
% reduced reward and timeout to increase tr rates
% moved to adaptive to try to improve tr rates and perf 9/30

subjectID = '266';
% sub = subject(subjectID,'mouse','c57bl/6j','male','12/30/2014','unknown','a 12/30/2014','Jackson Laboratories','ChatChR2XVIP','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% reduce rewards to 0.2 7/15
% reduced reward to 0.2 7/21
% increased timeout for improved performance 8/20
% reduced timeout 8/31
% increased reward and timeout to improve performance 9/20
% moved to pAdaptive 9/30

       
subjectID = '270';
% sub = subject(subjectID,'mouse','c57bl/6j','male','10/01/2014','unknown','a 10/01/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% sent back to step 3 7/15
% moved to request reward trials to increase water consumption 7/30
% increased timeout for improved perf 8/20
% reduced reward and timeout 8/31
% increase timeout 9/3
% increase timeout to 15s 9/8
% reduced reward and timeout to increase trial rates 9/20
% moved to pAdaptive 9/30


subjectID = '271';
% sub = subject(subjectID,'mouse','c57bl/6j','male','10/01/2014','unknown','b 10/01/2014','Jackson Laboratories','Som-cre','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% reduced reward to 0.2 % 7/15
% increaed timoue for improved performance 8/20
% reduced timeout to 7.5 s 8/31
% reduce reward and timeout 9/3 to increase trials
% increase reward and timeout 9/8
% moved to pAdaptive 9/30

subjectID = '276';
% sub = subject(subjectID,'mouse','c57bl/6j','male','11/03/2014','unknown','a 11/03/2014','Jackson Laboratories','Pv-cre','none');
% subjectChange = {subjectID,'pAdaptiveTest',6};
% subjectChanges{end+1} = subjectChange;
% moved 276 to step 3 7/15
% increased penalty to 15 s 8/20
% reduced timeout 8/31
% increase timeout to 10 s 9/3
% increase timeout to 20s
% increased rewrad to 0.5 and timeout to 25s

subjectID = '999';
% sub = subject(subjectID,'mouse','c57bl/6j','male','11/03/2014','unknown','unknown','Jackson Laboratories','none','none');
% subjectChange = {subjectID,'pOD','step'};
% subjectChanges{end+1} = subjectChange;

save(changeParamsFile,'subjectChanges');
clear subjectChanges;
%% gLab-Behavior 2
mac =  'A41F729213E2';

remoteFileLocation = '\\ghosh-nas.ucsd.edu\ghosh\Behavior\changeParams';

changeParamsFile = fullfile(remoteFileLocation,[mac '.mat']);
clear subjectChanges
try
    temp = load(changeParamsFile);
    subjectChanges = temp.subjectChanges;
    if ~isempty(subjectChanges)
        disp('why didnt we run this through?');
        keyboard;
    end
catch ex
    if strcmp(ex.identifier,'MATLAB:load:couldNotReadFile')
        % probably because there exists no mac.mat file
        subjectChanges = {};
    end
end

subjectID = '273';
% sub = subject(subjectID,'mouse','c57bl/6j','male','10/26/2014','unknown','b 10/26/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% reduced reward 6/11
% auto graduate to step 5 because of poor performance 8/6/15
% reduced reward trying to improve trial rate
% increased reward and timeout 8/25
% reduced reward and timeout to increase trial rate 8/31
% reduced reward and timeout (0.1 and 5s) increase tr rate 9/20
% moved to pAdaptive 9/30

% 
%
subjectID = '267';
% sub = subject(subjectID,'mouse','c57bl/6j','male','12/30/2014','unknown','b 12/30/2014','Jackson Laboratories','ChatChR2XVIP','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% increase penalty 6/15
% reduced reward and reduced penalty 7/15
% reduced reward trying to increase trial rate 7/21
% increasing the tmeout for improving perf 8/20
% reduced timeout to 7.5 s 8/31
% increase timeout to increase performance 9-3
% increase reward and reduce timeout (does animal do fine?) 9/8
% increased reward and timeout to improve performance 9/20
% moved to pAdaptive 9/30

subjectID = '253';
% sub = subject(subjectID,'mouse','c57bl/6j','male','05/08/2014','unknown','a 05/08/2014','Jackson Laboratories','Som-cre','none');
subjectChange = {subjectID,'pOD','step'};
subjectChanges{end+1} = subjectChange;
% increased penalty for 6/15
% moved to step 3 7/21
% moved to the normal data set on biased dataset
% reduced rewa dn timeout to improve # tr 8/20
% why arent you learning? moved to pOD 8/25
% trying to increase performance 10/14
%
subjectID = '254';
% sub = subject(subjectID,'mouse','c57bl/6j','male','05/08/2014','unknown','b 05/08/2014','Jackson Laboratories','Som-cre','none');
subjectChange = {subjectID,'pOD','step'};
subjectChanges{end+1} = subjectChange;
% back to standard stimulus for 254
% sent to biasednAFC 7/15
% biasedNAFC has numTrialsDoneLatestStreak as the criterion 7/21
% increased timeout for improved perf 8/20
% why arent you learning? moved to pOD 8/25
% moved to the regular trial for Bias
% trying to increase performance 10/14

subjectID = '277';
%  sub = subject(subjectID,'mouse','c57bl/6j','male','11/03/2014','unknown','b 11/03/2014','Jackson Laboratories','Pv-cre','none');
subjectChange = {subjectID,'pOD',6};
subjectChanges{end+1} = subjectChange;
% back to standard stimulus for 254
% sent to biasednAFC 7/15
% biasedNAFC has numTrialsDoneLatestStreak as the criterion 7/21
% moved back to basic orientation 8/20 inc rew and timeout
% sent to pReturn step 1 8/31
% reduce reward and timeout to increase tr 9/3
% reduce reward 9/8
% increased timeout and reward to improce performance 9/20
% reduce timeout to 10000 10/14

subjectID = '999';
% sub = subject(subjectID,'mouse','c57bl/6j','male','11/03/2014','unknown','unknown','Jackson Laboratories','none','none');
% subjectChange = {subjectID,'pOD','step'};
% subjectChanges{end+1} = subjectChange;

save(changeParamsFile,'subjectChanges');
clear subjectChanges;
%% gLab-Behavior 3
mac =  'A41F726EC11C';
remoteFileLocation = '\\ghosh-nas.ucsd.edu\ghosh\Behavior\changeParams';

changeParamsFile = fullfile(remoteFileLocation,[mac '.mat']);
clear subjectChanges
try
    temp = load(changeParamsFile);
    subjectChanges = temp.subjectChanges;
    if ~isempty(subjectChanges)
        disp('why didnt we run this through?');
        keyboard;
    end
catch ex
    if strcmp(ex.identifier,'MATLAB:load:couldNotReadFile')
        % probably because there exists no mac.mat file
        subjectChanges = {};
    end
end

subjectID = '274';
% sub = subject(subjectID,'mouse','c57bl/6j','male','11/14/2014','unknown','a 11/14/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% moved to request reward trials - to increase water consumption
% increased timepout for improved performance 8/20
% reduced reward and timeout 8/31
% increase timeout to 10 s 9/3
% increase timneout to 15s
% increased timeout to 20s
% moved to pAdaptive 9/30

subjectID = '268';
% sub = subject(subjectID,'mouse','c57bl/6j','female','10/31/2014','unknown','a 10/31/2014','Jackson Laboratories','ChatChR2XVIP','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% reduce reward, increase penalty 7/15
% moved to step 3
% reduced reward and timeout to increase # tr 8/20
% increase reward and timeout 8/31
% reduce timeout and reward 9/8
% increased reward and timeout to improve performance 9/20
% moved to pAdaptive 9/30

subjectID = '255';
% sub = subject(subjectID,'mouse','c57bl/6j','female','04/10/2014','unknown','a 04/10/2014','Jackson Laboratories','PV-cre','none');
% subjectChange = {subjectID,'pOD','step'};
% subjectChanges{end+1} = subjectChange;
% reduced reward to 0.1 and increased penmalty 6/11
% increasing reward to 0.4 increase penalty to 20s 7/15
% moved to request reward trials - to increase water consumption
% reduced reward and reduced timeout 8/20
% increased timeout 8/25
% reduced timeout to 7.5 s 8/31

subjectID = '256';
% sub = subject(subjectID,'mouse','c57bl/6j','female','04/10/2014','unknown','b 04/10/2014','Jackson Laboratories','PV-cre','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% reduced reward and increased penalty 6/11
% increasing reward to 0.4 incrtease penalty to 20s 7/15
% moved to request reward trials - to increase water consumption
% reduced reward and timeout - make it do more trials 8/20
% increased penalty a little bit 8/25
% increase timeout to 15s 8/31
% reduce reward and timeout 9/3
% moved to pAdaptive 9/30

subjectID = '278';
% sub = subject(subjectID,'mouse','c57bl/6j','male','12/08/2014','unknown','a 12/08/2014','Jackson Laboratories','Som-cre','none');
% subjectChange = {subjectID,'pOD','step'};
% subjectChanges{end+1} = subjectChange;
% reduce reward to 0.2 7/15
% increasing timeout 8/20
% decrease timeout and reward 9/3
% increase timeout 9/8

subjectID = '999';
% sub = subject(subjectID,'mouse','c57bl/6j','male','11/03/2014','unknown','unknown','Jackson Laboratories','none','none');
% subjectChange = {subjectID,'pOD','step'};
% subjectChanges{end+1} = subjectChange;

save(changeParamsFile,'subjectChanges');
clear subjectChanges;
%% gLab-Behavior 4
mac =  '7845C4256F4C';
remoteFileLocation = '\\ghosh-nas.ucsd.edu\ghosh\Behavior\changeParams';

changeParamsFile = fullfile(remoteFileLocation,[mac '.mat']);
clear subjectChanges
try
    temp = load(changeParamsFile);
    subjectChanges = temp.subjectChanges;
    if ~isempty(subjectChanges)
        disp('why didnt we run this through?');
        keyboard;
    end
catch ex
    if strcmp(ex.identifier,'MATLAB:load:couldNotReadFile')
        % probably because there exists no mac.mat file
        subjectChanges = {};
    end
end

subjectID = '275';
% sub = subject(subjectID,'mouse','c57bl/6j','male','11/14/2014','unknown','b 11/14/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% increased timeout to 15 s 7/15
% moved to request reward trials - to increase water consumption
% reduced reward and timeout 8/20
% increased reward and timeout 8/31
% reduce reward and timeout to increase trial rates 9/3
% increased reward (0.2) and timeout (15s) 9/8
% reduced timeout to increase tr rates 9/20
% moved to adaptive to try to improve tr rate and perf 9/30

subjectID = '269';
%  sub = subject(subjectID,'mouse','c57bl/6j','female','10/31/2014','unknown','b 10/31/2014','Jackson Laboratories','ChatChR2XVIP','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% lowered reward and lowered penalty - 8/6
% increased penalty 8/20
% reduce reward and timneout 9/3
% increase reward rate and timeout 9/8
% increased reward and timeout to improve performance 9/20
% moved to pAdaptive 9/30

subjectID = '264';
% sub = subject(subjectID,'mouse','c57bl/6j','male','10/31/2014','unknown','a 10/31/2014','Jackson Laboratories','ChatChR2XVIP','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% tryingto improve # trs reducing reward 8/20
% increase timeout to make the animal perform more trials 9/3
% reduce reward (0.1) and timeout (5s) to increase tr rate 9/8
% moved to pAdaptive 9/30

subjectID = '265';
% sub = subject(subjectID,'mouse','c57bl/6j','male','10/31/2014','unknown','b 10/31/2014','Jackson Laboratories','ChatChR2XVIP','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% increase penalty 6/15
% reduced rewaard and reduced penallty 7/15
% increased timeout 8/20
% increase reward and timeout 8/31
% moved to pAdaptive 9/30

subjectID = '279';
% sub = subject(subjectID,'mouse','c57bl/6j','male','12/08/2014','unknown','b 12/08/2014','Jackson Laboratories','Som-cre','none');
% subjectChange = {subjectID,'pAdaptive',6};
% subjectChanges{end+1} = subjectChange;
% sent back to step 3 7/15
% moved to request reward trials - to increase water consumption
% increased timeout 8/20
% reduced reward and timeout 8/25
% increased timneout 8/31
% reduce reward and timeout 9/3
% increased reward and timeout to improe performance 9/20
% moved to pAdaptive 9/30


subjectID = '999';
% sub = subject(subjectID,'mouse','c57bl/6j','male','11/03/2014','unknown','unknown','Jackson Laboratories','none','none');
% subjectChange = {subjectID,'pOD','step'};
% subjectChanges{end+1} = subjectChange;

save(changeParamsFile,'subjectChanges');
clear subjectChanges;
%% gLab-Behavior 5
mac =  '7845C42558DF'; 
remoteFileLocation = '\\ghosh-nas.ucsd.edu\ghosh\Behavior\changeParams';

changeParamsFile = fullfile(remoteFileLocation,[mac '.mat']);
clear subjectChanges
try
    temp = load(changeParamsFile);
    subjectChanges = temp.subjectChanges;
    if ~isempty(subjectChanges)
        disp('why didnt we run this through?');
        keyboard;
    end
catch ex
    if strcmp(ex.identifier,'MATLAB:load:couldNotReadFile')
        % probably because there exists no mac.mat file
        subjectChanges = {};
    end
end


subjectID = '227';
% subjectChange = {subjectID,'pOD','step'};
% subjectChanges{end+1} = subjectChange;
% back on step 1 of pOD trying to remove bioased performance
% weird - whats happening to 227. increasing reward and timeout to
% check if animal can deal with the increase
% moved to step 7 to regain performance
% reduced reward and reduced timeout! 7/15
% moving animal to step 5 because he sucks at doing trials
% increased reward and timeout to improve performance

subjectID = '252';
% sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PVChR2XSOM','none');
% subjectChange = {subjectID,'pReturn',3};
% subjectChanges{end+1} = subjectChange;
% added animal to rig 5/12
% moved to pOD at 0.25 rew and 10s pen 8/20
% moved to pReturn 8/25
% moved to pReturn step 2 8/31
% reduced timeout to try to increase tr rate 9/20
% moved to step 3 on pReturn (100 ms stim) 9/30

subjectID = '259';
% subjectChange = {subjectID,'pReturn',3};
% subjectChanges{end+1} = subjectChange;
% sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PVChR2XSOM','none');
% moved to pOD at 0.25 rew and 15s pen 8/20
% moved to pReturn step 1 8/31
% reduced reward to 0.1 and timeout to 5 s
% moved to step 3 on pReturn (100 ms stim) 9/30

subjectID = '999';

save(changeParamsFile,'subjectChanges');
clear subjectChanges;
%% gLab-Behavior 6
mac =  'A41F729211B1';
remoteFileLocation = '\\ghosh-nas.ucsd.edu\ghosh\Behavior\changeParams';

changeParamsFile = fullfile(remoteFileLocation,[mac '.mat']);
clear subjectChanges
try
    temp = load(changeParamsFile);
    subjectChanges = temp.subjectChanges;
    if ~isempty(subjectChanges)
        disp('why didnt we run this through?');
        keyboard;
    end
catch ex
    if strcmp(ex.identifier,'MATLAB:load:couldNotReadFile')
        % probably because there exists no mac.mat file
        subjectChanges = {};
    end
end        

subjectID = '999';


subjectID = '280';
% sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
% subjectChange = {subjectID,'pAdaptiveTest',6};
% subjectChanges{end+1} = subjectChange;
% moved to adaptive test - step 6 9/18
% moved to adaptive step 6 9/30

subjectID = '281';
% sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
% subjectChange = {subjectID,'pAdaptiveTest',6};
% subjectChanges{end+1} = subjectChange;
% moved to adaptive test - step 6 9/18
% penalty is on for too long sent to 0.1
% moved to adaptive step 6 9/30

subjectID = '282';
% sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
% subjectChange = {subjectID,'pAdaptiveTest',5};
% subjectChanges{end+1} = subjectChange;
% moved to adaptive test - step 4 9/18
% penalty is on for too long sent to 0.1
% moved to adaptive step 5 9/30


subjectID = '283';
%  sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
% subjectChange = {subjectID,'pAdaptiveTest',6};
% subjectChanges{end+1} = subjectChange;
% moved to adaptive test - step 5 9/18
% penalty is on for too long sent to 0.1
% moved to pAdaptive 9/30



subjectID = '284';
% sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
% subjectChange = {subjectID,'pAdaptiveTest',5};
% subjectChanges{end+1} = subjectChange;
% moved to adaptive test - step 5 9/18
% penalty is on for too long sent to 0.1


subjectID = 'demo1';
% sub = subject(subjectID,'mouse','c57bl/6j','male','12/30/2012','unknown','unknown','wild caught','unknown','none');
% subjectChange = {subjectID,'pAdaptiveTest','step'};
% subjectChanges{end+1} = subjectChange;

save(changeParamsFile,'subjectChanges');
clear subjectChanges;
end
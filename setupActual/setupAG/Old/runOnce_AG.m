function runOnce_AG

dataPath=fullfile(fileparts(fileparts(getRatrixPath)),'ratrixData',filesep);

try
    [success, mac]=getMACaddress();
    if ~success
        mac='000000000000';
    end
catch
    mac='000000000000';
end

machines={{'1U',mac,[1 1 1]}};
rx=createRatrixWithDefaultStations(machines,dataPath,'localTimed');
permStorePath=fullfile(dataPath,'PermanentTrialRecordStore');
mkdir(permStorePath);
rx=setStandAlonePath(rx,permStorePath);
fprintf('created new ratrix\n')

pReturn = @mouseTraining_Return;
pOD = @mouseTraining_OD;
pOD_Rec = @mouseTraining_OD_Rec;
pBias = @mouseTraining_bias;
pAdaptiveTest = @mouseTraining_OD_RecAdapt;

switch mac
    case 'BC305BD38BFB' % ephys-stim
%         sub = subject('999','mouse','c57bl/6j','male','12/30/2012','unknown','unknown','wild caught','unknown','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD('999'),true,true,true,8,rx,'mouseTraining_OD','bas');
%         % changed protocol to variedDur and to step 5 on 7/29
       
%          sub = subject('demo1','mouse','c57bl/6j','male','12/30/2012','unknown','unknown','wild caught','unknown','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD('demo1'),true,true,true,8,rx,'mouseTraining_OD','bas');
%         % changed protocol to variedDur and to step 5 on 7/29
        
    case 'A41F7278B4DE' %gLab-Behavior1
%         subjectID = '272';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','10/26/2014','unknown','a 10/26/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,2,rx,'mouseTraining_OD','bas');
        
%         subjectID = '266';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','12/30/2014','unknown','a 12/30/2014','Jackson Laboratories','ChatChR2XVIP','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,5,rx,'mouseTraining_OD','bas');
        
%         subjectID = '270';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','10/01/2014','unknown','a 10/01/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,2,rx,'mouseTraining_OD','bas');
        
%         subjectID = '271';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','10/01/2014','unknown','b 10/01/2014','Jackson Laboratories','Som-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,2,rx,'mouseTraining_OD','bas');
        
%         subjectID = '276'; 
%         sub = subject(subjectID,'mouse','c57bl/6j','male','11/03/2014','unknown','a 11/03/2014','Jackson Laboratories','Pv-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,1,rx,'mouseTraining_OD','bas');
    case 'A41F729213E2' %gLab-Behavior2
%         subjectID = '273';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','10/26/2014','unknown','b 10/26/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,3,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '267';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','12/30/2014','unknown','b 12/30/2014','Jackson Laboratories','ChatChR2XVIP','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,5,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '253';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','05/08/2014','unknown','a 05/08/2014','Jackson Laboratories','Som-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,5,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '254';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','05/08/2014','unknown','b 05/08/2014','Jackson Laboratories','Som-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pBias(subjectID),true,true,true,1,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '277'; 
%         sub = subject(subjectID,'mouse','c57bl/6j','male','11/03/2014','unknown','b 11/03/2014','Jackson Laboratories','Pv-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,5,rx,'mouseTraining_OD','bas');

    case 'A41F726EC11C' %gLab-Behavior3
        subjectID = '274';
        sub = subject(subjectID,'mouse','c57bl/6j','male','11/14/2014','unknown','a 11/14/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
        rx = addSubject(rx, sub, 'bas');
        [sub, rx]=setProtocolAndStep(sub,pAdaptiveTest(subjectID),true,true,true,6,rx,'mouseTraining_OD','bas');

        subjectID = '268';
        sub = subject(subjectID,'mouse','c57bl/6j','female','10/31/2014','unknown','a 10/31/2014','Jackson Laboratories','ChatChR2XVIP','none');
        rx = addSubject(rx, sub, 'bas');
        [sub, rx]=setProtocolAndStep(sub,pAdaptiveTest(subjectID),true,true,true,6,rx,'mouseTraining_OD','bas');
        
        subjectID = '255';
        sub = subject(subjectID,'mouse','c57bl/6j','female','04/10/2014','unknown','a 04/10/2014','Jackson Laboratories','PV-cre','none');
        rx = addSubject(rx, sub, 'bas');
        [sub, rx]=setProtocolAndStep(sub,pAdaptiveTest(subjectID),true,true,true,6,rx,'mouseTraining_OD','bas');
        
        subjectID = '256';
        sub = subject(subjectID,'mouse','c57bl/6j','female','04/10/2014','unknown','b 04/10/2014','Jackson Laboratories','PV-cre','none');
        rx = addSubject(rx, sub, 'bas');
        [sub, rx]=setProtocolAndStep(sub,pAdaptiveTest(subjectID),true,true,true,6,rx,'mouseTraining_OD','bas');
        
        subjectID = '278'; 
        sub = subject(subjectID,'mouse','c57bl/6j','male','12/08/2014','unknown','a 12/08/2014','Jackson Laboratories','Som-cre','none');
        rx = addSubject(rx, sub, 'bas');
        [sub, rx]=setProtocolAndStep(sub,pAdaptiveTest(subjectID),true,true,true,6,rx,'mouseTraining_OD','bas');
        
        subjectID = '999'; 
        sub = subject(subjectID,'virtual','none','none','02/27/2014','unknown','unknown','Jackson Laboratories','none','none');
        rx = addSubject(rx, sub, 'bas');
        [sub, rx]=setProtocolAndStep(sub,pOD('999'),true,true,true,5,rx,'mouseTraining_OD','bas');

    case '7845C4256F4C' %gLab-Behavior4
%         subjectID = '275';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','11/14/2014','unknown','b 11/14/2014','Jackson Laboratories','Pv-Chr2XSom-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,2,rx,'mouseTraining_OD','bas');
        
%         subjectID = '269';
%         sub = subject(subjectID,'mouse','c57bl/6j','female','10/31/2014','unknown','b 10/31/2014','Jackson Laboratories','ChatChR2XVIP','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,4,rx,'mouseTraining_OD','bas');
        
%         subjectID = '264';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','10/31/2014','unknown','a 10/31/2014','Jackson Laboratories','ChatChR2XVIP','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,4,rx,'mouseTraining_OD','bas');
        
%         subjectID = '265';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','10/31/2014','unknown','b 10/31/2014','Jackson Laboratories','ChatChR2XVIP','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,4,rx,'mouseTraining_OD','bas');
        
%         subjectID = '279'; 
%         sub = subject(subjectID,'mouse','c57bl/6j','male','12/08/2014','unknown','b 12/08/2014','Jackson Laboratories','Som-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,1,rx,'mouseTraining_OD','bas');

    case '7845C42558DF' %gLab-Behavior5
       
%         subjectID = '227';
%         sub = subject(subjectID,'mouse','c57bl/6j','female','04/03/2013','unknown','a 04/03/2013','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD('227'),true,true,true,6,rx,'mouseTraining_OD','bas');
        
%         subjectID = '247';
%         sub = subject(subjectID,'mouse','c57bl/6j','female','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD('247'),true,true,true,6,rx,'mouseTraining_OD','bas');
        
        
%         subjectID = '249';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD('249'),true,true,true,6,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '999';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD('999'),true,true,true,5,rx,'mouseTraining_OD','bas');
%         
%         subjectID = 'demo1';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD('999'),true,true,true,3,rx,'mouseTraining_OD','bas');
    case 'A41F729211B1' %gLab-Behavior6
        
%         sub = subject('999','virtual','none','none','02/27/2014','unknown','unknown','Jackson Laboratories','none','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD_Rec('999'),true,true,true,5,rx,'mouseTraining_OD','bas');
%         
%         subjectID = 'demo1';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD_Rec(subjectID),true,true,true,3,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '280';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD_Rec(subjectID),true,true,true,1,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '281';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD_Rec(subjectID),true,true,true,1,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '282';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD_Rec(subjectID),true,true,true,1,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '283';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD_Rec(subjectID),true,true,true,1,rx,'mouseTraining_OD','bas');
%         
%         subjectID = '284';
%         sub = subject(subjectID,'mouse','c57bl/6j','male','02/27/2014','unknown','a 02/27/2014','Jackson Laboratories','PV-cre','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD_RecsubjectID),true,true,true,1,rx,'mouseTraining_OD','bas');
%         
        
    case 'A41F72921700' %bas - workstation
%         sub = subject('999','virtual','none','none','02/27/2014','unknown','unknown','Jackson Laboratories','none','none');
%         rx = addSubject(rx, sub, 'bas');
%         [sub, rx]=setProtocolAndStep(sub,pOD('999'),true,true,true,5,rx,'mouseTraining_OD','bas');
%         
    case 'F8BC128444CB' %robert - analysis
        sub = subject('demo1','virtual','none','none','07/22/2015','unknown','unknown','Jackson Laboratories','none','none');
        rx = addSubject(rx,sub,'bas');
        [sub, rx]=setProtocolAndStep(sub,pAdaptiveTest('demo1'),true,true,true,8,rx,'mouseTraining_OD','bas');
        
    otherwise
        warning('not sure which computer you are using. add that mac to this step. delete db and then continue. also deal with the other createStep functions.');
        keyboard;
end

end
classdef ratrix
    properties
        serverDataPath = '';
        dbpath = '';
        subjects = {};
        boxes = {};
        assignments = {};
        standAlonePath = '';
        creationDate = '';
    end
    
    methods
        function r = ratrix(varargin)
            switch nargin
                case 0
                    % pass
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'ratrix'))
                        r = varargin{1};
                    else
                        error('Input argument is not a ratrix object')
                    end
                case 2
                    r = establishDB(r,varargin{1},varargin{2});
                case 3
                    r = establishDB(r,varargin{1},varargin{2});
                    r = setStandAlonePath(r,varargin{3});
                otherwise
                    error('ratrix::unsupported number of arguments');
            end
        end
        
        function out=getSubjectIDs(r)
            out={};
            for i=1:length(r.subjects)
                out{i}=getID(r.subjects{i});
            end
        end
        
        function r=setStandAlonePath(r,path)
            if isdir(path) %can fail due to windows networking/filesharing bug, but unlikely at construction time
                r.standAlonePath = path;
                saveDB(r,0);  %alsoReplaceSubjectData = false
            else
                path
                error('Argument to setPermanentStorePath is not a directory')
            end
        end
        
        function r = addBox(r,b)
            if isa(b,'box')
                
                [member index]=ismember(getID(b),getBoxIDs(r));
                if index>0
                    error('ratrix already contains a box with that id')
                    
                else
                    n=length(r.boxes)+1;
                    r.boxes{n}=b;
                    r.assignments{getID(b)}={{},{}};
                    saveDB(r,0);
                    clearSubjectDataDir(b);
                end
                
            else
                error('argument not box object')
            end
        end
        
        function r=addStationToBoxID(r,s,b)
            bx=getBoxFromID(r,b);
            if isa(s,'station') && ~isempty(bx) && checkPath(getPath(s))
                if isempty(getStationByID(r,getID(s)))
                    if isempty(getStationsForBoxID(r,b)) || all(getPhysicalLocationForBoxID(r,b)==getPhysicalLocation(s))
                        %TODO: should also check that no other boxes are at this
                        %physical location
                        
                        if isempty(getStationByMACaddress(r,getMACaddress(s)))
                            r.assignments{b}{1}{end+1,1}=s;
                            r.assignments{b}{1}{end,2}=0;
                            saveDB(r,0);
                        else
                            error('MAC address for that station already assigned to another station in this ratrix')
                        end
                    else
                        error('box contains stations at other physical locations')
                    end
                else
                    error('station id already exists in ratrix')
                end
            else
                error('s was not a station or box id not in ratrix or couldn''t get to station path')
            end
        end
        
        function r = addSubject(r,s,author)
            if isa(s,'subject')
                [member index]=ismember(lower(getID(s)),lower(getSubjectIDs(r)));
                if index>0
                    getID(s)
                    error('ratrix already contains a subject with that id')
                    
                else
                    if litterCheck(r,s) && authorCheck(r,author)
                        r.subjects{length(r.subjects)+1}=s;
                        saveDB(r,0);
                        makeSubjectServerDirectory(r,getID(s));
                        recordInLog(r,s,sprintf('added subject %s\n%s',getID(s),display(s)),author);
                    else
                        error('litterID should be ''unknown'' or should match acquisition and birth dates of other subjects with the same litterID')
                    end
                end
            else
                error('argument not subject object')
            end
        end
        
        function out=boxIDEmpty(r,b)
            [~, index]=ismember(b,getBoxIDs(r));
            
            if index>0
                out= isempty(r.assignments{b}{2});
            else
                error('no such box id')
            end
        end
        
        function out=boxIDRunning(r,b)
            out=0;
            [~, index]=ismember(b,getBoxIDs(r));
            if index>0
                for i=1:size(r.assignments{b}{1},1)
                    out=out || r.assignments{b}{1}{i,2};
                end
            else
                error('no such box id')
            end
        end
        
        function r=commandAllBoxes(r,cmd,comment,auth,secsAcknowledgeWait)
            for i=1:length(r.boxes)
                r=commandAllBoxIDStations(r,cmd,getID(r.boxes{i}),comment,auth,secsAcknowledgeWait);
            end
        end
        
        function r=commandAllBoxIDStations(r,cmd,boxID,comment,auth,secsAcknowledgeWait)
            stationIDs=getStationIDsForBoxID(r,boxID);
            r=commandBoxIDStationIDs(r,cmd,boxID,stationIDs,comment,auth,secsAcknowledgeWait);
        end
        
        function r=commandBoxIDStationIDs(r,cmd,boxID,stationIDs,comment,auth,secsAcknowledgeWait)
            if ~ismember(cmd,{'start','stop'})
                error('cmd must be start or stop')
            end
            
            b=getBoxFromID(r,boxID);
            status=zeros(1,length(stationIDs));
            stationInds=getStationInds(r,stationIDs,boxID);
            stationStr=[];
            ackStr=[];
            
            if all(stationInds>0)
                if (strcmp(cmd,'start') && all(~stationIDsRunning(r,stationIDs))) || (strcmp(cmd,'stop') && all(stationIDsRunning(r,stationIDs)))
                    if ~boxIDEmpty(r,boxID)
                        if authorCheck(r,auth)
                            if testBoxSubjectAndStationDirs(r,b,stationIDs)
                                subIDs=r.assignments{boxID}{2};
                                theTime=clock;
                                
                                for i=1:length(stationIDs)
                                    stationID=stationIDs(i);
                                    if strcmp(cmd,'start')
                                        cmdStr='starting';
                                        if writeObjectsToStationAndStart(r,b,stationID)
                                            % dan hill recommended the following and it works! http://www.sysinternals.com/Utilities/PsTools.html
                                            %[status, result]=dos('"C:\Documents and Settings\Rlab\Desktop\PsTools\psexec" \\rlab_rig1b -u rlab -p Pac3111 matlab')
                                            %    -d         Don't wait for process to terminate (non-interactive).
                                            %     -w         Set the working directory of the process (relative to remote computer).
                                            %      -priority  Specifies -low, -belownormal, -abovenormal, -high or -realtime to run the process at a different priority.
                                            % psexec [\\computer[,computer2[,...]
                                            % PsKill - kill processes by name or process ID
                                            % PsInfo - list information about a system
                                            % PsList - list detailed information about processes
                                            % PsShutdown - shuts down and optionally reboots a computer
                                            % PsSuspend - suspends processes
                                            %Note that the password is transmitted in clear text to the remote system.
                                            
                                            % > the other useful command is "net use \\machine password /USER:username" which logs you into a remote machine.
                                            % > the pattern is:
                                            % >
                                            % > "net use ..."  to log on
                                            % > copy files over
                                            % > psexec to run your program
                                            % > pslist to see if its done
                                            % > pskill to suddently end the session
                                            
                                            status(i)=1;
                                            if status(i)
                                                r.assignments{boxID}{1}{stationInds(i),2}=1;
                                            else
                                                error('could not start matlab process for station')
                                            end
                                        else
                                            error('cannot send objects to station or cannot write to station control directory')
                                        end
                                        
                                    elseif strcmp(cmd,'stop')
                                        cmdStr='stopping';
                                        if stopStation(r,b,stationID)
                                            status(i)=1;
                                            r.assignments{boxID}{1}{stationInds(i),2}=0;
                                        else
                                            error('cannot stop station')
                                        end
                                        
                                    else
                                        error('unrecognized command')
                                    end
                                end
                                
                                saveDB(r,0);
                                pause(secsAcknowledgeWait);
                                
                                for i=1:length(stationIDs)
                                    if status(i)
                                        ack(i) = checkStationAcknowledgeSince(r,getStationByID(r,stationIDs(i)),theTime);
                                        if ~ack(i)
                                            warning('station failed to acknowledge command')
                                        end
                                        stationStr=[stationStr ' ' num2str(stationIDs(i))];
                                        ackStr=[ackStr ' ' num2str(ack(i))];
                                    end
                                end
                                
                                for sid=1:length(subIDs)
                                    subID=subIDs{sid};
                                    sub=getSubjectFromID(r,subID);
                                    
                                    [p,i]=getProtocolAndStep(sub);
                                    k=getNumTrainingSteps(p);
                                    
                                    recordInLog(r,sub,sprintf('%s: %s stations [%s] for subject %s in box %d on step %d/%d of protocol %s. station acknowledgements [%s] after %g secs.',comment,cmdStr,stationStr,subID,boxID,i,k,getName(p),num2str(ackStr),secsAcknowledgeWait),auth);
                                end
                                
                            else
                                error('cannot access station or box subject directory')
                            end
                        else
                            error('author does not authenticate')
                        end
                    else
                        error('box has no subjects')
                    end
                else
                    %strcmp(cmd,'start')
                    %stationIDsRunning(r,stationIDs)
                    %all(~stationIDsRunning(r,stationIDs))
                    error('to start, all stations must be stopped.  to stop, all stations must be running.')
                end
            else
                error('box doesn''t contain all those stations')
            end
        end
        
        function r=decache(r)
            for i=1:length(r.subjects)
                r.subjects{i}=decache(r.subjects{i});
            end
        end
        
        function d=display(r)
            d=['ratrix\n\tdatabase:\t' strrep(r.dbpath,'\','\\') '\n\tserver path:\t' strrep(r.serverDataPath,'\','\\')];
            d=[d '\n\tboxes:\n\t'];
            for i=1:length(r.boxes)
                d=[d '\t' strrep(display(r.boxes{i}),'\','\\') '\n\t'];
                stns=getStationsForBoxID(r,getID(r.boxes{i}));
                for stnNum=1:length(stns)
                    d=[d '\t\t' strrep(display(stns(stnNum)),'\','\\') '\n\t'];
                end
            end
            d=[d 'subjects:\n\t\t'];
            for i=1:length(r.subjects)
                d=[d getID(r.subjects{i}) ' '];
            end
            d=[d '\n\tassignments:\n'];
            boxIDs=getBoxIDs(r);
            subjectIDs=getSubjectIDs(r);
            for i=1:length(r.assignments)
                if isempty(r.assignments{i}) && ~ismember(i,boxIDs)
                    d=[d '\t\tbox ' num2str(i) ':\tno box with this id\n'];
                elseif ismember(i,boxIDs)
                    d=[d '\t\tbox ' num2str(i) ':\trunning: ' num2str(boxIDRunning(r,i)) '\tnumSubjects: ' num2str(length(r.assignments{i}{2})) '\tnumStations: ' num2str(size(r.assignments{i}{1},1)) '\n'];
                    for subN=1:length(r.assignments{i}{2})
                        if ismember(r.assignments{i}{2}{subN},subjectIDs)
                            [p k]=getProtocolAndStep(getSubjectFromID(r,r.assignments{i}{2}{subN}));
                            d=[d '\t\t\tsubject ' r.assignments{i}{2}{subN} ':\tprotocol: ' ...
                                getName(p) '\tstep: ' num2str(k) ' of ' num2str(getNumTrainingSteps(p)) '\n'];
                            %probably want to add info about how long subject has been in box, progress, trial rate etc.
                        else
                            error('box found to have subject not in ratrix')
                        end
                    end
                    for staN=1:size(r.assignments{i}{1},1)
                        %d=[d '\t\t\tstation: ' display(r.assignments{i}{1}{staN,1}) '\trunning: ' num2str(r.assignments{i}{1}{staN,2})];
                        d=[d '\t\t\tstation ' num2str(getID(r.assignments{i}{1}{staN,1})) ':\trunning: ' num2str(r.assignments{i}{1}{staN,2})];
                    end
                else
                    error('something is wrong with this ratrix''s assignments')
                end
            end
            d=sprintf(d);
            
        end
        
        function [rx ids] = emptyAllBoxes(rx,comment,author)
            ids={};
            bs=getBoxIDs(rx);
            for i=1:length(bs)
                s=getSubjectIDsForBoxID(rx,bs(i));
                for j=1:length(s)
                    ids{end+1}=s{j};
                    rx=removeSubjectFromBox(rx,s{j},bs(i),comment,author)
                end
            end
        end
        
        function r = establishDB(r,dataPath,replaceExistingDB)
            
            if ischar(dataPath)
                r.serverDataPath = dataPath;
            else
                error('ratrix:improperDataType','dataPath should be a fully resolved path string')
            end
            
            [pathstr, name, ~] = fileparts(fullfile(r.serverDataPath, filesep));
            
            if replaceExistingDB && isempty(r.creationDate)
                r.creationDate = now;
            end
            
            if ~isempty(pathstr) && isempty(name)
                fileStr = 'db.mat';
                r.dbpath = fullfile(pathstr, fileStr);
                if checkPath(pathstr)
                    found=dir(r.dbpath);
                    if isempty(found)
                        if replaceExistingDB
                            saveDB(r,1);
                        else
                            disp(r.dbpath)
                            error('ratrix:dataNotFound','no db at that location')
                        end
                    elseif length(found)==1
                        if replaceExistingDB
                            disp('found existing db, replacing')
                            saveDB(r,1);
                        else
                            disp('loading existing db')
                            startTime=GetSecs();
                            keyboard
                            saved=load(r.dbpath,'-mat');
                            disp(sprintf('done loading ratrix db: %g s elapsed',GetSecs()-startTime))
                            
                            r=saved.r;
                        end
                        
                    else
                        error('unknown error -- found got %d matches',length(found))
                    end
                    
                    if ~testAllSubjectBoxAndStationDirs(r)
                        error('can''t find box, station, or subject dirs')
                    end
                    
                    %         else
                    %             error('could not find specified directory')
                    %         end
                    %         cd(currdir);
                else
                    error('could not make specified directory')
                end
            else
                pathstr
                name
                error('must provide a fully resolved path to a new or existing data base directory')
            end
            
        end
        
        function [out type]=getBasicFacts(r,displayOn)
            %returns a structure with the step and current reward scalar and current
            %penalty for all rats
            
            if ~exist('displayOn','var')
                displayOn=0;
            end
            
            type={'subj', 'step', 'reward','scalar', 'penalty'};
            subjectIDs=getSubjectIDs(r);
            count=0;
            
            for i=1:size(subjectIDs,2)
                count=count+1;
                s=getSubjectFromID(r,subjectIDs(i));
                [p step ] =getProtocolAndStep(s);
                out{count,1}=subjectIDs{i};
                out{count,2}=step;
                
                
                if ~isempty(p)
                    
                    ts=getTrainingStep(p,step);
                    tm=getTrialManager(ts);
                    sm=getStimManager(ts);
                    if isa(tm,'trialManager')
                        rm=getReinforcementManager(tm);
                    elseif isa(tm,'struct')
                        rm=getReinforcementManager(tm.trialManager);
                    else
                        error('bad tm')
                    end
                    
                    %calculate the reward the rat would get after 100 corrects
                    [trialRecords(1:100).correct]=deal(true);
                    %         [trialRecords(1:100).stimManagerClass]=deal(class(sm));
                    %         %asymetric needs too much history for now.
                    if ~isa(rm,'cuedReinforcement') && ~isa(rm,'asymetricReinforcement') % cued breaks b/c it requires calcstim's details
                        [rm rewardSizeULorMS requestRewardSizeULorMS msPenalty] = calcReinforcement(rm,trialRecords, s);
                    else
                        rewardSizeULorMS=nan;
                        msPenalty=nan;
                    end
                    stimName=class(sm);
                    rewardName=class(rm);
                    protocolName=getName(p);
                    ln=11;
                    if length(stimName)>ln
                        stimName=stimName(1:ln);
                    end
                    if length(rewardName)>ln
                        rewardName=rewardName(1:ln);
                    end
                    if length(protocolName)>ln
                        if strcmp(protocolName(1:7),'version')
                            protocolName=[protocolName(60:68) protocolName(8:11)];
                        else
                            protocolName=protocolName(1:ln);
                        end
                    end
                    
                    out{count,3}=rewardSizeULorMS;
                    out{count,4}=getScalar(rm);
                    out{count,5}=msPenalty;
                    out{count,6}=stimName;
                    out{count,7}=rewardName;
                    out{count,8}=protocolName;
                    try
                        if isa(sm,'stimManager')
                            out{count,9}=getCurrentShapedValue(sm);
                            out{count,10}=getPercentCorrectionTrials(sm); %all SM need to report this if they have it!
                        else
                            out{count,9}=nan;
                            out{count,10}=nan;
                        end
                    catch ex
                        warning('probably the stim manager does not have that method')
                        getReport(ex)
                        keyboard
                    end
                    
                    
                else
                    out{count,3}=nan;
                    out{count,4}=nan;
                    out{count,5}=nan;
                    out{count,6}=nan;
                    out{count,7}=nan;
                    out{count,8}=nan;
                    out{count,9}=nan;
                    out{count,10}=nan;
                end
                
                
            end
            
            subs=out(:,1);
            [a order]=unique(subs);
            out=out(order,:);
            
            if displayOn
                disp(type)
                disp(out)
            end
            
            
        end
        
        function b=getBoxFromID(r,id)
            [member index]=ismember(id,getBoxIDs(r));
            if index>0
                b=r.boxes{index};
            else
                error('request for box id not contained in ratrix')
            end
        end
        
        function b=getBoxIDForStationID(r,sid)
            found=0;
            for i=1:length(r.boxes)
                assigns=r.assignments{getID(r.boxes{i})}{1};
                for j=1:size(assigns,1)
                    if strcmp(getID(assigns{j,1}),sid) %changed from sid's being ints and checking w/==
                        if found
                            error('found multiple references to station')
                        else
                            found=1;
                            b=getID(r.boxes{i});
                        end
                    end
                end
            end
            
            if ~found
                sid
                error('no station with that id')
            end
        end
        
        function out=getBoxIDForSubjectID(r,s)
            out = 0;
            [member index]=ismember(s,getSubjectIDs(r));
            
            if index>0
                foundSubj=0;
                boxIDs=getBoxIDs(r);
                for i=1:length(boxIDs)
                    for j=1:length(r.assignments{boxIDs(i)}{2})
                        if strcmp(r.assignments{boxIDs(i)}{2}{j},s)
                            if foundSubj
                                error('found subject in more than one box')
                            else
                                foundSubj=1;
                                out=boxIDs(i);
                            end
                        end
                    end
                end
                if ~foundSubj || isempty(out)
                    disp(s)
                    warning('no box for given subject')
                end
            else
                error('no such subject id')
            end
        end
        
        function out=getBoxIDs(r)
            out=[];
            for i=1:length(r.boxes)
                out(i)=getID(r.boxes{i});
            end
        end
        
        function [compiledRecords]=getCompiledRecordsForSubject(r,subject)
            
            sID = getID(subject);
            [compiledRecords]=getCompiledRecordsForSubjectID(r,sID)
        end
        
        function [compiledRecords]=getCompiledRecordsForSubjectID(r,sID)
            
            disp(sprintf('loading compiled records for %s (from ratrix)',sID))
            
            [dataPath junk] = fileparts(getStandAlonePath(r));
            subjCompiledStorePath = fullfile(dataPath,'CompiledTrialRecords');
            subjSearchStr = sprintf('%s.*.mat',sID);
            d = dir(fullfile(subjCompiledStorePath,subjSearchStr));
            if length(d)>1
                error('multiiple compiled records. clean up before use');
            elseif isempty(d)
                compiledRecords = [];
            else
                compiledRecords = load(fullfile(subjCompiledStorePath,d.name));
            end
        end
        
        function date = getCreationDate(r)
            date = r.creationDate;
        end
        
        function out=getNumPortsForStationID(rx,st)
            s=getStationByID(rx,st);
            out=getNumPorts(s);
        end
        
        function path =getPermanentStorePath(r)
            error('this is outdated now - please fix your code to use subject-specific permanent stores and getStandAlonePath if necessary');
            path = r.permanentStorePath;
        end
        
        function v=getPhysicalLocationForBoxID(r,b)
            s=getStationsForBoxID(r,b);
            if length(s)==1
                v=getPhysicalLocation(s);
            else
                error('zero or multiple stations for that box id or no boxes with that id')
            end
        end
        
        function out = getProtocolForSubjectID(r,s)
            
            [member index]=ismember(s,getSubjectIDs(r));
            
            if index>0
                
                [out i]=getProtocolAndStep(getSubjectFromID(r,s));
                
                
            else
                error('no such subject id')
            end
        end
        
        function path = getServerDataPath(r)
            path = r.serverDataPath;
        end
        
        function path = getStandAlonePath(r)
            path = r.standAlonePath;
        end
        
        function s=getStationByID(r,id)
            found=0;
            s=[];
            
            for bx=1:length(r.assignments)
                if ~isempty(r.assignments{bx})
                    for st=1:size(r.assignments{bx}{1},1)
                        if strcmp(getID(r.assignments{bx}{1}{st,1}),id) %changed from sid's being ints and checking w/==
                            if found
                                error('found multiple stations with that id')
                            else
                                found=1;
                                s=[s r.assignments{bx}{1}{st,1}];
                            end
                        end
                    end
                end
            end
        end
        
        function s=getStationByMACaddress(r,m)
            s=[];
            stations=getStations(r);
            for i=1:length(stations)
                %     getMACaddress(stations(i))
                %     strcmp(getMACaddress(stations(i)),m)
                if strcmp(getMACaddress(stations(i)),m)
                    if isempty(s)
                        s=stations(i);
                    else
                        error('found more than one station with that MAC address')
                    end
                end
            end
        end
        
        function out=getStationIDsForBoxID(r,bid)
            out={};
            stns=getStationsForBoxID(r,bid);
            for i=1:length(stns)
                %         out={out getID(stns(i))}; %changed to be cell cuz station id's are now strings, not ints ERROR: included empty set as a station .. pmm 03/26/2008
                out{end+1}=getID(stns(i)); %remove the empty set from above
            end
        end
        
        function s=getStations(r)
            s=[];
            bIDs=getBoxIDs(r);
            for i=1:length(bIDs)
                s=[s getStationsForBoxID(r,bIDs(i))];
            end
        end
        
        function s=getStationsForBoxID(r,id)
            b=getBoxFromID(r,id);
            if ~isempty(b)
                s=[r.assignments{id}{1}{:,1}];
            else
                error('box id not contained in ratrix')
            end
        end
        
        function s=getSubjectFromID(r,id)
            [member index]=ismember(id,getSubjectIDs(r));
            if index>0
                s=r.subjects{index};
            else
                error('request for subject id not contained in ratrix')
            end
        end
        
        function out=getSubjectIDsForBoxID(r,b)
            
            bx=getBoxFromID(r,b);
            %     'assign'
            %     b
            %     r.assignments{b}{2}
            out=[r.assignments{b}{2}];
        end
        
        function out=getSubjectIDsForStationID(r,id)
            out={};
            subs=getSubjectsForStationID(r,id);
            for i=1:length(subs)
                out{i}=getID(subs{i});
            end
            
            if isempty(out)
                id
                warning('didn''t find any subjects for that station id')
            end
        end
        
        function subs=getSubjectsForStationID(r,sID)
            
            bID=getBoxIDForStationID(r,sID);
            subIDs=getSubjectIDsForBoxID(r,bID);
            subs={};
            for i=1:length(subIDs)
                subs{i}=getSubjectFromID(r,subIDs{i});
            end
        end
        
        function s=getSubjectsFromIDs(r,ids)
            s=[];
            if ischar(ids)
                s=getSubjectFromID(r,ids);
            elseif iscell(ids)
                ids={ids{:}};
                for i=1:length(ids)
                    s{end+1}=getSubjectFromID(r,ids{i});
                end
            end
        end
        
        function out=getTrainingStepNamesForSubject(r,subj)
            out = getTrainingStepNames(r.subjects{strcmp(getSubjectIDs(r),subj)});
        end
        
        function [trialRecords, localIndex, sessionNumber, compiledRecords]=getTrialRecordsForSubjectID(r,sID,filter, trustOsRecordFiles)
            % r,sID, {filterType filterParameters}
            % {'dateRange',[dateFromInclusive dateToInclusive]}
            % {'lastNTrials', numTrials}
            %
            disp(sprintf('loading records for %s (from ratrix)',sID))
            startTime=GetSecs();
            bID=getBoxIDForSubjectID(r,sID);
            if ~exist('filter','var') ||  isempty(filter)
                filter = {'all'};
            else
                if ~iscell(filter) || ~isvector(filter)
                    error('Filter invalid')
                end
            end
            filterType = filter{1};
            switch(filterType)
                case 'lastNTrials'
                    numTrials = filter{2};
                case 'all'
                    numTrials = 0;
                otherwise
                    error('Only filters ''all'' and ''lastNTrials'' supported when running')
            end
            if bID==0
                error('no box for that subject') %edf changed -- the serverDataPath is where the ratrix db is, not where trial records would be
                %    subPath=getServerDataPathForSubjectID(r,sID);
                %    localTrialRecords=loadMakeOrSaveTrialRecords(subPath);
            else
                b=getBoxFromID(r,bID);
                localTrialRecords=getTrialRecordsForSubjectID(b,sID,r);
            end
            
            remoteTrialRecords=[];
            % 9/17/08 - fixed to do subject-specific trialRecords
            % ========================
            % subjPermStorePath = getPermanentStorePath(r);
            
            subjectSpecificPermStore = false;
            subjPermStorePath = getStandAlonePath(r);
            
            if isempty(subjPermStorePath)
                conn = dbConn();
                subjPermStorePath = getPermanentStorePathBySubject(conn, sID);
                closeConn(dbConn());
                subjPermStorePath = subjPermStorePath{1};
                subjectSpecificPermStore = true;
            end
            % ========================
            % 9/30/08 - added serverDataPath argument to getTrialRecordsFromPermanentStore call for location of temp.mat file
            serverDataPath = getServerDataPath(r);
            
            if numTrials>0
                if numTrials-length(localTrialRecords) > 0
                    remoteNumTrials = numTrials-length(localTrialRecords);
                    % Get only the remaining N trials from the remote store
                    remoteTrialRecords=getTrialRecordsFromPermanentStore(subjPermStorePath,sID,...
                        {filterType,int32(remoteNumTrials)}, trustOsRecordFiles,subjectSpecificPermStore,serverDataPath);
                end
            else
                % Get all of the remote records
                remoteTrialRecords=getTrialRecordsFromPermanentStore(subjPermStorePath,sID,filter, trustOsRecordFiles,subjectSpecificPermStore,serverDataPath);
            end
            % Get from permanent store
            localIndex = length(remoteTrialRecords)+1;
            % 'this is local index'
            % localIndex
            % length(localTrialRecords)
            % length(remoteTrialRecords)
            % 1/28/09 - if remoteTrialRecords and localTrialRecords have different fields, give a warning and dont concat them
            % this will happen if the current session is the first of a new trialRecord format - should be rare enough that we can live with
            % the consequences of losing some history temporarily
            if isstruct(remoteTrialRecords) && isstruct(localTrialRecords) && ...
                    length(intersect(fieldnames(remoteTrialRecords),fieldnames(localTrialRecords)))==length(fieldnames(localTrialRecords))
                trialRecords = [remoteTrialRecords localTrialRecords];
            else
                warning('local and remote trialRecords have different formats - throwing out remote records!');
                trialRecords = localTrialRecords;
                % also reset localIndex
                localIndex = localIndex - length(remoteTrialRecords);
            end
            if ~isempty(trialRecords)
                trialNums = [trialRecords.trialNumber];
            else
                trialNums=[];
            end
            if ~all(diff(trialNums)==1)
                diff(trialNums)
                error('missing trials!')
            end
            disp(sprintf('done loading records for %s: %g s elapsed',sID,GetSecs()-startTime))
            
            % Return the next session number
            if isempty(trialRecords)
                sessionNumber = 1;
            else
                if isfield(trialRecords(end),'sessionNumber')
                    sessionNumber=trialRecords(end).sessionNumber+1;
                else
                    error('Trial records do not have session number!')
                end
            end
            
            compiledRecords = getCompiledRecordsForSubjectID(r,sID);
        end
        
        function out=getZoneForStationMAC(r,m)
            out=[];
            s=getStationByMACaddress(r,m);
            if ~isempty(s)
                out=getPhysicalLocation(s);
                out=out(2);
            end
        end
        
        function out=isGoodNonpersistedSingleStationRatrix(r)
            out=true;
            
            %there is at least one subject
            sids=getSubjectIDs(r);
            out=out && ~isempty(sids);
            if ~out
                getSubjectIDs(r)
                warning('no subjects')
            end
            
            %there is only one box
            bids=getBoxIDs(r);
            out=out && length(bids)==1;
            if ~out
                length(bids)
                warning('more than one box')
            end
            
            %box is not empty and is not running
            out=out && ~boxIDEmpty(r,bids(1)) && ~boxIDRunning(r,bids(1));
            if ~out
                boxIDEmpty(r,bids(1))
                boxIDRunning(r,bids(1))
                warning('box empty or running')
            end
            
            %all subjects in same box
            for i=1:length(sids)
                out = out && bids(1)==getBoxIDForSubjectID(r,sids{i});
            end
            if ~out
                getBoxIDForSubjectID(r,sids{i})
                warning('subjects not all in same box')
            end
            
            %there is only one station and it is not running
            st=getStationsForBoxID(r,bids(1));
            out = out && length(st)==1 && ~stationIDsRunning(r,{getID(st)});
            if ~out
                length(st)
                stationIDsRunning(r,{getID(st)})
                warning('more than one station or station is running')
            end
            
            out
        end
        
        function out=iterStationID(rx,curr,dir)
            s=getStations(rx);
            n=[];
            for i=1:length(s)
                n=[n getID(s(i))];
            end
            if curr==0 && ~isempty(n)
                out=min(n);
            else
                [tf loc]=ismember(curr,n);
                if tf
                    switch dir
                        case 'next'
                            %loc=loc; %ha
                        case 'prev'
                            loc=loc-2; %go figure...
                        otherwise
                            error('bad dir arg -- must be next or prev')
                    end
                    out=n(mod(loc,length(n))+1);
                else
                    error('no stations or no station by that number')
                end
            end
        end
        
        function out=makeNonpersistedRatrixForStationID(r,id)
            if isempty(id)
                out=[];
                return
            else
                out=ratrix();
            end
            bid=getBoxIDForStationID(r,id);
            'this box'
            bid
            out.boxes={getBoxFromID(r,bid)};
            out.creationDate = getCreationDate(r);
            out.subjects=getSubjectsForStationID(r,id);
            subIDs=getSubjectIDsForStationID(r,id);
            if isempty(subIDs)
                out=[];
            else
                out.assignments{bid}={{getStationByID(r,id),stationIDsRunning(r,{id})}, subIDs};
                if ~isempty(r.standAlonePath)
                    error('this standAlonePath should be empty b/c we should not be in standalone mode');
                end
                out.standAlonePath =r.standAlonePath;
            end
            %
            % display(out.boxes)
            % display(out.subjects)
            % out.assignments
            % size(out.assignments)
            % out.assignments{bid}
            % out.assignments{bid}{1}
            % out.assignments{bid}{2}
        end
        
        function out=makeNonpersistedRatrixForStationMAC(r,m)
            if isMACaddress(m)
                out=makeNonpersistedRatrixForStationID(r,getID(getStationByMACaddress(r,m)));
            else
                error('need mac address')
            end
        end
        
        function r = mergeMiniIntoRatrix(r,newR)
            % Take the 'newR' that has a subset of information present in 'r'
            % and merge the objects into 'r', only if the version number
            
            % Go through all of the subjects in the new ratrix, and
            newSubjectIDs = getSubjectIDs(newR);
            for i=1:length(newSubjectIDs)
                [member index]=ismember(newSubjectIDs{i},getSubjectIDs(r));
                if member
                    s=r.subjects{index};
                    newS =getSubjectFromID(newR,newSubjectIDs{i});
                    protocolVersion = getProtocolVersion(s);
                    newProtocolVersion = getProtocolVersion(newS);
                    [oldP oldTSNum]=getProtocolAndStep(s);
                    [newP newTSNum]=getProtocolAndStep(newS);
                    creationDate = getCreationDate(r);
                    newCreationDate = getCreationDate(newR);
                    % Check that the manual version of the current ratrix is NOT
                    % higher than the new ratrix
                    if creationDate == newCreationDate
                        if protocolVersion.manualVersion == newProtocolVersion.manualVersion
                            if protocolVersion.autoVersion == newProtocolVersion.autoVersion
                                % No change occurred
                            elseif protocolVersion.autoVersion< newProtocolVersion.autoVersion
                                % Ok, no new manual version has appeared, we can safely
                                % overwrite the protocol and step
                                % p,thisIsANewProtocol,thisIsANewTrainingStep,thisIsANewSte
                                % pNum,i,r,comment,auth)
                                oldTS=getTrainingStep(oldP,oldTSNum);
                                newTS=getTrainingStep(newP,newTSNum);
                                isNewProtocol=false;
                                isNewTrainingStep=strcmp(display(oldTS),display(newTS));
                                isNewStepNum= oldTSNum~=newTSNum;
                                [s r]=setProtocolAndStep(s,newP,isNewProtocol,isNewTrainingStep,isNewStepNum,newTSNum,r,'Updating subject protocol on server ratrix','ratrix');
                                s=setProtocolVersion(s,newProtocolVersion);
                                r.subjects{index}=s;
                            else
                                % The client auto version should never be lower than the
                                % server's auto version
                                protocolVersion.autoVersion
                                newProtocolVersion.autoVersion
                                error('The autoVersion of the new mini ratrix should never be older than the current ratrix')
                            end
                        elseif protocolVersion.manualVersion > newProtocolVersion.manualVersion
                            % Someone has changed the protocol on the server
                            warning('The manual protocol version has changed on the server, will NOT update the server copy with the client update');
                        else
                            % This is odd, the manual version is newer on the client
                            error('The manualVersion of the new mini ratrix should never be newer than the current ratrix')
                        end
                        
                    elseif creationDate > newCreationDate
                        warning('The creation date of the ratrix is newer on the server, will NOT update the server copy with the client update');
                    else
                        error('The creation date of the current server ratrix should never be older than that of the client update');
                    end
                else
                    newSubjectIDs{i}
                    warning('This subject id is not in the current server side ratrix, but is in the client side ratrix');
                end
            end
        end
        
        function r=putSubjectInBox(r,s,b,author)
            sub=getSubjectFromID(r,s);
            box=getBoxFromID(r,b);
            
            if boxIDRunning(r,b)
                error('cannot put a subject in a currently running box, first call stop() on the box')
            elseif subjectIDRunning(r,s)
                error('cannot change box for a currently running subject, first call stop() on the subject''s box')
            elseif getBoxIDForSubjectID(r,s)>0 && getBoxIDForSubjectID(r,s)~=b
                error('cannot put a subject who is already in a box into a different box, first remove the subject from its current box')
            elseif getBoxIDForSubjectID(r,s)==b
                error('subject already in that box')
            else
                [p,i]=getProtocolAndStep(sub);
                if isempty(p)
                    error('cannot put a subject with no protocol into a box, first assign it a protocol')
                elseif isempty(getStationsForBoxID(r,b))
                    error('cannot put a subject in a box with no stations, first assign stations to box')
                elseif ~boxOKForProtocol(p,box,r)
                    error('box has no stations suitable for subject''s protocol')
                elseif ~testBoxSubjectDir(box,sub)
                    error('could not access subject''s directory in new box')
                elseif ~authorCheck(r,author)
                    error('author does not authenticate')
                else
                    r.assignments{b}{2}{end+1}=s;
                    saveDB(r,0);
                    recordInLog(r,sub,sprintf('put subject %s in box %d',s,b),author);
                end
            end
            
        end
        
        function r=removeSubjectFromBox(r,s,b,comment,author)
            sub=getSubjectFromID(r,s);
            box=getBoxFromID(r,b);
            
            if boxIDRunning(r,b)
                error('cannot remove subject from running box, first call stop() on the box')
            elseif subjectIDRunning(r,s)
                error('cannot remove a currently running subject, first call stop() on the subject')
            elseif getBoxIDForSubjectID(r,s)~=b
                error('that subject is not in that box')
            elseif ~authorCheck(r,author)
                error('author does not authenticate')
            elseif ~testBoxSubjectDir(box,sub)
                error('cannot access subject''s directory in box')
            else
                r.assignments{b}{2}=removeStr(r.assignments{b}{2},s);
                saveDB(r,0);
                
                %     r
                %     class(r)
                %     sub
                %     class(sub)
                %     class(s)
                %     class(b)
                %     s
                %     b
                fprintf('%s: removed subject %s from box %d\n',comment,s,b)
                %     author
                recordInLog(r,sub,sprintf('%s: removed subject %s from box %d',comment,s,b),author);
                
            end
        end
        
        function r=replaceAllStructProtocolsWithTempProtocol(r,dummyProtocol,auth)
            %when ratrix has objects that have been redefined it will fail to decache
            %certain objects on saves (example, stimManger has been redefined)thus,
            %in one fell swoop, the old stuctized objects  must be replaced.
            %this function does that. keep in mind that it will save over
            %the db.mat, so you will loose your (functionally-useless) structure
            %
            %example use case: right before re-setting protocols, after SVN update:
            %
            %r=replaceAllStructProtocolsWithTempProtocol %to flush out structs, enabling:
            %setupPMM(r)
            
            if ~exist('r')
                dataPath=fullfile(fileparts(fileparts(getRatrixPath)),'ratrixData',filesep);
                r=ratrix(fullfile(dataPath, 'ServerData'),0); %load from file
            end
            
            if ~exist('dummyProtocol')
                %just using any old protocol thats up to date, and has one step
                parameters=getDefaultParameters(ifFeatureGoRightWithTwoFlank,'goToSide','1_0','Oct.09,2007');
                [ts]=setFlankerStimRewardAndTrialManager(parameters, 'dummy');
                dummyProtocol=protocol('dummy',{ts});
                %dummyProtocol=protocol; %has zero steps
            end
            
            if ~exist('auth')
                auth='pmm'
            end
            
            facts=getBasicFacts(r);
            
            %currently only looks for stim managers that are structs, could add other
            %objects within protocol, ts, tm ,rm, etc.
            whichHaveStruct=find(strcmp(facts(:,6),'struct'));
            
            subjects=facts(whichHaveStruct,1); % get the ones with bad protocols
            for i=1:length(subjects)
                %work on paired down ratrix
                miniR=r;
                subjectInd=find(strcmp(getSubjectIDs(miniR),subjects{i}));
                
                %remove other subjects
                miniR.subjects={miniR.subjects{subjectInd}}
                
                %don't let it overwrite real db
                miniR.dbpath=fullfile(fileparts(r.dbpath),'junk_db.mat');
                
                %set the protocol
                step=1;
                s=getSubjectFromID(miniR,subjects{i})
                getID(s)
                [s miniR]=setProtocolAndStep(s,dummyProtocol,0,0,0,step,miniR,'flushing out struct from protocol',auth);
                r.subjects{subjectInd}=s; % same subject is returned, but with a dummny protocol
                
            end
            
            %replace the full database with the structs removed
            saveDB(r,0);
            
        end
        
        function r=replaceStationForBox(r,s)
            if isa(s,'station') && checkPath(getPath(s))
                b=getBoxIDForStationID(r,getID(s));
                
                %could make a method: r=removeStationFromBoxID(r,b);
                if size(r.assignments{b}{1},1)==1 && boxIDEmpty(r,b) && ~boxIDRunning(r,b)
                    r.assignments{b}{1}={};
                    saveDB(r,0);
                else
                    error('box did not have exactly one station, contained one or more subjects, or was running')
                end
                
                r=addStationToBoxID(r,s,b);
            else
                error('s was not a station or box id not in ratrix or couldn''t get to station path')
            end
        end
        
        function r=setPermanentStorePath(r,path)
            error('deprecated - use subject specific permanent storage or setStandAlonePath if in standalone mode');
            
            if isdir(path) %can fail due to windows networking/filesharing bug, but unlikely at construction time
                r.permanentStorePath = path;
                saveDB(r,0);  %alsoReplaceSubjectData = false
            else
                path
                error('Argument to setPermanentStorePath is not a directory')
            end
        end
        
        function r=setStationIDSoundOn(r,sid,val)
            station=getStationByID(r,sid);
            bID=getBoxIDForStationID(getID(station));
            
            j=getStationInds(r,{sid},bID);
            
            r.assignments{bID}{1}{j,1}=setSoundOn(station,val);
            
            saveDB(r,0);
        end
        
        function r=setStationMACaddress(r,sid,mac)
            station=getStationByID(r,sid);
            bID=getBoxIDForStationID(r,getID(station));
            
            j=getStationInds(r,{sid},bID);
            
            r.assignments{bID}{1}{j,1}=setMACaddress(station,mac);
            
            saveDB(r,0);
        end
        
        function out=stationIDsRunning(r,stationIDs)
            out=zeros(1,length(stationIDs));
            for i=1:length(stationIDs)
                b=getBoxIDForStationID(r,stationIDs{i});
                ind=getStationInds(r,{stationIDs{i}},b);
                out(i)=r.assignments{b}{1}{ind,2};
            end
        end
        
        function out=subjectIDRunning(r,s)
            bx=getBoxIDForSubjectID(r,s);
            if bx==0
                out=0;
            else
                out=boxIDRunning(r,bx);
            end
            
        end
        
        function r = updateRatrix(r, ratrixParameters)
            % takes existing standAlonePath version ratrix and sets the other fields from old style ratrix
            
            r.serverDataPath = ratrixParameters.serverDataPath;
            r.dbpath = ratrixParameters.dbpath;
            r.subjects = ratrixParameters.subjects;
            r.boxes = ratrixParameters.boxes;
            r.assignments = ratrixParameters.assignments;
            r.creationDate = ratrixParameters.creationDate;
            r.standAlonePath = [];
            
            saveDB(r, 0);
            
        end
        
        function r=updateSubjectProtocol(r,s,comment,auth,listProtocol,listTrainingStep,listStepNum)
            [member index]=ismember(getID(s),getSubjectIDs(r));
            if isa(s,'subject') && member && index>0 && ~subjectIDRunning(r,getID(s))
                if authorCheck(r,auth)
                    
                    r.subjects{index}=s;
                    
                    [p i]=getProtocolAndStep(s);
                    
                    if listProtocol
                        protocolListing=sprintf('\n%s',display(p));
                    else
                        protocolListing='';
                    end
                    
                    if listTrainingStep
                        stepListing=sprintf('\n%s',display(getTrainingStep(p,i)));
                    else
                        stepListing='';
                    end
                    
                    if listStepNum
                        newStepStr=[': setting to step ' num2str(i) '/' num2str(getNumTrainingSteps(p)) ' of protocol: ' getName(p)];
                    else
                        newStepStr='';
                    end
                    
                    recordInLog(r,s,[comment newStepStr protocolListing stepListing],auth);
                    saveDB(r,0);
                    
                else
                    error('author failed authentication')
                end
            else
                error('either not a subject or not a subject in this ratrix or subject is running')
            end
        end
        
        function updateTrialRecordsForSubjectID(r,sID,trialRecords)
            disp(sprintf('saving records for %s (from ratrix)',sID))
            startTime=GetSecs();
            bID=getBoxIDForSubjectID(r,sID);
            if bID==0
                subPath=getServerDataPathForSubjectID(r,sID);
                loadMakeOrSaveTrialRecords(subPath,trialRecords);
            else
                b=getBoxFromID(r,bID);
                updateTrialRecordsForSubjectID(b,sID,trialRecords,r);
            end
            disp(sprintf('done saving records for %s: %g s elapsed',sID,GetSecs()-startTime))
        end
        
        function  out = viewStim(r,subIDs)
            %returns a single image for each requested rat
            %future idea:  pass in a rackNumber instead of a subjectIDlist
            % example: viewStim(r,'136')
            
            
            if ~exist('subIDs','var')
                subIDs=getSubjectIDs(r)
            end
            
            switch class(subIDs)
                case 'char'
                    subIDs={subIDs}
                    xGrid=1;
                    yGrid=1;
                    numSubjects=1;
                case 'cell'
                    numSubjects=length(subIDs)
                    xGrid=ceil(sqrt(numSubjects));
                    yGrid=ceil(numSubjects./xGrid);
                case 'double'
                    %treatNumbers as rack IDs
                    if size(subIDs)==[1 1]
                        rackNum=subIDs;
                    else
                        error('must be rackNum')
                    end
                    %how do you know this ratrix has all the rats in that rack? you dont
                    subIDs=getCurrentSubjects(rackNum)
                    numSubjects=length(subIDs(:))
                    xGrid=size(subIDs,1);
                    yGrid=size(subIDs,2);
                otherwise
                    error('bad input')
            end
            
            
            
            figure
            for i=1:numSubjects
                subplot(xGrid,yGrid,i)
                disp(sprintf('doing %s',subIDs{i}))
                im=sampleStimFrame(getSubjectFromID(r,subIDs{i}));
                if isinteger(im)
                    imagesc(im,[0 intmax(class(im))]);
                else
                    imagesc(im,[0 1]);
                end
                colormap(gray)
                title(subIDs{i})
                set(gca,'XTickLabel',[]);
                set(gca,'YTickLabel',[]);
                set(gca,'TickLength',[0 0]);
            end
        end
        
    end
    
    methods (Static)
        function out=authorCheck(~,author)
            approved={'bas'};
            if ismember(author,approved)
                out=1;
            else
                out=0;
                approved
                warning('author must be one of above')
            end
        end
    end
    
    methods (Access = protected)
        
        
        function saveDB(r,alsoReplaceSubjectData)
            
            disp(sprintf('saving db'))
            startTime=GetSecs();
            
            [pathstr, name, ext] = fileparts(r.dbpath);
            
            if ~isempty(pathstr) && ~isempty(name)
                
                fName=fullfile(pathstr, [name ext]);
                found=dir(fName);
                
                doIt=0;
                
                if isempty(found)==0
                    warning('didn''t find existing database, writing new one')
                    doIt=1;
                elseif length(found)==1
                    
                    newDir=fullfile(pathstr,'replacedDBs',['replaced.' datestr(now,30)]);
                    [success,message,messageid] = mkdir(newDir);
                    
                    if success
                        disp('replacing exisiting database')
                        
                        [status,message,messageid] = movefile(fName,newDir);
                        if status
                            if alsoReplaceSubjectData
                                subPath=getSubjectDataPath(r);
                                if length(dir(subPath))>0
                                    
                                    [status,message,messageid] = movefile(subPath,newDir);
                                    
                                    if status
                                        doIt=1;
                                    else
                                        error('couldn''t move subjectData directory: %s, %s',message,messageid)
                                    end
                                end
                                
                                makeAllSubjectServerDirectories(r);
                            else
                                doIt=1;
                            end
                        else
                            error('couldn''t move existing db: %s, %s',message,messageid)
                        end
                    else
                        error('couldn''t create directory %s: %s, %s',newDir,message,messageid)
                    end
                    
                else
                    error('unknown error -- found got %d matches',length(found))
                end
                
                r=decache(r);
                if doIt
                    save(fName,'r');
                end
            else
                error(sprintf('ratrix:improperDataType','can''t read database path %s',r.dpbpath))
            end
            
            disp(sprintf('done saving db: %g s elapsed',GetSecs()-startTime))
        end
        
        function makeAllSubjectServerDirectories(r)
            subIDs=getSubjectIDs(r);
            for subInd=1:length(subIDs)
                makeSubjectServerDirectory(r,subIDs{subInd});
            end
        end
        
        function makeSubjectServerDirectory(r,sID)
            serverPath=getServerDataPathForSubjectID(r,sID);
            
            [success,message,msgid] = mkdir(serverPath);
            if ~success
                error(sprintf('could not make subject server directory: %s, %s, %s',serverPath,message,msgid))
            end
        end
        
        %look for an appropriately dated text file in the appropriate place on the station that acknowledges the last command.
        function out=checkStationAcknowledgeSince(r,s,startTime)
            if isa(s,'station')
                out=0;
            else
                error('not a station object')
            end
        end
        
        function subPath=getServerDataPathForSubjectID(r,sID)
            if isa(getSubjectFromID(r,sID),'subject')
                subPath=fullfile(getSubjectDataPath(r), sID); %[r.serverDataPath 'subjectData' filesep sID filesep];
            else
                error('subject not in ratrix')
            end
        end
        
        function inds=getStationInds(r,stationIDs,boxID)
            inds=[];
            b=getBoxFromID(r,boxID);
            
            if ~all(ismember(stationIDs,getStationIDsForBoxID(r,boxID)))
                error('not all those stationIDs are in that box')
            else
                for i=1:length(stationIDs)
                    found(i)=0;
                    for j=1:size(r.assignments{boxID}{1},1)
                        if strcmp(stationIDs{i},getID(r.assignments{boxID}{1}{j,1}))%changed from sid's being ints and checking w/==
                            if found(i)
                                error('found multiple references to station')
                            else
                                found(i)=1;
                                inds(i)=j;
                            end
                        end
                    end
                end
                if any(~found)
                    error('couldn''t find some of those stations')
                end
            end
        end
        
        function out=getSubjectDataPath(r)
            out=fullfile(r.serverDataPath, 'subjectData');
            checkPath(out);
        end
        
        function out=litterCheck(r,s)
            out=0;
            if isa(s,'subject')
                lID=getLitterID(s);
                if strcmp(lID,'unknown')
                    out=1;
                else
                    for i=1:length(r.subjects)
                        if strcmp(getLitterID(r.subjects{i}),lID)
                            if strcmp(getAcquisitionDate(r.subjects{i}),'unknown')
                                ds='unknown';
                            else
                                ds=datestr(getAcquisitionDate(r.subjects{i}),'mm/dd/yyyy');
                            end
                            
                            if all(getAcquisitionDate(r.subjects{i})==getAcquisitionDate(s))
                                disp(sprintf('found acquisition date match with known litter %s: %s (%s)',...
                                    lID,getID(r.subjects{i}), ds));
                            else
                                out=-1;
                                disp(sprintf('found acquisition date mismatch with known litter %s: %s (%s)',...
                                    lID,getID(r.subjects{i}), ds));
                            end
                            
                            if all(getBirthDate(r.subjects{i})==getBirthDate(s))
                                disp(sprintf('found birth date match with known litter %s: %s (%s)',...
                                    lID,getID(r.subjects{i}), datestr(getBirthDate(r.subjects{i}),'mm/dd/yyyy')));
                            else
                                out=-1;
                                disp(sprintf('found birth date mismatch with known litter %s: %s (%s)',...
                                    lID,getID(r.subjects{i}), datestr(getBirthDate(r.subjects{i}),'mm/dd/yyyy')));
                            end
                            
                        end
                    end
                    if out==-1
                        out=0;
                    else
                        out=1;
                    end
                end
            else
                error('argument is not a subject object')
            end
        end
        
        function recordInLog(r,s,str,author)
            if ~authorCheck(r,author)
                author='unknown author';
                warning(sprintf('this is bad -- an unknown author succeeded in making a system change: %s, which means this code did not use checkAuthor() prior to making the change',str))
            end
            
            if isa(s,'subject')
                theStr = sprintf('%s: %s: %s\n\n',datestr(now,31),author,str);
                %disp(sprintf('appending log for subject %s:\n%s',getID(s),sprintf(theStr)));
                
                serverFile=fullfile(getServerDataPathForSubjectID(r,getID(s)), [getID(s) '.log.txt']);
                
                
                [fid errmsg] = fopen(serverFile,'at');
                if fid~=-1
                    fprintf(fid,theStr);
                    status=fclose(fid);
                    if status~=0
                        error(sprintf('could not close subject %s logfile at %s',getID(s),serverFile))
                    end
                else
                    error(sprintf('could not open subject %s logfile at %s, errmsg was %s',getID(s),serverFile,errmsg))
                end
                
            else
                error('argument is not a subject object')
            end
        end
        
        function out=stopStation(r,b,stationID)
            if isa(b,'box')
                if ismember(stationID,getStationIDsForBoxID(r,getID(b)))
                    s=getStationByID(r,stationID)
                    out=1;
                else
                    error('that station not in that box')
                end
            else
                error('not a box object')
            end
        end
        
        function out=testAllSubjectBoxAndStationDirs(r)
            makeAllSubjectServerDirectories(r);
            
            out=true;
            for i=1:length(r.boxes)
                b=r.boxes{i};
                sIDs=getStationIDsForBoxID(r,getID(b));
                out=out && testBoxSubjectAndStationDirs(r,b,sIDs);
                stations=getStationsForBoxID(r,getID(b));
                
                
                for i=1:length(stations)
                    
                    out = out && checkPath(stations(i));
                end
            end
            
        end
        
        function out=testBoxSubjectAndStationDirs(r,b,sIDs)
            out=1;            
            if isa(b,'box')
                stationInds=getStationInds(r,sIDs,getID(b));
                if all(stationInds>0)
                    if testBoxSubjectDirs(r,b)
                        for i=1:length(stationInds)
                            %                 if ~checkPath(getPath(r.assignments{getID(b)}{1}{i,1}))
                            %                     out=0;
                            %                     error('coudln''t get to station dir')
                            %                 end
                            if ~checkPath(r.assignments{getID(b)}{1}{i,1})
                                out=0;
                                error('coudln''t get to station dir')
                            end
                        end
                    else
                        out=0;
                        error('couldn''t get to all subject dirs for box')
                    end
                else
                    error('box doesn''t contain all those stations')
                end
            else
                error('need a box object')
            end
        end
        
        function out = testBoxSubjectDirs(r,box)
            if isa(box,'box')
                subIDs=getSubjectIDsForBoxID(r,getID(box));
                success=1;
                for i=1:length(subIDs)
                    sub=getSubjectFromID(r,subIDs(i));
                    success = success && testBoxSubjectDir(box,sub);
                end
                out=success;
            else
                error('need a box object')
            end
        end

        function out=writeObjectsToStationAndStart(r,b,stationID)
            
            if isa(b,'box')
                if ismember(stationID,getStationIDsForBoxID(r,getID(b)))
                    s=getStationByID(r,stationID)
                    out=1;
                else
                    error('that station not in that box')
                end
            else
                error('not a box object')
            end
        end
    end
end
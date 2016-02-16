classdef trainingStep
    
    properties
        svnRevURL = [];
        svnRevNum = [];
        svnCheckMode = 'session'; % default means we only check for an svn update once per session
    end
    
    methods
        function t=trainingStep(varargin)
            % TRAININGSTEP  class constructor.
            % t = trainingStep(trialManager,stimManager,criterion,scheduler,svnRevision,svnCheckMode)

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    t.trialManager = trialManager();
                    t.stimManager = stimManager();
                    t.criterion = criterion();
                    t.scheduler = scheduler();
                    t.stepName = '';

                    t.previousSchedulerState=0;
                    t.trialNum=0;
                    t.sessionRecords =[];
                    %sessionStarts=sessionRecords(:,1);
                    %sessionStops=sessionRecords(:,2);
                    %trialsCompleted=sessionRecords(:,3);  % so far this session

                    t = class(t,'trainingStep');
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'trainingStep'))
                        t = varargin{1};
                    else
                        error('Input argument is not a trainingStep object')
                    end
                case {6,7}
                    % create object using specified values
                    if isa(varargin{1},'trialManager') && isa(varargin{2},'stimManager') && isa(varargin{3},'criterion') && isa(varargin{4},'scheduler')
                        t.trialManager = varargin{1};
                        t.stimManager = varargin{2};
                        t.criterion = varargin{3};
                        t.scheduler = varargin{4};

                        if ischar(varargin{6}) && (strcmp(varargin{6},'session') || strcmp(varargin{6},'trial') || strcmp(varargin{6},'none'))
                            t.svnCheckMode = varargin{6};
                        else
                            error('svnCheckMode must be ''session'' or ''trial'' or ''none''');
                        end

                        if ~strcmp(t.svnCheckMode,'none')
                            try
                                [t.svnRevURL t.svnRevNum]=checkTargetRevision(varargin{5});
                            catch ex
                                warning('svn isn''t working due to no network access -- this needs to be fixed, but for now we just bail')
                                % ex
                                t.svnRevURL='';
                                t.svnRevNum=0;
                            end
                        end

                        if nargin>=7
                            if ischar(varargin{7})
                                t.stepName=varargin{7};
                            else
                                error('name must be a character string')
                            end
                        else
                            t.stepName='';
                        end

                        t.previousSchedulerState=0;
                        t.trialNum=0;
                        t.sessionRecords =[];
                        %sessionStarts=sessionRecords(:,1);
                        %sessionStops=sessionRecords(:,2);
                        %trialsCompleted=sessionRecords(:,3);  % so far this session

                        if stimMgrOKForTrialMgr(t.stimManager,t.trialManager)
                            t = class(t,'trainingStep');
                        else
                            class(t.stimManager)
                            class(t.trialManager)
                            error('stimManager doesn''t know about this kind of trialManager')
                        end

                    else
                        isa(varargin{1},'trialManager')
                        isa(varargin{2},'stimManager')
                        isa(varargin{3},'criterion')
                        isa(varargin{4},'scheduler')
                        error('must pass in a trialManager, stimManager, criterion, scheduler')
                    end
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function ok=boxOKForTrainingStep(t,b,r)
            if isa(b,'box') && isa(r,'ratrix')
                ok=boxOKForTrialManager(t.trialManager,b,r) & boxOKForStimManager(t.stimManager,b,r);
            else
                error('need a box and a ratrix')
            end
        end
        
        function trainingStep=calibrateEyeTracker(trainingStep)

            trainingStep.trialManager=calibrateEyeTracker(trainingStep.trialManager);

        end
    
        function t=decache(t)
            t.trialManager=decache(t.trialManager);
            t.stimManager=decache(t.stimManager);
        end
        
        function d=display(t)
            %    display(t.trialManager)
            %    display(t.stimManager)
            %    display(t.criterion)
            %    display(t.scheduler)

            d='';
            %following line causes 'can't find path specified' error?
            %d=['\t\ttrialManager: ' display(t.trialManager) '\n\t\tstimManager: '
            %display(t.stimManager) '\n\t\tcriterion: ' display(t.criterion) '\n\t\tscheduler: ' display(t.scheduler)];

            %get rid of empty b/c it might  interfere with sprintf
            if isempty(t.sessionRecords)
                dispSessionRecs='empty';
            else
                dispSessionRecs=num2str(t.sessionRecords);
            end

            d=[d '\n\t\tpreviousSchedulerState: ' num2str(t.previousSchedulerState)  '\n\t\ttrialNum: ' num2str(t.trialNum) '\n\t\tsessionRecs: ' dispSessionRecs];

            d=sprintf(d);
        end
        
        function stopEarly = doInterSession(ts, rn, window)
            %hack : in the future call "run" on trial manager with the variable far more ally known as "intertrial context" sent to the stimManager

            %things to do here:
            %1) save the trialRecords, get the RS to send em to the DS
            %this prevents the memory problems with large trail records

            %note: the number of session is preserved in the session
            %record in the the training step, but this hack version
            %always overwrites the ratrix, so isn't making use of that
            %funcitonality, even though it should work

            %always make a new session after an intersession
            stopEarly = 1;  %stopEarly = 0;
            interSessionScreenLuminance=0;
            texture=Screen('MakeTexture', window, interSessionScreenLuminance);
            destRect= Screen('Rect', window);
            xTextPos = 25;
            yTextPos =100;
             if ~isempty(rn)
                    constants = getConstants(rn);
             end


            interSessionStart = now; %ts.sessionRecords(end,2);
            interTrialContinues=1; i=0;
            while interTrialContinues
                disp(sprintf('waited for %d frames',i))
                i=i+1;
                secondsSince=etime(datevec(now),datevec(interSessionStart));
                secondsUntil=getCurrentHoursBetweenSession(ts.scheduler)*3600-secondsSince;  %okay this depends on my scheduler
                %consider secsRemainingTilStateFlip

                if rand<0.001
                    disp(sprintf('timeSince %d, timeUntil: %d',secondsSince,secondsUntil))
                end

                Screen('DrawTexture', window, texture,[],destRect,[],0);
                [garbage,yNewTextPos] = Screen('DrawText',window,[ ' frame ind:' num2str(i) ' hoursSince: ' num2str(secondsSince/3600,'%8.3f') ' hoursUntil: ' num2str(secondsUntil/3600,'%8.3f') ' percentThere: ' num2str((100*secondsSince/(secondsSince+secondsUntil)),'%8.1f') ],xTextPos,yTextPos,100*ones(1,3));
                [vbl sos ft]=Screen('Flip',window);

                if secondsUntil< 0
                    interTrialContinues=0;
                end

                %check for key presses
                [keyIsDown,secs,keyCode]=KbCheck;
                keys=find(keyCode);
                kDown=0;
                if keyIsDown
                    for keyNum=1:length(keys)
                        kDown= kDown || strcmp(KbName(keys(keyNum)),'k');  % IF HOLD "K"
                    end
                end

                if kDown
                    'kdown!'
                    for keyNum=1:length(keys)
                        keyName=KbName(keys(keyNum));
                        if strcmp(keyName,'q')  % AND PRESS "Q"
                            interTrialContinues=0;
                            disp('manual kill of interSession')
                            stopEarly = 1;
                            %record belongs in interSessionRecords eventually:
            %                 trialRecords(end).response='manual kill'; %this should break loop in RatSubjectSession.m
            %                 updateTrialRecordsForSubjectID(r,getID(subject),trialRecords);
                        end
                    end
                end

                if ~isempty(rn)

                    if ~isConnected(rn)
                        interTrialContinues=0;
                    end


                    while commandsAvailable(rn,constants.priorities.IMMEDIATE_PRIORITY) && interTrialContinues
                        logwrite('handling IMMEDIATE priority command in interTrial');
                        if ~isConnected(rn)
                            interTrialContinues=0;
                        end

                        com=getNextCommand(rn,constants.priorities.IMMEDIATE_PRIORITY);
                        if ~isempty(com)
                            [good cmd args]=validateCommand(rn,com);
                            logwrite(sprintf('interSession command is %d',cmd));

                            if good
                                done=clientHandleVerifiedCommand(rn,com,cmd,args,constants.statuses.MID_TRIAL)
                                if done
                                    interTrialContinues = 0;
            %                         response='server kill';
                                end
                        % no rewards handled during interSession

                        % stimOGL handled two commands
                        %   constants.serverToStationCommands.S_SET_VALVES_CMD,
                        %   constants.serverToStationCommands.S_REWARD_COMPLETE_CMD
                        % all other commands were handled as follows: 


                        % old stimOGL code below ... pmm 04/03/08
            %                     switch cmd
            %                         case constants.serverToStationCommands.S_SET_VALVES_CMD
            %                             isPrime=args{2};
            %                             if isPrime
            %                                 if reqeustRewardStarted && ~requestRewardDone
            %                                     quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'stimOGL received priming S_SET_VALVES_CMD while a non-priming request reward was unfinished');
            %                                 else
            %                                     timeout=-1;
            %                                     [quit valveErrorDetails(end+1)]=clientAcceptReward(rn,...
            %                                         com,...
            %                                         station,...
            %                                         timeout,...
            %                                         valveStart,...
            %                                         requestedValveState,...
            %                                         [],...
            %                                         isPrime);
            %                                     if quit
            %                                         done=true;
            %                                     end
            %                                 end
            %                             else
            %                                 if all(size(ports)==size(args{1}))
            % 
            %                                     serverValveStates=args{1};
            %                                     serverValveChange=true;
            % 
            %                                     if reqeustRewardStarted && requestRewardStartLogged && ~requestRewardDone
            %                                         if requestRewardOpenCmdDone
            %                                             if all(~serverValveStates)
            %                                                 requestRewardDone=true;
            %                                             else
            %                                                 quit=sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'stimOGL received S_SET_VALVES_CMD for closing request reward but not all valves were indicated to be closed');
            %                                             end
            %                                         else
            %                                             if all(serverValveStates==requestRewardPorts)
            %                                                 requestRewardOpenCmdDone=true;
            %                                             else
            %                                                 quit=sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'stimOGL received S_SET_VALVES_CMD for opening request reward but wrong valves were indicated to be opened');
            %                                             end
            %                                         end
            %                                     else
            %                                         quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'stimOGL received unexpected non-priming S_SET_VALVES_CMD');
            %                                     end
            %                                 else
            %                                     quit=sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'stimOGL received inappropriately sized S_SET_VALVES_CMD arg');
            %                                 end
            %                             end


            %                         case constants.serverToStationCommands.S_REWARD_COMPLETE_CMD
            %                             if requestRewardDone
            %                                 quit=sendAcknowledge(rn,com);
            %                             else
            %                                 if requestRewardStarted
            %                                     quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'client received S_REWARD_COMPLETE_CMD apparently not preceeded by open and close S_SET_VALVES_CMD''s');
            %                                 else
            %                                     quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'client received S_REWARD_COMPLETE_CMD not preceeded by C_REWARD_CMD (MID_TRIAL)');
            %                                 end
            %                             end
            %                         otherwise
            %                             done=clientHandleVerifiedCommand(rn,com,cmd,args,constants.statuses.MID_TRIAL);
            %                             if done
            %                                 quit=true;
            %                                 response='server kill';
            %                             end
            %                     end
                            end
                        end
                    end
            %         newValveState=doValves|serverValveStates;

                end
            end
        end
        
        function [graduate, keepWorking, secsRemainingTilStateFlip, subject, r, trialRecords, station, manualTs] ...
                =doTrial(ts,station,subject,r,rn,trialRecords,sessionNumber,compiledRecords)
            graduate=0;

            manualTs=false;
            if ~isempty(rn) && strcmp(getSVNCheckMode(ts),'trial') %need to be in bootstrap context cuz updating involves a matlab quit/expects daemon to restart it -- actually probably not necessary, but what if stand alone user has files open in editor that get svn updated?
                if ~isempty(ts.svnRevNum)
                    args={ts.svnRevURL ts.svnRevNum};
                else
                    args={ts.svnRevURL};
                end
                doQuit=updateRatrixRevisionIfNecessary(args);
                if doQuit
                    keepWorking=false;
                    secsRemainingTilStateFlip=0;
                    return
                end
            end

            try


                if isa(station,'station') && isa(r,'ratrix') && isa(subject,'subject') && (isempty(rn) || isa(rn,'rnet'))
                    if isa(ts,'trainingStep')
                        if isa(ts.stimManager,'stimManager')
                            %everything is good!
                        else
                            sca
                            ts.stimManager
                            class(ts.stimManager)
                            class(ts.trialManager)
                            class(ts.criterion)
                            class(ts.scheduler)
                            class(ts)
                            class(ts.stimManager)
                            error('Its gotta be a stim manager')
                        end
                    else
                        class(ts);
                        error('it''s not a trainingStep')
                    end

                    %class(ts.scheduler)
                    [keepDoingTrials, secsRemainingTilStateFlip, updateScheduler, newScheduler] = checkSchedule(ts.scheduler,subject,ts,trialRecords,sessionNumber);

                    if keepDoingTrials
                        [newTM, updateTM, newSM, updateSM, stopEarly, trialRecords, station, updateRM]=...
                            doTrial(ts.trialManager,station,ts.stimManager,subject,r,rn,trialRecords,sessionNumber,compiledRecords);
                        keepWorking=~stopEarly;

                        % 1/22/09 - check to see if we want to dynamically change trainingStep (look in trialRecords(end).result, if stopEarly is set)
                        if stopEarly
                            if isfield(trialRecords(end),'result') && ischar(trialRecords(end).result) && strcmp(trialRecords(end).result,'manual training step')
                                manualTs=true;
                            end
                        end

                        graduate = checkCriterion(ts.criterion,subject,ts, trialRecords, compiledRecords);

                        %END SESSION BY GRADUATION
                        if false && graduate % && isempty(getStandAlonePath(r)) %this was phil's quick-fix mentality hack to create an ugly special case for standalone
                            % see http://132.239.158.177/trac/rlab_hardware/ticket/282#comment:5
                            % edf thinks this is no longer necessary since fli updated trial records to allow multiple stim/trialManager types per file
                            keepWorking=0;
                        end

                        % ## not sure updateTM is needed here? causes bug because isnt
                        % set even when reinforcementMgr needs to be updated in TM.

                        if updateTM || updateRM

                            ts.trialManager=newTM;
                            updateTS = true;
                        end
                        if updateSM
                            ts.stimManager=newSM;
                            updateTS = true;
                        end
                        if updateScheduler
                            ts.scheduler=newScheduler;
                            updateTS = true;
                        end

                        if updateTM || updateSM || updateScheduler || updateRM
                            % This will update the protocol locally, and also update
                            % the subject's protocolversion.autoVersion, which will
                            % propagate the changes back to the server upon session end
                            [subject, r]=changeProtocolStep(subject,ts,r,'trialManager or stimManager or scheduler state change','ratrix');
                        end

                    else
                        disp('*************************INTERTRIAL PERIOD STARTS!*****************************')
                        stopEarly = doInterSession(ts, rn, getPTBWindow(station)); % note: we have no records of this
                        keepWorking=~stopEarly;
                        disp('*************************INTERTRIAL PERIOD ENDS!*****************************')
                    end
                else
                    sca
                    isa(station,'station')
                    isa(r,'ratrix')
                    isa(subject,'subject')


                    error('need station and ratrix and subject and rnet objects')
                end

            catch ex
                display(ts)
                %disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                Screen('CloseAll');
                rethrow(ex)
            end
        end
        
        function tsName = generateStepName(ts,ratrixSVN,ptbSVN)
            % assembles a name by calling a getNameFragment() method on its trialMgr, stimMgr, rewadrMgr, and scheduler,
            % together with the actual svnRev and ptbRev for that trial 
            % (which should be added to the trialRecord in trialManager.doTrial() anyway --
            %   return ptbVersion and ratrixVersion from stimOGL). 
            % the base class inherited implementation for each getNameFragment() could just return 
            % an abbreviated class name, but could be overridden by subclasses to include important parameter values.

            tsName = [getNameFragment(ts.trialManager) '_' getNameFragment(ts.stimManager) '_' getNameFragment(ts.criterion) '_' getNameFragment(ts.scheduler)];

            usersNameOfWholeStep=getStepName(ts); % optional name is used by physiology and could be used by ratrix protocols.  defaults to '' when unspecified.
            if ~strcmp(usersNameOfWholeStep,'')
                tsName=[usersNameOfWholeStep '_' tsName];
            end

            % append ratrix and ptb svn info
            tsName = [tsName '_' ratrixSVN '_' ptbSVN];

        end % end function
        
        function out=getCriterion(t)
            out=t.criterion;
        end
        
        function out=getScheduler(t)
            out=t.scheduler;
        end
        
        function [sessionRecords ]=getSessionRecords(trainingStep);

            sessionRecords=trainingStep.sessionRecords;
        end
        
        function out=getStepName(t)
            out=t.stepName;
        end
        
        function out=getStimManager(t)
            out=t.stimManager;
        end
        
        function out=getSVNCheckMode(t)
            out=t.svnCheckMode;
        end
        
        function out = getSVNRevNum(ts)
            out=ts.svnRevNum;
        end
        
        function out = getSVNRevURL(ts)
            out=ts.svnRevURL;
        end
        
        function out=getTrialManager(t)
            out=t.trialManager;
        end
        
        function  out = sampleStimFrame(ts)
            %returns a single image from calc stim movie

            %out=sampleStimFrame(); one day?
            if isa(ts.stimManager,'stimManager')
            out=sampleStimFrame(ts.stimManager,class(ts.trialManager));
            else
                out=[];
                warning('not a stimManager:  maybe the current class definitions don''t match the ratrix')
            end

        end
        
        function ts=setReinforcementParam(ts,param,val)

            ts=setTrialManager(ts,setReinforcementParam(getTrialManager(ts),param,val));
        end 
        
        function ts = setStimManager(ts, stim)
            if isa(stim, 'stimManager')
                ts.stimManager = stim ;
            else
                class(stim)
                error('must be stimManager')

            end
        end
        
        function ts=setTrialManager(ts,tm)
            if(isa(tm, 'trialManager'))

                    ts.trialManager = tm;

            else
                 class(tm)
                error('input is not of type trialManager');
            end
        end
        
        function trainingStep=stopEyeTracking(trainingStep)

            trainingStep.trialManager=stopEyeTracking(trainingStep.trialManager);
        end   
        
    end
    
end


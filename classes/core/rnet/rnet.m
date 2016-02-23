classdef rnet
    
    properties
        constants = [];
        type = 0;
        server = [];
        client = [];
        serverRegister = {};
        primeClient = {};
        id = [];
        host = [];
        port = 0;
    end
    
    methods
        function r = rnet(varargin)

            if ~usejava('jvm')
                error('no rnet without java')
            end

            % Server to Station Commands
            r.constants.serverToStationCommands.S_START_TRIALS_CMD = 1;
            r.constants.serverToStationCommands.S_STOP_TRIALS_CMD = 2;
            %r.constants.serverToStationCommands.S_GET_TRIAL_RECORDS_CMD = 3;
            %r.constants.serverToStationCommands.S_CLEAR_TRIAL_RECORDS_CMD = 4;
            r.constants.serverToStationCommands.S_GET_STATUS_CMD = 5;
            r.constants.serverToStationCommands.S_GET_RATRIX_CMD = 6;
            r.constants.serverToStationCommands.S_GET_RATRIX_BACKUPS_CMD = 7;
            r.constants.serverToStationCommands.S_CLEAR_RATRIX_BACKUPS_CMD = 8;
            r.constants.serverToStationCommands.S_GET_QUICK_REPORT_CMD = 9;
            r.constants.serverToStationCommands.S_SET_VALVES_CMD = 10;
            r.constants.serverToStationCommands.S_SHUTDOWN_STATION_CMD = 11;
            r.constants.serverToStationCommands.S_GET_PENDING_COMMANDS_CMD = 12;
            r.constants.serverToStationCommands.S_CLEAR_COMMAND_CMD = 13;
            r.constants.serverToStationCommands.S_UPDATE_SOFTWARE_CMD = 14;
            r.constants.serverToStationCommands.S_REWARD_COMPLETE_CMD = 15;
            r.constants.serverToStationCommands.S_GET_MAC_CMD = 16;
            r.constants.serverToStationCommands.S_GET_VALVE_STATES_CMD = 17;
            r.constants.serverToStationCommands.S_REPLICATE_TRIAL_RECORDS_CMD = 18;
            r.constants.serverToStationCommands.S_RECEIVE_DATA_CMD = 99; %for testing only

            % Station to Server
            r.constants.stationToServerCommands.C_CMD_ACK = 101;
            r.constants.stationToServerCommands.C_CMD_ERR = 102;
            %r.constants.stationToServerCommands.C_RECV_TRIAL_RECORDS_CMD = 103;
            r.constants.stationToServerCommands.C_RECV_RATRIX_CMD = 104;
            r.constants.stationToServerCommands.C_RECV_RATRIX_BACKUPS_CMD = 105;
            r.constants.stationToServerCommands.C_RECV_STATUS_CMD = 106;
            r.constants.stationToServerCommands.C_RECV_REPORT_CMD = 107;
            r.constants.stationToServerCommands.C_RECV_VALVE_STATES_CMD = 108;
            r.constants.stationToServerCommands.C_RECV_COMMAND_LIST_CMD = 109;
            r.constants.stationToServerCommands.C_REWARD_CMD = 110;
            r.constants.stationToServerCommands.C_VALVES_SET_CMD = 111;
            r.constants.stationToServerCommands.C_UPDATE_SOFTWARE_ON_TARGETS_CMD = 112;
            r.constants.stationToServerCommands.C_RECV_MAC_CMD = 113;
            r.constants.stationToServerCommands.C_RECV_UPDATING_SOFTWARE_CMD = 114;
            r.constants.stationToServerCommands.C_STOPPED_TRIALS = 115;
            r.constants.stationToServerCommands.C_RECEIVE_DATA_CMD = 199; %for testing only

            % Monitoring Client to Server
            r.constants.monitorClientCommands.M_ISSUE_COMMAND_CMD = 201;
            r.constants.monitorClientCommands.M_VERIFY_ALL_STATIONS_CMD = 202;

            % Command Priority Levels
            r.constants.priorities.IMMEDIATE_PRIORITY = 1;
            r.constants.priorities.AFTER_TRIAL_PRIORITY = 2;
            r.constants.priorities.AFTER_SESSION_PRIORITY = 3;
            r.constants.priorities.MESSAGE_RECEIPTS_PRIORITY = 4;

            % Client statuses
            r.constants.statuses.MID_TRIAL = 1;
            r.constants.statuses.IN_SESSION_BETWEEN_TRIALS = 2;
            r.constants.statuses.BETWEEN_SESSIONS = 3;
            r.constants.statuses.NO_RATRIX = 4;

            %Command Error Response Types
            r.constants.errors.UNRECOGNIZED_COMMAND = 1;
            r.constants.errors.BAD_ARGS = 2;
            r.constants.errors.CORRUPT_STATE_SENT = 3;
            r.constants.errors.BAD_STATE_FOR_COMMAND = 4;

            %Error values (non-command)
            r.constants.errors.CANT_DETERMINE_MAC = -1;

            %Node Types
            r.constants.nodeTypes.SERVER_TYPE = 1;
            r.constants.nodeTypes.CLIENT_TYPE = 2;

            %addJavaComponents(); would like to have this here, but it doesn't work for some reason...
            %     the caller has to call it before constructing an
            %     rnet for some reason.  can't figure out why, but if you don't do it, even
            %     though the dynamic path is updated correctly, the import appears to
            %     fail.
            import rlab.net.*; %lame that import isn't global -- can't call in lower function

            if nargin==1 && isa(varargin{1},'rnet')
                r = varargin{1};
            elseif nargin>0 && ischar(varargin{1})
                type = varargin{1};
                switch(nargin)
                    case 0
                        error('Default rnet object not supported');
                    case {1 2}
                        if strcmp(type,'server') == 1
                            r.type = r.constants.nodeTypes.SERVER_TYPE;
                            r.id = 'server';
                            r.host = 'localhost';

                            if nargin==2
                                if isnumeric(varargin{2}) %should be a stricter test?  positive integer?
                                    r.port = varargin{2};
                                    r.server = RlabNetworkServer(r.port);
                                else
                                    error('Server second argument should be port number');
                                end
                            else
                                r.port = RlabNetworkServer.SERVER_PORT;
                                r.server = RlabNetworkServer();
                            end

                            r.server.setTemporaryPath(java.lang.String(matlabroot));
                            thread = java.lang.Thread(r.server);
                            thread.start();
                        else
                            error('Only server type can have one or two arguments');
                        end

                    case {3 4}
                        if strcmp(type,'client') == 1
                            if ischar(varargin{2})
                                r.id = varargin{2};
                            else
                                error('Client should provide its id in string form');
                            end

                            if ischar(varargin{3}) %should be a stricter test?  ip address?
                                r.host = varargin{3};
                            else
                                error('Client should provide the host string');
                            end

                            if nargin==4
                                if isnumeric(varargin{4})  %should be a stricter test?  positive integer?
                                    r.port = varargin{4};
                                else
                                    error('Client should provide a number port number');
                                end
                            else
                                r.port = RlabNetworkServer.SERVER_PORT;
                            end

                            r.type = r.constants.nodeTypes.CLIENT_TYPE;
                            r.client = RlabNetworkClient(java.lang.String(r.id),java.lang.String(r.host),r.port);
                            r.client.setTemporaryPath(java.lang.String(matlabroot));

                            % Need to determine if the connect command was acked by the server, and by that if this
                            % connection is fully established
                            startTime = GetSecs();
                            timeout = 5.0;
                            while ~r.client.connectionEstablished()
                              if GetSecs() > startTime+timeout
                                r.client.shutdown();
                                r.client=[ ];
                                error('Client timed out waiting to establish connection');
                              end
                              WaitSecs(0.1);
                            end
                        else
                            error('Only client can have three or four arguments');
                        end

                    otherwise
                        errror('Invalid number of arguments to rnet');
                end

                
            else
                error('First argument to rnet should be type');
            end
        end
        
        function valid = checkAck(r,sentCommand,response)
            % Determine if the response is an acknowledgement of the sent command
            valid=false;

            [good cmd args]=validateCommand(r,response);
            if good
                if cmd ~= r.constants.stationToServerCommands.C_CMD_ACK
                    error('Response is not an acknowledgement, but it was checked sent to checkAck()');
                else
                    ackUID = args{1};
                    sentUID = getUID(sentCommand);
                    if(ackUID == sentUID)
                        valid = true;
                    end
                end
            end
        end
        
        function cmd=checkForSpecificCommand(varargin);
            cmd=[];
            if nargin>=1 && isa(varargin{1},'rnet')
              r = varargin{1};
            else
              error('checkForSpecificCommand() must pass in rnet object as first parameter');
            end
            switch nargin
             case 3
              client = varargin{2};
              command = varargin{3};
              priority = [];
             case 4
              client = varargin{2};
              command = varargin{3};
              priority = varargin{4};
             otherwise
              error('bad number of arguments to check for specific command');
            end

            switch r.type
             case r.constants.nodeTypes.SERVER_TYPE
              if isempty(priority)
                cmd = r.server.checkForSpecificCommand(client,command);
              else
                cmd = r.server.checkForSpecificCommand(client,command,priority);
              end
             case r.constants.nodeTypes.CLIENT_TYPE
              if isempty(priority)
                cmd = r.client.checkForSpecificCommand(command);
              else
                cmd = r.client.checkForSpecificCommand(command,priority);
              end
             otherwise
              error('bad rnet node type')
            end

            if ~isempty(cmd)
                % Turn the command into a matlab object command
                %'Got a valid command converting to rnetcommand()'
                cmd = rnetcommand(cmd);
            end
        end
        
        function cmd=checkForSpecificCommands(varargin)

            cmd=[];

            if nargin>=1 && isa(varargin{1},'rnet')
              r = varargin{1};
            else
              error('checkForSpecificCommands() must pass in rnet object as first parameter');
            end
            allPrio = getSortedPrioritiesHighestFirst(r);

            switch nargin
             case 3
              client = varargin{2};
              commands = varargin{3};
              priorities = allPrio; % Get all the priorities
             case 4
              client = varargin{2};
              commands = varargin{3};
              lowestPriority = varargin{4};
              if ~isValidPriority(r,lowestPriority)
                error('checkForSpecificCommands() priority is not valid');
              end
              % Get the subset of priorities that are equal or higher than lowestPriority
              priorities=allPrio(1:find(allPrio==lowestPriority));
             otherwise
              error('bad number of arguments to checkForSpecificCommands()');
            end

            % Look at the highest priorities first
            for p=1:length(priorities)
              % Within the same priority, look at each command in the order given
              for c=1:length(commands)
                cmd=checkForSpecificCommand(r,client,commands(c),priorities(p));
                if ~isempty(cmd)
                  % Found the corresponding command at an acceptable priority
                  return;
                end
              end
            end
        end
        
        function cmd=checkForSpecificPriority(r,client,priority)

            cmd=[];

            switch r.type
                case r.constants.nodeTypes.SERVER_TYPE
                    if isempty(client)
                        cmd = r.server.checkForSpecificPriority(priority);
                    else
                        cmd = r.server.checkForSpecificPriority(client,priority);
                    end
                case r.constants.nodeTypes.CLIENT_TYPE
                    cmd = r.client.checkForSpecificPriority(priority);
                otherwise
                    error('bad rnet node type')
            end

            if ~isempty(cmd)
                % Turn the command into a matlab object command
                cmd = rnetcommand(cmd);
            end
        end
        
        function clearTemporaryFiles(r)
            fout = sprintf('.tmp-java-matlab-%d-*-*-outgoing.mat',r.type);
            fin = sprintf('.tmp-java-%d-*-*-incoming.mat',r.type);
            foutpath = fullfile(matlabroot,fout);
            finpath = fullfile(matlabroot,fin);
            warning('off','MATLAB:DELETE:FileNotFound')
            delete(foutpath)
            delete(finpath)
            warning('on','MATLAB:DELETE:FileNotFound')

            % if IsWin
            %     dos(sprintf('del %s',foutpath));
            %     dos(sprintf('del %s',finpath));
            % elseif IsOSX
            %     system(sprintf('rm %s',foutpath));
            %     system(sprintf('rm %s',finpath));
            % else
            %     error('In clearTemporaryFiles(): Unsupported OS');
            % end
        end
        
        function [quit valveErrorDetails latencyToOpenValves latencyToCloseValveRecd latencyToCloseValves actualRewardDuration latencyToRewardCompleted latencyToRewardCompletelyDone]= ...
    clientAcceptReward(rn,com,station,timeout,refTime,requestedValveState,expectedRequestedValveState,isPrime)

            currentValveState=verifyValvesClosed(station);
            allClosed=currentValveState;
            constants=rn.constants;
            doReward=true;
            latencyToRewardCompleted = nan;
            latencyToRewardCompletelyDone = nan;
            valveErrorDetails=[];
            quit=false;

            if length(requestedValveState) == getNumPorts(station)
                'got good accept reward'
                if isPrime
                    if ~any(requestedValveStates)
                        sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'server sent priming open S_SET_VALVES_CMD with no open valve states');
                        doReward=false;
                    end
                elseif ~valveStateMatch(requestedValveState,expectedRequestedValveState)
                    sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'server S_SET_VALVES_CMD response to C_REWARD_CMD was not compatible with requested valve states')
                    doReward=false;
                end

                if doReward
                    'got into do reward'
                    [currentValveState valveErrorDetails]=setAndCheckValves(station,requestedValveState,currentValveState,valveErrorDetails,refTime,'opening valves');
                    latencyToOpenValves=GetSecs()-refTime;
                    quit = sendToServer(rn,getClientId(rn),constants.priorities.IMMEDIATE_PRIORITY,constants.stationToServerCommands.C_VALVES_SET_CMD,{currentValveState,latencyToOpenValves});
                    if ~quit
                        [quit closeValveCom closeValveCmd closeValveCmdArgs]=waitForSpecificCommand(rn,[],constants.serverToStationCommands.S_SET_VALVES_CMD,timeout,'waiting for server close valve S_SET_VALVES_CMD',constants.statuses.MID_TRIAL);
                    end
                    if quit
                        'got quit'

                        %note -- leaving valves open cuz server told me to quit in the
                        %middle of delivering water to me and never told me to close my
                        %valves.  so i am basically a leak at this point.

                        latencyToCloseValveRecd =nan;
                        latencyToCloseValves  =nan;
                        actualRewardDuration  =nan;
                        latencyToRewardCompleted  =nan;
                        latencyToRewardCompletelyDone =nan;

                    else
                        'got past quit'

                        latencyToCloseValveRecd=GetSecs()-refTime;
                        if length(closeValveCmdArgs{1}) == getNumPorts(station)
                            requestedValveState=closeValveCmdArgs{1};
                            if isPrime==closeValveCmdArgs{2}
                                if valveStateMatch(requestedValveState,allClosed)
                                    'got to lowest level'

                                    [currentValveState valveErrorDetails]=setAndCheckValves(station,requestedValveState,currentValveState,valveErrorDetails,refTime,'closing valves');
                                    latencyToCloseValves=GetSecs()-refTime;
                                    actualRewardDuration = latencyToCloseValves-latencyToOpenValves;
                                    quit=sendToServer(rn,getClientId(rn),constants.priorities.IMMEDIATE_PRIORITY,constants.stationToServerCommands.C_VALVES_SET_CMD,{currentValveState,actualRewardDuration});
                                    if ~isPrime
                                        'got to lowest level not prime'
                                        if ~quit
                                            [quit rewardCompleteCom rewardCompleteCmd rewardCompleteCmdArgs]=waitForSpecificCommand(rn,[],constants.serverToStationCommands.S_REWARD_COMPLETE_CMD,timeout,'waiting for server reward complete command',constants.statuses.MID_TRIAL);
                                        end
                                        if quit
                                            latencyToRewardCompleted=nan;
                                            latencyToRewardCompletelyDone=nan;
                                        else
                                            latencyToRewardCompleted=GetSecs()-refTime;
                                            sendAcknowledge(rn,rewardCompleteCom);
                                            latencyToRewardCompletelyDone=GetSecs()-refTime;
                                        end
                                    end
                                    'all done with reward'
                                else
                                    sendError(rn,closeValveCom,constants.errors.CORRUPT_STATE_SENT,'client received closer S_SET_VALVES_CMD that was not all zeros')
                                end
                            else
                                sendError(rn,closeValveCom,constants.errors.CORRUPT_STATE_SENT,'client received closer S_SET_VALVES_CMD that did not match priming of opener');
                            end
                        else
                            sendError(rn,closeValveCom,constants.errors.CORRUPT_STATE_SENT,'client received inappropriately sized closer S_SET_VALVES_CMD arg');
                        end
                    end
                else
                    'failed do reward!'
                end
            else
                sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'client received inappropriately sized opener S_SET_VALVES_CMD arg');
            end
        end
        
        function quit=clientHandleCommand(r,com,status)

            if ~isValidStatus(r,status)
                error('status must be a status constant as defined in rnet.m')
            end

            quit=false;
            [good cmd args] = validateCommand(r,com);

            if good
                quit=clientHandleVerifiedCommand(r,com,cmd,args,status);
            end
        end
        
        function quit=clientHandleVerifiedCommand(r,com,cmd,args,stat)

            if ~iscell(args)
                error('args must be a cell array')
            end

            if ~isa(com,'rnetcommand') %~strcmp(class(c),'rnetcommand') %does isa not work for java objects?
                error('com must be a rnetcommand')
            end

            if ~isValidClientCommand(r,cmd)
                error('cmd must be a command constant as defined in rnet.m: S_***_CMD')
            end

            if ~isValidStatus(r,stat)
                error('stat must be a status constant as defined in rnet.m')
            end

            quit=false;
            constants = getConstants(r);

            ratrixDataPath=fullfile(fileparts(fileparts(getRatrixPath)),'testdata',filesep);
            %ratrixDataPath='C:\Documents and Settings\rlab\Desktop\testdata\'; 
            %figure out where to store this
            %actually, this is an ok place -- there's nothing persistent
            %that the client/bootstrap can use to know where it sticks ratrices
            %the server could tell it where to stick them, but it's cooler
            %that it can decide whatever it wants.  the thing is that
            %box/station directories make themselves according to their own paths, 
            %which under the old way of thinking could be remote, but in reality
            %are always local.  this make for counterintuitive behavior when
            %miniratrices passed over an rnet implant themselves and have separate
            %server and data directories.

            switch cmd
                %commands that require status=NO_RATRIX
                case constants.serverToStationCommands.S_START_TRIALS_CMD
                    if stat==constants.statuses.NO_RATRIX
                        fprintf('Got a ratrix to begin trials with\n');
                        rx = args{1};
                        if isGoodNonpersistedSingleStationRatrix(rx)
                            fprintf('Ratrix is in good state to begin trials with\n');

                            rx=establishDB(rx,fullfile(ratrixDataPath, 'ServerData'),1); %THIS DOESN'T WORK THE FIRST TIME, BUT DOES ONCE THE DIRS ARE CREATED
                            quit=sendAcknowledge(r,com);

                            ids=getSubjectIDs(rx);
                            s=getSubjectFromID(rx,ids{1});
                            b=getBoxIDForSubjectID(rx,getID(s));
                            st=getStationsForBoxID(rx,b);

                            %see commandBoxIDStationIDs() (need to add stuff for updating logs, keeping track of running, etc.)

                            fprintf('About to run trials on new ratrix\n');
                            rx=doTrials(st(1),rx,0,r); %0 means repeat forever
                            quit=sendToServer(r,getClientId(r),constants.priorities.IMMEDIATE_PRIORITY,constants.stationToServerCommands.C_STOPPED_TRIALS,{rx});
                        else
                            quit=sendError(r,com,constants.errors.CORRUPT_STATE_SENT,'ratrix is not good nonpersisted single station ratrix');
                            fprintf('Ratrix is not in a good persistant state\n');
                        end
                    else
                        quit=sendError(r,com,constants.errors.BAD_STATE_FOR_COMMAND,'client status is not NO_RATRIX - must call S_STOP_TRIALS_CMD before S_START_TRIALS_CMD');
                    end
                case constants.serverToStationCommands.S_SHUTDOWN_STATION_CMD
                    fprintf('handling shutdown from server\n')
                    if stat==constants.statuses.NO_RATRIX
                        if ~commandsAvailable(r)
                            quit=true;
                            sendAcknowledge(r,com);
                            %sendRatrixToServer(ratrixDataPath,r,constants);
                        else
                            quit=sendError(r,com,constants.errors.BAD_STATE_FOR_COMMAND,'client has commands in queue - must allow them to complete or remove each using S_CLEAR_COMMAND_CMD before S_SHUTDOWN_STATION_CMD');
                        end
                    else
                        quit=sendError(r,com,constants.errors.BAD_STATE_FOR_COMMAND,'client status is not NO_RATRIX - must call S_STOP_TRIALS_CMD before S_SHUTDOWN_STATION_CMD');
                    end
                case constants.serverToStationCommands.S_UPDATE_SOFTWARE_CMD
                    if stat==constants.statuses.NO_RATRIX
                        quit=updateRatrixRevisionIfNecessary(args);

                        quitOnError=sendToServer(r,getClientId(r),constants.priorities.IMMEDIATE_PRIORITY,constants.stationToServerCommands.C_RECV_UPDATING_SOFTWARE_CMD,{quit});
                        if quitOnError || quit
                            quit=true;
                        end
                    else
                        quit=sendError(r,com,constants.errors.BAD_STATE_FOR_COMMAND,'client status is not NO_RATRIX - must call S_STOP_TRIALS_CMD before S_UPDATE_SOFTWARE_CMD');
                    end





                    %commands that require a ratrix

                case constants.serverToStationCommands.S_GET_QUICK_REPORT_CMD
                    if stat==constants.statuses.NO_RATRIX
                        quit=sendError(r,com,constants.errors.BAD_STATE_FOR_COMMAND,'client status is NO_RATRIX - must call S_START_TRIALS_CMD(ratrix) before S_GET_QUICK_REPORT_CMD');
                    else
                        %C_RECV_REPORT_CMD
                    end
                case constants.serverToStationCommands.S_STOP_TRIALS_CMD
                    fprintf('handling stop trials from server\n')
                    if stat==constants.statuses.NO_RATRIX
                        quit=sendError(r,com,constants.errors.BAD_STATE_FOR_COMMAND,'client status is NO_RATRIX - must call S_START_TRIALS_CMD(ratrix) before S_STOP_TRIALS_CMD');
                    else
                        quit=true;
                        sendAcknowledge(r,com); %even tho this just means the client is telling itself to stop trials, not that it is done.
                        %rather than sending an ack here, may be better to always return the ratrix w/C_RECV_RATRIX_CMD
                        %no actually, need to let session clean itself up.  the ratrix
                        %will get sent by the line after doTrials in the handler for
                        %start_trials
                    end




                    %commands that are OK regardless of status

                case constants.serverToStationCommands.S_GET_RATRIX_CMD

                    quit=sendRatrixToServer(ratrixDataPath,r,constants);


                case constants.serverToStationCommands.S_GET_PENDING_COMMANDS_CMD
                    %C_RECV_COMMAND_LIST_CMD
                case constants.serverToStationCommands.S_CLEAR_COMMAND_CMD
                    %ack?
                    %     case constants.serverToStationCommands.S_GET_TRIAL_RECORDS_CMD
                    %         C_RECV_TRIAL_RECORDS_CMD

                    %     case constants.serverToStationCommands.S_CLEAR_TRIAL_RECORDS_CMD
                    %         go clear all records
                    %         sendAcknowledge(r,com);
                case constants.serverToStationCommands.S_REPLICATE_TRIAL_RECORDS_CMD
            %         paths=args{1};
                    deleteOnSuccess=args{2};
                    recordInOracle=1; %pmm -08/06/26
                    replicateTrialRecords([],deleteOnSuccess, recordInOracle); %9/17/2008 - fli
                    sendAcknowledge(r,com);
                case constants.serverToStationCommands.S_GET_RATRIX_BACKUPS_CMD
                    %C_RECV_RATRIX_BACKUPS_CMD
                case constants.serverToStationCommands.S_CLEAR_RATRIX_BACKUPS_CMD
                    %ack?
                case constants.serverToStationCommands.S_GET_STATUS_CMD
                    fprintf('handling get status from server\n')
                    quit=sendToServer(r,getClientId(r),constants.priorities.IMMEDIATE_PRIORITY,constants.stationToServerCommands.C_RECV_STATUS_CMD,{stat});
                case constants.serverToStationCommands.S_GET_MAC_CMD
                    fprintf('handling mac req\n')
                    [success mac]=getMACaddress();
                    if ~success
                        mac
                        mac=constants.errors.CANT_DETERMINE_MAC;
                    end
                    quit=sendToServer(r,getClientId(r),constants.priorities.IMMEDIATE_PRIORITY,constants.stationToServerCommands.C_RECV_MAC_CMD,{mac});



                    %commands that should always be handled elsewhere
                case constants.serverToStationCommands.S_REWARD_COMPLETE_CMD
                    quit=sendError(r,com,constants.errors.BAD_STATE_FOR_COMMAND,'client received S_REWARD_COMPLETE_CMD outside of a trial context');
                case {constants.serverToStationCommands.S_GET_VALVE_STATES_CMD constants.serverToStationCommands.S_SET_VALVES_CMD}
                    %C_RECV_VALVE_STATES_CMD
                    %C_VALVES_SET_CMD
                    quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'client received S_GET_VALVE_STATES_CMD or S_SET_VALVES_CMD outside of a session context (a ratrix and station are needed to work valves)');
                otherwise
                    quit=sendError(r,com,constants.errors.UNRECOGNIZED_COMMAND);
            end
        end

        function quit=sendRatrixToServer(ratrixDataPath,r,constants)
            try
                rx=ratrix(fullfile(ratrixDataPath, 'ServerData'),0); %load from file
            catch ex
                noDBstr='no db at that location';
                if ~isempty(findstr(ex.message,noDBstr))
                    rx=[];
                else
                    ple(ex)
                    rethrow(ex);
                end
            end

            quit=sendToServer(r,getClientId(r),constants.priorities.IMMEDIATE_PRIORITY,constants.stationToServerCommands.C_RECV_RATRIX_CMD,{rx});
        end
        
        function [tf loc]=clientIsRegistered(r,c)
            loc=0;
            tf=false;
            clients={r.serverRegister{:,1}};
            for i=1:length(clients)
                if c.equals(clients{i})
                    if loc==0
                        loc=i;
                        tf=true;
                    else
                        error('multiple instances of that client in the register')
                    end
                end
            end
        end
        
        function reregstate = clientReregistered(r,client)
            reregstate = r.server.checkAndResetReconnectState(client);
        end
        
        function numCommands = commandsAvailable(r,priority,client)

            import rlab.net.*;


            if ~exist('priority','var') || isempty(priority)
                %     if r.type == r.constants.SERVER_TYPE
                %         if ~exist('client','var') || isempty(client)
                %             numCommands = r.server.incomingCommandsAvailable();
                %         else
                %             numCommands = r.server.incomingCommandsAvailable(client);
                %         end
                %     elseif r.type == r.constants.CLIENT_TYPE
                %         numCommands = r.client.commandsAvailable();
                %     else
                %         error('Unknown rnet.type value');
                %     end

                switch r.type
                    case r.constants.nodeTypes.SERVER_TYPE
                        if ~exist('client','var') || isempty(client)
                            numCommands = r.server.incomingCommandsAvailable();
                        else
                            numCommands = r.server.incomingCommandsAvailable(client);
                        end
                    case r.constants.nodeTypes.CLIENT_TYPE
                        numCommands = r.client.incomingCommandsAvailable();
                    otherwise
                        error('Unknown rnet.type value');
                end

            else
                %     if r.type == r.constants.SERVER_TYPE
                %         if ~exist('client','var') || isempty(client)
                %             %class(priority)
                %             numCommands = r.server.incomingCommandsAvailable(priority);
                %         else
                %             numCommands = r.server.incomingCommandsAvailable(client,priority);
                %         end
                %     elseif r.type == r.constants.CLIENT_TYPE
                %         numCommands = r.client.commandsAvailable(priority);
                %     else
                %         error('Unknown rnet.type value');
                %     end

                switch r.type
                    case r.constants.nodeTypes.SERVER_TYPE
                        if ~exist('client','var') || isempty(client)
                            numCommands = r.server.incomingCommandsAvailable(priority);
                        else
                            numCommands = r.server.incomingCommandsAvailable(client,priority);
                        end
                    case r.constants.nodeTypes.CLIENT_TYPE
                        numCommands = r.client.incomingCommandsAvailable(priority);
                    otherwise
                        error('Unknown rnet.type value');
                end

            end


        end

        
        function cList = disconnectClient(r,client)
            javaCList = r.server.disconnectClient(client);
            cList = {};
            if ~isempty(javaCList)
                for i=1:javaCList.length
                    cList{i} = rnetcommand(javaCList(i));
                end
            end
        end
        
        function doTimeHists(r)
            for i=1:size(r.serverRegister,1)
            subplot(size(r.serverRegister,1),1,i)
                hist(r.serverRegister{i,4},50)

            end

        end
        
        function client = getClient(r)
            client = r.client;
        end
        
        function id = getClientId(r)
            if r.type==r.constants.nodeTypes.CLIENT_TYPE
                id=r.client.getLocalNodeId();
            else
                error('Only client type should ask for their own client id');
            end
        end
        
        function id = getClientIdent(r)
            if r.type==r.constants.nodeTypes.CLIENT_TYPE
                id=r.client.getLocalNodeId();
            else
                error('Only client type should ask for their own client id');
            end
        end
        
        function [quit out]=getClientMACaddress(r,c)
            out = [];
            quit=false;
            [tf loc]=clientIsRegistered(r,c);
            if tf
                out=r.serverRegister{loc,2};
            else

                timeout=5.0;
                constants = getConstants(r);
                quit=sendToClient(r,c,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_GET_MAC_CMD,{});
                if ~quit
                    [quit respCmd respCom respArgs] = waitForSpecificCommand(r,c,constants.stationToServerCommands.C_RECV_MAC_CMD,timeout,'waiting for client response to S_GET_MAC_CMD',[]);
                end
                if quit
                    'Got a quit waiting for mac address' 
                elseif any([isempty(respCmd) isempty(respCom) isempty(respArgs)])
                    error('timed out waiting for client response to S_GET_MAC_CMD')
                else
                    out=respArgs{1};
                end
            end
        end
        
        function out=getCommandStr(r,c)
            server2station=fields(r.constants.serverToStationCommands);
            for i=1:length(server2station)
                if c==r.constants.serverToStationCommands.(server2station{i})
                    out=['SERVER->STATION:' server2station{i}];
                    return
                end
            end

            station2server=fields(r.constants.stationToServerCommands);
            for i=1:length(station2server)
                if c==r.constants.stationToServerCommands.(station2server{i})
                    out=['STATION->SERVER:' station2server{i}];
                    return
                end
            end

            c
            error('unrecognized command')
        end
        
        function constants = getConstants(r)
            constants = r.constants;
        end
        
        function out=getMaxPriority(r)
            ps=fieldnames(r.constants.priorities);
            out=[];
            for i=1:length(ps)
                if isempty(out) || r.constants.priorities.(ps{i})<out
                    out= r.constants.priorities.(ps{i});
                end
            end
        end
        
        function out=getMinPriority(r)
            ps=fieldnames(r.constants.priorities);
            out=[];
            for i=1:length(ps)
                if isempty(out) || r.constants.priorities.(ps{i})>out
                    out= r.constants.priorities.(ps{i});
                end
            end
        end
        
        function client = getNextClient(r)
            client = r.server.getNextClient();
        end
        
        function cmd = getNextCommand(r,client,priority)

            ps=getSortedPrioritiesHighestFirst(r);
            if exist('priority','var')
                if ~isValidPriority(r,priority)
                    error('invalid priority')
                end
            else
                priority=ps(end);
            end

            if ~exist('client','var')
                client=[];
            end

            cmd=[];
            for p=1:length(ps)
                if isSameOrHigherPriority(r,ps(p),priority) && commandsAvailable(r,ps(p),client)
                    cmd=checkForSpecificPriority(r,client,ps(p));
                    break;
                end
            end

            % if r.type == r.constants.SERVER_TYPE
            %     if ~exist('client','var')
            %         cmd = r.server.getNextCommand();
            %     else
            %         cmd = r.server.getNextCommand(client);
            %     end
            % elseif r.type == r.constants.CLIENT_TYPE
            %     cmd = r.client.getNextCommand();
            % end

            if isempty(cmd)
                %error('no command available')
                %now this is expected behavior
            else
                % Turn the command into a matlab object command
                cmd = rnetcommand(cmd);
            end
        end
        
        function server = getServer(r)
            server = r.server;
        end
        
        function out=getSortedPrioritiesHighestFirst(r)
            ps=fieldnames(r.constants.priorities);
            out=[];
            for i=1:length(ps)
                out=[out r.constants.priorities.(ps{i})];
            end
            out=sort(out);
        end
        
        function out=getZoneForClient(r,c)
            [tf loc]=clientIsRegistered(r,c);
            if tf
                out=r.serverRegister{loc,3};
            else
                error('that client is not registered')
            end
        end
        
        function reregstate = isClientReregistered(r,client)
            reregstate = r.server.checkReconnectState(client);
        end
        
        function status = isConnected(r,client)
            if r.type==r.constants.nodeTypes.CLIENT_TYPE
                status = r.client.isConnected();
            elseif r.type==r.constants.nodeTypes.SERVER_TYPE
                status = r.server.clientIsConnected(client);
            else
                error('isConnected(): Unknown node type');    
            end
        end
        
        function out=isSameOrHigherPriority(r,a,b)


            if ~isValidPriority(r,a) || ~isValidPriority(r,b)
                error('invalid priority')
            end

            ps=getSortedPrioritiesHighestFirst(r);


            out= find(a==ps)<=find(b==ps);
        end
        
        function out=isValidClientCommand(r,c)
            cs=fieldnames(r.constants.serverToStationCommands);
            out=false;
            for i=1:length(cs)
                if r.constants.serverToStationCommands.(cs{i})==c
                    out= true;
                end
            end
        end     
        
        function out=isValidError(r,e)
            es=fieldnames(r.constants.errors);
            out=false;
            for i=1:length(es)
                if r.constants.errors.(es{i})==e
                    out= true;
                end
            end
        end
        
        function out=isValidPriority(r,p)
            ps=fieldnames(r.constants.priorities);
            out=false;
            for i=1:length(ps)
                if r.constants.priorities.(ps{i})==p
                    out= true;
                end
            end
        end
        
        function out=isValidStatus(r,s)
            ss=fieldnames(r.constants.statuses);
            out=false;
            for i=1:length(ss)
                if r.constants.statuses.(ss{i})==s
                    out= true;
                end
            end
        end
        
        function clients = listClients(r)
            clients = [];
            listClients = r.server.listClients();
            iterClients = listClients.iterator();
            while iterClients.hasNext()
                client = iterClients.next();
                clients = [clients client];
            end

        end
        
        function com = packageArguments(r,com,arguments)
            if ~iscell(arguments)
                error('Arguments not a cell array in packageArguments()');
            end
            if ~isempty(arguments)
                toObj = zeros(length(arguments));
                cmdArgs = javaArray('java.lang.Object',length(arguments));
                for i=1:length(arguments)
                    arg = arguments{i};
                    if isinteger(arg) && length(arg) == 1
                        cmdArgs(i) = java.lang.Integer(arg);
                    elseif isnumeric(arg) && length(arg) == 1
                        cmdArgs(i) = java.lang.Double(arg);
                    elseif islogical(arg) && length(arg) == 1
                        cmdArgs(i) = java.lang.Boolean(arg);
                    elseif isa(arg,'java.lang.Double') || isa(arg,'java.lang.Integer')
                        cmdArgs(i) = arg;
                    elseif ischar(arg)
                        cmdArgs(i) = java.lang.String(arg);
                    elseif isa(arg,'java.lang.String')
                        cmdArgs(i) = arg;
                    elseif isa(arg,'java.util.Vector')
                        cmdArgs(i) = arg;
                    elseif isvector(arg) && iscell(arg)
                        vec = java.util.Vector();
                        setVector = 1;
                        for j=1:length(arg)
                            argj = arg{j};
                            if isinteger(argj) && length(argj) == 1
                                vec.add(java.lang.Integer(argj));
                            elseif isnumeric(argj) && length(argj) == 1
                                vec.add(java.lang.Double(argj));
                            elseif ischar(argj)
                                vec.add(java.lang.String(argj));
                            elseif islogical(argj) && length(argj) == 1
                                vec.add(java.lang.Boolean(argj));
                            else
                                % Give up on making the vector, it has to be an object
                                fprintf('Had to give up on making the vector, could not handle element %s',class(argj));
                                setVector = 0;
                                break;
                            end
                        end
                        % If the vector transformation was successful, set it
                        if setVector
                            cmdArgs(i) = vec;
                        else
                            cmdArgs(i) = packageObjectArgument(r,com,arg);
                        end
                    elseif isvector(arg) && ~iscell(arg) && isinteger(arg)
                        arr = javaArray('java.lang.Integer',length(arguments));
                        for  j=1:length(arg)
                            arr(j) = java.lang.Integer(arg(j));
                        end
                        cmdArgs(i) = arr;
                    elseif isvector(arg) && ~iscell(arg) && isnumeric(arg)
                        arr = javaArray('java.lang.Double',length(arguments));
                        for  j=1:length(arg)
                            arr(j) = java.lang.Double(arg(j));
                        end
                        cmdArgs(i) = arr;
                    elseif isvector(arg) && ~iscell(arg) && islogical(arg)
                        arr = javaArray('java.lang.Boolean',length(arguments));
                        for  j=1:length(arg)
                            arr(j) = java.lang.Boolean(arg(j));
                        end
                        cmdArgs(i) = arr;
                    else % Multidim cell arrays, matrices, and objects should all hit this case
                        cmdArgs(i) = packageObjectArgument(r,com,arg);
                    end
                end
                com.setArguments(cmdArgs);
            end

        end

        function newArg = packageObjectArgument(r,com,arg)
            try
                tmp = arg;
                % This name should be unique per process, command, and argument
                fname = sprintf('.tmp-java-matlab-%d-%d-%d-outgoing.mat',r.type,com.getUID(),i);
                fpath = fullfile(matlabroot,fname);
                save(fpath,'tmp');
                newArg=java.io.File(java.lang.String(fpath));
            catch ex
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                error('Unable to handle given argument %s',class(arg));
            end

        end
        
        function reconnect(r,timeout)
            % reconnect to the server
            % timeout - in milliseconds

            % if no timeout is set, set it to zero
            if ~exist('timeout','var')
                timeout = 0
            end

            switch r.type
                case r.constants.nodeTypes.SERVER_TYPE
                    error('Server objects do not reconnect');
                case r.constants.nodeTypes.CLIENT_TYPE
                    r.client.reconnect(timeout);
                    thread = java.lang.Thread(r.client);
                    thread.start();
                otherwise
                    error('Unknown rnet type in reconnnect');
            end
        end
        
        function [r rx tf]=registerClient(r,c,mac,zone,rx,subjects)
            tf=false;
            if clientIsRegistered(r,c)
                error('that client already exists in the register')
            elseif isMACaddress(mac) && isinteger(zone) && zone>0
                s=getStationByMACaddress(rx,mac);
                if ~isempty(s)

                    for i=1:length(subjects)
                        %subjects{i}{2}{2}
                        if strcmp(subjects{i}{2}{2},mac)

                            rx=putSubjectInBox(rx,subjects{i}{1},getBoxIDForStationID(rx,getID(s)),'ratrix');
                            tf=true;

                        end
                    end

                    % 9/22/08 - changed to register clients regardless of tf
            %         if tf
            %             r.serverRegister{size(r.serverRegister,1)+1,1}=c; %holding on to these might be what's keeping java from clearing
            %             r.serverRegister{size(r.serverRegister,1),2}=mac;
            %             r.serverRegister{size(r.serverRegister,1),3}=zone;
            %             r.serverRegister{size(r.serverRegister,1),4}=[]; %reward waits
            %             r.serverRegister{size(r.serverRegister,1),5}=[]; %reward durs
            %         else
            %             warning('no subject for that mac')
            %         end
                    r.serverRegister{size(r.serverRegister,1)+1,1}=c; %holding on to these might be what's keeping java from clearing
                    r.serverRegister{size(r.serverRegister,1),2}=mac;
                    r.serverRegister{size(r.serverRegister,1),3}=zone;
                    r.serverRegister{size(r.serverRegister,1),4}=[]; %reward waits
                    r.serverRegister{size(r.serverRegister,1),5}=[]; %reward durs
                    if ~tf
                        warning('no subject for that mac, but registered anyways')
                    end

                else
                    warning('no station for that mac')
                end
            else
                error('not a good mac address or not a good zone')
            end
        end
        
        function [r rx]=remoteClientShutdown(r,c,rx,subjects)

            constants=r.constants;

            fprintf('shutting down %s\n',c.id.toCharArray()) %need a matlab wrapper around RatrixNetworkNodeIdent to expose this
            timeout=10.0;

            [quit com]=sendToClient(r,c,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_GET_STATUS_CMD,{});
            if ~quit
                [quit statCom statCmd statCmdArgs]=waitForSpecificCommand(r,c,constants.stationToServerCommands.C_RECV_STATUS_CMD,timeout,'waiting for client response to S_GET_STATUS_CMD',[]);
            end
            if ~quit
                if any([isempty(statCom) isempty(statCmd) isempty(statCmdArgs)])
                    quit=sendToClient(r,c,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_SHUTDOWN_STATION_CMD,{});
                    warning('Client timedout for status request in remoteClientShutdown()');
                else
                    stat=statCmdArgs{1};
                    switch stat
                        case {constants.statuses.MID_TRIAL constants.statuses.IN_SESSION_BETWEEN_TRIALS constants.statuses.BETWEEN_SESSIONS}
                            [quit com]=sendToClient(r,c,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_STOP_TRIALS_CMD,{});

                            if ~quit
                                quit=waitForAck(r,com,timeout,'waiting for ack to stop_trials');
                            end

                            if ~quit
                                [quit stopCom stopCmd stopArgs]=waitForSpecificCommand(r,c,constants.stationToServerCommands.C_STOPPED_TRIALS,timeout,'waiting for client response (with ratrix) to already acked S_STOP_TRIALS_CMD (C_STOPPED_TRIALS)',[]);
                                %get ratrix, merge
                                if ~quit && ~isempty(rx)
                                    [rx quit] = updateRatrixFromClientRatrix(r,rx,c);
                                end
                            end

                        case constants.statuses.NO_RATRIX
                            if ~isempty(rx)
                                %get ratrix, merge (could pass in)
                                [rx quit] = updateRatrixFromClientRatrix(r,rx,c);
                            end
                        otherwise
                            error('bad status')
                    end
                    if ~quit
                        if ~isempty(rx)
                            quit=replicateClientTrialRecords(r,c,{});
                        end

                        [quit com]=sendToClient(r,c,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_SHUTDOWN_STATION_CMD,{});

                        if ~quit
                            quit=waitForAck(r,com,timeout,'waiting for ack to shutdown_station');
                        end
                    end

                end
            end

            if quit
                warning('Got a quit in remote client shutdown')
            end

            if clientIsRegistered(r,c)
                [r rx]=unregisterClient(r,c,rx,subjects);
                disconnectClient(r,c);
            end
        end

        function removeAllDisconnectedClients(r)
            % Attempt to disconnect all clients
            clients = listClients(r);
            for i=1:length(clients)
                if ~isConnected(r,clients(i))
                    removeDisconnectedClient(r,clients(i));
                end
            end
        end
        
        function quit=replicateClientTrialRecords(r,c,paths)

            % [quit com]=sendToClient(r,c,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_GET_TRIAL_RECORDS_CMD,{});
            % [quit trCmd trCom trArgs]=waitForSpecificCommand(r,c,constants.stationToServerCommands.C_RECV_TRIAL_RECORDS_CMD,timeout,'waiting for client response to S_GET_TRIAL_RECORDS_CMD',[]);
            % 
            % if confirm successful save
            % [quit com]=sendToClient(r,c,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_CLEAR_TRIAL_RECORDS_CMD,{});    

            constants = getConstants(r);

            timeout=30;
            %paths={getPermanentStorePath(r)}; % Get the permanent store path from the ratrix

            [quit com]=sendToClient(r,c,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_REPLICATE_TRIAL_RECORDS_CMD,{paths,true});    

            if ~quit
            quit=waitForAck(r,com,timeout,'waiting for ack from S_REPLICATE_TRIAL_RECORDS_CMD');
            end

        end
        
        function bool = resetRequested(r)
            if r.type == r.constants.nodeTypes.SERVER_TYPE
                bool = r.server.resetRequested();
            else
                error('Can only check reset request on server');
            end
        end
        
        function [sys r]=rewardClient(r,client,ulRewardSize,valveStates,rewardTimeout,isPrime,sys)
            constants=r.constants;

            quit=sendToClient(r,client,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_SET_VALVES_CMD,{valveStates,isPrime});

            if ~quit
                %wait for confirmation, confirm correct valves, send reward, ask client to close valves
                [quit confirmation confirmationCmd confirmationArgs]=waitForSpecificCommand(r,client,constants.stationToServerCommands.C_VALVES_SET_CMD,rewardTimeout,'waiting for client response to S_SET_VALVES_CMD',[]);
            end
            if quit
                'Got a quit in reward client'
                return
            end

            if any([isempty(confirmation) isempty(confirmationCmd) isempty(confirmationArgs)])
                error('timed out waiting for client response to opener C_VALVES_SET_CMD')
            end

            if all(size(valveStates)==size(confirmationArgs{1}))
                actualStates=confirmationArgs{1};
                waitTime=confirmationArgs{2};
                if valveStateMatch(valveStates,actualStates)
                    %do pump of ulRewardSize
                    sys=doReward(sys,ulRewardSize/1000,getZoneForClient(r,client));

                    allClosed=false(size(valveStates));
                    quit=sendToClient(r,client,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_SET_VALVES_CMD,{allClosed,isPrime}); %hmm, OK to assume all closed?  our plumbing depends on it...
                    if ~quit
                        %wait for confirmation of close, confirm correct values, send reward complete, wait for final ack
                        [quit closeConfirm closeConfirmCmd closeConfirmArgs]=waitForSpecificCommand(r,client,constants.stationToServerCommands.C_VALVES_SET_CMD,rewardTimeout,'waiting for client response to S_SET_VALVES_CMD',[]);
                    end
                    if quit
                        'Got a quit in reward client'
                        return
                    end

                    if any([isempty(closeConfirm) isempty(closeConfirmCmd) isempty(closeConfirmArgs)])
                        error('timed out waiting for client response to closer C_VALVES_SET_CMD')
                    end

                    if all(size(valveStates)==size(closeConfirmArgs{1}))
                        actualStates=closeConfirmArgs{1};
                        rewardDur=closeConfirmArgs{2};

                        if valveStateMatch(allClosed,actualStates)
                            if ~isPrime
                                [quit complete]=sendToClient(r,client,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_REWARD_COMPLETE_CMD,{});
                                if ~quit
                                    quit=waitForAck(r,complete,rewardTimeout,'waiting for ack from reward_complete');
                                end
                                if quit
                                    return
                                end

                                [tf loc]=clientIsRegistered(r,client);
                                if ~tf
                                    error('that client doesn''t exist in the register')
                                else
                                    r.serverRegister{loc,4}=[r.serverRegister{loc,4} waitTime];
                                    r.serverRegister{loc,5}=[r.serverRegister{loc,5} rewardDur];
                                    for i=1:size(r.serverRegister,1)
                                        macs{i}=r.serverRegister{i,2}(end-3:end);
                                        waitTimes(i)=mean(r.serverRegister{i,4});
                                        rewardDurs(i)=mean(r.serverRegister{i,5});
                                        rewardCounts(i)=length(r.serverRegister{i,4});
                                    end

                                    format short g
                                    macs
                                    rewardCounts
                                    waitTimes
                                    rewardDurs
                                    format long g
                                end

                            end
                        else
                            error('C_VALVES_SET_CMD response to S_SET_VALVES_CMD close request was not compatible with requested valve states')
                        end
                    else
                        error('wrong vector length of valve states back from C_VALVES_SET_CMD in response to close request')
                    end
                else
                    error('C_VALVES_SET_CMD response to S_SET_VALVES_CMD open request was not compatible with requested valve states')
                end
            else
                error('wrong vector length of valve states back from C_VALVES_SET_CMD in response to open request')
            end
        end
        
        function quit=sendAcknowledge(r,com)
            quit=sendToServer(r,getReceivingNode(com),r.constants.priorities.MESSAGE_RECEIPTS_PRIORITY,r.constants.stationToServerCommands.C_CMD_ACK,{getUID(com)});
        end 
        
        function quit=sendError(r,com,errType,errMsg)
            if isValidError(r,errType)
                fprintf('%s: sending error to server: %s\n',datestr(now),errMsg)
                quit=sendToServer(r,getReceivingNode(com),r.constants.priorities.IMMEDIATE_PRIORITY,r.constants.stationToServerCommands.C_CMD_ERR,{errType,errMsg});
                %used to be MESSAGE_RECEIPTS_PRIORITY, but then errors don't make it through waitForSpecific
            else
                error('bad errType')
            end
            
        end
        
        function quit=sendFileToServer(r,clientId,priority,command,arguments,files)

            error('sendFileToServer(): This should never be used')
            % Go through the list of files and send them over the filesystem
              driveLetter = 'z';
              serverAddress = '132.239.158.169';
              % The share name used on the server
              serverShare = 'Ratrix';
              % The server share mapping to the server's local filesystem
              serverShareLocal = 'C:\Ratrix'; 
              commPath = 'Network\Incoming'; % Location on share to store .mat objects being sent to
              % another computer
              serverPath = sprintf('\\\\%s\\%s',serverAddress,serverShare);
              serverPassword = 'Pac3111';
              serverUsername = 'rlab';

              if ~ispc
                  error('File transfer mechanism in rnet is windows specific!');
              end

              % Mount remote filesystem
              [status result]= dos(sprintf('net use %s: /delete',driveLetter));
              % Don't care if the removal didn't work
              [status result] = dos(sprintf('net use %s: %s %s /USER:%s',driveLetter,serverPath,serverPassword,serverUsername));
              if status ~= 0
                  error('Unable to mount remote filesystem');
              end
              fileStr = '';
              for i=1:length(files)
                  fileStr = strcat(fileStr,files{i},' ');
              end
              [status result] = dos(sprintf('copy /Y %s %s:\\%s',fileStr,driveLetter,commPath));
              if status ~= 0
                  error('Unable to copy file to remote filesystem');
              end  
              dos(sprintf('net use %s: /delete',driveLetter));
              % Send the command to the server
              quit=sendToServer(r,clientId,priority,command,arguments)
        end
        
        function [quit com] = sendToClient(r,clientId,priority,command,arguments)
            import rlab.net.*;
            quit=false;
            if ~isa(clientId,'RlabNetworkNodeIdent')
                clientId
                class(clientId)
                javaclasspath
                error('<clientId> argument must be a RlabNetworkNoteIdent object');
            end
            if ~exist('arguments','var')
                arguments = {};
            end
            if ~iscell(arguments)
                error('<arguments> argument must be a cell array');
            end
            jCom = RlabNetworkCommand(r.server.getNextCommandUID(),r.server.getLocalNodeId(),clientId,priority,command);
            % Convert the matlab arguments into something java can understand
            jCom = packageArguments(r,jCom,arguments);
            try
                r.server.sendImmediately(jCom);
                com = rnetcommand(jCom);
            catch ex

                quit=true;

                'got a quit in sendToClient on command'
                command
                'to client'
                clientId

                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])

                try
                    f=fopen('SocketErrorLog.txt','a');
                    fprintf(f,'%s: sendToClient in server socket error\n',datestr(now));
                    fprintf(f,['\t' ex.message '\n']);
                    fprintf(f,['\t' ex.stack.file '\n']);
                    fprintf(f,['\t' ex.stack.line '\n']);
                    fclose(f);
                catch ex
                    disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                    error('errored within a caught error display!')
                end
                com=[];
            end
        end
        
        function [quit com] = sendToServer(r,clientId,priority,command,arguments)
              import rlab.net.*;  
              quit=false;
              if ~isa(clientId,'RlabNetworkNodeIdent')
                error('<clientId> argument must be a RlabNetworkNodeIdent object');
              end
              if ~exist('arguments','var')
                  arguments = {};
              end
              if ~iscell(arguments)
                error('<arguments> argument must be a cell array');
              end
              jCom = RlabNetworkCommand(r.client.getNextCommandUID(),clientId,r.client.getRemoteNodeId(),priority,command);
              % Convert the matlab arguments into something java can understand
              jCom = packageArguments(r,jCom,arguments);
              try
                  r.client.sendImmediately(jCom);
                  com = rnetcommand(jCom);
              catch ex
                  disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                  quit=true;

                  ple(ex)
                  try
                      f=fopen('SocketErrorLog.txt','a');
                      fprintf(f,'%s: sendToServer from %s in client socket error\n',datestr(now),r.id);
                      fprintf(f,['\t' ex.message '\n']);
                      fprintf(f,['\t' ex.stack.file '\n']);
                      fprintf(f,['\t' ex.stack.line '\n']);
                      fclose(f);
                  catch ex
                      disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                      error('errored within a caught error log!') %-pmm, cleaning up errs
                  end
                  com=[];
              end
              
        end
        
        function [sys r rx]=serverHandleCommand(r,com,sys,rx,subjects)

            %fprintf('Server recieved: %s remaining %d\n', toString(com),commandsAvailable(r,{},getSendingNodeId(com)));
            constants = getConstants(r);
            client = getSendingNode(com);
            [good cmd args] = validateCommand(r,com);

            if good
                switch cmd
                    case constants.stationToServerCommands.C_CMD_ACK
                        error('received unexpected ACK')
                    case constants.stationToServerCommands.C_CMD_ERR
                        errType = args{1};
                        errString = args{2};
                        fprintf('Error Received from %s: [%d]\n\t%s\n',toString(com),errType,errString);
                        error('client sent an error')
            %         case constants.stationToServerCommands.C_RECV_TRIAL_RECORDS_CMD
            %             error('unexpected C_RECV_TRIAL_RECORDS_CMD')
                    case constants.stationToServerCommands.C_RECV_RATRIX_CMD
                        error('unexpected C_RECV_RATRIX_CMD')
                    case constants.stationToServerCommands.C_RECV_RATRIX_BACKUPS_CMD
                        error('unexpected C_RECV_RATRIX_BACKUPS_CMD')
                    case constants.stationToServerCommands.C_RECV_STATUS_CMD
                        error('unexpected C_RECV_STATUS_CMD')
                    case constants.stationToServerCommands.C_RECV_REPORT_CMD
                        error('unexpected C_RECV_REPORT_CMD')
                    case constants.stationToServerCommands.C_RECV_VALVE_STATES_CMD
                        error('unexpected C_RECV_VALVE_STATES_CMD')
                    case constants.stationToServerCommands.C_RECV_COMMAND_LIST_CMD
                        error('unexpected C_RECV_COMMAND_LIST_CMD')
                    case constants.stationToServerCommands.C_REWARD_CMD
                        if isa(sys,'pumpSystem')
                            rewardTimeout = 20.0; %figure out where to store this
                            ulRewardSize=args{1};
                            valveStates=args{2};
                            isPrime=false;
                            [sys r]=rewardClient(r,client,ulRewardSize,valveStates,rewardTimeout,isPrime,sys);
                        else
                            error('got a reward request for a server that doesn''t serve a pump')
                        end
                    case constants.stationToServerCommands.C_VALVES_SET_CMD
                        error('unexpected C_VALVES_SET_CMD')
                    case constants.stationToServerCommands.C_UPDATE_SOFTWARE_ON_TARGETS_CMD
                        % Update software on all stations
                        clients = listClients(r);
                        fprintf('Sending update software command to all clients');
                        for i=1:length(clients)
                            updateClient = clients(i);
                            quit=sendToClient(r,updateClient,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_UPDATE_SOFTWARE_CMD,{});
                        end
                        % Now update the software on the server
                        fprintf('Now updating the software on the server');
                        r=svnUpdate(r);

                        %shouldn't we check for an ACK from the client?  except it's
                        %shutting down...
                    case constants.stationToServerCommands.C_RECV_UPDATING_SOFTWARE_CMD
                        error('unexpected C_RECV_UPDATING_SOFTWARE_CMD')
                    case r.constants.stationToServerCommands.C_STOPPED_TRIALS
                        warning('unexpected C_STOPPED_TRIALS - client has chosen to change svn revision, graduated, or has a serious problem')
                        %args{1} %possible issue -- we get the rx here, but would
                        %rather ask again in shutdown, but if that fails we lost a good chance to get it.  possibly merge here? 
                        [r rx]=remoteClientShutdown(r,client,rx,subjects); %handles merge,replication,unregister,disconnect
                    otherwise
                        error('Unknown command received');
                end
            end
        end
        
        function [r rx]=shutdown(r,rx,subjects)
            constants=r.constants;

            firstErr=[];

            switch r.type
                case r.constants.nodeTypes.SERVER_TYPE
                    r=stopAcceptingConnections(r);

                    %doTimeHists(r);

                    clients=listClients(r);
                    %         try
                    for i=1:length(clients)
                        try
                            [r rx]=remoteClientShutdown(r,clients(i),rx,subjects);
                        catch ex
                            firstErr=ex;
                            disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                        end
                        try
                            cList=disconnectClient(r,clients(i));
                            cList=[]; % Ignore leftover commands
                        catch ex
                            disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                        end
                    end
                    %         catch
                    %             % Must ensure that server is shutdown properly
                    %             if ~isempty(r)
                    %                 r.server.shutdown();
                    %                 r.server.shutdownAll();
                    %             end
                    %             % Now throw the error that occurred
                    %
                    %         end

                    try
                        r.server.shutdown();
                        r.server.shutdownAll();

                        while ~r.server.isShutdown
                            if rand>.99
                                'waiting for ratrix server thread to shutdown'
                            end
                        end

                        r.server=[];
                    catch ex
                        disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                        %rethrow(ex);
                    end
                    if ~isempty(firstErr)
                        %rethrow(firstErr)
                    end


                case r.constants.nodeTypes.CLIENT_TYPE
                    r.client.shutdown();

                    while ~r.client.isShutdown
                        if rand>.99
                            'waiting for ratrix client thread to shutdown'
                        end
                    end

                    r.client=[];
                otherwise
                    error('Unknown rnet type in shutdown');
            end
            fprintf('threads should be exited\n')
            %struct(r)
            clearTemporaryFiles(r);

            r=[];
        end
        
        function [r priming]=startPrime(r,stationID,portID)
            if isempty(r.primeClient)
                potentialPrimeClient=getClientForStationID(r,stationID);
                if clientIsRegistered(r,potentialPrimeClient)
                    r.primeClient={potentialPrimeClient, portID};
                    fprintf('priming: station %d port %d\n',stationID,portID);
                    priming=true;
                else
                    fprintf('current priming target (station %d port %d) is not yet registered.  ignoring priming request.\n',stationID,portID);
                    priming=false;
                end
            else
                error('already priming someone -- must stop before you prime someone else')
            end
        end
        
        function r=stopAcceptingConnections(r)
            constants=r.constants;

            switch r.type
                case r.constants.nodeTypes.SERVER_TYPE
                    r.server.stopAcceptingNewConnections();
                case r.constants.nodeTypes.CLIENT_TYPE
                    error('Only server types accept connections');
                otherwise
                    error('Unknown rnet type in stopAcceptingConnections');
            end
        end
        
        function r=stopPrime(r)
            if isempty(r.primeClient)
                error('not priming anyone -- cannot call stopPrime')
            else
                r.primeClient={};
            end
        end
        
        function r=svnUpdate(r,targetRevision)
            % Shutdown server/client, and remove the java server/client object

            info.type = r.type;
            info.serverType = r.constants.nodeTypes.SERVER_TYPE;
            info.clientType = r.constants.nodeTypes.CLIENT_TYPE;
            info.id = r.id;
            info.host = r.host;
            info.port = r.port;

            r=shutdown(r);

            % Update the Ratrix codebase using SVN
            % Determine the root directory for the ratrix code
            % If no revision is specified, supply the empty string
            if nargin <= 1
                targetRevision = '';
            end
            svnPath = GetSubversionPath;

            % Construct svn update command
            info.updateCommand=[svnPath 'svn update '  targetRevision getRatrixPath ];
            save('info.mat','info');

            % Clear java classes
            clearJavaComponents();
            clearJavaComponents();

            whos
            clear all
            java.lang.System.gc();
            WaitSecs(5)
            clear all
            java.lang.System.gc();
            x=whos
            clear java
            clearJavaComponents();
            import ratrix.net.*;  

            load('info.mat','info');
            % Run svn update command
            % if IsWin
            %     s = dos(info.updateCommand);
            % else
                [s result] = system(info.updateCommand);
            % end

            %Check return arguments to verify success
            if s~=0
              warning('SVN update not successful!');
              result
            end

            % Update psychtoolbox
            updatePsychtoolboxIfNecessary

            % Reload java classes
            addJavaComponents();
            import ratrix.net.*;



            % Once the command is completed, then start up the client/server again
            successful=false;
            while ~successful
              try
                switch info.type
                 case info.serverType
                  r = rnet('server',info.port);
                 case info.clientType
                  r = rnet('client',info.id,info.host,info.port);
                 otherwise
                  error('In svnUpdate(): Unknown node type');
                end
                successful = true;
              catch ex
                successful = false;
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                pause(1.0);
                fprintf('Attempting to reconnect in svnUpdate()\n');
              end
            end

        end
        
        function [r rx]=unregisterClient(r,c,rx,subjects)
            % IMPORTANT! Here is the higher level program acknowledging a disconnection
            [tf loc]=clientIsRegistered(r,c);
            if ~tf
                c

                warning('that client doesn''t exist in the register')
            else
                [quit mac]=getClientMACaddress(r,c);
                if quit
                    error('got a quit from getClientMACaddress for a registered client!')
                end

                fprintf('disconnecting %s\n',r.serverRegister{loc,2});
                inds = 1:size(r.serverRegister,1);
                r.serverRegister=r.serverRegister(inds(inds~=loc),:); %WOW.  those should be curlies!  how is that consistent syntax, mathworks?

                    for i=1:length(subjects)
                    %subjects{i}{2}{2}
                    if strcmp(subjects{i}{2}{2},mac)
                        rx=removeSubjectFromBox(rx,subjects{i}{1},getBoxIDForSubjectID(rx,subjects{i}{1}),'unregistering client','ratrix');
                    end
                end


            end
        end
        
        function [rx quit] = updateRatrixFromClientRatrix(rn,rx,client)
            constants = getConstants(rn);

            [quit com]=sendToClient(rn,client,constants.priorities.IMMEDIATE_PRIORITY,constants.serverToStationCommands.S_GET_RATRIX_CMD,{});

            if ~quit
                timeout=10.0;
                [quit rxCmd rxCom rxArgs]=waitForSpecificCommand(rn,client,constants.stationToServerCommands.C_RECV_RATRIX_CMD,timeout,'waiting for client response to S_GET_RATRIX_CMD',[]);
                com=[];
                rxCmd=[];

                if ~quit
                    if length(rxArgs)==1 && ~isempty(rxArgs{1})
                        newRX = rxArgs{1};
                        if isa(newRX,'ratrix')
                            %merge backup to rx %may be for totally different subject!
                            rx = mergeMiniIntoRatrix(rx,newRX);
                        else
                            error('C_RECV_RATRIX_CMD sent an argument that was not a ratrix')
                        end
                    else
            %             rxArgs
            %             warning('Ratrix was not sent to the server as a part of the the C_RECV_RATRIX_CMD')
                    end
                end
            end
        end
        
        function [good cmd args] = validateCommand(r,c)

            if isempty(c)
                good=false;
                cmd=[];
                args=[];
                return
            end

            if ~isa(c,'rnetcommand')
                error('com must be a rnetcommand')
            end

            constants = getConstants(r);
            cmd = getCommand(c);
            args = getArguments(c);
            good = true;

            switch r.type
                case r.constants.nodeTypes.SERVER_TYPE

                    client = getSendingNode(c);

                    [tf loc]=clientIsRegistered(r,client);
                    if tf
                        mac=r.serverRegister{loc,2};
                    else
                        mac='unregistered client';
                    end

                    switch cmd
                        case constants.stationToServerCommands.C_CMD_ACK
                            if length(args) ~= 1 || ~isscalar(args{1}) || args{1}<=0 || ~isnumeric(args{1}) %|| ~isinteger(args{1}) %should really check that it's an integer, but packageArguments hasn't been fixed yet to preserve numeric types properly...
                                good=false;
                                args{1}
                                class(args{1})
                                error('Usage: C_CMD_ACK(commandUID)');
                            end
                        case constants.stationToServerCommands.C_CMD_ERR
                            if length(args) ~= 2 || ~isValidError(r,args{1}) || ~ischar(args{2})
                                good=false;
                                error('Usage: C_CMD_ERR(rnet.constants.errors.*,string)');
                            end
            %             case constants.stationToServerCommands.C_RECV_TRIAL_RECORDS_CMD
            %                 if how pass file?
            %                     error('Usage: C_RECV_TRIAL_RECORDS_CMD(?)')
            %                 end
                        case constants.stationToServerCommands.C_RECV_RATRIX_CMD
                            if length(args) ~=1 || ~(isa(args{1},'ratrix') || isempty(args{1}))
                                good=false;
                                error('Usage: C_RECV_RATRIX_CMD(ratrix)   (ratrix may be [])')
                            end
                        case constants.stationToServerCommands.C_RECV_RATRIX_BACKUPS_CMD
                        case constants.stationToServerCommands.C_RECV_STATUS_CMD
                            if ~(length(args)==1 && isValidStatus(r,args{1}))
                                good=false;
                                error('Usage: C_RECV_STATUS_CMD(status)')
                            end
                        case constants.stationToServerCommands.C_RECV_REPORT_CMD
                        case constants.stationToServerCommands.C_RECV_VALVE_STATES_CMD
                        case constants.stationToServerCommands.C_RECV_COMMAND_LIST_CMD
                        case constants.stationToServerCommands.C_REWARD_CMD
                            if ~(length(args)==2 && isreal(args{1}) && isscalar(args{1}) && args{1}>=0 && islogical(args{2}) && isvector(args{2}))
                                good=false;
                                error('Usage: C_REWARD_CMD(double ulRewardSize >=0,logical vector valvestates)');
                            end
                        case constants.stationToServerCommands.C_VALVES_SET_CMD
                            if ~(ismember(length(args),[1 2]) && islogical(args{1}) && isvector(args{1}) && (length(args)==1 || (isscalar(args{2}) && isfloat(args{2}) && args{2}>0)))
                                good=false;
                                error('Usage: C_VALVES_SET_CMD(logical vector valvestates[, double waitTime])')
                            end
                        case constants.stationToServerCommands.C_UPDATE_SOFTWARE_ON_TARGETS_CMD
                            if ~isempty(args)
                                good=false;
                                error('Usage: C_UPDATE_SOFTWARE_ON_TARGETS_CMD(void)')
                            end
                        case constants.stationToServerCommands.C_RECV_MAC_CMD
                            if ~(length(args)==1 && (isMACaddress(args{1}) || args{1}==constants.errors.CANT_DETERMINE_MAC))
                                good=false;
                                error('Usage: C_RECV_MAC_CMD(MACaddress)')
                            end
                        case constants.stationToServerCommands.C_RECV_UPDATING_SOFTWARE_CMD
                            if length(args)~=1 || ~islogical(args{1}) || ~isscalar(args{1})
                                good=false;
                                error('Usage: C_RECV_CURR_VERSION_CMD(booleanRestarting)')
                            end
                        case r.constants.stationToServerCommands.C_STOPPED_TRIALS
                            if length(args) ~=1 || ~isa(args{1},'ratrix')
                                good=false;
                                error('Usage: C_RECV_RATRIX_CMD(ratrix)')
                            end
                        otherwise
                            good=false;
                            error('received unrecognized command')
                    end
                case r.constants.nodeTypes.CLIENT_TYPE

                    mac='server';

                    switch cmd
                        case constants.serverToStationCommands.S_START_TRIALS_CMD
                            if length(args)~=1 || ~isa(args{1},'ratrix')
                                good=false;
                                sendError(r,c,constants.errors.BAD_ARGS,'usage: S_START_TRIALS_CMD(Ratrix)');
                            end
                        case constants.serverToStationCommands.S_STOP_TRIALS_CMD
            %             case constants.serverToStationCommands.S_GET_TRIAL_RECORDS_CMD
            %                 if ~isempty(args)
            %                     good=false;
            %                     sendError(r,c,constants.errors.BAD_ARGS,'usage: S_GET_TRIAL_RECORDS_CMD(void)');
            %                 end
            %             case constants.serverToStationCommands.S_CLEAR_TRIAL_RECORDS_CMD
            %                 if ~isempty(args)
            %                     good=false;
            %                     sendError(r,c,constants.errors.BAD_ARGS,'usage: S_CLEAR_TRIAL_RECORDS_CMD(void)');
            %                 end
                        case constants.serverToStationCommands.S_REPLICATE_TRIAL_RECORDS_CMD
                            if length(args)==2 && iscell(args{1}) && (isempty(args{1}) || isvector(args{1})) && isscalar(args{2}) && islogical(args{2})
                                for i=1:length(args{1})
                                    if ~ischar(args{1}{i})
                                        'not char'
                                        sendError(r,c,constants.errors.BAD_ARGS,'paths should be strings');
                                        good=false;
                                    else
                                        if ~isDirRemote(args{1}{i}) %not safe due to windows networking/filesharing bug -- if this causes lots of crashes (will bring down whole server/rack), consider not checking at all (or just checking for char vector), rely on the replication function doing the check
                                            'cant see dir'
                                            args{1}{i}
                                            sendError(r,c,constants.errors.BAD_ARGS,['can''t find path: ' args{1}{i}]);
                                            good=false;
                                        end
                                    end
                                end
                            else
                                'bad args'
                                good=false;
                                sendError(r,c,constants.errors.BAD_ARGS,'Usage: S_REPLICATE_TRIAL_RECORDS_CMD({destination paths},bool deleteOnSuccess)')
                            end
                        case constants.serverToStationCommands.S_GET_STATUS_CMD
                        case constants.serverToStationCommands.S_GET_RATRIX_CMD
                            if ~isempty(args)
                                good=false;
                                sendError(r,c,constants.errors.BAD_ARGS,'usage: S_GET_RATRIX_CMD(void)');
                            end
                        case constants.serverToStationCommands.S_GET_RATRIX_BACKUPS_CMD
                        case constants.serverToStationCommands.S_CLEAR_RATRIX_BACKUPS_CMD
                        case constants.serverToStationCommands.S_GET_QUICK_REPORT_CMD
                        case constants.serverToStationCommands.S_SET_VALVES_CMD
                            if length(args)~=2 || ~islogical(args{1}) || ~isvector(args{1}) || ~islogical(args{2}) || ~isscalar(args{2})
                                good=false;
                                sendError(r,c,constants.errors.BAD_ARGS,'usage: S_SET_VALVES_CMD(logical vector valvestates, logical isPrime)');
                            end
                        case constants.serverToStationCommands.S_SHUTDOWN_STATION_CMD
                            if ~isempty(args)
                                good=false;
                                sendError(r,c,constants.errors.BAD_ARGS,'usage: S_SHUTDOWN_STATION_CMD(void)');
                            end
                        case constants.serverToStationCommands.S_GET_PENDING_COMMANDS_CMD
                        case constants.serverToStationCommands.S_CLEAR_COMMAND_CMD
                        case constants.serverToStationCommands.S_UPDATE_SOFTWARE_CMD
                            try
                                checkTargetRevision(args);
                            catch
                                good=false;
                                sendError(r,c,constants.errors.BAD_ARGS,'usage: S_UPDATE_SOFTWARE_CMD(svn url(ex: ''svn://132.239.158.177/projects/ratrix/tags/v0.6'') [,integer revision_number]) (see util\checkTargetRevision for more restrictions)');
                            end
                        case constants.serverToStationCommands.S_REWARD_COMPLETE_CMD
                        case constants.serverToStationCommands.S_GET_MAC_CMD
                            if ~isempty(args)
                                good=false;
                                sendError(r,c,constants.errors.BAD_ARGS,'usage: S_GET_MAC_CMD(void)');
                            end
                        case constants.serverToStationCommands.S_GET_VALVE_STATES_CMD
                        otherwise
                            good=false;
                            sendError(r,c,constants.errors.UNRECOGNIZED_COMMAND);
                    end
                otherwise
                    good=false;
                    error('Unknown rnet.type value');
            end

            if good
                outstr='validated!';
            else
                outstr='failed validation!';
            end

            f=fopen('cmdLog.txt','a');
            fprintf(f,'%s: got command %d (%s from %s): %s\n',datestr(now),cmd,getCommandStr(r,cmd),mac,outstr);
            fclose(f);
        end
        
        function quit=waitForAck(r,com,timeout,str)
            [quit ackCom ackCmd ackArgs]=waitForSpecificCommand(r,getReceivingNode(com),r.constants.stationToServerCommands.C_CMD_ACK,timeout,sprintf('waiting for ACK: %s',str),[]);

            if ~quit


                if any([isempty(ackCom) isempty(ackCmd) isempty(ackArgs)])
                    str
                    warning('timed out waiting for ack')
                    quit=true;
                end

                if ~checkAck(r,com,ackCom)
                    str
                    warning('got ACK for wrong command')
                    quit=true;
                end
            end
        end
        
        function cmd=waitForCommands(r,client,commands,priorities,timeout)
            if isempty(priorities)
                ps=getSortedPrioritiesHighestFirst(r);
                priority=ps(end);
                priorities = repmat(priority,1,length(commands));
            else
                for i=1:length(priorities)
                    if ~isValidPriority(r,priorities(i))
                        error('In waitForCommands(), invalid priority')
                    end
                end
            end
            if ~all(size(commands)==size(priorities))
                error('In waitForCommands(), size of commands and priorities is different')
            end
            jCommands = javaArray('java.lang.Integer',length(commands));
            jPriorities = javaArray('java.lang.Integer',length(commands));

            for i=1:length(commands)
                jCommands(i) = java.lang.Integer(commands(i));
                jPriorities(i) = java.lang.Integer(priorities(i));
            end

            switch(r.type)
                case r.constants.nodeTypes.SERVER_TYPE
                    jCmd=r.server.waitForCommands(client,jCommands,jPriorities,timeout);
                case r.constants.nodeTypes.CLIENT_TYPE
                    jCmd=r.client.waitForCommands(jCommands,jPriorities,timeout);
                otherwise
                    error('Invalid rnet type in waitForCommands()');
            end

            if ~isempty(jCmd)
                % Turn the command into a matlab object command
                %'Got a valid command converting to rnetcommand()'
                cmd = rnetcommand(jCmd);
            else
                cmd = [];
            end
        end
        
        function [quit cmd com args]=waitForSpecificCommand(r,client,command,timeout,errStr,stat)

            quit=false;
            cmd=[];
            com=[];
            args=[];
            startTime=GetSecs();

            switch r.type
                case r.constants.nodeTypes.SERVER_TYPE
                    emergencyCommands=[r.constants.stationToServerCommands.C_CMD_ERR];
                    lightweightCommands=[];

                    [tf loc]=clientIsRegistered(r,client);
                    if tf
                        mac=r.serverRegister{loc,2};
                    else
                        mac='unregistered client';
                    end

                case r.constants.nodeTypes.CLIENT_TYPE
                    mac='server';
                    lightweightCommands=[r.constants.serverToStationCommands.S_GET_MAC_CMD,r.constants.serverToStationCommands.S_GET_STATUS_CMD];
                    emergencyCommands=[r.constants.serverToStationCommands.S_STOP_TRIALS_CMD,r.constants.serverToStationCommands.S_SHUTDOWN_STATION_CMD];
                otherwise
                    error('bad rnet.type')
            end

            if timeout<=0
                f=fopen('cmdLog.txt','a');
                fprintf(f,'%s: waitForSpecificCommand from %s (willing to wait forever): %s\n',datestr(now), mac, errStr);
                fclose(f);

            end

            highPriorityCommands=[emergencyCommands(:)',lightweightCommands(:)'];
            commandsToWaitFor = [highPriorityCommands,command];
            ps=getSortedPrioritiesHighestFirst(r);
            lowestPriority = ps(end);
            priorities = [repmat(r.constants.priorities.IMMEDIATE_PRIORITY,1,length(highPriorityCommands)),lowestPriority];

            if timeout>0
                endTime=GetSecs+timeout;
            else
                endTime=[];
            end

            while isempty(cmd) && (isempty(endTime) || GetSecs<endTime) && ~quit
                if ~isempty(endTime)
                    timeout=endTime-GetSecs;
                end

                % Wait for commands to appear
                cmd=waitForCommands(r,client,commandsToWaitFor,priorities,timeout);

                switch r.type
                    case r.constants.nodeTypes.SERVER_TYPE
                        if ~isConnected(r,client) || isClientReregistered(r,client)
                            try
                                f=fopen('SocketErrorLog.txt','a');
                                fprintf(f,'%s: waitForSpecificCommand from %s server unexpectedly no longer connected to this client\n',datestr(now),mac);
                                fclose(f);
                            catch ex
                                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                            end
                            fprintf('waitForSpecificCommand: Client unexpectedly disconnected\n')
                            client.id
                            isConnected(r,client)
                            isClientReregistered(r,client)
                            quit=true;
                        end
                    case r.constants.nodeTypes.CLIENT_TYPE
                        if ~isConnected(r)
                            quit=true;
                        end
                end
                if ~isempty(cmd)

                    f=fopen('cmdLog.txt','a');
                    fprintf(f,'%s: waitForSpecificCommand from %s: %s, got a command after %g\n',datestr(now), mac, errStr, GetSecs()-startTime);
                    fclose(f);

                    [good com args]=validateCommand(r,cmd);
                    if ~good
                        cmd=[];
                        fprintf('%s: waitForSpecificCommand got a command that failed validation!\n',datestr(now))
                    else
                        fprintf('%s: waitForSpecificCommand received from %s command %d (%s) (%d commands available)\n',datestr(now),mac,getCommand(cmd),getCommandStr(r,getCommand(cmd)),commandsAvailable(r));
                    end

                    if command~=com
                        switch r.type
                            case r.constants.nodeTypes.SERVER_TYPE
                                serverHandleCommand(r,cmd,[],[],[]);
                                quit=true; %hack for now, cuz only emergency commands are errors
                            case r.constants.nodeTypes.CLIENT_TYPE
                                quit=clientHandleVerifiedCommand(r,cmd,com,args,stat);
                        end

                        if quit
                            fprintf('waitForSpecificCommand got an unexpected quit!\n')
                        end
                        if ismember(com,lightweightCommands)
                            cmd=[];
                            fprintf('\twaitForSpecificCommand handling unexpected lightweight command (will return to original wait loop)!\n');
                        else
                            fprintf('\twaitForSpecificCommand handling unexpected emergency command (will break original wait loop)!\n');
                        end
                    end
                end
            end

            if isempty(cmd)
                client
                warning(['timed out: ' errStr])

                f=fopen('cmdLog.txt','a');
                fprintf(f,'%s: timed out of: %s, ignored %d commands in queue\n',datestr(now), errStr, commandsAvailable(r));
                fclose(f);
            end
        end
        
        
        
    end
    
end


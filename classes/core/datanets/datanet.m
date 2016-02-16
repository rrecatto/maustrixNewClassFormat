classdef datanet
    properties
        type = [];
        host = [];
        ports = [];
        cmdSockcon = [];
        ackSockcon = [];
        storepath = '';
        
        cmdCon = [];
        ackCon = [];
        client_hostname = '';
        ai_parameters = '';
    end
    
    properties (Constant)
        % data to stim commands
        D_START_TRIALS_CMD = 1;
        D_STOP_TRIALS_CMD = 2;
        D_SET_STOREPATH_CMD = 3;
        D_GET_TIME_CMD = 4;
        D_DELETE_DB = 5;
        
        % stim to data responses
        S_TRIALS_STARTED = 101;
        S_TRIALS_STOPPED = 102;
        S_STOREPATH_SET = 103;
        S_TIME_RESPONSE = 104;
        S_DB_DELETED = 105;
        % =================================================================
        % commands/responses where stim sends a command, data sends a response
        % stim to data commands
        S_TRIAL_START_EVENT_CMD = 51;
        S_TRIAL_END_EVENT_CMD = 52;
        S_STOP_RECORDING_CMD = 53;
        S_ERROR_RECOVERY_METHOD = 54;
        
        % data to stim responses
        D_TRIAL_START_EVENT_ACK = 151;
        D_TRIAL_END_EVENT_ACK = 152;
        D_RECORDING_STOPPED = 153;
        D_ERROR_METHOD_RECEIVED = 154;
        
        % special omni messages that can act as both a command and a response (ack)
        END_OF_DOTRIALS = 1001;
        
    end
    
    methods
        function d = datanet(varargin)
            switch nargin
                case 0
                    error('default datanet object not supported');
                case {2 3}
                    % stim side
                    if ischar(varargin{1}) && ischar(varargin{2})
                        if strcmp(varargin{1}, 'stim')
                            r.type = 'stim';
                            r.ports = [8888 8889];
                            r.host = varargin{2};
                        else
                            error('first argument must be ''stim'' and second argument must be a string');
                        end
                        % if we have ai_parameters
                        if nargin==3
                            if isstruct(varargin{3}) && strcmp(r.type, 'stim')
                                r.ai_parameters = varargin{3};
                            end
                        end
                    else
                        error('must be ''stim'' type, and provide hostname');
                    end
                case {4 5}
                    % data side
                    % type and hostname
                    if ischar(varargin{1}) && ischar(varargin{2})
                        if strcmp(varargin{1}, 'data')
                            r.type = 'data';
                            r.ports = [8888 8889];
                            r.host = varargin{2};
                        else
                            error('type must be data');
                        end
                    else
                        error('first argument must be ''data'' and second argument must be a string');
                    end
                    % client_hostname
                    if ischar(varargin{3})
                        r.client_hostname = varargin{3};
                    else
                        error('client_hostname must be a string');
                    end
                    % storepath
                    if ischar(varargin{4})
                        r.storepath = varargin{4};
                    else
                        error('data_storepath must be a valid directory');
                    end
                    % optional ai_parameters
                    if nargin==5
                        if isstruct(varargin{5})
                            r.ai_parameters = varargin{5};
                        else
                            error('ai_parameters must be a struct');
                        end
                    end
                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
        end
        
        function con = getAckCon(datanet)
            % retrieves the ackCon field of the datanet object (pnet connection)
            con = datanet.ackCon;
            
        end
        
        function con = getCmdCon(datanet)
            % retrieves the cmdCon field of the datanet object (pnet connection)
            con = datanet.cmdCon;
            
        end % end function
        
        function c = getConstants(datanet)
            
            c = datanet.constants;
        end
        
        function sp = getStorePath(datanet)
            sp = datanet.storepath;
            
        end % end function
        
        function t = getTimeFromClient(d)
            % gets a timestamp from the client using pnet
            constants=getConstants(d);
            
            commands=[];
            commands.cmd=constants.dataToStimCommands.D_GET_TIME_CMD;
            [gotAck t] = sendCommandAndWaitForAck(d,commands);
            
        end % end function
        
        function [datanet, quit, retval] = handleCommands(datanet,params)
            % This function gets called by the client's bootstrap function, and also at the doTrial/runRealTimeLoop level to handle any available
            % server commands. also gets called during physiologyServer's doServerIteration (to handle any commands sent from ratrix side)
            % INPUTS:
            %	datanet - a datanet object (either stim or data)
            %   params - a struct containing additional information that may be needed to process commands
            %       for now, this is a timestamp that was taken during 'trial start' and passed to 'trial end' for serverHandleCommand
            % OUTPUTS:
            %	quit - a quit flag (not sure if this will be doTrial's stopEarly or realtimeloop's quit), but something to tell ratrix to stop running trials!
            %	retval - some return value (in the case of doServerIteration, should be an event to add to events_data), may be other stuff....
            
            quit = false;
            retval=[];
            ret=[];
            CMDSIZE=1;
            commandAvailable=false;
            specificCommand=[];
            
            % ===================================================
            type=datanet.type;
            cmdCon=getCmdCon(datanet);
            ackCon=getAckCon(datanet);
            
            % ===================================================
            % try to get the first available command
            try
                cmd=pnet(cmdCon,'read',CMDSIZE,'double','noblock');
                if isempty(cmd) % no commands available, so just return
                    %         fprintf('no commands found!\n')
                    return;
                else
                    commandAvailable=true;
                    fprintf('we found a command (%d)!\n',cmd)
                end
            catch ex
                keyboard
                disp(['CAUGHT ER: ' getReport(ex)]);
                % do some cleanup here
            end
            
            % ===================================================
            % now loop while commandAvailable and use a switch statement on possible cmds received
            try
                while commandAvailable && ~quit
                    success=false;
                    if ~isempty(specificCommand) && cmd~=specificCommand
                        error('received a faulty command %d when waiting for the specific command %d',cmd,specificCommand);
                    end
                    
                    if strcmp(type,'stim')
                        [datanet, quit, specificCommand, response] = clientHandleCommand(datanet, cmdCon, cmd, specificCommand, params);
                    else
                        [quit, specificCommand, response, ret] = serverHandleCommand(datanet, cmdCon, cmd, specificCommand, params);
                    end
                    
                    % this means only one retval per server iteration for now...how to fix?
                    if ~isempty(ret)
                        if isempty(retval)
                            retval=ret;
                        else
                            retval(end+1)=ret;
                        end
                    end
                    
                    % give a response (usually an ack)
                    if ~isempty(response)
                        fprintf('writing response %d\n',response)
                        pnet(ackCon,'write',response);
                    end
                    
                    if quit
                        return
                    end
                    
                    % now check to see if another command is available
                    cmd=pnet(cmdCon,'read',CMDSIZE,'double','noblock');
                    if isempty(cmd) % no commands available, so just return
                        return;
                    else
                        commandAvailable=true;
                    end
                end
            catch ex
                disp(['CAUGHT ER (at handleCommands): ' getReport(ex)]);
                rethrow(ex);
                % do some cleanup here
            end
            
            
        end % end function
        
        function obj=loadobj(s)
            % r = datanet('stim', hostname, data_hostname, data_storepath, [ai_parameters])
            
            obj=datanet('stim',s.host,s.data_hostname,s.storepath,s.ai_parameters);
        end
        
        function [gotAck response] = sendCommandAndWaitForAck(datanet, commands)
            % this function sends a command to the data machine and waits for an ack
            % commands must be a struct that contains these fields:
            %   cmd - type double: choose from datanet.constants
            %   [optional] arg - type char: filename to save to given the r.constants.stimToDataCommands.S_SEND_DATA_CMD
            %                  - type double: ai_parameters
            %
            % if commands is empty, then dont send anything, just wait for an ack
            % (this may be useful for waiting for the omni-message END_OF_DOTRIALS)
            
            
            % 4/3 to do - remove trialData? - for now, just handle simple acks. this function should work from both the ratrix and data sides...
            MAXSIZE = 1024*1024;
            CMDSIZE = 1;
            trialData = [];
            % getDataFromFile = false; % flag to determine if we need to load from file for certain commands
            % if strmatch(datanet.type, 'data')
            %     error('must be called on datanet of type ''stim''');
            % end
            cmdCon=getCmdCon(datanet);
            ackCon=getAckCon(datanet);
            
            if isstruct(commands)
                % cmd
                if isfield(commands,'cmd') && isscalar(commands.cmd)
                    pnet(cmdCon,'write', commands.cmd);
                    fprintf('writing command %d\n', commands.cmd);
                elseif iscell(commands.cmd) % if cmd is a cell of variables - could be anything, so use putvar and getvar
                    pnet_putvar(cmdCon, commands.cmd);
                else
                    error('unsupported cmd type - must be constant or cell array');
                end
                % args
                if isfield(commands,'arg')
                    if ischar(commands.arg)
                        pnet(cmdCon,'write',commands.arg);
                        fprintf('writing arg %s\n', commands.arg);
                    elseif isnumeric(commands.arg)
                        pnet(cmdCon,'write',commands.arg);
                        fprintf('writing arg %s\n', commands.arg);
                    elseif isstruct(commands.arg) % a struct - use putvar
                        pnet_putvar(cmdCon, commands.arg);
                        fprintf('using putvar for arg\n');
                    else
                        error('args must be a char or number array');
                    end
                end
            elseif isempty(commands)
                % pass
            else
                error('commands must be a struct');
            end
            
            
            % wait for acknowledgement from data computer that connection was received
            gotAck = false;
            constants = getConstants(datanet);
            while ~gotAck
                % need a switch here depending on commands.cmd
                % most cases, just do the below,
                % but in case we need to use a pnet_getvar, this has to come BEFORE any
                % pnet('read') ops b/c pnet works that way dammit
                % for now, whenever commands.cmd==4 (getting neural events data)
                %     if ismember(commands.cmd, constants.pnetGetvarCommands) % getting neural events
                %         disp('trying pnet_getvar to get neural events');
                %         trialData=pnet_getvar(cmdCon);
                %     end
                received = pnet(ackCon,'read',CMDSIZE,'double','noblock');
                if ~isempty(received) % if we received something from data computer (ack or fail)
                    disp('received something')
                    received
                    receivedIsAck = isAck(datanet,received,constants);
                    if receivedIsAck
                        gotAck = true;
                        % 4/21/09 - now try to read again to check for a response
                        response=pnet(ackCon,'read',MAXSIZE,'double','noblock');
                    else
                        received
                        error('if received isnt empty and isnt an ack, then what is it?');
                    end
                else % didnt receive anything yet, so keep listening
                    
                end
            end
            
            
        end % end function
        
        
        
        % =====================================================================================
        function ack = isAck(datanet,data,constants)
            % this subfunction determines if the value returned from data is a success
            % acknowledgement (based on constants.stimToDataResponses)
            ack = false;
            responses = fields(constants.stimToDataResponses);
            for i=1:length(responses)
                if data == constants.stimToDataResponses.(responses{i})
                    ack = true;
                end
            end
            responses = fields(constants.dataToStimResponses);
            for i=1:length(responses)
                if data == constants.dataToStimResponses.(responses{i})
                    ack = true;
                end
            end
            responses = fields(constants.omniMessages);
            for i=1:length(responses)
                if data == constants.omniMessages.(responses{i})
                    ack = true;
                end
            end
            
        end % end function
        
        function [quit, specificCommand, response, retval] = serverHandleCommand(datanet,con,cmd,specificCommand,params)
            % This function gets called by handleCommands, which loops through available commands. This function just does the switch statement on cmd
            % and decides what to execute on the data (server) side.
            % INPUTS:
            %	datanet - the server-side datanet object; should already have a pnet connection with proper timeouts set
            %	cmd - the command from the server side to handle
            %	specificCommand - if nonempty, a specificCommand that is expected by the client (set during handleCommands by previous call to serverHandleCommand)
            %   params - a struct containing additional parameters passed from handleCommands
            % OUTPUTS:
            %	quit - not sure what this quit flag means just yet...
            %	specificCommand - return to handleCommands if the current cmd requires a specific command be the next in line
            %	response - a response message to send to the client (usually an ack)
            %	retval - something from the client that needs to be saved by the server (typically an element of events_data)
            
            quit = false;
            constants = getConstants(datanet);
            response = [];
            retval=[];
            MAXSIZE=1024*1024;
            CMDSIZE=1;
            
            % ===================================================
            if strmatch(datanet.type, 'stim')
                error('must be called on datanet of type ''data''');
            end
            
            % ===================================================
            try
                success=false;
                if ~isempty(specificCommand) && cmd~=specificCommand
                    error('received a faulty command %d when waiting for the specific command %d',cmd,specificCommand);
                end
                switch cmd
                    case constants.stimToDataCommands.S_TRIAL_START_EVENT_CMD
                        % mark start of trial - how do we add an event to events_data, which is all the way out in physiologyServer?
                        response=constants.dataToStimResponses.D_TRIAL_START_EVENT_ACK;
                        retval(end+1).type='trial start';
                        
                        
                        % create the neuralRecords file with that will get appended to by physServer in 30sec chunks
                        cparams=pnet_getvar(con);
                        retval(end).time=cparams.time; % should also have a timestamp from client
                        filename=cparams.neuralFilename;
                        stimFilename = cparams.stimFilename;
                        fullFilename = fullfile(datanet.storepath, 'neuralRecords', filename);
                        [~, filenameBase] = fileparts(fullFilename);
                        fullFilenameRaw = fullfile(datanet.storepath,'neuralRecordsRaw',filenameBase);
                        if params.recording
                            disp('saving matlab basic details');
                            numChunks = [];
                            samplingRate=params.samplingRate;
                            electrodeDetails = params.electrodeDetails;
                            save(fullFilename, 'samplingRate');
                            save(fullFilename, 'numChunks','-append');
                            save(fullFilename, 'stimFilename','-append');
                            save(fullFilename, 'electrodeDetails','-append');
                            
                            disp('making sure things are closed as they should be ');
                            params.ai.stop();
                            params.ai.SaveFile.close();
                            
                            
                            disp('opening new file for recording');
                            filenameRHD = sprintf('%s.rhd',fullFilenameRaw);
                            filenameRHD
                            params.ai.SaveFile.open(rhd2000.savefile.Format.intan, filenameRHD);
                            params.ai.run_continuously();
                        end
                        retval(end).neuralFilename = fullFilename; % return filename for appending by physServer
                        
                        retval(end).neuralFilenameRaw = fullFilenameRaw;
                        retval(end).datablock = params.datablock;
                        retval(end).ai = params.ai;
                        
                        retval(end).stimFilename = fullfile(datanet.storepath,'stimRecords',cparams.stimFilename);
                        retval(end).trialNumber=cparams.trialNumber;
                        retval(end).stimManagerClass=cparams.stimManagerClass;
                        retval(end).stepName=cparams.stepName;
                        retval(end).stepNumber=cparams.stepNumber;
                        fprintf('got trial start command from ratrix\n')
                    case constants.stimToDataCommands.S_TRIAL_END_EVENT_CMD
                        % mark end of trial - how do we add an event to events_data, which is all the way out in physiologyServer?
                        response=constants.dataToStimResponses.D_TRIAL_END_EVENT_ACK;
                        cparams=pnet_getvar(con);
                        retval(end+1).time=cparams.time; % timestamp from client
                        retval(end).type='trial end';
                        
                        % 4/11/09 - send remaining neural data for this trial (from last 30sec chunk time to now end of trial event)
                        if params.recording
                            try
                                disp('saving data for trial end');
                                params.ai.stop();
                                % while params.ai.FIFOPercentageFull>1 % until very little of what is remaining
                                while true
                                    params.datablock.read_next(params.ai);
                                    if ~ params.datablock.HasData
                                        break
                                    end
                                    params.datablock.save();
                                end
                                
                                disp('closing previous trial file')
                                params.ai.SaveFile.close();
                            catch ex
                                getReport(ex)
                                disp('failed to get neural records');
                                keyboard
                            end
                        end
                        
                        retval(end).datablock = params.datablock;
                        retval(end).ai = params.ai;
                        
                        fprintf('got trial end command from ratrix\n')
                    case constants.stimToDataCommands.S_ERROR_RECOVERY_METHOD
                        % whether client pressed 'Restart' or 'Quit'
                        response=constants.dataToStimResponses.D_ERROR_METHOD_RECEIVED;
                        cparams=pnet_getvar(con);
                        retval(end+1).errorMethod=cparams.method;
                        fprintf('got error recovery method from client\n')
                    case constants.omniMessages.END_OF_DOTRIALS
                        % this handles a k+q from the client
                        quit=true;
                        fprintf('we got a client kill!\n');
                        
                    otherwise
                        error('unknown command');
                end
                
                % now check to see if another command is available
                cmd=pnet(con,'read',CMDSIZE,'double','noblock');
                if isempty(cmd) % no commands available, so just return
                    return;
                else
                    commandAvailable=true;
                end
            catch ex
                if isfield(params,'ai') && ~isempty(params.ai)
                    params.ai.stop();
                    params.ai.SaveFile.close();
                end
                disp(['CAUGHT ER: ' getReport(ex)]);
                % do some cleanup here
            end
            
            
        end % end function
        
        function dn = setAckCon(dn,con)
            dn.ackCon=con;
        end
        
        function dn = setCmdCon(dn,con)
            dn.cmdCon=con;
        end
        
        function [datanet] = setStorePath(datanet, path)
            if ~ischar(path)
                error('path must be a string')
            end
            datanet.storepath=path;
        end
        
        function gotAck = startClientTrials(datanet,subjectID,protocolDetails,startEyelink,rigParams,subjectDetails)
            % This function sends a command to the client to set the correct datanet_storepath (for stimRecords) and then
            % to start running trials, and waits for an ack.
            % INPUTS:
            %	datanet - the server-side datanet object; should have a valid pnet connection with parameters (timeout) already set
            %	subjectID - the ID string of the subject to start (pass to standAloneRun)
            %	protocol - the name of the protocol file to run (pass to standAloneRun)
            %   determines if the eyelink should be run
            % OUTPUTS:
            %	gotAck - true if we get an ack from the client
            
            % tell client computer to start running trials and send an ack
            if ~exist('startEyelink','var')||isempty(startEyelink)
                startEyelink = true;
            end
            gotAck = false;
            constants=getConstants(datanet);
            commands=[];
            commands.cmd=constants.dataToStimCommands.D_SET_STOREPATH_CMD;
            params=[];
            params.storepath=getStorePath(datanet);
            commands.arg=params;
            gotAck = sendCommandAndWaitForAck(datanet,commands);
            
            protocol = protocolDetails.protocolName;
            trainingStepNum = protocolDetails.trainingStepNum;
            
            commands=[];
            commands.cmd=constants.dataToStimCommands.D_START_TRIALS_CMD;
            subjParams=[];
            subjParams.id=subjectID;
            subjParams.protocol=protocol;
            subjParams.startEyelink=startEyelink;
            subjParams.rigParams = rigParams;
            subjParams.subjectDetails = subjectDetails;
            subjParams.trainingStepNum = trainingStepNum;
            
            commands.arg=subjParams;
            gotAck = sendCommandAndWaitForAck(datanet,commands);
            
        end % end function
        
        
        function [gotAck, retval] = stopClientTrials(datanet,subjectID,params)
            % This function sends a command to the client to stop running trials, and waits for an ack.
            % INPUTS:
            %	datanet - the server-side datanet object; should have a valid pnet connection with parameters (timeout) already set
            %	subjectID - the ID string of the subject to start
            %		(pass to station.doTrials or whoever sets quit on ratrix side - just to make sure this is the correct subject to stop)
            %   params - the struct of params that includes the ai object so we can get the last trial's data
            % OUTPUTS:
            %	gotAck - true if we get an ack from the client
            %   retval - the event returned by handleCommands on the last trial's TRIAL_END_EVENT_CMD
            
            % tell client computer to stop running trials and send an ack
            gotAck = false;
            constants=getConstants(datanet);
            
            commands=[];
            commands.cmd=constants.dataToStimCommands.D_STOP_TRIALS_CMD;
            subjParams=[];
            subjParams.id=subjectID;
            commands.arg=subjParams;
            
            gotAck = sendCommandAndWaitForAck(datanet,commands);
            
            % now wait for this last trial's TRIAL_END_EVENT_CMD from client and save last neuralRecord
            retval=[];
            while isempty(retval) % wait until we get something from handling tm.doTrial's call to save neuralData
                [garbage, quit, retval] = handleCommands(datanet,params);
            end
            
            % now wait for the END_OF_DOTRIALS omni-message which gets sent after doTrials finishes in clientHandleCommand
            % (to indicate that client finished executing doTrials)
            gotAck = sendCommandAndWaitForAck(datanet,[]);
            
            
        end % end function
        
        
    end
end
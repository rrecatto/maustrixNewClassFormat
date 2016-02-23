classdef pump
    
    properties
        perialPortAddress='';
        mmDiameter=0.0;
        mlPerHour=0.0;
        doVolChecks=logical(0);
        motorRunningBit={};
        infTooFarBit={};
        wdrTooFarBit={};
        mlMaxSinglePump=0.0;
        maxPosition=0.0;
        mlOpportunisticRefill=0.0;
        mlAntiRock=0.0;

        units='';
        volumeScaler=0.0;
        serialPort=[];
        pumpOpen=logical(0);
        currentPosition=0.0;
        minPosition=0.0;

        const = [];
    end
    
    methods
        function p=pump(varargin)
            % PUMP  class constructor.
            % p = pump(serPortAddr mmDiam mlPerHr doVolChks   motorRunningBit infTooFarBit  wdrTooFarBit  mlMaxSinglePump mlMaxPos mlOpportunisticRefill mlAntiRock)

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'pump'))
                        p = varargin{1};
                    else
                        error('Input argument is not a pump object')
                    end

                case 11
                    % create object using specified values

                    if ischar(varargin{1})>0
                        p.serialPortAddress=varargin{1};
                    else
                        error('serialPortAddress must be a string')
                    end

                    checks=[varargin{2} varargin{3} varargin{8} varargin{9} varargin{10} varargin{11}];
                    if all(isnumeric(checks)) && all(isreal(checks)) && all(checks>0) && length(checks)==6 %this verifies they are each scalar
                        p.mmDiameter=varargin{2};
                        p.mlPerHour=varargin{3};
                        p.maxPosition=varargin{9};

                        if varargin{11}<= varargin{8} && varargin{11}<= varargin{8} && varargin{8}<= p.maxPosition
                            p.mlMaxSinglePump=varargin{8};
                            p.mlOpportunisticRefill=varargin{10};
                            p.mlAntiRock=varargin{11};
                        else
                            error('mlAntiRock and mlOpportunisticRefill must be <= mlMaxSinglePump and mlMaxSinglePump must be <= maxPosition')
                        end

                        if p.mmDiameter<=14.0
                            p.volumeScaler=1000;
                            p.units='UL';
                        else
                            p.units='ML';
                            p.volumeScaler=1;
                        end

                    else
                        error('mmDiameter, mlPerHour, mlMaxSinglePump, and mlMaxPosition must be strictly positive real numbers')
                    end

                    if islogical(varargin{4})
                        p.doVolChecks=varargin{4};
                    else
                        error('doVolChecks must be a logical')
                    end


                    checks={varargin{5},varargin{6},varargin{7}};
                    if goodPins(checks)
                        p.motorRunningBit = varargin{5};
                        p.infTooFarBit = varargin{6};
                        p.wdrTooFarBit = varargin{7};

                        if getDirForPinNum(p.motorRunningBit{2},'read')...
                                && getDirForPinNum(p.infTooFarBit{2},'read')...
                                && getDirForPinNum(p.wdrTooFarBit{2},'read')
                            %ok
                        else
                            error('wrong direction on those pins')
                        end            


                    else
                        error('motorRunningBit, infTooFarBit, and wdrTooFarBit must be unique {''hexPPortAddr'', int8 pin ID btw 1-17}')
                    end

                    

                otherwise
                    error('Wrong number of input arguments')
            end

            %ensurePumpStopped(p);
            % 
            % while 1
            %     [infTooFar(p) wdrTooFar(p)]
            %     in=input('test\n')
            %     if isempty(in)
            %         break
            %     end
            % end
        end
        
        function p=closePump(p)

            ensurePumpStopped(p);
            if ~p.pumpOpen
                warning('pump not open')
            end
            fprintf('closing pump serial connection\n')
            fclose(p.serialPort);
            p.pumpOpen=0;

            closeAllSerials;
        end
        
        function [durs t p]= doAction(p,mlVol,action)

            if ~ismember(action,{'reset position','infuse','withdrawl'})
                error('urecognized action')
            end

            durs=[];
            doChecks=0;
            %override = strcmp(action,'reset position') && mlVol==0;

            if mlVol<=p.mlMaxSinglePump && mlVol>=0 %|| override

                if motorRunning(p)
                    error('pump motor running before action (or power cut to pump, which tripped motor running bit)')
                    %warning('pump motor running before action')
                else

                    %[p.currentPosition p.maxPosition]
                    if (strcmp(action,'infuse') && p.currentPosition+mlVol>p.maxPosition) || (strcmp(action,'withdrawl') && p.currentPosition-mlVol<p.minPosition)
                        action
                        p.currentPosition
                        mlVol
                        p.maxPosition
                        error('request will put pump outside max/min position -- reset pump position first')
                        % [durs t p]=doAction(p,0,'reset position'); %can't do this automatically cuz caller needs to know it's going to happen so they can set valves correctly
                    end

                    %             if strcmp(action,'reset position') && mlVol==0
                    %                 fprintf('reseting position\n')
                    %                 mlVol=abs(p.currentPosition);
                    %                 if p.currentPosition>=0
                    %                     action='withdrawl';
                    %                 else
                    %                     action='infuse';
                    %                 end
                    %             end

                    switch action
                        case 'infuse'
                            if mlVol>0
                                if infTooFar(p)
                                    %                         warning('infuse request while sensor indicates infused too far -- probably flickering sensor with flag right at beam -- trying tiny hysteretic infuse')
                                    %                         [p durs]= sendCommands(p,{'PHN 1' sprintf('VOL %.4g',p.volumeScaler*p.mlAntiRock) 'RUN 1'});
                                    %                         p.currentPosition=p.currentPosition+p.mlAntiRock;
                                    %                         if infTooFar(p)
                                    %                             error('hysteretic infuse failed')
                                    %                         end
                                    error('infuse request while sensor indicates infused too far')
                                end
                                fprintf('infusing\n')
                                [p durs]= sendCommands(p,{'PHN 1' sprintf('VOL %.4g',p.volumeScaler*mlVol) 'RUN 1'});
                                p.currentPosition=p.currentPosition+mlVol;
                            end
                        case 'withdrawl'
                            if mlVol>0
                                if wdrTooFar(p)
                                    %                         warning('withdrawl request while sensor indicates withdrawn too far -- probably flickering sensor with flag right at beam -- trying tiny hysteretic withdrawl')
                                    %                         [p durs]= sendCommands(p,{'PHN 3' sprintf('VOL %.4g',p.volumeScaler*p.mlAntiRock) 'RUN 3'});
                                    %                         p.currentPosition=p.currentPosition-p.mlAntiRock;
                                    %                         if wdrTooFar(p)
                                    %                             error('hysteretic withdrawl failed')
                                    %                         end
                                    error('withdrawl reqeust while sensor indicates withdrawn too far')
                                end
                                fprintf('withdrawing\n')
                                [p durs]= sendCommands(p,{'PHN 3' sprintf('VOL %.4g',p.volumeScaler*mlVol) 'RUN 3'});
                                p.currentPosition=p.currentPosition-mlVol;
                            end
                        case 'reset position'
                            %dbstack
                            fprintf('reseting position\n')
                            tempMin=p.minPosition;
                            tempMax=p.maxPosition;
                            p.minPosition = -inf;
                            p.maxPosition = inf;
                            while ~infTooFar(p) && wdrTooFar(p)
                                [durs t p]=doAction(p,getMlOpportunisticRefill(p),'infuse');
                            end
                            while ~wdrTooFar(p)
                                try
                                    [durs t p]=doAction(p,getMlOpportunisticRefill(p),'withdrawl');
                                catch ex
                                    if strcmp(ex.message,'withdrawl reqeust while sensor indicates withdrawn too far')
                                        break %lack of hysteresis on sensor -- it told us that wdrTooFar was false, but then, without moving, decided wdrTooFar was true -- happens when flag is just breaking the beam
                                    else
                                        rethrow(ex)
                                    end
                                end
                            end
                            [durs t p]=doAction(p,getMlOpportunisticRefill(p),'infuse');
                            while wdrTooFar(p) %added this to avoid the issue of lots of repeated infuse/withdrawl cycles when initing pump
                                [durs t p]=doAction(p,getMlOpportunisticRefill(p),'infuse');
                            end
                            p.currentPosition=0.0;
                            p.minPosition = tempMin;
                            p.maxPosition = tempMax;
                        otherwise
                            error('pump received unknown action')
                    end

                    start=GetSecs();
                    pumpRunning = 1;
                    t=0;
                    while motorRunning(p)
                        t=t+1;
                    end
                    durs=[durs GetSecs()-start];

                    if doChecks
                        [p durs]= deal(durs, sendCommands(p,{'DIS' 'CLD WDR' 'CLD INF'}));
                    end

                    %             if strcmp(action,'reset position') && strcmp(action,'withdrawl')
                    %                 [dursTemp tTemp p]= doAction(p,p.mlAntiRock,'infuse');
                    %                 durs=[durs dursTemp];
                    %                 t=[t tTemp];
                    %             end

                end
            else
                error('request exceeds mlMaxSinglePump or is negative')
            end
        end
        
        function ensurePumpStopped(p)
            if motorRunning(p)
                warning('pump motor running -- or pump has lost power and motor running bit got tripped')
            end
        end
        
        function out=getBits(p)
            out={p.motorRunningBit,p.infTooFarBit,p.wdrTooFarBit};
        end
        
        function out=getCurrentPosition(p)
            out=p.currentPosition;
        end
    
        function out=getMlAntiRock(p)
            out=p.mlAntiRock;
        end
        
        function m=getMlMaxSinglePump(p)
            m=p.mlMaxSinglePump;
        end
        
        function out=getMlOpportunisticRefill(p)
            out=p.mlOpportunisticRefill;
        end

        function out=getMotorRunningBit(p)
            out=p.motorRunningBit;
        end
        
        function out=infTooFar(p)

            out = p.currentPosition>p.maxPosition || lptReadBit(p.infTooFarBit{1},p.infTooFarBit{2});
        end
        
        function [p durs]=openPump(p)

            closeAllSerials;

            ensurePumpStopped(p);

            mlDefaultVolume=.5;

            pumpProgram = ...
                {'*RESET' ...
                'VER' ...
                sprintf('DIA %.4g ',p.mmDiameter) ...
                'PHN 1' ...
                'FUN RAT' ...
                sprintf('RAT %d MH',p.mlPerHour) ...
                sprintf('VOL %.4g',p.volumeScaler*mlDefaultVolume) ...
                'DIR INF' ...
                'PHN 2' ...
                'FUN STP' ...
                'PHN 3' ...
                'FUN RAT' ...
                sprintf('RAT %d MH',p.mlPerHour) ...
                sprintf('VOL %.4g',p.volumeScaler*mlDefaultVolume) ...
                'DIR WDR' ...
                'PHN 4' ...
                'FUN STP' ...
                'CLD INF' ...
                'CLD WDR' ...
                'DIS' ...
                'PHN 1' ...
                'VOL' ...
                'PHN 3' ...
                'VOL' ...
                'ROM' ...
                'AL'};

            p.serialPort = serial(p.serialPortAddress,'BaudRate',19200,'Terminator',{3,'CR'},'Timeout',1.0);
            fprintf('opening pump serial connection\n');

            if ~p.pumpOpen
                try
                    fopen(p.serialPort);
                    p.pumpOpen=1;
                    [p durs]=sendCommands(p,pumpProgram);
                catch ex
                    fprintf('closing serial port due to error\n');
                    fclose(p.serialPort);
                    rethrow(ex)
                end
            else
                error('pump already open')
            end
        end
        
        function out=outsidePositionBounds(p)
            %out=p.currentPosition>p.maxPosition || p.currentPosition<p.minPosition;
            out=wdrTooFar(p) || infTooFar(p) || p.currentPosition>p.maxPosition || p.currentPosition<p.minPosition;

            if out
                'wdrtoofar:'
                wdrTooFar(p)
                'inftoofar:'
                infTooFar(p)
                '[min cur max]:'
                [p.minPosition p.currentPosition p.maxPosition]
            end
        end
        
        function out=wdrTooFar(p)

            out = p.currentPosition<p.minPosition || lptReadBit(p.wdrTooFarBit{1},p.wdrTooFarBit{2});
        end
    end
    methods (Access=private)
       function out=motorRunning(p)
            out = lptReadBit(p.motorRunningBit{1},p.motorRunningBit{2})==p.const.motorRunning;
       end
       
       function [p durs]=sendCommands(p,cmds)
            showWarnings=true;

            if p.pumpOpen
                durs=zeros(1,length(cmds));
                for i=1:length(cmds)
                    start=GetSecs();

                    successfulSend=false;
                    while ~successfulSend
                        try
                            sprintf('sending %s',cmds{i});
                            fprintf(p.serialPort,cmds{i});
                            try
                                in=fscanf(p.serialPort);
                                if strcmp(in(2:4),'00A')
                                    warning('got pump alarm ''%s'' -- trying resend (not cycling pump)',in)
                                else
                                    successfulSend=true;
                                end
                            catch ex
                               disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                                in
                                warning('pump failure on read!  cycling pump!')
                                p=closePump(p);
                                p=openPump(p);
                            end
                        catch ex
                            disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                            warning('pump failure on write!  cycling pump!')
                            p=closePump(p);
                            p=openPump(p);
                            %rethrow(ex)
                        end
                    end
                    durs(i)=GetSecs()-start;
                    %in %once this was empty!  figure out why?
                    if int8(in(1))==2 && int8(in(end))==3
                        in=in(2:end-1);
                        switch cmds{i}
                            case 'DIS'
                                if strcmp(in(1:3),'00S') && ...
                                        ... %(strcmp(in(4:15),sprintf('I%4.3fW%4.3f',volume,volume)) || strcmp(in(4:15),'I0.000W0.000')) && ...
                                        strcmp(in(16:17),p.units)
                                    if showWarnings
                                        warning('unchecked pump response to [%s]: [%s i:%s w:%s %s]',cmds{i},in(1:3),in(5:9),in(11:15),in(16:17))
                                    end
                                else
                                    error(sprintf('unexpected pump response to [%s]: [%s]',cmds{i},in))
                                end
                            case 'VOL'
                                if strcmp(in(1:3),'00S') && strcmp(in(9:10),p.units) %&& strcmp(in(4:8),sprintf('%4.3f',volume))
                                    if showWarnings
                                        warning('unchecked pump response to [%s]: [%s %s %s]',cmds{i},in(1:3),in(4:8),in(9:10))
                                    end
                                else
                                    error(sprintf('unexpected pump response to [%s]: [%s]',cmds{i},in))
                                end
                            case 'RUN 1'
                                checkStr(in,'00I',cmds{i});
                            case 'RUN 3'
                                checkStr(in,'00W',cmds{i});
                            case {'ROM' 'AL' 'DIR'}
                                if showWarnings
                                    warning(sprintf('unchecked pump response to [%s]: [%s]',cmds{i},in))
                                end
                                %need to fill these in
                            case 'VER'
                                if strcmp(in(1:6),'00SNE5')
                                    fprintf('pump firmware version: %s\n',in(4:end))
                                else
                                    error(sprintf('unexpected response to [%s]: [%s]',cmds{i},in))
                                end
                            otherwise
                                checkStr(in,'00S',cmds{i});
                        end
                    else
                        error('response from pump doesn''t have correct initiator/terminator')
                    end
                end
            else
                error('pump not open')
            end
       end
        function checkStr(resp,pred,cause)
            if ~strcmp(resp,pred)
                error(sprintf('pump responded to [%s] with [%s], should have responded [%s]',cause,resp,pred))
            end
        end
    end
    
    
end


classdef pumpSystem
    
    properties
        pump=[];
        zones={};
        lastZone=0;
        needsAntiRock=true;
    end
    
    methods
        function s=pumpSystem(varargin)
            % PUMPSYSTEM  class constructor.
            % s = pumpSystem(pump,{cell array of zones})

            if ~ispc
                error('pump systems only supported on pc')
            end

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s = class(s,'pumpSystem');
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'pumpSystem'))
                        s = varargin{1};
                    else
                        error('Input argument is not a pumpSystem object')
                    end

                case 2
                    % create object using specified values

                    if isa(varargin{1},'pump')
                        s.pump=varargin{1};
                    else
                        error('pump must be a pump')
                    end

                    bits=getBits(s.pump);
                    putativeZones=varargin{2};
                    for i=1:length(putativeZones)
                        if ~isa(putativeZones{i},'zone')
                            error('all zones must be zones')
                        else
                            s.zones{i}=putativeZones{i};
                            newBits=getBits(s.zones{i});
                            for j=1:length(newBits)
                                bits{end+1}=newBits{j};
                            end
                        end

                    end

                    if ~goodPins(bits)
                        error('zones and pump must not contain any identical valve or sensor bits')
                    end

                    s = class(s,'pumpSystem');

                otherwise
                    error('Wrong number of input arguments')
            end

            closeAllValves(s);
        end
        
        function closeAllValves(s)
            for i = 1:length(s.zones)
                closeAllValves(s.zones{i});
            end
        end
        
        function s=closePumpSystem(s)
            [durs t s.pump]=resetPumpPosition(s.zones{1},s.pump);
            s.pump=closePump(s.pump);
            durs=ensureAllRezFilled(s);
            closeAllValves(s);
            s=[];
        end
        
        function s=considerOpportunisticRefill(s)
            [s.pump didOpportunisiticRefill]=considerOpportunisticRefill(s.zones{s.lastZone},s.pump);
            if didOpportunisiticRefill
                s.needsAntiRock=true;
            elseif s.needsAntiRock   %don't do this every time cuz might want to do more refills first
                s.pump=doAntiRock(s.zones{s.lastZone},s.pump);
                s.needsAntiRock = false;
            end
        end
        
        function s = doAntiRock(s,k)
            s.pump = doAntiRock(s.zones{k},s.pump);
        end
        
        function [durs,s] = doInfuse(s,zoneNum,vol,check)
            [durs,s.pump] = doInfuse(s.zones{zoneNum},s.pump,vol,check);
        end

        function s=doOpportunisticRefillPumps(s,vol,keys)

            if isscalar(vol) && isreal(vol) && vol>0
            else
                error('vol must be a strictly positive real number')
            end

            try
                lastZone=0;
                closeAllValves(s);
                [s.pump durs]=openPump(s.pump);

                [durs t s.pump]=resetPumpPosition(s.zones{1},s.pump);
                %[s lastZone] = doPrime(s);

                pause

                ListenChar(2)
                FlushEvents('keyDown')
                done=0;
                needsAntiRock=1;
                fprintf('hit the key for a zone (%s) to deliver a %g ml reward, ''q'' to quit\n',num2str([1:length(s.zones)]),vol)
                while ~done
                    for i=1:length(s.zones)
                        setOnlineRefill(s.zones{i});
                    end
                    % Check for commands from the command queue here
                    % FILL IN
                    if ~isempty(keys) || CharAvail()
                        if ~isempty(keys)
                            k=keys(1);
                            keys=keys(2:end);
                        else
                            k=GetChar(0);
                        end

                        switch k
                            case 'q'
                                done=1;
                            case 'p'
                                [s lastZone] = doPrime(s);
                                needsAntiRock = 1;
                            otherwise
                                k=str2num(k);
                                if ~isempty(k) && k>0 && k<=length(s.zones)
                                    fprintf('doing zone %d\n',k)
                                    if needsAntiRock
                                        s.pump=doAntiRock(s.zones{k},s.pump);
                                        lastZone=k;
                                        needsAntiRock=0;
                                    end
                                    [durs s.pump] =doInfuse(s.zones{k},s.pump,vol,lastZone~=k);
                                    lastZone=k;
                                end
                        end
                    else
                        if lastZone==0
                            lastZone=ceil(rand*length(s.zones));
                            [s.pump durs]=equalizePressure(s.zones{lastZone},s.pump);
                        elseif ismember(lastZone,1:length(s.zones))
                            %OK
                        else
                            error('lastZone is bad val: %g',lastZone)
                        end
                        [s.pump didOpportunisiticRefill]=considerOpportunisticRefill(s.zones{lastZone},s.pump);
                        if didOpportunisiticRefill
                            needsAntiRock=1;
                        elseif needsAntiRock
                            s.pump=doAntiRock(s.zones{lastZone},s.pump);
                            needsAntiRock = 0;
                        end
                    end
                end
                ListenChar(1)

                [durs t s.pump]=resetPumpPosition(s.zones{1},s.pump);
                s.pump=closePump(s.pump);
                durs=ensureAllRezFilled(s);
                closeAllValves(s);
            catch ex
                %ListenChar(1) %this is needed to undo the ListenChar(2) above, but seems to replace useful errors with 'Undefined function or variable 'GetCharJava_1_4_2_09'.'
                closeAllValves(s);
                fprintf('closing pump due to error\n');
                s.pump=closePump(s.pump);
                rethrow(ex)
            end
        end
        
        function [s lastZone] = doPrime(s)
                    for i=1:length(s.zones)
                        fprintf('priming zone %d\n',i)
                        s.pump=doPrime(s.zones{i},s.pump);
                        lastZone=i;
                    end
        end
        
        function s=doPumps(s,zones,vol)

            if nargin==2
                if ~size(zones,1)==2
                    error('2 arg call requires zones to have 2 rows.  row 1 holds the target zones, row 2 holds the target volumes')
                end
            elseif nargin==3
                if isscalar(vol) && isreal(vol) && vol>0 && (size(zones,1)==1 || isempty(zones))
                    zones=[zones;vol*ones(1,length(zones))];
                else
                    error('vol must be a strictly positive real number, and zones must be a 1-dim vector or empty')
                end
            else
                error('2 or 3 args required')
            end

            try
                lastZone=0;
                closeAllValves(s);
                [s.pump durs]=openPump(s.pump);

                if isempty(zones)
                    ListenChar(2)
                    FlushEvents('keyDown')
                    done=0;
                    while ~done
                        fprintf('hit the key for a zone (%s) to deliver a %g ml reward, ''q'' to quit\n',num2str([1:length(s.zones)]),vol)
                        k=GetChar(0);
                        switch k
                            case 'q'
                                done=1;
                            otherwise
                                k=str2num(k);
                                if ~isempty(k) && k>0 && k<=length(s.zones)
                                    fprintf('doing zone %d\n',k)
                                    [durs s.pump] =doInfuse(s.zones{k},s.pump,vol,lastZone~=k);
                                    lastZone=k;
                                end
                        end
                    end
                    ListenChar(1)
                else
                    for i=1:size(zones,2)
                        fprintf('doing zone %d, pump %d\n',zones(1,i),i);
                        [durs s.pump]=doInfuse(s.zones{zones(1,i)},s.pump,zones(2,i),lastZone~=zones(1,i));
                        lastZone=zones(1,i);
                    end
                end

                [durs t s.pump]=resetPumpPosition(s.zones{1},s.pump);
                s.pump=closePump(s.pump);
                durs=ensureAllRezFilled(s);
                closeAllValves(s);
            catch ex
                %ListenChar(1) %this is needed to undo the ListenChar(2) above, but seems to replace useful errors with 'Undefined function or variable 'GetCharJava_1_4_2_09'.'
                closeAllValves(s);
                fprintf('closing pump due to error\n');
                s.pump=closePump(s.pump);
                rethrow(ex)
            end
        end
        
        function s=doReward(s,mlRewardSize,zone)
            fprintf('rewarding zone %d\n',zone)
            if s.needsAntiRock
                s.pump=doAntiRock(s.zones{zone},s.pump);
                s.lastZone=zone;
                s.needsAntiRock=false;
            end
            [durs s.pump] =doInfuse(s.zones{zone},s.pump,mlRewardSize,s.lastZone~=zone);
            s.lastZone=zone;
        end
        
        function durs=ensureAllRezFilled(s)
            durs=zeros(1,length(s.zones));
            for i=1:length(s.zones)
                durs(i)=ensureRezFilled(s.zones{i});
            end
        end
        
        function [s durs]=equalizePressure(s,lastZone)
            [s.pump durs]=equalizePressure(s.zones{lastZone},s.pump);
        end

        function s=initPumpSystem(s)
            if ~isempty(s.zones)
                closeAllValves(s);
                [s.pump durs]=openPump(s.pump);
                s.lastZone=ceil(rand*length(s.zones));
                [durs t s.pump]=resetPumpPosition(s.zones{s.lastZone},s.pump);
                [s.pump durs]=equalizePressure(s.zones{s.lastZone},s.pump);
                s.needsAntiRock=false;
            else
                error('can''t init a pumpsystem with no zones')
            end
        end
        
        function num = numZones(s)
            num = length(s.zones);
        end

        function [s durs] = openPumpSystem(s)
            [s.pump durs]=openPump(s.pump);
        end

        function [durs t s]=resetPumpPosition(s,zoneNum)
            [durs t s.pump]=resetPumpPosition(s.zones{zoneNum},s.pump);
        end

        %need to rapidly call this over and over to avoid flooding!
        function setOnlineRefill(s)
            for i=1:length(s.zones)
                setOnlineRefill(s.zones{i});
            end
        end
    
        
    end
    
end


classdef zone
    
    properties
        rezSensorBit = {};
        reservoirValveBit = {};
        toStationsValveBit = {};
        fillRezValveBit = {};
        valveDelay = 0; % How long to wait after changing the valve state
        equalizeDelay = 0; % How long to wait to equalize pressure
        
        const = [];

    end
    
    methods
        function z=zone(varargin)
            % ZONE  class constructor.
            % z = zone(rezSensorBit,reservoirValveBit,toStationsValveBit,fillRezValveBit,valveDelay,equalizeDelay)
            z.const.valveOff = int8(0);
            z.const.valveOn = int8(1);
            z.const.sensorBlocked = int8(0);%'0';

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'zone'))
                        z = varargin{1};
                    else
                        error('Input argument is not a zone object')
                    end

                case 6
                    % create object using specified values

                    checks={varargin{1},varargin{2},varargin{3},varargin{4}};
                    if goodPins(checks)
                        z.rezSensorBit = varargin{1};
                        z.reservoirValveBit = varargin{2};
                        z.toStationsValveBit = varargin{3};
                        z.fillRezValveBit = varargin{4};

                        if strcmp(getDirForPinNum(z.rezSensorBit{2}),'read')...
                                && strcmp(getDirForPinNum(z.reservoirValveBit{2}),'write')...
                                && strcmp(getDirForPinNum(z.toStationsValveBit{2}),'write')...
                                && strcmp(getDirForPinNum(z.fillRezValveBit{2}),'write')
                            %ok
                        else
                            error('wrong direction on those pins')
                        end

                    else
                        error('rezSensorBit, reservoirValveBit, toStationsValveBit, and fillRezValveBit must be unique {''hexPPortAddr'', int8 pin ID btw 1-17}')
                    end        

                    if all([varargin{5} varargin{6}]>=0) && all(isnumeric([varargin{5} varargin{6}])) && all(isreal([varargin{5} varargin{6}]))
                        z.valveDelay = varargin{5};
                        z.equalizeDelay = varargin{6};
                    else
                        error('valveDelay and equalizeDelay must be real numbers >= 0')
                    end


                    

                otherwise
                    error('Wrong number of input arguments')
            end
            closeAllValves(z);
        end
        
        function closeAllValves(z)
            bits=getValveBits(z);
            for i = 1:length(bits)
                setValve(z,bits{i},z.const.valveOff);
            end
        end
        
        function closeRezValve(z)
            setValve(z,z.reservoirValveBit,z.const.valveOff);
        end
        
        function [pump didOpportunisiticRefill]=considerOpportunisticRefill(z,pump)
            if getCurrentPosition(pump)>=getMlOpportunisticRefill(pump)

                setValve(z,z.reservoirValveBit,z.const.valveOn);
                [durs t pump]=doAction(pump,getMlOpportunisticRefill(pump),'withdrawl');
                setValve(z,z.reservoirValveBit,z.const.valveOff);

                didOpportunisiticRefill=1;
            else
                didOpportunisiticRefill=0;
            end
        end
        
        function pump=doAntiRock(z,pump)

            setValve(z,z.reservoirValveBit,z.const.valveOn);
            [durs t pump]=doAction(pump,getMlAntiRock(pump),'infuse');
            [pump durs]=equalizePressure(z,pump);
            setValve(z,z.reservoirValveBit,z.const.valveOff);
        end
        
        function [durs pump] =doInfuse(z,pump,mlVol,needsEqualization)
            durs=[];

            if mlVol>getMlMaxSinglePump(pump)
                numPumps=ceil(mlVol/getMlMaxSinglePump(pump));
                volPerPump=mlVol/numPumps;

                for i=1:numPumps
                    [dursTemp pump] = doInfuse(z,pump,volPerPump,needsEqualization);
                    durs=[durs dursTemp];
                    needsEqualization=0;
                end
            else

                if outsidePositionBounds(pump)
                    [dursTemp t pump]=resetPumpPosition(z,pump);
                    durs=[durs dursTemp];
                    needsEqualization=0;
                end

                if needsEqualization %|| true
                    [pump dursTemp]=equalizePressure(z,pump);
                    durs=[durs dursTemp];
                end
                %[durs pump] = [durs doAction(z,'infuse',z.toStationsValveBit,pump,mlVol)];
                %[durs pump] = [durs doAction(z,'withdrawl',z.reservoirValveBit,pump,mlVol)];


                setValve(z,z.toStationsValveBit,z.const.valveOn);
                [durs t pump]=doAction(pump,mlVol,'infuse');
                setValve(z,z.toStationsValveBit,z.const.valveOff);
            end
        end
        
        function pump=doPrime(z,pump)
            ensureRezFilled(z);
            pump=emptyRez(z,pump);

            % while ~infTooFar(pump)
            %     setValve(z,z.toStationsValveBit,z.const.valveOn);
            %     [durs t pump]=doAction(pump,getMlOpportunisticRefill(pump),'infuse');
            % end
            % setValve(z,z.toStationsValveBit,z.const.valveOff);
            % 
            % while ~wdrTooFar(pump)
            %     setValve(z,z.reservoirValveBit,z.const.valveOn);
            %     [durs t pump]=doAction(pump,getMlOpportunisticRefill(pump),'withdrawl');
            % end
            % setValve(z,z.reservoirValveBit,z.const.valveOff);


        end
        
        function pump=emptyRez(z,pump)

            while ~infTooFar(pump)
                setValve(z,z.toStationsValveBit,z.const.valveOn);
                [durs t pump]=doAction(pump,getMlOpportunisticRefill(pump),'infuse');
            end
            setValve(z,z.toStationsValveBit,z.const.valveOff);

            while ~wdrTooFar(pump)
                setValve(z,z.reservoirValveBit,z.const.valveOn);
                [durs t pump]=doAction(pump,getMlOpportunisticRefill(pump),'withdrawl');
            end
            [durs t pump]=doAction(pump,0,'reset position');
            setValve(z,z.reservoirValveBit,z.const.valveOff);
        end
        
        function dur=ensureRezFilled(z)
            start=GetSecs();
            full=0;
            beeped=0;
            while ~full
                if sensorBlocked(z)
                    if ~beeped
                        beep
                        beeped=1;
                        fprintf('refilling\n')
                    end
                    setValve(z,z.fillRezValveBit,z.const.valveOn);
                else
                    setValve(z,z.fillRezValveBit,z.const.valveOff);
                    full=1;
                    if beeped
                        beep
                    end
                end
            end
            dur=GetSecs()-start;
        end
        
        function [pump dur]=equalizePressure(z,pump)
            dur=ensureRezFilled(z);

            setValve(z,z.reservoirValveBit,z.const.valveOn);

            %WaitSecs(z.equalizeDelay);

            equalizeVol=.01;

            [durs t pump]=doAction(pump,equalizeVol,'infuse');
            WaitSecs(z.equalizeDelay);

            setValve(z,z.reservoirValveBit,z.const.valveOff);
 
 
            if outsidePositionBounds(pump)
               [dursTemp t pump]=resetPumpPosition(z,pump);
               pump = equalizePressure(z,pump);
            end
        end
        
        function out=getBits(z)
            out=getValveBits(z);
            out{end+1}=getSensorBit(z);
        end
        
        function out=getSensorBit(z)
            out= z.rezSensorBit;
        end
        
        function out=getValveBits(z)
            out= {z.reservoirValveBit  z.toStationsValveBit  z.fillRezValveBit};
        end
        
        function openRezValve(z)
            setValve(z,z.reservoirValveBit,z.const.valveOn);
        end
        
        function [durs t pump]=resetPumpPosition(z,pump)
            durs=[];
            durs=[durs ensureRezFilled(z)];
            setValve(z,z.reservoirValveBit,z.const.valveOn);
            [dursTemp t pump]=doAction(pump,0,'reset position');
            durs=[durs dursTemp];
            setValve(z,z.reservoirValveBit,z.const.valveOff);
            durs=[durs ensureRezFilled(z)];
        end
        
        function out=sensorBlocked(z)
            out = lptReadBit(z.rezSensorBit{1},z.rezSensorBit{2})==z.const.sensorBlocked;
        end
        
        function setValve(z,valve,state)
            lptWriteBit(valve{1},valve{2},state);
            WaitSecs(z.valveDelay);
        end
        
        function setOnlineRefill(z)
            if sensorBlocked(z)
                setValve(z,z.fillRezValveBit,z.const.valveOn);
            else
                setValve(z,z.fillRezValveBit,z.const.valveOff);
            end
        end
        
        
    end
    
end


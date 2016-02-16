classdef standardStation <station
    
    properties
        decPPortAddr = '';
        rewardMethod = 'localTimed';
        valvePins = [];
        sensorPins=[];
        framePins=[];
        phasePins=[];
        stimPins=[];
        indexPins=[];
        trialPins = [];
        LED1Pins = [];
        LED2Pins = [];
    end
    
    methods
        function st = standardStation(varargin)
            if nargin>=1
                stationParams = varargin{1};
            else
                stationParams.id = 1;
                stationParams.path = 1;
            end
            st = st@station(stationParams);
            switch nargin
                case 0
                    %pass
                case 2
                    in = varargin{2};
 
                    validateattributes(in.decPPortAddr,{'char'},{'nonempty'})
                    st.decPPortAddr = in.decPPortAddr;
                    
                    validateattributes(in.rewardMethod,{'char','<pump>'},{'nonempty'})
                    st.rewardMethod = in.rewardMethod;
                    
                    usedPins = [];
                    
                    validateattributes(in.valvePins,{'numeric'},{'integer','vector'})
                    st.valvePins = in.valvePins;
                    if intersect(usedPins,st.valvePins), error('standardStation:improperValue','valvePins uses already used pin'); end
                    usedPins = union(usedPins,st.valvePins);
                        
                    validateattributes(in.sensorPins,{'numeric'},{'integer','vector'})
                    st.sensorPins = in.sensorPins;
                    if intersect(usedPins,st.sensorPins), error('standardStation:improperValue','sensorPins uses already used pin'); end
                    usedPins = union(usedPins,st.sensorPins);
                    
                    validateattributes(in.framePins,{'numeric'},{'integer'})
                    st.framePins = in.framePins;
                    if intersect(usedPins,st.framePins), error('standardStation:improperValue','framePins uses already used pin'); end
                    usedPins = union(usedPins,st.framePins);
                    
                    validateattributes(in.phasePins,{'numeric'},{'integer'})
                    st.phasePins = in.phasePins;
                    if intersect(usedPins,st.phasePins), error('standardStation:improperValue','phasePins uses already used pin'); end
                    usedPins = union(usedPins,st.phasePins);
                        
                    validateattributes(in.stimPins,{'numeric'},{'integer'})
                    st.stimPins = in.stimPins;
                    if intersect(usedPins,st.stimPins), error('standardStation:improperValue','stimPins uses already used pin'); end
                    usedPins = union(usedPins,st.stimPins);
                    
                    validateattributes(in.indexPins,{'numeric'},{'integer'})
                    st.indexPins = in.indexPins;
                    if intersect(usedPins,st.indexPins), error('standardStation:improperValue','indexPins uses already used pin'); end
                    usedPins = union(usedPins,st.indexPins);
                    
                    validateattributes(in.trialPins,{'numeric'},{'integer'})
                    st.trialPins = in.trialPins;
                    if intersect(usedPins,st.trialPins), error('standardStation:improperValue','trialPins uses already used pin'); end
                    usedPins = union(usedPins,st.trialPins);
                    
                    validateattributes(in.LED1Pins,{'numeric'},{'integer'})
                    st.LED1Pins = in.LED1Pins;
                    if intersect(usedPins,st.LED1Pins), error('standardStation:improperValue','LED1Pins uses already used pin'); end
                    usedPins = union(usedPins,st.LED1Pins);
                    
                    validateattributes(in.LED2Pins,{'numeric'},{'integer'})
                    st.LED2Pins = in.LED2Pins;
                    if intersect(usedPins,st.LED2Pins), error('standardStation:improperValue','LED2Pins uses already used pin'); end
                    usedPins = union(usedPins,st.LED2Pins);
                    
                    st.responseMethod = 'parallelPort';
                    
            end
        end
        
        function times=flushPorts(st,dursSec,numSquirts,ifi,ports)
            
            if ~exist('dursSec','var')
                dursSec=2;
            end            
            
            if ~exist('numSquirts','var')
                numSquirts=1;
            end
            
            if ~exist('ifi','var')
                ifi=.1;
            end
            
            numPorts=getNumPorts(st);
            
            if all(size(dursSec)==1)
                squirtDuration = dursSec*ones(1,3);
            else
                squirtDuration=dursSec;
                if length(dursSec) ~= getNumPorts(st)
                    %check that there are only as many args as available ports;
                    error('durMs bust be length of num ports')
                end
            end
            
            %set bag pressure to just below letters that say "PRESSURE"
            
            i=1;
            times=zeros(3,numSquirts);
            
            % localTimed method
            for i=1:numSquirts
                for j=ports
                    valvesUsed=zeros(1,numPorts);
                    valvesUsed(j)=1;
                    
                    setValves(st,valvesUsed); %open
                    
                    times(j,i)=GetSecs();
                    WaitSecs(squirtDuration(j));
                    times(j,i)=GetSecs()-times(j,i);
                    
                    setValves(st,zeros(1,numPorts)); %close
                    
                    WaitSecs(ifi);
                end
            end
        end
        
        function [r, exitByFinishingTrialQuota]=doTrials(s,r,n,trustOsRecordFiles)
            setValves(s, 0*getValves(s))
             % only difference is setValve. All the rest of the method is
             % identical to doTrial of station
             
            [r, exitByFinishingTrialQuota]=doTrials@station(s,r,n,trustOsRecordFiles);         
        end
        
        function valves =getValves(s)
            if strcmp(s.responseMethod,'parallelPort')
                
                status=fastDec2Bin(lptread(s.valvePins.decAddr));
                
                valves=status(s.valvePins.bitLocs)=='1'; %need to set parity in station, assumes normally closed valves
                valves(s.valvePins.invs)=~valves(s.valvePins.invs);
            else
                if ~ismac
                    warning('can''t read ports without parallel port')
                end
                valves=false(1,s.numPorts);%*s.valvePins.bitLocs;
            end
        end
        
        function ports=readPorts(s)
                status=fastDec2Bin(lptread(s.sensorPins.decAddr));
                ports=status(s.sensorPins.bitLocs)=='0'; %need to set parity in station, assumes sensors emit +5V for unbroken beams
                ports(s.sensorPins.invs)=~ports(s.sensorPins.invs);
        end
        
        function securePins(st)
            setValves(st,0*getValves(st))
            setStatePins(st,'all',false);
            verifyValvesClosed(st);
        end
        
        function [endValveState, valveErrorDetails]=setAndCheckValves(station, requestedValves,expectedValveState,valveErrorDetails,startTime,description,barebones)
            
            if ~exist('barebones','var') || isempty(barebones)
                barebones=true;%false;
            end
            
            %[endValveState valveErrorDetails]=setAndCheckValves(station, requestedValves,expectedValveState,valveErrorDetails,startTime,description)
            %
            %set the valves to the requested value
            %first check to make sure the valves are in the expected state
            %if not, it logs an error
            if strcmp(station.responseMethod,'parallelPort')
                if ~barebones
                    %CHECK to see if the valves are as we expect
                    beforeValveState=getValves(station);
                    if ~all(beforeValveState==expectedValveState)
                        disp('VALVE ERROR: LOGGING IT')
                        errNum=size(valveErrorDetails,2)+1;
                        valveErrorDetails(errNum).timeSinceTrial=GetSecs()-startTime;
                        valveErrorDetails(errNum).expected=expectedValveState;
                        valveErrorDetails(errNum).found=beforeValveState;
                        valveErrorDetails(errNum).description=description;
                    else
                        %don't update
                        %valveErrorDetails=valveErrorDetails;
                    end
                end
                
                % DO IT
                setValves(station, requestedValves);
                
                if ~barebones
                    %return the end state of the valves
                    %If getValves is slow we could assume they are as requested
                    endValveState=getValves(station);
                    if any(endValveState~=requestedValves)
                        endValveState=endValveState
                        requestedValves=requestedValves
                        error('valve setting failed')
                        %it might be porttalk isn't installed
                        %follw instructions: http://tech.groups.yahoo.com/group/psychtoolbox/message/4825
                        %download from here: http://www.beyondlogic.org/porttalk/porttalk.htm
                    end
                else
                    endValveState=requestedValves;
                end
                
                
            else
                if ~ismac
                    warning('can''t check and set valves without parallel port')
                end
                endValveState=false(1,station.numPorts);
            end
        end
        
        function setStatePins(s,pinClass,state)
            if isscalar(state)
                state=logical(state);
            else
                error('state must be scalar')
            end
            
            done=false;
            possibles={ ... %edf worries this is slow
                'frame',s.framePins; ...
                'stim',s.stimPins; ...
                'phase',s.phasePins; ...
                'index',s.indexPins;...
                'trial',s.trialPins;...
                'LED1',s.LED1Pins;...
                'LED2',s.LED2Pins};
            
            
            
            for i=1:size(possibles,1)
                if strcmp('all',pinClass) || strcmp(pinClass,possibles{i,1}) %pmm finds this faster
                    %if ismember(pinClass,{'all',possibles{i,1}}) %edf worries this is slow
                    done=true;
                    pins=possibles{i,2}; %edf worries this is slow
                    if ~isempty(pins)
                        thisState=state(ones(1,length(pins.pinNums)));
                        thisState(pins.invs)=~thisState(pins.invs);
                        lptWriteBits(pins.decAddr,pins.bitLocs,thisState);
                    else
                        warning('standardStation:setStatePins:unavailableStatePins','station asked to set optional state pins it doesn''t have')
                    end
                end
            end
            if ~done
                error('standardStation:setStatePins:unrecognized pinClass','')
            end
        end
        
        function setValves(s, valves)
            if length(valves)==s.numPorts
                valves=logical(valves);
                valves(s.valvePins.invs)=~valves(s.valvePins.invs);
                lptWriteBits(s.valvePins.decAddr,s.valvePins.bitLocs,valves);
            else
                error('valves must be a vector of length numValves')
            end
            
        end
        
        function currentValveStates=verifyValvesClosed(station)
            currentValveStates=getValves(station);
            if any(currentValveStates)
                
                currentValveStates =...
                    setAndCheckValves(station,0*currentValveStates,0*currentValveStates,[],GetSecs,'verify valves closed found open valves');
                warning('verify valves closed found open valves')
            end
        end
    end
end
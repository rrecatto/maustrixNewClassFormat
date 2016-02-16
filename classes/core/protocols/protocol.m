classdef protocol
    
    properties
        id='';    %BAD BUG!!  WOW.  I HAD THESE DEFINED IN THE OPPOSITE ORDER BY CHANCE, AND THE LOAD COMMAND COULDN'T HANDLE IT == TURNED IT TO A STRUCT THAT THEN WOULDN"T DO PROTOCOL THINGS
        trainingSteps={};
        loopedTS = false;
    end
    
    methods
        function p=protocol(varargin)
            % PROTOCOL  class constructor. 
            % p = protocol(name,{trainingStep array}) 

            switch nargin
                case 0
                    % if no input arguments, create a default object

                    p = class(p,'protocol');
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'protocol'))
                        p = varargin{1};
                    else
                        error('Input argument is not a protocol object')
                    end
                case 2
                    p.id=varargin{1};
                    %     keyboard
                    if isVectorOfType(varargin{2},'trainingStep')
                        p.trainingSteps=varargin{2};

                    else
                        error('need array of trainingSteps')
                    end
                    p.loopedTS = false;
                    p = class(p,'protocol');
                case 3
                    p.id=varargin{1};
                    %     keyboard
                    if isVectorOfType(varargin{2},'trainingStep')
                        p.trainingSteps=varargin{2};

                    else
                        error('need array of trainingSteps')
                    end
                    p.loopedTS = varargin{3};
                    p = class(p,'protocol');
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function ok=boxOKForProtocol(p,b,r)
            if isa(b,'box') && isa(r,'ratrix')
                ok=1;
                for i=1:length(p.trainingSteps)
                    ok=ok && boxOKForTrainingStep(p.trainingSteps{i},b,r);

                end
            else
                error('need a box and a ratrix')
            end
        end


        function p=calibrateEyeTracker(p,step)
            p.trainingSteps{step}=calibrateEyeTracker(p.trainingSteps{step});

            %if multistep, change all eyeTrackers on subsequent steps of the same type
            %here in protocols eyetracker
        end
        
        function protocol = changeStep(protocol, ts, stepNumToChange)

            if isscalar(stepNumToChange) && isinteger(stepNumToChange) && stepNumToChange>0 && stepNumToChange<=length(protocol.trainingSteps) && isa(ts,'trainingStep')
                protocol.trainingSteps{stepNumToChange} = ts;
            else
                error('stepNumToChange must be scalar integer >0 and <= number of defined trainingSteps, or ts is not a valid trainingStep');
            end

        end % end function

        function p=decache(p)
            for i=1:length(p.trainingSteps)
                p.trainingSteps{i}=decache(p.trainingSteps{i});
            end
        end
        
        function d=display(p)
            d=['protocol ' p.id ': ' num2str(length(p.trainingSteps)) ' steps'];
            for i=1:length(p.trainingSteps)
                d=[d '\n\ttraining step ' num2str(i) ':\n' display(p.trainingSteps{i})];
            end
            d=sprintf(d);
        end
        
        function out=getName(p)
            out=p.id;
        end
        
        function out=getNumTrainingSteps(p)
            out=length(p.trainingSteps);
        end
        
        function out=getTrainingStep(p,i)
            if i<=length(p.trainingSteps)
                out=p.trainingSteps{i};
            else
                error('request for training step with larger index than total number');
            end

        end
            
        function out=getTrainingStepNames(p)
            out = {};
            for i = 1:length(p.trainingSteps)
                out{i} = getStepName(p.trainingSteps{i});
            end
        end
        
        function out=isLooped(p)
            out=p.loopedTS;
        end
        
        function  out = sampleStimFrame(p,stepNum)
            %returns a single image from calc stim movie

            out=sampleStimFrame(p.trainingSteps{stepNum});
        end
        
        function p=stopEyeTracking(p,step)
            p.trainingSteps{step}=stopEyeTracking(p.trainingSteps{step});
        end
        
    end
end


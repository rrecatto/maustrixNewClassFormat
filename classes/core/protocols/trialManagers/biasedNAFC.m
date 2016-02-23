classdef biasedNAFC<trialManager
    
    properties
        bias = 0;
    end
    
    methods
        function t=biasedNAFC(varargin)
            % BIASEDNAFC  class constructor.
            % t=biasedNAFC(soundManager,percentCorrectionTrials,rewardManager,
            %         [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %		  [delayManager],[responseWindowMs],[showText])

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    a=nAFC();
                    

                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'biasedNAFC'))
                        t = varargin{1};
                    else
                        error('Input argument is not a biasedNAFC object')
                    end
                case {4 5 6 7 8 9 10 11 12 13}

                    % percentCorrectionTrials
                    if varargin{1}>=0 && varargin{1}<=1
                        t.bias=varargin{1};
                    else
                        error('1 >= bias >= 0')
                    end

                    a=nAFC(varargin{2:end});

                    

                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
        end
        
        function out = getRequestBias(tM)
            out = tM.bias;
        end
        
    end
    
end


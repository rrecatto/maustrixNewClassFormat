classdef randomBursts<scheduler
    %UNTITLED25 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        minsPerBurst=0;
        burstsPerDay=0;
    end
    
    methods
        function s=randomBursts(varargin)
            % RANDOMBURSTS  class constructor.  
            % s=randomBursts(minsPerBurst,burstsPerDay)

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'randomBursts'))
                        s = varargin{1};
                    else
                        error('Input argument is not a randomBursts object')
                    end
                case 2
                    if varargin{1}>=0 && varargin{2}>=0
                        s.minsPerBurst=varargin{1};
                        s.burstsPerDay=varargin{2};
                    else
                        error('minsPerBurst and burstsPerDay must be >= 0')
                    end
                    
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function d=display(s)
            d=['random bursts (minsPerBurst: ' num2str(s.minsPerBurst) ' burstsPerDay: ' num2str(s.burstsPerDay) ')'];
        end
        
    end
    
end


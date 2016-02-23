classdef delayManager
    %UNTITLED12 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        label=[];
    end
    
    methods
        function f=delayManager(varargin)
            % the base delayManager class
            % OBJ=delayManager(label)
            % currently, i cant think of any fields that this base class needs to have
            % we only use this so that every method can inherit the abstract getDelayAndTimeout function

            switch nargin
                case 0
                    % if no input arguments, create a default object

                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'delayManager'))
                        f = varargin{1};
                    elseif ischar(varargin{1})
                        f.label=varargin{1};
                        
                    else
                        error('Input argument is not a delayManager object')
                    end
                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
        end % end function
    
    
    end
    
end


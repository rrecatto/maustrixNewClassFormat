classdef numDaysCriterion<criterion
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function s=numDaysCriterion(varargin)
            % NUMDAYSCRITERION  class constructor.  
            % s=numDaysCriterion(numDays)

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s.numDays=0;
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'numDaysCriterion'))
                        s = varargin{1};
                    elseif varargin{1}>=0
                        s.numDays = varargin{1};
                        
                    else
                        error('Input argument is not a numDays object or a numeric data type')
                    end
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [graduate, details] = checkCriterion(c,subject,trainingStep,trialRecords, compiledRecords)

            %determine what type trialRecord are
            recordType='compiledData'; %circularBuffer

            thisStep=[trialRecords.trainingStepNum]==trialRecords(end).trainingStepNum;
            trialsUsed=trialRecords(thisStep);

            graduate=true;
            if ~isempty(trialRecords)
                %get the correct vector
                switch recordType
                    case 'largeData'
                        dates = floor(datenum(cell2mat({trialsUsed.date}'))); % the actual dates of each trials

                        graduate = graduate && length(unique(dates))>c.numDays;

                    case 'compiledData'
                        dates = unique(floor(datenum(cell2mat({trialsUsed.date}')))); % the actual dates of each trials
                        if ~isempty(compiledRecords)
                            whichCompiled = compiledRecords.compiledTrialRecords.step == trialRecords(end).trainingStepNum;
                            datesCompiled = unique(floor(compiledRecords.compiledTrialRecords.date(whichCompiled)));
                        else
                            datesCompiled = [];
                        end
                        graduate = graduate && (length(union(dates,datesCompiled))>c.numDays);
                    otherwise
                        error('unknown trialRecords type')
                end

            end


            %play graduation tone

            if graduate
                beep;
                pause(.2);
                beep;
                pause(.2);
                beep;
                pause(1);
                [junk stepNum]=getProtocolAndStep(subject);
                for i=1:stepNum+1
                    beep;
                    pause(.4);
                end
                if (nargout > 1)
                    details.date = now;
                    details.criteria = c;
                    details.graduatedFrom = stepNum;
                    details.allowedGraduationTo = stepNum + 1;
                    details.numDays = c.numDays;
                end
            end
        end % end function
        
        
        function d=display(s)
            d=['num days criterion (numDays: ' num2str(s.numDays) ')'];
        end
        
    end
    
end


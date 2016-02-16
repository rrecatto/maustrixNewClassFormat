classdef numTrialsDoneCriterion

    properties
    end
    
    methods
        function s=numTrialsDoneCriterion(varargin)
            % NUMTRIALSDONECRITERION  class constructor.  
            % s=numTrialsDoneCriterion([numTrialsNeeded])

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    s.numTrialsNeeded = 1;
                    s = class(s,'numTrialsDoneCriterion',criterion());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'numTrialsDoneCriterion'))
                        s = varargin{1};
                    elseif isscalar(varargin{1})
                        s.numTrialsNeeded = varargin{1};
                        s = class(s,'numTrialsDoneCriterion',criterion());
                    else
                        error('Input argument is not a numTrialsDoneCriterion object')
                    end
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [graduate details] = checkCriterion(c,subject,trainingStep,trialRecords, compiledRecords)
            % this criterion will graduate if we have done a certain number of trials in this trainingStep


            thisStep=[trialRecords.trainingStepNum]==trialRecords(end).trainingStepNum;
            trialsUsed=trialRecords(thisStep);
            if ~isempty(compiledRecords)
                whichCompiledTrials = compiledRecords.compiledTrialRecords.step == trialRecords(end).trainingStepNum;
                compiledTrialNums = compiledRecords.compiledTrialRecords.trialNumber(whichCompiledTrials);
            else
                compiledTrialNums = [];
            end
            trialsUsedTrialNums = [trialsUsed.trialNumber];
            details=[];
            graduate=0;

            if length(union(trialsUsedTrialNums,compiledTrialNums)) >= c.numTrialsNeeded
                graduate = 1;
            end

            %play graduation tone
            if graduate
                beep;
                pause(.2);
                beep;
                pause(.2);
                beep;
            end
        end
        
    end
    
end


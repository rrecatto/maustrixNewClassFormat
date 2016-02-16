classdef rewardNcorrectInARow
    
    properties
    end
    
    methods
        function r=rewardNcorrectInARow(varargin)
            % ||rewardNcorrectInARow||  class constructor.
            % r=rewardNcorrectInARow(rewardNthCorrect,requestRewardSizeULorMS,requestMode,msPenalty,...
            %   fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff)

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    r.rewardNthCorrect=[0]; %this is a vector of the rewardSizeULorMSs for the Nth trial correct in a row

                    r = class(r,'rewardNcorrectInARow',reinforcementManager());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'rewardNcorrectInARow'))
                        r = varargin{1};
                    else
                        error('Input argument is not a rewardNcorrectInARow object')
                    end

                case 8

                    if all(varargin{1})>=0
                        r.rewardNthCorrect=varargin{1};
                    else
                        error('all the rewardSizeULorMSs must be >=0')
                    end

                    r = class(r,'rewardNcorrectInARow',...
                        reinforcementManager(varargin{4},varargin{8},varargin{7},varargin{5}, varargin{6}, varargin{2}, varargin{3}));

                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
        end
        
        function [r, rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM] = ...
    calcReinforcement(r,trialRecords,compiledRecord, subject)
            verbose=0;

            correct=0;
            if ~isempty(trialRecords)
                if isfield(trialRecords,'trialDetails') && isfield([trialRecords.trialDetails],'correct')
                    td=[trialRecords.trialDetails];
                    if ~isempty([td.correct])
                        correct=[td.correct];
                    else
                        warning('**trialRecord.trialDetails has an empty ''correct'' field');
                    end
                elseif any(strcmp(fields(trialRecords),'correct')) && ~isempty([trialRecords.correct])
                    correct=[trialRecords.correct];
                else
                    warning('**trialRecords does not have the ''correct'' field yet or is empty')
                end
            else
                warning('**trialRecords has size too small')
            end

            %determine how many were correct in row before this
            if correct(end)==0
                n=1;
            elseif correct(end)==1
                sameInRow=diff([1 find(diff(correct)) length(correct)]);
                n=sameInRow(end)+1;
            else
                warning('unknown correct val, setting to reward state 1,')
                n=1;
            end

            %if many correct in a row, use last entry in rewardNthCorrect
            if n> size(r.rewardNthCorrect,2)
                n=size(r.rewardNthCorrect,2);
            end

            updateTM=0;

            [rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound] = calcCommonValues(r,r.rewardNthCorrect(n),getRequestRewardSizeULorMS(r));

            if verbose
                disp(sprintf('if next trial is correct will reward %d ms, reward level %d',rewardSizeULorMS,n))
            end

        end
        
        function d=display(r)
            d=[sprintf('\n\t\t\trewardNthCorrect:\t\t\t%s',num2str(r.rewardNthCorrect)) ...
               ];

           %add on the superclass 
            d=[d sprintf('\n\t\treinforcementManager:\t') display(r.reinforcementManager)];
        end
        
    end
    
end


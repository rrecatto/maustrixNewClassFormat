classdef asymetricReinforcement<reinforcementManager

    properties
        hitRewardSizeULorMS=0;
        correctRejectRewardSizeULorMS=0;
        missMsPenalty=0;
        falseAlarmMsPenalty=0;
    end
    
    methods
        function r=asymetricReinforcement(varargin)
            % ||asymetricReinforcement||  class constructor.
            % r=asymetricReinforcement(hitRewardSizeULorMS,correctRejectRewardSizeULorMS,missMsPenalty,falseAlarmMsPenalty,requestRewardSizeULorMS,requestMode,msPenalty,...
            %   fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff)

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'asymetricReinforcement'))
                        r = varargin{1};
                    else
                        error('Input argument is not a asymetricReinforcement object')
                    end

                case 11

                    if varargin{1}>=0 && isreal(varargin{1}) && isscalar(varargin{1})
                        r.hitRewardSizeULorMS=varargin{1};
                    else
                        error('the hitRewardSizeULorMS must a single scalar be >=0')
                    end

                    if varargin{2}>=0 && isreal(varargin{2}) && isscalar(varargin{2})
                        r.correctRejectRewardSizeULorMS=varargin{2};
                    else
                        error('the correctRejectRewardSizeULorMS must a single scalar be >=0')
                    end


                    if varargin{3}>=0 && isreal(varargin{3}) && isscalar(varargin{3})
                        r.missMsPenalty=varargin{3};
                    else
                        error('the missMsPenalty must a single scalar be >=0')
                    end

                    if varargin{4}>=0 && isreal(varargin{4}) && isscalar(varargin{4})
                        r.falseAlarmMsPenalty=varargin{4};
                    else
                        error('the falseAlarmMsPenalty must a single scalar be >=0')
                    end


                    msPenalty=max([r.missMsPenalty r.falseAlarmMsPenalty]);  % these unfortunately are also set in the super class, because they will vary in this sub-class
                    %the super class stores the larger which is what setReinforcementParam will change... typically the only non-zero value. 
                    %msPuff=NaN; % should add asymetric puffs  (to support air in face on fa, not on miss), in which case pass in NAN to super class
                    msPuff=varargin{11};
                       %(msPenalty, msPuff, scalar, fractionOpenTimeSoundIsOn, fractionPenaltySoundIsOn, requestRewardSizeULorMS, requestMode)
                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
        end
        
        function [r rewardSizeULorMS requestRewardSizeULorMS msPenalty msPuff msRewardSound msPenaltySound updateRM] = ...
                        calcReinforcement(r,trialRecords,compiledRecord, subject)


                        %confirm trial redords contains THIS trial (not merely the trials before this trial)

                        evalStr = sprintf('sm = %s();',trialRecords(end).stimManagerClass);
                        eval(evalStr);
                        details=trialRecords(end).stimDetails;
                        targetIsPresent=checkTargetIsPresent(sm,details);

                        if targetIsPresent==1
                            rewardSizeULorMS=getScalar(r) * r.hitRewardSizeULorMS;
                            msPenalty=0; %r.missMsPenalty; %set when we want to punish falsemisses, but we don't (so set to 0)
                        elseif targetIsPresent==0;
                            rewardSizeULorMS=getScalar(r) * r.correctRejectRewardSizeULorMS;
                            msPenalty=r.falseAlarmMsPenalty;
                        else  %(ie. any negative value)
                            class(sm)
                            targetIsPresent
                            error('this reinforcement manager requires the stim manager to report that the target is present or absent')
                        end

                        rewardSizeULorMS= getScalar(r) * rewardSizeULorMS;

                        requestRewardSizeULorMS = getScalar(r) * getRequestRewardSizeULorMS(r);
                        msPuff=getMsPuff(r);
                        msRewardSound=rewardSizeULorMS*getFractionOpenTimeSoundIsOn(r);
                        msPenaltySound=msPenalty*getFractionPenaltySoundIsOn(r);

                        updateRM=0;
                    end

                    function rm=setReinforcementParam(rm,param,val)



            try
                verySmall=0; % msec... this enables the possibility of very small rewards or penalties... used for debugging... had not effect if set to zero.
                switch param
                    case {'penaltyMS','msPenalty'}
                        %if they are equal we change both of them. if one is 0 we
                        %change the other one. if they are both nonzero but not equal
                        %error.
                        rm=setMsPenalty(rm,val);
                        if rm.missMsPenalty==rm.falseAlarmMsPenalty
                            rm.falseAlarmMsPenalty=val;
                            rm.missMsPenalty=val;
                        elseif (rm.missMsPenalty==0 || rm.missMsPenalty==verySmall)&& rm.falseAlarmMsPenalty>0
                            rm.falseAlarmMsPenalty=val;
                        elseif rm.missMsPenalty>0 && (rm.falseAlarmMsPenalty==0 || rm.falseAlarmMsPenalty==verySmall)
                            rm.missMsPenalty=val;
                        else
                            val
                            x=struct(rm)


                            error('dont know how to handle this case');
                        end    
                    case {'scalar', 'requestRewardSizeULorMS'}
                        rm.reinforcementManager=setReinforcementParam(rm.reinforcementManager,param,val);
                    case 'rewardULorMS'

                        if rm.hitRewardSizeULorMS==rm.correctRejectRewardSizeULorMS
                            rm.correctRejectRewardSizeULorMS=val;
                            rm.hitRewardSizeULorMS=val;
                        elseif (rm.hitRewardSizeULorMS==0 || rm.hitRewardSizeULorMS==verySmall) && rm.correctRejectRewardSizeULorMS>0
                            rm.correctRejectRewardSizeULorMS=val;
                        elseif rm.hitRewardSizeULorMS>0 && (rm.correctRejectRewardSizeULorMS==0 || rm.correctRejectRewardSizeULorMS==verySmall)
                            rm.hitRewardSizeULorMS=val;
                        else
                            error('dont know how to handle this case');
                        end

                    otherwise
                        param
                        error('unrecognized param')
                end
            catch ex
                if strcmp(ex.identifier,'MATLAB:UndefinedFunction')
                    class(rm)    
                    warning(sprintf('can''t set %s for reinforcementManager of this class',param))
                    keyboard
                else
                    param=param
                    value=val
                    rethrow(ex)
                end
            end
        end
        
        
    end
    
end


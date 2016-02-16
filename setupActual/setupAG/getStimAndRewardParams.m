function out = getStimAndRewardParams(out,subID)

switch lower(subID)
    case '218'
        out.rewardScalar = 0.1;
        % reduced reward to 0.25 8/3
        % reduced reward to 0.1 8/10
    case '227'
        out.rewardScalar = 0.5;
        out.msPenalty = 15000;
        % reduced reward to 0.25 8/3
        % reward reduced to 0.1 8/10
        % increased pealty to 15000 on 9/13
        % reduced penalty to 5000 4/16
    case '228'
        out.rewardScalar = 0.25;
        % reduced reward to 0.25 8/3
    case '232'
        out.rewardScalar = 0.1;
        % reduced reward to 0.25 8/3
        % reduced reward to 0.1 on 8/10
    case '237'
        out.rewardScalar = 0.1;
        % reduced reward to 0.25 8/3
        % reduced reward to 0.1 9/13
    case '238'
        out.rewardScalar = 0.1;
        % reduced reward to 0.25 8/3
        % reduced reward to 0.1 8/10
    case '239'
        out.rewardScalar = 0.05;
        % reduced reward to 0.25 8/3
        % reduced reward to 0.1 8/10
        % reduced reward to 0.05 8/20
    case '240'
        out.rewardScalar = 0.05;
        % reduced reward to 0.25 8/3
        % reduced reward to 0.1 8/10
        % reduced reward to 0.05 8/20
    case '241'
        out.rewardScalar = 0.25;
        out.msPenalty = 15000;
        % reduced reward to 0.5 8/3
        % increased penalty to 15000 on 8/10
        % reduced reward to 0.25 9/13
    case '242'
        out.rewardScalar = 0.15;
        out.msPenalty = 15000;
        % reduced reward to 0.25 8/3
        % reduced reward to 0.1 9/13
    case '243'
        out.rewardScalar = 0.1;
        out.msPenalty = 15000;
        % reduced reward to 0.25 8/3
        % increased penalty to 15000 9/6
        % reduced reward to 0.1 9/13
    case '244'
        out.rewardScalar = 0.1;
        out.msPenalty = 15000;
        % reduced reward to 0.25 8/3
        % increased penalty to 15000 9/6
        % reduced reward to 0.1 9/13
    case '245'
        out.rewardScalar = 0.05;
        % reduced reward to 0.25 8/3
        % reduced reward to 0.1 8/10
        % reduced reward scalar to 0.02 9/6
    case '246'
        out.rewardScalar = 0.2;
        out.msPenalty = 5000;
        % reduced reward to 0.2 4/16
        % decreased timeout to 5 s 4/16
    case '247'
        out.rewardScalar = 0.25;
        out.msPenalty = 5000;
        % increased pealty to 15000 on 8/10
        % reduced reward to 0.25 9/13
        % reduced penalty to 5 s 4/16
    case '248'
        out.rewardScalar = 0.25;
        out.msPenalty = 15000;
        % reduced reward to 0.25 9/13
        % increased pealty to 15000 on 9/13
    case '249'
        out.rewardScalar = 0.25;
        out.msPenalty = 5000;
        % reduced reward to 0.25 8/10
        % reduced penalty to 5 s 4/16
    case '250'
        out.rewardScalar = 0.1;
        % reduced reward to 0.25 8/10
        % reduced reward to 0.1 9/13
    case '251'
        out.rewardScalar = 0.25;
        % reduced reward to 0.25 9/13
    case '252'
        out.rewardScalar = 0.25;
        out.msPenalty = 5000;
    case '253'
        out.rewardScalar = 0.3;
        out.msPenalty = 12500;
    case '254'
        out.msPenalty = 15000;
    case '255'
        out.rewardScalar = 0.2;
        out.msPenalty = 7500;
    case '256'
        out.rewardScalar = 0.1;
        out.msPenalty = 7500;
    case '257'
        out.rewardScalar = 0.25;
        % reduced reward to 0.25 9/13
    case '258'
        out.rewardScalar = 0.25;
        % reduced reward to 0.25 9/13    
    case '259'
        out.rewardScalar = 0.1;
        out.msPenalty = 5000;
    case '262'
        out.rewardScalar = 0.1;
        out.mePenalty = 15000;
        % reduced reward to 0.1 11/16
        % increased penalty to 15 s 11/16
    case '264'
        out.rewardScalar = 0.1;
        out.msPenalty = 5000;
    case '265'
        out.rewardScalar = 0.4;
        out.msPenalty = 20000;
    case '266'
        out.rewardScalar = 0.3;
        out.msPenalty = 15000;
    case '267'
        out.rewardScalar = 0.3;
        out.msPenalty = 10000;
    case '268'
        out.rewardScalar = 0.2;
        out.msPenalty = 15000;
    case '269'
        out.rewardScalar = 0.3;
        out.msPenalty = 20000;
    case '270'
        out.rewardScalar = 0.1;
        out.msPenalty = 5000;
    case '271'
        out.rewardScalar = 0.2; 
        out.msPenalty = 10000;
    case '272'
        out.rewardScalar = 0.1;
        out.msPenalty = 5000;
    case '273'
        out.rewardScalar = 0.1;
        out.msPenalty = 5000;
    case '274'
        out.rewardScalar = 1;
        out.msPenalty= 5000;
    case '275'
        out.rewardScalar = 0.2;
        out.msPenalty = 5000;
    case '276'
        out.rewardScalar = 0.5;
        out.msPenalty = 25000;
    case '277'
        out.rewardScalar = 0.25;
        out.msPenalty = 10000;
    case '278'
        out.rewardScalar = 1;
        out.msPenalty = 15000;
    case '279'
        out.rewardScalar = 0.25;
        out.msPenalty = 15000;
    case '280'
        out.rewardScalar = 0.2;
    case '281'
        out.rewardScalar = 0.2;
    case '282'
        out.rewardScalar = 0.2;
    case '283'
        out.rewardScalar = 0.2;
    case '284'
        out.rewardScalar = 0.2;
        
    case 'l001'
        out.rewardScalar = 0.25;
        % reduced reward 9/4;
    case 'l002'
        out.rewardScalar = 0.25;
        % reduced reward 9/4
    otherwise
        % use the default setup
end

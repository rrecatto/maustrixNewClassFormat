classdef soundManager

    properties
        clips={};   
        player=[];
        boundaries=[];
    end
    
    methods
        function t=soundManager(varargin)
            % SOUNDMANAGER  class constructor.
            % t = soundManager({soundClips})
            % typical soundClips: {correctSound,keepGoingSound,trySomethingElseSound,wrongSound}
            switch nargin
                case 0
                    % if no input arguments, create a default object
                case 1
                    if (isa(varargin{1},'soundManager')) % if single argument of this class type, return it
                        t = varargin{1};
                        return
                    elseif isVectorOfType(varargin{1},'soundClip') % create object using specified values
                        t.clips=varargin{1};
                    else
                        error('must pass in a vector of soundClips')
                    end
                otherwise
                    error('Wrong number of input arguments')
            end
            t.playing=[];
            t.looping=false;
            t.clipDurs=zeros(1,length(t.clips));
            t = class(t,'soundManager');
        end
        
        function sm=addSound(sm,clip,station)
            if isa(station,'station')
                if getSoundOn(station)
                    if isa(clip,'soundClip')
                        soundName = getName(clip);
                        done = 0;
                        for i=1:length(sm.clips)
                            if strcmp(getName(sm.clips{i}),soundName)
                                if done
                                    error('found that name twice')
                                else
                                    % Found the same name, update it
                                    done = 1;
                                    sm.clips{i}=clip;
                                end
                            end
                        end
                        if ~done
                            % Name not found, add it to the end
                            sm.clips = [sm.clips {clip}];
                        end
                        sm=uninit(sm,station); %this is inefficient -- forces recomputing of all clips, could be more surgical...
                    else
                        error('need a soundClip')
                    end
                end
            else
                error('need a station')
            end
        end

        function [sm updateCache]=cacheSounds(sm,station)
            if isa(station,'station')

                updateCache=false;

                if getSoundOn(station) && length(sm.boundaries)~=length(sm.clips)+1
                    warning('recaching sounds, this is expensive')

                    updateCache=true;

                    soundNames = getSoundNames(sm);

                    sm=uninit(sm,station); %need to clean up any existing buffers

                    dllPath=fullfile(PsychtoolboxRoot, 'portaudio_x86.dll');
                    if IsWin && exist(dllPath,'file') && length(soundNames)>1
                        warning('found enhanced asio driver -- disabling because this only allows us to make one buffer')
                        %note that we could instead just select a non-asio device (i
                        %think MME is next most preferred)
                        [status,message,messageid]=movefile(dllPath,fullfile(PsychtoolboxRoot, 'disabled.portaudio_x86.dll'));
                        if ~status || exist(dllPath,'file')
                            message
                            messageid
                            error('couldn''t disable enhanced psychportaudio dll')
                        end
                    end

                    InitializePsychSound(1);

                    %tested systems:
                    % 1) erik's osx macbook pro
                    % 2) gigabyte mobo w/integrated realtek audio, xp sp3, 2GB, core 2 duo 6850 3GHz/2GHz, 8600 GTS (balaji's machine)
                    % 3) rig dell w/ati card
                    % 4) rig dell w/nvidia + audigy cards, settings below don't work as well, consider moving to asio (need to use new playlist functionality in psychportaudio for this)
                    latclass=1; %4 is max, higher means less latency + stricter checks.  lowering may reduce system load if having frame drops.  1 seems ok on systems 1-3.
                    if IsWin
                        buffsize=1250; %max is 4096 i think.  the larger this is, the larger the audio latency, but if too small, sound is distorted, and system load increases (could cause frame drops).  1250 is good on systems 1-3.
                    else
                        buffsize=[];
                    end

                    sampleRate=44100;
                    sm.player= PsychPortAudio('Open',[],[],latclass,sampleRate,2,buffsize);

                    s=PsychPortAudio('GetStatus',sm.player);
                    s=s.SampleRate;

                    if s~=sampleRate
                        sampleRate
                        s
                        error('didn''t get requested sample rate')
                    end

                    buff=[];

                    for i=1:length(soundNames)
                        [clip clipSampleRate sm updateSMCache] = getSound(sm,soundNames{i});

                        if clipSampleRate~=sampleRate
                            clipSampleRate
                            error('soundManager only works for clips with sampleRate %d',sampleRate)
                        end

                        if size(clip,1)>2
                            clip=clip'; %psychportaudio requires channels to be rows
                        end
                        switch size(clip,1)
                            case 1
                                clip(2,:) = clip(1,:);
                            case 2
                                %pass
                            otherwise
                                error('max 2 channels')
                        end

                        sm.boundaries(i)=size(buff,2); %these are zero based indices cuz ppa('setloop') wants them that way

                        buff=[buff clip];

                        sm.clipDurs(i)=size(clip,2)/sampleRate;
                    end
                    sm.boundaries(end+1)=size(buff,2);

                    PsychPortAudio('FillBuffer', sm.player, buff);

                    PsychPortAudio('RunMode', sm.player, 1);
                    PsychPortAudio('Verbosity' ,1); %otherwise it types crap out when we try to start, must think it's still running even after .Active is false, try to reproduce!

                    for i=1:length(sm.clips)
                        sm.clips{i}=decache(sm.clips{i});
                    end
                end
            else
                error('need a station')
            end
        end
        
        function sm=close(sm)
            error('does anyone call this?')
            PsychPortAudio('Close');
        end
        
        function s=decache(s)

            for i=1:length(s.clips)
                s.clips{i}=decache(s.clips{i});
            end
            s.player=[];
            s.playing=[];
            s.looping=false;
            s.boundaries=[];
            s.clipDurs=zeros(1,length(s.clips));
        end
        
        function d=display(s)
            d=[];
            for i=1:length(s.clips)
                d=[d '\n\t\t\t\t' display(s.clips{i})];

            end
            d=sprintf(d);
        end
        
        function [clip sampleRate sm updateSMCache] = getSound(sm,soundName)
            done=0;
            updateSMCache=0;
            for i=1:length(sm.clips)
                if strcmp(getName(sm.clips{i}),soundName)
                    if done
                        error('found that name twice')
                    else
                        done=1;
                        [clip sampleRate newSC updateSC]=getClip(sm.clips{i});
                        if updateSC
                            updateSMCache=1;
                            sm.clips{i}=newSC;
                        end
                    end
                end
            end
            if ~done
                error('no sound by that name')
            end
        end
        
        function s=getSoundNames(sm)
            s={};
            for i=1:length(sm.clips)
                s{i}=getName(sm.clips{i});
            end
        end
        
        function sm=initializeSound(sm)
            error('deprecated')
        end
        
        %by design: you can only have one sound playing at a time
        %this call will override a previously running call to playSound.
        function sm=playLoop(sm,newSound,station,keepPlaying)
            sm=doSound(sm,newSound,station,keepPlaying,true);
        end
        
        %by design: you can only have one sound playing at a time
        %this call will override a previously running call to playSound or playLoop.
        %negative durations mean play the native clip length
        function sm=playSound(sm,soundName,duration,station)
            sm=doSound(sm,soundName,station,duration,false);
        end
        
        function sm=uninit(sm,station)
            if isa(station,'station')
                sm=decache(sm);

                if getSoundOn(station)
                    %can't put in soundManager.decache() directly, because need to be able to call decache without closing psychportaudio + losing buffers
                    initPPA;
                    PsychPortAudio('Close'); %does this work OK if sounds currently playing?  yes on osx...
                    clear PsychPortAudio;
                end
            else
                error('need a station')
            end
            end

            function initPPA
            if ismac
                fn='libportaudio.0.0.19.dylib'; % old form erik's time
            %     fn='libportaudio.2.0.0.dylib'; % in balaji's macbook air
            %     keyboard
                paths={'/usr/local/lib','/usr/lib','~/lib'};
                src=fullfile(PsychtoolboxRoot,'PsychSound',fn);

                if ~any(cellfun(@(x) exist(fullfile(x,fn),'file'),paths))
                    if exist(src,'file')
                        good=false;
                        for i=1:length(paths)
                            if ~exist(paths{i},'dir')
                                [a b c]=mkdir(paths{i});
                            else
                                % the dir exists and matlab should just get going...eh?
                                a = 1;b = 0;c = 0;
                            end
                            if a~=1
                                sca;
                                keyboard;
                                b
                                c
                                warning('couldn''t mkdir')
                            else
                                [a b c]=copyfile(src,fullfile(paths{i},fn)); %not fullfiling like this might be why we sometimes make files when we think we're making dirs
                                if a~=1
                                    b
                                    c
                                    warning('couldn''t copy libportaudio')
                                else
                                    good=true;
                                    break
                                end
                            end
                        end
                        if ~good
                            error('couldn''t copy libportaudio')
                        end
                    else
                        error('can''t find libportaudio, maybe need updatepsychtoolbox')
                    end
                end
            end
            InitializePsychSound(1);
          end
        
    end
    
    methods (Access = private)
    
        function sm=doSound(sm,soundName,station,duration,isLoop)
            if isa(station,'station')
                if getSoundOn(station)
                    if isempty(soundName)
                        if isLoop && duration==0
                            sm=stopPlayer(sm);
                        else
                            error('if soundName is empty, call must have been to playLoop and keepPlaying must be 0')
                        end
                    else

                        match=getClipInd(sm,soundName);
                        sm=cacheSounds(sm,station);

                        if ~isLoop
                            reps=1;

                            if duration>0
                                reps=duration/sm.clipDurs(match);
                            end

                            sm=stopPlayer(sm);
                        else
                            if duration==0 || (~isempty(sm.playing) && (sm.playing~=match || ~sm.looping))
                                sm=stopPlayer(sm);
                            end

                            if duration~=0 && ~isempty(sm.playing) && sm.playing==match && sm.looping
                                duration=0;
                            end

                            reps=0;
                        end

                        if duration~=0

                            PsychPortAudio('SetLoop',sm.player,sm.boundaries(match), sm.boundaries(match+1)-1);
                            PsychPortAudio('Start', sm.player, reps);

                            sm.playing=match;
                            sm.looping=isLoop;
                        end
                    end
                end
            else
                error('need a station')
            end
        end
        
        function match=getClipInd(sm,soundName)
            match=0;
            for i = 1:length(sm.clips)
                if strcmp(getName(sm.clips{i}),soundName)
                    if match>0
                        error('found more than 1 clip by same name')
                    end
                    match = i;
                end
            end
            if match<=0
                error('found no clip by that name')
            end
        end
        
        function sm=playSnd(sm,soundName,duration,station,isLoop)
            error('deprecated')

            if isa(station,'station')
                if getSoundOn(station)
                    if ischar(soundName)
                        if duration==-1 || duration>=0

                            if sm.playerType == sm.AUDIO_PLAYER_CACHED

                                if isLoop
                                    error('can''t call playSnd with isLoop set for AUDIO_PLAYER_CACHED type')
                                end

                                match=0;
                                for i = 1:length(sm.clips)
                                    if strcmp(getName(sm.clips{i}),soundName)
                                        if match>0
                                            error('found more than 1 clip by same name')
                                        end
                                        match = i;
                                    end
                                end
                                if match<=0
                                    error('found no clip by that name')
                                end

                                numSamps=get(sm.players{match},'TotalSamples');
                                if duration>=0
                                    sampleRate=get(sm.players{match},'SampleRate');

                                    durationSamps = max(1,ceil(sampleRate*duration)); %if don't have at least 1, audioplayer complains
                                    startStop=[1 durationSamps];
                                else
                                    startStop=[1 numSamps];
                                end

                                if isplaying(sm.players{match})
                                    error('sound was already playing')
                                end
                                while startStop(2)-startStop(1)>0
                                    thisTime=min(numSamps,startStop(2));
                                    startStop(2)=startStop(2)-thisTime;
                                    playblocking(sm.players{match}, [startStop(1) thisTime]); %note the blocking -- means it won't be simultaneous with stim
                                end

                            else



                                [clip sampleRate sm updateSMCache]=getSound(sm,soundName);
                                %size(clip)
                                if duration>=0
                                    durationSamps = max(1,ceil(sampleRate*duration)); %if don't have at least 1, audioplayer complains
                                    if durationSamps>size(clip,2)
                                        clear newClip;
                                        for i=1:size(clip,1)
                                            newClip(i,:)=repmat(clip(i,:),1,floor(durationSamps/size(clip,2))+1);
                                        end
                                    else
                                        newClip = clip;
                                    end
                                    clip=newClip(:,1:durationSamps);
                                end

                                try
                                    newRecs=struct([]);
                                    numRecs=0;
                                    %length(sm.records)
                                    % If mono sound, send same signal to both channels
                                    if(size(clip,1) == 1)
                                        clip(2,:) = clip(1,:);
                                    elseif(size(clip,1) ~= 2)
                                        error('Stereo or mono sound expected');
                                    end
                                    if sm.playerType == sm.AUDIO_PLAYER
                                        for i=1:length(sm.records)
                                            if sm.records(i).isLoop || isplaying(sm.records(i).player) %garbage collect anyone that is not a loop and not playing
                                                if numRecs==0 %lame that this has to be a special case, cuz struct([]) doesn't have matching fields
                                                    newRecs=sm.records(i);
                                                else
                                                    newRecs(numRecs+1)=sm.records(i);
                                                end
                                                numRecs=numRecs+1;
                                            end
                                        end

                                        if size(clip,1)==2
                                            clip=clip'; %on osx, audioplayer constructor requires this
                                        end
                                        newRecs(end+1).player=audioplayer(clip, sampleRate);
                                        newRecs(end).name=soundName;
                                        newRecs(end).isLoop=isLoop;

                                        sm.records=newRecs;
                                        play(sm.records(end).player); %THIS CALL IS PROBLEMATIC ON OSX

                                    elseif sm.playerType == sm.PSYCH_PORT_AUDIO
                                        PsychPortAudio('Close');
                                        newRecs(end+1).player=PsychPortAudio('Open', sm.deviceid, [], sm.reqlatencyclass, sampleRate, 2, sm.buffersize);
                                        newRecs(end).name=soundName;
                                        newRecs(end).isLoop=isLoop;
                                        sm.records=newRecs;
                                        % Fill buffer with data:
                                        PsychPortAudio('FillBuffer', sm.records(end).player, clip);
                                        % Start the sound
                                        if(isLoop)
                                            repetitions = 0; % Loop forever
                                        else
                                            repetitions = 1; % Only run once
                                        end
                                        PsychPortAudio('Start', sm.records(end).player, repetitions, 0, 0);
                                    else
                                        error('Unkown sound player type')
                                    end
                                catch ex
                                    %disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                                    rethrow(ex)
                                end
                            end
                        else
                            error('duration must be >=0')
                        end
                    else
                        error('need a sound name')
                    end
                end
            else
                error('need a station')
            end
        end
        
        function sm=stopPlayer(sm)

            try
                    PsychPortAudio('Stop', sm.player,2,0);
            catch
                % usage seems fine but maybe the problem is that sm.player does not exist?
                sm.player
            end
            sm.playing=[];
            sm.looping=false;
        end
        
    end
    
    methods (Static = true)
        function testsound
            clear mex
            clear psychportaudio

            p=MaxPriority('getsecs');
            Priority(p);
            InitializePsychSound(1);
            try
                x=PsychPortAudio('open',[],[],4,[],[],4096); %reqclass 4 doesn't work with asio4all + enhanced dll
            catch ex
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                x=PsychPortAudio('open',[],[],2,[],[],4096);
            end
            s=PsychPortAudio('getstatus',x);
            s.SampleRate
            PsychPortAudio('fillbuffer',x,rand(2,400000)-.5);
            GetSecs;

            PsychPortAudio('RunMode', x, 1);

            PsychPortAudio('start',x);
            PsychPortAudio('stop',x);

            val=true;
            for i=1:10
                val=~val;
                y=GetSecs;
                PsychPortAudio('fillbuffer',x,val*rand(2,round(2*44100*i/10))-.5);
                t=GetSecs-y;
                if val
                    fprintf('yes:')
                else
                    fprintf('no:')
                end
                fprintf('\t%g\n',t)
            end
            y=GetSecs;
            PsychPortAudio('start',x);
            PsychPortAudio('stop',x,2,0);
            t=GetSecs-y;
            fprintf('%g\n',t)
            pause
            for i=1:10
                waitForStop(x);
                y=GetSecs;
                PsychPortAudio('start',x);
                s=GetSecs-y;
                pause(.5);
                y=GetSecs;
                PsychPortAudio('stop',x,2,0);
                t=GetSecs-y;
                fprintf('%g\t%g\n',s,t)
            end

            pause
            for i=1:10
                waitForStop(x);
                y=GetSecs;
                PsychPortAudio('start',x);
                s=GetSecs-y;
                pause(.5);
                y=GetSecs;
                PsychPortAudio('stop',x,0,0);
                t=GetSecs-y;
                fprintf('%g\t%g\n',s,t)
            end

            PsychPortAudio('close')

            x=audioplayer(rand(400000,2)-.5,44100);
            play(x);
            stop(x);
            for i=1:10
                y=GetSecs;
                play(x);
                s=GetSecs-y;
                pause(.5);
                y=GetSecs;
                stop(x);
                t=GetSecs-y;
                fprintf('%g\t%g\n',s,t)
            end
            priority(0);
        end

        
    end
end


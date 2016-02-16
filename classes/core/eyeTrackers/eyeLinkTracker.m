classdef eyeLinkTracker
    
    properties
        eyeLinkDLL=which('eyeLink'); %not used, just for record keeping
        eyeUsed=[];  %this is a variable that says which eye channel EyeLink is using in software
        %it tends to be left, but is meaningless for our data;  don't want to save it b/c its confusing.

        constants=[];
    end
    
    methods
        function et=eyeLinkTracker(varargin)
            % EYETRACKER claess constructor. ABSTRACT CLASS -- DO NOT INSTANTIATE
            % et = eyeLinkTracker()

            switch nargin
                case 0
                    % if no input arguments, create a default object  
                    et = class(et,'eyeLinkTracker',eyeTracker());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'eyeLinkTracker'))
                        et = varargin{1};
                    else
                        error('Input argument is not a eyeLinkTracker object')
                    end
               case 2
                    et = class(et,'eyeLinkTracker',eyeTracker(varargin{1},varargin{2}));
                otherwise
                    error('Wrong number of input arguments')
            end

        end
        
        function isGood=checkRecording(et)

            if Eyelink('IsConnected') && 0==Eyelink('CheckRecording')
                %good
                isGood=1;
            else
                eyeERR = Eyelink('CheckRecording')
                error(sprintf('lost connection with eye tracker: %s',eyeERR))
            end

        end
    
        function done=cleanUp(et)

            try
                stop(et)
            catch
                warning('cleanup eyelink failed')
            end
        end

        function consts=getConstants(et)
            consts=et.constants;
        end

        function values=getCurrentCalibrationValues(et)
            %you will be asked to confirm all of these values before each session 

            % Calibration Values

            values.counter=3; %increase this number by 1 everytime
            values.trusted=0; %set to 1 if you trust all the calibration values, otherwise zero
        end
        
        function out=getEyeDataVarNames(t)

            out={'timeEyelink',...
                'type',...
                'flags',...
                'px',...
                'py',...
                'hx',...
                'hy',...
                'pa',...
                'gx',...
                'gy',...
                'rx',...
                'ry',...
                'status',...
                'input',...
                'buttons',...
                'htype',...
                'hdata1',...
                'hdata2',...
                'hdata3',...
                'hdata4',...
                'hdata5',...
                'hdata6',...
                'hdata7',...
                'hdata8',...
                'raw_pupil_x',...
                'raw_pupil_y',...
                'raw_cr_x',...
                'raw_cr_y',...
                'pupil_area',...
                'cr_area',...
                'pupil_dimension_x',...
                'pupil_dimension_y',...
                'cr_dimension_x',...
                'cr_dimension_y',...
                'window_position_x',...
                'window_position_y',...
                'pupil_cr_x',...
                'pupil_cr_y',...
                'cr_area2',...
                'raw_cr2_x',...
                'raw_cr2_y'...
                'timeCPU',...
                'date'};
        end
        
        function [gazes samples]=getSamples(et)
            %returning samples as a matrix requires that everything is a single
            %space could be saved by converting appropriate fields to smaller ints and giving them dedicated matrices
            %
            % int16:
            % sample.type
            % sample.htype
            % sample.hdata
            %
            % uint16:
            % sample.flags
            % sample.status
            % sample.input
            % sample.buttons
            %
            % uint32 (same size as single):
            % raw.pupil_area
            % raw.cr_area
            % raw.pupil_dimension
            % raw.cr_dimension
            % raw.window_position
            % raw.cr_area2

            el=getConstants(et);

            if ~ismember(et.eyeUsed,[el.LEFT_EYE el.RIGHT_EYE])
                et.eyeUsed
                Eyelink('EyeAvailable')
                error('bad eye')
            end

            gazes=[]; %initialize in case all samples are lost data

            justGetLatestSample=false;

            if justGetLatestSample
                newOrOld = Eyelink('NewFloatSampleAvailable');
                switch newOrOld
                    case -1
                        error('NewFloatSampleAvailable returned -1')
                    case 0
                        error('NewFloatSampleAvailable returned 0')
                    case 1
                        [sample, raw] = Eyelink('NewestFloatSampleRaw',et.eyeUsed);
                    otherwise
                        newOrOld
                        error('NewFloatSampleAvailable returned unexpected value')
                end

                gazes=getGazeEstimate(et,raw.raw_cr,raw.raw_pupil); %this can have nans in it if some of the raw values are the MISSING_DATA code

                index=et.eyeUsed+1;

                samples=[...
                    sample.time;...
                    sample.type;...
                    sample.flags;...
                    sample.px(index);...
                    sample.py(index);...
                    sample.hx(index);...
                    sample.hy(index);...
                    sample.pa(index);...
                    sample.gx(index);...
                    sample.gy(index);...
                    sample.rx;...
                    sample.ry;...
                    sample.status;...
                    sample.input;...
                    sample.buttons;...
                    sample.htype;...
                    sample.hdata(1);...
                    sample.hdata(2);...
                    sample.hdata(3);...
                    sample.hdata(4);...
                    sample.hdata(5);...
                    sample.hdata(6);...
                    sample.hdata(7);...
                    sample.hdata(8);...
                    raw.raw_pupil(1);...
                    raw.raw_pupil(2);...
                    raw.raw_cr(1);...
                    raw.raw_cr(2);...
                    raw.pupil_area;...
                    raw.cr_area;...
                    raw.pupil_dimension(1);...
                    raw.pupil_dimension(2);...
                    raw.cr_dimension(1);...
                    raw.cr_dimension(2);...
                    raw.window_position(1);...
                    raw.window_position(2);...
                    raw.pupil_cr(1);...
                    raw.pupil_cr(2);...
                    raw.cr_area2;...
                    raw.raw_cr2(1);...
                    raw.raw_cr2(2);...
                    GetSecs;...
                    now... %edf: 'now' is useless and slow -- why does pmm want it?  it is less accurate than GetSecs and takes 4x longer -- minimum 30us per call, often takes 100us and peaks at 5ms!!!
                    ]';
            else

                [samples events]=Eyelink('GetQueuedData',et.eyeUsed);
                if ~isempty(events)
                    for i=events(2,:)
                        fprintf('got event type: %s\n',geteventtype(el, i))
                    end
                end

                if ~isempty(samples)
                    losts=samples(2,:)==el.LOSTDATAEVENT;
                    numGood=sum(~losts);
                    if sum(losts)>0
                        fprintf('got %d lost data events\n',sum(losts))
                    end

                    gazes=getGazeEstimate(et,samples([34 35],~losts)',samples([32 33],~losts)'); %this can have nans in it if some of the raw values are the MISSING_DATA code

                    if numGood>0
                        switch et.eyeUsed
                            case el.LEFT_EYE
                                badsOffset=1; %remove right eye values
                            case el.RIGHT_EYE
                                badsOffset=0; %remove left eye values
                            otherwise
                                error('bad eye')
                        end
                        badFields=(4:2:16)+badsOffset;
                        goodFields=~ismember((1:size(samples,1)),badFields);

                        samples=[samples(goodFields,~losts)' GetSecs*ones(numGood,1) now*ones(numGood,1)];
                        %edf: 'now' is useless and slow -- why does pmm want it?  it is less accurate than GetSecs and takes 4x longer -- minimum 30us per call, often takes 100us and peaks at 5ms!!!
                        %pmm notes its easier to relate to trial start time
                        %edf says everything should be kept in the GetSecs scale, except the trialrecord gross time/date stamp.  if you care about accurate time since trial start, you need the trial's first GetSecs.
                    else
                        samples=[];
                    end
                end
            end
        end
        
        function et=initialize(et,eyeDataPath,window)
            % this should initialize eyelink and set the data path.  If you can't
            % initialize, check the following:

            % 1. Are you on a station that has an eyetracker on it? if not, you can't
            % run  a protocol that defines an eyetracker.  Leave that field empty in
            % the trial manager. 

            % 2. is the eye tracker turned on?  power the camera, and enter the command
            % "t" on the command line of the eyeTracker computer.  Its okay if it says
            % "offline - link closed" in the green box as long as the eyeLink software 
            % is up and running.
            %
            % 3.  maybe you have not installed  the eyeLink software
            % developers kit.  Here is how to set things up the first time:
            %
            % download and install lastest sdk from here:
            %    https://www.sr-support.com/forums/showthread.php?t=6
            %(user: eflister, password: password) %---% to sign up for your own user account at sr research takes about 24 hours
            % i installed 1.7.277 on the righthand computer in the small rig room.
            %    https://www.sr-support.com/forums/showthread.php?t=172
            % has the latest version of the installation guide.  i used 1.4.0.  it says what to do with the ip address.  section 9.1.5 says:
            % Select the Use the following IP address radio button. Enter the IP
            % address of 100.1.1.2. The last digit of the IP address can increase for other computers on the EyeLink network. Enter the subnet mask of 255.255.255.0. Leave the default gateway and other setting blank.
            % psychtoolbox comes with everything else you need.
            % fixationSoundDemo demonstrates how to collect the full raw samples.
            % loadlibrary and my eyelinkExtraData/getExtendedEyelinkData are not needed, franz's stuff does everything.  my stuff was just an alternative before we knew franz would do it for us.
            % works with 2007b at least.  but we haven't verified that franz's method
            % for extracting the extended data wasn't broken when sol added the double CR data into the records.
            % let's email sol and ask him if the stuff he and suganthan put for us in 1.5.1.104 and 1.5.1.272 all made it into the latest 1.7.277 that we download from https://www.sr-support.com/forums/showthread.php?t=6.  and also how the double CR data is supposed to be accessed.
            %
            % Here are the error codes that come back on the eyeLink status checks:
            %(from 28.3 eyelink.h File Reference in 'EyeLink Programmers Guide.pdf')
            % • #define OK_RESULT 0
            % • #define NO_REPLY 1000
            % • #define LINK_TERMINATED_RESULT -100
            % • #define ABORT_RESULT 27
            % • #define UNEXPECTED_EOL_RESULT -1
            % • #define SYNTAX_ERROR_RESULT -2
            % • #define BAD_VALUE_RESULT -3
            % • #define EXTRA_CHARACTERS_RESULT -4
            % • #define current_msec() current_time()
            % • #define LINK_INITIALIZE_FAILED -200
            % • #define CONNECT_TIMEOUT_FAILED -201
            % • #define WRONG_LINK_VERSION -202
            % • #define TRACKER_BUSY -203
            % • #define IN_DISCONNECT_MODE 16384
            % • #define IN_UNKNOWN_MODE 0
            % • #define IN_IDLE_MODE 1
            % • #define IN_SETUP_MODE 2
            % • #define IN_RECORD_MODE 4
            % • #define IN_TARGET_MODE 8
            % • #define IN_DRIFTCORR_MODE 16
            % • #define IN_IMAGE_MODE 32
            % • #define IN_USER_MENU 64
            % • #define IN_PLAYBACK_MODE 256

            if Eyelink('Initialize')==0
                %good
            else
                error('couldn''t initialize eyeLink, see "help eyeLinkTracker/Initialize"')
            end

            %%  make sure that we get gaze data from the Eyelink
                status=Eyelink('command','link_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,INPUT,HMARKER');
                if status~=0
                    error('link_sample_data error, status: ',status)
                end

                status=Eyelink('command','file_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,INPUT,HMARKER');
                if status~=0
                    error('file_sample_data error, status: ',status)
                end

            %     turned off for a test
                status=Eyelink('command','inputword_is_window = ON');
                if status~=0
                    error('inputword_is_window error, status: ',status)
                end

                et=setConstants(et);




            %% set the path for the data

            %subjectID=getID(subject);
            %b=getBoxFromID(getBoxIDForStationID(r,s.id));
            %eyeDataPath=fullfile(getBoxPathForSubjectID(b,subjectID,r),?subjectID?,'') %store by subject or by box?

            % eyeDataPath= fullfile(fileParts(fileParts(getRatrixPath)),'ratrixData','eyeData',subjectID); 
            % eyeDataPath = fullfile('\\Reinagel-lab.AD.ucsd.edu\RLAB\Rodent-Data\Fan\datanet', subjectID, 'eyeRecords'); % 10/23/08 - to be replaced by oracle lookup
            % eyeDataPath = fullfile('\\132.239.158.179','datanet_storage', subjectID, 'eyeRecords');  %should be where the neural data is, how do we get this is EyeTracker is on but datanet is not...
            [suc msg]=mkdir(eyeDataPath);
            if ~suc
                eyeDataPath
                error(sprintf('path failed for eye tracker: %s',msg))
            else
                et=setEyeDataPath(et,eyeDataPath);
            end
        end
        
        function et=setConstants(et)

            et.constants=EyelinkInitDefaults();
        end
        
        function et = setEyeUsed(et, value)
            et.eyeUsed=value;
        end
        
        function et=start(et,trialNumber)
            %starts tracking, starts recording an eyelink data file
            %trialNumber is just used to set the fileName for the dataFile
            %
            %History
            %edf 09.19.06 reinagel lab developed first code, using resources:
            %   http://psychtoolbox.org/eyelinktoolbox/EyelinkToolbox.pdf
            %   http://www.kyb.tuebingen.mpg.de/bu/people/kleinerm/ptbosx/ptbdocu-1.0.5MK4R1.html
            %    (also available in local install at Psychtoolbox\ProgrammingTips.html)
            %   Psychtoolbox\PsychHardware\EyelinkToolbox\EyelinkDemos\Short demos\EyelinkExample.m
            %   discussion thread:  http://tech.groups.yahoo.com/group/psychtoolbox/message/4993
            %   old function examples not in ratrix:  fixationSoundDemo.m, eyeTrackerExperiment.m
            %   check eyeLink website or CD for: Manuals/EyeLink API Specification.pdf

            %pmm 06.28.08 added to ratrix
            %  using the code in Pyschtoolbox... for more: "help eyelink"
            %  for hardware information http://www.eyelinkinfo.com/index.php

            if ~exist('createFile','var') || isempty(createFile)
                createFile=true;
            end

            % MAYBE ADD ON!
            %     % make sure that we get gaze data from the Eyelink
            %     status=Eyelink('command','link_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,INPUT,HMARKER');
            %     if status~=0
            %         error('link_sample_data error, status: ',status)
            %     end
            % 
            %     status=Eyelink('command','inputword_is_window = ON');
            %     if status~=0
            %         error('inputword_is_window error, status: ',status)
            %     end
            %     


            %OPEN FILE
            if createFile
                %toDo replace this to right place, passed in:
                fileName=sprintf('eyeSessionData_%d_%s.edf',trialNumber,datestr(now,30)); %can't be long!
                et=setSessionFileName(et,fileName);

                edfFileName=sprintf('lastSess.edf',trialNumber)% must be short name;
                %fileName='test.edf'
                errCode=Eyelink('OpenFile',edfFileName);
                if ~errCode==0
                    errCode=errCode
                    error('eyeLink couldn''t open file')
                end
            end

            %START
            % file_samples=
            % file_events=
            % link_samples
            % link_events
            % [startrecording_error =] Eyelink('StartRecording' [,file_samples, file_events, link_samples, link_events] )
            startrecording_error = Eyelink('StartRecording');
            if startrecording_error~=0
                startrecording_error=startrecording_error
                error(sprintf('problem starting eyelink recording: %s',startrecording_error))
            end

            % mark zero-plot time in data file
            status=Eyelink('message','SYNCTIME');
            if status~=0
                error('message error, status: ',status)
            end

            %% figure out which eye channel the software is using
            %this used to be in initilize.m but failed with -1 because...we have to
            %start recording before we can call this function 

                et.eyeUsed = Eyelink('EyeAvailable'); % get eye that's tracked

                if isempty(et.eyeUsed)
                    error('gotta have an eye')
                end

                el=getConstants(et);
                if ~ismember(et.eyeUsed,[el.LEFT_EYE el.RIGHT_EYE])
                    error(sprintf('must be left or right, which is 0 or 1: but rather was found to be %d',et.eyeUsed))
                end
                %tracker will always indicate left eye in software, but we always use
                %one camera pointed to the right eye (b/c we record from the left LGN)
                %-pmm 080628
            %     switch eye_used
            %         case el.BINOCULAR
            %             disp('tracker indicates binocular, we''ll use right')
            %             eye_used = el.RIGHT_EYE
            %         case el.LEFT_EYE
            %             disp('tracker indicates left eye')
            %         case el.RIGHT_EYE
            %             disp('tracker indicates right eye')
            %         case -1
            %             error('eyeavailable returned -1')
            %         otherwise
            %             error('uninterpretable result from eyeavailable: ',eye_used)
            %     end

            % record a few samples before we actually start displaying
            %WaitSecs(0.1);  %removed -- why bother waiting?

            et=setIsTracking(et,true);
        end
        
        function et=stop(et)
            %stop recording, receive .edf file from session, turn off tracker object

            Eyelink('Stoprecording')
            status = Eyelink('CloseFile');
            if ~status==0
                status=status
                error('error closing eyelink datafile')
            end

            fileName=getSessionFileName(et);
            lastFile=[];
            disp('transfering eyeLink datafile... this could take a few seconds.');

            status = Eyelink('ReceiveFile',lastFile, fullfile(getEyeDataPath(et),fileName),0);
            disp('done transfer');
            %status = Eyelink('ReceiveFile',['filename'], ['dest'], ['dest_is_path'])
            %(2.95 receive_data_file in 'EyeLink API Specification.pdf')

            % edf thinks this looks wrong -- my original code in "fixationSoundDemo.m" was:
            %    status=Eyelink('ReceiveFile',edfFile,pwd,1);
            %    if status~=0
            %        fprintf('problem: ReceiveFile status: %d\n', status);
            %    end
            %
            % the help says you need to set the third arg to nonzero, so that your path is used.
            %
            % also looks like i also assumed that status should nominally be 0, but the help says:
            % returns: file size if OK, 0 if file transfer was cancelled, negative =  error code
            %
            % so i think you should be hitting your error every time?
            %
            % btw, what does 2.95 refer to?

            % edf recommends you do the following check:
            %if 2==exist(edfFile, 'file')
            %     fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
            % else
            %     disp('unknown where data file went')
            % end

            if ~status==0
                status=status
                fileName=fileName
                destination=getEyeDataPath(et)
                error('error receicving eyelink session datafile')
            end

            Eyelink('Shutdown')

            et=setIsTracking(et, false);
            et=setEyeUsed(et, []);
            et=clearEyeDataPath(et);

        end
        
        
    end
    
end


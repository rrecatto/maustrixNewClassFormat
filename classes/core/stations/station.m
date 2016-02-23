classdef station
    
    properties
        id = '';
        path = '';
        screenNum = 0;
        soundOn = false;
        MACAddress = '';
        physicalLocation = [];
        numPorts = 0;
        rewardMethod='';
        responseMethod = 'Keyboard';
    end
    
    properties (Transient=true)
        window = [];
        imagingTasks = [];
        ifi = [];
    end
    
    properties (Dependent)
        resolutions
    end
    
    methods
        function st = station(varargin)
            switch nargin
                case 0
                    % default station - nothing happens
                case 1
                    in = varargin{1};
                    
                    %validateattributes(in.id,{'numeric'},{'integer','positive'})#####
                    st.id = in.id;
                    
                    validateattributes(in.path,{'char'},{'nonempty'})
                    st.path = in.path;
                    
                    %validateattributes(in.screenNum,{'numeric'},{'integer','positive'})#####
                    st.screenNum = in.screenNum;
                    
                    validateattributes(in.soundOn,{'logical'},{'numel', 1})
                    st.soundOn = in.soundOn;
                    
                    validateattributes(in.MACaddress,{'char'},{'nonempty'})
                    st.MACAddress = in.MACaddress;
                    
                    validateattributes(in.physicalLocation,{'numeric'},{'positive','vector','numel',3})
                    st.physicalLocation = in.physicalLocation;
                    
                    validateattributes(in.numPorts,{'numeric'},{'positive','integer','numel',1})
                    st.numPorts = in.numPorts;
                    
                    validateattributes(in.responseMethod,{'char'},{'nonempty'})
                    st.responseMethod = in.responseMethod;
                otherwise
                    error('station:unknownInputType','please input no or one input')
            end
        end
        
        function out=display(boxes)
            out='';
            for i=1:length(boxes)
                b=boxes(i);
                
                d=['station id: ' b.id '\tports: ' num2str(b.numPorts) '\tresponseMethod: ' b.responseMethod '\tpath: ' strrep(b.path,'\','\\')];
                if ~isempty(out)
                    out=sprintf('%s\n%s',out,sprintf(d));
                else
                    out=sprintf(d);
                end
            end
        end
        
        function sub=getCurrentSubject(s,r)
            validateattributes(r,{'ratrix'},{'nonempty'})
            subs=getSubjectsForStationID(r,s.id);
            if length(subs)==1
                sub=subs{1};
            else
                error('only implemented for stations in boxes with exactly one subject -- later will use RFID for group housing')
            end
        end
        
        function out=getDisplaySize(s)
            [a, b]=Screen('DisplaySize',s.screenNum);
            out=[a b];
        end
        
        function out=getLUTbits(s)
            [~, dacbits, reallutsize] = Screen('ReadNormalizedGammaTable', s.screenNum);
            if dacbits==log2(reallutsize)
                out=dacbits;
            elseif log2(reallutsize)==8
                out=8; %what we really care about is log2(reallutsize), see comment in makeStandardLUT()
                warning('dacbits and reallutsize don''t match')
            else
                fprintf('dacbits:\n');
                disp(dacbits);
                fprintf('reallutsize:\n');
                disp(reallutsize);
                error('dacbits and reallutsize don''t match')
            end
        end
        
        function [r, exitByFinishingTrialQuota]=doTrials(s,r,n,rn,trustOsRecordFiles)
            %this will doTrials on station=(s) of ratrix=(r).
            %n=number of trials, where 0 means repeat indefinitely
            %rn is a ratrix network object, which only the server uses, otherwise leave empty
            %trustOsRecordFiles is risky because we know that they can be wrong when
            %the server is taxed. The ratrix downstairs does not trust them. But you
            %are free of oracle dependency. It is not recommended to trustOsRecordFiles
            %unless your permanentStore is local, then it might be okay.
            %recordNeuralData is a flag to decide whether or not to start datanet for NIDAQ recording
            if ~exist('trustOsRecordFiles','var')
                trustOsRecordFiles=false;
            end
            exitByFinishingTrialQuota = false;
            
            if ~isempty(getStationByID(r,s.id))
                
                subject=getCurrentSubject(s,r);
                keepWorking=1;
                trialNum=0;
                
                if n>=0
                    ListenChar(2);
                    if usejava('jvm')
                        FlushEvents('keyDown');
                    end
                    
                    try
                        
                        s=startPTB(s);
                        
                        % ==========================================================================
                        
                        % This is a hard coded trial records filter
                        % Need to decide where to parameterize this
                        filter = {'lastNTrials',int32(100)};
                        
                        % Load a subset of the previous trial records based on the given filter
                        [trialRecords, localRecordsIndex, sessionNumber, compiledRecords] = getTrialRecordsForSubjectID(r,getID(subject),filter, trustOsRecordFiles);
                        
                        while keepWorking
                            trialNum=trialNum+1;
                            [subject, r, keepWorking, ~, trialRecords, s]= ...
                                doTrial(subject,r,s,rn,trialRecords,sessionNumber,compiledRecords);
                            % Cut off a trial record as we increment trials, IFF we
                            % still have remote records (because we need to keep all
                            % local records to properly save the local .mat)
                            if localRecordsIndex > 1
                                trialRecords = trialRecords(2:end);
                            end
                            % Now update the local index (eventually all of the records
                            % will be local if run long enough)
                            localRecordsIndex = max(1,localRecordsIndex-1);
                            % Only save the local records to the local copy!
                            updateTrialRecordsForSubjectID(r,getID(subject),trialRecords(localRecordsIndex:end));
                            
                            if n>0 && trialNum>=n
                                keepWorking=0;
                                exitByFinishingTrialQuota = true;
                            end
                        end
                        
                        stopPTB(s);
                    catch ex
                        disp(['CAUGHT ER (at doTrials): ' getReport(ex)]);
                        rethrow(ex);
                    end
                    
                    close all
                    FlushEvents('mouseUp','mouseDown','keyDown','autoKey','update');
                    ListenChar(0);
                else
                    error('n must be >= 0')
                end
                
            else
                error('that ratrix doesn''t contain this station')
            end
        end
        
        function [s newRes imagingTasksApplied]=setResolutionAndPipeline(s,res,imagingTasks)
            if res.pixelSize~=32
                res.pixelSize
                sca
                keyboard
                error('station:setResolutionAndPipeline:improperValue','color depth must be 32')
            end
            
            oldRes=Screen('Resolution', s.screenNum);
            
            if oldRes.width~=res.width || oldRes.height~=res.height || oldRes.hz ~=res.hz || oldRes.pixelSize~=res.pixelSize || ...
                    ~station.allImagingTasksSame(s.imagingTasks,imagingTasks)
                
                resolutions=Screen('Resolutions', s.screenNum);
                
                match=[[resolutions.width]==res.width; [resolutions.height]==res.height; [resolutions.hz]==res.hz; [resolutions.pixelSize]==res.pixelSize];
                
                ind=find(sum(match)==4);
                
                if length(ind)>1
                    fprintf('ind:\n');
                    disp(ind)
                    warning('multiple matches')
%                     ind=min(ind);
                elseif length(ind)<1
                    fprintf('res:\n');
                    disp(res)
                    unique([resolutions.width])
                    unique([resolutions.height])
                    unique([resolutions.hz])
                    unique([resolutions.pixelSize])
                    error('station:configurationUnavailable','target res not available')
                end
                
                s=stopPTB(s);
                
                Screen('Resolution', s.screenNum, res.width, res.height, res.hz, res.pixelSize);

                s=startPTB(s,imagingTasks);
                imagingTasksApplied=imagingTasks; % is there a way to confirm they took effect?
                
                newRes=Screen('Resolution', s.screenNum);
                if ~all([newRes.width==res.width newRes.height==res.height newRes.pixelSize==res.pixelSize newRes.hz==res.hz])
                    error('station:configurationUnavailable','failed to get desired res') %needs to be warning to work with remotedesktop
                end
                
            else
                newRes=oldRes;
                imagingTasksApplied=s.imagingTasks; % propogate state into records
            end
        end % end function
        
        function s=startPTB(s,imagingTasks)

            clear Screen;
            Screen('Screens');
            try

                if ~exist('imagingTasks','var') || isempty('imagingTasks')
                    imagingTasks=[]; % default mode does not require any tasks for the imaging pipeline
                end

                AssertOpenGL;
                %Screen('Preference','Backgrounding',0);  %mac only?
                HideCursor;

                Screen('Preference', 'SkipSyncTests', 0);

                Screen('Preference', 'VisualDebugLevel', 6);
                %http://psychtoolbox.org/wikka.php?wakka=FaqWarningPrefs
                %Level 4 is most thorough, level 1 is errors only.

                % http://groups.yahoo.com/group/psychtoolbox/message/4292
                % A new Preference setting Screen('Preference', 'VisualDebugLevel',level);
                % allows to customize the visual warning and feedback signals that can show up during Screen('OpenWindow')
                % zero disables all feedback
                % 1 allows errors to be signalled
                % 2 includes warnings
                % 3 includes information
                % 4 shows the blue screen at startup
                % 5 enables the visual flicker test-sheet on multi-display setups
                % By default, level 6 is selected -- all warnings, bells & whistles on.

                Screen('Preference', 'SuppressAllWarnings', 0);

                Screen('Preference', 'Verbosity', 4);
                %http://psychtoolbox.org/wikka.php?wakka=FaqWarningPrefs
                %0) Disable all output - Same as using the 'SuppressAllWarnings' flag.
                %1) Only output critical errors.
                %2) Output warnings as well.
                %3) Output startup information and a bit of additional information. This is the default.
                %4) Be pretty verbose about information and hints to optimize your code and system.
                %5) Levels 5 and higher enable very verbose debugging output, mostly useful for debugging PTB itself, not generally useful for end-users.

                Screen('Preference', 'ConserveVRAM', 4); % added by BAS. conserves VRAM levels to prevent weiird errors XXXX remove this if there is a problem


                preScreen=GetSecs();
                if isempty(imagingTasks)
                    % do not do this even if you "know" what you are doing
            %         PsychImaging('PrepareConfiguration');
            %         PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', 'C:\Documents and Settings\Owner\Application Data\Psychtoolbox\GeometryCalibration\SphereCalibdata_0_1600_1200.mat');
            %         [windowPtr,rect]=Screen('OpenWindow',windowPtrOrScreenNumber [,color] [,rect][,pixelSize][,numberOfBuffers][,stereomode][,multisample][,imagingmode][,specialFlags][,clientRect]);
            %         s.window = PsychImaging('OpenWindow',s.screenNum,0);%,[],32,2);  %%color, rect, depth, buffers (none can be changed in basic version)

                    [s.window,~] = Screen('OpenWindow',s.screenNum);%,[],32,2);  %%color, rect, depth, buffers (none can be changed in basic version)

                else

                    warning('edf says: have you checked that the stopPTB will remove these tasks?  i see no evidence that you clean up after yourself if a later trial doesn''t want these things.  a clear Screen may help, but i want proof.  it''s not stated in ''help psychimaging'' -- worst case, ask mario.  also, i don''t see that you''ve been careful to make sure the pipeline details are recorded in the trial record.')
                    %well, i guess it's relatively convincing that you get a unique window pointer out of it, so i'm downgrading to a warning...

                    PsychImaging('PrepareConfiguration');
                    % PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible'); %enable general support of such tasks
                    %6/2/09 - add imagingTasks to the pipeline
                    for i=1:length(imagingTasks)
                        % add task
                        evalStr=sprintf('PsychImaging(''AddTask''');
                        for j=1:length(imagingTasks{i})
                            if ischar(imagingTasks{i}{j})
                                evalStr=sprintf('%s,''%s''',evalStr,imagingTasks{i}{j});
                            elseif isnumeric(imagingTasks{i}{j})
                                evalStr=sprintf('%s,%d',evalStr,imagingTasks{i}{j});
                            else
                                error('arguments to PsychImaging must be char or numeric');
                            end
                        end
                        evalStr=[evalStr ');'];
                        eval(evalStr);
                    end
                    s.window = PsychImaging('OpenWindow', s.screenNum, 0); % use psychImaging if tasks are applied
                    s.imagingTasks=imagingTasks;
                end
                disp(sprintf('took %g to call screen(openwindow)',GetSecs()-preScreen))

                res=Screen('Resolution', s.screenNum);

                s.ifi = Screen('GetFlipInterval',s.window);%,200); %numSamples

                if res.hz~=0
                    if abs((s.ifi/(1/res.hz))-1)>.1
                        s.ifi
                        1/res.hz
                        error('screen(resolution) reporting framerate off by more than 10%% of measured ifi') %needs to be warning to work with remotedesktop
                    end
                else
                    if ~ismac
                        error('screen(resolution) reporting 0 hz, but not on mac')
                    end
                    x=Screen('Resolutions',s.screenNum);
                    %[x.hz]
                    warning('screen(resolution) reporting 0 hz -- calcStims must take this into account (this happens on osx)')
                end

                texture=Screen('MakeTexture', s.window, BlackIndex(s.window));
                [resident texidresident] = Screen('PreloadTextures', s.window);

                if resident ~= 1
                    disp(sprintf('error: blank texture not cached'));
                    find(texidresident~=1)
                end

                Screen('DrawTexture', s.window, texture,[],Screen('Rect', s.window),[],0);
                Screen('DrawingFinished',s.window,0);

                Screen('Flip',s.window);

                Screen('Close'); %leaving off second argument closes all textures

            catch ex                  
                s.ifi=[];
                s.window=[];
                Screen('CloseAll');
                Priority(0);
                ShowCursor;
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                rethrow(ex);
            end
        end
        
        function s=stopPTB(s)
            
            Screen('LoadNormalizedGammaTable', s.window, makeStandardLUT(8));
            
            s.ifi=[];
            s.window=[];
            Screen('CloseAll');
            ShowCursor;
            
            if ismac
                x=Screen('Resolutions',s.screenNum);
                x=x([x.pixelSize]==max([x.pixelSize]) & [x.hz]==max([x.hz]) & [x.width].*[x.height]==max([x.height].*[x.width]));
                if length(x)>1
                    x=x(1);
                elseif length(x)<1
                    error('can''t maximize depth, hz, and width x height simultaneously')
                end
                Screen('Resolution',s.screenNum,x.width,x.height,x.hz,x.pixelSize);
                
                % following not true on osx:
                % Psychtoolbox will automatically restore the systems display resolution to the
                % system settings made via the display control panel as soon as either your script
                % finishes by closing all its windows or by some error. Terminating Matlab due to
                % quit command or due to crash will also restore the system preference settings.
                % If you call this command without ever opening onscreen windows and closing them
                % at some point, Psychtoolbox will not restore display settings automatically.
                
                for i=1:20
                    ShowCursor %seems to get stuck in multiple layers of hidecursor
                end
            end
        end
        
        % getters and setters
        function out = get.resolutions(s)
            out=Screen('Resolutions',s.screenNum);
        end
        
        function s = set.soundOn(s,val)
            %validateattributes(val,{'boolean'},{'nonempty','numel',1});#####
            s.soundOn = val;
        end
    end
    
    methods (Static)
        function out = allImagingTasksSame(oldTasks,newTasks)
            % compare the two lists of imaging tasks and return if they are the same or not
            out=true;
            % do they have same # of tasks?
            if ~all(size(oldTasks)==size(newTasks))
                out=false;
                return
            end
            % check that each task is the same...what about if they are in diff order?
            % for now, enforce that the tasks must be in same order as well
            % ie [4 5 6] is not equal to [5 4 6]
            for i=1:length(oldTasks)
                a=oldTasks{i};
                b=newTasks{i};
                if length(a)~=length(b)
                    out=false;
                    return
                end
                for j=1:length(a)
                    if strcmp(class(a{j}),class(b{j})) % same class, now check that they are equal
                        if ischar(a{j})
                            if strcmp(a{j},b{j})
                                %pass
                            else
                                out=false;
                                return
                            end
                        elseif isnumeric(a{j})
                            if a{j}==b{j}
                                %pass
                            else
                                out=false;
                                return
                            end
                        else
                            error('found an argument that was neither char nor numeric');
                        end
                    else
                        out=false; % args have diff class
                        return
                    end
                end
            end
        end % end function
    end
end
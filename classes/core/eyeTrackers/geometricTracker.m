classdef geometricTracker
    
    properties
        method=[];
        Rp=[];                   % in mm
        Rcornea=[];              % radius of the cornea in mm
        alpha=[];                % degrees vertical angular elevation above camera of CR light source
        beta=[];                 % degrees horizontal angular elevation above camera of CR light source
        CameraImSizePixs=[];     % x pixels, y pixels,  Sol says: [1280,1024]
        CameraImSizeMm=[];       %measured to 0.5 mm acc on 061122
        CameraPixPerMm=[];       %calulated
        MonitorImSizePixs=[];    %x pixels, y pixels  [1024,768];
        MonitorImSizeMm=[];      %measured to 10mm acc on 061122
        MonitorPixPerMm=[]       %calculated
        eyeToMonitorTangentMm=[];      %measured 24 cm on 061122;   to be adjusted based on input from HorizTrack
        eyeAboveMonitorCenterMm=[];    %roughly measured on Oct 16, 2006;  to be adjusted based on input from JackHeight
        eyeRightOfMonitorCenterMm=[];    %always zero (less than 1mm) in our rig;  user must center eye before recording
        degreesCameraIsClockwiseOfMonitorCenter=[];  %roughly if camera is at right of monitor; to be entered by user
        degreesCameraIsAboveEye=[];      %always zero (less than 3deg) in our rig;  user must center eye before recording
        settingMethod='none';
        humanConfirmation=false;         %this is set each session at run time.

    end
    
    methods
        function et=geometricTracker(varargin)
            % geometricTracker claess constructor.
            % tracks the eye using trigometric back calculation, given knownledge of the spatial geometry of the rig
            % for more information about method see work by John Stahl 
            %         method='simple';         % 'simple' involves less noise, 'yCorrected' better in principle for more accurate for non-tangetial vertical eye positions. but may have noise from yEstimate      
            %         Rp=2;                    % in mm distance from pupil center to corneal surface see Stahl 2002 for methods of measuring it 
            %         Rcornea=3;               % radius of the cornea in mm
            %         alpha=12;                % degrees vertical angular elevation above camera of CR light source
            %         beta=0;                  % degrees horizontal angular elevation above camera of CR light source
            %         CameraImSizePixs=int16([1280,1024]);     % x pixels, y pixels,  Sol says: [1280,1024]
            %         CameraImSizeMm=[42,28];       % measured to 0.5 mm acc on 061122
            %         MonitorImSizePixs=int16([1024,768]);    % x pixels, y pixels  [1024,768];
            %         MonitorImSizeMm=[400,290];      %measured to 10mm acc on 061122
            %         eyeToMonitorTangentMm=300;         % measured 24 cm on 061122;   to be adjusted based on input from HorizTrack
            %         eyeAboveMonitorCenterMm=-25;       % roughly measured on Oct 16, 2006;  to be adjusted based on input from JackHeight
            %         eyeRightOfMonitorCenterMm=0;     % always zero (less than 1mm) in our rig;  user must center eye before recording
            %         degreesCameraIsClockwiseOfMonitorCenter=45;  %roughly if camera is at right of monitor; to be entered by user
            %         degreesCameraIsAboveEye=0;      %always zero (less than 3deg) in our rig;  user must center eye before recording
            %         settingMethod='guiPrompt';    % will allow human to update and/or confirm settings.  alternatelt, you can use 'none', in which case
            %                                       % the settings are not updated each time, and considered unconfirmed to be true
            % et = geometricTracker(method, Rp, Rcornea, alpha, beta, CameraImSizePixs, CameraImSizeMm, MonitorImSizePixs, MonitorImSizeMn, eyeToMoinitorTangentMm, eyeAboveMonitorCenterMm, eyeRightOfMonitorCenterMm, degreesCameraIsClockwiseOfMonitorCenter, degreesCameraIsAboveEye,settingMethod,framesPerAllocationChunk)
            % et = geometricTracker('simple', 2, 3, 12, 0, int16([1280,1024]), [42,28], int16([1024,768]), [400,290], 300, -25, 0, 45, 0)
            % future idea:  et =geometricTracker(getDefaults(geometricTracker))

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                    requiresCalibration = true;
                    

            %       et.hackScaleFactor=[];    % should be 1 for normal function.  Increases "camera resolution."  Acts like 1/Rp.
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'geometricTracker'))
                        et = varargin{1};
                    else
                        error('Input argument is not a geometricTracker object')
                    end

                case 16
                    if ismember(varargin{1}, {'simple', 'yCorrected','cr-p'})
                        et.method=varargin{1};
                    else
                        error('method must be simple or ycorrected')
                    end

                    if varargin{2}>0 && varargin{2}<15
                        et.Rp=varargin{2};
                    else
                        error('Rp must be a sensible measure (0-15) in mm of distance from pupil center to corneal surface');
                    end

                    if varargin{3}>0 && varargin{3}<30
                        et.Rcornea=varargin{3};
                    else
                        error('Rcornea must be a sensible measure (0-30) in mm of distance of the radius of the cornea');
                    end

                    if varargin{4}>-90 && varargin{4}<90
                        et.alpha=varargin{4};
                    else
                        error('alpha must be a sensible measure (-90 - 90) in degrees of vertical angle between camera axis and cr light source');
                    end

                    if varargin{5}==0
                        et.beta=varargin{5};
                    else
                        error('beta must be 0 for John Stahl''s method to work');
                    end

                    if all(size(varargin{6})==[1 2]) && isinteger(varargin{6})
                        et.CameraImSizePixs=double(varargin{6});
                    else
                        error('CameraImSizePixs must be x by y pixel and integers');
                    end

                    if all(size(varargin{7})==[1 2]) && all(varargin{7}>0)
                        et.CameraImSizeMm=varargin{7};
                    else
                        error('CameraImSizeMm must be x by y mm and must be >0');
                    end

                    et.CameraPixPerMm=double(et.CameraImSizePixs)./et.CameraImSizeMm;

                    if all(size(varargin{8})==[1 2]) && isinteger(varargin{8})
                        et.MonitorImSizePixs=double(varargin{8});
                    else
                        error('MonitorImSizePixs must be x by y pixel and integers');
                    end

                    if all(size(varargin{9})==[1 2]) && all(varargin{9}>0)
                        et.MonitorImSizeMm=varargin{9};
                    else
                        error('MonitorImSizeMm must be x by y mm and must be >0');
                    end

                    et.MonitorPixPerMm=double(et.MonitorImSizePixs)./et.MonitorImSizeMm;

                    if all(size(varargin{10})==[1 1]) && all(varargin{10}>0)
                        et.eyeToMonitorTangentMm=varargin{10};
                    else
                        error('eyeToMonitorTangentMm must a single number in mm and must be >0');
                    end

                    if all(size(varargin{11})==[1 1]) && all(abs(varargin{11})<300)
                        et.eyeAboveMonitorCenterMm=varargin{11};
                    else
                        error('eyeAboveMonitorCenterMm must a single number in mm and the absolute value must be less than 300');
                    end

                    if all(size(varargin{12})==[1 1]) && all(abs(varargin{11})<300)
                        et.eyeRightOfMonitorCenterMm=varargin{12};
                    else
                        error('eyeRightOfMonitorCenterMm must a single number in mm and must be >0');
                    end

                    if varargin{13}>=0 && varargin{13}<=180
                        et.degreesCameraIsClockwiseOfMonitorCenter=varargin{13};
                    else
                        error('degreesCameraIsClockwiseOfMonitorCenter must be a sensible measure (0 - 180) in clockwise degrees of angle between camera axis and monitor');
                    end

                    if varargin{14}==0 %varargin{14}>-3 && varargin{14}<3
                        et.degreesCameraIsAboveEye=varargin{14};
                    else
                        error('degreesCameraIsAboveEye should be zero');
                        %error('degreesCameraIsAboveEye should be zero, but code tolerates (-3 - 3) in vertical degrees of angle between camera axis and the eye');
                    end

                    if ismember(varargin{15},{'guiPrompt','none'})
                        et.settingMethod=varargin{15};
                    else
                        error('eyeAboveMonitorCenterMm must a single number in mm and the absolute value must be less than 300');
                    end

                    et.humanConfirmation=false;

                    requiresCalibration = true;
                    
                otherwise
                    error('Wrong number of input arguments')
            end

            %et=setSuper(et,et.eyeLinkTracker); %no more supers -pmm 090122 
        end
        
        function et=calibrate(et)
            %gets the calibration values from the user

            switch et.settingMethod
                case 'none'
                    %do nothing
                case 'mfile'
                    previousValues=getCurrentCalibrationValues(et);
                    edit ('eyeLinkTracker/getCurrentCalibrationValues')
                    pause

                    values=getCurrentCalibrationValues(et);

                    if previousValues.counter+1~=values.counter
                        previousValues.counter
                        values.counter
                        error ('user failed to update counter and save currentCalibrationValues.');
                    end

                    %         et.eyeToMonitorTangentMm=[];      %measured 24 cm on 061122;   to be adjusted based on input from HorizTrack
                    %         et.eyeAboveMonitorCenterMm=[];    %roughly measured on Oct 16, 2006;  to be adjusted based on input from JackHeight
                    %         et.eyeRightOfMonitorCenterMm=[];    %always zero (less than 1mm) in our rig;  user must center eye before recording
                    %         et.degreesCameraIsClockwiseOfMonitorCenter=[];  %roughly if camera is at right of monitor; to be entered by user
                    %         et.degreesCameraIsAboveEye=[];      %always zero (less than 3deg) in our rig;  user must center eye before recording
                case 'guiPrompt'
                    prompt={'enter based ruler measurement in mm:', 'degreesCameraIsClockwiseOfMonitorCenter:', 'eyeAboveMonitorCenterMm:', 'eyeRightOfMonitorCenterMm:(please center eye and confirm it is 0 mm)', 'degreesCameraIsAboveEye:(please move camera until eye is centered, enter 0)', 'human confirmation that values are good:'};
                    name='Geometric Calibration User Specified Parameters';
                    numlines=1;
                    defaultanswer={'110','45','-55','0','0','0'};

                    confirmedCorrect=0;
                    while ~confirmedCorrect

                        answer=inputdlg(prompt,name,numlines,defaultanswer);
                        correctSoFar=1;

                        input=str2num(answer{1});
                        if all(size(input)==[1 1]) && input>0 && input<380 %true for rig on -pmm 080711
                            screenToRulerZeroMm=490;
                            backRightCornerToPivotCenterMm=65;
                            et.eyeToMonitorTangentMm=screenToRulerZeroMm-backRightCornerToPivotCenterMm-input;
                            %et=setEyeToMonitorTangentMm(et, eyeToMonitorTangentMm);
                        else
                            warning('based ruler measurement must be between 0 and 380 mm');
                            correctSoFar=0;
                        end

                        input=str2num(answer{2});
                        if input>0 && input<180
                            et.degreesCameraIsClockwiseOfMonitorCenter=input;
                            %et=setDegreesCameraIsClockwiseOfMonitorCenter(et, degreesCameraIsClockwiseOfMonitorCenter);
                        else
                            warning('degreesCameraIsClockwiseOfMonitorCenter must be a sensible measure (0 - 180) in clockwise degrees of angle between camera axis and monitor');
                            correctSoFar=0;
                        end

                        input=str2num(answer{3});
                        if all(size(input)==[1 1]) && all(abs(input)<300)
                            et.eyeAboveMonitorCenterMm=input;
                            %et=setEyeAboveMonitorCenterMm(et, eyeAboveMonitorCenterMm);
                        else
                            warning('eyeAboveMonitorCenterMm must a single number in mm and the absolute value must be less than 300');
                            correctSoFar=0;
                        end

                        input=str2num(answer{4});
                        if all(size(input)==[1 1]) && all(abs(input)<300)
                            et.eyeRightOfMonitorCenterMm=input;
                            %et=setEyeRightOfMonitorCenterMm(et, eyeRightOfMonitorCenterMm);
                        else
                            warning('eyeRightOfMonitorCenterMm must a single number in mm and must be <300');
                            correctSoFar=0;
                        end

                        input=str2num(answer{5});
                        if input==0 %varargin{14}>-3 && varargin{14}<3
                            et.degreesCameraIsAboveEye=input;
                            %et=setDegreesCameraIsAboveEye(et, degreesCameraIsAboveEye);
                        else
                            warnning('degreesCameraIsAboveEye should be zero');
                            %error('degreesCameraIsAboveEye should be zero, but code tolerates (-3 - 3) in vertical degrees of angle between camera axis and the eye');
                            correctSoFar=0;

                        end

                        et.humanConfirmation=str2num(answer{6});


                        if ~correctSoFar
                            beep
                            defaultanswer=answer;
                            warning('not all of the values were acceptable');

                        else
                            confirmedCorrect=1;
                            struct(et);
                        end
                    end

                    %         options.Resize='on';
                    %         options.WindowStyle='normal';
                    %         options.Interpreter='tex';
                    %
                    %         answer=inputdlg(prompt,name,numlines,defaultanswer,options)



                otherwise
                    et.settingMethod
                    error ('bad method');
            end


            et.eyeLinkTracker=calibrate(et.eyeLinkTracker); % updated 10/19/08 according to pmm version
        end
        
        function gaze=getGazeEstimate(et,cr,pup)
            %using Fick coordinates; see Stahl, 2002 and 2004
            %toDo:  find whats causing the imaginary component
            el = getConstants(et);

            cr(cr==el.MISSING_DATA)=nan;
            pup(pup==el.MISSING_DATA)=nan;

            %Short code
            switch et.method
                case 'cr-p'
                    %these are not in terms of screen coordinates, and do not acoud for eye curvature, animal position, etc
                    %but they do monotonically relate to gaze angle.
                    gaze=cr-pup;
                case 'simple'
                    %same function in few lines, less interpretable b/c no intermediate variables
                    gaze=[(et.MonitorImSizePixs(1)/2)+et.MonitorPixPerMm(1)*(et.eyeToMonitorTangentMm*tan(-asin((cr(:,1)-pup(:,1))/(et.CameraPixPerMm(1)*et.Rp))-(et.degreesCameraIsClockwiseOfMonitorCenter*pi/180))+et.eyeRightOfMonitorCenterMm),...
                        (et.MonitorImSizePixs(2)/2)+et.MonitorPixPerMm(2)*(et.eyeToMonitorTangentMm*tan(atan((cr(:,2)-pup(:,2))/(et.CameraPixPerMm(2)*et.Rp))-(et.degreesCameraIsAboveEye*pi/180))+et.eyeAboveMonitorCenterMm)];
                case 'yCorrected'
                    Rp0b=sqrt(((cr(:,2)-pup(:,2))/et.CameraPixPerMm(2)+et.Rcornea*sin((et.alpha*pi/180)/2)).^2+et.Rp^2);
                    Yraw=((cr(:,2)-pup(:,2))/et.CameraPixPerMm(2));
                    RpCorrectedb=sqrt(sqrt((Yraw+et.Rcornea*sin((et.alpha*pi/180)/2)).^2+et.Rp^2).^2-Yraw.^2);
                    gaze=[(et.MonitorImSizePixs(1)/2)+et.MonitorPixPerMm(1)*(et.eyeToMonitorTangentMm*tan(-asin((cr(:,1)-pup(:,1))./(et.CameraPixPerMm(1)*RpCorrectedb))-(et.degreesCameraIsClockwiseOfMonitorCenter*pi/180))+et.eyeRightOfMonitorCenterMm),...
                        (et.MonitorImSizePixs(2)/2)+et.MonitorPixPerMm(2)*(et.eyeToMonitorTangentMm*tan(asin((cr(:,2)-pup(:,2))./(et.CameraPixPerMm(2)*Rp0b))-(et.degreesCameraIsAboveEye*pi/180))+et.eyeAboveMonitorCenterMm)];
            end

            if 0
                if any(imag(gaze)>0)
                    sca
                    keyboard
                    error('no imaginary values allowed!')
                end
            end


            % %don't need this, but this line explains the relation of long to short code
            % angle2test=[asin((cr(:,1)-pup(:,1))/(et.CameraPixPerMm(1)*RpCorrectedb)), asin((cr(:,2)-pup(:,2))/(et.CameraPixPerMm(2)*Rp0b))];
            %
            %
            % x=gaze2(1);
            % y=gaze2(2);


            errorCheck=false;
            if errorCheck
                %LONG CODE
                %cr=[crx,cry];
                %pup=[pupx,pupy];

                ns=size(cr,1);
                dif=cr-pup;                                %distance between corneal reflection and pupil center
                dif=dif./repmat(et.CameraPixPerMm,ns,1);                   %convert pixels to mm

                %MODE ONE, simple
                horiz1=asin(dif(:,1)/et.Rp);                   %eqn 1, only use when vertical position is on camera axis =0
                %without correction will have less noise b/c no Rp0 estimated
                vert1=atan(dif(:,2)/et.Rp);                    %eqn 6, use Rp and tangent, why? see diagram
                %in this mode you should have RefIR at horizontal position, not above

                %MODE TWO, uses correction
                Yraw=dif(:,2);
                y=Yraw+et.Rcornea*sin((et.alpha*pi/180)/2);     %corrected y, accounts for position of LED, eqn 3
                Rp0=sqrt(y.^2+et.Rp^2);
                RpCorrected=sqrt(Rp0.^2-Yraw.^2);         %corrected Rp at this vertical position, eqn 5
                horiz2=asin(dif(:,1)./RpCorrected);          %eqn 1, but with adjusted Rp
                vert2=asin(dif(:,2)./Rp0);                   %eqn 6, use sin and great circle radius

            %     angle1=[horiz1,vert1];                         % in radians
            %     angle2=[horiz2,vert2];                         % in radians
                angle1=[-horiz1,vert1];                         % in radians -- if this is correct put an minus in front of asin in short code too, then check long and short match
                angle2=[-horiz2,vert2];                         % in radians
                angle1deg=angle1*180/pi;                         % in degrees, good for viewing, not used in code
                angle2deg=angle2*180/pi;                         % in degrees, good for viewing, not used in code

                physicalOffset=repmat([et.eyeRightOfMonitorCenterMm,et.eyeAboveMonitorCenterMm],ns,1);
                angularOffset=repmat([et.degreesCameraIsClockwiseOfMonitorCenter*pi/180,et.degreesCameraIsAboveEye*pi/180],ns,1);
                centerScreenPix=repmat(et.MonitorImSizePixs/2,ns,1);

                gazeMm1=et.eyeToMonitorTangentMm*tan(angle1-angularOffset);   %the mm of offset from gaze
                gazeMm2=et.eyeToMonitorTangentMm*tan(angle2-angularOffset);   %the mm of offset from gaze
                gaze1= centerScreenPix+(physicalOffset+gazeMm1).*repmat(et.MonitorPixPerMm,ns,1);  %estimate of gaze in Monitor Pix
                gaze2= centerScreenPix+(physicalOffset+gazeMm2).*repmat(et.MonitorPixPerMm,ns,1);  %estimate of gaze in Monitor Pix



                switch et.method
                    case 'simple'
                        if ~all((gaze(:)-gaze1(:))==0)
                            gaze
                            gaze1
                            theDif=gaze-gaze1
                            error('these should be the same!')
                        end
                    case 'yCorrected'
                        if ~all((gaze(:)-gaze2(:))==0)

                            gaze
                            gaze2
                            theDif=gaze-gaze2
                            %angle2test==angle2
                            error('these should be the same!')
                        end
                end

                % %reasoning about signs...
                %     %if gaze coordinates way off screen check sign of angle1-angularOffset
            end
        end
        
    end
    
end


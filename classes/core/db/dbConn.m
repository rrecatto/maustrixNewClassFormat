classdef dbConn
    
    properties
        host = '132.239.158.177'; % Default Oracle DB Server address
        port = '1521'; % Default Oracle DB Port
        user = 'dparks';
        password = 'pac3111';
        driver='oracle.jdbc.driver.OracleDriver';
        service = 'XE';
        name=''; % This must be left blank!
    end
    
    methods
        
        function conn=dbConn%(host,port,user,password)
        % dbConn  class constructor.
        %
        % Create a persistent connection to Oracle database
        %

        % edf 08.09.08: require using defaults rather than passing in
        % host/port/user/password so these aren't sprinkled everywhere, 
        % in case we change addr/acct info

            % if exist('host')
            %     conn.host = host;
            % end
            % if exist('port')
            %     if ~ischar(port)
            %         conn.port = sprintf('%d',port) % Turn port into a string
            %     else
            %         conn.port = port;
            %     end
            % end
            % if exist('user','var') % IMPORTANT 'user' is a type in exist
            %     conn.user = user;
            % end
            % if exist('password')
            %     conn.password = password;
            % end

            conn.url=['jdbc:oracle:thin:/' conn.user '/' conn.password '@//' conn.host ':' conn.port '/' conn.service];
            % Load driver and then create db connection
            conn.conn = openDBConnection(conn.driver,conn.url,conn.user,conn.password);

            conn = class(conn,'dbConn');
        end
        
        function addTrialRecordFile(conn,subject_id,file_name)

            % Get the hidden subject uin for this id
            subjectquery=sprintf('select subjects.uin from subjects where UPPER(display_uin)=UPPER(''%s'') ',subject_id);
            subjectdata=query(conn,subjectquery);
            if isempty(subjectdata)
                subject_id
                file_name
                error('File for unknown subject was attempted to be added')
            else
                subject_uin=subjectdata{1,1};
            end

            % Add the file name for the given subject
            % This is the SQL query where all the real work is done
            insertStr=sprintf('insert into trialrecords values( %d, ''%s'')',subject_uin,file_name);

            rowCount = exec(conn,insertStr);
        end
        
        function conn = closeConn(conn)
            close(conn.conn);
        end
        
        function success=copyAndAddTrialRecordFile(conn,subject_id,file_name,oldLocation,newLocation)

            % Get the hidden subject uin for this id
            subjectquery=sprintf('select subjects.uin from subjects where LOWER(display_uin)=LOWER(''%s'') ',subject_id);
            subjectdata=query(conn,subjectquery);
            if isempty(subjectdata)
                subject_id
                file_name
                error('File for unknown subject was attempted to be added')
            else
                subject_uin=subjectdata{1,1};
            end

            % Add the file name for the given subject
            % This is the SQL query where all the real work is done
            insertStr=sprintf('insert into trialrecords values( %d, ''%s'')',subject_uin,file_name);

            % Copy the file first                        
            [success messageC messageIDC]=copyfile(oldLocation,newLocation);
            if ~success
                messageC
                messageIDC
                error('couldn''t copy file')
            else
                % Copy succeeded, so hopefully we can get this in real fast
                rowCount = exec(conn,insertStr);
                if rowCount ~= 1
                    error('Unable to insert trial record file into database')
                end
            end
        end
        
        function out=deleteCalibrationData(conn,mac,timeRange)
            % this function deletes calibrationData entries based on a mac and timeRange

            out=0;
            str=sprintf('select data, to_char(timestamp,''mm-dd-yyyy hh24:mi''),comm,calibrationString from MONITOR_CALIBRATION where station_mac=''%s''',mac);
            results=query(conn,str);
            list=results(:,[2 3 4]);

            for i=1:size(results,1)
                results{i,2}=datenum(results{i,2},'mm-dd-yyyy HH:MM');
            end
            which=find(cell2mat(results(:,2))>=timeRange(1)&cell2mat(results(:,2))<=timeRange(2));

            if ~isempty(which)
                dispStr=sprintf('This will DELETE %d calibration data entries! Are you sure you want to delete (Y/N)?',length(which));
                validInput=false;
                while ~validInput
                    s=input(dispStr,'s');
                    if strcmpi(s,'Y')
                        validInput=true;
                        % do delete
                        for i=1:length(which)
                            str=sprintf('delete from MONITOR_CALIBRATION where comm=''%s'' and calibrationString=''%s'' and timestamp=to_date(''%s'',''mm-dd-yyyy hh24:mi'')',...
                                list{which(i),2},list{which(i),3},list{which(i),1})
                            exec(conn,str);
                            out=out+1;
                        end
                    elseif strcmpi(s,'N')
                        validInput=true;
                        % do not delete
                        disp('No entries deleted.');
                    else
                        disp('Invalid input - please try again');
                    end
                end        
            elseif isempty(which)
                error('failed to find any entries for the given mac address and timeRange');
            end

        end % end function
        
        function rowCount = exec(conn,execString)

            stmt = conn.conn.createStatement();

            try
                rowCount = stmt.executeUpdate(execString);
                stmt.close();
            catch ex
                stmt.close();
                rethrow(ex)
            end
        end
        
        function rackIDs=getAllRackIDs(conn)
            rackIDs = {};
            selectRackIDQuery = ...
                sprintf('SELECT DISTINCT rack_id from RACKS, STATIONS where racks.uin=stations.rack_uin order by rack_id'); 

            rackIDs=query(conn,selectRackIDQuery);

            % if ~isempty(results)
            %     numRecords=size(results,1);
            %     assignments = cell(numRecords,1);
            %     for i=1:numRecords
            %         a = [];
            %         a.subject_id = results{i,1};
            %         a.rack_id = results{i,2};
            %         a.station_id = results{i,3};
            %         a.heat = results{i,4};
            %         a.owner = results{i,5};
            %         a.experiment = results{i,6};
            %         assignments{i} = a;
            %     end
        end

        function subjects=getAllSubjects(conn)
            subjects = {};
            selectSubjectsQuery = 'select display_uin, subjects.uin from subjects order by display_uin';
            results=query(conn,selectSubjectsQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                subjects = cell(numRecords,1);
                for i=1:numRecords
                    s = [];
                    s.subjectID = results{i,1};
                    s.subject_uin = results{i,2};
                    subjects{i} = s;
                end
            end
        end

        function assignments=getAssignments(conn,rack_id,heat_name)
            assignments = {};
            selectAssignmentQuery = ...
                sprintf('SELECT LOWER(subjects.display_uin), rack_id, station_id, heats.name, researchers.username, experiments.name, heat_assignments.note FROM heat_assignments,subjects,racks,stations,heats,researchers,experiments WHERE heat_assignments.subject_uin=subjects.uin AND heat_assignments.station_uin=stations.uin AND stations.rack_uin=racks.uin AND heat_assignments.heat_uin=heats.uin AND subjects.owner_uin=researchers.uin(+) AND heat_assignments.experiment_uin=experiments.uin AND racks.rack_id=%d AND heats.name=''%s''ORDER BY rack_id,station_id',rack_id,heat_name); 

            results=query(conn,selectAssignmentQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                assignments = cell(numRecords,1);
                for i=1:numRecords
                    a = [];
                    a.subject_id = results{i,1};
                    a.rack_id = results{i,2};
                    a.station_id = results{i,3};
                    a.heat = results{i,4};
                    a.owner = results{i,5};
                    a.experiment = results{i,6};
                    a.note = results{i,7};
                    assignments{i} = a;
                end
            end
        end
        
        function assignments=getAssignmentsForServer(conn,server_name,heat_names,include_test_rats)

            % 12/4/08
            % include_test_rats allows analysis to exclude test rats
            if ~exist('include_test_rats','var')
                include_test_rats=1; % default is to include test rats (used in other ratrix code)
            end

            if ~exist('heat_names','var') || isempty(heat_names)
                heat_names=getHeats(conn);
                heat_names=[heat_names{:}];
                heat_names={heat_names.name};
            elseif ischar(heat_names) && isvector(heat_names)
                heat_names={heat_names};
            elseif iscell(heat_names) && isvector(heat_names)
                %pass
            else
                error('heat names must be a string or a cell vector of strings or empty (for all heats)')
            end

            assignments = {};
            for j=1:length(heat_names)
                heat_name=heat_names{j};
                selectAssignmentQuery = ...
                    sprintf('SELECT LOWER(subjects.display_uin), rack_id, station_id, heats.name, researchers.username, experiments.name, heat_assignments.note FROM heat_assignments,subjects,racks,stations,heats,researchers,experiments,ratrixservers WHERE heat_assignments.subject_uin=subjects.uin AND heat_assignments.station_uin=stations.uin AND subjects.owner_uin=researchers.uin(+) AND stations.rack_uin=racks.uin AND heat_assignments.experiment_uin=experiments.uin(+) AND heat_assignments.heat_uin=heats.uin AND stations.server_uin=ratrixservers.uin AND ratrixservers.name=''%s'' AND heats.name=''%s'' AND (subjects.test_subject=%d OR subjects.test_subject is null OR subjects.test_subject=0) ORDER BY rack_id,station_id',server_name,heat_name,include_test_rats);

                results=query(conn,selectAssignmentQuery);

                if ~isempty(results)
                    numRecords=size(results,1);
                    for i=1:numRecords
                        a = [];
                        a.subject_id = results{i,1};
                        a.rack_id = results{i,2};
                        a.station_id = results{i,3};
                        a.heat = results{i,4};
                        a.owner = results{i,5};
                        a.experiment = results{i,6};
                        a.note = results{i,7};
                        assignments{end+1} = a;
                    end
                end
            end
        end
        
        function [weights dates thresholds thresholds_90pct ages] = getBodyWeightHistory(conn,subject_id)
            % 10/20/08 - the thresholds returned are from the weightthreshold table in oracle, and are already scaled to 85% of mean weights
            % DO NOT RESCALE THEM in analysis
            weights={};
            thresholds={};
            dates={};
            thresholds_90pct={};

            if nargout<3
                usethresholds=false;
            else
                usethresholds=true;
            end


            % Get the hidden subject uin for this id and species
            subjectquery=sprintf('select subjects.uin from subjects where display_uin=''%s'' ',subject_id);
            subjectdata=query(conn,subjectquery);
            if isempty(subjectdata)
                'No subject'
                return
            else
                subject_uin=subjectdata{1,1};
            end

            if usethresholds
                % Get the weights, thresholds, and dates for this subject uin
                % This is the SQL query where all the real work is done

                %dan changed this to the following, but it breaks:
            %    queryStr=sprintf('select         observation_date,                  to_number(value), to_number(threshold) from combinedthreshold where ((threshold_date,uin) in (select max(threshold_date),uin from combinedthreshold where threshold_date <= observation_date group by uin) or threshold_date is null) and subject_uin= %d and observationtype_uin=1 ORDER BY observation_date',subject_uin);
            %     queryStr=sprintf('select to_char(observation_date,''DD-MON-YYYY''), to_number(value), to_number(threshold) from combinedthreshold where ((threshold_date,uin) in (select max(threshold_date),uin from combinedthreshold where threshold_date <= observation_date group by uin) or threshold_date is null) and subject_uin= %d and observationtype_uin=1 and value is not null ORDER BY observation_date',subject_uin);
            % 10/3/08 - changed to use the view "thresholdcurve_nocalc" instead of "combinedthreshold" to skip the 85% calc
            % thresholdcurve_nocalc just correlates the weightthreshold table with observations according to age (does no other calcs)
            % queryStr=sprintf('select to_char(observation_date,''DD-MON-YYYY''), to_number(value), to_number(threshold) from thresholdcurve_nocalc where ((threshold_date,uin) in (select max(threshold_date),uin from thresholdcurve_nocalc where threshold_date <= observation_date group by uin) or threshold_date is null) and subject_uin= %d and observationtype_uin=1 and value is not null ORDER BY observation_date',subject_uin);
            % 
            % ========================================================================================================
                % 10/7/08 - do not use oracle views (because they are recomputed at every call and thus still slow)
                queryStr = sprintf('select to_char(dob, ''DD-MON-YYYY''), gender, strain_uin from subjects where subjects.display_uin=''%s''', subject_id);
                data = query(conn, queryStr);
                if ~isempty(data)
                    dob = datenum(data{1});
                    gender = data{2};
                    strain_uin = data{3};
                end

                queryStr = sprintf('select to_char(observation_date, ''DD-MON-YYYY''), to_number(observations.value) FROM observations,subjects WHERE observations.subject_uin=subjects.uin AND value is not null AND subjects.display_uin=''%s'' order by observation_date', subject_id);
                data = query(conn, queryStr);
                if ~isempty(data)
                    dates=data(:,1);
                    weights=data(:,2);
                    ages= datenum(dates) - dob;
                end
                % we have dates/values - now get thresholds
                queryStr = sprintf('select age, weight, threshold_90pct from weightthreshold where strain_uin=%d AND gender=''%s'' order by age', strain_uin, gender);
                data = query(conn, queryStr);
                if ~isempty(data)
                    % get thresholds
                    all_threshold_ages = cell2mat(data(:,1));
                    all_thresholds=cell2mat(data(:,2));
                    all_thresholds_90pct=cell2mat(data(:,3));
                end

                % now align all_thresholds with the provided ages according to all_threshold_ages
                thresholds = zeros(length(ages),1);
                thresholds_90pct = zeros(length(ages),1);
                % 11/6/08 - changed to return threshold of 0 if rat is so old that there is no threshold data available
                for i=1:length(ages)
                    all_thresholds_index = find(all_threshold_ages == ages(i));
                    if ~isempty(all_thresholds_index)
                        thresholds(i) = all_thresholds(all_thresholds_index);
                        thresholds_90pct(i) = all_thresholds_90pct(all_thresholds_index);
                    else
                        thresholds(i) = 0;
                        thresholds_90pct(i) = 0;
                    end
                end

            % =========================================================================================================
            % unchanged - fast query
            else
                % Get the weights and dates for this subject uin
                % This is the SQL query where all the real work is done

                %dan changed this to the following, but it breaks:    
            %    queryStr=sprintf('select         observation_date,                  to_number(value) from observations where subject_uin= %d and observationtype_uin=1 ORDER BY observation_date',subject_uin);
                queryStr=sprintf('select to_char(observation_date,''DD-MON-YYYY''), to_number(value) from observations where subject_uin= %d and observationtype_uin=1 and value is not null ORDER BY observation_date',subject_uin);



                data = query(conn,queryStr);
                if ~isempty(data)
                    dates=data(:,1);
                    weights=data(:,2);
                end

            end

            %dates=cell2mat(dates); %dan's new file uses this, but it breaks
            dates=datenum(dates); % Turn the dates into datenums, this produces a mat
            weights=cell2mat(weights);
            % thresholds=cell2mat(thresholds); % 10/7/08 - already done above
        end
        
        function out=getCalibrationData(conn,mac,timeRange)
            % this function retrieves an existing BLOB based on mac, reads it as a binary .mat file, and loads this temp file.
            % timeRange is specified as a a 2x1 vector of datenums

            out={};
            str=sprintf('select data, to_char(timestamp,''mm-dd-yyyy hh24:mi''),comm,calibrationString from MONITOR_CALIBRATION where station_mac=''%s''',mac);
            results=query(conn,str);
            list=results(:,[2 3 4]);

            for i=1:size(results,1)
                results{i,2}=datenum(results{i,2},'mm-dd-yyyy HH:MM');
            end
            which=find(cell2mat(results(:,2))>=timeRange(1)&cell2mat(results(:,2))<=timeRange(2));
            ind=1;
            if length(which)>1
                for i=1:length(which)
                    dispStr=sprintf('%d\t%s\t%s',which(i),list{which(i),1},list{which(i),2});
                    disp(dispStr);
                end
                validInput=false;
                while ~validInput
                    dispStr=sprintf('select an entry (%d-%d):',which(1),which(end));
                    ind=input(dispStr);
                    if isnumeric(ind) && isscalar(ind) && length(find(which==ind))==1
                        % pass
                        validInput=true;
                        ind=find(which==ind);
                    end
                end
            elseif isempty(which)
                error('failed to find any entries for the given mac address and timeRange');
            end
            c=results{which(ind),1};
            stream=c.getBinaryStream;
            nextbyte=stream.read();
            while nextbyte~=-1
                out=[out nextbyte];
                nextbyte=stream.read();
            end
            out=cell2mat(out);
            out=uint8(out);

            fid=fopen('tempdata.mat','w');
            fwrite(fid,out);
            fclose(fid);

            out=load('tempdata.mat');
        end % end function
        
        function assignments=getCoachAssignmentsForServer(conn,server_name,heat_name)
            assignments = {};
            selectAssignmentQuery = ...
                sprintf('SELECT LOWER(subjects.display_uin), researchers.username FROM heat_assignments,subjects,racks,stations,heats,researchers,experiments,ratrixservers WHERE heat_assignments.subject_uin=subjects.uin AND heat_assignments.station_uin=stations.uin AND subjects.coach_uin=researchers.uin(+) AND stations.rack_uin=racks.uin AND heat_assignments.experiment_uin=experiments.uin(+) AND heat_assignments.heat_uin=heats.uin AND stations.server_uin=ratrixservers.uin AND ratrixservers.name=''%s'' AND heats.name=''%s''ORDER BY rack_id,station_id',server_name,heat_name);

            results=query(conn,selectAssignmentQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                assignments = cell(numRecords,1);
                for i=1:numRecords
                    a = [];
                    a.subject_id = results{i,1};
                    a.coach = results{i,2};
                    assignments{i} = a;
                end
            end
        end
        
        function path = getCompilePathBySubject(conn, subjectID)
            % retreives the compile_path (compiled trialRecords store path) field from the subjects table given the display_uin
            % returns the result as a 1x1 cell array (holding a char array)

            getPathQuery = sprintf('select compile_path from subjects where display_uin=''%s''', subjectID);

            path=query(conn,getPathQuery);
            % path
            % if isempty(path{1})
            %     error('could not find compiled trialRecords store path for this subject %s', subjectID);
            % end


        end %end function

        function [dates free_water_amounts free_water_units] = getFreeWaterHistory(conn,subject_id)

            dates={};
            free_water_amounts={};
            free_water_units={};

            queryStr = sprintf('select to_char(observation_date, ''DD-MON-YYYY''), to_number(observations.water_amount), observations.water_unit FROM observations,subjects WHERE observations.subject_uin=subjects.uin AND water_amount is not null AND subjects.display_uin=''%s'' order by observation_date', subject_id);
            data = query(conn, queryStr);
            if ~isempty(data)
                dates=data(:,1);
                free_water_amounts=data(:,2);
                free_water_units=data(:,3);
            end

            dates=datenum(dates);
            free_water_amounts=cell2mat(free_water_amounts);

        end % end function
        
        function heats=getHeats(conn)
            heats = {};
            selectHeatQuery = ...
                'SELECT name, red_value, green_value, blue_value FROM heats ORDER BY calchue(red_value,green_value,blue_value)'; 

            results=query(conn,selectHeatQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                heats = cell(numRecords,1);
                for i=1:numRecords
                    h = [];
                    h.name = results{i,1};
                    h.red = results{i,2};
                    h.green = results{i,3};
                    h.blue = results{i,4};
                    heats{i} = h;
                end
            end
        end
        
        function path = getPermanentStorePathBySubject(conn, subjectID)
            % retreives the store_path (permanent store path) field from the subjects table given the display_uin
            % returns the result as a 1x1 cell array (holding a char array)

            getPathQuery = sprintf('select store_path from subjects where display_uin=''%s''', subjectID);

            path=query(conn,getPathQuery);
            if isempty(path{1})
                error('could not find permanent store path for this subject %s', subjectID);
            end


        end %end function

        function rrs=getRacksAndRoomsFromServerName(conn, server_name)
            rrs = {};
            selectRackIDQuery = ...
                sprintf('SELECT DISTINCT rack_id, room from RACKS, STATIONS, RATRIXSERVERS where racks.uin=stations.rack_uin AND stations.server_uin=ratrixservers.uin AND ratrixservers.name=''%s'' order by rack_id', server_name); 

            results=query(conn,selectRackIDQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                rrs = cell(numRecords,1);
                for i=1:numRecords
                    a = [];
                    a.rackID = results{i,1};
                    a.room = results{i,2};
                    rrs{i} = a;
                end
            end
        end
        
        function servers=getServers(conn)
            servers = {};
            selectServerQuery = ...
                'SELECT address, name from ratrixservers ORDER BY name'; 

            results=query(conn,selectServerQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                servers = cell(numRecords,1);
                for i=1:numRecords
                    s = [];
                    s.address = results{i,1};
                    s.server_name = results{i,2};
                    servers{i} = s;
                end
            end
        end
        
        function station=getStation(conn,rack_id,station_id)
            station = [];
            selectStationQuery = ...
                sprintf('SELECT mac, station_id,rack_id,row_num,col_num,ratrixservers.address FROM stations,racks,ratrixservers WHERE stations.rack_uin=racks.uin AND stations.server_uin=ratrixservers.uin AND rack_id=%d AND station_id=''%s'' ORDER BY rack_id,station_id',rack_id,station_id); 

            results=query(conn,selectStationQuery);

            if ~isempty(results)
                numRecords=size(results,1);

                if numRecords ~= 1
                    error('Only one record expected when asking for a station given a rack and station id')
                end

                s.mac = results{1,1};
                s.station_id = results{1,2};
                s.rack_id = results{1,3};
                s.row = results{1,4};
                s.col = results{1,5};
                s.server = results{1,6};
                station = s;
            end
        end
        
        function station=getStationFromMac(conn,mac)
            station = [];
            selectStationQuery = ...
                sprintf('SELECT mac, station_id,rack_id,row_num,col_num,ratrixservers.address FROM stations,racks,ratrixservers WHERE stations.rack_uin=racks.uin AND stations.server_uin=ratrixservers.uin AND mac=''%s'' ORDER BY rack_id,station_id',mac); 

            results=query(conn,selectStationQuery);

            if ~isempty(results)
                numRecords=size(results,1);

                if numRecords ~= 1
                    error('Only one record expected when asking for a station given a mac')
                end

                s.mac = results{1,1};
                s.station_id = results{1,2};
                s.rack_id = results{1,3};
                s.row = results{1,4};
                s.col = results{1,5};
                s.server = results{1,6};
                station = s;
            end
        end

        function stations=getStations(conn)
            stations = {};
            selectStationQuery = ...
                'SELECT mac, station_id,rack_id,row_num,col_num,ratrixservers.address FROM stations,racks,ratrixservers WHERE stations.rack_uin=racks.uin AND stations.server_uin=ratrixservers.uin ORDER BY rack_id,station_id'; 

            results=query(conn,selectStationQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                stations = cell(numRecords,1);
                for i=1:numRecords
                    s = [];
                    s.mac = results{i,1};
                    s.station_id = results{i,2};
                    s.rack_id = results{i,3};
                    s.row = results{i,4};
                    s.col = results{i,5};
                    s.server = results{i,6};
                    stations{i} = s;
                end
            end
        end

        function stations=getStationsByRoom(conn)
            stations = {};
            selectStationQuery = ...
                sprintf('SELECT mac, station_id,rack_id,row_num,col_num,ratrixservers.address FROM stations,racks,ratrixservers WHERE stations.rack_uin=racks.uin AND stations.server_uin=ratrixservers.uin ORDER BY room,rack_id,station_id'); 

            results=query(conn,selectStationQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                stations = cell(numRecords,1);
                for i=1:numRecords
                    s = [];
                    s.mac = results{i,1};
                    s.station_id = results{i,2};
                    s.rack_id = results{i,3};
                    s.row = results{i,4};
                    s.col = results{i,5};
                    s.server = results{i,6};
                    stations{i} = s;
                end
            end
        end
        
        function stations=getStationsForServer(conn,server_name)
            stations = {};
            selectStationQuery = ...
                sprintf('SELECT mac, station_id,rack_id,row_num,col_num,ratrixservers.address FROM stations,racks,ratrixservers WHERE stations.rack_uin=racks.uin AND stations.server_uin=ratrixservers.uin AND ratrixservers.name=''%s'' ORDER BY rack_id,station_id',server_name); 

            results=query(conn,selectStationQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                stations = cell(numRecords,1);
                for i=1:numRecords
                    s = [];
                    s.mac = results{i,1};
                    s.station_id = results{i,2};
                    s.rack_id = results{i,3};
                    s.row = results{i,4};
                    s.col = results{i,5};
                    s.server = results{i,6};
                    stations{i} = s;
                end
            end
        end
        
        function stations=getStationsOnRack(conn,rack)
            stations = {};
            selectStationQuery = ...
                sprintf('SELECT mac, station_id,rack_id,row_num,col_num,ratrixservers.address FROM stations,racks,ratrixservers WHERE stations.rack_uin=racks.uin AND stations.server_uin=ratrixservers.uin AND rack_id=%d ORDER BY rack_id,station_id',rack); 

            results=query(conn,selectStationQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                stations = cell(numRecords,1);
                for i=1:numRecords
                    s = [];
                    s.mac = results{i,1};
                    s.station_id = results{i,2};
                    s.rack_id = results{i,3};
                    s.row = results{i,4};
                    s.col = results{i,5};
                    s.server = results{i,6};
                    stations{i} = s;
                end
            end
        end

        function s=getSubject(conn,id)
            s = [];
            selectSubjectQueryFormat = ...
                ['SELECT SUBJECTTYPES.NAME,STRAINS.NAME,GENDER,SUPPLIERS.NAME,' ...
                '(CASE WHEN LITTER_ID IS NULL THEN ''UNKNOWN'' ELSE LITTER_ID END),' ...
                'DOB,ENTERED_LAB,EXITED_LAB,EXITSTATUS,USERNAME, TEST_SUBJECT ' ...
                'FROM SUBJECTS LEFT JOIN RESEARCHERS ON SUBJECTS.OWNER_UIN=RESEARCHERS.UIN,' ...
                'STRAINS, SUBJECTTYPES, SUPPLIERS ' ...
                'WHERE SUBJECTS.STRAIN_UIN=STRAINS.UIN AND SUBJECTS.SUPPLIER_UIN=SUPPLIERS.UIN AND ' ...
                'STRAINS.SUBJECTTYPE_UIN=SUBJECTTYPES.UIN AND ' ...
                'LOWER(SUBJECTS.DISPLAY_UIN) = LOWER(''%s'')'];


            selectSubjectQuery = sprintf(selectSubjectQueryFormat,id);
            results=query(conn,selectSubjectQuery);
            if ~isempty(results) && size(results,1) == 1
                numRecords=size(results,1);
                numCols = size(results,2);
                if numRecords ~= 1
                    error('Only one record expected when asking for a subject given an id')
                end
                if numCols ~= 11
                    error('For subject query 11 columns expected to be returned')
                end
                s.id = lower(id);
                s.species = results{1,1};
                s.strain = results{1,2};
                s.gender = results{1,3};
                s.supplier = results{1,4};
                s.litter = results{1,5};
                s.dob = results{1,6};
                s.date_entered = results{1,7};
                s.date_exited = results{1,8};
                s.exit_status = results{1,9};
                s.owner = results{1,10};
                s.test = boolean(results{1,11});
            else
                warning(['Queried for nonexistent subject ' id])
            end
        end

        function subjectIDs = getSubjectIDsFromServer(conn, server_name)
            % This function grabs all subjectIDs (display_uin) that belong to a given server_name from the Oracle DB.
            % Returns a cell array of subjectIDs.

            subjectIDs={};
            getSubIDsQuery = sprintf('select LOWER(display_uin) from subjects, heat_assignments, stations, ratrixservers where subjects.uin=heat_assignments.subject_uin AND stations.server_uin=ratrixservers.uin AND ratrixservers.name=''%s'' AND heat_assignments.station_uin=stations.uin', server_name);
            results=query(conn,getSubIDsQuery);

            if ~isempty(results)
                numRecords=size(results,1);
                subjectIDs = cell(numRecords,1);
                for i=1:numRecords
                    s = [];
                    s.subjectID = results{i,1};
                    subjectIDs{i} = s.subjectID;
                end
            end


        end % end function

        function s=getSubjects(conn,ids)
            s = [];
            selectSubjectQueryFormat = ...
                ['SELECT SUBJECTTYPES.NAME,STRAINS.NAME,GENDER,SUPPLIERS.NAME,' ...
                '(CASE WHEN LITTER_ID IS NULL THEN ''UNKNOWN'' ELSE LITTER_ID END),' ...
                'DOB,ENTERED_LAB,EXITED_LAB,EXITSTATUS,USERNAME, TEST_SUBJECT ' ...
                'FROM SUBJECTS LEFT JOIN RESEARCHERS ON SUBJECTS.OWNER_UIN=RESEARCHERS.UIN,' ...
                'STRAINS, SUBJECTTYPES, SUPPLIERS ' ...
                'WHERE SUBJECTS.STRAIN_UIN=STRAINS.UIN AND SUBJECTS.SUPPLIER_UIN=SUPPLIERS.UIN AND ' ...
                'STRAINS.SUBJECTTYPE_UIN=SUBJECTTYPES.UIN AND ' ...
                'LOWER(SUBJECTS.DISPLAY_UIN) = LOWER(''%s'')'];

            for i=1:length(ids)
                selectSubjectQuery = sprintf(selectSubjectQueryFormat,ids{i});
                results=query(conn,selectSubjectQuery);
                if ~isempty(results)
                    numRecords=size(results,1);
                    numCols = size(results,2);
                    if numRecords ~= 1
                        error('Only one record expected when asking for a subject given an id')
                    end
                    if numCols ~= 11
                        error('For subject query 11 columns expected to be returned')
                    end
                    s(i).id = lower(ids{i});
                    s(i).species = results{1,1};
                    s(i).strain = results{1,2};
                    s(i).gender = results{1,3};
                    s(i).supplier = results{1,4};
                    s(i).litter = results{1,5};
                    s(i).dob = results{1,6};
                    s(i).date_entered = results{1,7};
                    s(i).date_exited = results{1,8};
                    s(i).exit_status = results{1,9};
                    s(i).owner = results{1,10};
                    s(i).test = boolean(results{1,11});
                else
                    warning(['Queried for nonexistent subject ' ids{i}])
                end
            end
        end

        function results=getSurgeryFields(conn,subjectID)

            str=sprintf('select anchor_ap,anchor_ml,anchor_z,bregma_ap,bregma_ml,bregma_z from subjects where display_uin=''%s''',subjectID);
            r=query(conn,str);

            results=[];
            if all(size(r)==[1 6])
                % replace emptys with nans
                for i=1:length(r)
                    if isempty(r{i})
                        r{i}=nan;
                    end
                end
                results.anchorAP=r{1};
                results.anchorML=r{2};
                results.anchorZ=r{3};
                results.bregmaAP=r{4};
                results.bregmaML=r{5};
                results.bregmaZ=r{6};
            else
            %     warning('failed to get surgery fields');
            end

        end
        
        function files = getTrialRecordFiles(conn,subject_id)
            files={};

            % Get the hidden subject uin for this id
            subjectquery=sprintf('select subjects.uin from subjects where LOWER(display_uin)=LOWER(''%s'') ',subject_id);
            subjectdata=query(conn,subjectquery);
            if isempty(subjectdata)
                subject_id
                warning('Subject is not defined in subject table')
                return
            else
                subject_uin=subjectdata{1,1};
            end

            % Get the file names
            % This is the SQL query where all the real work is done
            queryStr=sprintf('select file_name from trialrecords where subject_uin = %d ORDER BY file_name',subject_uin);

            data = query(conn,queryStr);
            if ~isempty(data)
                files=data(:,1);
            else
                subject_id
                warning('No files listed for subject');
            end
        end

        function results=listAllCalibrationEntries(conn,mac)
            % list all calibration entries for a given MAC

            str=sprintf('select to_char(timestamp,''mm-dd-yyyy hh24:mi''), comm, calibrationstring from MONITOR_CALIBRATION where station_mac=''%s''',mac);
            results=query(conn,str);


        end % end function
        
        function records = query(conn,queryString)

            stmt = conn.conn.createStatement();
            records = {};
            curRow = 0;
            failed = false;
            try
                rs=stmt.executeQuery(queryString);
                try
                    while rs.next()
                        curRow = curRow + 1;
                        metaData = rs.getMetaData();
                        numColumns = metaData.getColumnCount();
                        for i=1:numColumns
                            c = rs.getObject(i);
                            switch(class(c))
                                case 'java.math.BigDecimal'
                                    convC = c.doubleValue();
                                case 'java.sql.Date'
                                    % java.sql.Date is defined as 
                                    % year - CalendarYear - 1900
                                    % month - (0 to 11)
                                    % day - (1 to 31)
                                    convC = datenum(c.getYear()+1900,c.getMonth()+1,c.getDay());%,c.getHours(),c.getMinutes(),c.getSeconds());
                                case 'double'
                                    convC = c;
                                case 'char'
                                    convC = c;
                                case 'oracle.sql.BLOB'
                                    convC=c;
                                    % return the oracle.sql.BLOB object and let getCLUT (or whatever the retrieval function) decode the object
            %                         convC={};
            %                         stream=c.getBinaryStream;
            %                         nextbyte=stream.read();
            %                         while nextbyte~=-1
            %                             convC=[convC nextbyte];
            %                             nextbyte=stream.read();
            %                         end
                                otherwise
                                    'Cannot handle'
                                    class(c)
                                    error('Cannot handle object type')
                            end
                            records{curRow,i}=convC;
                        end
                    end
                    rs.close();
                catch ex
                    rs.close();
                    disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                    failed = true;
                end
                stmt.close();
            catch ex
                stmt.close();
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                failed = true;
            end
            % Make sure the statement and recordset are closed, now we can error if needed
            if failed
                rethrow(ex)
            end
        end
       
        function success=reconcileTrialRecordFileNames(conn, subID, permStore, doUpdate, verbose, doWarn)
            % VALIDATED 6/24/09 fli
            %   useful in conjunction with fixTrialRecordRanges if a rat is accidentally run under the wrong subject
            if ~exist('subID','var') || isempty(subID)
                error('please enter valid subID');
            end

            if ~exist('permStore','var') || isempty(permStore)
                error('please enter valid permStore');
            end

            if ~exist('verbose','var') || isempty(verbose)
                verbose = true;
            elseif ~islogical(verbose) || verbose~=0
                verbose = true;
            end

            if ~exist('doUpdate','var') || isempty(doUpdate)
                doUpdate = false;
            end

            if ~exist('doWarn','var') || isempty(doWarn)
                doWarn = true;
            end

            resp=getSubject(conn,subID);
            if isempty(resp)
                subID
                warning('Skipping directory, does not exist in subject list');
                return
            end

            inDB = getTrialRecordFiles(conn, subID);


            [vHF ranges] = getTrialRecordFiles(permStore,doWarn);

            inFS = {};
            for j = 1:length(vHF)
                [subdir name ext] = fileparts(vHF{j});
                inFS{end+1} = [name ext];
            end

            inDBNotInFS = setdiff(inDB,inFS);
            inFSNotInDB = setdiff(inFS,inDB);
            matches = length(inDB)-length(inDBNotInFS);

            fprintf('checking subject %s: ',subID);

            if matches~=length(inFS)-length(inFSNotInDB)
                error('bad set math')
            end

            fprintf('%d good matches\n',matches);

            for j = 1:length(inDBNotInFS)
                if doUpdate
                    removeTrialRecordFile(conn,subID,inDBNotInFS{j});
                    str=' (removed from DB)';
                else
                    str='';
                end
                if verbose
                    fprintf('\tin DB but not FS: %s%s\n',inDBNotInFS{j},str);
                end
            end

            for j = 1:length(inFSNotInDB)
                if doUpdate
                    addTrialRecordFile(conn,subID,inFSNotInDB{j});
                    str=' (added to DB)';
                else
                    str='';
                end
                if verbose
                    fprintf('\tin FS but not DB: %s%s\n',inFSNotInDB{j},str);
                end
            end

            if isempty(inDBNotInFS) && isempty(inFSNotInDB)
                success=true;
            elseif doUpdate
                success=reconcileTrialRecordFileNames(conn, subID, permStore, false, verbose, doWarn);
                if ~success
                    error('failed to reconcile');
                end
            else
                success=false;
            end
        end
        
        function removeTrialRecordFile(conn,subject_id,file_name)

            % Get the hidden subject uin for this id
            subjectquery=sprintf('select subjects.uin from subjects where UPPER(display_uin)=UPPER(''%s'') ',subject_id);
            subjectdata=query(conn,subjectquery);
            if isempty(subjectdata)
                subject_id
                file_name
                error('File for unknown subject was attempted to be removed')
            else
                subject_uin=subjectdata{1,1};
            end

            % Remove the file name for the given subject
            % This is the SQL query where all the real work is done
            deleteStr=sprintf('delete from trialrecords where subject_uin=%d and file_name=''%s''',subject_uin,file_name);

            rowCount = exec(conn,deleteStr);
        end

        function updateCalibrationData(conn,mac,timestamp,newdata)
            % this function updates the BLOB object associated with the given mac address and timestamp
            % empties the existing BLOB and replaces it with newdata, a vector of uint8s
            % the given mac/timestamp should ALWAYS exist, because we never call this directly
            % this is a function that gets called by addCLUTToOracle, which does an INSERT first, then a select for update


            % first remove the existing BLOB
            str=sprintf('update MONITOR_CALIBRATION set data=empty_blob() where station_mac=''%s'' and timestamp=to_date(''%s'',''mm-dd-yyyy hh24:mi'')',mac,timestamp);
            r=exec(conn,str);

            % now select the BLOB for updating
            str=sprintf('select data from MONITOR_CALIBRATION where station_mac=''%s'' and timestamp=to_date(''%s'',''mm-dd-yyyy hh24:mi'') FOR UPDATE',mac,timestamp);
            % str=sprintf('select data from CLUTS where station_mac=''%s''',mac);
            results=query(conn,str);
            blob=results{1};
            % blob.length


            if strcmp(class(newdata),'uint8')
                blob.putBytes(length(blob)+1,newdata);
            %     blob.length
            else
                error('newdata must be uint8');
            end

            %5/12/09
            % for some reason, the executeUpdate statement will hang if you have SQL developer open.
            % i think this has to do with access issues to BLOB entries (when you close SQL developer, the statement finishes executing).
            % happens if you've used the CLUTs table in oracle (for example, to delete an entry).
            % i think for now it is okay to just assume that sql developer is not accessing CLUTS, but what about when calibrateMonitor 
            % automaticallys calls updateCLUT?
            str=sprintf('update MONITOR_CALIBRATION set data=? where station_mac=''%s'' and timestamp=to_date(''%s'',''mm-dd-yyyy hh24:mi'')',mac,timestamp);
            ps = conn.conn.prepareStatement(str);
            ps.setBlob(1,blob);
            ps.executeUpdate();
            ps.close();

        end % end function
        
    end
    
end


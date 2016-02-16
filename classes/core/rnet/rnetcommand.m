classdef rnetcommand
    
    properties
    end
    
    methods
        function c = rnetcommand(varargin)

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    error('Default command not supported');
                case 1
                    % if single argument of this class type, return it
                    if isa(varargin{1},'rnetcommand')
                        c = varargin{1};
                        return;
                    elseif isa(varargin{1},'rlab.net.RlabNetworkCommand')
                        c.javaCommand = varargin{1};
                        tmp = c.javaCommand.sendingNode.toString();
                        sendingNodeId = tmp.toCharArray();
                        tmp = c.javaCommand.receivingNode.toString();
                        receivingNodeId = tmp.toCharArray();
                        uid = c.javaCommand.getUID();
                    else
                        fprintf('Unknown class of cmd\n');
                        disp(class(varargin{1}));
                        error('Input argument is not a rnetcommand object');
                    end;
                case 5
                    uid = varargin{1};
                    sendingNodeId = varargin{2};
                    receivingNodeId = varargin{3};
                    priority = varargin{4};
                    command = varargin{5};
                    arguments = {};
                case 6
                    uid = varargin{1};
                    sendingNodeId = varargin{2};
                    receivingNodeId = varargin{3};
                    priority = varargin{4};
                    command = varargin{5};
                    arguments = varargin{6};
                otherwise
                    error('Wrong number of input arguments');
            end


            if nargin >1
                sNode = RlabNetworkNodeIdent(sendingNodeId);
                rNode = RlabNetworkNodeIdent(receivingNodeId);
                c.javaCommand = RlabNetworkCommand(uid,sNode,rNode,priority,command,arguments);
            end
            jc = c.javaCommand;
            c.uid = uid;
            c.sendingNodeId = sendingNodeId;
            c.receivingNodeId = receivingNodeId;
            c.priority = jc.priority;
            c.command = jc.command;
            c.arguments = jc.getArguments();
            if nargin > 0
                c = class(c,'rnetcommand');
            end
        end
        
        function args = getArguments(c)
            args = {};
            %c.arguments
            if ~isempty(c.arguments)
                if ~isa(c.arguments,'java.lang.Object[]')
                    error('Arguments should always be empty or java.lang.Object[]');
                end
                for i=1:length(c.arguments)
                    arg = c.arguments(i);
                    if isa(arg,'int8')
                        tmp = mdeserialize(arg); %this is old and broken usage of a discontinued undocumented matlab function
                        arg = tmp;
                    elseif isa(arg,'java.util.Vector')
                        % Vectors translate to cell arrays
                        cellArg = {};
                        vec = arg;
                        for j=1:vec.size()
                            argj = vec.elementAt(j-1);
                            if isa(argj,'java.lang.String')
                                argj = argj.toCharArray();
                            end
                            cellArg{j}=argj;
                        end
                        arg = cellArg;
                    elseif isa(arg,'java.lang.Boolean[]')
                        % Arrays of booleans translate into 1xn logicals
                        mArg = logical([]);
                        for j=1:arg.length
                            mArg(j) = arg(j).booleanValue;
                        end
                        arg = mArg;
                    elseif isa(arg,'java.lang.Integer[]')
                        % Arrays of doubles translate into 1xn doubles
                        mArg = [];
                        for j=1:arg.length
                            mArg(j) = int32(arg(j));
                        end
                        arg = mArg;
                    elseif isa(arg,'java.lang.Double[]')
                        % Arrays of doubles translate into 1xn doubles
                        mArg = [];
                        for j=1:arg.length
                            mArg(j) = double(arg(j));
                        end
                        arg = mArg;
                    elseif isa(arg,'java.lang.Integer') || isinteger(arg)
                        arg = int32(arg);
                    elseif isa(arg,'java.lang.Double') || isnumeric(arg)
                        arg = double(arg);
                    elseif isa(arg,'java.lang.Boolean')
                        arg = arg.booleanValue;
                    elseif islogical(arg)
                        arg = logical(arg);
                    elseif ischar(arg)
                        % Nothing to do
                    elseif isa(arg,'java.lang.String')
                        arg = arg.toCharArray();
                    elseif isa(arg,'java.io.File')
                        str = arg.getPath();
                        fpath = str.toCharArray();
                        fprintf('Reading command argument .mat file in\n');
                        load(fpath,'tmp');
                        arg = tmp;
                    else
                        fprintf('Unable to handle this argument type %s in getArguments()\n',class(arg));
                        error('Unable to handle type');
                    end
                    args{i} = arg;
                end
            end
        end
        
        function ident = getClientIdent(c)
            ident = c.javaCommand.client;
        end
        
        function cmd = getCommand(c)
            cmd = c.command;
        end
        
        function id = getId(c)
            id = c.id;
        end
        
        function obj = getObject(cmd,argument)
            try
                tmp = arguments;
                fName = ['.' filesep 'tmp-java-matlab-var-transfer' ];
                fd=fopen(fName,'w+');
                fwrite(fd,argument.toCharArray());
                frewind(fd);
                load(fd,'tmp');
                fclose(fd);
            catch ex
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                error('Unable to handle given argument %s',class(arguments{i}));
            end
        end
        
        function priority = getPriority(c)
            priority = c.priority;
        end
        
        function id = getReceivingNode(c)
            id = c.javaCommand.receivingNode;
        end
        
        function id = getSendingNode(c)
            id = c.javaCommand.sendingNode;
        end
        
        function uid = getUID(c)
            uid = c.uid;
        end
        
        function str = toString(c)
            tmp = c.javaCommand.toString();
            str = tmp.toCharArray();
        end
      
        
    end
    
end


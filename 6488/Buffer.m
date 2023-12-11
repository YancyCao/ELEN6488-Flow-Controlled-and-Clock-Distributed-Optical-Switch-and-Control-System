classdef Buffer

    properties

        BufferSize
        Block = cell(24,4);
        MostOccupiedBlock = dictionary();    
        % key : source ToR of most occupied block  ;  
        % value : N * 3 matrix  --  value[:,1] -> source host ; value[:,2] -> Ethernet frame ; value[:,3] -> destination host
        SourceHosts = cell(24,1);
        SourceToR
        TimeStamp 
        IntraRackData     %  HostNumber * 1 cell
        BufferPacketLossRecord = []
        
    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = Buffer(varargin)     % varargin{1} : number of hosts per ToR ; varargin{2} : number of ToRs 

            if ~isempty(varargin) 
                obj.Block = cell(varargin{1},varargin{2});
                obj.Block = cellfun(@(b) [0,0,0],obj.Block,'UniformOutput', false);
                obj.SourceHosts = cell(varargin{1},1);
            end

        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = ProcessHosts(obj,host,varargin)      % varargin : TimeStamp
            Source_ToR = host.SourceToR;

            obj.SourceToR = Source_ToR; 

            if ~isempty(varargin) 
                obj.TimeStamp = varargin{1};
            end

            destination_ToR = host.DestinationToR;
            destination_host = host.DestinationHost;
            FrameValue = host.EthernetFrames;

            if ~(isempty(destination_ToR) & isempty(destination_host))

                obj.Block{destination_host,destination_ToR} = [host.SourceHost,FrameValue,destination_host;obj.Block{destination_host,destination_ToR}];
                obj.SourceHosts{host.SourceHost} = [host,obj.SourceHosts{host.SourceHost}];

            end

            

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = FindMostOccupiedBlock(obj)

            block = obj.Block;
            block = cellfun(@(b) b(:,2),block,'UniformOutput', false);    % extract the EthernetFrame value

            cellsum = cellfun(@sum,block);
            cellsum(:,obj.SourceToR) = 0;          % eliminate the intra-ract data
            blocksum = sum(cellsum,"omitnan");
            [~,maxindex] = max(blocksum);

            blockselected = cell2mat(obj.Block(:,maxindex));
            tosend = [];
            for i = 1 : length(blockselected(:,1))
                if blockselected(i,:) ~= [0,0,0]
                    tosend = [tosend;blockselected(i,:)];
                end
            end

            if ~isempty(tosend)
                obj.MostOccupiedBlock{maxindex} = tosend;
            end
               
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = IntraRackTraffic(obj)

            block = obj.Block;
            samesourceblock = cell2mat(block(:,obj.SourceToR));
            tosend = [];

            for i = 1 : length(samesourceblock(:,1))

                if samesourceblock(i,:) ~= [0,0,0]
                    tosend = [tosend;samesourceblock(i,:)];
                end

            end

            obj.IntraRackData = tosend;%block(:,obj.SourceToR);

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = BufferStackCheck(obj,varargin)

            if ~isempty(varargin)
                obj.BufferSize = cell2mat(varargin);
            end

            

            block = obj.Block;
            block = cellfun(@(b) b(:,2),block,'UniformOutput', false);    % extract the EthernetFrame value

            cellsum = cellfun(@sum,block);
            totalsum = sum(cellsum,'all');

            bufferpacketloss = 0;

            while totalsum > obj.BufferSize

                disp(['Buffer of ToR ',num2str(obj.SourceToR),' Have Stack Overflow'])

                minimum = min(nonzeros(cellsum),[],'all');
                minindex = find(cellsum == minimum);
                cellsum(minindex(1)) = 0;
                obj.Block{minindex(1)} = [0,0,0];

                totalsum = sum(cellsum,'all');

                bufferpacketloss = bufferpacketloss + 1;

            end
            
            obj.BufferPacketLossRecord = [obj.BufferPacketLossRecord;bufferpacketloss];

            
        end


    end


end
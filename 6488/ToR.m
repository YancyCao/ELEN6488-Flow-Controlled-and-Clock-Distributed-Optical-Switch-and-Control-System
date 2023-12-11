classdef ToR

    properties

        SourceToR
        LabelPacket = dictionary('DestinationToR', NaN,'SourceToR', NaN, 'Priority', NaN);        %Priority : ToR_1 > ToR_2 > ToR_3...
        DataPacket = cell(1,3)
        BufferToSend 
        BufferRecieved  
        ACKState = false
        TimeStamp

    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = ToR(BufferToSend)
            SerialNumber = BufferToSend.SourceToR;
            obj.SourceToR = SerialNumber;
            obj.BufferToSend = BufferToSend;
            blocksize = size(BufferToSend.Block);
            obj.BufferRecieved = Buffer(blocksize(1),blocksize(2));
            obj.BufferRecieved.SourceToR = SerialNumber;
            obj.LabelPacket('Priority') = SerialNumber;
            obj.LabelPacket('SourceToR') = SerialNumber;

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = DataPacketAggregator(obj,varargin)
            
            buffer = obj.BufferToSend;
            MostOccupiedBlock = buffer.MostOccupiedBlock;

            obj.DataPacket = {NaN,obj.SourceToR,NaN};
            
            if isConfigured(MostOccupiedBlock)

                destinationToR = keys(MostOccupiedBlock);   % integer from [1,2,3,4]
                EthernetFrames = MostOccupiedBlock{destinationToR};   % N * 3 matrix
    
                if ~isempty(varargin)
                    obj.DataPacket{1} = varargin;
                    obj.TimeStamp = varargin;
                end
    
                obj.DataPacket{2} = [obj.SourceToR,destinationToR];
    
                obj.DataPacket{3} = EthernetFrames;   % N *3 matrix

            end
         
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = LabelPacketAggregator(obj)

            buffer = obj.BufferToSend;
            MostOccupiedBlock = buffer.MostOccupiedBlock;

            if isConfigured(MostOccupiedBlock)
                destinationToR = keys(MostOccupiedBlock);
    
                obj.LabelPacket('DestinationToR') = destinationToR;

            else 
                
                obj.LabelPacket('DestinationToR') = Inf;
           
            end

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = BufferUpdate(obj,intertrafficdata)%},acksignal)                

            % intra-rack triffic
            intrarackdata = obj.BufferToSend.IntraRackData;      %  N * 3 matrix : [SourceHost , EthernetFrame , DestinationHost]

            if ~isempty(intrarackdata)
                for i = 1 : length(intrarackdata(:,1))

                    obj.BufferRecieved.Block{intrarackdata(i,3),obj.SourceToR} = [intrarackdata(i,:) ;obj.BufferRecieved.Block{i,obj.SourceToR}];

                end

                for m = 1 : length(obj.BufferToSend.Block(:,obj.SourceToR))

                    obj.BufferToSend.Block{m,obj.SourceToR} = [0,0,0];

                end
            end

            % inter-rack traffic
            datapacketreceived = intertrafficdata{obj.SourceToR};
            if ~isempty(datapacketreceived)

                datapacketsize = size(datapacketreceived);

                for j = 1 : datapacketsize(1)

                    datapacketreceived_j = datapacketreceived(j,:);

                    sourceToR = datapacketreceived_j{2}(1);
                    EthernetFrames = datapacketreceived_j{3};     % N * 3 matrix

                    for i = 1: length(EthernetFrames(:,1)) 

                        obj.BufferRecieved.Block{EthernetFrames(i,3),sourceToR} = [EthernetFrames(i,:) ; obj.BufferRecieved.Block{EthernetFrames(i,3),sourceToR}];

                    end

                end

            end
            
            

            % update buffer based on ACKState
            %obj.ACKState = acksignal;

            if obj.ACKState

                for k = 1 : length(obj.BufferToSend.Block(:,keys(obj.BufferToSend.MostOccupiedBlock)))

                    obj.BufferToSend.Block{k,keys(obj.BufferToSend.MostOccupiedBlock)} = [0,0,0];
                
                end

                %obj.BufferToSend.Block{:,keys(obj.BufferToSend.MostOccupiedBlock)} = [0,0,0];
                
                obj.ACKState = false;

            end
            obj.BufferToSend.MostOccupiedBlock = dictionary();
            

          
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = ACKStateUpdate(obj,acksignal)

            obj.ACKState = acksignal;

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    end



end
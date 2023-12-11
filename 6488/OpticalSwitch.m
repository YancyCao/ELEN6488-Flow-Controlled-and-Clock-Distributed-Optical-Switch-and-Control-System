classdef OpticalSwitch

    properties

        DataPacketList     % 1 *  ToRNumber cell          before InterRackTraffic
        InterTrafficData   % 1 * (ToRNumber + 1) cell     after InterRackTraffic
        ToRNumber

    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = OpticalSwitch(ToRNumber)
            obj.DataPacketList = cell(1,ToRNumber);
            obj.InterTrafficData = cell(1,ToRNumber+1);
            obj.ToRNumber = ToRNumber;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = ProcessDataPackets(obj,datapacket)     % every ToR can noly send one datapacket to optical switch

            SourceToR = datapacket{2}(1);
            obj.DataPacketList{SourceToR} = datapacket;

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = InterRackTraffic(obj,opticalconfiguration)   % ToRNumber * (ToRNumber + 1) matrix

            oc = opticalconfiguration;

            for i = 1 : obj.ToRNumber

                if ~isempty(find(oc(:,i) ~= Inf))      % data packet with destination ToR = i is allowed

                    [~,minindex] = min(oc(:,i));       % minindex = source ToR of the data packet that is allowed

                    obj.InterTrafficData{i} = obj.DataPacketList{minindex};

                end

            end

            restcolumn = oc(:,end);

            for i = 1 : obj.ToRNumber

                if restcolumn(i) ~= Inf

                    obj.InterTrafficData{end} = [obj.DataPacketList{i};obj.InterTrafficData{end}];

                end
                 
            end
            

        end

        
    end


end
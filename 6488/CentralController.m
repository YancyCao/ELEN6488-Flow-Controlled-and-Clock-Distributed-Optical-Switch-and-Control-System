classdef CentralController

    properties

        LabelPacketList        % ToRNumber * ToRNumber matrix     Row : SourceToR      Column : DestinationToR
        OpticalConfiguration   % ToRNumber * (ToRNumber + 1) matrix     last row for rest ToR configuration
        ACKSignals             % ToRNumber * ToRNumber matrix
        ToRNumber
        TimeStamp

    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = CentralController(ToRNumber)

            obj.LabelPacketList = Inf(ToRNumber,ToRNumber);     
            obj.OpticalConfiguration = Inf(ToRNumber,ToRNumber);    
            obj.ACKSignals = boolean(zeros(ToRNumber,ToRNumber));
            obj.ToRNumber = ToRNumber;

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = PacketContention(obj,labelpacket)

            DestinationToR = labelpacket('DestinationToR');
            SourceToR = labelpacket('SourceToR');

            if DestinationToR ~= Inf
                obj.LabelPacketList(SourceToR,DestinationToR) = labelpacket('Priority');
            end

            

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = OpticalConfigurationGenaration(obj)

            pc = obj.LabelPacketList;

            restcolumn = zeros(obj.ToRNumber,1);

            for i = 1 : obj.ToRNumber

                column = pc(:,i);
                minimum = min(column);
                restcolumn = restcolumn + (column ~= minimum & column ~= Inf) .* [1:obj.ToRNumber]';
                column(column ~= minimum) = Inf;       
                obj.OpticalConfiguration(:,i) = column;

            end

            restcolumn(restcolumn == 0) = Inf;
            obj.OpticalConfiguration = [obj.OpticalConfiguration,restcolumn];


        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = ACKSignalGeneration(obj)

            oc = obj.OpticalConfiguration(:,1:obj.ToRNumber);

            acksignals = [];

            for i = 1 : length(oc(:,1))

                acksignals = [acksignals,~isequal(oc(i,:),Inf(1,length(oc(:,1))))];

            end

            obj.ACKSignals = acksignals;

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        

    end

end
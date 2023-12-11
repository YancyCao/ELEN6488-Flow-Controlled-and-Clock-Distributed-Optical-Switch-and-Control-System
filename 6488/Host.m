classdef Host

    properties
        
        EthernetFrames

        DestinationToR 
        DestinationHost 

        SourceToR
        SourceHost 

        TimeStamp

    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = Host(Source_ToR , Source_Host , varargin)      % varargin{1} : DestinationToR  ;  varargin{2} : DestinationHost  varargin{3} : TimeStamp

            

            obj.SourceToR = Source_ToR;
            obj.SourceHost = Source_Host;

            if ~isempty(varargin)          
                obj.DestinationToR = varargin{1};
                obj.DestinationHost = varargin{2};
                obj.EthernetFrames = randi(128,1);
                %obj.TimeStamp = varargin{3};
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = DestinationAssignment(obj,DestinationToR,DestinationHost,varargin)

            obj.DestinationToR = DestinationToR;
            obj.DestinationHost = DestinationHost;
            obj.EthernetFrames = randi(128,1);

            if ~isempty(varargin)
                obj.TimeStamp = varargin{1};
            end

        end



    end


end
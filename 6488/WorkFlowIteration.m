function [New_ToR_list,New_ToR_rest,Optical_Configuration,ACKsignals] = WorkFlowIteration(ToR_list,ToR_rest,varargin)
import Host.*;
import Buffer.*;
import ToR.*;
import CentralController.*;
import OpticalSwitch.*;

ToRNumber = length(ToR_list);
HostNumber = length(ToR_list{1}.BufferToSend.Block(:,1));

if ~isempty(varargin)
    Time_offset = varargin;
end

T_tx = [];
T_rx = [];

for i  = 1 : ToRNumber

    % generate hosts
    SourceToRArray = i * ones(1,HostNumber);
    SourceHostsArray = randperm(HostNumber);

    hosts = arrayfun(@(m,n) Host(m,n), SourceToRArray, SourceHostsArray);

    HostsToSend = randi([0,HostNumber]);     %  number of hosts having Ehthernet Frame to forward
    DestinationToRArray = randi([1,ToRNumber],1,HostsToSend);
    DestinationHostsArray = randi([1,HostNumber],1,HostsToSend);

    for j = 1 : HostsToSend
        hosts(j) = hosts(j).DestinationAssignment(DestinationToRArray(j),DestinationHostsArray(j));
    end

    %buffer = ToR_list{i}.BufferToSend(HostNumber,ToRNumber);

    for m = 1 : HostNumber
        ToR_list{i}.BufferToSend = ToR_list{i}.BufferToSend.ProcessHosts(hosts(m));
    end

    ToR_list{i}.BufferToSend = ToR_list{i}.BufferToSend.BufferStackCheck();
    ToR_list{i}.BufferToSend = ToR_list{i}.BufferToSend.FindMostOccupiedBlock();

end

for i = 1 : ToRNumber

    T_tx = [T_tx,datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSSS')];

    ToR_list{i} = ToR_list{i}.DataPacketAggregator(T_tx(i));
    % DataPacket{2} = [obj.SourceToR,destinationToR];

    ToR_list{i} = ToR_list{i}.LabelPacketAggregator();

end

% intialize CentralController
Central_Controller = CentralController(ToRNumber);
Optical_Switch = OpticalSwitch(ToRNumber);

for i = 1 : ToRNumber

    Central_Controller = Central_Controller.PacketContention(ToR_list{i}.LabelPacket);

end

%{
for i = 1 : ToRNumber

    Optical_Switch = Optical_Switch.ProcessDataPackets(ToR_list{i}.DataPacket);
    

end
%}

PacketContention = Central_Controller.LabelPacketList

Central_Controller = Central_Controller.OpticalConfigurationGenaration();
Optical_Configuration = Central_Controller.OpticalConfiguration

Central_Controller = Central_Controller.ACKSignalGeneration();
ACKsignals = Central_Controller.ACKSignals

for i = 1 : ToRNumber

    ToR_list{i} = ToR_list{i}.ACKStateUpdate(ACKsignals(i));

    T_rx = [T_rx,datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSSS')];

    Optical_Switch = Optical_Switch.ProcessDataPackets(ToR_list{i}.DataPacket);

end

DataPacketList = Optical_Switch.DataPacketList

Optical_Switch = Optical_Switch.InterRackTraffic(Optical_Configuration);

InterTrafficData = Optical_Switch.InterTrafficData

for i = 1 : ToRNumber

    ToR_list{i}.BufferToSend = ToR_list{i}.BufferToSend.IntraRackTraffic();
    ToR_list{i} = ToR_list{i}.BufferUpdate(InterTrafficData);%,ACKsignals(i));

end

ToR_rest = ToR_rest.ACKStateUpdate(false);
ToR_rest = ToR_rest.BufferUpdate(InterTrafficData);%,false);

New_ToR_list = ToR_list;
New_ToR_rest = ToR_rest;
end
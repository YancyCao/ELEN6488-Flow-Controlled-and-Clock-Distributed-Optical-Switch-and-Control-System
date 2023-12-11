close all
clear all
clc

import Host.*;
import Buffer.*;
import ToR.*;
import CentralController.*;
import OpticalSwitch.*;


HostNumber = 24;
ToRNumber = 4;
ToRNumber_rest = 1;
DataPacketsRecord = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Generate hosts and Buffer for every working ToR 
tic

ToR_list = cell(1,ToRNumber);
buffersize = 8192;
buffersizearray = ones(1,ToRNumber) * buffersize;

for i  = 1 : ToRNumber

    % generate hosts
    SourceToRArray = i * ones(1,HostNumber);
    SourceHostsArray = randperm(HostNumber);

    hosts = arrayfun(@(m,n) Host(m,n), SourceToRArray, SourceHostsArray);

    HostsToSend = randi([0,HostNumber]);     %  number of hosts having Ehthernet Frame to forward
    DestinationToRArray = randi([1,ToRNumber],1,HostsToSend);
    DestinationHostsArray = randi([1,HostNumber],1,HostsToSend);

    for j = 1 : HostsToSend
        timestamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSSS');
        hosts(j) = hosts(j).DestinationAssignment(DestinationToRArray(j),DestinationHostsArray(j),timestamp);
    end

    % generate buffer
    buffer = Buffer(HostNumber,ToRNumber);

    for m = 1 : HostNumber
        buffer = buffer.ProcessHosts(hosts(m));
    end
    buffer.TimeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSSS');

    % assign buffer to ToR
    ToR_list{i} = ToR(buffer);
    ToR_list{i}.BufferToSend = ToR_list{i}.BufferToSend.BufferStackCheck(buffersizearray(i));
    ToR_list{i}.BufferToSend = ToR_list{i}.BufferToSend.FindMostOccupiedBlock();
    
end

% generate rest ToR
buffer_rest = Buffer(HostNumber,ToRNumber);
buffer_rest.SourceToR = 5;
ToR_rest = ToR(buffer_rest);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% generate data packets and label packets in every ToR

%Time_offset = zeros(1,ToRNumber);
T_tx = [];
T_rx = [];

for i = 1 : ToRNumber
    
    T_tx = [T_tx,datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSSS')];

    ToR_list{i} = ToR_list{i}.DataPacketAggregator(T_tx(i));
    % DataPacket{2} = [obj.SourceToR,destinationToR];

    ToR_list{i} = ToR_list{i}.LabelPacketAggregator();

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% intialize CentralController
Central_Controller = CentralController(ToRNumber);
Optical_Switch = OpticalSwitch(ToRNumber);


for i = 1 : ToRNumber

    Central_Controller = Central_Controller.PacketContention(ToR_list{i}.LabelPacket);

end

PacketContention = Central_Controller.LabelPacketList

Central_Controller = Central_Controller.OpticalConfigurationGenaration();
Optical_Configuration = Central_Controller.OpticalConfiguration

Central_Controller = Central_Controller.ACKSignalGeneration();
ACKsignals = Central_Controller.ACKSignals

DataPacketsRecord = [DataPacketsRecord;ACKsignals];

for i = 1 : ToRNumber

    ToR_list{i} = ToR_list{i}.ACKStateUpdate(ACKsignals(i));
    T_rx = [T_rx,datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSSS')];

    Optical_Switch = Optical_Switch.ProcessDataPackets(ToR_list{i}.DataPacket);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Time_offset = duration(T_rx-T_tx,"Format",'mm:ss.SSSS');

DataPacketList = Optical_Switch.DataPacketList

Optical_Switch = Optical_Switch.InterRackTraffic(Optical_Configuration);

InterTrafficData = Optical_Switch.InterTrafficData

for i = 1 : ToRNumber

    ToR_list{i}.BufferToSend = ToR_list{i}.BufferToSend.IntraRackTraffic();
    ToR_list{i} = ToR_list{i}.BufferUpdate(InterTrafficData);%,ACKsignals(i));

end

ToR_rest = ToR_rest.ACKStateUpdate(false);
ToR_rest = ToR_rest.BufferUpdate(InterTrafficData);%,false);

ThroughputRecord = [0];
for i = 1 : ToRNumber

    block = ToR_list{i}.BufferRecieved.Block;
    block = cellfun(@(b) b(:,2),block,'UniformOutput', false);
    cellsum = cellfun(@sum,block);
    ThroughputRecord = ThroughputRecord + sum(cellsum,'all');

end

% first time slot is over
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% next time slots
OldState = {ToR_list,ToR_rest};
Old_ToR_list = OldState{1};
Old_ToR_rest = OldState{2};

for i  = 1:1000
    
    [New_ToR_list,New_ToR_rest,ForwardingTable,NewACKsignals] = WorkFlowIteration(Old_ToR_list,Old_ToR_rest);
    Old_ToR_list = New_ToR_list;
    Old_ToR_rest = New_ToR_rest;
    DataPacketsRecord = [DataPacketsRecord;NewACKsignals];

    Throughput = 0;
    for j = 1 : ToRNumber

        block = New_ToR_list{j}.BufferRecieved.Block;
        block = cellfun(@(b) b(:,2),block,'UniformOutput', false);
        cellsum = cellfun(@sum,block);
        Throughput = Throughput + sum(cellsum,'all');

    end

    ThroughputRecord = [ThroughputRecord;Throughput-sum(ThroughputRecord,'all')];
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data Analysis 

OSPacketLoss = ones(size(DataPacketsRecord)) - DataPacketsRecord

%DataPacketsRecord

BufferPacketLoss = [];
for i  = 1 : ToRNumber

    BufferPacketLoss = [BufferPacketLoss,New_ToR_list{i}.BufferToSend.BufferPacketLossRecord];

end
TotalPackets = cumsum(ToRNumber + sum(BufferPacketLoss,2))

OSPacketLoss = cumsum(sum(OSPacketLoss,2))
BufferPacketLoss = cumsum(sum(BufferPacketLoss,2))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Save data for plotting

TotalPacketsName = strcat('/MATLAB Drive/6488/TotalPackets_',num2str(buffersize),'.mat');
OSPacketLossName = strcat('/MATLAB Drive/6488/OSPacketLoss_',num2str(buffersize),'.mat');
BufferPacketLossName = strcat('/MATLAB Drive/6488/BufferPacketLoss_',num2str(buffersize),'.mat');
ThroughputRecordName = strcat('/MATLAB Drive/6488/ThroughputRecord_',num2str(buffersize),'.mat');

save(TotalPacketsName,'TotalPackets')
save(OSPacketLossName,'OSPacketLoss')
save(BufferPacketLossName,'BufferPacketLoss')
save(ThroughputRecordName,'ThroughputRecord')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot result for fixed buffer size

X = [1:1:length(OSPacketLoss)];

figure
p = plot(X,OSPacketLoss./TotalPackets,X,BufferPacketLoss./TotalPackets,X,(OSPacketLoss+BufferPacketLoss)./TotalPackets);
[p(1).LineWidth, p(2).LineWidth, p(3).LineWidth] = deal(2);
legend('OSPacketLoss','BufferPacketLoss','OSPacketLoss+BufferPacketLoss','Location','southeast')
grid on
grid minor
xlabel('Time Slots')
ylabel('Packet Loss Ratio')
title('Packet Loss Performance','EthernetFrame Length : [0,128]; Buffer Size : 4096; Time Slots : 1000')

figure
p2 = plot(X,ThroughputRecord,'LineWidth',2);
grid on
grid minor
xlabel('Time Slots')
ylabel('Throughput')
title('Throughput Performance','EthernetFrame Length : [0,128]; Buffer Size : 4096; Time Slots : 1000')


toc

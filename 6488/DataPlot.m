clear all
clc

FileNameList = dir('/MATLAB Drive/6488/*.mat');
FileNameList = struct2cell(FileNameList);
FileNameList = FileNameList(1,:);
FileNameList = reshape(FileNameList,4,[]);

VariableNameList = cellfun(@(x) strcat('/MATLAB Drive/6488/',x),FileNameList,'UniformOutput', false);

VariableValueList = cellfun(@(x) cell2mat(struct2cell(load(x))),VariableNameList,'UniformOutput', false);

X = [1:1:length(VariableValueList{1})];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure

p1 = plot(X,(VariableValueList{3,1})./(VariableValueList{3,4}), ...
    X,(VariableValueList{3,2})./(VariableValueList{3,4}), ...
    X,(VariableValueList{3,1}+VariableValueList{3,2})./(VariableValueList{3,4}));

[p1(1).LineWidth, p1(2).LineWidth, p1(3).LineWidth] = deal(2);
legend('BufferPacketLoss','OSPacketLoss','OSPacketLoss+BufferPacketLoss','Location','southeast')
grid on
grid minor
xlabel('Time Slots')
ylabel('Packet Loss Ratio')
title('Packet Loss Performance','EthernetFrame Length : [0,128]; Buffer Size : 4096; Time Slots : 1000')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure

p2 = plot(X,(VariableValueList{1,1}+VariableValueList{1,2})./(VariableValueList{1,4}), ...
    X,(VariableValueList{2,1}+VariableValueList{2,2})./(VariableValueList{2,4}), ...
    X,(VariableValueList{3,1}+VariableValueList{3,2})./(VariableValueList{3,4}), ...
    X,(VariableValueList{4,1}+VariableValueList{4,2})./(VariableValueList{4,4}));

[p2(1).LineWidth, p2(2).LineWidth, p2(3).LineWidth, p2(4).LineWidth] = deal(2);
legend('BufferSize = 1024','BufferSize = 2048','BufferSize = 4096','BufferSize = 8192','Location','best')
grid on
grid minor
xlabel('Time Slots')
ylabel('Packet Loss Ratio')
title('Total Packet Loss Performance','EthernetFrame Length : [0,128]; Time Slots : 1000')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure

p3 = plot(X,(VariableValueList{1,1})./(VariableValueList{1,4}), ...
    X,(VariableValueList{2,1})./(VariableValueList{2,4}), ...
    X,(VariableValueList{3,1})./(VariableValueList{3,4}), ...
    X,(VariableValueList{4,1})./(VariableValueList{4,4}));

[p3(1).LineWidth, p3(2).LineWidth, p3(3).LineWidth, p3(4).LineWidth] = deal(2);
legend('BufferSize = 1024','BufferSize = 2048','BufferSize = 4096','BufferSize = 8192','Location','best')
grid on
grid minor
xlabel('Time Slots')
ylabel('Buffer Packet Loss Ratio')
title('Buffer Packet Loss Performance','EthernetFrame Length : [0,128]; Time Slots : 1000')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure

p4 = plot(X,(VariableValueList{1,2})./(VariableValueList{1,4}), ...
    X,(VariableValueList{2,2})./(VariableValueList{2,4}), ...
    X,(VariableValueList{3,2})./(VariableValueList{3,4}), ...
    X,(VariableValueList{4,2})./(VariableValueList{4,4}));

[p4(1).LineWidth, p4(2).LineWidth, p4(3).LineWidth, p4(4).LineWidth] = deal(2);
legend('BufferSize = 1024','BufferSize = 2048','BufferSize = 4096','BufferSize = 8192','Location','northwest')
grid on
grid minor
xlabel('Time Slots')
ylabel('OS Packet Loss Ratio')
title('OS Packet Loss Performance','EthernetFrame Length : [0,128]; Time Slots : 1000')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure

p5 = plot(X,VariableValueList{1,3},X,VariableValueList{2,3}, ...
    X,VariableValueList{3,3},X,VariableValueList{4,3});

[p5(1).LineWidth, p5(2).LineWidth, p5(3).LineWidth, p5(4).LineWidth] = deal(2);
%[p5(1).Color(4), p5(2).Color(4), p5(3).Color(4), p5(4).Color(4)] = deal(0.25);

legend('BufferSize = 1024','BufferSize = 2048','BufferSize = 4096','BufferSize = 8192','Location','best')
grid on
grid minor
xlabel('Time Slots')
ylabel('Throughput')
title('Throughput Performance','EthernetFrame Length : [0,128]; Time Slots : 1000')

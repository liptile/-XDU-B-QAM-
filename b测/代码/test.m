% 参数设置
M = 4; % 4QAM调制
nSym = 10; % 符号数量
sps = 2; % 每个符号的采样点数

% 生成随机符号
txSym4 = randi([0, M-1], 1, nSym);

% 格雷编码映射
grayMap4 = [0, 1, 3, 2]; % 4QAM格雷码映射表
graySym4 = grayMap4(txSym4 + 1);

% QAM调制
txSig4 = qammod(graySym4, M);

% 上采样以模拟每个符号多个采样点
%% txSig4_up = upsample(txSig4, sps);

% 显示结果
disp('原始符号:');
disp(txSym4);
disp('格雷编码后的符号:');
disp(graySym4);
disp('QAM调制后的信号:');
disp(txSig4);
disp('QAM上采样信号:');
disp(txSig4_up);

% 绘制眼图
eyediagram(txSig4, sps);
title('4QAM信号的眼图');
xlabel('时间（采样点）');
ylabel('幅度');
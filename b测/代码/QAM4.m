clc; clear all; close all;  

% =============== 参数定义 ===============
nSym = 5e3;      % 符号数量
M = 8;           % 8QAM调制阶数，每个符号携带log2(8)=3比特信息
N = 16;          % 16QAM调制阶数，每个符号携带log2(16)=4比特信息
grayMap8 = [0,1,3,2,6,7,5,4];          % 8QAM格雷映射表
grayMap16 = [0 1 3 2 4 5 7 6 12 13 15 14 8 9 11 10]; % 16QAM格雷映射，确保相邻星座点仅1比特差异
snrRange = 0:15;               % 信噪比扫描范围(0-15dB)，步长1
snrSingle = 16;                % 单独测试信噪比，用于眼图等可视化分析
snrLinear = 10.^(snrRange/10); % 将dB值转为SNR信噪比，用于理论计算

% =============== 8QAM调制 ===============
% 生成阶段
txSym8 = randi([0, M-1], 1, nSym);  % 生成8进制符号序列
graySym8 = grayMap8(txSym8 + 1);     % 格雷编码映射(MATLAB索引从1开始)
txSig8 = qammod(graySym8, M);       % 执行QAM调制，输出复数星座点(点在星座图的位置)

% 可视化
eyediagram(txSig8, 2);     % 绘制眼图，2表示每符号2个采样点
scatterplot(txSig8);       % 绘制星座图观察调制效果
pow8 = norm(txSig8)^2 / nSym;  % 计算信号平均功率：范数平方/符号数

% =============== 16QAM调制 ===============
% 生成阶段（流程同8QAM）
txSym16 = randi([0, N-1], 1, nSym);  
graySym16 = grayMap16(txSym16 + 1);  
txSig16 = qammod(graySym16, N);  

% 可视化
eyediagram(txSig16, 2);     % 眼图（对比与8QAM的差异）
scatterplot(txSig16);       % 16QAM星座图（观察16个星座点分布）
pow16 = norm(txSig16)^2 / nSym;  % 计算功率

% =============== 信道仿真 ===============
% 预分配存储数组  全0行向量，长16
ber8 = zeros(1, length(snrRange));     % 8QAM误比特率(BER)
ser8 = zeros(1, length(snrRange));     % 8QAM误符号率(SER)
ber16 = zeros(1, length(snrRange));    % 16QAM误比特率
ser16 = zeros(1, length(snrRange));    % 16QAM误符号率

% 循环遍历所有信噪比
for i = 1:length(snrRange)
    % 噪声功率计算（实部虚部独立，总噪声功率=sigma^2 * 2）
    sigma8 = sqrt(pow8 / (2 * snrLinear(i)));  % 8QAM噪声标准差：sqrt(符号功率/(2*SNR))
    sigma16 = sqrt(pow16 / (2 * snrLinear(i))); % 16QAM噪声标准差
    
    % 加性高斯白噪声信道模拟
    rxSig8 = txSig8 + sigma8*(randn(1,nSym) + 1i*randn(1,nSym)); % 复噪声：实虚独立同分布
    rxSig16 = txSig16 + sigma16*(randn(1,nSym) + 1i*randn(1,nSym));
    
    % QAM解调
    rxSym8 = qamdemod(rxSig8, M);      % 8QAM解调，返回0-7的整数
    rxSym16 = qamdemod(rxSig16, N);    % 16QAM解调，返回0-15的整数
    
    % 格雷逆映射（解格雷编码）
    decSym8 = grayMap8(rxSym8 + 1);    % +1索引调整，映射回原始数据
    decSym16 = grayMap16(rxSym16 + 1); 
    
    [~, ber8(i)] = biterr(txSym8, decSym8, log2(M));  % 比特错误率，log2(M)指定比特数
    [~, ser8(i)] = symerr(txSym8, decSym8);           % 符号错误率（直接比较符号）
    [~, ber16(i)] = biterr(txSym16, decSym16, log2(N)); % 16QAM BER
    [~, ser16(i)] = symerr(txSym16, decSym16);          % 16QAM SER
end

% =============== 8QAM噪声分析 ===============
% 使用awgn函数分别加噪（验证两种加噪方法等效性）
rxReal8 = awgn(real(txSig8), snrSingle);  % 实部加噪，snrSingle指定信噪比(dB)
rxImag8 = awgn(imag(txSig8), snrSingle);  % 虚部加噪
rxNoise8 = complex(rxReal8, rxImag8);     % 重构复信号

% 可视化加噪效果
scatterplot(rxNoise8);      % 显示加噪后的星座图
eyediagram(rxNoise8, 2);    % 眼图观察噪声影响

% 理论误码率计算（8QAM=QPSK）
p8 = 2*(1 - 1/sqrt(M)) * qfunc(sqrt(3*snrLinear/(M-1)));  % 符号错误率公式：2*(1-1/sqrt(M))*Q(sqrt(3*SNR/(M-1)))
serTheory8 = 1 - (1 - p8).^2;  % 正确概率平方反推总错误率
berTheory8 = serTheory8 / log2(M);  % 近似关系：BER ≈ SER / 比特数


% =============== 16QAM噪声分析 ===============
% 加噪过程同8QAM
rxReal16 = awgn(real(txSig16), snrSingle);  
rxImag16 = awgn(imag(txSig16), snrSingle);  
rxNoise16 = complex(rxReal16, rxImag16);  

% 可视化
scatterplot(rxNoise16);     
eyediagram(rxNoise16, 2);  

% 理论计算（16QAM）
p16 = 2*(1 - 1/sqrt(N)) * qfunc(sqrt(3*snrLinear/(N-1)));  % 符号错误率公式
serTheory16 = 1 - (1 - p16).^2;  
berTheory16 = serTheory16 / log2(N);  

% =============== 绘图 ===============
% 8QAM性能对比图
figure()
semilogy(snrRange, ber8, "o", snrRange, ser8, "*", snrRange, serTheory8, "-", snrRange, berTheory8, "-");
title("8QAM误码率性能");
xlabel("Es/N0 (dB)"); 
ylabel("误码率");
legend("BER仿真", "SER仿真", "SER理论", "BER理论", 'Location','best');
grid on;

% 8QAM与16QAM SER理论对比
figure()
semilogy(snrRange, serTheory8, 'o', snrRange, serTheory16, 'o');
title('8QAM vs 16QAM性能对比');
grid on; 
xlabel('Es/N0 (dB)'); 
ylabel('SER');
legend('8QAM理论', '16QAM理论', 'Location','best');
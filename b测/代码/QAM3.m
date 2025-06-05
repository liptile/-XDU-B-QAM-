clc;
clear all;
close all;

% 1. 生成原始二进制数据
data = randi([0 1], 3000, 1); % 生成3000个随机二进制数据

% 2. 8QAM调制
M8 = 8;
bits_per_symbol8 = log2(M8); % 每符号比特数为3
num_symbols8 = floor(length(data) / bits_per_symbol8); % 计算可以形成多少个符号
data8 = data(1:num_symbols8 * bits_per_symbol8); % 截取刚好可以形成整数个符号的数据
data8_matrix = reshape(data8, bits_per_symbol8, num_symbols8); % 将数据reshape为矩阵
symbols8 = bi2de(data8_matrix'); % 将二进制矩阵转换为十进制数，得到符号序列
symbols8 = symbols8(:); % 确保为列向量
symbols8 = mod(symbols8, M8); % 强制将符号值限制在 [0, M8-1] 范围内
constellation8 = qammod(symbols8, M8); % 调制生成8QAM信号

% 绘制8QAM星座图
figure;
subplot(1,2,1);
scatterplot(constellation8);
title('8QAM 星座图');

% 3. 16QAM调制
M16 = 16;
bits_per_symbol16 = log2(M16); % 每符号比特数为4
num_symbols16 = floor(length(data) / bits_per_symbol16); % 计算可以形成多少个符号
data16 = data(1:num_symbols16 * bits_per_symbol16); % 截取刚好可以形成整数个符号的数据
data16_matrix = reshape(data16, bits_per_symbol16, num_symbols16); % 将数据reshape为矩阵
symbols16 = bi2de(data16_matrix'); % 将二进制矩阵转换为十进制数，得到符号序列
symbols16 = symbols16(:); % 确保为列向量
symbols16 = mod(symbols16, M16); % 强制将符号值限制在 [0, M16-1] 范围内
constellation16 = qammod(symbols16, M16); % 调制生成16QAM信号

% 绘制16QAM星座图
subplot(1,2,2);
scatterplot(constellation16);
title('16QAM 星座图');

% 4. 添加高斯白噪声（信噪比为18dB）
SNR = 18;
noisy_constellation8 = awgn(constellation8, SNR, 'measured'); % 给8QAM信号添加噪声
noisy_constellation16 = awgn(constellation16, SNR, 'measured'); % 给16QAM信号添加噪声

% 绘制接收信号星座图
figure;
subplot(1,2,1);
scatterplot(noisy_constellation8);
title('8QAM 接收信号星座图（SNR=18dB）');

subplot(1,2,2);
scatterplot(noisy_constellation16);
title('16QAM 接收信号星座图（SNR=18dB）');

% 5. 绘制眼图
% 绘制8QAM眼图
figure;
eyediagram(constellation8, 8); % 绘制8QAM眼图
title('8QAM 眼图');

% 绘制16QAM眼图
figure;
eyediagram(constellation16, 16); % 绘制16QAM眼图
title('16QAM 眼图');

% 6. 解调接收信号并计算误码率
received_symbols8 = qamdemod(noisy_constellation8, M8); % 解调8QAM信号
received_symbols16 = qamdemod(noisy_constellation16, M16); % 解调16QAM信号

% 将解调后的符号转换为二进制数据
demod_data8_matrix = de2bi(received_symbols8, bits_per_symbol8);
demod_data8 = demod_data8_matrix(:); % 将矩阵转换为列向量
demod_data8 = demod_data8(1:length(data8)); % 截取与原始数据相同长度的数据

demod_data16_matrix = de2bi(received_symbols16, bits_per_symbol16);
demod_data16 = demod_data16_matrix(:); % 将矩阵转换为列向量
demod_data16 = demod_data16(1:length(data16)); % 截取与原始数据相同长度的数据

% 计算误码率
bit_error_rate8 = sum(ne(data8, demod_data8)) / length(data8);
bit_error_rate16 = sum(ne(data16, demod_data16)) / length(data16);

% 7. 绘制误码率曲线图并与理论值对比
EbN0 = -2:25; % 设置不同的信噪比范围
theory_ber8 = qamtheor(EbN0, M8); % 计算8QAM的理论误码率
theory_ber16 = qamtheor(EbN0, M16); % 计算16QAM的理论误码率

% 在不同的信噪比下，重复调制、加噪、解调过程得到仿真误码率数据
sim_ber8 = zeros(size(EbN0));
sim_ber16 = zeros(size(EbN0));
for i = 1:length(EbN0)
    noisy_constellation8_temp = awgn(constellation8, EbN0(i), 'measured');
    noisy_constellation16_temp = awgn(constellation16, EbN0(i), 'measured');
    
    received_symbols8_temp = qamdemod(noisy_constellation8_temp, M8);
    received_symbols16_temp = qamdemod(noisy_constellation16_temp, M16);
    
    demod_data8_temp = de2bi(received_symbols8_temp, bits_per_symbol8);
    demod_data8_temp = demod_data8_temp(:);
    demod_data8_temp = demod_data8_temp(1:length(data8));
    
    demod_data16_temp = de2bi(received_symbols16_temp, bits_per_symbol16);
    demod_data16_temp = demod_data16_temp(:);
    demod_data16_temp = demod_data16_temp(1:length(data16));
    
    sim_ber8(i) = sum(ne(data8, demod_data8_temp)) / length(data8);
    sim_ber16(i) = sum(ne(data16, demod_data16_temp)) / length(data16);
end

% 绘制误码率曲线图
figure;
semilogy(EbN0, theory_ber8, '-s', EbN0, theory_ber16, '-o', EbN0, sim_ber8, 'k:*', EbN0, sim_ber16, 'k:x');
legend('8QAM 理论值', '16QAM 理论值', '8QAM 仿真值', '16QAM 仿真值');
xlabel('EbNo (dB)');
ylabel('误码率');
title('误码率曲线图');
grid on;

% 显示单个信噪比（18dB）下的误码率
disp(['在SNR=18dB时，8QAM的误码率为: ', num2str(bit_error_rate8)]);
disp(['在SNR=18dB时，16QAM的误码率为: ', num2str(bit_error_rate16)]);
%% 清空环境
clc; clear; close all;

%% 参数设置
M_8qam = 8;               % 8QAM调制阶数
M_16qam = 16;             % 16QAM调制阶数
numSymbols = 1e4;         % 发送符号数
sps = 8;                  % 每符号采样数
rolloff = 0.25;           % 升余弦滚降系数
span = 10;                % 滤波器跨度
EbN0_dB = 0:2:18;         % Eb/N0范围
snr_plot = 18;            % 星座图显示的信噪比

%% ========== 第一部分：生成星座图 ==========
% 8QAM星座图（自定义非均匀星座）
I_8qam = [-3 -1 1 3];
Q_8qam = [1 -1];
[I_grid, Q_grid] = meshgrid(I_8qam, Q_8qam);
constellation_8qam = (I_grid(:) + 1j*Q_grid(:)).';
avg_power = mean(abs(constellation_8qam).^2);
constellation_8qam = constellation_8qam/sqrt(avg_power); % 归一化功率

% 16QAM星座图（标准正交）
constellation_16qam = qammod(0:M_16qam-1, M_16qam, 'UnitAveragePower', true);

% 绘制星座图
figure;
subplot(1,2,1);
plot(constellation_8qam, 'o', 'MarkerSize', 8);
title('8QAM Constellation');
axis([-2 2 -2 2]); grid on;

subplot(1,2,2);
plot(constellation_16qam, 'o', 'MarkerSize', 8);
title('16QAM Constellation');
axis([-1.5 1.5 -1.5 1.5]); grid on;

%% ========== 第二部分：噪声信道传输 ==========
% 生成随机数据
data_8qam = randi([0 M_8qam-1], 1, numSymbols);
data_16qam = randi([0 M_16qam-1], 1, numSymbols);

% 调制信号
tx_8qam = constellation_8qam(data_8qam+1);
tx_16qam = qammod(data_16qam, M_16qam, 'UnitAveragePower', true);

% 添加AWGN噪声
rx_8qam = awgn(tx_8qam, snr_plot, 'measured');
rx_16qam = awgn(tx_16qam, snr_plot, 'measured');

% 绘制接收星座图
figure;
subplot(1,2,1);
plot(rx_8qam, '.');
title(['8QAM Received (SNR=' num2str(snr_plot) 'dB)']);
axis([-2 2 -2 2]); grid on;

subplot(1,2,2);
plot(rx_16qam, '.');
title(['16QAM Received (SNR=' num2str(snr_plot) 'dB)']);
axis([-1.5 1.5 -1.5 1.5]); grid on;

%% ========== 第三部分：生成眼图 ==========
% 设计升余弦滤波器
rctFilt = rcosdesign(rolloff, span, sps);

% 8QAM眼图
tx_waveform_8qam = upfirdn(real(tx_8qam), rctFilt, sps);
figure;
eyediagram(tx_waveform_8qam(span*sps+1:end-span*sps), 2*sps);
title('8QAM Eye Diagram');

% 16QAM眼图
tx_waveform_16qam = upfirdn(real(tx_16qam), rctFilt, sps);
figure;
eyediagram(tx_waveform_16qam(span*sps+1:end-span*sps), 2*sps);
title('16QAM Eye Diagram');

%% ========== 第四部分：误码率分析 ==========
% 预分配存储空间
ber_8qam = zeros(size(EbN0_dB));
ber_16qam = zeros(size(EbN0_dB));
ber_16qam_theory = zeros(size(EbN0_dB));

for idx = 1:length(EbN0_dB)
    % 当前Eb/N0转换
    EbN0 = 10^(EbN0_dB(idx)/10);
    
    % ===== 8QAM仿真 =====
    EsN0_8qam = EbN0 * log2(M_8qam);
    snrdB_8qam = 10*log10(EsN0_8qam);
    
    % 添加噪声
    rx_signal = awgn(tx_8qam, snrdB_8qam, 'measured');
    
    % 解调（最小距离判决）
    demod_indices = zeros(1,numSymbols);
    for k = 1:numSymbols
        [~, demod_indices(k)] = min(abs(rx_signal(k) - constellation_8qam));
    end
    demod_data = demod_indices - 1;
    
    % 计算误码率
    [~, ber_8qam(idx)] = biterr(data_8qam, demod_data, log2(M_8qam));
    
    % ===== 16QAM仿真 =====
    EsN0_16qam = EbN0 * log2(M_16qam);
    rx_signal = awgn(tx_16qam, 10*log10(EsN0_16qam), 'measured');
    
    % 解调
    demod_data = qamdemod(rx_signal, M_16qam, 'UnitAveragePower', true);
    
    % 计算误码率
    [~, ber_16qam(idx)] = biterr(data_16qam, demod_data, log2(M_16qam));
    
    % 理论值计算（16QAM）
    ber_16qam_theory(idx) = 3/4 * erfc(sqrt(4*EbN0/5));
end

%% 绘制误码率曲线
figure;
semilogy(EbN0_dB, ber_8qam, 'ro-', 'LineWidth', 1.5); hold on;
semilogy(EbN0_dB, ber_16qam, 'bs-', 'LineWidth', 1.5);
semilogy(EbN0_dB, ber_16qam_theory, 'g--', 'LineWidth', 2);
grid on;
xlabel('Eb/N0 (dB)');
ylabel('Bit Error Rate');
legend('8QAM Simulated', '16QAM Simulated', '16QAM Theoretical');
title('BER Performance Comparison');
axis([0 18 1e-5 1]);
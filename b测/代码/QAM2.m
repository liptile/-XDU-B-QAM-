%% QAM系统仿真主程序
% 功能：实现QAM调制解调全流程仿真，包含星座图、接收星座图、眼图及误码率性能分析
% 作者：豆包编程助手
% 日期：2025-05-05

% 清空工作区、关闭所有图形窗口、清空命令窗口（初始化操作）
clear; close all; clc;  


%% 参数设置（全局仿真参数定义）
M_list = [8, 16];          % 调制阶数列表（本次仿真8QAM和16QAM）
numSymbols = 10000;        % 生成的符号数量（用于统计误码率时保证样本量）
sps = 4;                    % 每符号采样点数（用于脉冲成形和眼图绘制）
rolloff = 0.35;             % 升余弦滤波器的滚降系数（0~1之间，越大滤波器过渡带越宽）
span = 6;                   % 升余弦滤波器的跨度（单位：符号周期，总长度=span*sps+1）
SNR = 18;                   % 接收星座图的信噪比设置（dB，用于观察噪声影响）
EbN0_dB = 0:2:20;           % 误码率仿真的Eb/N0范围（dB，从0dB到20dB，步长2dB）


%% ========================== 第一部分：发送端星座图绘制 ==========================
% 目的：绘制不同阶数QAM的理想星座图（无噪声），观察符号分布规律
for M = M_list  % 遍历8QAM和16QAM分别处理
    % 1. 生成随机符号（0到M-1的整数，每个符号对应星座图一个点）
    data = randi([0 M-1], numSymbols, 1);  % 生成numSymbols行×1列的随机符号序列
    
    % 2. QAM调制（将符号映射到星座点）
    % qammod函数参数说明：
    %   data：待调制的符号序列
    %   M：调制阶数（8/16）
    %   'UnitAveragePower'：启用平均功率归一化（保证不同阶数星座点平均功率相同）
    modSignal = qammod(data, M, 'UnitAveragePower', true);
    
    % 3. 绘制星座图（显示同相分量I和正交分量Q的分布）
    figure('Name', ['星座图 M=' num2str(M)]);  % 创建图形窗口并命名
    scatterplot(modSignal);  % 绘制星座点（横轴=I分量，纵轴=Q分量）
    title([num2str(M) 'QAM 发送端星座图']);  % 设置标题
    xlabel('同相分量 (I)'); ylabel('正交分量 (Q)');  % 坐标轴标签
    grid on;  % 显示网格线
end


%% ================== 第二部分：加噪后的接收星座图(SNR=18dB) ===================
% 目的：观察高斯白噪声对星座点的影响（噪声导致符号点扩散）
for M = M_list  % 遍历8QAM和16QAM分别处理
    % 1. 生成随机符号并调制（同第一部分）
    data = randi([0 M-1], numSymbols, 1);
    modSignal = qammod(data, M, 'UnitAveragePower', true);
    
    % 2. 添加高斯白噪声（模拟实际信道干扰）
    % awgn函数参数说明：
    %   modSignal：输入信号
    %   SNR：信噪比（dB）
    %   'measured'：根据输入信号的实际功率计算噪声功率
    rxSignal = awgn(modSignal, SNR, 'measured');
    
    % 3. 绘制接收端星座图（带噪声的符号分布）
    figure('Name', ['接收星座图 M=' num2str(M)]);  % 创建图形窗口并命名
    scatterplot(rxSignal);  % 绘制加噪后的星座点
    title([num2str(M) 'QAM 接收星座图 (SNR=' num2str(SNR) 'dB)']);  % 设置标题
    xlabel('同相分量 (I)'); ylabel('正交分量 (Q)');  % 坐标轴标签
    grid on;  % 显示网格线
end


%% ========================== 第三部分：眼图绘制 ==========================
% 目的：通过眼图评估信号质量（眼睛越开，噪声和码间串扰越小）
% 关键操作：使用升余弦滤波器进行脉冲成形（减少码间串扰）
% 设计升余弦滤波器（平方根升余弦，用于发射端脉冲成形）
% rcosdesign函数参数说明：
%   rolloff：滚降系数
%   span：滤波器跨度（符号周期数）
%   sps：每符号采样点数
%   'sqrt'：生成平方根升余弦滤波器（收发端各用一次可实现升余弦滚降）
filterCoeffs = rcosdesign(rolloff, span, sps, 'sqrt');

for M = M_list  % 遍历8QAM和16QAM分别处理
    % 1. 生成随机符号并调制（同第一部分）
    data = randi([0 M-1], numSymbols, 1);
    modSignal = qammod(data, M, 'UnitAveragePower', true);
    
    % 2. 脉冲成形（将符号转换为连续时间信号，减少码间串扰）
    upsampled = upsample(modSignal, sps);  % 上采样（每符号插入sps-1个零）
    txSignal = conv(upsampled, filterCoeffs, 'same');  % 与滤波器卷积实现脉冲成形
    
    % 3. 绘制眼图（截取中间有效部分避免滤波器暂态影响）
    figure('Name', ['眼图 M=' num2str(M)]);  % 创建图形窗口并命名
    % eyediagram函数参数说明：
    %   txSignal(span*sps+1:end-span*sps)：截取信号中间部分（去除滤波器初始/结束的暂态）
    %   2*sps：每符号显示2*sps个点（覆盖两个符号周期，便于观察码间串扰）
    eyediagram(txSignal(span*sps+1:end-span*sps), 2*sps);
    title([num2str(M) 'QAM 眼图']);  % 设置标题
    xlabel('时间 (符号周期)'); ylabel('幅度');  % 坐标轴标签
end


%% =================== 第四部分：误码率曲线及理论对比 =====================
% 目的：验证不同阶数QAM的抗噪声性能（SNR越高，误码率越低）
figure('Name', '误码率性能比较');  % 创建图形窗口
hold on;  % 保持图形窗口，允许多次绘制
colors = ['r', 'b'];       % 曲线颜色（红、蓝分别对应8QAM、16QAM）
markers = ['o', 's'];      % 标记符号（圆圈、方块分别对应仿真值）

for idx = 1:length(M_list)  % 遍历8QAM和16QAM分别处理
    M = M_list(idx);        % 当前调制阶数
    k = log2(M);            % 每符号比特数（8QAM=3，16QAM=4）
    ber_sim = zeros(size(EbN0_dB));  % 预分配仿真误码率数组
    
    % 1. 理论误码率计算（仅16QAM有内置函数，8QAM需自定义）
    if M == 8
        % 8QAM理论误码率（需手动推导，此处示例留空，实际可根据公式计算）
        ber_theory = zeros(size(EbN0_dB)); 
    else
        % 16QAM理论误码率（使用MATLAB内置函数berawgn）
        % berawgn函数参数说明：EbN0_dB（Eb/N0），调制类型'qam'，阶数M
        ber_theory = berawgn(EbN0_dB, 'qam', M);
    end
    
    % 2. 仿真误码率计算（遍历不同Eb/N0）
    for i = 1:length(EbN0_dB)
        % a. 生成随机符号（0到M-1的整数）
        data = randi([0 M-1], numSymbols, 1);
        
        % b. QAM调制（同第一部分）
        txSig = qammod(data, M, 'UnitAveragePower', true);
        
        % c. 添加噪声（需将Eb/N0转换为SNR）
        % 转换公式：SNR(dB) = Eb/N0(dB) + 10*log10(每符号比特数k)
        % （因为SNR=信号功率/噪声功率，Eb=信号功率/(k*符号速率)，噪声功率=噪声谱密度*符号速率）
        SNR = EbN0_dB(i) + 10*log10(k);
        rxSig = awgn(txSig, SNR, 'measured');  % 添加高斯白噪声
        
        % d. QAM解调（将接收信号恢复为符号）
        % qamdemod参数与qammod对应，需保持'UnitAveragePower'一致
        rxData = qamdemod(rxSig, M, 'UnitAveragePower', true);
        
        % e. 计算误码率（比较原始数据和解调数据的二进制位）
        % de2bi函数：将十进制符号转换为k位二进制数（列向量）
        % biterr函数：统计误码数并计算误码率（第一个输出为误码数，第二个为误码率）
        [~, ber_sim(i)] = biterr(de2bi(data, k), de2bi(rxData, k));
    end
    
    % 3. 绘制仿真误码率曲线
    semilogy(EbN0_dB, ber_sim, [markers(idx) '-'], ...  % 半对数坐标绘制（y轴对数）
        'Color', colors(idx), 'LineWidth', 1.5, ...     % 设置颜色、线宽
        'DisplayName', [num2str(M) 'QAM 仿真']);        % 图例显示内容
    
    % 4. 绘制理论误码率曲线（仅16QAM）
    if M == 16
        semilogy(EbN0_dB, ber_theory, '--', ...          % 虚线绘制理论值
            'Color', colors(idx), 'LineWidth', 1.5, ...  % 设置颜色、线宽
            'DisplayName', [num2str(M) 'QAM 理论']);      % 图例显示内容
    end
end

% 图形通用设置（提升可读性）
xlabel('Eb/N0 (dB)');        % x轴标签（比特能量与噪声谱密度之比）
ylabel('误码率 (BER)');       % y轴标签（错误比特数占比）
title('QAM系统误码率性能');   % 图形标题
legend('Location', 'southwest');  % 图例位置（西南方向）
grid on;  % 显示网格线
axis tight;  % 自动调整坐标轴范围，使图形更紧凑
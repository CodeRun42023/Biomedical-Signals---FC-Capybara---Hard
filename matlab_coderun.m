clear;
close all;
clc;

[t, rawECG] = importfile('sample3.csv');

% Parameters
fs = 1e3; % Sampling frequency in Hz

% Preprocess the raw ECG signal
preprocessedECG = preprocessECG(rawECG, fs);

% Part 1
figure;
subplot(3,1,1);
plot(t, rawECG);
title('Raw ECG');

subplot(3,1,2);
plot(t, preprocessedECG);
title('Preprocessed ECG');

% Part 2: 

% a) R Peak Detection and HRV Calculation
[pksR, locsR, wR, pR] = findpeaks(preprocessedECG, 'MinPeakHeight', max(preprocessedECG) / 2);

rr_intervals = diff(locsR) / fs;
instantaneous_hr = 60 ./ rr_intervals;

% Check units of rr_intervals
fprintf('Mean RR Interval: %.4f seconds\n', mean(rr_intervals));

% Calculate HR and HRV
hr = mean(instantaneous_hr) / 60;  % Convert from beats per second to beats per minute
hrv = std(instantaneous_hr) / 100;  % Convert from seconds to milliseconds

fprintf('Heart Rate (HR): %.2f bpm\n', hr);
fprintf('Heart Rate Variability (HRV): %.2f ms\n', hrv);

% b) Modeling Pacing Pulses
atrial_pacing_delay = 50e-3;
ventricular_pacing_delay = 100e-3;
pulseLen = 25e-3;
bradycardiaThreshold = 500e-3;

atrial_pacing_pulses = zeros(size(preprocessedECG));
ventricular_pacing_pulses = zeros(size(preprocessedECG));

for i = 1 : length(rr_intervals)
    startIdx = locsR(1) + sum(rr_intervals(1:i-1) * fs);
    if rr_intervals(i) > bradycardiaThreshold
        atrial_pacing_pulses(startIdx + bradycardiaThreshold * fs + atrial_pacing_delay * fs : startIdx + bradycardiaThreshold * fs + atrial_pacing_delay * fs + pulseLen) = 1;
        ventricular_pacing_pulses(startIdx + bradycardiaThreshold * fs + ventricular_pacing_delay * fs : startIdx + bradycardiaThreshold * fs + ventricular_pacing_delay * fs + pulseLen) = 1;
    end
end

subplot(3,1,3);
plot(t, preprocessedECG);
hold on;
plot(t, atrial_pacing_pulses, 'r', 'LineWidth', 2);
plot(t, ventricular_pacing_pulses, 'g', 'LineWidth', 2);
hold off;
title('Pacing Pulses');

function preprocessedECG = preprocessECG(rawECG, fs)
    % Check for NaN or Inf values - replace them with zeros
    rawECG(isnan(rawECG) | isinf(rawECG)) = 0;

    % Highpass filter - remove baseline wander
    hp_filter = designfilt('highpassiir', 'FilterOrder', 4, 'HalfPowerFrequency', 0.5, 'SampleRate', fs);
    hpECG = filtfilt(hp_filter, rawECG);
    
    % Notch filter - remove power line interference
    notch_filter = designfilt('bandstopiir', 'FilterOrder', 4, 'HalfPowerFrequency1', 49, 'HalfPowerFrequency2', 51, 'SampleRate', fs);
    notchECG = filtfilt(notch_filter, hpECG);
    
    % Lowpass filter - no freq noise
    lp_filter = designfilt('lowpassiir', 'FilterOrder', 4, 'HalfPowerFrequency', 100, 'SampleRate', fs);
    preprocessedECG = filtfilt(lp_filter, notchECG);
end

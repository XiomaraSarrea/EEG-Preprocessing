function [psd, freq, band_power_table] = calculate_eeg_psd(EEG, channel_names, length_interval, fs)
% signal: EEG signal with n channels (each column represents a channel)
% fs: sampling frequency

% Define frequency bands
bands = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
band_limits = [0.5 4; 4 8; 8 12; 12 30; 30 100];

% Compute PSD for each channel
n_channels = length(EEG.data(:,1));
psd = cell(1, n_channels);
freq = cell(1, n_channels);
band_power_table = cell(n_channels * length(bands), 3); % Initialize table

row = 1; % Row index for band_power_table
for i = 1:n_channels
    % Example parameters
    NFFT = fs / 0.5; % FFT length to get 0.5 Hz resolution
    window = hamming(NFFT); % Window function
    noverlap = 0; % Overlap between segments
    [p, freq] = pwelch(EEG.data(i,:), window, noverlap, NFFT, fs);
    psd{i}= [p;length_interval(i)];

    for j = 1:length(bands)
        % Get band limits
        band_start = band_limits(j, 1);
        band_end = band_limits(j, 2);

        % Compute band power
        band_power = trapz(freq(freq >= band_start & freq <= band_end), psd{i}(freq >= band_start & freq <= band_end));

        % Store in table
        band_power_table{row, 1} = channel_names{i};
        band_power_table{row, 2} = bands{j};
        band_power_table{row, 3} = band_power;
        row = row + 1;
    end
end

freq=[freq;0];
% Convert cell array to table for better readability
band_power_table = cell2table(band_power_table, 'VariableNames', {'Channel', 'Band', 'Power'});
end

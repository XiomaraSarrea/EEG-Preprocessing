function [envelopeTable, statsTable, regionStatsTable, psdTable, bandPowerTable] = compute_envelope(EEG, regions, filepath, filename)
    % Computes the envelope of EEG data, computes PSD of envelope,
    % power in bands, and saves all results to Excel.
    
    eegData = EEG.data; % channels x time
    fs = EEG.srate;
    numChannels = size(eegData, 1);
    channelNames = {EEG.chanlocs.labels};

    % Preallocate
    envelopeData = zeros(size(eegData));
    meanEnvelope = zeros(numChannels, 1);
    stdEnvelope = zeros(numChannels, 1);
    psdData = []; % Will hold PSD for each channel
    freq = [];
    
    % Parameters for PSD
    windowLength = round(2 * fs); % 2-second window
    overlap = round(0.5 * windowLength); % 50% overlap
    nfft = max(256, 2^nextpow2(windowLength));
    
    % Store band power
    bandNames = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
    bandLimits = [0.5 4; 4 8; 8 13; 13 30; 30 45];
    bandPowers = zeros(numChannels, length(bandNames));

    for ch = 1:numChannels
        % Compute envelope
        analyticSignal = hilbert(eegData(ch, :));
        env = abs(analyticSignal);
        envelopeData(ch, :) = env;

        % Mean and std of envelope
        meanEnvelope(ch) = mean(env);
        stdEnvelope(ch) = std(env);

        % PSD of envelope
        [Pxx, f] = pwelch(env, windowLength, overlap, nfft, fs);
        if isempty(freq)
            freq = f;
        end
        psdData(:, ch) = Pxx;

        % Band power from envelope PSD
        for b = 1:length(bandNames)
            bandIdx = f >= bandLimits(b,1) & f <= bandLimits(b,2);
            bandPowers(ch, b) = trapz(f(bandIdx), Pxx(bandIdx));
        end
    end

    %% Tables
    envelopeTable = array2table(envelopeData', 'VariableNames', channelNames);
    statsTable = table(channelNames', meanEnvelope, stdEnvelope, ...
        'VariableNames', {'Channel', 'MeanEnvelope', 'StdEnvelope'});

    psdTable = array2table(psdData', 'VariableNames', strcat('F_', string(round(freq,2))));
    psdTable = addvars(psdTable, channelNames', 'Before', 1, 'NewVariableNames', 'Channel');

    bandPowerTable = array2table(bandPowers, 'VariableNames', bandNames);
    bandPowerTable = addvars(bandPowerTable, channelNames', 'Before', 1, 'NewVariableNames', 'Channel');

    %% Region Stats
    numRegions = size(regions, 1);
    regionNames = regions(:, 1);
    meanEnvelopeRegions = zeros(numRegions, 1);
    stdEnvelopeRegions = zeros(numRegions, 1);

    for r = 1:numRegions
        regionChannels = regions{r, 2};
        validChannels = find(ismember(channelNames, regionChannels));

        if ~isempty(validChannels)
            regionEnv = envelopeData(validChannels, :);
            meanEnvelopeRegions(r) = mean(regionEnv(:));
            stdEnvelopeRegions(r) = std(regionEnv(:));
        else
            meanEnvelopeRegions(r) = NaN;
            stdEnvelopeRegions(r) = NaN;
        end
    end

    regionStatsTable = table(regionNames, meanEnvelopeRegions, stdEnvelopeRegions, ...
        'VariableNames', {'Region', 'MeanEnvelope', 'StdEnvelope'});

    %% Save to Excel
    fullFilePath = fullfile(filepath, strcat(filename, '_envelope.xlsx'));
    writetable(envelopeTable, fullFilePath, 'Sheet', 'Envelope Data');
    writetable(statsTable, fullFilePath, 'Sheet', 'Channel Stats');
    writetable(regionStatsTable, fullFilePath, 'Sheet', 'Region Stats');
    writetable(psdTable, fullFilePath, 'Sheet', 'Envelope PSD');
    writetable(bandPowerTable, fullFilePath, 'Sheet', 'Envelope Band Powers');

    fprintf('Envelope and spectral data saved to %s\n', fullFilePath);
end

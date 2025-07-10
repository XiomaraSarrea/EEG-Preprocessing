function plvBetweenClusters(eegData, fs, freqBand, regions,channelNames, output_folder,output_file)
    % Compute and visualize PLV matrices between averaged signals of clusters.
    %
    % INPUTS:
    % eegData: EEG data matrix (channels x timepoints).
    % fs: Sampling frequency (Hz).
    % freqBand: Frequency band of interest (e.g., [4, 8] for theta).
    % regions: Cell array defining clusters and their channels.

    numRegions = size(regions, 1); % Number of clusters
    averagedSignals = zeros(numRegions, size(eegData, 2)); % To store averaged signals for each cluster

    % Step 1: Compute the averaged signal for each cluster
    for i = 1:numRegions
        clusterName = regions{i, 1};
        clusterChannels = regions{i, 2};
        
        % Find indices of cluster channels in eegData
        channelIndices = findChannelIndices(clusterChannels, channelNames);
        
        % Average the signals within the cluster
        averagedSignals(i, :) = mean(eegData(channelIndices, :), 1);
    end

    % Step 2: Compute the PLV between all pairs of clusters
    PLV = zeros(numRegions, numRegions); % Initialize PLV matrix
    filteredSignals = bandpass(averagedSignals', freqBand, fs)'; % Bandpass filter averaged signals
    phases = angle(hilbert(filteredSignals')); % Compute instantaneous phase of filtered signals

    for i = 1:numRegions
        for j = i:numRegions
            % Compute phase difference
            phaseDiff = phases(:, i) - phases(:, j);

            % Compute PLV
            PLV(i, j) = abs(mean(exp(1i * phaseDiff)));
            PLV(j, i) = PLV(i, j); % Symmetry
        end
    end

    % Step 3: Plot and save the PLV matrix
    figure;
    imagesc(PLV);
    colorbar;
    xticks(1:numRegions);
    yticks(1:numRegions);
    xticklabels({regions{:, 1}});  % Use cluster names as labels for x-axis
    yticklabels({regions{:, 1}});  % Use cluster names as labels for y-axis
    title('PLV Between Clusters');
    xlabel('Clusters');
    ylabel('Clusters');

    saveas(gcf, fullfile(output_folder,strcat(output_file ,'_PLV_Between_Clusters.png')));
    excelFileName = fullfile(output_folder, strcat(output_file ,'_betweenPLV.xlsx'));
    PLVTable = array2table(PLV, ...
    'VariableNames', {regions{:, 1}}, ... % Column headers
    'RowNames', {regions{:, 1}});         % Row headers

    % Write the table to a specific sheet in the Excel file
    writetable(PLVTable, excelFileName, ...
    'WriteRowNames', true);            % Include row headers

end


% Helper functions
function clusterChannels = findChannelIndices(clusterChannelNames, channelNames)
    clusterChannels = [];
    for i = 1:length(clusterChannelNames)
        channelIdx = find(strcmp({channelNames.labels}, clusterChannelNames{i}));
        if ~isempty(channelIdx)
            clusterChannels = [clusterChannels, channelIdx];
        end
    end
end


function plvWithinClusters(eegData, fs, freqBand, regions, channelNames, output_folder,output_file)
    % Compute and visualize PLV matrices for channels within each cluster.
    %
    % INPUTS:
    % eegData: EEG data matrix (channels x timepoints).
    % fs: Sampling frequency (Hz).
    % freqBand: Frequency band of interest (e.g., [4, 8] for theta).
    % regions: Cell array defining clusters and their channels.

    for i = 1:size(regions, 1)
        % Extract cluster information
        clusterName = regions{i, 1};
        clusterChannels = regions{i, 2};
        if clusterName == "C3" || clusterName == "C4"
            continue

        else
            % Find indices of cluster channels in eegData
            channelIndices = findChannelIndices(clusterChannels, channelNames);
            
            % Subset EEG data for the cluster
            clusterData = eegData(channelIndices, :);
            
            % Compute PLV matrix
            PLV = computePLV(clusterData, fs, freqBand);
            
            % Plot and save the PLV matrix
            figure;
            imagesc(PLV); 
            colorbar; 
            title(['PLV Matrix - ' clusterName]);
            xlabel('Channels'); 
            ylabel('Channels');
            
            % Set x and y axis labels as the channel names
            set(gca, 'XTick', 1:length(clusterChannels), 'XTickLabel', clusterChannels);
            set(gca, 'YTick', 1:length(clusterChannels), 'YTickLabel', clusterChannels);
            
            % Save the figure in the specified folder
            saveas(gcf, fullfile(output_folder, strcat(output_file ,'_', clusterName ,'_PLV.png')));
    
            excelFileName = fullfile(output_folder, strcat(output_file ,'_withinPLV.xlsx'));

            PLVTable = array2table(PLV, 'VariableNames', clusterChannels, 'RowNames', clusterChannels);  
        
            % Write the table to a specific sheet in the Excel file
            writetable(PLVTable, excelFileName, ...
            'Sheet', clusterName, ...          % Use cluster name as sheet name
            'WriteRowNames', true);            % Include row headers            
        end
    end
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

function PLV = computePLV(eegData, fs, freqBand)
    % Compute PLV between every pair of channels in a given dataset.
    %
    % INPUTS:
    % eegData: EEG data matrix (channels x timepoints).
    % fs: Sampling frequency (Hz).
    % freqBand: Frequency band of interest (e.g., [4, 8] for theta).
    
    % Number of channels
    numChannels = size(eegData, 1);
    
    % Bandpass filter the data for the given frequency band
    filteredData = bandpass(eegData', freqBand, fs)';  % Bandpass filter along time (rows)

    % Compute the instantaneous phase using the Hilbert transform
    phase = angle(hilbert(filteredData'));  % Instantaneous phase (time x channels)

    % Initialize the PLV matrix
    PLV = zeros(numChannels, numChannels);

    % Compute the PLV for each pair of channels
    for i = 1:numChannels
        for j = i:numChannels
            % Compute the phase difference between the two channels
            phaseDiff = phase(:, i) - phase(:, j);
            
            % Compute the PLV for this pair of channels
            PLV(i, j) = abs(mean(exp(1i * phaseDiff)));  % PLV formula
            PLV(j, i) = PLV(i, j);  % Symmetric matrix
        end
    end
end


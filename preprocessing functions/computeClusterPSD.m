function [meanPSDs] = computeClusterPSD(psdData, channelNames,regions)


    % Create a table to store the mean PSD values for each region
    meanPSDs = table();
    meanPSDs.Region = regions(:,1);
        
    % Initialize an array to store the mean PSD values
    meanValues = zeros(length(regions), length(psdData(1).Frequencies));
    
    % Compute the mean PSD for each region
    for i = 1:length(regions)
        regionChannels = regions{i, 2};
        regionPSDs = [];
        
        for j = 1:length(regionChannels)
            channelIdx = find(strcmp( {channelNames.labels}.', regionChannels{j}));
            if ~isempty(channelIdx)
                regionPSDs = [regionPSDs; psdData(channelIdx).PSD'];
            end
        end
        
        if ~isempty(regionPSDs)
            allData = horzcat(regionPSDs{:});
            meanValues(i, :) = mean(allData,2);
        end
    end
    
    % Add the mean PSD values to the table
    for k = 1:length(psdData(1).Frequencies)
        meanPSDs{:, k + 1} = meanValues(:, k);
    end
        
    % Add the frequency as the first row
    frequencies = [{'Frequency'}, num2cell(psdData(1).Frequencies')];
    meanPSDs = [frequencies; meanPSDs];


end
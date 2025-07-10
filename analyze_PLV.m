clear all
close all 

% LOAD EEG
folderpath= "C:\Users\FENNSI\Desktop\FENNSI\EEG_DOLOR\sujetos";
folders = dir(folderpath);
sujetos = {folders.name};
sujetos = sujetos(3:end-1); 
test = ["PRE" "POST" "PRE2" "POST2"];
ojostipo = ["OC" "OA"];

% Define cluster names
clusterNames = {'C3_proximity', 'C4_proximity', 'Left_Frontal', 'Right_Frontal', 'Left_frontocentral', ...
    'Right_frontocentral', 'Left_centroparietal', 'Right_centroparietal', 'Left_occitoparietal', ...
    'Right_occitoparietal', 'Left_Temporal', 'Right_Temporal'};

% Initialize a table to store the final results
resultsTable = table();

% Loop through each subject folder
for i = 1:length(sujetos)
    resultsTablewithinSubject = table();
    subjectName = sujetos(i);
    folderPath = fullfile(folderpath, subjectName);
    
    % Get a list of all relevant Excel files
    fileList_within = dir(fullfile(folderPath, '*_withinPLV.xlsx'));
    fileList_between = dir(fullfile(folderPath, '*_betweenPLV.xlsx'));
    
    % Initialize a structure to store the results for the current subject
    subjectResults = struct();
    
    % Loop through each file to compute the average PLV
    for j = 1:length(fileList_within)
        excelFileName = fullfile(folderPath, fileList_within(j).name);
        
        % Initialize a structure to store the results for the current file
        PLVData = struct();
        
        % Loop through each cluster to compute the average PLV
        for k = 1:length(clusterNames)
            clusterName = clusterNames{k};
            
            % Read the PLV matrix from the corresponding sheet in the Excel file
            PLV = readmatrix(excelFileName, 'Sheet', clusterName);
            PLV = PLV(:, 2:end);
            
            % Ensure diagonal elements are excluded
            n = size(PLV, 1);
            offDiagonalMask = ~eye(n);
            
            % Extract off-diagonal elements and compute their average
            offDiagonalValues = PLV(offDiagonalMask);
            averagePLV = mean(offDiagonalValues);
            
            % Store the result
            PLVData.(clusterName) = averagePLV;
        end
        
        % Store the results for the current file
        subjectResults.(fileList_within(j).name(1:end-5)) = PLVData;
    end

    % Loop through each file to compute the average PLV
    for j = 1:length(fileList_between)
        excelFileName = fullfile(folderPath, fileList_between(j).name);
        
        % Initialize a structure to store the results for the current file
        PLVData = struct();
        
       
            
        % Read the PLV matrix from the corresponding sheet in the Excel file
        PLV = readmatrix(excelFileName);
        PLV = PLV(:, 2:end);
        
        % Ensure diagonal elements are excluded
        n = size(PLV, 1);
        offDiagonalMask = ~eye(n);
        
        % Extract off-diagonal elements and compute their average
        offDiagonalValues = PLV(offDiagonalMask);
        averagePLV = mean(offDiagonalValues);

        
        
        % Store the results for the current file
        subjectResults.(fileList_between(j).name(1:end-5)) = averagePLV;
    end


    % Prepare data to be added to the table for the current subject
    conditionNames = fieldnames(subjectResults);
    for condIdx = 1:length(conditionNames)
        condition = conditionNames{condIdx};

            
        currentData = subjectResults.(condition);
        if contains(condition, '2')
            continue
        end
        
        % Prepare row for the table with all cluster results
        rowData = table();
        if contains(condition, 'between')
            rowData.(condition) = subjectResults.(condition);
            
        end
        for clusterIdx = 1:length(clusterNames)
            clusterName = clusterNames{clusterIdx};
            if isfield(currentData, clusterName)
                rowData.([condition '_', clusterName]) = currentData.(clusterName);
            else
                if contains(condition, 'between')
                    continue
                else
                    rowData.([condition '_', clusterName]) = NaN;
                end
            end
        end
        
        
        % Append to the main results table
        resultsTablewithinSubject = [resultsTablewithinSubject, rowData];
    end
    
    % Add the subject name as an identifier
    resultsTablewithinSubject.Subject = {subjectName};
    
    % Append to the main results table
    resultsTable = [resultsTable; resultsTablewithinSubject];
end

% Write the results table to an Excel file
outputExcelFile = 'C:\Users\FENNSI\Desktop\FENNSI\EEG_DOLOR\EEG_ANALYSIS\data_analysis\results_summary.xlsx';
writetable(resultsTable, outputExcelFile);
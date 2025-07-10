clear all
close all


%START EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; 
eeglab;


%LOAD EEG
% sujeto = ["8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21"];
folderpath= "C:\Users\FENNSI\Desktop\FENNSI\EEG_DOLOR\sujetos_faltan";
folders = dir(folderpath);
sujetos = {folders.name};
sujetos = sujetos(3:end); 
test = ["PRE" "POST" "PRE2" "POST2"];
ojostipo = ["OC" "OA"];
%%
% Define the regions and their corresponding channels (no esta el FCz en los dos frontocentrales ni CPP8h en centroparietal derecho)
regions = {
    'C3', {'C3'}
    'C4', {'C4'}
    'C3_proximity', {'FC5', 'FC3', 'FC1', 'C5', 'C3', 'C1', 'CP5', 'CP3', 'CP4'}
    'C4_proximity', {'FC2', 'FC4', 'FC6', 'C2', 'C4', 'C6', 'CP2', 'CP4', 'CP6'}
    'Left_Frontal', {'Fp1', 'Fpz', 'AF7', 'AF3', 'AFF5h', 'AFF1h', 'F5', 'F3', 'F1', 'Fz'}
    'Right_Frontal', {'Fpz', 'Fp2', 'AF4', 'AF8', 'AFF2h', 'AFF6h', 'Fz', 'F2', 'F4', 'F6'}
    'Left_frontocentral', {'FC5', 'FC3', 'FC1',  'FCC3h', 'FCC1h', 'C5', 'C3', 'C1', 'Cz'}
    'Right_frontocentral', {'FC2', 'FC4', 'FC6', 'FCC2h', 'FCC4h', 'FCC6h', 'Cz', 'C2', 'C4', 'C6'}
    'Left_centroparietal', {'CP5', 'CP3', 'CP1', 'CPz', 'TPP7h', 'CPP5h', 'CPP3h', 'CPP1h', 'P7', 'P5', 'P3', 'P1', 'Pz'}
    'Right_centroparietal', {'CPz', 'CP2', 'CP4', 'CP6', 'CPP2h', 'CPP4h', 'CPP6h',  'Pz', 'P2', 'P4', 'P6', 'P8'}
    'Left_occitoparietal', {'PO7', 'PO3', 'POz', 'POO1', 'O1', 'Oz', 'POO9h', 'PO9', 'Iz'}
    'Right_occitoparietal', {'POz', 'PO4', 'PO8', 'POO2', 'Oz', 'O2', 'POO10h', 'PO10', 'Iz'}
    'Left_Temporal', {'F9', 'F7', 'FT9', 'FT7', 'FTT9h', 'FTT7h', 'T7', 'TP9', 'TP7', 'TPP9h'}
    'Right_Temporal', {'F10', 'F8', 'FT10', 'FT8', 'FTT8h', 'FTT10h', 'T8', 'TP8', 'TP10', 'TPP10h'}
};

Fs=500;
for i = 1:length(sujetos)
    paciente = char(sujetos(i));
    for j = 1:length(test)
        prueba = char(test(j));
        if exist(fullfile(folderpath,paciente,prueba),'dir')
            for h = 1:length(ojostipo)
                ojos = ojostipo(h);
                currently = msgbox(strcat("Sujeto ", paciente, " Prueba ", prueba, " Ojos ", ojos),"Subject window");
                
                % Define path to the preprocessed file
                preprocFile = fullfile(folderpath, paciente, prueba, strcat('EEG_preprocess_', char(ojos), '.mat'));
                
                % Check if preprocessed file exists
                if exist(preprocFile, 'file')
                    % Load preprocessed EEG directly
                    load(preprocFile, 'EEG');
                    EEG = eeg_checkset(EEG); % sanity check
                else
                    % Preprocessed file not found, so load and preprocess raw EEG
                    if ojos == "OC"
                        if exist(fullfile(folderpath,paciente,prueba,"oc.vhdr"),'file') || exist(fullfile(folderpath,paciente,prueba,"OC.vhdr"),'file')
                
                            fileList = dir(fullfile(folderpath,paciente,prueba, '*.*'));
                            name = {fileList.name}.'; 
                            check = char(name(end));
                            if all(isstrprop(check(1), 'lower'))
                                EEG = pop_loadbv(fullfile(folderpath,paciente,prueba), 'oc.vhdr');
                            else
                                EEG = pop_loadbv(fullfile(folderpath,paciente,prueba), 'OC.vhdr');
                            end
                        end
                    elseif ojos == "OA"
                        if exist(fullfile(folderpath,paciente,prueba,"oa.vhdr"),'file') || exist(fullfile(folderpath,paciente,prueba,"OA.vhdr"),'file')
                            fileList = dir(fullfile(folderpath,paciente,prueba, '*.*'));
                            name = {fileList.name}.'; 
                            check = char(name(end));
                            if all(isstrprop(check(1), 'lower'))
                                EEG = pop_loadbv(fullfile(folderpath,paciente,prueba), 'oa.vhdr');
                            else
                                EEG = pop_loadbv(fullfile(folderpath,paciente,prueba), 'OA.vhdr');
                            end
                        end
                    end
                
                    % Preprocess and save
                    direc1 = char(fullfile(folderpath, paciente, prueba));
                    EEG = preprocess_EEG(EEG, direc1, ...
                        'C:\Users\FENNSI\Desktop\FENNSI\EEG_DOLOR\EEG_ANALYSIS\eeglab2021.1\plugins\dipfit\standard_BEM\elec\standard_1005.elc'); 
                    save(preprocFile, 'EEG')
                    
                    % Save also as .set
                    EEG = pop_saveset( EEG, 'filename', strcat('EEG_preprocess_', char(ojos), '.set'), 'filepath', direc1 );
                    EEG = eeg_checkset( EEG );
                end


                % Initialize a structure to hold the PSD data
                psdData = struct();

                % Initialize a cell array to hold the PSD values for each channel
                psdValues = cell(96, 1);
                
                % Initialize a cell array to hold the frequency values (assuming same for all channels)
                frequencies = [];
                                
                % Loop through each channel to compute and store the PSD
                length_interval=ones(1,EEG.nbchan).*length(EEG.data);
                [psd, freq, band_power_table] = calculate_eeg_psd(EEG,{EEG.chanlocs.labels},length_interval, Fs);
                for c = 1:length(EEG.chanlocs)
                    
                    psdData(c).ChannelName = string(EEG.chanlocs(c).labels);
                    psdData(c).PSD = psd(c);
                    psdData(c).Frequencies = freq;

                                
                end


                % Envelope 
                [envelopeTable, statsTable, regionStatsTable, psdTable, bandPowerTable]  = compute_envelope(EEG, regions, folderpath, strcat(paciente, '_', prueba, '_', ojos));

                
                writetable(band_power_table, fullfile(folderpath,paciente,strcat(paciente,"_frequency_bands.xlsx")),'Sheet', strcat(prueba,"_",ojos));
                % Get EEG data
                eegData = EEG.data; % EEG data matrix (channels x time points)
                channelNames = EEG.chanlocs; % Channel locations\labels structure
                
                % Define the low and high frequency bands (adjust these as necessary)
                lowFreqBand = [8 12]; % Alpha band for phase
                highFreqBand = [12 30]; % Gamma band for amplitude
                fs = EEG.srate; % Sampling frequency of the EEG data
                n_bins= 30;
            
                % Compute PAC matrix between clusters for the current channel(s)
                PACMatrix = compute_pac_interregion(eegData, channelNames, lowFreqBand, highFreqBand, fs, regions, n_bins);
                % writecell([regions(:,1)]',fullfile(folderpath,paciente,strcat(paciente,"_pacmatrix.xlsx")),'Sheet', strcat(prueba,"_",ojos),'Range',"B1")
                % writematrix(PACMatrix, fullfile(folderpath,paciente,strcat(paciente,"_pacmatrix.xlsx")),'Sheet', strcat(prueba,"_",ojos),'Range',"B2");
                % writecell([regions(:,1)],fullfile(folderpath,paciente,strcat(paciente,"_pacmatrix.xlsx")),'Sheet', strcat(prueba,"_",ojos),'Range',"A2")
                % 
                % imagesc(PACMatrix); 
                % colorbar;
                % xticks(1:14)
                % yticks(1:14)
                % xticklabels([regions(:,1)]);
                % yticklabels([regions(:,1)]);
                % saveas(gcf,fullfile(folderpath,paciente,strcat('pacmatrix_',prueba,'_',ojos,'.png')))
                % 

                % Compute PAC matrices for each region
                % phase_freqs = 4:1:12;  % Low frequencies (for phase extraction)
                % amp_freqs = 15:1:30;   % High frequencies (for amplitude extraction)
                % pac_matrices = compute_pac_regional(eegData, fs, regions, phase_freqs, amp_freqs,fullfile(folderpath,paciente,prueba), channelNames);

                meanPSDs = computeClusterPSD(psdData, EEG.chanlocs, regions);
                % Write the table to an Excel file
                writetable(meanPSDs, fullfile(folderpath,paciente,strcat(paciente,"_clusters.xlsx")), 'WriteVariableNames', false, 'Sheet',strcat(prueba,"_",ojos));

                freqBand= [8 12];
                % Compute and save PLV matrices within clusters
                plvWithinClusters(eegData, fs, freqBand, regions, channelNames,  fullfile(folderpath,paciente),strcat(prueba,'_',ojos));
                % 
                % % Compute and save PLV matrices between clusters
                plvBetweenClusters(eegData, fs, freqBand, regions, channelNames,  fullfile(folderpath,paciente),strcat(prueba,'_',ojos));

                %CREO EL EXCEL

                Channel = [];
                columna = "";
                if ojos == "OC" && prueba == "PRE"
                    columna = "A1";
                    colpsd = "A4";
                elseif ojos == "OA" && prueba == "PRE"
                    columna = "B1";
                    colpsd = "B4";
                elseif ojos == "OC" && prueba == "POST"
                    columna = "C1";
                    colpsd = "C4";
                elseif ojos == "OA" && prueba == "POST"
                    columna = "D1";
                    colpsd = "D4";
                elseif ojos == "OC" && prueba == "PRE2"
                    columna = "E1";
                    colpsd = "E4";
                elseif ojos == "OA" && prueba == "PRE2"
                    columna = "F1";
                    colpsd = "F4";
                elseif ojos == "OC" && prueba == "POST2"
                    columna = "G1";
                    colpsd = "G4";
                elseif ojos == "OA" && prueba == "POST2"
                    columna = "H1";
                    colpsd = "H4";
                end

                for i = 1:length(EEG.chanlocs)
                    Channel = string(EEG.chanlocs(i).labels);
                    completo = [Channel;ojos;prueba];
                    writematrix(completo,strcat(folderpath,"\",paciente,"\",paciente,".xlsx"),'Sheet',Channel,'Range',columna);
                end

                %FREQ ANALYSIS ONLY PSD

                for i = 1:length(EEG.chanlocs)
                    psd=psdData(i).PSD;
                    Channel = string(EEG.chanlocs(i).labels);

                    writematrix(psd{1,1},strcat(folderpath,"\",paciente,"\",paciente,".xlsx"),'Sheet',Channel,'Range', colpsd);
                end
                
            
            end
        else
            continue
        end
    end
    close all
end

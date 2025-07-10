function [EEG] = preprocess_EEG(EEG, pathtosave,standard_eeg)
    %START EEGLAB
    % [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; 
    % eeglab;
    % if endsWith(filename,'.vhdr')
    %     EEG = pop_loadbv(filename); %carga el eeg vhdr
    % elseif endsWith(filename,'.edf')
    %     EEG = pop_readedf(filename); %carga el eeg vhdr
    % end
    % [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 ); %saves the dataset in EEGLAB memory
    EEG = eeg_checkset( EEG ); %check the dataset consistency

    %CHANNELS

    EEG = pop_chanedit(EEG, 'lookup', standard_eeg);
    EEG = eeg_checkset( EEG );

    %FILTER 40-05

    EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'plotfreqz',1);
    EEG = pop_eegfiltnew(EEG, 'hicutoff',60,'plotfreqz',1);
    EEG.comments = pop_comments(EEG.comments,'','Filters applied, locutoff 0.5, hicutoff 40',1);
    EEG = eeg_checkset(EEG);

    %GUARDO ESTE DATASET PARA USARLO LUEGO

    direc1 = pathtosave;
    archivo1 = char('EEG_PRE');
    if isfile(strcat(direc1,archivo1))
        delete(strcat(direc1,archivo1,'.set'))
        EEG = pop_saveset( EEG,archivo1,direc1);
    else
        EEG = pop_saveset( EEG,archivo1,direc1);
        EEG = eeg_checkset( EEG );
    end

    %ASR

    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
    EEG.comments = pop_comments(EEG.comments,'','ASR applied 1',1);
    EEG = eeg_checkset(EEG);

    %CREO ARRAY CHANNELS PARA INTERPOLAR
    PostASR = [];
    for u = 1:length(EEG.chanlocs)
        PostASR(u) = EEG.chanlocs(u).urchan;
    end

    ChansPostASR = [];
    j = 1;
    for h = 1:length({EEG.chanlocs.labels})
        if j > length(PostASR)
                ChansPostASR(h) = 0;
                break;
        end
        if h == PostASR(j)
            ChansPostASR(h) = PostASR(j);
            %ChansPostASR(h) = h;
            j = j + 1;
        else
            ChansPostASR(h) = 0;
        end
    end

    Inter = find(ChansPostASR==0);
    InterNO = find(ChansPostASR~=0);

    %CARGO EL DATASET SIN ELIMINAR CANALES
    EEG = pop_loadset('EEG_PRE.set',direc1);

    %ASR SIN ELIMINAR CANALES
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
    % EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
    EEG.comments = pop_comments(EEG.comments,'','ASR applied 2',1);
    EEG = eeg_checkset(EEG);

    %ICA
    InterNO = find(ChansPostASR~=0);
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on','chanind',InterNO);
    EEG.comments = pop_comments(EEG.comments,'','Runica applied',1);
    EEG = eeg_checkset( EEG );

    %ELIMINAR COMPONENTES ICA
    EEG = pop_iclabel(EEG, 'default');
    IcaRem = zeros([1 length(EEG.etc.ic_classification.ICLabel.classifications)]);
    for k = 1:length(IcaRem)
%                 if (EEG.etc.ic_classification.ICLabel.classifications(k,1)<0.04) %brain
%                     IcaRem(k) = 1;
        if (EEG.etc.ic_classification.ICLabel.classifications(k,2)>0.1) %muscle
            IcaRem(k) = 1;
        elseif (EEG.etc.ic_classification.ICLabel.classifications(k,3)>0.1) %eye
            IcaRem(k) = 1;
        elseif (EEG.etc.ic_classification.ICLabel.classifications(k,4)>0.1) %heart
            IcaRem(k) = 1;
        elseif (EEG.etc.ic_classification.ICLabel.classifications(k,5)>0.1) %line noise
            IcaRem(k) = 1;
        elseif (EEG.etc.ic_classification.ICLabel.classifications(k,6)>0.1) %channel noise
            IcaRem(k) = 1;
        end
    end
    IcaRemBad = find(IcaRem==1);

    EEG = pop_subcomp( EEG, IcaRemBad, 0);
    EEG.comments = pop_comments(EEG.comments,'','ICA components removed',1);
    EEG = eeg_checkset( EEG );

    %INTERPOLACIÓN

    EEG = pop_interp(EEG, Inter,'spherical');
    EEG.comments = pop_comments(EEG.comments,'','Interpolation applied',1);
    EEG = eeg_checkset( EEG );

    

end
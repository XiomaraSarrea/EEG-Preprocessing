# EEG-Preprocessing

A MATLAB/EEGLAB pipeline for automated preprocessing of EEG data, spectral and connectivity analyses, and multi‐subject PLV summary.

## Table of Contents

- [Overview](#overview)    
- [Usage](#usage)  
- [File Descriptions](#file-descriptions)  

## Overview

This toolbox streamlines EEG data analysis by:

1. **Importing and cleaning** raw recordings  
2. **Computing** channel and cluster Power Spectral Density (PSD) and band‐limited amplitude envelopes  
3. **Estimating** Phase-Locking Value (PLV) within and between cortical clusters  
4. **Exporting** results to Excel.

All processing is built upon EEGLAB and MATLAB’s Signal Processing Toolbox.


## Usage

1. **Set your data path**  
   In `main_preprocessEEG_dolor.m`, update the `folderpath` variable to point at your folder of raw EEG files (*.vhdr/*.eeg).  
2. **Run preprocessing**  
   Launch MATLAB and run `main_preprocessEEG_dolor.m`. This will:
   - Start EEGLAB, load each subject file  
   - Filter (0.5-60 Hz), re-reference, detect bad channels (ASR), and perform ICA for artifact removal (`preprocess_EEG.m`)  
   - Compute each channel’s PSD (Welch function via `calculate_eeg_psd.m`)  
   - Extract amplitude envelopes per band (`compute_envelope.m`)  
   - Aggregate channel PSD into cluster means (`computeClusterPSD.m`)  
   - Calculate within- and between-cluster PLV (`plvWithinClusters.m`, `plvBetweenClusters.m`)  
   - Export all results as Excel sheets under each subject’s directory  
3. **Generate group PLV summary**  
   After preprocessing finishes for all subjects, run `analyze_PLV.m` to read the PLV spreadsheets across subjects, compute average off-diagonal PLV metrics, and write `results_summary.xlsx` in the root folder.

## File Descriptions

### `main_preprocessEEG_dolor.m`

- **Main script** that loops through subjects and conditions.  
- Calls all the individual preprocessing and analysis functions in the correct order.

---

### `analyze_PLV.m`

- **Reads** every `*_withinPLV.xlsx` and `*_betweenPLV.xlsx` output.  
- **Computes** the mean PLV (off-diagonal) per subject and cluster pair.  
- **Writes** a summary (`results_summary.xlsx`) for group‐level statistics.

---

### `preprocessing functions/`

- **`preprocess_EEG.m`**  
  Implements raw‐data cleaning:  
  - Bandpass filtering  
  - Re‐referencing and bad‐channel detection/interpolation (ASR) 
  - ICA decomposition, IC label classification and automatic artifact rejection  

- **`calculate_eeg_psd.m`**  
  Uses Welch’s method to compute PSD per channel, returning power spectral densities and band‐power summaries.

- **`compute_envelope.m`**  
  Filters the data into user‐defined bands, computes the Hilbert‐based amplitude envelope, and outputs channel‐ and region‐level envelope statistics.
 
- **`computeClusterPSD.m`**  
  Aggregates individual channel PSD results into cluster‐average spectra for region‐wise power comparisons.

- **`plvWithinClusters.m`**  
  Computes channel-to-channel Phase-Locking Value (PLV) matrices within each cluster.

- **`plvBetweenClusters.m`**  
  Computes PLV matrices between every pair of clusters, saving each as an Excel sheet for downstream analysis.

# Clinical Data Analysis Tools

This repository contains a set of R scripts designed for analyzing clinical data, focusing on identifying clinically significant results and correlating them with Adverse Events (AE) and Medical History (MH).

## Project Structure

The scripts are organized by clinical domain and analysis type:

### Analysis Scripts
- `analyze_ecg_ae_mh.R`: Correlates clinically significant ECG findings with patient Adverse Events and Medical History.
- `analyze_lab_ae.R`: Correlates lab results outside normal ranges with Adverse Events.
- `analyze_lab_ae_mh.R`: Correlates clinically significant lab results with Adverse Events and Medical History.
- `analyze_vs_ae_mh.R`: Correlates clinically significant Vital Signs with Adverse Events and Medical History.

### Data Quality & QC Scripts
- `check_lab_units.R`: Summarizes units used across different lab tests to identify inconsistencies.
- `check_lab_outliers.R`: Identifies suspicious lab results using Z-score analysis.
- `check_lab_errors.R`: Performs advanced checks for boundary violations and expected value outliers.

### Shared Logic
- `utils.R`: Contains common functions for data loading, cleaning, and merging to ensure consistency across all analysis scripts.

## Requirements

The scripts require the following R packages:
- `dplyr`
- `data.table`
- `readxl`
- `openxlsx`

## How it Works

1. **Data Loading**: Scripts read raw clinical data from Excel files (typically named like `LB_YYYYMMDD_HHMMSS.xlsx`).
2. **Filtering**: The tools filter for "clinically significant" records (e.g., where `LBCLSIG == 'Yes'` or `LBNRIND` is 'High'/'Low').
3. **Correlation**: For each patient with significant findings, the scripts pull all related Adverse Events and Medical History.
4. **Output**: Results are exported to Excel files for medical review, typically in a side-by-side format for easy comparison.

## Configuration

Paths to input files are currently hardcoded at the top of each script. Before running, ensure the paths in `utils.R` or the individual scripts point to your local data directories.

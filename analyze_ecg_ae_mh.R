source("utils.R")

# --- Configuration ---
paths <- list(
  eg = '~/Desktop/UKM-рабочее/EG_20240325_073355.xlsx',
  ae = '~/Desktop/UKM-рабочее/AE_20240325_070654.xlsx',
  mh = '~/Desktop/UKM-рабочее/MH_20240325_080702.xlsx',
  output = '~/Desktop/UKM-рабочее/res/EGAEMH.xlsx'
)

# --- Load Data ---
message("Loading ECG, AE, and MH data...")
eg_df <- load_clinical_data(paths$eg)
ae_df <- load_clinical_data(paths$ae)
mh_df <- load_clinical_data(paths$mh)

# --- Filter ECG for Clinically Significant Results ---
message("Filtering for clinically significant ECG results...")
# Keep relevant columns
eg_df <- eg_df[, .(USUBJID, EGTEST, EGORRES, EGORRESU, VISIT, EGDTC, EGDY, EGCLSIG)]

# Identify patients/tests with clinically significant findings
positive_findings <- eg_df[EGCLSIG == 'Yes', .(USUBJID, EGTEST)] %>% distinct()

# Filter full dataset to keep all records for those specific patient-test combinations
sel_data <- eg_df[USUBJID %in% positive_findings$USUBJID & EGTEST %in% positive_findings$EGTEST]

# --- Merge with AE and MH ---
message("Merging with Adverse Events and Medical History...")
ae_sel_cols <- ae_df[, .(USUBJID, AETERM, AESEV, AESTDTC, AEENDTC, AESTDY, AEENDY, AEENRF, AESEQ)]
mh_sel_cols <- mh_df[, .(USUBJID, MHTERM, MHSTDTC, MHENDTC, MHENRF)]

merged_table <- merge_clinical_data(
  domain_df = sel_data, 
  ae_df = ae_sel_cols, 
  mh_df = mh_sel_cols, 
  test_col = "EGTEST"
)

# --- Save Results ---
message("Saving results to: ", paths$output)
write.xlsx(merged_table, paths$output)
message("Done.")

source("utils.R")

# --- Configuration ---
paths <- list(
  expected = '~/Desktop/WORK/TNP-STEMI-III/2024.03.29_Ожидаемые значения лабораторных показателей.xlsx',
  lb = '~/Desktop/WORK/TNP-STEMI-III/LB_20240325_121009.xlsx',
  output_dir = '~/Desktop/WORK/TNP-STEMI-III/'
)

# --- Load Data ---
message("Loading data and expected values...")

# Expected values for clinical sanity checks
expected_values <- read_excel(
  path = paths$expected,
  col_names = c('Res_ID', 'Test_type', 'Test', 'Units', 'Low_limit', 'High_limit'),
  skip = 1
) %>% filter(Res_ID == 'TNP-STEMI-III')

# Lab data
dt <- load_clinical_data(paths$lb)
dt <- clean_numeric_data(dt, c("LBORRES", "LBORNRLO", "LBORNRHI"))

# Filter for relevant categories
if ("LBCAT" %in% names(dt)) {
  dt <- dt[LBCAT %in% c("Complete blood count", "Blood chemistry")]
}

# --- 1. Boundary Violations ---
message("Checking for boundary violations (inconsistent reference ranges)...")
bad_data_summary <- get_boundary_violations(dt)

# Get full details for those violations
bad_data_details <- dt[USUBJID %in% bad_data_summary$USUBJID & LBTEST %in% bad_data_summary$LBTEST]

# --- 2. Expected Value Outliers ---
message("Comparing against expected values...")
outliers <- find_outliers(dt, expected_values)

# --- Save Results ---
message("Saving QC results...")
write.xlsx(bad_data_details, paste0(paths$output_dir, 'LB_limits_changed.xlsx'))
write.xlsx(outliers$results_outliers, paste0(paths$output_dir, 'LB_results_outliers.xlsx'))
write.xlsx(outliers$limits_outliers, paste0(paths$output_dir, 'LB_limits_outlier.xlsx'))

message("Done.")

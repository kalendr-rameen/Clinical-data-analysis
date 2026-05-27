source("utils.R")

# --- Configuration ---
paths <- list(
  lb = '~/Desktop/UKM-рабочее/LB_20240325_073918.xlsx',
  output = '~/Desktop/UKM-рабочее/res/LB_suspicious_results.xlsx'
)

# --- Load and Clean Data ---
message("Loading Lab data for outlier analysis...")
df <- load_clinical_data(paths$lb)
df <- clean_numeric_data(df, "LBORRES")

# --- Unit Normalization ---
# Example: Normalize Hemoglobin to g/L if it's in g/dL
df[LBTEST == 'Hemoglobin' & LBORRESU == 'g/dL', LBORRES := LBORRES * 10]

# --- Calculate Screening Statistics (Visit 1) ---
message("Calculating screening visit statistics...")
stats <- df[VISITNUM == '1', .(
  mean_val = mean(LBORRES, na.rm = TRUE),
  sd_val = sd(LBORRES, na.rm = TRUE)
), by = LBTEST]

# Merge stats back to main dataframe
df <- merge(df, stats, by = "LBTEST", all.x = TRUE)

# --- Identify Outliers ---
message("Identifying outliers (Z-score > 3.5)...")
df[, z_score := (LBORRES - mean_val) / sd_val]

# Flag outliers: Z-score > 3.5, NOT Normal range indicator, and NOT clinically significant (per original script logic)
outliers <- df[(abs(z_score) > 3.5) & (LBNRIND != 'Normal') & (LBCLSIG == 'No')]

# --- Post-process and Cleanup ---
# Revert unit normalization for output if needed
outliers[LBTEST == 'Hemoglobin' & LBORRESU == 'g/dL', LBORRES := LBORRES / 10]

# Select final columns
final_cols <- setdiff(names(outliers), c("mean_val", "sd_val", "z_score"))
outliers_output <- outliers[, ..final_cols]

# --- Save Results ---
message("Saving outliers to: ", paths$output)
write.xlsx(outliers_output, paths$output)
message("Done.")

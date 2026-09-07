# Install and load required libraries
install.packages("pdftools")
library(pdftools)
library(dplyr)
library(stringr)

# Define folder paths
raw_pdf_dir <- "data/raw/"    # take input from raw
txt_out_dir <- "data/interim/"    #populate converted files here

# Get list of all PDF files
pdf_files <- list.files(raw_pdf_dir, pattern = "\\.pdf$", full.names = TRUE)

# To keep track of how many documents are successfully coverted from pdf to txt
counter <- 0

# Loop through each PDF, extract text, and save as .txt
for (pdf_path in pdf_files) {
  # Extract text page by page
  raw_text <- pdf_text(pdf_path)
  
  # Combine all pages into a single character string
  full_transcript <- paste(raw_text, collapse = "\n\n")
  
  # Generate output filename
  base_name <- tools::file_path_sans_ext(basename(pdf_path))
  out_path <- file.path(txt_out_dir, paste0(base_name, ".txt"))
  
  # Save clean text file
  writeLines(full_transcript, out_path)
  cat("Successfully converted:", base_name, "\n")
  
  counter <- counter + 1
}

cat("Total documents converted:", counter, "\n")

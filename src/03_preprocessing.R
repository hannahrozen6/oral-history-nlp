library(tidyverse)
library(tidytext)
library(fs)

# Load text files from interim folder
interim_dir <- "data/interim/"
processed_dir <- "data/processed/"
txt_files <- list.files(interim_dir, pattern = "\\.txt$", full.names = TRUE)

# Checks that txt files exist and are in correct location
# Change == 0 to != 150 or however many files there actually are
if (length(txt_files) == 0) {
  stop("No .txt files found in data/interim/! Run 01_pdf_to_txt.R on all raw PDF files first.")
}

# Define custom stop words table
custom_stops <- tibble(
  word = c("interviewer", "speaker", "transcript", "yeah", "um", "uh", 
           "you know", "i mean", "okay", "question", "answer", "interview", 
           "like", "applause", "laughter", "crosstalk")
)

# Loop through each txt file: clean and tokenize
for (file_path in txt_files) {
  
  # Read full file as a character vector (one string per line or entire file)
  raw_text <- read_lines(file_path)
  
  cleaned_text <- raw_text %>%
    # Fix broken line breaks (rejoin lines split in middle of sentence)
    str_c(collapse = "\n") %>%
    str_replace_all("(?<=[a-z,-])\n(?=[a-z])", " ") %>%
    
    # Remove time stamp markers (e.g., [00:12:34] or 01:23:45)
    str_remove_all("\\[?\\b\\d{1,2}:\\d{2}(:\\d{2})?\\b\\]?") %>%
    
    # Remove page headers (e.g., "Page 1 of 10" or "HEADER: ...")
    str_remove_all("(?i)page\\s+\\d+\\s+of\\s+\\d+") %>%
    
    # Remove standalone page numbers
    str_remove_all("(?m)^\\s*\\d+\\s*$") %>%
    
    # Anything else? (Remove transcript noise/brackets like [LAUGHTER], web URLs, excess whitespace)
    str_remove_all("\\[.*?\\]|\\(.*?\\)") %>%
    str_remove_all("http\\S+|www\\.\\S+") %>%
    str_squish() %>%
    
    # Remove capitalization
    str_to_lower() %>%
    
    # Remove remaining punctuation (retains word-internal apostrophes optionally, or clears all)
    str_replace_all("[[:punct:]]", " ") %>%
    str_squish()
  
  # Convert back to tibble for tidytext operations
  text_df <- tibble(text = cleaned_text)
  
  # Tokenize before Filtering: Convert text to unigrams
  tokens <- text_df %>%
    unnest_tokens(word, text) %>%
    # Remove standard English stop words + custom filler words
    anti_join(stop_words, by = "word") %>%
    anti_join(custom_stops, by = "word") %>%
    # Remove numeric tokens
    filter(!str_detect(word, "^\\d+$"))
  
  # Verify Tokenization: Basic sanity check inline
  if (nrow(tokens) == 0) {
    warning(paste("File resulted in 0 tokens after cleaning:", file_path))
  }
  
  # Add modified file to data/processed
  out_filename <- file.path(processed_dir, basename(file_path))
  write_csv(tokens, out_filename)
}

# 3. Final Verification Check
interim_count <- length(txt_files)
processed_files <- list.files(processed_dir, pattern = "\\.txt$", full.names = TRUE)
processed_count <- length(processed_files)

message(sprintf("Verification Summary:\n - Input files: %d\n - Output files: %d", interim_count, processed_count))

if (interim_count != processed_count) {
  stop("Mismatch in file count between data/interim/ and data/processed/!")
} else {
  message("Success: All files were cleaned, tokenized, and exported to data/processed/")
}
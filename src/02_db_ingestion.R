# Install and load required libraries
# install.packages(c("DBI", "RSQLite", "readr", "stringr"))
library(DBI)
library(RSQLite)
library(stringr)

# 1. Helper Functions

# Helper to handle NULL/NA defaults
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || all(is.na(a))) b else a

## Parse header metadata: contains speaker, interview date, location, interviewer, and length
parse_header_metadata <- function(text_content) {
  # Limit search to the first 2,000 characters to prevent matching transcript body text
  header_chunk <- substr(text_content, 1, 2000)
  
  # Speaker(s) - Handles "Interviewee:" or "Interviewees:"
  speaker_val <- str_match(header_chunk, "(?i)Interviewees?:\\s*([^\r\n]+)")[,2]
  speaker_val <- str_squish(speaker_val) %||% "Unknown"  # return Unknown by default if not found
  
  # Interview Date - Captures dates and multi-day formats
  interview_date_val <- str_match(header_chunk, "(?i)Interview Date:\\s*([^\r\n]+)")[,2]
  interview_date_val <- str_squish(interview_date_val) %||% "Unknown"
  
  # Location - Extracts full location line
  location_val <- str_match(header_chunk, "(?i)Location:\\s*([^\r\n]+)")[,2]
  location_val <- str_squish(location_val) %||% "Unknown"
  
  # Interviewer - Captures interviewer name(s)
  interviewer_val <- str_match(header_chunk, "(?i)Interviewer:\\s*([^\r\n]+)")[,2]
  interviewer_val <- str_squish(interviewer_val) %||% "Unknown"
  
  # Length - Extracts duration string
  length_val <- str_match(header_chunk, "(?i)Length:\\s*([^\r\n]+)")[,2]
  length_val <- str_squish(length_val) %||% "Unknown"
  
  return(list(
    speaker        = speaker_val,
    interview_date = interview_date_val,
    location       = location_val,
    interviewer    = interviewer_val,
    length         = length_val
  ))
}

# 2. Database Connection & Schema Setup

# Connect to the SQLite database in the project's data/interim folder
db_path <- "data/interim/testimonies_interim.db"
con <- dbConnect(RSQLite::SQLite(), db_path)

# Drop old table to allow for updates in code (e.g. adding schema, fixing bugs, etc)
# Can drop this line and change CREATE TABLE to CREATE TABLE IF NOT EXISTS once schema is finalized
dbExecute(con, "DROP TABLE IF EXISTS testimonies_interim")

# Create the table schema
# TO DO: Add additional columns (see db construction doc)
dbExecute(con, "
  CREATE TABLE testimonies_interim (
    interview_id TEXT PRIMARY KEY,
    speaker TEXT,
    interview_date TEXT,
    location TEXT,
    interviewer TEXT, 
    length TEXT,
    raw_text TEXT
  )
")

# 3. File Ingestion

# Load text files in interim folder 
txt_files <- list.files("data/interim/", pattern = "\\.txt$", full.names = TRUE)

# Checks that txt files exist and are in correct location
# Change == 0 to != 150 or however many files there actually are
if (length(txt_files) == 0) {
  stop("No .txt files found in data/interim/! Run 01_pdf_to_txt.R on all raw PDF files first.")
}

# Ingest each text file into the database
for (file_path in txt_files) {
  # Extract unique ID from file name (e.g., "interview_001.txt" -> "interview_001")
  file_id <- tools::file_path_sans_ext(basename(file_path))
  
  # Read full transcript text
  text_content <- readChar(file_path, file.info(file_path)$size)

  # Parse header metadata
  header <- parse_header_metadata(text_content)
  
  # Insert into database using parameterized query (prevents SQL injection/syntax errors)
  dbExecute(con, "
    INSERT OR REPLACE INTO testimonies_interim (interview_id, speaker, interview_date, location, interviewer, length, raw_text)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ", params = list(
    file_id, 
    header$speaker, 
    header$interview_date, 
    header$location, 
    header$interviewer, 
    header$length, 
    text_content
  ))
  
  cat("Ingested into database:", file_id, "\n")
}

# 4. Verification Queries

# Verify data was loaded correctly
print(dbGetQuery(con, "SELECT interview_id, speaker, interview_date, location, substr(raw_text, 1, 50) AS snippet FROM testimonies_interim LIMIT 5"))

# Return the number of rows to verify all records are in db
print(dbGetQuery(con, "SELECT COUNT(*) AS total_rows FROM testimonies_interim"))

# Close the connection when finished
dbDisconnect(con)
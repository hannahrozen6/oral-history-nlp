# oral-history-nlp
An end-to-end NLP data pipeline and interactive Shiny dashboard analyzing oral history transcripts from the Library of Congress Civil Rights History Project.

## Project Overview
This repository contains a full-scale text mining and natural language processing (NLP) pipeline built to analyze oral history transcripts from the Library of Congress Civil Rights History Project. Initiated under the Civil Rights History Project Act of 2009, this archive documents firsthand accounts of activists, grassroots leaders, and community members during the 1950s and 60s freedom struggle. 

This project aims to convert raw, unstructured oral history transcript PDFs into a clean, structured relational database (SQLite), extract metadata using rule-based regular expressions, and apply advanced NLP techniques—including topic modeling (LDA), TF-IDF vocabulary distributions, and sentiment trajectories. An interactive R Shiny application serves as the user-facing interface for dynamic exploration.

## Repository Structure
```text
oral-history-nlp-ads/
├── data/
│   ├── raw/                # Unprocessed transcript PDF files
│   ├── interim/            # Converted plain .txt files
│   └── processed/          # Cleaned CSVs and SQLite database file (testimonies.db)
├── src/
│   ├── 01_pdf_to_txt.R     # Extracts raw text from PDFs in data/raw/ to data/interim/
│   ├── 02_db_ingestion.R   # Constructs and populates the SQLite database schema
│   ├── 03_preprocessing.R  # Tokenization, custom stopword filtering, line-break/header cleaning
│   ├── 04_nlp_modeling.R   # LDA Topic Modeling, TF-IDF, and sentiment trajectory engines
│   └── 05_dashboard.R      # Interactive visualization app (R Shiny)
├── oral-history-nlp-ads.Rproj
└── README.md

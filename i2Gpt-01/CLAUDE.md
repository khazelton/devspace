# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Python web scraping project designed to crawl and parse Internet2 Grouper wiki documentation pages, converting them to Markdown format for later processing.

## Development Environment Setup

### Dependencies
Install required Python packages:
```bash
pip install requests beautifulsoup4 markdownify
```

## Common Development Commands

### Running the Script
```bash
python scanChunk.py
```

### Code Quality
Since no linting or testing framework is currently set up, consider running basic Python syntax checks:
```bash
python -m py_compile scanChunk.py
```

## Code Architecture

### Main Script: scanChunk.py
The script is intended to:
1. Fetch content from Internet2 Grouper wiki pages
2. Parse HTML content using BeautifulSoup
3. Convert HTML to Markdown using markdownify
4. Save the scraped content to `grouper_docs.json`

### Known Issues
The current code has syntax errors mixing Python and JavaScript-like syntax that need to be fixed:
- Line 9: Uses `const` instead of Python variable declaration
- Line 18: Uses `then` instead of Python's `:` for conditionals
- Line 24: Missing closing parenthesis
- Function `fetch_page()` is not properly indented and has incorrect flow

## Working with This Codebase

When fixing or extending this script:
1. Ensure proper Python syntax throughout
2. Handle HTTP errors and exceptions appropriately
3. Consider adding rate limiting to be respectful to the target server
4. The script expects to find content in a div with id='main-content' - verify this matches the actual page structure
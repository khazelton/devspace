# Python Script to Crawl and Parse Pages
# Install dependencies:
# pip install requests beautifulsoup4 markdownify

import requests
from bs4 import BeautifulSoup
from markdownify import markdownify as md

urls = [
    'https://spaces.at.internet2.edu/display/Grouper/Grouper+provisioning+framework',
    'https://spaces.at.internet2.edu/display/Grouper/Grouper+Loader',
    # Add more wiki URLs here
]

def fetch_page(url):
    headers = {'User-Agent': 'Mozilla/5.0'}
    resp = requests.get(url, headers=headers)
    if resp.status_code != 200:
        return None
    
    soup = BeautifulSoup(resp.text, 'html.parser')
    content = soup.find('div', {'id': 'main-content'})
    if not content:
        return None
    return md(str(content))

docs = {}
for url in urls:
    md_text = fetch_page(url)
    if md_text:
        docs[url] = md_text
        print(f"Fetched: {url}")

# Save for later embedding
import json
with open('grouper_docs.json', 'w') as f:
    json.dump(docs, f, indent=2)

# This will save a JSON file with URLs as keys and Markdown-formatted content as values.
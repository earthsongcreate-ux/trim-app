import re
import difflib
from datetime import datetime
from collections import defaultdict
from typing import List, Dict, Any

MERCHANT_MAP = {
    "amzn": "Amazon",
    "amazon": "Amazon",
    "netflix": "Netflix",
    "nflx": "Netflix",
    "spotify": "Spotify",
    "uber": "Uber",
    "lyft": "Lyft",
    "hulu": "Hulu",
    "apple": "Apple",
    "doordash": "DoorDash",
    "disney": "Disney+"
}

CATEGORY_MAP = {
    "Netflix": "subscription",
    "Spotify": "subscription",
    "Hulu": "subscription",
    "Apple": "subscription",
    "Disney+": "subscription",
    "Uber": "transport",
    "Lyft": "transport",
    "Amazon": "shopping",
    "DoorDash": "food"
}

def clean_text(text: str) -> str:
    """Removes symbols, numbers, and whitespaces from text, returns lowercase."""
    if not text:
        return ""
    # Remove non-alphabetical characters
    cleaned = re.sub(r'[^a-zA-Z\s]', '', text)
    return cleaned.lower().strip()

def parse_date(date_str: str) -> datetime:
    return datetime.strptime(date_str, "%Y-%m-%d")

def normalize_transactions(raw_transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Normalizes a list of raw Plaid transactions into clean, structured records.
    """
    processed = []
    
    # STEP 1, 2 & 3: Clean, Map Merchant, and Classify
    for txn in raw_transactions:
        # Prefer merchant_name if available, fallback to name
        raw_name = txn.get('merchant_name') or txn.get('name', '')
        cleaned_name = clean_text(raw_name)
        
        merchant = None
        confidence = 0.50
        
        # Attempt direct substring match first
        for key, value in MERCHANT_MAP.items():
            if key in cleaned_name:
                merchant = value
                confidence = 0.95
                break
                
        # Attempt fuzzy matching if no direct match
        if not merchant and cleaned_name:
            matches = difflib.get_close_matches(cleaned_name, MERCHANT_MAP.keys(), n=1, cutoff=0.7)
            if matches:
                merchant = MERCHANT_MAP[matches[0]]
                confidence = 0.85
        
        # Fallback to original name if unmapped
        if not merchant:
            merchant = raw_name.strip()
            confidence = 0.40
            
        category = CATEGORY_MAP.get(merchant, "uncategorized")
        
        processed.append({
            "merchant": merchant,
            "display_name": merchant.title() if confidence >= 0.85 else merchant,
            "category": category,
            "amount": txn.get('amount', 0.0),
            "date": txn.get('date'),
            "confidence": confidence,
            "type": "one-time" # Default
        })
        
    # STEP 4: Transaction Type (Recurrence Detection)
    grouped_txns = defaultdict(list)
    for pt in processed:
        grouped_txns[pt['merchant']].append(pt)
        
    for merchant, txns in grouped_txns.items():
        if len(txns) < 2 or merchant == "":
            continue
            
        # Sort chronologically
        sorted_txns = sorted(txns, key=lambda x: parse_date(x['date']))
        
        for i in range(1, len(sorted_txns)):
            prev = sorted_txns[i-1]
            curr = sorted_txns[i]
            
            d1 = parse_date(prev['date'])
            d2 = parse_date(curr['date'])
            days_diff = (d2 - d1).days
            
            # Recurrence rule: 25-35 days apart and identical amounts
            if 25 <= days_diff <= 35 and prev['amount'] == curr['amount']:
                prev['type'] = "recurring"
                curr['type'] = "recurring"
                
                # STEP 5: Boost confidence due to pattern consistency
                prev['confidence'] = min(1.0, prev['confidence'] + 0.10)
                curr['confidence'] = min(1.0, curr['confidence'] + 0.10)
                
    # Prepare final output structure
    normalized_output = []
    for pt in processed:
        normalized_output.append({
            "merchant": pt['merchant'],
            "display_name": pt['display_name'],
            "category": pt['category'],
            "type": pt['type'],
            "amount": pt['amount'],  # Passed through for downstream engines
            "date": pt['date'],      # Passed through for downstream engines
            "confidence": round(pt['confidence'], 2)
        })
        
    return normalized_output

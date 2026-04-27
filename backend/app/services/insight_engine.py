from datetime import datetime
from collections import defaultdict
from typing import List, Dict, Any

def parse_date(date_str: str) -> datetime:
    """Parses a date string in YYYY-MM-DD format."""
    return datetime.strptime(date_str, "%Y-%m-%d")

def generate_insights(transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Analyzes a list of transactions to generate financial insights.
    
    Expected transaction format:
    {
        "name": str,
        "amount": float,
        "date": str (YYYY-MM-DD)
    }
    """
    insights = []
    
    # Group transactions by merchant name
    grouped_txns = defaultdict(list)
    for txn in transactions:
        grouped_txns[txn['name']].append(txn)
        
    for merchant, txns in grouped_txns.items():
        if len(txns) < 2:
            continue
            
        # Sort transactions chronologically
        sorted_txns = sorted(txns, key=lambda x: parse_date(x['date']))
        
        is_subscription = False
        price_increased = False
        
        for i in range(1, len(sorted_txns)):
            prev = sorted_txns[i-1]
            curr = sorted_txns[i]
            
            d1 = parse_date(prev['date'])
            d2 = parse_date(curr['date'])
            days_diff = (d2 - d1).days
            
            # RULE 3: Duplicate Charges
            # Same merchant, same amount, within 24 hours (<= 1 day)
            if days_diff <= 1 and prev['amount'] == curr['amount']:
                insights.append({
                    "type": "duplicate",
                    "title": f"Duplicate charge detected for {merchant}",
                    "amount": curr['amount'],
                    "confidence": "high"
                })
            
            # RULE 1 & 2: Subscriptions and Price Increases
            # Check for monthly recurrence roughly 25 to 35 days apart
            if 25 <= days_diff <= 35:
                if curr['amount'] == prev['amount']:
                    is_subscription = True
                elif curr['amount'] > prev['amount']:
                    is_subscription = True
                    price_increased = True
                    insights.append({
                        "type": "price_increase",
                        "title": f"Price increase detected for {merchant}",
                        "amount": curr['amount'],
                        "confidence": "high"
                    })
        
        if is_subscription:
            last_amount = sorted_txns[-1]['amount']
            
            # Add primary subscription insight
            insights.append({
                "type": "subscription",
                "title": f"{merchant} subscription detected",
                "amount": last_amount,
                "confidence": "high"
            })
            
            # RULE 4: Unused Subscriptions (Mock Logic)
            # If it's a stable subscription and hasn't had a price increase recently,
            # we arbitrarily flag it as potentially unused for the user to review.
            if not price_increased:
                 insights.append({
                    "type": "unused_subscription",
                    "title": f"Review {merchant} usage. Suggest cancellation?",
                    "amount": last_amount,
                    "confidence": "medium"
                })

    return insights

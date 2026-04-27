import plaid
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.transactions_get_request import TransactionsGetRequest
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from app.core.config import settings

# Determine Plaid environment URL
if settings.PLAID_ENV == "production":
    host = plaid.Environment.Production
elif settings.PLAID_ENV == "development":
    host = plaid.Environment.Development
else:
    host = plaid.Environment.Sandbox

# Configure Plaid client
configuration = plaid.Configuration(
    host=host,
    api_key={
        'clientId': settings.PLAID_CLIENT_ID,
        'secret': settings.PLAID_SECRET,
        'plaidVersion': '2020-09-14'
    }
)

api_client = plaid.ApiClient(configuration)
client = plaid_api.PlaidApi(api_client)

def create_link_token() -> str:
    """
    Generate a Plaid link_token for frontend initialization.
    """
    request = LinkTokenCreateRequest(
        products=[Products("transactions")],
        client_name="Trim",
        country_codes=[CountryCode("US")],
        language="en",
        user=LinkTokenCreateRequestUser(
            client_user_id="test-user"
        )
    )
    
    response = client.link_token_create(request)
    return response['link_token']

def exchange_public_token(public_token: str) -> dict:
    """
    Exchanges a temporary public_token for a permanent access_token.
    """
    request = ItemPublicTokenExchangeRequest(
        public_token=public_token
    )
    
    response = client.item_public_token_exchange(request)
    return {
        "access_token": response['access_token'],
        "item_id": response['item_id']
    }

from datetime import date

def fetch_transactions(access_token: str, start_date: date, end_date: date) -> list:
    """
    Fetch up to 90 days of transaction data from Plaid for a connected item.
    """
    request = TransactionsGetRequest(
        access_token=access_token,
        start_date=start_date,
        end_date=end_date,
    )
    
    response = client.transactions_get(request)
    return response['transactions']

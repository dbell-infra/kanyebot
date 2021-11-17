import requests


def get_quote():
    quote = requests.get('https://api.kanye.rest')
    return quote.json()['quote']


print(get_quote())
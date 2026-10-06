"""Read-only connectivity and anonymous authorization checks; never prints keys."""
import json
import urllib.error
import urllib.request
from pathlib import Path

config = json.loads(Path('config/development.json').read_text())
base = config['SUPABASE_URL']
headers = {'apikey': config['SUPABASE_PUBLISHABLE_KEY']}
request = urllib.request.Request(base + '/auth/v1/settings', headers=headers)
with urllib.request.urlopen(request, timeout=20) as response:
    settings = json.load(response)
print('Auth endpoint reachable')
for provider in ['google', 'apple', 'email']:
    print(f'{provider}: {settings.get("external", {}).get(provider, False)}')
for table in ['profiles', 'categories', 'sources', 'transactions']:
    request = urllib.request.Request(base + '/rest/v1/' + table + '?select=*&limit=1', headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            raise AssertionError(f'Anonymous request unexpectedly succeeded: {table}')
    except urllib.error.HTTPError as error:
        assert error.code in (401, 403), (table, error.code)
        print(f'{table}: anonymous access denied ({error.code})')

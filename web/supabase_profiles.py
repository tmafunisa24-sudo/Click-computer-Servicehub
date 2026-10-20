import os
import sys
import urllib.error
import urllib.request


def main() -> int:
    supabase_url = os.getenv("SUPABASE_URL")
    api_key = os.getenv("SUPABASE_API_KEY")
    if not supabase_url or not api_key:
        print(
            "Set SUPABASE_URL and SUPABASE_API_KEY environment variables.",
            file=sys.stderr,
        )
        return 2

    bearer_token = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or api_key
    headers = {
        "apikey": api_key,
        "Authorization": f"Bearer {bearer_token}",
    }
    url = (
        f"{supabase_url.rstrip('/')}/rest/v1/profiles"
        "?select=id,user_id,email,full_name,role&limit=100"
    )
    request = urllib.request.Request(url, headers=headers)

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            print("STATUS", response.status)
            print(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        print(f"Supabase request failed with HTTP {error.code}.", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

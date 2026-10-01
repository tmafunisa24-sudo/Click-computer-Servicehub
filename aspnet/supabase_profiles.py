import urllib.request as r
headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjZm5pcGhkcmdvb25zdmlhdHduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzMjI5NDAsImV4cCI6MjEwMDg5ODk0MH0.BSzfH3YyMI-A4Qz-5Z2knzgRHin31k9kZx5mzclkv5o',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjZm5pcGhkcmdvb25zdmlhdHduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzMjI5NDAsImV4cCI6MjEwMDg5ODk0MH0.BSzfH3YyMI-A4Qz-5Z2knzgRHin31k9kZx5mzclkv5o'
}
uri = 'https://qcfniphdrgoonsviatwn.supabase.co/rest/v1/profiles?select=id,user_id,email,full_name,role&limit=100'
req = r.Request(uri, headers=headers)
with r.urlopen(req) as resp:
    print('STATUS', resp.status)
    print(resp.read().decode('utf-8'))

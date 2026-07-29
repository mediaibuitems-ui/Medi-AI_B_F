import urllib.request
import json
import ssl

url = "https://api.groq.com/openai/v1/chat/completions"
headers = {
    "Authorization": "Bearer [INSERT_YOUR_GROQ_API_KEY]",
    "Content-Type": "application/json"
}
data = json.dumps({
    "model": "llama3-8b-8192",
    "messages": [{"role": "user", "content": "hello"}]
}).encode("utf-8")

req = urllib.request.Request(url, data=data, headers=headers)
context = ssl.create_default_context()
try:
    with urllib.request.urlopen(req, context=context) as response:
        result = json.loads(response.read().decode())
        print("SUCCESS:", result["choices"][0]["message"]["content"])
except urllib.error.HTTPError as e:
    print("ERROR:", e.code, e.read().decode())
except Exception as e:
    print("EXCEPTION:", str(e))

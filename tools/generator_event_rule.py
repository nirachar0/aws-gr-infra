import os
import sys
import json
import argparse

try:
    import openai as OpenAI
except Exception:
    print("Install dependencies: pip install -r tools/requirements.txt")
    raise

DEFAULT_OUT = os.path.join(os.path.dirname(__file__), "..", "event.json")
SYSTEM_PROMPT = (
    "You are a generator that outputs exactly one JSON object representing an AWS EventBridge rule payload "
    "suitable for Terraform's 'event_pattern' or a full rule file. Output ONLY JSON (no markdown, no commentary). "
    "Follow this shape: {\"source\": [...], \"detail-type\": [...], \"detail\": {...}}. Respect provided template if present."
)

def call_openai(messages, model="gpt-4o-mini"):
    key = os.getenv("OPENAI_API_KEY")
    if not key:
        print("OPENAI_API_KEY not set in environment.")
        sys.exit(2)
    client = OpenAI.Client(
        api_key=key,
    )
    resp = client.responses.create(model=model, instructions=SYSTEM_PROMPT, input=messages, max_output_tokens=800)
    return resp.output_text

def validate_json_str(s):
    try:
        return True, json.loads(s)
    except json.JSONDecodeError as e:
        return False, str(e)

def main():
    p = argparse.ArgumentParser(description="Generate EventBridge rule JSON using OpenAI.")
    p.add_argument("-p", "--prompt", help="Natural language description (or leave empty to use default for CreateBucket).")
    p.add_argument("-o", "--out", default=DEFAULT_OUT, help="Output path for event JSON")
    p.add_argument("--model", default="gpt-4o-mini")
    args = p.parse_args()

    default_example = {
        "eventSource": "s3.amazonaws.com",
        "eventName": "CreateBucket",
        "recipientAccountId": "253645728653",
        "detail-type": "AWS API Call via CloudTrail"
    }

    user_text = args.prompt or (
        "Create an EventBridge eventPattern JSON that matches CloudTrail management events "
        "where detail.eventSource == 's3.amazonaws.com' and detail.eventName == 'CreateBucket'. "
        "Include the 'detail-type' = 'AWS API Call via CloudTrail' and match recipientAccountId if available. "
        "Output only the JSON event pattern object."
    )

    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": "Template/example CloudTrail fields: " + json.dumps(default_example)},
        {"role": "user", "content": "User request: " + user_text},
    ]

    print("Calling OpenAI to generate EventBridge JSON...")
    ai_out = call_openai(messages, model=args.model)

    ok, parsed = validate_json_str(ai_out)
    if not ok:
        print("AI output is not valid JSON:", parsed)
        print("AI output:\n", ai_out)
        sys.exit(3)

    # Write validated JSON
    out_path = os.path.abspath(args.out)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(parsed, f, indent=2)
    print("Wrote event JSON to", out_path)

if __name__ == "__main__":
    main()
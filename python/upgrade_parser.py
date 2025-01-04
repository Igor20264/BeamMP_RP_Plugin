import json
import re


def parse_logs(log_data):
    # Split the log data into individual JSON strings
    # Remove leading/trailing characters if necessary
    log_data = log_data.strip()
    if log_data.startswith('{') and log_data.endswith('}'):
        log_data = log_data[1:-1]
    entries = log_data.split('}\n{')

    parsed_logs = []
    for entry in entries:
        # Add missing braces back to each entry
        entry = '{' + entry + '}'
        # Parse the JSON entry
        try:
            log_json = json.loads(entry)
        except json.JSONDecodeError as e:
            print(f"Failed to decode JSON: {e}")
            continue

        # Clean the 'log' field by removing ANSI escape codes
        log_message = log_json.get('log', '')
        ansi_escape = re.compile(r'\x1B[@-_][0-?]*[ -/]*[@-~]')
        clean_log = ansi_escape.sub('', log_message)
        # Decode Unicode escape sequences
        clean_log = clean_log.encode('utf-8').decode('unicode_escape')

        # Process the timestamp if needed
        time_str = log_json.get('time', '')
        # Example: Convert to datetime object
        # from datetime import datetime
        # time_obj = datetime.fromisoformat(time_str.replace('Z', '+00:00'))

        # Create a new dictionary with cleaned data
        parsed_entry = {
            'log': clean_log,
            'stream': log_json.get('stream', ''),
            'time': time_str
            # Add more fields as needed
        }

        parsed_logs.append(parsed_entry)

    return parsed_logs


# Example usage:
if __name__ == "__main__":
    # Assuming 'log_data' is the string containing all the log entries
    with open("11f9d3fb58b32fae5b3cc0149150c99c3fc713d5d7c1924afd7e85e624c34493-json.log","r",encoding="utf-8") as f:
        log_data = f.read()
    parsed_logs = parse_logs(log_data)

    # Print the parsed logs
    for log in parsed_logs:
        print(log)
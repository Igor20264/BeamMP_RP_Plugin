import re

with open("11f9d3fb58b32fae5b3cc0149150c99c3fc713d5d7c1924afd7e85e624c34493-json.log","r",encoding="utf-8") as f:
    data = f.readlines()
error = []
for line in data:
    line = line.strip()
    line = line.replace("\\u001b[0m", "").replace("\\u001b[2K","")
    line = line.replace("\\u001b[3G", "").replace('\\u001b[0G',"").replace("\\u001b[33m", "")
    line = re.sub(r'\\u[0-9a-f]{4}', '', line)
    line = line.replace(r"\r\n","")

    if line == "" or line == "\n":
        continue
    if "forced_save_database" in line:
        continue
    if re.findall(r'\[CHAT\] <Server> \(to ".*"\)(.*) - (.*) h', line) != []:
        continue
    if "ERROR" in line or "LUA ERROR" in line or "WARN" in line:
        if "is_doesnt" in line or "is_newdoesnt" in line or "Освобождено памяти:" in line:
            continue
        if "Respond failed, dropping client" in line:
            continue
        if "server_url" in line:
            continue
        error.append(line)
    print(line)
print("\n")
print(*error,sep="\n")
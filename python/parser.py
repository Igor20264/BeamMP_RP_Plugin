import re

with open("332c8e310e97a12929b923379005b47c4060b99560caed8a984854e58e859456-json.log","r",encoding="utf-8") as f:
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
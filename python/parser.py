import re

with open("_server_beammp-server-prod_1_logs (3).txt","r",encoding="utf-8") as f:
    data = f.readlines()
error = []
for line in data:
    line = line.strip()
    if line == "" or line == "\n":
        continue
    if "forced_save_database" in line:
        continue
    if re.findall(r'\[CHAT\] <Server> \(to ".*"\)(.*) - (.*) h', line) != []:
        continue
    if "ERROR" in line or "LUA ERROR" in line or "WARN" in line:
        error.append(line)
    print(line)
print("\n")
print(*error,sep="\n")

brands = [('as',), ("As",)]
new_brands = []
for brand in brands:
    brand = list(brand)
    brand[0] = brand[0].lower()
    new_brands.append(brand[0])
brands = list(set(new_brands))

brands = [(item,) for item in brands]
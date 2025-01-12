Переработать базу данных, с использованием hex функции
Hex хранит название файла - имя пользователя
`{database}.hex.ixt`

`cars.hex.ixt` >
```
hex = {nickname: str, id: uuid4}
```

`{hex_function}.metadata` >
```
created: int -- time 
last_update: int -- time 
location_of_inizializator: str --path in code
size: int -- size file
last_nicknames: list[str] -- 
owner: str -- username
last_owner: list[str] --
last_change: list[int] --
creator: str -- 
```

- cars.hex.ixt
- \ cars
- | {hex_function}.metadata
- | {hex_function}.ixt

inmemory = {храним данные о пользователя которые сейчас онлайн}
ondisk = Куча файлов пользователей
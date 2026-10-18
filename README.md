# BeamMP RP Plugin

**English** · [Русский](README.ru.md)

Server and client mod for a roleplay server on [BeamMP](https://beammp.com) in BeamNG.drive. Players earn money, keep their own cars, take jobs, and act in character. Staff run the server from chat.

Chat commands use the prefix from `Server/settings/base.json` (default `!`).

## What it does

### Economy

Each player has a balance, a job, and a driving licence. New players start with money and the job “unemployed”.

- Check a balance and pay another player
- Coin-flip another player for a bet, or spin a roulette stake
- Staff can read, set, add, or wipe a player’s economy data

Money from jobs is tracked and can unlock achievements.

### Cars

Players keep a garage of named vehicles.

- Buy a car from the dealer, spawn it, and rename it
- See the repair price and repair a car
- Give a car to another player, sell it to them, or scrap it to the state
- Offer a rental or a test drive, with a time limit
- Staff can list someone’s garage, update a vehicle, set a price, or delete the car a player is driving

### Jobs

A player starts and stops a shift from chat or from the jobs app. Route jobs send the next point over GPS and pay for distance, with a bonus for a streak of stops. Some jobs use a work vehicle instead of a route.

A shift can be limited in time (`work_time_limit` in `Server/settings/base.json`, two hours by default). Staff can see who is working, grant an experience boost, or end someone’s shift.

### Licences

Driving categories are A, B, C, and D. Category A is free in the default config; the others cost money. Police and staff can grant or revoke a category. The player can list their own categories.

### Roleplay

Nearby chat stays the normal BeamMP chat. Extra commands cover in-character play:

| Command | What it does |
| --- | --- |
| `!me` | First-person action |
| `!do` | Third-person action |
| `!try` | Action that can succeed or fail |
| `!b` | Out-of-character note |
| `!dm` | Private message |

Muted players cannot use these or the public chat.

### Progress

Playtime is counted in the background. Hours can be shown in front of the nickname. Players can ask for their own time; staff can ask for one player, a list, or the top.

Achievements pop up in the client when a statistic crosses a line. The default set includes the first visit, the first job, the first car and a garage of ten, money earned at work, 50 and 100 hours, a coin-flip win and loss, a test drive given and taken, a sale to another player, and scrapping a car. Titles and requirements live in `Server/settings/achivment.json`.

### Staff

Roles such as admin, moderator, and police gate the sensitive commands.

- Ban, unban, kick, mute, unmute, and a name whitelist
- Add, remove, and list roles
- Freeze a player, repair their vehicle, and toggle client restrictions
- Place, edit, and delete map points used by jobs and GPS
- Set the server clock when environment sync is enabled

`!help` lists the commands available to the person who asks. `!uptime` prints how long the server has been up.

### Client

The client mod shows a welcome screen, session limits, and in-game apps:

- Balance
- Jobs
- Phone
- Achievement popup
- Navigation
- Notifications

The welcome text, restrictions, and time sync are configured in `Client/settings/config.lua`.

## Layout

```text
Client/      BeamNG client mod
Server/      BeamMP server plugin
SteamUI/     interface layout
OldServer/   older drafts and examples
python/      helper scripts
```

Module notes are in `Server/docs`.

## Branches

| Branch | Role |
| --- | --- |
| `main` | stable line |
| `dev` | current development |

## Install

### Server

Copy the `Server` directory into the BeamMP server mods and restart the server. The entry file is `Server/base.lua`. Economy, jobs, and starting values are in `Server/settings/base.json`.

### Client

Ship the `Client` directory as the client mod. BeamMP can hand it to players from the server’s client resources.

## Deploy

`.github/workflows` uploads the server files over SSH. The host, user, and password are not stored in the repository. Set them as the GitHub secrets `FTP_HOST`, `FTP_USERNAME`, and `FTP_PASSWORD`.

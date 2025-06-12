# 🎶 Musicbox-CLI v1.1

A simple, feature-rich command-line music player for Linux built with Bash and `mpg123`.  
Play your local `.mp3` songs with system info, audio metadata, shuffle, repeat, search, and playback history — right from your terminal.


## 📦 Features

- 📄 Display playlist of songs from `$HOME/Music
- 🎵 Play, Next, Previous, Shuffle, Repeat songs
- 🔊 Volume control
- 🔍 Search songs by name
- 📜 Show playback history
- 📂 Play any song by exact file path
- 📊 Show system info (CPU, memory, uptime)
- 📑 Audio metadata (codec, bitrate, duration)
- 🎨 Colored terminal UI

---

## 📥 Requirements

- `mpg123`
- `ffprobe` (from `ffmpeg`)
- Bash

### Install dependencies:
```bash
sudo apt update
sudo apt install mpg123 ffmpeg


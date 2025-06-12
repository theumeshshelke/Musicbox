#!/bin/bash

# Banner
echo " "
echo "   __  __           _         _                  "
echo "  |  \/  | ___   __| | ___   | |_   _  __ _  ___ "
echo "  | |\/| |/ _ \ / _\` |/ _ \  | | | | |/ _\` |/ _ \\"
echo "  | |  | | (_) | (_| |  __/  | | |_| | (_| |  __/"
echo "  |_|  |_|\___/ \__,_|\___|  |_|\__,_|\__, |\___|"
echo "                                       |___/      "
echo " "
echo "      🎶  Welcome to Musicbox-CLI v1.1 🎶 "
echo " "

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Config
MUSIC_DIR="$HOME/Music"
SONG_LIST="$HOME/.songlist.txt"
TRACK_INDEX="$HOME/.current_track"
HISTORY_LOG="$HOME/.music_history.log"

# Init song list
if [ ! -f "$SONG_LIST" ]; then
    find "$MUSIC_DIR" -type f -iname "*.mp3" > "$SONG_LIST"
fi

TOTAL_SONGS=$(wc -l < "$SONG_LIST")

if [ ! -f "$TRACK_INDEX" ]; then
    echo 1 > "$TRACK_INDEX"
fi

# System Info
show_system_info() {
    echo -e "${YELLOW}📊 System Info:${NC}"
    echo -e "CPU: $(lscpu | grep 'Model name' | awk -F: '{print $2}')"
    echo -e "Memory: $(free -h | grep Mem | awk '{print $2}') total"
    echo -e "Audio Codec: $(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$(sed -n "1p" "$SONG_LIST")")"
    echo " "
}
play_by_name() {
    read -p "🎶 Enter song name or keyword: " keyword
    match=$(grep -i "$keyword" "$SONG_LIST" | head -n 1)
    if [ -z "$match" ]; then
        echo -e "${RED}No song found with keyword '$keyword'.${NC}"
    else
        echo -e "${GREEN}▶️  Playing: $(basename "$match")${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $match" >> "$HISTORY_LOG"
        mpg123 -q "$match"
    fi
}

play_by_path() {
    read -e -p "📂 Enter full file path: " filepath
    if [ ! -f "$filepath" ]; then
        echo -e "${RED}File not found at $filepath.${NC}"
    else
        echo -e "${GREEN}▶️  Playing: $(basename "$filepath")${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $filepath" >> "$HISTORY_LOG"
        mpg123 -q "$filepath"
    fi
}


play_song() {
    local n=$(cat "$TRACK_INDEX")
    local song=$(sed -n "${n}p" "$SONG_LIST")
    local prev=$((n-1)); [ $prev -lt 1 ] && prev=$TOTAL_SONGS
    local next=$((n+1)); [ $next -gt $TOTAL_SONGS ] && next=1

    # System Info
    cpu_info=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')
    cores=$(nproc)
    mem_total=$(free -h | grep Mem | awk '{print $2}')
    mem_free=$(free -h | grep Mem | awk '{print $7}')
    uptime_info=$(uptime -p)
    current_datetime=$(date '+%Y-%m-%d %H:%M:%S')

    # Audio Metadata
    codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$song")
    bitrate=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of csv=p=0 "$song" | awk '{printf "%.0f", $1/1000}')
    samplerate=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "$song")
    channels_num=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$song")
    [ "$channels_num" = "2" ] && channels="Stereo" || channels="Mono"
    filesize=$(du -h "$song" | cut -f1)
    duration_sec=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$song")
    duration_min_sec=$(awk -v dur="$duration_sec" 'BEGIN {m=int(dur/60); s=int(dur%60); printf "%d min %d sec", m, s}')
    mod_date=$(stat -c %y "$song" | cut -d'.' -f1)

    # Display Info
    echo -e "${CYAN}⏮️  Previous: $(basename "$(sed -n "${prev}p" "$SONG_LIST")")${NC}"
    echo -e "${RED}▶️  Now Playing: $(basename "$song")${NC}"
    echo -e "${CYAN}⏭️  Next: $(basename "$(sed -n "${next}p" "$SONG_LIST")")${NC}"
    echo -e "${YELLOW}\n📄 Audio Metadata:${NC}"
    echo -e "Codec:         $codec"
    echo -e "Bitrate:       ${bitrate:-N/A} kbps"
    echo -e "Sample Rate:   ${samplerate:-N/A} Hz"
    echo -e "Channels:      $channels"
    echo -e "File Size:     $filesize"
    echo -e "Duration:      $duration_min_sec"
    echo -e "Modified:      $mod_date"
    echo -e "File Path:     $song"
    echo -e "${YELLOW}\n🖥️ System Info:${NC}"
    echo -e "CPU:           $cpu_info"
    echo -e "Cores:         $cores"
    echo -e "Memory:        $mem_total total / $mem_free free"
    echo -e "Uptime:        $uptime_info"
    echo -e "Date & Time:   $current_datetime"
    echo ""

    echo "$(date '+%Y-%m-%d %H:%M:%S') - $song" >> "$HISTORY_LOG"
    mpg123 -q "$song"
}


next_song() {
    local n=$(cat "$TRACK_INDEX")
    n=$((n+1)); [ "$n" -gt "$TOTAL_SONGS" ] && n=1
    echo "$n" > "$TRACK_INDEX"
    play_song
}

prev_song() {
    local n=$(cat "$TRACK_INDEX")
    n=$((n-1)); [ "$n" -lt 1 ] && n=$TOTAL_SONGS
    echo "$n" > "$TRACK_INDEX"
    play_song
}

shuffle_song() {
    local random=$(( ( RANDOM % TOTAL_SONGS )  + 1 ))
    echo "$random" > "$TRACK_INDEX"
    play_song
}

repeat_song() {
    while true; do
        play_song
    done
}

show_playlist() {
    echo -e "${YELLOW}🎶 Playlist:${NC}"
    cat -n "$SONG_LIST"
}

search_song() {
    read -p "🔍 Enter keyword to search: " keyword
    grep -i --color=always "$keyword" "$SONG_LIST" || echo -e "${RED}No match found.${NC}"
}

show_history() {
    echo -e "${YELLOW}🎵 Playback History:${NC}"
    cat "$HISTORY_LOG"
}

volume_control() {
    read -p "🔊 Enter volume percentage (0-100): " vol
    mpg123 --gain "$vol" "$(sed -n "$(cat "$TRACK_INDEX")p" "$SONG_LIST")"
}

pause_resume_song() {
    echo -e "${YELLOW}⚠️  Note: mpg123 runs in blocking mode; use 'cmus' or 'mpg123 --remote' for pause/resume.${NC}"
}

show_menu() {
    echo -e "${CYAN}"
    echo "┌──────────────────────────────────────────────┐"
    echo "│         🎵 Umesh's Terminal Musicbox 🎵          │"
    echo "├──────────────────────────────────────────────┤"
    echo "│  [1] Play Current Song                        │"
    echo "│  [2] Next Song                                │"
    echo "│  [3] Previous Song                            │"
    echo "│  [4] Shuffle (Random Song)                    │"
    echo "│  [5] Repeat Current Song                      │"
    echo "│  [6] Show Playlist                            │"
    echo "│  [7] Search Song by Name                      │"
    echo "│  [8] Show Playback History                    │"
    echo "│  [9] Play Song with Custom Volume             │"
    echo "│ [10] Pause/Resume Info                        │"
    echo "│ [11] Show System Info                         │"
    echo "│ [12] Quit                                     │"
    echo "│ [13] Play Song by Name                        │"
    echo "│ [14] Play Song by Exact File Path             │"
    echo "└──────────────────────────────────────────────┘"
    echo -e "${NC}"
}

while true; do
    show_menu
    read -p "🎧 Choose an option [1-14]: " choice

    case $choice in
        1) play_song ;;
        2) next_song ;;
        3) prev_song ;;
        4) shuffle_song ;;
        5) repeat_song ;;
        6) show_playlist ;;
        7) search_song ;;
        8) show_history ;;
        9) volume_control ;;
        10) pause_resume_song ;;
        11) show_system_info ;;
        13) play_by_name ;;
        14) play_by_path ;;
        12) echo -e "${RED}👋 Goodbye, Umesh! 🎶${NC}"; exit ;;
        *) echo -e "${RED}Invalid option. Try again.${NC}" ;;
    esac
done

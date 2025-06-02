#!/bin/bash
set -e
BASE="$HOME/ShroomtopPinterest"
mkdir -p "$BASE"/{ui,engine,post,cron,data,output,logs}

cat > "$BASE/ui/index.html" <<'EOF'
(INDEX_HTML)
EOF

cat > "$BASE/engine/generate_caption.sh" <<'EOF'
#!/bin/bash
DAY="day$1"
IN="$HOME/ShroomtopPinterest/data/schedule.json"
OUT="$HOME/ShroomtopPinterest/output/$DAY"
mkdir -p "$OUT"
photos=$(jq -r ".\"$DAY\"[]" "$IN")
i=1
echo "$photos" | while read -r photo; do
  title="✨ Day $1 — Fine Wine Moment #$i"
  caption="Wrapped in light and laughter, this moment felt like forever. Curated for those who sip slow and love deep."
  hashtags="#FineWineEnergy #LuxuryVibes #PinterestWorthy #ModernRomance #ShroomtopSeries"
  echo "$title" > "$OUT/title$i.txt"
  echo "$caption" > "$OUT/caption$i.txt"
  echo "$hashtags" > "$OUT/tags$i.txt"
  ((i++))
done
EOF
chmod +x "$BASE/engine/generate_caption.sh"

cat > "$BASE/post/pin_upload.sh" <<'EOF'
#!/bin/bash
DAY=$(date +'%Y-%m-%d')
BASE="$HOME/ShroomtopPinterest"
JSON="$BASE/data/schedule.json"
DAYKEY="day$(date +%-j)"
OUT="$BASE/output/$DAYKEY"
mkdir -p "$OUT"
"$BASE/engine/generate_caption.sh" "$(date +%-j)" > "$OUT/gen.log" 2>&1
PHOTOS=$(jq -r ".\"$DAYKEY\"[]" "$JSON")
ARR=($PHOTOS)
for i in {1..3}; do
  PHOTO="${ARR[$((i-1))]}"
  TITLE=$(cat "$OUT/title$i.txt")
  DESC=$(cat "$OUT/caption$i.txt")
  TAGS=$(cat "$OUT/tags$i.txt")
  tailwind post create     --image "$BASE/photos/$PHOTO"     --title "$TITLE"     --description "$DESC"     --board "Weddings"     --tags "$TAGS" >> "$BASE/logs/${DAYKEY}_upload.log" 2>&1
done
EOF
chmod +x "$BASE/post/pin_upload.sh"

cat > "$BASE/cron/install.sh" <<'EOF'
#!/bin/bash
PLIST="$HOME/Library/LaunchAgents/com.shroomtop.daily.pin.plist"
cp "$HOME/ShroomtopPinterest/cron/com.shroomtop.daily.pin.plist" "$PLIST"
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"
EOF
chmod +x "$BASE/cron/install.sh"

cat > "$BASE/cron/com.shroomtop.daily.pin.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.shroomtop.daily.pin</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BASE/post/pin_upload.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>9</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>$BASE/logs/stdout.log</string>
  <key>StandardErrorPath</key>
  <string>$BASE/logs/stderr.log</string>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

echo "Setup complete. UI is at: file://$BASE/ui/index.html"

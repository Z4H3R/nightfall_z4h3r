# A translation/interpretation (Covenant) of ysap's nigthfall.sh form bash to powershell. 
$Y_art = 24
$Y_message = 38
$Y_user_input = 39
$Y_status = 37
$ALBUM_ART = @"
,ggg, ,ggggggg,
dP""Y8,8P"""""Y8b                    ,dPYb,      I8   ,dPYb,             ,dPYb, ,dPYb,
Yb, `8dP'`       88                    IP' `Yb      I8   IP' `Yb             IP' `Yb IP' `Yb
`"   88'        88   gg               I8  8I   88888888I8  8I             I8  8I I8  8I
    88         88   ""               I8  8'      I8   I8  8'             I8  8' I8  8'
    88         88   gg     ,gggg,gg  I8 dPgg,    I8   I8 dP    ,gggg,gg  I8 dP  I8 dP
    88         88   88    dP"  "Y8I  I8dP" "8I   I8   I8dP    dP"  "Y8I  I8dP   I8dP
    88         88   88   i8'    ,8I  I8P    I8  ,I8,  I8P    i8'    ,8I  I8P    I8P
    88         Y8,_,88,_,d8,   ,d8I ,d8     I8,,d88b,,d8b,_ ,d8,   ,d8I ,d8     I8,
    88         `Y88P""Y8P"Y8888P"88888P`     Y88P""Y8PI8"888P"Y8888P"`Y88P'"Y888P'"Y88
                               ,d8I'                  I8 `8,
                             ,dP'8I                   I8  `8,
                            ,8"  8I                   I8   8I
                            I8   8I                   I8   8I
                            `8, ,8I                    I8, ,8'
                             `Y8P"                     "Y8P'
"@ -split "`n"

function artWidth {
    param(
    [string[]] $art
        )
    $width = 0
    foreach ($line in $art) {
        if ( $line.Length -gt $width ) {
            $width = $line.Length
        }
    }
    return $width
}

    function draw_border {
param (
        [int] $V_offset,
        [int] $H_offset,
        [string] $Line_color
    )
    $i = 0
    $j = 0
    $windowHeight = [console]::BufferHeight
    $windowWidth = [console]::BufferWidth
    [console]::BackgroundColor = $Line_color
        for ($i = $H_offset - 1; $i -le ($windowWidth - $H_offset -1); $i++ )
            {
        [console]::CursorLeft = $i
    [console]::CursorTop = $V_offset
    [console]::Write(" ")
    [console]::CursorTop = $windowHeight - $V_offset
    [console]::Write(" ")
        }
    for ($j = $V_offset; $j -le ($windowHeight - $V_offset); $j++)
    {
        [console]::CursorTop = $j
        [console]::CursorLeft = $H_offset - 1
        [console]::Write("  ")
        [console]::CursorLeft = $windowWidth - $H_offset - 1
        [console]::Write("  ")
    }
    [console]::ResetColor()
}

# Iterate through each line in the ASCII art and print it
$ALBUM_ART_width = artWidth $ALBUM_ART

$X_art = ([console]::BufferWidth - $ALBUM_ART_width)/2
$x = 2


# --- Configuration ---
$BASE_URL = 'https://music.daveeddy.com/static/music/Nightfall - 2024/mp3'
$TRACKS = @(
    '01 Before the Night',
    '02 Snowfall Serenade',
    '03 Tears Unspoken',
    '04 Colors',
    '05 Gone',
    '06 Safe House',
    '07 B♭ Song (2024 Version)',
    '08 Drifted Away',
    '09 Piano Improvisation',
    '10 Reverie Amidst Ruins',
    '11 Echoes of Solace',
    '12 Song for an Empty World',
    '13 The Final Storm'
)

# --- State ---
$currentFfplayProcess = $null

$text_X = ([console]::BufferWidth / 2) -13
$blank_line = " " * 80
# --- Functions ---
function Stop-CurrentSong {
    if ($null -ne $script:currentFfplayProcess) {
        try {
            # Stop the process and its children
            Stop-Process -Id $script:currentFfplayProcess.Id -Force -ErrorAction SilentlyContinue
            [console]::CursorTop = $Y_status
            [console]::CursorLeft = $text_X 
            Write-Host $blank_line -NoNewLine
            [console]::CursorLeft = $text_X 
           Write-Host "Playback stopped." -NoNewLine -BackgroundColor Red -ForegroundColor Black
        } catch {
            # Silently ignore if the process is already gone
        }
        $script:currentFfplayProcess = $null
    }
}

# --- Main Logic ---
# Check console size
if ([console]::BufferWidth -lt 190 -or [console]::BufferHeight -lt 43) {
    Write-Host ("Window too small. Minimum size 190x43")
    break
}
# Draw borders
clear
draw_border 2 1 "DarkBlue"
draw_border 3 3 "Red"
draw_border 4 5 "Magenta"

# Draw art
[console]::ForegroundColor = "DarkBlue"
foreach ($line in $ALBUM_ART) {
    [console]::CursorLeft = $X_art
    [console]::CursorTop = 5 + $x
    [console]::WriteLine($line)
    $x++
}
[console]::ResetColor()
[console]::CursorTop = [console]::BufferHeight - 1

# Check for ffplay dependency
if (-not (Get-Command ffplay -ErrorAction SilentlyContinue)) {
    [console]::CursorTop = $Y_status
    [console]::CursorLeft = $text_X 
    Write-Host $blank_line -NoNewLine
    [console]::CursorLeft = $text_X 
    Write-Host "Error: ffplay (from ffmpeg) is required for playback." -ForegroundColor Red
    Write-Host "Please install 'ffmpeg' using your package manager and try again."
    exit 1
}
# Display the track list
[console]::CursorTop = $Y_art
for ($i = 0; $i -lt $TRACKS.Count; $i++) {
    $trackNumber = $i + 1
    [console]::CursorLeft = $text_X 
    # Write-Host ("{0,2}. {1}" -f $trackNumber, $TRACKS[$i])
    Write-Host ("{0}" -f $TRACKS[$i])
}
Write-Host "" # Add a newline for spacing

# Main input loop
while ($true) {
    [console]::CursorLeft = $text_X
    [console]::CursorTop = $Y_user_input
    $choice = Read-Host  "Enter track number to play, 's' to stop playing or 'q' to quit"
        if ($choice -eq 'q') {
        Stop-CurrentSong
        break
        }
    if ($choice -eq 's') {
        Stop-CurrentSong
        $trackIndex = $null
    } else {
    # Validate the input
    $trackIndex = -1
    if ($choice -match '^\d+$') {
        $trackIndex = [int]$choice - 1
    } else {
        [console]::CursorTop = $Y_message
        [console]::CursorLeft = $text_X 
        Write-Host $blank_line -NoNewLine
        [console]::CursorLeft = $text_X
        Write-Host "Invalid input. Please enter a number or 's' to stop playing or 'q' to quit." -ForegroundColor Red -NoNewLine
        continue
    }

    if ($trackIndex -lt 0 -or $trackIndex -ge $TRACKS.Count) {
        [console]::CursorTop = $Y_message
        [console]::CursorLeft = $text_X 
        Write-Host $blank_line -NoNewLine
        [console]::CursorLeft = $text_X
        Write-Host "Invalid track number. Please choose a number from the list." -ForegroundColor Red
    } else {
        # Stop any currently playing song
        Stop-CurrentSong

        # Get track name and construct URL
        $trackName = $TRACKS[$trackIndex]
        $url = "$BASE_URL/$trackName.mp3"

        # Play the song in the background
        [console]::CursorTop = $Y_message
        [console]::CursorLeft = $text_X 
        Write-Host $blank_line -NoNewLine
        [console]::CursorTop = $Y_status
        [console]::CursorLeft = $text_X 
        Write-Host $blank_line -NoNewLine
        [console]::CursorLeft = $text_X 
        $trackNumber = $trackIndex + 1
        Write-Host ("Now playing: {0}" -f $trackName) -NoNewLine -ForegroundColor Black -BackgroundColor Green
        try {
            # Use -PassThru to get the process object, but don't wait for it to exit
            $script:currentFfplayProcess = Start-Process ffplay -ArgumentList "-hide_banner -loglevel panic -autoexit -nodisp `"$url`"" -PassThru -WindowStyle Hidden -ErrorAction Stop
        } catch {
            Write-Host "Error playing track. Make sure ffplay is working correctly." -ForegroundColor Red
            $script:currentFfplayProcess = $null
        }
    }
}
}
Write-Host "Exiting."
clear-Host

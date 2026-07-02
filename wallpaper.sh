#!/bin/bash
export DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority LANG=en_US.UTF-8

IMG_DIR="./example/wallpapers"
TSV_FILE="./example/wallpaper_info.tsv"
IMG_LIST="./example/.cache/wallpaper_list"
STATE_FILE="./example/.cache/wallpaper_index"
CHARS_LINE=50 #characters width in the conky widget

case ${1:-} in
    -u|--updatedir)
        if [[ ! -f "$IMG_LIST" ]];then
            find "$IMG_DIR" -type f | shuf > "$IMG_LIST"
            exit
        fi
        check=$(diff <(sort "$IMG_LIST") <(find "$IMG_DIR" -type f | sort))
        if [[ -n "$check" ]]; then
            find "$IMG_DIR" -type f | shuf > "$IMG_LIST"
            echo "$check" | awk -F'/' '/^> / {print $NF}' >> "$TSV_FILE"
        fi
        exit
    ;;
    -n|--now)
        # cat "$STATE_FILE"
        read -r _idx _ < "$STATE_FILE" && echo "$_idx"
        exit
        ;;
    -h|--help)
        printf "There will be no help, you\'re on your own, go read the source\n"
        exit
        ;;
esac

mapfile -t IMAGES < "$IMG_LIST"

IMG_CNT=${#IMAGES[@]}

if [[ ! -f "$TSV_FILE" || "$IMG_CNT" -eq 0 ]]; then
    if [[ ! -f "$TSV_FILE" ]]; then
        warning="Error: file '$TSV_FILE' not found."
    fi
    if [[ "$IMG_CNT" -eq 0 ]]; then
        if [[ -n "$warning" ]]; then
            warning+="\n"
        fi
        if [[ ! -f "$IMG_LIST" ]];then
            warning+="Error: file list '$IMG_LIST' not found. Run wallpaper.sh --updatedir"
        else
            warning+="Error: wallpaper folder '$IMG_DIR' is empty."
        fi
    fi
    pkill conky
    pkill picom
    yad --undecorated --no-buttons --width=300 --window-type="splash" --title="Wallpaper select error" --timeout 30 --text="$warning"
    conky -a mm -d -t "$warning" &
    xsetroot -solid "#FF0000"
    exit 1
fi

# Read last index or start at 0
if [[ -f "$STATE_FILE" ]]; then
    # read -r LAST < "$STATE_FILE"
    read -r LAST CONKY_PID < "$STATE_FILE"
    case ${1:-} in
        -r|--reverse)
            NEXT=$(( (LAST - 1 + IMG_CNT) % $IMG_CNT ))
            ;;
        -s|--select)
            NUM=$(yad --entry --undecorated --window-type="splash" --title="Wallpaper select" --text="Enter image number (0-$(( $IMG_CNT - 1 ))):\nor ±N - how many images to scroll\ncurrent: $LAST)" --width=300)
            if [[ -z "$NUM" ]]; then
                exit 1
            fi
            if [[ "$NUM" =~ ^[0-9]+$ ]] && (( NUM >= 0 && NUM <= ( IMG_CNT - 1 ) )); then
                NEXT=$NUM
            elif [[ "$NUM" =~ ^[-+][0-9]+$ ]]; then
                NEXT=$(( ((LAST + NUM) % IMG_CNT + IMG_CNT) % IMG_CNT ))
            else
                # dunstify -t 3000 -- "$NUM is wrong блять! Must be a number 0–$(( $IMG_CNT - 1 )) or ±integer"
                yad --undecorated --no-buttons --width=300 --window-type="splash" --title="Wallpaper select error" --timeout 3 --text="\n\n\n$NUM is wrong блять! Must be a number 0–$(( $IMG_CNT - 1 )) or ±integer"
                exit 1
            fi
            ;;
        *)
            NEXT=$(( (LAST + 1) % IMG_CNT ))
            ;;
    esac
else
    NEXT=0
fi

IMAGE=${IMAGES[$NEXT]}
target="${IMAGE##*/}"
echo $NEXT > "$STATE_FILE"

mapfile -t fields < <(grep -m1 "^$target"$'\t' "$TSV_FILE" | tr '\t' '\n')
author="${fields[1]}"  
title="${fields[2]}"  
description="${fields[3]}"  
medium="${fields[4]}"  
misc="${fields[5]}"
tag="${fields[6]}"

declare -A FONT_MAP1=(
    ["Battletech"]=$"Digital Sans Now ML Pro:size=13"
    ["Slavic"]=$"SPSLRussianSouvenir:size=18"
)
declare -A FONT_MAP2=(
    ["Battletech"]=$"Battletech:size=14"
    ["Slavic"]=$"Slavianskiy:size=16"
)
declare -A FONT_MAP3=(
    ["Battletech"]=$"Digital Sans Now ML Pro:size=13"
    ["Slavic"]=$""
)

if [[ -v FONT_MAP1["$tag"] || -v FONT_MAP2["$tag"] || -v FONT_MAP3["$tag"] ]]; then  
    author_font=${FONT_MAP1["$tag"]}
    title_font=${FONT_MAP2["$tag"]}
    text_font=${FONT_MAP3["$tag"]}
else  
    author_font=''
    title_font=''
    text_font=''
fi

if [[ -n $author || -n $title ]]; then
    text='$alignr ${font '"$author_font} $author "
    if [[ -n $title ]]; then
        title=$(echo "$title" | par "$CHARS_LINE" | sed 's|^|$alignr |')
        text+='\n\n${font '"$title_font} $title"
    fi
    if [[ -n $description ]]; then
        description=$(echo "$description" | par w"$CHARS_LINE"f1 | sed 's|^|$alignr |')
        text+='\n\n${font '"$text_font} $description"
    fi
    if [[ -n $medium ]]; then
        # medium='${font (Iosevka Regular:size=8)} '"$medium"
        medium=$(echo "$medium" | par w"$CHARS_LINE"f1 | sed 's|^|$alignr |')
        text+='\n$font3 '"$medium"
    fi
    if [[ -n $misc ]]; then
        misc=$(echo "$misc" | par w"$CHARS_LINE"f1 | sed 's|^|$alignr |')
        text+='\n$font3 '"$misc"
    fi

    if [[ -n "$CONKY_PID" ]] && kill -0 "$CONKY_PID" 2>/dev/null; then  
        kill "$CONKY_PID"  
    fi  
    conky -c "$HOME/.config/conky/conky.conf" -t "$text" &  
    CONKY_PID=$!  
else
    if [[ -n "$CONKY_PID" ]] && kill -0 "$CONKY_PID" 2>/dev/null; then  
        kill "$CONKY_PID"  
    fi  
    CONKY_PID=""
fi
    
echo "$NEXT $CONKY_PID" > "$STATE_FILE"

feh --no-fehbg --bg-max -B black "$IMAGE"
exit

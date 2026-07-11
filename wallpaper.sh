#!/bin/bash
export DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority LANG=en_US.UTF-8

. "$(dirname "$0")/wallpaper_config.sh"

update_list () {
    find "$IMG_DIR" -type f | shuf > "$IMG_LIST" #change shuf to sort <option> if you don't want randimized image order
}

yad-error () {
    yad --undecorated --no-buttons --width=300 --window-type="splash" --title="$1" --text="$2" --timeout "$3"
}

modulo () {
    local NUM=$(( ((LAST + $1) % IMG_CNT + IMG_CNT) % IMG_CNT ))
    echo "$NUM"
}

format_text_plaque () {
    if [[ -n $1 ]]; then
        text+="{$4}{font:$2}$3$1{/font}{/$4}"
    fi
}

# format_text () {
#     if [[ -n $1 ]]; then
#         local strings
#         strings=$(echo "$1" | par "$CHARS_LINE" | sed 's|^|$alignr |')
#         text+="$3"'\n${font '"$2} $strings"
#     fi
# }
#
# kill_conky () {
#     if [[ -n "$CONKY_PID" ]] && kill -0 "$CONKY_PID" 2>/dev/null; then  
#         kill "$CONKY_PID"  
#     fi
# }

case ${1:-} in
    -u|--updatedir)
        if [[ ! -f "$IMG_LIST" ]];then
            update_list
            exit
        fi
        check=$(diff <(sort "$IMG_LIST") <(find "$IMG_DIR" -type f | sort))
        if [[ -n "$check" ]]; then
            update_list
            echo "$check" | awk -F'/' '/^> / {print $NF}' >> "$TSV_FILE"
        fi
        exit
    ;;
    -n|--now)
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
    pkill picom
    yad-error "Wallpaper select error" "$warning" "30"
    xsetroot -solid "#FF0000"
    plaque -u -t "$warning" --opacity 1.0 &
    exit 1
fi

# Read last index or start at 0
if [[ -f "$STATE_FILE" ]]; then
    read -r LAST < "$STATE_FILE"
    # read -r LAST CONKY_PID < "$STATE_FILE"
    case ${1:-} in
        -r|--reverse)
            NEXT=$(modulo "-1")
            ;;
        -s|--select)
            NUM=$(yad --entry --undecorated --window-type="splash" --title="Wallpaper select" --text="Enter image number (1-$(( IMG_CNT ))):\nor ±N - how many images to scroll\ncurrent: $(( LAST + 1 ))" --width=300)
            if [[ -z "$NUM" ]]; then
                exit 1
            elif [[ "$NUM" =~ ^[0-9]+$ ]] && (( NUM > 0 && NUM <= ( IMG_CNT ) )); then
                NEXT=$(( NUM - 1 ))
            elif [[ "$NUM" =~ ^[-+][0-9]+$ ]]; then
                NEXT=$(modulo "$NUM")
            else
                # dunstify -t 3000 -- "$NUM is wrong блять! Must be a number 0–$(( $IMG_CNT - 1 )) or ±integer"
                yad-error "Wallpaper select error" "\n\n\n$NUM is wrong блять! Must be a number 1–$(( IMG_CNT )) or ±integer" "3"
                exit 1
            fi
            ;;
        *)
            NEXT=$(modulo "1")
            ;;
    esac
else
    NEXT=0
fi

IMAGE=${IMAGES[$NEXT]}
target="${IMAGE##*/}"

mapfile -t fields < <(grep -m1 "^$target"$'\t' "$TSV_FILE" | tr '\t' '\n')
author="${fields[1]}"  
title="${fields[2]}"  
description="${fields[3]}"  
medium="${fields[4]}"  
misc="${fields[5]}"
tag="${fields[6]}"

if [[ -v FONT_MAP1["$tag"] || -v FONT_MAP2["$tag"] || -v FONT_MAP3["$tag"] ]]; then  
    author_font=${FONT_MAP1["$tag"]}
    title_font=${FONT_MAP2["$tag"]}
    description_font=${FONT_MAP3["$tag"]}
else  
    author_font=''
    title_font=''
    description_font=''
fi


extra_newline="\n"
medium_font='Noto Sans CJK JP:size=8'
misc_font="$medium_font"

if [[ -n $author || -n $title ]]; then
    # text='$alignr ${font '"$author_font} $author "
    #
    # format_text "$title" "$title_font" "$extra_newline"
    # format_text "$description" "$description_font" "$extra_newline"
    # format_text "$medium" "$medium_font"
    # format_text "$misc" "$misc_font"
    #
    # kill_conky
    # conky -c "$CONKY_CONFIG" -t "$text" &  
    # CONKY_PID=$!  
    text="{right}{font:$author_font}$author{/font}{/right}"

    format_text_plaque "$title" "$title_font"  "$extra_newline" "right"
    format_text_plaque "$description" "$description_font" "$extra_newline" "justify-right"
    format_text_plaque "$medium" "$medium_font" "" "right"
    format_text_plaque "$misc" "$misc_font" "" "right"
    plaque -u -t "$text" --LMB-double "$IMAGE" --opacity 1 &
else
    # kill_conky
    # CONKY_PID=""
    plaque -u -t "" --LMB-double "" --opacity 0.0 &
fi
    
# echo "$NEXT $CONKY_PID" > "$STATE_FILE"
echo "$NEXT" > "$STATE_FILE"

feh --no-fehbg --bg-max -B black "$IMAGE"
exit

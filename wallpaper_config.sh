IMG_DIR="./example/wallpapers"                                  #wallpapers folder
TSV_FILE="./example/wallpaper_info.tsv"                         #location of the data file with information about the pictures
IMG_LIST="./example/.cache/wallpaper_list"                      #location of the cached file list, $HOME/.cache looks like a reasonable choice
STATE_FILE="./example/.cache/wallpaper_index"                   #location of the index file - needed to keep track of the next wallpaper to show and conky PID to only kill the one we spawn
CONKY_CONFIG="$HOME/.config/conky/conky.conf"                   #conky config for the wallpaper plaque, in this case the default config location
CHARS_LINE=50                                                   #characters width in the conky widget

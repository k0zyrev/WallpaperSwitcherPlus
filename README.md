![Screenshot of a desktop wallpaper with an info plaque](/screenshots/5.png)
[2](/screenshots/2.png)  [3](/screenshots/3.png)  [4](/screenshots/4.png)  [5](/screenshots/1.png)

Script to show a random background image and some information about the picture from a .tsv file. File list is shuffled and saved to cache.

## Requirements:
 * feh - to display the images
 * conky - to display the image info plaque
 * yad - to handle input to select image
 * par - to format text for conky

## Usage:
Since the script relies on a cached list of the files, you must run `wallpaper.sh -u` first in order to generate the list. If you don't it will display an error. It also requires a .tsv file with the image information and will not run without it. The .tsv schema is `file name \t author \t title \t description \t medium \t misc \t tag` (see example file). Up to you to create it manually.\
Add wallpaper.sh to autostart in your window manager\
i3wm example:\
    ```
        exec_always --no-startup-id ~/scripts/wallpaper.sh
        # optional keybindings
        bindsym $mod+n exec --no-startup-id ~/scripts/wallpaperSlideshow.sh  #next wallpaper
        bindsym $mod+p exec --no-startup-id ~/scripts/wallpaperSlideshow.sh -r  #previous wallpaper
        bindsym $mod+shift+n exec --no-startup-id ~/scripts/wallpaperSlideshow.sh -s  #select wallpaper
    ```\
This will switch wallpaper on every i3wm restart, to make it a slideshow add the script to crontab (crontab -e):\
    switch image every 20 minutes\
    ```
        */20 * * * * /path/to/script/wallpaper.sh
    ```\
    update file list every 12 hours\
    ```
        * */12 * * * /path/to/script/wallpaper.sh -u
    ```\
By default the script shuffles images, if you want to change that you need to replace "shuf" with "sort" configured to sorting order of your choosing.\
The script support dynamic text style - it looks into the tag field and if it contains a tag in it, it switches the fonts. Read the script for more\

> [!IMPORTANT]
> Caveat: in order to properly kill conky process from the script, conky must not fork into background, make sure that background = false in the conky config.

## Supported commands:
 * wallpaper.sh - display the next image
 * -r, --reverse - display the previous image
 * -s, --select - open a dialog window to select the image number (from the cached file list) or +/- offset from the current image
 * -n, --now - put current image index to stdout
 * -u, --updatedir - update cached file list if the files were added or removed from the wallpaper folder and add new file names to the .tsv file (does not check for duplicates)
 * -h, --help - display helpful message

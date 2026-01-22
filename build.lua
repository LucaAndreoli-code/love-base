return {
    -- basic settings:
    name = 'BASE',                     -- name of the game for your executable
    developer = 'Luca Andreoli',       -- dev name used in metadata of the file
    output = 'dist',                   -- output location for your game, defaults to $SAVE_DIRECTORY
    version = '1.1a',                  -- 'version' of your game, used to name the folder in output
    love = '11.5',                     -- version of LÖVE to use, must match github releases
    ignore = { 'dist', 'ignoreme.txt' }, -- folders/files to ignore in your project
    icon = 'assets/icon/icon.png',     -- 256x256px PNG icon for game, will be converted for you

    -- optional settings:
    platforms = { 'windows', 'macos', 'linux' } -- set if you only want to build for a specific platform
}

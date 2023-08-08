#!/bin/bash
search_directory="/home"
logs_directory="/home/wpcli"
wp_cli_path="/usr/local/bin/wp"

if [ -e "$wp_cli_path" ]; then
    echo "wp-cli installed at: $wp_cli_path"
    echo "Updating wp-cli to latest version"
    wp cli update
else
    echo "wp-cli not found."
    echo "Install wp-cli ..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar $wp_cli_path
    wp --info
fi

if [ ! -d "$logs_directory" ]; then
    echo "Folder $logs_directory does not exist."
    echo "Creating $logs_directory."
    mkdir -p "$logs_directory"
    echo "Folder $logs_directroy created."
fi

echo "Searching for WordPress websites in $search_directory..."

# Find directories that potentially contain WordPress files
wordpress_dirs=$(find "$search_directory" -type d -name "wp-content" -prune)

# Loop through each potential WordPress directory
# Clean files
echo "" > ${logs_directory}/wp_cron_generated
for dir in $wordpress_dirs; do
    wp_dir=$(dirname "$dir")
    wp_user=$(echo "$wp_dir" | cut -d '/' -f 3)
    if [[ -f "$wp_dir/wp-config.php" ]]; then
        echo "Found WordPress website: $wp_dir"
        echo "Username for website: $wp_user"
        echo "#!/bin/bash" >> ${logs_directory}/wp_cron_generated
        echo "su -c \"cd $wp_dir;wp core update --minor;wp plugin update --all --minor;wp theme update --all\" $wp_user >> /home/wpcli/${wp_user}_update.log 2>&1" >> ${logs_directory}/wp_cron_generated
        chmod +x ${logs_directory}/wp_cron_generated
        if grep -q "${logs_directory}" "/etc/crontab"; then
          echo "WP CLI cron installed."
        else
          echo "Install WP CLI cron."
          echo "0 */3 * * * ${logs_directory}/wp_cron_generated" >> /etc/crontab
          crontab /etc/crontab
        fi
    fi
done

echo "Search complete."

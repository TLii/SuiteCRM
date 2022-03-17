#!/bin/bash
set -e

# Move to installation directory if set
[[ -z ${SUITECRM_INSTALL_DIR+x} ]] && (echo "Install directory not set" >&2; exit 1);
cd "$SUITECRM_INSTALL_DIR" || (echo "Cannot cd to installation directory $SUITECRM_INSTALL_DIR"; exit 2) >&2;

# Apply new custom-code.
if [[ ! -d $SUITECRM_INSTALL_DIR/custom ]]; then
    echo "Creating customizations directory." >&1;
    mkdir "$SUITECRM_INSTALL_DIR"/custom || (echo "Failed creating customizations directory." >&2; exit 4)
fi

# Move updated custom entries to custom.
# Note: This overwrites existing customizations. Not necessarily a good thing.
# TODO: Change this behavior.
if [[ -d $SUITECRM_INSTALL_DIR/custom && -d $SUITECRM_INSTALL_DIR/newcustom ]]; then
    rsync "$SUITECRM_INSTALL_DIR"/newcustom/* "$SUITECRM_INSTALL_DIR"/custom/ >&1
fi

# Use install.lock to check if already installed
if [[ ! -f $SUITECRM_INSTALL_DIR/custom/install.lock ]] && [[ -n $SUITECRM_SILENT_INSTALL ]]; then
    echo "Running silent install..." >&1;
    php -r "\$_SERVER['HTTP_HOST'] = 'localhost'; \$_SERVER['REQUEST_URI'] = '$SUITECRM_INSTALL_DIR/install.php';\$_REQUEST = array('goto' => 'SilentInstall', 'cli' => true);require_once '$SUITECRM_INSTALL_DIR/install.php';" >&1; 
    touch $SUITECRM_INSTALL_DIR/custom/install.lock || (echo "Failed creating install lock" >&2; exit 4);
    echo "Installation ready" >&1
fi

# Create crontab
echo '* * * * * /usr/bin/flock -n /var/lock/crm-cron.lockfile "cd /var/www/html;php -f cron.php" > /dev/null 2>&1' >> /tmp/cronfile
crontab -u www-data /tmp/cronfile || (echo "Failed to create crontab" >&2; exit 5)
rm /tmp/cronfile
echo "Crontab set" >&1


# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

exec "$@"
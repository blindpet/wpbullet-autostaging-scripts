<img src="https://guides.wp-bullet.com/wp-content/uploads/2016/07/wp-bullet-logo.svg" height="50"> 

# WP Autostaging Scripts

These scripts are for easily creating WordPress or WooCommerce staging servers running nginx or Apache.

There are creation and removal scripts.

Not tested on multisite (and is likely to not work)

Only tested on Ubuntu and Debian but other OSes should work if you change the SITE variables.

## nginx Instructions

The nginx staging script takes a virtual host as an optional parameter

`bash nginx-staging.sh virtualhost`

Similarly the nginx staging removal script also takes a virtual host as an optional parameter

`bash nginx-staging-remove.sh virtualhost`

## Apache Instructions

The Apache staging script takes a virtual host as an optional parameter

`bash apache-staging.sh virtualhost`

Similarly the Apache staging removal script also takes a virtual host as an optional parameter

`bash apache-staging-remove.sh virtualhost`

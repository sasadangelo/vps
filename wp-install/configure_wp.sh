#!/bin/bash -e

# Customize these parameters according to your needs.

# Database configuration
DB_NAME="mywebsite_db"
DB_USER="dbuser"
DB_PASSWD="dbpwd"

# Wordpress configuration
WP_NAME="My Website"
WP_DESCRIPTION="MyWebsite description."
WP_USER="user"
WP_PASSWD="password"
WP_USER_EMAIL="user@gmail.com"
WP_LOCALE="it_IT"
WP_THEME=""
# If you are restoring a wordpress web site this property must be empty 
WP_PLUGINS="antispam-bee,better-font-awesome,contact-form-7,cookie-law-info, \
	php-code-widget,re-add-underline-justify,custom-css-js, \
	social-media-widget,w3-total-cache,widget-logic, \
	wordpress-seo, wp-google-maps"

# Do not touch these variables unless you know what you are doing.
WP_CONTENT_FOLDER=$DOCUMENT_ROOT/$DOMAIN/wp-content
WP_CONFIG_FILE=$DOCUMENT_ROOT/$DOMAIN/wp-config.php

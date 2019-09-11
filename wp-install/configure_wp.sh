#!/bin/bash -e

# Database configuration
DB_NAME="mywebsite_db"
DB_USER="dbuser"
DB_PASSWD="dbpwd"

# Wordpress configuration
WP_NAME="MyWebsite"
WP_DESCRIPTION="MyWebsite description."
WP_USER="user"
WP_PASSWD="password"
WP_USER_EMAIL="user@gmail.com"
WP_NAME="My Website"
WP_LOCALE="it_IT"
WP_THEME="twentyseventeen"
WP_PLUGINS="antispam-bee,better-font-awesome,contact-form-7,cookie-law-info, \
	php-code-widget,re-add-underline-justify,custom-css-js, \
	social-media-widget,w3-total-cache,widget-logic,widgets-on-pages, \
	wordpress-seo, wp-google-maps"

# Variables
WP_CONTENT_FOLDER=$DOCUMENT_ROOT/$DOMAIN/wp-content
WP_CONFIG_FILE=$DOCUMENT_ROOT/$DOMAIN/wp-config.php

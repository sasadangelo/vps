#!/bin/bash -e

# Website VPS configuration
DOMAIN="www.mywebsite2.com"
HOST_USER="webuser"
HOST_PASSWD="webpwd"
DOCUMENT_ROOT=/home/$HOST_USER/www

# Database configuration
DB_NAME="mywebsite2_db"
DB_USER="dbuser2"
DB_PASSWD="dbpwd2"

# Wordpress configuration
WP_NAME="MyWebsite"
WP_DESCRIPTION="MyWebsite"
WP_USER="user"
WP_PASSWD="password"
WP_USER_EMAIL="user@gmail.com"
WP_NAME="My Website"
WP_LOCALE="it_IT"
WP_PLUGINS="antispam-bee,better-font-awesome,contact-form-7,cookie-law-info, \
	php-code-widget,re-add-underline-justify,custom-css-js, \
	social-media-widget,w3-total-cache,widget-logic,widgets-on-pages, \
	wordpress-seo, wp-google-maps"

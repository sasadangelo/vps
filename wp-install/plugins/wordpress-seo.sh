WPSEO="array ( \
  'ms_defaults_set' => false, \
  'version' => '13.0', \
  'disableadvanced_meta' => true, \
  'onpage_indexability' => false, \
  'baiduverify' => '', \
  'googleverify' => '', \
  'msverify' => '', \
  'yandexverify' => '', \
  'site_type' => '', \
  'has_multiple_authors' => '', \
  'environment_type' => '', \
  'content_analysis_active' => true, \
  'keyword_analysis_active' => true, \
  'enable_admin_bar_menu' => true, \
  'enable_cornerstone_content' => true, \
  'enable_xml_sitemap' => true, \ 
  'enable_text_link_counter' => true, \
  'show_onboarding_notice' => false, \
  'first_activated_on' => false, \
  'myyoast-oauth' => false, \
)"

sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
        echo $WPSEO | wp option update wpseo\""

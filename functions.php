<?php
function evumi_setup(){add_theme_support('title-tag');add_theme_support('post-thumbnails');register_nav_menus(array('primary'=>'প্রধান মেনু'));}
add_action('after_setup_theme','evumi_setup');
function evumi_assets(){wp_enqueue_style('evumi-style',get_stylesheet_uri());}
add_action('wp_enqueue_scripts','evumi_assets');

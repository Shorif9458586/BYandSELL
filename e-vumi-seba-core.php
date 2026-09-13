<?php
/*
Plugin Name: E-Vumi Seba Core
Description: Customer registration, service requests, secure document uploads, admin dashboard, status tracking, WhatsApp and payment-ready workflow for E-Vumi Seba.
Version: 2.0.0
*/
if(!defined('ABSPATH')) exit;
define('EVUMI_VER','2.0.0');
define('EVUMI_DIR',plugin_dir_path(__FILE__));
define('EVUMI_URL',plugin_dir_url(__FILE__));

function evumi_install(){
 global $wpdb;
 $charset=$wpdb->get_charset_collate();
 $table=$wpdb->prefix.'evumi_requests';
 $sql="CREATE TABLE $table (
 id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
 tracking_id varchar(32) NOT NULL,
 user_id bigint(20) unsigned NOT NULL,
 service_id bigint(20) unsigned NOT NULL,
 full_name varchar(190) NOT NULL,
 phone varchar(30) NOT NULL,
 district varchar(100) DEFAULT '',
 upazila varchar(100) DEFAULT '',
 mouza varchar(100) DEFAULT '',
 khatian varchar(100) DEFAULT '',
 dag varchar(100) DEFAULT '',
 notes text,
 status varchar(30) NOT NULL DEFAULT 'pending',
 payment_status varchar(30) NOT NULL DEFAULT 'unpaid',
 payment_method varchar(40) DEFAULT '',
 amount decimal(12,2) DEFAULT 0,
 created_at datetime NOT NULL,
 updated_at datetime NOT NULL,
 PRIMARY KEY(id), UNIQUE KEY tracking_id(tracking_id), KEY user_id(user_id)
 ) $charset;";
 require_once ABSPATH.'wp-admin/includes/upgrade.php'; dbDelta($sql);
}
register_activation_hook(__FILE__,'evumi_install');

function evumi_register_cpt(){
 register_post_type('evumi_service',array('labels'=>array('name'=>'ভূমি সেবা','singular_name'=>'ভূমি সেবা'),'public'=>true,'show_ui'=>true,'menu_icon'=>'dashicons-admin-site-alt3','supports'=>array('title','editor')));
}
add_action('init','evumi_register_cpt');

function evumi_register(){
 if(isset($_POST['evumi_register_nonce']) && wp_verify_nonce($_POST['evumi_register_nonce'],'evumi_register')){
  $name=sanitize_text_field($_POST['full_name']);$email=sanitize_email($_POST['email']);$pass=(string)$_POST['password'];
  if(!$email||!$pass||email_exists($email)){return 'রেজিস্ট্রেশন ব্যর্থ: ই-মেইলটি সঠিক ও নতুন হতে হবে।';}
  $uid=wp_create_user($email,$pass,$email); if(is_wp_error($uid)) return $uid->get_error_message();
  wp_update_user(array('ID'=>$uid,'display_name'=>$name,'first_name'=>$name)); wp_set_current_user($uid);wp_set_auth_cookie($uid);
  return 'সফলভাবে অ্যাকাউন্ট তৈরি হয়েছে।';
 } return '';
}
function evumi_register_shortcode(){
 $msg=evumi_register(); ob_start(); if($msg) echo '<div class="card">'.esc_html($msg).'</div>'; ?>
 <form class="formbox" method="post"><label>পূর্ণ নাম</label><input name="full_name" required><label>ই-মেইল</label><input type="email" name="email" required><label>পাসওয়ার্ড</label><input type="password" name="password" minlength="8" required><?php wp_nonce_field('evumi_register','evumi_register_nonce'); ?><button class="btn" type="submit">অ্যাকাউন্ট তৈরি করুন</button></form>
 <?php return ob_get_clean();
}
add_shortcode('evumi_register','evumi_register_shortcode');

function evumi_handle_request(){
 if(!isset($_POST['evumi_request_nonce'])||!wp_verify_nonce($_POST['evumi_request_nonce'],'evumi_request')) return;
 if(!is_user_logged_in()) return;
 global $wpdb;$table=$wpdb->prefix.'evumi_requests';
 $tid='EV'.strtoupper(wp_generate_password(8,false,false));
 $service=absint($_POST['service_id']);$amount=floatval($_POST['amount']);
 $wpdb->insert($table,array('tracking_id'=>$tid,'user_id'=>get_current_user_id(),'service_id'=>$service,'full_name'=>sanitize_text_field($_POST['full_name']),'phone'=>sanitize_text_field($_POST['phone']),'district'=>sanitize_text_field($_POST['district']),'upazila'=>sanitize_text_field($_POST['upazila']),'mouza'=>sanitize_text_field($_POST['mouza']),'khatian'=>sanitize_text_field($_POST['khatian']),'dag'=>sanitize_text_field($_POST['dag']),'notes'=>sanitize_textarea_field($_POST['notes']),'amount'=>$amount,'created_at'=>current_time('mysql'),'updated_at'=>current_time('mysql')));
 $rid=$wpdb->insert_id;
 if(!empty($_FILES['document']['name'])){
  require_once ABSPATH.'wp-admin/includes/file.php';
  $allowed=array('pdf','jpg','jpeg','png');
  $ext=strtolower(pathinfo($_FILES['document']['name'],PATHINFO_EXTENSION));
  if(in_array($ext,$allowed,true) && $_FILES['document']['size']<=5*1024*1024){
   $upload=wp_handle_upload($_FILES['document'],array('test_form'=>false,'mimes'=>array('pdf'=>'application/pdf','jpg'=>'image/jpeg','jpeg'=>'image/jpeg','png'=>'image/png')));
   if(!empty($upload['url'])) add_post_meta($rid,'_evumi_document_url',esc_url_raw($upload['url']));
  }
 }
 wp_safe_redirect(add_query_arg('evumi_submitted',$tid,wp_get_referer()?:home_url()));exit;
}
add_action('init','evumi_handle_request');

function evumi_request_shortcode(){
 if(!is_user_logged_in()) return '<div class="card"><h3>প্রথমে লগইন করুন</h3><p>সেবা আবেদন করতে WordPress account-এ লগইন করা প্রয়োজন।</p><a class="btn" href="'.esc_url(wp_login_url(get_permalink())).'">লগইন</a><a class="btn" href="'.esc_url(home_url('/register/')).'">রেজিস্ট্রেশন</a></div>';
 $services=get_posts(array('post_type'=>'evumi_service','numberposts'=>-1,'post_status'=>'publish')); ob_start();
 if(isset($_GET['evumi_submitted'])) echo '<div class="card"><h3>আবেদন সফল হয়েছে</h3><p>আপনার Tracking ID: <strong>'.esc_html(sanitize_text_field($_GET['evumi_submitted'])).'</strong></p></div>'; ?>
 <form class="formbox" method="post" enctype="multipart/form-data">
 <label>সেবা নির্বাচন</label><select name="service_id" required><?php foreach($services as $s): ?><option value="<?php echo esc_attr($s->ID); ?>"><?php echo esc_html($s->post_title); ?></option><?php endforeach; ?></select>
 <label>নাম</label><input name="full_name" value="<?php echo esc_attr(wp_get_current_user()->display_name); ?>" required>
 <label>মোবাইল</label><input name="phone" required>
 <label>জেলা</label><input name="district"><label>উপজেলা</label><input name="upazila"><label>মৌজা</label><input name="mouza"><label>খতিয়ান নম্বর</label><input name="khatian"><label>দাগ নম্বর</label><input name="dag">
 <label>সেবার ফি (টাকা)</label><input type="number" step="0.01" name="amount" value="0">
 <label>অতিরিক্ত তথ্য</label><textarea name="notes"></textarea>
 <label>ডকুমেন্ট (PDF/JPG/PNG, সর্বোচ্চ ৫MB)</label><input type="file" name="document" accept=".pdf,.jpg,.jpeg,.png">
 <?php wp_nonce_field('evumi_request','evumi_request_nonce'); ?><button class="btn" type="submit">আবেদন জমা দিন</button></form>
 <?php return ob_get_clean();
}
add_shortcode('evumi_service_request','evumi_request_shortcode');

function evumi_track_shortcode(){
 global $wpdb;$out='';$table=$wpdb->prefix.'evumi_requests';
 if(isset($_POST['evumi_track_nonce'])&&wp_verify_nonce($_POST['evumi_track_nonce'],'evumi_track')){
  $tid=sanitize_text_field($_POST['tracking_id']);$r=$wpdb->get_row($wpdb->prepare("SELECT * FROM $table WHERE tracking_id=%s",$tid));
  if($r){$out='<div class="card"><h3>আবেদন: '.esc_html($r->tracking_id).'</h3><p>স্ট্যাটাস: <strong>'.esc_html(ucfirst($r->status)).'</strong></p><p>পেমেন্ট: '.esc_html(ucfirst($r->payment_status)).'</p><p>জমা: '.esc_html($r->created_at).'</p></div>';}else $out='<div class="card">Tracking ID পাওয়া যায়নি।</div>';
 }
 return $out.'<form class="formbox" method="post"><label>Tracking ID</label><input name="tracking_id" placeholder="যেমন EVABCDEFGH" required>'.wp_nonce_field('evumi_track','evumi_track_nonce',true,false).'<button class="btn" type="submit">স্ট্যাটাস দেখুন</button></form>';
}
add_shortcode('evumi_track','evumi_track_shortcode');

function evumi_admin_menu(){add_menu_page('E-Vumi Dashboard','ই-ভূমি Dashboard','manage_options','evumi-dashboard','evumi_admin_page','dashicons-location-alt',25);}
add_action('admin_menu','evumi_admin_menu');
function evumi_admin_page(){
 if(!current_user_can('manage_options')) return; global $wpdb;$table=$wpdb->prefix.'evumi_requests';
 if(isset($_POST['evumi_admin_nonce'])&&wp_verify_nonce($_POST['evumi_admin_nonce'],'evumi_admin')){
  $id=absint($_POST['id']);$status=sanitize_key($_POST['status']);$pay=sanitize_key($_POST['payment_status']);
  $wpdb->update($table,array('status'=>$status,'payment_status'=>$pay,'updated_at'=>current_time('mysql')),array('id'=>$id));
 }
 $rows=$wpdb->get_results("SELECT * FROM $table ORDER BY id DESC LIMIT 100"); ?>
 <div class="wrap"><h1>ই-ভূমি সেবা Dashboard</h1><p>সর্বশেষ ১০০টি আবেদন</p><table class="widefat striped"><thead><tr><th>Tracking</th><th>নাম</th><th>ফোন</th><th>সেবা</th><th>ফি</th><th>স্ট্যাটাস</th><th>পেমেন্ট</th><th>আপডেট</th></tr></thead><tbody>
 <?php foreach($rows as $r): $s=get_post($r->service_id); ?><tr><td><?php echo esc_html($r->tracking_id); ?></td><td><?php echo esc_html($r->full_name); ?></td><td><?php echo esc_html($r->phone); ?></td><td><?php echo esc_html($s?$s->post_title:'—'); ?></td><td><?php echo esc_html($r->amount); ?></td><td><form method="post"><input type="hidden" name="id" value="<?php echo esc_attr($r->id); ?>"><?php wp_nonce_field('evumi_admin','evumi_admin_nonce'); ?><select name="status"><option value="pending" <?php selected($r->status,'pending'); ?>>Pending</option><option value="processing" <?php selected($r->status,'processing'); ?>>Processing</option><option value="completed" <?php selected($r->status,'completed'); ?>>Completed</option><option value="rejected" <?php selected($r->status,'rejected'); ?>>Rejected</option></select></td><td><select name="payment_status"><option value="unpaid" <?php selected($r->payment_status,'unpaid'); ?>>Unpaid</option><option value="pending" <?php selected($r->payment_status,'pending'); ?>>Pending</option><option value="paid" <?php selected($r->payment_status,'paid'); ?>>Paid</option></select></td><td><button class="button button-primary">Save</button></form></td></tr><?php endforeach; ?></tbody></table>
 <h2>Shortcodes</h2><p><code>[evumi_register]</code> = customer registration &nbsp; <code>[evumi_service_request]</code> = service request &nbsp; <code>[evumi_track]</code> = tracking.</p></div><?php
}

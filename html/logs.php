<?php

require_once("../inc/db.inc");
require_once("../inc/util.inc");
require_once("../inc/news.inc");
require_once("../inc/cache.inc");
require_once("../inc/uotd.inc");
require_once("../inc/sanitize_html.inc");
require_once("../inc/text_transform.inc");
require_once("../project/project.inc");
require_once("../inc/bootstrap.inc");

$config = get_config();
$no_web_account_creation = parse_bool($config, "no_web_account_creation");
$project_id = parse_config($config, "<project_id>");
    
$stopped = web_stopped();
$user = get_logged_in_user(true);

page_head(null, null, true);

$path = "/home/boincadm/projects/loda/upload";
$dirs = array_diff(scandir($path), array('.', '..'));

echo "<h1>Logs</h1>";

$s = "$user->name";
if (isset($_GET['s'])) {
  $s = $_GET['s'];
}

foreach ($dirs as $d) {
  $files = array_diff(scandir("$path/$d"), array('.', '..'));
  foreach ($files as $f) {
    $p = "$path/$d/$f";
    $c = file_get_contents($p);
    if (strpos($c, $s) !== false) {
      echo "<h2>$f</h2>\n";
      echo "<pre>$c</pre>\n";
      ob_flush();
      flush();
    }
  }
}

page_tail(false, "", true);

?>

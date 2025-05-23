<?php
/**
 * REQUIRED OPTIONS:
 * app_name: webapp name
 * app_uid: unique name of app
 * tribe_port: port to be attached to tribe's docker
 * junction_port: port to be attached to junction's docker
 * db_user: non-root user for database
 * db_pass: mysqldb password
 * db_name: mysqldb name
 * junction_pass: password for junction
 * enable_ssl: bool true/false
 * allow_cross_origin: bool true/false
 * web_bare_url: domain name without http/s
 * web_url: http/s based domain name
 * junction_url: http/s based url for junction app
 * junction_slug: junction's slug
 */

if (!isset($_SERVER['HTTP_HOST'])) {
    parse_str($argv[1], $_POST);
}

$APP_NAME= $_POST['app_name'] ?? null;
$APP_UID= $_POST['app_uid'] ?? null;
$TRIBE_PORT= $_POST['tribe_port'] ?? null;

$JUNCTION_PORT= $_POST['junction_port'] ?? null;
$JUNCTION_PASS= $_POST['junction_pass'] ?? null;
$JUNCTION_URL= $_POST['junction_url'] ?? null;

$DB_USER= $_POST['db_user'] ?? null;
$DB_PASS= $_POST['db_pass'] ?? null;
$DB_NAME= $_POST['db_name'] ?? null;
$DB_HOST= $APP_UID."-db";

$WEB_BARE_URL= $_POST['web_bare_url'] ?? null;
$WEB_URL= $_POST['web_url'] ?? null;

$TRIBE_API_SECRET_KEY= $_POST['tribe_secret'] ?? null;

if (!$APP_UID) {
    die("'app_uid' is required");
}

$BASE_DIR = "/mnt/junctions";

if (!is_dir($BASE_DIR)) {
    mkdir($BASE_DIR);
}

chdir($BASE_DIR);

try {
    exec("git clone https://github.com/tribe-framework/docker-tribe-template.git {$APP_UID}");
} catch (\Exception $e) {
    echo "<pre style='color: red;'>";
    var_dump($e);
    echo "</pre>";
    die();
}

$APP_PATH = "{$BASE_DIR}/{$APP_UID}";
chdir($APP_PATH);

// update .env
copy("{$APP_PATH}/.sample.env", "{$APP_PATH}/.env");
$env_file = file_get_contents("{$APP_PATH}/.env");
$env_file = str_replace("\$JUNCTION_PASS", $JUNCTION_PASS, $env_file);
$env_file = str_replace("\$JUNCTION_URL", $JUNCTION_URL, $env_file);
$env_file = str_replace("\$APP_UID", $APP_UID, $env_file);

$env_file = str_replace("\$TRIBE_PORT", $TRIBE_PORT, $env_file);
$env_file = str_replace("\$JUNCTION_PORT", $JUNCTION_PORT, $env_file);

$env_file = str_replace("\$APP_NAME", $APP_NAME, $env_file);
$env_file = str_replace("\$WEB_BARE_URL", $WEB_BARE_URL, $env_file);
$env_file = str_replace("\$WEB_URL", $WEB_URL, $env_file);
$env_file = str_replace("\$DOCKER_EXTERNAL_TRIBE_URL", "localhost:$TRIBE_PORT", $env_file);
$env_file = str_replace("\$DOCKER_EXTERNAL_JUNCTION_URL", "localhost:$JUNCTION_PORT", $env_file);
$env_file = str_replace("\$TRIBE_API_SECRET_KEY", $TRIBE_API_SECRET_KEY, $env_file);

$env_file = str_replace("\$DB_NAME", $DB_NAME, $env_file);
$env_file = str_replace("\$DB_USER", $DB_USER, $env_file);
$env_file = str_replace("\$DB_PASS", $DB_PASS, $env_file);
$env_file = str_replace("\$DB_HOST", $DB_HOST, $env_file);

file_put_contents("{$APP_PATH}/.env", $env_file); // write changes to .env

// update PMA configuration
$pma_config = file_get_contents("{$APP_PATH}/config/phpmyadmin/config.inc.php");
$pma_config = str_replace("\$DB_HOST", $DB_HOST, $pma_config);

file_put_contents("{$APP_PATH}/config/phpmyadmin/config.inc.php", $pma_config); // write changes to pma_config

exec("chown -R www-data: $APP_PATH"); // transfer ownership of app to www-data

exec("bash ./install/docker-scripts/setup-network.sh"); // create and add network information for this stack
exec("docker compose pull"); // pull the latest image for this stack
exec("docker compose up -d"); // bring up the composer stack

// wait for process to start before importing and applying database structure
exec("docker exec -i {$DB_HOST} mysql -u{$DB_USER} -p{$DB_PASS} {$DB_NAME} < {$APP_PATH}/install/db.sql; while [ $? -eq 1 ]; do docker exec -i {$DB_HOST} mysql -u{$DB_USER} -p{$DB_PASS} {$DB_NAME} < {$APP_PATH}/install/db.sql; sleep 2; done;");

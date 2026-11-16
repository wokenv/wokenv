<?php
/**
 * Plugin Name: Wokenv Mailpit
 * Description: Sends every WordPress email to the Mailpit container instead of the outside world. Added by Wokenv when mailpit is enabled in wokenv.yml.
 * Author: Wokenv
 * License: GPL-3.0-or-later
 */

defined('ABSPATH') || exit;

add_action(
    'phpmailer_init',
    static function ($phpmailer) {
        $phpmailer->isSMTP();
        $phpmailer->Host = 'mailpit';
        $phpmailer->Port = 1025;
        $phpmailer->SMTPAuth = false;
        $phpmailer->SMTPAutoTLS = false;
    }
);

// WordPress builds "wordpress@localhost" on local sites, which its own
// validator rejects before the message is even handed to the mailer.
add_filter(
    'wp_mail_from',
    static function ($from) {
        return 'wordpress@localhost' === $from ? 'wordpress@localhost.test' : $from;
    }
);

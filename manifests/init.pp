define rdm_ghost (
  $port      = '2368',
  $path      = '',
  $subdomain = undef,
  $domain    = undef,
  $email     = undef,
) {

  if $domain == undef {
    fail("\$domain must be specified")
  }

  if $email == undef {
    fail("\$email must be specified")
  }

  if $subdomain == undef {
    $_subdomain = $name
  } else {
    $_subdomain = $subdomain
  }
 
  if $_subdomain == '' {
    $hostname = $domain
  } else {
    $hostname = "${_subdomain}.${domain}"
  }
 
  $mail_options = {
    host => 'smtp.mandrillapp.com',
    service => 'mandrill',
    port    => 587,
    auth => {
      user => 'ross@macduff.ca',
      pass => 'op3a7jXMdFdYzZuQyH8aZw',
    },
  }

  ::ghost::blog { $name:
    blog           => $name,
    port           => $port,
    source         => "https://github.com/TryGhost/Ghost/releases/download/0.6.4/Ghost-0.6.4.zip",
    url            => "https://${hostname}$/{path}",
    mail_transport => 'SMTP',
    mail_from      => $email,
    mail_options   => $mail_options,
  }

  ::nginx::resource::upstream { $name:
    ensure => 'present',
    members => ["localhost:${port}"],
  }

  ::nginx::resource::vhost { "${hostname}":
    ssl => true,
    ssl_cert => '/etc/pki/tls/certs/_.macduff.ca-bundle.crt',
    ssl_key  => '/etc/pki/tls/private/_.macduff.ca.key',
    ssl_dhparam => '/etc/pki/tls/certs/dhparams.pem',
    use_default_location => false,
    rewrite_www_to_non_www => true,
    rewrite_to_https => true,
  }

  ::nginx::resource::location { $name:
    vhost => "${hostname}",
    location => '/',
    proxy => "http://${name}/",
    ssl => true,
    ssl_only => true,
    location_cfg_prepend => { 
      proxy_ignore_headers => 'Set-Cookie',
      proxy_hide_header => 'Set-Cookie',
    }
  }
}

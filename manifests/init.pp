define rdm_ghost (
  $port      = '2368',
  $path      = '',
  $domain    = undef,
  $email     = undef,
  $ssl_cert  = undef,
  $ssl_key   = undef,
) {

  if $domain == undef {
    fail("\$domain must be specified")
  }

  if $email == undef {
    fail("\$email must be specified")
  }

  if $ssl_cert == undef {
    fail("\$ssl_cert must be specified")
  }
 
  if $ssl_key == undef {
    fail("\$ssl_cert must be specified")
  }

  $mail_options = {
    host => 'smtp.mandrillapp.com',
    service => 'mandrill',
    port    => 587,
    auth => {
      user => hiera('mandrill::username'),
      pass => hiera('mandrill::apikey'),
    },
  }

  ::ghost::blog { $name:
    blog           => $name,
    port           => $port,
    source         => "https://github.com/TryGhost/Ghost/releases/download/0.6.4/Ghost-0.6.4.zip",
    url            => "https://${domain}/${path}",
    mail_transport => 'SMTP',
    mail_from      => $email,
    mail_options   => $mail_options,
  }

  ::nginx::resource::upstream { $name:
    ensure => 'present',
    members => ["localhost:${port}"],
  }

  ::nginx::resource::vhost { "${domain}":
    ssl => true,
    ssl_cert => "/etc/pki/tls/certs/${ssl_cert}",
    ssl_key  => "/etc/pki/tls/private/${ssl_key}",
    ssl_dhparam => '/etc/pki/tls/certs/dhparams.pem',
    use_default_location => false,
    rewrite_www_to_non_www => true,
    rewrite_to_https => true,
  }

  ::nginx::resource::location { $name:
    vhost => "${domain}",
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

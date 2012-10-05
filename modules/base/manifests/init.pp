class base {
  package { screen:
    ensure => latest 
  }
  package { vim-enhanced:
    ensure => latest,
  }
  package { iptables:
    ensure => latest,
  }

  service { "iptables":
    ensure  => running,
    require => Package["iptables"],
  }

  firewall { '000 allow packets with valid state':
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }

  firewall { '001 allow icmp':
    proto  => 'icmp',
    action => 'accept',
  }
  
  firewall { '002 allow all to lo interface':
    iniface => 'lo',
    action  => 'accept',
  }

  firewall { '100 allow ssh':
    proto  => 'tcp',
    dport  => '22',
    action => 'accept',
  }

  firewall { '999 drop everything else':
    action => 'reject',
  }

  #  resources { 'firewall':
  #  purge => false,
  #}
}

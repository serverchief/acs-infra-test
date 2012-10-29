#Python 2.7 installation - also setuptools, distools, pip, virtualenv
#From the original by : https://github.com/rcrowley/puppet-python

class setuptoolsinstall::build {
  file { '/usr/local/sbin/setuptoolsinstall':
    source => 'puppet://$servername/python/setuptoolsinstall',
    ensure => present,
  }
}

define setuptoolsinstall($egg, $prefix, $version) {
  include setuptoolsinstall::build
  exec { '/usr/local/sbin/setuptoolsinstall $egg $prefix >>/tmp/setuptoolsinstall.out 2>>/tmp/setuptoolsinstall.err':
    require => [
      Sourceinstall['Python-$version'],
      File['/usr/local/sbin/setuptoolsinstall']
    ],
    timeout => '-1',
  }
}

define sourceinstall($tarball, $prefix, $vers) {
  exec { 'python-fetch':
    cwd     => '/tmp/',
    command => 'wget $tarball',
  }
  exec { 'python-extract':
    require => Exec['python-fetch'],
    cwd => '/tmp',
    command => 'tar xjf /tmp/Python-$vers.tar.bz2',
    creates => '/tmp/Python-$vers',
  }
  $altpacks = ['make', 'gcc', 'sqlite', 'sqlite-devel', 'readline', 'readline-devel', 'bzip2', 'bzip2-devel']
  package { $altpacks:
    ensure => installed,
  }
  exec { 'python-source':
    require => Exec['python-extract'],
    cwd     => '/tmp',
    command => './configure; make; make altinstall',
    creates => '/usr/local/lib/python-$vers',
  }
}

define pipinstall($version, $bin) {
  exec { 'pipinstall-exec-$version':
    require => [
      Sourceinstall['Python-$version'],
      Setuptoolsinstall['setuptoolsinstall-$version'],
      Exec['pipinstall-extract']
    ],
    cwd => '/tmp/pip-0.5.1',
    command => '/opt/Python-$version/bin/$bin setup.py install',
    creates => '/opt/Python-$version/bin/pip',
  }
}

define pip($package, $version) {
  exec { 'pip-exec-$package-$version':
    require => Pipinstall['pipinstall-$version'],
    command => '/opt/Python-$version/bin/pip install $package',
    timeout => '-1',
  }
}

class python {
  include python::python_2_7_2

  exec { 'pipinstall-fetch':
    cwd => '/tmp',
    command => 'wget http://pypi.python.org/packages/source/p/pip/pip-0.5.1.tar.gz',
  }
  exec { 'pipinstall-extract':
    require => Exec['pipinstall-fetch'],
    cwd => '/tmp',
    command => 'tar xf /tmp/pip-0.5.1.tar.gz',
    creates => '/tmp/pip-0.5.1',
  }
  exec { 'pipinstall-remove':
    require => [
      Pipinstall['pipinstall-2.7.2'],
    ],
    command => 'rm -rf /tmp/pip-0.5.1*',
  }
  file { '/usr/local/bin/pick-python':
    source => 'puppet://$servername/python/pick-python',
    ensure => present,
  }

}

class python::python_2_7_2 {
  $version = '2.7.2'
  sourceinstall { 'Python-$version':
    tarball => 'http://python.org/ftp/python/$version/Python-$version.tar.bz2',
    prefix  => '/opt/Python-$version',
    vers   => $version,
  }
  setuptoolsinstall { 'setuptoolsinstall-$version':
    egg => 'http://pypi.python.org/packages/2.6/s/setuptools/setuptools-0.6c9-py2.6.egg',
    prefix => '/opt/Python-$version',
    version => '$version',
  }
  pipinstall { 'pipinstall-$version':
    version => '$version',
    bin => 'python',
  }
  pip { 'virtualenv-$version':
    package => 'virtualenv',
    version => '$version',
  }
  pip { 'pysqlite-$version':
    require => Package['libsqlite3-dev'],
    package => 'pysqlite',
    version => '$version',
  }
}

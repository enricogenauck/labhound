class { 'postgresql::server':
  postgres_password => 'secret'
}

class { 'rbenv': }
rbenv::plugin { [ 'sstephenson/rbenv-vars', 'sstephenson/ruby-build' ]: }
rbenv::build { '2.2.3':
  global => true,
  env    => 'CONFIGURE_OPTS=--disable-install-doc',
}

class { 'redis': }

package { 'libpq-dev': ensure => 'installed' }
package { 'nodejs': ensure => 'installed' }

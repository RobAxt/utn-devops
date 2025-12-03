# puppet/modules/jenkins/manifests/init.pp

class jenkins {

  # Asegurar Java para Jenkins
  package { 'openjdk-11-jre-headless':
    ensure => installed,
  }

  # Agregar la key de Jenkins (repo oficial)
  exec { 'add_jenkins_key':
    command => 'wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null',
    creates => '/usr/share/keyrings/jenkins-keyring.asc',
    path    => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
  }

  # Agregar el archivo de repositorio de Jenkins
  file { '/etc/apt/sources.list.d/jenkins.list':
    ensure  => file,
    content => "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/\n",
    require => Exec['add_jenkins_key'],
  }

  # Ejecutar apt update cuando cambie el repo de Jenkins
  exec { 'apt_update_jenkins':
    command     => '/usr/bin/apt-get update',
    refreshonly => true,
    subscribe   => File['/etc/apt/sources.list.d/jenkins.list'],
    path        => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
  }

  # Instalar Jenkins desde el repo
  package { 'jenkins':
    ensure  => installed,
    require => [
      Exec['apt_update_jenkins'],
      Package['openjdk-11-jre-headless'],
    ],
  }

  # Asegurar que el servicio Jenkins esté habilitado y corriendo
  service { 'jenkins':
    ensure    => running,
    enable    => true,
    require   => Package['jenkins'],
    hasstatus => true,
    hasrestart=> true,
  }

}

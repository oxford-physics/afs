#Source https://projects.linux.duke.edu/puppet/browser/modules/afs/
class afs::client( $enableclient=$afs::params::enableclient  ) inherits afs::params {
   if ( $enableclient  )
   {
       class {"afs::client::do":}

   }
}
class afs::client::do () 
{

    ## Packages Needed
       
	case $operatingsystem {
 # TODO get afs on CentOS like the lines below
		/centos|CentOS|redhat|RedHat|Redhat/: {
                }
                /centosfixed/: {
    		package { "openafs":
				ensure => present;
    		}
			package {"openafs-kernel":
				ensure => present;
			}
        	package {"openafs-client":
				ensure => present;
			}

	        file { "/etc/openafs/afs.conf.client":
		        owner   => root,
		        group   => root,
		        mode    => 0644,
		        content => template("afs/afs.conf.client.erb"),
	                before  => Service["afs"],
		        require	=> Package["openafs-client"]
	        	}
		}
        /scientific|Scientific/: {

            package{"openafs-client":
                ensure  => present
            }

            package {"openafs-krb5":
                ensure  => present;
            }


            file{"/usr/vice/etc/CellAlias":
                owner   => root, group  => root, mode   => 0644,
                content => "cern.ch acpub\n",
                require => Package["openafs-client", "openafs-krb5"],
                before  => Service["afs"]
            }

        }
		Ubuntu: {
        	package {["openafs-client","openafs-krb5"]:
				ensure => present;
			}
		}
	}

#TODO This block should not have an overrarching OS dependency, its only there to stop afs running when it doesnt work on centos
 case $operatingsystem {
 /centos|CentOS|redhat|RedHat|Redhat/: { }
 /scientific|Scientific/: {


	file { "ThisCell":
		owner   => root,
		group   => root,
		mode    => 0644,
		content => "cern.ch",
        path    => $operatingsystem ? {
            /scientific|Scientific/ => "/usr/vice/etc/ThisCell",
            default                 => "/etc/openafs/ThisCell"
        },
		require	=> $operatingsystem ? {
			Ubuntu	=> Package["openafs-client"],
			default	=> Package["openafs-client"],
		}
	}

		

	file { "CellServDB":
		owner   => root,
		group   => root,
		mode    => 0644,
		content => template("afs/cellservdb.erb"),
        path    => $operatingsystem ? {
            /scientific|Scientific/ => "/usr/vice/etc/CellServDB",
            default                 => "/etc/openafs/CellServDB"
        },
		require	=> $operatingsystem ? {
			Ubuntu	=> Package["openafs-client"],
			default	=> Package["openafs-client"],
		}
	}

        file { "/usr/vice/etc/cacheinfo":
                        source => "puppet:///modules/$module_name/cacheinfo",
                        owner   => root,
                        group   => root,
                        mode    => 0644,
                        before =>Service["afs"],
                        require => Package["openafs-client"]
                 
	}
    ## Make sure the afs client is running
    service {"afs":
		name	=> $operatingsystem ? {
			Ubuntu	=> "openafs-client",
			default	=> "afs"
		},
		ensure => running,
                enable => true,
		pattern	=> afsd,
		hasstatus	=> $operatingsystem ? {
			Ubuntu	=> false,
			default	=> true
		}
    }
 }#sl
 }#os
}

class afs::volume-server {

    realize(
        User["ambackup"],
        Yumrepo["afs-v2"],
        Package["xinetd"],
        Service["xinetd"]
    )

    iptables{"afs tcp":
        proto       => "tcp",
        dport       => ["7000", "7001", "7002", "7003", "7004", "7005", "7006", "7007", "7008", "7009"],
        jump        => "ACCEPT",
    }

    iptables{"afs udp":
        proto       => "udp",
        dport       => ["7000", "7001", "7002", "7003", "7004", "7005", "7006", "7007", "7008", "7009"],
        jump        => "ACCEPT",
    }

    iptables{"afs-backup-03 tcp":
        proto       => "tcp",
        source      => "152.3.102.15",
        jump        => "ACCEPT",
    }

    iptables{"afs-backup-03 udp":
        proto       => "udp",
        source      => "152.3.102.15",
        jump        => "ACCEPT",
    }

    iptables{"afs-backup-04 tcp":
        proto       => "tcp",
        source      => "152.3.102.20",
        jump        => "ACCEPT",
    }

    iptables{"afs-backup-04 udp":
        proto       => "udp",
        source      => "152.3.102.20",
        jump        => "ACCEPT",
    }

    package{["krbafs", "krbafs-utils", "amanda-client", "amanda-afs"]:
        ensure  => installed,
        require => [Yumrepo["afs-v2"], User["ambackup"] ]
    }

    package{["openafs-server", "openafs-client"]:
        ensure  => installed
    }

    file{["/var/openafs", "/var/openafs/logs"]:
        ensure  => directory,
        owner   => root, group  => root, mode   => 0700
    }

    file{"/etc/openafs/server":
        ensure  => directory,
        owner   => root, group  => root, mode   => 0755,
        require => Package["openafs-client"]
    }

    ## Misc files
    file{"/etc/openafs/server/UserList":
        source  => "puppet:///afs-volserver/UserList",
        owner   => root, group  => root, mode   => 0644,
        require => File["/etc/openafs/server"]
    }

    file{"/etc/openafs/server/KeyFile":
        source  => "puppet:///afs-volserver/KeyFile",
        owner   => root, group  => root, mode   => 0600,
        require => File["/etc/openafs/server"]
    }

    file{"/etc/openafs/server/ThisCell":
        content => "cern.ch\n",
        owner   => root, group  => root, mode   => 0644,
        require => File["/etc/openafs/server"]
    }

    file{"/etc/openafs/BosConfig":
        source  => "puppet:///afs-volserver/BosConfig",
        owner   => root, group  => root, mode   => 0644,
        require => Package["openafs-client"]
    }

    file{"/etc/openafs/CellServDB":
        source  => "puppet:///afs-volserver/CellServDB",
        owner   => root, group  => root, mode   => 0644,
        require => Package["openafs-client"]
    }

    file{"/etc/sysconfig/afs":
        source  => "puppet:///afs-volserver/afs-sysconfig",
        owner   => root, group  => root, mode   => 0644,
        require => Package["openafs-client"]
    }

    file{"/etc/openafs/server/CellServDB":
        ensure  => "/etc/openafs/CellServDB",
        require => File["/etc/openafs/CellServDB"]
    }

    file{"/usr/local/bin/init_vicepartitions.sh":
        source  => [
            "puppet:///private_files/init_vicepartitions.sh",
            "puppet:///afs-volserver/init_vicepartitions.sh"
        ],
        owner   => root, group  => root, mode   => 0755,
        require => Package["openafs-client"]
    }

    file{"/usr/local/bin/wtf_am_i_hosting.sh":
        source  => "puppet:///afs-volserver/wtf_am_i_hosting.sh",
        owner   => root, group  => root, mode   => 0755,
        require => Package["openafs-client"]
    }

    file{"/usr/local/bin/update_afs_stats.sh":
        source  => "puppet:///afs-volserver/update_afs_stats.sh",
        owner   => root, group  => root, mode   => 0755,
        require => Package["openafs-client"]
    }

    file{"/usr/local/bin/show_salvage_status.sh":
        source  => "puppet:///afs-volserver/show_salvage_status.sh",
        owner   => root, group  => root, mode   => 0755,
        require => Package["openafs-client"]
    }

    file{"/var/lib/amanda/.amandahosts":
        source  => "puppet:///afs-volserver/amandahosts",
        owner   => ambackup, group  => disk, mode   => 0600,
        require => [ Package["amanda-client"], User["ambackup"] ]

    }

    file{"/etc/logrotate.d/afs-stats":
        source  => "puppet:///afs-volserver/afs-stats.logrotate",
        owner   => root, group  => root, mode   => 0644,
    }

    file{"/etc/xinetd.d/amanda":
        source  => "puppet:///afs-volserver/xinetd-amanda",
        owner   => root, group  => root, mode   => 0644,
        require => [Package["amanda-client"], Package["xinetd"], Package["amanda-afs"]],
        notify  => Service["xinetd"]
    }

    service{"afs":
        enable  => true
    }

}

class afs::db-server {
    realize(
        Yumrepo["afs-v2"]
    )
    package{["krbafs", "krbafs-utils", "openafs-server", "openafs-client"]:
        ensure  => installed,
        require => [Yumrepo["afs-v2"]]
    }

    iptables{"afs tcp":
        proto       => "tcp",
        dport       => ["7000", "7001", "7002", "7003", "7004", "7005", "7006", "7007", "7008", "7009", "7021"],
        jump        => "ACCEPT",
    }

    iptables{"afs udp":
        proto       => "udp",
        dport       => ["7000", "7001", "7002", "7003", "7004", "7005", "7006", "7007", "7008", "7009", "7021"],
        jump        => "ACCEPT",
    }

    file{["/var/openafs"]:
        ensure  => directory,
        owner   => root, group  => root, mode   => 0700
    }

    file{["/var/openafs/logs", "/var/openafs/db"]:
        ensure  => directory,
        owner   => root, group  => root, mode   => 0775,
        require => File["/var/openafs"]
    }

    file{"/etc/sysconfig/afs":
        source  => "puppet:///afs-dbserver/afs-sysconfig",
        owner   => root, group  => root, mode   => 0644,
        require => Package["openafs-client"]
    }

    file{"/etc/openafs/BosConfig":
        source  => "puppet:///afs-dbserver/BosConfig",
        owner   => root, group  => root, mode   => 0644,
        require => Package["openafs-client"]
    }

    file{"/etc/openafs/License":
        source  => "puppet:///afs-dbserver/BosConfig",
        owner   => root, group  => root, mode   => 0644,
        require => Package["openafs-client"]
    }

    file{"/etc/openafs/ThisCell":
        source  => "puppet:///afs-dbserver/ThisCell",
        owner   => root, group  => root, mode   => 0644,
        require => Package["openafs-client"]
    }

    file{"/etc/openafs/server":
        ensure  => directory,
        owner   => root, group  => root, mode   => 0755,
        require => Package["openafs-client"]
    }

    file{"/etc/openafs/server/UserList":
        source  => "puppet:///afs-dbserver/UserList",
        owner   => root, group  => root, mode   => 0644,
        require => File["/etc/openafs/server"]
    }

    file{"/etc/openafs/server/ThisCell":
        ensure  => "/etc/openafs/ThisCell",
        require => File["/etc/openafs/server"]
    }

    file{"/etc/openafs/server/CellServDB":
        ensure  => "/etc/openafs/CellServDB",
        require => File["/etc/openafs/server"]
    }

    if $afs_key_exists == "true" {
        ## Do some stuff with the key here, chicken, meet egg
        file{"/etc/openafs/server/KeyFile":
            source  => "puppet:///afs-dbserver/KeyFile",
            owner   => root, group  => root, mode   => 0600,
            require => File["/etc/openafs/server"]
        }

    } else {

        notify{"afs-key-notify":
            message => "The AFS key does not exist.  This is a safeguard against accidentally screwing up the databases before the server is fully configure.  If you want the real key, just run:  touch /etc/openafs/server/KeyFile, then run puppet again"
        }

    }

}

class afs::client::authoritative inherits afs::client {
	## This class includes files necessary to give the client
	## control over the afs volume servers
	##
	## !! BE CAREFUL OF WHERE YOU PUT THIS !!
	##
    file{"/etc/openafs/server":
        ensure  => directory,
        require => Package["openafs-client"]
    }
    file{"afs-krb5key":
        path    => "/etc/openafs/server/KeyFile",
        source  => "puppet://$servername/private_files/KeyFile",
        owner   => root, group  => root, mode   => 0600,
        require => File["/etc/openafs/server"]
    }

	package{"openafs-devel":
		ensure	=> installed
	}

	file { "/etc/openafs/server/CellServDB":
		owner   => root,
		group   => root,
		mode    => 0644,
		content => template("afs/cellservdb.erb"),
        require => File["/etc/openafs/server"]
	}

	file { "/etc/openafs/server/ThisCell":
		owner   => root,
		group   => root,
		mode    => 0644,
		content => "cern.ch",
        require => File["/etc/openafs/server"]
		}
}

class afs::client::disabled inherits afs::client {

    ## Make sure the afs client is running
    Service["afs"]{
        enable => false
    }

}


CVMFS
=====

Install and configure [CernVM-FS (CVMFS)][cvmfs], particularly for [Galaxy][galaxy] servers.

[cvmfs]: https://cernvm.cern.ch/portal/filesystem
[galaxy]: https://galaxyproject.org

Requirements
------------

On Enterprise Linux (`ansible_os_family == "RedHat"`), it is assumed that you have enabled [Extra Packages for Enterprise
Linux (EPEL)][epel] for CVMFS's dependencies.  If you need to enable EPEL, [geerlingguy.repo-epel][repo-epel] can easily
do this for you.

[epel]: https://fedoraproject.org/wiki/EPEL
[repo-epel]: https://galaxy.ansible.com/geerlingguy/repo-epel/

Role Variables
--------------

All variables are optional. However, if unset, the role will essentially do nothing. See the [defaults][defaults] and
[example playbook](#example-playbook) for examples.

## Galaxy Client

Other than `cvmfs_role` as described below, [Galaxy][galaxy] administrators will most likely only need to set the
`galaxy_cvmfs_repos_enabled` variable (disabled by default), which automatically configures the CVMFS client for
[galaxyproject.org][galaxy] CVMFS repositories.

The value of `galaxy_cvmfs_repos_enabled` can be either `config-repo` or any value that evaluates to `true` (or `false`
to explcititly disable, although this is the default). Using `config-repo` is recommended since it causes the role to
only install a minimal configuration needed to mount the `cvmfs-config.galaxyproject.org` CVMFS repository, and then
uses CVMFS' [Config Repository][cvmfs-config-repo] support to obtain the configs for the other galaxyproject.org CVMFS
repositories. This ensures you will always have up-to-date configs for all galaxyproject.org CVMFS repositories.

Setting `galaxy_cvmfs_repos_enabled` to `config-repo` overrides the value of `cvmfs_config_repo` since there can be only
one default config repo configured on the client.

Setting `galaxy_cvmfs_repos_enabled` to any other truthy value will causes the role to create a static configuration
where the full configurations for each galaxyproject.org CVMFS repository is installed on the target host. This option
is retained for legacy purposes.

You can override the defaults for Galaxy's `cvmfs_keys`, `cvmfs_server_urls`, and `cvmfs_repositories` by prepending
`galaxy_` to the variable names. See the [defaults][defaults] for details.

If `galaxy_cvmfs_repos_enabled` is not set, full configuration of non-Galaxy repositories can be performed using the set
of variables described below.

## Client or shared client/server variables

variable | type | description
--- | --- | ---
`cvmfs_role` | string | Type of CVMFS host: `client`, `stratum0`, `stratum1`, or `localproxy`. Alternatively, you may put hosts in to groups `cvmfsclients`, `cvmfsstratum0servers`, `cvmfsstratum1servers`, and `cvmfslocalproxies`. Controls what packages are installed and what configuration is performed.
`cvmfs_keys` | list of dicts | Keys to install on hosts of all types.
`cvmfs_server_urls` | list of dicts | CVMFS server URLs, the value of `CVMFS_SERVER_URL` in `/etc/cvmfs/domain.d/<domain>.conf`.
`cvmfs_repositories` | list of dicts | CVMFS repository configurations, the value of `CVMFS_REPOSITORIES` in `/etc/cvmfs/default.local` plus additional settings in `/etc/cvmfs/repositories.d/<repository>/{client,server}.conf`.
`cvmfs_config_repo` | dict | CVMFS [Configuration Repository][cvmfs-config-repo] configuration, see the value of `galaxy_cvmfs_config_repo` in the [defaults][defaults] for syntax.
`cvmfs_quota_limit` | integer in MB | Size of CVMFS client cache. Default is `4000`.
`cvmfs_upgrade_client` | boolean | Upgrade CVMFS on clients to the latest version if it is already installed. Default is `false`.
`cvmfs_preload_install` | boolean | Install the `cvmfs_preload` script for [preloading the CVMFS cache][preload].
`cvmfs_preload_path` | path | Directory where `cvmfs_preload` should be installed
`cvmfs_install_setuid_cvmfs_wipecache` | boolean | Install a setuid binary on clients that allows unprivileged users to perform `cvmfs_config wipecache`. EL only (source is provided).
`cvmfs_install_setuid_cvmfs_remount_sync` | boolean | Install a setuid binary on clients that allows unprivileged users to perform `cvmfs_talk remount sync`. EL only (source is provided).

The complex (list of dict) variables have the following syntaxes:

```yaml
cvmfs_keys:
  - path: 'absolute path to repo key.pub'
    owner: 'user owning key file (default: root)'
    key: |
      -----BEGIN PUBLIC KEY-----
      MIIBIjAN...

cvmfs_server_urls:
  - domain: 'repo parent domain'
    urls:
      - 'repository URL'

cvmfs_repositories:
  - repository: 'repo name'
    stratum0: 'stratum 0 hostname'
    owner: 'user owning repository (default: root)'
    key_dir: 'path to directory containing repo keys (default: /etc/cvmfs/keys)'
    server_options:
      - KEY=val
    client_options:
      - KEY=val
```

## Server variables

variable | type | description
--- | --- | ---
`cvmfs_private_keys` | list of dicts | Keys to install on Stratum 0 hosts. Separate from `cvmfs_keys` for vaultability and avoiding duplication.
`cvmfs_config_apache` | boolean | Configure Apache on Stratum 0 and 1 servers. If disabled, you must configure it yourself. Default is `true`.
`cvmfs_manage_firewall` | boolean | Attempt to configure firewalld (EL) or ufw (Debian) to permit traffic to configured ports. Default is `false`.
`cvmfs_squid_conf_src` | path | Path to template Squid configuration file (for Stratum 1 and local proxy servers). Defaults are in the role `templates/` directory.
`cvmfs_stratum0_http_ports` | list of integers | Port(s) to configure Apache on Stratum 0 servers to listen on. Default is `80`.
`cvmfs_stratum1_http_ports` | list of integers | Port(s) to configure Squid on Stratum 1 servers to listen on. Default is `80` and `8000`.
`cvmfs_stratum1_apache_port` | integer | Port to configure Apache on Stratum 1 servers to listen on. Default is `8008`.
`cvmfs_stratum1_cache_mem` | integer in MB | Amount of memory for Squid to use for caching. Default is `128`.
`cvmfs_stratum1_cache_dir` | list of dicts |
`cvmfs_localproxy_http_ports` | list of integers | Port(s) to configure Squid on local proxy servers to listen on.  Default is `3128`.
`cvmfs_upgrade_server` | boolean | Upgrade CVMFS on servers to the latest version if it is already installed. Default is `false`.
`cvmfs_srv_device` | path | Block device to create a filesystem on and mount for CVMFS data. Unset by default.
`cvmfs_srv_fstype` | string | Filesystem to create on `cvmfs_srv_device`. Default is `ext4`.
`cvmfs_srv_mount` | path | Path to mount CVMFS data volume on. Default is `/srv` (but is ignored if `cvmfs_srv_device` is unset).
`cvmfs_union_fs` | string | Union filesystem type (`overlayfs` or `aufs`) for new repositories on Stratum 0 servers.
`cvmfs_numfiles` | integer | Set the maximum number of open files in `/etc/security/limits.conf`. Useful with the `CVMFS_NFILES` client option on Stratum 0 servers.

[defaults]: https://github.com/galaxyproject/ansible-cvmfs/blob/master/defaults/main.yml
[cvmfs-config-repo]: https://cvmfs.readthedocs.io/en/stable/cpt-configure.html#the-config-repository
[preload]: http://cvmfs.readthedocs.io/en/stable/cpt-hpc.html

Dependencies
------------

None.

Example Playbook
----------------

Configure all hosts as CVMFS clients with configurations for the Galaxy CVMFS repositories:

```yaml
- name: CVMFS
  hosts: all
  vars:
    cvmfs_role: client
    galaxy_cvmfs_repos_enabled: config-repo
  roles:
    - geerlingguy.repo-epel
    - galaxyproject.cvmfs
```

Create a Stratum 1 (mirror) of the Galaxy CVMFS repositories and configure clients to prefer your Stratum 1 (assuming
you have configured hosts in groups `cvmfsclients` and `cvmfsstratum1servers`):

```yaml
- name: CVMFS
  hosts: cvmfsclients:cvmfsstratum1servers
  vars:
    cvmfs_srv_device: /dev/sdb
    galaxy_cvmfs_repos_enabled: true
    # override the default
    galaxy_cvmfs_server_urls:
      - domain: galaxyproject.org
        urls:
          - "http://cvmfs.example.org/cvmfs/@fqrn@"
          - "http://cvmfs1-psu0.galaxyproject.org/cvmfs/@fqrn@"
          - "http://cvmfs1-iu0.galaxyproject.org/cvmfs/@fqrn@"
          - "http://cvmfs1-tacc0.galaxyproject.org/cvmfs/@fqrn@"
          - "http://cvmfs1-mel0.gvl.org.au/cvmfs/@fqrn@"
          - "http://cvmfs1-ufr0.galaxyproject.eu/cvmfs/@fqrn@"
  roles:
    - galaxyproject.cvmfs
```

Create your own CVMFS infrastructure. Run once without keys (new keys will be generated on repo creation):

```yaml
- name: CVMFS
  hosts: cvmfsstratum0servers
  vars:
    cvmfs_numfiles: 4096
    cvmfs_server_urls:
      - domain: example.org
        urls:
          - "http://cvmfs0.example.org/cvmfs/@fqrn@"
    cvmfs_repositories:
      - repository: foo.example.org
        stratum0: cvmfs0.example.org
        key_dir: /etc/cvmfs/keys/example.org
        server_options:
          - CVMFS_AUTO_TAG=false
          - CVMFS_GARBAGE_COLLECTION=true
          - CVMFS_AUTO_GC=false
        client_options:
          - CVMFS_NFILES=4096
      - repository: bar.example.org
        stratum0: cvmfs0.example.org
        key_dir: /etc/cvmfs/keys/example.org
  roles:
    - galaxyproject.cvmfs
```

Once keys have been created, add them to `cvmfs_keys` and run the same as above but `hosts: all` and `cvmfs_keys`
defined as:

```yaml
- name: CVMFS
  vars:
    cvmfs_keys:
      - path: /etc/cvmfs/keys/example.org/foo.example.org.pub
        key: |
          -----BEGIN PUBLIC KEY-----
          MIIBIjAN...
      - path: /etc/cvmfs/keys/example.org/bar.example.org.pub
        key: |
          -----BEGIN PUBLIC KEY-----
          MIIBIjAN...
```

License
-------

MIT

Author Information
------------------

[Nate Coraor](https://github.com/natefoo)
[Helena Rasche](https://github.com/erasche)

[View contributors on GitHub](https://github.com/galaxyproject/ansible-cvmfs/graphs/contributors)

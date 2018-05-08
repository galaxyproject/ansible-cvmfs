CVMFS
=====

Install and configure [CernVM-FS (CVMFS)][cvmfs].

**NOTE: This role is not for general use. Currently, it makes certain assumptions and will, by default, configure
[Galaxy][galaxy]'s CVMFS servers. When this role is generalized in the future it will be uploaded to [Ansible
Galaxy][ansible-galaxy].**

Also, this role is currently only works with Enterprise Linux.

[cvmfs]: https://cernvm.cern.ch/portal/filesystem
[galaxy]: https://galaxyproject.org
[ansible-galaxy]: https://galaxy.ansible.com

Requirements
------------

On Enterprise Linux (`ansible_os_family == "RedHat"`), it is assumed that you have enabled [Extra Packages for Enterprise
Linux (EPEL)][epel] for CVMFS's dependencies.  If you need to enable EPEL, [geerlingguy.repo-epel][repo-epel] can easily
do this for you.

[epel]: https://fedoraproject.org/wiki/EPEL
[repo-epel]: https://galaxy.ansible.com/geerlingguy/repo-epel/

Role Variables
--------------

TODO

Dependencies
------------

None.

Example Playbook
----------------

TODO

License
-------

MIT

Author Information
------------------

[Nate Coraor](https://github.com/natefoo)  

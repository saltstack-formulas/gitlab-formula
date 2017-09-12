{% if grains['os_family'] == 'RedHat' %}
# https://github.com/gitlabhq/gitlab-recipes/tree/master/install/centos
PUIAS_6_computational:
  pkgrepo.managed:
    - humanname: PUIAS computational Base $releasever - $basearch
    - gpgcheck: 1
    - gpgkey: http://springdale.math.ias.edu/data/puias/6/x86_64/os/RPM-GPG-KEY-puias
    - mirrorlist: http://puias.math.ias.edu/data/puias/computational/$releasever/$basearch/mirrorlist

{% if not salt['pillar.get']('gilab:use_rvm', false) %}
include:
  - gitlab.ruby

ruby-scl:
  pkgrepo.managed:
    - humanname: Ruby 1.9.3 Dynamic Software Collection
    - gpgcheck: 0
    - baseurl: http://people.redhat.com/bkabrda/ruby193-rhel-6/
    - require_in:
      - pkg: gitlab-ruby
{% endif %}

{% elif grains['os_family'] == 'Debian' %}
{# TODO: Handling of packages should be moved to map.jinja #}
{# Gitlab 8.17+ requires nodejs-4.3+ but is not available before Debian 9 or Ubuntu 16.10 #}
gitlab-nodejs-repo-mgmt-pkgs:
  pkg.installed:
    - names:
        - python-apt
        - apt-transport-https
    - require_in:
        - pkgrepo: gitlab-nodejs-repo
        - pkgrepo: gitlab-yarn-repo

gitlab-nodejs-repo:
  pkgrepo.managed:
    - name: deb https://deb.nodesource.com/node_4.x {{ grains.oscodename|lower }} main
    - file: /etc/apt/sources.list.d/nodesource_4.list
    - key_url: salt://gitlab/files/nodesource.gpg.key

gitlab-nodejs-preference:
  file.managed:
    - name: /etc/apt/preferences.d/90_nodesource
    - contents: |
        Package: nodejs
        Pin: release o=Node source,l=Node source
        Pin-Priority: 901
    - require_in:
      - sls: gitlab.packages

gitlab-yarn-repo:
  pkgrepo.managed:
    - name: deb https://dl.yarnpkg.com/debian/ stable main
    - file: /etc/apt/sources.list.d/yarn.list
    - key_url: salt://gitlab/files/dl.yarn.com.key
    - require_in:
      - sls: gitlab.packages
{% endif %}

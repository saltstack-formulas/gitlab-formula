{% if grains['os_family'] == 'RedHat' %}
# https://github.com/gitlabhq/gitlab-recipes/tree/master/install/centos
PUIAS_6_computational:
  pkgrepo.managed:
    - humanname: PUIAS computational Base $releasever - $basearch
    - gpgcheck: 1
    - gpgkey: http://springdale.math.ias.edu/data/puias/6/x86_64/os/RPM-GPG-KEY-puias
    - mirrorlist: http://puias.math.ias.edu/data/puias/computational/$releasever/$basearch/mirrorlist

{% elif grains['os_family'] == 'Debian' %}
{# TODO: Handling of packages should be moved to map.jinja #}
{# Gitlab 9.2+ requires golang-1.8+ which requires backports on Debian 9 and Ubuntu 16.04 #}
{%- set distro = grains.oscodename %}
gitlab-distro-backports:
  file.managed:
    - name: /etc/apt/preferences.d/55_gitlab_req_backports
    {%- if grains.os == "Ubuntu" %}
    - contents: |
        Package: golang
        Pin: release o=Ubuntu,a={{ distro }}-backports
        Pin-Priority: 800
    {%- else %}
    - contents: |
        Package: golang
        Pin: release o=Debian Backports,a={{ distro }}-backports
        Pin-Priority: 800
    {%- endif %}
  pkgrepo.managed:
    {%- if grains.os == "Ubuntu" %}
    - name: deb http://archive.ubuntu.com/ubuntu {{ distro }}-backports main
    {%- else %}
    - name: deb http://httpredir.debian.org/debian {{ distro }}-backports main
    {%- endif %}
    - file: /etc/apt/sources.list.d/gitlab_req_backports.list
    - require_in:
      - sls: gitlab.packages

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

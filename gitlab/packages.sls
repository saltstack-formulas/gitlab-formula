
gitlab-deps:
  pkg.installed:
{% if grains['os_family'] == 'RedHat' %}
    - pkgs:
      - autoconf
      - automake
      - binutils
      - bison
      - byacc
      - crontabs
      - cscope
      - ctags
      - cvs
      - db4-devel
      - diffstat
      - doxygen
      - elfutils
      - expat-devel
      - flex
      - gcc
      - gcc-c++
      - gcc-gfortran
      - gdbm-devel
      - gettext
      - git
      - glibc-devel
      - indent
      - intltool
      - libffi
      - libffi-devel
      - libicu
      - libicu-devel
      - libcurl-devel
      - libtool
      - libxml2
      - libxml2-devel
      - libxslt
      - libxslt-devel
      - libyaml
      - libyaml-devel
      - logrotate
      - logwatch
      - make
      - ncurses-devel
      - openssl-devel
      - patch
      - patchutils
      - perl-Time-HiRes
      - pkgconfig
      - postgresql-devel
      - python-devel
      - rcs
      - readline
      - readline-devel
      - redhat-rpm-config
      - redis
      - rpm-build
      - sqlite-devel
      - subversion
      - sudo
      - swig
      - system-config-firewall-tui
      - systemtap
      - tcl-devel
      - vim-enhanced
      - wget
    - require:
      - pkgrepo: PUIAS_6_computational
{% elif grains['os_family'] == 'Debian' %}
    - pkgs:
      - build-essential
      - checkinstall
      - curl
      - cmake
      - golang: ">=1.8"
      - libcurl4-openssl-dev
      - libffi-dev
      - libgdbm-dev
      - libicu-dev
      - libncurses5-dev
      - libre2-dev
      - libreadline-dev
      {%- if (grains['os'] == 'Ubuntu' and grains['osrelease_info'][0] >= 17) or (grains['os'] == 'Debian' and grains['osrelease_info'][0] >= 9) %}
      - libssl1.0-dev
      {%- else %}
      - libssl-dev
      {%- endif %}
      - libxml2-dev
      - libxslt1-dev
      - libyaml-dev
      - logrotate
      - openssh-server
      - nodejs: ">=4.3"
      - pkg-config
      - python
      - python-docutils
      - rake
      - redis-server
      - yarn: ">=0.17"
      - zlib1g-dev
      {% if salt['pillar.get']('gitlab:db:engine', 'postgresql') == 'postgresql' %}
      - libpq-dev
      {% endif %}
{% endif %}

{% if salt['pillar.get']('gitlab:use_rvm', False) %}
rvm-deps:
  pkg.installed:
    - pkgs:
    {% if grains['os_family'] == 'RedHat' %}
      - bash
      - bzip2
      - coreutils
      - curl
      - gawk
      - gzip
      - libtool
      - sed
      - zlib
      - zlib-devel
    {% endif %}
{% endif %}

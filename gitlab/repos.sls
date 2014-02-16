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
{% endif %}

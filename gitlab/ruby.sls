gitlab-ruby:
{% if salt['pillar.get']('gitlab:use_rvm', false) %}
  rvm.installed:
    - name: ruby-{{ salt['pillar.get']('gitlab:rvm_ruby', '2.1.0') }}
    - default: True
    - user: git
    - require:
      - user: git-user
      - pkg: rvm-deps
  gem.installed:
    - user: git
    - ruby: ruby-2.1.0
    - require:
      - rvm: gitlab-ruby
{% else %}
  {% if grains['os_family'] == 'Debian' %}
  pkg.installed:
    - pkgs:
      - ruby
      - ruby-dev
  gem.installed:
    - name: bundler
    - require:
      - pkg: gitlab-ruby
  {% elif grains['os_family'] == 'RedHat' %}
  pkg.installed:
    - pkgs:
      - ruby193-ruby
      - ruby193-ruby-devel
      - ruby193-rubygem-bundler
  {% endif %}
{% endif %}

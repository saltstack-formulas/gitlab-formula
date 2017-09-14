gitlab-ruby:
{% if salt['pillar.get']('gitlab:use_rvm', false) %}
  rvm.installed:
    - name: ruby-{{ salt['pillar.get']('gitlab:rvm_ruby', '2.3.3') }}
    - default: True
    - user: git
    - require:
      - user: git-user
      - pkg: rvm-deps
  gem.installed:
    - user: git
    - ruby: ruby-2.3.3
    - require:
      - rvm: gitlab-ruby
{% else %}
  {% if grains['os_family'] == 'Debian' %}
  pkg.installed:
    - pkgs:
      - ruby: ">=2.3"
      - ruby-dev: ">=2.3"
  gem.installed:
    - name: bundler
    - version: ">= 1.14, <15.0"
    - require:
      - pkg: gitlab-ruby
    {% if salt['pillar.get']('gitlab:proxy:enabled', false) %}
    - proxy: {{ salt['pillar.get']('gitlab:proxy:address') }}
    {% endif %}
  {% endif %}
{% endif %}

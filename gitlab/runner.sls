# vim: sts=2 ts=2 sw=2 et ai
#
{% from "gitlab/map.jinja" import gitlab with context %}

{% if grains['os_family'] == 'Debian' %}
gitlab-runner repo:
  pkgrepo.managed:
    - humanname: gitlab-runner debian repo
    - file: /etc/apt/sources.list.d/gitlab-runner.list
    - name: deb https://packages.gitlab.com/runner/gitlab-runner/{{ grains['os']|lower }}/ {{ grains['oscodename'] }} main
    - key_url: https://packages.gitlab.com/runner/gitlab-runner/gpgkey

gitlab-install_pkg:
  pkg.installed:
    - name: gitlab-runner
{% else %}
gitlab-install_pkg:
  pkg.installed:
    - sources:
      - gitlab-runner: {{gitlab.runner.downloadpath}}
{% endif %}

gitlab-create_group:
  group.present:
    - name: "gitlab-runner"
    - system: True
    - require:
      - pkg: gitlab-install_pkg

gitlab-install_runserver_create_user:
  user.present:
    - name: {{gitlab.runner.username}}
    - shell: /bin/false
    - home: /home/{{gitlab.runner.username}}
    - groups:
      - gitlab-runner
    - require:
      - group: gitlab-create_group

gitlab-install_runserver3:
  cmd.run:
    - name: "CI_SERVER_URL='{{gitlab.runner.url}}' REGISTRATION_TOKEN='{{gitlab.runner.token}}' /usr/bin/gitlab-runner  register --config /home/{{gitlab.runner.username}}/config.yml"
    - unless: 'test -e /home/{{gitlab.runner.username}}/config.yml'
    - require:
      - user: gitlab-install_runserver_create_user

gitlab-runner:
  service.running:
    - enable: True
    - require:
      - pkg: gitlab-install_pkg
      - cmd: gitlab-install_runserver3

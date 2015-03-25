# vim: sts=2 ts=2 sw=2 et ai
#
{% from "gitlab/map.jinja" import gitlab with context %}

gitlab-install_pkg:
  pkg.installed:
    - sources:
      - gitlab-runner: {{gitlab.runner.downloadpath}} 

gitlab-install_runserver_create_user:
  user.present:
    - name: {{gitlab.runner.username}}
    - shell: /bin/false
    - home: /home/{{gitlab.runner.username}}
    - groups:
      - gitlab-runner 

gitlab-install_runserver3:
  cmd.run:
    - name: "export CI_SERVER_URL='{{gitlab.runner.url}}'; export REGISTRATION_TOKEN='{{gitlab.runner.token}}'; /opt/gitlab-runner/bin/setup -C /home/{{gitlab.runner.username}};"
    - unless: 'test -e /home/{{gitlab.runner.username}}/config.yml'

gitlab-create_init_file:
  file.managed:
    - name: "/etc/init/gitlab-runner.conf"
    - source:
      - "/opt/gitlab-runner/doc/install/upstart/gitlab-runner.conf"
    - user: "root" 
    - group: "root" 
    - mode: 775 

gitlab-runner:
  service.running:
    - enable: True

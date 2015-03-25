# vim: sts=2 ts=2 sw=2 et ai
#
{% from "gitlab/map.jinja" import gitlab with context %}

gitlab-install_pkg:
  pkg.installed:
    - sources:
      - gitlab-runner: {{gitlab.runner.downloadpath}} 

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
    - name: "export CI_SERVER_URL='{{gitlab.runner.url}}'; export REGISTRATION_TOKEN='{{gitlab.runner.token}}'; /opt/gitlab-runner/bin/setup -C /home/{{gitlab.runner.username}};"
    - unless: 'test -e /home/{{gitlab.runner.username}}/config.yml'
    - require:
      - user: gitlab-install_runserver_create_user

gitlab-create_init_file:
  file.symlink:
    - name: "/etc/init/gitlab-runner.conf"
    - target: "/opt/gitlab-runner/doc/install/upstart/gitlab-runner.conf"
    - user: "root" 
    - group: "root" 
    - mode: 775 
    - unless: 'test -e /etc/init/gitlab-runner.conf'
    - require:
      - cmd: gitlab-install_runserver3

gitlab-runner:
  service.running:
    - enable: True
    - running: True
    - require:
      - file: gitlab-create_init_file

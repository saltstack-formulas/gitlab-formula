# vim: sts=2 ts=2 sw=2 et ai
#
{% from "gitlab/map.jinja" import gitlab with context %}
install_runserver:
  pkg.installed:
    - pkgs:
      - wget 

install_runserver1:
  pkg.installed:
    - sources:
      - gitlab-runner: {{gitlab.runner.downloadpath}} 

install_runserver2:
  cmd.run:
    - name: "useradd -s /bin/false -m -r {{gitlab.runner.username}}"

install_runserver3:
  cmd.run:
    - name: "export CI_SERVER_URL='{{gitlab.runner.url}}'; export REGISTRATION_TOKEN='{{gitlab.runner.token}}'; /opt/gitlab-runner/bin/setup -C /home/{{gitlab.runner.username}};"

install_runserver4:
  cmd.run:
    - name: "cp /opt/gitlab-runner/doc/install/upstart/gitlab-runner.conf /etc/init/"
    - unless: file.exists /etc/init/gitlab-runner.conf

install_runserver5:
  cmd.run:
    - name: "service gitlab-runner start"

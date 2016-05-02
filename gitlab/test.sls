{% set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}

{% set active_db = salt['pillar.get']('gitlab:databases:production', 'paf') %}
{% set user, user_infos = salt['pillar.get']('postgres:users').items()[0] %}

/tmp/test:
  file.managed:
    - source: salt://gitlab/files/test
    - template: jinja
    - user: root
    - group: root
    - mode: 644

gitlab-initialize:
  cmd.run:
    - user: git
    - cwd: {{ root_dir }}/gitlab
    - name: force=yes bundle exec rake gitlab:setup RAILS_ENV=production
    - shell: /bin/bash
    - unless: PGPASSWORD={{ user_infos.password }} psql -h {{ active_db.host }} -U {{ user }} {{ active_db.name }} -c 'select * from users;'
#    - watch:
#      - git: gitlab-git
#    - require:
#      - cmd: gitlab-gems
#      - file: gitlab-db-config

include:
  - postgres
  - gitlab.ruby

{% set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}
{% set repositories = salt['pillar.get']('gitlab:lookup:repositories', root_dir ~ '/repositories') %}
{% set sockets_dir = salt['pillar.get']('gitlab:lookup:sockets_dir', root_dir ~ '/var/sockets') %}
{% set pids_dir = salt['pillar.get']('gitlab:lookup:pids_dir', root_dir ~ '/var/pids') %}
{% set logs_dir = salt['pillar.get']('gitlab:lookup:logs_dir', root_dir ~ '/var/logs') %}
{% set uploads_dir = salt['pillar.get']('gitlab:lookup:uploads_dir', root_dir ~ '/var/uploads') %}

{% set active_db = salt['pillar.get']('gitlab:databases:production', 'paf') %}
{% set db_user, db_user_infos = salt['pillar.get']('postgres:users').items()[0] %}

{% if salt['pillar.get']('gitlab:proxy:enabled', false) %}
gitlab-git-present:
  git.present:
    - name: {{ root_dir }}/gitlab
    - bare: False

gitlab-git-proxy:
  git.config:
    - name: http.proxy
    - value: {{ salt['pillar.get']('gitlab:proxy:address') }}
    - repo: {{ root_dir }}/gitlab
{% endif %}

gitlab-git:
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-ce.git
    - rev: {{ salt['pillar.get']('gitlab:gitlab_version') }}
    - user: git
    - target: {{ root_dir }}/gitlab
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - sls: gitlab.ruby
      - cmd: gitlab-shell
      - user: git-user
      {% if salt['pillar.get']('gitlab:proxy:enabled', false) %}
      - git: gitlab-git-proxy
      {% endif %}

# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example
gitlab-config:
  file.managed:
    - name: {{ root_dir }}/gitlab/config/gitlab.yml
    - source: salt://gitlab/files/gitlab-gitlab.yml
    - template: jinja
    - user: git
    - group: git
    - mode: 640
    - require:
      - git: gitlab-git
      - user: git-user

# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/database.yml.postgresql
gitlab-db-config:
  file.managed:
    - name: {{ root_dir }}/gitlab/config/database.yml
    - source: salt://gitlab/files/gitlab-database.yml
    - template: jinja
    - user: git
    - group: git
    - mode: 640
    - require:
      - git: gitlab-git
      - user: git-user

# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/unicorn.rb.example
unicorn-config:
  file.managed:
    - name: {{ root_dir }}/gitlab/config/unicorn.rb
    - source: salt://gitlab/files/gitlab-unicorn.rb
    - template: jinja
    - user: git
    - group: git
    - mode: 640
    - require:
      - git: gitlab-git
      - user: git-user

# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/initializers/rack_attack.rb.example
rack_attack-config:
  file.managed:
    - name: {{ root_dir }}/gitlab/config/initializers/rack_attack.rb
    - source: salt://gitlab/files/gitlab-rack_attack.rb
    - user: git
    - group: git
    - mode: 640
    - require:
      - git: gitlab-git
      - user: git-user

git-config:
  file.managed:
    - name: {{ root_dir }}/.gitconfig
    - source: salt://gitlab/files/gitlab-gitconfig
    - template: jinja
    - user: git
    - group: git
    - mode: 640
    - require:
      - user: git-user

git-var-mkdir:
  file.directory:
    - name: {{ root_dir }}/var
    - user: git
    - group: git
    - mode: 750

# pids_dir
{% for dir in [ sockets_dir, logs_dir ] %}
git-{{ dir }}-mkdir:
  file.directory:
    - name: {{ dir }}
    - user: git
    - group: git
    - mode: 750
{% endfor %}

# Hardcoded in gitlab, so, we have to create symlink
gitlab-pids_dir-symlink:
  file.symlink:
    - name: {{ pids_dir }}
    - target: {{ root_dir }}/gitlab/tmp/pids
  require:
    - file: gitlab-config

# When code changes, trigger upgrade procedure
# Based on https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/upgrader.rb
gitlab-gems:
  cmd.run:
    - user: git
    - cwd: {{ root_dir }}/gitlab
    - name: bundle install --deployment --without development test mysql aws kerberos
    - shell: /bin/bash
    - watch:
      - git: gitlab-git
    - require:
      - file: gitlab-db-config
      - file: gitlab-config
      - file: unicorn-config
      - file: rack_attack-config
      - sls: gitlab.ruby

gitlab-initialize:
  cmd.run:
    - user: git
    - cwd: {{ root_dir }}/gitlab
    - name: force=yes bundle exec rake gitlab:setup RAILS_ENV=production
    - shell: /bin/bash
    - unless: PGPASSWORD={{ db_user_infos.password }} psql -h {{ active_db.host }} -U {{ db_user }} {{ active_db.name }} -c 'select * from users;'
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-gems
      - file: gitlab-db-config

gitlab-migrate-db:
  cmd.wait:
    - user: git
    - cwd: {{ root_dir }}/gitlab
    - name: bundle exec rake db:migrate RAILS_ENV=production
    - shell: /bin/bash
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-gems
      - cmd: gitlab-initialize
      - file: gitlab-db-config

gitlab-recompile-assets:
  cmd.wait:
    - user: git
    - cwd: {{ root_dir }}/gitlab
    - name: bundle exec rake assets:clean assets:precompile RAILS_ENV=production
    - shell: /bin/bash
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-migrate-db

gitlab-clear-cache:
  cmd.wait:
    - user: git
    - cwd: {{ root_dir }}/gitlab
    - name: bundle exec rake cache:clear RAILS_ENV=production
    - shell: /bin/bash
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-recompile-assets

# Needed to be able to update tree via git
gitlab-stash:
  cmd.wait:
    - user: git
    - cwd: {{ root_dir }}/gitlab
    - name: git stash
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-clear-cache

# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/support/init.d/gitlab.default.example
gitlab-default:
  file.managed:
    - name: /etc/default/gitlab
    - source: salt://gitlab/files/gitlab-default
    - template: jinja
    - user: root
    - group: root
    - mode: 644

# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/support/logrotate/gitlab
gitlab-logwatch:
  file.managed:
    - name: /etc/logrotate.d/gitlab
    - source: salt://gitlab/files/gitlab-logrotate
    - template: jinja
    - user: root
    - group: root
    - mode: 644

gitlab-respositories-dir:
  file.directory:
    - name: {{ repositories }}
    - user: git
    - group: git
    - file_mode: 0660
    - dir_mode: 2770

gitlab-uploads-dir:
  file.directory:
    - name: {{ root_dir }}/gitlab/public/uploads
    - dir_mode: 0700

gitlab-uploads-symlink:
  file.symlink:
    - name: {{ uploads_dir }}
    - target: {{ root_dir }}/gitlab/public/uploads
    - require:
      - file: git-var-mkdir

gitlab-service:
  file.managed:
    - name: /etc/init.d/gitlab
    - source: salt://gitlab/files/initd
    - mode: 0755
    - template: jinja
    - require:
      - git: gitlab-git
  service:
    - name: gitlab
    - running
    - enable: True
    - reload: True
    - require:
      - file: gitlab-service
#      - cmd: gitlab-initialize
      - file: gitlab-pids_dir-symlink      
    - watch:
      - git: gitlab-git
      - cmd: gitlab-clear-cache
      - file: gitlab-config
      - file: gitlab-db-config
      - file: gitlab-default
      - file: rack_attack-config
      - file: unicorn-config

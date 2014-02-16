include:
  - gitlab.ruby

gitlab-git:
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-ce.git
    - rev: {{ salt['pillar.get']('gitlab:gitlab_version') }}
    - user: git
    - target: /home/git/gitlab
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - sls: gitlab.ruby
      - cmd: gitlab-shell
      - user: git-user

# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example
gitlab-config:
  file.managed:
    - name: /home/git/gitlab/config/gitlab.yml
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
    - name: /home/git/gitlab/config/database.yml
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
    - name: /home/git/gitlab/config/unicorn.rb
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
    - name: /home/git/gitlab/config/initializers/rack_attack.rb
    - source: salt://gitlab/files/gitlab-rack_attack.rb
    - user: git
    - group: git
    - mode: 640
    - require:
      - git: gitlab-git
      - user: git-user

git-config:
  file.managed:
    - name: /home/git/.gitconfig
    - source: salt://gitlab/files/gitlab-gitconfig
    - template: jinja
    - user: git
    - group: git
    - mode: 640
    - require:
      - user: git-user

{% for dir in ['gitlab-satellites', 'gitlab/tmp/pids', 'gitlab/tmp/sockets', 'gitlab/public/uploads'] %}
/home/git/{{ dir }}:
  file.directory:
    - user: git
    - group: git
    - mode: 750
    - require:
      - user: git-user
      - git: gitlab-git
{% endfor %}

gitlab-initialize:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: echo yes | bundle exec rake gitlab:setup RAILS_ENV=production
    - shell: /bin/bash
    - unless: psql -U {{ salt['pillar.get']('gitlab:db_user') }} {{ salt['pillar.get']('gitlab:db_name') }} -c 'select * from users;'
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-gems
      - postgres_database: gitlab-db

# When code changes, trigger upgrade procedure
# Based on https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/upgrader.rb
gitlab-gems:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: bundle install --deployment --without development test mysql aws
    - shell: /bin/bash
    - watch:
      - git: gitlab-git
    - require:
      - file: gitlab-db-config
      - file: gitlab-config
      - file: unicorn-config
      - file: rack_attack-config
      - sls: gitlab.ruby

gitlab-migrate-db:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: bundle exec rake db:migrate RAILS_ENV=production
    - shell: /bin/bash
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-gems
      - cmd: gitlab-initialize
      - postgres_database: gitlab-db

gitlab-recompile-assets:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: bundle exec rake assets:clean assets:precompile RAILS_ENV=production
    - shell: /bin/bash
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-migrate-db

gitlab-clear-cache:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
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
    - cwd: /home/git/gitlab
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

gitlab-service:
  file.symlink:
    - name: /etc/init.d/gitlab
    - target: /home/git/gitlab/lib/support/init.d/gitlab
    - require:
      - git: gitlab-git
  service:
    - name: gitlab
    - running
    - enable: True
    - require:
      - cmd: gitlab-initialize
    - watch:
      - git: gitlab-git
      - cmd: gitlab-clear-cache
      - file: gitlab-config
      - file: gitlab-db-config
      - file: gitlab-default
      - file: gitlab-service
      - file: rack_attack-config
      - file: unicorn-config

# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/support/logrotate/gitlab
gitlab-logwatch:
  file.managed:
    - name: /etc/logrotate.d/gitlab
    - source: salt://gitlab/files/gitlab-logrotate
    - user: root
    - group: root
    - mode: 644

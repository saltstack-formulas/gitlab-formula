gitlab-git:
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-ce.git
    - rev: {{ salt['pillar.get']('gitlab:gitlab_version') }}
    - user: git
    - target: /home/git/gitlab
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - gem: bundler
      - user: git-user

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

unicorn-config:
  file.managed:
    - name: /home/git/gitlab/config/unicorn.rb
    - source: salt://gitlab/files/gitlab-unicorn.rb
    - user: git
    - group: git
    - mode: 640
    - require:
      - git: gitlab-git
      - user: git-user

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

# When code changes, trigger upgrade procedure
# Based on https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/upgrader.rb
gitlab-gems:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: bundle install --deployment --without development test mysql aws
    - watch:
      - git: gitlab-git
    - require:
      - git: gitlab-git
      - file: gitlab-db-config
      - file: gitlab-config
      - file: unicorn-config
      - file: rack_attack-config
      - gem: bundler

gitlab-migrate-db:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: bundle exec rake db:migrate RAILS_ENV=production
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-gems

gitlab-recompile-assets:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: bundle exec rake assets:clean assets:precompile RAILS_ENV=production
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-migrate-db

gitlab-clear-cache:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: bundle exec rake cache:clear RAILS_ENV=production
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-recompile-assets

gitlab-stash:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: git stash
    - watch:
      - git: gitlab-git
    - require:
      - cmd: gitlab-clear-cache

gitlab-initialize:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab
    - name: echo yes | bundle exec rake gitlab:setup RAILS_ENV=production
    - unless: psql -U {{ salt['pillar.get']('gitlab:db_user') }} {{ salt['pillar.get']('gitlab:db_name') }} -c 'select * from users;'
    - watch:
      - git: gitlab-git
    - require:
      - git: gitlab-git
      - cmd: gitlab-gems

gitlab-service:
  file.managed:
    - name: /etc/init.d/gitlab
    - source: salt://gitlab/files/gitlab-init
    - user: root
    - group: root
    - mode: 755
  service:
    - name: gitlab
    - running
    - enable: True
    - require:
      - file: gitlab-service
      - cmd: gitlab-initialize
    - watch:
      - git: gitlab-git
      - file: gitlab-service
      - file: gitlab-db-config
      - file: gitlab-config
      - file: unicorn-config
      - file: rack_attack-config
      - cmd: gitlab-clear-cache

gitlab-logwatch:
  file.managed:
    - name: /etc/logrotate.d/gitlab
    - source: salt://gitlab/files/gitlab-logrotate
    - user: root
    - group: root
    - mode: 644

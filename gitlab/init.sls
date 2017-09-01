include:
  - gitlab.repos
  {% if not salt['pillar.get']('gitlab:archives:enabled', false) %}
  - gitlab.git
  {% endif %}
  - gitlab.packages
  - redis
  - gitlab.user
  - gitlab.ruby
  - gitlab.gitlab-shell
  - gitlab.gitlab-workhorse
  - gitlab.gitlab

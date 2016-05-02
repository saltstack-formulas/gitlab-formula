gitlab-formula
==============

Modification from original formula :

* No hardcoded path : possibilty to install gitlab where you want
* Use of Postgresql formula
* Original initd script from Gitlab setup
* Lot of little things...

SaltStack formula to install GitLab

Salt state for installing GitLab - https://gitlab.com/gitlab-org/gitlab-ce

Following original install docs ( https://gitlab.com/gitlab-org/gitlab-ce/blob/6-5-stable/doc/install/installation.md ) as close as possible, with some exceptions:

* ruby 1.9.3 is enough for it to work, so I'm using system packages for that

Attempt made to have most settings tunable via pillars.

Formula Dependencies
====================

* git: https://github.com/saltstack-formulas/git-formula

Available states
================

.. contents::
       :local:

``gitlab.runner``
-----------------

Install and configure from pillar, gitlab-runner for gitlab-ci. Using https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/gitlab-ci/README.md

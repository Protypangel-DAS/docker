# Docker
Pour lancer les container : `.\run-docker.bat`

Ce docker est composé de container :
* gitlab
* postgresql, contenant la bdd de gitlab
* verdaccio, étant le server privé npm
  * se connecte via les auth de gitlab


## Commande dans le container Gitlab

|Commande|Explication|
|--|--|
|gitlab-psql|Acceder à postgresql|
|gitlab-rails dbconsole|Accèder à la console gitlab|

## Récuperer le password gitlab admin :
```bash
docker exec 8f48f834e036 sh -c "cat /etc/gitlab/initial_root_password | grep Password: | cut -d' ' -f2-"
```

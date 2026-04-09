# ЛАБОРАТОРНАЯ №6. Continuous Deployment (CD). GitOps. ArgoCD. Kustomize charts

## Docs

* [ArgoCD installation](https://argo-cd.readthedocs.io/en/stable/getting_started/)

# Требования

Развернуть ArgoCD. Создать в нем несколько `application` и запустить в нем свои сервис/сервисы.

# 1) helm source chart + gitops repo
## helm source chart
Из 5 работы взять chart `LAB_5/helm/application`.<br>
Создать под него отдельный репозиторий (например `custom-lib`) в системе контроля версий (forgejo, gitlab) и загрузить.

```
$ cd LAB_5/helm/application
$ git init
$ git add --all
$ git remote add origin http://192.168.99.100:81/adminforg/custom-lib.git
$ git branch -m main
$ git push origin main
```

## gitops repo
Создать в системе контроля версий репозиторий с названием `gitops`.<br>
Перейти в директорию `LAB_6/gitops` и выполнить следующее:<br>

Инициализация git:
```
$ git init
```

Добавить submodule на `source helm chart`, который создали на предыдущем шаге:<br>
```
$ git submodule add http://192.168.99.100:81/adminforg/custom-lib.git chart
```

Ну и стандартные действия чтобы запушить репозиторий:
```
$ git remote add origin http://192.168.99.100:81/adminforg/gitops.git
$ git add --all
$ git commit -m "init"
$ git branch -m main
$ git push origin main
```

Создадим рабочую ветку `develop` и запушим ее:
```
$ git switch -C develop
$ git push origin develop
```

В итоге в нашей системе контроля версий должно два репозитория:
* helm source chart
* gitops repo (с ветками main, develop)

# 2) deploy ArgoCD

Подключиться по ssh к ВМ master-0 и выполнить следующие этапы:

## Перейти в рабочую директорию
```
$ cd ~/work/LAB_6/
```

## Скопировать ssh private key (имя priv_key не менять)
```
$ cp ~/.ssh/id_ed25519 ./argocd/files/ssh/priv_key
```

## Установить необходимые пакеты
```
$ ./scripts/install_pkgs.sh
```

## Создать ns для argocd
```
$ k create ns argocd
```

## Запустить сценарий для подстановки ssh_known_hosts
```
$ ./scripts/ssh_known_hosts_subts.sh
```

## Установить argocd
```
$ k apply -n argocd --server-side --force-conflicts -k ./argocd/
```

## Проверить статус
```
$ k get -n argocd all
```
![argocd_success_install](./docs/argocd_success_install.png "argocd_success_install")

## Проверить события (если не запускаются pods)
```
$ k get events -n argocd --sort-by='.lastTimestamp' --watch
```

## Получить пароль из секрета
```
$ ./scripts/obtain_argo_token.sh
```

## Зайти в UI ArgoCD

Добавить строку на `host` машину в /etc/hosts:
```
192.168.99.200 argocd.test.local
```
Открыть ArgoCD UI: [argocd](http://argocd.test.local)

Username: `admin`<br>
Password: `из команды выше`

## Проверить, что репозиторий добавился

http://argocd.test.local/settings/repos

![argocd_repo_connection](./docs/argocd_repo_connection.png "argocd_repo_connection")

# 3) Создать Application
![argocd_create_application](./docs/argocd_create_application.png "argocd_create_application")
Нажать `new app` ->
Вставить yaml манифест из `./gitops/.application/dev-application.yaml` -><br>
Нажать `save` -><br>
Нажать `create`

## Открыть созданый application и синхронизировать состояние
![argocd_application](./docs/argocd_application.png "argocd_application")
![argocd_sync](./docs/argocd_sync.png "argocd_sync")
![argocd_sync](./docs/argocd_success_sync.png "argocd_sync")

## Проверить работу gitops репозитория
ArgoCD отслеживает состояние синхронизированных манифестов с теми которые находятся в репозитории.

Если внести изменения в `gitops` репозиторий, загрузить изменения в репозиторий и затем нажать на `refresh` (или подождать), то все изменения, которые могут влиять на текущее состояние будут показаны в `diff`.<br>

Например, если поменять количество реплик, то можно увидеть изменение состояния.

![argocd_out_of_sync_state](./docs/argocd_out_of_sync_state.png "argocd_out_of_sync_state")
![argocd_diff](./docs/argocd_diff.png "argocd_diff")

Обычно все стенды кроме `prod` отслеживают состояние какой-нибудь любой ветки кроме `main/master` (например `develop`).<br>
Все изменения фиксируется в ней напрямую или через вспомогательные ветки `feature/*`, которые ответвляются от `develop`.<br>
Когда приходит время делать очередной релиз, то из `develop` через `PR` в `release branch` (например `main`), сливаются все изменения и затем синхронизируется `prod` стенд.<br>
Тем самым мы никак не влияем на релизную ветку на всех других этапах жизни ПО.<br>

![argocd_applications](./docs/argocd_applications.png "argocd_applications")

Можете также развернуть еще одно `application` с релизной веткой и выполнить какие-нибудь действия.<br>
Например внести измениня в рабочую ветку или изменить `live manifest`, посмотреть `logs` и.т.д.<br>

## Команды для полного удаления ArgoCD (если понадобится)
Само argocd устроено так, что хранит все постоянные данные в `etcd` кластера.<br>
Даже если не удалять созданные `application`, но удалить ArgoCD, они продолжат работу.<br>
После повторного развертывания и создания `application` ArgoCD увидит все запущенные ранее манифесты и покажет их статус синхронизации с gitops repository.
```
$ k delete -n argocd -k ./argocd/
$ k delete ns argocd
```

## При показе выполненного задания
* Продемонстрировать работоспособность ArgoCD с запущенными сервисами
* Изменить состояние репозитория и проверить что изменения видны в `diff`
* Синхронизировать состояние кластера с репозиторием


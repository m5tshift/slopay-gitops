# AGENTS.md — slopay-gitops

GitOps-репозиторий SLOPay: всё, что ArgoCD разворачивает в кластер выше bootstrap-слоя (SRS INF-2.2).
Требования — в `docs/SRS.md` репозитория [`slopay`](https://github.com/m5tshift/slopay), там же общие правила
в `AGENTS.md`. Ссылки вида «SRS 4.1.11» ведут на разделы SRS.

## Структура

```
apps/
  root.yaml              App of Apps
  platform/              Application платформенных компонентов
  services/              Application сервисов, тестовых компонентов и holmes-bridge
platform/<component>/    values и манифесты: local-path-provisioner, cert-manager, istio, envoy-rls,
                         cnpg, percona-mongodb, clickhouse, valkey, garage, openbao, external-secrets,
                         observability, holmesgpt, mailpit, arc, zot, karpenter, kwok, anvil,
                         network-policies
platform/strimzi/        оператор и CR Kafka, целиком сгенерированы Ansible-ролью из slopay
services/<component>/values.yaml   values чарта из Zot: сервисы, merchant-mock, rate-mock, payer-sim,
                         holmes-bridge
```

## Правила

- **Только декларативные манифесты и values.** Скриптов и ручных шагов здесь нет.
- **Секретов нет.** Только `ExternalSecret` со ссылками на OpenBao (SRS INF-2.4).
- **Неймспейсы создаёт bootstrap-слой** (Terraform, SRS INF-2.2). Здесь нет `Namespace`
  и `CreateNamespace=true`.
- **Чарты компонентов SLOPay берутся из Zot** как OCI-артефакты (SRS CI-5.3). Application указывает
  версию чарта, values лежат здесь.
- **Каждое изменение — через PR.** Исключение одно: CI основного репозитория пушит в `main` обновление
  тега образа и версии чарта через deploy key (SRS 4.1.11). Вручную `image.tag` и версия чарта не правятся.
  После merge или push ArgoCD применяет изменение сам (auto-sync, self-heal). `kubectl apply` и правка
  ресурсов в кластере запрещены.
- **`platform/strimzi/` вручную не редактируется:** правится Ansible-роль в `slopay`, манифесты
  генерируются заново (SRS INF-2.3).
- **Порядок развёртывания** задаётся `argocd.argoproj.io/sync-wave`: операторы и CRD раньше
  ресурсов, которые от них зависят.
- **Ресурсы** (SRS 6.2): у каждого пода `requests` и `limits`; сумма `requests` постоянной нагрузки —
  не больше 19 ГБ.
- **Реплики** (SRS 6.3): не меньше 2 у каждого сервиса. Меньше — только по порядку разгрузки SRS 6.2.
- **Сетевые политики** (SRS 4.1.10, 4.1.11): default-deny, разрешения — явными политиками Cilium.
- **Образы и чарты Bitnami запрещены.**
- **Окно заморозки** (SRS 6.3): auto-sync выключен, кластер зафиксирован на теге релиза, изменения
  только в ветки.
- Репозиторий публичный: правила SRS 4.1.11 действуют и здесь. Перед первым коммитом в клоне —
  `pre-commit install` (gitleaks и базовые проверки).

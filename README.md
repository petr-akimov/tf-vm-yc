# Проект Terraform + GitHub Actions (state в artifacts)

### Что изменено
- Убран S3/Object Storage backend.
- Terraform использует локальный `terraform.tfstate`.
- GitHub Actions хранит состояние (tfstate) в artifacts и восстанавливает его перед запуском.
- Добавлен `concurrency` в workflow для защиты от одновременных запусков.

### Минусы этого подхода
- Отсутствует надёжная блокировка — мы полагаемся на `concurrency` GitHub Actions.
- Артефакты имеют ограниченный срок хранения (настраивается в настройках репозитория).
- Менее удобен для командной работы по сравнению с удалённым backend.

### Secrets (GitHub)
- `YC_TOKEN` — токен Yandex Cloud
- `CLOUD_ID`
- `FOLDER_ID`
- `SSH_PUBLIC_KEY`

### Запуск
1. Заполнить секреты.
2. Закоммитить в `main` — workflow применит инфраструктуру и сохранит `terraform.tfstate` в artifacts.

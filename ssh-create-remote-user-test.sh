#!/usr/bin/bash

# Скрипт для создания удалённого пользователя на сервере с настройкой SSH-доступа и добавлением в выбранную группу (users или admin).
# Скрипт принимает 4 аргумента: 
# 1. Имя текущего пользователя с правами sudo (например, root или user)
# 2. IP-адрес сервера
# 3. Имя нового пользователя, которого необходимо создать
# 4. Публичный SSH-ключ для нового пользователя
#
# Скрипт проверяет существование пользователя и группы, создает директорию .ssh, добавляет публичный ключ и устанавливает необходимые права доступа.
# В случае, если группа не существует, она будет создана.
# Если публичный ключ уже существует, повторное добавление будет пропущено.

# Проверка на наличие необходимых аргументов
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <current_user> <server_ip> <new_user> <public_key>"
  exit 1
fi

# Переменные, полученные из аргументов
CURRENT_USER=$1         # текущий пользователь (например user или root)
SERVER_IP=$2            # IP-адрес сервера (например 44.208.164.98)
NEW_USER=$3             # имя нового пользователя (например user1)
PUBLIC_KEY=$4           # публичный ключ SSH

# Путь к приватному ключу
KEY_PATH="/home/alex/aws_server/ubuntu_server.pem"

# Запрос пароля
echo -n "Введите пароль для sudo: "
read -s PASSWORD
echo

# Запрос группы для нового пользователя
while true; do
  echo -n "Введите 'u' для добавления в группу users или 'a' для добавления в группу admin: "
  read GROUP_CHOICE

  if [ "$GROUP_CHOICE" = "u" ]; then
    USER_GROUP="users"
    break
  elif [ "$GROUP_CHOICE" = "a" ]; then
    USER_GROUP="admin"
    break
  else
    echo "Неверный ввод. Будет выбрана группа по умолчанию - 'users'"
    USER_GROUP="users"
  fi
done

# Проверка прав доступа к приватному ключу
if [ ! -f "$KEY_PATH" ]; then
  echo "Ошибка: Файл приватного ключа не найден: $KEY_PATH"
  exit 1
fi

if [ "$(stat -c %a "$KEY_PATH")" != "400" ]; then
  echo "Ошибка: Неправильные права доступа к файлу ключа. Установите права 400."
  exit 1
fi

# Подключение к серверу и выполнение команд
ssh -i "$KEY_PATH" -t "$CURRENT_USER@$SERVER_IP" << EOF
echo "$PASSWORD" | sudo -S -v

# Проверка существования пользователя
if id "$NEW_USER" &>/dev/null; then
  echo "Пользователь $NEW_USER уже существует. Выберите другое имя."
  #exit 1
else
  # Проверка наличия группы
  if ! getent group "$USER_GROUP" > /dev/null 2>&1; then
    # Создание группы
    echo "$PASSWORD" | sudo -S groupadd "$USER_GROUP"
    echo "Группа '$USER_GROUP' создана..."
  else
    echo "Группа '$USER_GROUP' уже существует..."
  fi

  # Создание нового пользователя и добавление его в группу '$USER_GROUP'
  echo "$PASSWORD" | sudo -S adduser --disabled-password --gecos "" --ingroup "$USER_GROUP" "$NEW_USER"
  echo "Пользователь $NEW_USER создан и добавлен в группу '$USER_GROUP'..."
fi

# Проверка существования директории '.ssh'
if [ ! -d "/home/$NEW_USER/.ssh" ]; then
  # Создание директории '.ssh' и установка прав
  echo "$PASSWORD" | sudo -S mkdir -p /home/$NEW_USER/.ssh
  echo "$PASSWORD" | sudo -S chmod 700 /home/$NEW_USER/.ssh
  echo "Директория /home/$NEW_USER/.ssh создана..."
else
  echo "Директория /home/$NEW_USER/.ssh уже существует..."
fi

# Проверка наличия публичного ключа
if ! grep -Fq "$PUBLIC_KEY" /home/$NEW_USER/.ssh/authorized_keys 2>/dev/null; then
  # Добавление публичного ключа
  echo "$PUBLIC_KEY" | sudo tee -a /home/$NEW_USER/.ssh/authorized_keys > /dev/null
  echo "$PASSWORD" | sudo -S chmod 600 /home/$NEW_USER/.ssh/authorized_keys
  echo "Публичный ключ добавлен для пользователя $NEW_USER..."
else
  echo "Публичный ключ для пользователя $NEW_USER уже существует..."
fi

# Установка правильных прав для директории '.ssh' и файла 'authorized_keys'
echo "$PASSWORD" | sudo -S chown -R "$NEW_USER:$USER_GROUP" /home/$NEW_USER/.ssh

# Проверка создания пользователя
MAX_RETRIES=6    # Максимальное количество попыток
RETRY_INTERVAL=90 # Интервал между попытками

for ((i=1; i<=MAX_RETRIES; i++)); do
  if id "$NEW_USER" &>/dev/null; then
    echo "Пользователь $NEW_USER успешно создан."
    break
  else
    echo "Пользователь $NEW_USER еще не создан. Ожидание..."
    sleep $RETRY_INTERVAL
  fi
done

# Если после всех попыток пользователь не был создан, выдаем ошибку
if ! id "$NEW_USER" &>/dev/null; then
  echo "Ошибка: не удалось создать пользователя $NEW_USER."
  exit 1
fi

EOF

echo "Процесс создания нового пользователя $NEW_USER завершен."
#!/bin/bash

# Тестовый скрипт

CONFIG_FILE="T3_DevOps_config.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file $CONFIG_FILE not found!" >&2
    exit 1
fi

source "$CONFIG_FILE"

add_log()
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_PATH" 
}

get_previous_pid()
{
    if [ -f "$PID_FILE" ]; then
        tail -n 1 "$PID_FILE" 2>/dev/null
    else
        echo ""
    fi
}

check_process_restart()
{
    local current_pid="$1"
    local previous_pid="$2"
    
    if [ -n "$previous_pid" ] && [ "$current_pid" != "$previous_pid" ]; then
        add_log "INFO: Process \"$PROCESS_NAME\" was restarted. Old PID: $previous_pid, New PID: $current_pid"
        return 0
    else
        return 1
    fi
}

# Функция создания тестового процесса
create_test_process()
{
    # Создаем тестовый скрипт
    cat > /tmp/test_process.sh << 'EOF'
#!/bin/bash
sleep 3
EOF
    chmod +x /tmp/test_process.sh
    
    # Запускаем в фоне и получаем ТОЛЬКО PID
    /tmp/test_process.sh &
    local pid=$!
    
    # Ждем немного чтобы процесс точно запустился
    sleep 0.5
    
    # Возвращаем ТОЛЬКО числовой PID
    echo "$pid"
}

run_restart_test()
{
    echo "=== ТЕСТ ОБНАРУЖЕНИЯ ПЕРЕЗАПУСКА ==="
    echo ""
    
    # Очищаем файлы перед тестом
    rm -f "$PID_FILE" "$LOG_PATH"
    
    echo "1. Запускаем первый процесс..."
    PID1=$(create_test_process)
    echo "   PID первого процесса: $PID1"
    
    # Сохраняем первый PID в файл
    echo "$PID1" > "$PID_FILE"
    echo "   Сохранили PID $PID1 в файл"
    
    echo ""
    echo "2. Проверяем с тем же PID (перезапуска не должно быть)..."
    check_process_restart "$PID1" "$(get_previous_pid)"
    if [ $? -eq 0 ]; then
        echo "   ❌ ОШИБКА: Ложное срабатывание перезапуска!"
    else
        echo "   ✓ OK: Перезапуск не обнаружен (правильно)"
    fi
    
    echo ""
    echo "3. Останавливаем первый процесс и запускаем второй..."
    kill "$PID1" 2>/dev/null
    sleep 2
    PID2=$(create_test_process)
    echo "   PID второго процесса: $PID2"
    
    echo ""
    echo "4. Проверяем с новым PID (должен обнаружить перезапуск)..."
    check_process_restart "$PID2" "$(get_previous_pid)"
    if [ $? -eq 0 ]; then
        echo "   ✓ OK: Перезапуск обнаружен правильно!"
        echo "   Старый PID: $PID1, Новый PID: $PID2"
    else
        echo "   ❌ ОШИБКА: Перезапуск не обнаружен!"
    fi
    
    echo ""
    echo "5. Проверяем логи..."
    if [ -f "$LOG_PATH" ]; then
        echo "   Содержимое лога:"
        cat "$LOG_PATH"
    else
        echo "   ❌ Лог файл не создан!"
    fi
    
    # Очистка
    kill "$PID2" 2>/dev/null
    rm -f /tmp/test_process.sh
}

run_edge_cases_test()
{
    echo ""
    echo "=== ТЕСТ ГРАНИЧНЫХ СЛУЧАЕВ ==="
    echo ""
    
    rm -f "$PID_FILE" "$LOG_PATH"
    
    echo "1. Тест с пустым предыдущим PID..."
    check_process_restart "1234" ""
    if [ $? -eq 0 ]; then
        echo "   ❌ ОШИБКА: Ложное срабатывание с пустым PID!"
    else
        echo "   ✓ OK: Правильно игнорирует пустой предыдущий PID"
    fi
    
    echo ""
    echo "2. Тест с одинаковыми PID..."
    check_process_restart "1234" "1234"
    if [ $? -eq 0 ]; then
        echo "   ❌ ОШИБКА: Ложное срабатывание с одинаковыми PID!"
    else
        echo "   ✓ OK: Правильно игнорирует одинаковые PID"
    fi
    
    echo ""
    echo "3. Тест с разными PID..."
    check_process_restart "1234" "5678"
    if [ $? -eq 0 ]; then
        echo "   ✓ OK: Правильно обнаружил разные PID"
    else
        echo "   ❌ ОШИБКА: Не обнаружил разные PID!"
    fi
}

# Запуск тестов
echo "ЗАПУСК ТЕСТОВ ОБНАРУЖЕНИЯ ПЕРЕЗАПУСКА ПРОЦЕССА"
echo "=============================================="

run_restart_test
run_edge_cases_test

echo ""
echo "=============================================="
echo "ТЕСТИРОВАНИЕ ЗАВЕРШЕНО"
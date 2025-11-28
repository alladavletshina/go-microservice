package utils

import (
    "fmt"
    "log"
    "time"
)

func LogUserAction(action string, userID int) {
    logMessage := fmt.Sprintf("[%s] Action: %s, UserID: %d", 
        time.Now().Format(time.RFC3339), action, userID)
    
    // В реальном приложении здесь можно писать в файл или отправлять в ELK
    log.Println(logMessage)
    
    // Имитация асинхронной работы
    go func(msg string) {
        time.Sleep(100 * time.Millisecond) // имитация задержки
        fmt.Printf("Async log completed: %s\n", msg)
    }(logMessage)
}
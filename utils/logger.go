package utils

import (
    "fmt"
    "log"
    "time"
)

func LogUserAction(action string, userID int) {
    logMessage := fmt.Sprintf("[%s] Action: %s, UserID: %d", 
        time.Now().Format(time.RFC3339), action, userID)
    
    log.Println(logMessage)
    
    go func(msg string) {
        time.Sleep(100 * time.Millisecond) 
        fmt.Printf("Async log completed: %s\n", msg)
    }(logMessage)
}

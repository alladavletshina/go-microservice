package models

type User struct {
    ID      int    `json:"id"`
    Name    string `json:"name"`
    Email   string `json:"email"`
    Avatar  string `json:"avatar,omitempty"`  // URL к аватару в MinIO
}

package handlers

import (
    "encoding/json"
    "net/http"
    "strconv"
    
    "github.com/gorilla/mux"
    "go-microservice/models"
    "go-microservice/services"
    "go-microservice/utils"
)

type UserHandler struct {
    userService *services.UserService
}

func NewUserHandler() *UserHandler {
    return &UserHandler{
        userService: services.GetUserService(),
    }
}

func (h *UserHandler) GetUsers(w http.ResponseWriter, r *http.Request) {
    users := h.userService.GetAll()
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(users)
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    id, err := strconv.Atoi(vars["id"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }
    
    user, err := h.userService.GetByID(id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}

func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var user models.User
    if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    // Валидация
    if user.Name == "" || user.Email == "" {
        http.Error(w, "Name and email are required", http.StatusBadRequest)
        return
    }
    
    savedUser := h.userService.Create(user)
    
    // Асинхронное логирование
    go utils.LogUserAction("CREATE", savedUser.ID)
    
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(savedUser)
}

func (h *UserHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    id, err := strconv.Atoi(vars["id"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }
    
    var user models.User
    if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    updatedUser, err := h.userService.Update(id, user)
    if err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }
    
    // Асинхронное логирование
    go utils.LogUserAction("UPDATE", updatedUser.ID)
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(updatedUser)
}

func (h *UserHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    id, err := strconv.Atoi(vars["id"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }
    
    if err := h.userService.Delete(id); err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }
    
    // Асинхронное логирование
    go utils.LogUserAction("DELETE", id)
    
    w.WriteHeader(http.StatusNoContent)
}

// Добавьте этот метод в UserHandler
func (h *UserHandler) UploadUserAvatar(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    userID, err := strconv.Atoi(vars["id"])
    if err != nil {
        http.Error(w, "Invalid user ID", http.StatusBadRequest)
        return
    }

    // Проверяем существование пользователя
    _, err = h.userService.GetByID(userID)
    if err != nil {
        http.Error(w, "User not found", http.StatusNotFound)
        return
    }

    // Парсим multipart форму
    err = r.ParseMultipartForm(10 << 20) // 10 MB
    if err != nil {
        http.Error(w, "Failed to parse form", http.StatusBadRequest)
        return
    }

    file, header, err := r.FormFile("avatar")
    if err != nil {
        http.Error(w, "No avatar file provided", http.StatusBadRequest)
        return
    }
    defer file.Close()

    // Читаем файл
    imageData, err := io.ReadAll(file)
    if err != nil {
        http.Error(w, "Failed to read file", http.StatusInternalServerError)
        return
    }

    // Проверяем размер файла
    if len(imageData) > 5<<20 { // 5 MB
        http.Error(w, "File too large", http.StatusBadRequest)
        return
    }

    // Загружаем в MinIO
    storageService := services.GetStorageService()
    avatarURL, err := storageService.UploadUserAvatar(userID, imageData)
    if err != nil {
        log.Printf("Failed to upload avatar: %v", err)
        http.Error(w, "Failed to upload avatar", http.StatusInternalServerError)
        return
    }

    // Возвращаем URL аватара
    response := map[string]string{
        "avatar_url": avatarURL,
        "message":    "Avatar uploaded successfully",
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
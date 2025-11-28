package services

import (
    "errors"
    "go-microservice/models"
    "sync"
    "sync/atomic"
)

type UserService struct {
    users  map[int]models.User
    nextID int64
    mutex  sync.RWMutex
}

var (
    userServiceInstance *UserService
    once                sync.Once
)

func GetUserService() *UserService {
    once.Do(func() {
        userServiceInstance = &UserService{
            users:  make(map[int]models.User),
            nextID: 1,
        }
    })
    return userServiceInstance
}

func (s *UserService) Create(user models.User) models.User {
    s.mutex.Lock()
    defer s.mutex.Unlock()
    
    user.ID = int(atomic.AddInt64(&s.nextID, 1))
    s.users[user.ID] = user
    return user
}

func (s *UserService) GetByID(id int) (models.User, error) {
    s.mutex.RLock()
    defer s.mutex.RUnlock()
    
    user, exists := s.users[id]
    if !exists {
        return models.User{}, errors.New("user not found")
    }
    return user, nil
}

func (s *UserService) GetAll() []models.User {
    s.mutex.RLock()
    defer s.mutex.RUnlock()
    
    users := make([]models.User, 0, len(s.users))
    for _, user := range s.users {
        users = append(users, user)
    }
    return users
}

func (s *UserService) Update(id int, updatedUser models.User) (models.User, error) {
    s.mutex.Lock()
    defer s.mutex.Unlock()
    
    if _, exists := s.users[id]; !exists {
        return models.User{}, errors.New("user not found")
    }
    
    updatedUser.ID = id
    s.users[id] = updatedUser
    return updatedUser, nil
}

func (s *UserService) Delete(id int) error {
    s.mutex.Lock()
    defer s.mutex.Unlock()
    
    if _, exists := s.users[id]; !exists {
        return errors.New("user not found")
    }
    
    delete(s.users, id)
    return nil
}

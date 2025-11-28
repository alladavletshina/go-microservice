package services

import (
    "bytes"
    "context"
    "fmt"
    "log"
    "sync"
    
    "github.com/minio/minio-go/v7"
    "github.com/minio/minio-go/v7/pkg/credentials"
)

type StorageService struct {
    client     *minio.Client
    bucketName string
}

var (
    storageServiceInstance *StorageService
    storageOnce            sync.Once
)

func GetStorageService() *StorageService {
    storageOnce.Do(func() {
        endpoint := "minio:9000"
        accessKey := "admin"
        secretKey := "password"
        useSSL := false

        client, err := minio.New(endpoint, &minio.Options{
            Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
            Secure: useSSL,
        })
        
        if err != nil {
            log.Printf("Warning: Failed to create MinIO client: %v", err)
            storageServiceInstance = &StorageService{client: nil, bucketName: "user-avatars"}
            return
        }
        
        bucketName := "user-avatars"
        ctx := context.Background()
        
        exists, err := client.BucketExists(ctx, bucketName)
        if err == nil && !exists {
            err = client.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{})
            if err != nil {
                log.Printf("Error creating bucket: %v", err)
            } else {
                log.Printf("Successfully created bucket: %s", bucketName)
            }
        }
        
        storageServiceInstance = &StorageService{
            client:     client,
            bucketName: bucketName,
        }
        
        log.Println("MinIO storage service initialized successfully")
    })
    
    return storageServiceInstance
}

func (s *StorageService) IsAvailable() bool {
    return s.client != nil
}

func (s *StorageService) UploadUserAvatar(userID int, imageData []byte) (string, error) {
    if !s.IsAvailable() {
        return "", fmt.Errorf("storage service not available")
    }
    
    ctx := context.Background()
    objectName := fmt.Sprintf("user-%d-avatar.jpg", userID)
    contentType := "image/jpeg"
    
    _, err := s.client.PutObject(
        ctx,
        s.bucketName,
        objectName,
        bytes.NewReader(imageData),
        int64(len(imageData)),
        minio.PutObjectOptions{ContentType: contentType},
    )
    
    if err != nil {
        return "", fmt.Errorf("failed to upload avatar: %v", err)
    }
    
    avatarURL := fmt.Sprintf("http://localhost:9000/%s/%s", s.bucketName, objectName)
    return avatarURL, nil
}

func (s *StorageService) GetUserAvatarURL(userID int) string {
    if !s.IsAvailable() {
        return ""
    }
    
    objectName := fmt.Sprintf("user-%d-avatar.jpg", userID)
    return fmt.Sprintf("http://localhost:9000/%s/%s", s.bucketName, objectName)
}

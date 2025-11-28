package services

import (
    "context"
    "log"
    
    "github.com/minio/minio-go/v7"
    "github.com/minio/minio-go/v7/pkg/credentials"
)

type StorageService struct {
    client *minio.Client
}

func NewStorageService() *StorageService {
    endpoint := "minio:9000"
    accessKey := "admin"
    secretKey := "password"
    useSSL := false

    client, err := minio.New(endpoint, &minio.Options{
        Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
        Secure: useSSL,
    })
    
    if err != nil {
        log.Fatalf("Failed to create MinIO client: %v", err)
    }
    
    // Создаем bucket если не существует
    bucketName := "user-avatars"
    ctx := context.Background()
    
    exists, err := client.BucketExists(ctx, bucketName)
    if err == nil && !exists {
        err = client.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{})
        if err != nil {
            log.Printf("Error creating bucket: %v", err)
        }
    }
    
    return &StorageService{client: client}
}

func (s *StorageService) UploadUserAvatar(userID int, filePath string) error {
    ctx := context.Background()
    bucketName := "user-avatars"
    objectName := fmt.Sprintf("user-%d-avatar", userID)
    
    _, err := s.client.FPutObject(ctx, bucketName, objectName, filePath, minio.PutObjectOptions{})
    return err
}
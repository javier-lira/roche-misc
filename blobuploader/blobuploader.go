package main

import (
	"context"
	"fmt"
	"log"
	"net/url"
	"os"

	"github.com/Azure/azure-storage-blob-go/azblob"
)

func main() {
	var configuration *Configuration
	if len(os.Args) != 2 {
		log.Fatal("Usage: ./blobuploader <config-file>")
	} else {
		configuration = GetConfiguration(os.Args[1])
	}

	accountName := configuration.Azure.StorageAccountName
	accountKey := configuration.Azure.StorageAccountKey
	credential, err := azblob.NewSharedKeyCredential(accountName, accountKey)
	if err != nil {
		log.Fatal("Invalid credentials with error: " + err.Error())
	}
	p := azblob.NewPipeline(credential, azblob.PipelineOptions{})

	containerName := configuration.Blob.ContainerName

	// From the Azure portal, get your storage account blob service URL endpoint.
	URL, _ := url.Parse(
		fmt.Sprintf("https://%s.blob.core.windows.net/%s", accountName, containerName))

	// Create a ContainerURL object that wraps the container URL and a request
	// pipeline to make requests.
	containerURL := azblob.NewContainerURL(*URL, p)

	// Create the container
	log.Println("Creating a container named ", containerName)
	ctx := context.Background() // This example uses a never-expiring context
	_, err = containerURL.Create(ctx, azblob.Metadata{}, azblob.PublicAccessBlob)
	if err != nil {
		log.Fatal("Unable to create container: " + err.Error())
	}

	// Here's how to upload a blob.
	blobURL := containerURL.NewBlockBlobURL(configuration.Blob.BlobName)

	file, err := os.Open(configuration.Source)
	if err != nil {
		log.Fatal("Unable to open file: " + err.Error())
	}
	defer file.Close()

	log.Println("Start uploading file")
	azblob.UploadFileToBlockBlob(ctx, file, blobURL,
		azblob.UploadToBlockBlobOptions{})
	log.Println("Upload complete")
	var url = blobURL.URL()
	os.Stderr.WriteString(url.String())
}

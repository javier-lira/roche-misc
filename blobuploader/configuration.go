package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
)

type AzureConfiguration struct {
	StorageAccountName string `json:"storageAccountName"`
	StorageAccountKey  string `json:"storageAccountKey"`
}

type BlobConfiguration struct {
	ContainerName string `json:"containerName"`
	BlobName      string `json:"blobName"`
}

type Configuration struct {
	Azure  AzureConfiguration `json:"azure"`
	Blob   BlobConfiguration  `json:"blob"`
	Source string             `json:"source"`
}

func GetConfiguration(configFile string) *Configuration {

	configBytes, err := ioutil.ReadFile(configFile)
	if err != nil {
		log.Fatal("Error reading configuration file", err)
	}
	var config Configuration
	err = json.Unmarshal(configBytes, &config)
	if err != nil {
		log.Fatal("Error parsing config file to JSON: " + configFile)
	}
	return &config
}

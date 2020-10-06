package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/javier-lira/roche-misc/cosmosdbtoken"
)

func processItem(execute <-chan bool,
	done chan<- bool,
	idx int,
	data interface{},
	masterKeyBase64 string,
	cosmosdbInstance string,
	database string,
	collection string) {

	<-execute

	verb := "POST"
	resourceType := "docs"
	resourceLink := fmt.Sprintf("dbs/%s/colls/%s", database, collection)
	url := fmt.Sprintf("https://%s.documents.azure.com/%s/docs", cosmosdbInstance, resourceLink)

	jsonContent, _ := json.Marshal(data)
	authToken, date := cosmosdbtoken.GetAuthorizationToken(masterKeyBase64, verb, resourceType, resourceLink)

	client := &http.Client{}
	request, _ := http.NewRequest(verb, url, bytes.NewReader(jsonContent))
	request.Header.Set("Authorization", authToken)
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("x-ms-date", date)
	request.Header.Set("x-ms-version", "2018-09-17")
	resp, err := client.Do(request)

	if err != nil {
		log.Println(idx, ": Error communicating to cosmosdb: ", err)
	} else {
		log.Println(idx, ": ", resp.Status)
		defer resp.Body.Close()
		body, _ := ioutil.ReadAll(resp.Body)
		log.Println(idx, ": ", string(body))
	}
	done <- true
}

func main() {
	var jsonFile *string = flag.String("json", "", "Json file to upload")
	var masterKeyBase64 *string = flag.String("masterKey", "", "Primary key for accessing to cosmosdb")
	var cosmosdbInstance *string = flag.String("cosmosdb", "", "Name of the cosmosDB instance")
	var database *string = flag.String("database", "", "Database name")
	var collection *string = flag.String("collection", "", "Collection name")
	var logFile *string = flag.String("log", "output.log", "Log file")

	flag.Parse()

	if flag.NFlag() != 6 {
		fmt.Println("Not all parameters have been set. Please use -h for more information")
		os.Exit(1)
	}

	f, err := os.OpenFile(*logFile, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("error opening file: %v", err)
	}
	defer f.Close()

	log.SetOutput(f)

	jsonFileContent, err := ioutil.ReadFile(*jsonFile)
	if err != nil {
		log.Println("Error reading file: ", err)
		os.Exit(1)
	}

	var array []interface{}
	json.Unmarshal(jsonFileContent, &array)

	done := make(chan bool, len(array))
	execute := make(chan bool, 10)
	for idx, item := range array {
		go processItem(execute, done, idx, item, *masterKeyBase64, *cosmosdbInstance, *database, *collection)
	}

	for i := 0; i < 10; i++ {
		execute <- true
	}

	for i := 0; i < len(array); i++ {
		<-done
		execute <- true
	}
}

package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"flag"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

func getAuthorizationToken(masterKeyBase64 string,
	verb string,
	resourceType string,
	resourceLink string) (string, string) {
	date := time.Now().UTC().Format(http.TimeFormat)
	payload := fmt.Sprintf("%s\n%s\n%s\n%s\n%s\n",
		strings.ToLower(verb),
		strings.ToLower(resourceType),
		resourceLink,
		strings.ToLower(date),
		"")
	masterKey, _ := base64.StdEncoding.DecodeString(masterKeyBase64)
	h := hmac.New(sha256.New, []byte(masterKey))
	h.Write([]byte(payload))
	sha := base64.StdEncoding.EncodeToString(h.Sum(nil))
	auth := fmt.Sprintf("type=master&ver=1.0&sig=%s", sha)
	authencoded := url.QueryEscape(auth)
	return authencoded, date
}

func main() {

	var masterKeyBase64 *string = flag.String("masterkey", "", "Primary key for accessing to cosmosdb")
	var verb *string = flag.String("verb", "GET", "Method for the HTTP request, e.g. GET, POST or PUT")
	var resourceType *string = flag.String("resourceType", "docs", "Type of resource that is being requested")
	var resourceLink *string = flag.String("resourceLink", "", "Identifier for the entity being queried")

	flag.Parse()

	if flag.NFlag() != 4 {
		fmt.Println("Not all parameters have been set. Please use -h for more information")
		os.Exit(1)
	}

	authToken, date := getAuthorizationToken(*masterKeyBase64,
		*verb,
		*resourceType,
		*resourceLink)

	fmt.Println("Authorization: ", authToken)
	fmt.Println("Date: ", date)

}

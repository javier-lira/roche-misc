package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/javier-lira/roche-misc/cosmosdbtoken"
)

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

	authToken, date := cosmosdbtoken.GetAuthorizationToken(*masterKeyBase64,
		*verb,
		*resourceType,
		*resourceLink)

	fmt.Println("Authorization: ", authToken)
	fmt.Println("Date: ", date)

}

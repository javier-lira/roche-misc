package cosmosdbtoken

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

func GetAuthorizationToken(masterKeyBase64 string,
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

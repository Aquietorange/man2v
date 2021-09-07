package tool

import (
	"fmt"
	"strings"
	"testing"
)

func Test_Substr(t *testing.T) {

	var s = ""

	fmt.Println(Substr(s, strings.LastIndex(s, "://")+3, 6))
	fmt.Println(Substr(s, strings.LastIndex(s, "://")+3, -1))

	fmt.Println(Substr(s, 0, 0+strings.Index(s, "://")))

	fmt.Println(Substr(s, strings.LastIndex(s, "://")+3, -1))

}

func Test_NewUUID(t *testing.T) {
	uuid := NewUUID()
	uuid, _ = ParseString(uuid.String())
	fmt.Println(uuid.String())
}

package core

import (
	"os"

	"github.com/Aquietorange/tool/tfile"
)

func init() {
	var err error
	CorePath, err = tfile.GetCurrentDirectory()
	if err != nil {
		os.Exit(0)
	}

}

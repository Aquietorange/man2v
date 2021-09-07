package core

import (
	"fmt"
	"testing"
	"time"
)

func TestShellout(t *testing.T) {
	out, _, err := Shellout(`test.bat`)
	if err != nil {
		t.Error(err)
	} else {
		t.Log(out)
	}
}

func TestDeferRestartV2(t *testing.T) {
	DeferRestartV2()
	time.Sleep(5 * time.Second)
	DeferRestartV2()
	time.Sleep(11 * time.Second)
	DeferRestartV2()
	time.Sleep(6 * time.Second)
	DeferRestartV2()
	time.Sleep(15 * time.Second)
}

func Test_Savenodelist(t *testing.T) {
	nodelist := `vmess://eyJ2IjoiMiIsInBzIjoiQOWumOe9keawuOS5heWcsOWdgHBhb2x1ei5wdyDor7fmjILku6PnkIborr/pl64iLCJhZGQiOiJ3d3cuYmluZy5jb20iLCJwb3J0IjoiMTAwODYiLCJpZCI6IjI2NjFiNWY4LTgwNjItMzRhNS05MzcxLWE0NDMxM2E3NWI2YiIsImFpZCI6IjIiLCJuZXQiOiJ0Y3AiLCJ0eXBlIjoibm9uZSIsImhvc3QiOiIiLCJ0bHMiOiIifQ==
vmess://eyJ2IjoiMiIsInBzIjoiQOWPr+eUqOa1gemHjzUwR0J86L+H5pyf5pe26Ze0MjAyMVwvMDlcLzI2IiwiYWRkIjoid3d3LmJpbmcuY29tIiwicG9ydCI6IjEwMDg2IiwiaWQiOiIyNjYxYjVmOC04MDYyLTM0YTUtOTM3MS1hNDQzMTNhNzViNmIiLCJhaWQiOiIyIiwibmV0IjoidGNwIiwidHlwZSI6Im5vbmUiLCJob3N0IjoiIiwidGxzIjoiIn0=

vmess://eyJob3N0Ijoid3d3LmJpbmcuY29tIiwicGF0aCI6Ii92MnJheSIsInRscyI6IiIsInZlcmlmeV9jZXJ0Ijp0cnVlLCJhZGQiOiJxZC5sdC4wMS54eXgteHktMDEuY29tIiwicG9ydCI6MzAwMDcsImFpZCI6MSwibmV0Ijoid3MiLCJ0eXBlIjoibm9uZSIsInYiOiIyIiwicHMiOiLkv4TnvZfmlq9WMi1ITjAxUlUwNyIsImlkIjoiMzU5MTZjZGMtZTFhZS0zNzk5LWEyNzYtOGM3MzQwOWE1NGZjIiwiY2xhc3MiOjJ9
vmess://eyJob3N0Ijoid3d3LmJpbmcuY29tIiwicGF0aCI6Ii92MnJheSIsInRscyI6IiIsInZlcmlmeV9jZXJ0Ijp0cnVlLCJhZGQiOiJxZC5sdC4wMS54eXgteHktMDEuY29tIiwicG9ydCI6MzAwMDgsImFpZCI6MSwibmV0Ijoid3MiLCJ0eXBlIjoibm9uZSIsInYiOiIyIiwicHMiOiLkv4TnvZfmlq9WMi1ITjAxUlUwOCIsImlkIjoiMzU5MTZjZGMtZTFhZS0zNzk5LWEyNzYtOGM3MzQwOWE1NGZjIiwiY2xhc3MiOjJ9`
	Savenodelist(nodelist, "test")
}

func Test_Runexe(t *testing.T) {
	out, pid, err := Runexe("v2ray.exe", []string{" -config", "config.json"})
	fmt.Println(out, pid, err)
}

//go:build windows
// +build windows

package core

import (
	"strings"
	"syscall"
	"unsafe"
)

func init() {

	GetProcessByName_win = func(name string) (int64, []string) {

		name = name + ".exe"
		var targetProcess = syscall.ProcessEntry32{
			Size: 0,
		}

		pHandle, _ := syscall.CreateToolhelp32Snapshot(15, 0) //当前进程快照
		if int(pHandle) == -1 {
			return 0, []string{"error:Can not find any proess"}
		}
		defer syscall.CloseHandle(pHandle)

		for {
			var proc syscall.ProcessEntry32
			proc.Size = uint32(unsafe.Sizeof(proc))
			if err := syscall.Process32Next(pHandle, &proc); err == nil {

				pname := syscall.UTF16ToString(proc.ExeFile[0:])

				xpoint := strings.LastIndex(pname, ".exe")
				if pname == name || (xpoint > 0 && pname[:xpoint] == name) {
					return int64(proc.ProcessID), nil
				}
			} else {
				break
			}
		}

		return int64(targetProcess.ProcessID), []string{}

		//return targetProcess, fmt.Errorf("error:Can not find any proess")
	}
}

//进程名 取进程

//win 结束进程
func CloseProcess(pid uint32) bool {
	handle, err := syscall.OpenProcess(1024, false, pid)
	if err != nil {
		return false
	}

	psapi := syscall.NewLazyDLL("kernel32.dll")
	TerminateProcess := psapi.NewProc("TerminateProcess")

	_, _, err = TerminateProcess.Call(uintptr(handle), 0)

	if err != nil { //err := syscall.TerminateProcess(handle, 0);
		return false
	} else {
		return true
	}
}

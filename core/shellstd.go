package core

import (
	"bufio"
	"bytes"
	"io"
	"os/exec"
)

func Shellstd(command string) (string, error) {
	ShellToUse := "/bin/bash"

	cmd := exec.Command(ShellToUse, "-c", command)

	stdout, _ := cmd.StdoutPipe()

	//input, _ := cmd.StdinPipe()
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	//fmt.Fprintln(input, command) //此方法 运行的程序 在主程序退出时，被调用的程序也会关闭

	err := cmd.Start()
	if err != nil {
		return stdout.Close().Error(), err
	}
	render := bufio.NewReader(stdout)

	for {
		line, err := render.ReadString('\n')
		if err != nil || err == io.EOF {
			break
		}
		OutLine.Append(line)
	}
	cmd.Wait()
	return stdout.Close().Error(), err
}

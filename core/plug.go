package core

import (
	"bufio"
	"bytes"
	"io"
	"io/ioutil"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/Aquietorange/tool/container/tqueue"
	"github.com/Aquietorange/tool/tfile"
	"github.com/gogf/gf/encoding/gjson"
	"github.com/gogf/gf/os/glog"
)

type PlugInfo struct {
	Name    string              //插件昵称,同时也是插件目录  可重复
	SubName string              //插件子模块 名称,默认为main,  不可重复
	Pid     int64               //插件模块已运行的PID
	File    string              //相对运行目录  相对主程序 plugs 目录
	Args    []string            //插件运行 指定参数
	Conf    string              //配置文件相对路径  相对主程序 plugs 目录
	Logs    *tqueue.CircleQueue //插件 运行日志
}

type Plug struct {
	Pluginfos []*PlugInfo
}

//前端展示数据
func (p *Plug) GetPlugInfos() []map[string]interface{} {
	var arr []map[string]interface{}

	for _, info := range p.Pluginfos {
		arr = append(arr, map[string]interface{}{
			"name":    info.Name,
			"subname": info.SubName,
			"pid":     info.Pid,
		})
	}
	return arr
}

//前端读插件运行日志
func (p *Plug) GetLogs(name, subname string) []string {
	pinfp := p.FindPlugSubs(name, subname)

	var lines []string

	for _, v := range pinfp {
		lines = append(lines, "------"+v.Name+":"+v.SubName+":logs-----")
		for _, QueueContents := range v.Logs.Getlines(0) {
			lines = append(lines, QueueContents.Content)
		}
	}
	return lines
}

//判断 插件 是否已安装
func (p *Plug) IsInstalled(name string) bool {
	if tfile.PathExists(CorePath + "/plugs/" + name) {
		return true
	} else {
		return false
	}
}

//查找插件子模块 返回一项
func (p *Plug) FindPlugSub(name, subname string) *PlugInfo {
	for _, info := range p.Pluginfos {
		if info.Name == name && info.SubName == subname {
			return info
		}
	}
	return nil
}

//查找插件子模块 可返回 多项
func (p *Plug) FindPlugSubs(name, subname string) []*PlugInfo {
	var plinfos []*PlugInfo
	for _, info := range p.Pluginfos {
		if subname != "" {
			if info.Name == name && info.SubName == subname {
				//return info
				plinfos = append(plinfos, info)
			}
		} else {
			if info.Name == name {
				//return info
				plinfos = append(plinfos, info)
			}

		}

	}
	return plinfos
}

//安装插件
func (p *Plug) Install(name string) bool {
	installsh, ok := Pluginstallsh[name]
	if !ok {
		return false
	}

	shf := tfile.PathGetFileName(installsh, true)
	out, _, _ := Shellout("wget " + installsh + "&&chmod +x " + shf + "&&./" + shf)
	//fmt.Println(installsh)
	glog.Info(out)

	if tfile.PathExists(CorePath + "/plugs/NetPenetrate/client") {
		return true
	} else {
		return false
	}
}

//运行插件
func (p *Plug) Run(name, subname string) bool {
	pinfo := p.FindPlugSub(name, subname)
	if pinfo.Pid > 0 {
		return true
	} else {

		if runtime.GOOS == "linux" {
			cmd := exec.Command(CorePath+"/plugs"+pinfo.File, pinfo.Args...)
			cmd.Dir = CorePath + "/plugs/" + pinfo.Name
			stdout, _ := cmd.StdoutPipe()
			var stderr bytes.Buffer
			cmd.Stderr = &stderr

			err := cmd.Start()
			if err != nil {
				pinfo.Logs.Append(err.Error())
				return false
			}

			render := bufio.NewReader(stdout)
			pinfo.Pid = int64(cmd.Process.Pid)

			for {
				line, err := render.ReadString('\n')
				if err != nil || err == io.EOF {
					break
				}
				pinfo.Logs.Append(line)
			}
			cmd.Wait()
			pinfo.Pid = 0
			return false
		} else {
			cmd := exec.Command(CorePath+"/plugs"+pinfo.File, pinfo.Args...) //"cmd.exe"
			cmd.Dir = CorePath + "/plugs/" + pinfo.Name
			stdout, _ := cmd.StdoutPipe()
			var stderr bytes.Buffer
			cmd.Stderr = &stderr
			err := cmd.Start()
			if err != nil {
				pinfo.Logs.Append(err.Error())
				return false
			}

			render := bufio.NewReader(stdout)
			pinfo.Pid = int64(cmd.Process.Pid)

			for {
				line, err := render.ReadString('\n')
				if err != nil || err == io.EOF {
					break
				}
				pinfo.Logs.Append(line)
			}
			cmd.Wait()

			pinfo.Pid = 0
			return false
		}

	}
}

//停止插件
func (p *Plug) Stop(name, subname string) bool {
	pinfo := p.FindPlugSub(name, subname)
	if pinfo.Pid == 0 {
		return true
	} else {
		if runtime.GOOS == "linux" {
			Shellout("kill -9 " + strconv.Itoa(int(pinfo.Pid)))
		} else {
			Shellout("taskkill /f /pid " + strconv.Itoa(int(pinfo.Pid)) + " -t ")
		}
		return true
	}
}

//重启插件
func (p *Plug) Restart(pinfo *PlugInfo) bool {
	p.Stop(pinfo.Name, pinfo.SubName)
	time.Sleep(1 * time.Second)
	p.Run(pinfo.Name, pinfo.SubName)
	return true
}

//取插件配置 ，isjson=true 时，content 为gjson 类型，否则为string
func (p *Plug) GetConfig(name, subname string) (content interface{}, isjson bool) {
	var pinf *PlugInfo
	if subname == "" {
		aff := p.FindPlugSubs(name, subname)
		if len(aff) > 0 {
			pinf = aff[0]
		}
	} else {
		pinf = p.FindPlugSub(name, subname)
	}
	if pinf == nil {
		return "", false
	}

	suff := tfile.GetFileSuffixes(pinf.Conf)
	if suff == ".json" {
		confjson, err := gjson.Load(CorePath + "/plugs" + pinf.Conf)
		if err != nil {
			return nil, false
		}
		return confjson, true

	} else {
		confz, err := ioutil.ReadFile(CorePath + "/plugs" + pinf.Conf)
		if err != nil {
			return nil, false
		}
		return string(confz), false
	}
}

//更新并保存插件 配置 ,相关插件 重新启动
func (p *Plug) SetConfig(name, subname, value string) {
	var pinf *PlugInfo
	if subname == "" { //插件 子模块 共用 配置文件
		aff := p.FindPlugSubs(name, subname)
		if len(aff) > 0 {
			pinf = aff[0]
			ioutil.WriteFile(CorePath+"/plugs"+pinf.Conf, []byte(value), 0666)
		}

		for _, pf := range aff {
			if pf.Pid > 0 {
				p.Restart(pf)
			}
		}

	} else {
		pinf = p.FindPlugSub(name, subname)

		ioutil.WriteFile(CorePath+"/plugs"+pinf.Conf, []byte(value), 0666)
		if pinf.Pid > 0 {
			p.Restart(pinf)
		}
	}

}

var Plugs = Plug{
	Pluginfos: []*PlugInfo{},
}

var Pluginstallsh = map[string]string{
	"NetPenetrate": "https://raw.githubusercontent.com/Aquietorange/man2v/master/test/NetPenetrate.sh",
}

func init() {
	suffixes := ""
	if runtime.GOOS == "windows" {
		suffixes = ".exe"
	}

	Plugs.Pluginfos = append(Plugs.Pluginfos, &PlugInfo{
		Name:    "NetPenetrate",
		SubName: "Client",
		File:    "/NetPenetrate/client" + suffixes,
		Conf:    "/NetPenetrate/config.json",
		Logs:    tqueue.NewCircleQueue(300),
	})

	Plugs.Pluginfos = append(Plugs.Pluginfos, &PlugInfo{
		Name:    "NetPenetrate",
		SubName: "Server",
		File:    "/NetPenetrate/server" + suffixes,
		Conf:    "/NetPenetrate/config.json",
		Logs:    tqueue.NewCircleQueue(300),
	})

	autorunp := V2manJson.GetMap("plugautorun")

	for k, p := range autorunp {

		names := strings.Split(k, "_")

		if p.(float64) > 0 && len(names) == 2 {

			go Plugs.Run(names[0], names[1])

		}

	}

}

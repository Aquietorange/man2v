package core

import (
	"fmt"
	"runtime"

	"github.com/Aquietorange/tool/tfile"
)

type PlugInfo struct {
	Name    string //插件昵称,同时也是插件目录  可重复
	SubName string //插件子模块 名称,默认为main,  不可重复
	Pid     int64  //插件模块已运行的PID
	File    string //运行目录  相对主程序路径
}
type Plug struct {
	Pluginfos []PlugInfo
}

//判断 插件 是否已安装
func (p *Plug) IsInstalled(name string) bool {
	if tfile.PathExists(CorePath + "/" + name) {
		return true
	} else {
		return false
	}
}

//查找插件子模块
func (p *Plug) FindPlugSub(name, subname string) *PlugInfo {
	for _, info := range p.Pluginfos {
		if info.Name == name && info.SubName == subname {
			return &info
		}
	}
	return nil
}

//安装插件
func (p *Plug) Install(name string) bool {
	installsh, ok := Pluginstallsh[name]
	if !ok {
		return false
	}

	shf := tfile.PathGetFileName(installsh, true)
	out, _, _ := Shellout("wget " + installsh + "&&chmod +x " + shf + "&&./" + shf)

	fmt.Println(installsh)
	fmt.Println(out)
	return true
}

var Plugs = Plug{
	Pluginfos: []PlugInfo{},
}

var Pluginstallsh = map[string]string{
	"NetPenetrate": "https://raw.githubusercontent.com/Aquietorange/man2v/master/test/NetPenetrate.sh",
}

func init() {
	suffixes := ""
	if runtime.GOOS == "windows" {
		suffixes = ".exe"
	}

	Plugs.Pluginfos = append(Plugs.Pluginfos, PlugInfo{
		Name:    "NetPenetrate",
		SubName: "Client",
		File:    "/NetPenetrate/client" + suffixes,
	})

	Plugs.Pluginfos = append(Plugs.Pluginfos, PlugInfo{
		Name:    "NetPenetrate",
		SubName: "Server",
		File:    "/NetPenetrate/server" + suffixes,
	})

}

package core

import (
	"bufio"
	"bytes"
	"crypto/md5"
	"encoding/base64"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/Aquietorange/tool/container/tqueue"
	"github.com/Aquietorange/tool/tfile"
	"github.com/Aquietorange/tool/tnum"
	"github.com/Aquietorange/tool/tstr"
	"github.com/gogf/gf/encoding/gjson"
	"github.com/gogf/gf/util/gconv"
)

var DefaultV2Config = "config.json" //默认 v2 配置路径
var V2pid int = 0

var V2json *gjson.Json    //v2ray config
var V2manJson *gjson.Json //V2man		config

var aiaittimer *time.Timer                 //v2 config
var awaitmark chan int = make(chan int, 1) //v2 config

var aiaittimerV2man *time.Timer                 //v2man config
var awaitmarkV2man chan int = make(chan int, 1) //v2man config

var OutLine = tqueue.NewCircleQueue(100)

var GetProcessByName_win func(name string) (int64, []string)

//主程序运行目录
var CorePath string

func Runexe(command string, arg []string) (string, int, error) { //运行的子进程 会在进程退出后 自动关闭，暂无法做到 子进程不受主进程退出影响

	if runtime.GOOS == "linux" {
		cmd := exec.Command(command, arg...)
		cmd.Dir = GetCurrentDirectory()
		//	cmd.Path = GetCurrentDirectory()

		stdout, _ := cmd.StdoutPipe()

		//var stdout bytes.Buffer
		var stderr bytes.Buffer
		//cmd.Stdout = &stdout
		cmd.Stderr = &stderr
		/* process, err := os.StartProcess(cmd.Path, cmd.Args, &os.ProcAttr{
			Dir: cmd.Dir,
		}) */
		err := cmd.Start()
		if err != nil {
			return stdout.Close().Error(), 0, err
		}

		render := bufio.NewReader(stdout)
		V2pid = cmd.Process.Pid

		for {
			line, err := render.ReadString('\n')
			if err != nil || err == io.EOF {
				break
			}
			OutLine.Append(line)
		}
		cmd.Wait()
		V2pid = 0
		return stdout.Close().Error(), 0, err
	} else {
		cmd := exec.Command(command, arg...) //"cmd.exe"
		cmd.Dir = GetCurrentDirectory()
		stdout, _ := cmd.StdoutPipe()
		//var stdout bytes.Buffer
		var stderr bytes.Buffer
		//cmd.Stdout = &stdout
		cmd.Stderr = &stderr
		//input, _ := cmd.StdinPipe()
		//fmt.Fprintln(input, command+strings.Join(arg, " ")) //此方法 运行的程序 在主程序退出时，被调用的程序也会关闭
		err := cmd.Start()
		if err != nil {
			return stdout.Close().Error(), 0, err
		}

		render := bufio.NewReader(stdout)
		V2pid = cmd.Process.Pid

		for {
			line, err := render.ReadString('\n')
			if err != nil || err == io.EOF {
				break
			}
			OutLine.Append(line)
		}
		cmd.Wait()
		//input.Close()
		//cmd.Wait()
		V2pid = 0
		return stdout.Close().Error(), 0, err
	}
}

func Shellout(command string) (string, string, error) {
	ShellToUse := ""

	if runtime.GOOS == "windows" {

		ShellToUse = "cmd.exe"

	} else {

		ShellToUse = "/bin/bash"

	}

	var stdout bytes.Buffer

	var stderr bytes.Buffer

	cmd := exec.Command(ShellToUse)

	//cmd.Stdout = os.Stdout

	cmd.Stdout = &stdout

	cmd.Stderr = &stderr

	//cmd.Path = GetCurrentDirectory()

	cmd.Dir = GetCurrentDirectory()

	input, _ := cmd.StdinPipe()

	fmt.Fprintln(input, command) //此方法 运行的程序 在主程序退出时，被调用的程序也会关闭

	err := cmd.Start()

	input.Close()

	cmd.Wait()

	return stdout.String(), stderr.String(), err

}

//程序运行目录
func GetCurrentDirectory() string {
	//返回绝对路径 filepath.Dir(os.Args[0])去除最后一个元素的路径
	dir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		log.Fatal(err)
	}
	//将\替换成/
	return strings.Replace(dir, "\\", "/", -1)
}

//延迟重启 v2ray
func DeferRestartV2() {
	awaitmark <- 1
	aiaittimer = time.NewTimer(20 * time.Second)
	go func() {
		if len(awaitmark) > 0 { //防止 被之前协程 消费 导致 卡住
			<-awaitmark
		}

		select {
		case <-aiaittimer.C:
			//保存并重启v2
			fmt.Println("保存config并重启v2")

			ioutil.WriteFile(DefaultV2Config, V2json.MustToJson(), 07555)
			fmt.Println("-----1")
			go RestartV2ray()
		case <-awaitmark: //提前结束 标记
			fmt.Println("提前结束")
			break
		}
	}()
}

//延迟5秒 保存v2man 配置
func DeferSaveConfg() {
	awaitmarkV2man <- 1
	aiaittimerV2man = time.NewTimer(5 * time.Second)
	go func() {
		if len(awaitmarkV2man) > 0 { //防止 被之前协程 消费 导致 卡住
			<-awaitmarkV2man
		}
		select {
		case <-aiaittimerV2man.C:
			fmt.Println("保存v2man config")
			SaveV2manConfig()
		case <-awaitmarkV2man: //提前结束 标记
			fmt.Println("提前结束")
			break
		}
	}()
}

func SaveV2manConfig() {
	ioutil.WriteFile("v2man.json", V2manJson.MustToJson(), 07555)
}

//重启v2
func RestartV2ray() {

	if !hasv2() {
		return
	}

	//Loginfo.Println("开始重启v2ray")
	pid, file := Getv2config()

	if runtime.GOOS == "linux" {
		/* if pid > 0 {
			Shellout("kill -9 " + strconv.Itoa(int(pid)))
		}
		time.Sleep(1 * time.Second)
		go Runexe("./v2ray", []string{"-config", file}) */
		Shellout("systemctl restart v2ray")
		time.Sleep(2 * time.Second)
		outstr, _, _ := Shellout("systemctl show --property MainPID --value v2ray")
		fmt.Println(outstr)
		if outstr != "" {
			V2pid = gconv.Int(outstr)
		}

	} else { //windows
		if pid > 0 {
			Shellout("taskkill /f /pid " + strconv.Itoa(int(pid)) + " -t ")
			//CloseProcess(uint32(pid))
		}
		time.Sleep(1 * time.Second)
		//	out, pidn, err := Runexe("v2ray.exe", []string{" -config", file}) //  "nohup ./v2ray -config "+file+" >/dev/null 2>&1 &"
		go Runexe("v2ray.exe", []string{" -config", file})
		/* if pidn > 0 {
			V2pid = pidn
		}
		Loginfo.Println(out)
		Loginfo.Println(err) */
	}
}

func Getv2config() (pid int, file string) {
	/* pid, cmd := GetProcessByName("v2ray")

	for i, v := range cmd {
		if v == "-config" {
			file = cmd[i+1]
		}
	}
	if file == "" {
		file = DefaultV2Config
	} */

	if V2pid == 0 {
		if runtime.GOOS != "linux" {
			ppid, _ := GetProcessByName_win("v2ray")
			pid = int(ppid)
		} else {
			ppid, _ := GetProcessByName("v2ray")
			pid = int(ppid)
		}

	} else {
		pid = V2pid
	}
	file = DefaultV2Config

	return pid, file
}

//通过进程名 查找进程 linux ,win 下 name 不含.exe
func GetProcessByName(name string) (pid int64, cmd []string) {

	outstr, _, _ := Shellout("ps -aux")
	//outstr, _ := os.ReadFile("testrge.txt")
	lines := strings.Split(string(outstr), "\n")

	for _, line := range lines {
		spre, _ := regexp.Compile(`\s+`)
		ss := spre.Split(line, -1)
		if len(ss) >= 11 {
			paths := strings.Split(ss[10], "/")
			appname := paths[len(paths)-1]
			if appname == name {
				pid, _ = strconv.ParseInt(ss[1], 10, 64)
				cmd = ss[11:]
				return
			}
		}
	}
	return 0, []string{}

}

func FindSub(remark string) int {
	for i := range V2manJson.GetArray("subs") {
		if remark == V2manJson.GetString("subs."+strconv.Itoa(i)+".remark") {
			return i
		}
	}
	return -1
}

//查找 指定 tag 或 port 入站是否存在 ,不存在返回-1
func Findinbounds(tag string, port int) int {
	for i := range V2json.GetArray("inbounds") {
		if tag != "" && tag == V2json.GetString("inbounds."+strconv.Itoa(i)+".tag") {
			return i
		}
		if port > 0 && port == V2json.GetInt("inbounds."+strconv.Itoa(i)+".port") {
			return i
		}
	}
	return -1
}

//查找 是否存在 指定 tag 的出站,返回 路由下标
func Findrouteouttag(outtag string) int {

	for i := range V2json.GetArray("routing.rules") {

		if outtag == V2json.GetString("routing.rules."+strconv.Itoa(i)+".outboundTag") {

			return i
		}
	}
	return -1
}

//根据 别名 分组，保存节点列表
func Savenodelist(nodes, remark string) {
	reader := bufio.NewReader(strings.NewReader(nodes))

	for {
		line, errl := reader.ReadString('\n')
		if len(line) > 0 {
			protocol := tstr.Substr(line, 0, strings.Index(line, "://"))
			if strings.TrimSpace(protocol) == "" {
				continue
			}
			s, err := base64.StdEncoding.DecodeString(tstr.Substr(line, strings.LastIndex(line, "://")+3, -1))
			if err == nil {
				j, err := gjson.LoadContent(string(s))
				if err == nil {
					j.Set("protocol", protocol)
					j.Set("port", j.GetFloat64("port"))
					V2manJson.Append("nodelist."+remark, j)

				}
			}
		}
		if errl == io.EOF {
			break
		}
	}
	SaveV2manConfig()
}
func Readsubhttp(i int, remark string) bool {
	address := V2manJson.GetString("subs." + strconv.Itoa(i) + ".address")
	client := &http.Client{}
	req, _ := http.NewRequest("GET", address, nil) //TODO:读取订阅
	req.Header.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/507.13 (KHTML, like Gecko) Chrome/85.0.1364.120 Safari/507.13")
	res, err := client.Do(req)
	if err != nil {
		return false
	}
	defer res.Body.Close()
	body, _ := ioutil.ReadAll(res.Body)
	body, _ = base64.StdEncoding.DecodeString(string(body))

	V2manJson.Remove("nodelist." + remark)
	Savenodelist(string(body), remark)

	return true
}

//移除 节点
func Deletenode(sub, add string, port int64) {
	for i := range V2manJson.GetArray("nodelist." + sub) {
		d_add := V2manJson.GetString("nodelist." + sub + "." + strconv.Itoa(i) + ".add")
		d_port := V2manJson.GetInt64("nodelist." + sub + "." + strconv.Itoa(i) + ".port")
		if add == d_add && port == d_port {
			V2manJson.Remove("nodelist." + sub + "." + strconv.Itoa(i))
			if len(V2manJson.GetArray("nodelist."+sub)) == 0 {
				V2manJson.Remove("nodelist." + sub)
			}
			break
		}
	}

}

//克隆 节点
func CloneNode(sub, add string, port int64) {
	for i := range V2manJson.GetArray("nodelist." + sub) {
		d_add := V2manJson.GetString("nodelist." + sub + "." + strconv.Itoa(i) + ".add")
		d_port := V2manJson.GetInt64("nodelist." + sub + "." + strconv.Itoa(i) + ".port")
		if add == d_add && port == d_port {
			nodej := V2manJson.Get("nodelist." + sub + "." + strconv.Itoa(i))
			V2manJson.Append("nodelist."+"Clone"+strconv.Itoa(int(tnum.Randint(1111, 9999))), nodej)
			break
		}
	}
	DeferSaveConfg()
}

//添加到出站
func AddOut(sub, add, tag string, port int64) {
	for i := range V2manJson.GetArray("nodelist." + sub) {
		d_add := V2manJson.GetString("nodelist." + sub + "." + strconv.Itoa(i) + ".add")
		d_port := V2manJson.GetInt64("nodelist." + sub + "." + strconv.Itoa(i) + ".port")
		if add == d_add && port == d_port {
			nodej := V2manJson.Get("nodelist." + sub + "." + strconv.Itoa(i))
			V2json.Append("outbounds", SubnodeTov2node(nodej.(map[string]interface{}), tag))
			break
		}
	}
	savev2config()
}

func savev2config() {
	ioutil.WriteFile(DefaultV2Config, V2json.MustToJson(), 07555)
}

//设为活动出口节点
func SetActivity(sub, add string, port int64) {
	for i := range V2manJson.GetArray("nodelist." + sub) {
		d_add := V2manJson.GetString("nodelist." + sub + "." + strconv.Itoa(i) + ".add")
		d_port := V2manJson.GetInt64("nodelist." + sub + "." + strconv.Itoa(i) + ".port")
		if add == d_add && port == d_port {

			nodej := V2manJson.Get("nodelist." + sub + "." + strconv.Itoa(i))

			V2manJson.Set("ActivityNode", V2manJson.Get("nodelist."+sub+"."+strconv.Itoa(i)+".ps"))
			DeferSaveConfg()
			//如果 现活动出口 有 前置代理或为系统默认出口规则  则直接添加到 头部成员， 否则替换头部成员
			if len(V2json.GetArray("outbounds")) > 0 {

				protocol := V2json.GetString("outbounds.0.protocol")

				if V2json.Contains("outbounds.0.proxySettings") || protocol == "freedom" || protocol == "blackhole" {
					vnode := SubnodeTov2node(nodej.(map[string]interface{}), sub+strconv.Itoa(int(tnum.Randint(1111, 9999))))

					v0 := V2json.Get("outbounds.0") //移到尾部

					V2json.Set("outbounds.0", vnode)

					V2json.Append("outbounds", v0)

				} else {
					vnode := SubnodeTov2node(nodej.(map[string]interface{}), sub+strconv.Itoa(int(tnum.Randint(1111, 9999))))
					V2json.Set("outbounds.0", vnode)
				}
			} else {
				vnode := SubnodeTov2node(nodej.(map[string]interface{}), sub+strconv.Itoa(int(tnum.Randint(1111, 9999))))
				V2json.Set("outbounds.0", vnode)
			}
			DeferRestartV2()
			break
		}
	}
}

//订阅节点 生成 v2节点
func SubnodeTov2node(node map[string]interface{}, sub string) *gjson.Json {
	j := gjson.New("")

	j.Set("protocol", node["protocol"])
	j.Set("tag", sub)

	switch node["protocol"] {
	case "socks":
		j.Set("settings.servers.0.address", node["add"])
		j.Set("settings.servers.0.port", node["port"])
		j.Set("settings.servers.0.users.0.user", node["user"])
		j.Set("settings.servers.0.users.0.pass", node["pass"])
	case "vmess":
		j.Set("settings.vnext.0.address", node["add"])
		j.Set("settings.vnext.0.port", gconv.Int64(node["port"]))

		//aid, _ := strconv.ParseInt(node["aid"].(string), 10, 64)
		if node["aid"] != nil {
			j.Set("settings.vnext.0.users.0.alterId", gconv.Int64(node["aid"]))
		}
		j.Set("settings.vnext.0.users.0.email", "t@t.tt")
		j.Set("settings.vnext.0.users.0.id", node["id"])

		if node["security"] != nil { // 有指定加密方式
			j.Set("settings.vnext.0.users.0.security", node["security"])
		} else {
			j.Set("settings.vnext.0.users.0.security", "auto")
		}

		if node["net"] != "tcp" {

			j.Set("streamSettings.network", node["net"])

			var settingname string
			switch node["net"] {
			case "ws":
				settingname = "wsSettings"
			case "kcp":
				settingname = "kcpSettings"
			case "h2":
				settingname = "httpSettings"
			case "quic":
				settingname = "quicSettings"
			}

			if node["host"] != nil {
				j.Set("streamSettings."+settingname+".headers.Host", node["host"])
			}
			j.Set("streamSettings."+settingname+".path", node["path"])

			if node["tls"].(string) != "" {
				j.Set("streamSettings.security", node["tls"])
				/* 	 "tlsSettings": {// 跳过证书验证
				  "allowInsecure": true,
				  "serverName": "335e8d1495c5cc9e2b3979186593c720.v.smtcdns.net"
				}, */
				j.Set("streamSettings.tlsSettings.allowInsecure", true)
				j.Set("streamSettings.tlsSettings.serverName", node["host"])
			}
		}
	}
	return j
}

func Getauthmd5() string {
	hash := md5.New()

	md5a := fmt.Sprintf("%x", hash.Sum(append(V2manJson.GetBytes("user"), V2manJson.GetBytes("pass")...)))

	return md5a
}

func hasv2() bool {

	//pathrun, _ := tfile.GetCurrentDirectory()
	runname := ""
	if runtime.GOOS == "linux" {
		//runname = "v2ray"
		return true
	} else {
		runname = "v2ray.exe"
	}

	if !tfile.PathExists(runname) { //v2man 配置文件不存在
		return false
	} else {
		return true
	}

}

func init() {
	var err error

	if !tfile.PathExists(CorePath + "/plugs") {
		os.Mkdir(CorePath+"/plugs", 0777)
	}

	if !tfile.PathExists(CorePath + "/v2man.json") { //v2man 配置文件不存在
		V2manJson, _ = gjson.LoadContent(`{"v2config": "/etc/v2ray/config.json",
			"user": "root",
			"pass": "ab123456"}`)
		SaveV2manConfig()
	} else {
		V2manJson, err = gjson.Load("v2man.json")
		if err != nil {
			fmt.Println(err)
		}
	}
	DefaultV2Config = V2manJson.GetString("v2config")
	if runtime.GOOS != "linux" {
		DefaultV2Config = "config.json"
	}

	if !tfile.PathExists(DefaultV2Config) { //v2config 配置文件不存在
		fmt.Println(DefaultV2Config)
		fmt.Println("v2配置文件不存在")
		//os.Exit(0)
	} else {
		V2json, _ = gjson.Load(DefaultV2Config)

		needrestart := false
		if V2json.GetString("log.access") != "" {
			V2json.Set("log.access", "")
			needrestart = true
		}
		if V2json.GetString("log.error") != "" {
			V2json.Set("log.error", "")
			needrestart = true
		}

		if runtime.GOOS == "windows" { //需先 等待 core_windows.go 初始化完成 ，因此 要在线程 中执行

			go func() {
				time.Sleep(5 * time.Second)
				pid, _ := Getv2config()
				if pid == 0 {
					needrestart = true
				}
				if needrestart {
					RestartV2ray()
				}
			}()

		} else {
			pid, _ := Getv2config()
			if pid == 0 {
				needrestart = true
			}

			if needrestart {
				ioutil.WriteFile(DefaultV2Config, V2json.MustToJson(), 07555)
				go RestartV2ray()
			}
			fmt.Println(DefaultV2Config)
			fmt.Println(len(V2json.GetArray("inbounds")))

		}
	}
}

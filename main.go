package main

import (
	"log"
	"os"
	"v2man/api"
	"v2man/core"

	"github.com/gin-gonic/gin"
)

func main() { //TODO: 完成 api 认证 和 一键安装  运行 即 结束此项目
	//fmt.Println(GetCurrentDirectory())
	/* fmt.Println("v2man start")
	if runtime.GOOS == "linux" {
		fmt.Println(os.Args)

		Regsrv() //注册为系统服务
		//Run()
	} else {
		Run()
	} */
	//Regsrv()
	Run()
}
func Run() {
	buf, _ := os.OpenFile(core.GetCurrentDirectory()+"/log.txt", os.O_CREATE|os.O_RDWR|os.O_APPEND, 0766)
	core.Loginfo = log.New(buf, "logger: ", log.Lshortfile)

	go func() {
		r := gin.Default()

		{

			r.LoadHTMLGlob("view/*")
			r.Use(api.Apiauth())
			r.GET("/api/config", api.Apigetv2config)
			r.GET("/api/restartv2", api.ApirestartV2ray)
			r.POST("/api/changeconfig", api.Changeconfig)
			r.POST("/api/addsub", api.AddSub)
			r.POST("/api/removesub", api.RemoveSub)
			r.POST("/api/removenode", api.RemoveNode)
			r.POST("/api/clonenode", api.CloneNode)
			r.POST("/api/setactivity", api.SetActivity)
			r.POST("/api/batchnode", api.BatchNode)
			r.POST("/api/addout", api.AddOut)
			r.POST("/api/toggleproxy", api.ToggleProxy)
			r.POST("/api/selectout", api.SelectOut)
			r.POST("/api/CreateDomainRou", api.CreateDomainRou)
			r.POST("/api/CreateIpRou", api.CreateIpRou)
			r.POST("/api/Createinbound", api.Createinbound)

			r.POST("/api/readsub", api.ReadSub)
			r.GET("/api/getnodelist", api.GetNodeList)

			r.GET("/api/getlogs", api.GetLogs)

			r.Static("/layui", "./static/layui")

			r.POST("/login", api.Login)
			r.GET("/signout", api.Signout)
			r.GET("/admin", api.Admin)
			r.GET("/admin/nodelist", api.NodeList)
			//r.StaticFile("/admin", "./view/index.html")

		}
		r.Run(":18066")
	}()

	core.RestartV2ray()
	var ch chan int
	ch <- 1
}

package api

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"
	"v2man/core"
	"v2man/tool"

	"github.com/gin-gonic/gin"
	"github.com/gogf/gf/encoding/gjson"
	"github.com/gogf/gf/util/gconv"
)

func Apigetv2config(c *gin.Context) {
	pid, file := core.Getv2config()

	/* conf, err := os.OpenFile(file, os.O_RDWR, 0755)

	//conf, err := ioutil.ReadFile(file)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
			"message": "读v2配置文件失败",
		})
		return
	} */

	/* 	jdata := make(map[string]interface{})
	   	json.NewDecoder(conf).Decode(&jdata)
	   	if err != nil {
	   		c.JSON(http.StatusOK, gin.H{
	   			"succeed": 0,
	   			"message": "解析v2配置文件失败",
	   		})
	   		return
	   	} */

	c.JSON(http.StatusOK, gin.H{
		"succeed":   1,
		"pid":       pid,
		"confile":   file,
		"v2config":  core.V2json,
		"manconfig": core.V2manJson,
	})
}

func ApirestartV2ray(c *gin.Context) {
	go core.RestartV2ray()
	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})
}

//更新 v2 config 配置
func Changeconfig(c *gin.Context) {
	//postf := make(map[string]interface{})
	switch c.PostForm("type") {
	case "1": //更新 ins 属性值
		/*
			type: 1
			tag: proxy
			field: port
			value: 10811
		*/
		for i := range core.V2json.GetArray("inbounds") {
			tag := core.V2json.GetString("inbounds." + strconv.Itoa(i) + ".tag")
			if tag == c.PostForm("tag") {
				oldv := core.V2json.Get("inbounds." + strconv.Itoa(i) + "." + c.PostForm("field"))
				switch oldv.(type) {
				case string:
					core.V2json.Set("inbounds."+strconv.Itoa(i)+"."+c.PostForm("field"), c.PostForm("value"))
				case float64:
					f64, _ := strconv.ParseFloat(c.PostForm("value"), 64)
					core.V2json.Set("inbounds."+strconv.Itoa(i)+"."+c.PostForm("field"), f64)
				case bool:
					fb, _ := strconv.ParseBool(c.PostForm("value"))
					core.V2json.Set("inbounds."+strconv.Itoa(i)+"."+c.PostForm("field"), fb)
				}
				c.JSON(http.StatusOK, gin.H{
					"succeed": 1,
				})
				//延迟30S 保存 并重启v2ray
				core.DeferRestartV2()
				return
			}
		}
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
			"message": "未找到tag入口",
		})
	case "11": //更新指定tag ins 成员对象

		tagj, err := gjson.LoadContent(c.PostForm("value"))

		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"succeed": 0,
				"message": "源码格式错误",
			})
		} else {

			for i := range core.V2json.GetArray("inbounds") {
				tag := core.V2json.GetString("inbounds." + strconv.Itoa(i) + ".tag")
				if tag == c.PostForm("tag") {

					core.V2json.Set("inbounds."+strconv.Itoa(i), tagj)

					c.JSON(http.StatusOK, gin.H{
						"succeed": 1,
					})
					//延迟30S 保存 并重启v2ray
					core.DeferRestartV2()
					return
				}
			}
			c.JSON(http.StatusOK, gin.H{
				"succeed": 0,
				"message": "未找到tag入口",
			})
			fmt.Println(tagj.ToJsonString())
		}
	case "12": //删除ins 成员对象

		for i := range core.V2json.GetArray("inbounds") {
			tag := core.V2json.GetString("inbounds." + strconv.Itoa(i) + ".tag")
			if tag == c.PostForm("tag") {

				core.V2json.Remove("inbounds." + strconv.Itoa(i))

				c.JSON(http.StatusOK, gin.H{
					"succeed": 1,
				})
				//延迟30S 保存 并重启v2ray
				core.DeferRestartV2()
				return
			}
		}
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
			"message": "未找到tag入口",
		})
	case "13": //删除outs 成员对象

		for i := range core.V2json.GetArray("outbounds") {
			tag := core.V2json.GetString("outbounds." + strconv.Itoa(i) + ".tag")
			if tag == c.PostForm("tag") {

				core.V2json.Remove("outbounds." + strconv.Itoa(i))

				c.JSON(http.StatusOK, gin.H{
					"succeed": 1,
				})
				//延迟30S 保存 并重启v2ray
				core.DeferRestartV2()
				return
			}
		}

		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
			"message": "未找到tag入口",
		})
	case "14": //更新指定tag outs 成员对象
		tagj, err := gjson.LoadContent(c.PostForm("value"))

		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"succeed": 0,
				"message": "源码格式错误",
			})
		} else {

			for i := range core.V2json.GetArray("outbounds") {
				tag := core.V2json.GetString("outbounds." + strconv.Itoa(i) + ".tag")
				if tag == c.PostForm("tag") {

					core.V2json.Set("outbounds."+strconv.Itoa(i), tagj)

					c.JSON(http.StatusOK, gin.H{
						"succeed": 1,
					})
					//延迟30S 保存 并重启v2ray
					core.DeferRestartV2()
					return
				}
			}
			c.JSON(http.StatusOK, gin.H{
				"succeed": 0,
				"message": "未找到tag出口",
			})
		}
	case "15": //通过 id 更新routing.rules 成员 对象
		roulej, err := gjson.LoadContent(c.PostForm("value"))
		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"succeed": 0,
				"message": "源码格式错误",
			})
		} else {
			core.V2json.Set("routing.rules."+c.PostForm("id"), roulej)
			c.JSON(http.StatusOK, gin.H{
				"succeed": 1,
			})
			//延迟30S 保存 并重启v2ray
			core.DeferRestartV2()
			return
		}
	case "16": //通过 id 移除 routing.rules 成员 对象

		core.V2json.Remove("routing.rules." + c.PostForm("id"))
		c.JSON(http.StatusOK, gin.H{
			"succeed": 1,
		})
		//延迟30S 保存 并重启v2ray
		core.DeferRestartV2()
		return
	case "17": //修改 routing 源码
		routingj, err := gjson.LoadContent(c.PostForm("value"))
		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"succeed": 0,
				"message": "源码格式错误",
			})
			return
		}
		core.V2json.Set("routing", routingj)
		c.JSON(http.StatusOK, gin.H{
			"succeed": 1,
		})
		core.DeferRestartV2()
	case "18": //编辑v2ray config
		routingj, err := gjson.LoadContent(c.PostForm("value"))
		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"succeed": 0,
				"message": "源码格式错误",
			})
			return
		}
		core.V2json = routingj
		core.DeferRestartV2()
		c.JSON(http.StatusOK, gin.H{
			"succeed": 1,
		})
	case "19": //修改默认 出站
		id, _ := strconv.ParseInt(c.PostForm("id"), 10, 64)

		if id > 0 {

			temp := core.V2json.Get("outbounds.0")
			core.V2json.Set("outbounds.0", core.V2json.Get("outbounds."+c.PostForm("id")))
			core.V2json.Set("outbounds."+c.PostForm("id"), temp)
			c.JSON(http.StatusOK, gin.H{
				"succeed": 1,
			})
			core.DeferRestartV2()
			return
		} else {
			c.JSON(http.StatusOK, gin.H{
				"succeed": 0,
				"message": "源码格式错误",
			})
		}
	}
}

func Admin(c *gin.Context) {
	c.HTML(http.StatusOK, "index", gin.H{"pathindex": "1"})
}

func NodeList(c *gin.Context) {
	c.HTML(http.StatusOK, "nodelist", gin.H{"pathnodelist": "1"})
}

func AddSub(c *gin.Context) {

	if i := core.FindSub(c.PostForm("remark")); i >= 0 {
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
			"message": "添加失败,备注已存在",
		})
		return
	}

	core.V2manJson.Append("subs", map[string]string{
		"remark":  c.PostForm("remark"),
		"address": c.PostForm("address"),
	})

	//延迟5S 保存 并重启v2ray
	//core.DeferSaveConfg()

	core.Readsubhttp(len(core.V2manJson.GetArray("subs"))-1, c.PostForm("remark"))

	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})
}

func RemoveSub(c *gin.Context) {

	if i := core.FindSub(c.PostForm("remark")); i >= 0 {
		core.V2manJson.Remove("subs." + strconv.Itoa(i)) //移除订阅
		if core.V2manJson.Contains("nodelist") {         //移除订阅下的节点
			core.V2manJson.Remove("nodelist." + c.PostForm("remark"))
		}

		core.DeferSaveConfg()
		c.JSON(http.StatusOK, gin.H{
			"succeed": 1,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"succeed": 0,
	})
}

func RemoveNode(c *gin.Context) {
	//	sub: data.sub, add: data.add, port: data.port

	type nodea struct {
		Sub  string `json:"sub"`
		Add  string `json:"add"`
		Port int64  `json:"port"`
	}

	var nodes []nodea

	if err := c.ShouldBindJSON(&nodes); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
		})
		return
	}

	for _, nodea := range nodes {
		//port, _ := strconv.ParseInt(nodea.Port, 10, 64)
		core.Deletenode(nodea.Sub, nodea.Add, nodea.Port)
	}

	core.DeferSaveConfg()

	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})

}

//克隆节点
func CloneNode(c *gin.Context) {

	port, _ := strconv.ParseInt(c.PostForm("port"), 10, 64)
	core.CloneNode(c.PostForm("sub"), c.PostForm("add"), port)
	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})

}

//将节点添加到出站
func AddOut(c *gin.Context) {
	port, _ := strconv.ParseInt(c.PostForm("port"), 10, 64)
	core.AddOut(c.PostForm("sub"), c.PostForm("add"), c.PostForm("tag"), port)
	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})

}

func Login(c *gin.Context) {

	if c.PostForm("user") == core.V2manJson.GetString("user") && c.PostForm("pass") == core.V2manJson.GetString("pass") {

		c.SetCookie("ssid", core.Getauthmd5(), 3600*24*60, "/", "", false, true)
		c.JSON(http.StatusOK, gin.H{
			"succeed": 1,
			"message": "登录成功",
		})
	} else {
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
			"message": "登录失败",
		})
	}
}
func Signout(c *gin.Context) {
	c.SetCookie("ssid", "", 60, "/", "", false, true)
	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})
}

//切换前置代理
func ToggleProxy(c *gin.Context) {
	/*
		proxytag
		transportLayer
		tag
	*/

	proxytag := c.PostForm("proxytag")
	for i := range core.V2json.GetArray("outbounds") {
		tag := core.V2json.GetString("outbounds." + strconv.Itoa(i) + ".tag")

		if tag == c.PostForm("tag") {
			if proxytag == "" { //移除前置代理
				if core.V2json.Contains("outbounds." + strconv.Itoa(i) + ".proxySettings") {
					core.V2json.Remove("outbounds." + strconv.Itoa(i) + ".proxySettings")
				}
			} else {

				core.V2json.Set("outbounds."+strconv.Itoa(i)+".proxySettings.tag", proxytag)
				if c.PostForm("transportLayer") == "on" {
					core.V2json.Set("outbounds."+strconv.Itoa(i)+".proxySettings.transportLayer", true)
				} else {
					core.V2json.Set("outbounds."+strconv.Itoa(i)+".proxySettings.transportLayer", false)
				}

			}

			c.JSON(http.StatusOK, gin.H{
				"succeed": 1,
			})
			//延迟30S 保存 并重启v2ray
			core.DeferRestartV2()
			return
		}

	}

	c.JSON(http.StatusOK, gin.H{
		"succeed": 0,
		"message": "未找到tag出口",
	})

}

//切换指定路由出口
func SelectOut(c *gin.Context) {

	if c.PostForm("outtag") == "" {
		c.JSON(http.StatusOK, gin.H{
			"succeed": 1,
			"message": "出口tag不能为空",
		})
	} else {

		core.V2json.Set("routing.rules."+c.PostForm("id")+".outboundTag", c.PostForm("outtag"))
		c.JSON(http.StatusOK, gin.H{
			"succeed": 1,
		})
		core.DeferRestartV2()

	}

}

func CreateDomainRou(c *gin.Context) {

	//domainlist

	reader := bufio.NewReader(strings.NewReader(c.PostForm("domainlist")))

	rule := gjson.New(`{
		"domains": [],
		 "outboundTag": "direct",
        "type": "field"
	}`)

	for {
		line, errl := reader.ReadString('\n')
		if len(line) > 0 {
			rule.Append("domains", strings.TrimSpace(line))
		}
		if errl == io.EOF {
			break
		}
	}
	core.V2json.Append("routing.rules", rule)

	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})
	core.DeferRestartV2()
}

func CreateIpRou(c *gin.Context) {

	//domainlist

	reader := bufio.NewReader(strings.NewReader(c.PostForm("domainlist")))

	rule := gjson.New(`{
		"ip": [],
		 "outboundTag": "direct",
        "type": "field"
	}`)

	for {
		line, errl := reader.ReadString('\n')
		if len(line) > 0 {
			rule.Append("ip", strings.TrimSpace(line))
		}
		if errl == io.EOF {
			break
		}
	}
	core.V2json.Append("routing.rules", rule)

	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})
	core.DeferRestartV2()
}

//根据type 创建一个入站
func Createinbound(c *gin.Context) {
	var Type = gconv.Int(c.PostForm("type"))
	ip := c.PostForm("ip")
	if ip == "" {
		ip = "0.0.0.0"
	}
	port := gconv.Int(c.PostForm("port"))
	tag := c.PostForm("tag")

	if core.Findinbounds(tag, port) >= 0 {
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
			"message": "入站参数不符要求",
		})
		return
	}

	switch Type {
	case 0: //ws+vmess
		wsvm := gjson.New(`{
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {}
      }
    }`)
		uuid := tool.NewUUID()
		wsvm.Set("port", port)
		wsvm.Set("listen", ip)
		wsvm.Set("tag", tag)
		wsvm.Set("settings.clients.0.id", uuid.String())
		wsvm.Set("settings.clients.0.alterId", tool.Randint(1, 10))
		wsvm.Set("streamSettings.wsSettings.path", c.PostForm("wspath"))

		core.V2json.Append("inbounds", wsvm)
		c.JSON(http.StatusOK, gin.H{
			"succeed": 1,
		})
		core.DeferRestartV2()
	default:
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
		})
	}
}

//设为活动
func SetActivity(c *gin.Context) {
	port, _ := strconv.ParseInt(c.PostForm("port"), 10, 64)
	core.SetActivity(c.PostForm("sub"), c.PostForm("add"), port)
	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})
}

//批量导入
func BatchNode(c *gin.Context) {
	nodelist := c.PostForm("nodelist")
	//nodelists := strings.Split(nodelist, "\n")
	core.Savenodelist(nodelist, time.Now().Format("2006-01-02 15:04:05"))
	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})

}

func ReadSub(c *gin.Context) {
	var i int
	if i = core.FindSub(c.PostForm("remark")); i == -1 {
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
			"message": "订阅不存在",
		})
		return
	}
	f := core.Readsubhttp(i, c.PostForm("remark"))

	if !f {
		c.JSON(http.StatusOK, gin.H{
			"succeed": 0,
			"message": "读订阅异常",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
	})
}

func GetNodeList(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"succeed":  1,
		"nodelist": core.V2manJson.Get("nodelist"),
	})
}

func GetLogs(c *gin.Context) {
	id := gconv.Int(c.DefaultQuery("id", "0"))

	c.JSON(http.StatusOK, gin.H{
		"succeed": 1,
		"logs":    gjson.New(core.OutLine.Getlines(id)),
	})

}

func AddSubtest() {
	core.V2manJson = gjson.New("")

	core.V2manJson.Append("subs", map[string]string{
		"remark":  "aaa",
		"address": "dddddddddddddddddddd",
	})
	fmt.Println(core.V2manJson.GetString("."))
}

func Apiauth() gin.HandlerFunc {
	return func(c *gin.Context) {

		if tool.Substr(c.Request.URL.Path, 0, 4) == "/api" {

			sid, err := c.Cookie("ssid")
			if err != nil {
				c.JSON(http.StatusOK, gin.H{
					"succeed": 0,
					"message": "未登陆",
				})
				c.Abort()
			} else {
				//	hash := md5.New()

				//md5a := fmt.Sprintf("%x", hash.Sum([]byte(sid)))

				if sid != core.Getauthmd5() {
					c.JSON(http.StatusOK, gin.H{
						"succeed": 0,
						"message": "权限验证失败",
					})
					c.Abort()
				}
			}

		}
	}
}

var Other = {
    NetPenetrate: {
        start (name, subname) {
            $.postjson("/api/post", {
                type: name + "_start_" + subname,//启动或关闭客户端 由后端判断
            }, (res) => {
                console.log(res)
                if (res.succeed == 1) {
                    $("#lab_" + name + "_" + subname).html(res.message)
                }
            })
        },
    },
    plugsinfo: [],
    loadlabstatus () {//首次加载  各插件运行状态
        Other.plugsinfo.some((v) => {
            let labtitle = ""
            if (v.pid > 0) {
                labtitle = Other.getstatus(v.name, v.subname, 1)
            } else {
                labtitle = Other.getstatus(v.name, v.subname, 0)
            }
            $("#lab_" + v.name + "_" + v.subname).html(labtitle)
        })
    },
    getstatus (name, subname, status) {
        var sts = {
            "NetPenetrate_Client_0": "启动客户端",
            "NetPenetrate_Client_1": "停止客户端",
            "NetPenetrate_Server_0": "启动服务端",
            "NetPenetrate_Server_1": "停止服务端"
        }
        return sts[name + "_" + subname + "_" + status]
    },
    editjsonconfig (name, subname) {//加载 并 编辑插件配置
        $.get("/api/getconfig?type=plug&name=" + name + "&subname=" + subname, (data) => {
            if (data.succeed == 1) {

                var container = document.getElementById("editor");
                editor = new JSONEditor(container, {
                    change: function () {

                    }
                });

                editor.set(data.content);

                layer.open({
                    type: 1,
                    title: false, //不显示标题
                    content: $('#editjson'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
                    btn: ['保存', '取消'],
                    closeBtn: false,
                    area: ['900px', '600px'], //宽高
                    yes: function (index) {

                        layer.close(index);
                        layer.closeAll()

                        $.post("/api/changeconfig", { type: 21, name, subname, value: JSON.stringify(editor.get()) }, (data) => {
                            console.log(data)
                            if (data.succeed) {
                                layer.msg("更新配置成功,插件将重新启动")
                            }
                        })
                    },
                    end: function () {//销毁时的回调函数
                        $("#editjson").css({ "display": "none" })
                    }
                });

            } else {
                layer.msg(data.message, { icon: 5 });
            }
        })
    },
    showlogs (name, subname) {
        $.get("/api/getlogs?name=" + name + "&subname=" + (subname || ""), (data) => {
            if (data.succeed) {
                if (data.logs && data.logs.length) {
                    let logs = data.logs
                    $("#logs").empty()
                    for (let index = 0; index < logs.length; index++) {
                        const element = logs[index];
                        $("#logs").append("<div>" + element + "</div>")
                    }
                    var index = layer.open({
                        type: 1,
                        title: "日志", //不显示标题
                        content: $('#logs'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
                        closeBtn: 2,
                        skin: "layui-layer-lan",
                        area: ['700px', '500px'], //宽高
                        end: function () {//销毁时的回调函数
                            $("#logs").css({ "display": "none" })
                        }
                    });
                }
            }
        })
    }
}
//读取插件状态
$.get("/api/plugsinfo", (data) => {
    if (data.succeed == 1) {
        Other.plugsinfo = data.data
        Other.loadlabstatus()
    } else {
        layer.msg(data.message, { icon: 5 });
        renderlogin()
    }
})

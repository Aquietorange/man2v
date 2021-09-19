$.postjson = function (url, data, callback) {

    $.ajax({
        type: "POST",
        url: url,
        dataType: "json",
        data: JSON.stringify(data),
        contentType: "application/json",
        success: function (d) {
            callback(d)
        }
    })

}

layui.use(['element', 'layer', 'util', 'table', 'form', 'dropdown', 'laytpl'], function () {
    var element = layui.element
        , layer = layui.layer
        , util = layui.util
        , $ = layui.$;
    laytpl = layui.laytpl;

    //头部事件
    util.event('lay-header-event', {
        //左侧菜单事件
        menuLeft: function (othis) {
            layer.msg('展开左侧菜单的操作', { icon: 0 });
        }
        , menuRight: function () {
            layer.open({
                type: 1
                , content: '<div style="padding: 15px;">处理右侧面板的操作</div>'
                , area: ['260px', '100%']
                , offset: 'rt' //右上角
                , anim: 5
                , shadeClose: true
            });
        }
    });

});

var v2man = {}
var laytpl
var SelectProxytag = ""
var SelectOuttag = ""
var lastlogid = 0
$.get("/api/config", (data) => {
    if (data.succeed == 1) {
        v2man.v2config = data.v2config
        v2man.manconfig = data.manconfig
        v2man.pid = data.pid
        v2man.confile = data.confile
        if (location.pathname == "/admin") {
            renderins()
            renderouts()
            renderrouting()
            refreshv2html()
            refreshlogs()
        } else if (location.pathname == "/admin/nodelist") {
            handnodelist()
        }
    } else {
        layer.msg(data.message, { icon: 5 });
        renderlogin()
    }
})


function renderlogin() {
    var index = layer.open({
        type: 1,
        title: "需要登录",
        content: $('#login'),
        btn: ['登录', '取消'],
        closeBtn: false,
        area: ['500px', '300px'],
        yes: function (index, layero) {
            layer.close(index);


            let formdata = layui.form.val("login");

            $.post("/login", { ...formdata }, (data) => {
                console.log(data)
                if (data.succeed) {
                    location.reload()
                }
            })


        },
        end: function () {//销毁时的回调函数
            $("#login").css({ "display": "none" })
            //关闭时将选择插入的dom结构结构display设置为none
        }
    });
}
function signout() {

    $.get("/signout", (data) => {

        if (data.succeed) {
            location.reload()
        }
    })
}

function refreshv2html() {
    $("#v2config").html(v2man.confile)
    $("#v2pid").html(v2man.pid)
}

function refreshlogs() {
    getlogs()
    setInterval(getlogs, 2000)
}

function getlogs() {
    $.get("/api/getlogs?id=" + lastlogid, (data) => {
        if (data.succeed) {
            if (data.logs && data.logs.length) {
                lastlogid = data.logs[data.logs.length - 1].id
                renderlogs(data.logs)
            }
        }
    })
}

function renderlogs(logs) {

    for (let index = 0; index < logs.length; index++) {
        const element = logs[index];
        $("#logs").append("<div>" + element.content + "</div>")
    }
    $('#logs').scrollTop($('#logs')[0].scrollHeight);
}


//动态渲染 前置代理 切换 下拉项
function rendersoption(transportLayer) {
    laytpl.config({//自定义模板分割符 防止和后端冲突
        open: '{%',
        close: '%}'
    });
    if (transportLayer) {
        $(":checkbox[name='transportLayer']").prop("checked", true)
    } else {
        $(":checkbox[name='transportLayer']").prop("checked", false)
    }


    var getTpl = proxytag.innerHTML
        , view = document.getElementById('proxytagview');
    laytpl(getTpl).render(v2man.v2config.outbounds, function (html) {
        view.innerHTML = html;
        laytpl.config({//还原分割符
            open: '{{',
            close: '}}'
        });



        layui.form.render('', "toggleproxy")//刷新表单 项
    });
}

//动态渲染 路由 切换 出口 下拉项
function rendersOutOption(transportLayer) {
    laytpl.config({//自定义模板分割符 防止和后端冲突
        open: '{%',
        close: '%}'
    });

    var getTpl = outtag.innerHTML
        , view = document.getElementById('selectoutview');
    laytpl(getTpl).render(v2man.v2config.outbounds, function (html) {
        view.innerHTML = html;
        laytpl.config({//还原分割符
            open: '{{',
            close: '}}'
        });

        layui.form.render('', "selectout")//刷新表单 项
    });
}


function loadoutstable() {
    var table = layui.table;

    var outs = deepClone(v2man.v2config.outbounds)
    outs.some((v, i) => {
        v.id = i
    })

    tableOutss = table.render({
        elem: "#outbounds",
        data: outs,
        id: 'outbounds',
        cols: [[
            { field: 'id', width: 50, title: 'id' },
            {
                field: 'tag', width: 200, title: 'Tag', templet: (d) => {

                    if (d.id == 0) {
                        return '<span style="color: #c00;">[默认出站]' + d.tag + '</span>'
                    } else {
                        return d.tag
                    }
                }
            },
            {
                field: 'listen', title: '远程地址',
                templet: (d) => {
                    if (d.settings && d.settings.servers) {
                        return d.settings.servers[0].address
                    } else if (d.settings && d.settings.vnext) {
                        return d.settings.vnext[0].address
                    } else {
                        return ""
                    }
                }
            }, {
                field: 'port', width: 100, title: '端口',
                templet: (d) => {
                    if (d.settings && d.settings.servers) {
                        return d.settings.servers[0].port
                    } else if (d.settings && d.settings.vnext) {
                        return d.settings.vnext[0].port
                    } else {
                        return ""
                    }
                }
            }, { field: 'protocol', width: 120, title: '协议' },

            {
                field: 'proxySettings', title: '前置代理',
                templet: (d) => {

                    let outhtml = ``
                    if (d.proxySettings && d.proxySettings.tag) {//有启用前置代理
                        outhtml += `<span class="layui-badge-rim">tag : ${d.proxySettings.tag}</span>`
                        if (d.proxySettings.transportLayer) {
                            outhtml += `<span class="layui-badge-rim layui-bg-blue">支持传输层</span>`
                        }
                    }
                    return outhtml
                }

            }, { field: '操作', title: '操作', toolbar: '#editouts' }]],
    });

}

function renderouts() {//TODO: 先完成 订阅导入
    loadoutstable()
    var table = layui.table;

    //工具条事件
    table.on('tool(outbounds)', function (obj) { //注：tool 是工具条事件名，inbounds 是 table 原始容器的属性 lay-filter="对应的值"
        var data = obj.data; //获得当前行数据
        var layEvent = obj.event; //获得 lay-event 对应的值（也可以是表头的 event 参数对应的值）
        var tr = obj.tr; //获得当前行 tr 的 DOM 对象（如果有的话）

        console.log(obj)

        if (layEvent === 'del') { //删除
            layer.confirm('真的删除行么', function (index) {
                obj.del(); //删除对应行（tr）的DOM结构，并更新缓存
                layer.close(index);
                //向服务端发送删除指令
                $.post("/api/changeconfig", { type: 13, tag: data.tag }, (data) => {
                    console.log(data)
                    if (data.succeed) {

                    }
                })
            });
        } else if (layEvent == "setdef") {//设为默认

            var temp = v2man.v2config.outbounds[0]

            v2man.v2config.outbounds[0] = v2man.v2config.outbounds[data.id]

            v2man.v2config.outbounds[data.id] = temp

            $.post("/api/changeconfig", { type: 19, id: data.id }, (data) => {
                console.log(data)
                if (data.succeed) {
                    loadoutstable()
                }
            })
        } else if (layEvent === 'edit') { //编辑
            //do something
            //同步更新缓存对应的值
            //editor
            var container = document.getElementById("editor");
            editor = new JSONEditor(container, {
                change: function () {
                    // console.log(editor.get())
                }
            });
            var out_index
            v2man.v2config.outbounds.some((v, i) => {
                if (v.tag == obj.data.tag) {
                    editor.set(v);
                    out_index = i
                    return true
                }
            })

            var index = layer.open({
                type: 1,
                title: false, //不显示标题
                content: $('#edit'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
                btn: ['保存', '取消'],
                closeBtn: false,
                area: ['700px', '500px'], //宽高
                yes: function (index, layero) {
                    //do something
                    console.log("yes")
                    layer.close(index); //如果设定了yes回调，需进行手工关闭
                    layer.closeAll()
                    v2man.v2config.outbounds[out_index] = editor.get()
                    $.post("/api/changeconfig", { type: 14, tag: data.tag, value: JSON.stringify(editor.get()) }, (data) => {
                        console.log(data)
                        if (data.succeed) {
                            obj.update(v2man.v2config.outbounds[out_index]);
                            layer.msg('[出站Tag: ' + data.tag + '] 已更新' + value, {
                                time: 5000
                            });
                        }
                    })
                },
                end: function () {//销毁时的回调函数
                    $("#edit").css({ "display": "none" })
                    //关闭时将选择插入的dom结构结构display设置为none
                }
            });
        } else if (layEvent == "toggleproxy") {

            if (data.proxySettings) {//当前行 的前置代理
                SelectProxytag = data.proxySettings.tag
            } else {
                SelectProxytag = ""
            }

            rendersoption(data.proxySettings && data.proxySettings.transportLayer)


            var index = layer.open({
                type: 1,
                title: "选择前置代理Tag", //不显示标题
                content: $('#toggleproxy'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
                btn: ['保存', '取消'],
                closeBtn: false,
                area: ['500px', '300px'], //宽高
                yes: function (index, layero) {
                    //do something
                    console.log("yes")
                    layer.close(index); //如果设定了yes回调，需进行手工关闭
                    layer.closeAll()


                    let formdata = layui.form.val("toggleproxy");
                    $.post("/api/toggleproxy", { ...formdata, tag: data.tag }, (data) => {
                        console.log(data)
                        if (data.succeed) {
                            var out_index
                            v2man.v2config.outbounds.some((v, i) => {
                                if (v.tag == obj.data.tag) {
                                    if (formdata.proxytag == "") {
                                        delete v.proxySettings
                                        // v.proxySettings = {}
                                    } else {
                                        if (!v.proxySettings) {
                                            v.proxySettings = {}
                                        }
                                        v.proxySettings.tag = formdata.proxytag
                                        v.proxySettings.transportLayer = formdata.transportLayer ? true : false
                                    }
                                    out_index = i
                                    return true
                                }
                            })

                            obj.update(v2man.v2config.outbounds[out_index]);
                            console.log(v2man.v2config.outbounds[out_index])
                            loadoutstable()
                            layer.msg('前置代理，已更新为' + formdata.proxytag, {
                                time: 5000
                            });

                        }
                    })

                },
                end: function () {//销毁时的回调函数
                    $("#toggleproxy").css({ "display": "none" })
                    //关闭时将选择插入的dom结构结构display设置为none
                }
            });


        } else if (layEvent === 'LAYTABLE_TIPS') {
            layer.alert('Hi，头部工具栏扩展的右侧图标。');
        }
    });
}

function renderins() {
    var table = layui.table
        , util = layui.util;

    console.log(v2man)

    tableIns = table.render({
        elem: "#inbounds",
        data: deepClone(v2man.v2config.inbounds),
        id: 'inbounds',
        cols: [[{ field: 'tag', width: 200, title: 'Tag' }, { field: 'listen', width: 120, title: '监听地址', edit: "text" }, { field: 'port', minWidth: 80, title: '端口', edit: "text" }, { field: 'protocol', minWidth: 80, title: '协议', edit: "text" }, { field: '操作', minWidth: 80, title: '操作', toolbar: '#editins' }]],
    });

    //监听ins 单元格编辑
    table.on('edit(inbounds)', function (obj) {
        console.log(obj)
        var value = obj.value //得到修改后的值
            , data = obj.data //得到所在行所有键值
            , field = obj.field; //得到字段
        layer.msg('[Tag: ' + data.tag + '] 属性 ' + field + " 由:" + getv2configoriginal(1, data.tag, field) + ', 已修改为：' + value, {
            time: 5000
        });
        setv2configoriginal(1, data.tag, field, value)

        $.post("/api/changeconfig", { type: 1, tag: data.tag, field, value }, (data) => {

            console.log(data)

        })

    });

    //工具条事件
    table.on('tool(inbounds)', function (obj) { //注：tool 是工具条事件名，inbounds 是 table 原始容器的属性 lay-filter="对应的值"
        var data = obj.data; //获得当前行数据
        var layEvent = obj.event; //获得 lay-event 对应的值（也可以是表头的 event 参数对应的值）
        var tr = obj.tr; //获得当前行 tr 的 DOM 对象（如果有的话）

        console.log(obj)

        if (layEvent === 'del') { //删除
            layer.confirm('确定删除么', function (index) {
                obj.del(); //删除对应行（tr）的DOM结构，并更新缓存
                layer.close(index);
                //向服务端发送删除指令
                $.post("/api/changeconfig", { type: 12, tag: data.tag }, (data) => {
                    console.log(data)
                    if (data.succeed) {

                    }
                })
            });
        } else if (layEvent === 'edit') { //编辑
            //do something
            //同步更新缓存对应的值

            // editor
            var container = document.getElementById("editor");
            editor = new JSONEditor(container, {
                change: function () {
                    // console.log(editor.get())
                }
            });
            var in_index
            v2man.v2config.inbounds.some((v, i) => {
                if (v.tag == obj.data.tag) {
                    editor.set(v);
                    in_index = i
                    return true
                }
            })

            var index = layer.open({
                type: 1,
                title: false, //不显示标题
                content: $('#edit'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
                btn: ['保存', '取消'],
                closeBtn: false,
                area: ['700px', '500px'], //宽高
                yes: function (index, layero) {
                    //do something
                    console.log("yes")
                    layer.close(index); //如果设定了yes回调，需进行手工关闭
                    layer.closeAll()
                    v2man.v2config.inbounds[in_index] = editor.get()
                    $.post("/api/changeconfig", { type: 11, tag: data.tag, value: JSON.stringify(editor.get()) }, (data) => {
                        console.log(data)
                        if (data.succeed) {
                            obj.update(v2man.v2config.inbounds[in_index]);
                        }
                    })
                },
                btn2: function (index, layero) {
                    //按钮【按钮二】的回调
                    console.log("no")
                    //return false 开启该代码可禁止点击该按钮关闭
                },
                end: function () {//销毁时的回调函数
                    $("#edit").css({ "display": "none" })
                    //关闭时将选择插入的dom结构结构display设置为none
                }
            });
        } else if (layEvent === 'LAYTABLE_TIPS') {
            layer.alert('Hi，头部工具栏扩展的右侧图标。');
        }
    });



}

function loadRoutingTable() {
    var table = layui.table
        , util = layui.util;

    var rules = deepClone(v2man.v2config.routing.rules)
    rules.some((v, i) => {
        v.id = i
    })

    tableIns = table.render({
        elem: "#routing",
        data: rules,
        id: 'routing',
        cols: [[
            { colspan: 7, align: 'center', title: "匹配条件(为空项跳过，不为空项为并且关系)" },

            {
                field: 'outboundTag', width: 120, title: '指定出口Tag', rowspan: 2, templet: (d) => {
                    if (getoutprotocol(d.outboundTag) == "freedom") {
                        return "直连"
                    } else if (getoutprotocol(d.outboundTag) == "blackhole") {
                        return "黑洞"
                    } else {
                        return d.outboundTag
                    }
                }
            },

            { field: '操作', minWidth: 80, title: '操作', toolbar: '#editrouts', rowspan: 2 }

        ], [
            {
                field: 'id', width: 200, title: 'id',
                align: 'center',
            },
            {
                field: 'inboundTag', width: 200, title: '入站Tag',
                align: 'center',
                templet: (d) => {
                    if (d.inboundTag) {
                        return d.inboundTag.join(",")
                    } else {
                        return ""
                    }
                }
            },
            {
                field: 'domains', width: 120, title: '访问域名', templet: (d) => {
                    if (d.domains) {
                        return d.domains.length + "条"
                    } else {
                        return ""
                    }
                }
            },
            {
                field: 'ip', width: 120, title: '访问IP', templet: (d) => {
                    if (d.ip) {
                        return d.ip.length + "条"
                    } else {
                        return ""
                    }
                }
            },
            { field: 'port', width: 120, title: '访问端口', },
            {
                field: 'source', width: 120, title: '来源IP', templet: (d) => {
                    if (d.source) {
                        return d.source.length + "条"
                    } else {
                        return ""
                    }
                }
            },
            {
                field: 'user', width: 120, title: '用户', templet: (d) => {
                    if (d.user) {
                        return d.user.length + "个"
                    } else {
                        return ""
                    }
                }
            }]],
    });
}

function renderrouting() {
    loadRoutingTable()
    var table = layui.table

    //工具条事件
    table.on('tool(routing)', function (obj) { //注：tool 是工具条事件名，inbounds 是 table 原始容器的属性 lay-filter="对应的值"
        var data = obj.data; //获得当前行数据
        var layEvent = obj.event; //获得 lay-event 对应的值（也可以是表头的 event 参数对应的值）
        var tr = obj.tr; //获得当前行 tr 的 DOM 对象（如果有的话）

        console.log(obj)

        if (layEvent === 'del') { //删除
            layer.confirm('确定删除么', function (index) {
                obj.del(); //删除对应行（tr）的DOM结构，并更新缓存
                layer.close(index);
                //向服务端发送删除指令
                $.post("/api/changeconfig", { type: 16, id: data.id }, (data) => {
                    console.log(data)
                    if (data.succeed) {

                    }
                })
            });
        } else if (layEvent === 'edit') { //编辑
            //do something
            //同步更新缓存对应的值

            console.log(obj)

            // editor
            var container = document.getElementById("editor");
            editor = new JSONEditor(container, {
                change: function () {
                    // console.log(editor.get())
                }
            });

            editor.set(v2man.v2config.routing.rules[data.id]);

            var index = layer.open({
                type: 1,
                title: false, //不显示标题
                content: $('#edit'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
                btn: ['保存', '取消'],
                closeBtn: false,
                area: ['700px', '500px'], //宽高
                yes: function (index, layero) {
                    //do something
                    console.log("yes")
                    layer.close(index); //如果设定了yes回调，需进行手工关闭
                    layer.closeAll()
                    v2man.v2config.routing.rules[data.id] = editor.get()
                    $.post("/api/changeconfig", { type: 15, id: data.id, value: JSON.stringify(editor.get()) }, (data) => {
                        console.log(data)
                        if (data.succeed) {
                            obj.update(v2man.v2config.routing.rules[obj.data.id]);
                            //loadRoutingTable()
                        }
                    })
                },
                end: function () {//销毁时的回调函数
                    $("#edit").css({ "display": "none" })
                    //关闭时将选择插入的dom结构结构display设置为none
                }
            });
        } else if (layEvent == "selectout") {

            if (data.outboundTag) {//当前行 出口tag
                SelectOuttag = data.outboundTag
            } else {
                SelectOuttag = ""
            }

            rendersOutOption()

            var index = layer.open({
                type: 1,
                title: "选择出站Tag",
                content: $('#selectout'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
                btn: ['保存', '取消'],
                closeBtn: false,
                area: ['500px', '300px'], //宽高
                yes: function (index, layero) {
                    //do something
                    console.log("yes")
                    layer.close(index); //如果设定了yes回调，需进行手工关闭
                    layer.closeAll()

                    let formdata = layui.form.val("selectout");
                    $.post("/api/selectout", { ...formdata, id: data.id }, (data) => {
                        if (data.succeed) {
                            v2man.v2config.routing.rules[obj.data.id].outboundTag = formdata.outtag
                            obj.update(v2man.v2config.routing.rules[obj.data.id]);
                            // loadRoutingTable()
                            layer.msg('出口TAG，已更新为' + formdata.outtag, {
                                time: 5000
                            });
                        }
                    })
                },
                end: function () {//销毁时的回调函数
                    $("#selectout").css({ "display": "none" })
                    //关闭时将选择插入的dom结构结构display设置为none
                }
            });

        } else if (layEvent === 'LAYTABLE_TIPS') {
            layer.alert('Hi，头部工具栏扩展的右侧图标。');
        }
    });
}

function editroutings() {

    var container = document.getElementById("editor");
    editor = new JSONEditor(container, {
        change: function () {

        }
    });

    editor.set(v2man.v2config.routing);

    var index = layer.open({
        type: 1,
        title: false, //不显示标题
        content: $('#edit'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
        btn: ['保存', '取消'],
        closeBtn: false,
        area: ['700px', '500px'], //宽高
        yes: function (index, layero) {
            layer.close(index);
            layer.closeAll()
            v2man.v2config.routing = editor.get()
            $.post("/api/changeconfig", { type: 17, value: JSON.stringify(editor.get()) }, (data) => {
                console.log(data)
                if (data.succeed) {
                    loadRoutingTable()
                }
            })
        },
        end: function () {//销毁时的回调函数
            $("#edit").css({ "display": "none" })
            //关闭时将选择插入的dom结构结构display设置为none
        }
    });
}

function editv2config() {
    var container = document.getElementById("editor");
    editor = new JSONEditor(container, {
        change: function () {

        }
    });

    editor.set(v2man.v2config);

    var index = layer.open({
        type: 1,
        title: false, //不显示标题
        content: $('#edit'), //捕获的元素，注意：最好该指定的元素要存放在body最外层，否则可能被其它的相对元素所影响
        btn: ['保存', '取消'],
        closeBtn: false,
        area: ['900px', '600px'], //宽高
        yes: function (index, layero) {
            layer.close(index);
            layer.closeAll()
            v2man.v2config = editor.get()
            $.post("/api/changeconfig", { type: 18, value: JSON.stringify(editor.get()) }, (data) => {
                console.log(data)
                if (data.succeed) {
                    location.reload()//刷新
                }
            })
        },
        end: function () {//销毁时的回调函数
            $("#edit").css({ "display": "none" })
            //关闭时将选择插入的dom结构结构display设置为none
        }
    });
}

function CreateDomainRou(type) {
    var urlp = ""
    var con
    var tbid = ""
    var filedname = ""
    if (type == 0) {
        urlp = "/api/CreateDomainRou"
        con = $('#CreateDomainRou')
        tbid = "CreateDomainRou"
        filedname = "domains"
    } else if (type == 1) {
        urlp = "/api/CreateIpRou"
        con = $('#CreateIpRou')
        tbid = "CreateIpRou"
        filedname = "ip"
    }


    var index = layer.open({
        type: 1,
        title: "请输入", //不显示标题
        content: con,
        closeBtn: 0,
        btn: ['创建', '取消'],
        yes: function (index, layero) {
            var data = layui.form.val(tbid);     //表单取值
            layer.close(index);
            $.post(urlp, { ...data }, (datav) => {
                if (datav.succeed) {
                    layer.msg("创建成功");
                    let rule = {
                        "outboundTag": "direct",
                        "type": "field"
                    }
                    rule[filedname] = [...data.domainlist.split("\n")],
                        v2man.v2config.routing.rules.push(rule)
                    loadRoutingTable()
                    //refreshnodelist()
                }
            })
        },
        skin: "layui-layer-lan",
        area: ['700px', '500px'], //宽高
        end: function () {//销毁时的回调函数
            $("#CreateDomainRou").css({ "display": "none" })
            //关闭时将选择插入的dom结构结构display设置为none
        }
    });
}

//创建一个入站
function Createinbound(type) {
    let Title = ""
    console.log(type)
    switch (type) {
        case 0:
            Title = "创建WS+VMESS"
            break
        case 1:
            Title = "创建Socks5"
            break
        case 2:
            Title = "创建透明代理"
            break
        case 3:
            Title = "创建HTTP代理"
            break
    }
    var index = layer.open({
        type: 1,
        title: Title + ";请输入", //不显示标题
        content: $("#Createinbound"),
        closeBtn: 0,
        btn: ['创建', '取消'],
        yes: function (index, layero) {
            var data = layui.form.val("Createinbound");
            layer.close(index);
            $.post("/api/Createinbound", { ...data, type }, (datav) => {
                if (datav.succeed) {
                    layer.msg("创建成功");
                    location.reload()
                }
            })
        },
        skin: "layui-layer-lan",
        area: ['700px', '500px'], //宽高
        end: function () {//销毁时的回调函数
            $("#Createinbound").css({ "display": "none" })
            //关闭时将选择插入的dom结构结构display设置为none
        }
    });

}

function Createoutbound(type){
       let Title = ""
    console.log(type)
    switch (type) {
        case 0:
            Title = "导入出站从二维码内容"
            break
    }
    var index = layer.open({
        type: 1,
        title: Title + ";请输入", //不显示标题
        content: $("#Createoutbound"),
        closeBtn: 0,
        btn: ['创建', '取消'],
        yes: function (index, layero) {
            var data = layui.form.val("Createoutbound");
            layer.close(index);
            $.post("/api/Createoutbound", { ...data, type }, (datav) => {
                if (datav.succeed) {
                    layer.msg("创建成功");
                    location.reload()
                }
            })
        },
        skin: "layui-layer-lan",
        area: ['700px', '500px'], //宽高
        end: function () {//销毁时的回调函数
            $("#Createoutbound").css({ "display": "none" })
            //关闭时将选择插入的dom结构结构display设置为none
        }
    });

}

//出站tag取协议
function getoutprotocol(tag) {
    var proto = ""
    v2man.v2config.outbounds.some((v) => {
        if (v.tag == tag) {
            proto = v["protocol"]
            return true
        }
    })
    return proto
}

//取配置原始值
function getv2configoriginal(type, tag, field) {
    if (type == 1) {//inbounds
        var resv
        v2man.v2config.inbounds.some((v) => {
            if (v.tag == tag) {
                resv = v[field]
                return true
            }
        })
        return resv
    }
}
//改配置原始值
function setv2configoriginal(type, tag, field, value) {
    if (type == 1) {//inbounds
        v2man.v2config.inbounds.some((v) => {
            if (v.tag == tag) {
                v[field] = value
                return true
            }
        })
    }
}


// 判断arr是否为一个数组，返回一个bool值
function isArray(arr) {
    return Object.prototype.toString.call(arr) === '[object Array]';
}



// 深度克隆
function deepClone(obj) {
    if (typeof obj !== "object" && typeof obj !== 'function') {
        return obj;        //原始类型直接返回
    }
    var o = isArray(obj) ? [] : {};
    for (i in obj) {
        if (obj.hasOwnProperty(i)) {
            o[i] = typeof obj[i] === "object" ? deepClone(obj[i]) : obj[i];
        }
    }
    return o;
}

function Isequ(a, b) {
    return a == b
}
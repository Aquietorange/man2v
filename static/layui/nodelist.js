function showaddsub () {
    var index = layer.open({
        type: 1,
        title: "添加订阅", //不显示标题
        content: $('#addsub'),
        closeBtn: 2,
        skin: "layui-layer-lan",
        area: ['500px', '300px'], //宽高
        end: function () {//销毁时的回调函数
            $("#addsub").css({ "display": "none" })
            //关闭时将选择插入的dom结构结构display设置为none
        }
    });
}
function batchnode () {
    var index = layer.open({
        type: 1,
        title: "批量导入节点", //不显示标题
        content: $('#batchnode'),
        closeBtn: 0,
        btn: ['导入', '取消'],
        yes: function (index, layero) {
            var data = layui.form.val('batchnode');     //表单取值
            layer.close(index);
            $.post("/api/batchnode", { ...data }, (datav) => {
                if (datav.succeed) {
                    layer.msg("导入成功");
                    refreshnodelist()
                }
            })

        },
        skin: "layui-layer-lan",
        area: ['700px', '500px'], //宽高
        end: function () {//销毁时的回调函数
            $("#batchnode").css({ "display": "none" })
            //关闭时将选择插入的dom结构结构display设置为none
        }
    });
}

function handnodelist () {
    var form = layui.form;
    form.on('submit(addsub)', function (data) {
        layer.closeAll()
        $.post("/api/addsub", { ...data.field }, (datav) => {
            if (datav.succeed) {
                layer.msg("添加成功");
                if (!v2man.manconfig.subs) {
                    v2man.manconfig.subs = []
                }
                v2man.manconfig.subs.push({ ...data.field })
                loadsubtable()
                refreshnodelist()
            }
        })
        return false;
    });
    rendersub()
    rendernodelist()
}

function loadnodelisttable () {
    //ActivityNode

    let nodelist = []
    let id = 0
    for (const remark in v2man.manconfig.nodelist) {
        if (Object.hasOwnProperty.call(v2man.manconfig.nodelist, remark)) {
            const arr = v2man.manconfig.nodelist[remark];
            for (let index = 0; index < arr.length; index++) {
                const element = arr[index];
                element.sub = remark
                id++
                element.id = id
                nodelist.push(element)
            }
        }
    }


    var table = layui.table;
    tablenodes = table.render({
        elem: "#nodelist",
        data: nodelist,
        id: 'nodelist',
        limit: 500,
        toolbar: '#toolbarnodelist', //开启头部工具栏，并为其绑定左侧模板
        defaultToolbar: [],
        cols: [[
            { type: 'checkbox' },
            { field: 'id', title: 'id', width: 80 },
            { field: 'protocol', title: '类型', width: 80 },
            {
                field: 'ps', title: '别名', minWidth: 250, templet: (d) => {
                    if (d.ps == v2man.manconfig.ActivityNode) {//活动节点
                        return '<span style="color: #c00;">[使用中]' + d.ps + '</span>'
                    } else {
                        return d.ps
                    }
                }
            },
            { field: 'add', title: '地址', minWidth: 200 },
            { field: 'port', title: '端口', },
            { field: 'net', title: '传输协议', },
            { field: 'sub', title: '订阅', width: 100 },
            { field: 'down', title: '下载', },
            { field: 'up', title: '上传', },
            {
                field: '操作', title: '操作',
                toolbar: "#editnode",
                minWidth: 400
            }
        ]],
    });

}
function rendernodelist () {
    loadnodelisttable()
    var table = layui.table;
    var dropdown = layui.dropdown;

    table.on('tool(nodelist)', function (obj) {
        var that = this
        var data = obj.data; //获得当前行数据
        var layEvent = obj.event;

        if (layEvent === 'setactivity') {//设为活动
            $.post("/api/setactivity", { sub: data.sub, add: data.add, port: data.port }, (datav) => {
                console.log(datav)
                if (datav.succeed) {
                    v2man.manconfig.ActivityNode = data.ps
                    loadnodelisttable()
                    layer.msg("设置成功");
                }
            })

        } else if (layEvent == "addout") {

            layer.prompt({
                formType: 0,
                value: '',
                title: '请输入出站tag',
            }, function (value, index, elem) {
                layer.close(index);

                $.post("/api/addout", { sub: data.sub, add: data.add, port: data.port, tag: value }, (datav) => {
                    console.log(datav)
                    if (datav.succeed) {
                        layer.msg("添加成功");
                    }
                })
            });

        } else if (layEvent === 'more') {//更多
            dropdown.render({
                elem: that
                , show: true, //外部事件触发即显示
                data: [{
                    title: '克隆'
                    , id: 'clone'
                }, {
                    title: '移除'
                    , id: 'del'
                }]
                , click: function (datam, othis) {
                    let evt = datam.id
                    switch (evt) {
                        case "clone"://克隆
                            $.post("/api/clonenode", { sub: data.sub, add: data.add, port: data.port }, (data) => {
                                console.log(data)
                                if (data.succeed) {
                                    refreshnodelist()
                                }
                            })
                            break
                        case "del"://删除
                            layer.confirm('确定移除节点么', function (index) {
                                layer.close(index);
                                //向服务端发送删除指令

                                $.postjson("/api/removenode", [{ sub: data.sub, add: data.add, port: data.port }], (data) => {
                                    console.log(data)
                                    if (data.succeed) {
                                        obj.del();
                                    }
                                })
                            });
                            break
                    }
                }
            });
        }
    }
    )

    //头工具栏事件
    table.on('toolbar(nodelist)', function (obj) {
        var checkStatus = table.checkStatus(obj.config.id);
        switch (obj.event) {
            case 'removenode'://移除选中
                var data = checkStatus.data;
                console.log(obj)
                console.log(checkStatus)
                layer.confirm('确定移除选中的' + data.length + '个节点么', function (index) {
                    layer.close(index);
                    //向服务端发送删除指令
                    let arr = []
                    for (let index = 0; index < data.length; index++) {
                        arr.push({ sub: data[index].sub, add: data[index].add, port: data[index].port })
                    }
                    $.postjson("/api/removenode", arr, (data) => {
                        console.log(data)
                        if (data.succeed) {
                            refreshnodelist()
                        }
                    })
                });

                break;
            case 'batchnode'://批量导入
                batchnode()
                break;
            //自定义头工具栏右侧图标 - 提示
            case 'LAYTABLE_TIPS':
                layer.alert('这是工具栏右侧自定义的一个图标按钮');
                break;
        };
    });
}

function loadsubtable () {
    var table = layui.table;
    tableOutss = table.render({
        elem: "#subscription",
        data: deepClone(v2man.manconfig.subs),
        id: 'subscription',
        cols: [[
            { field: 'remark', width: 200, title: '备注' },
            { field: 'address', title: '地址', },
            {
                field: '操作', title: '操作',
                toolbar: "#toolsub"
            }
        ]],
    });

}
function rendersub () {
    loadsubtable()
    var table = layui.table;
    table.on('tool(subscription)', function (obj) {
        var data = obj.data; //获得当前行数据
        var layEvent = obj.event;

        if (layEvent === 'del') { //删除
            layer.confirm('确定移除订阅么', function (index) {
                layer.close(index);
                //向服务端发送删除指令
                $.post("/api/removesub", { remark: data.remark }, (data) => {
                    console.log(data)
                    if (data.succeed) {
                        obj.del(); //删除对应行（tr）的DOM结构，并更新缓存

                        for (let index = 0; index < v2man.manconfig.subs.length; index++) {
                            if (v2man.manconfig.subs.remark == data.remark) {
                                v2man.manconfig.subs.splice(index, 1)
                                break
                            }
                        }

                        refreshnodelist()
                    }
                })
            });
        } else if (layEvent === 'read') {//读取订阅
            $.post("/api/readsub", { remark: data.remark }, (data) => {
                console.log(data)
                if (data.succeed) {
                    refreshnodelist()
                }
            })
        }
    }
    )
}

//刷新节点列表
function refreshnodelist () {
    $.get("/api/getnodelist", (data) => {
        console.log(data)
        if (data.succeed) {
            v2man.manconfig.nodelist = data.nodelist
            loadnodelisttable()
        }
    })
}
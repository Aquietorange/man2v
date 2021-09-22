var Other = {
    NetPenetrate: {
        startclient () {
            $.postjson("/api/post", {
                type: "NetPenetrate_startclient",//启动或关闭客户端 由后端判断
            }, (res) => {
                console.log(res)
            })

        },
        startserve () {


        }

    }


}
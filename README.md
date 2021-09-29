# passwall节点订阅后自动将节点添加至自动切换列表
我不会lua所以随便写的，又不是不能用<br><br>
可以增加到计划任务(cron)服务<br><br>
00 10 * * * /usr/bin/lua /usr/share/passwall/auto_add_node.lua > /tmp/auto_add_node.log 2>&1

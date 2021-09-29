local appname = 'jlyy'

local log = function(...)
    local result = os.date("%Y-%m-%d %H:%M:%S: ") .. table.concat({ ... }, " ")
    local f, err = io.open("/var/log/" .. appname .. ".log", "a")
    if f and err == nil then
        f:write(result .. "\n")
        f:close()
    end
    print(result)
end

function run_shell(shell)
    log(shell)
    --local process = io.popen(string.format("ssh root@192.168.10.1 \"%s\"", shell))
    local process = io.popen(shell)
    return process:read("*all")
end

function split(str, reps)
    local result = {}
    string.gsub(str, '[^' .. reps .. ']+', function(w)
        table.insert(result, w)
    end)
    return result
end

function get_config(config_list, pattern)
    local result = {}
    for _, v in ipairs(config_list) do
        if string.find(v, pattern) then
            v = string.gsub(v, "passwall.", "")
            v = string.gsub(v, pattern, "")
            table.insert(result, v)
        end
    end
    return result
end
--自动订阅
log(run_shell("lua /usr/share/passwall/subscribe.lua start print"))
--获取全部配置数据
local config = run_shell("uci show passwall")
--转换配置为列表数据
local config_list = split(config, "\n")
--获取节点数据
local node_list = get_config(config_list, "=nodes")
--节点长度
local len = table.getn(node_list)
--打印节点长度
log(string.format('一共有%s条节点数据', len))
--清除当前节点信息
run_shell("uci delete passwall.@auto_switch[0].tcp_node1")
--设置节点配置
for i, v in ipairs(node_list) do
    if i == 1 then
        run_shell(string.format("uci set passwall.@auto_switch[0].tcp_main1=\'%s\'", v))
        run_shell(string.format("uci set passwall.@global[0].tcp_node1=\'%s\'", v))
        run_shell("uci set passwall.@global[0].udp_node1=\'tcp_\'")
        run_shell("uci set passwall.@global[0].enabled=\'1\'")
    else
        run_shell(string.format("uci add_list passwall.@auto_switch[0].tcp_node1=\'%s\'", v))
    end
end

if len == 0 then
    log('无任何节点,可能订阅地址挂壁了...')
    run_shell("uci set passwall.@global[0].enabled=\'0\'")
end

run_shell("uci commit passwall")
run_shell("/etc/init.d/passwall restart")

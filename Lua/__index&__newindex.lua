tab = {}
--__index用来在原表中定义表的取值操作
--__newindex用来在元表中定义表的赋值操作
metaTable = {__index = {a = "我是元表__index中a的值"},
                __newindex= {}}
setmetatable(tab, metaTable)

tab.b = "我被设置到了元表中的__newindex的b"
print("tab.b == nil:")
print((tab.b == nil))
print("tab.a:" .. tab.a)
print("getmetatable(tab).__newindex.b:" .. getmetatable(tab).__newindex.b)

--__index可以是一个方法，当是一个方法时取表中不存在的值时，会调用元表中__index方法传入的参数是 table, key
--__newindex可以是一个方法，当是一个方法时给表赋值时，会调用元表的__newindex方法传入的参数是table, key, value

tab2 = {}
metaTab2 = {__index = function(table, key)
    print(table)
    print(key)
end,
    __newindex = function(table, key, value)
        print(table)
        print(key)
        print(value)
    end
}

setmetatable(tab2, metaTab2)

local vl = tab2.a
tab2.a = "rise"
--__call当table的名字被当做是函数的名字被调用的时候会调用__call方法
tab = {}
metaTab = {__call = function(table, key, key2)
    print(table)
    print(key)
    print(key2)
end}

setmetatable(tab, metaTab)
tab("a","b")

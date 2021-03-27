function Closure()
    local i = {a = 1}
    return function()
        i.a = i.a + 1
        return i.a
    end
end

fun1 = Closure()
fun2 = Closure()
print(fun1())
print(fun2())

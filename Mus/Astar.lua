AStar = {}

--障碍
local BLOCK = 0
--可行走
local WALK = 1

--直线相邻的格子
local straightNbs = {
    {-1,0}, {0,1}, {1,0}, {0,-1}
}

--斜线相邻的格子
local diagonalNbsNbs = {
    {-1,-1}, {-1,1}, {1,1}, {1,-1}
}

local function AStarHeap()
    local Heap = {}
    Heap.list = {}
    Heap.size = 0
    Heap.data = {}

    function Heap.SetData(data)
        Heap.data = data
    end

    function Heap.Size()
        return Heap.size
    end

    function Heap.Top()
        return Heap.list[1]
    end

    --- @param index index是data中一个元素的一个下表
    function Heap.Add(index)
        Heap.size = Heap.size + 1
        --先放在最后一位
        Heap.list[Heap.size] = index

        local childIndex = Heap.size
        local parentIndex = math.floor(childIndex/2)
        local childDataIndex = Heap.list[childIndex]
        local parentDataIndex = Heap.list[parentIndex]

        while parentIndex > 0 and Heap.data[childDataIndex].F < Heap.data[parentDataIndex] do
            Heap.list[childIndex] = parentDataIndex
            Heap.data[parentDataIndex].open = childIndex
            Heap.list[parentIndex] = childDataIndex
            Heap.data[childDataIndex].open = parentIndex

            childIndex = parentIndex
            parentIndex = math.floor( childIndex/2 )
            childDataIndex = Heap.list[childIndex]
            parentDataIndex = Heap.list[parentIndex]
        end
    end

    ----- @param index 在list中的下标，可以通过.open获取
    function Heap.Update(index)
        local childIndex = index
        local parentIndex = math.floor( childIndex/2 )

        local childDataIndex = Heap.list[childIndex]
        local parentDataIndex = Heap.list[parentIndex]

        while parentIndex > 0 and Heap.data[childDataIndex].F < Heap.data[parentDataIndex] do
            Heap.list[childIndex] = parentDataIndex
            Heap.data[parentDataIndex].open = childIndex
            Heap.list[parentIndex] = childDataIndex
            Heap.data[childDataIndex].open = parentIndex

            childIndex = parentIndex
            parentIndex = math.floor( childIndex/2 )
            childDataIndex = Heap.list[childIndex]
            parentDataIndex = Heap.list[parentIndex]
        end
    end

    function Heap.Pop()
        if Heap.size <= 0 then
            return nil
        end

        local topValue = Heap.list[1]
        Heap.list[1] = Heap.list[Heap.size]
        Heap.data[Heap.list[1]].open = 1
        Heap.list[Heap.size] = nil
        Heap.size = Heap.size - 1

        if Heap.size > 0 then
            local parentIndex = 1
            local childIndexLeft = parentIndex * 2
            local childIndexRight = childIndexLeft + 1
            local minIndex
            local tmp

            while Heap.list[childIndexLeft] do
                minIndex = childIndexLeft
                if Heap.list[childIndexRight] 
                    and Heap.data[Heap.list[childIndexLeft]].F > Heap.data[Heap.list[childIndexRight]] then
                    minIndex = childIndexRight
                end
                if Heap.data[Heap.list[minIndex]].F < Heap.data[Heap.list[parentIndex]].F then
                    tmp = Heap.list[minIndex]
                    Heap.list[minIndex] = Heap.list[parentIndex]
                    Heap.data[Heap.list[minIndex]].open = minIndex
                    Heap.list[parentIndex] = tmp
                    Heap.data[tmp].open = parentIndex

                    parentIndex = minIndex
                    childIndexLeft = parentIndex * 2
                    childIndexRight = childIndexLeft + 1
                else
                    break
                end
            end
        end

        return topValue
    end

    return Heap
end

--- @param position_1, position_2 {x, y}
function AStar.H(position_1, position_2)
    local dx = position_1[1] - position_2[1]
    local dy = position_1[2] - position_2[2]
    return (math.abs(dy) + math.abs(dx)) * 10
end

--- @param position_1, position_2 {x, y}并且两点必定相邻
function AStar.G(posiiton_1, position_2)
    if posiiton_1[1] == position_2[1] or position_2[2] == position_2[2] then
        return 10
    end
    return 14
end

function AStar.IsRange(width, height, position)
    if (position[1] < 0 or position[2] >= width or position[2] < 0 or position[2] >= height) then
        return false
    end
    return true
end

function AStar.FindNbs(tiles, width, height, position)
    local nbs = {}
    local straight = {}

    for i = 1, 4 do
        local nb = {position[1] + straightNbs[i][1], position[2] + straightNbs[i][2]}
        if AStar.IsRange(width, height, nb) and tiles[nb[1]][nb[2]] == WALK then
            table.insert( nbs, nb)
            straight[i] = 1
        end
    end

    for i = 1, 4 do
        local nb = {position[1] + diagonalNbsNbs[i][1], position[2] + diagonalNbsNbs[i][2]}
        if AStar.IsRange(width, height, nb) and tiles[nb[1]][nb[2]] == WALK then
            if i == 1 and straight[1] and straight[4] then
                table.insert( nbs, nb)
            end
            if i == 2 and straight[1] and straight[2] then
                table.insert( nbs, nb)
            end
            if i == 3 and straight[2] and straight[3] then
                table.insert( nbs, nb)
            end
            if i == 4 and straight[3] and straight[4] then
                table.insert( nbs, nb)
            end
        end
    end

    return nbs
end

--- @param tiles 地图
--- @param startTile 起点
--- @param endTile 终点
function AStar.CanLineThrough( tiles, startTile, endTile)
    local xStart = startTile[1]
    local yStart = startTile[2]
    local xEnd = endTile[1]
    local yEnd = endTile[2]

    local dx = xEnd - xStart
    local dy = yEnd - yStart

    local xTurn = 1
    local xOffset = 0
    local yTurn = 1
    local yOffset = 0

    if dx < 0 then
        dx = -dx
        xTurn = -1
        xOffset = -1
        xStart = -xStart  + xOffset
        xEnd = - xEnd + xOffset
    end

    if dy < 0 then
        dy = -dy
        yTurn = -1
        yOffset = -1
        yStart = -yStart + yOffset
        yEnd = -yEnd + yOffset
    end

    if dx == dy then
        while xStart ~= xEnd do
            if tiles[xTurn * xStart + xOffset][yTurn * yStart + yOffset] == BLOCK
            or tiles[xTurn * (xStart + 1) + xOffset][yTurn * yStart + yOffset] == BLOCK
            or tiles[xTurn * xStart + xOffset][yTurn * (yStart + 1) + yOffset] == BLOCK then
                return false
            end
            xStart = xStart + 1
            yStart = yStart + 1
        end
        if tiles[xTurn * xStart + xOffset][yTurn * yStart + yOffset] == BLOCK then return false end
    end

    local e = dx + dy
    local dx2 = 2 * dx
    local dy2 = 2 * dy

    if dx > dy then
        if tiles[xTurn * xStart + xOffset][yTurn * yStart + yOffset] == BLOCK or tiles[xTurn * (xStart + 1) + xOffset][yTurn * yStart + yOffset] == BLOCK then
            return false
        end

        xStart = xStart + 1
        while xStart ~= xEnd do
            xStart = xStart + 1
            e = e + dy2
            if e < dx2 then
                if tiles[xTurn * xStart + xOffset][yTurn * yStart + yOffset] == BLOCK then return false end
            else
                yStart = yStart + 1
                if tiles[xTurn * xStart + xOffset][yTurn * yStart + yOffset] == BLOCK or tiles[xTurn * (xStart - 1) + xOffset][yTurn * yStart + yOffset] == BLOCK then
                    return false
                end
                if e == dx2 then
                    if tiles[xTurn * xStart + xOffset][yTurn * (yStart - 1) + yOffset] == BLOCK then return false end
                end
                e = e- dx2
            end
        end
    end

    if dx < dy then
        if tiles[xTurn * xStart + xOffset][yTurn * yStart + yOffset] == BLOCK or tiles[xTurn * xStart + xOffset][yTurn * (yStart + 1) + yOffset] == BLOCK then
            return false
        end

        yStart = yStart + 1
        while yStart ~= yEnd do
            yStart = yStart + 1
            e = e + dx2
            if e < dy2 then
                if tiles[xTurn * xStart + xOffset][yTurn * yStart + yOffset] == BLOCK then return false end
            else
                xStart = xStart + 1
                if tiles[xTurn * xStart + xOffset][yTurn * yStart + yOffset] == BLOCK or tiles[xTurn * xStart + xOffset][yTurn * (yStart - 1) + yOffset] == BLOCK then
                    return false
                end
                if e == dy2 then
                    if tiles[xTurn * (xStart - 1) + xOffset][yTurn * yStart + yOffset] == BLOCK then return false end
                end
                e = e- dy2
            end
        end
    end
    return true
end

function AStar.PathOptimization(tiles, path)
    if #path <= 2 then return path end
    for i = 1, #path do
        for j = #path, i+2, -1 do
            if AStar.CanLineThrough(tiles, path[i], path[j]) then
                for k = i + 1, j - 1 do
                    table.remove( path, i + 1)
                end
                break
            end
        end
        if i > #path - 2 then
            break
        end
    end
    return path
end

function AStar.FindPath(tiles, width, height, startTile, endTile)
    if not AStar.IsRange(width, height, startTile) or not AStar.IsRange(width, height, endTile) then
        return nil
    end
    if tiles[startTile[1]][startTile[2]] == BLOCK or tiles[endTile[1]][endTile[2]] == BLOCK then
        return nil
    end

    if AStar.CanLineThrough(tiles, startTile, endTile) then
        local path = {}
        table.insert( path, startTile)
        table.insert( path, endTile)
        return path
    end


    local cacheNodes = {}
    local openList = AStarHeap()
    openList.SetData(cacheNodes)

    local firstNode = {position = startTile, G = 0, H = 0, F = 0, open = 1}
    local curIndex = startTile[1] << 16 | startTile[2]
    cacheNodes[curIndex] = firstNode
    openList.Add(curIndex)

    while openList.Size() > 0 do
        local minIndex
        minIndex = openList.Pop()
        local minNode = cacheNodes[minIndex]
        minNode.open = 0
        local nbs = AStar.FindNbs(tiles, width, height, minNode.position)

        for k, v in nbs do
            if v[1] == endTile[1] and v[2] == endTile[2] then
                local path = {}
                local xOffset = 0
                local yOffset = 0
                local beforeNode = endTile
                local xOffsetTemp = 0
                local yOffsetTemp = 0
                while minNode ~= nil do
                    xOffsetTemp = minNode.position[1] - beforeNode[1]
                    yOffsetTemp = minNode.position[2] - beforeNode[2]
                    if xOffset == xOffsetTemp and yOffset == yOffsetTemp then
                        beforeNode = minNode.position
                    else
                        table.insert( path, 1, beforeNode)
                        xOffset = xOffsetTemp
                        yOffset = yOffsetTemp
                        beforeNode = minNode.position
                    end
                    minNode = minNode.parent
                end
                if beforeNode ~= path[#path] then
                    table.insert( path, 1, beforeNode)
                end
                return AStar.PathOptimization(tiles, path)
            end

            local key = v[1] << 16 | v[2]
            if cacheNodes[key] == nil then
                local GValue = minNode.G + AStar.G(minNode.position, v)
                local HValue = AStar.H(v, endTile)
                local node = {position = v, parent = minNode, G = GValue, H = HValue, F = GValue + HValue, open = 1}
                cacheNodes[key] = node
                openList.Add(key)
            else
                local node = cacheNodes[key]
                if node.open ~= 0 then
                    local nbG = minNode.G + AStar.G(minNode.position + v)
                    if node.G > nbG then
                        node.parent = minNode
                        node.G = nbG
                        node.F = node.G + node.F
                        openList.Update(node.open)
                    end
                end
            end
        end
    end
end


function AStar.InitTiles(bytes)
    local pos = 1
    local tiles = {}
    local widthTop
    local widthBottom
    widthTop, pos = string.unpack(">B", bytes, pos)
    widthBottom, pos = string.unpack(">B", bytes, pos)
    local width = widthTop << 8 | widthBottom

    local heightTop
    local heightBottom
    heightTop, pos = string.unpack(">B", bytes, pos)
    heightBottom, pos = string.unpack(">B", bytes, pos)
    local height = heightTop << 8 | heightBottom
    local type
    for x = 0, width - 1 do
        for y = 0, height - 1 do
            if tiles[x] == nil then
                tiles[x] = {}
            end
            type, pos = string.unpack(">B", bytes, pos)
            tiles[x][y] = type
        end
    end
    return tiles, width, height
end


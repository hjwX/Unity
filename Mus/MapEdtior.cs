priavte void Save()
{
    string filePath = Application.dataPath + "/Resources/TileMapData/mianCity.bytes";
    if (File.Exists(filePath))
        File.Delete(filePath)
    
    int width = tileMap.width;
    int height = tileMap.height;

    var fi = new FileInfo(filePath);
    FileStream fileStream = fi.OpenWrite();

    WriteInt16(fileStream, width);
    WriteInt16(fileStream, height);

    List<int> tiles = tileMap.tiles;
    tiles.Sort();
    for (int x = 0; x < width, x++)
    {
        for (int y = 0; y < height; y++)
        {
            if (tiles.BinarySearch(KeyFormat(x, y)) >= 0)
                fileStream.WriteByte((byte)TileType.BLOCK)
            else
                fileStream.WriteByte((byte)TileType.WALK)
        }
    }
    fileStream.Flush();
    fileStream.Close();
    Debug.log("Save finished!");
}

private int KeyFormat(int x, int y) 
{
    return x << 16 | y;
}

priavte void WriteInt16(FileStream fileStream, int value)
{
    fileStream.WriteByte((byte)(value>>8));
    fileStream.WriteByte((byte)value);
}
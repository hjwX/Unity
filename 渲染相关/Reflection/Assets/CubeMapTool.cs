using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class CubeMapTool :  EditorWindow
{

    private Cubemap cubeMap = null;

    [MenuItem("Tools/CubeMapGenerate")]
    public static void GenerateCubeMap()
    {
        GetWindow<CubeMapTool>();
    }

    private void OnGUI()
    {
        cubeMap = EditorGUILayout.ObjectField(cubeMap, typeof(Cubemap), false, GUILayout.Width(400)) as Cubemap;
        if(GUILayout.Button("Render to Cube Map"))
        {
            SceneView.lastActiveSceneView.camera.RenderToCubemap(cubeMap);
        }
    }
}

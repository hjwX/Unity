using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
 
public class Test : MonoBehaviour {
 
    public Text show;
    List<string> showLog = new List<string>();
    List<List<string>> splitToList = new List<List<string>>();
 
    void ShowLogInfo(string _log)
    {
        show.text = "";
        showLog.Clear();
        splitToList.Clear();
        //根据尖括号分开成文字和颜色
        string[] logChar = _log.Split(new char[] { '<', '>' });
        //结果为{"龙虾的","color=#FFFFFFFF","Text","/color",""}
        for (int i = 0; i < logChar.Length; i++)
        {
            List<string> logcharArr = new List<string>();
            for (int l = 0; l < logChar[i].Length; l++)
            {
                logcharArr.Add(logChar[i][l].ToString());
            }
            splitToList.Add(logcharArr);
        }
        //结果为{{龙,虾,的},{c,o,l,o,r,=,#,F,F,F,F,F,F,F,F},{T,e,x,t},{/,c,o,l,o,r},{}}
        for (int i = 0; i < logChar.Length; i++)
        {
            //当找到/color这个字段的时候,将上一个所有字符都加上颜色
            if (logChar[i].CompareTo("/color") == 0)
            {
                List<string> addColorString = new List<string>();
                List<string> addColotStingCache = new List<string>();
 
                //拿到需要加颜色的字符
                for (int k = 0; k < logChar[i - 1].Length; k++)
                {
                    addColorString.Add(logChar[i - 1][k].ToString());
                }
 
                //将字符加颜色
                for (int j = 0; j < addColorString.Count; j++)
                {
                    //logChar[i]是"/color"所以logChar[i-1]是需要加颜色的字符，logChar[i-2]是需要的颜色码
                    addColotStingCache.Add(string.Format("<{0}>{1}</color>", logChar[i - 2], addColorString[j]));
                }
 
                splitToList[i - 1] = addColotStingCache;
 
                //将颜色码的两个数据清除
                splitToList[i - 2].Clear();
                splitToList[i].Clear();
            }
 
        }
 
        //重写需要显示的数据
        for (int i = 0; i < splitToList.Count; i++)
        {
            for (int j = 0; j < splitToList[i].Count; j++)
            {
                showLog.Add(splitToList[i][j]);
            }
        }
        StartCoroutine(ShowLog());
 
 
 
    }
 
 
    IEnumerator ShowLog()
    {
        foreach (var item in showLog)
        {
            show.text += item;
            yield return new WaitForSeconds(0.1f);
        }
    }
}
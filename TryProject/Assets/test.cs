using UnityEngine;
using System.Collections;
using System;

public class test : MonoBehaviour
{
    //private string test1 = new string('123');
    private int test2 = 1;

    // Use this for initialization
    private IEnumerator Start()
    {
        yield return StartCoroutine("zz");
        Debug.Log(2);
    }

    private IEnumerator zz()
    {
        yield return new WaitForSeconds(2f);
        Debug.Log(1);
    }

    // Update is called once per frame
    private void Update()
    {
    }
}
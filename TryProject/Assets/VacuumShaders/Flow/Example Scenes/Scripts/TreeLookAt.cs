using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class TreeLookAt : MonoBehaviour 
{    
	// Update is called once per frame
	void Update () 
    {

        transform.LookAt(Camera.main.transform, Vector3.up);
	}
}

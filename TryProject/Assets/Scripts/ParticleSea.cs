using UnityEngine;
using System.Collections;
using System;

//Unity学习笔记（4）-----粒子效果的实现
//http://blog.csdn.net/Guo15331092/article/details/70805204

public class ParticleSea : MonoBehaviour
{
    public ParticleSystem particleSystem;
    private ParticleSystem.Particle[] particlesArray;
    private particleSettings[] psetting;
    public int seaResolution = 25;
    public static float MaxRadius = 120f;
    public static float MinRadius = 50f;
    public float radius = 100.0f;
    public Gradient colorGradient;

    private void Start()
    {
        particlesArray = new ParticleSystem.Particle[seaResolution * seaResolution];
        psetting = new particleSettings[seaResolution * seaResolution];
        particleSystem.maxParticles = seaResolution * seaResolution;
        particleSystem.Emit(seaResolution * seaResolution);
        particleSystem.GetParticles(particlesArray);
        setInitialPosition();
    }

    private void setInitialPosition()
    {
        for (int i = 0; i < seaResolution; i++)
        {
            for (int j = 0; j < seaResolution; j++)
            {
                psetting[i * seaResolution + j] = new particleSettings(radius);
                particlesArray[i * seaResolution + j].position = psetting[i * seaResolution + j].getPosition();
            }
        }
        particleSystem.SetParticles(particlesArray, particlesArray.Length);
    }

    private void Update()
    {
        RotateParticles();
        changeColor();
        particleSystem.SetParticles(particlesArray, particlesArray.Length);
    }

    private void changeColor()
    {
        for (int i = 0; i < seaResolution; i++)
        {
            for (int j = 0; j < seaResolution; j++)
            {
                float value = (Time.realtimeSinceStartup - Mathf.Floor(Time.realtimeSinceStartup));
                value += psetting[i * seaResolution + j].angle / 2 / Mathf.PI;
                while (value > 1)
                    value--;
                particlesArray[i * seaResolution + j].color = colorGradient.Evaluate(value);
                //particlesArray [i * seaResolution + j].color = colorGradient.Evaluate (Random.value);
            }
        }
    }

    private void RotateParticles()
    {
        for (int i = 0; i < seaResolution; i++)
        {
            for (int j = 0; j < seaResolution; j++)
            {
                psetting[i * seaResolution + j].rotate();
                particlesArray[i * seaResolution + j].position = psetting[i * seaResolution + j].getPosition();
            }
        }
    }
}

public class particleSettings
{
    public float angle { get; set; }
    public float radius { get; set; }
    public float speed { get; set; }

    public particleSettings(float r)
    {
        this.radius = r;
        this.angle = UnityEngine.Random.value * 2 * Mathf.PI;
        this.speed = UnityEngine.Random.value * Mathf.Sqrt(radius);
    }

    public Vector3 getPosition()
    {
        return radius * new Vector3(Mathf.Cos(angle), 0, Mathf.Sin(angle));
    }

    public void rotate()
    {
        this.angle += Time.deltaTime * speed / 10;
        if (this.angle > 2 * Mathf.PI)
            this.angle -= 2 * Mathf.PI;
        this.radius += UnityEngine.Random.value * 0.2f - 0.1f;
        if (this.radius > ParticleSea.MaxRadius)
            this.radius = ParticleSea.MaxRadius;
        if (this.radius < ParticleSea.MinRadius)
            this.radius = ParticleSea.MinRadius;
    }
}
Shader "VacuumShaders/Flow/Base_Diffuse/Flow_Reflective" {
	Properties {
		_BaseColor ("Base Color (A)", Color) = (1, 1, 1, 1)
		_MainTex ("Base Texture", 2D) = "" {}
		_SpecColor ("Flow Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	    _Shininess ("Flow Shininess", Range(0, 10)) = 6
		_FlowColor ("Flow Color (A)", Color) = (1, 1, 1, 1)
		_FlowTexture ("Flow Texture", 2D) = ""{}
		_FlowBump ("Flow Bump", 2D) = ""{}
		_FlowMap ("FlowMap (RG) Alpha (B) Gradient (A)", 2D) = ""{}
		_RevealSize("Flow Reveal Size", Range(-1, 1)) = 1
		_RevealPow("Reveal Pow", Range(1, 128)) = 1	
		_ReflColor("Reflection Color (A)", Color) = (1, 1, 1, 1)
		_Cube ("Reflection Cubemap", Cube) = "" { TexGen CubeReflect }
		_Strength ("Noise strength", Range(0, 1)) = 0				
		_Noise ("Flow Noise (R)", 2D) = ""{}	
		_Emission("Flow Emission", Range(0, 2)) = 0
		_DistorScale("Distortion Scale", float) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" "FlowTag"="Flow" }
		LOD 600
		
		CGPROGRAM
		#pragma surface surf BlinnPhong vertex:vert
		#pragma target 3.0 		

		fixed4 _BaseColor;
		sampler2D _MainTex;
		fixed4 _Color;
		half _Shininess;
		fixed4 _FlowColor;
		sampler2D _FlowTexture;
		sampler2D _FlowBump;
		sampler2D _FlowMap;
		fixed4 _ReflColor;
		samplerCUBE _Cube;
		half _Strength;
		sampler2D _Noise;
		half _Emission;
		half _PhaseLength;
		float4 _FlowMapOffset;
		
		fixed _DistorScale;

		half _RevealSize;	
		half _RevealPow;

		struct Input {
			float2 uv_MainTex;
			float2 uv_FlowTexture;
			float2 uv_FlowBump;
			float2 uv_FlowMap;
			float2 uv_Noise;
			float3 simpleWorldRefl;
			INTERNAL_DATA
		};

		void vert (inout appdata_full v, out Input o)
		{
			o = (Input)0;
		    o.simpleWorldRefl = -reflect( normalize(WorldSpaceViewDir(v.vertex)), normalize(mul((float3x3)_Object2World, SCALED_NORMAL)));
		}

		void surf (Input IN, inout SurfaceOutput o) 
		{
			
			half4 flowMap = tex2D (_FlowMap, IN.uv_FlowMap);
			flowMap.r = flowMap.r * 2.0f - 1.011765;
			flowMap.g = flowMap.g * 2.0f - 1.003922;

			//Gradient
		    half gradient = _RevealSize;
			gradient += flowMap.a;
			gradient = clamp(gradient, 0, 1);
			gradient = pow(gradient, _RevealPow);
			
			flowMap.b *= gradient; 
			////////////////////////////////////////
			
			float phase1 = _FlowMapOffset.x;
			float phase2 = _FlowMapOffset.y;

			float noise = tex2D (_Noise, IN.uv_Noise).r * _Strength;
			
			float2 uvNoise_1 = flowMap.rg * (phase1 + noise);
			float2 uvNoise_2 = flowMap.rg * (phase2 + noise);
			
			half4 t1D = tex2D (_FlowTexture, IN.uv_FlowTexture + uvNoise_1); 		 	
			half4 t2D = tex2D (_FlowTexture, IN.uv_FlowTexture + uvNoise_2); 	
			
			half4 t1B = tex2D (_FlowBump, IN.uv_FlowBump + uvNoise_1); 		 	
			half4 t2B = tex2D (_FlowBump, IN.uv_FlowBump + uvNoise_2); 	 

			half blend = abs(_PhaseLength - _FlowMapOffset.z) / _PhaseLength;
			blend = max(0, blend);
			half4 finalD = lerp( t1D, t2D, blend);				
			half4 finalB = lerp( t1B, t2B, blend);	
			
			half flowMapColor = flowMap.b * _FlowColor.a;

			float2 distUV = (saturate(finalB) * 2 - 1) * _DistorScale * flowMap.b;
			half4 mainColor = tex2D (_MainTex, IN.uv_MainTex + distUV);	

			mainColor.rgb *= _BaseColor * (1 - flowMapColor);
			finalD.rgb *= _FlowColor.rgb * flowMapColor;


			//o.Gloss = finalB.rgb * flowMap.b;   
			o.Gloss = flowMap.b;  
			o.Specular = _Shininess;

			fixed4 reflcol = texCUBE (_Cube, IN.simpleWorldRefl);
			reflcol.rgb *= _ReflColor.rgb;
			reflcol.rgb *= flowMap.b;

			o.Albedo = (mainColor.rgb + finalD.rgb) + (reflcol.rgb * _ReflColor.a);
			o.Emission = o.Albedo.rgb * _Emission * flowMap.b;


			o.Normal = UnpackNormal(finalB * flowMap.b + float4(0, 0.5, 0, 0.5) * (1 - flowMap.b));
			o.Alpha = mainColor.a * _BaseColor.a * flowMap.b;
		}
		ENDCG
	} 
	FallBack "Reflective/VertexLit"
}
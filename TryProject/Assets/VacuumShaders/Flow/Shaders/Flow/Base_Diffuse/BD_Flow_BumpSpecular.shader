Shader "VacuumShaders/Flow/Base_Diffuse/Flow_BumpSpecular" {
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
		_Strength ("Noise strength", Range(0, 1)) = 0			
		_Noise ("Flow Noise (R)", 2D) = ""{}	
		_Emission("Flow Emission", Range(0, 2)) = 0
		_DistorScale("Distortion Scale", float) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" "FlowTag"="Flow" }
		LOD 400
		
		CGPROGRAM
		#pragma surface surf BlinnPhong
		#pragma target 3.0

		fixed4 _BaseColor;
		sampler2D _MainTex;
		fixed4 _Color;
		half _Shininess;
		fixed4 _FlowColor;
		sampler2D _FlowTexture;
		sampler2D _FlowBump;
		sampler2D _FlowMap;
		half _Strength;
		sampler2D _Noise;
		half _Emission;
		half _PhaseLength;
		float4 _FlowMapOffset;
		
		float _DistorScale;

		half _RevealSize;	
		half _RevealPow;

		struct Input {
			float2 uv_MainTex;
			float2 uv_FlowTexture;
			float2 uv_FlowBump;
			float2 uv_FlowMap;
			float2 uv_Noise;
		};

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
			
			//o.Gloss = finalB.rgb * flowMap.b; 	
			o.Gloss = flowMap.b;
			half flowMapColor = flowMap.b * _FlowColor.a;

			float2 distUV = (saturate(finalB.rg) * 2 - 1) * _DistorScale * flowMap.b;
			half4 mainColor = tex2D (_MainTex, IN.uv_MainTex + distUV);	

			mainColor.rgb *= _BaseColor.rgb * (1 - flowMapColor);
			finalD.rgb *= _FlowColor.rgb * flowMapColor;

			o.Albedo = mainColor.rgb + finalD.rgb;
			o.Specular = _Shininess;

			o.Emission = o.Albedo.rgb * _Emission * flowMap.b;

			o.Normal = UnpackNormal(finalB * flowMap.b + float4(0, 0.5, 0, 0.5) * (1 - flowMap.b));
			o.Alpha = mainColor.a * _BaseColor.a * flowMap.b;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}







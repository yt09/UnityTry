Shader "VacuumShaders/Flow/Base_BumpSpecular/Flow_Specular" {
		Properties {
		_BaseColor ("Base Color", Color) = (1, 1, 1, 1)		
		_SpecColor ("Base Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	    _Shininess ("Base Shininess", Range (0.03, 2)) = 0.078125
		_BaseTex ("Base Texture", 2D) = "" {}
		_BaseBumpMap ("Base Normalmap", 2D) = "" {}		
		_FlowSpecularColor("Flow Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_FlowShininess ("Flow Shininess", Range (0.01, 2)) = 0.078125
		_FlowColor ("Flow Color (A)", Color) = (1, 1, 1, 1)
		_FlowTexture ("Flow Texture (RGB)", 2D) = ""{}
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
		#pragma surface surf Vacuum
		#pragma target 3.0

		struct VacuumSurfaceOutput
		 {
		    half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Specular;
			half3 GlossColor;
			half Alpha;
		};

		inline half4 LightingVacuum (VacuumSurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
		{
			  half3 h = normalize (lightDir + viewDir);
			  half diff = max (0, dot (s.Normal, lightDir));
			  float nh = max (0, dot (s.Normal, h));
			  float spec = pow (nh, s.Specular * 32);
			  half3 specCol = spec * s.GlossColor;

			  half4 c;
			  c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * specCol) * (atten * 2);
			  c.a = s.Alpha;
			  return c;
		}

		
		inline half4 LightingVacuum_PrePass (VacuumSurfaceOutput s, half4 light)
		{
			half3 spec = light.a * s.GlossColor;
			half4 c;			
			c.rgb = (s.Albedo * light.rgb + light.rgb * spec);
			c.a = s.Alpha + spec;
			
			return c;
		}

		fixed4 _BaseColor;
		half _Shininess;
		sampler2D _BaseTex;
		sampler2D _BaseBumpMap;
		half4 _FlowColor;
		fixed4 _FlowSpecularColor;
		half _FlowShininess;
		sampler2D _FlowTexture;
		sampler2D _FlowMap;
		half _Strength;
		sampler2D _Noise;
		half _Emission;
		half _PhaseLength;
		float4 _FlowMapOffset;

		fixed _DistorScale;

		half _RevealSize;	
		half _RevealPow;

		struct Input 
		{
			float2 uv_BaseTex;
			float2 uv_BaseBumpMap;
			float2 uv_FlowTexture;
			float2 uv_FlowMap;
			float2 uv_Noise;
		};

		void surf (Input IN, inout VacuumSurfaceOutput o)
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

			half4 t1 = tex2D (_FlowTexture, IN.uv_FlowTexture + flowMap.rg * (phase1 + noise)); 		 	
			half4 t2 = tex2D (_FlowTexture, IN.uv_FlowTexture + flowMap.rg * (phase2 + noise));
			
			half blend = abs(_PhaseLength - _FlowMapOffset.z) / _PhaseLength;
			blend = max(0, blend);
			half4 final = lerp( t1, t2, blend ); 
			
			
			half invertFlow = 1 - flowMap.b;							
			o.GlossColor = _SpecColor.rgb * invertFlow + _FlowSpecularColor.rgb * flowMap.b;

			half flowMapColor = flowMap.b * _FlowColor.a;

			float2 distUV = (saturate(final) * 2 - 1) * _DistorScale * flowMap.b;
			half4 mainColor = tex2D (_BaseTex, IN.uv_BaseTex + distUV);

			mainColor.rgb *= _BaseColor.rgb;
			final.rgb *= _FlowColor.rgb * flowMapColor;


			o.Albedo = mainColor.rgb + final.rgb;
			o.Emission = o.Albedo.rgb * _Emission * flowMap.b;

						
			o.Normal = UnpackNormal( tex2D(_BaseBumpMap, IN.uv_BaseBumpMap) * invertFlow + float4(0, 0.5, 0, 0.5) * flowMap.b ); 

			half baseSh = _Shininess * invertFlow;
			half flowSH = _FlowShininess * flowMap.b;
			o.Specular = baseSh + flowSH;
			o.Alpha = mainColor.a * _BaseColor.a * flowMap.b;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}




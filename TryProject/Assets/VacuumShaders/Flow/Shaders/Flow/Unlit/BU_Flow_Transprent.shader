Shader "VacuumShaders/Flow/Unlit/Flow_Transprent" {
	Properties {
		_BaseColor ("Base Color(RGB) Alpha(A)", Color) = (1, 1, 1, 1)
		_MainTex ("Base", 2D) = "" {}
		_FlowColor("Flow Color", Color) = (1, 1, 1, 1)
		_FlowTexture ("Flow Texture", 2D) = ""{}
		_FlowMap ("FlowMap (RG) Alpha (B) Gradient (A)", 2D) = ""{}
		_RevealSize("Flow Reveal Size", Range(-1, 1)) = 1
		_RevealPow("Reveal Pow", Range(1, 128)) = 1
		_Strength ("Noise strength", Range(0, 1)) = 0				
		_Noise ("Flow Noise (R)", 2D) = ""{}
		_DistorScale("Distortion Scale", float) = 0
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow"}
		LOD 100
	
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha 
		
		Pass {
			CGPROGRAM
				#pragma vertex vert 
				#pragma fragment frag
				#include "UnityCG.cginc"
			
				struct v2f {
					float4 pos : SV_POSITION;
					float2 uv[4] : TEXCOORD0;
					fixed4 color: COLOR;
				};
			
				float4 _MainTex_ST;
				float4 _FlowTexture_ST;
				float4 _FlowMap_ST;
				float4 _Noise_ST;
			
				v2f vert(appdata_full v) {
					v2f o;
					o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
					o.uv[0] = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.uv[1] = TRANSFORM_TEX(v.texcoord, _FlowTexture);
					o.uv[2] = TRANSFORM_TEX(v.texcoord, _FlowMap);
					o.uv[3] = TRANSFORM_TEX(v.texcoord, _Noise);
					
					o.color = v.color;
					
					return o;
				}
			
				fixed4 _BaseColor;
				sampler2D _MainTex;
				fixed4 _FlowColor;
				sampler2D _FlowTexture;
				sampler2D _FlowMap;
				half _Strength;
				sampler2D _Noise;
				half _PhaseLength;
				float4 _FlowMapOffset;

				fixed _DistorScale;

				half _RevealSize;	
				half _RevealPow;
			
				float4 frag(v2f IN) : COLOR 
				{

					half4 flowMap = tex2D (_FlowMap, IN.uv[2]);
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

					float noise = tex2D (_Noise, IN.uv[3]).r * _Strength;

					half4 t1 = tex2D (_FlowTexture, IN.uv[1] + flowMap.rg * (phase1 + noise)); 		 	
					half4 t2 = tex2D (_FlowTexture, IN.uv[1] + flowMap.rg * (phase2 + noise)); 		 	
	 	

					half blend = abs(_PhaseLength - _FlowMapOffset.z) / _PhaseLength;
					blend = max(0, blend);
					half4 final = lerp( t1, t2, blend);

					float2 distUV = (final.xy / (final.w * 2 - 1)) * _DistorScale * flowMap.b;
					half4 mainColor = tex2D (_MainTex, IN.uv[0] + distUV);	
			
					half4 retColor; 
					retColor.rgb = mainColor.rgb * _BaseColor.rgb + final.rgb * _FlowColor.rgb;
					retColor.a = flowMap.b * _BaseColor.a * IN.color.a;
					return retColor; 
				}
			ENDCG
		}
	}
}
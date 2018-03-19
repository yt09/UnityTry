// Upgrade NOTE: commented out 'float4 unity_LightmapST', a built-in variable
// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable

// - no Specular Color 
// - specular lighting directions are approximated per vertex
// - Normalmap uses Tiling/Offset of the Base texture
// - no Deferred Lighting support
// - supports no Light. Unlit


Shader "VacuumShaders/FlowMobile/Unlit/Mobile_Flow_Texture" {
Properties {
		_MainColor("Main Color", Color) = (1, 1, 1, 1)
		_MainTex ("Base", 2D) = "" {}
		_FlowColor("Flow Color", Color) = (1, 1, 1, 1)
		_FlowTexture ("Flow Texture", 2D) = ""{}
		_FlowMap ("FlowMap (RG) Alpha (B) Gradient (A)", 2D) = ""{}
		_RevealSize("Flow Reveal Size", Range(-1, 1)) = 1
		_DistorScale("Distortion Scale", float) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" "IgnoreProjector"="True"  "FlowTag"="Flow"}
		LOD 100

		 
		Pass {
			CGPROGRAM
			#include "UnityCG.cginc"

				#pragma vertex vert
				#pragma fragment frag exclude_path:prepass noforwardadd halfasview novertexlights
				#pragma fragmentoption ARB_precision_hint_fastest 
				
			
				struct v2f {
					float4 pos : SV_POSITION;
					half2 uv[3] : TEXCOORD0;	
				};
			
				float4 _MainTex_ST;
				float4 _FlowTexture_ST;
				float4 _FlowMap_ST;

				// float4 unity_LightmapST;
				// sampler2D unity_Lightmap;
			
				v2f vert(appdata_full v) {
					v2f o;
					o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
					o.uv[0] = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.uv[1] = TRANSFORM_TEX(v.texcoord, _FlowTexture);
					o.uv[2] = TRANSFORM_TEX(v.texcoord, _FlowMap);
					
					return o;
				}
			
				fixed4 _MainColor;
				sampler2D _MainTex;
				fixed4 _FlowColor;
				sampler2D _FlowTexture;
				sampler2D _FlowMap;
				half _PhaseLength;
				float4 _FlowMapOffset;


				fixed _DistorScale;

				half _RevealSize;	
			
				float4 frag(v2f IN) : COLOR 
				{
					half4 flowMap = tex2D (_FlowMap, IN.uv[2]);
					flowMap.r = flowMap.r * 2.0f - 1.011765;
					flowMap.g = flowMap.g * 2.0f - 1.003922;

					//Gradient
					half gradient = _RevealSize;
					gradient += flowMap.a;
					gradient = clamp(gradient, 0, 1);
			
					flowMap.b *= gradient; 
					////////////////////////////////////////
			
					half4 t1 = tex2D (_FlowTexture, IN.uv[1] + flowMap.rg * _FlowMapOffset.x); 		 	
					half4 t2 = tex2D (_FlowTexture, IN.uv[1] + flowMap.rg * _FlowMapOffset.y); 		 	
					
					half blend = abs(_PhaseLength - _FlowMapOffset.z) / _PhaseLength;
					blend = max(0, blend);
					half4 final = lerp( t1, t2, blend);

					float2 distUV = (final.xy / (final.w * 2 - 1)) * _DistorScale * flowMap.b;
					half4 mainColor = tex2D (_MainTex, IN.uv[0] + distUV);
						 
					half flowMapColor = flowMap.b * _FlowColor.a;
					mainColor.rgb *= _MainColor * (1 - flowMapColor);

					half4 retColor; 
					retColor.rgb = mainColor.rgb  + final.rgb * flowMap.b * _FlowColor.rgb * _FlowColor.a;
					retColor = clamp(retColor, 0, 1);
					retColor.a = mainColor.a * _MainColor.a * flowMap.b;
					
					return retColor; 
				}
			ENDCG
		}
	}
}
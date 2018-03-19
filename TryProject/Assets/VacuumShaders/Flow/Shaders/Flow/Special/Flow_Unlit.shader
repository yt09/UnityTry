Shader "VacuumShaders/Flow/Special/Flow_Unlit" {
Properties {
		_FlowColor("Flow Color", Color) = (1, 1, 1, 1)
		_FlowTexture ("Flow Texture (A)", 2D) = ""{}
		_FlowMap ("FlowMap (RG)", 2D) = ""{}
		_Strength ("Noise strength", Range(0, 1)) = 0				
		_Noise ("Flow Noise (R)", 2D) = ""{}
		_Emission("Flow Emission", Range(0, 2)) = 0	
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow"}
	    LOD 200
		
		ZWrite On
		Lighting Off
		Blend SrcAlpha OneMinusSrcAlpha 
		
		Pass {
			CGPROGRAM 
				#pragma vertex vert 
				#pragma fragment frag
				#include "UnityCG.cginc"
			
				struct v2f {
					float4 pos : SV_POSITION;
					float2 uv[3] : TEXCOORD0;
					fixed4 color: COLOR;
				};
			
				float4 _FlowTexture_ST;
				float4 _FlowMap_ST;
				float4 _Noise_ST;
			
				v2f vert(appdata_full v) {
					v2f o;
					o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
					o.uv[0] = TRANSFORM_TEX(v.texcoord, _FlowTexture);
					o.uv[1] = TRANSFORM_TEX(v.texcoord, _FlowMap);
					o.uv[2] = TRANSFORM_TEX(v.texcoord, _Noise);

					o.color = v.color;
					return o;
				}
			
				fixed4 _FlowColor;
				sampler2D _FlowTexture;
				sampler2D _FlowMap;
				half _Strength;
				sampler2D _Noise;
				half _Emission;
				half _PhaseLength;
				float4 _FlowMapOffset;

			
				float4 frag(v2f IN) : COLOR 
				{
					half4 flowMap = tex2D (_FlowMap, IN.uv[1]);
					flowMap.r = flowMap.r * 2.0f - 1.011765;
					flowMap.g = flowMap.g * 2.0f - 1.003922;			

					float noise = tex2D (_Noise, IN.uv[2]).r * _Strength;

					half4 t1 = tex2D (_FlowTexture, IN.uv[0] + flowMap.rg * (_FlowMapOffset.x + noise)); 
									
					half4 retColor; 
					retColor.rgb = t1.rgb * _FlowColor.rgb * _Emission;
					retColor.a = t1.a * _FlowColor.a * IN.color.a;
					return retColor; 
				}
			ENDCG
		}
	}
}
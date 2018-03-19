// - no Specular Color 
// - specular lighting directions are approximated per vertex
// - Normalmap uses Tiling/Offset of the Base texture
// - no Deferred Lighting support
// - supports ONLY 1 directional light. Other lights are completely ignored.

Shader "VacuumShaders/FlowMobile/Special/Mobile_Flow_Unlit" {
Properties {
		_FlowColor("Flow Color", Color) = (1, 1, 1, 1)
		_FlowTexture ("Flow Texture (A)", 2D) = ""{}
		_FlowMap ("FlowMap (RG)", 2D) = ""{}
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow"}
		LOD 100
	
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha 
		
		Pass {
			CGPROGRAM
				#pragma vertex vert exclude_path:prepass nolightmap noforwardadd halfasview novertexlights
				#pragma fragment frag
				#include "UnityCG.cginc"
			
				struct v2f {
					float4 pos : SV_POSITION;
					float2 uv[2] : TEXCOORD0;
					fixed4  color: COLOR;
				};
			
				float4 _FlowTexture_ST;
				float4 _FlowMap_ST;
			
				v2f vert(appdata_full v) {
					v2f o;
					o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
					o.uv[0] = TRANSFORM_TEX(v.texcoord, _FlowTexture);
					o.uv[1] = TRANSFORM_TEX(v.texcoord, _FlowMap);

					o.color = v.color;
					return o;
				}
			
				fixed4 _FlowColor;
				sampler2D _FlowTexture;
				sampler2D _FlowMap;
				half _PhaseLength;
				float4 _FlowMapOffset;

			
				float4 frag(v2f IN) : COLOR 
				{
					half4 flowMap = tex2D (_FlowMap, IN.uv[1]);
					flowMap.r = flowMap.r * 2.0f - 1.011765;
					flowMap.g = flowMap.g * 2.0f - 1.003922;	

					half4 t1 = tex2D (_FlowTexture, IN.uv[0] + flowMap.rg * _FlowMapOffset.x); 
									
					half4 retColor; 
					retColor.rgb = t1.rgb * _FlowColor.rgb;
					retColor.a = t1.a * _FlowColor.a * IN.color.a;
					return retColor; 
				}
			ENDCG
		}
	}
	Fallback "Mobile/VertexLit"
}
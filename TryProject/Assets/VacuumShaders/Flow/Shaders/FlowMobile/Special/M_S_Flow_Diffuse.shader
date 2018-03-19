// - no Specular Color 
// - specular lighting directions are approximated per vertex
// - Normalmap uses Tiling/Offset of the Base texture
// - no Deferred Lighting support
// - supports ONLY 1 directional light. Other lights are completely ignored.

Shader "VacuumShaders/FlowMobile/Special/Mobile_Flow_Diffuse" {
	Properties {
			_FlowColor ("Flow Color", Color) = (1, 1, 1, 1)
			_FlowTexture ("Flow Texture (A)", 2D) = ""{}
			_FlowMap ("FlowMap (RG)", 2D) = ""{}
		}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow"}
	    LOD 200
		
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#pragma surface surf Lambert noforwardadd novertexlights alpha

		fixed4 _FlowColor;
		sampler2D _FlowTexture;
		sampler2D _FlowMap;
		half _PhaseLength;
		float4 _FlowMapOffset;

		struct Input
		 {
			float2 uv_FlowTexture;
			float2 uv_FlowMap;
			float4 color: Color;
		};

		void surf (Input IN, inout SurfaceOutput o)
		 {
			
			half4 flowMap = tex2D (_FlowMap, IN.uv_FlowMap);
			flowMap.r = flowMap.r * 2.0f - 1.011765;
			flowMap.g = flowMap.g * 2.0f - 1.003922;
						

			half4 t1 = tex2D (_FlowTexture, IN.uv_FlowTexture + flowMap.rg * _FlowMapOffset.x); 		 	



			
			t1.rgb *= _FlowColor.rgb;

			o.Albedo = t1.rgb;

			o.Alpha = t1.a * _FlowColor.a * IN.color.a;
		}
		ENDCG
	} 
	Fallback "Mobile/VertexLit"
}

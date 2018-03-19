// - no Specular Color 
// - specular lighting directions are approximated per vertex
// - Normalmap uses Tiling/Offset of the Base texture
// - no Deferred Lighting support
// - supports ONLY 1 directional light. Other lights are completely ignored.

Shader "VacuumShaders/FlowMobile/Special/Mobile_Flow_Refractive_Fast" {
Properties {
			_FlowColor ("Flow Color", Color) = (1, 1, 1, 1)
			_FlowTexture ("Flow Texture (A)", 2D) = ""{}
			_FlowMap ("FlowMap (RG)", 2D) = ""{}
			_DistorScale("Distortion Scale", float) = 10
		}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow"}
	    LOD 200

		GrabPass { "_GrabTexture" }	
		
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#pragma surface surf Lambert vertex:vert noforwardadd novertexlights alpha

		fixed4 _FlowColor;
		sampler2D _FlowTexture;
		sampler2D _FlowMap;
		half _PhaseLength;
		float4 _FlowMapOffset;

		sampler2D _GrabTexture;
		float4 _GrabTexture_TexelSize;
		fixed _DistorScale;

		struct Input
		 {
			float2 uv_FlowTexture;
			float2 uv_FlowMap;
			float4 GrabUV;
			float4 color: Color;
		};

		void vert (inout appdata_full v, out Input o) 
		{
			o = (Input)0;

			half4 vertex = mul(UNITY_MATRIX_MVP, v.vertex);

			#if UNITY_UV_STARTS_AT_TOP
			float scale = -1.0;
			#else
			float scale = 1.0;
			#endif
			o.GrabUV.xy = (float2(vertex.x, vertex.y * scale) + vertex.w) * 0.5;
			o.GrabUV.zw = vertex.zw;
			

        }

		void surf (Input IN, inout SurfaceOutput o)
		 {
			
			half4 flowMap = tex2D (_FlowMap, IN.uv_FlowMap);
			flowMap.r = flowMap.r * 2.0f - 1.011765;
			flowMap.g = flowMap.g * 2.0f - 1.003922;
						

			half4 t1 = tex2D (_FlowTexture, IN.uv_FlowTexture + flowMap.rg * _FlowMapOffset.x); 		 	

			
			
			t1.rgb *= _FlowColor.rgb;

			float2 offset = t1.rg * _DistorScale * 16384 * _GrabTexture_TexelSize.xy;
			IN.GrabUV.xy = offset * IN.GrabUV.z + IN.GrabUV.xy;	
			half4 col = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(IN.GrabUV));

			o.Albedo = lerp(col, t1.rgb, _FlowColor.a);

			o.Alpha = t1.a * IN.color.a;
		}
		ENDCG
	} 
	Fallback "Mobile/VertexLit"
}
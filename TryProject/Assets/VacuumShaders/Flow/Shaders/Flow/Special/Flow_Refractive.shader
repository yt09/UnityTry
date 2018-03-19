Shader "VacuumShaders/Flow/Special/Flow_Refractive" {
Properties {
		_SpecColor ("Flow Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	     _Shininess ("Flow Shininess", Range(0, 10)) = 6
		_FlowColor ("Flow Color", Color) = (1, 1, 1, 1)
		_FlowTexture ("Flow Texture (A)", 2D) = ""{}
		_FlowBump ("Flow Bump", 2D) = ""{}
		_FlowMap ("FlowMap (RG)", 2D) = ""{}
		_Strength ("Noise strength", Range(0, 1)) = 0				
		_Noise ("Flow Noise (R)", 2D) = ""{}		
		_Emission("Flow Emission", Range(0, 2)) = 0
		_DistorScale("Distortion Scale", float) = 10
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow"}
		LOD 400

		GrabPass { "_GrabTexture" }	

		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#pragma surface surf BlinnPhong vertex:vert
		#pragma target 3.0

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
		
		sampler2D _GrabTexture;
		float4 _GrabTexture_TexelSize;
		fixed _DistorScale;	

		struct Input {
			float2 uv_FlowTexture;
			float2 uv_FlowBump;
			float2 uv_FlowMap;
			float2 uv_Noise;
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
			
			float noise = tex2D (_Noise, IN.uv_Noise).r * _Strength;

			float2 uvNoise_1 = flowMap.rg * (_FlowMapOffset.x + noise);
			
			half4 t1D = tex2D (_FlowTexture, IN.uv_FlowTexture + uvNoise_1);  	
			
			half4 t1B = tex2D (_FlowBump, IN.uv_FlowBump + uvNoise_1); 	 	

			//o.Gloss = t1D.rgb * t1D.a * _SpecColor.a; 				
			o.Gloss = 1;

			t1D.rgb *= _FlowColor.rgb;

			half3 bump = UnpackNormal(t1B); 

			float2 offset = bump.rg * _DistorScale * 16384 * _GrabTexture_TexelSize.xy;
			IN.GrabUV.xy = offset * IN.GrabUV.z + IN.GrabUV.xy;	
			half4 col = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(IN.GrabUV));

			o.Albedo = lerp(col, t1D.rgb, _FlowColor.a); 
			o.Specular = _Shininess;

			o.Emission = o.Albedo.rgb * _Emission;

			o.Normal = bump;

			o.Alpha = t1D.a * IN.color.a;
			
		}
		ENDCG
	} 
	Fallback "Transparent/VertexLit"
}

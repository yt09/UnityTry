Shader "VacuumShaders/Flow/Special/Flow_Reflective" {
Properties {
		_SpecColor ("Flow Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	     _Shininess ("Flow Shininess", Range(0, 10)) = 6
		_FlowColor ("Flow Color", Color) = (1, 1, 1, 1)
		_FlowTexture ("Flow Texture (A)", 2D) = ""{}
		_FlowBump ("Flow Bump", 2D) = ""{}
		_FlowMap ("FlowMap (RG)", 2D) = ""{}
		_ReflColor("Reflection Color (A)", Color) = (1, 1, 1, 1)
		_Cube ("Reflection Cubemap", Cube) = "" { TexGen CubeReflect }
		_Strength ("Noise strength", Range(0, 1)) = 0					
		_Noise ("Flow Noise (R)", 2D) = ""{}		
		_Emission("Flow Emission", Range(0, 2)) = 0
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow"}
		LOD 600

		ZWrite On
		//Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#pragma surface surf BlinnPhong alpha vertex:vert
		#pragma target 3.0 		

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
		

		struct Input {
			float2 uv_FlowTexture;
			float2 uv_FlowBump;
			float2 uv_FlowMap;
			float2 uv_Noise;
			float4 color: Color;
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
			
			float noise = tex2D (_Noise, IN.uv_Noise).r * _Strength;

			float2 uvNoise_1 = flowMap.rg * (_FlowMapOffset.x + noise);
			
			half4 t1D = tex2D (_FlowTexture, IN.uv_FlowTexture + uvNoise_1); 	
			
			half4 t1B = tex2D (_FlowBump, IN.uv_FlowBump + uvNoise_1); 		 	

			

			t1D.rgb *= _FlowColor.rgb;

			
			//o.Gloss = t1B.rgb;   
			o.Gloss = 1;
			o.Specular = _Shininess;

			fixed4 reflcol = texCUBE (_Cube, IN.simpleWorldRefl);
			reflcol.rgb *= _ReflColor.rgb;

			o.Albedo = t1D.rgb + (reflcol.rgb * _ReflColor.a);
			o.Emission = o.Albedo.rgb * _Emission;

			o.Normal = UnpackNormal(t1B);

			o.Alpha = t1D.a * _FlowColor.a * IN.color.a;
		}
		ENDCG
	} 
	FallBack "Reflective/VertexLit"
}

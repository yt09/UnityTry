Shader "VacuumShaders/Flow/Special/Flow_BumpSpecular" {
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
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow"}
		LOD 400

		ZWrite On
		//Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#pragma surface surf BlinnPhong alpha
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

		struct Input {
			float2 uv_FlowTexture;
			float2 uv_FlowBump;
			float2 uv_FlowMap;
			float2 uv_Noise;
			float4 color: Color;
		};

		void surf (Input IN, inout SurfaceOutput o) 
		{
			
			half4 flowMap = tex2D (_FlowMap, IN.uv_FlowMap);
			flowMap.r = flowMap.r * 2.0f - 1.011765;
			flowMap.g = flowMap.g * 2.0f - 1.003922;			
			
			float noise = tex2D (_Noise, IN.uv_Noise).r * _Strength;

			float2 uvNoise_1 = flowMap.rg * (_FlowMapOffset.x + noise);
			
			half4 t1D = tex2D (_FlowTexture, IN.uv_FlowTexture + uvNoise_1);  	
			
			half4 t1B = tex2D (_FlowBump, IN.uv_FlowBump + uvNoise_1); 	 	

			//o.Gloss = t1D.rgb * t1D.a; 				
			o.Gloss = 1;


			t1D.rgb *= _FlowColor.rgb;

			o.Albedo = t1D.rgb;
			o.Specular = _Shininess;

			o.Emission = o.Albedo.rgb * _Emission;

			o.Normal = UnpackNormal(t1B);

			o.Alpha = t1D.a * _FlowColor.a * IN.color.a;
			
		}
		ENDCG
	} 
	Fallback "Transparent/VertexLit"
}

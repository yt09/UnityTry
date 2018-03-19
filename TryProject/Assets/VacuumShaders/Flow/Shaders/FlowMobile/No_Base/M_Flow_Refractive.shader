// - no Specular Color 
// - specular lighting directions are approximated per vertex
// - Normalmap uses Tiling/Offset of the Base texture
// - no Deferred Lighting support
// - supports ONLY 1 directional light. Other lights are completely ignored.

Shader "VacuumShaders/FlowMobile/No_Base/Mobile_Flow_Refractive" {
Properties {	    
	    _Shininess ("Flow Shininess", Range (0.01, 1)) = 0.078125
		_FlowColor ("Flow Color (A)", Color) = (1, 1, 1, 1)		
		_FlowTexture ("Flow Texture(RGB) Specular (A)", 2D) = ""{}	
		_FlowBump ("Flow Bump", 2D) = ""{}	
		_FlowMap ("FlowMap (RG) Alpha (B) Gradient (A)", 2D) = ""{}
		_RevealSize("Flow Reveal Size", Range(-1, 1)) = 1
		_DistorScale("Distortion Scale", float) = 10
	} 
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow" }
		LOD 250

		GrabPass { "_GrabTexture" }	

		CGPROGRAM
		#pragma surface surf MobileBlinnPhong vertex:vert exclude_path:prepass noforwardadd halfasview novertexlights alpha
		#pragma exclude_renderers flash 		

		inline fixed4 LightingMobileBlinnPhong (SurfaceOutput s, fixed3 lightDir, fixed3 halfDir, fixed atten)
		{
			fixed diff = max (0, dot (s.Normal, lightDir));
			fixed nh = max (0, dot (s.Normal, halfDir));
			fixed spec = pow (nh, s.Specular*128) * s.Gloss;
	
			fixed4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * (atten*2);
			c.a = 0.0;
			return c;
		}
		
	
		half _Shininess;
		fixed4 _FlowColor;
		sampler2D _FlowTexture;
		sampler2D _FlowBump;
		sampler2D _FlowMap;
		half _PhaseLength;
		float4 _FlowMapOffset;

		sampler2D _GrabTexture;
		float4 _GrabTexture_TexelSize;
		fixed _DistorScale;

		half _RevealSize;	

	struct Input {
			float2 uv_MainTex;
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

			//Gradient
			half gradient = _RevealSize;
			gradient += flowMap.a;
			gradient = clamp(gradient, 0, 1);
			
			flowMap.b *= gradient; 
			////////////////////////////////////////

			float phase1 = _FlowMapOffset.x;
			float phase2 = _FlowMapOffset.y;

			float2 uvNoise_1 = flowMap.rg * (phase1);
			float2 uvNoise_2 = flowMap.rg * (phase2);
			
			half4 t1D = tex2D (_FlowTexture, IN.uv_FlowTexture + uvNoise_1); 		 	
			half4 t2D = tex2D (_FlowTexture, IN.uv_FlowTexture + uvNoise_2); 	
			
			half4 t1B = tex2D (_FlowBump, IN.uv_FlowTexture + uvNoise_1); 		 	
			half4 t2B = tex2D (_FlowBump, IN.uv_FlowTexture + uvNoise_2); 	 	

			half blend = abs(_PhaseLength - _FlowMapOffset.z) / _PhaseLength;
			blend = max(0, blend);
			half4 finalD = lerp( t1D, t2D, blend);				
			half4 finalB = lerp( t1B, t2B, blend);			
			 
			o.Gloss = finalD.rgb; 				 
			
			
						
			finalD.rgb *= _FlowColor.rgb;

			half3 bump = UnpackNormal(finalB * flowMap.b + float4(0, 0.5, 0, 0.5) * (1 - flowMap.b)); 

			float2 offset = bump.rg * _DistorScale * 16384 * _GrabTexture_TexelSize.xy;
			IN.GrabUV.xy = offset * IN.GrabUV.z + IN.GrabUV.xy;	
			half4 col = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(IN.GrabUV));

			o.Albedo = lerp(col, finalD.rgb, _FlowColor.a);
			o.Specular = _Shininess;

			
			o.Normal = bump;

			o.Alpha = flowMap.b * IN.color.a;
	}

ENDCG
}

Fallback "Mobile/VertexLit"
}


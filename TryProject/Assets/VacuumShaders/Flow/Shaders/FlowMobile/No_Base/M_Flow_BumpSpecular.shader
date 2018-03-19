// - no Specular Color 
// - specular lighting directions are approximated per vertex
// - Normalmap uses Tiling/Offset of the Base texture
// - no Deferred Lighting support
// - supports ONLY 1 directional light. Other lights are completely ignored.

Shader "VacuumShaders/FlowMobile/No_Base/Mobile_Flow_BumpSpecular" {
Properties {	    
	    _Shininess ("Flow Shininess", Range (0.01, 1)) = 0.078125
		_FlowColor ("Flow Color (A)", Color) = (1, 1, 1, 1)		
		_FlowTexture ("Flow Texture(RGB) Specular (A)", 2D) = ""{}	
		_FlowBump ("Flow Bump", 2D) = ""{}	
		_FlowMap ("FlowMap (RG) Alpha (B) Gradient (A)", 2D) = ""{}
		_RevealSize("Flow Reveal Size", Range(-1, 1)) = 1
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow" }
		LOD 250

		CGPROGRAM
		#pragma surface surf MobileBlinnPhong exclude_path:prepass noforwardadd halfasview novertexlights alpha

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

		half _RevealSize;	

	struct Input {
			float2 uv_MainTex;
			float2 uv_FlowTexture;
			float2 uv_FlowMap;
			float4 color: Color;
		};
 
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
			

			o.Albedo = finalD.rgb * _FlowColor.rgb;
			o.Specular = _Shininess;

			
			o.Normal = UnpackNormal(finalB * flowMap.b + float4(0, 0.5, 0, 0.5) * (1 - flowMap.b));

			o.Alpha = flowMap.b * _FlowColor.a * IN.color.a;
	}

ENDCG
}

Fallback "Mobile/VertexLit"
}

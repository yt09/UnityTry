Shader "VacuumShaders/Flow/No_Base/Flow_Specular" {
	Properties {		
		_SpecColor ("Flow Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	    _Shininess ("Flow Shininess", Range (0.01, 1)) = 0.078125
		_FlowColor ("Flow Color (A)", Color) = (1, 1, 1, 1)
		_FlowTexture ("Flow Texture", 2D) = ""{}
		_FlowMap ("FlowMap (RG) Alpha (B) Gradient (A)", 2D) = ""{}
		_RevealSize("Flow Reveal Size", Range(-1, 1)) = 1
		_RevealPow("Reveal Pow", Range(1, 128)) = 1
		_Strength ("Noise strength", Range(0, 1)) = 0				
		_Noise ("Flow Noise (R)", 2D) = ""{}
		_Emission("Flow Emission", Range(0, 2)) = 0	
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "FlowTag"="Flow"}
	    LOD 300

		ZWrite On 
		
		CGPROGRAM
		#pragma surface surf BlinnPhong alpha
		#pragma target 3.0

		
		half _Shininess;
		fixed4 _FlowColor;
		sampler2D _FlowTexture;
		sampler2D _FlowMap;
		half _Strength;
		sampler2D _Noise;
		half _Emission;
		half _PhaseLength;
		float4 _FlowMapOffset;

		half _RevealSize;	
		half _RevealPow;
		

		struct Input {
			float2 uv_FlowTexture;
			float2 uv_FlowMap;
			float2 uv_Noise;
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
			gradient = pow(gradient, _RevealPow);
			
			flowMap.b *= gradient; 
			////////////////////////////////////////
			
			float phase1 = _FlowMapOffset.x;
			float phase2 = _FlowMapOffset.y;

			float noise = tex2D (_Noise, IN.uv_Noise).r * _Strength;

			half4 t1 = tex2D (_FlowTexture, IN.uv_FlowTexture + flowMap.rg * (phase1 + noise)); 		 	
			half4 t2 = tex2D (_FlowTexture, IN.uv_FlowTexture + flowMap.rg * (phase2 + noise)); 	
			
			half blend = abs(_PhaseLength - _FlowMapOffset.z) / _PhaseLength;
			blend = max(0, blend);
			half4 final = lerp( t1, t2, blend);				
			
			//o.Gloss = final.rgb;  
			o.Gloss = 1;
			 

			final.rgb *= _FlowColor.rgb;

			o.Albedo = final.rgb;	
			o.Emission = o.Albedo.rgb * _Emission;		
			o.Specular = _Shininess;

			o.Alpha = flowMap.b * _FlowColor.a * IN.color.a;
		}

		ENDCG
	} 
	Fallback "Transparent/VertexLit"
}
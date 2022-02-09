float TextureScale < Default( 10 ); Range( 0, 1000.0 ); UiGroup( "Triplanar,90" ); >;
	float TextureBlendSoftness < Default( 1 ); Range( 0, 100.0 ); UiGroup( "Triplanar,90" ); >;

	Material TriplanarMaterial(PixelInput i,Texture2D color,Texture2D norm,Texture2D rma,float3 tintcolor,float scale,float softness){
			float2 yUV = i.worldspace.xz / scale;
			float2 xUV = i.worldspace.zy / scale;
			float2 zUV = i.worldspace.xy / scale;
			// Now do texture samples from our diffuse map with each of the 3 UV set's we've just made.
			float4 yDiff = Tex2DS(color,TextureFiltering, yUV);
			float4 xDiff = Tex2DS(color,TextureFiltering, xUV);
			float4 zDiff = Tex2DS(color,TextureFiltering, zUV);

			float4 yNorm = Tex2DS(norm,TextureFiltering, yUV);
			float4 xNorm = Tex2DS(norm,TextureFiltering, xUV);
			float4 zNorm = Tex2DS(norm,TextureFiltering, zUV);

			float4 yRma = Tex2DS(rma,TextureFiltering, yUV);
			float4 xRma = Tex2DS(rma,TextureFiltering, xUV);
			float4 zRma = Tex2DS(rma,TextureFiltering, zUV);
			// Get the absolute value of the world normal.
			// Put the blend weights to the power of BlendSharpness, the higher the value, 
            // the sharper the transition between the planar maps will be.
			float3 blendWeights = pow (abs(i.vNormalWs), softness);
			// Divide our blend mask by the sum of it's components, this will make x+y+z=1
			blendWeights = blendWeights / (blendWeights.x + blendWeights.y + blendWeights.z);
			// Finally, blend together all three samples based on the blend mask.
			float4 dif = xDiff * blendWeights.x + yDiff * blendWeights.y + zDiff * blendWeights.z;
			float4 norms = xNorm * blendWeights.x + yNorm * blendWeights.y + zNorm * blendWeights.z;
			float4 rough = xRma * blendWeights.x + yRma * blendWeights.y + zRma * blendWeights.z;
			return ToMaterial(dif,norms,rough,tintcolor);

	}

	//-----------------------------------------------------------------------------
	//
	// ToMaterial but for multiple material channels
	//
	//-----------------------------------------------------------------------------
	Material TriplanarToMaterialMultiblend(PixelInput i )
	{
	    #if S_MULTIBLEND >= 0
	        Material material = TriplanarMaterial(i,  
	                g_tColorA, 
	                g_tNormalA, 
	                g_tRmaA, 
	                g_flTintColorA,
					TextureScale,
					TextureBlendSoftness
	            );
	    #if S_MULTIBLEND >= 1
	        Material materialB = TriplanarMaterial(i, 
	            g_tColorB, 
	            g_tNormalB, 
	            g_tRmaB, 
	            g_flTintColorB,
					TextureScale,
					TextureBlendSoftness
	        );
	        material = MaterialParametersMultiblend( material, materialB, i.vBlendValues.r, g_flBlendSoftnessB );
	    #if S_MULTIBLEND >= 2
	        Material materialC = TriplanarMaterial(i, 
	            g_tColorC, 
	            g_tNormalC, 
	            g_tRmaC, 
	            g_flTintColorC,
					TextureScale,
					TextureBlendSoftness
	        );
	        material = MaterialParametersMultiblend( material, materialC, i.vBlendValues.g, g_flBlendSoftnessC );
	    #if S_MULTIBLEND >= 3
	        Material materialD = TriplanarMaterial(i, 
	            g_tColorD, 
	            g_tNormalD, 
	            g_tRmaD, 
	            g_flTintColorD,
					TextureScale,
					TextureBlendSoftness
	        );
	        material = MaterialParametersMultiblend( material, materialD, i.vBlendValues.b, g_flBlendSoftnessD );
	    #if S_MULTIBLEND >= 4
	        Material materialE = TriplanarMaterial(i, 
	            g_tColorE, 
	            g_tNormalE, 
	            g_tRmaE, 
	            g_flTintColorE,
					TextureScale,
					TextureBlendSoftness
	        );
	        material = MaterialParametersMultiblend( material, materialE, i.vBlendValues.a, g_flBlendSoftnessE );
	    #endif // 4
	    #endif // 3
	    #endif // 2
	    #endif // 1
	    #endif // 0

	    return material;
	}
	
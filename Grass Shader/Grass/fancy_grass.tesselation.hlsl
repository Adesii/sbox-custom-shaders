#if ( PROGRAM == VFX_PROGRAM_HS )



	
	int MaxTesselation< UiGroup("Blade,10/Tessellation"); UiType(Slider); Default(6); Range(1, 10); >;

	float TesselationFalloff< UiGroup("Blade,10/Tessellation"); UiType(Slider); Default(3000); Range(1, 8192); >;
	float MinTesselationFalloff< UiGroup("Blade,10/Tessellation"); UiType(Slider); Default(1); Range(1, 8192); >;


	PatchSize( 3 );
	HullPatchConstants TessellationFunc(InputPatch<HullInput, 3> patch)
	{
		HullPatchConstants o;

		float fTessMax = 1.0f;
		float3 p0 = mul( g_matProjectionToWorld, patch[0].vPositionPs ).xyz;
		float3 p1 = mul( g_matProjectionToWorld, patch[1].vPositionPs ).xyz;
		float3 p2 = mul( g_matProjectionToWorld, patch[2].vPositionPs ).xyz;

		float4 vTess = DistanceBasedTess( p0, p1,p2, MinTesselationFalloff, TesselationFalloff, MaxTesselation);
		
		o.Edge[0] = vTess.x;
		o.Edge[1] = vTess.y;
		o.Edge[2] = vTess.z;
		
		o.Inside = vTess.w;
		return o;
	}

	TessellationDomain( "tri" )
    TessellationOutputControlPoints( 3 )
    TessellationOutputTopology( "triangle_cw" )
    TessellationPartitioning( "fractional_odd" )
    TessellationPatchConstantFunc( "TessellationFunc" )
	HullOutput MainHs( InputPatch<HullInput, 3> patch, uint id : SV_OutputControlPointID )
	{
        return patch[id];
/* 

		HullInput i = patch[id];
		HullOutput o;
		o.vPositionPs = i.vPositionPs;

		#if ( S_DETAIL_TEXTURE )
			o.vDetailTextureCoords = i.vDetailTextureCoords;
		#endif

		o.vPositionWs = i.vPositionWs;
		o.vNormalWs = i.vNormalWs;
		o.vTextureCoords = i.vTextureCoords;
		#if ( D_BAKED_LIGHTING_FROM_LIGHTMAP )
			o.vLightmapUV = i.vLightmapUV;
		#endif

		#if ( PixelInput_HAS_PER_VERTEX_LIGHTING )
			o.vPerVertexLighting = i.vPerVertexLighting;
		#endif

		o.vVertexColor = i.vVertexColor;
		#if ( S_SPECULAR )
			o.vCentroidNormalWs = i.vCentroidNormalWs;
		#endif

		#ifdef PixelInput_HAS_TANGENT_BASIS
			o.vTangentUWs = i.vTangentUWs;
			o.vTangentVWs = i.vTangentVWs;
		#endif

		#if ( S_USE_PER_VERTEX_CURVATURE )
			o.flSSSCurvature = i.flSSSCurvature;
		#endif
		
		#if ( D_MULTIVIEW_INSTANCING > 0 )
			o.vClip0 = i.vClip0;
		#endif

		#if ( D_ENABLE_USER_CLIP_PLANE )
			o.vClip1 = i.vClip1;
		#endif
		return o; */
	}
#endif //( PROGRAM == VFX_PROGRAM_HS )



#if ( PROGRAM == VFX_PROGRAM_DS )
    TessellationDomain( "tri" )
    PixelInput MainDs(HullPatchConstants i, float3 barycentricCoordinates : SV_DomainLocation, const OutputPatch<PixelInput, 3> patch)
	{
		#define Baycentric3Interpolate(fieldName) o.fieldName = \
					patch[0].fieldName * barycentricCoordinates.x + \
					patch[1].fieldName * barycentricCoordinates.y + \
					patch[2].fieldName * barycentricCoordinates.z;

		PixelInput o;

        o.vPositionPs = float4(0,0,0,0);

		// Common Vertex Shader Attributes

	#if ( S_DETAIL_TEXTURE )
		Baycentric3Interpolate(vDetailTextureCoords);
	#endif

	#if ( PROGRAM == VFX_PROGRAM_PS )
		Baycentric3Interpolate(vPositionWithOffsetWs);
	#else
		Baycentric3Interpolate(vPositionWs);
	#endif
	#if ( S_WRINKLE )
		Baycentric3Interpolate(vNormalWs);
	#else
		Baycentric3Interpolate(vNormalWs);
	#endif

	//o.vNormalWs = patch[0].vNormalWs;

	#if ( S_UV2 )
		Baycentric3Interpolate(vTextureCoords);
	#else
		Baycentric3Interpolate(vTextureCoords);
	#endif

	#if ( D_BAKED_LIGHTING_FROM_LIGHTMAP )
		Baycentric3Interpolate(vLightmapUV);
	#endif

	#if ( PS_INPUT_HAS_PER_VERTEX_LIGHTING )
		Baycentric3Interpolate( vPerVertexLighting);
	#endif

	Baycentric3Interpolate(vVertexColor);

	#if ( S_SPECULAR )
		Baycentric3Interpolate(vCentroidNormalWs);
	#endif

	#ifdef PS_INPUT_HAS_TANGENT_BASIS
		Baycentric3Interpolate(vTangentUWs);
		Baycentric3Interpolate(vTangentVWs);
	#endif

	#if ( S_USE_PER_VERTEX_CURVATURE )
		Baycentric3Interpolate(flSSSCurvature);
	#endif

	//-------------------------------------------------------------------------------------------------------------------------------------------------------------
	// System interpolants
	//-------------------------------------------------------------------------------------------------------------------------------------------------------------

		Baycentric3Interpolate(vPositionPs);
		#if ( D_MULTIVIEW_INSTANCING == 1 )
			o.vClip0 = patch[0].vClip0;
		#elif ( D_MULTIVIEW_INSTANCING == 2 )
			o.vClip0 = patch[0].vClip0;
		#endif

		#if ( D_ENABLE_USER_CLIP_PLANE )
			o.vClip1 = patch[0].vClip1;
		#endif

		Baycentric3Interpolate(vBladeUV);
		Baycentric3Interpolate(vBlendValues);
		Baycentric3Interpolate(vPaintValues);
		Baycentric3Interpolate(vGrassValues);


		return o;
	}
#endif //( PROGRAM == VFX_PROGRAM_DS )

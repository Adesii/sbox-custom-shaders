#if ( PROGRAM == VFX_PROGRAM_HS )
	int sMaxTesselation< UiGroup("Blade,10/Tessellation"); UiType(Slider); Default(6); Range(1, 50); >;
	#ifdef DISTANCE_BASED_TESS
		float fTesselationFalloff< UiGroup("Blade,10/Tessellation"); UiType(Slider); Default(3000); Range(1, 8192); >;
	#endif

	PatchSize( 3 );
	HullPatchConstants TessellationFunc(InputPatch<HullInput, 3> patch)
	{
		HullPatchConstants o;

		float fTessMax = 1.0f;
		float4 vTess = DistanceBasedTess( patch[0].worldspace, patch[1].worldspace, patch[2].worldspace, 1.0, fTesselationFalloff, sMaxTesselation);
		
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


		Baycentric3Interpolate(worldspace);
		Baycentric3Interpolate(worldspacenormals);
		Baycentric3Interpolate(worldspacevTangentUWs);


		return o;
	}
#endif //( PROGRAM == VFX_PROGRAM_DS )

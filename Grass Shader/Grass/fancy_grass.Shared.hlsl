CreateTexture2D( g_tFlameTex )< Attribute( "GrassFlameMap" );SrgbRead( true );AddressU( CLAMP ); AddressV( CLAMP );>;
//float g_flFlameRadius < Attribute( "Radius" ); Default( 512.0f ); >;
//float2 g_vFlameViewPosition < Attribute( "ViewPosition" );  >;

//cbuffer FlameBuffer_t{
//    float2 g_vFlameViewPosition;
//    float g_flFlameRadius;
//};


//float2 SampleSplash( float2 vPos )
//{
//    float2 vTexCoordSplash = ( (vPos-g_vFlameViewPosition ) / g_flFlameRadius ) * 0.5f + 0.5f;
//    
//    // If PS sample a higher quality, bicubic one, else do a bilinear fetch
//    #if ( PROGRAM == VFX_PROGRAM_PS )
//        float2 vSplashColor = Tex2DLevel( g_tFlameTex, vTexCoordSplash, 0 ).rg;
//    #else
//        float2 vSplashColor = Tex2DLevel( g_tFlameTex, vTexCoordSplash, 0 ).rg;
//    #endif
//
//    return 1.0 - vSplashColor;
//}
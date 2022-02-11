#define PI 3.141592
#define PI_TWO 6.283185

float2 BladeWidth<UiType(Slider);UiGroup("Blade,10/Blades,10/1");Range2(0,0,100,100);Default2(2.5f,7.75f);>;
float2 BladeLenght<UiType(Slider);UiGroup("Blade,10/Blades,10/2");Range2(0,0,100,100);Default2(14,25);>;
float BladeBendDistance<UiType(Slider);UiGroup("Blade,10/Blades,10/3");Range(-40,40);Default(19);>;
float BladeBendCurve<UiType(Slider);UiGroup("Blade,10/Blades,10/4");Range(1,40);Default(2);>;

float BendDelta<UiType(Slider);UiGroup("Blade,10/Blades,10/5");Range(-1,1);Default(0.43);>;
float RandRotation<UiType(Slider);UiGroup("Blade,10/Blades,10/6");Range(0,1);Default(0.4);>;

float GrassPatchDist<UiType(Slider);UiGroup("Blade,10/Grass,10/2");Range(0,100);Default(20);>;

#include "common/proceedural.hlsl"
#include "Grass/noise3D.hlsl"
//#include "Grass/fancy_grass.SDFCollisions.hlsl"


CreateInputTexture2D(WindMap,Linear, 8,"NormalizeNormals","_normal","Blade,10/Wind,10/1", Default3( 0.5, 0.5, 1.0 ) );
CreateTexture2D( g_tWindMap ) < Channel( RGBA, Box( WindMap ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;

SamplerState TextureFilteringingstuff < Filter( ANISOTROPIC ); MaxAniso( 8 ); >;

float4 WindMapSTR<UiType(Slider);UiGroup("Blade,10/Wind,10/2");Default4(1,1,1,1);Range4(-1,-1,-1,-1,1,1,1,1);>;
float2 WindVelocity<UiType(Slider);UiGroup("Blade,10/Wind,10/3");Default2(1,0);Range2(-10,-10,10,10);>;
float WindFrequency<UiType(Slider);UiGroup("Blade,10/Wind,10/4");Range(0,1);Default(0.015);>;



float GrassCutoffDistance<UiGroup("Blade,10/Tessellation");UiType(Slider); Default(3000); Range(1, 8192);>;
float GrassCutoffDistanceFalloff<UiGroup("Blade,10/Tessellation");UiType(Slider); Default(0.5f); Range(0, 5);>;

// Following functions from Roystan's code:
// (https://github.com/IronWarrior/UnityGrassGeometryShader)
// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
// Extended discussion on this function can be found at the following link:
// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
// Returns a number in the 0...1 range.
float rand(float3 co)
{
	return (snoise(co)+1)/2;
	//return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}
// Construct a rotation matrix that rotates around the provided axis, sourced from:
// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
float3x3 angleAxis3x3(float angle, float3 axis)
{
	float c, s;
	sincos(angle, s, c);
	float t = 1 - c;
	float x = axis.x;
	float y = axis.y;
	float z = axis.z;
	return float3x3
	(
		t * x * x + c, t * x * y - s * z, t * x * z + s * y,
		t * x * y + s * z, t * y * y + c, t * y * z - s * x,
		t * x * z - s * y, t * y * z + s * x, t * z * z + c
	);
}





float3 projection(float3 vec, float3 norm){
	return vec - dot(vec,norm) * norm;
} 



PS_INPUT TransformGeomToClip(GeometryInput i,int index,float3 offset,float3x3 transmatrix,float2 uv){
	PS_INPUT o = (PS_INPUT)i;
	float3 transformedpos = float3(0,0,0);
	float4 vPositionWs = mul( g_matProjectionToWorld, i.vPositionPs );
	float3 pos = ((i.vPositionWs.xyz*vPositionWs.w)+g_vCameraPositionWs)/100;
	transformedpos.x += snoise(float3(pos.xy*((index+1)*10),pos.z*((index+1)*10)))*(GrassPatchDist);
	transformedpos.y += snoise(float3(pos.yx*((index+1)*10),100+pos.z*((index+1)*10)))*(GrassPatchDist);

	transformedpos = projection(transformedpos,i.vNormalWs);
	o.vPositionPs = Position4WsToPsMultiview( 0, float4( vPositionWs.xyz+transformedpos+mul(offset.xyz,transmatrix),vPositionWs.w ) );
	o.vBladeUV = uv;
	return o;
}

float GetDistanceFalloff(float3 pos,float3 vertpos,float mindist,float maxdist,float falloffExp){
	float dist = length(pos-vertpos);
	float falloff = 1;
	if(dist<mindist){
		falloff = 1;
	}else if(dist>maxdist){
		falloff = 0;
	}else{
		falloff = pow(1-((dist-mindist)/(maxdist-mindist)),falloffExp);
	}
	return falloff;
}


//get float from 2 float4 where the x is the biggest and return x2
float GetBiggestFloat(float4 v){
	return max(v.x,max(v.y,max(v.z,v.w)));
}

#include "texture_blending.fxc"
float getfalloff(float a, float b){
	float fBlendfactor = ComputeBlendWeight( b, 1, 0.5 );
    return lerp( 1, a, fBlendfactor); 
}



void GenerateGrass(triangle GeometryInput i[3],int index, inout TriangleStream< PS_INPUT > triStream){

    
	float4 vPositionWs = mul( g_matProjectionToWorld, i[index].vPositionPs );
	float3 pos = ((g_vCameraPositionWs)+i[index].vPositionWs.xyz)/100;
	float3 normal = normalize(i[index].vNormalWs.xyz);
    float3 tangent = normalize(i[index].vTangentUWs.xyz);

	float3 bitangent = cross(normal, tangent.xyz);
	float3x3 tangentToLocal = float3x3
	(
		tangent.x, bitangent.x, normal.x,
		tangent.y, bitangent.y, normal.y,
		tangent.z, bitangent.z, normal.z
	);

    //float3x3 tangentToLocal = g_matViewToProjection;


    float3x3 randRotMatrix = angleAxis3x3((rand((pos)*((index+1)*2))*PI_TWO)*RandRotation,float3(0,0,1.0f));

    float3x3 randBendMatrix = angleAxis3x3((rand((pos.yyx)*((index+1)*2))-0.5f)*BendDelta*PI,float3(-1.0f,0,0));

    float2 windUV = (pos.xy/100) * WindMapSTR.xy + WindMapSTR.zw  * WindFrequency * g_flTime;
	float2 windSample = ((Tex2DLevel(g_tWindMap,windUV, 0).xy * 2) - 1) * length(WindVelocity);

	float3 windAxis = normalize(float3(windSample.x, windSample.y, 0));
	float3x3 windMatrix = angleAxis3x3(PI * windSample.x, windAxis);
	//float3x3 windMatrix = angleAxis3x3(0, float3(1,0,0));

    float3x3 baseTransformationMatrix = mul(tangentToLocal,randRotMatrix);
	float3x3 tipTransformationMatrix = mul(tangentToLocal,mul(mul(windMatrix,randBendMatrix),randRotMatrix));

	float falloffamount = GetDistanceFalloff(pos,g_vCameraPositionWs/100,GrassCutoffDistance*0.005,GrassCutoffDistance*0.01,GrassCutoffDistanceFalloff);
	if(length(i[index].vBlendValues)> 0){
		#if S_MULTIBLEND >= 1
		falloffamount *=getfalloff(i[index].vGrassValues.r,i[index].vBlendValues.r);
		#if S_MULTIBLEND >= 2
		falloffamount *=getfalloff(i[index].vGrassValues.g,i[index].vBlendValues.g);
		#if S_MULTIBLEND >= 3
		falloffamount *=getfalloff(i[index].vGrassValues.b,i[index].vBlendValues.b);
		#if S_MULTIBLEND >= 4
		falloffamount *=getfalloff(i[index].vGrassValues.a,i[index].vBlendValues.a);
		#endif //1
		#endif //2
		#endif //3
		#endif //4
	}
	if(falloffamount<=0.01){
		return;
	}
	#if S_USE_BLADE_TEXTURE == 0
    float width  = lerp(BladeWidth.x, BladeWidth.y*10, rand(pos.xyz) * GrassFalloff)* falloffamount;
	float height = lerp(BladeLenght.x, BladeLenght.y*10, rand(pos.yzx) * GrassFalloff)* falloffamount;
	#else
	float width  = lerp(BladeWidth.x, BladeWidth.y*10, rand(pos.xyz) * GrassFalloff)* falloffamount;
	float height = width;
	#endif
	//float height =  TraceSDF(i[index])*10;
	float forward = rand(pos.zzy) * BladeBendDistance;


    for (int k = 0; k < BLADE_SEGMENTS; ++k)
	{
		float t = k / (float)BLADE_SEGMENTS;
		#if S_USE_BLADE_TEXTURE == 1
			float3 offset = float3(width, pow(t, BladeBendCurve) * forward, height * t ) ;
		#else
			float3 offset = float3(width * (1 - t), pow(t, BladeBendCurve) * forward, height * t ) ;
		#endif

		float3x3 transformationMatrix = (k == 0) ? baseTransformationMatrix : tipTransformationMatrix;
        GSAppendVertex(triStream,TransformGeomToClip(i[index],index,float3(offset.x, offset.y, offset.z),transformationMatrix ,float2(0,1-t)));
	    GSAppendVertex(triStream,TransformGeomToClip(i[index],index,float3(-offset.x, offset.y, offset.z),transformationMatrix ,float2(1.0f,1-t)));
	}
	#if S_USE_BLADE_TEXTURE == 0
		GSAppendVertex(triStream,TransformGeomToClip(i[index],index,float3(0,forward, height),tipTransformationMatrix,float2(0.5f,0)));
	#endif
	GSRestartStrip( triStream );
}

#define BLADE_AMOUNT 1

bool FustrumCull( float4 vPositionPs0, float4 vPositionPs1, float4 vPositionPs2 )
    {
        // Discard if all the vertices are behind the near plane
        if ( ( vPositionPs0.z < 0.0 ) && ( vPositionPs1.z < 0.0 ) && ( vPositionPs2.z < 0.0 ) )
            return true;

        // Discard if all the vertices are behind the far plane
        if ( ( vPositionPs0.z > vPositionPs0.w ) && ( vPositionPs1.z > vPositionPs1.w ) && ( vPositionPs2.z > vPositionPs2.w ) )
        	return true;

        // Discard if all the vertices are outside one of the frustum sides
        if ( vPositionPs0.x < -vPositionPs0.w-40 &&
        	 vPositionPs1.x < -vPositionPs1.w-40 &&
        	 vPositionPs2.x < -vPositionPs2.w-40 )
        	 return true;
        if ( vPositionPs0.y < -vPositionPs0.w-40 &&
        	 vPositionPs1.y < -vPositionPs1.w-40 &&
        	 vPositionPs2.y < -vPositionPs2.w-40 )
        	 return true;
        if ( vPositionPs0.x > vPositionPs0.w+40 &&
        	 vPositionPs1.x > vPositionPs1.w+40 &&
        	 vPositionPs2.x > vPositionPs2.w+40 )
        	 return true;
        if ( vPositionPs0.y > vPositionPs0.w+40 &&
        	 vPositionPs1.y > vPositionPs1.w+40 &&
        	 vPositionPs2.y > vPositionPs2.w+40 )
        	 return true;

        return false;
    }



[maxvertexcount(3+(BLADE_SEGMENTS*2+1)*BLADE_AMOUNT )]
void MainGs( triangle GeometryInput i[3], inout TriangleStream< PS_INPUT > triStream )
{

	if( FustrumCull(i[0].vPositionPs, i[1].vPositionPs, i[2].vPositionPs) )
    {
        return;
    }

    [unroll]for( uint l = 0; l < 3; l++)
    {
		float4 vPositionWs = mul( g_matProjectionToWorld, i[l].vPositionPs );
        i[l].vPositionPs = Position4WsToPsMultiview(0,float4( vPositionWs.xyz+(i[l].vNormalWs*0.05),vPositionWs.w));
		i[l].vBladeUV = float2(0,0);
        GSAppendVertex( triStream, i[l] );
    }
	GSRestartStrip( triStream );

	if(distance (i[0].vPositionWs+g_vCameraPositionWs, g_vCameraPositionWs)> GrassCutoffDistance){
		return;
	}
	[unroll]for( uint j = 0; j < BLADE_AMOUNT; j++)
    {
        GenerateGrass(i,j,triStream);
    }	

    
}
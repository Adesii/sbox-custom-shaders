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



PS_INPUT TransformGeomToClip(GeometryInput i,float3 offset,float3x3 transmatrix,float2 uv){
	PS_INPUT o = (PS_INPUT)i;
	float3 transformedpos = float3(0,0,0);
	transformedpos.x += snoise(float3(i.worldspace.xy/90,0+i.worldspace.z/90))*(GrassPatchDist);
	transformedpos.y += snoise(float3(i.worldspace.yx/90,100+i.worldspace.z/90))*(GrassPatchDist);
	i.worldspace += projection(transformedpos,i.worldspacenormals);
	o.vPositionPs = Position3WsToPs(i.worldspace + mul( offset.xyz,transmatrix));
	o.vTextureCoords = uv;
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


void GenerateGrass(triangle GeometryInput i[3],int index, inout TriangleStream< PS_INPUT > triStream){

    float3 pos = i[index].worldspace.xyz/100;
	float3 normal = i[index].worldspacenormals.xyz;
    float3 tangent = i[index].worldspacevTangentUWs.xyz;

    float3x3 tangentToLocal = g_matViewToProjection;


    float3x3 randRotMatrix = angleAxis3x3((rand((pos)*(index+1))*PI_TWO)*RandRotation,float3(0,0,1.0f));

    float3x3 randBendMatrix = angleAxis3x3((rand(pos.yyx*(index+1))-0.5f)*BendDelta*PI,float3(-1.0f,0,0));

    float2 windUV = (pos.xy/100) * WindMapSTR.xy + WindMapSTR.zw  * WindFrequency * g_flTime;
	float2 windSample = ((Tex2DLevel(g_tWindMap,windUV, 0).xy * 2) - 1) * length(WindVelocity);

	float3 windAxis = normalize(float3(windSample.x, windSample.y, 0));
	float3x3 windMatrix = angleAxis3x3(PI * windSample.x, windAxis);

    float3x3 baseTransformationMatrix = mul(windMatrix,randRotMatrix);
	float3x3 tipTransformationMatrix = mul(mul(windMatrix,randBendMatrix),randRotMatrix);

	float falloffamount = GetDistanceFalloff(pos,g_vCameraPositionWs/100,GrassCutoffDistance*0.005,GrassCutoffDistance*0.01,GrassCutoffDistanceFalloff);
    float width  = lerp(BladeWidth.x, BladeWidth.y*10, rand(pos.xyz) * GrassFalloff)* falloffamount;
	float height = lerp(BladeLenght.x, BladeLenght.y*10, rand(pos.yzx) * GrassFalloff)* falloffamount;
	float forward = rand(pos.zzy) * BladeBendDistance;


    for (int k = 0; k < BLADE_SEGMENTS; ++k)
	{
		float t = k / (float)BLADE_SEGMENTS;
		float3 offset = float3(width * (1 - t), pow(t, BladeBendCurve) * forward, height * t ) ;
		float3x3 transformationMatrix = (k == 0) ? baseTransformationMatrix : tipTransformationMatrix;
        GSAppendVertex(triStream,TransformGeomToClip(i[index],float3(offset.x, offset.y, offset.z),transformationMatrix ,float2(0,t)));
	    GSAppendVertex(triStream,TransformGeomToClip(i[index],float3(-offset.x, offset.y, offset.z),transformationMatrix ,float2(1.0f,t)));
	}
	GSAppendVertex(triStream,TransformGeomToClip(i[index],float3(0,forward, height),tipTransformationMatrix,float2(0.5f,1.0f)));
	GSRestartStrip( triStream );
}

#define BLADE_AMOUNT 1


[maxvertexcount(3+(BLADE_SEGMENTS*2+1)*BLADE_AMOUNT )]
void MainGs( triangle GeometryInput i[3], inout TriangleStream< PS_INPUT > triStream )
{

    [unroll]for( uint l = 0; l < 3; l++)
    {
        i[l].vTextureCoords = float2(0,0);
        i[l].vPositionPs = Position3WsToPs(i[l].worldspace+ i[l].worldspacenormals);
        GSAppendVertex( triStream, i[l] );
    }
	GSRestartStrip( triStream );

	if(distance (i[0].worldspace, g_vCameraPositionWs)> GrassCutoffDistance){
		return;
	}
	[unroll]for( uint j = 0; j < BLADE_AMOUNT; j++)
    {
		//i[j].vPositionWs = i[j].worldspace;
        GenerateGrass(i,j,triStream);
    }	

    
}
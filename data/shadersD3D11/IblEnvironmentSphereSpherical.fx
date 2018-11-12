//------------------------------------------------------------------------------------//
//                                                                                    //
//    ._____________.____   __________         __                                     //
//    |   \______   \    |  \______   \_____  |  | __ ___________                     //
//    |   ||    |  _/    |   |    |  _/\__  \ |  |/ // __ \_  __ \                    //
//    |   ||    |   \    |___|    |   \ / __ \|    <\  ___/|  | \/                    //
//    |___||______  /_______ \______  /(____  /__|_ \\___  >__|                       //
//                \/        \/      \/      \/     \/    \/                           //
//                                                                                    //
//    IBLBaker is provided under the MIT License(MIT)                                 //
//    IBLBaker uses portions of other open source software.                           //
//    Please review the LICENSE file for further details.                             //
//                                                                                    //
//    Copyright(c) 2014 Matt Davidson                                                 //
//                                                                                    //
//    Permission is hereby granted, free of charge, to any person obtaining a copy    //
//    of this software and associated documentation files(the "Software"), to deal    //
//    in the Software without restriction, including without limitation the rights    //
//    to use, copy, modify, merge, publish, distribute, sublicense, and / or sell     //
//    copies of the Software, and to permit persons to whom the Software is           //
//    furnished to do so, subject to the following conditions :                       //
//                                                                                    //
//    1. Redistributions of source code must retain the above copyright notice,       //
//    this list of conditions and the following disclaimer.                           //
//    2. Redistributions in binary form must reproduce the above copyright notice,    //
//    this list of conditions and the following disclaimer in the                     //
//    documentation and / or other materials provided with the distribution.          //
//    3. Neither the name of the copyright holder nor the names of its                //
//    contributors may be used to endorse or promote products derived                 //
//    from this software without specific prior written permission.                   //
//                                                                                    //
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR      //
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,        //
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE      //
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER          //
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,   //
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN       //
//    THE SOFTWARE.                                                                   //
//                                                                                    //
//------------------------------------------------------------------------------------//
float ShaderName : SHADERNAME 
<
    string ToString = "EnvironmentSphereSpherical";
> = 0.0;


float4x4 worldMatrix : WORLD;
float4x4 worldViewProjection : WORLDVIEWPROJECTION;
float4x4 viewInverse : VIEWINVERSE;
float4 eyeLocation : EYELOCATION;
Texture2D environmentMap : DIFFUSEMAP;
float textureGamma : TEXTUREGAMMA;


#define INV_PI 1.0 / 3.14159;

SamplerState anisotropicSampler
{
    Filter =     ANISOTROPIC;
    MaxAnisotropy = 16;
    AddressU  = Wrap;
    AddressV  = Wrap;
    BorderColor = float4(10000,10000,10000,10000);
};

float4 texSphericalOld(float3 dir, float lod)
{
    float n = length(dir.xz);

    float2 pos = float2( (n>0.0000001) ? dir.x / n : 0.0, dir.y);
    pos = acos(pos)*INV_PI;
    pos.x = (dir.z > 0.0) ? pos.x*0.5 : 1.0-(pos.x*0.5);
    pos.x = 1.0-pos.x;
    return environmentMap.SampleLevel(anisotropicSampler, pos, lod);
}

float4 texSpherical(float3 dir, float lod)
{
	float3 normalizedDir = normalize(dir);

	float lon = atan2(-normalizedDir.z, normalizedDir.x);
	float lat = acos(normalizedDir.y);
	
	float2 radians = float2(1.0 / (3.141592 * 2.0), 1.0 / 3.141592);
	
	float2 uv = float2(lon, lat) * radians;
	
	return environmentMap.SampleLevel(anisotropicSampler, uv, lod);
}

struct VertexShaderIn
{
    float4 position   : POSITION;
    float3 normal     : NORMAL;
    float2 uv         : TEXCOORD0;
};


struct VertexShaderOut
{
    float4 position       :     SV_POSITION;
    float3 positionInWorld : TEXCOORD0;
    float3 normal : TEXCOORD1;

};

struct PixelShaderInput
{
    float4 position       :     SV_POSITION;
    float3 positionInWorld : TEXCOORD0;
    float3 normal : TEXCOORD1;

};

struct PixelShaderOut
{
    float4 output0: SV_TARGET0;
};

VertexShaderOut vs (VertexShaderIn vertexShaderIn)
{
    VertexShaderOut output;
    output.position = mul(vertexShaderIn.position, worldViewProjection);
    float3 position = vertexShaderIn.position.xyz;
    float2 texCoord = vertexShaderIn.uv;
    float3 normal = normalize(mul(vertexShaderIn.position, (float3x3)worldMatrix));    
    float3 worldPos = mul(float4(position.xyz, 1), worldMatrix).xyz;    
    output.positionInWorld = worldPos;
    output.normal = normal;

    return output;
}


PixelShaderOut ps (PixelShaderInput vertexShaderOut) 
{
    PixelShaderOut output;

    float4 textureGammaColor = float4(0,0,0,1);
    float3 envDiffuseCoord = vertexShaderOut.normal.xyz;
    envDiffuseCoord = vertexShaderOut.normal;
    textureGammaColor = texSpherical(vertexShaderOut.normal.xyz, 0);
    float4    diffuseColor = float4(pow(textureGammaColor.rgb, textureGamma), textureGammaColor.a);
    float alpha =  diffuseColor.a ;

	output.output0 = float4(diffuseColor.rgb, 1);

    return output;
}

technique11 Default
{
    pass p0
    {
        SetVertexShader (CompileShader (vs_5_0, vs()));
        SetGeometryShader (NULL);
        SetPixelShader (CompileShader (ps_5_0, ps()));
    }
}


Shader "normalizedcrow/Directional Blur"
{
    Properties
    {
        //Size
        _BlurSize("Blur Size", Range(0.0, 0.25)) = 0.1
        [ToggleUI] _UsePerspectiveBlurSize("Apply Perspective To Blur Size", Float) = 1.0
        _MaxBlurSize("Max Blur Size", Range(0.0, 0.25)) = 0.1

        //Direction and Strength
        [Enum(None, 0, Strength, 1, Direction, 2)] _BlurTextureMode("Texture Mode", Int) = 0.0
        [MainTexture] _BlurTexture("Blur Texture", 2D) = "white" {}
        _TextureScrollX("Scroll Speed X", Float) = 0.0
        _TextureScrollY("Scroll Speed Y", Float) = 0.0

        _BlurDirectionRotation("Blur Direction Rotation", Range(0.0, 360.0)) = 0.0
        [ToggleUI] _UseWorldspaceBlurDirection("Use Worldspace Orientation For Direction", Float) = 1.0
        [ToggleUI] _UseVertexAlphaBlurStrength("Vertex Alpha Affects Blur Strength", Float) = 1.0

        //Shape
        _BlurOffset("Blur Center Offset", Range(-0.5, 0.5)) = 0.0
        [Enum(Gaussian, 0, Dispersion, 1)] _BlurMode("Blur Type", Int) = 0.0
        _GaussianBlurFalloff("Falloff", Range(0.0, 5.0)) = 0.0
        _GaussianBlurOffset("Peak Offset", Range(-0.5, 0.5)) = 0.0
        _DispersionBlurIntensity("Intensity", Range(0.0, 1.0)) = 1.0

        //Tint
        [MainColor] _Tint("Base Tint", Color) = (1.0, 1.0, 1.0, 1.0)
        [ToggleUI] _UseVertexColorTint("Tint With Vertex Color", Float) = 1.0
        _MinTintStrength("Min Tint Strength", Range(0.0, 1.0)) = 0.0

        //Advanced
        [IntRange] _MaxSampleCount("Max Sample Count", Range(5, 25)) = 5
        [NoScaleOffset] _DitherTexture("Dither Texture", 2D) = "linearGray" {}

        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Int) = 4
        [Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Int) = 1.0
        [IntRange] _DepthOffset("Depth Offset", Range(-1.0, 1.0)) = 0.0
    }

    CustomEditor "DirectionalBlurGUI"

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }

        GrabPass
        {
            "_DirectionalBlurTexture"
        }

        Pass
        {
            Cull [_Cull]
            Offset [_DepthOffset], [_DepthOffset]
            ZTest [_ZTest]
            ZWrite [_ZWrite]
            Blend Off
            ColorMask RGB

            HLSLPROGRAM
            #pragma multi_compile_instancing

            #pragma vertex DirectionalBlurVertexShader
            #pragma fragment DirectionalBlurPixelShader

            #include "UnityCG.cginc"

            //resources

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_DirectionalBlurTexture);
            
            Texture2D _BlurTexture;
            SamplerState sampler_BlurTexture;

            Texture2D _DitherTexture;

            //constants

            float _BlurSize;
            bool _UsePerspectiveBlurSize;
            float _MaxBlurSize;

            uint _BlurTextureMode;
            float4 _BlurTexture_ST;
            float _TextureScrollX;
            float _TextureScrollY;

            float _BlurDirectionRotation;
            bool _UseWorldspaceBlurDirection;
            bool _UseVertexAlphaBlurStrength;

            float _BlurOffset;
            uint _BlurMode;
            float _GaussianBlurFalloff;
            float _GaussianBlurOffset;
            float _DispersionBlurIntensity;

            float3 _Tint;
            bool _UseVertexColorTint;
            float _MinTintStrength;

            uint _MaxSampleCount;
            float4 _DitherTexture_TexelSize;

            //structs

            struct DirectionalBlurVertexInput
            {
                float3 position : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 color : COLOR;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct DirectionalBlurPixelInput
            {
                float4 pos : SV_POSITION;
                float4 clipPos : TEXCOORD0;
                float3 viewPos : TEXCOORD1;
                float3 viewNormal : TEXCOORD2;
                float4 viewTangent : TEXCOORD3;
                float2 uv : TEXCOORD4;
                float4 color : TEXCOORD5;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            //screenspace texture helper, replaces UNITY_SAMPLE_SCREENSPACE_TEXTURE() with a version that always samples lod 0
#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
    #define SAMPLE_SCREENSPACE_TEXTURE_LOD0(tex, uv) UNITY_SAMPLE_TEX2DARRAY_LOD(tex, float3((uv).xy, (float)unity_StereoEyeIndex), 0)
#else
    #define SAMPLE_SCREENSPACE_TEXTURE_LOD0(tex, uv) tex2Dlod(tex, float4(uv, 0.0, 0.0))
#endif

            //vertex shader

            DirectionalBlurPixelInput DirectionalBlurVertexShader(DirectionalBlurVertexInput vertex)
            {
                DirectionalBlurPixelInput output;

                UNITY_SETUP_INSTANCE_ID(vertex);
                UNITY_INITIALIZE_OUTPUT(DirectionalBlurPixelInput, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.pos = UnityObjectToClipPos(vertex.position);
                output.clipPos = output.pos;
                output.viewPos = UnityObjectToViewPos(vertex.position);

                output.viewNormal = UnityObjectToWorldNormal(vertex.normal);
                output.viewNormal = normalize(mul(UNITY_MATRIX_V, float4(output.viewNormal, 0.0)));

                output.viewTangent.xyz = UnityObjectToWorldDir(vertex.tangent.xyz);
                output.viewTangent.xyz = normalize(mul(UNITY_MATRIX_V, float4(output.viewTangent.xyz, 0.0)).xyz);
                output.viewTangent.w = vertex.tangent.w;

                output.uv = vertex.uv;
                output.color = vertex.color;

                return output;
            }

            //pixel shader

            float4 DirectionalBlurPixelShader(DirectionalBlurPixelInput input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                //get blur strength and base direction

                float blurStrength = _UseVertexAlphaBlurStrength ? input.color.a : 1.0;
                float2 blurDirection = float2(1.0, 0.0);

                float2 uvScroll = float2(_TextureScrollX, _TextureScrollY) * _Time.y;
                float2 blurTextureUv = ((input.uv - uvScroll) * _BlurTexture_ST.xy) + _BlurTexture_ST.zw;

                [branch]
                if (_BlurTextureMode == 1)
                {
                    blurStrength *= _BlurTexture.Sample(sampler_BlurTexture, blurTextureUv).r;
                }
                else if (_BlurTextureMode == 2)
                {
                    float2 textureDirection = (_BlurTexture.Sample(sampler_BlurTexture, blurTextureUv).rg * 2.0) - 1.0;

                    blurStrength *= saturate(length(textureDirection));
                    blurDirection = normalize(textureDirection);
                }

                blurStrength = saturate(blurStrength);

                //get blur direction

                float rotationAngle = (_BlurDirectionRotation / 360.0) * 2.0 * UNITY_PI;
                float2 rotationVector = float2(cos(rotationAngle), sin(rotationAngle));

                blurDirection = float2(dot(blurDirection, float2(rotationVector.x, -rotationVector.y)),
                                       dot(blurDirection.yx, rotationVector));

                if(_UseWorldspaceBlurDirection)
                {
                    float3 viewBitangent = normalize(cross(input.viewTangent.xyz, input.viewNormal)) * input.viewTangent.w * unity_WorldTransformParams.w;
                    float3 viewBlurDirection = (normalize(input.viewTangent.xyz) * blurDirection.x) + (viewBitangent * blurDirection.y);

                    blurDirection = normalize((input.viewPos.xy * viewBlurDirection.z) - (viewBlurDirection.xy * input.viewPos.z));
                }

                //get blur size

                float blurSize = _BlurSize;

                if (_UsePerspectiveBlurSize && (unity_OrthoParams.w < 0.5))
                {
                    blurSize /= length(input.viewPos);
                    blurSize = min(blurSize, _MaxBlurSize);
                }

                blurSize *= blurStrength;

                //get values for blur sampling

                float4 screenPos = ComputeGrabScreenPos(input.clipPos);
                float2 screenUv = screenPos.xy / screenPos.w;

                float2 screenUvAxis = blurDirection * blurSize * float2(UNITY_MATRIX_P._m00, UNITY_MATRIX_P._m11);
#if UNITY_UV_STARTS_AT_TOP
                screenUvAxis.y = -screenUvAxis.y;
#endif
                screenUvAxis = TransformStereoScreenSpaceTex(screenUvAxis, 0.0);

                uint idealSamplesNeeded = ceil(length(screenUvAxis * _ScreenParams.xy));
                uint actualSampleCount = clamp(idealSamplesNeeded, 1, _MaxSampleCount);

                float dither = frac(_DitherTexture[input.pos.xy % _DitherTexture_TexelSize.zw]);

                //do sampling

                float3 totalColor = 0.0;
                float3 totalWeights = 0.0;

                [loop]
                for (uint i = 0; i < actualSampleCount; i++)
                {
                    float sampleCoord = ((i + dither) / actualSampleCount) - 0.5;

                    float2 sampleUv = screenUv + (screenUvAxis * (sampleCoord + _BlurOffset));
                    float3 sampleColor = SAMPLE_SCREENSPACE_TEXTURE_LOD0(_DirectionalBlurTexture, sampleUv).rgb;

                    float3 weights = 0.0;
                    if (_BlurMode == 0)
                    {
                        float exponent = _GaussianBlurFalloff * (sampleCoord + _GaussianBlurOffset);
                        exponent = -0.5 * exponent * exponent;

                        weights = exp(exponent).xxx;
                    }
                    else
                    {
                        float3 rainbowWeights = saturate(float3(-3.0 * sampleCoord, 1.0 - (3.0 * abs(sampleCoord)), 3.0 * sampleCoord));
                        weights = lerp(1.0.xxx, rainbowWeights, _DispersionBlurIntensity) + 0.0001; // add an epsilon to avoid divide by 0 errors
                    }

                    totalColor += sampleColor * weights;
                    totalWeights += weights;
                }

                totalColor /= totalWeights;

                //get tint

                float3 blurTint = _Tint;

                if (_UseVertexColorTint)
                {
                    blurTint *= input.color.rgb;
                }

                float tintStrength = lerp(_MinTintStrength, 1.0, blurStrength);
                blurTint = saturate(blurTint + 0.0001); // add an epsilon to avoid floating point errors
                blurTint = pow(blurTint, tintStrength);

                return float4(totalColor * blurTint, 0.0);
            }

            ENDHLSL
        }
    }
}
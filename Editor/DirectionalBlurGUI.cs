namespace UnityEditor
{
    internal class DirectionalBlurGUI : ShaderGUI
    {
        private struct Properties
        {
            public MaterialProperty blurSize;
            public MaterialProperty usePerspectiveBlurSize;
            public MaterialProperty maxBlurSize;

            public MaterialProperty blurTextureMode;
            public MaterialProperty blurTexture;
            public MaterialProperty textureScrollX;
            public MaterialProperty textureScrollY;

            public MaterialProperty blurDirectionRotation;
            public MaterialProperty useWorldspaceBlurDirection;
            public MaterialProperty useVertexAlphaBlurStrength;

            public MaterialProperty blurOffset;
            public MaterialProperty blurMode;
            public MaterialProperty gaussianBlurFalloff;
            public MaterialProperty gaussianBlurOffset;
            public MaterialProperty dispersionBlurIntensity;

            public MaterialProperty tint;
            public MaterialProperty useVertexColorTint;
            public MaterialProperty minTintStrength;

            public MaterialProperty maxSampleCount;
            public MaterialProperty ditherTexture;

            public MaterialProperty cull;
            public MaterialProperty zTest;
            public MaterialProperty zWrite;
            public MaterialProperty depthOffset;

            public Properties(MaterialProperty[] props)
            {
                blurSize = FindProperty("_BlurSize", props);
                usePerspectiveBlurSize = FindProperty("_UsePerspectiveBlurSize", props);
                maxBlurSize = FindProperty("_MaxBlurSize", props);

                blurTextureMode = FindProperty("_BlurTextureMode", props);
                blurTexture = FindProperty("_BlurTexture", props);
                textureScrollX = FindProperty("_TextureScrollX", props);
                textureScrollY = FindProperty("_TextureScrollY", props);

                blurDirectionRotation = FindProperty("_BlurDirectionRotation", props);
                useWorldspaceBlurDirection = FindProperty("_UseWorldspaceBlurDirection", props);
                useVertexAlphaBlurStrength = FindProperty("_UseVertexAlphaBlurStrength", props);

                blurOffset = FindProperty("_BlurOffset", props);
                blurMode = FindProperty("_BlurMode", props);
                gaussianBlurFalloff = FindProperty("_GaussianBlurFalloff", props);
                gaussianBlurOffset = FindProperty("_GaussianBlurOffset", props);
                dispersionBlurIntensity = FindProperty("_DispersionBlurIntensity", props);

                tint = FindProperty("_Tint", props);
                useVertexColorTint = FindProperty("_UseVertexColorTint", props);
                minTintStrength = FindProperty("_MinTintStrength", props);

                maxSampleCount = FindProperty("_MaxSampleCount", props);
                ditherTexture = FindProperty("_DitherTexture", props);

                cull = FindProperty("_Cull", props);
                zTest = FindProperty("_ZTest", props);
                zWrite = FindProperty("_ZWrite", props);
                depthOffset = FindProperty("_DepthOffset", props);
            }
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            Properties properties = new Properties(props);

            //matches unity default inspector
            EditorGUIUtility.labelWidth = 0.0f;
            EditorGUIUtility.fieldWidth = 64.0f;

            EditorGUILayout.LabelField("Size", EditorStyles.boldLabel);
            materialEditor.ShaderProperty(properties.blurSize, "Blur Size");
            materialEditor.ShaderProperty(properties.usePerspectiveBlurSize, "Apply Perspective To Blur Size");
            if (properties.usePerspectiveBlurSize.floatValue != 0.0f)
            {
                EditorGUI.indentLevel++;
                materialEditor.ShaderProperty(properties.maxBlurSize, "Max Blur Size");
                EditorGUI.indentLevel--;
            }

            EditorGUILayout.Space(12);

            EditorGUILayout.LabelField("Direction and Strength", EditorStyles.boldLabel);
            materialEditor.ShaderProperty(properties.blurTextureMode, "Texture Mode");

            if (properties.blurTextureMode.floatValue != 0.0f)
            {
                string textureName = properties.blurTextureMode.floatValue == 1.0f ? "Strength Texture" : "Direction Texture";
                materialEditor.TextureProperty(properties.blurTexture, textureName, false);

                EditorGUI.indentLevel++;
                materialEditor.TextureScaleOffsetProperty(properties.blurTexture);
                EditorGUI.indentLevel--;

                EditorGUILayout.BeginHorizontal();

                EditorGUI.indentLevel++;
                EditorGUILayout.PrefixLabel("Scroll Speed");
                EditorGUI.indentLevel--;

                EditorGUIUtility.labelWidth = 10.0f;
                materialEditor.ShaderProperty(properties.textureScrollX, "X");
                materialEditor.ShaderProperty(properties.textureScrollY, "Y");
                EditorGUIUtility.labelWidth = 0.0f;
                
                EditorGUILayout.EndHorizontal();

                EditorGUILayout.Space(12);
            }

            materialEditor.ShaderProperty(properties.blurDirectionRotation, "Blur Direction Rotation");
            materialEditor.ShaderProperty(properties.useWorldspaceBlurDirection, "Use Worldspace Orientation For Direction");
            materialEditor.ShaderProperty(properties.useVertexAlphaBlurStrength, "Vertex Alpha Affects Blur Strength");

            EditorGUILayout.Space(12);

            EditorGUILayout.LabelField("Shape", EditorStyles.boldLabel);
            materialEditor.ShaderProperty(properties.blurOffset, "Blur Center Offset");
            materialEditor.ShaderProperty(properties.blurMode, "Blur Type");

            EditorGUI.indentLevel++;

            if (properties.blurMode.floatValue == 0.0f)
            {
                materialEditor.ShaderProperty(properties.gaussianBlurFalloff, "Falloff");
                materialEditor.ShaderProperty(properties.gaussianBlurOffset, "Peak Offset");
            }
            else
            {
                materialEditor.ShaderProperty(properties.dispersionBlurIntensity, "Intensity");
            }

            EditorGUI.indentLevel--;

            EditorGUILayout.Space(12);

            EditorGUILayout.LabelField("Tint", EditorStyles.boldLabel);
            materialEditor.ShaderProperty(properties.tint, "Base Tint");
            materialEditor.ShaderProperty(properties.useVertexColorTint, "Tint With Vertex Color");
            materialEditor.ShaderProperty(properties.minTintStrength, "Min Tint Strength");

            EditorGUILayout.Space(12);

            EditorGUILayout.LabelField("Advanced", EditorStyles.boldLabel);
            materialEditor.ShaderProperty(properties.maxSampleCount, "Max Sample Count");
            materialEditor.ShaderProperty(properties.ditherTexture, "Dither Texture");

            EditorGUILayout.Space(12);

            materialEditor.ShaderProperty(properties.cull, "Cull");
            materialEditor.ShaderProperty(properties.zTest, "ZTest");
            materialEditor.ShaderProperty(properties.zWrite, "ZWrite");
            materialEditor.ShaderProperty(properties.depthOffset, "Depth Offset");

            EditorGUILayout.Space(12);

            materialEditor.RenderQueueField();
            materialEditor.EnableInstancingField();
            materialEditor.DoubleSidedGIField();
        }
    }
}
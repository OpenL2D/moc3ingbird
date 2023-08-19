/*
 * MOC3 Format Specification, 2.1
 *
 * Copyright (C) 2023 The OpenL2D Project Developers
 *
 * This software is free software: you can redistribute and/or modify it
 * under the terms of the Free Development Public License version 1.0-US
 * as published at <https://freedevproject.org/fdpl-1.0-us>.
 *
 * This software is provided as is, without any warranty. See the license
 * for more details.
 */
 
/*
 * This pattern has not been fully verified for correctness. Use at your
 * own risk.
 *
 * == Change Log ==
 * 2.0 - Initial implementation as a pattern.
 * 2.0a - Support for latest MOC3 features (experimental).
 * 2.0b - Experimental support for verification.
 * 2.0c - New FIXUP attribute to support more MOC3 files.
 * 2.1 - Support for version 5 MOC3 features.
 */

#pragma MIME application/x-moc3-data

// MOC3 files can contain large arrays of coordinates.
// Do NOT increase pattern_limit; that's usually a sign the data structure
// should be marked [[static]] instead.
#ifndef MOC3_NO_SET_ARRAY_LIMIT
#pragma array_limit 1048576
#endif

#ifndef NO_BIG_ENDIAN_SUPPORT
    // Experimental big endian MOC3 support. Setting the following to
    // true will ensure that MOC3 files are always read as big endian,
    // otherwise endianness will be autodetected.
    bool AlwaysReadAsBigEndian in;
#endif

#ifdef NO_BIG_ENDIAN_SUPPORT
    #pragma endian little
#endif

// If you are interested in modifying Runtime Space fields, set the
// following to true.
bool ShowRuntimeSpaceFields in;

using void = u8;
using bool32 = u32;

#ifndef NO_OFFSET_FIXUP
    #include <std/mem.pat>
    #include <std/io.pat>
    // Apparently some empty fields can point to EOF.
    // I also think this is bad design (and there's no way to support
    // this without weaking verification a bit), but here it is.
    fn fixOffset(u32 offset) {
        if (offset == std::mem::size()) {
            return -offset;
        }
        return 0;
    };
    
    fn identity(auto value) {
        return value;
    };
    
    // If you want to disable these fixups with a toggle, set the
    // following to true.
    bool DisableOffsetFixUps in;
    #define FIXUP pointer_base(DisableOffsetFixUps ? "identity" : "fixOffset")
#endif

#ifdef NO_OFFSET_FIXUP
    #define FIXUP dummy
#endif

enum Version : u8 {
    V3_00_00 = 1,
    V3_03_00 = 2,
    V4_00_00 = 3,
    V4_02_00 = 4,
    V5_00_00 = 5,
} [[comment("MOC3 version")]];

struct Header {
    char magic[4] [[name("Magic"), comment("MOC3 magic string: 'MOC3'")]];
    Version version [[name("Version"), comment("MOC3 version")]];
    bool isBigEndian [[name("Big Endian"), comment("MOC3 endianness")]];
    padding[58];
} [[static]];

bitfield CanvasFlags {
    reverseYCoordinate : 1;
    reserved : 7;
};

struct CanvasInfo {
    float pixelsPerUnit [[name("Pixels Per Unit")]];
    float originX [[name("X Origin")]];
    float originY [[name("Y Origin")]];
    float canvasWidth [[name("Width")]];
    float canvasHeight [[name("Height")]];
    CanvasFlags canvasFlags [[name("Flags")]];
    padding[43];
} [[static]];

struct CountInfoTable<auto V> {
    if (V >= Version::V5_00_00)
        padding[128] [[no_unique_address]];
    else
        padding[256] [[no_unique_address]];

    u32 parts [[name("Parts")]];
    u32 deformers [[name("Deformers")]];
    u32 warpDeformers [[name("Warp Deformers")]];
    u32 rotationDeformers [[name("Rotation Deformers")]];
    u32 artMeshes [[name("Art Meshes")]];
    u32 parameters [[name("Parameters")]];
    u32 partKeyforms [[name("Part Keyforms")]];
    u32 warpDeformerKeyforms [[name("Warp Deformer Keyforms")]];
    u32 rotationDeformerKeyforms [[name("Rotation Deformer Keyforms")]];
    u32 artMeshKeyforms [[name("Art Mesh Keyforms")]];
    u32 keyformPositions [[name("Keyform Positions")]];
    u32 parameterBindingIndices [[name("Parameter Binding Indices")]];
    u32 keyformBindings [[name("Keyform Bindings")]];
    u32 parameterBindings [[name("Parameter Bindings")]];
    u32 keys [[name("Keys")]];
    u32 uvs [[name("UVs")]];
    u32 positionIndices [[name("Position Indices")]];
    u32 drawableMasks [[name("Drawable Masks")]];
    u32 drawOrderGroups [[name("Draw Order Groups")]];
    u32 drawOrderGroupObjects [[name("Draw Order Group Objects")]];
    u32 glue [[name("Glue")]];
    u32 glueInfo [[name("Glue Info")]];
    u32 glueKeyforms [[name("Glue Keyforms")]];
    
    if (V >= Version::V4_02_00) {
        u32 keyformMultiplyColors [[name("Keyform Colors (Multiply)")]];
        u32 keyformScreenColors [[hidden, name("Keyform Colors (Screen)")]];
        u32 blendShapeParameterBindings [[name("Blend Shape Parameter Bindings")]];
        u32 blendShapeKeyformBindings [[name("Blend Shape Keyform Bindings")]];
        u32 blendShapesWarpDeformers [[name("Blend Shapes (Warp Deformers)")]];
        u32 blendShapesArtMeshes [[hidden, name("Blend Shapes (Art Meshes)")]];
        u32 blendShapeConstraintIndices [[name("Blend Shape Constraint Indices")]];
        u32 blendShapeConstraints [[name("Blend Shape Constraints")]];
        u32 blendShapeConstraintValues [[name("Blend Shape Constraint Values")]];
    }

    if (V >= Version::V5_00_00) {
        u32 blendShapesParts [[name("Blend Shapes (Parts)")]];
        u32 blendShapesRotationDeformers [[name("Blend Shapes (Rotation Deformers)")]];
        u32 blendShapesGlue [[name("Blend Shapes (Glue)")]];
    }
};

union ID {
    padding[64];
    char value[64];
} [[static]];

struct UV {
    float u, v;
} [[static]];

struct XY {
    float x, y;
} [[static]];

struct PartOffsets<auto N> {
    if (ShowRuntimeSpaceFields)
        u32 runtimeSpace0 [[name("Runtime Space 0 Offset")]];
    else
        void* runtimeSpace0[N * 8] : u32 [[name("Runtime Space 0"), hidden]];
    ID* ids[N] : u32 [[name("IDs"), FIXUP]];
    s32* keyformBindingSourcesIndices[N] : u32 [[name("Keyform Binding Sources Indices"), FIXUP]];
    s32* keyformSourcesBeginIndices[N] : u32 [[name("Keyform Sources Begin Indices"), FIXUP]];
    s32* keyformSourcesCounts[N] : u32 [[name("Keyform Sources Counts"), FIXUP]];
    bool32* isVisible[N] : u32 [[name("Visible"), FIXUP]];
    bool32* isEnabled[N] : u32 [[name("Enabled"), FIXUP]];
    s32* parentPartIndices[N] : u32 [[name("Parent Part Indices"), FIXUP]];
};

enum DeformerType : u32 {
    WARP = 0,
    ROTATION = 1,
};

struct DeformerOffsets<auto N> {
    if (ShowRuntimeSpaceFields)
        u32 runtimeSpace0 [[name("Runtime Space 0 Offset")]];
    else
        void* runtimeSpace0[N * 8] : u32 [[name("Runtime Space 0"), hidden]];
    ID* ids[N] : u32 [[name("IDs"), FIXUP]];
    s32* keyformBindingSourcesIndices[N] : u32 [[name("Keyform Binding Sources Indices"), FIXUP]];
    bool32* isVisible[N] : u32 [[name("Visible"), FIXUP]];
    bool32* isEnabled[N] : u32 [[name("Enabled"), FIXUP]];
    s32* parentPartIndices[N] : u32 [[name("Parent Part Indices"), FIXUP]];
    s32* parentDeformerIndices[N] : u32 [[name("Parent Deformer Indices"), FIXUP]];
    DeformerType* types[N] : u32 [[name("Types"), FIXUP]];
    s32* specificSourcesIndices[N] : u32 [[name("Specific Sources Indices"), FIXUP]];
};

struct WarpDeformerOffsets<auto N> {
    s32* keyformBindingSourcesIndices[N] : u32 [[name("Keyform Binding Sources Indices"), FIXUP]];
    s32* keyformSourcesBeginIndices[N] : u32 [[name("Keyform Sources Begin Indices"), FIXUP]];
    s32* keyformSourcesCounts[N] : u32 [[name("Keyform Sources Counts"), FIXUP]];
    s32* vertexCounts[N] : u32 [[name("Vertex Counts"), FIXUP]];
    u32* rows[N] : u32 [[name("Rows"), FIXUP]];
    u32* columns[N] : u32 [[name("Columns"), FIXUP]];
};

struct RotationDeformerOffsets<auto N> {
    s32* keyformBindingSourcesIndices[N] : u32 [[name("Keyform Binding Sources Indices"), FIXUP]];
    s32* keyformSourcesBeginIndices[N] : u32 [[name("Keyform Sources Begin Indices"), FIXUP]];
    s32* keyformSourcesCounts[N] : u32 [[name("Keyform Sources Counts"), FIXUP]];
    float* baseAngles[N] : u32 [[name("Base Angles"), FIXUP]];
};

bitfield DrawableFlags {
    blendMode : 2;
    isDoubleSided : 1;
    isInverted : 1;
    padding : 4;
};

struct ArtMeshOffsets<auto N> {
    if (ShowRuntimeSpaceFields) {
        u32 runtimeSpace0 [[name("Runtime Space 0 Offset")]];
        u32 runtimeSpace1 [[name("Runtime Space 1 Offset")]];
        u32 runtimeSpace2 [[name("Runtime Space 2 Offset")]];
        u32 runtimeSpace3 [[name("Runtime Space 3 Offset")]];
    } else {
        void* runtimeSpace0[N * 8] : u32 [[name("Runtime Space 0"), hidden]];
        void* runtimeSpace1[N * 8] : u32 [[name("Runtime Space 1"), hidden]];
        void* runtimeSpace2[N * 8] : u32 [[name("Runtime Space 2"), hidden]];
        void* runtimeSpace3[N * 8] : u32 [[name("Runtime Space 3"), hidden]];
    }
    ID* ids[N] : u32 [[name("IDs"), FIXUP]];
    s32* keyformBindingSourcesIndices[N] : u32 [[name("Keyform Binding Sources Indices"), FIXUP]];
    s32* keyformSourcesBeginIndices[N] : u32 [[name("Keyform Sources Begin Indices"), FIXUP]];
    s32* keyformSourcesCounts[N] : u32 [[name("Keyform Sources Counts"), FIXUP]];
    bool32* isVisible[N] : u32 [[name("Visible"), FIXUP]];
    bool32* isEnabled[N] : u32 [[name("Enabled"), FIXUP]];
    s32* parentPartIndices[N] : u32 [[name("Parent Part Indices"), FIXUP]];
    s32* parentDeformerIndices[N] : u32 [[name("Parent Deformer Indices"), FIXUP]];
    u32* textureNos[N] : u32 [[name("Texture No."), FIXUP]];
    DrawableFlags* drawableFlags[N] : u32 [[name("Drawable Flags"), FIXUP]];
    s32* vertexCounts[N] : u32 [[name("Vertex Counts"), FIXUP]];
    s32* uvSourcesBeginIndices[N] : u32 [[name("UV Sources Begin Indices"), FIXUP]];
    s32* positionIndexSourcesBeginIndices[N] : u32 [[name("Position Index Sources Begin Indices"), FIXUP]];
    s32* positionIndexSourcesCounts[N] : u32 [[name("Position Index Sources Counts"), FIXUP]];
    s32* drawableMaskSourcesBeginIndices[N] : u32 [[name("Drawable Mask Sources Begin Indices"), FIXUP]];
    s32* drawableMaskSourcesCounts[N] : u32 [[name("Drawable Mask Sources Counts"), FIXUP]];
};

struct ParameterOffsets<auto N> {
    if (ShowRuntimeSpaceFields)
        u32 runtimeSpace0 [[name("Runtime Space 0 Offset")]];
    else
        void* runtimeSpace0[N * 8] : u32 [[name("Runtime Space 0"), hidden]];
    ID* ids[N] : u32 [[name("IDs"), FIXUP]];
    float* maxValues[N] : u32 [[name("Max Values"), FIXUP]];
    float* minValues[N] : u32 [[name("Min Values"), FIXUP]];
    float* defaultValues[N] : u32 [[name("Default Values)"), FIXUP]];
    bool32* isRepeat[N] : u32 [[name("Repeat"), FIXUP]];
    u32* decimalPlaces[N] : u32 [[name("Decimal Places"), FIXUP]];
    s32* parameterBindingSourcesBeginIndices[N] : u32 [[name("Parameter Binding Sources Begin Indices"), FIXUP]];
    s32* parameterBindingSourcesCounts[N] : u32 [[name("Parameter Binding Sources Count"), FIXUP]]; 
};

struct PartKeyformOffsets<auto N> {
    float* drawOrders[N] : u32 [[name("Draw Orders"), FIXUP]];
};

struct WarpDeformerKeyformOffsets<auto N> {
    float* opacities[N] : u32 [[name("Opacities"), FIXUP]];
    s32* keyformPositionSourcesBeginIndices[N] : u32 [[name("Keyform Position Sources Begin Indices"), FIXUP]];
};

struct RotationDeformerKeyformOffsets<auto N> {
    float* opacities[N] : u32 [[name("Opacities"), FIXUP]];
    float* angles[N] : u32 [[name("Angles"), FIXUP]];
    float* originX[N] : u32 [[name("X Origins"), FIXUP]];
    float* originY[N] : u32 [[name("Y Origins"), FIXUP]];
    float* scales[N] : u32 [[name("Scales"), FIXUP]];
    bool32* isReflectX[N] : u32 [[name("Reflect on X"), FIXUP]];
    bool32* isReflectY[N] : u32 [[name("Reflect on Y"), FIXUP]];
};

struct ArtMeshKeyformOffsets<auto N> {
    float* opacities[N] : u32 [[name("Opacities"), FIXUP]];
    float* drawOrders[N] : u32 [[name("Draw Orders"), FIXUP]];
    s32* keyformPositionSourcesBeginIndices[N] : u32 [[name("Keyform Position Sources Begin Indices"), FIXUP]];
};

struct KeyformPositionOffsets<auto N> {
    XY* xys[N / 2] : u32 [[name("Coordinates"), FIXUP]];
};

struct ParameterBindingIndicesOffsets<auto N> {
    s32* bindingSourcesIndices[N] : u32 [[name("Binding Sources Indices"), FIXUP]];
};

struct KeyformBindingOffsets<auto N> {
    s32* parameterBindingIndexSourcesBeginIndices[N] : u32 [[name("Parameter Binding Index Sources Begin Indices"), FIXUP]];
    s32* parameterBindingIndexSourcesCounts[N] : u32 [[name("Parameter Binding Index Sources Counts"), FIXUP]];
};

struct ParameterBindingOffsets<auto N> {
    s32* keysSourcesBeginIndices[N] : u32 [[name("Keys Sources Begin Indices"), FIXUP]];
    s32* keysSourcesCounts[N] : u32 [[name("Keys Sources Counts"), FIXUP]];
};

struct KeyOffsets<auto N> {
    float* values[N] : u32 [[name("Key Values"), FIXUP]];
};

struct UVOffsets<auto N> {
    UV* uvs[N / 2] : u32 [[name("UVs"), FIXUP]];
};

struct PositionIndicesOffsets<auto N> {
    s16* indices[N] : u32 [[name("Indices"), FIXUP]];
};

struct DrawableMaskOffsets<auto N> {
    s32* artMeshSourcesIndices[N] : u32 [[name("Art Mesh Sources Indices"), FIXUP]];
};

struct DrawOrderGroupOffsets<auto N> {
    s32* objectSourcesBeginIndices[N] : u32 [[name("Object Sources Begin Indices"), FIXUP]];
    s32* objectSourcesCounts[N] : u32 [[name("Object Sources Counts"), FIXUP]];
    s32* objectSourcesTotalCounts[N] : u32 [[name("Object Sources Total Counts"), FIXUP]];
    u32* maximumDrawOrders[N] : u32 [[name("Maximum Draw Orders"), FIXUP]];
    u32* minimumDrawOrders[N] : u32 [[name("Minimum Draw Orders"), FIXUP]];
};

enum DrawOrderGroupObjectType : u32 {
    ART_MESH = 0,
    PART = 1,
};

struct DrawOrderGroupObjectOffsets<auto N> {
    DrawOrderGroupObjectType* types[N] : u32 [[name("Types"), FIXUP]];
    s32* indices[N] : u32 [[name("Indices"), FIXUP]];
    s32* selfIndices[N] : u32 [[name("Self Indices"), FIXUP]];
};

struct GlueOffsets<auto N> {
    if (ShowRuntimeSpaceFields)
        u32 runtimeSpace0 [[name("Runtime Space 0 Offset")]];
    else
        void* runtimeSpace0[N * 8] : u32 [[name("Runtime Space 0"), hidden]];
    ID* IDs[N] : u32 [[name("IDs"), FIXUP]];
    s32* keyformBindingSourcesIndices[N] : u32 [[name("Keyform Binding Sources Indices"), FIXUP]];
    s32* keyformSourcesBeginIndices[N] : u32 [[name("Keyform Sources Begin Indices"), FIXUP]];
    s32* keyformSourcesCounts[N] : u32 [[name("Keyform Binding Sources Counts"), FIXUP]];
    s32* artMeshIndicesA[N] : u32 [[name("Art Mesh Indices (A)"), FIXUP]];
    s32* artMeshIndicesB[N] : u32 [[name("Art Mesh Indices (B)"), FIXUP]];
    s32* glueInfoSourcesBeginIndices[N] : u32 [[name("Info Sources Begin Indices"), FIXUP]];
    s32* glueInfoSourcesCounts[N] : u32 [[name("Info Sources Counts"), FIXUP]];
};

struct GlueInfoOffsets<auto N> {
    float* weights[N] : u32 [[name("Weights"), FIXUP]];
    s16* positionIndices[N] : u32 [[name("Position Indices"), FIXUP]];
};

struct GlueKeyformOffsets<auto N> {
    float* intensities[N] : u32 [[name("Intensities"), FIXUP]];
};

struct WarpDeformerKeyformOffsetsV3_3<auto N> {
    bool32* isQuadSource[N] : u32 [[name("Quad Source"), FIXUP]];
};

struct ParameterExtensionOffsets<auto N> {
    if (ShowRuntimeSpaceFields)
        u32 runtimeSpace0 [[name("Runtime Space 0")]];
    else
        void* runtimeSpace0[N * 8] : u32 [[name("Runtime Space 0"), hidden]];
    s32* keysSourcesBeginIndices[N] : u32 [[name("Keys Sources Begin Indices"), FIXUP]];
    s32* keysSourcesCounts[N] : u32 [[name("Keys Sources Counts"), FIXUP]];
};

struct WarpDeformerKeyformOffsetsV4_2<auto N> {
    s32* keyformColorSourcesBeginIndices[N] : u32 [[name("Keyform Color Sources Begin Indices"), FIXUP]];
};

struct RotationDeformerOffsetsV4_2<auto N> {
    s32* keyformColorSourcesBeginIndices[N] : u32 [[name("Keyform Color Sources Begin Indices"), FIXUP]];
};

struct ArtMeshOffsetsV4_2<auto N> {
    s32* keyformColorSourcesBeginIndices[N] : u32 [[name("Keyform Color Sources Begin Indices"), FIXUP]];
};

struct KeyformColorOffsets<auto N> {
    float* R[N] : u32 [[name("Red Values"), FIXUP]];
    float* G[N] : u32 [[name("Green Values"), FIXUP]];
    float* B[N] : u32 [[name("Blue Values"), FIXUP]];
};

enum ParameterType : u32 {
    NORMAL = 0,
    BLEND_SHAPE = 1,
};

struct ParameterOffsetsV4_2<auto N> {
    ParameterType* parameterTypes[N] : u32 [[name("Types"), FIXUP]];
    s32* blendShapeParameterBindingSourcesBeginIndices[N] : u32 [[name("Blend Shape Parameter Binding Sources Begin Indices"), FIXUP]];
    s32* blendShapeParameterBindingSourcesCounts[N] : u32 [[name("Blend Shape Parameter Binding Sources Counts"), FIXUP]];
};

struct BlendShapeParameterBindingOffsets<auto N> {
    s32* keysSourcesBeginIndices[N] : u32 [[name("Keys Sources Begin Indices"), FIXUP]];
    s32* keysSourcesCounts[N] : u32 [[name("Keys Sources Counts"), FIXUP]];
    s32* baseKeyIndices[N] : u32 [[name("Base Key Indices"), FIXUP]];
};

struct BlendShapeKeyformBindingOffsets<auto N> {
    s32* parameterBindingSourcesIndices[N] : u32 [[name("Parameter Binding Sources Indices"), FIXUP]];
    s32* blendShapeConstraintIndexSourcesBeginIndices[N] : u32 [[name("Blend Shape Constraint Index Sources Begin Indices"), FIXUP]];
    s32* blendShapeConstraintIndexSourcesCounts[N] : u32 [[name("Blend Shape Constraint Index Sources Counts"), FIXUP]];
    s32* keyformSourcesBlendShapeIndices[N] : u32 [[name("Keyform Sources Blend Shape Indices"), FIXUP]];
    s32* keyformSourcesBlendShapeCounts[N] : u32 [[name("Keyform Sources Blend Shape Counts"), FIXUP]];
};

struct BlendShapeOffsets<auto N> {
    s32* targetIndices[N] : u32 [[name("Target Indices"), FIXUP]];
    s32* blendShapeKeyformBindingSourcesBeginIndices[N] : u32 [[name("Blend Shape Keyform Binding Sources Begin Indices"), FIXUP]];
    s32* blendShapeKeyformBindingSourcesCounts[N] : u32 [[name("Blend Shape Keyform Binding Sources Counts"), FIXUP]];
};

struct BlendShapeConstraintIndicesOffsets<auto N> {
    s32* blendShapeConstraintSourcesIndices[N] : u32 [[name("Blend Shape Constraint Sources Indices"), FIXUP]];
};

struct BlendShapeConstraintOffsets<auto N> {
    s32* parameterIndices[N] : u32 [[name("Parameter Indices"), FIXUP]];
    s32* blendShapeConstraintValueSourcesBeginIndices[N] : u32 [[name("Blend Shape Constraint Value Sources Begin Indices"), FIXUP]];
    s32* blendShapeConstraintValueSourcesCounts[N] : u32 [[name("Blend Shape Constraint Value Sources Counts"), FIXUP]];
};

struct BlendShapeConstraintValueOffsets<auto N> {
    float* keys[N] : u32 [[name("Keys"), FIXUP]];
    float* weights[N] : u32 [[name("Weights"), FIXUP]];
};

struct SectionOffsetTable<auto V> {
    padding[0x280] [[no_unique_address]];

    CountInfoTable<V>* countInfo : u32 [[name("Count Info Table")]];
    CanvasInfo* canvasInfo : u32 [[name("Canvas Info")]];
    
    PartOffsets<countInfo.parts> parts [[name("Parts")]];
    DeformerOffsets<countInfo.deformers> deformers [[name("Deformers")]];
    WarpDeformerOffsets<countInfo.warpDeformers> warpDeformers [[name("Warp Deformers")]];
    RotationDeformerOffsets<countInfo.rotationDeformers> rotationDeformers [[name("Rotation Deformers")]];
    ArtMeshOffsets<countInfo.artMeshes> artMeshes [[name("Art Meshes")]];
    ParameterOffsets<countInfo.parameters> parameters [[name("Parameters")]];
    PartKeyformOffsets<countInfo.partKeyforms> partKeyforms [[name("Part Keyforms")]];
    WarpDeformerKeyformOffsets<countInfo.warpDeformerKeyforms> warpDeformerKeyforms [[name("Warp Deformer Keyforms")]];
    RotationDeformerKeyformOffsets<countInfo.rotationDeformerKeyforms> rotationDeformerKeyforms [[name("Rotation Deformer Keyforms")]];
    ArtMeshKeyformOffsets<countInfo.artMeshKeyforms> artMeshKeyforms [[name("Art Mesh Keyforms")]];
    KeyformPositionOffsets<countInfo.keyformPositions> keyformPositions [[name("Keyform Positions")]];
    ParameterBindingIndicesOffsets<countInfo.parameterBindingIndices> parameterBindingIndices [[name("Parameter Binding Indices")]];
    KeyformBindingOffsets<countInfo.keyformBindings> keyformBindings [[name("Keyform Bindings")]];
    ParameterBindingOffsets<countInfo.parameterBindings> parameterBindings [[name("Parameter Bindings")]];
    KeyOffsets<countInfo.keys> keys [[name("Keys")]];
    UVOffsets<countInfo.uvs> UVs [[name("UVs")]];
    PositionIndicesOffsets<countInfo.positionIndices> positionIndices [[name("Position Indices")]];
    DrawableMaskOffsets<countInfo.drawableMasks> drawableMasks [[name("Drawable Masks")]];
    DrawOrderGroupOffsets<countInfo.drawOrderGroups> drawOrderGroups [[name("Draw Order Groups")]];
    DrawOrderGroupObjectOffsets<countInfo.drawOrderGroupObjects> drawOrderGroupObjects [[name("Draw Order Group Objects")]];
    GlueOffsets<countInfo.glue> glue [[name("Glue")]];
    GlueInfoOffsets<countInfo.glueInfo> glueInfo [[name("Glue Info")]];
    GlueKeyformOffsets<countInfo.glueKeyforms> glueKeyforms [[name("Glue Keyforms")]];
    
    if (V >= Version::V3_03_00) {
        WarpDeformerKeyformOffsetsV3_3<countInfo.warpDeformers> warpDeformersV3_3 [[name("Warp Deformer Keyforms (V3_03_00+)")]];
    }
    
    if (V >= Version::V4_02_00) {
        ParameterExtensionOffsets<countInfo.parameters> parameterExtensions [[name("Parameter Extensions")]];
        WarpDeformerKeyformOffsetsV4_2<countInfo.warpDeformers> warpDeformersV4_2 [[name("Warp Deformer Keyforms (V4_02_00+)")]];
        RotationDeformerOffsetsV4_2<countInfo.rotationDeformers> rotationDeformersV4_2 [[name("Rotation Deformers (V4_02_00+)")]];
        ArtMeshOffsetsV4_2<countInfo.artMeshes> artMeshesV4_2 [[name("Art Meshes (V4_02_00+)")]];
        KeyformColorOffsets<countInfo.keyformMultiplyColors> keyformMultiplyColors [[name("Keyform Colors (Multiply)")]];
        KeyformColorOffsets<countInfo.keyformScreenColors> keyformScreenColors [[name("Keyform Colors (Screen)")]];
        ParameterOffsetsV4_2<countInfo.parameters> parametersV4_2 [[name("Parameters (V4_02_00+)")]];
        BlendShapeParameterBindingOffsets<countInfo.blendShapeParameterBindings> blendShapeParameterBindings [[name("Blend Shape Parameter Bindings")]];
        BlendShapeKeyformBindingOffsets<countInfo.blendShapeKeyformBindings> blendShapeKeyformBindings [[name("Blend Shape Keyform Bindings")]];
        BlendShapeOffsets<countInfo.blendShapesWarpDeformers> blendShapesWarpDeformers [[name("Blend Shapes (Warp Deformers)")]];
        BlendShapeOffsets<countInfo.blendShapesArtMeshes> blendShapesArtMeshes [[name("Blend Shapes (Art Meshes)")]];
        BlendShapeConstraintIndicesOffsets<countInfo.blendShapeConstraintIndices> blendShapeConstraintIndices [[name("Blend Shape Constraints Indices")]];
        BlendShapeConstraintOffsets<countInfo.blendShapeConstraints> blendShapeConstraints [[name("Blend Shape Constraints")]];
        BlendShapeConstraintValueOffsets<countInfo.blendShapeConstraintValues> blendShapeConstraintValues [[name("Blend Shape Constraint Values")]];
    }

    if (V >= Version::V5_00_00) {
        BlendShapeOffsets<countInfo.blendShapesParts> blendShapesParts [[name("Blend Shapes (Parts)")]];
        BlendShapeOffsets<countInfo.blendShapesRotationDeformers> blendShapesRotationDeformers [[name("Blend Shapes (Rotation Deformers)")]];
        BlendShapeOffsets<countInfo.blendShapesGlue> blendShapesGlue [[name("Blend Shapes (Glue)")]];
    }
};

struct RuntimeAddressMap {
    void runtimeData[0x480] [[name("Runtime Data (Overwritten at Load Time)"), comment("Do not put data here.")]];
};

Header header @ 0x0 [[name("MOC3 Header")]];
#ifndef NO_BIG_ENDIAN_SUPPORT
    #include <std/core.pat>
    #include <std/mem.pat>
    if (AlwaysReadAsBigEndian || header.isBigEndian) {
        std::core::set_endian(std::mem::Endian::Big);
    } else {
        std::core::set_endian(std::mem::Endian::Little);
    }
#endif

SectionOffsetTable<header.version> sections @ 0x40 [[name("Section Offset Table")]];
RuntimeAddressMap runtimeAddressMap @ 0x2c0 [[name("Runtime Address Map")]];

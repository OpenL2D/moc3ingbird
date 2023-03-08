/*
 * The Cubism Archive File Format Specification, 1.0
 * (Also CMO3 or CAFF)
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

/* THIS SPECFICIATION IS INCOMPLETE */

#include <std/io.pat>
#include <std/mem.pat>
 
#pragma MIME application/x-caff-archive

// For some reason, CAFF archives are big endian.
#pragma endian big

using Version;
using FileInfo;

// Type used for 32-bit XOR obfuscation key
using Key = u32;

using header;

namespace Util {
    fn versionToString(Version V) {
        return std::format("{}.{}.{}", V.major, V.minor, V.patch);
    };
    
    fn cryptBool(bool value) {
        return Util::cryptU8(u8(value)) != 0;
    };
    
    fn cryptU8(u8 value) {
        return value ^ (header.obfuscateKey & 0xFF);
    };
    
    fn cryptU8Array(ref auto array) {
        char ret[sizeof(array)];
        for (u32 i = 0, i < sizeof(array), i += 1) {
            ret[i] = Util::cryptU8(array[i]);
        }
        return ret;
    };
    
    fn cryptU8String(ref auto array) {
        str ret;
        for (u32 i = 0, i < sizeof(array), i += 1) {
            ret += std::format("{:c}", Util::cryptU8(array[i]));
        }
        return ret;
    };
    
    fn cryptU32(u32 value) {
        return value ^ header.obfuscateKey;
    };
    
    fn parseVarIntFromArray(auto array) {
        u32 ret = Util::cryptU8(array[0]) & 0x7F;
        for (u8 i = 1, Util::cryptU8(array[i-1]) & 0x80 != 0, i += 1) {
            ret = ret << 7 | (Util::cryptU8(array[i-1]) & 0x7F);
        }
        
        ret |= Util::cryptU8(array[sizeof(array)-1]);
        return ret;
    };
    
    fn parseVarInt(auto obj) {
        return Util::parseVarIntFromArray(obj.array);
    };
}

#define CRYPT_BOOL transform("Util::cryptBool")
#define CRYPT_U8 transform("Util::cryptU8")
#define CRYPT_U32 transform("Util::cryptU32")

#define CRYPT_U8A transform("Util::cryptU8Array")
#define CRYPT_U8A_FMTSTR format("Util::cryptU8String")

struct Version {
    u8 major, minor, patch;
} [[sealed, format("Util::versionToString")]];

struct _VarInt {
    u8 array[while($ == addressof(this) || Util::cryptU8(std::mem::read_unsigned($-1, 1)) & 0x80 != 0)];
} [[sealed]];

using VarInt = _VarInt [[format("Util::parseVarInt"), transform("Util::parseVarInt")]];

struct StringSlice {
    VarInt length;
    char bytes[length] [[CRYPT_U8A_FMTSTR, CRYPT_U8A]];
};

struct ByteSlice {
    VarInt length;
    char bytes[length] [[CRYPT_U8A]];
};

enum ImageType : s8 {
    UNKNOWN,
    PNG,
    NONE = 0x7F,
};

enum ColorType : s8 {
    UNKNOWN,
    ARGB,
    RGB,
    NONE = 0x7F,
};

struct PreviewImage {
    ImageType imageType [[name("Image Type")]];
    ColorType colorType [[name("Color Type")]];
    padding[2];
    
    u16 width [[name("Width")]];
    u16 height [[name("Height")]];
    padding[8];
    
    u32; // offset to fileinfo?
};

struct Header {
    char magic[4] [[name("Archive Magic")]];
    Version version [[name("Archive Version")]];
    char format[4] [[name("Format Identifier")]];
    Version formatVersion [[name("Format Version")]];
    Key obfuscateKey [[name("Obfuscation Key")]];
    padding[8];
    
    PreviewImage previewImage [[name("Preview Image")]];
    padding[8];
    
    u32 entryCount [[name("Total File Entries"), CRYPT_U32]];
};

enum CompressOption : u8 {
    RAW = 0x00,
    FAST = 0x01,
    SMALL = 0x10,
};

struct FileInfo {
    StringSlice fileName;
    ByteSlice tag;
    padding[8];
    u32 fileSize [[CRYPT_U32]];
    bool isObfuscated [[CRYPT_BOOL]];
    u8 compression [[CRYPT_U8]];
    padding[8];
};

struct FileData<N> {
    u8 data[N];
};

struct Body<auto N> {
    FileInfo metaData[N];
   // FileData data[1];
};

Header header @ 0x00 [[name("CAFF Header")]];
Body<header.entryCount> body @ 0x3A;


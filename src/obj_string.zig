const std = @import("std");
const HeapObject = @import("heap_object.zig").HeapObject;
const ObjType = @import("heap_object.zig").ObjType;
const String = @import("types.zig").String;

pub const ObjString = struct {
    base: HeapObject,
    data: String,

    pub fn init(data: String) ObjString {
        return ObjString{
            .base = HeapObject{ .obj_type = .string },
            .data = data,
        };
    }
};

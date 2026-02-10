const std = @import("std");
const String = @import("types.zig").String;
const Value = @import("value.zig").Value;
const HeapObject = @import("heap_object.zig").HeapObject;
const ObjType = @import("heap_object.zig").ObjType;

pub const ObjObject = struct {
    base: HeapObject,
    properties: std.StringHashMap(Value),
    proto: ?*ObjObject,

    pub fn init(allocator: std.mem.Allocator, proto: ?*ObjObject) ObjObject {
        return ObjObject{
            .base = HeapObject{ .obj_type = ObjType.object },
            .properties = std.StringHashMap(Value).init(allocator),
            .proto = proto,
        };
    }

    pub fn deinit(self: *ObjObject) void {
        var it = self.properties.iterator();

        while (it.next()) |_| {}
        self.properties.deinit();
    }

    pub fn set(
        self: *ObjObject,
        key: String,
        value: Value,
    ) !void {
        try self.properties.put(key, value);
    }

    pub fn get(
        self: *ObjObject,
        key: String,
    ) Value {
        if (self.properties.get(key)) |val| {
            return val;
        }

        if (self.proto) |p| {
            return p.get(key);
        }

        return Value{ .undefined = {} };
    }
};

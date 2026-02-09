const std = @import("std");
const String = @import("types.zig").String;
const Value = @import("value.zig").Value;
const HeapObject = @import("heap_object.zig").HeapObject;
const ObjType = @import("heap_object.zig").ObjType;

pub const ObjObject = struct {
    base: HeapObject,
    properties: std.StringHashMap(Value),

    pub fn init(allocator: std.mem.Allocator) ObjObject {
        return ObjObject{
            .base = HeapObject{ .obj_type = ObjType.object },
            .properties = std.StringHashMap(Value).init(allocator),
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
        return self.properties.get(key) orelse Value{ .undefined = {} };
    }
};

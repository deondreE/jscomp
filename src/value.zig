const std = @import("std");
const HeapObject = @import("heap_object.zig").HeapObject;

pub const ValueTag = enum {
    number,
    boolean,
    null,
    undefined,
    object,
};

pub const Value = union(ValueTag) {
    number: f64,
    boolean: bool,
    null: void,
    undefined: void,
    object: *HeapObject,

    pub fn print(self: Value) void {
        switch (self) {
            .number => |n| std.debug.print("{d}", .{n}),
            .boolean => |b| std.debug.print("{}", .{b}),
            .null => std.debug.print("null", .{}),
            .undefined => std.debug.print("undefined", .{}),
            .object => |_| std.debug.print("[object]", .{}),
        }
    }
};

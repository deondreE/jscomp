const std = @import("std");
const HeapObject = @import("heap_object.zig").HeapObject;
const ObjString = @import("obj_string.zig").ObjString;

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
            .object => |ptr| {
                switch (ptr.obj_type) {
                    .string => {
                        const s: ObjString = @fieldParentPtr("base", ptr);
                        std.debug.print("\"{s}\"", .{s.data});
                    },
                    .function => std.debug.print("[function]", .{}),
                    .object => std.debug.print("[object]", .{}),
                }
            },
        }
    }
};

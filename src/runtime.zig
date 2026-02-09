const std = @import("std");
const Value = @import("value.zig").Value;
const ObjObject = @import("object.zig").ObjObject;
const ObjFunction = @import("function.zig").ObjFunction;
const NativeFn = @import("function.zig").NativeFn;
const HeapObject = @import("heap_object.zig").HeapObject;
const ObjType = @import("heap_object.zig").ObjType;

pub const Runtime = struct {
    allocator: std.mem.Allocator,
    objects: std.ArrayList(*HeapObject),

    pub fn init(allocator: std.mem.Allocator) Runtime {
        return .{
            .allocator = allocator,
            .objects = .empty,
        };
    }

    pub fn deinit(self: *Runtime) void {
        for (self.objects.items) |obj| {
            switch (obj.obj_type) {
                .object => {
                    const o: *ObjObject = @alignCast(@fieldParentPtr("base", obj));
                    o.deinit();
                    self.allocator.destroy(o);
                },
                .function => {
                    const f: *ObjFunction = @alignCast(@fieldParentPtr("base", obj));
                    self.allocator.destroy(f);
                },
            }
        }
        self.objects.deinit(self.allocator);
    }

    pub fn newObject(self: *Runtime) !Value {
        const obj = try self.allocator.create(ObjObject);
        obj.* = ObjObject.init(self.allocator);
        try self.objects.append(self.allocator, &obj.base);
        return Value{ .object = &obj.base };
    }

    pub fn newFunction(self: *Runtime, func: *const NativeFn) !Value {
        const f = try self.allocator.create(ObjFunction);
        f.* = ObjFunction.init(func);
        try self.objects.append(self.allocator, &f.base);
        return Value{ .object = &f.base };
    }

    pub fn callFunction(
        _: *Runtime,
        v: Value,
        argc: usize,
        argv: []const Value,
    ) Value {
        const aligned_base: *align(@alignOf(ObjFunction)) HeapObject =
            @alignCast(v.object);

        const fn_obj: *ObjFunction =
            @alignCast(@fieldParentPtr("base", aligned_base));
        return fn_obj.call(argc, argv);
    }
};

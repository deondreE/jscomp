const std = @import("std");
const Value = @import("value.zig").Value;
const ObjObject = @import("object.zig").ObjObject;
const ObjString = @import("obj_string.zig").ObjString;
const ObjFunction = @import("function.zig").ObjFunction;
const NativeFn = @import("function.zig").NativeFn;
const HeapObject = @import("heap_object.zig").HeapObject;
const ObjType = @import("heap_object.zig").ObjType;
const String = @import("types.zig").String;

pub const Runtime = struct {
    allocator: std.mem.Allocator,
    objects: ?*HeapObject = null,

    pub fn init(allocator: std.mem.Allocator) Runtime {
        return .{
            .allocator = allocator,
            .objects = null,
        };
    }

    pub fn deinit(self: *Runtime) void {
        var curr = self.objects;
        while (curr) |obj| {
            const next = obj.next;
            self.freeSpecificObject(obj);
            curr = next;
        }

        self.objects = null;
    }

    fn trackObject(self: *Runtime, obj: *HeapObject) void {
        obj.next = self.objects;
        self.objects = obj;
        obj.marked = false;
    }

    pub fn newObject(self: *Runtime) !Value {
        const obj = try self.allocator.create(ObjObject);
        obj.* = ObjObject.init(self.allocator);
        // try self.objects.append(self.allocator, &obj.base);
        self.trackObject(&obj.base);
        return Value{ .object = &obj.base };
    }

    pub fn newFunction(self: *Runtime, func: *const NativeFn) !Value {
        const f = try self.allocator.create(ObjFunction);
        f.* = ObjFunction.init(func);
        // try self.objects.append(self.allocator, &f.base);
        self.trackObject(&f.base);
        return Value{ .object = &f.base };
    }

    fn freeObjects(self: *Runtime) void {
        var curr = self.objects;
        while (curr) |obj| {
            const next = obj.next;
            self.freeSpecificObject(obj);
            curr = next;
        }
    }

    fn freeSpecificObject(self: *Runtime, obj: *HeapObject) void {
        switch (obj.obj_type) {
            .string => {
                const aligned_base: *align(@alignOf(ObjString)) HeapObject =
                    @alignCast(obj);
                const actual: *ObjString = @fieldParentPtr("base", aligned_base);
                self.allocator.free(actual.data);
                self.allocator.destroy(actual);
            },
            .object => {
                const aligned_base: *align(@alignOf(ObjObject)) HeapObject =
                    @alignCast(obj);
                const actual: *ObjObject = @fieldParentPtr("base", aligned_base);
                actual.properties.deinit();
                self.allocator.destroy(actual);
            },
            .function => {
                const aligned_base: *align(@alignOf(ObjFunction)) HeapObject =
                    @alignCast(obj);
                const actual: *ObjFunction = @fieldParentPtr("base", aligned_base);
                self.allocator.destroy(actual);
            },
        }
    }

    pub fn collectGarbage(self: *Runtime, roots: []const Value) void {
        for (roots) |root| {
            self.markValue(root);
        }

        self.sweep();
    }

    fn markValue(self: *Runtime, val: Value) void {
        if (val != .object) return;
        const obj = val.object;
        if (obj.marked) return;

        obj.marked = true;

        switch (obj.obj_type) {
            .object => {
                const aligned_base: *align(@alignOf(ObjObject)) HeapObject =
                    @alignCast(obj.*);
                const actual: ObjObject = @fieldParentPtr("base", aligned_base);
                var it = actual.properties.iterator();
                while (it.next()) |v| {
                    self.markValue(v.*);
                }
            },
            .function => {},
        }
    }

    fn sweep(self: *Runtime) void {
        var prev: ?*HeapObject = null;
        var curr = self.objects;

        while (curr) |obj| {
            if (!obj.marked) {
                // Unlink
                const next = obj.next;
                if (prev) |p| {
                    p.next = next;
                } else {
                    self.objects = next;
                }

                self.freeSpecificObject(obj);
                curr = next;
            } else {
                obj.marked = false;
                prev = curr;
                curr = obj.next;
            }
        }
    }

    pub fn newString(self: *Runtime, text: String) !Value {
        const obj = try self.allocator.create(ObjString);

        const data = try self.allocator.dupe(u8, text);

        obj.* = ObjString.init(data);
        self.trackObject(&obj.base);

        return Value{ .object = &obj.base };
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

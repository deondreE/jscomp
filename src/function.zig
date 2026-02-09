const Value = @import("value.zig").Value;
const HeapObject = @import("heap_object.zig").HeapObject;
const ObjType = @import("heap_object.zig").ObjType;

pub const NativeFn = fn (argc: usize, argv: []const Value) Value;

pub const ObjFunction = struct {
    base: HeapObject,
    func: *const NativeFn,

    pub fn init(func: *const NativeFn) ObjFunction {
        return ObjFunction{
            .base = HeapObject{ .obj_type = ObjType.function },
            .func = func,
        };
    }

    pub fn call(
        self: *ObjFunction,
        argc: usize,
        argv: []const Value,
    ) Value {
        return self.func(argc, argv);
    }
};

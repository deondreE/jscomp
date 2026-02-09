pub const ObjType = enum(u8) {
    object,
    function,
};

pub const HeapObject = struct {
    obj_type: ObjType,
};

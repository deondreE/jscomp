pub const ObjType = enum(u8) {
    object,
    function,
    string,
};

pub const HeapObject = struct {
    obj_type: ObjType,
    marked: bool = false,
    next: ?*HeapObject = null,
};

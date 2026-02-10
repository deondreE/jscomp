const std = @import("std");
const Scanner = @import("scanner.zig").Scanner;
const Parser = @import("parser.zig").Parser;
const Emitter = @import("emitter.zig").Emitter;
const Node = @import("ast.zig").Node;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. Parse CLI Arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3 or !std.mem.eql(u8, args[1], "build")) {
        std.debug.print("Usage: jscomp build <filename.js>\n", .{});
        std.process.exit(1);
    }

    const filename = args[2];
    const source = try std.fs.cwd().readFileAlloc(allocator, filename, 1024 * 1024);
    defer allocator.free(source);

    std.debug.print("Compiling {s} to native machine code...\n", .{filename});

    // 2. Scan & Parse to AST
    var scanner = Scanner.init(source);
    var parser = Parser.init(allocator, &scanner);
    parser.advance(); // Prime the token stream

    var nodes = std.ArrayList(*Node){};
    defer {
        // Free all AST nodes
        for (nodes.items) |node| {
            freeNode(allocator, node);
        }
        nodes.deinit(allocator);
    }

    while (parser.current.token_type != .EOF) {
        const node = try parser.parseDeclaration();
        try nodes.append(allocator, node);
    }

    // 3. Emit Zig Code
    var emitter = Emitter.init(allocator);
    defer emitter.deinit(); // Add this if Emitter has cleanup
    const zig_code = try emitter.emit(nodes.items);
    defer allocator.free(zig_code); // Free the emitted code if it's allocated

    // 4. Compile to Native
    try compile(zig_code);
}

fn freeNode(allocator: std.mem.Allocator, node: *Node) void {
    switch (node.*) {
        .variable_decl => |decl| {
            freeNode(allocator, decl.initializer);
        },
        .binary_expr => |expr| {
            freeNode(allocator, expr.left);
            freeNode(allocator, expr.right);
        },
        .call_expr => |*expr| { // Changed to mutable pointer with *
            freeNode(allocator, expr.callee);
            for (expr.arguments.items) |arg| {
                freeNode(allocator, arg);
            }
            expr.arguments.deinit(allocator);
        },
        .literal_expr => {},
        .indentifier_expr => {},
    }
    allocator.destroy(node);
}

fn compile(asm_code: []const u8) !void {
    const out_file = "output.asm";
    try std.fs.cwd().writeFile(.{ .sub_path = out_file, .data = asm_code });

    std.debug.print("\nAssembly written to {s}\n", .{out_file});
    std.debug.print("To compile: nasm -f elf64 output.asm && gcc output.o -o hello -no-pie\n", .{});
}

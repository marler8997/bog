const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const tokenizer = @import("tokenizer.zig");
const Token = tokenizer.Token;

pub const Op = enum(u8) {
    /// A <- B
    Move,

    /// CALL(A)
    Call,

    /// STACK(A, B) = C
    PushStack,

    /// DISCARD(A)
    Discard,

    /// A = arg1
    ConstSmallInt,

    /// A = STRING(arg1)
    ConstString,

    /// A = NUM(arg1)
    ConstNum,

    /// A = A // B
    DivFloor,

    /// A = A / B
    Div,

    /// A = A * B
    Mul,

    /// A = A % B
    Mod,

    /// A = A + B
    Add,

    /// A = A - B
    Sub,

    /// A = A << B
    LShift,

    /// A = A << B
    RShift,

    /// A = A & B
    BinAnd,

    /// A = A | B
    BinOr,

    /// A = A and B
    And,

    /// A = A or B
    Or,

    /// A = not A
    Not,

    /// A = ~A
    BinNot,

    /// A = -A
    Negate,

    /// IF (A==error) RET A
    Try,

    Jump,

    JumpTrue,

    Return,

    Break,
    EndBreak,

    _,
};

pub const Instruction = packed struct {
    op: Op,
    A: RegRef = 0,
    B: RegRef = 0,
    C: RegRef = 0,
};

pub const Code = std.ArrayList(u32);

pub const Module = struct {
    sect_funcs: []const u32,
    sect_values: []const u64,
    sect_strings: []const u8,
};

pub const MaxStack = 250;
pub const RegRef = u8;

const FuncState = struct {
    frame_size: u8 = 0,
    cur_regs: u8 = 0,
    // parent_ref: ?u8,
    code: Code,

    fn init(allocator: *Allocator) FuncState {
        return .{
            .code = Code.init(allocator),
        };
    }

    fn deinit(self: *FuncState) void {
        self.code.deinit();
    }

    fn registerAlloc(self: *FuncState) !RegRef {
        const reg = self.cur_regs;
        self.cur_regs += 1;
        if (self.cur_regs > self.frame_size) {
            if (self.cur_regs >= MaxStack)
                return error.StackOverflow;
            self.frame_size = self.cur_regs;
        }
        return reg;
    }

    fn registerFree(self: *FuncState, reg: RegRef) void {
        std.debug.assert(self.cur_regs != 0);
        self.cur_regs -= 1;
    }

    fn emitInstruction(self: *FuncState, inst: Instruction, arg: ?u32) anyerror!void {
        try self.code.append(@bitCast(u32, inst));
        if (arg) |some| {
            try self.code.append(some);
        }
    }
};

const FuncList = std.SegmentedList(FuncState, 4);

const Symbol = struct {
    name: []const u8,
    func: *FuncState,
    reg: RegRef,
};

const SymbolList = std.SegmentedList(Symbol, 8);

pub const Builder = struct {
    funcs: FuncList,
    syms: SymbolList,
    cur_func: *FuncState,

    pub fn init(builder: *Builder, allocator: *Allocator) !void {
        // https://github.com/ziglang/zig/issues/2765 pls
        builder.funcs = FuncList.init(allocator);
        builder.cur_func = try builder.funcs.addOne();
        builder.cur_func.* = FuncState.init(allocator);
        builder.syms = SymbolList.init(allocator);
    }

    pub fn deinit(self: *Builder) void {
        self.syms.deinit();
        var it = self.funcs.iterator(0);
        while (it.next()) |f| f.deinit();
        self.funcs.deinit();
    }

    pub fn discard(self: *Builder, reg: RegRef) anyerror!void {
        defer self.cur_func.registerFree(reg);
        try self.cur_func.emitInstruction(.{
            .op = .Discard,
            .A = reg,
        }, null);
    }

    pub fn move(self: *Builder, from: RegRef, to: RegRef) anyerror!void {
        defer self.cur_func.registerFree(from);
        try self.cur_func.emitInstruction(.{
            .op = .Move,
            .A = to,
            .B = from,
        }, null);
    }

    pub fn jumpFalse(self: *Builder, reg: RegRef) anyerror!usize {
        std.debug.warn("jumpFalse #{}\n", .{reg});
        return 1;
    }

    pub fn jumpNotErr(self: *Builder, reg: RegRef) anyerror!usize {
        std.debug.warn("jumpNotErr #{}\n", .{reg});
        return 1;
    }

    pub fn finishJump(self: *Builder, jump: usize) void {
        std.debug.warn("#finishJump #{}\n", .{jump});
    }

    pub fn constant(self: *Builder, tok: *Token) anyerror!RegRef {
        const reg = try self.cur_func.registerAlloc();
        var arg: ?u32 = null;
        const op: Op = switch (tok.id) {
            .String,
            .Keyword_false,
            .Keyword_true,
            .Number,
            => return error.Unimplemented,
            .Integer => |val| if (val <= std.math.maxInt(u32)) blk: {
                // fits in u32
                arg = @truncate(u32, val);
                break :blk .ConstSmallInt;
            } else {
                return error.Unimplemented;
            },
            else => unreachable,
        };
        try self.cur_func.emitInstruction(.{
            .op = op,
            .A = reg,
        }, arg);
        return reg;
    }

    pub fn declRef(self: *Builder, tok: *Token) anyerror!RegRef {
        const name = tok.id.Identifier;
        var it = self.syms.iterator(self.syms.len);
        const found = while (it.prev()) |sym| {
            if (mem.eql(u8, sym.name, name))
                break sym;
        } else {
            return error.UndeclaredIdentifier;
        };
        if (found.func != self.cur_func) {
            // TODO pushStack
            return error.Unimplemented;
        } else {
            return found.reg;
        }
    }

    pub fn buildErr(self: *Builder, tok: *Token, val: RegRef) anyerror!RegRef {
        const reg = self.registerAlloc();
        std.debug.warn("buildErr {}\n", .{ val });
        return reg;
    }

    pub fn buildList(self: *Builder, tok: *Token) anyerror!usize {
        // todo allocate register here?
        const list = 1;
        std.debug.warn("buildList {}\n", .{ list });
        return list;
    }

    pub fn finishList(self: *Builder, tok: *Token, list: usize) anyerror!RegRef {
        const reg = self.registerAlloc();
        std.debug.warn("#finishList {}\n", .{ list });
        return reg;
    }

    pub fn listPush(self: *Builder, val: RegRef) anyerror!void {
        defer self.registerFree(val);
        std.debug.warn("listPush {}\n", .{ val });
    }

    pub fn import(self: *Builder, tok: *Token, str: RegRef) anyerror!RegRef {
        const reg = self.registerAlloc();
        std.debug.warn("import {}\n", .{ str });
        return reg;
    }

    pub fn prefix(self: *Builder, tok: *Token, rhs: RegRef) anyerror!RegRef {
        std.debug.warn("{} {}\n", .{ tok, rhs });
        return rhs;
    }

    pub fn infix(self: *Builder, lhs: RegRef, tok: *Token, rhs: RegRef) anyerror!RegRef {
        defer self.cur_func.registerFree(rhs);
        try self.cur_func.emitInstruction(.{
            .op = switch (tok.id) {
                .SlashSlash => .DivFloor,
                .Slash => .Div,
                .Asterisk => .Mul,
                .Percent => .Mod,
                .Plus => .Add,
                .Minus => .Sub,
                .LArrArr => .LShift,
                .RArrArr => .RShift,
                .Keyword_and => .And,
                .Keyword_or => .Or,
                .Ampersand => .BinAnd,
                .Pipe => .BinOr,
                // .LArr, // TODO
                // .LArrEqual,
                // .RArr,
                // .RArrEqual,
                // .EqualEqual,
                // .BangEqual,
                // .Keyword_in,
                // .Keyword_is,
                else => unreachable,
            },
            .A = lhs,
            .B = rhs,
        }, null);
        return lhs;
    }

    pub fn assign(self: *Builder, lhs: RegRef, tok: *Token, rhs: RegRef) anyerror!void {
        defer self.registerFree(rhs);
        defer self.registerFree(lhs);
        std.debug.warn("#{} {} #{}\n", .{ lhs, tok, rhs });
    }
};

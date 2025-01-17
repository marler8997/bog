const std = @import("std");
const math = std.math;
const bog = @import("../bog.zig");
const Value = bog.Value;
const Vm = bog.Vm;

/// Euler's number (e)
pub const e = math.e;

/// Archimedes' constant (π)
pub const pi = math.pi;

/// Circle constant (τ)
pub const tau = math.tau;

/// log2(e)
pub const log2e = math.log2e;

/// log10(e)
pub const log10e = math.log10e;

/// ln(2)
pub const ln2 = math.ln2;

/// ln(10)
pub const ln10 = math.ln10;

/// 2/sqrt(π)
pub const two_sqrtpi = math.two_sqrtpi;

/// sqrt(2)
pub const sqrt2 = math.sqrt2;

/// 1/sqrt(2)
pub const sqrt1_2 = math.sqrt1_2;

pub fn ln(ctx: Vm.Context, val: *Value) !*Value {
    switch (val.*) {
        .int => |i| {
            if (i <= 0) return ctx.throw("ln is undefined for numbers less than zero");
            const res = try ctx.vm.gc.alloc(.int);
            res.* = Value{ .int = std.math.lossyCast(i64, std.math.floor(std.math.ln(@intToFloat(f64, i)))) };
            return res;
        },
        .num => |n| {
            const res = try ctx.vm.gc.alloc(.num);
            res.* = Value{ .num = std.math.ln(n) };
            return res;
        },
        else => return ctx.throwFmt("ln expects a number, got '{s}'", .{val.typeName()}),
    }
}

pub fn sqrt(ctx: Vm.Context, val: *Value) !*Value {
    return switch (val.*) {
        .int => |i| {
            _ = i;
            const res = try ctx.vm.gc.alloc(.int);
            res.* = Value{ .int = std.math.sqrt(@intCast(u64, i)) };
            return res;
        },
        .num => |n| {
            const res = try ctx.vm.gc.alloc(.num);
            res.* = Value{ .num = std.math.sqrt(n) };
            return res;
        },
        else => return ctx.throwFmt("sqrt expects a number, got '{s}'", .{val.typeName()}),
    };
}

pub fn isNan(val: f64) bool {
    return math.isNan(val);
}

pub fn isSignalNan(val: f64) bool {
    return math.isSignalNan(val);
}

pub fn fabs(val: f64) f64 {
    return math.fabs(val);
}

pub fn ceil(val: f64) f64 {
    return math.ceil(val);
}

pub fn floor(val: f64) f64 {
    return math.floor(val);
}

pub fn trunc(val: f64) f64 {
    return math.trunc(val);
}

pub fn round(val: f64) f64 {
    return math.round(val);
}

pub fn isFinite(val: f64) bool {
    return math.isFinite(val);
}

pub fn isInf(val: f64) bool {
    return math.isInf(val);
}

pub fn isPositiveInf(val: f64) bool {
    return math.isPositiveInf(val);
}

pub fn isNegativeInf(val: f64) bool {
    return math.isNegativeInf(val);
}

pub fn isNormal(val: f64) bool {
    return math.isNormal(val);
}

pub fn signbit(val: f64) bool {
    return math.signbit(val);
}

pub fn scalbn(val: f64, n: i32) f64 {
    return math.scalbn(val, n);
}

pub fn cbrt(val: f64) f64 {
    return math.cbrt(val);
}

pub fn acos(val: f64) f64 {
    return math.acos(val);
}

pub fn asin(val: f64) f64 {
    return math.asin(val);
}

pub fn atan(val: f64) f64 {
    return math.atan(val);
}

pub fn atan2(y: f64, x: f64) f64 {
    return math.atan2(f64, y, x);
}

pub fn hypot(x: f64, y: f64) f64 {
    return math.hypot(f64, x, y);
}

pub fn exp(val: f64) f64 {
    return math.exp(val);
}

pub fn exp2(val: f64) f64 {
    return math.exp2(val);
}

pub fn expm1(val: f64) f64 {
    return math.expm1(val);
}

pub fn ilogb(val: f64) i32 {
    return math.ilogb(val);
}

pub fn log(base: f64, val: f64) f64 {
    return math.log(f64, base, val);
}

pub fn log2(val: f64) f64 {
    return math.log2(val);
}

pub fn log10(val: f64) f64 {
    return math.log10(val);
}

pub fn log1p(val: f64) f64 {
    return math.log1p(val);
}

pub fn asinh(val: f64) f64 {
    return math.asinh(val);
}

pub fn acosh(val: f64) f64 {
    return math.acosh(val);
}

pub fn atanh(val: f64) f64 {
    return math.atanh(val);
}

pub fn sinh(val: f64) f64 {
    return math.sinh(val);
}

pub fn cosh(val: f64) f64 {
    return math.cosh(val);
}

pub fn tanh(val: f64) f64 {
    return math.tanh(val);
}

pub fn cos(val: f64) f64 {
    return math.cos(val);
}

pub fn sin(val: f64) f64 {
    return math.sin(val);
}

pub fn tan(val: f64) f64 {
    return math.tan(val);
}

pub fn clz(val: i64) i64 {
    return @clz(i64, val);
}

pub fn ctz(val: i64) i64 {
    return @ctz(i64, val);
}

pub fn popcount(val: i64) i64 {
    return @popCount(i64, val);
}

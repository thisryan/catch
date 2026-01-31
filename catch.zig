const std = @import("std");
const print = std.debug.print;
const fs = std.fs;
const Allocator = std.mem.Allocator;

const Buffer = struct {
    buffer: []u8,
    index: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Buffer {
        return .{
            .allocator = allocator,
            .buffer = &.{},
            .index = 0
        };
    }

    pub fn writeFile(self: *Buffer, file_name: []const u8, bytes: []u8) !void {
        const addition = file_name.len + 1 + bytes.len + @sizeOf(usize);

        if(self.buffer.len < self.index + addition) {
            const new_size = (self.index + addition) * 2;

            self.buffer = try self.allocator.realloc(self.buffer, new_size);
        }

        for(0..file_name.len) |i| {
            self.buffer[self.index] = file_name[i];

            self.index += 1;
        }

        self.buffer[self.index] = 0;
        self.index += 1;

        const size_ptr: *align(1) usize = @ptrCast(&self.buffer[self.index]);
        size_ptr.* = bytes.len;

        self.index += @sizeOf(usize);

        for(0..bytes.len) |i| {
            self.buffer[self.index] = bytes[i];

            self.index += 1;
        }
    }

    pub fn cleanup(self: *Buffer) void {
        self.allocator.free(self.buffer);
    }

    pub fn get(self: Buffer) []const u8 {
        return self.buffer[0..self.index];
    }
};

const File = struct {
    name: []const u8,
    bytes: []const u8,
};

pub fn read_files(allocator: Allocator, bytes: []const u8) !std.ArrayList(File)  {
    var result: std.ArrayList(File) = .empty;

    var i = @as(usize, 0);
    while(i < bytes.len){
        const start = i;
        var cur = i+1;
        while(bytes[cur] != 0) : (cur += 1) {}

        const name = bytes[start..cur];

        i += cur-start+1;

        const size_ptr: *const align(1) usize = @ptrCast(&bytes[i]);

        i += @sizeOf(usize);

        const bytes_start = i;
        const bytes_end = i + size_ptr.*;

        i += size_ptr.*;

        try result.append(allocator, .{
            .bytes = bytes[bytes_start..bytes_end],
            .name = name
        });
    }

    return result;
}

pub fn collect_files(file_name: []const u8, allocator: std.mem.Allocator) !Buffer {
    var dir = try fs.cwd().openDir(file_name, .{ .iterate = true });
    
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var buffer = Buffer.init(allocator);

    while (try walker.next()) |entry| {
        if(entry.kind == .directory) continue;

        if(std.mem.startsWith(u8, entry.path, ".")) continue;

        const bytes = try fs.cwd().readFileAlloc(allocator, entry.path, std.math.maxInt(usize));        
        defer allocator.free(bytes);

        try buffer.writeFile(entry.path, bytes);
    }

    return buffer;
}

pub fn do_catch(allocator: std.mem.Allocator, file_name: []const u8) !void {
    var buffer = try collect_files(".", allocator);
    defer buffer.cleanup();

    try std.fs.cwd().writeFile(.{
        .data = buffer.get(),
        .flags = .{},
        .sub_path = file_name
    });
}

pub fn do_release(allocator: std.mem.Allocator, target_dir: []const u8) !void {
    const bytes = try fs.cwd().readFileAlloc(allocator, ".catch", std.math.maxInt(usize));
    defer allocator.free(bytes);

    var files = try read_files(allocator, bytes);
    defer files.deinit(allocator);

    for (files.items) |file| {
        const strings: [3][]const u8 = .{target_dir, "/", file.name};

        const path = try std.mem.concat(allocator, u8, &strings);
        defer allocator.free(path);

        print("{s}\n", .{path});
        try std.fs.cwd().writeFile(.{
            .data = file.bytes,
            .flags = .{},
            .sub_path = path
        });
    }
}

pub fn main() !void {
    const args = std.os.argv;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak");
    const allocator = gpa.allocator();

    if(args.len >= 2 and std.mem.eql(u8, std.mem.span(args[1]), "release")) {
        var exists = true;

        fs.cwd().access(".releasestop", .{}) catch {
            exists = false;
        };

        if(exists) {
            std.debug.print("Found releasestop file stopping release \n", .{});
            return;
        }

        try do_release(allocator, ".");
        return;
    }

    try do_catch(allocator, ".catch");
}
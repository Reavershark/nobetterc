module druntime.slices.copying;

@safe @nogc:

@trusted nothrow extern (C)
void _d_array_slice_copy(void* dst, size_t dstlen, void* src, size_t srclen, size_t elemsz)
{
    import ldc.intrinsics : llvm_memcpy;

    assert(srclen == dstlen);
    assert(src > dst ? src - dst : dst - src >= elemsz);

    llvm_memcpy!size_t(dst, src, dstlen * elemsz, 0);
}

@("slice _d_array_slice_copy")
unittest
{
    int[3] a = [1, 2, 3];
    int[3] b;
    b[] = a[];
    assert(b[0] == 1 && b[1] == 2 && b[2] == 3);
}

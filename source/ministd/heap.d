module ministd.heap;

// import core.lifetime;
// 
// @safe @nogc:
// 
// T* move(T)(ref T* ptr)
// {
//     scope(exit) ptr = null;
//     return ptr;
// }
// 
// T[] move(T)(ref T[] slice)
// {
//     scope(exit) slice = [];
//     return slice;
// }
// 
// struct UniqueHeapPtr(T)
// {
//     private T* m_ptr;
// 
//     @disable this();
//     @disable this(typeof(this));
// 
//     private
// 
//     this(T* ptr) pure
//     {
//         m_ptr = ptr;
//     }
// 
//     ~this()
//     {
//         if (!empty)
//             reset;
//     }
// 
//     static typeof(this) create(CtorArgs...)(CtorArgs ctorArgs)
//     {
//         T* ptr = dalloc!T;
//         moveEmplace(T(ctorArgs), *ptr);
//         return typeof(this)(ptr);
//     }
// 
//     bool empty() pure const => m_ptr is null;
// 
//     void reset()
//     in (!empty)
//     {
//         destroy(*m_ptr);
//         dfree(m_ptr);
//         m_ptr = null;
//     }
// 
//     inout(T*) get() inout pure => m_ptr;
// }
// 
// struct UniqueHeapArray(T)
// {
//     private T[] m_arr;
// 
//     @disable this();
// 
//     this(T[] arr) pure
//     {
//         m_arr = arr;
//     }
// 
//     ~this()
//     {
//         if (!empty)
//             reset;
//     }
// 
//     typeof(this) move()
//     {
//         return UniqueHeapArray(.move(m_arr));
//     }
// 
//     static typeof(this) create(CtorArgs...)(size_t length, CtorArgs ctorArgs)
//     {
//         T[] arr = dallocArray!T(length);
//         foreach (ref el; arr)
//             el = T(ctorArgs);
//         return typeof(this)(.move(arr));
//     }
// 
//     bool empty() pure const => m_arr is [];
// 
//     void reset()
//     in (!empty)
//     {
//         static if (is(T == struct)) 
//             foreach (ref el; m_arr)
//                 destroy(el);
//         dfree(m_arr);
//         m_arr = [];
//     }
// 
//     inout(T[]) get() inout pure => m_arr;
// }
// 
// struct SharedHeapPtr(T)
// {
//     private struct Container
//     {
//         T value;
//         int refCount;
//     }
// 
//     private Container* m_container;
// 
//     @disable this();
// 
//     private this(Container* container)
//     {
//         m_container = container;
//     }
// 
//     this(typeof(this) other)
//     in (!other.empty)
//     {
//         m_container = other.m_container;
//         m_container.refCount++;
//     }
// 
//     ~this()
//     {
//         if (!empty)
//             reset;
//     }
// 
//     static typeof(this) create(CtorArgs...)(CtorArgs ctorArgs)
//     {
//         Container* container = dalloc!Container;
//         moveEmplace(Container(T(ctorArgs), 1), *container);
//         return typeof(this)(container);
//     }
// 
//     bool empty() pure const => m_container is null;
// 
//     void reset()
//     in (!empty)
//     {
//         m_container.refCount--;
//         if (m_container.refCount == 0)
//         {
//             destroy(*m_container);
//             dfree(m_container);
//         }
//         m_container = null;
//     }
// 
//     inout(T*) get() inout pure
//     in (!empty)
//     {
//         return &m_container.value;
//     }
// }
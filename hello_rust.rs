#![no_std]
#![no_main]

extern "C" {
    fn printf(format: *const u8, args: ...);
}

#[no_mangle]
extern "C" fn main(_argc: isize, _argv: *const *const u8) -> isize {
    unsafe {
        printf(b"Hello, world!\n".as_ptr(), 0);
    }
    0
}

#[panic_handler]
fn my_panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}
